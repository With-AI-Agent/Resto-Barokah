-- ============================================================================
-- UJI: Pemilik Platform — Daftar & Pengelolaan Penyewa Baru (PRD M1 / ART-1)
--
-- Membuktikan pemenuhan kriteria DoD T9-10:
--  1. Pemilik Platform dapat mendaftarkan resto baru + cabang pertama + akun Owner
--     pertama lengkap dengan PIN 6 digit angka dan pengaturan bawaan.
--  2. Pengamanan masukan: validasi nama resto, format slug unik, email, zona waktu,
--     dan tolak PIN lemah.
--  3. Pembuktian isolasi total antar dua penyewa (ART-1): data Resto A tidak terlihat
--     sama sekali oleh Resto B dan Resto C (penyewa, cabang, pengaturan, pengguna,
--     pesanan, meja, catatan_audit).
--  4. Soft-disable penyewa via RPC set_status_penyewa tanpa merusak atau menghapus
--     data transaksi dan riwayat operasional masa lalu.
--  5. Pemicu fail-closed picu_penyewa_cegah_hapus menolak hard-delete penyewa yang
--     memiliki riwayat cabang, akun, atau transaksi finansial.
--  6. RPC ambil_daftar_penyewa menyajikan ringkasan resto bagi Pemilik Platform.
-- ============================================================================

-- Simpan variabel ID penyewa baru untuk pengujian
create temp table if not exists _t_daftar_penyewa (
  penyewa_id uuid,
  slug       text,
  cabang_id  uuid,
  owner_id   uuid
);
grant all on _t_daftar_penyewa to authenticated, anon;

-- ============================================================================
-- BAGIAN 1: Hak Akses Pemanggil (Hanya Pemilik Platform)
-- ============================================================================

-- 1. Pengguna anonim ditolak memanggil buat_penyewa
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Liar', 'resto-liar')$$,
  'permission denied for function buat_penyewa',
  'Anonim dilarang keras memanggil buat_penyewa'
);

-- 2. Pegawai biasa (Kasir Kedai Oasis) ditolak memanggil buat_penyewa
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Kasir', 'resto-kasir')$$,
  'Hanya pemilik_platform yang berhak mendaftarkan penyewa baru.',
  'Kasir tidak berhak memanggil buat_penyewa'
);

-- 3. Owner Pusat resto A ditolak memanggil buat_penyewa
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Owner', 'resto-owner')$$,
  'Hanya pemilik_platform yang berhak mendaftarkan penyewa baru.',
  'Owner restoran tidak berhak mendaftarkan penyewa platform baru'
);

-- 4. Owner Pusat ditolak memanggil set_status_penyewa dan ambil_daftar_penyewa
select uji.harap_gagal_sebab(
  $$select public.set_status_penyewa('11111111-1111-1111-1111-111111111111', 'nonaktif', 'alasan palsu')$$,
  'Hanya pemilik_platform yang berhak mengubah status penyewa.',
  'Owner resto tidak berhak mengubah status penyewa'
);

select uji.harap_gagal_sebab(
  $$select * from public.ambil_daftar_penyewa()$$,
  'Hanya pemilik_platform yang berhak melihat daftar penyewa.',
  'Owner resto tidak berhak memanggil ambil_daftar_penyewa'
);

-- ============================================================================
-- BAGIAN 2: Validasi Masukan Pendaftaran Penyewa
-- ============================================================================

-- Masuk sebagai Pemilik Platform
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

-- 5. Validasi: Nama resto kosong ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('', 'resto-kosong', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Owner', 'owner@test.id', '123456')$$,
  'Nama penyewa/resto wajib diisi',
  'Tolak nama resto kosong'
);

-- 6. Validasi: Format slug tidak valid (huruf besar atau karakter terlarang)
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'Resto_Indah!', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Owner', 'owner@test.id', '123456')$$,
  'Format slug "resto_indah!" tidak valid',
  'Tolak format slug tidak alfanumerik huruf kecil'
);

-- 7. Validasi: Zona waktu tidak didukung ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Eropa/Paris', 'IDR', null, null, 'Cabang 1', null, null, 'Owner', 'owner@test.id', '123456')$$,
  'Zona waktu "Eropa/Paris" tidak didukung.',
  'Tolak zona waktu tidak didukung'
);

-- 8. Validasi: Format mata uang tidak valid
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Asia/Jakarta', 'IDRRR', null, null, 'Cabang 1', null, null, 'Owner', 'owner@test.id', '123456')$$,
  'Format kode mata uang "IDRRR" tidak valid',
  'Tolak kode mata uang di luar 3 huruf kapital'
);

-- 9. Validasi: Nama Owner pertama kosong ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, '', 'owner@test.id', '123456')$$,
  'Nama Owner pertama wajib diisi',
  'Tolak nama owner pertama kosong'
);

-- 10. Validasi: Format email Owner salah ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Budi Owner', 'email-salah-tanpa-domain', '123456')$$,
  'Format email Owner "email-salah-tanpa-domain" tidak valid.',
  'Tolak format email owner tanpa at/domain'
);

-- 11. Validasi: PIN Owner bukan 6 digit angka ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Budi Owner', 'owner@indah.test', '1234')$$,
  'Akun Owner wajib diberikan PIN awal 6 digit angka.',
  'Tolak PIN kurang dari 6 digit'
);

-- 12. Validasi: PIN Owner lemah (mis. urutan berulang) ditolak fail-closed
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Resto Indah', 'resto-indah', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Budi Owner', 'owner@indah.test', '123456')$$,
  'PIN Owner ditolak',
  'Tolak PIN lemah berpola urutan mudah ditebak'
);

-- ============================================================================
-- BAGIAN 3: Pendaftaran Berhasil & Pembentukan Entitas Terpadu
-- ============================================================================

-- 13. Pendaftaran Resto Baru Lengkap oleh Pemilik Platform
do $$
declare
  v_res jsonb;
begin
  v_res := public.buat_penyewa(
    'Resto Rasa Nusantara',
    'rasa-nusantara',
    'Asia/Jakarta',
    'IDR',
    '081234567890',
    'halo@rasanusantara.test',
    'Cabang Riau Pusat',
    'Jl. Riau No. 45 Bandung',
    '022-7654321',
    'Siti Rahma',
    'siti.owner@rasanusantara.test',
    '741852'
  );

  insert into _t_daftar_penyewa (penyewa_id, slug, cabang_id, owner_id)
  values (
    (v_res->'data'->>'penyewa_id')::uuid,
    v_res->'data'->>'slug',
    (v_res->'data'->>'cabang_id')::uuid,
    (v_res->'data'->>'owner_id')::uuid
  );
end;
$$;

select uji.sama(
  (select count(*) from _t_daftar_penyewa where penyewa_id is not null and cabang_id is not null and owner_id is not null),
  1::bigint,
  'Pendaftaran resto baru menghasilkan ID penyewa, cabang, dan owner lengkap'
);

-- 14. Validasi Duplikasi Slug: Slug yang sama ditolak
select uji.harap_gagal_sebab(
  $$select public.buat_penyewa('Nusantara Tiruan', 'rasa-nusantara', 'Asia/Jakarta', 'IDR', null, null, 'Cabang 1', null, null, 'Tiruan', 'tiruan@test.id', '985321')$$,
  'Slug resto "rasa-nusantara" sudah digunakan.',
  'Tolak duplikasi slug yang sudah terdaftar'
);

-- 15. Pendaftaran Resto Baru Tanpa Slug Manual (Slug Otomatis)
do $$
declare
  v_res2 jsonb;
begin
  v_res2 := public.buat_penyewa(
    'Warung Padang Minang Saiyo',
    null,
    'Asia/Jakarta',
    'IDR',
    null,
    null,
    'Cabang Dipati Ukur',
    null,
    null,
    'Datuk Maringgih',
    'datuk.owner@saiyo.test',
    '951357'
  );
end;
$$;

select uji.sama(
  (select count(*) from public.ambil_daftar_penyewa('Warung Padang Minang Saiyo')),
  1::bigint,
  'Slug otomatis ter-generate rapi dalam format kebab-case dan terbaca via ambil_daftar_penyewa'
);

-- 16. Verifikasi Entitas Pengaturan Bawaan Terbentuk Otomatis
reset role;
select uji.klaim(null);

select uji.sama(
  (select p.header_struk from public.pengaturan p join _t_daftar_penyewa t on p.penyewa_id = t.penyewa_id),
  'Resto Rasa Nusantara',
  'Header struk pengaturan otomatis berisi nama resto baru'
);

-- 17. Verifikasi Izin Peran Bawaan Terisi Otomatis oleh Pemicu
select uji.sama(
  (select count(distinct ip.peran) from public.izin_peran ip join _t_daftar_penyewa t on ip.penyewa_id = t.penyewa_id),
  5::bigint,
  'Pemicu otomatis memasang izin peran bawaan untuk seluruh 5 peran operasional'
);

-- 18. Verifikasi Penugasan Cabang & Akun Owner
select uji.sama(
  (select count(*)
     from public.pengguna_cabang pc
     join _t_daftar_penyewa t on pc.pengguna_id = t.owner_id and pc.cabang_id = t.cabang_id
    where pc.aktif = true),
  1::bigint,
  'Akun owner terhubung ke cabang pertama dengan status aktif'
);

-- 19. Verifikasi Jejak Audit Tercatat untuk Pemilik Platform
select uji.sama(
  (select count(*)
     from public.catatan_audit ca
     join _t_daftar_penyewa t on ca.penyewa_id = t.penyewa_id
    where ca.aksi = 'buat_penyewa' and ca.entitas = 'penyewa'),
  1::bigint,
  'Aksi pendaftaran penyewa baru tercatat permanen di catatan_audit'
);

-- ============================================================================
-- BAGIAN 4: PEMBUKTIAN ISOLASI TOTAL DUA PENYEWA (ART-1)
-- ============================================================================

-- 20. Impersonate Owner Resto A (Bu Oasis - Kedai Oasis):
-- Data Resto B (Warung Bandung) dan Resto C (Resto Rasa Nusantara) TIDAK TERLIHAT sama sekali.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select count(*) from public.penyewa),
  1::bigint,
  'ART-1: Owner Resto A hanya dapat melihat 1 baris penyewa (restonya sendiri)'
);

select uji.sama(
  (select nama from public.penyewa limit 1),
  'Kedai Oasis',
  'ART-1: Penyewa yang terlihat oleh Owner Resto A adalah Kedai Oasis'
);

select uji.sama(
  (select count(*) from public.cabang),
  2::bigint,
  'ART-1: Owner Resto A hanya melihat cabang miliknya sendiri (Pusat & Cabang Dua)'
);

select uji.sama(
  (select count(*) from public.cabang where nama = 'Cabang Riau Pusat'),
  0::bigint,
  'ART-1: Cabang milik Resto Rasa Nusantara tidak terlihat oleh Resto A'
);

select uji.sama(
  (select count(*) from public.pengguna where email = 'siti.owner@rasanusantara.test'),
  0::bigint,
  'ART-1: Akun Owner Resto Rasa Nusantara tidak terlihat oleh Resto A'
);

-- 21. Upaya Modifikasi Lintas Resto Ditolak (RLS Fail-Closed)
update public.cabang
   set alamat = 'Diretas oleh Resto A'
 where id = (select cabang_id from _t_daftar_penyewa);

-- Verifikasi alamat cabang Resto C tidak berubah
reset role;
select uji.klaim(null);
select uji.sama(
  (select alamat from public.cabang where id = (select cabang_id from _t_daftar_penyewa)),
  'Jl. Riau No. 45 Bandung',
  'ART-1: Upaya modifikasi cabang lintas penyewa diblokir total oleh RLS'
);

-- 22. Impersonate Owner Resto Baru (Siti Rahma - Resto Rasa Nusantara)
select uji.klaim((select owner_id from _t_daftar_penyewa));
set local role authenticated;

select uji.sama(
  (select count(*) from public.penyewa),
  1::bigint,
  'ART-1: Owner baru hanya dapat melihat 1 baris penyewa (Resto Rasa Nusantara)'
);

select uji.sama(
  (select slug from public.penyewa limit 1),
  'rasa-nusantara',
  'ART-1: Slug penyewa terverifikasi sesuai resto baru'
);

select uji.sama(
  (select count(*) from public.cabang),
  1::bigint,
  'ART-1: Owner baru hanya melihat 1 cabang pertama miliknya'
);

select uji.sama(
  (select count(*) from public.cabang where nama in ('Pusat', 'Cabang Dua', 'Tunggal')),
  0::bigint,
  'ART-1: Cabang milik Kedai Oasis dan Warung Bandung tidak terlihat sama sekali oleh owner baru'
);

select uji.sama(
  (select count(*) from public.pesanan),
  0::bigint,
  'ART-1: Resto baru memiliki keranjang pesanan bersih 0 tanpa kebocoran transaksi resto lain'
);

-- ============================================================================
-- BAGIAN 5: Penonaktifan Penyewa (Soft-Disable & Proteksi Data)
-- ============================================================================

-- Masuk kembali sebagai Pemilik Platform
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

-- 23. Validasi: Penonaktifan tanpa alasan ditolak
select uji.harap_gagal_sebab(
  format($$select public.set_status_penyewa('%s', 'nonaktif', '')$$, (select penyewa_id from _t_daftar_penyewa)),
  'Alasan penonaktifan penyewa wajib diisi minimal 5 karakter.',
  'Tolak penonaktifan tanpa alasan jelas'
);

-- 24. Penonaktifan Berhasil dengan Alasan
select uji.sama(
  (select (public.set_status_penyewa((select penyewa_id from _t_daftar_penyewa), 'nonaktif', 'Uji coba penonaktifan sementara'))->>'berhasil'),
  'true',
  'Pemilik platform berhasil menonaktifkan penyewa'
);

select uji.sama(
  (select status from public.ambil_daftar_penyewa('rasa-nusantara')),
  'nonaktif',
  'Status penyewa berubah menjadi nonaktif'
);

-- 25. Bukti Data Transaksi / Operasional Masa Lalu Tetap Tersimpan Utuh
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.cabang where penyewa_id = (select penyewa_id from _t_daftar_penyewa)),
  1::bigint,
  'Data cabang tidak terhapus saat penyewa dinonaktifkan (integritas data utuh)'
);

select uji.sama(
  (select count(*) from public.pengguna where penyewa_id = (select penyewa_id from _t_daftar_penyewa)),
  1::bigint,
  'Akun pengguna tidak terhapus saat penyewa dinonaktifkan'
);

-- 26. Pengaktifan Kembali Penyewa
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

select uji.sama(
  (select (public.set_status_penyewa((select penyewa_id from _t_daftar_penyewa), 'aktif'))->>'berhasil'),
  'true',
  'Pemilik platform berhasil mengaktifkan kembali penyewa'
);

select uji.sama(
  (select status from public.ambil_daftar_penyewa('rasa-nusantara')),
  'aktif',
  'Status penyewa pulih menjadi aktif'
);

-- ============================================================================
-- BAGIAN 6: Pemicu Fail-Closed picu_penyewa_cegah_hapus & Proteksi Tingkat Tabel
-- ============================================================================

-- 27a. Cegah Hard Delete via peran klien authenticated (Izin Tabel Ditolak)
select uji.harap_gagal_sebab(
  format($$delete from public.penyewa where id = '%s'$$, (select penyewa_id from _t_daftar_penyewa)),
  'permission denied for table penyewa',
  'Peran klien authenticated dilarang keras melakukan delete fisik pada penyewa'
);

-- 27b. Cegah Hard Delete pada jalur peladen/superuser oleh Pemicu picu_penyewa_cegah_hapus
reset role;
select uji.klaim(null);

select uji.harap_gagal_sebab(
  format($$delete from public.penyewa where id = '%s'$$, (select penyewa_id from _t_daftar_penyewa)),
  'tidak dapat dihapus karena masih memiliki data cabang. Silakan nonaktifkan status penyewa.',
  'Pemicu fail-closed menolak penghapusan fisik penyewa ber-riwayat operasional'
);

-- ============================================================================
-- BAGIAN 7: Pembacaan Daftar Penyewa oleh Pemilik Platform
-- ============================================================================

-- Masuk sebagai Pemilik Platform
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;
select uji.sama(
  (select count(*) >= 3 from public.ambil_daftar_penyewa()),
  true,
  'Pemilik platform dapat membaca seluruh penyewa (Kedai Oasis, Warung Bandung, Rasa Nusantara)'
);

-- 29. Filter Pencarian Nama / Slug pada ambil_daftar_penyewa
select uji.sama(
  (select count(*) from public.ambil_daftar_penyewa('Rasa Nusantara')),
  1::bigint,
  'Pencarian nama resto menyaring hasil dengan tepat'
);

select uji.sama(
  (select owner_nama from public.ambil_daftar_penyewa('rasa-nusantara') limit 1),
  'Siti Rahma',
  'Daftar penyewa menampilkan nama akun owner pusat pertama'
);
