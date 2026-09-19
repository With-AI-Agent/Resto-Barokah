-- ============================================================================
-- UJI: peran tunggal — satu akun satu peran (T1-23 · ART-12 · AUD-0 B.1–B.3)
--
-- Kebijakan baru 2026-09-17 (docs/KEAMANAN.md §3): satu akun = SATU peran yang
-- berlaku di semua cabangnya; orang dengan dua fungsi memakai dua akun.
-- Kolom `pengguna_cabang.peran` (peran berbeda per cabang) dibongkar lewat
-- migrasi 0011, dan mesin izin `izin_efektif()` membaca `pengguna.peran`.
--
-- Uji ini MENGGANTIKAN uji lama `izin.sql` §8 yang justru menguji perilaku yang
-- kini dilarang ("pegawai merangkap dapat peran berbeda per cabang").
-- ============================================================================

-- 1. Peran per cabang benar-benar hilang dari skema (bukan hanya diabaikan).
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'pengguna_cabang' and column_name = 'peran'),
  0::bigint,
  'pengguna_cabang tidak lagi punya kolom peran (peran kedua per akun mustahil disimpan)'
);
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public' and table_name = 'pengguna' and column_name = 'peran'),
  1::bigint,
  'peran tunggal hidup di pengguna.peran'
);
select uji.harap_gagal(
  $$insert into public.pengguna_cabang (pengguna_id, cabang_id, peran)
      values ('90000000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000002', 'dapur')$$,
  'percobaan menuliskan peran kedua per akun DITOLAK'
);

-- 2. Penjaga keanggotaan: akun & cabang wajib satu resto; pemilik platform tidak bertugas di cabang.
select uji.harap_gagal(
  $$insert into public.pengguna_cabang (pengguna_id, cabang_id)
      values ('90000000-0000-0000-0000-000000000004', 'b1b1b1b1-0000-0000-0000-000000000001')$$,
  'pegawai tidak boleh didaftarkan ke cabang resto lain'
);
select uji.harap_gagal(
  $$insert into public.pengguna_cabang (pengguna_id, cabang_id)
      values ('90000000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'pemilik platform tidak boleh didaftarkan ke cabang mana pun'
);
insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('90000000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000002');
select uji.sama(
  (select count(*) from public.pengguna_cabang where pengguna_id = '90000000-0000-0000-0000-000000000004'),
  2::bigint,
  'pegawai tetap boleh merangkap DUA CABANG (yang tidak boleh: dua peran)'
);

-- 3. Mesin izin memakai peran AKUN, sama di semua cabang yang dia anggotai.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Rina
set local role authenticated;
select uji.sama(
  public.boleh('tutup_kas', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid),
  true,
  'kasir boleh menutup kas di cabang pertamanya'
);
select uji.sama(
  public.boleh('tutup_kas', 'a1a1a1a1-0000-0000-0000-000000000002'::uuid),
  true,
  'peran yang SAMA berlaku di cabang keduanya (bukan peran berbeda per cabang)'
);
select uji.sama(
  public.boleh('ubah_stok', 'a1a1a1a1-0000-0000-0000-000000000002'::uuid),
  false,
  'kasir tetap tidak boleh mengubah stok di cabang mana pun'
);
select uji.sama(
  public.boleh('tutup_kas', 'b1b1b1b1-0000-0000-0000-000000000001'::uuid),
  false,
  'cabang resto lain tetap DITOLAK, bukan jatuh ke peran se-resto'
);
reset role;
select uji.klaim(null);

-- 4. Mengubah peran akun langsung mengubah wewenang di semua cabangnya.
update public.pengguna set peran = 'dapur' where id = '90000000-0000-0000-0000-000000000005';
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- Dedi, tadinya pelayan
set local role authenticated;
select uji.sama(public.boleh('ubah_stok'), true, 'setelah peran akun diubah ke dapur, wewenang ikut berubah');
select uji.sama(public.boleh('pakai_voucher'), false, 'wewenang pelayan hilang karena peran akun sudah berganti');
reset role;
select uji.klaim(null);
update public.pengguna set peran = 'pelayan' where id = '90000000-0000-0000-0000-000000000005';
