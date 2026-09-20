-- ============================================================================
-- UJI: saldo stok hanya berubah lewat buku besar — termasuk saat klien nakal
-- Temuan audit AUD-3 K-2 (A F-06, 2026-09-17): penjaga "jangan ubah jumlah
-- langsung" memakai penanda sesi `app.stok_dari_buku_besar` yang bisa dipasang
-- klien sendiri (`select set_config('app.stok_dari_buku_besar','1',true)`),
-- sehingga dapur bisa menulis angka stok berapa pun tanpa baris buku besar —
-- opname, HPP, dan laporan bahan jadi tidak bisa dipercaya.
-- Aturan yang dikunci: penjaga memakai bukti yang TIDAK bisa dipalsukan klien
-- (sedang berjalan sebagai pemilik tabel / peladen), bukan penanda sesi.
-- ============================================================================

-- 1. Dapur mengubah saldo langsung → DITOLAK (penjaga dasar masih bekerja).
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (izin ubah_stok)
set local role authenticated;
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  20, 'kontrol: saldo awal Beras 20'
);
select uji.harap_gagal_sebab($$update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001'$$, 'Jumlah stok hanya boleh berubah lewat catatan pergerakan stok \(bukan ditulis langsung\)', 'ubah saldo stok langsung ditolak');

-- 2. Memasang penanda sesi sendiri TIDAK boleh membuka penjaga.
select set_config('app.stok_dari_buku_besar', '1', true);
select uji.harap_gagal_sebab($$update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001'$$, 'Jumlah stok hanya boleh berubah lewat catatan pergerakan stok \(bukan ditulis langsung\)', 'penanda sesi buatan klien TIDAK membuka penjaga saldo stok');
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  20, 'saldo tidak berubah setelah percobaan curang'
);

-- 3. Jalur resmi lewat buku besar tetap bekerja dan saldo ikut menambah.
select set_config('app.stok_dari_buku_besar', '0', true);
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'masuk', 5, 'uji buku besar'),
  25::numeric, 'catat_stok mengembalikan saldo baru (20 + 5)'
);
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  25, 'saldo bertambah lewat catatan pergerakan stok (jalur sah)'
);
select uji.sama(
  (select count(*) from public.stok_pergerakan p
    where p.stok_bahan_id = 'beef1000-0000-0000-0000-000000000001' and p.alasan = 'uji buku besar'),
  1::bigint, 'pergerakan stok tercatat sebagai baris buku besar'
);
reset role;
select uji.klaim(null);
