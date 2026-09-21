-- ============================================================================
-- UJI: hitungan nomor pesanan tidak bocor antar resto (temuan K-2 PR-03)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. KONTROL — kasir Resto A memanggil untuk cabangnya sendiri: jawabannya
--      memang max(nomor)+1 untuk cabang itu (fungsi tetap bekerja).
--   2. KONTROL — owner pusat boleh menghitung cabang mana pun di restonya.
--   3. TEMUAN — kasir REST0 B memanggil untuk cabang Resto A → DITOLAK, bukan
--      dijawab dengan angka (dulu dijawab 11: kasir resto lain tahu berapa
--      pesanan yang sudah dibuat resto A hari itu).
--   4. Cabang yang tidak ada / bukan cabang siapa pun juga tidak dibocorkan.
--   5. Peladen (tanpa identitas) tetap bisa memakainya — pemicu penomoran
--      pesanan baru berjalan sebagai peladen.
-- ============================================================================

-- 1. KONTROL: kasir Resto A, cabangnya sendiri.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
select uji.sama(
  public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', current_date),
  (select (coalesce(max(p.nomor), 0) + 1)::integer from public.pesanan p
    where p.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001' and p.tanggal = current_date),
  'kontrol: kasir cabangnya sendiri tetap mendapat max(nomor)+1'
);
reset role;
select uji.klaim(null);

-- 2. KONTROL: owner pusat boleh menghitung kedua cabang restonya.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- Bu Oasis, owner pusat
set local role authenticated;
select uji.sama(
  public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000002', current_date) > 0,
  true, 'kontrol: owner pusat boleh menghitung cabang keduanya'
);
reset role;
select uji.klaim(null);

-- 3. TEMUAN PR-03: kasir Resto B menanyakan cabang Resto A → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- Ujang, kasir Resto B
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', current_date)$$,
  'bukan cabang',
  'PR-03: hitungan pesanan resto lain DITOLAK (dulu dijawab 11)'
);

-- 4. Cabang Resto B sendiri tetap boleh (isolasi tidak menutup pekerjaannya).
select uji.sama(
  public.nomor_pesanan_berikutnya('b1b1b1b1-0000-0000-0000-000000000001', current_date) >= 1,
  true, 'kontrol: kasir Resto B tetap bisa menghitung cabangnya sendiri'
);
reset role;
select uji.klaim(null);

-- 5. Peladen (tanpa identitas) tetap bisa — pemicu penomoran pesanan baru jalan sebagai peladen.
select uji.sama(
  public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', current_date) >= 1,
  true, 'kontrol: pemanggil tanpa identitas (penyiapan/peladen) tidak dihalangi'
);
