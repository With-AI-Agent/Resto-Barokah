-- ============================================================================
-- UJI: public.cabang_aktif_saya() (N F-04 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-04: `public.cabang_aktif_saya()` tidak
--     pernah didefinisikan; migrasi 0056 menutupnya.
-- ============================================================================

-- 1. Anon: fungsi identitas tidak bisa dipanggil (hak dicabut).
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  'select public.cabang_aktif_saya()',
  'permission denied for function cabang_aktif_saya',
  'anon tidak boleh memanggil cabang_aktif_saya'
);
reset role;
select uji.klaim(null);

-- 2. Pemilik platform (berdiri di luar penyewa) → NULL.
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  null::uuid,
  'pemilik platform tidak punya cabang_aktif_saya'
);
reset role;
select uji.klaim(null);

-- 3. Owner pusat (punya penyewa, tidak bertugas di kasir) → NULL.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  null::uuid,
  'owner pusat tanpa cabang aktif'
);
reset role;
select uji.klaim(null);

-- 4. Admin cabang (satu cabang) → cabang itu.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  'admin cabang Pusat adalah cabang_aktif_saya'
);
reset role;
select uji.klaim(null);

-- 5. Kasir (satu cabang) → cabang itu.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  'cabang_aktif_saya untuk kasir cabang Pusat'
);
reset role;
select uji.klaim(null);

-- 6. Pelayan merangkap 2 cabang → cabang paling awal dibuat_pada.
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  'cabang_aktif_saya untuk pelayan merangkap = cabang pertama (Pusat)'
);
reset role;
select uji.klaim(null);

-- 7. Isolasi lintas-tenant: Ujang (kasir Penyewa B / Warung Bandung) hanya
--    boleh melihat cabang B1, BUKAN cabang A1/A2.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama(
  public.cabang_aktif_saya(),
  'b1b1b1b1-0000-0000-0000-000000000001'::uuid,
  'kasir B1 hanya boleh melihat cabang B1 — cabang A1/A2 tidak boleh bocor'
);
reset role;
select uji.klaim(null);
