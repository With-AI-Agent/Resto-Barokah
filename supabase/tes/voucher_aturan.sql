-- ============================================================================
-- UJI T8-14 — UJI LENGKAP ATURAN VOUCHER (6 KASUS WAJIB)
-- ----------------------------------------------------------------------------
-- Referensi: PRD M10 & TECH_SPEC §8
-- 6 Kasus Wajib:
--   1. Belanja kurang dari minimum ditolak (SUBTOTAL_KURANG)
--   2. Persen dipotong sampai batas maks (plafon tepat sampai satuan rupiah)
--   3. Masa berlaku lewat ditolak (VOUCHER_KEDALUWARSA)
--   4. Kuota habis ditolak (KUOTA_HARIAN_CABANG_HABIS & ANGGARAN_KAMPANYE_HABIS)
--   5. Beda cabang ditolak bila cabang terkunci (CABANG_TIDAK_BERLAKU)
--   6. Voucher dipakai pesanan lain ditolak (VOUCHER_SUDAH_TERPAKAI)
-- ============================================================================

reset role;
select uji.klaim(null);

-- Setup Kasir Rina (Cabang Pusat & Cabang Dua)
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values
  ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true),
  ('90000000-0000-0000-0000-000000000004', 'ubah_harga', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('90000000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000002')
on conflict do nothing;

-- Setup Pelanggan Uji
insert into public.pelanggan (id, penyewa_id, nama, email, email_normalisasi, telepon, cara_masuk, persetujuan_privasi)
values
  ('b0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 1', 'aturan1@test.com', 'aturan1@test.com', '0811111111', 'google', true),
  ('b0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 2', 'aturan2@test.com', 'aturan2@test.com', '0822222222', 'google', true),
  ('b0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 3', 'aturan3@test.com', 'aturan3@test.com', '0833333333', 'google', true),
  ('b0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 4', 'aturan4@test.com', 'aturan4@test.com', '0844444444', 'google', true),
  ('b0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 5', 'aturan5@test.com', 'aturan5@test.com', '0855555555', 'google', true),
  ('b0000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'Pelanggan Aturan 6', 'aturan6@test.com', 'aturan6@test.com', '0866666666', 'google', true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- KASUS 1: Belanja Kurang Dari Minimum Ditolak (min_belanja)
-- ---------------------------------------------------------------------------
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000101',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye Syarat Min Belanja 50K',
  'SYARATMIN50',
  'nominal',
  10000,
  null,
  50000,
  100,
  50,
  1000000,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000101',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000101',
  'b0000000-0000-0000-0000-000000000001',
  'RB-MINB-0001',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

-- Pesanan 1A: subtotal 35.000 (< 50.000)
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000101',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  101,
  'draf',
  35000,
  35000,
  'idem-psn-101'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e0000000-0000-0000-0000-000000000201',
  'e0000000-0000-0000-0000-000000000101',
  'beef0000-0000-0000-0000-000000000001',
  'Menu Uji 35K',
  35000,
  1,
  35000
) on conflict (id) do nothing;

-- Cek voucher: harus ditolak karena subtotal 35.000 < min_belanja 50.000
select uji.sama(
  (select (public.cek_voucher('RB-MINB-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 35000))->>'berhasil'),
  'false',
  'Kasus 1: cek_voucher menolak pesanan dengan subtotal di bawah batas minimum belanja'
);

select uji.sama(
  (select (public.cek_voucher('RB-MINB-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 35000))->>'kode'),
  'SUBTOTAL_KURANG',
  'Kasus 1: kode error cek_voucher adalah SUBTOTAL_KURANG'
);

-- Pakai voucher: harus ditolak
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000101'::uuid, 'RB-MINB-0001', '1234'))->>'berhasil'),
  'false',
  'Kasus 1: pakai_voucher menolak pesanan di bawah minimum belanja'
);

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000101'::uuid, 'RB-MINB-0001', '1234'))->>'kode'),
  'SUBTOTAL_KURANG',
  'Kasus 1: kode penolakan pakai_voucher adalah SUBTOTAL_KURANG'
);

-- Tingkatkan subtotal pesanan menjadi 60.000 (>= 50.000) dengan menambah item
reset role;
select uji.klaim(null);

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e0000000-0000-0000-0000-000000000202',
  'e0000000-0000-0000-0000-000000000101',
  'beef0000-0000-0000-0000-000000000001',
  'Menu Tambahan 25K',
  25000,
  1,
  25000
) on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Cek voucher berhasil
select uji.sama(
  (select (public.cek_voucher('RB-MINB-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 60000))->>'berhasil'),
  'true',
  'Kasus 1: cek_voucher berhasil setelah subtotal mencapai minimum belanja'
);

-- Pakai voucher berhasil
select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000101'::uuid, 'RB-MINB-0001', '1234'))->>'berhasil'),
  'true',
  'Kasus 1: pakai_voucher berhasil saat subtotal memenuhi syarat'
);

-- ---------------------------------------------------------------------------
-- KASUS 2: Potongan Persen Dipotong Sampai Batas Maks (Plafon Rupiah Terkecil)
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000102',
  '11111111-1111-1111-1111-111111111111',
  'Diskon 40% Plafon 25K',
  'PLAFON40',
  'persen',
  40,
  25000,
  20000,
  100,
  50,
  1000000,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000102',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000102',
  'b0000000-0000-0000-0000-000000000002',
  'RB-PLAF-0001',
  'aktif',
  now() + interval '7 days'
),
(
  '70000000-0000-0000-0000-000000000103',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000102',
  'b0000000-0000-0000-0000-000000000003',
  'RB-PLAF-0002',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

-- Uji 2A: Subtotal 100.000. 40% = 40.000 -> Harus dipotong sampai batas maks: 25.000
select uji.sama(
  (select ((public.cek_voucher('RB-PLAF-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 100000))->'data')->>'estimasi_potongan'),
  '25000',
  'Kasus 2A: diskon 40% dari 100.000 dipotong pas di plafon maks 25.000'
);

-- Uji 2B: Subtotal 45.555 (angka ganjil). 40% dari 45.555 = 18.222.
-- Belum mencapai batas maks 25.000 -> Harus tepat floor(45555 * 40 / 100) = 18222 rupiah terkecil.
select uji.sama(
  (select ((public.cek_voucher('RB-PLAF-0002', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 45555))->'data')->>'estimasi_potongan'),
  '18222',
  'Kasus 2B: diskon 40% dari 45.555 dihitung presisi sampai rupiah terkecil (18.222)'
);

-- Pakai voucher pada pesanan dengan subtotal 45.555
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000102',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  102,
  'draf',
  45555,
  45555,
  'idem-psn-102'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e0000000-0000-0000-0000-000000000203',
  'e0000000-0000-0000-0000-000000000102',
  'beef0000-0000-0000-0000-000000000001',
  'Menu 45555',
  45555,
  1,
  45555
) on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000102'::uuid, 'RB-PLAF-0002', '1234'))->>'berhasil'),
  'true',
  'Kasus 2B: pakai_voucher berhasil menerapkan diskon persen dengan nilai rupiah presisi'
);

select uji.sama(
  (select nilai from public.diskon_transaksi where pesanan_id = 'e0000000-0000-0000-0000-000000000102'::uuid and jenis = 'voucher'),
  18222,
  'Kasus 2B: nilai potongan diskon tersimpan di database tepat 18.222 rupiah'
);

-- ---------------------------------------------------------------------------
-- KASUS 3: Masa Berlaku Lewat Ditolak (Kedaluwarsa)
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000103',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye Sudah Kedaluwarsa',
  'KEDALUWARSA',
  'nominal',
  15000,
  null,
  20000,
  100,
  50,
  1000000,
  now() - interval '30 days',
  now() - interval '2 days', -- berakhir 2 hari lalu
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000104',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000103',
  'b0000000-0000-0000-0000-000000000004',
  'RB-EXPR-0001',
  'aktif',
  now() - interval '2 days'
) on conflict (id) do nothing;

insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000103',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  103,
  'draf',
  50000,
  50000,
  'idem-psn-103'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e0000000-0000-0000-0000-000000000204',
  'e0000000-0000-0000-0000-000000000103',
  'beef0000-0000-0000-0000-000000000001',
  'Menu 50K',
  50000,
  1,
  50000
) on conflict (id) do nothing;

-- Cek voucher kedaluwarsa
select uji.sama(
  (select (public.cek_voucher('RB-EXPR-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'berhasil'),
  'false',
  'Kasus 3: cek_voucher menolak voucher kedaluwarsa'
);

select uji.sama(
  (select (public.cek_voucher('RB-EXPR-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'kode'),
  'VOUCHER_KEDALUWARSA',
  'Kasus 3: kode penolakan cek_voucher adalah VOUCHER_KEDALUWARSA'
);

-- Pakai voucher kedaluwarsa
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000103'::uuid, 'RB-EXPR-0001', '1234'))->>'berhasil'),
  'false',
  'Kasus 3: pakai_voucher menolak voucher yang sudah melewati masa berlaku'
);

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000103'::uuid, 'RB-EXPR-0001', '1234'))->>'kode'),
  'VOUCHER_KEDALUWARSA',
  'Kasus 3: kode penolakan pakai_voucher adalah VOUCHER_KEDALUWARSA'
);

-- ---------------------------------------------------------------------------
-- KASUS 4: Kuota Habis Ditolak (Batas Harian Cabang & Anggaran Kampanye)
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

-- 4A. Kuota Harian Cabang = 1
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000104',
  '11111111-1111-1111-1111-111111111111',
  'Promo Kuota Harian Ketat 1',
  'KUOTA1HARI',
  'nominal',
  10000,
  null,
  20000,
  100,
  1, -- Hanya 1 voucher per cabang per hari
  1000000,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000105',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000104',
  'b0000000-0000-0000-0000-000000000005',
  'RB-KOTA-0001',
  'aktif',
  now() + interval '7 days'
),
(
  '70000000-0000-0000-0000-000000000106',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000104',
  'b0000000-0000-0000-0000-000000000006',
  'RB-KOTA-0002',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000104',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  104,
  'draf',
  50000,
  50000,
  'idem-psn-104'
),
(
  'e0000000-0000-0000-0000-000000000105',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  105,
  'draf',
  50000,
  50000,
  'idem-psn-105'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values
  ('e0000000-0000-0000-0000-000000000205', 'e0000000-0000-0000-0000-000000000104', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K A', 50000, 1, 50000),
  ('e0000000-0000-0000-0000-000000000206', 'e0000000-0000-0000-0000-000000000105', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K B', 50000, 1, 50000)
on conflict (id) do nothing;

-- Pakai voucher pertama di Cabang Utama -> harus sukses (menghabiskan kuota 1 harian)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000104'::uuid, 'RB-KOTA-0001', '1234'))->>'berhasil'),
  'true',
  'Kasus 4A: voucher pertama berhasil dipakai memenuhi kuota harian cabang (1 dari 1)'
);

-- Cek voucher kedua di cabang yang sama pada hari yang sama -> harus ditolak
select uji.sama(
  (select (public.cek_voucher('RB-KOTA-0002', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'berhasil'),
  'false',
  'Kasus 4A: cek_voucher menolak voucher kedua karena kuota harian cabang habis'
);

select uji.sama(
  (select (public.cek_voucher('RB-KOTA-0002', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'kode'),
  'KUOTA_HARIAN_CABANG_HABIS',
  'Kasus 4A: kode penolakan cek_voucher adalah KUOTA_HARIAN_CABANG_HABIS'
);

-- Pakai voucher kedua -> harus ditolak
select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000105'::uuid, 'RB-KOTA-0002', '1234'))->>'berhasil'),
  'false',
  'Kasus 4A: pakai_voucher menolak pemakaian voucher saat kuota harian cabang telah habis'
);

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000105'::uuid, 'RB-KOTA-0002', '1234'))->>'kode'),
  'KUOTA_HARIAN_CABANG_HABIS',
  'Kasus 4A: kode penolakan pakai_voucher adalah KUOTA_HARIAN_CABANG_HABIS'
);

-- 4B. Anggaran Kampanye Habis
reset role;
select uji.klaim(null);

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000105',
  '11111111-1111-1111-1111-111111111111',
  'Promo Anggaran Mepet 25K',
  'ANGGARAN25K',
  'nominal',
  20000,
  null,
  20000,
  100,
  50,
  25000, -- Anggaran maks hanya 25.000. Voucher pertama (20K) muat; voucher kedua (20K + 20K = 40K > 25K) tidak muat
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000107',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000105',
  'b0000000-0000-0000-0000-000000000001',
  'RB-ANGG-0001',
  'aktif',
  now() + interval '7 days'
),
(
  '70000000-0000-0000-0000-000000000108',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000105',
  'b0000000-0000-0000-0000-000000000002',
  'RB-ANGG-0002',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000106',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  106,
  'draf',
  50000,
  50000,
  'idem-psn-106'
),
(
  'e0000000-0000-0000-0000-000000000107',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  107,
  'draf',
  50000,
  50000,
  'idem-psn-107'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values
  ('e0000000-0000-0000-0000-000000000207', 'e0000000-0000-0000-0000-000000000106', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K C', 50000, 1, 50000),
  ('e0000000-0000-0000-0000-000000000208', 'e0000000-0000-0000-0000-000000000107', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K D', 50000, 1, 50000)
on conflict (id) do nothing;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Pakai voucher pertama (20.000 dari anggaran 25.000) -> sukses
select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000106'::uuid, 'RB-ANGG-0001', '1234'))->>'berhasil'),
  'true',
  'Kasus 4B: pemakaian voucher pertama berhasil menyerap anggaran 20.000'
);

-- Cek voucher kedua -> anggaran tersisa hanya 5.000, voucher 20.000 melampaui batas anggaran kampanye
select uji.sama(
  (select (public.cek_voucher('RB-ANGG-0002', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'berhasil'),
  'false',
  'Kasus 4B: cek_voucher menolak voucher kedua karena anggaran maksimal kampanye akan terlampaui'
);

select uji.sama(
  (select (public.cek_voucher('RB-ANGG-0002', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'kode'),
  'ANGGARAN_KAMPANYE_HABIS',
  'Kasus 4B: kode penolakan cek_voucher adalah ANGGARAN_KAMPANYE_HABIS'
);

-- ---------------------------------------------------------------------------
-- KASUS 5: Beda Cabang Ditolak Bila Cabang Terkunci
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

-- Kampanye khusus Cabang Pusat saja
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, cabang_berlaku, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000106',
  '11111111-1111-1111-1111-111111111111',
  'Promo Khusus Cabang Pusat',
  'KHUSUSPUSAT',
  'nominal',
  10000,
  null,
  20000,
  100,
  50,
  1000000,
  jsonb_build_array('a1a1a1a1-0000-0000-0000-000000000001'), -- Hanya Cabang Pusat
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000109',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000106',
  'b0000000-0000-0000-0000-000000000003',
  'RB-CAB1-0001',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

-- Pesanan di Cabang Dua (a1a1a1a1-0000-0000-0000-000000000002)
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000108',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000002',
  108,
  'draf',
  50000,
  50000,
  'idem-psn-108'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e0000000-0000-0000-0000-000000000209',
  'e0000000-0000-0000-0000-000000000108',
  'beef0000-0000-0000-0000-000000000001',
  'Menu 50K E',
  50000,
  1,
  50000
) on conflict (id) do nothing;

-- Cek voucher di Cabang Dua -> harus ditolak
select uji.sama(
  (select (public.cek_voucher('RB-CAB1-0001', 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 50000))->>'berhasil'),
  'false',
  'Kasus 5: cek_voucher menolak voucher yang tidak berlaku di cabang bersangkutan'
);

select uji.sama(
  (select (public.cek_voucher('RB-CAB1-0001', 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 50000))->>'kode'),
  'CABANG_TIDAK_BERLAKU',
  'Kasus 5: kode penolakan cek_voucher adalah CABANG_TIDAK_BERLAKU'
);

-- Pakai voucher di Cabang Dua -> harus ditolak
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000108'::uuid, 'RB-CAB1-0001', '1234'))->>'berhasil'),
  'false',
  'Kasus 5: pakai_voucher menolak voucher bila dicoba di cabang yang tidak diizinkan'
);

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000108'::uuid, 'RB-CAB1-0001', '1234'))->>'kode'),
  'CABANG_TIDAK_BERLAKU',
  'Kasus 5: kode penolakan pakai_voucher adalah CABANG_TIDAK_BERLAKU'
);

-- Cek voucher di Cabang Pusat (yang diizinkan) -> harus sukses
select uji.sama(
  (select (public.cek_voucher('RB-CAB1-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'berhasil'),
  'true',
  'Kasus 5: cek_voucher berhasil bila diperiksa di cabang yang sah'
);

-- ---------------------------------------------------------------------------
-- KASUS 6: Voucher Dipakai Pesanan Lain Ditolak (Sekali Pakai / Anti Reuse)
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, maks_potongan, min_belanja, kuota, kuota_harian_cabang, anggaran_maks, mulai, selesai, aktif
) values (
  'c0000000-0000-0000-0000-000000000107',
  '11111111-1111-1111-1111-111111111111',
  'Promo Sekali Pakai Ketat',
  'SEKALIPAKAI',
  'nominal',
  10000,
  null,
  20000,
  100,
  50,
  1000000,
  now() - interval '1 day',
  now() + interval '7 days',
  true
) on conflict (id) do nothing;

insert into public.voucher (
  id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai
) values (
  '70000000-0000-0000-0000-000000000110',
  '11111111-1111-1111-1111-111111111111',
  'c0000000-0000-0000-0000-000000000107',
  'b0000000-0000-0000-0000-000000000004',
  'RB-SEKL-0001',
  'aktif',
  now() + interval '7 days'
) on conflict (id) do nothing;

-- Pesanan 6A dan Pesanan 6B
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten
) values (
  'e0000000-0000-0000-0000-000000000109',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  109,
  'draf',
  50000,
  50000,
  'idem-psn-109'
),
(
  'e0000000-0000-0000-0000-000000000110',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  110,
  'draf',
  50000,
  50000,
  'idem-psn-110'
) on conflict (id) do nothing;

insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values
  ('e0000000-0000-0000-0000-000000000210', 'e0000000-0000-0000-0000-000000000109', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K 6A', 50000, 1, 50000),
  ('e0000000-0000-0000-0000-000000000211', 'e0000000-0000-0000-0000-000000000110', 'beef0000-0000-0000-0000-000000000001', 'Menu 50K 6B', 50000, 1, 50000)
on conflict (id) do nothing;

-- Pakai voucher di Pesanan 6A -> harus sukses
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000109'::uuid, 'RB-SEKL-0001', '1234'))->>'berhasil'),
  'true',
  'Kasus 6: voucher berhasil dipakai pada Pesanan 6A'
);

-- Pastikan status voucher berubah menjadi 'terpakai'
reset role;
select uji.klaim(null);

select uji.sama(
  (select status from public.voucher where kode = 'RB-SEKL-0001'),
  'terpakai',
  'Kasus 6: status voucher terkunci menjadi terpakai'
);

-- Cek voucher untuk Pesanan 6B -> harus ditolak karena sudah pernah dipakai
select uji.sama(
  (select (public.cek_voucher('RB-SEKL-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'berhasil'),
  'false',
  'Kasus 6: cek_voucher menolak voucher yang statusnya sudah terpakai'
);

select uji.sama(
  (select (public.cek_voucher('RB-SEKL-0001', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 50000))->>'kode'),
  'VOUCHER_SUDAH_TERPAKAI',
  'Kasus 6: kode penolakan cek_voucher adalah VOUCHER_SUDAH_TERPAKAI'
);

-- Pakai voucher untuk Pesanan 6B -> harus ditolak
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000110'::uuid, 'RB-SEKL-0001', '1234'))->>'berhasil'),
  'false',
  'Kasus 6: pakai_voucher menolak voucher yang sudah digunakan di pesanan lain'
);

select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000110'::uuid, 'RB-SEKL-0001', '1234'))->>'kode'),
  'VOUCHER_SUDAH_TERPAKAI',
  'Kasus 6: kode penolakan pakai_voucher adalah VOUCHER_SUDAH_TERPAKAI'
);

-- Verifikasi Idempoten: pemanggilan ulang untuk Pesanan 6A yang sama mengembalikan IDEMPOTEN dan berhasil
select uji.sama(
  (select (public.pakai_voucher('e0000000-0000-0000-0000-000000000109'::uuid, 'RB-SEKL-0001', '1234'))->>'kode'),
  'IDEMPOTEN',
  'Kasus 6: pemanggilan pakai_voucher ulang pada pesanan yang sama bersifat idempoten'
);
