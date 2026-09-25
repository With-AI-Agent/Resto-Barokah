-- ============================================================================
-- UJI: RPC verifikasi_pin_perangkat untuk Autentikasi Staf (N F-01)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-01: RPC verifikasi_pin_perangkat yang
--     dipanggil oleh aplikasi/src/lib/auth.ts:176 belum ada di database.
--   - Migrasi 0061_verifikasi_pin_perangkat.sql
-- ============================================================================

-- Penyiapan: Owner memasang PIN '516372' untuk kasir Rina (kasir.a1@contoh.test)
select uji.klaim('90000000-0000-0000-0000-000000000002');
select public.simpan_pin(
  '516372',
  null,
  '90000000-0000-0000-0000-000000000004',
  'de000000-0000-0000-0000-000000000001',
  'kunci-uji-hp-owner-0123456789'
);

-- Pastikan perangkat kasir aktif & peran kasir diizinkan
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

-- Uji dipanggil dari peran anon (karena belum login)
select uji.klaim(null);
set local role anon;

-- 1. Input kosong ditolak
select uji.sama(
  (public.verifikasi_pin_perangkat('', '')->>'berhasil')::boolean,
  false,
  'Input email & PIN kosong ditolak'
);

-- 2. Format PIN bukan 6 digit ditolak
select uji.sama(
  (public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '1234')->>'kode'),
  'FORMAT_PIN_SALAH',
  'PIN 4 digit ditolak dengan kode FORMAT_PIN_SALAH'
);

-- 2b. Login tanpa perangkat ditolak (faktor wajib staf)
select uji.sama(
  (public.verifikasi_pin_perangkat('kasir.a1@contoh.test', '516372', null)->>'kode'),
  'PERANGKAT_WAJIB',
  'Login tanpa perangkat ditolak PERANGKAT_WAJIB'
);

-- 3. Email tidak terdaftar ditolak (anti-oracle: kode & pesan seragam)
select uji.sama(
  (public.verifikasi_pin_perangkat('hantu@contoh.test', '516372', 'de000000-0000-0000-0000-000000000003')->>'kode'),
  'KREDENSIAL_TIDAK_VALID',
  'Email tidak dikenal ditolak KREDENSIAL_TIDAK_VALID'
);

-- 4. PIN salah ditolak (anti-oracle: kode & pesan seragam)
select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '999999',
    'de000000-0000-0000-0000-000000000003',
    'hp-kasir'
  )->>'kode'),
  'KREDENSIAL_TIDAK_VALID',
  'PIN salah ditolak dengan kode KREDENSIAL_TIDAK_VALID'
);

-- 5. Perangkat dicabut / tidak sah ditolak
reset role;
update public.perangkat set aktif = false where id = 'de000000-0000-0000-0000-000000000003';
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '516372',
    'de000000-0000-0000-0000-000000000003',
    'hp-kasir'
  )->>'kode'),
  'PERANGKAT_TIDAK_SAH',
  'Login dari perangkat yang tidak aktif/dicabut ditolak PERANGKAT_TIDAK_SAH'
);

-- 6. Login berhasil dengan PIN dan perangkat yang sah
reset role;
update public.perangkat set aktif = true where id = 'de000000-0000-0000-0000-000000000003';
set local role anon;

drop table if exists temp_hasil_login;
create temporary table temp_hasil_login as
select public.verifikasi_pin_perangkat(
  'kasir.a1@contoh.test',
  '516372',
  'de000000-0000-0000-0000-000000000003',
  'hp-kasir'
) as res;

select uji.sama(
  ((select res from temp_hasil_login)->>'berhasil')::boolean,
  true,
  'Login PIN staf dari perangkat terdaftar berhasil'
);

select uji.sama(
  ((select res from temp_hasil_login)->'data'->>'pengguna_id')::uuid,
  '90000000-0000-0000-0000-000000000004'::uuid,
  'Data pengguna_id sesuai kasir Rina'
);

select uji.sama(
  ((select res from temp_hasil_login)->'data'->>'peran'),
  'kasir',
  'Data peran sesuai kasir'
);

select uji.sama(
  ((select res from temp_hasil_login)->'data'->>'penyewa_id')::uuid,
  '11111111-1111-1111-1111-111111111111'::uuid,
  'Data penyewa_id sesuai Resto Oasis'
);
