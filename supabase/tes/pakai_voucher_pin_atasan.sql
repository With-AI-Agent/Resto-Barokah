-- ============================================================================
-- UJI SQL: Pakai voucher wajib persetujuan PIN atasan — PMB1-F-038 BAGIAN B,
-- OPSI 1 (keputusan Lee 2026-10-04), DISIAPKAN DI BALIK SAKLAR MATI (klaster B).
-- ============================================================================
-- Yang dijaga (migrasi 0098_wajib_pin_atasan_pakai_voucher.sql):
--   1. Saklar `pengaturan.wajib_pin_atasan_pakai_voucher` BAWAAN MATI:
--      perilaku lama persis (PIN kasir sendiri cukup).
--   2. Saklar MENYALA: pakai voucher hanya berhasil bila ada bukti PIN atasan
--      (stempel `percobaan_pin` aksi 'pakai_voucher' terikat pesanan, 5 menit,
--      sekali pakai — pola yang sama dengan persetujuan diskon T5-05 di 0016/0041).
--   3. Penyetuju TIDAK BOLEH kasir yang sama (tidak bisa menyetujui diri sendiri)
--      dan harus berizin `pakai_voucher`.
-- Skenario kerugian F-038 Bagian B: kasir mengarang pelanggan lalu mencairkan
-- vouchernya dengan PIN-nya sendiri; dengan saklar menyala pencairan itu wajib
-- disetujui orang kedua yang benar-benar menekan PIN-nya.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/pakai_voucher_pin_atasan.sql
-- ============================================================================

-- --- Persiapan: PIN + izin kasir Rina, PIN owner (atasan) --------------------
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('1234', gen_salt('bf', 8)))
on conflict (pengguna_id) do update set pin_hash = crypt('1234', gen_salt('bf', 8));

insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'pakai_voucher', true)
on conflict (pengguna_id, kode_izin) do update set boleh = true;

select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner memasang PIN
set local role authenticated;
select public.simpan_pin('551937', null, null,
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789');
reset role;
select uji.klaim(null);

update public.pengaturan
   set tumpuk_diskon = false,
       batas_maks_potongan_persen = 100,
       batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- --- Persiapan: kampanye + pelanggan + voucher + pesanan ---------------------
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c4000000-0000-0000-0000-000000000098',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye uji persetujuan atasan F-038B', 'SETUJUF38B', 'nominal', 10000, 40000,
  now() - interval '1 hour', now() + interval '1 day', 50, true
);

insert into public.pelanggan (id, penyewa_id, nama, telepon, cara_masuk, didaftarkan_oleh, persetujuan_privasi)
values ('c5000000-0000-0000-0000-000000000098', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan', '081400000098', 'kasir',
        '90000000-0000-0000-0000-000000000004', true),
       ('c5000000-0000-0000-0000-000000000099', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan Dua', '081400000099', 'kasir',
        '90000000-0000-0000-0000-000000000004', true),
       ('c5000000-0000-0000-0000-000000000097', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan Tiga', '081400000097', 'kasir',
        '90000000-0000-0000-0000-000000000004', true),
       ('c5000000-0000-0000-0000-000000000096', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan Empat', '081400000096', 'kasir',
        '90000000-0000-0000-0000-000000000004', true),
       ('c5000000-0000-0000-0000-000000000095', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan Lima', '081400000095', 'kasir',
        '90000000-0000-0000-0000-000000000004', true),
       ('c5000000-0000-0000-0000-000000000094', '11111111-1111-1111-1111-111111111111',
        'Tamu Uji Persetujuan Enam', '081400000094', 'kasir',
        '90000000-0000-0000-0000-000000000004', true);

insert into public.voucher (id, penyewa_id, kampanye_id, pelanggan_id, kode, status, berlaku_sampai)
values ('c6000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000098',
        'VC-BA-01', 'aktif', now() + interval '1 day'),
       ('c6000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000099',
        'VC-BA-02', 'aktif', now() + interval '1 day'),
       ('c6000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000097',
        'VC-BA-03', 'aktif', now() + interval '1 day'),
       ('c6000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000096',
        'VC-BA-04', 'aktif', now() + interval '1 day'),
       ('c6000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000095',
        'VC-BA-05', 'aktif', now() + interval '1 day'),
       ('c6000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111',
        'c4000000-0000-0000-0000-000000000098', 'c5000000-0000-0000-0000-000000000094',
        'VC-BA-06', 'aktif', now() + interval '1 day');

-- Pesanan uji baru (pesanan data-uji eeee...0010 dipakai berkas lain; tiap berkas
-- di-rollback, tetapi di dalam berkas ini satu pesanan hanya untuk satu pakai).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, meja_id,
                            status, subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000210', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 210, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-210'),
       ('eeee0000-0000-0000-0000-000000000211', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 211, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-211'),
       ('eeee0000-0000-0000-0000-000000000212', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 212, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-212'),
       ('eeee0000-0000-0000-0000-000000000213', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 213, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-213'),
       ('eeee0000-0000-0000-0000-000000000214', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 214, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-214'),
       ('eeee0000-0000-0000-0000-000000000215', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 215, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        60000, 6000, 3000, 69000, 'keranjang-uji-f038b-215');

-- Baris item nyata untuk pesanan 0215: pemicu `diskon_hitung_total` menghitung
-- ulang subtotal pesanan dari `pesanan_item` setiap kali baris diskon masuk.
-- Tanpa baris item, subtotal pesanan menjadi 0 setelah voucher pertama cair dan
-- pencairan kedua keliru ditolak SUBTOTAL_KOSONG (kecelakaan fixture, bukan kode).
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000215', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 30000, 2, 60000);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Rina memegang layar
set local role authenticated;

-- ---------------------------------------------------------------------------
-- 1. Saklar MATI (bawaan): perilaku lama persis — PIN kasir cukup.
-- ---------------------------------------------------------------------------
select uji.harap(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000210', 'VC-BA-01', '1234') ->> 'berhasil')::boolean,
  'F-038 B opsi 1: saklar mati bawaan -> pakai voucher cukup PIN kasir (perilaku lama utuh)'
);

select uji.sama(
  (select pakai_disetujui_oleh from public.voucher where kode = 'VC-BA-01'),
  null::uuid,
  'F-038 B opsi 1: tanpa saklar, jejak penyetuju tetap kosong'
);

-- ---------------------------------------------------------------------------
-- Saklar DINYALAKAN untuk sisa uji (kembali dimatikan di akhir berkas).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner menyalakan saklar
update public.pengaturan
   set wajib_pin_atasan_pakai_voucher = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali ke kasir

-- 2. Saklar menyala, TANPA persetujuan -> DITOLAK.
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000211', 'VC-BA-02', '1234') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-038 B opsi 1: saklar menyala tanpa persetujuan atasan -> DITOLAK'
);

-- 3. Kasir menunjuk DIRINYA sebagai penyetuju -> DITOLAK (tidak boleh setujui diri sendiri).
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000211', 'VC-BA-02', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000004') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-038 B opsi 1: kasir tidak bisa menyetujui dirinya sendiri'
);

-- 4. Klaim penyetuju TANPA bukti PIN (karangan) -> DITOLAK.
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000211', 'VC-BA-02', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-038 B opsi 1: klaim persetujuan tanpa bukti PIN atasan -> DITOLAK'
);

-- 5. Atasan benar-benar menekan PIN-nya untuk pesanan ini -> pakai BERHASIL.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '551937', 'pakai_voucher',
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789',
                         'eeee0000-0000-0000-0000-000000000211')).berhasil,
  true,
  'F-038 B opsi 1: atasan menekan PIN-nya sendiri untuk aksi pakai_voucher di pesanan ini'
);

select uji.harap(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000211', 'VC-BA-02', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'berhasil')::boolean,
  'F-038 B opsi 1: dengan bukti PIN atasan, pakai voucher BERHASIL'
);

-- 6. Jejak: voucher mencatat SIAPA yang menyetujui.
select uji.sama(
  (select pakai_disetujui_oleh from public.voucher where kode = 'VC-BA-02'),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'F-038 B opsi 1: jejak penyetuju tersimpan pada voucher'
);

-- 7. Stempel SEKALI PAKAI: stempel yang sama tidak bisa dipakai untuk voucher lain.
select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000212', 'VC-BA-03', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-038 B opsi 1: stempel persetujuan sekali pakai — tidak bisa dipakai ulang'
);

-- 8. Penyetuju tanpa izin pakai_voucher (dapur; izin bawaan dapur = false di 0005):
--    a. dapur bahkan TIDAK BISA membuat stempel — verifikasi_pin menolak menjadi
--       oracle izin (pelajaran 0091): PIN benar pun dijawab gagal;
--    b. akibatnya klaim penyetuju dapur di pakai_voucher selalu DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur memasang PIN
select public.simpan_pin('264810', null, null,
                         'de000000-0000-0000-0000-000000000005',
                         'kunci-uji-hp-dapur-0123456789');
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali ke kasir

select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '264810', 'pakai_voucher',
                         'de000000-0000-0000-0000-000000000005',
                         'kunci-uji-hp-dapur-0123456789',
                         'eeee0000-0000-0000-0000-000000000213')).berhasil,
  false,
  'F-038 B opsi 1: pegawai tanpa izin (dapur) tidak bisa membuat stempel — PIN bukan oracle'
);

select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000213', 'VC-BA-04', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000006') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-038 B opsi 1: klaim penyetuju tanpa izin (dapur) DITOLAK'
);

-- 27. PMB1-F-229 (temuan H-F-03.7): stempel benar-benar SEKALI PAKAI pada
--     pesanan yang SAMA. Dengan tumpuk_diskon menyala, satu stempel hanya boleh
--     mencairkan SATU voucher di pesanan itu; voucher kedua pada pesanan yang
--     sama tanpa stempel baru wajib DITOLAK (bukan karena aturan tumpuk).
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner menyalakan tumpuk
update public.pengaturan
   set tumpuk_diskon = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali ke kasir

select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '551937', 'pakai_voucher',
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789',
                         'eeee0000-0000-0000-0000-000000000215')).berhasil,
  true,
  'F-229: stempel atasan dibuat untuk pesanan 0215'
);

select uji.harap(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000215', 'VC-BA-05', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'berhasil')::boolean,
  'F-229: voucher pertama pesanan 0215 cair memakai stempel itu'
);

select uji.sama(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000215', 'VC-BA-06', '1234',
                        null, null, null,
                        '90000000-0000-0000-0000-000000000002') ->> 'kode'),
  'PERSETUJUAN_ATASAN_WAJIB',
  'F-229: voucher kedua pada pesanan yang sama DITOLAK — stempel sudah dikonsumsi sekali'
);

select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner mematikan tumpuk lagi
update public.pengaturan
   set tumpuk_diskon = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali ke kasir

-- 9. Saklar dimatikan lagi -> perilaku lama pulih.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner mematikan saklar lagi
update public.pengaturan
   set wajib_pin_atasan_pakai_voucher = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali ke kasir

select uji.harap(
  (public.pakai_voucher('eeee0000-0000-0000-0000-000000000214', 'VC-BA-04', '1234') ->> 'berhasil')::boolean,
  'F-038 B opsi 1: saklar dimatikan lagi -> perilaku lama pulih (PIN kasir cukup)'
);
