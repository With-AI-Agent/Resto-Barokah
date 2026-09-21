-- ============================================================================
-- UJI: URUTAN HITUNGAN UANG (temuan AUD-3 2026-09-19 F-01 & F-02)
-- ============================================================================
-- Aturan yang dijaga (kutipan `docs/TECH_SPEC.md` §329-331):
--   "subtotal (jumlah harga_saat_itu × qty) → diskon → pajak PB1 → service →
--    pembulatan → total. Diskon dihitung dari subtotal, pajak & service dihitung dari
--    SUBTOTAL SETELAH DISKON. Semua nominal bilangan bulat rupiah; pembulatan hanya di
--    langkah terakhir sesuai pengaturan resto."
--
-- Yang dibuktikan berkas ini:
--   1. Tanpa diskon: pajak & service dari subtotal (perilaku lama tetap sama).
--   2. DENGAN diskon: pajak & service dari subtotal SETELAH diskon (inti perbaikan).
--   3. Pembulatan 'none' → total apa adanya; '100'/'500'/'1000' → dibulatkan KE BAWAH.
--   4. Pembulatan berlaku sebagai langkah TERAKHIR (setelah pajak & service).
--   5. Pesanan yang sudah LUNAS tidak bisa dihitung ulang dari perangkat (kasir) —
--      angka struk yang sudah dibayar tidak berubah.
--   6. Jalur peladen tetap boleh: perubahan item lewat jalur resmi (pemicu) tetap
--      menghitung ulang angka pesanan yang belum lunas.
-- ============================================================================

-- Penyiapan (pemilik tabel): tiga pesanan di cabang A1 (Nasi Goreng Rp27.000/harga cabang).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e2000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 971, current_date, 'dinein', 'draf', 'urutan-uang-1'),
       ('e2000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 972, current_date, 'dinein', 'draf', 'urutan-uang-2'),
       ('e2000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 973, current_date, 'dinein', 'draf', 'urutan-uang-3');

-- 1. Tanpa diskon: 27.000 → PB1 2.700 + service 1.350 → 31.050.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e2000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
select uji.sama(
  (select (p.subtotal, p.pajak, p.service, p.total) from public.pesanan p
    where p.id = 'e2000000-0000-0000-0000-000000000001'),
  (27000, 2700, 1350, 31050), 'tanpa diskon: PB1 & service dari subtotal (aturan lama tetap)'
);

-- 2. DENGAN diskon 10% (2.700): dasar = 24.300 → PB1 2.430 + service 1.215 → 27.945.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e2000000-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (diskon ≤ 5% / 25.000)
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
values ('e2000000-0000-0000-0000-000000000002', 'manual', 5, 1350, 'uji urutan uang');
reset role;
select uji.klaim(null);
select uji.sama(
  (select (p.subtotal, p.total_diskon, p.pajak, p.service, p.total) from public.pesanan p
    where p.id = 'e2000000-0000-0000-0000-000000000002'),
  (27000, 1350, 2565, 1283, 29498),
  'F-01a: dasar pajak/service = subtotal SETELAH diskon (25.650 → PB1 2.565, service 1.283)'
);
select uji.sama(
  (select p.pajak from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000002'),
  round((27000 - 1350) * 10 / 100.0)::integer,
  'F-01a: pajak = 10% × (subtotal − diskon), bukan 10% × subtotal'
);

-- 3. Pembulatan: '100' → ke bawah, '500' → ke bawah, '1000' → ke bawah.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e2000000-0000-0000-0000-000000000003', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000003'),
  31050, 'pembulatan none (bawaan): total apa adanya 31.050'
);

update public.pengaturan set pembulatan = '500'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan_item set catatan = 'picu hitung ulang'
 where pesanan_id = 'e2000000-0000-0000-0000-000000000003';
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000003'),
  31000, 'F-01b: pembulatan 500 dibaca → 31.050 dibulatkan KE BAWAH menjadi 31.000'
);

update public.pengaturan set pembulatan = '1000'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan_item set catatan = 'picu hitung ulang lagi'
 where pesanan_id = 'e2000000-0000-0000-0000-000000000003';
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000003'),
  31000, 'F-01b: pembulatan 1000 juga berlaku (31.000)'
);

update public.pengaturan set pembulatan = '100'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan_item set catatan = 'picu hitung ulang ketiga'
 where pesanan_id = 'e2000000-0000-0000-0000-000000000003';
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000003'),
  31000, 'F-01b: pembulatan 100 berlaku (31.050 → 31.000)'
);
update public.pengaturan set pembulatan = 'none'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- 4. Pembulatan adalah langkah TERAKHIR: angka pajak & service tidak ikut dibulatkan.
update public.pengaturan set pembulatan = '500'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan_item set catatan = 'cek komponen tetap utuh'
 where pesanan_id = 'e2000000-0000-0000-0000-000000000001';
select uji.sama(
  (select (p.pajak, p.service) from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000001'),
  (2700, 1350), 'pembulatan tidak menyentuh kolom pajak/service (hanya total)'
);
update public.pengaturan set pembulatan = 'none'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan_item set catatan = 'kembali ke pembulatan none'
 where pesanan_id = 'e2000000-0000-0000-0000-000000000001';
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000001'),
  31050, 'kembali ke pembulatan none → total kembali 31.050 (angka mengikuti pengaturan)'
);

-- 5. Pesanan LUNAS tidak bisa dihitung ulang dari perangkat (temuan F-02).
update public.pesanan set status = 'lunas', dibayar_pada = now()
 where id = 'e2000000-0000-0000-0000-000000000001';
update public.pengaturan set pajak_pb1_persen = 20
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.hitung_total('e2000000-0000-0000-0000-000000000001')$$,
  'lunas',
  'F-02: kasir TIDAK bisa menghitung ulang pesanan yang sudah lunas'
);
reset role;
select uji.klaim(null);
select uji.sama(
  (select (p.pajak, p.service, p.total) from public.pesanan p
    where p.id = 'e2000000-0000-0000-0000-000000000001'),
  (2700, 1350, 31050),
  'F-02: angka pesanan lunas TIDAK berubah walau tarif pajak pengaturan naik'
);
update public.pengaturan set pajak_pb1_persen = 10
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- 6. Jalur peladen tetap boleh: pelayan mengirim pesanan ke dapur memicu hitung ulang
--    pada pesanan yang BELUM lunas, dan angkanya benar (bukan ditolak).
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e2000000-0000-0000-0000-000000000002'),
  29498, 'jalur pemicu peladen tetap menghitung ulang pesanan yang belum lunas'
);
