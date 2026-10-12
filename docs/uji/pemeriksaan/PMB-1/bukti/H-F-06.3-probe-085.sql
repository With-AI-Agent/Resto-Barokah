-- ============================================================================
-- PROBE HAKIM — H-F-06.3 (2026-10-06), verifikasi ulang PMB1-F-085 (migrasi 0100)
-- ============================================================================
-- Perilaku yang DIHARAPKAN hari ini (sesudah perbaikan 0100) → harus LULUS.
--   A. Admin cabang A1 (hanya bertugas di cabang A1) DITOLAK saat menerbitkan
--      kode untuk cabang A2 — kode FORBIDDEN, dan tidak ada baris tersimpan.
--   B. Kontrol: admin A1 tetap bisa menerbitkan kode untuk cabangnya sendiri;
--      kode yang diterbitkan 8 karakter [A-Z0-9] (silang-uji PMB1-F-086).
--   C. Kontrol: owner_pusat tetap leluasa untuk semua cabang penyewanya.
--   D. Kontrol negatif: lintas penyewa ditolak (CABANG_TIDAK_VALID), pemegang
--      tanpa izin kelola_pegawai ditolak (FORBIDDEN).
--   E. Pagar dasarnya diuji langsung dari kursi peran: cabang_pantau_saya.
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.3-probe-085.sql
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel ---------------------------------------
reset role;
delete from public.kode_pendaftaran_perangkat
 where dibuat_oleh in (
   '90000000-0000-0000-0000-000000000002',
   '90000000-0000-0000-0000-000000000003',
   '90000000-0000-0000-0000-000000000004',
   '90000000-0000-0000-0000-000000000007'
 );

-- --- A. admin cabang A1 → cabang A2 DITOLAK -------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  public.cabang_pantau_saya('a1a1a1a1-0000-0000-0000-000000000002'),
  false,
  'F-085: Pak Andi (admin A1) bukan pemantau cabang A2'
);
select uji.sama(
  public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000002', 'Perangkat Lintas Cabang', 'pos', array['kasir']
  )->>'kode',
  'FORBIDDEN',
  'F-085: admin cabang DITOLAK (FORBIDDEN) menerbitkan kode untuk cabang di luar pantauannya'
);
reset role;
select uji.sama(
  (select count(*) from public.kode_pendaftaran_perangkat
    where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'
      and dibuat_oleh = '90000000-0000-0000-0000-000000000003'),
  0::bigint,
  'F-085: penolakan tidak meninggalkan baris kode yatim'
);

-- --- B. kontrol: cabang sendiri boleh, format kode sesuai backend ---------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  public.cabang_pantau_saya('a1a1a1a1-0000-0000-0000-000000000001'),
  true,
  'F-085: Pak Andi memang pemantau cabang A1 (pagar tidak terlalu ketat)'
);
select uji.harap(
  public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000001', 'Perangkat Cabang Sendiri', 'pos', array['kasir']
  )->>'kode' = 'KODE_DIBUAT',
  'F-085: admin cabang tetap bisa menerbitkan kode untuk cabangnya sendiri'
);
select uji.harap(
  (select kode ~ '^[A-Z0-9]{8}$'
     from public.kode_pendaftaran_perangkat
    where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
      and dibuat_oleh = '90000000-0000-0000-0000-000000000003'
    order by dibuat_pada desc limit 1),
  'F-086 silang-uji: kode dari peladen memang 8 karakter [A-Z0-9]'
);

-- --- C. kontrol: owner_pusat leluasa di semua cabang penyewanya -----------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  public.cabang_pantau_saya('a1a1a1a1-0000-0000-0000-000000000002'),
  true,
  'F-085: owner_pusat memantau seluruh cabang penyewanya'
);
select uji.sama(
  public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000002', 'Perangkat Buatan Owner', 'pos', array['kasir']
  )->>'kode',
  'KODE_DIBUAT',
  'F-085: owner_pusat tetap bisa menerbitkan kode untuk cabang mana pun di restonya'
);

-- --- D. kontrol negatif: lintas penyewa & tanpa izin ----------------------
select uji.sama(
  public.buat_kode_perangkat(
    'b1b1b1b1-0000-0000-0000-000000000001', 'Perangkat Penyewa Lain', 'pos', array['kasir']
  )->>'kode',
  'CABANG_TIDAK_VALID',
  'F-085: owner penyewa A ditolak membuat kode untuk cabang penyewa B'
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.sama(
  public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000001', 'Perangkat Kasir', 'pos', array['kasir']
  )->>'kode',
  'FORBIDDEN',
  'F-085: kasir (tanpa kelola_pegawai) tidak bisa menerbitkan kode'
);

select uji.klaim('90000000-0000-0000-0000-000000000007');
select uji.sama(
  public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000001', 'Perangkat Kasir B', 'pos', array['kasir']
  )->>'kode',
  'FORBIDDEN',
  'F-085: kasir penyewa B tidak bisa menyentuh cabang penyewa A'
);

-- --- E. hanya dua kode sah yang tersimpan --------------------------------
reset role;
select uji.sama(
  (select count(*) from public.kode_pendaftaran_perangkat
    where dibuat_oleh in (
      '90000000-0000-0000-0000-000000000002',
      '90000000-0000-0000-0000-000000000003',
      '90000000-0000-0000-0000-000000000004',
      '90000000-0000-0000-0000-000000000007'
    )),
  2::bigint,
  'F-085: dari lima percobaan, hanya dua yang sah tersimpan'
);
