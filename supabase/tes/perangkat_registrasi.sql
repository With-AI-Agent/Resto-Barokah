-- ============================================================================
-- UJI: perangkat TERDAFTAR — pendaftaran, pencabutan, dan kerahasiaan kunci (T1-24)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. Kasir TANPA izin kelola_pegawai tidak bisa mendaftarkan perangkat.
--   2. Admin cabang bisa mendaftarkan perangkat untuk cabangnya; kunci disimpan
--      sebagai hash bcrypt (bukan teks biasa) — diverifikasi jalur pemilik tabel.
--   3. Kunci pendek (< 16 karakter) ditolak.
--   4. Cabang yang tidak dikelola (resto lain) ditolak.
--   5. Perangkat terdaftar bisa dipakai verifikasi PIN; setelah DICABUT tidak bisa.
--   6. Kasir tanpa kelola_pegawai tidak melihat daftar perangkat (RLS); dan
--      TIDAK ADA klien yang bisa membaca kredensial_perangkat (hash kunci).
--   7. `perangkat_sah` tidak bisa dipanggil klien (anti-oracle, pola F-11).
-- ============================================================================

-- 1. Kasir (Rina, tanpa kelola_pegawai) mencoba mendaftarkan perangkat → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-gelap', 'kunci-panjang-0123456789', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'kelola_pegawai',
  'kasir tanpa izin tidak bisa mendaftarkan perangkat'
);
reset role;

-- 2. Admin cabang mendaftarkan perangkat untuk cabangnya → berhasil.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap(
  (select public.daftarkan_perangkat('hp-tes-registrasi', 'kunci-panjang-0123456789',
                                     'a1a1a1a1-0000-0000-0000-000000000001')) is not null,
  'admin cabang mendaftarkan perangkat untuk cabangnya'
);

-- 3. Kunci pendek ditolak.
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-kunci-pendek', 'pendek', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'minimal 16 karakter',
  'kunci perangkat wajib panjang (dibangkitkan aplikasi)'
);

-- 4. Cabang resto lain ditolak.
select uji.harap_gagal_sebab(
  $$select public.daftarkan_perangkat('hp-lintas-resto', 'kunci-panjang-0123456789', 'b1b1b1b1-0000-0000-0000-000000000001')$$,
  'cabang yang Anda kelola',
  'perangkat hanya untuk cabang yang dikelola'
);
reset role;

-- 2b. Kunci tersimpan sebagai HASH bcrypt, bukan teks biasa (jalur pemilik tabel).
select uji.klaim(null);
select uji.harap(
  (select kp.kunci_hash ~ '^\$[a-z0-9]+\$' and kp.kunci_hash <> 'kunci-panjang-0123456789'
     from public.kredensial_perangkat kp
     join public.perangkat pr on pr.id = kp.perangkat_id
    where pr.nama = 'hp-tes-registrasi'),
  'kunci perangkat disimpan sebagai hash, bukan teks biasa'
);

-- 5. Perangkat baru bisa dipakai verifikasi; sesudah dicabut → tidak bisa.
--    (Admin memasang PIN dulu untuk dirinya lewat perangkat data-uji.)
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(public.simpan_pin('317259', null, null,
                                  'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789'),
                'PIN tersimpan.', 'admin memasang PIN-nya sendiri');
select uji.sama(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '317259', null,
                                             (select pr.id from public.perangkat pr where pr.nama = 'hp-tes-registrasi'),
                                             'kunci-panjang-0123456789') r),
  'PIN diterima.',
  'perangkat yang baru terdaftar langsung sah dipakai'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner mencabut
set local role authenticated;
select uji.harap(
  public.cabut_perangkat((select pr.id from public.perangkat pr where pr.nama = 'hp-tes-registrasi')),
  'owner mencabut perangkat'
);
select uji.sama(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '317259', null,
                                             (select pr.id from public.perangkat pr where pr.nama = 'hp-tes-registrasi'),
                                             'kunci-panjang-0123456789') r),
  'Perangkat tidak dikenali.',
  'perangkat yang dicabut tidak bisa lagi dipakai'
);

-- 6. Kasir tanpa kelola_pegawai tidak melihat daftar perangkat (RLS baris), dan
--    kredensial kunci tidak terbaca klien mana pun.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select count(*) from public.perangkat)::bigint,
  0::bigint,
  'kasir tanpa kelola_pegawai tidak melihat perangkat apa pun'
);
select uji.harap_gagal_sebab(
  $$select count(*) from public.kredensial_perangkat$$,
  'permission denied for table kredensial_perangkat',
  'hash kunci perangkat tidak terbaca klien'
);
-- 7. pemeriksa internal tidak bisa dipanggil klien (anti-oracle).
select uji.harap_gagal_sebab(
  $$select public.perangkat_sah('de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789')$$,
  'permission denied for function perangkat_sah',
  'perangkat_sah bukan oracle klien'
);
reset role;
select uji.klaim(null);
