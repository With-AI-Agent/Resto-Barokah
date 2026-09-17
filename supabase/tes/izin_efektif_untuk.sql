-- ============================================================================
-- UJI: SATU RUMUS IZIN UNTUK SIAPA PUN — `izin_efektif_untuk` (orang lain)
-- Menutup temuan review PR putaran8 PR-11: fungsi ini masih membaca kolom
-- `pengguna_cabang.peran` yang DIHAPUS migrasi 0011, sehingga panggilan dengan
-- cabang meledak (`column pc.peran does not exist`) dan klaim "satu rumus izin,
-- dua pintu" batal. Sekarang rumusnya sama dengan `izin_efektif`, hanya subjeknya
-- pegawai lain; ditambah penjaga akun nonaktif, anggota cabang, dan lintas resto.
-- ============================================================================

-- Dijalankan dari jalur peladen (fungsi internal memakai SECURITY DEFINER).
set local role service_role;

-- 1. Dua pintu memakai RUMUS YANG SAMA: izin pegawai lewat `izin_efektif_untuk`
--    = jawaban `boleh_untuk` untuk pegawai itu (yang membungkusnya), dan batasnya
--    sejalan dengan yang dicentang di layar izin.
select uji.sama(
  (select public.boleh_untuk('90000000-0000-0000-0000-000000000004', 'beri_diskon',
                             'a1a1a1a1-0000-0000-0000-000000000001')),
  true, 'pintu boleh_untuk menyatakan kasir berizin memberi diskon'
);
select uji.sama(
  (select public.boleh_untuk('90000000-0000-0000-0000-000000000004', 'ubah_harga')),
  false, 'pintu yang sama menyatakan kasir TIDAK berizin mengubah harga'
);

-- 2. Cabang yang disebut & dianggota → boleh; batas diskon ikut.
select uji.sama(
  (select i.batas_nominal from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000004',
                                                         'beri_diskon',
                                                         'a1a1a1a1-0000-0000-0000-000000000001') i),
  25000, 'batas diskon kasir terbaca lewat pintu orang-lain (dulu: error kolom dihapus)'
);

-- 3. Cabang yang TIDAK dianggota → tolak (bukan jatuh ke peran se-resto).
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000004',
                                                 'beri_diskon',
                                                 'a1a1a1a1-0000-0000-0000-000000000002') i),
  false, 'kasir Pusat tidak dianggap berizin di Cabang Dua'
);

-- 3b. Keanggotaan cabang yang DINONAKTIFKAN = tidak lagi berizin di cabang itu
--     (mis. pegawai dipindah/dicabut aksesnya). Dipakai kasir (yang memang berizin
--     memberi diskon) supaya yang menahan benar-benar pemeriksaan keanggotaan.
update public.pengguna_cabang set aktif = false
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001';
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000004',
                                                 'beri_diskon',
                                                 'a1a1a1a1-0000-0000-0000-000000000001') i),
  false, 'keanggotaan cabang yang nonaktif tidak memberi izin di cabang itu'
);
update public.pengguna_cabang set aktif = true
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001';

-- 4. Jalur PELADEN (tanpa identitas) memang boleh menilai pegawai mana pun — itu
--    yang dibutuhkan gerbang PIN/void. Yang menahan penyalahgunaan adalah HAK EXECUTE:
--    klien TIDAK bisa memanggil fungsi ini sama sekali (diuji di bagian 8 di bawah).
--    Pemanggil yang PUNYA identitas (klien lewat jalur lain) tetap dibatasi isolasi
--    lintas penyewa oleh penjaga di dalam fungsi (auth.uid() tidak null → hanya resto sendiri).
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000007',
                                                 'beri_diskon') i),
  true, 'jalur peladen boleh menilai pegawai resto lain (dipakai penjaga internal, bukan klien)'
);

-- 5. Akun NONAKTIF: izinnya hilang, walau centangnya masih ada (cabut seketika).
update public.pengguna set aktif = false where id = '90000000-0000-0000-0000-000000000006';
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000006',
                                                 'ubah_stok') i),
  false, 'pegawai nonaktif tidak punya izin lewat pintu orang-lain'
);
update public.pengguna set aktif = true where id = '90000000-0000-0000-0000-000000000006';

-- 6. Owner pusat: cabang boleh disebut walau ia tidak bertugas di kasir.
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000002',
                                                 'beri_diskon',
                                                 'a1a1a1a1-0000-0000-0000-000000000002') i),
  true, 'owner pusat dinilai sah untuk cabang mana pun di restonya'
);

-- 7. Izin yang tidak dikenal / tidak dicentang = TOLAK (bukan lolos).
select uji.sama(
  (select i.boleh from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000004',
                                                 'kelola_pegawai') i),
  false, 'izin yang tidak dimiliki ditolak'
);

-- 8. KLIEN tidak boleh memakai pintu ini untuk mengintip izin orang lain.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$select * from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000003', 'beri_diskon')$$,
  'klien tidak bisa memanggil pintu izin orang lain'
);
reset role;
select uji.klaim(null);
