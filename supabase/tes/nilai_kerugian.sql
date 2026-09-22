-- ============================================================================
-- UJI: NILAI KERUGIAN PEMBATALAN — dihitung peladen, bukan dikarang klien
-- Menutup temuan review putaran11 PR-03 (K-3, jejak/uang):
--   Dulu nilai non-nol kiriman klien diterima apa adanya → kasir bisa menulis kerugian
--   Rp1 untuk pesanan Rp54.000 (laporan kerugian under-report) atau angka besar
--   sesukanya; kolomnya append-only sehingga angka karangan itu bertahan selamanya.
-- ============================================================================

insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, subtotal, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b001','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 811, current_date, 'dinein', 'draf', 54000, 54000, 'kerugian-uji');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000b001','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2,54000);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (punya void_sebelum_dapur)
set local role authenticated;

-- 1. Angka KARANGAN → DITOLAK (inti temuan PR-03).
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, alasan, nilai_kerugian)
      values ('00000000-0000-0000-0000-00000000b001', 'sebelum_dapur', 'barang salah', 1)$$, 'Nilai kerugian dihitung peladen dari salinan harga \(', 'nilai kerugian yang dikarang klien (1 rupiah) DITOLAK');
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, alasan, nilai_kerugian)
      values ('00000000-0000-0000-0000-00000000b001', 'sebelum_dapur', 'barang salah', 999999)$$, 'Nilai kerugian dihitung peladen dari salinan harga \(', 'nilai kerugian yang dibesarkan klien (999.999) DITOLAK');

-- 2. Mengirim 0 = "tolong isi peladen" → DIISI dari salinan harga (54.000).
insert into public.pembatalan (pesanan_id, tahap, alasan, nilai_kerugian)
values ('00000000-0000-0000-0000-00000000b001', 'sebelum_dapur', 'barang salah', 0);
select uji.sama(
  (select b.nilai_kerugian::bigint from public.pembatalan b
     where b.pesanan_id = '00000000-0000-0000-0000-00000000b001'),
  54000::bigint,
  'nilai kerugian diisi PELADEN dari salinan harga (54.000), bukan angka klien'
);

-- 3. Baris item: angka yang SAMA dengan hitungan peladen tetap boleh (tidak kaku).
--    CATATAN (putaran13): uji ini dulu menambah item pada pesanan yang SUDAH dibatalkan
--    di langkah 2. Sejak 0014 pesanan yang sudah batal tidak boleh diubah lagi, jadi
--    langkah ini memakai pesanan KEDUA yang masih berjalan — maksudnya tidak berubah.
reset role;
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b003','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 812, current_date, 'dinein', 'draf', 'kerugian-uji-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000b002','00000000-0000-0000-0000-00000000b003',
        'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2,54000);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan, nilai_kerugian)
values ('00000000-0000-0000-0000-00000000b003','00000000-0000-0000-0000-00000000b002','sebelum_dapur','salah masak', 54000);
select uji.sama(
  (select b.nilai_kerugian::bigint from public.pembatalan b
     where b.pesanan_item_id = '00000000-0000-0000-0000-00000000b002'),
  54000::bigint,
  'angka yang SAMA dengan hitungan peladen tetap diterima (tidak menutup jalur sah)'
);
