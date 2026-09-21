-- ============================================================================
-- UJI: VARIAN/TAMBAHAN TIDAK DIREKAM DIAM-DIAM TANPA HARGA
-- Menutup temuan audit AUD-3 2026-09-18 F-05 (K-2): varian & tambahan diterima
-- sebagai jsonb tetapi tidak pernah dihargai (subtotal = harga dasar saja),
-- sementara menulis harga yang benar DITOLAK pemicu harga jujur — jadi setiap
-- pesanan bervarian KURANG TAGIH tanpa jejak. Selama mesin harga varian
-- (T1-12/T1-19) belum ada, jalur ini ditutup gagal-aman.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (tanpa izin ubah_harga)
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, varian)
      values ('eeee0000-0000-0000-0000-000000000010','beef0000-0000-0000-0000-000000000001',
              'Nasi Goreng Jumbo', 27000, 1, '{"nama":"Jumbo"}')$$, 'Varian/tambahan belum bisa dihargai otomatis \(menyusul T1-12\)\. Catat sebagai catatan denga', 'kasir tidak bisa merekam varian yang harganya belum bisa dihitung (dulu tersimpan tanpa harga tambahan)');
select uji.harap_gagal_sebab($$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, tambahan)
      values ('eeee0000-0000-0000-0000-000000000010','beef0000-0000-0000-0000-000000000001',
              'Nasi Goreng + Kerupuk', 27000, 1, '["Kerupuk"]')$$, 'Varian/tambahan belum bisa dihargai otomatis \(menyusul T1-12\)\. Catat sebagai catatan denga', 'tambahan berbayar juga tidak bisa direkam tanpa harga');
-- Item biasa tetap boleh.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
values ('eeee0000-0000-0000-0000-000000000010','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1);
select uji.sama(
  (select pi.subtotal from public.pesanan_item pi
    where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pi.nama_saat_itu = 'Nasi Goreng' and pi.qty = 1),
  27000, 'item tanpa varian tetap bisa dicatat (jalur sah terbuka)'
);
reset role;
select uji.klaim(null);

-- Pemegang izin ubah_harga boleh mencatat varian dengan harga yang benar (jalan keluar sampai T1-12).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (punya ubah_harga)
set local role authenticated;
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, varian, tambahan)
values ('eeee0000-0000-0000-0000-000000000010','beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng Jumbo + Kerupuk', 34000, 1, '{"nama":"Jumbo"}', '["Kerupuk"]');
select uji.sama(
  (select pi.subtotal from public.pesanan_item pi
    where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and pi.harga_saat_itu = 34000),
  34000, 'pemegang izin ubah_harga mencatat varian dengan harga benarnya (34.000)'
);
reset role;
select uji.klaim(null);
