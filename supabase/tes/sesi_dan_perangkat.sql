-- ============================================================================
-- PENGUJIAN SQL: Sesi Perangkat, Kode Pendaftaran, Persetujuan, & Percobaan Masuk
-- (T1-24, T1-25, T1-26, ART-11 & ART-12)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Uji Pembuatan Kode Pendaftaran Perangkat (T1-24)
-- ---------------------------------------------------------------------------
-- Kasir mencoba membuat kode -> DITOLAK (tidak punya hak kelola_pegawai)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.buat_kode_perangkat('a1a1a1a1-0000-0000-0000-000000000001', 'Tablet Kasir Baru')->>'berhasil')::boolean),
  false,
  'Kasir tanpa hak kelola_pegawai ditolak membuat kode pendaftaran perangkat'
);

-- Owner membuat kode pendaftaran -> BERHASIL
select uji.klaim('90000000-0000-0000-0000-000000000002');

select uji.sama(
  (select (public.buat_kode_perangkat('a1a1a1a1-0000-0000-0000-000000000001', 'Tablet Kasir Baru 1', 'tablet_kasir', array['kasir']::text[])->>'berhasil')::boolean),
  true,
  'Owner berhasil membuat kode pendaftaran perangkat 15 menit'
);

-- Ambil kode yang baru dibuat
drop table if exists temp_kode;
create temporary table temp_kode as
select id as kode_id, kode
  from public.kode_pendaftaran_perangkat
 where nama_perangkat = 'Tablet Kasir Baru 1'
 order by dibuat_pada desc limit 1;

select uji.sama(
  (select count(*)::int from temp_kode),
  1,
  'Kode pendaftaran berhasil tersimpan di database'
);

-- ---------------------------------------------------------------------------
-- 2. Uji Pendaftaran Perangkat Menggunakan Kode (T1-24)
-- ---------------------------------------------------------------------------
-- Pendaftaran dengan kode salah -> DITOLAK
select uji.sama(
  (select (public.daftarkan_perangkat_dengan_kode('KODESALAH', 'rahasia_super_panjang_1234567890')->>'berhasil')::boolean),
  false,
  'Pendaftaran dengan kode salah ditolak'
);

-- Pendaftaran dengan kode valid -> BERHASIL
drop table if exists temp_hasil_daftar;
create temporary table temp_hasil_daftar as
select public.daftarkan_perangkat_dengan_kode(
  (select kode from temp_kode),
  'rahasia_super_panjang_1234567890'
) as res;

select uji.sama(
  (select (res->>'berhasil')::boolean from temp_hasil_daftar),
  true,
  'Pendaftaran perangkat dengan kode valid berhasil'
);

drop table if exists temp_perangkat;
create temporary table temp_perangkat as
select ((res->'data')->>'perangkat_id')::uuid as perangkat_id
  from temp_hasil_daftar;

-- Uji pemakaian kode yang sama kedua kali -> DITOLAK (sekali pakai)
select uji.sama(
  (select (public.daftarkan_perangkat_dengan_kode((select kode from temp_kode), 'rahasia_super_panjang_1234567890')->>'berhasil')::boolean),
  false,
  'Kode pendaftaran sekali pakai ditolak saat dipakai kedua kali'
);

-- ---------------------------------------------------------------------------
-- 3. Uji Persetujuan Perangkat oleh Owner (T1-24)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  (select (public.setujui_perangkat_pegawai((select perangkat_id from temp_perangkat), '90000000-0000-0000-0000-000000000004')->>'berhasil')::boolean),
  true,
  'Owner berhasil menyetujui pegawai pertama memakai perangkat'
);

select uji.harap(
  exists(select 1 from public.persetujuan_perangkat where perangkat_id = (select perangkat_id from temp_perangkat) and pengguna_id = '90000000-0000-0000-0000-000000000004'),
  'Baris persetujuan perangkat tersimpan di database'
);

-- ---------------------------------------------------------------------------
-- 4. Uji Pengikatan Sesi Perangkat & Batas Umur (T1-25)
-- ---------------------------------------------------------------------------
-- Pengikatan dengan kunci salah -> DITOLAK
select uji.sama(
  (select (public.ikat_sesi_perangkat('sess_uji_001', (select perangkat_id from temp_perangkat), 'kunci_salah_total_1234567890', '90000000-0000-0000-0000-000000000004')->>'berhasil')::boolean),
  false,
  'Pengikatan sesi ditolak jika kunci perangkat salah'
);

-- Pengikatan dengan peran yang tidak diizinkan pada perangkat (pelayan pada tablet kasir) -> DITOLAK
select uji.sama(
  (select (public.ikat_sesi_perangkat('sess_uji_002', (select perangkat_id from temp_perangkat), 'rahasia_super_panjang_1234567890', '90000000-0000-0000-0000-000000000005')->>'berhasil')::boolean),
  false,
  'Pengikatan sesi ditolak jika peran pengguna (pelayan) tidak diizinkan pada perangkat (khusus kasir)'
);

-- Pengikatan dengan peran yang diizinkan (kasir) -> BERHASIL (umur 12 jam)
select uji.sama(
  (select (public.ikat_sesi_perangkat('sess_uji_kasir_01', (select perangkat_id from temp_perangkat), 'rahasia_super_panjang_1234567890', '90000000-0000-0000-0000-000000000004')->>'berhasil')::boolean),
  true,
  'Kasir berhasil mengikat sesi pada perangkat kasir yang sah'
);

select uji.harap(
  exists(select 1 from public.sesi_perangkat where session_id = 'sess_uji_kasir_01' and status = 'aktif'),
  'Sesi kasir aktif tersimpan di database'
);

-- ---------------------------------------------------------------------------
-- 5. Uji Pencabutan Seluruh Sesi (keluar_semua_perangkat) (T1-25)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.sama(
  (select (public.keluar_semua_perangkat('90000000-0000-0000-0000-000000000004')->>'berhasil')::boolean),
  true,
  'keluar_semua_perangkat berhasil dijalankan oleh owner'
);

select uji.sama(
  (select status from public.sesi_perangkat where session_id = 'sess_uji_kasir_01'),
  'dicabut',
  'Status sesi kasir berubah menjadi dicabut'
);

-- ---------------------------------------------------------------------------
-- 6. Uji Pencabutan Perangkat Seketika (cabut_perangkat) (T1-24 & T1-25)
-- ---------------------------------------------------------------------------
-- Ikat ulang sesi kasir
select public.ikat_sesi_perangkat('sess_uji_kasir_02', (select perangkat_id from temp_perangkat), 'rahasia_super_panjang_1234567890', '90000000-0000-0000-0000-000000000004');

select uji.sama(
  (select status from public.sesi_perangkat where session_id = 'sess_uji_kasir_02'),
  'aktif',
  'Sesi baru kasir aktif'
);

-- Cabut perangkat
select uji.sama(
  (select public.cabut_perangkat((select perangkat_id from temp_perangkat), 'Tablet dicuri orang')),
  true,
  'cabut_perangkat berhasil dijalankan oleh owner'
);

select uji.sama(
  (select aktif from public.perangkat where id = (select perangkat_id from temp_perangkat)),
  false,
  'Perangkat berstatus nonaktif/dicabut'
);

select uji.sama(
  (select status from public.sesi_perangkat where session_id = 'sess_uji_kasir_02'),
  'dicabut',
  'Sesi pada perangkat yang dicabut otomatis diputus seketika'
);

-- ---------------------------------------------------------------------------
-- 7. Uji Pembatasan Percobaan Masuk (T1-26)
-- ---------------------------------------------------------------------------
-- Catat 5 kegagalan pada akun kasir via RPC
select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'PIN salah');
select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'PIN salah');
select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'PIN salah');
select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'PIN salah');
select public.catat_percobaan_masuk('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000004', null, false, 'PIN salah');

select uji.sama(
  (select (public.periksa_kunci_masuk('90000000-0000-0000-0000-000000000004', null)->>'terkunci')::boolean),
  true,
  'Akun kasir terkunci sementara setelah 5 kali percobaan gagal'
);
