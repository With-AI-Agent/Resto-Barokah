-- ============================================================================
-- UJI: ARAH PERGERAKAN STOK ditentukan JENIS, bukan tanda kiriman klien
-- Menutup temuan review PR putaran8 (laporan C, PR-03): `catat_stok('keluar', +5)`
-- MENAMBAH saldo — buku besar bilang keluar, saldo naik, sehingga selisih opname
-- bisa ditutup tanpa jejak yang jujur.
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (izin ubah_stok)
set local role authenticated;
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  20, 'kontrol: saldo awal Beras 20'
);

-- 1. KELUAR dengan tanda PLUS tetap MENGURANGI (inti perbaikan).
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'keluar', 5, 'keluar walau dikirim plus'),
  15::numeric, 'catat_stok(keluar, +5) MENGURANGI saldo: 20 → 15'
);
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  15, 'saldo benar-benar berkurang (bukan bertambah seperti dulu)'
);

-- 2. MASUK dengan tanda MINUS tetap MENAMBAH (tanda kiriman diabaikan).
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'masuk', -3, 'masuk walau dikirim minus'),
  18::numeric, 'catat_stok(masuk, -3) MENAMBAH saldo: 15 → 18'
);

-- 3. OPNAME/KOREKSI memakai delta apa adanya (arahnya memang dua arah).
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'opname', -8, 'opname kurang 8'),
  10::numeric, 'opname boleh mengurangi (delta dua arah)'
);
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'koreksi', 2, 'koreksi tambah 2'),
  12::numeric, 'koreksi boleh menambah'
);

-- 4. Opname/koreksi dengan NOL ditolak (tidak mengubah apa pun = tidak perlu dicatat).
select uji.harap_gagal(
  $$select public.catat_stok('beef1000-0000-0000-0000-000000000001', 'opname', 0, 'nol')$$,
  'opname tanpa perubahan ditolak'
);
select uji.harap_gagal(
  $$select public.catat_stok('beef1000-0000-0000-0000-000000000001', 'keluar', 0, 'nol')$$,
  'pergerakan tanpa perubahan ditolak'
);

-- 5. Bahan yang tidak ada tetap ditolak dengan pesan jelas.
select uji.harap_gagal(
  $$select public.catat_stok('beef1000-0000-0000-0000-0000000000ff', 'masuk', 1, 'bahan hantu')$$,
  'bahan yang tidak ada ditolak'
);

-- 6. Setiap pergerakan tetap meninggalkan baris buku besar (tidak ada perubahan diam-diam).
select uji.sama(
  (select count(*) from public.stok_pergerakan p
    where p.stok_bahan_id = 'beef1000-0000-0000-0000-000000000001'
      and p.alasan in ('keluar walau dikirim plus', 'masuk walau dikirim minus',
                       'opname kurang 8', 'koreksi tambah 2')),
  4::bigint, 'empat pergerakan tercatat sebagai baris buku besar'
);
select uji.sama(
  (select sum(p.jumlah)::int from public.stok_pergerakan p
    where p.stok_bahan_id = 'beef1000-0000-0000-0000-000000000001'
      and p.alasan in ('keluar walau dikirim plus', 'masuk walau dikirim minus',
                       'opname kurang 8', 'koreksi tambah 2')),
  -8, 'jumlah baris buku besar (-5+3-8+2) sama dengan perubahan saldo'
);

reset role;
select uji.klaim(null);
