-- ============================================================================
-- PROBE HAKIM — H-F-06.3 (2026-10-06), verifikasi ulang PMB1-F-082 (migrasi 0101)
-- ============================================================================
-- Dijalankan dari salinan unik di luar repo; berkas ini TIDAK menimpa bukti
-- giliran lain. Setiap `uji.harap`/`uji.sama` di bawah menyatakan PERILAKU YANG
-- DIHARAPKAN HARI INI (sesudah perbaikan 0101). Bila ada yang GAGAL → perbaikan
-- tidak sah. Berbeda dari probe pemeriksa (F-06-persetujuan-perangkat-bypass.sql)
-- yang justru harus GAGAL sekarang, probe ini = kontrol hijau alur sah.
--
-- Yang diperiksa:
--   A. Pasangan (pegawai x perangkat) TANPA baris persetujuan → DITOLAK dengan
--      kode PERANGKAT_BELUM_DISETUJUI, walau PIN & perangkat benar.
--   B. Anti-orakel: PIN salah pada pasangan tanpa persetujuan tetap dijawab
--      KREDENSIAL_TIDAK_VALID (bukan PERANGKAT_BELUM_DISETUJUI) — penolakan
--      memang SESUDAH PIN terbukti benar.
--   C. Sesudah owner menyetujui (RPC setujui_perangkat_pegawai dari kursi
--      authenticated owner) → LOGIN_SUKSES (fungsi tidak rusak).
--   D. RESIDU (dasar temuan baru hakim): jalur pen daftaran RESMI — owner
--      menerbitkan kode, pegawai mendaftarkan perangkat dengan
--      daftarkan_perangkat_dengan_kode — TIDAK menulis baris persetujuan
--      apa pun, sehingga pegawai itu tetap DITOLAK saat login sampai ada
--      yang menyetujui lewat RPC/UI yang (di repo ini) tidak dipanggil klien.
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.3-probe-082.sql
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel (pola berkas uji) ---------------------
delete from public.percobaan_pin;

insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('135790', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

delete from public.persetujuan_perangkat
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and perangkat_id = 'de000000-0000-0000-0000-000000000003';

-- --- A. tanpa persetujuan → DITOLAK (kode spesifik) ------------------------
select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '135790',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode',
  'PERANGKAT_BELUM_DISETUJUI',
  'F-082: PIN benar + perangkat sah tanpa baris persetujuan ditolak PERANGKAT_BELUM_DISETUJUI'
);

-- --- B. anti-orakel: PIN salah tetap KREDENSIAL_TIDAK_VALID ---------------
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '999999',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode',
  'KREDENSIAL_TIDAK_VALID',
  'F-082: PIN salah dijawab KREDENSIAL_TIDAK_VALID — penolakan persetujuan tidak membocorkan keberadaan pasangan'
);

-- --- C. sesudah owner menyetujui → LOGIN_SUKSES (kontrol positif) ---------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (public.setujui_perangkat_pegawai(
    'de000000-0000-0000-0000-000000000003',
    '90000000-0000-0000-0000-000000000004'
  )->>'berhasil')::boolean,
  true,
  'F-082: owner tetap bisa menyetujui pasangan lewat RPC setujui_perangkat_pegawai'
);

select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '135790',
    'de000000-0000-0000-0000-000000000003', 'Tablet Kasir', null
  )->>'kode',
  'LOGIN_SUKSES',
  'F-082: pasangan yang sudah disetujui bisa masuk (aturan baru tidak mengunci alur sah)'
);

-- --- D. RESIDU: jalur pendaftaran RESMI tidak menulis persetujuan ---------
reset role;
delete from public.persetujuan_perangkat
 where perangkat_id <> 'de000000-0000-0000-0000-000000000003';



insert into public.kode_pendaftaran_perangkat (
  penyewa_id, cabang_id, kode, nama_perangkat, jenis, peran_diizinkan, dibuat_oleh
) values (
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'F082PROBE', 'Tablet Alur Resmi', 'pos', array['kasir']::text[],
  '90000000-0000-0000-0000-000000000002'
);

select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.daftarkan_perangkat_dengan_kode(
    'F082PROBE', 'kunci-probe-alur-resmi-0123456789'
  )->>'berhasil')::boolean,
  'F-082 residu: pendaftaran perangkat lewat kode resmi berhasil (jalur sah)'
);

reset role;
-- Kursi anon tidak berhak membaca tabel perangkat; id disimpan lewat tabel
-- sementara supaya asersi login tetap dijalankan dari kursi anon (kursi klien).
create temp table probe_082_dev as
  select id from public.perangkat where nama = 'Tablet Alur Resmi' limit 1;
grant select on probe_082_dev to anon;

-- Berapa baris persetujuan yang lahir dari jalur itu? Harapannya 0.
select uji.sama(
  (select count(*) from public.persetujuan_perangkat pp
    join public.perangkat p on p.id = pp.perangkat_id
   where p.nama = 'Tablet Alur Resmi'),
  0::bigint,
  'F-082 residu: daftarkan_perangkat_dengan_kode tidak menulis baris persetujuan apa pun'
);

select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '135790',
    (select id from probe_082_dev),
    'Tablet Alur Resmi', null
  )->>'kode',
  'PERANGKAT_BELUM_DISETUJUI',
  'F-082 residu: pegawai yang mendaftar lewat kode resmi tetap DITOLAK sampai ada persetujuan manual'
);
