-- ============================================================================
-- UJI: Tangga Pemulihan Perangkat Darurat & Kunci Induk (T1-36)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. Hanya owner_pusat yang berhak membuat kode pemulihan darurat.
--   2. Kode pemulihan pendek (< 20 karakter) ditolak.
--   3. Non-owner (kasir / admin cabang) tidak bisa membuat atau memulihkan perangkat.
--   4. Pengajuan pemulihan dengan kode yang benar berhasil membuat perangkat
--      dengan masa tenggang 30 menit (perangkat belum aktif).
--   5. Kode pemulihan yang sudah dipakai tidak bisa dipakai kedua kalinya (sekali pakai).
--   6. Kode pemulihan salah ditolak.
--   7. Selesaikan pemulihan sebelum 30 menit ditolak (masa tenggang aktif).
--   8. Pembatalan pemulihan darurat berhasil dan mengunci perangkat tetap nonaktif.
--   9. Setelah 30 menit berlalu, pemulihan dapat diselesaikan dan perangkat menjadi aktif.
--  10. Kredensial pemulihan (kode_hash) tidak bisa diakses klien biasa (RLS).
-- ============================================================================

-- 1. Kasir (Rina) mencoba membuat kode pemulihan darurat -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.buat_kode_pemulihan('kunci-pemulihan-darurat-rahasia-super-panjang-01')$$,
  'Hanya owner_pusat',
  'kasir tidak berhak membuat kode pemulihan darurat'
);

-- 2. Kode pemulihan pendek (< 20 karakter) -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner_pusat)
select uji.harap_gagal_sebab(
  $$select public.buat_kode_pemulihan('pendek')$$,
  'minimal 20 karakter',
  'kode pemulihan darurat wajib panjang'
);

-- 3. Owner membuat kode pemulihan darurat yang valid
select uji.sama(
  public.buat_kode_pemulihan('kunci-pemulihan-darurat-rahasia-super-panjang-01'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'owner_pusat berhasil membuat kode pemulihan darurat'
);
reset role;

-- 4. Kredensial pemulihan tersimpan sebagai bcrypt hash (bukan teks biasa)
select uji.klaim(null);
select uji.harap(
  (select kp.kode_hash ~ '^\$[a-z0-9]+\$' and kp.kode_hash <> 'kunci-pemulihan-darurat-rahasia-super-panjang-01'
     from public.kredensial_pemulihan kp
    where kp.penyewa_id = '11111111-1111-1111-1111-111111111111'
      and not kp.terpakai),
  'kode pemulihan darurat disimpan sebagai bcrypt hash'
);

-- 5. Non-owner (Pak Andi admin_cabang) mencoba memulihkan perangkat -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-pemulihan-darurat-rahasia-super-panjang-01',
      'hp-darurat-andi',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Hanya owner_pusat',
  'hanya owner yang boleh mengajukan pemulihan perangkat darurat'
);

-- 6. Owner mengajukan kode salah -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-pemulihan-salah-total-0123456789012345',
      'hp-darurat-oasis',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Kode pemulihan darurat tidak valid',
  'kode pemulihan salah ditolak'
);

-- 7. Owner mengajukan pemulihan dengan kode yang benar -> BERHASIL diajukan (status menunggu, perangkat nonaktif)
select uji.harap(
  (select public.pulihkan_perangkat(
      'kunci-pemulihan-darurat-rahasia-super-panjang-01',
      'hp-darurat-oasis-1',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )) is not null,
  'owner berhasil mengajukan permohonan pemulihan perangkat'
);

-- 8. Kode yang sama dicoba lagi kedua kali -> DITOLAK (sekali pakai)
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kunci-pemulihan-darurat-rahasia-super-panjang-01',
      'hp-darurat-oasis-2',
      'kunci-panjang-darurat-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001'
    )$$,
  'Kode pemulihan darurat tidak valid atau sudah pernah dipakai',
  'kode pemulihan tidak bisa dipakai ulang (sekali pakai)'
);

-- 9. Perangkat baru belum aktif selama masa tenggang
reset role;
select uji.klaim(null);
select uji.sama(
  (select pr.aktif from public.perangkat pr where pr.nama = 'hp-darurat-oasis-1'),
  false,
  'perangkat darurat nonaktif selama masa tenggang 30 menit'
);

-- 10. Selesaikan pemulihan sebelum 30 menit -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan(
      (select pp.id from public.pemulihan_perangkat pp
        join public.perangkat pr on pr.id = pp.perangkat_id
       where pr.nama = 'hp-darurat-oasis-1')
    )$$,
  'Masa tenggang 30 menit belum berakhir',
  'tidak bisa diselesaikan sebelum 30 menit'
);

-- 11. Pembatalan pemulihan oleh owner -> status dibatalkan
select uji.harap(
  public.batalkan_pemulihan(
    (select pp.id from public.pemulihan_perangkat pp
      join public.perangkat pr on pr.id = pp.perangkat_id
     where pr.nama = 'hp-darurat-oasis-1'),
    'Perangkat lama ditemukan kembali.'
  ),
  'pembatalan permohonan pemulihan berhasil'
);

reset role;
select uji.klaim(null);
select uji.sama(
  (select pp.status from public.pemulihan_perangkat pp
     join public.perangkat pr on pr.id = pp.perangkat_id
    where pr.nama = 'hp-darurat-oasis-1'),
  'dibatalkan',
  'status pemulihan tercatat dibatalkan'
);

-- 12. Alur pemulihan lengkap yang berhasil (setelah 30 menit)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.buat_kode_pemulihan('kunci-pemulihan-darurat-rahasia-super-panjang-02');
select public.pulihkan_perangkat(
  'kunci-pemulihan-darurat-rahasia-super-panjang-02',
  'hp-darurat-oasis-sah',
  'kunci-panjang-darurat-0123456789',
  'a1a1a1a1-0000-0000-0000-000000000001'
);
reset role;

-- Majukan waktu aktif_setelah (simulasi 30 menit telah berlalu)
select uji.klaim(null);
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 minute'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-darurat-oasis-sah');

-- Selesaikan pemulihan
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  public.selesaikan_pemulihan(
    (select pp.id from public.pemulihan_perangkat pp
      join public.perangkat pr on pr.id = pp.perangkat_id
     where pr.nama = 'hp-darurat-oasis-sah')
  ),
  'pemulihan berhasil diselesaikan setelah 30 menit'
);

-- Perangkat kini aktif dan dapat dipakai
select uji.sama(
  (select pr.aktif from public.perangkat pr where pr.nama = 'hp-darurat-oasis-sah'),
  true,
  'perangkat darurat menjadi aktif setelah pemulihan diselesaikan'
);

-- 13. Klien tidak bisa membaca kredensial_pemulihan (RLS)
select uji.harap_gagal_sebab(
  $$select count(*) from public.kredensial_pemulihan$$,
  'permission denied for table kredensial_pemulihan',
  'kredensial pemulihan tidak dapat dibaca klien'
);

reset role;
select uji.klaim(null);
