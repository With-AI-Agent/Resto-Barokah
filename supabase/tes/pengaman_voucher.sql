-- ============================================================================
-- Uji SQL: Pengaman Anti-Kecurangan Voucher 10 Lapis & Log Percobaan (T8-12)
-- Sesuai PRD M10, TECH_SPEC §9 ART-5, dan ROADMAP T8-12.
--
-- Menguji 10 Lapis Pengaman Anti-Fraud:
--   Lapis 1 : 1 voucher per identitas per kampanye (penolakan klaim berulang).
--   Lapis 2 : Batas penukaran voucher per outlet per hari (kuota_harian_cabang).
--   Lapis 3 : Wajib belanja minimum (min_belanja).
--   Lapis 4 : Batas maksimal potongan (maks_potongan plafon diskon persen).
--   Lapis 5 : Anggaran kampanye tidak bisa dilampaui (anggaran_maks).
--   Lapis 6 : Sekali pakai & kunci atomik (status terpakai anti dobel cair).
--   Lapis 7 : Kode acak tidak berurutan (format kriptografis RB-XXXX-XXXX).
--   Lapis 8 : Log semua cek/scan & batas percobaan per perangkat (rate limiting).
--   Lapis 9 : Tolak email sekali-pakai (anti disposable email).
--   Lapis 10: Normalisasi alamat Gmail (anti alias titik dan tag plus).
-- ============================================================================

begin;

-- Siapkan Kredensial PIN & Izin Kasir Rina (90000000-0000-0000-0000-000000000004)
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('123456', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('123456', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

-- Pastikan pengaturan resto: tumpuk_diskon default false (PRD M10 ART-5)
update public.pengaturan
   set tumpuk_diskon = false,
       batas_maks_potongan_persen = 100,
       batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- ----------------------------------------------------------------------------
-- SETUP KAMPANYE UJI
-- ----------------------------------------------------------------------------

-- Kampanye K1: Diskon 20%, min 50rb, maks 15rb, kuota 100, anggaran 30rb, kuota_harian_cabang 1
insert into public.kampanye_voucher (
  id,
  penyewa_id,
  nama,
  kode_kampanye,
  jenis,
  nilai,
  min_belanja,
  maks_potongan,
  mulai,
  selesai,
  kuota,
  anggaran_maks,
  kuota_harian_cabang,
  kuota_per_pelanggan,
  cabang_berlaku,
  aktif
) values (
  'c8100000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'Promo Super Hemat 20%',
  'HEMAT20',
  'persen',
  20,
  50000,
  15000,
  now() - interval '1 hour',
  now() + interval '30 days',
  100,
  30000, -- Anggaran ketat 30.000 (cukup untuk 2 voucher @15rb)
  1,     -- Batas harian per cabang: 1 voucher per hari!
  1,     -- 1 voucher per pelanggan
  '[]'::jsonb,
  true
) on conflict (id) do update set kuota_harian_cabang = 1, anggaran_maks = 30000;

-- ----------------------------------------------------------------------------
-- LAPIS 9 & 10: Tolak Email Sekali-Pakai & Normalisasi Gmail
-- ----------------------------------------------------------------------------

-- Lapis 9: Tolak email sekali-pakai
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'EMAIL_SEKALI_PAKAI'
      from public.daftar_voucher(
        '11111111-1111-1111-1111-111111111111',
        'c8100000-0000-0000-0000-000000000001',
        'Bot Jahat',
        'spammer@tempmail.com',
        '0899001122',
        null,
        true,
        'email',
        'perangkat-bot-1',
        '10.0.0.1'
      ) as hasil
  ),
  'T8-12 Lapis 9: Mendaftar dengan domain email sekali-pakai ditolak (EMAIL_SEKALI_PAKAI)'
);

-- Lapis 10: Klaim pertama pelanggan Gmail
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = true
      from public.daftar_voucher(
        '11111111-1111-1111-1111-111111111111',
        'c8100000-0000-0000-0000-000000000001',
        'Ali Ridho',
        'ali.ridho+promo@gmail.com',
        '081234567890',
        null,
        true,
        'email',
        'perangkat-ali',
        '10.0.0.2'
      ) as hasil
  ),
  'T8-12 Lapis 10: Klaim pertama dengan email Gmail beralias tag berhasil'
);

-- ----------------------------------------------------------------------------
-- LAPIS 1: Satu Voucher Per Identitas Per Kampanye
-- ----------------------------------------------------------------------------

-- Klaim kedua dengan variasi titik Gmail untuk kampanye yang sama -> DITOLAK
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'VOUCHER_SUDAH_DIKLAIM'
      from public.daftar_voucher(
        '11111111-1111-1111-1111-111111111111',
        'c8100000-0000-0000-0000-000000000001',
        'Ali Ridho Duplikat',
        'a.l.i.r.i.d.h.o@gmail.com',
        '081234567890',
        null,
        true,
        'email',
        'perangkat-ali',
        '10.0.0.2'
      ) as hasil
  ),
  'T8-12 Lapis 1: Klaim kedua orang yang sama dengan variasi titik Gmail ditolak (VOUCHER_SUDAH_DIKLAIM)'
);

-- Terbitkan voucher kedua untuk Pelanggan Berbeda (Siti)
select public.daftar_voucher(
  '11111111-1111-1111-1111-111111111111',
  'c8100000-0000-0000-0000-000000000001',
  'Siti Khadijah',
  'siti.khadijah@barokah.id',
  '081987654321',
  null,
  true,
  'email',
  'perangkat-siti',
  '10.0.0.3'
);

-- Terbitkan voucher ketiga untuk Pelanggan Ketiga (Fatimah)
select public.daftar_voucher(
  '11111111-1111-1111-1111-111111111111',
  'c8100000-0000-0000-0000-000000000001',
  'Fatimah Zahra',
  'fatimah.zahra@barokah.id',
  '081777888999',
  null,
  true,
  'email',
  'perangkat-fatimah',
  '10.0.0.4'
);

-- ----------------------------------------------------------------------------
-- LAPIS 7: Kode Acak Tidak Berurutan (Format RB-XXXX-XXXX)
-- ----------------------------------------------------------------------------
select uji.harap(
  (
    select count(*) = 3 and every(kode ~ '^RB-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}$')
      from public.voucher
     where kampanye_id = 'c8100000-0000-0000-0000-000000000001'
  ),
  'T8-12 Lapis 7: Kode voucher acak berformat kriptografis RB-XXXX-XXXX non-sekuensial'
);

-- Ambil kode voucher masing-masing
do $$
declare
  v_kode_ali text;
  v_kode_siti text;
  v_kode_fatimah text;
begin
  select v.kode into v_kode_ali
    from public.voucher v
    join public.pelanggan p on p.id = v.pelanggan_id
   where v.kampanye_id = 'c8100000-0000-0000-0000-000000000001'
     and p.email_normalisasi = 'aliridho@gmail.com';

  select v.kode into v_kode_siti
    from public.voucher v
    join public.pelanggan p on p.id = v.pelanggan_id
   where v.kampanye_id = 'c8100000-0000-0000-0000-000000000001'
     and p.email_normalisasi = 'siti.khadijah@barokah.id';

  select v.kode into v_kode_fatimah
    from public.voucher v
    join public.pelanggan p on p.id = v.pelanggan_id
   where v.kampanye_id = 'c8100000-0000-0000-0000-000000000001'
     and p.email_normalisasi = 'fatimah.zahra@barokah.id';

  perform set_config('resto.kode_ali', v_kode_ali, true);
  perform set_config('resto.kode_siti', v_kode_siti, true);
  perform set_config('resto.kode_fatimah', v_kode_fatimah, true);
end;
$$;

-- ----------------------------------------------------------------------------
-- LAPIS 3: Wajib Belanja Minimum (min_belanja = 50.000)
-- ----------------------------------------------------------------------------
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'SUBTOTAL_KURANG'
      from public.cek_voucher(
        current_setting('resto.kode_ali'),
        'a1a1a1a1-0000-0000-0000-000000000001',
        30000 -- Belanja 30.000 < min_belanja 50.000
      ) as hasil
  ),
  'T8-12 Lapis 3: Cek voucher dengan subtotal di bawah minimum belanja ditolak (SUBTOTAL_KURANG)'
);

-- ----------------------------------------------------------------------------
-- LAPIS 4: Batas Maksimal Potongan (Diskon 20% plafon maks 15.000)
-- ----------------------------------------------------------------------------
-- Belanja 100.000 -> 20% = 20.000 -> dibatasi plafon 15.000
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = true
       and (hasil->'data'->>'estimasi_potongan')::numeric = 15000
      from public.cek_voucher(
        current_setting('resto.kode_ali'),
        'a1a1a1a1-0000-0000-0000-000000000001',
        100000
      ) as hasil
  ),
  'T8-12 Lapis 4: Diskon persen dibatasi tepat pada plafon maks_potongan (15.000 dari subtotal 100.000)'
);

-- ----------------------------------------------------------------------------
-- LAPIS 6: Kunci Atomik Sekali Pakai & Pemakaian Pertama
-- ----------------------------------------------------------------------------
-- Reset role untuk persiapan data pesanan
reset role;
select uji.klaim(null);

-- Pasang kredensial PIN dan izin untuk Kasir Rina
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

-- Buat pesanan 1 di Cabang Pusat
insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  nomor,
  tanggal,
  tipe,
  status,
  kunci_idempoten
) values (
  'd8100000-0000-0000-0000-000000000081',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  81,
  current_date,
  'dinein',
  'draf',
  'kunci-order-81'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'd8100000-0000-0000-0000-000000000181',
  'd8100000-0000-0000-0000-000000000081',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  100000,
  1,
  100000
) on conflict (id) do nothing;

-- Masuk sebagai Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Pakai voucher Ali pada pesanan 1 -> BERHASIL
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = true
       and (hasil->'data'->>'nilai_potongan')::numeric = 15000
      from public.pakai_voucher(
        'd8100000-0000-0000-0000-000000000081',
        current_setting('resto.kode_ali'),
        '1234',
        'kunci-idempoten-81',
        'pos-pusat-1',
        '192.168.1.10'
      ) as hasil
  ),
  'T8-12 Lapis 6: Pakai voucher pertama berhasil memotong tagihan'
);

-- Reset role untuk membuat pesanan 2
reset role;
select uji.klaim(null);

-- Buat pesanan 2 di Cabang Pusat
insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  nomor,
  tanggal,
  tipe,
  status,
  kunci_idempoten
) values (
  'd8100000-0000-0000-0000-000000000082',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  82,
  current_date,
  'dinein',
  'draf',
  'kunci-order-82'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'd8100000-0000-0000-0000-000000000182',
  'd8100000-0000-0000-0000-000000000082',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  80000,
  1,
  80000
) on conflict (id) do nothing;

-- Masuk kembali sebagai Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Mencoba memakai voucher Ali untuk kedua kalinya pada pesanan 2 -> DITOLAK
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'VOUCHER_SUDAH_TERPAKAI'
      from public.pakai_voucher(
        'd8100000-0000-0000-0000-000000000082',
        current_setting('resto.kode_ali'),
        '1234',
        'kunci-idempoten-82',
        'pos-pusat-1',
        '192.168.1.10'
      ) as hasil
  ),
  'T8-12 Lapis 6: Voucher yang sudah berstatus terpakai ditolak pemakaian berulang (VOUCHER_SUDAH_TERPAKAI)'
);

-- ----------------------------------------------------------------------------
-- LAPIS 2: Batas Voucher Per Outlet Per Hari (kuota_harian_cabang = 1)
-- ----------------------------------------------------------------------------
-- Cabang Pusat sudah memakai 1 voucher Ali hari ini. Kuota harian Cabang Pusat adalah 1.
-- Sekarang Siti mencoba memakai vouchernya di Cabang Pusat hari ini -> DITOLAK
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'KUOTA_HARIAN_CABANG_HABIS'
      from public.pakai_voucher(
        'd8100000-0000-0000-0000-000000000082',
        current_setting('resto.kode_siti'),
        '1234',
        'kunci-idempoten-83',
        'pos-pusat-1',
        '192.168.1.10'
      ) as hasil
  ),
  'T8-12 Lapis 2: Penukaran voucher di Cabang Pusat ditolak karena kuota harian cabang habis (KUOTA_HARIAN_CABANG_HABIS)'
);

-- Reset role untuk membuat pesanan 3 di Cabang Dua
reset role;
select uji.klaim(null);

insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  nomor,
  tanggal,
  tipe,
  status,
  kunci_idempoten
) values (
  'd8100000-0000-0000-0000-000000000083',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000002', -- Cabang Dua
  83,
  current_date,
  'dinein',
  'draf',
  'kunci-order-83'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'd8100000-0000-0000-0000-000000000183',
  'd8100000-0000-0000-0000-000000000083',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  100000,
  1,
  100000
) on conflict (id) do nothing;

-- Pastikan Kasir Rina terhubung ke Cabang Dua untuk pengujian ini
insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('90000000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000002')
on conflict do nothing;

-- Masuk sebagai Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Bila Siti memakai vouchernya di Cabang Dua (cabang berbeda) -> BERHASIL
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = true
      from public.pakai_voucher(
        'd8100000-0000-0000-0000-000000000083',
        current_setting('resto.kode_siti'),
        '1234',
        'kunci-idempoten-84',
        'pos-cabangdua-1',
        '192.168.2.10'
      ) as hasil
  ),
  'T8-12 Lapis 2: Penukaran voucher di Cabang Dua berhasil karena kuota harian cabangnya masih ada'
);

-- ----------------------------------------------------------------------------
-- LAPIS 5: Anggaran Kampanye Tidak Bisa Dilampaui (anggaran_maks = 30.000)
-- ----------------------------------------------------------------------------
-- Reset role untuk membuat pesanan 4 di Cabang Dua
reset role;
select uji.klaim(null);

-- Naikkan kuota harian per cabang agar pengujian fokus murni menguji batas anggaran
update public.kampanye_voucher
   set kuota_harian_cabang = 5
 where id = 'c8100000-0000-0000-0000-000000000001';

-- Voucher Ali menghabiskan diskon 15.000.
-- Voucher Siti menghabiskan diskon 15.000.
-- Total anggaran terpakai saat ini = 30.000 (sama dengan anggaran_maks).
-- Jika voucher Fatimah dicoba pakai (butuh 15.000 diskon lagi) -> DITOLAK
insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  nomor,
  tanggal,
  tipe,
  status,
  kunci_idempoten
) values (
  'd8100000-0000-0000-0000-000000000084',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000002',
  84,
  current_date,
  'dinein',
  'draf',
  'kunci-order-84'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'd8100000-0000-0000-0000-000000000184',
  'd8100000-0000-0000-0000-000000000084',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng Spesial',
  100000,
  1,
  100000
) on conflict (id) do nothing;

-- Masuk sebagai Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'ANGGARAN_KAMPANYE_HABIS'
      from public.pakai_voucher(
        'd8100000-0000-0000-0000-000000000084',
        current_setting('resto.kode_fatimah'),
        '1234',
        'kunci-idempoten-85',
        'pos-cabangdua-1',
        '192.168.2.10'
      ) as hasil
  ),
  'T8-12 Lapis 5: Penukaran voucher ditolak karena anggaran maksimal kampanye telah tercapai (ANGGARAN_KAMPANYE_HABIS)'
);

-- ----------------------------------------------------------------------------
-- LAPIS 8: Log Semua Cek/Scan & Batas Percobaan Per Perangkat (Rate Limiting)
-- ----------------------------------------------------------------------------
-- Simulasikan perangkat brute-force penyerang 'perangkat-serang-01' yang gagal 5 kali
select public.cek_voucher('KODE-SALAH-1', 'a1a1a1a1-0000-0000-0000-000000000001', 60000, 'perangkat-serang-01', '192.168.99.99');
select public.cek_voucher('KODE-SALAH-2', 'a1a1a1a1-0000-0000-0000-000000000001', 60000, 'perangkat-serang-01', '192.168.99.99');
select public.cek_voucher('KODE-SALAH-3', 'a1a1a1a1-0000-0000-0000-000000000001', 60000, 'perangkat-serang-01', '192.168.99.99');
select public.cek_voucher('KODE-SALAH-4', 'a1a1a1a1-0000-0000-0000-000000000001', 60000, 'perangkat-serang-01', '192.168.99.99');
select public.cek_voucher('KODE-SALAH-5', 'a1a1a1a1-0000-0000-0000-000000000001', 60000, 'perangkat-serang-01', '192.168.99.99');

-- Pada percobaan ke-6 dari perangkat yang sama, sistem langsung memblokir
select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'TERLALU_BANYAK_PERCOBAAN'
      from public.cek_voucher(
        'KODE-SALAH-6',
        'a1a1a1a1-0000-0000-0000-000000000001',
        60000,
        'perangkat-serang-01',
        '192.168.99.99'
      ) as hasil
  ),
  'T8-12 Lapis 8: Perangkat dengan 5 kegagalan berturut-turut diblokir sementara (TERLALU_BANYAK_PERCOBAAN)'
);

-- Pengawasan Audit Kecurangan: ambil_log_percobaan_voucher oleh Admin Pak Andi
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = true
       and jsonb_array_length(hasil->'data') >= 6
      from public.ambil_log_percobaan_voucher(null, 50) as hasil
  ),
  'T8-12 Lapis 8: Admin dapat mengambil log audit seluruh percobaan cek/scan/pakai voucher'
);

-- Pengawasan Audit: Kasir biasa tidak berhak melihat audit log percobaan
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (
    select (hasil->>'berhasil')::boolean = false and (hasil->>'kode') = 'TIDAK_BERIZIN'
      from public.ambil_log_percobaan_voucher(null, 50) as hasil
  ),
  'T8-12 Pengawasan: Kasir biasa ditolak mengakses log percobaan voucher (TIDAK_BERIZIN)'
);

rollback;
