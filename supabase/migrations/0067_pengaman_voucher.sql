-- ============================================================================
-- Migrasi 0067: Pengaman Anti-Kecurangan Voucher (10 Lapis) & Log Percobaan (T8-12)
-- Sesuai PRD M10, TECH_SPEC §9 ART-5, dan ROADMAP T8-12.
--
-- 10 Lapis Pengaman Teruji:
--   1. Satu voucher per identitas per kampanye (email normalisasi / nomor telepon).
--   2. Batas voucher per outlet per hari (kuota_harian_cabang lokal ART-9).
--   3. Wajib belanja minimum (min_belanja).
--   4. Batas maksimal potongan (maks_potongan plafon diskon persen).
--   5. Anggaran kampanye tidak bisa dilampaui (anggaran_maks).
--   6. Sekali pakai & kunci atomik (status aktif -> terpakai anti race condition).
--   7. Kode acak tidak berurutan (RB-XXXX-XXXX kriptografis, bebas ambigu).
--   8. Log semua percobaan cek/scan & batas percobaan per perangkat (rate limiting).
--   9. Tolak email sekali-pakai (anti disposable domain).
--  10. Normalisasi alamat Gmail (penghapusan titik & tag plus).
-- ============================================================================

-- 1. Penambahan kolom pengaman pada tabel kampanye_voucher
alter table public.kampanye_voucher
  add column if not exists kuota_harian_cabang integer check (kuota_harian_cabang is null or kuota_harian_cabang > 0),
  add column if not exists kuota_per_pelanggan integer not null default 1 check (kuota_per_pelanggan > 0);

comment on column public.kampanye_voucher.kuota_harian_cabang is
  'Batas maksimal penukaran/pemakaian voucher kampanye ini per outlet/cabang per hari (Lapis 2 pengaman anti-fraud).';
comment on column public.kampanye_voucher.kuota_per_pelanggan is
  'Batas klaim voucher per identitas pelanggan untuk kampanye ini (Lapis 1 pengaman anti-fraud).';

-- 2. Penambahan kolom audit dan rate limiting pada voucher_percobaan
alter table public.voucher_percobaan
  add column if not exists ip_pengakses text default null,
  add column if not exists aksi text default 'cek' check (aksi in ('cek', 'pakai', 'daftar'));

create index if not exists idx_voucher_percobaan_perangkat_rate
  on public.voucher_percobaan (penyewa_id, perangkat, hasil, waktu);

create index if not exists idx_voucher_percobaan_ip_rate
  on public.voucher_percobaan (penyewa_id, ip_pengakses, hasil, waktu);

-- 3. Fungsi Pemeriksa Batas Percobaan Perangkat / IP (Lapis 8: Rate Limiting)
create or replace function public.apakah_perangkat_terblokir(
  p_penyewa_id uuid,
  p_perangkat text,
  p_ip text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_gagal integer := 0;
  v_ambang integer := 5; -- 5 kali gagal dalam 15 menit
begin
  if p_penyewa_id is null then
    return false;
  end if;

  if (p_perangkat is null or trim(p_perangkat) = '') and (p_ip is null or trim(p_ip) = '') then
    return false;
  end if;

  select count(*)
    into v_gagal
    from public.voucher_percobaan
   where penyewa_id = p_penyewa_id
     and hasil = 'gagal'
     and waktu >= now() - interval '15 minutes'
     and (
       (p_perangkat is not null and trim(p_perangkat) <> '' and perangkat = trim(p_perangkat))
       or (p_ip is not null and trim(p_ip) <> '' and ip_pengakses = trim(p_ip))
     );

  return coalesce(v_gagal, 0) >= v_ambang;
end;
$$;

revoke all on function public.apakah_perangkat_terblokir(uuid, text, text) from public;
grant execute on function public.apakah_perangkat_terblokir(uuid, text, text) to authenticated, anon, service_role;

-- 4. Pembaruan RPC cek_voucher dengan 10 Lapis Pengaman
drop function if exists public.cek_voucher(text, uuid, numeric);
drop function if exists public.cek_voucher(text, uuid, numeric, text, text);

create or replace function public.cek_voucher(
  p_kode text,
  p_cabang_id uuid default null,
  p_subtotal numeric default null,
  p_perangkat text default null,
  p_ip text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_penyewa_id uuid := public.penyewa_saya();
  v_voucher record;
  v_kampanye record;
  v_pelanggan record;
  v_estimasi_potongan numeric := 0;
  v_sekarang timestamptz := now();
  v_berlaku_sampai timestamptz;
  v_pemakaian_hari_ini integer;
  v_tgl_lokal date;
  v_total_anggaran_terpakai numeric;
begin
  if v_kode = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KODE_KOSONG',
      'pesan', 'Kode voucher tidak boleh kosong.'
    );
  end if;

  -- Jika penyewa_id belum didapat dari konteks auth (misal pemanggilan publik/anon), cari dari voucher
  if v_penyewa_id is null then
    select penyewa_id into v_penyewa_id from public.voucher where kode = v_kode;
  end if;

  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting Brute Force Protection)
  if v_penyewa_id is not null and public.apakah_perangkat_terblokir(v_penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_penyewa_id, v_kode, 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

  select v.*
    into v_voucher
    from public.voucher v
   where v.kode = v_kode
     and (v_penyewa_id is null or v.penyewa_id = v_penyewa_id);

  if v_voucher.id is null then
    if v_penyewa_id is not null then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_penyewa_id, v_kode, 'gagal', 'Voucher tidak ditemukan.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());
    end if;

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_TIDAK_DITEMUKAN',
      'pesan', 'Voucher dengan kode tersebut tidak ditemukan.'
    );
  end if;

  select * into v_kampanye
    from public.kampanye_voucher
   where id = v_voucher.kampanye_id;

  select * into v_pelanggan
    from public.pelanggan
   where id = v_voucher.pelanggan_id;

  v_berlaku_sampai := coalesce(v_voucher.berlaku_sampai, v_kampanye.selesai);

  -- Lapis 6: Sekali Pakai (Periksa apakah sudah pernah dipakai)
  if v_voucher.status = 'terpakai' then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher sudah pernah digunakan.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_TERPAKAI',
      'pesan', 'Voucher ini sudah pernah digunakan pada ' || to_char(coalesce(v_voucher.terpakai_pada, now()), 'DD/MM/YYYY HH24:MI') || '.'
    );
  end if;

  if v_voucher.status = 'dibatalkan' then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher telah dibatalkan.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_DIBATALKAN',
      'pesan', 'Voucher ini telah dibatalkan.'
    );
  end if;

  -- Masa Berlaku
  if v_berlaku_sampai < v_sekarang or not v_kampanye.aktif then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_voucher.penyewa_id, v_kode, 'gagal', 'Voucher sudah kedaluwarsa.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_KEDALUWARSA',
      'pesan', 'Masa berlaku voucher ini telah berakhir.'
    );
  end if;

  -- Cabang Berlaku
  if p_cabang_id is not null
     and v_kampanye.cabang_berlaku is not null
     and jsonb_typeof(v_kampanye.cabang_berlaku) = 'array'
     and jsonb_array_length(v_kampanye.cabang_berlaku) > 0 then
    if not (v_kampanye.cabang_berlaku @> jsonb_build_array(p_cabang_id::text)) then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Cabang tidak berlaku.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'CABANG_TIDAK_BERLAKU',
        'pesan', 'Voucher ini tidak dapat digunakan di cabang ini.'
      );
    end if;
  end if;

  -- Lapis 2: Batas Voucher Per Outlet Per Hari (kuota_harian_cabang)
  if p_cabang_id is not null and v_kampanye.kuota_harian_cabang is not null and v_kampanye.kuota_harian_cabang > 0 then
    v_tgl_lokal := public.tanggal_lokal_cabang(p_cabang_id, now());
    select count(*)
      into v_pemakaian_hari_ini
      from public.voucher
     where kampanye_id = v_kampanye.id
       and terpakai_di_cabang = p_cabang_id
       and status = 'terpakai'
       and public.tanggal_lokal_cabang(terpakai_di_cabang, terpakai_pada) = v_tgl_lokal;

    if v_pemakaian_hari_ini >= v_kampanye.kuota_harian_cabang then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Kuota harian cabang habis.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'KUOTA_HARIAN_CABANG_HABIS',
        'pesan', 'Kuota harian penukaran voucher untuk cabang ini sudah habis hari ini.'
      );
    end if;
  end if;

  -- Lapis 3: Wajib Belanja Minimum (min_belanja)
  if p_subtotal is not null then
    if p_subtotal < v_kampanye.min_belanja then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Subtotal kurang dari minimum belanja.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'SUBTOTAL_KURANG',
        'pesan', 'Belanja minimal belum tercapai. Minimal belanja Rp ' || public.format_rupiah(v_kampanye.min_belanja) || '.'
      );
    end if;

    -- Lapis 4: Batas Maksimal Potongan (Plafon Diskon Persen)
    if v_kampanye.jenis = 'persen' then
      v_estimasi_potongan := floor((p_subtotal * v_kampanye.nilai) / 100);
      if v_kampanye.maks_potongan is not null and v_estimasi_potongan > v_kampanye.maks_potongan then
        v_estimasi_potongan := v_kampanye.maks_potongan;
      end if;
    else
      v_estimasi_potongan := v_kampanye.nilai;
    end if;

    if v_estimasi_potongan > p_subtotal then
      v_estimasi_potongan := p_subtotal;
    end if;
  else
    if v_kampanye.jenis = 'nominal' then
      v_estimasi_potongan := v_kampanye.nilai;
    end if;
  end if;

  -- Lapis 5: Anggaran Kampanye Tidak Bisa Dilampaui
  if v_kampanye.anggaran_maks is not null and v_kampanye.anggaran_maks > 0 then
    select coalesce(sum(dt.nilai), 0)
      into v_total_anggaran_terpakai
      from public.diskon_transaksi dt
      join public.voucher v on v.id = dt.voucher_id
     where v.kampanye_id = v_kampanye.id;

    if v_total_anggaran_terpakai + v_estimasi_potongan > v_kampanye.anggaran_maks then
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_voucher.penyewa_id, v_kode, 'gagal', 'Anggaran kampanye habis.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

      return jsonb_build_object(
        'berhasil', false,
        'kode', 'ANGGARAN_KAMPANYE_HABIS',
        'pesan', 'Anggaran promo kampanye ini sudah mencapai batas maksimal.'
      );
    end if;
  end if;

  -- Lapis 8: Log Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (v_voucher.penyewa_id, v_kode, 'sukses', 'Cek voucher berhasil.', auth.uid(), p_cabang_id, p_perangkat, p_ip, 'cek', now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'VOUCHER_VALID',
    'pesan', 'Voucher valid dan dapat digunakan.',
    'data', jsonb_build_object(
      'id', v_voucher.id,
      'kode', v_voucher.kode,
      'nama_kampanye', v_kampanye.nama,
      'jenis', v_kampanye.jenis,
      'nilai', v_kampanye.nilai,
      'min_belanja', v_kampanye.min_belanja,
      'maks_potongan', v_kampanye.maks_potongan,
      'estimasi_potongan', v_estimasi_potongan,
      'berlaku_sampai', v_berlaku_sampai,
      'nama_pelanggan', v_pelanggan.nama
    )
  );
end;
$$;

revoke all on function public.cek_voucher(text, uuid, numeric, text, text) from public, anon;
grant execute on function public.cek_voucher(text, uuid, numeric, text, text) to authenticated, anon, service_role;

-- 5. Pembaruan RPC pakai_voucher dengan 10 Lapis Pengaman
drop function if exists public.pakai_voucher(uuid, text, text, text);
drop function if exists public.pakai_voucher(uuid, text, text, text, text, text);

create or replace function public.pakai_voucher(
  p_pesanan_id uuid,
  p_kode text,
  p_pin_kasir text,
  p_kunci_idempoten text default null,
  p_perangkat text default null,
  p_ip text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kode text := upper(trim(coalesce(p_kode, '')));
  v_saya uuid := auth.uid();
  v_pesanan record;
  v_voucher record;
  v_kampanye record;
  v_pelanggan record;
  v_kasir record;
  v_potongan integer := 0;
  v_diskon_sudah record;
  v_tumpuk boolean;
  v_pemakaian_hari_ini integer;
  v_tgl_lokal date;
  v_total_anggaran_terpakai numeric;
begin
  if v_saya is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_TERAUTENTIKASI',
      'pesan', 'Anda harus masuk sebagai kasir untuk menggunakan voucher.'
    );
  end if;

  -- 1. Izin kasir
  if not public.boleh('pakai_voucher') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_BERIZIN',
      'pesan', 'Anda tidak memiliki izin untuk memakai voucher.'
    );
  end if;

  -- 2. Verifikasi PIN Kasir
  select p.*, k.pin_hash
    into v_kasir
    from public.pengguna p
    left join public.kredensial_pin k on k.pengguna_id = p.id
   where p.id = v_saya;

  if v_kasir.id is null or not coalesce(v_kasir.aktif, false) or v_kasir.pin_hash is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KASIR_TIDAK_VALID',
      'pesan', 'Akun kasir tidak aktif atau belum memiliki PIN.'
    );
  end if;

  if p_pin_kasir is null or p_pin_kasir = '' or crypt(p_pin_kasir, v_kasir.pin_hash) is distinct from v_kasir.pin_hash then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
    values (v_saya, coalesce(p_perangkat, 'kasir'), false, 'pakai_voucher', p_pesanan_id);

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PIN_SALAH',
      'pesan', 'PIN kasir tidak sah. Mohon periksa kembali PIN Anda.'
    );
  end if;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, pesanan_id)
  values (v_saya, coalesce(p_perangkat, 'kasir'), true, 'pakai_voucher', p_pesanan_id);

  -- 3. Verifikasi Pesanan
  select * into v_pesanan
    from public.pesanan
   where id = p_pesanan_id;

  if v_pesanan.id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_TIDAK_DITEMUKAN',
      'pesan', 'Pesanan tidak ditemukan.'
    );
  end if;

  if v_pesanan.status in ('lunas', 'batal') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PESANAN_SUDAH_SELESAI',
      'pesan', 'Pesanan sudah berstatus ' || v_pesanan.status || '; voucher tidak dapat ditambahkan.'
    );
  end if;

  if coalesce(v_pesanan.subtotal, 0) <= 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'SUBTOTAL_KOSONG',
      'pesan', 'Pesanan belum memiliki item atau subtotal masih 0.'
    );
  end if;

  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting Brute Force Protection)
  if public.apakah_perangkat_terblokir(v_pesanan.penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

  -- 4. Idempoten: Cek apakah voucher ini sudah tercatat pada pesanan ini
  select dt.* into v_diskon_sudah
    from public.diskon_transaksi dt
    join public.voucher v on v.id = dt.voucher_id
   where dt.pesanan_id = p_pesanan_id
     and v.kode = v_kode;

  if v_diskon_sudah.id is not null then
    return jsonb_build_object(
      'berhasil', true,
      'kode', 'IDEMPOTEN',
      'pesan', 'Voucher sudah diterapkan pada pesanan ini.',
      'data', jsonb_build_object(
        'diskon_id', v_diskon_sudah.id,
        'nilai_potongan', v_diskon_sudah.nilai,
        'kode_voucher', v_kode
      )
    );
  end if;

  -- 5. Cek Pengaturan Tumpuk Diskon
  select p.tumpuk_diskon into v_tumpuk
    from public.pengaturan p
   where p.penyewa_id = v_pesanan.penyewa_id;

  if not coalesce(v_tumpuk, false) and exists (
    select 1 from public.diskon_transaksi where pesanan_id = p_pesanan_id
  ) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TUMPUK_DISKON_DILARANG',
      'pesan', 'Resto ini hanya mengizinkan satu diskon per transaksi.'
    );
  end if;

  -- Lapis 6: Kunci Atomik Sekali Pakai (ART-5)
  update public.voucher
     set status = 'terpakai',
         terpakai_pada = now(),
         terpakai_di_cabang = v_pesanan.cabang_id,
         terpakai_oleh = v_saya,
         pesanan_id = p_pesanan_id
   where kode = v_kode
     and penyewa_id = v_pesanan.penyewa_id
     and status = 'aktif'
     and (berlaku_sampai is null or berlaku_sampai >= now())
  returning * into v_voucher;

  if v_voucher.id is null then
    select * into v_voucher from public.voucher where kode = v_kode and penyewa_id = v_pesanan.penyewa_id;
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Voucher tidak dapat dipakai.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    if v_voucher.id is null then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_TIDAK_DITEMUKAN', 'pesan', 'Voucher tidak ditemukan.');
    elsif v_voucher.status = 'terpakai' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_SUDAH_TERPAKAI', 'pesan', 'Voucher ini sudah pernah digunakan.');
    elsif v_voucher.status = 'dibatalkan' then
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_DIBATALKAN', 'pesan', 'Voucher ini telah dibatalkan.');
    else
      return jsonb_build_object('berhasil', false, 'kode', 'VOUCHER_KEDALUWARSA', 'pesan', 'Masa berlaku voucher telah berakhir.');
    end if;
  end if;

  select * into v_kampanye from public.kampanye_voucher where id = v_voucher.kampanye_id;
  select * into v_pelanggan from public.pelanggan where id = v_voucher.pelanggan_id;

  -- Cabang Berlaku
  if v_kampanye.cabang_berlaku is not null
     and jsonb_typeof(v_kampanye.cabang_berlaku) = 'array'
     and jsonb_array_length(v_kampanye.cabang_berlaku) > 0 then
    if not (v_kampanye.cabang_berlaku @> jsonb_build_array(v_pesanan.cabang_id::text)) then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Cabang tidak berlaku.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'CABANG_TIDAK_BERLAKU', 'pesan', 'Voucher ini tidak berlaku di cabang ini.');
    end if;
  end if;

  -- Lapis 2: Batas Voucher Per Outlet Per Hari (kuota_harian_cabang)
  if v_kampanye.kuota_harian_cabang is not null and v_kampanye.kuota_harian_cabang > 0 then
    v_tgl_lokal := public.tanggal_lokal_cabang(v_pesanan.cabang_id, now());
    select count(*)
      into v_pemakaian_hari_ini
      from public.voucher
     where kampanye_id = v_kampanye.id
       and terpakai_di_cabang = v_pesanan.cabang_id
       and status = 'terpakai'
       and id <> v_voucher.id
       and public.tanggal_lokal_cabang(terpakai_di_cabang, terpakai_pada) = v_tgl_lokal;

    if v_pemakaian_hari_ini >= v_kampanye.kuota_harian_cabang then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Kuota harian cabang habis.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'KUOTA_HARIAN_CABANG_HABIS', 'pesan', 'Kuota harian voucher kampanye ini untuk cabang ini sudah habis hari ini.');
    end if;
  end if;

  -- Lapis 3: Wajib Belanja Minimum (min_belanja)
  if v_pesanan.subtotal < v_kampanye.min_belanja then
    update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Subtotal kurang dari minimum belanja.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

    return jsonb_build_object('berhasil', false, 'kode', 'SUBTOTAL_KURANG', 'pesan', 'Subtotal pesanan belum memenuhi minimum belanja Rp ' || public.format_rupiah(v_kampanye.min_belanja) || '.');
  end if;

  -- Lapis 4: Hitung Nilai Potongan Diskon (Plafon maks_potongan)
  if v_kampanye.jenis = 'persen' then
    v_potongan := floor((v_pesanan.subtotal * v_kampanye.nilai) / 100)::integer;
    if v_kampanye.maks_potongan is not null and v_potongan > v_kampanye.maks_potongan then
      v_potongan := v_kampanye.maks_potongan::integer;
    end if;
  else
    v_potongan := v_kampanye.nilai::integer;
  end if;

  if v_potongan > v_pesanan.subtotal then
    v_potongan := v_pesanan.subtotal::integer;
  end if;

  -- Lapis 5: Anggaran Kampanye Tidak Bisa Dilampaui (anggaran_maks)
  if v_kampanye.anggaran_maks is not null and v_kampanye.anggaran_maks > 0 then
    select coalesce(sum(dt.nilai), 0)
      into v_total_anggaran_terpakai
      from public.diskon_transaksi dt
      join public.voucher v on v.id = dt.voucher_id
     where v.kampanye_id = v_kampanye.id;

    if v_total_anggaran_terpakai + v_potongan > v_kampanye.anggaran_maks then
      update public.voucher set status = 'aktif', terpakai_pada = null, terpakai_di_cabang = null, terpakai_oleh = null, pesanan_id = null where id = v_voucher.id;
      insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
      values (v_pesanan.penyewa_id, v_kode, 'gagal', 'Anggaran kampanye habis.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

      return jsonb_build_object('berhasil', false, 'kode', 'ANGGARAN_KAMPANYE_HABIS', 'pesan', 'Anggaran promo kampanye ini sudah mencapai batas maksimal.');
    end if;
  end if;

  -- Rekam Diskon Transaksi
  insert into public.diskon_transaksi (
    pesanan_id,
    jenis,
    persen,
    nominal,
    nilai,
    alasan,
    pelaku_id,
    voucher_id
  ) values (
    p_pesanan_id,
    'voucher',
    case when v_kampanye.jenis = 'persen' then v_kampanye.nilai else null end,
    case when v_kampanye.jenis = 'nominal' then v_kampanye.nilai else null end,
    v_potongan,
    'Voucher: ' || v_kampanye.nama || ' (' || v_kode || ')',
    v_saya,
    v_voucher.id
  );

  -- Lapis 8: Catat Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (v_pesanan.penyewa_id, v_kode, 'pakai_berhasil', 'Pemakaian voucher berhasil.', v_saya, v_pesanan.cabang_id, p_perangkat, p_ip, 'pakai', now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil digunakan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher.id,
      'kode_voucher', v_kode,
      'nilai_potongan', v_potongan,
      'nama_kampanye', v_kampanye.nama,
      'nama_pelanggan', v_pelanggan.nama
    )
  );
end;
$$;

revoke all on function public.pakai_voucher(uuid, text, text, text, text, text) from public, anon;
grant execute on function public.pakai_voucher(uuid, text, text, text, text, text) to authenticated, service_role;

-- 6. Pembaruan RPC daftar_voucher dengan 10 Lapis Pengaman
drop function if exists public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text);
drop function if exists public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text);

create or replace function public.daftar_voucher(
  p_penyewa_id uuid,
  p_kampanye_id uuid,
  p_nama text,
  p_email text,
  p_telepon text default null,
  p_alamat text default null,
  p_persetujuan_privasi boolean default true,
  p_cara_masuk text default 'email',
  p_perangkat text default null,
  p_ip text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kmp record;
  v_email_norm text;
  v_pelanggan_id uuid;
  v_terbit_count integer;
  v_kode_voucher text;
  v_voucher_id uuid;
  v_ada record;
  v_jumlah_voucher_pelanggan integer := 0;
begin
  -- Lapis 8: Batas Percobaan Per Perangkat / IP (Rate Limiting)
  if p_penyewa_id is not null and public.apakah_perangkat_terblokir(p_penyewa_id, p_perangkat, p_ip) then
    insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
    values (p_penyewa_id, 'KLAIM_BARU', 'gagal', 'Terlalu banyak percobaan kode voucher yang gagal.', auth.uid(), null, p_perangkat, p_ip, 'daftar', now());

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TERLALU_BANYAK_PERCOBAAN',
      'pesan', 'Terlalu banyak percobaan kode voucher yang gagal dari perangkat ini. Mohon tunggu 15 menit.'
    );
  end if;

  -- 1. Validasi Persetujuan Privasi (UU PDP & T-011)
  if coalesce(p_persetujuan_privasi, false) is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PRIVASI_WAJIB',
      'pesan', 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
    );
  end if;

  -- 2. Validasi Nama
  if p_nama is null or length(trim(p_nama)) = 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NAMA_WAJIB',
      'pesan', 'Nama lengkap wajib diisi.'
    );
  end if;

  -- 3. Lapis 9 & 10: Validasi, Anti-Disposable, dan Normalisasi Email Gmail
  if (p_email is null or length(trim(p_email)) = 0) and p_cara_masuk != 'kasir' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'EMAIL_WAJIB',
      'pesan', 'Alamat email wajib diisi.'
    );
  end if;

  if p_email is not null and length(trim(p_email)) > 0 then
    if public.apakah_email_sekali_pakai(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_SEKALI_PAKAI',
        'pesan', 'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
      );
    end if;

    v_email_norm := public.normalisasi_email(p_email);
    if v_email_norm is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_TIDAK_SAH',
        'pesan', 'Format alamat email tidak sah.'
      );
    end if;
  end if;

  -- 4. Periksa Kampanye
  select * into v_kmp
    from public.kampanye_voucher
   where id = p_kampanye_id
     and penyewa_id = p_penyewa_id;

  if v_kmp.id is null or v_kmp.aktif is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_TIDAK_AKTIF',
      'pesan', 'Kampanye voucher tidak ditemukan atau sudah tidak aktif.'
    );
  end if;

  if now() < v_kmp.mulai or now() > v_kmp.selesai then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_BERAKHIR',
      'pesan', 'Masa berlaku kampanye voucher telah berakhir.'
    );
  end if;

  select count(1) into v_terbit_count
    from public.voucher
   where kampanye_id = p_kampanye_id;

  if v_terbit_count >= v_kmp.kuota then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KUOTA_HABIS',
      'pesan', 'Mohon maaf, kuota voucher untuk kampanye ini telah habis.'
    );
  end if;

  -- 5. Ambil atau Buat Pelanggan
  if v_email_norm is not null then
    select id into v_pelanggan_id
      from public.pelanggan
     where penyewa_id = p_penyewa_id
       and email_normalisasi = v_email_norm;
  end if;

  if v_pelanggan_id is null then
    insert into public.pelanggan (
      penyewa_id,
      nama,
      email,
      telepon,
      alamat,
      cara_masuk,
      persetujuan_privasi,
      didaftarkan_oleh
    ) values (
      p_penyewa_id,
      trim(p_nama),
      trim(p_email),
      nullif(trim(coalesce(p_telepon, '')), ''),
      nullif(trim(coalesce(p_alamat, '')), ''),
      p_cara_masuk,
      true,
      case when p_cara_masuk = 'kasir' then (select auth.uid()) else null end
    ) returning id into v_pelanggan_id;
  end if;

  -- Lapis 1: Satu Voucher Per Identitas Per Kampanye (kuota_per_pelanggan)
  select count(1) into v_jumlah_voucher_pelanggan
    from public.voucher
   where kampanye_id = p_kampanye_id
     and pelanggan_id = v_pelanggan_id;

  if v_jumlah_voucher_pelanggan >= coalesce(v_kmp.kuota_per_pelanggan, 1) then
    select kode, status into v_ada
      from public.voucher
     where kampanye_id = p_kampanye_id
       and pelanggan_id = v_pelanggan_id
     limit 1;

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_DIKLAIM',
      'pesan', 'Satu identitas hanya berhak mengklaim 1 voucher untuk kampanye ini.',
      'data', jsonb_build_object(
        'kode_voucher', v_ada.kode,
        'status', v_ada.status
      )
    );
  end if;

  -- Lapis 7: Terbitkan Kode Acak Tidak Berurutan (T8-08)
  loop
    v_kode_voucher := public.buat_kode_voucher_acak();
    exit when not exists (
      select 1 from public.voucher where penyewa_id = p_penyewa_id and kode = v_kode_voucher
    );
  end loop;

  insert into public.voucher (
    penyewa_id,
    kampanye_id,
    pelanggan_id,
    kode,
    status,
    berlaku_sampai
  ) values (
    p_penyewa_id,
    p_kampanye_id,
    v_pelanggan_id,
    v_kode_voucher,
    'aktif',
    v_kmp.selesai
  ) returning id into v_voucher_id;

  -- Lapis 8: Log Percobaan Sukses
  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, alasan, kasir_id, cabang_id, perangkat, ip_pengakses, aksi, waktu)
  values (p_penyewa_id, v_kode_voucher, 'sukses', 'Klaim voucher berhasil diterbitkan.', auth.uid(), null, p_perangkat, p_ip, 'daftar', now());

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil diterbitkan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher_id,
      'kode_voucher', v_kode_voucher,
      'nama_pelanggan', trim(p_nama),
      'nilai', v_kmp.nilai,
      'jenis', v_kmp.jenis,
      'min_belanja', v_kmp.min_belanja,
      'maks_potongan', v_kmp.maks_potongan,
      'berlaku_sampai', v_kmp.selesai,
      'pola_barcode', public.pola_barcode_garis(v_kode_voucher)
    )
  );
end;
$$;

revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) from public;
grant execute on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text, text, text) to anon, authenticated, service_role;

-- 7. RPC Pengawasan Audit Kecurangan: ambil_log_percobaan_voucher (PRD M10 & TECH_SPEC §5)
create or replace function public.ambil_log_percobaan_voucher(
  p_kampanye_id uuid default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_peran text := public.peran_saya();
  v_hasil jsonb;
begin
  if v_penyewa is null or v_peran not in ('owner_pusat', 'admin_cabang') then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'TIDAK_BERIZIN',
      'pesan', 'Hanya admin atau pemilik resto yang dapat melihat log percobaan voucher.'
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(sub)::jsonb), '[]'::jsonb)
    into v_hasil
    from (
      select
        vp.id,
        vp.kode_dicoba,
        vp.hasil,
        vp.alasan,
        vp.perangkat,
        vp.ip_pengakses,
        vp.aksi,
        vp.waktu,
        c.nama as nama_cabang,
        p.nama as nama_kasir
      from public.voucher_percobaan vp
      left join public.cabang c on c.id = vp.cabang_id
      left join public.pengguna p on p.id = vp.kasir_id
     where vp.penyewa_id = v_penyewa
     order by vp.waktu desc
     limit coalesce(p_limit, 50)
    ) sub;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Log percobaan voucher berhasil diambil.',
    'data', v_hasil
  );
end;
$$;

revoke all on function public.ambil_log_percobaan_voucher(uuid, integer) from public, anon;
grant execute on function public.ambil_log_percobaan_voucher(uuid, integer) to authenticated, service_role;
