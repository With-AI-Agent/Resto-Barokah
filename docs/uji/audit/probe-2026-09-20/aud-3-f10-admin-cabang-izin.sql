-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-19 F-10
--                       (isolasi izin admin cabang bertentangan: policy vs kontrak vs uji)
-- ============================================================================
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL.
--
-- Kontrak yang berlaku (docs/TECH_SPEC.md §294 · docs/PRD.md:174 · docs/DISCOVERY.md:53):
--   "admin_cabang, kasir, pelayan, dapur HANYA cabangnya; owner seluruh cabang restonya."
-- Yang diuji di sini: layar centang izin (M3) memakai `public.izin`. Policy lamanya
-- `izin_pilih` membatasi admin cabang dengan `sepenyewa(pengguna_id)` — yaitu SELURUH
-- penyewa, bukan cabangnya — sehingga admin Cabang Pusat membaca izin pegawai Cabang Dua.
-- ============================================================================

-- F-10a: admin Cabang Pusat membaca baris izin pegawai Cabang Dua (dapur).
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin cabang Pusat
set local role authenticated;
select uji.harap(
  exists (select 1 from public.izin i where i.pengguna_id = '90000000-0000-0000-0000-000000000006'),
  'F-10a NYATA: admin Cabang Pusat melihat izin pegawai Cabang Dua (dapur…0006) — policy-nya se-penyewa, bukan se-cabang'
);

-- F-10b: jumlah baris izin yang terlihat = seluruh penyewa (bukan cabangnya).
select uji.sama(
  (select count(*) from public.izin),
  8::bigint,
  'F-10b NYATA: admin cabang melihat 8 baris izin (seluruh penyewa); aturan cabang akan memberi 4 (dirinya + kasir cabangnya)'
);

-- Kontrol: owner pusat memang boleh melihat seluruh restonya.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select count(*) from public.izin), 8::bigint,
  'kontrol: owner pusat melihat seluruh izin restonya (tidak berubah)'
);
reset role;
select uji.klaim(null);
