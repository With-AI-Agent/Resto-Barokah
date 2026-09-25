-- ============================================================================
-- UJI: Penegakan Keaktifan Sesi, Batas Umur, dan Pencabutan Perangkat (N F-03)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-03: Pencabutan perangkat/sesi tidak
--     diperiksa pada permintaan berikutnya (umur maksimum sesi tidak ditegakkan).
--   - Migrasi 0058_sesi_masih_aktif.sql
-- ============================================================================

-- Gunakan perangkat kasir sah dari data-uji.sql:
-- id: 'de000000-0000-0000-0000-000000000003' (hp-kasir)
-- kunci: 'kunci-uji-hp-kasir-0123456789'
-- kasir: '90000000-0000-0000-0000-000000000004' (Rina Kasir, peran kasir)
-- owner: '90000000-0000-0000-0000-000000000002'

-- Pastikan perangkat terdaftar aktif
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

-- 1. Sesi aktif: ikat sesi kasir
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.sama(
  (select (public.ikat_sesi_perangkat(
    'sess_uji_nf03_01',
    'de000000-0000-0000-0000-000000000003',
    'kunci-uji-hp-kasir-0123456789',
    '90000000-0000-0000-0000-000000000004'
  )->>'berhasil')::boolean),
  true,
  'Sesi kasir berhasil diikat ke perangkat'
);

-- Simulasikan kasir bertransaksi dengan token yang membawa claim session_id
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_01"}'::jsonb);
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  true,
  'Sesi baru yang masih aktif terverifikasi true'
);

select uji.sama(
  public.penyewa_saya(),
  '11111111-1111-1111-1111-111111111111'::uuid,
  'penyewa_saya() mengembalikan ID resto bila sesi aktif'
);

select uji.sama(
  public.boleh('beri_diskon'),
  true,
  'boleh() mengizinkan aksi kasir saat sesi aktif'
);

select uji.harap(
  (select count(*)::int from public.pesanan) > 0,
  'Kasir dengan sesi aktif dapat membaca baris pesanan via RLS'
);

-- ---------------------------------------------------------------------------
-- 2. Umur Maksimum: Sesi kedaluwarsa (berakhir_pada terlewati) ditolak
-- ---------------------------------------------------------------------------
-- Paksa berakhir_pada ke masa lalu
reset role;
update public.sesi_perangkat
   set berakhir_pada = now() - interval '1 minute'
 where session_id = 'sess_uji_nf03_01';

select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_01"}'::jsonb);
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'Sesi yang melewati umur maksimum (berakhir_pada <= now) ditolak'
);

select uji.sama(
  public.penyewa_saya(),
  null,
  'penyewa_saya() mengembalikan NULL saat sesi kedaluwarsa'
);

select uji.sama(
  public.boleh('beri_diskon'),
  false,
  'boleh() menolak saat sesi kedaluwarsa'
);

select uji.sama(
  (select count(*)::int from public.pesanan),
  0,
  'Kasir dengan sesi kedaluwarsa mendapat 0 baris pesanan via RLS'
);

-- ---------------------------------------------------------------------------
-- 3. Pencabutan Perangkat: menolak seketika token sesi pada perangkat dicabut
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
-- Ikat sesi kedua
select public.ikat_sesi_perangkat(
  'sess_uji_nf03_02',
  'de000000-0000-0000-0000-000000000003',
  'kunci-uji-hp-kasir-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

-- Verifikasi sesi 2 aktif
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_02"}'::jsonb);
set local role authenticated;
select uji.sama(public.sesi_masih_aktif(), true, 'Sesi 2 aktif sebelum pencabutan');

-- 3a. Uji ketajaman pagar p.aktif: status sesi masih aktif, tapi perangkat dinonaktifkan
reset role;
update public.perangkat set aktif = false where id = 'de000000-0000-0000-0000-000000000003';
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_02"}'::jsonb);
set local role authenticated;
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'Sesi ditolak bila perangkat nonaktif meskipun status baris sesi masih aktif'
);

-- Pulihkan perangkat untuk menguji cabut_perangkat resmi
reset role;
update public.perangkat set aktif = true where id = 'de000000-0000-0000-0000-000000000003';

-- 3b. Owner mencabut perangkat via RPC resmi
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  public.cabut_perangkat('de000000-0000-0000-0000-000000000003', 'Perangkat dicuri'),
  true,
  'Owner berhasil mencabut perangkat'
);

-- Kasir mencoba kembali dengan token sesi 2 (token lama)
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_02"}'::jsonb);
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'Permintaan token lama setelah cabut_perangkat ditolak seketika di database'
);

select uji.sama(
  public.penyewa_saya(),
  null,
  'penyewa_saya() NULL setelah perangkat dicabut'
);

select uji.sama(
  (select count(*)::int from public.pesanan),
  0,
  'Akses data terputus seketika setelah perangkat dicabut'
);

-- ---------------------------------------------------------------------------
-- 4. keluar_semua_perangkat memutus sesi seketika
-- ---------------------------------------------------------------------------
reset role;
update public.perangkat set aktif = true, status = 'aktif' where id = 'de000000-0000-0000-0000-000000000003';
select uji.klaim('90000000-0000-0000-0000-000000000004');
select public.ikat_sesi_perangkat(
  'sess_uji_nf03_03',
  'de000000-0000-0000-0000-000000000003',
  'kunci-uji-hp-kasir-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select (public.keluar_semua_perangkat('90000000-0000-0000-0000-000000000004')->>'berhasil')::boolean;

select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_03"}'::jsonb);
set local role authenticated;
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'Sesi terputus seketika setelah keluar_semua_perangkat'
);

-- ---------------------------------------------------------------------------
-- 5. akhiri_sesi mengakhiri satu sesi tertentu
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
select public.ikat_sesi_perangkat(
  'sess_uji_nf03_04',
  'de000000-0000-0000-0000-000000000003',
  'kunci-uji-hp-kasir-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_uji_nf03_04"}'::jsonb);
set local role authenticated;
select uji.sama(
  (select (public.akhiri_sesi('sess_uji_nf03_04')->>'berhasil')::boolean),
  true,
  'Kasir berhasil mengakhiri sesinya sendiri lewat akhiri_sesi'
);
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'Sesi berstatus dicabut/selesai setelah akhiri_sesi dipanggil'
);
