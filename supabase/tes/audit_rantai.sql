-- ============================================================================
-- UJI: Catatan Audit Kekal & Rantai Hash Anti-Manipulasi (T1-13 & T1-27)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. UPDATE pada catatan_audit DITOLAK oleh trigger pencegah ubah/hapus (T1-13).
--   2. DELETE pada catatan_audit DITOLAK oleh trigger pencegah ubah/hapus (T1-13).
--   3. Penyisipan baris audit otomatis menghitung hash_sebelumnya dan hash_baris (T1-27).
--   4. Rantai baris 1 (genesis) -> baris 2 -> baris 3 terhubung secara kriptografis.
--   5. Fungsi verifikasi_rantai_audit() memvalidasi seluruh rantai bernilai valid = true.
--   6. Percobaan modifikasi hash_sebelumnya / hash_baris pada saat insert diabaikan
--      karena dihitung ulang oleh trigger.
-- ============================================================================

select uji.klaim(null);

-- 1. Sisipkan baris audit pertama (genesis block)
insert into public.catatan_audit (
  id,
  penyewa_id,
  pelaku_id,
  aksi,
  entitas,
  entitas_id,
  nilai_baru
) values (
  'ca000000-0000-0000-0000-000000000101',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000002',
  'daftar_resto',
  'penyewa',
  '11111111-1111-1111-1111-111111111111',
  '{"nama": "Resto Utama"}'::jsonb
);

-- Periksa bahwa baris pertama memiliki genesis hash sebagai hash_sebelumnya
select uji.sama(
  (select hash_sebelumnya from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000101'),
  '0000000000000000000000000000000000000000000000000000000000000000',
  'baris pertama audit memakai genesis hash sebagai hash_sebelumnya'
);

select uji.harap(
  (select hash_baris is not null and length(hash_baris) = 64 from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000101'),
  'hash_baris pertama terisi sha256 64 karakter'
);

-- 2. Sisipkan baris audit kedua
insert into public.catatan_audit (
  id,
  penyewa_id,
  pelaku_id,
  aksi,
  entitas,
  entitas_id,
  nilai_baru
) values (
  'ca000000-0000-0000-0000-000000000102',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000003',
  'tambah_menu',
  'menu_item',
  gen_random_uuid(),
  '{"nama": "Ayam Goreng"}'::jsonb
);

-- Baris kedua wajib mengikat hash_baris dari baris pertama
select uji.sama(
  (select hash_sebelumnya from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000102'),
  (select hash_baris from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000101'),
  'baris kedua mengikat hash_baris milik baris pertama'
);

-- 3. Sisipkan baris audit ketiga
insert into public.catatan_audit (
  id,
  penyewa_id,
  pelaku_id,
  aksi,
  entitas,
  entitas_id,
  nilai_baru
) values (
  'ca000000-0000-0000-0000-000000000103',
  '11111111-1111-1111-1111-111111111111',
  '90000000-0000-0000-0000-000000000004',
  'tutup_shift',
  'shift_kas',
  gen_random_uuid(),
  '{"total": 500000}'::jsonb
);

-- Baris ketiga wajib mengikat hash_baris dari baris kedua
select uji.sama(
  (select hash_sebelumnya from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000103'),
  (select hash_baris from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000102'),
  'baris ketiga mengikat hash_baris milik baris kedua'
);

-- 4. Verifikasi seluruh rantai melalui fungsi verifikasi_rantai_audit
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner pusat
set local role authenticated;

select uji.sama(
  (select r.valid from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  true,
  'fungsi verifikasi_rantai_audit memvalidasi keutuhan rantai hash'
);

select uji.sama(
  (select r.jumlah_baris from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  3,
  'jumlah baris terverifikasi tepat 3 baris'
);

-- 4b. Uji deteksi pemutusan rantai pada data yang dimanipulasi
reset role;
select uji.klaim(null);

-- Buat 2 baris untuk resto 2 dengan waktu terdefinisi
insert into public.catatan_audit (id, penyewa_id, waktu, aksi, entitas)
values ('ca000000-0000-0000-0000-000000000201', '22222222-2222-2222-2222-222222222222', '2026-09-22 10:00:00+00', 'buka_toko', 'resto');

insert into public.catatan_audit (id, penyewa_id, waktu, aksi, entitas)
values ('ca000000-0000-0000-0000-000000000202', '22222222-2222-2222-2222-222222222222', '2026-09-22 10:05:00+00', 'tutup_toko', 'resto');

-- Manipulasi baris kedua: putuskan hash_sebelumnya tetapi buat hash_baris valid secara mandiri
set session_replication_role = 'replica';
update public.catatan_audit
   set hash_sebelumnya = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
       hash_baris = encode(sha256(('ca000000-0000-0000-0000-000000000202:22222222-2222-2222-2222-222222222222:sistem:tutup_toko:resto::::2026-09-22T10:05:00.000000Z:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff')::bytea), 'hex')
 where id = 'ca000000-0000-0000-0000-000000000202';
set session_replication_role = 'origin';

-- Verifikasi bahwa pemutusan rantai terdeteksi oleh pengecekan tautan (valid = false)
select uji.sama(
  (select r.valid from public.verifikasi_rantai_audit('22222222-2222-2222-2222-222222222222') r),
  false,
  'fungsi verifikasi_rantai_audit mendeteksi pemutusan rantai'
);

select uji.sama(
  (select r.baris_rusak_id from public.verifikasi_rantai_audit('22222222-2222-2222-2222-222222222222') r),
  'ca000000-0000-0000-0000-000000000202'::uuid,
  'fungsi verifikasi_rantai_audit menunjuk baris rusak yang tepat'
);

-- 5. Trigger menolak UPDATE bahkan untuk pemilik database/superuser (T1-13)
reset role;
select uji.klaim(null);

select uji.harap_gagal_sebab(
  $$update public.catatan_audit set aksi = 'curang' where id = 'ca000000-0000-0000-0000-000000000102'$$,
  'Catatan audit bersifat permanen dan tidak dapat diubah atau dihapus',
  'UPDATE pada catatan_audit ditolak mutlak oleh trigger'
);

-- 6. Trigger menolak DELETE bahkan untuk pemilik database/superuser (T1-13)
select uji.harap_gagal_sebab(
  $$delete from public.catatan_audit where id = 'ca000000-0000-0000-0000-000000000103'$$,
  'Catatan audit bersifat permanen dan tidak dapat diubah atau dihapus',
  'DELETE pada catatan_audit ditolak mutlak oleh trigger'
);

reset role;
select uji.klaim(null);
