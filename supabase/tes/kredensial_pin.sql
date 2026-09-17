-- ============================================================================
-- UJI: kredensial PIN — rahasia tidak boleh terbaca klien & ganti PIN wajib PIN lama
-- Temuan audit AUD-3 K-2 (2026-09-17, dua laporan):
--   * F-02/F-10: kolom `pin_hash` bisa dibaca lewat API otomatis (RLS menyaring
--     baris, bukan kolom) — seluruh hash PIN pegawai satu resto bisa ditarik klien.
--   * F-01: `simpan_pin(pin_baru, null, <uuid DIRI SENDIRI>)` tidak memeriksa PIN
--     lama karena penjaganya hanya menyala bila argumen uuid dibiarkan kosong →
--     siapa pun yang memegang perangkat kasir bisa memasang PIN baru & memakai
--     identitas itu untuk menyetujui void/diskon.
-- ============================================================================

-- 1. Rahasianya tidak lagi berada di tabel yang bisa dibaca klien.
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'pengguna' and column_name = 'pin_hash'),
  0::bigint,
  'kolom pin_hash TIDAK ada lagi di public.pengguna (dipindah ke tabel rahasia)'
);
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'kredensial_pin' and column_name = 'pin_hash'),
  1::bigint,
  'kolom pin_hash ada di tabel kredensial_pin'
);
select uji.sama(has_table_privilege('authenticated', 'public.kredensial_pin', 'select'), false,
                'peran authenticated TIDAK punya hak baca kredensial_pin');
select uji.sama(has_table_privilege('anon', 'public.kredensial_pin', 'select'), false,
                'peran anon TIDAK punya hak baca kredensial_pin');

-- 2. Batas (CHECK) tetap menolak PIN mentah di tabel barunya.
select uji.harap_gagal(
  $$insert into public.kredensial_pin (pengguna_id, pin_hash)
      values ('90000000-0000-0000-0000-000000000004', '2468')$$,
  'PIN mentah tetap DITOLAK database walau sudah pindah tabel'
);

-- 3. Klien tetap tidak bisa membaca rahasianya walau memaksa lewat SQL.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal(
  $$select pin_hash from public.kredensial_pin$$,
  'kasir tidak bisa membaca kredensial_pin'
);
reset role;
select uji.klaim(null);

-- 4. Ganti PIN sendiri WAJIB PIN lama — dua-duanya: uuid diri sendiri maupun dikosongkan.
--    (Owner memasang PIN awal dulu supaya sasaran sudah punya PIN.)
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(public.simpan_pin('2468', null, '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'owner memasang PIN awal kasir');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal(
  $$select public.simpan_pin('8888', null)$$,
  'ganti PIN sendiri tanpa PIN lama DITOLAK (argumen uuid dikosongkan)'
);
select uji.harap_gagal(
  $$select public.simpan_pin('8888', null, '90000000-0000-0000-0000-000000000004')$$,
  'ganti PIN sendiri tanpa PIN lama DITOLAK (uuid diri sendiri disebutkan)'
);
select uji.harap_gagal(
  $$select public.simpan_pin('8888', '9999', '90000000-0000-0000-0000-000000000004')$$,
  'ganti PIN dengan PIN lama SALAH tetap DITOLAK'
);
select uji.sama(public.simpan_pin('8888', '2468', '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'ganti PIN sendiri BERHASIL bila PIN lama benar');
select uji.sama((public.verifikasi_pin('90000000-0000-0000-0000-000000000004', '8888', null, 'hp-uji')).berhasil,
                true, 'PIN baru benar-benar terpasang');
reset role;
select uji.klaim(null);
