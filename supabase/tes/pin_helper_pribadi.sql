-- ============================================================================
-- UJI: helper hierarki PIN bukan oracle publik
-- Temuan AUD-3 2026-09-19 F-11 (K-2), dibuktikan nyata lewat probe sesi kerja:
-- docs/uji/audit/probe-2026-09-20/aud-3-f11-helper-pin.sql
-- ============================================================================
-- Aturan yang dijaga: pemeriksaan "atasan" bertumpu pada identitas yang sedang masuk, bukan
-- UUID kiriman perangkat. Sebelum perbaikan, kasir bisa memanggil
-- `peran_lebih_tinggi(<uuid siapa pun>, <uuid siapa pun>)` langsung dari perangkat dan
-- membaca peta hierarki peran — termasuk lintas resto.
-- ============================================================================

-- 1. Klien biasa TIDAK punya hak memanggil helper internal itu sama sekali.
select uji.sama(
  has_function_privilege('authenticated', 'public.peran_lebih_tinggi(uuid, uuid)', 'execute'),
  false,
  'F-11: authenticated tidak lagi punya hak execute atas helper hierarki PIN'
);
select uji.sama(
  has_function_privilege('service_role', 'public.peran_lebih_tinggi(uuid, uuid)', 'execute'),
  true,
  'kontrol: jalur peladen (service_role) tetap boleh memanggilnya'
);

-- 2. Percobaan nyata dari kursi kasir → DITOLAK oleh hak akses, bukan dijawab.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
select uji.harap_gagal_sebab($$select public.peran_lebih_tinggi('90000000-0000-0000-0000-000000000002',
                                     '90000000-0000-0000-0000-000000000005')$$, 'permission denied for function peran_lebih_tinggi', 'F-11: kasir tidak bisa memanggil helper hierarki untuk membaca peta peran');
reset role;
select uji.klaim(null);

-- 3. Jalur SAH tetap bekerja: owner mengganti PIN bawahan → tersimpan (helper dipakai dari
--    dalam `simpan_pin` yang berjalan sebagai pemilik tabel).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select public.simpan_pin('482913', null, null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789');                    -- kasir memasang PIN sendiri
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');    -- owner
set local role authenticated;
select uji.sama(
  public.simpan_pin('705164', null, '90000000-0000-0000-0000-000000000004', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
  'PIN tersimpan.',
  'kontrol: jalur sah tetap terbuka — owner boleh mengganti PIN kasir (helper tetap bisa dipakai internal)'
);
reset role;
select uji.klaim(null);

-- 3b. Lapis kedua (pemakuan identitas) diuji lewat pembungkus SECURITY DEFINER — persis
--     skenario yang dikhawatirkan laporan: "apabila hasil helper dipakai di jalur baru tanpa
--     pembungkus identitas, pemeriksaan atasan dapat dipalsukan". Pembungkus ini mewakili jalur
--     baru itu; dengan pemakuan, jawabannya HARUS false walau UUID kiriman adalah owner.
select uji.klaim(null);
create or replace function public.uji_coba_hierarki_pin(p_pemanggil uuid, p_target uuid)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$ select public.peran_lebih_tinggi(p_pemanggil, p_target) $$;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir masuk
set local role authenticated;
select uji.sama(
  public.uji_coba_hierarki_pin('90000000-0000-0000-0000-000000000002',   -- owner (UUID kiriman)
                               '90000000-0000-0000-0000-000000000005'),  -- pelayan
  false,
  'F-11: jalur baru tanpa pembungkus identitas TIDAK bisa memakai helper untuk mengaku atasan (dipakukan ke auth.uid())'
);
reset role;
select uji.klaim(null);

-- 4. Hierarki tetap ditegakkan: admin cabang tidak boleh mengganti PIN owner.
select uji.klaim('90000000-0000-0000-0000-000000000003');    -- admin cabang
set local role authenticated;
select uji.sama(
  public.simpan_pin('318549', null, '90000000-0000-0000-0000-000000000002', 'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789')
    like 'Peran Anda tidak lebih tinggi%', true,
  'kontrol: aturan hierarki PIN tetap bekerja setelah helper dikunci (kontrak pesan sejak F-14)'
);
reset role;
select uji.klaim(null);
