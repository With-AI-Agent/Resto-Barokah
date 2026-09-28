-- ============================================================================
-- UJI: jejak audit — tabel catatan_audit (T1-13 / temuan F F-07)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. Penulisan (insert) via klien ditolak (sebab dipatok harap_gagal_sebab).
--      Begitu pula update dan delete via klien ditolak.
--   2. Penulisan via jalur pemilik (peladen/superuser) berhasil & terbaca.
--   3. Baca oleh kasir/pelayan tanpa izin kelola_pegawai menghasilkan 0 baris.
--   4. Admin cabang & owner dengan izin kelola_pegawai dapat melihat catatan audit penyewanya.
--   5. Lintas penyewa menghasilkan 0 baris (isolasi multi-tenant).
--   6. Kolom pelaku_id null (peristiwa sistem) dapat disimpan dan dibaca dengan benar.
-- ============================================================================

-- 1. Penulisan via klien DITOLAK (tanpa grant insert/update/delete untuk authenticated).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$insert into public.catatan_audit (penyewa_id, aksi, entitas) values ('11111111-1111-1111-1111-111111111111', 'tambah', 'menu')$$,
  'permission denied.*catatan_audit',
  'insert via klien (kasir) ditolak'
);

select uji.harap_gagal_sebab(
  $$update public.catatan_audit set aksi = 'palsu'$$,
  'permission denied.*catatan_audit',
  'update via klien ditolak'
);

select uji.harap_gagal_sebab(
  $$delete from public.catatan_audit$$,
  'permission denied.*catatan_audit',
  'delete via klien ditolak'
);
reset role;

-- Bahkan admin dengan izin kelola_pegawai pun ditolak menulis langsung lewat klien.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.catatan_audit (penyewa_id, aksi, entitas) values ('11111111-1111-1111-1111-111111111111', 'tambah', 'pegawai')$$,
  'permission denied.*catatan_audit',
  'insert via klien (admin cabang) ditolak — jalur peladen/definer saja'
);
reset role;

-- 2. Penulisan lewat jalur pemilik (peladen/superuser) BERHASIL.
--    Baris 1: kejadian perubahan pengaturan oleh admin cabang di Resto A.
insert into public.catatan_audit (id, penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
values (
  'ca000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000003',
  'ubah_pengaturan',
  'pengaturan',
  '11111111-1111-1111-1111-111111111111',
  '{"pajak_pb1_persen": 10}'::jsonb,
  '{"pajak_pb1_persen": 11}'::jsonb
);

--    Baris 2: kejadian sistem (pelaku_id IS NULL) di Resto A.
insert into public.catatan_audit (id, penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
values (
  'ca000000-0000-0000-0000-000000000002',
  '11111111-1111-1111-1111-111111111111',
  null,
  'cadangan_otomatis',
  'sistem',
  null,
  null,
  '{"status": "sukses", "ukuran_kb": 1240}'::jsonb
);

--    Baris 3: kejadian di Resto B oleh pegawai Resto B.
insert into public.catatan_audit (id, penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
values (
  'ca000000-0000-0000-0000-000000000003',
  '22222222-2222-2222-2222-222222222222',
  '90000000-0000-0000-0000-000000000007',
  'buka_shift',
  'shift_kas',
  null,
  null,
  '{"modal_awal": 100000}'::jsonb
);

-- Bukti jalur pemilik dapat membaca seluruh 3 baris.
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  3,
  'pemilik tabel membaca semua baris audit (jalur peladen/pemilik)'
);

-- 3. Kasir tanpa izin kelola_pegawai membaca 0 baris.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  0,
  'kasir tanpa izin kelola_pegawai membaca 0 baris catatan_audit'
);
reset role;

-- Pelayan tanpa izin kelola_pegawai juga membaca 0 baris.
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  0,
  'pelayan tanpa izin kelola_pegawai membaca 0 baris catatan_audit'
);
reset role;

-- 4. Admin cabang melihat catatan penyewanya.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  2,
  'admin cabang melihat catatan penyewanya (2 baris)'
);
select uji.harap(
  exists (select 1 from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000001'),
  'admin cabang melihat catatan perubahan pengaturan'
);
select uji.harap(
  exists (select 1 from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000002' and pelaku_id is null),
  'admin cabang melihat catatan sistem dengan pelaku null'
);
reset role;

-- Owner pusat juga melihat catatan penyewanya.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  2,
  'owner pusat melihat catatan audit penyewanya (2 baris)'
);
reset role;

-- 5. Lintas penyewa menghasilkan 0 baris.
-- Pegawai Resto A tidak bisa melihat catatan Resto B.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  (select count(*)::int from public.catatan_audit where penyewa_id = '22222222-2222-2222-2222-222222222222'),
  0,
  'admin cabang resto A melihat 0 baris milik resto B'
);
reset role;

-- Berikan izin kelola_pegawai kepada pegawai di Resto B untuk menguji isolasi dari sisi Resto B.
insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000007', 'kelola_pegawai', true);

select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
-- Pegawai Resto B melihat catatannya sendiri (1 baris).
select uji.sama(
  (select count(*)::int from public.catatan_audit),
  1,
  'pegawai resto B berizin kelola_pegawai melihat 1 baris miliknya'
);
-- Pegawai Resto B tidak melihat catatan Resto A (0 baris).
select uji.sama(
  (select count(*)::int from public.catatan_audit where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'pegawai resto B melihat 0 baris milik resto A'
);
reset role;

-- Pengguna anon (belum login) ditolak membaca tabel sama sekali.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select * from public.catatan_audit$$,
  'permission denied.*catatan_audit',
  'anon tidak punya hak baca catatan_audit'
);
reset role;
select uji.klaim(null);
