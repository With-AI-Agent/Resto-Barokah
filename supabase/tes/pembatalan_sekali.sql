-- ============================================================================
-- UJI: satu target pembatalan = satu jejak (idempoten terhadap kiriman ulang)
-- Temuan AUD-3 2026-09-19 F-05 (K-2), dibuktikan nyata lewat probe sesi kerja:
-- docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql
-- ============================================================================
-- Aturan yang dijaga: pembatalan adalah kejadian uang. Kiriman ULANG baris yang sama
-- (klik ganda kasir, antrean perangkat offline, percobaan ulang jaringan) TIDAK boleh
-- dicatat sebagai kejadian kedua — laporan kerugian tidak boleh menghitung satu aksi
-- dua kali. Yang ditolak adalah target yang SUDAH batal, bukan alasan yang sama.
-- ============================================================================

-- 1. Pesanan sebelum dapur: pembatalan SATU item dua kali → kiriman kedua ditolak.
select uji.klaim(null);   -- pemilik tabel: menyiapkan pesanan uji
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e5000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 991, current_date, 'dinein', 'draf', 'uji-sekali-1');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e5000000-0000-0000-0000-000000000101', 'e5000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2, 54000);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (izin void sebelum dapur)
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000101',
        'sebelum_dapur', 'salah input kasir');
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
      values ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000101',
              'sebelum_dapur', 'salah input kasir')$$,
  'sudah dibatalkan',
  'F-05: kiriman ULANG pembatalan item yang sama ditolak'
);
-- Walau alasannya diganti, target yang sudah batal tetap tidak bisa dibatalkan lagi.
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
      values ('e5000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000101',
              'sebelum_dapur', 'alasan berbeda, target sama')$$,
  'sudah dibatalkan',
  'F-05: ganti alasan tidak menghidupkan kembali target yang sudah batal'
);
select uji.sama(
  (select count(*) from public.pembatalan pb where pb.pesanan_id = 'e5000000-0000-0000-0000-000000000001'),
  1::bigint, 'jejak pembatalan tetap SATU untuk satu aksi'
);
select uji.sama(
  (select coalesce(sum(pb.nilai_kerugian), 0) from public.pembatalan pb
    where pb.pesanan_id = 'e5000000-0000-0000-0000-000000000001'),
  54000::bigint, 'kerugian tidak tergandakan (hanya 54.000, bukan 108.000)'
);
reset role;
select uji.klaim(null);

-- 2. Kontrol positif: item LAIN pada pesanan yang sama tetap bisa dibatalkan.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e5000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 992, current_date, 'dinein', 'draf', 'uji-sekali-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e5000000-0000-0000-0000-000000000201', 'e5000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('e5000000-0000-0000-0000-000000000202', 'e5000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 5000, 1, 5000);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('e5000000-0000-0000-0000-000000000002', 'e5000000-0000-0000-0000-000000000201',
        'sebelum_dapur', 'pelanggan berubah pikiran');
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('e5000000-0000-0000-0000-000000000002', 'e5000000-0000-0000-0000-000000000202',
        'sebelum_dapur', 'pelanggan berubah pikiran');
select uji.sama(
  (select count(*) from public.pembatalan pb where pb.pesanan_id = 'e5000000-0000-0000-0000-000000000002'),
  2::bigint, 'kontrol: dua item BERBEDA tetap bisa dibatalkan masing-masing satu kali'
);
reset role;
select uji.klaim(null);

-- 3. Pembatalan tingkat PESANAN dua kali → kiriman kedua ditolak.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e5000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 993, current_date, 'dinein', 'draf', 'uji-sekali-3');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e5000000-0000-0000-0000-000000000301', 'e5000000-0000-0000-0000-000000000003',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, alasan)
values ('e5000000-0000-0000-0000-000000000003', 'sebelum_dapur', 'pelanggan membatalkan seluruh pesanan');
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, tahap, alasan)
      values ('e5000000-0000-0000-0000-000000000003', 'sebelum_dapur', 'pelanggan membatalkan seluruh pesanan')$$,
  'sudah dibatalkan',
  'F-05: pembatalan tingkat pesanan juga tidak bisa diulang'
);
reset role;
select uji.klaim(null);

-- 4. Jalur PELADEN tetap boleh menulis jejak apa pun (pemicu & fungsi peladen bisa
--    memperbaiki keadaan tanpa tertahan aturan klien) — dibuktikan oleh uji pembayaran
--    yang memakai peran pemilik tabel, mis. `supabase/tes/pembayaran.sql`.
select uji.sama(
  (select count(*) from public.pembatalan pb
    where pb.pesanan_id = 'e5000000-0000-0000-0000-000000000003'),
  1::bigint, 'kontrol: peran pemilik tabel tetap bisa menyiapkan data (jejak tetap satu)'
);
