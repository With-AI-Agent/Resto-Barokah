-- ============================================================================
-- UJI: pesanan yang sudah TUTUP (lunas/batal) beku total bagi perangkat (temuan H F-07)
-- ============================================================================
-- Temuan aslinya (probe `docs/uji/audit/probe-2026-09-21/h-f07-kolom-non-uang.sql`):
-- pembekuan pesanan tertutup dulu hanya menjaga nilai uang, item, dan stempel
-- lifecycle — kolom jejak lain (catatan, tipe, shift) masih bisa ditulis perangkat
-- SETELAH lunas/batal, sehingga laporan membaca jejak yang tidak pernah terjadi.
--
-- Yang dibuktikan berkas ini:
--   1. KONTROL — pesanan masih draf: kasir boleh mengubah catatan (tidak beku).
--   2. Sesudah LUNAS: UPDATE jejak non-uang dari perangkat → DITOLAK, sebabnya
--      menyebut status pesanan (dipatok — bukan penolakan apa pun).
--   3. Sesudah BATAL: UPDATE dari perangkat → DITOLAK dengan sebab yang sama.
--   4. Jalur PELADEN tetap bebas: pemilik tabel mengoreksi catatan pesanan lunas → SAH.
--   5. Angka & jejak pesanan lunas tidak berubah sedikit pun setelah percobaan itu.
-- ============================================================================

-- Penyiapan (pemilik tabel): tiga pesanan Cabang A1 + item.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('ea000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 961, current_date, 'dinein', 'draf', 'tertutup-beku-1'),
       ('ea000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 962, current_date, 'dinein', 'draf', 'tertutup-beku-2'),
       ('ea000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 963, current_date, 'dinein', 'draf', 'tertutup-beku-3');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('ea000000-0000-0000-0000-000000000101', 'ea000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('ea000000-0000-0000-0000-000000000102', 'ea000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('ea000000-0000-0000-0000-000000000103', 'ea000000-0000-0000-0000-000000000003',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);

-- Jalur peladen menutup pesanan 1 (lunas) dan 2 (batal); pesanan 3 tetap draf (kontrol).
update public.pesanan set status = 'lunas', dibayar_pada = now()
 where id = 'ea000000-0000-0000-0000-000000000001';
update public.pesanan set status = 'batal', dibatalkan_pada = now(), alasan_batal = 'bahan habis'
 where id = 'ea000000-0000-0000-0000-000000000002';

-- 1. KONTROL: pesanan masih draf — kasir boleh mengubah catatan.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
update public.pesanan set catatan = 'tanpa sambal'
 where id = 'ea000000-0000-0000-0000-000000000003';
reset role;
select uji.sama(
  (select catatan from public.pesanan where id = 'ea000000-0000-0000-0000-000000000003'),
  'tanpa sambal',
  'kontrol: pesanan draf tidak beku — catatan boleh diubah kasir'
);

-- 2. Sesudah LUNAS: jejak non-uang dikarang perangkat → DITOLAK karena status.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.pesanan
       set catatan = 'catatan dikarang sesudah lunas', tipe = 'takeaway'
     where id = 'ea000000-0000-0000-0000-000000000001'$$,
  'Pesanan sudah ditutup \(status lunas\)',
  'jejak pesanan lunas beku bagi perangkat'
);
reset role;

-- 3. Sesudah BATAL: sama — DITOLAK karena status.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.pesanan set catatan = 'jejak batal dikarang'
     where id = 'ea000000-0000-0000-0000-000000000002'$$,
  'Pesanan sudah ditutup \(status batal\)',
  'jejak pesanan batal beku bagi perangkat'
);
reset role;

-- 4. Jalur PELADEN tetap bebas (koreksi resmi tidak boleh ikut beku).
update public.pesanan set catatan = 'koreksi resmi peladen'
 where id = 'ea000000-0000-0000-0000-000000000001';
select uji.sama(
  (select catatan from public.pesanan where id = 'ea000000-0000-0000-0000-000000000001'),
  'koreksi resmi peladen',
  'jalur peladen tetap boleh mengoreksi pesanan tertutup'
);

-- 5. Jejak & uang pesanan lunas tetap utuh setelah percobaan perangkat.
select uji.sama(
  (select tipe from public.pesanan where id = 'ea000000-0000-0000-0000-000000000001'),
  'dinein',
  'tipe pesanan lunas tidak berubah oleh percobaan perangkat'
);
select uji.sama(
  (select total from public.pesanan where id = 'ea000000-0000-0000-0000-000000000001'),
  (select subtotal + pajak + service - total_diskon from public.pesanan
    where id = 'ea000000-0000-0000-0000-000000000001'),
  'uang pesanan lunas tetap konsisten (subtotal+pajak+service-diskon) setelah percobaan perangkat'
);
