-- ============================================================================
-- UJI: hanya metode bayar yang AKTIF boleh mencatat uang
-- Temuan AUD-3 2026-09-19 F-03 (K-2), dibuktikan nyata lewat probe sesi kerja:
-- docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql
-- ============================================================================
-- Aturan yang dijaga: metode bayar adalah PENGATURAN pemilik. Metode yang sudah
-- dinonaktifkan tidak boleh dipakai mencatat uang — kalau tidak, laporan penjualan
-- memuat pembayaran lewat kanal yang sudah dimatikan pemilik.
-- ============================================================================

-- 1. Pemilik menonaktifkan QRIS di restonya.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(
  (select count(*) from public.metode_bayar mb
    where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS' and mb.aktif),
  1::bigint, 'sebelum diubah: QRIS aktif'
);
update public.metode_bayar set aktif = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS';
select uji.sama(
  (select mb.aktif from public.metode_bayar mb
    where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS'),
  false, 'pemilik menonaktifkan QRIS'
);
reset role;
select uji.klaim(null);

-- 2. Kasir mencoba membayar dengan metode yang sudah dinonaktifkan → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, referensi, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 'REF-NONAKTIF', 'uji-nonaktif-1'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS'$$,
  'dinonaktifkan',
  'F-03: pembayaran lewat metode NONAKTIF ditolak sebelum baris uang tercipta'
);
select uji.sama(
  (select count(*) from public.pembayaran pb where pb.kunci_idempoten = 'uji-nonaktif-1'),
  0::bigint, 'tidak ada baris uang yang tercipta dari percobaan itu'
);

-- 3. Metode yang menjadi kembali aktif → jalur sah tetap terbuka.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
update public.metode_bayar set aktif = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS';
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
insert into public.pembayaran (pesanan_id, metode_id, jumlah, referensi, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 'REF-AKTIF', 'uji-nonaktif-2'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS';
select uji.sama(
  (select count(*) from public.pembayaran pb where pb.kunci_idempoten = 'uji-nonaktif-2'),
  1::bigint, 'metode yang aktif kembali boleh dipakai (jalur sah tidak ikut tertutup)'
);
reset role;
select uji.klaim(null);
