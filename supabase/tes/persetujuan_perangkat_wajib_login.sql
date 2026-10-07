-- ============================================================================
-- UJI SQL: persetujuan pemilik WAJIB ada sebelum staf masuk dari suatu
--          perangkat (PMB1-F-082 · K-2 · KEAMANAN §4)
-- ============================================================================
-- Yang dijaga (migrasi 0101):
--   1. Staf dengan PIN benar pada perangkat terdaftar yang SAH tetap DITOLAK
--      (PERANGKAT_BELUM_DISETUJUI) bila belum ada baris persetujuan untuk
--      pasangan (pegawai x perangkat) itu — sebelumnya (0061/0087) tabel
--      persetujuan_perangkat tidak pernah dibaca saat login.
--   2. Setelah baris persetujuan ada (owner/admin menyetujui), login berhasil.
--   3. Pendaftaran mandiri perangkat baru (jalur saklar F-036 hidup & jalur
--      perangkat pertama penyewa baru) TIDAK terkunci oleh aturan baru:
--      pelakunya dicatat sebagai penyetuju dirinya sendiri.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/persetujuan_perangkat_wajib_login.sql
-- ============================================================================

-- Penyiapan sebagai pemilik tabel (pola berkas data uji).
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

-- Pastikan TIDAK ADA persetujuan untuk pasangan Rina x hp-kasir.
delete from public.persetujuan_perangkat
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and perangkat_id = 'de000000-0000-0000-0000-000000000003';

-- 1. PIN benar + perangkat sah + TANPA persetujuan -> DITOLAK.
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode') = 'PERANGKAT_BELUM_DISETUJUI',
  'F-082: login tanpa baris persetujuan ditolak PERANGKAT_BELUM_DISETUJUI'
);

-- 2. Owner menyetujui pasangan itu -> login berhasil.
reset role;
insert into public.persetujuan_perangkat (penyewa_id, perangkat_id, pengguna_id, disetujui_oleh)
values (
  '11111111-1111-1111-1111-111111111111',
  'de000000-0000-0000-0000-000000000003',
  '90000000-0000-0000-0000-000000000004',
  '90000000-0000-0000-0000-000000000002'
);
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode') = 'LOGIN_SUKSES',
  'F-082: setelah owner menyetujui pasangan, login berhasil'
);

-- 3. Jalur saklar F-036 (owner mendaftarkan perangkatnya sendiri) tetap hidup:
--    perangkat baru yang didaftarkan mandiri otomatis mencatat persetujuan
--    oleh pelakunya sendiri, jadi login berikutnya tidak terkunci.
reset role;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
update public.pengaturan
   set izin_daftar_perangkat_bebas_peran_berkuasa = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516',
    'f0820000-0000-4000-8000-000000000001', 'HP Baru Owner', null
  )->>'kode') = 'LOGIN_SUKSES',
  'F-082: pendaftaran mandiri perangkat owner (saklar hidup) tetap berhasil masuk'
);
reset role;
select uji.harap(
  exists (
    select 1 from public.persetujuan_perangkat
     where perangkat_id = 'f0820000-0000-4000-8000-000000000001'
       and pengguna_id = '90000000-0000-0000-0000-000000000002'
       and disetujui_oleh = '90000000-0000-0000-0000-000000000002'
  ),
  'F-082: pendaftaran mandiri mencatat persetujuan diri sendiri (jejak audit)'
);
update public.pengaturan
   set izin_daftar_perangkat_bebas_peran_berkuasa = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- 4. Bootstrap penyewa baru tanpa perangkat: staf pertama tetap boleh
--    mendaftarkan perangkat pertama dan langsung masuk (persetujuan mandiri).
reset role;
insert into public.penyewa (id, nama, slug, zona_waktu)
values ('f0820000-0000-0000-0000-0000000000bb', 'Resto Uji F-082', 'uji-f082', 'Asia/Jakarta')
on conflict (id) do nothing;
insert into auth.users (id, email)
values ('f0820000-0000-0000-0000-0000000000aa', 'kasir.perintis@contoh.test')
on conflict (id) do nothing;
insert into public.cabang (id, penyewa_id, nama, alamat)
values ('f0820000-0000-0000-0000-0000000000c1', 'f0820000-0000-0000-0000-0000000000bb', 'Pusat Uji', 'Jl. Uji 1')
on conflict (id) do nothing;
insert into public.pengguna (id, penyewa_id, nama, email, peran)
values ('f0820000-0000-0000-0000-0000000000aa', 'f0820000-0000-0000-0000-0000000000bb',
        'Kasir Perintis', 'kasir.perintis@contoh.test', 'kasir')
on conflict (id) do nothing;
insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('f0820000-0000-0000-0000-0000000000aa', 'f0820000-0000-0000-0000-0000000000c1');
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('f0820000-0000-0000-0000-0000000000aa', crypt('246810', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.perintis@contoh.test', '246810',
    'f0820000-0000-4000-8000-000000000002', 'Tablet Perintis', null
  )->>'kode') = 'LOGIN_SUKSES',
  'F-082: perangkat pertama penyewa baru tetap bisa didaftarkan & dimasuki'
);
