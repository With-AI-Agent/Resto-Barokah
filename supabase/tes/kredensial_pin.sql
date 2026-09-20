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
select uji.harap_gagal_sebab($$insert into public.kredensial_pin (pengguna_id, pin_hash)
      values ('90000000-0000-0000-0000-000000000004', '2468')$$, 'violates check constraint "kredensial_pin_pin_hash_check"', 'PIN mentah tetap DITOLAK database walau sudah pindah tabel');

-- 3. Klien tetap tidak bisa membaca rahasianya walau memaksa lewat SQL.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal_sebab($$select pin_hash from public.kredensial_pin$$, 'permission denied for table kredensial_pin', 'kasir tidak bisa membaca kredensial_pin');
reset role;
select uji.klaim(null);

-- 4. Ganti PIN sendiri WAJIB PIN lama — dua-duanya: uuid diri sendiri maupun dikosongkan.
--    (Owner memasang PIN awal dulu supaya sasaran sudah punya PIN.)
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
select uji.sama(public.simpan_pin('516372', null, '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'owner memasang PIN awal kasir');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
-- TEMUAN AUDIT A-17/F-06 (2026-09-18): dua asersi pertama dulu lulus karena pemeriksaan
-- BENTUK ("PIN lama salah. PIN harus tepat 6 angka.") — sebab yang diakuinya memang
-- "tanpa PIN lama", jadi sekarang sebabnya disebut apa adanya. Asersi ketiga memakai
-- PIN 6 angka yang SALAH, sehingga yang menolak benar-benar pemeriksaan autentikasi.
-- Sejak F-14 (2026-09-20) penolakan jalur PIN-lama dikembalikan sebagai PESAN
-- (bukan exception) supaya catatan percobaan bertahan dan pembatas menyala.
select uji.sama(
  public.simpan_pin('917426', null) like 'PIN lama salah%tepat 6 angka%', true,
  'ganti PIN sendiri tanpa PIN lama DITOLAK karena bentuk PIN lama kosong'
);
select uji.sama(
  public.simpan_pin('917426', null, '90000000-0000-0000-0000-000000000004') like 'PIN lama salah%tepat 6 angka%', true,
  'ganti PIN sendiri tanpa PIN lama DITOLAK karena bentuk PIN lama kosong (uuid diri sendiri disebutkan)'
);
select uji.sama(
  public.simpan_pin('917426', '135791', '90000000-0000-0000-0000-000000000004')
    like 'PIN lama salah%PIN salah%', true,
  'ganti PIN dengan PIN lama 6 angka yang SALAH ditolak oleh pemeriksaan AUTENTIKASI (pesan, F-14)'
);
select uji.sama(public.simpan_pin('917426', '516372', '90000000-0000-0000-0000-000000000004'),
                'PIN tersimpan.', 'ganti PIN sendiri BERHASIL bila PIN lama benar');
select uji.sama((public.verifikasi_pin('90000000-0000-0000-0000-000000000004', '917426', null, 'hp-uji')).berhasil,
                true, 'PIN baru benar-benar terpasang');
reset role;
select uji.klaim(null);

-- ============================================================================
-- 5. ATURAN PIN BARU (T1-23 · ART-12): 6 angka, bukan pola lemah, dan UNIK
--    antar pegawai satu resto. (Format 4 angka yang dulu diizinkan sudah
--    ditutup: PIN 4 angka hanya 10.000 kemungkinan — dengan batas 5/15 menit
--    pun masih bisa ditebak dalam hitungan hari.)
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;

-- 5a. Wajib 6 angka.
select uji.harap_gagal_sebab($$select public.simpan_pin('2468', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN 4 angka DITOLAK (dulu diizinkan)');
select uji.harap_gagal_sebab($$select public.simpan_pin('2468135', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN 7 angka ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('24681x', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: harus tepat 6 angka', 'PIN bukan angka ditolak');
-- Jalur VERIFIKASI juga menolak bentuk yang bukan 6 angka (dijawab sebagai pesan,
-- bukan "PIN salah", supaya tidak ikut menghabiskan jatah tebak).
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000003', '1234', null, 'hp-uji')).pesan,
  'PIN harus tepat 6 angka.',
  'verifikasi menolak PIN yang bukan 6 angka dengan pesan yang jelas');
select uji.sama(
  (select count(*) from public.percobaan_pin where pengguna_id = '90000000-0000-0000-0000-000000000003'),
  0::bigint,
  'bentuk PIN yang salah tidak dihitung sebagai percobaan menebak');

-- 5b. Pola lemah ditolak: semua digit sama · urutan · blok berulang · tanggal.
select uji.harap_gagal_sebab($$select public.simpan_pin('111111', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: semua angkanya sama', 'PIN semua digit sama ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('123456', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: berisi deret angka berurutan', 'PIN berurutan naik ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('654321', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: berisi deret angka berurutan', 'PIN berurutan turun ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('121212', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: pola berulang', 'PIN blok berulang ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('010190', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: berbentuk tanggal', 'PIN berbentuk tanggal (ddmmyy) ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('456789', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: berisi deret angka berurutan', 'PIN deret panjang (456789) ditolak');
select uji.harap_gagal_sebab($$select public.simpan_pin('112233', null, '90000000-0000-0000-0000-000000000003')$$, 'PIN ditolak: pasangan angka berurutan', 'PIN pasangan berurutan (112233) ditolak');
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000003'),
                'PIN tersimpan.', 'PIN 6 angka yang kuat DITERIMA');

-- 5c. PIN wajib unik antar pegawai satu resto.
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000006'),
                'PIN itu tidak bisa dipakai — pilih angka lain.',
                'PIN yang sudah dipakai pegawai lain di resto yang sama DITOLAK (via pesan, supaya tercatat; pesannya netral sejak PR-04 2026-09-19)');
select uji.sama(public.simpan_pin('692735', null, '90000000-0000-0000-0000-000000000006'),
                'PIN tersimpan.', 'PIN lain yang belum dipakai tetap diterima');
reset role;
select uji.klaim(null);

-- 5d. Keunikan berlaku per resto: resto lain boleh memakai angka yang sama
--     (kalau tidak, angka PIN pegawai satu resto bisa dibaca dari resto lain).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto LAIN (memasang PIN-nya sendiri)
set local role authenticated;
select uji.sama(public.simpan_pin('274918'),
                'PIN tersimpan.', 'pegawai resto LAIN boleh memakai angka PIN yang sama');
reset role;
select uji.klaim(null);

-- 5e. Ganti PIN sendiri ke angka yang sama tetap boleh (keunikan mengecualikan diri sendiri).
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin, PIN 334455
set local role authenticated;
select uji.sama(public.simpan_pin('274918', '274918'),
                'PIN tersimpan.', 'memasang ulang PIN sendiri dengan angka yang sama tidak dianggap kembar');
reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- F-14 (2026-09-20): tebakan PIN lama lewat simpan_pin WAJIB terhitung
-- ----------------------------------------------------------------------------
-- Dulu raise 'PIN lama salah' menggulung balik catatan percobaan → pembatas
-- 5-gagal tidak pernah menyala untuk jalur ini. Kini kegagalan dikembalikan
-- sebagai pesan, catatan bertahan, dan penguncian tercapai.
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan (pasang PIN dulu)
set local role authenticated;
select uji.sama(public.simpan_pin('618273'), 'PIN tersimpan.', 'F-14 prasyarat: pelayan punya PIN');
select public.simpan_pin('981237', '246810');
select public.simpan_pin('981237', '135791');
select public.simpan_pin('981237', '975311');
select public.simpan_pin('981237', '864209');
select public.simpan_pin('981237', '753951');
select uji.sama(
  (select count(*) from public.percobaan_pin pp
    where pp.pemanggil_id = '90000000-0000-0000-0000-000000000005' and not pp.berhasil) >= 5,
  true, 'F-14: lima tebakan PIN lama tercatat (tidak tergulung balik)');
select uji.sama(
  public.simpan_pin('981237', '642861') like '%terkunci%',
  true, 'F-14: tebakan keenam menjawab terkunci — pembatas menyala');
reset role;
select uji.klaim(null);
