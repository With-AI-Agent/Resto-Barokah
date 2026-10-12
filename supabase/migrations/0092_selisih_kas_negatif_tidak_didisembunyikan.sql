-- ============================================================================
-- MIGRASI 0092 — PMB1-F-046 (K-2): kekurangan kas tidak lagi disembunyikan jadi nol
-- ============================================================================
-- Baseline yang dilanggar: `docs/PRD.md:40` (laporan tutup kas harus cocok; "selisih
-- kas tanpa alasan" adalah cacat), `docs/ROADMAP.md` T7-02 DoD (selisih wajib
-- disertai alasan), `docs/KEAMANAN.md` §10 (jejak audit tidak bisa dihapus).
--
-- Cacat: `tutup_shift` (0084) dan `ambil_shift_perlu_tutup` (0084) MEMAKSA angka
-- "uang seharusnya" yang negatif menjadi 0. Contoh: modal awal 100.000, setoran 0,
-- uang keluar (kasbon) 150.000 -> seharusnya -50.000, dipaksa jadi 0. Kalau uang
-- fisiknya 0, `selisih = 0`, sehingga syarat "selisih wajib disertai alasan" TIDAK
-- menyala: kekurangan 50.000 hilang tanpa jejak. Pratinjau di aplikasi memakai
-- `greatest(0, ...)` yang sama, jadi kasir pun tidak pernah melihat kekurangan.
--
-- Perbaikan: batasan skema `uang_seharusnya >= 0` dilepas dan angka negatif
-- dipertahankan apa adanya di kedua fungsi. Akibatnya
-- `selisih` menjadi negatif sehingga kewajiban mengisi alasan (baris validasi di
-- bawah, tidak diubah) benar-benar menyala, dan laporan menampilkan kekurangan
-- sebagai selisih negatif. Migrasi lama tidak diubah; berkas berlaku = 0092.
--
-- RUJUKAN: `kartu/K-F-03.md` §1 (PMB1-F-046), `kartu/H-F-03.md`; dijaga oleh uji
-- `supabase/tes/selisih_kas_kekurangan_terlihat.sql`.

-- 1. Skema: batasan lama `uang_seharusnya >= 0` (dari 0045) IKUT MENYEMBUNYIKAN
--    kekurangan kas — ini akar bersama bugnya. Dilepas; kebenaran angka kini
--    dijaga rumus hitung + wajibnya alasan selisih (0046), bukan pelarasan nol.
alter table public.shift_kas
  drop constraint if exists shift_kas_uang_seharusnya_check;

create or replace function public.ambil_shift_perlu_tutup(
  p_cabang_id uuid default null
)
returns table (
  shift_id              uuid,
  cabang_id             uuid,
  nama_cabang           text,
  dibuka_oleh           uuid,
  nama_kasir            text,
  peran_kasir           text,
  dibuka_pada           timestamptz,
  modal_awal            integer,
  tunai_masuk           bigint,
  uang_seharusnya       integer,
  perlu_tutup_atasan    boolean,
  catatan_serah_terima  text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- Wajib berizin kelola_pegawai, tutup_kas, atau lihat_laporan
  if not (
    public.boleh('kelola_pegawai') or
    public.boleh('tutup_kas') or
    public.boleh('lihat_laporan')
  ) then
    raise exception 'Anda tidak berwenang melihat daftar shift serah terima atasan.';
  end if;

  return query
  select
    s.id as shift_id,
    s.cabang_id,
    c.nama as nama_cabang,
    s.dibuka_oleh,
    coalesce(u.nama, 'Pegawai Nonaktif') as nama_kasir,
    coalesce(u.peran, 'kasir') as peran_kasir,
    s.dibuka_pada,
    s.modal_awal,
    coalesce((
      select sum(pb.jumlah)
        from public.pembayaran pb
       where pb.shift_id = s.id
         and pb.jenis_saat_itu = 'tunai'
    ), 0)::bigint as tunai_masuk,
    -- PMB1-F-046: tanpa `greatest(0, …)` — kalau kas sebenarnya kurang dari
    -- modal awal + setoran, angkanya negatif dan itu justru yang harus terlihat
    -- (selisih negatif = uang hilang), bukan disembunyikan jadi nol.
    (s.modal_awal + coalesce((
        select sum(pb.jumlah)
          from public.pembayaran pb
         where pb.shift_id = s.id
           and pb.jenis_saat_itu = 'tunai'
      ), 0))::integer as uang_seharusnya,
    s.perlu_tutup_atasan,
    s.catatan_serah_terima
  from public.shift_kas s
  join public.cabang c on c.id = s.cabang_id
  left join public.pengguna u on u.id = s.dibuka_oleh
  where s.penyewa_id = v_penyewa
    and s.status = 'terbuka'
    and s.perlu_tutup_atasan = true
    and (p_cabang_id is null or s.cabang_id = p_cabang_id)
    and public.cabang_pantau_saya(s.cabang_id)
  order by s.dibuka_pada asc;
end;
$$;

create or replace function public.tutup_shift(
  p_uang_fisik      integer,
  p_alasan_selisih  text    default null,
  p_shift_id        uuid    default null,
  p_catatan         text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa               uuid;
  v_shift                 public.shift_kas%rowtype;
  v_penjualan_tunai       integer := 0;
  v_kas_masuk             integer := 0;
  v_kas_keluar            integer := 0;
  v_tunai_masuk           integer := 0;
  v_tunai_keluar          integer := 0;
  v_uang_seharusnya       integer;
  v_selisih               integer;
  v_alasan                text;
  v_hasil                 public.shift_kas%rowtype;
  v_melewati_tengah_malam boolean := false;
  v_ditutup_atasan        boolean := false;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- Validasi masukan uang fisik
  if p_uang_fisik is null or p_uang_fisik < 0 then
    raise exception 'Jumlah uang fisik wajib diisi dan tidak boleh negatif.';
  end if;

  -- Cari shift yang akan ditutup
  if p_shift_id is not null then
    select *
      into v_shift
      from public.shift_kas
     where id = p_shift_id
       and penyewa_id = v_penyewa
       for update;

    if v_shift.id is null then
      raise exception 'Shift kas tidak ditemukan.';
    end if;

    if v_shift.status <> 'terbuka' then
      raise exception 'Shift kas ini sudah ditutup sebelumnya.';
    end if;
  else
    -- Cari shift kasir aktif milik akun ini
    select *
      into v_shift
      from public.shift_kas
     where penyewa_id = v_penyewa
       and dibuka_oleh = auth.uid()
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1
     for update;

    -- Bila tidak ada shift yang dibuka sendiri, cari shift terbuka di cabang yang dipantau
    if v_shift.id is null then
      select *
        into v_shift
        from public.shift_kas
       where penyewa_id = v_penyewa
         and public.cabang_pantau_saya(cabang_id)
         and status = 'terbuka'
       order by dibuka_pada asc
       limit 1
       for update;
    end if;

    if v_shift.id is null then
      raise exception 'Tidak ada shift kas terbuka yang dapat ditutup.';
    end if;
  end if;

  -- Verifikasi izin tutup_kas di cabang shift bersangkutan
  if not public.boleh('tutup_kas', v_shift.cabang_id) then
    raise exception 'Peran % tidak berwenang menutup shift kas di cabang ini.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  -- Deteksi apakah ditutup oleh atasan/orang lain (T10-12 / T-013)
  v_ditutup_atasan := (auth.uid() is distinct from v_shift.dibuka_oleh);

  -- Kaitkan pembayaran tunai belum terikat yang terjadi di cabang selama rentang shift
  update public.pembayaran
     set shift_id = v_shift.id
   where shift_id is null
     and pesanan_id in (select id from public.pesanan where cabang_id = v_shift.cabang_id and penyewa_id = v_penyewa)
     and waktu >= v_shift.dibuka_pada
     and waktu <= now();

  -- Hitung penerimaan tunai dari pembayaran pesanan
  select coalesce(sum(jumlah), 0)
    into v_penjualan_tunai
    from public.pembayaran
   where shift_id = v_shift.id
     and jenis_saat_itu = 'tunai';

  -- Perhitungkan kas_pergerakan:
  if to_regclass('public.kas_pergerakan') is not null then
    -- Uang masuk (tambahan modal)
    select coalesce(sum(jumlah), 0)
      into v_kas_masuk
      from public.kas_pergerakan
     where shift_id = v_shift.id
       and jenis = 'masuk';

    -- Uang keluar (belanja mendadak, kasbon) & setoran
    select coalesce(sum(jumlah), 0)
      into v_kas_keluar
      from public.kas_pergerakan
     where shift_id = v_shift.id
       and jenis in ('keluar', 'setoran');
  end if;

  v_tunai_masuk := v_penjualan_tunai + v_kas_masuk;
  v_tunai_keluar := v_kas_keluar;

  -- Hitung uang seharusnya: modal_awal + tunai_masuk - tunai_keluar
  v_uang_seharusnya := v_shift.modal_awal + v_tunai_masuk - v_tunai_keluar;
  -- PMB1-F-046: nilai negatif TIDAK lagi dipaksa jadi 0 (lihat kepala berkas).

  -- Hitung selisih: fisik - seharusnya
  v_selisih := p_uang_fisik - v_uang_seharusnya;

  -- Validasi alasan selisih (DoD T7-02: bila selisih -> alasan wajib)
  v_alasan := btrim(coalesce(p_alasan_selisih, ''));
  if v_selisih <> 0 and v_alasan = '' then
    raise exception 'Alasan selisih wajib diisi jika uang fisik berbeda dari uang seharusnya.';
  end if;

  if v_alasan = '' then
    v_alasan := null;
  end if;

  -- Evaluasi apakah shift melewati tengah malam di zona waktu lokal Asia/Jakarta (T7-05)
  if timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', v_shift.dibuka_pada)::date then
    v_melewati_tengah_malam := true;
  end if;

  -- Tutup shift kas dan sinkronisasi penanda atasan (T10-12)
  update public.shift_kas
     set status = 'ditutup',
         ditutup_oleh = auth.uid(),
         ditutup_pada = now(),
         uang_seharusnya = v_uang_seharusnya,
         uang_fisik = p_uang_fisik,
         selisih = v_selisih,
         alasan_selisih = v_alasan,
         ditutup_oleh_atasan = v_ditutup_atasan,
         perlu_tutup_atasan = false,
         melewati_tengah_malam = (v_shift.melewati_tengah_malam or v_melewati_tengah_malam),
         catatan = case
           when p_catatan is not null and btrim(p_catatan) <> '' then btrim(p_catatan)
           else catatan
         end
   where id = v_shift.id
  returning * into v_hasil;

  -- Jejak audit berantai kriptografis (ART-6 / T1-13 / T10-12)
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  )
  values (
    v_penyewa,
    auth.uid(),
    'tutup_shift',
    'shift_kas',
    v_hasil.id,
    jsonb_build_object(
      'status', 'terbuka',
      'modal_awal', v_shift.modal_awal,
      'perlu_tutup_atasan', v_shift.perlu_tutup_atasan
    ),
    jsonb_build_object(
      'shift_id', v_hasil.id,
      'status', 'ditutup',
      'ditutup_oleh', auth.uid(),
      'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'ditutup_oleh_atasan', v_ditutup_atasan,
      'modal_awal', v_hasil.modal_awal,
      'penjualan_tunai', v_penjualan_tunai,
      'kas_masuk', v_kas_masuk,
      'kas_keluar', v_kas_keluar,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam,
      'catatan_serah_terima', v_hasil.catatan_serah_terima
    )
  );

  -- Jika shift melewati tengah malam, catat jejak audit khusus untuk laporan owner (T7-05)
  if v_melewati_tengah_malam then
    insert into public.catatan_audit (
      penyewa_id,
      pelaku_id,
      aksi,
      entitas,
      entitas_id,
      nilai_lama,
      nilai_baru
    )
    values (
      v_penyewa,
      auth.uid(),
      'shift_melewati_tengah_malam',
      'shift_kas',
      v_hasil.id,
      null,
      jsonb_build_object(
        'shift_id', v_hasil.id,
        'cabang_id', v_hasil.cabang_id,
        'dibuka_pada', to_char(v_hasil.dibuka_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'melewati_tengah_malam', true
      )
    );
  end if;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SH-200',
    'pesan', case
      when v_ditutup_atasan then 'Shift kas berhasil ditutup oleh atasan saat serah terima.'
      else 'Shift kas berhasil ditutup.'
    end,
    'data', jsonb_build_object(
      'shift_id', v_hasil.id,
      'cabang_id', v_hasil.cabang_id,
      'dibuka_oleh', v_hasil.dibuka_oleh,
      'ditutup_oleh', v_hasil.ditutup_oleh,
      'ditutup_oleh_atasan', v_hasil.ditutup_oleh_atasan,
      'dibuka_pada', v_hasil.dibuka_pada,
      'ditutup_pada', v_hasil.ditutup_pada,
      'modal_awal', v_hasil.modal_awal,
      'penjualan_tunai', v_penjualan_tunai,
      'kas_masuk', v_kas_masuk,
      'kas_keluar', v_kas_keluar,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam,
      'status', v_hasil.status,
      'catatan', v_hasil.catatan,
      'catatan_serah_terima', v_hasil.catatan_serah_terima
    )
  );
end;
$$;

comment on function public.tutup_shift(integer, text, uuid, text) is
  'Menutup shift kas. Angka uang sebaiknya boleh negatif (PMB1-F-046) sehingga kekurangan kas tidak lagi dipaksa menjadi nol dan selisihnya tetap wajib disertai alasan.';

revoke all on function public.tutup_shift(integer, text, uuid, text) from public;
grant execute on function public.tutup_shift(integer, text, uuid, text) to authenticated, service_role;
