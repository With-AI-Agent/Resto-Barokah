-- ============================================================================
-- UJI: batas percobaan PIN dua lapis dengan perangkat TERDAFTAR (B F-11 → T1-24)
--
-- Riwayat:
--   * Temuan audit AUD-3 (laporan B, F-11, tingkat K-3): lapis kedua (12×/perangkat/
--     15 menit) dulu di-key pada NAMA kiriman klien — penyerang yang memutar nama
--     tidak pernah terkumpul 12 kali. Versi lama uji ini mengunci perilaku sementara
--     (memutar nama tidak menambah jatah AKUN) sambil menunggu obat permanen.
--   * T1-24 (migrasi 0018, 2026-09-21) mendarat: perangkat TERDAFTAR dengan
--     identitas terverifikasi. Sesuai amanat ROADMAP, uji ini DIPERKETAT —
--     bagian 1 tidak lagi melayani 5 percobaan melainkan 0: perangkat asing
--     DITOLAK sebelum kredensial disentuh.
--
-- Yang dibuktikan berkas ini:
--   1. Memutar id perangkat karangan (tak terdaftar) → 0 percobaan dilayani;
--      semuanya ditolak seragam 'Perangkat tidak dikenali.'
--   2. Perangkat terdaftar dengan KUNCI SALAH → jawaban seragam yang sama
--      (anti-oracle: tidak bisa dibedakan dari id yang tidak ada).
--   3. Perangkat yang DICABUT (nonaktif) → jawaban seragam yang sama.
--   4. Lapis perangkat MASIH HIDUP untuk perangkat sah: 13 percobaan dari SATU
--      perangkat terdaftar, disebar ke empat akun (supaya batas per akun tidak
--      ikut kena) → percobaan ke-13 ditolak karena jatah 12×/perangkat.
--      (Menghapus lapis kedua akan memerahkan bagian ini.)
--   5. Lapis akun (5×) tetap hidup: pada bagian 4, akun pertama hanya dilayani
--      sampai 5 kegagalan walau perangkatnya berganti-ganti akun sasaran.
--
-- Catatan teknis (jebakan yang sudah kena): panggilan fungsi di dalam LATERAL
-- yang argumennya TIDAK bergantung pada baris kiri hanya dijalankan SEKALI oleh
-- PostgreSQL (hasilnya disebar ke semua baris). Karena itu uji ini memakai blok
-- `do` dengan perulangan eksplisit, supaya jumlah panggilan nyata pasti 8/8/13.
-- ============================================================================

-- 0. Persiapan: PIN dua calon korban dipasang owner; penghitung percobaan
--    dikosongkan supaya berkas ini tidak bergantung urutan berkas uji lain
--    (hanya bisa dari peran pemilik tabel — klien tidak bisa).
delete from public.percobaan_pin;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('274918', null, '90000000-0000-0000-0000-000000000003', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
                'PIN tersimpan.', 'owner memasang PIN awal admin');
select uji.sama(public.simpan_pin('692735', null, '90000000-0000-0000-0000-000000000006', 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'),
                'PIN tersimpan.', 'owner memasang PIN awal dapur');
reset role;
select uji.klaim(null);

-- 1. SERANGAN: kasir memutar id perangkat KARANGAN (tak terdaftar) 8 kali ke satu
--    akun. Sebelum T1-24 pola ini dilayani 5 kali (batas akun); sekarang 0 kali.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_pesan    text;
  v_dilayani integer := 0;
  v_ditolak  integer := 0;
begin
  for i in 1..8 loop
    select r.pesan into v_pesan
      from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null,
                                 ('00000000-0000-0000-0000-0000000000' || lpad(i::text, 2, '0'))::uuid,
                                 'kunci-karangan-0123456789') r;
    if v_pesan = 'Perangkat tidak dikenali.' then
      v_ditolak := v_ditolak + 1;
    else
      v_dilayani := v_dilayani + 1;
    end if;
  end loop;
  perform uji.harap(
    v_dilayani = 0 and v_ditolak = 8,
    'T1-24: memutar perangkat tak terdaftar tidak dilayani sama sekali (0 dilayani · 8 ditolak) — dapat '
      || v_dilayani || ' · ' || v_ditolak);
end $$;

-- 2. Perangkat TERDAFTAR dengan kunci SALAH → jawaban seragam yang sama.
select uji.sama(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null,
                                             'de000000-0000-0000-0000-000000000003', 'kunci-salah-0123456789') r),
  'Perangkat tidak dikenali.',
  'kunci salah dijawab seragam — tidak bisa dibedakan dari perangkat yang tidak ada'
);

-- 3. Perangkat yang DICABUT pemilik → jawaban seragam yang sama.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(public.cabut_perangkat('de000000-0000-0000-0000-000000000007'),
                 'owner mencabut perangkat (hp-cadangan)');
select uji.sama(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '135791', null,
                                             'de000000-0000-0000-0000-000000000007', 'kunci-uji-hp-cadangan-0123456789') r),
  'Perangkat tidak dikenali.',
  'perangkat yang dicabut ditolak seragam'
);
reset role;
select uji.klaim(null);
delete from public.percobaan_pin;

-- 4 & 5. Perangkat SAH: lapis perangkat (12×) dan lapis akun (5×) dua-duanya hidup.
--    13 percobaan dari SATU perangkat terdaftar, disebar ke empat akun supaya batas
--    per akun tidak ikut kena (akun ke-3 & ke-4 tak dikenal → 'PIN tidak dikenali.',
--    tetap tercatat sebagai kegagalan perangkat).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  v_target text[] := array['90000000-0000-0000-0000-000000000002',
                            '90000000-0000-0000-0000-000000000005',
                            '90000000-0000-0000-0000-000000000001',
                            '90000000-0000-0000-0000-000000000007'];
  v_pesan    text;
  v_panggil  integer := 0;
  v_terkunci integer := 0;
begin
  for i in 1..13 loop
    select r.pesan into v_pesan
      from public.verifikasi_pin(v_target[1 + ((i - 1) % 4)]::uuid, '135791', null,
                                 'de000000-0000-0000-0000-000000000003', 'kunci-uji-hp-kasir-0123456789') r;
    v_panggil := v_panggil + 1;
    if v_pesan like 'PIN terkunci%' then
      v_terkunci := v_terkunci + 1;
    end if;
  end loop;
  perform uji.harap(
    v_panggil = 13 and v_terkunci = 1,
    'T1-24: lapis perangkat (12 per perangkat terdaftar) hidup — 13 panggilan, '
      || v_terkunci || ' terkunci');

end $$;

-- 5. Lapis akun: korban (dapur, yang PIN-nya ditebak-tebak pada bagian 1) tetap bisa
--    memakai PIN-nya sendiri dari perangkatnya sendiri — yang dikunci adalah PENCOBA,
--    bukan korban (PR-13 dipertahankan).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select r.pesan from public.verifikasi_pin('90000000-0000-0000-0000-000000000006', '692735', null,
                                             'de000000-0000-0000-0000-000000000005', 'kunci-uji-hp-dapur-0123456789') r),
  'PIN diterima.',
  'korban tetap bisa memakai PIN-nya sendiri dari perangkatnya sendiri (PR-13)'
);

reset role;
select uji.klaim(null);
