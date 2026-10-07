-- ============================================================================
-- UJI SQL: Peringatan "perangkat berkuasa tinggal 1" (PMB1-F-072 · K-3)
-- ============================================================================
-- Yang dijaga (KEAMANAN §4 keputusan pemilik + §14 matriks uji):
--   1. `hitung_perangkat_berkuasa()` menghitung perangkat AKTIF per peran
--      berkuasa dari `peran_diizinkan`, milik penyewa pemanggil saja.
--   2. `cadangan_cukup` = true hanya bila >= 2 perangkat aktif.
--   3. Perangkat tidak aktif (dicabut) TIDAK dihitung.
--   4. Perangkat penyewa lain TIDAK bocor ke hitungan (isolasi tenant).
--   5. Peran tanpa satu pun perangkat tampil sebagai 0 / tidak cukup
--      (keadaan paling berbahaya justru harus terlihat).
--   6. Kasir (tanpa izin lihat_laporan) DITOLAK.
--   7. Keadaan "tinggal satu" (peringatan wajib) bisa dicapai dan terdeteksi.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/perangkat_berkuasa.sql
-- Migrasi berlaku: 0103_peringatan_perangkat_berkuasa_tinggal_satu.sql
-- ============================================================================

-- Penyiapan (jalur pemilik tabel — klien tidak pernah menulis tabel perangkat).
-- Perangkat bawaan data-uji memakai peran_diizinkan DEFAULT yang memuat SEMUA peran
-- (0030), jadi dibersihkan dulu supaya hitungan di berkas ini terkontrol penuh.
delete from public.kredensial_perangkat where perangkat_id::text like 'de000000%';
delete from public.perangkat where id::text like 'de000000%';

insert into public.perangkat (id, penyewa_id, cabang_id, nama, aktif, peran_diizinkan, didaftarkan_oleh) values
  ('f0720000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'f072-owner-utama',    true,  array['owner_pusat'],  '90000000-0000-0000-0000-000000000002'),
  ('f0720000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'f072-owner-cadangan', true,  array['owner_pusat'],  '90000000-0000-0000-0000-000000000002'),
  ('f0720000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'f072-owner-cabut',    false, array['owner_pusat'],  '90000000-0000-0000-0000-000000000002'),
  ('f0720000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'f072-admin',          true,  array['admin_cabang'], '90000000-0000-0000-0000-000000000002'),
  ('f0720000-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'b1b1b1b1-0000-0000-0000-000000000001', 'f072-owner-resto-b',  true,  array['owner_pusat'],  '90000000-0000-0000-0000-000000000007');

-- 1. Owner pusat penyewa A: dua perangkat aktif → cadangan cukup.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select jumlah_aktif from public.hitung_perangkat_berkuasa() where peran = 'owner_pusat'),
  2::bigint,
  'F-072: owner_pusat dihitung 2 perangkat aktif (perangkat dicabut & milik resto B tidak ikut)'
);
select uji.harap(
  (select cadangan_cukup from public.hitung_perangkat_berkuasa() where peran = 'owner_pusat'),
  'F-072: dua perangkat aktif → cadangan_cukup true'
);

-- 2. Admin cabang baru punya 1 perangkat → peringatan (cadangan tidak cukup).
select uji.sama(
  (select jumlah_aktif from public.hitung_perangkat_berkuasa() where peran = 'admin_cabang'),
  1::bigint,
  'F-072: admin_cabang dihitung 1 perangkat aktif'
);
select uji.harap(
  not (select cadangan_cukup from public.hitung_perangkat_berkuasa() where peran = 'admin_cabang'),
  'F-072: satu perangkat admin → cadangan_cukup false (layar harus memperingatkan)'
);

-- 3. Simulasi keadaan paling berbahaya: peran berkuasa TANPA satu pun perangkat.
reset role;
delete from public.perangkat where id = 'f0720000-0000-0000-0000-000000000004';
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select jumlah_aktif from public.hitung_perangkat_berkuasa() where peran = 'admin_cabang'),
  0::bigint,
  'F-072: peran berkuasa tanpa perangkat tampil sebagai 0 (tidak boleh hilang dari hitungan)'
);
select uji.harap(
  not (select cadangan_cukup from public.hitung_perangkat_berkuasa() where peran = 'admin_cabang'),
  'F-072: nol perangkat → cadangan_cukup false'
);

-- 4. Keadaan "tinggal satu" untuk owner (inti peringatan KEAMANAN §4).
reset role;
update public.perangkat set aktif = false where id = 'f0720000-0000-0000-0000-000000000002';
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select jumlah_aktif from public.hitung_perangkat_berkuasa() where peran = 'owner_pusat'),
  1::bigint,
  'F-072: satu perangkat owner dicabut → hitungan turun jadi 1'
);
select uji.harap(
  not (select cadangan_cukup from public.hitung_perangkat_berkuasa() where peran = 'owner_pusat'),
  'F-072: perangkat berkuasa tinggal 1 TERDETEKSI (cadangan_cukup false)'
);

-- 5. Kasir tidak berwenang memanggil RPC ini.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$select * from public.hitung_perangkat_berkuasa()$$,
  'Anda tidak berwenang melihat status perangkat berkuasa\.',
  'F-072: kasir DITOLAK memanggil hitung_perangkat_berkuasa');

reset role;
select uji.klaim(null);
