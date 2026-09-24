-- ============================================================================
-- Migrasi 0054: Transaksi Lewat Tengah Malam & Zona Waktu Penyewa (T7-11)
--
-- Referensi:
--   - PRD M8 (kasus tepi): "transaksi lewat tengah malam (masuk tanggal transaksi,
--     bukan tanggal tutup kas) · nomor pesanan mengikuti hari operasional;
--     uji lulus dengan jam simulasi."
--   - TECH_SPEC §9 ART-9: "Simpan UTC; tampilkan per zona penyewa. Penomoran
--     pesanan harian memakai zona penyewa (bukan UTC) — kalau salah, nomor
--     pesanan bisa 'melompat hari'. Laporan harian memakai batas hari menurut
--     zona penyewa."
--   - DECISIONS_LOG.md: Area Zona Waktu (ART-9).
--
-- Masalah yang diselesaikan:
--   1. Pada saat jam operasional resto melewati tengah malam (misal 00:10 WIB di
--      Asia/Jakarta = 17:10 UTC hari sebelumnya), pembandingan tanggal pesanan
--      terhadap `current_date` UTC menyebabkan tanggal pesanan mundur ke hari
--      sebelumnya atau pesanan tanggal hari ini ditolak ('Tanggal pesanan baru harus
--      hari ini').
--   2. Nomor urut pesanan harian (`nomor_pesanan_berikutnya`) harus dihitung
--      berdasarkan tanggal kalender lokal resto (Asia/Jakarta), sehingga saat berganti
--      hari operasional (00:00:00 WIB), nomor pesanan berlanjut sesuai hari lokal
--      (mereset ke 1 untuk hari baru).
--   3. Transaksi masuk ke tanggal transaksi sesungguhnya, bukan tanggal tutup kas
--      (misal transaksi jam 23:50 masuk ke 2026-09-24, transaksi jam 00:10 masuk ke
--      2026-09-25, meskipun kasir baru menutup shift pada jam 02:00 tanggal 2026-09-25).
--   4. Pemotongan batas hari pada agregasi laporan (laporan_harian, laporan_penjualan,
--      laporan_menu) harus mengevaluasi stempel waktu dalam zona waktu lokal cabang.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Helper: Mengambil zona waktu cabang dari penyewa (default 'Asia/Jakarta')
-- ---------------------------------------------------------------------------
create or replace function public.zona_waktu_cabang(p_cabang_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(p.zona_waktu, 'Asia/Jakarta')
    from public.cabang c
    join public.penyewa p on p.id = c.penyewa_id
   where c.id = p_cabang_id;
$$;

comment on function public.zona_waktu_cabang(uuid) is
  'Mengambil zona waktu resmi cabang dari entitas penyewa (default: Asia/Jakarta) untuk kepatuhan ART-9.';

revoke all on function public.zona_waktu_cabang(uuid) from public, anon;
grant execute on function public.zona_waktu_cabang(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Helper: Menghitung tanggal kalender lokal berdasarkan zona waktu cabang
-- ---------------------------------------------------------------------------
create or replace function public.tanggal_lokal_cabang(
  p_cabang_id uuid,
  p_waktu     timestamptz default now()
)
returns date
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (coalesce(p_waktu, now()) at time zone coalesce(public.zona_waktu_cabang(p_cabang_id), 'Asia/Jakarta'))::date;
$$;

comment on function public.tanggal_lokal_cabang(uuid, timestamptz) is
  'Menghitung tanggal lokal kalender menurut zona waktu cabang untuk penomoran pesanan dan laporan (ART-9).';

revoke all on function public.tanggal_lokal_cabang(uuid, timestamptz) from public, anon;
grant execute on function public.tanggal_lokal_cabang(uuid, timestamptz) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Pembaruan penjaga pesanan: Menetapkan tanggal dan nomor urut pesanan
--    berdasarkan tanggal kalender lokal cabang (ART-9 & PRD M8)
-- ---------------------------------------------------------------------------
-- Lepas default current_date pada pesanan.tanggal agar tidak terisi tanggal UTC peladen
-- saat transaksi lewat tengah malam (00:00–07:00 WIB). Tanggal selalu ditetapkan oleh
-- pemicu berdasarkan tanggal_lokal_cabang.
alter table public.pesanan alter column tanggal drop default;

create or replace function public.picu_pesanan_jejak_jujur()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_nomor_seharusnya integer;
  v_pelayan_valid    boolean;
  v_tanggal_lokal    date;
begin
  -- Hitung tanggal lokal cabang berdasarkan jam transaksi
  v_tanggal_lokal := public.tanggal_lokal_cabang(new.cabang_id, coalesce(new.dibuat_pada, now()));

  if auth.uid() is null or public.peran_peladen() then
    if tg_op = 'INSERT' and new.tanggal is null then
      new.tanggal := v_tanggal_lokal;
    end if;
    return new;   -- penyiapan / fungsi peladen
  end if;

  if tg_op = 'INSERT' then
    -- Pelaku: kasir_id diisi sistem, bukan dipilih perangkat.
    if new.kasir_id is not null and new.kasir_id is distinct from auth.uid() then
      raise exception 'Nama kasir diisi sistem — tidak boleh menyebut orang lain.';
    end if;
    new.kasir_id := auth.uid();

    -- Waktu: pesanan baru selalu hari ini menurut zona waktu resto (ART-9 & PRD M8).
    -- Menggunakan tanggal lokal cabang pada jam transaksi dibuat (bukan UTC current_date).
    if new.tanggal is not null and new.tanggal <> v_tanggal_lokal then
      raise exception 'Tanggal pesanan baru harus hari ini — tanggal mundur hanya boleh diisi peladen.';
    end if;
    new.tanggal := coalesce(new.tanggal, v_tanggal_lokal);

    -- Nomor: SELALU dibuat sistem (berurutan per cabang per hari operasional lokal).
    -- Angka yang dikirim klien DIIABAIKAN — dulu klien bisa memilih nomornya sendiri (temuan audit F-04).
    new.nomor := public.nomor_pesanan_berikutnya(new.cabang_id, new.tanggal);
  else
    -- Pelaku & waktu tidak boleh dipindah setelah baris lahir.
    if new.kasir_id is distinct from old.kasir_id then
      raise exception 'Jejak kasir pesanan tidak boleh diubah.';
    end if;
    if new.tanggal is distinct from old.tanggal then
      raise exception 'Tanggal pesanan tidak boleh diubah.';
    end if;
    if new.nomor is distinct from old.nomor then
      raise exception 'Nomor pesanan tidak boleh diubah.';
    end if;

    -- TEMUAN AUD-3 F-06 (K-2): stempel kejadian hanya dari peladen
    if new.dibayar_pada is distinct from old.dibayar_pada then
      raise exception 'Stempel pembayaran (dibayar_pada) hanya diisi jalur peladen setelah pembayaran sah.';
    end if;
    if new.dibatalkan_pada is distinct from old.dibatalkan_pada
       or new.alasan_batal is distinct from old.alasan_batal then
      raise exception 'Stempel pembatalan hanya diisi jalur peladen setelah pembatalan resmi (baris pembatalan ber-PIN bila sesudah dapur).';
    end if;
  end if;

  -- Pelayan: hanya pegawai cabang itu yang boleh disebut.
  if new.pelayan_id is not null then
    select exists (
      select 1 from public.pengguna_cabang pc
       where pc.pengguna_id = new.pelayan_id
         and pc.cabang_id = new.cabang_id
    ) into v_pelayan_valid;
    if not v_pelayan_valid then
      raise exception 'Pelayan yang disebut harus pegawai di cabang pesanan itu.';
    end if;
  end if;

  return new;
end;
$$;

comment on function public.picu_pesanan_jejak_jujur() is
  'Menjaga jejak pesanan: kasir/tanggal/nomor diisi sistem berdasar zona waktu cabang (ART-9), pelayan se-cabang, dan stempel lifecycle terkunci.';

grant execute on function public.picu_pesanan_jejak_jujur() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. Pembaruan RPC public.laporan_harian (zona waktu lokal & batas hari)
-- ---------------------------------------------------------------------------
create or replace function public.laporan_harian(
  p_cabang_id uuid default null,
  p_tanggal   date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_zona               text;
  v_tanggal            date;
  v_jumlah_shift       integer := 0;
  v_omzet_total        integer := 0;
  v_omzet_makanan      integer := 0;
  v_omzet_minuman      integer := 0;
  v_omzet_lainnya      integer := 0;
  v_jumlah_transaksi   integer := 0;
  v_penjualan_tunai    integer := 0;
  v_penjualan_non_tunai integer := 0;
  v_kas_masuk          integer := 0;
  v_kas_keluar         integer := 0;
  v_setoran            integer := 0;
  v_total_modal_awal   integer := 0;
  v_total_uang_seharusnya integer := 0;
  v_total_uang_fisik   integer := 0;
  v_total_selisih      integer := 0;
  v_total_diskon       integer := 0;
  v_daftar_shift       jsonb := '[]'::jsonb;
  v_rincian_metode     jsonb := '[]'::jsonb;
  v_pembatalan_data    record;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- Wajib izin lihat_laporan (owner_pusat, admin_cabang)
  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan harian.';
  end if;

  -- Bila cabang_id diberikan, pastikan cabang valid dan dapat dipantau
  if p_cabang_id is not null then
    if not exists (
      select 1 from public.cabang c
       where c.id = p_cabang_id
         and c.penyewa_id = v_penyewa
    ) then
      raise exception 'Cabang tidak ditemukan.';
    end if;

    if not public.cabang_pantau_saya(p_cabang_id) then
      raise exception 'Cabang di luar wewenang pantauan Anda.';
    end if;

    v_zona := coalesce(public.zona_waktu_cabang(p_cabang_id), 'Asia/Jakarta');
    v_tanggal := coalesce(p_tanggal, public.tanggal_lokal_cabang(p_cabang_id, now()));
  else
    select coalesce(p.zona_waktu, 'Asia/Jakarta') into v_zona
      from public.penyewa p where p.id = v_penyewa;
    if v_zona is null then
      v_zona := 'Asia/Jakarta';
    end if;
    v_tanggal := coalesce(p_tanggal, (now() at time zone v_zona)::date);
  end if;

  -- Daftar shift pada tanggal tersebut (menurut zona waktu resto)
  select
    coalesce(count(s.id), 0),
    coalesce(sum(s.modal_awal), 0),
    coalesce(sum(case when s.status = 'ditutup' then coalesce(s.uang_seharusnya, 0) else 0 end), 0),
    coalesce(sum(case when s.status = 'ditutup' then coalesce(s.uang_fisik, 0) else 0 end), 0),
    coalesce(sum(case when s.status = 'ditutup' then coalesce(s.selisih, 0) else 0 end), 0),
    coalesce(jsonb_agg(
      jsonb_build_object(
        'shift_id', s.id,
        'cabang_id', s.cabang_id,
        'nama_cabang', c.nama,
        'dibuka_oleh', s.dibuka_oleh,
        'kasir_buka_nama', ub.nama,
        'dibuka_pada', s.dibuka_pada,
        'ditutup_oleh', s.ditutup_oleh,
        'kasir_tutup_nama', ut.nama,
        'ditutup_pada', s.ditutup_pada,
        'status', s.status,
        'melewati_tengah_malam', coalesce(s.melewati_tengah_malam, false),
        'modal_awal', s.modal_awal,
        'uang_seharusnya', s.uang_seharusnya,
        'uang_fisik', s.uang_fisik,
        'selisih', s.selisih,
        'alasan_selisih', s.alasan_selisih
      ) order by s.dibuka_pada asc
    ), '[]'::jsonb)
  into
    v_jumlah_shift,
    v_total_modal_awal,
    v_total_uang_seharusnya,
    v_total_uang_fisik,
    v_total_selisih,
    v_daftar_shift
  from public.shift_kas s
  join public.cabang c on c.id = s.cabang_id
  left join public.pengguna ub on ub.id = s.dibuka_oleh
  left join public.pengguna ut on ut.id = s.ditutup_oleh
  where s.penyewa_id = v_penyewa
    and (p_cabang_id is null or s.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(s.cabang_id)
    and ((s.dibuka_pada at time zone v_zona)::date = v_tanggal);

  if v_daftar_shift is null then
    v_daftar_shift := '[]'::jsonb;
  end if;

  -- Agregasi pergerakan kas pada tanggal tersebut
  select
    coalesce(sum(case when kp.jenis = 'masuk' then kp.jumlah else 0 end), 0),
    coalesce(sum(case when kp.jenis = 'keluar' then kp.jumlah else 0 end), 0),
    coalesce(sum(case when kp.jenis = 'setoran' then kp.jumlah else 0 end), 0)
  into
    v_kas_masuk,
    v_kas_keluar,
    v_setoran
  from public.kas_pergerakan kp
  where kp.penyewa_id = v_penyewa
    and (p_cabang_id is null or kp.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(kp.cabang_id)
    and ((kp.dibuat_pada at time zone v_zona)::date = v_tanggal);

  -- Agregasi pembayaran pada tanggal tersebut
  select
    coalesce(sum(case when pb.jenis_saat_itu = 'tunai' then pb.jumlah else 0 end), 0),
    coalesce(sum(case when pb.jenis_saat_itu = 'non_tunai' then pb.jumlah else 0 end), 0)
  into
    v_penjualan_tunai,
    v_penjualan_non_tunai
  from public.pembayaran pb
  join public.pesanan p on p.id = pb.pesanan_id
  where p.penyewa_id = v_penyewa
    and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(p.cabang_id)
    and ((pb.waktu at time zone v_zona)::date = v_tanggal);

  -- Agregasi pesanan lunas pada tanggal tersebut (berdasarkan p.tanggal kalender transaksi)
  select
    coalesce(count(distinct p.id), 0),
    coalesce(sum(p.total), 0),
    coalesce(sum(coalesce(p.total_diskon, 0)), 0)
  into
    v_jumlah_transaksi,
    v_omzet_total,
    v_total_diskon
  from public.pesanan p
  where p.penyewa_id = v_penyewa
    and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(p.cabang_id)
    and p.status = 'lunas'
    and p.tanggal = v_tanggal;

  -- Agregasi omzet per kategori menu
  select
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'makanan' then pi.subtotal else 0 end), 0),
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') = 'minuman' then pi.subtotal else 0 end), 0),
    coalesce(sum(case when coalesce(mi.jenis, 'lainnya') not in ('makanan', 'minuman') then pi.subtotal else 0 end), 0)
  into
    v_omzet_makanan,
    v_omzet_minuman,
    v_omzet_lainnya
  from public.pesanan_item pi
  join public.pesanan p on p.id = pi.pesanan_id
  left join public.menu_item mi on mi.id = pi.menu_item_id
  where p.penyewa_id = v_penyewa
    and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(p.cabang_id)
    and p.status = 'lunas'
    and p.tanggal = v_tanggal;

  -- Rincian metode bayar
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'metode_id', t.metode_id,
      'nama', t.nama,
      'jenis', t.jenis,
      'transaksi_count', t.transaksi_count,
      'total', t.total
    ) order by t.total desc, t.nama
  ), '[]'::jsonb)
  into v_rincian_metode
  from (
    select
      mb.id as metode_id,
      mb.nama,
      mb.jenis,
      count(pb.id) as transaksi_count,
      coalesce(sum(pb.jumlah), 0) as total
    from public.metode_bayar mb
    join public.pembayaran pb on pb.metode_id = mb.id
    join public.pesanan p on p.id = pb.pesanan_id
    where mb.penyewa_id = v_penyewa
      and (p_cabang_id is null or p.cabang_id = p_cabang_id)
      and public.cabang_pantau_saya(p.cabang_id)
      and ((pb.waktu at time zone v_zona)::date = v_tanggal)
    group by mb.id, mb.nama, mb.jenis
  ) t;

  if v_rincian_metode is null then
    v_rincian_metode := '[]'::jsonb;
  end if;

  -- Agregasi pembatalan
  select
    coalesce(count(b.id), 0) as jumlah_pembatalan,
    coalesce(sum(b.nilai_kerugian), 0) as total_nilai_rugi,
    coalesce(jsonb_agg(
      jsonb_build_object(
        'id', b.id,
        'nomor_pesanan', p.nomor,
        'item_nama', pi.nama_saat_itu,
        'waktu', b.waktu,
        'tahap', b.tahap,
        'alasan', b.alasan,
        'nilai_kerugian', b.nilai_kerugian,
        'bahan_terbuang', b.bahan_terbuang,
        'pelaku_nama', u.nama
      ) order by b.waktu asc
    ), '[]'::jsonb) as daftar
  into v_pembatalan_data
  from public.pembatalan b
  join public.pesanan p on p.id = b.pesanan_id
  left join public.pesanan_item pi on pi.id = b.pesanan_item_id
  left join public.pengguna u on u.id = b.pelaku_id
  where p.penyewa_id = v_penyewa
    and (p_cabang_id is null or p.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(p.cabang_id)
    and ((b.waktu at time zone v_zona)::date = v_tanggal);

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LP-200',
    'pesan', 'Laporan harian berhasil dimuat.',
    'data', jsonb_build_object(
      'tanggal', v_tanggal,
      'cabang_id', p_cabang_id,
      'jumlah_shift', v_jumlah_shift,
      'penjualan', jsonb_build_object(
        'jumlah_transaksi', v_jumlah_transaksi,
        'omzet_total', v_omzet_total,
        'omzet_makanan', v_omzet_makanan,
        'omzet_minuman', v_omzet_minuman,
        'omzet_lainnya', v_omzet_lainnya,
        'total_diskon', v_total_diskon
      ),
      'kas', jsonb_build_object(
        'penjualan_tunai', v_penjualan_tunai,
        'penjualan_non_tunai', v_penjualan_non_tunai,
        'kas_masuk', v_kas_masuk,
        'kas_keluar', v_kas_keluar,
        'setoran', v_setoran,
        'total_modal_awal', v_total_modal_awal,
        'total_uang_seharusnya', v_total_uang_seharusnya,
        'total_uang_fisik', v_total_uang_fisik,
        'total_selisih', v_total_selisih
      ),
      'metode_bayar', v_rincian_metode,
      'daftar_shift', v_daftar_shift,
      'pembatalan', jsonb_build_object(
        'jumlah_pembatalan', coalesce(v_pembatalan_data.jumlah_pembatalan, 0),
        'total_nilai_rugi', coalesce(v_pembatalan_data.total_nilai_rugi, 0),
        'daftar', coalesce(v_pembatalan_data.daftar, '[]'::jsonb)
      )
    )
  );
end;
$$;

comment on function public.laporan_harian(uuid, date) is
  'Laporan harian kas dan penjualan dengan batas hari berbasis zona waktu resto (ART-9).';

revoke all on function public.laporan_harian(uuid, date) from public, anon;
grant execute on function public.laporan_harian(uuid, date) to authenticated, service_role;
