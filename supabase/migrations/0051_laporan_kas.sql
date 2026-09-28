-- ============================================================================
-- 0051 — Laporan A: kas harian per shift (T7-07, PRD M8 · TECH_SPEC §5)
--
-- PRD M8:
--   "Sebagai Owner, saya ingin membuka satu layar dan langsung tahu kondisi
--   hari ini, supaya saya bisa memutuskan tanpa menghitung manual."
--
-- Yang disediakan migrasi ini:
--   1. View `public.laporan_kas_shift` (security_invoker = true)
--      Ringkasan kas per baris shift yang tunduk pada RLS shift_kas:
--      modal awal, koreksi modal, kas masuk/keluar, setoran, penjualan tunai,
--      penjualan non-tunai, uang seharusnya, fisik, selisih, alasan, status.
--   2. RPC `public.laporan_shift(p_shift_id uuid)`
--      RPC resmi TECH_SPEC §5 untuk memuat rincian mendalam satu shift:
--      omzet (makanan/minuman/lainnya), jumlah transaksi, rincian metode bayar,
--      diskon & voucher, pembatalan/void, pergerakan kas operasional, dan rekonsiliasi.
--   3. RPC `public.laporan_harian(p_cabang_id uuid, p_tanggal date)`
--      RPC resmi TECH_SPEC §5 untuk memuat ringkasan gabungan seluruh shift
--      pada tanggal bersangkutan untuk cabang tertentu (atau seluruh cabang pemantauan).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. View Ringkasan Kas Shift (security_invoker = true)
-- ---------------------------------------------------------------------------
create or replace view public.laporan_kas_shift
with (security_invoker = true) as
select
  s.id                                 as shift_id,
  s.penyewa_id,
  s.cabang_id,
  c.nama                               as nama_cabang,
  s.dibuka_oleh,
  ub.nama                              as kasir_buka_nama,
  s.dibuka_pada,
  s.ditutup_oleh,
  ut.nama                              as kasir_tutup_nama,
  s.ditutup_pada,
  s.status,
  coalesce(s.melewati_tengah_malam, false) as melewati_tengah_malam,
  s.modal_awal,
  coalesce((
    select sum(km.selisih)
      from public.koreksi_modal_shift km
     where km.shift_id = s.id
  ), 0)::integer                       as total_koreksi_modal,
  coalesce((
    select sum(kp.jumlah)
      from public.kas_pergerakan kp
     where kp.shift_id = s.id
       and kp.jenis = 'masuk'
  ), 0)::integer                       as kas_masuk,
  coalesce((
    select sum(kp.jumlah)
      from public.kas_pergerakan kp
     where kp.shift_id = s.id
       and kp.jenis = 'keluar'
  ), 0)::integer                       as kas_keluar,
  coalesce((
    select sum(kp.jumlah)
      from public.kas_pergerakan kp
     where kp.shift_id = s.id
       and kp.jenis = 'setoran'
  ), 0)::integer                       as setoran,
  coalesce((
    select sum(pb.jumlah)
      from public.pembayaran pb
     where pb.shift_id = s.id
       and pb.jenis_saat_itu = 'tunai'
  ), 0)::integer                       as penjualan_tunai,
  coalesce((
    select sum(pb.jumlah)
      from public.pembayaran pb
     where pb.shift_id = s.id
       and pb.jenis_saat_itu = 'non_tunai'
  ), 0)::integer                       as penjualan_non_tunai,
  coalesce((
    select sum(pb.jumlah)
      from public.pembayaran pb
     where pb.shift_id = s.id
  ), 0)::integer                       as total_penjualan,
  case
    when s.status = 'ditutup' then s.uang_seharusnya
    else greatest(
      0,
      s.modal_awal
      + coalesce((select sum(pb.jumlah) from public.pembayaran pb where pb.shift_id = s.id and pb.jenis_saat_itu = 'tunai'), 0)
      + coalesce((select sum(kp.jumlah) from public.kas_pergerakan kp where kp.shift_id = s.id and kp.jenis = 'masuk'), 0)
      - coalesce((select sum(kp.jumlah) from public.kas_pergerakan kp where kp.shift_id = s.id and kp.jenis in ('keluar', 'setoran')), 0)
    )
  end::integer                         as uang_seharusnya,
  s.uang_fisik,
  s.selisih,
  s.alasan_selisih,
  coalesce((
    select count(distinct p.id)
      from public.pesanan p
     where p.shift_id = s.id
       and p.status = 'lunas'
  ), 0)::integer                       as jumlah_transaksi
from public.shift_kas s
join public.cabang c on c.id = s.cabang_id
left join public.pengguna ub on ub.id = s.dibuka_oleh
left join public.pengguna ut on ut.id = s.ditutup_oleh;

comment on view public.laporan_kas_shift is
  'T7-07: Ringkasan kas per baris shift (modal, kas pergerakan, penjualan tunai/non-tunai, uang seharusnya vs fisik, dan selisih). security_invoker = true.';

revoke all on table public.laporan_kas_shift from public, anon;
grant select on table public.laporan_kas_shift to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. RPC public.laporan_shift (TECH_SPEC §5: rpc/laporan_shift)
-- ---------------------------------------------------------------------------
create or replace function public.laporan_shift(
  p_shift_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_shift              record;
  v_kas_masuk          integer := 0;
  v_kas_keluar         integer := 0;
  v_setoran            integer := 0;
  v_total_koreksi      integer := 0;
  v_penjualan_tunai    integer := 0;
  v_penjualan_non_tunai integer := 0;
  v_uang_seharusnya    integer := 0;
  v_jumlah_transaksi   integer := 0;
  v_omzet_total        integer := 0;
  v_omzet_makanan      integer := 0;
  v_omzet_minuman      integer := 0;
  v_omzet_lainnya      integer := 0;
  v_total_subtotal     integer := 0;
  v_total_pajak        integer := 0;
  v_total_service      integer := 0;
  v_total_diskon       integer := 0;
  v_rincian_metode     jsonb := '[]'::jsonb;
  v_daftar_pergerakan  jsonb := '[]'::jsonb;
  v_daftar_koreksi     jsonb := '[]'::jsonb;
  v_pembatalan_data    record;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- Ambil data shift
  select
    s.*,
    c.nama as nama_cabang,
    ub.nama as kasir_buka_nama,
    ut.nama as kasir_tutup_nama
  into v_shift
  from public.shift_kas s
  join public.cabang c on c.id = s.cabang_id
  left join public.pengguna ub on ub.id = s.dibuka_oleh
  left join public.pengguna ut on ut.id = s.ditutup_oleh
  where s.id = p_shift_id
    and s.penyewa_id = v_penyewa;

  if v_shift.id is null then
    raise exception 'Shift tidak ditemukan.';
  end if;

  -- Verifikasi hak pantau cabang
  if not public.cabang_pantau_saya(v_shift.cabang_id) then
    raise exception 'Shift di luar wewenang cabang Anda.';
  end if;

  -- Verifikasi wewenang peran:
  -- Pemegang izin lihat_laporan (owner_pusat, admin_cabang) ATAU kasir shift terkait
  if not (
    public.boleh('lihat_laporan') or
    (v_shift.dibuka_oleh = auth.uid() or v_shift.ditutup_oleh = auth.uid())
  ) then
    raise exception 'Anda tidak berwenang melihat laporan shift ini.';
  end if;

  -- Hitung pergerakan kas
  select coalesce(sum(jumlah), 0) into v_kas_masuk
    from public.kas_pergerakan
   where shift_id = v_shift.id and jenis = 'masuk';

  select coalesce(sum(jumlah), 0) into v_kas_keluar
    from public.kas_pergerakan
   where shift_id = v_shift.id and jenis = 'keluar';

  select coalesce(sum(jumlah), 0) into v_setoran
    from public.kas_pergerakan
   where shift_id = v_shift.id and jenis = 'setoran';

  select coalesce(sum(selisih), 0) into v_total_koreksi
    from public.koreksi_modal_shift
   where shift_id = v_shift.id;

  -- Hitung penjualan tunai & non-tunai
  select coalesce(sum(jumlah), 0) into v_penjualan_tunai
    from public.pembayaran
   where shift_id = v_shift.id and jenis_saat_itu = 'tunai';

  select coalesce(sum(jumlah), 0) into v_penjualan_non_tunai
    from public.pembayaran
   where shift_id = v_shift.id and jenis_saat_itu = 'non_tunai';

  -- Hitung uang seharusnya
  if v_shift.status = 'ditutup' then
    v_uang_seharusnya := v_shift.uang_seharusnya;
  else
    v_uang_seharusnya := v_shift.modal_awal + v_penjualan_tunai + v_kas_masuk - v_kas_keluar - v_setoran;
    if v_uang_seharusnya < 0 then
      v_uang_seharusnya := 0;
    end if;
  end if;

  -- Hitung agregasi pesanan lunas pada shift ini
  select
    coalesce(count(distinct p.id), 0),
    coalesce(sum(p.subtotal), 0),
    coalesce(sum(p.pajak), 0),
    coalesce(sum(p.service), 0),
    coalesce(sum(coalesce(p.total_diskon, 0)), 0),
    coalesce(sum(p.total), 0)
  into
    v_jumlah_transaksi,
    v_total_subtotal,
    v_total_pajak,
    v_total_service,
    v_total_diskon,
    v_omzet_total
  from public.pesanan p
  where p.shift_id = v_shift.id
    and p.status = 'lunas';

  -- Hitung omzet per kategori menu (makanan, minuman, lainnya)
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
  where p.shift_id = v_shift.id
    and p.status = 'lunas';

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
    join public.pembayaran pb on pb.metode_id = mb.id and pb.shift_id = v_shift.id
    where mb.penyewa_id = v_penyewa
    group by mb.id, mb.nama, mb.jenis
  ) t;

  if v_rincian_metode is null then
    v_rincian_metode := '[]'::jsonb;
  end if;

  -- Daftar pergerakan kas
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', kp.id,
      'jenis', kp.jenis,
      'jumlah', kp.jumlah,
      'alasan', kp.alasan,
      'pelaku_nama', u.nama,
      'disetujui_nama', us.nama,
      'waktu', kp.dibuat_pada
    ) order by kp.dibuat_pada asc
  ), '[]'::jsonb)
  into v_daftar_pergerakan
  from public.kas_pergerakan kp
  left join public.pengguna u on u.id = kp.pelaku_id
  left join public.pengguna us on us.id = kp.disetujui_oleh
  where kp.shift_id = v_shift.id;

  if v_daftar_pergerakan is null then
    v_daftar_pergerakan := '[]'::jsonb;
  end if;

  -- Daftar koreksi modal awal
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', km.id,
      'modal_awal_sebelumnya', km.modal_awal_sebelumnya,
      'modal_awal_baru', km.modal_awal_baru,
      'selisih', km.selisih,
      'alasan', km.alasan,
      'diajukan_nama', ua.nama,
      'disetujui_nama', us.nama,
      'waktu', km.dibuat_pada
    ) order by km.dibuat_pada asc
  ), '[]'::jsonb)
  into v_daftar_koreksi
  from public.koreksi_modal_shift km
  left join public.pengguna ua on ua.id = km.diajukan_oleh
  left join public.pengguna us on us.id = km.disetujui_oleh
  where km.shift_id = v_shift.id;

  if v_daftar_koreksi is null then
    v_daftar_koreksi := '[]'::jsonb;
  end if;

  -- Pembatalan / Void pada shift ini
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
        'pelaku_nama', u.nama,
        'penyetuju_nama', us.nama
      ) order by b.waktu asc
    ), '[]'::jsonb) as daftar
  into v_pembatalan_data
  from public.pembatalan b
  join public.pesanan p on p.id = b.pesanan_id
  left join public.pesanan_item pi on pi.id = b.pesanan_item_id
  left join public.pengguna u on u.id = b.pelaku_id
  left join public.pengguna us on us.id = b.disetujui_oleh
  where p.shift_id = v_shift.id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LP-200',
    'pesan', 'Laporan shift berhasil dimuat.',
    'data', jsonb_build_object(
      'shift', jsonb_build_object(
        'id', v_shift.id,
        'cabang_id', v_shift.cabang_id,
        'nama_cabang', v_shift.nama_cabang,
        'kasir_buka_id', v_shift.dibuka_oleh,
        'kasir_buka_nama', v_shift.kasir_buka_nama,
        'kasir_tutup_id', v_shift.ditutup_oleh,
        'kasir_tutup_nama', v_shift.kasir_tutup_nama,
        'dibuka_pada', v_shift.dibuka_pada,
        'ditutup_pada', v_shift.ditutup_pada,
        'status', v_shift.status,
        'melewati_tengah_malam', coalesce(v_shift.melewati_tengah_malam, false),
        'catatan_buka', v_shift.catatan
      ),
      'kas', jsonb_build_object(
        'modal_awal', v_shift.modal_awal,
        'total_koreksi_modal', v_total_koreksi,
        'kas_masuk', v_kas_masuk,
        'kas_keluar', v_kas_keluar,
        'setoran', v_setoran,
        'penjualan_tunai', v_penjualan_tunai,
        'penjualan_non_tunai', v_penjualan_non_tunai,
        'total_penjualan', v_penjualan_tunai + v_penjualan_non_tunai,
        'uang_seharusnya', v_uang_seharusnya,
        'uang_fisik', v_shift.uang_fisik,
        'selisih', case when v_shift.status = 'ditutup' then v_shift.selisih else null end,
        'alasan_selisih', v_shift.alasan_selisih
      ),
      'penjualan', jsonb_build_object(
        'jumlah_transaksi', v_jumlah_transaksi,
        'omzet_total', v_omzet_total,
        'omzet_makanan', v_omzet_makanan,
        'omzet_minuman', v_omzet_minuman,
        'omzet_lainnya', v_omzet_lainnya,
        'total_subtotal', v_total_subtotal,
        'total_pajak', v_total_pajak,
        'total_service', v_total_service,
        'total_diskon', v_total_diskon
      ),
      'metode_bayar', v_rincian_metode,
      'pergerakan_kas', v_daftar_pergerakan,
      'koreksi_modal', v_daftar_koreksi,
      'pembatalan', jsonb_build_object(
        'jumlah', coalesce(v_pembatalan_data.jumlah_pembatalan, 0),
        'total_nilai_rugi', coalesce(v_pembatalan_data.total_nilai_rugi, 0),
        'daftar', coalesce(v_pembatalan_data.daftar, '[]'::jsonb)
      )
    )
  );
end;
$$;

comment on function public.laporan_shift(uuid) is
  'T7-07: Laporan komprehensif kas & omzet per shift kasir (M8 · TECH_SPEC §5).';

revoke all on function public.laporan_shift(uuid) from public, anon;
grant execute on function public.laporan_shift(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. RPC public.laporan_harian (TECH_SPEC §5: rpc/laporan_harian)
-- ---------------------------------------------------------------------------
create or replace function public.laporan_harian(
  p_cabang_id uuid default null,
  p_tanggal   date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
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

  v_tanggal := coalesce(p_tanggal, current_date);

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
  end if;

  -- Daftar shift pada tanggal tersebut
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
    and s.dibuka_pada::date = v_tanggal;

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
    and kp.dibuat_pada::date = v_tanggal;

  -- Agregasi pembayaran
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
    and pb.waktu::date = v_tanggal;

  -- Agregasi pesanan lunas pada tanggal tersebut
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

  -- Agregasi omzet per kategori
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
      and pb.waktu::date = v_tanggal
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
    and b.waktu::date = v_tanggal;

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
        'total_modal_awal', v_total_modal_awal,
        'penjualan_tunai', v_penjualan_tunai,
        'penjualan_non_tunai', v_penjualan_non_tunai,
        'total_penjualan', v_penjualan_tunai + v_penjualan_non_tunai,
        'kas_masuk', v_kas_masuk,
        'kas_keluar', v_kas_keluar,
        'setoran', v_setoran,
        'total_uang_seharusnya', v_total_uang_seharusnya,
        'total_uang_fisik', v_total_uang_fisik,
        'total_selisih', v_total_selisih
      ),
      'daftar_shift', v_daftar_shift,
      'metode_bayar', v_rincian_metode,
      'pembatalan', jsonb_build_object(
        'jumlah', coalesce(v_pembatalan_data.jumlah_pembatalan, 0),
        'total_nilai_rugi', coalesce(v_pembatalan_data.total_nilai_rugi, 0),
        'daftar', coalesce(v_pembatalan_data.daftar, '[]'::jsonb)
      )
    )
  );
end;
$$;

comment on function public.laporan_harian(uuid, date) is
  'T7-07: Laporan harian kas & penjualan per cabang / multi-cabang (M8 · TECH_SPEC §5).';

revoke all on function public.laporan_harian(uuid, date) from public, anon;
grant execute on function public.laporan_harian(uuid, date) to authenticated, service_role;
