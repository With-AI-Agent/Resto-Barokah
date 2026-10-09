-- ============================================================================
-- UJI SQL: perangkat yang lahir dari jalur pendaftaran RESMI (kode sekali
--          pakai, migrasi 0030) tidak boleh menjadi jalan buntu persetujuan
--          (PMB1-F-233 · K-2 · KEPUTUSAN LEE 2026-10-09 "tambal RPC")
-- ============================================================================
-- Yang dijaga (migrasi 0107):
--   1. Pendaftaran lewat kode resmi TETAP tidak menulis baris persetujuan
--      saat pendaftaran (pendaftaran berjalan tanpa identitas pengguna —
--      perilaku 0030 sengaja tidak diubah).
--   2. Saat pegawai pemilik PIN sah pertama kali masuk dari perangkat hasil
--      kode resmi, baris persetujuan (pegawai x perangkat) ditulis OTOMATIS,
--      dinisbatkan kepada PENERBIT KODE (disetujui_oleh = dibuat_oleh), dan
--      login menjawab LOGIN_SUKSES — bukan lagi PERANGKAT_BELUM_DISETUJUI.
--   3. Jejak audit catatan_audit (aksi 'persetujuan_otomatis_kode') tertulis,
--      pelaku = penerbit kode, supaya penyetujuan otomatis ini terlacak.
--   4. Login kedua tetap LOGIN_SUKSES dan baris persetujuan tidak mendua
--      (on conflict do nothing).
--   5. KONTROL: perangkat yang TIDAK lahir dari kode resmi tetap wajib
--      disetujui manual — tanpa baris persetujuan login tetap DITOLAK
--      PERANGKAT_BELUM_DISETUJUI (gerbang 0101 tidak dilumpuhkan).
-- Jalankan: node alat/uji-sql.mjs supabase/tes/persetujuan_otomatis_kode_resmi.sql
-- MERAH sebelum 0107: butir 2 menjawab PERANGKAT_BELUM_DISETUJUI (cacat F-233).
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel (pola berkas uji) --------------------
delete from public.percobaan_pin;

insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- Bersihkan sisa nama uji bila ada (supaya berkas ini idempoten).
delete from public.kode_pendaftaran_perangkat where kode = 'F233RESMI';
delete from public.persetujuan_perangkat
 where perangkat_id in (select id from public.perangkat where nama = 'Tablet Kode Resmi F233');
delete from public.kredensial_perangkat
 where perangkat_id in (select id from public.perangkat where nama = 'Tablet Kode Resmi F233');
delete from public.perangkat where nama = 'Tablet Kode Resmi F233';
delete from public.catatan_audit where aksi = 'persetujuan_otomatis_kode';

-- Owner/penerbit menerbitkan kode pendaftaran (T1-24) untuk satu perangkat.
insert into public.kode_pendaftaran_perangkat (
  penyewa_id, cabang_id, kode, nama_perangkat, jenis, peran_diizinkan, dibuat_oleh
) values (
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'F233RESMI', 'Tablet Kode Resmi F233', 'pos', array['kasir']::text[],
  '90000000-0000-0000-0000-000000000002'
);

-- --- 1. Pendaftaran lewat kode resmi (kursi anon, jalur sah 0030) ---------
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.daftarkan_perangkat_dengan_kode(
    'F233RESMI', 'kunci-resmi-f233-0123456789'
  )->>'berhasil')::boolean,
  'F-233: pendaftaran perangkat lewat kode resmi berhasil (jalur sah T1-24)'
);

-- Pendaftaran TETAP tidak menulis persetujuan (perilaku 0030 tidak berubah:
-- persetujuan butuh identitas pengguna yang belum ada saat pendaftaran).
reset role;
select uji.sama(
  (select count(*) from public.persetujuan_perangkat pp
    join public.perangkat p on p.id = pp.perangkat_id
   where p.nama = 'Tablet Kode Resmi F233'),
  0::bigint,
  'F-233: pendaftaran kode resmi tetap tidak menulis persetujuan saat daftar (dinulis saat login pertama)'
);

-- Id perangkat hasil pendaftaran disimpan lewat tabel sementara supaya asersi
-- login tetap dijalankan dari kursi anon (kursi klien, pola probe H-F-06.3).
create temp table uji_f233_dev as
  select id from public.perangkat where nama = 'Tablet Kode Resmi F233' limit 1;
grant select on uji_f233_dev to anon;

-- --- 2. Login pertama dari perangkat kode resmi → LOGIN_SUKSES ------------
select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205',
    (select id from uji_f233_dev),
    'Tablet Kode Resmi F233', 'kunci-resmi-f233-0123456789'
  )->>'kode',
  'LOGIN_SUKSES',
  'F-233: pegawai sah yang memakai perangkat hasil kode resmi tidak lagi jalan buntu — login pertama berhasil'
);

-- --- 3. Baris persetujuan otomatis dinisbatkan ke penerbit kode -----------
reset role;
select uji.harap(
  exists (
    select 1 from public.persetujuan_perangkat pp
     where pp.perangkat_id = (select id from uji_f233_dev)
       and pp.pengguna_id = '90000000-0000-0000-0000-000000000004'
       and pp.penyewa_id = '11111111-1111-1111-1111-111111111111'
       and pp.disetujui_oleh = '90000000-0000-0000-0000-000000000002'
  ),
  'F-233: baris persetujuan otomatis ada, disetujui_oleh = penerbit kode (bukan diri pegawai)'
);

-- Jejak audit penyetujuan otomatis.
select uji.harap(
  exists (
    select 1 from public.catatan_audit ca
     where ca.aksi = 'persetujuan_otomatis_kode'
       and ca.pelaku_id = '90000000-0000-0000-0000-000000000002'
       and ca.entitas_id = (select id from uji_f233_dev)
       and ca.penyewa_id = '11111111-1111-1111-1111-111111111111'
  ),
  'F-233: catatan_audit memuat persetujuan_otomatis_kode dengan pelaku = penerbit kode'
);

-- --- 4. Login kedua tetap berhasil, baris tidak mendua ---------------------
select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205',
    (select id from uji_f233_dev),
    'Tablet Kode Resmi F233', 'kunci-resmi-f233-0123456789'
  )->>'kode',
  'LOGIN_SUKSES',
  'F-233: login kedua tetap berhasil (persetujuan otomatis idempoten)'
);
reset role;
select uji.sama(
  (select count(*) from public.persetujuan_perangkat pp
    where pp.perangkat_id = (select id from uji_f233_dev)),
  1::bigint,
  'F-233: baris persetujuan tepat satu walau login berulang (on conflict do nothing)'
);

-- --- 5. KONTROL: perangkat NON-kode-resmi tetap wajib persetujuan manual --
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

delete from public.persetujuan_perangkat
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and perangkat_id = 'de000000-0000-0000-0000-000000000003';

select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode',
  'PERANGKAT_BELUM_DISETUJUI',
  'F-233 kontrol: perangkat yang TIDAK lahir dari kode resmi tetap ditolak tanpa persetujuan manual (gerbang 0101 utuh)'
);
