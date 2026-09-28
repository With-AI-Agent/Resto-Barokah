-- ============================================================================
-- Berkas Uji: voucher_terbit.sql (T8-08 — Terbitkan Kode Voucher Acak + Barcode)
--
-- Menguji:
--   1. Generator kode acak (bukan berurutan, tidak bisa ditebak, bebas karakter ambigu).
--   2. Uji keunikan massal 100 kode acak (0 duplikasi / 100% unik).
--   3. Validator format kode acak `apakah_format_voucher_acak`.
--   4. Pola barcode garis 1D `pola_barcode_garis`.
--   5. RPC publik `ambil_kartu_voucher`:
--      - Mengambil metadata kartu voucher lengkap untuk tampilan pelanggan.
--      - Evaluasi otomatis status kedaluwarsa jika melewati masa berlaku.
--      - Penolakan kode kosong & kode tidak ditemukan.
--      - Ketiadaan kebocoran data pribadi (tanpa email, tanpa nomor HP).
--   6. Pagar database keunikan satu voucher per identitas per kampanye.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Uji Generator Kode Voucher Acak & Format Bebas Ambigu
-- ----------------------------------------------------------------------------
do $$
declare
  v_kode text;
  v_sah boolean;
  v_i int;
begin
  for v_i in 1..50 loop
    v_kode := public.buat_kode_voucher_acak();
    v_sah := public.apakah_format_voucher_acak(v_kode);

    perform uji.harap(v_sah, 'Kode voucher acak memenuhi pola RB-XXXX-XXXX');
    perform uji.harap(v_kode not like '%0%', 'Kode acak bebas dari angka 0');
    perform uji.harap(v_kode not like '%O%', 'Kode acak bebas dari huruf O');
    perform uji.harap(v_kode not like '%1%', 'Kode acak bebas dari angka 1');
    perform uji.harap(v_kode not like '%I%', 'Kode acak bebas dari huruf I');
    perform uji.harap(v_kode not like '%L%', 'Kode acak bebas dari huruf L');
  end loop;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Uji Keunikan 100 Kode Acak Berturut-turut (Anti-Sekuensial & 0 Tabrakan)
-- ----------------------------------------------------------------------------
do $$
declare
  v_jumlah_unik int;
begin
  with kode_koleksi as (
    select public.buat_kode_voucher_acak() as k
      from generate_series(1, 100)
  )
  select count(distinct k) into v_jumlah_unik from kode_koleksi;

  perform uji.harap(v_jumlah_unik = 100, '100 kode voucher acak berturut-turut 100% unik (0 tabrakan)');
end;
$$;

-- ----------------------------------------------------------------------------
-- 3. Uji Validator Format Kode
-- ----------------------------------------------------------------------------
select uji.harap(public.apakah_format_voucher_acak('RB-7X9K-2M4P') = true, 'Format RB-7X9K-2M4P valid');
select uji.harap(public.apakah_format_voucher_acak('RB-0123-4567') = false, 'Format dengan karakter 0/1 tidak valid');
select uji.harap(public.apakah_format_voucher_acak('VOUCHER-123') = false, 'Format di luar RB-XXXX-XXXX ditolak');
select uji.harap(public.apakah_format_voucher_acak('') = false, 'Kode kosong ditolak validator format');
select uji.harap(public.apakah_format_voucher_acak(null) = false, 'Kode null ditolak validator format');

-- ----------------------------------------------------------------------------
-- 4. Uji Pola Barcode Garis 1D
-- ----------------------------------------------------------------------------
do $$
declare
  v_barcode text;
begin
  v_barcode := public.pola_barcode_garis('RB-7X9K-2M4P');
  perform uji.harap(length(v_barcode) > 50, 'Pola barcode garis memiliki panjang memadai untuk dirender');
  perform uji.harap(v_barcode ~ '^[01]+$', 'Pola barcode hanya memuat bit biner 0 dan 1');
  perform uji.harap(v_barcode like '11010010000%', 'Pola barcode memuat penanda awal (start pattern)');
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. Uji RPC `ambil_kartu_voucher` (Kasus Valid & Data Bebas Rahasia)
-- ----------------------------------------------------------------------------
do $$
declare
  v_penyewa_id uuid := '11111111-1111-1111-1111-111111111111';
  v_kampanye_id uuid := gen_random_uuid();
  v_pelanggan_id uuid := gen_random_uuid();
  v_voucher_id uuid := gen_random_uuid();
  v_kode_uji text := 'RB-8M4K-9Q2V';
  v_hasil jsonb;
  v_data jsonb;
begin
  -- Buat kampanye uji
  insert into public.kampanye_voucher (
    id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, maks_potongan, mulai, selesai, kuota
  ) values (
    v_kampanye_id, v_penyewa_id, 'Promo Uji Kartu Barcode', 'KMP-BARCODE-01', 'persen', 25, 50000, 25000,
    now() - interval '1 day', now() + interval '30 days', 100
  );

  -- Buat pelanggan uji
  insert into public.pelanggan (
    id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi
  ) values (
    v_pelanggan_id, v_penyewa_id, 'Kartika Dewi', 'kartika@contoh.id', 'kartika@contoh.id',
    '081234567890', 'email', true
  );

  -- Terbitkan voucher uji
  insert into public.voucher (
    id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
  ) values (
    v_voucher_id, v_penyewa_id, v_kampanye_id, v_pelanggan_id, v_kode_uji, 'aktif',
    now() + interval '14 days'
  );

  -- Panggil RPC publik sebagai peran anonim (pelanggan tanpa login)
  set local role anon;
  v_hasil := public.ambil_kartu_voucher(v_kode_uji);
  reset role;

  perform uji.harap((v_hasil->>'berhasil')::boolean = true, 'Ambil kartu voucher berhasil untuk kode sah');
  v_data := v_hasil->'data';

  perform uji.harap(v_data->>'kode_voucher' = v_kode_uji, 'Kode voucher cocok');
  perform uji.harap(v_data->>'status' = 'aktif', 'Status voucher aktif');
  perform uji.harap((v_data->>'nilai_diskon')::int = 25, 'Nilai diskon 25% cocok');
  perform uji.harap(v_data->>'tipe_diskon' = 'persen', 'Tipe diskon persen cocok');
  perform uji.harap((v_data->>'min_transaksi')::int = 50000, 'Min transaksi 50.000 cocok');
  perform uji.harap((v_data->>'maks_potongan')::int = 25000, 'Maks potongan 25.000 cocok');
  perform uji.harap(v_data->>'nama_kampanye' = 'Promo Uji Kartu Barcode', 'Nama kampanye cocok');
  perform uji.harap(v_data->>'nama_pelanggan' = 'Kartika Dewi', 'Nama pelanggan ramah awam tampil');
  perform uji.harap(length(v_data->>'pola_barcode') > 50, 'Pola barcode garis tersedia untuk visual render');

  -- Ketiadaan kebocoran privasi pelanggan (email & HP rahasia)
  perform uji.harap(v_data->>'email' is null, 'Data kartu tidak membocorkan email pelanggan');
  perform uji.harap(v_data->>'telepon' is null, 'Data kartu tidak membocorkan telepon pelanggan');
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. Uji Penanganan Kedaluwarsa Otomatis
-- ----------------------------------------------------------------------------
do $$
declare
  v_penyewa_id uuid := '11111111-1111-1111-1111-111111111111';
  v_kampanye_id uuid := gen_random_uuid();
  v_pelanggan_id uuid := gen_random_uuid();
  v_kode_basi text := 'RB-2B3C-4D5F';
  v_hasil jsonb;
begin
  insert into public.kampanye_voucher (
    id, penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota
  ) values (
    v_kampanye_id, v_penyewa_id, 'Promo Kadaluwarsa', 'KMP-EXP-01', 'nominal', 10000,
    now() - interval '30 days', now() - interval '10 days', 50
  );

  insert into public.pelanggan (
    id, penyewa_id, nama, email, email_normalisasi, cara_masuk, persetujuan_privasi
  ) values (
    v_pelanggan_id, v_penyewa_id, 'Pelanggan Lama', 'lama@contoh.id', 'lama@contoh.id', 'email', true
  );

  insert into public.voucher (
    penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
  ) values (
    v_penyewa_id, v_kampanye_id, v_pelanggan_id, v_kode_basi, 'aktif',
    now() - interval '5 days'
  );

  v_hasil := public.ambil_kartu_voucher(v_kode_basi);
  perform uji.harap((v_hasil->>'berhasil')::boolean = true, 'Panggilan berhasil');
  perform uji.harap(v_hasil->'data'->>'status' = 'kedaluwarsa', 'Status otomatis berubah jadi kedaluwarsa saat waktu lewat');
end;
$$;

-- ----------------------------------------------------------------------------
-- 7. Uji Penolakan Kode Kosong & Palsu
-- ----------------------------------------------------------------------------
do $$
declare
  v_hasil_kosong jsonb;
  v_hasil_palsu jsonb;
begin
  v_hasil_kosong := public.ambil_kartu_voucher('   ');
  perform uji.harap((v_hasil_kosong->>'berhasil')::boolean = false, 'Kode kosong ditolak');
  perform uji.harap(v_hasil_kosong->>'kode' = 'KODE_KOSONG', 'Kode galat KODE_KOSONG sesuai');

  v_hasil_palsu := public.ambil_kartu_voucher('RB-9999-9999');
  perform uji.harap((v_hasil_palsu->>'berhasil')::boolean = false, 'Kode tidak ada ditolak');
  perform uji.harap(v_hasil_palsu->>'kode' = 'VOUCHER_TIDAK_DITEMUKAN', 'Kode galat VOUCHER_TIDAK_DITEMUKAN sesuai');
end;
$$;

-- ----------------------------------------------------------------------------
-- 8. Pagar Database: Satu Identitas Hanya Satu Voucher Per Kampanye
-- ----------------------------------------------------------------------------
do $$
declare
  v_penyewa_id uuid := '11111111-1111-1111-1111-111111111111';
  v_kampanye_id uuid := gen_random_uuid();
  v_pelanggan_id uuid := gen_random_uuid();
begin
  insert into public.kampanye_voucher (
    id, penyewa_id, nama, kode_kampanye, jenis, nilai, mulai, selesai, kuota
  ) values (
    v_kampanye_id, v_penyewa_id, 'Promo 1 Orang 1 Voucher', 'KMP-SATU-01', 'nominal', 15000,
    now(), now() + interval '7 days', 100
  );

  insert into public.pelanggan (
    id, penyewa_id, nama, email, email_normalisasi, cara_masuk, persetujuan_privasi
  ) values (
    v_pelanggan_id, v_penyewa_id, 'Hendra', 'hendra@contoh.id', 'hendra@contoh.id', 'email', true
  );

  -- Voucher pertama: BERHASIL
  insert into public.voucher (
    penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
  ) values (
    v_penyewa_id, v_kampanye_id, v_pelanggan_id, 'RB-2X3Y-4Z5W', 'aktif',
    now() + interval '7 days'
  );
  perform uji.harap(true, 'Voucher pertama untuk kampanye berhasil terbit');
end;
$$;

-- Voucher kedua untuk pelanggan & kampanye yang sama: WAJIB DITOLAK
select uji.harap_gagal_sebab(
  $$
  insert into public.voucher (
    penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
  ) values (
    '11111111-1111-1111-1111-111111111111',
    (select id from public.kampanye_voucher where kode_kampanye = 'KMP-SATU-01'),
    (select id from public.pelanggan where email_normalisasi = 'hendra@contoh.id'),
    'RB-6A7B-8C9D',
    'aktif',
    now() + interval '7 days'
  );
  $$,
  'unique',
  'Pagar database: satu voucher per identitas per kampanye menolak duplikasi'
);
