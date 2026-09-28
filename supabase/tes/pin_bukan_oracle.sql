-- ============================================================================
-- UJI: pesan PIN kembar tidak lagi memastikan PIN aktif kolega (temuan K-2 PR-04)
-- ============================================================================
-- Temuan aslinya (probe `docs/uji/audit/probe-2026-09-19/pr04-oracle-pin.sql`):
-- jawaban `simpan_pin` dulu berbunyi 'PIN itu sudah dipakai pegawai lain di resto ini'
-- — kalimat itu MEMASTIKAN bahwa angka yang baru saja ditebak penyerang adalah PIN
-- aktif seorang kolega. Selama 20 percobaan/15 menit ia bisa memeriksa daftar tebakan
-- kecil (tanggal lahir, angka favorit) tanpa pernah menyentuh layar login.
--
-- Yang dibuktikan berkas ini:
--   1. KONTROL — PIN pertama tersimpan (`'PIN tersimpan.'`).
--   2. TEMUAN  — angka yang sudah dipakai kolega ditolak, dan pesannya TIDAK memuat
--      kata yang memastikan angka itu milik pegawai lain.
--   3. KONTROL — angka lain yang belum dipakai tetap tersimpan (aturan unik tetap hidup).
--   4. Kejujuran mesin: pesan penolakan itu tetap menyebut "tidak bisa dipakai" supaya
--      pengguna tahu angkanya harus diganti; alasan sebenarnya tetap TERCATAT di
--      `percobaan_simpan_pin` (alasan 'PIN kembar') untuk ditelusuri pemilik.
-- ============================================================================

-- 1. KONTROL: owner memasang PIN-nya (angka kuat, bukan pola lemah).
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- Bu Oasis, owner
set local role authenticated;
select uji.sama(public.simpan_pin('482619', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
                'PIN tersimpan.', 'kontrol: PIN owner tersimpan');

-- 2. TEMUAN: pegawai lain menebak angka yang sama → ditolak dengan pesan NETRAL.
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- Dedi, pelayan (belum punya PIN)
set local role authenticated;
-- Dipanggil SEKALI saja (setiap panggilan tercatat di `percobaan_simpan_pin`).
do $$
declare
  v_pesan text := public.simpan_pin('482619', null, null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789');
begin
  perform uji.sama(v_pesan, 'PIN itu tidak bisa dipakai — pilih angka lain.',
                   'PR-04: angka yang sudah dipakai kolega ditolak TANPA menyebut pegawai lain');
  perform uji.sama(position('pegawai lain' in v_pesan) > 0, false,
                   'PR-04: pesannya tidak lagi memuat kalimat yang memastikan angka itu PIN aktif kolega');
end $$;

-- 3. KONTROL: angka yang belum dipakai tetap tersimpan (aturan unik tidak dilonggarkan).
select uji.sama(public.simpan_pin('957031', null, null, 'de000000-0000-0000-0000-000000000004', 'kunci-uji-hp-pelayan-0123456789'),
                'PIN tersimpan.', 'kontrol: angka yang belum dipakai tetap diterima');
reset role;
select uji.klaim(null);

-- 4. Alasan sebenarnya tetap TERCATAT untuk pemilik (bukan hilang, hanya tidak dibocorkan).
select uji.sama(
  (select count(*) from public.percobaan_simpan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000005'
      and alasan = 'PIN kembar'),
  1::bigint,
  'PR-04: percobaan kembar tetap tercatat (alasan PIN kembar) — jejak untuk pemilik'
);
