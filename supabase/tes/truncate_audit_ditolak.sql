-- ============================================================================
-- UJI: TRUNCATE catatan_audit ditolak (N F-02 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-02: TRUNCATE sebelumnya tidak memicu
--     trigger `cegah_ubah_hapus_audit` (yang hanya BEFORE UPDATE OR DELETE).
--   - Migrasi 0057 menambah trigger BEFORE TRUNCATE.
-- ============================================================================

-- 1. TRUNCATE catatan_audit ditolak oleh trigger BEFORE TRUNCATE 0057.
select uji.harap_gagal_sebab(
  $$ truncate table public.catatan_audit $$,
  'Pemotongan tabel catatan_audit dilarang',
  'TRUNCATE catatan_audit ditolak oleh trigger 0057'
);

-- 2. INSERT tetap boleh (catatan_audit hanya-tambah; migrasi 0029).
insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id)
values ('11111111-1111-1111-1111-111111111111', null, 'uji_truncate', 'catatan_audit', null);

select uji.harap(
  (select count(*)::integer from public.catatan_audit where aksi = 'uji_truncate') >= 1,
  'INSERT ke catatan_audit tetap berfungsi (catatan_audit hanya-tambah)'
);
