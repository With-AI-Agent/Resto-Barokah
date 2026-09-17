-- ============================================================================
-- UJI: CABANG AKTIF — satu sumber (tabel), bukan klaim klien
-- Menutup dua temuan review PR putaran8:
--   * PR-12 : penjaga "akun nonaktif kehilangan cabang" di `cabang_saya()` tidak
--             punya uji — mutasi yang menghapus `p.aktif` membuat SEMUA gerbang
--             tetap hijau (kelas cacat yang sudah pernah nyata di T1-03).
--   * PR-15 : `cabang_saya()` sebelumnya butuh klaim JWT `cabang_id` yang tidak
--             pernah diterbitkan di repo ini — di Supabase nyata hasilnya selalu
--             null; sekarang sumbernya tabel, diisi lewat RPC yang memverifikasi
--             keanggotaan, dan TABELNYA tidak bisa ditulis klien.
-- ============================================================================

-- 1. Sebelum memilih: tidak ada cabang aktif.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan (2 cabang)
set local role authenticated;
select uji.sama(public.cabang_saya(), null::uuid, 'belum memilih cabang = tidak ada cabang aktif');

-- 2. Klien TIDAK bisa menulis tabel sesi_cabang langsung (harus lewat RPC).
select uji.harap_gagal(
  $$insert into public.sesi_cabang (pengguna_id, cabang_id)
      values ('90000000-0000-0000-0000-000000000005', 'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'klien tidak bisa menulis pilihan cabang langsung ke tabel'
);

-- 3. Jalur sah: RPC memverifikasi keanggotaan.
select uji.sama(
  public.pilih_cabang('a1a1a1a1-0000-0000-0000-000000000002'),
  'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
  'pilih_cabang menerima cabang yang benar-benar ia tempati'
);
select uji.sama(
  public.cabang_saya(), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
  'cabang_saya mengikuti pilihan itu'
);

-- 4. Cabang yang bukan tempatnya (resto lain / cabang bukan anggota) DITOLAK.
select uji.harap_gagal(
  $$select public.pilih_cabang('b1b1b1b1-0000-0000-0000-000000000001')$$,
  'memilih cabang resto lain ditolak'
);
select uji.sama(
  public.cabang_saya(), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
  'pilihan lama tidak berubah setelah percobaan curang'
);

-- 5. MEMBALIK PILIHAN ke cabang pertama tetap boleh (pindah shift).
select uji.sama(
  public.pilih_cabang('a1a1a1a1-0000-0000-0000-000000000001'),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'pindah ke cabang lain yang juga ia tempati'
);
reset role;

-- 6. INTI PENJAGA (temuan PR-12): akun NONAKTIF kehilangan cabangnya seketika,
--    walau barisnya masih ada dan sebelumnya sudah memilih cabang.
update public.pengguna set aktif = false where id = '90000000-0000-0000-0000-000000000005';
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.cabang_saya(), null::uuid,
                'akun nonaktif TIDAK punya cabang aktif walau sempat memilih (penjaga p.aktif)');
reset role;
update public.pengguna set aktif = true where id = '90000000-0000-0000-0000-000000000005';

-- 7. Keanggotaan yang dicabut (baris pengguna_cabang.aktif = false) juga mencabut cabang.
update public.pengguna_cabang set aktif = false
 where pengguna_id = '90000000-0000-0000-0000-000000000005'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001';
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.cabang_saya(), null::uuid,
                'keanggotaan cabang yang dinonaktifkan mencabut cabang aktif');
reset role;
update public.pengguna_cabang set aktif = true
 where pengguna_id = '90000000-0000-0000-0000-000000000005'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001';

select uji.klaim(null);
