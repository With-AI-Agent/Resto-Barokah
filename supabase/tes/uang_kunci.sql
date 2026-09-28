-- ============================================================================
-- UJI: kunci serialisasi jalur uang ADA & kelakuan tidak berubah — AUD-3 F-12
-- Temuan AUD-3 2026-09-19 F-12 (K-1, DUGAAN): hitung-ulang + cap tanpa serialisasi.
-- ============================================================================
-- Batas jujur yang dicatat (sama seperti F-13): uji concurrency yang diminta
-- laporan (dua transaksi bersamaan) BELUM bisa dijalankan — PGlite satu koneksi.
-- Yang dijaga mesin di sini adalah SIFAT yang bisa diperiksa langsung:
--   1. `hitung_total` (§6) mengambil kunci baris pesanan (`for update`);
--   2. `picu_diskon_awal_pesanan` (pemicu BEFORE pertama, 0021) mengambil kunci
--      yang sama — keputusan cap dibuat sesudah kunci, bukan sebelumnya;
--   3. jalur normal tidak berubah (diskon sah diterima + dihitung ulang);
--   4. penjaga cap tidak rusak (diskon kedua tetap ditolak satu-per-transaksi).
-- Kalau seseorang melepas salah satu kunci, uji ini MERAH — itulah bukti yang bisa
-- diberikan sekarang, tanpa berpura-pura sudah menguji concurrency.
-- ============================================================================

-- 1. Sifat serialisasi: kedua fungsi menyebut `for update` di KODE badannya.
--    Komentar `--` dilucuti dulu (`regexp_replace`): komentar yang menjelaskan kunci
--    ("tanpa `for update` ...") TIDAK BOLEH ikut memuaskan pemeriksaan — kalau tidak,
--    melepas baris kuncinya pun tetap hijau (ditemukan saat uji mutasi pertama).
select uji.harap(
  (select regexp_replace(pg_get_functiondef(p.oid), '--[^\n]*', '', 'g') like '%for update%'
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'hitung_total'),
  'F-12: hitung_total mengambil kunci baris pesanan (for update) — §6'
);
select uji.harap(
  (select regexp_replace(pg_get_functiondef(p.oid), '--[^\n]*', '', 'g') like '%for update%'
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'picu_diskon_awal_pesanan'),
  'F-12: picu_diskon_awal_pesanan mengambil kunci baris pesanan (for update) — 0021'
);

-- 2. Jalur normal tidak berubah: diskon sah 2.000 diterima + dihitung ulang.
--    (Rina kasir: 2.000 di bawah batas nominal 25.000 & 3,7% di bawah batas 5%.)
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Pusat
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 2000, 2000, 'uji kunci serialisasi');
select uji.sama(
  (select p.total_diskon from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  2000, 'diskon sah diterima dan total_diskon dihitung ulang (= 2.000)'
);

-- 3. Penjaga cap tidak rusak: diskon KEDUA tetap ditolak (satu per transaksi).
--    Satu-satunya sebab penolakan = aturan jumlah (1.000 lolos izin & jumlah-cap).
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
    values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1000, 1000, 'diskon kedua')$$,
  'hanya mengizinkan satu diskon',
  'aturan satu-diskon: baris kedua tetap ditolak sesudah kunci 0021'
);
reset role;
select uji.klaim(null);
