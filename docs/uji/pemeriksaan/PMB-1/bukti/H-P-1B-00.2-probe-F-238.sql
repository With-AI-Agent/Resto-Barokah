-- PROBE HAKIM P-1B-00.2 (arena/a86e0cc5-resto-barokah, 2026-10-09) — PMB1-F-238
-- Verifikasi keputusan Lee 2026-10-07: batalkan_pemulihan SENGAJA tidak dibuka
-- tanpa sesi (eskalasi Tingkat 4). Yang dibuktikan hari ini:
--   A1. kursi anon DITOLAK permission denied (grant memang tanpa anon — 0028:334).
--   A2. kasir ber-sesi DITOLAK di gerbang boleh('kelola_pegawai') (0028:280-282).
--   A3. KONTROL POSITIF: owner_pusat (milik izin kelola_pegawai) TIDAK ditolak
--       ACL/izin — lanjut ke aturan domain ("tidak ditemukan") → penolakan A1/A2
--       memang karena pagar, bukan karena fungsi rusak.
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-P-1B-00.2-probe-F-238.sql

-- A1. Anon sama sekali tidak punya execute
select uji.klaim(null);
set local role anon;

select uji.harap_gagal_sebab(
  $$select public.batalkan_pemulihan('00000000-0000-0000-0000-000000000000'::uuid, 'uji hakim')$$,
  'permission denied for function batalkan_pemulihan',
  'F-238 A1: anon tidak bisa membatalkan pemulihan (ACL sengaja tanpa anon)'
);

reset role;

-- A2. Kasir ber-sesi ditolak di gerbang izin
-- Rina: kasir resto A (alat/sql/data-uji.sql:37)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.batalkan_pemulihan('00000000-0000-0000-0000-000000000000'::uuid, 'uji hakim')$$,
  'kelola_pegawai',
  'F-238 A2: kasir ber-sesi ditolak di gerbang kelola_pegawai'
);

reset role;

-- A3. Kontrol positif: owner_pusat punya izin → melewati gerbang, ditolak di
-- aturan domain karena id tidak ada (bentuk pesan berbeda total)
-- Owner resto A: 90000000-0000-0000-0000-000000000002 (alat/sql/data-uji.sql:35)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.batalkan_pemulihan('00000000-0000-0000-0000-000000000000'::uuid, 'uji hakim')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-238 A3 kontrol positif: owner_pusat melewati ACL+izin, lanjut ke aturan domain'
);

reset role;
