-- ============================================================================
-- UJI: PIN pegawai — tidak pernah teks biasa + percobaan dibatasi (T1-06)
-- Membuktikan: PIN tersimpan sebagai hash, PIN mentah ditolak database,
-- PIN salah dibatasi 5 kali/akun & 12 kali/perangkat per 15 menit, catatan
-- percobaan tersimpan, pemulihan setelah tunggu bekerja, dan PIN atasan tidak
-- bisa dipakai untuk tindakan yang memang bukan haknya.
--
-- Catatan: di lingkungan uji lokal, crypt()/gen_salt() adalah tiruan berlabel
-- dari alat uji (PGlite tidak memuat pgcrypto). Di Supabase, bcrypt asli yang
-- dipakai — perilaku yang diuji di sini tidak bergantung algoritmanya.
-- ============================================================================

-- 1. PIN mentah DITOLAK database (bukan hanya oleh kode aplikasi).
--    Rahasianya ada di tabel sendiri (`kredensial_pin`) sejak audit AUD-3 K-2 — tabel itu
--    tidak diberi hak apa pun kepada klien, berbeda dari `pengguna` yang bisa dibaca klien.
select uji.harap_gagal_sebab($$insert into public.kredensial_pin (pengguna_id, pin_hash)
      values ('90000000-0000-0000-0000-000000000004', '123456')$$, 'violates check constraint "kredensial_pin_pin_hash_check"', 'PIN mentah tidak boleh disimpan di kolom pin_hash');
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'kredensial_pin' and column_name = 'pin_hash'),
  1::bigint,
  'kolom pin_hash ada di tabel rahasia kredensial_pin'
);
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'pengguna' and column_name = 'pin_hash'),
  0::bigint,
  'kolom pin_hash TIDAK ada lagi di pengguna (yang bisa dibaca klien)'
);

-- 2. Hanya pemegang izin yang boleh menyimpan PIN pegawai lain.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab($$select public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'permission denied for function verifikasi_pin', 'anon tidak boleh memakai gerbang PIN');
select uji.harap_gagal_sebab($$select public.simpan_pin('1234', null, null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'permission denied for function simpan_pin', 'anon tidak boleh menyimpan PIN');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$select public.simpan_pin('560812', null, '90000000-0000-0000-0000-000000000005', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'Anda tidak berizin mengubah PIN pegawai lain', 'kasir tanpa izin kelola_pegawai tidak boleh menyimpan PIN pegawai lain');
select uji.harap_gagal_sebab($$select public.simpan_pin('12', null, null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN terlalu pendek ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('abcdef', null, null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN bukan angka ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('1234567', null, null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN lebih dari 6 angka ditolak');
reset role;
select uji.klaim(null);

-- 3. Owner memasang PIN awal pegawai (PIN pertama boleh tanpa PIN lama).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('516372', null, '90000000-0000-0000-0000-000000000004', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'PIN kasir tersimpan oleh owner');
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000003', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'PIN admin tersimpan oleh owner');
select uji.sama(public.simpan_pin('692735', null, '90000000-0000-0000-0000-000000000006', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'PIN dapur tersimpan oleh owner');
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'owner memasang PIN-nya sendiri');
reset role;
select uji.klaim(null);

-- 4. Yang tersimpan BENAR-BENAR hash, bukan PIN.
select uji.harap(
  (select k.pin_hash from public.kredensial_pin k where k.pengguna_id = '90000000-0000-0000-0000-000000000004') <> '516372',
  'hash PIN tidak sama dengan PIN'
);
select uji.harap(
  (select k.pin_hash from public.kredensial_pin k where k.pengguna_id = '90000000-0000-0000-0000-000000000004') not like '%2468%',
  'hash PIN tidak memuat PIN mentah'
);
select uji.harap(
  (select k.pin_hash from public.kredensial_pin k where k.pengguna_id = '90000000-0000-0000-0000-000000000004') ~ '^\$',
  'hash PIN berbentuk hash bersandi'
);
select uji.harap(
  (select p.pin_diubah_pada is not null from public.pengguna p where p.id = '90000000-0000-0000-0000-000000000004'),
  'waktu perubahan PIN tercatat'
);
select uji.harap(
  pg_get_function_result('public.verifikasi_pin(uuid, text, text, uuid, text, uuid)'::regprocedure) not like '%hash%',
  'verifikasi_pin tidak pernah mengembalikan hash'
);

-- 5. PIN salah dijawab salah, PIN benar diterima; semuanya TERCATAT.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), false, 'PIN salah ditolak');
select uji.sama((select v.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 'PIN salah.', 'pesan PIN salah jelas');
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 2, 'sisa percobaan berkurang setelah tiga kali salah');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), true, 'PIN owner diterima untuk menyetujui void sesudah dapur');
reset role;
select uji.klaim(null);

select uji.sama(
  (select count(*) from public.percobaan_pin where pengguna_id = '90000000-0000-0000-0000-000000000002' and not berhasil),
  3::bigint,
  'tiga percobaan salah tercatat'
);
select uji.sama(
  (select count(*) from public.percobaan_pin where pengguna_id = '90000000-0000-0000-0000-000000000002' and berhasil),
  1::bigint,
  'percobaan berhasil pun tercatat'
);

-- 6. PIN BENAR tetapi pegawainya tidak berizin untuk aksi itu → tetap ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '692735', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v),
  false,
  'PIN pegawai dapur tidak bisa dipakai menyetujui void (tidak berizin)'
);
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '692735', 'ubah_stok', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789') v),
  true,
  'PIN pegawai dapur berlaku untuk aksi yang memang haknya'
);
select uji.sama(
  (select v.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000007', '692735', 'ubah_stok', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789') v),
  'PIN tidak dikenali.',
  'PIN pegawai resto lain ditolak dengan pesan yang tidak membocorkan apa pun'
);
reset role;
select uji.klaim(null);

-- 7. Pegawai mengganti PIN-nya sendiri: PIN lama salah → ditolak; PIN lama benar → boleh.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(public.ganti_pin('135791', '445577', 'de000000-0000-0000-0000-000000000005', 'kunci-uji-hp-dapur-0123456789') like 'PIN lama salah%', true,
  'ganti PIN dengan PIN lama salah ditolak (pesan — sejak F-14 catatan percobaan bertahan)');
select uji.sama(public.ganti_pin('692735', '445577', 'de000000-0000-0000-0000-000000000005', 'kunci-uji-hp-dapur-0123456789'), 'PIN tersimpan.', 'ganti PIN dengan PIN lama benar berhasil');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '445577', 'ubah_stok', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789') v), true, 'PIN baru berlaku');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '692735', 'ubah_stok', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789') v), false, 'PIN lama tidak berlaku lagi');
reset role;
select uji.klaim(null);

-- 8. Owner tidak boleh menyimpan PIN pegawai resto lain.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab($$select public.simpan_pin('625084', null, '90000000-0000-0000-0000-000000000007', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789')$$, 'Pegawai itu bukan bagian dari resto Anda', 'owner resto A tidak boleh menyimpan PIN pegawai resto B');
reset role;
select uji.klaim(null);

-- 9. Catatan percobaan hanya terlihat oleh yang berhak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select count(*) from public.percobaan_pin where pengguna_id <> auth.uid()),
  0::bigint,
  'kasir tidak melihat catatan percobaan pegawai lain'
);
select uji.harap_gagal_sebab($$insert into public.percobaan_pin (pengguna_id, perangkat, berhasil) values ('90000000-0000-0000-0000-000000000004', 'HP-PALSU', false)$$, 'permission denied for table percobaan_pin', 'pegawai tidak boleh menulis catatan percobaan langsung');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  (select count(*) from public.percobaan_pin where pengguna_id = '90000000-0000-0000-0000-000000000006') > 0,
  'owner ber-izin kelola_pegawai melihat catatan percobaan pegawainya'
);
reset role;
select uji.klaim(null);

-- 10. Akun NONAKTIF kehilangan PIN-nya.
select uji.klaim(null);
update public.pengguna set aktif = false where id = '90000000-0000-0000-0000-000000000003';
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select v.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789', 'eeee0000-0000-0000-0000-000000000010') v),
  'PIN tidak dikenali.',
  'PIN pegawai nonaktif tidak berlaku lagi'
);
reset role;
select uji.klaim(null);
update public.pengguna set aktif = true where id = '90000000-0000-0000-0000-000000000003';

-- 11. PEMBATASAN PER AKUN: 5 kali salah → terkunci walau PIN-nya benar.
--     (Merapikan dulu catatan lama supaya hitungannya jelas.)
select uji.klaim(null);
delete from public.percobaan_pin;

reset role;
-- Perangkat terdaftar khusus uji pembatas (T1-24) — dibuat jalur pemilik tabel,
-- ikut tergulung balik bersama transaksi berkas uji ini.
insert into public.perangkat (id, penyewa_id, cabang_id, nama) values
  ('de000000-0000-0000-0000-0000000000a1', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-lock-1'),
  ('de000000-0000-0000-0000-0000000000a2', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-lock-2'),
  ('de000000-0000-0000-0000-0000000000a3', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-lock-3'),
  ('de000000-0000-0000-0000-0000000000b1', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-alat'),
  ('de000000-0000-0000-0000-0000000000c1', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'hp-bersih');
insert into public.kredensial_perangkat (perangkat_id, kunci_hash)
select id, crypt('kunci-uji-' || nama || '-0123456789', gen_salt('bf', 10))
  from public.perangkat
 where id in ('de000000-0000-0000-0000-0000000000a1', 'de000000-0000-0000-0000-0000000000a2',
              'de000000-0000-0000-0000-0000000000a3', 'de000000-0000-0000-0000-0000000000b1',
              'de000000-0000-0000-0000-0000000000c1');

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 4, 'sisa percobaan 4 setelah salah pertama');
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 3, 'sisa percobaan 3');
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 2, 'sisa percobaan 2');
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 1, 'sisa percobaan 1');
select uji.sama((select v.sisa_percobaan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), 0, 'sisa percobaan 0 setelah lima kali salah');

select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v), false, 'percobaan keenam DITOLAK walau PIN-nya benar');
select uji.harap(
  (select v.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a1', 'kunci-uji-hp-lock-1-0123456789', 'eeee0000-0000-0000-0000-000000000010') v) like '%terkunci%',
  'pesan menjelaskan PIN terkunci sementara'
);
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a2', 'kunci-uji-hp-lock-2-0123456789', 'eeee0000-0000-0000-0000-000000000010') v),
  false,
  'ganti HP tidak menembus pembatasan per akun'
);

-- 12. PEMULIHAN SETELAH TUNGGU: percobaan lama tidak lagi dihitung.
reset role;
select uji.klaim(null);
update public.percobaan_pin set waktu = now() - interval '20 minutes' where not berhasil;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', 'void_sesudah_dapur', 'de000000-0000-0000-0000-0000000000a3', 'kunci-uji-hp-lock-3-0123456789', 'eeee0000-0000-0000-0000-000000000010') v),
  true,
  'setelah 15 menit lewat, PIN yang benar diterima lagi'
);
reset role;
select uji.klaim(null);

-- 13. PEMBATASAN PER PERANGKAT: 12 kali salah dari satu HP, dibagi 3 akun
--     (masing-masing di bawah 5) → HP itu terkunci, akun-akunnya tidak.
select uji.klaim(null);
delete from public.percobaan_pin;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 1 dari akun owner');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 2 dari akun owner');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 3 dari akun owner');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 4 dari akun owner');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 1 dari akun admin');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 2 dari akun admin');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 3 dari akun admin');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 4 dari akun admin');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 1 dari akun dapur');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 2 dari akun dapur');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 3 dari akun dapur');
select uji.sama((select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v), false, 'salah 4 dari akun dapur');

select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', null, 'de000000-0000-0000-0000-0000000000b1', 'kunci-uji-hp-alat-0123456789') v),
  false,
  'setelah 12 kali salah, HP itu terkunci walau PIN-nya benar'
);
-- Hitungan dibaca sebagai pemilik tabel (RLS membatasi kasir hanya ke barisnya sendiri).
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.percobaan_pin where perangkat = 'hp-alat' and not berhasil),
  13::bigint,
  'penolakan karena HP terkunci tetap tercatat: 12 percobaan salah + 1 percobaan yang ditolak'
);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
-- Aturan yang dipilih: percobaan yang ditolak karena terkunci TETAP dihitung,
-- jadi mengetuk terus-menerus tidak memperpendek masa tunggu. Akibatnya akun
-- owner kini juga mencapai batas per akun:
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', null, 'de000000-0000-0000-0000-0000000000c1', 'kunci-uji-hp-bersih-0123456789') v),
  false,
  'akun owner ikut terkunci karena percobaan yang ditolak tetap dihitung'
);
-- Tetapi akun lain (admin, 4 kali salah) masih bisa dari HP lain:
select uji.sama(
  (select v.berhasil from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '274918', null, 'de000000-0000-0000-0000-0000000000c1', 'kunci-uji-hp-bersih-0123456789') v),
  true,
  'HP lain + akun yang belum mencapai batas tetap bisa memakai PIN'
);
reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- F-15 (2026-09-20): pemanggil NONAKTIF ditolak sebelum pemeriksaan kredensial
-- ----------------------------------------------------------------------------
-- Akun dinonaktifkan pemilik (JWT dianggap masih sah — dunia nyata begitu).
-- Prasyarat: owner punya PIN yang diketahui, supaya tanpa pagar F-15 pemanggil
-- nonaktif benar-benar mendapat berhasil=true (mutasi terbukti MERAH).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
reset role;
update public.pengguna set aktif = false
 where id = '90000000-0000-0000-0000-000000000005';   -- pelayan

select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', null, 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')).berhasil,
  false, 'F-15: pemanggil nonaktif tidak bisa verifikasi PIN siapa pun');
select uji.sama(
  (select count(*) from public.percobaan_pin pp
    where pp.pemanggil_id = '90000000-0000-0000-0000-000000000005'),
  0::bigint, 'F-15: penolakan terjadi sebelum pencatatan/cek kredensial (tanpa probing)');
reset role;
update public.pengguna set aktif = true
 where id = '90000000-0000-0000-0000-000000000005';
select uji.klaim(null);
