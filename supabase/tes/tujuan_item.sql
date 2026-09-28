-- ============================================================================
-- UJI: TUJUAN ITEM DAPUR/BAR — pemisahan otomatis, salinan kekal (T4-02, PRD M5)
-- Membuktikan: (1) tujuan item diturunkan OTOMATIS dari kategori saat pesanan dibuat
-- (spoof dari perangkat diabaikan); (2) tujuan = salinan — kategori diubah kemudian
-- tidak menggeser pesanan lama; (3) salinan tidak bisa ditulis ulang; (4) semua item
-- PASTI punya tujuan (tidak ada yang menghilang dari kedua layar); (5) satu pesanan
-- boleh muncul di dua layar, masing-masing melihat bagiannya.
-- ============================================================================

-- Persiapan (PELADEN): dua kategori uji — satu ditandai 'bar', satu dibiarkan 'dapur'.
insert into public.kategori_menu (id, penyewa_id, nama, tujuan)
values ('cafe0000-0000-0000-0000-000000000030','11111111-1111-1111-1111-111111111111', 'Minuman Bar Uji', 'bar'),
       ('cafe0000-0000-0000-0000-000000000031','11111111-1111-1111-1111-111111111111', 'Makanan Dapur Uji', 'dapur');
insert into public.menu_item (id, penyewa_id, kategori_id, nama, harga, jenis)
values ('beef0000-0000-0000-0000-000000000030','11111111-1111-1111-1111-111111111111',
        'cafe0000-0000-0000-0000-000000000030', 'Jus Jeruk Uji', 12000, 'minuman'),
       ('beef0000-0000-0000-0000-000000000031','11111111-1111-1111-1111-111111111111',
        'cafe0000-0000-0000-0000-000000000031', 'Ayam Goreng Uji', 23000, 'makanan');
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f052','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 91, current_date, 'dinein', 'dikirim', 'tujuan-item-uji');

-- 1. Tujuan DITURUNKAN otomatis dari kategori — kiriman 'tujuan' dari perangkat
--    diabaikan (item kategori bar tetap 'bar' walau minta 'dapur').
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal, tujuan)
values ('00000000-0000-0000-0000-00000000f152','00000000-0000-0000-0000-00000000f052',
        'beef0000-0000-0000-0000-000000000030','Jus Jeruk Uji',12000,1,12000, 'dapur');
select uji.sama(
  (select pi.tujuan from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f152'),
  'bar', 'tujuan mengikuti kategori (bar), bukan kiriman perangkat (dapur)');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000f153','00000000-0000-0000-0000-00000000f052',
        'beef0000-0000-0000-0000-000000000031','Ayam Goreng Uji',23000,1,23000);
select uji.sama(
  (select pi.tujuan from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f153'),
  'dapur', 'kategori bawaan = tujuan dapur');

-- 2. SEMUA item pasti punya tujuan (tidak ada yang hilang dari kedua layar).
select uji.sama(
  (select count(*) from public.pesanan_item pi where pi.tujuan is null),
  0::bigint, 'tidak ada item tanpa tujuan');

-- 3. Satu pesanan muncul di dua layar — masing-masing melihat bagiannya sendiri.
select uji.sama(
  (select count(*) from public.pesanan_item pi
    where pi.pesanan_id = '00000000-0000-0000-0000-00000000f052' and pi.tujuan = 'bar'),
  1::bigint, 'layar bar melihat tepat 1 bagiannya');
select uji.sama(
  (select count(*) from public.pesanan_item pi
    where pi.pesanan_id = '00000000-0000-0000-0000-00000000f052' and pi.tujuan = 'dapur'),
  1::bigint, 'layar dapur melihat tepat 1 bagiannya');

-- 4. Salinan TIDAK bisa ditulis ulang setelah lahir.
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set tujuan = 'dapur' where id = '00000000-0000-0000-0000-00000000f152'$$,
  'Tujuan item adalah salinan',
  'menulis ulang tujuan item ditolak');
select uji.sama(
  (select pi.tujuan from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f152'),
  'bar', 'tujuan item tetap bar setelah percobaan tulis ulang');

-- 5. Mengubah tujuan KATEGORI tidak menggeser pesanan lama (salinan saat itu);
--    item BARU di kategori yang sama mengikuti setelan baru.
update public.kategori_menu set tujuan = 'dapur' where id = 'cafe0000-0000-0000-0000-000000000030';
select uji.sama(
  (select pi.tujuan from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f152'),
  'bar', 'pesanan lama tetap pada tujuan saat itu (bar)');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000f154','00000000-0000-0000-0000-00000000f052',
        'beef0000-0000-0000-0000-000000000030','Jus Jeruk Uji',12000,1,12000);
select uji.sama(
  (select pi.tujuan from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f154'),
  'dapur', 'item baru mengikuti setelan kategori terbaru (dapur)');

-- 6. Nilai tujuan kategori di luar daftar ditolak database.
select uji.harap_gagal_sebab(
  $$update public.kategori_menu set tujuan = 'kolam' where id = 'cafe0000-0000-0000-0000-000000000031'$$,
  'kategori_menu_tujuan_check|check constraint',
  'tujuan kategori di luar dapur/bar ditolak');

-- 7. Item dari menu yang tidak ada/tidak layak jual ditolak penjaga menu (0012).
select uji.harap_gagal_sebab(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
    values ('00000000-0000-0000-0000-00000000f052', 'beef0000-0000-0000-0000-000000000000', 'Hantu', 1000, 1, 1000)$$,
  'Menu atau pesanan tidak ditemukan|Menu tidak ditemukan atau tidak dijual',
  'item dari menu hantu ditolak penjaga menu');
select uji.klaim(null);
