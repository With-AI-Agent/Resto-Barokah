-- ============================================================================
-- UJI: void SATU item TIDAK ikut membatalkan seluruh pesanan (temuan PR-02, K-2)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. KONTROL — pesanan 2 item, satu item dibatalkan lewat baris `pembatalan` resmi
--      (kasir berizin void pra-dapur): item itu batal, item lain TETAP HIDUP.
--   2. Pesanan TIDAK lagi ikut berstatus `batal` (dulu selalu ikut — temuan PR-02).
--   3. Angka uang dihitung ulang: item batal tidak ditagih.
--   4. Sisa tagihan MASIH BISA DIBAYAR (dulu ditolak karena pesanan sudah "batal").
--   5. Menutup pesanan tetap benar bila memang seluruh item habis: membatalkan item
--      hidup TERAKHIR (atau pembatalan tingkat pesanan) → status `batal`.
--
-- Pesanan uji dibuat di dalam berkas ini (id khusus `d1…`) supaya tidak mengganggu
-- pesanan contoh milik berkas uji lain. Semua langkah dari kursi KASIR, bukan pemilik tabel.
-- ============================================================================

-- Penyiapan (sebagai pemilik tabel): pesanan Cabang A1, 2 item, belum ke dapur.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('d1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 941, current_date, 'dinein', 'draf', 'void-satu-item');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('d1000000-0000-0000-0000-0000000000a1', 'd1000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('d1000000-0000-0000-0000-0000000000a2', 'd1000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 8000, 2, 16000);

-- 1–4. KASIR membatalkan SATU item sebelum dapur (izin void pra-dapur).
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('d1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-0000000000a1',
        'sebelum_dapur', 'pelanggan membatalkan satu item');
reset role;

-- 1. Item yang dibatalkan benar-benar batal; item lain HIDUP.
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'd1000000-0000-0000-0000-0000000000a1'),
  'batal', 'PR-02: item yang disebut baris pembatalan menjadi batal'
);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'd1000000-0000-0000-0000-0000000000a2'),
  'baru', 'PR-02: item lain TETAP HIDUP (dulu seluruh pesanan ikut dibatalkan)'
);

-- 2. Pesanan TIDAK ikut batal.
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd1000000-0000-0000-0000-000000000001'),
  'draf', 'PR-02: pesanan tetap hidup setelah SATU item dibatalkan (temuan ditutup)'
);

-- 3. Uang dihitung ulang: hanya item hidup yang ditagih (Es Teh 2 × 8.000 = 16.000).
select uji.sama(
  (select p.subtotal from public.pesanan p where p.id = 'd1000000-0000-0000-0000-000000000001'),
  16000, 'PR-02: subtotal dihitung ulang dari item hidup (item batal tidak ditagih)'
);

-- 4. Sisa tagihan MASIH BISA DIBAYAR oleh kasir (dulu ditolak: "pesanan sudah batal").
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'd1000000-0000-0000-0000-000000000001', mb.id, 8000, 10000, 'void-satu-item-bayar'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';
reset role;
select uji.sama(
  (select coalesce(sum(pb.jumlah), 0)::bigint from public.pembayaran pb
    where pb.pesanan_id = 'd1000000-0000-0000-0000-000000000001'),
  8000::bigint, 'PR-02: pembayaran item yang masih hidup DITERIMA (dulu buntu)'
);

-- 5a. Menghabiskan item hidup terakhir tetap menutup pesanan → status `batal`.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$delete from public.pembayaran where pesanan_id = 'd1000000-0000-0000-0000-000000000001'$$,
  'pembayaran|bayar',
  'kontrol: baris pembayaran tidak bisa dihapus dari perangkat'
);
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('d1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-0000000000a2',
        'sebelum_dapur', 'sisa item dibatalkan juga');
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd1000000-0000-0000-0000-000000000001'),
  'batal', 'PR-02: pesanan ditutup bila tidak ada item hidup lagi'
);

-- 5b. Pembatalan tingkat PESANAN (tanpa item) tetap langsung menutup pesanan.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('d1000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 942, current_date, 'dinein', 'draf', 'void-pesanan-penuh');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('d1000000-0000-0000-0000-0000000000b1', 'd1000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('d1000000-0000-0000-0000-0000000000b2', 'd1000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 8000, 1, 8000);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, alasan)
values ('d1000000-0000-0000-0000-000000000002', 'sebelum_dapur', 'pelanggan pergi sebelum makan');
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd1000000-0000-0000-0000-000000000002'),
  'batal', 'PR-02: pembatalan tingkat pesanan tetap langsung menutup pesanan'
);
select uji.sama(
  (select count(*) from public.pesanan_item pi
    where pi.pesanan_id = 'd1000000-0000-0000-0000-000000000002' and pi.status <> 'batal'),
  0::bigint, 'PR-02: pembatalan tingkat pesanan tidak meninggalkan item hidup'
);
select uji.klaim(null);
