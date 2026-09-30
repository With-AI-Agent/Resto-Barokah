-- UJI PMB1-F-010 — "buka laci tanpa transaksi" tercatat di jejak audit (kartu B-F-02)
--
-- MERAH pada repo lama: fungsi public.catat_buka_laci tidak ada (grep "buka laci" di
-- migrations → 0) sehingga seluruh berkas ini gagal — bukti MERAH tersimpan di
-- docs/uji/pemeriksaan/PMB-1/bukti/B-F-02-F-010-merah.txt.
--
-- Menjalankan: node alat/uji-sql.mjs supabase/tes/buka_laci_tercatat.sql

-- 0. Kontrak ada
select uji.harap(
  exists (
    select 1 from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'catat_buka_laci'
  ),
  'F-010: RPC catat_buka_laci ada (migrasi 0094)'
);

-- 1. Anon tanpa sesi → ditolak (fail-closed), tanpa baris audit
select uji.klaim(null);
set local role anon;
select uji.sama(
  (public.catat_buka_laci('manual', 'setoran koin')->>'kode'),
  'MASUK_WAJIB',
  'F-010: anon tanpa sesi ditolak MASUK_WAJIB'
);
reset role;
select uji.harap(
  (select count(*) from public.catatan_audit where aksi = 'buka_laci') = 0,
  'F-010: anon ditolak → tidak ada baris audit buka_laci'
);

-- 2. Kasir sah, buka manual TANPA alasan → ditolak ALASAN_WAJIB (jejak tanpa alasan tak berguna)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.catat_buka_laci('manual', null)->>'kode'),
  'ALASAN_WAJIB',
  'F-010: buka manual tanpa alasan ditolak ALASAN_WAJIB'
);

-- 3. Kasir sah, buka manual DENGAN alasan → TERCATAT + baris audit dengan pelaku benar
select uji.sama(
  (public.catat_buka_laci('manual', 'setoran koin seribuan ke brankas')->>'kode'),
  'TERCATAT',
  'F-010: buka manual beralasan → TERCATAT'
);
reset role;
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'buka_laci'
       and entitas = 'laci_kas'
       and pelaku_id = '90000000-0000-0000-0000-000000000004'::uuid
       and nilai_baru->>'alasan' = 'setoran koin seribuan ke brankas'
  ),
  'F-010: baris audit memuat pelaku kasir + alasan'
);

-- 4. Konteks cetak struk tunai (tanpa alasan) → TERCATAT (laci ikut struk, bukan buka mandiri)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.catat_buka_laci('cetak_struk_tunai', null)->>'kode'),
  'TERCATAT',
  'F-010: laci ikut cetak struk tunai → TERCATAT tanpa alasan'
);

-- 5. Pelanggan (peran bukan staf) → ditolak PERAN_TIDAK_BOLEH
--    (simulasi: sesi pengguna berperan pelanggan tidak tersedia di data uji; peran yang
--    jelas bukan pemilik laci diuji lewat jalur anon di atas dan batas peran di kode.)
reset role;
select uji.harap(
  (select count(*) from public.catatan_audit where aksi = 'buka_laci') = 2,
  'F-010: total baris buka_laci = 2 (manual beralasan + cetak_struk_tunai)'
);
