-- ============================================================================
-- UJI: Isolasi Penyewa & Larangan Anon pada percobaan_masuk (N F-05)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-05: percobaan_masuk bisa ditulis anon
--     lintas penyewa dan periksa_kunci_masuk bisa dibaca anon.
--   - Migrasi 0059_catat_percobaan_masuk_tenant.sql
-- ============================================================================

-- 1. Uji Anon DITOLAK memanggil catat_percobaan_masuk (hak anon dicabut)
set local role anon;

select uji.harap_gagal_sebab(
  $$ select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'serangan anon') $$,
  'permission denied for function catat_percobaan_masuk',
  'Anon ditolak memanggil catat_percobaan_masuk'
);

-- 2. Uji Anon DITOLAK memanggil periksa_kunci_masuk (hak anon dicabut)
select uji.harap_gagal_sebab(
  $$ select public.periksa_kunci_masuk('90000000-0000-0000-0000-000000000004', null) $$,
  'permission denied for function periksa_kunci_masuk',
  'Anon ditolak memanggil periksa_kunci_masuk'
);

-- 3. Uji Pengguna Authenticated DITOLAK mencatat untuk penyewa lain (lintas penyewa)
reset role;
-- Kasir resto 1 (11111111-...) mencoba mencatat untuk resto 2 (22222222-...)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$ select public.catat_percobaan_masuk('22222222-2222-2222-2222-222222222222', '90000000-0000-0000-0000-000000000007', null, false, 'serangan lintas tenant') $$,
  'Akses lintas penyewa ditolak',
  'Pengguna authenticated ditolak mencatat percobaan masuk untuk resto lain'
);

-- 4. Uji Kasir tanpa hak kelola_pegawai DITOLAK memeriksa status kunci akun pegawai lain
select uji.harap_gagal_sebab(
  $$ select public.periksa_kunci_masuk('90000000-0000-0000-0000-000000000002', null) $$,
  'Tidak berhak memeriksa status kunci pengguna lain',
  'Kasir tanpa kelola_pegawai ditolak memeriksa status kunci akun lain'
);

-- 5. Uji Kasir memeriksa status kuncinya sendiri -> DIIZINKAN
select uji.sama(
  (select (public.periksa_kunci_masuk('90000000-0000-0000-0000-000000000004', null)->>'terkunci')::boolean),
  false,
  'Kasir berhak memeriksa status kunci akunnya sendiri'
);

-- 6. Uji Owner dengan hak kelola_pegawai memeriksa status kunci pegawainya -> DIIZINKAN
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select (public.periksa_kunci_masuk('90000000-0000-0000-0000-000000000004', null)->>'terkunci')::boolean),
  false,
  'Owner berhak memeriksa status kunci pegawai restonya'
);
