-- ============================================================================
-- UJI SQL: admin cabang tidak boleh menerbitkan kode perangkat untuk cabang
--          di luar pantauannya (PMB1-F-085 · K-2 · KEAMANAN §4b)
-- ============================================================================
-- Yang dijaga (migrasi 0100):
--   1. Admin cabang (kelola_pegawai) yang memanggil buat_kode_perangkat untuk
--      cabang YANG BUKAN pantauannya DITOLAK (FORBIDDEN) dan tidak ada baris
--      kode yang tersimpan — sebelumnya (0030) cukup penyewa sama + izin
--      kelola_pegawai, jadi admin cabang A bisa menerbitkan kode cabang B.
--   2. Kontrol: admin cabang yang sama tetap BISA menerbitkan kode untuk
--      cabangnya sendiri (fungsi tidak rusak oleh pagar baru).
--   3. Kontrol: owner_pusat tetap bisa menerbitkan kode untuk semua cabang
--      penyewanya (cabang_pantau_saya = true untuk seluruh cabang penyewa).
-- Jalankan: node alat/uji-sql.mjs supabase/tes/kode_perangkat_lintas_cabang.sql
-- ============================================================================

-- Pak Andi: admin_cabang penyewa 1111..., hanya memantau cabang a1a1...0001
-- (lihat alat/sql/data-uji.sql tabel pengguna_cabang).
select uji.klaim('90000000-0000-0000-0000-000000000003');

-- 1. LINTAS CABANG: sasaran a1a1...0002 (Cabang Dua) bukan pantauan Pak Andi.
select uji.harap(
  (public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000002', 'Perangkat Lintas Cabang', 'pos', array['kasir']
  )->>'berhasil')::boolean = false,
  'F-085: admin cabang DITOLAK menerbitkan kode perangkat untuk cabang di luar pantauannya'
);

-- 1b. Penolakan itu tidak meninggalkan baris kode yatim.
select uji.harap(
  (select count(*) from public.kode_pendaftaran_perangkat
    where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'
      and dibuat_oleh = '90000000-0000-0000-0000-000000000003') = 0,
  'F-085: percobaan lintas cabang tidak menyimpan baris kode apa pun'
);

-- 2. KONTROL: cabang sendiri (a1a1...0001 = Pusat) tetap boleh.
select uji.harap(
  (public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000001', 'Perangkat Cabang Sendiri', 'pos', array['kasir']
  )->>'berhasil')::boolean = true,
  'F-085: admin cabang tetap bisa menerbitkan kode untuk cabangnya sendiri'
);

-- 3. KONTROL: owner_pusat (Bu Oasis) tetap leluasa di semua cabang penyewanya.
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap(
  (public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000002', 'Perangkat Buatan Owner', 'pos', array['kasir']
  )->>'berhasil')::boolean = true,
  'F-085: owner_pusat tetap bisa menerbitkan kode untuk semua cabang penyewanya'
);
