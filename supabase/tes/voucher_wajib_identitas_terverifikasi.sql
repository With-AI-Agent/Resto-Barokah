-- ============================================================================
-- UJI SQL: Voucher hanya terbit untuk identitas yang terverifikasi peladen
--            (PMB1-F-031 · K-1 · baseline PRD M10 baris 164-167)
-- ============================================================================
-- Yang dijaga:
--   1. Kontrol positif: pelanggan dengan SESI terverifikasi (email sesi = email yang
--      diklaim) tetap bisa memperoleh voucher.
--   2. Sesi ada tetapi alamat yang diklaim BEDA -> ditolak, tidak ada pelanggan/voucher.
--   3. Tanpa sesi sama sekali (auth.uid() null) -> ditolak, apa pun cara_masuk.
--   4. Peran `anon` tidak lagi punya hak EKSEKUSI fungsi (pertahanan lapis kedua).
--   5. Jalur `kasir` (petugas mencatat pelanggan di tempat) hanya boleh dipakai staf
--      yang sedang masuk; tanpa sesi staf -> ditolak.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/voucher_wajib_identitas_terverifikasi.sql
-- Migrasi berlaku: 0089_voucher_wajib_identitas_terverifikasi.sql
-- ============================================================================

-- Kampanye uji terpisah supaya tidak bentrok dengan berkas uji lain.
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000031',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye uji identitas F-031', 'UJIF031', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 10, true
);

-- 1. Kontrol positif: sesi terverifikasi, alamat sama -> SUKSES
select uji.klaim('f0310000-0000-0000-0000-000000000001', '{"email":"pelanggan.sah@contoh.test"}'::jsonb);
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Pelanggan Sah',
       'pelanggan.sah@contoh.test',
       '081200000001', null, true, 'google', 'hp-pelanggan-sah', '10.9.0.1'
     ) as hasil),
  'F-031: pelanggan dengan sesi terverifikasi (email sama) tetap mendapat voucher'
);
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000031') = 1,
  'F-031: tepat satu voucher tersimpan untuk identitas terverifikasi'
);

-- 2. Sesi terverifikasi tapi mengklaim alamat orang lain -> DITOLAK
select uji.klaim('f0310000-0000-0000-0000-000000000002', '{"email":"pelanggen.kuat@contoh.test"}'::jsonb);
select uji.harap(
  (select (hasil->>'kode')
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Penyusup',
       'korban.kuat@contoh.test',
       '081200000002', null, true, 'google', 'hp-penyusup', '10.9.0.2'
     ) as hasil) = 'VERIFIKASI_WAJIB',
  'F-031: sesi tidak boleh mengklaim voucher atas nama alamat lain'
);
select uji.harap(
  (select count(*) from public.pelanggan where email = 'korban.kuat@contoh.test') = 0,
  'F-031: alamat yang diklaim orang lain tidak pernah masuk tabel pelanggan'
);
select uji.harap(
  (select count(*) from public.voucher where kode is not null
     and pelanggan_id in (select id from public.pelanggan where email = 'korban.kuat@contoh.test')) = 0,
  'F-031: tidak ada voucher untuk identitas yang tidak bisa diverifikasi'
);

-- 3. Tanpa sesi sama sekali (auth.uid() null) -> DITOLAK untuk google & email
select uji.klaim(null);
select uji.harap(
  (select (hasil->>'kode')
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Tanpa Sesi',
       'tanpa.sesi@contoh.test',
       '081200000003', null, true, 'google', 'hp-anon', '10.9.0.3'
     ) as hasil) = 'VERIFIKASI_WAJIB',
  'F-031: pemanggil tanpa sesi tidak bisa mengaku Google'
);
select uji.harap(
  (select (hasil->>'kode')
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Tanpa Sesi',
       'tanpa.sesi.email@contoh.test',
       '081200000004', null, true, 'email', 'hp-anon-2', '10.9.0.4'
     ) as hasil) = 'VERIFIKASI_WAJIB',
  'F-031: pemanggil tanpa sesi tidak bisa mengaku email terverifikasi'
);
select uji.harap(
  (select count(*) from public.pelanggan
    where email in ('tanpa.sesi@contoh.test', 'tanpa.sesi.email@contoh.test')) = 0,
  'F-031: tidak ada pelanggan palsu yang tercatat dari pemanggil tanpa sesi'
);
select uji.harap(
  (select count(*) from public.voucher where kampanye_id = 'c3000000-0000-0000-0000-000000000031') = 1,
  'F-031: kuotanya tidak bertambah dari percobaan tanpa sesi'
);

-- 4. Pertahanan lapis kedua: peran anon tidak punya hak eksekusi
select uji.harap(
  not has_function_privilege(
    'anon',
    'public.daftar_voucher(uuid,uuid,text,text,text,text,boolean,text,text,text)',
    'EXECUTE'
  ),
  'F-031: peran anon tidak lagi bisa memanggil daftar_voucher langsung'
);

-- 5. Jalur kasir: wajib sesi staf
select uji.harap(
  (select (hasil->>'kode')
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Pelanggan Di Kasir',
       'dicatat.kasir@contoh.test',
       '081200000005', null, true, 'kasir', 'hp-kasir', '10.9.0.5'
     ) as hasil) = 'PENDAFTARAN_HARUS_OLEH_STAF',
  'F-031: pencatatan pelanggan lewat kasir ditolak bila tidak ada staf yang masuk'
);

-- Sesi pelanggan (bukan staf) tetap tidak boleh memakai jalur kasir
select uji.klaim('f0310000-0000-0000-0000-000000000003', '{"email":"pelanggan.sah@contoh.test"}'::jsonb);
select uji.harap(
  (select (hasil->>'kode')
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Pelanggan Di Kasir',
       'dicatat.kasir.2@contoh.test',
       '081200000006', null, true, 'kasir', 'hp-kasir', '10.9.0.6'
     ) as hasil) = 'PENDAFTARAN_HARUS_OLEH_STAF',
  'F-031: pelanggan yang sudah masuk tidak boleh menDAFTARKAN pelanggan lain sebagai kasir'
);

-- Kontrol positif jalur kasir: Rina (kasir A1) mencatat pelanggan di tempat
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"email":"kasir.a1@contoh.test"}'::jsonb);
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000031',
       'Pelanggan Datang Ke Kasir',
       'pelanggan.kasir@contoh.test',
       '081200000007', null, true, 'kasir', 'hp-kasir-rina', '10.9.0.7'
     ) as hasil),
  'F-031: kasir yang sedang masuk tetap bisa mencatat pelanggan di tempat'
);
select uji.harap(
  (select p.didaftarkan_oleh = '90000000-0000-0000-0000-000000000004'
     from public.pelanggan p
    where p.email = 'pelanggan.kasir@contoh.test'),
  'F-031: pelanggan jalur kasir tetap tercatat nama staf pendaftar (jejak pemisahan tugas)'
);
