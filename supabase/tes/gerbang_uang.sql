-- ============================================================================
-- UJI: gerbang uang saat total pesanan belum dihitung (T1-10 + temuan audit AUD-3)
-- Membuktikan: pembayaran HANYA boleh dicatat bila total pesanan sudah dihitung.
--
-- Kenapa ada: audit AUD-3 (2026-09-17, dua laporan independen) menemukan pemeriksaan
-- "tidak boleh melebihi total" DILEWATI ketika total masih 0 — dan karena hitung_total
-- (T1-15) belum ada, SEMUA pesanan baru bertotal 0, sehingga Rp1.000.000 dua kali
-- diterima untuk satu pesanan bertotal 0 tanpa satu pun penjaga yang menghalangi,
-- sementara baris uang tidak bisa diubah/dihapus siapa pun (tidak ada jalan pemulihan).
-- Uji ini adalah kunci regresi untuk temuan K-1 itu.
-- ============================================================================

-- 1. Kasir membuat pesanan baru seperti di aplikasi: total belum dihitung (0).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pesanan (penyewa_id, cabang_id, tipe, kunci_idempoten)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001',
        'dinein', 'gerbang-uang-total-nol');

select uji.sama(
  (select p.total from public.pesanan p where p.kunci_idempoten = 'gerbang-uang-total-nol'),
  0,
  'pesanan baru dibuat tanpa total (0) — sama seperti keadaan nyata sebelum T1-15'
);

-- 2. Uang TIDAK boleh masuk selama total belum dihitung.
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select p.id, mb.id, 1000000, 1000000, 'gerbang-uang-1'
        from public.pesanan p, public.metode_bayar mb
       where p.kunci_idempoten = 'gerbang-uang-total-nol'
         and mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$, 'Total pesanan belum dihitung — pembayaran belum boleh dicatat', 'pembayaran pada pesanan yang totalnya belum dihitung DITOLAK');
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select p.id, mb.id, 1000000, 1000000, 'gerbang-uang-2'
        from public.pesanan p, public.metode_bayar mb
       where p.kunci_idempoten = 'gerbang-uang-total-nol'
         and mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$, 'Total pesanan belum dihitung — pembayaran belum boleh dicatat', 'percobaan kedua juga DITOLAK (bukan hanya percobaan pertama)');
select uji.sama(
  (select count(*)
     from public.pembayaran pb
     join public.pesanan p on p.id = pb.pesanan_id
    where p.kunci_idempoten = 'gerbang-uang-total-nol'),
  0::bigint,
  'tidak ada satu baris uang pun yang tercatat untuk pesanan bertotal 0'
);

-- 3. Kontrol positif: pesanan yang totalnya SUDAH dihitung tetap bisa dibayar.
insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 5000, 5000, 'gerbang-uang-3'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';
select uji.sama(
  (select coalesce(sum(pb.jumlah), 0)::integer from public.pembayaran pb
    where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  5000,
  'pesanan bertotal 62.100 tetap bisa menerima pembayaran (penjaga tidak memblokir yang sah)'
);

-- 4. Batas lebih bayar tetap berlaku pada pesanan bertotal terisi.
select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 100000, 100000, 'gerbang-uang-4'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$, 'Total pembayaran \(', 'pembayaran yang membuat total melebihi total pesanan tetap DITOLAK');
reset role;
select uji.klaim(null);
