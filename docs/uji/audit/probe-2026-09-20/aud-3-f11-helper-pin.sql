-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-19 F-11
--                       (helper hierarki PIN = oracle publik atas dua UUID bebas)
-- ============================================================================
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL — karena itu ia hidup di
-- `docs/uji/audit/probe-2026-09-20/`, bukan di `supabase/tes` (folder uji wajib hijau).
--
-- Aturan yang dilanggar (kuitpan docs/TECH_SPEC.md §7 & ART-8): pemeriksaan "atasan"
-- harus bertumpu pada identitas pemanggil yang sedang masuk (`auth.uid()`), bukan pada
-- UUID yang dikirim perangkat. Helper internal yang bisa dipanggil klien dengan UUID
-- bebas = oracle: perangkat bisa memetakan hierarki peran, dan setiap jalur baru yang
-- memakainya tanpa pembungkus identitas akan menerima jawaban atas nama orang lain.
-- ============================================================================

-- Kasir (peran terendah) memanggil helper internal dengan UUID ORANG LAIN.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

-- F-11a: helper bisa dipanggil klien (bukan hanya dari dalam fungsi peladen).
select uji.sama(
  public.peran_lebih_tinggi('90000000-0000-0000-0000-000000000002',   -- owner
                            '90000000-0000-0000-0000-000000000005'),  -- pelayan
  true,
  'F-11a NYATA: kasir bisa memanggil helper hierarki internal (jawaban: owner lebih tinggi dari pelayan)'
);

-- F-11b: p_pemanggil TIDAK dipakukan ke auth.uid() — jawabannya mengikuti UUID kiriman.
select uji.sama(
  public.peran_lebih_tinggi('90000000-0000-0000-0000-000000000006',   -- dapur (UUID orang lain)
                            '90000000-0000-0000-0000-000000000005'),  -- pelayan
  false,
  'F-11b NYATA: jawaban mengikuti UUID KIRIMAN perangkat (dapur < pelayan), bukan identitas yang masuk'
);

-- F-11c: UUID lintas resto pun dijawab (bukan ditolak) → peta hierarki lintas penyewa.
select uji.sama(
  public.peran_lebih_tinggi('90000000-0000-0000-0000-000000000007',   -- kasir resto LAIN
                            '90000000-0000-0000-0000-000000000004'),
  false,
  'F-11c NYATA: UUID pegawai resto lain pun dijawab (tidak ditolak) — oracle lintas penyewa'
);
reset role;
select uji.klaim(null);
