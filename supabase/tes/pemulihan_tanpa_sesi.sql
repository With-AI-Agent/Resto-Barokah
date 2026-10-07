-- ============================================================================
-- UJI SQL: pemulihan perangkat darurat TANPA sesi aktif (PMB1-F-083 · K-2)
-- ============================================================================
-- Yang dijaga (migrasi 0102):
--   1. Owner yang kehilangan SELURUH perangkat (tidak bisa login, karena login
--      staf wajib perangkat terdaftar) tetap bisa memulihkan perangkat darurat
--      memakai kode pemulihan darurat — cukup kode, tanpa sesi. Sebelumnya
--      (0028) RPC menuntut auth.uid() owner_pusat sehingga alurnya deadlock.
--   2. Kode pemulihan tetap sekali pakai & salah kode tetap ditolak, kini juga
--      dari jalur tanpa sesi.
--   3. Perangkat hasil pemulihan darurat mendapat baris persetujuan pasangan
--      (owner menyetujui dirinya sendiri) sehingga aturan login PMB1-F-082
--      (0101) tidak mengunci perangkat yang baru dipulihkan.
--   4. Kontrol: jalur BERSESI tidak berubah — non-owner tetap ditolak
--      (dibuktikan juga di pemulihan.sql butir 5).
-- Jalankan: node alat/uji-sql.mjs supabase/tes/pemulihan_tanpa_sesi.sql
-- ============================================================================

-- Penyiapan: owner membuat kode pemulihan darurat (jalur ber-sesi sah, definisi lama).
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner_pusat)
select uji.sama(
  public.buat_kode_pemulihan('kunci-pemulihan-darurat-kehilangan-semua-hp-2026'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-083: owner membuat kode pemulihan darurat'
);
reset role;

-- Bersihkan sisa percobaan agar pembatas laju mulai dari nol.
delete from public.percobaan_masuk where sebab = 'pulihkan_darurat';

-- 1. TANPA SESI: owner kehilangan semua perangkat -> pulihkan dengan kode.
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kunci-pemulihan-darurat-kehilangan-semua-hp-2026',
    'hp-darurat-owner',
    'kunci-panjang-darurat-0123456789',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'F-083: pemulihan darurat tanpa sesi berhasil (deadlock pecah)'
);

-- 1b. Perangkat darurat terdaftar nonaktif dengan masa tenggang.
reset role;
select uji.harap(
  exists (
    select 1 from public.perangkat p
    join public.pemulihan_perangkat q on q.perangkat_id = p.id
     where p.nama = 'hp-darurat-owner'
       and p.aktif = false
       and q.status = 'menunggu'
  ),
  'F-083: perangkat darurat menunggu masa tenggang 30 menit (nonaktif)'
);

-- 1c. Kode pemulihan ditandai terpakai (sekali pakai juga di jalur tanpa sesi).
select uji.harap(
  not exists (
    select 1 from public.kredensial_pemulihan
     where penyewa_id = '11111111-1111-1111-1111-111111111111' and not terpakai
  ),
  'F-083: kode pemulihan terpakai dan tidak bisa dipakai lagi'
);

-- 1d. Persetujuan pasangan tercatat (kaitan PMB1-F-082/0101).
select uji.harap(
  exists (
    select 1 from public.persetujuan_perangkat pp
    join public.perangkat p on p.id = pp.perangkat_id
     where p.nama = 'hp-darurat-owner'
       and pp.pengguna_id = '90000000-0000-0000-0000-000000000002'
  ),
  'F-083: perangkat darurat yang dipulihkan langsung punya baris persetujuan'
);

-- 2. Kode yang sama dicoba lagi tanpa sesi -> DITOLAK (sekali pakai).
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-pemulihan-darurat-kehilangan-semua-hp-2026',
      'hp-darurat-kedua',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'tidak valid atau sudah pernah dipakai',
  'F-083: kode terpakai ditolak juga dari jalur tanpa sesi'
);

-- 3. Kode salah tanpa sesi -> DITOLAK. (Pembatas laju lapisan SQL sengaja
--    TIDAK diujikan: insert kegagalan tergulung bersama raise exception, jadi
--    tidak bisa bertahan murni di lapisan SQL — residu lapisan tepi, tercatat
--    jujur di header migrasi 0102 & kartu B-F-06.)
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-salah-pemulihan-darurat-xxxxxxxxxxxx',
      'hp-darurat-penyerang',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'tidak valid atau sudah pernah dipakai',
  'F-083: kode salah ditolak tanpa sesi'
);

-- 4. Kontrol jalur ber-sesi: non-owner tetap ditolak seperti definisi lama.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Pak Andi (admin_cabang)
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-apa-saja-tidak-penting-panjang-00000',
      'hp-darurat-andi',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Hanya owner_pusat',
  'F-083: jalur ber-sesi non-owner tetap ditolak (perilaku lama utuh)'
);
