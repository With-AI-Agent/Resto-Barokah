-- ============================================================================
-- UJI: BAWAHAN TIDAK BOLEH MEREBUT PIN ATASAN
-- Menutup temuan review putaran13 #2 PR-01 (K-2): admin cabang bisa mengganti PIN
-- owner tanpa PIN lama, lalu memakai PIN hasil rebutan untuk menerbitkan kupon
-- persetujuan void atas nama owner. Bukti sebelum perbaikan: admin
-- simpan_pin(target=owner) → 'PIN tersimpan.'; verifikasi_pin(owner, 849273,
-- void_sesudah_dapur) → berhasil = true.
-- ============================================================================

-- Owner memasang PIN-nya sendiri lebih dulu.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'owner memasang PIN sendiri');
reset role;
select uji.klaim(null);

-- 1. ADMIN tidak boleh mengganti PIN OWNER (peran lebih rendah).
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(
  public.simpan_pin('849273', null, '90000000-0000-0000-0000-000000000002', 'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789')
    like 'Peran Anda tidak lebih tinggi%', true,
  'admin cabang TIDAK boleh mengganti PIN owner (pesan penolakan; sejak F-14 catatan bertahan)'
);

-- 2. PIN owner tetap yang lama: PIN "hasil rebutan" tidak berlaku.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '849273', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789', 'eeee0000-0000-0000-0000-000000000010')).berhasil,
  false, 'PIN yang dipasang paksa (849273) TIDAK berlaku untuk owner'
);
-- (Urutan penting: uji penolakan DIJALANKAN SEBELUM kontrol yang menerbitkan kupon sah,
--  supaya perintahnya benar-benar ditolak karena tidak ada bukti — bukan karena sebab lain.)
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'void tanpa izin owner')$$, 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri u', 'kupon void atas nama owner TIDAK terbit kalau owner sendiri yang tidak memasukkan PIN-nya');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789', 'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true, 'kontrol: PIN owner yang asli (738294) masih berlaku'
);

-- 3. Atasan BOLEH mengganti PIN bawahannya (jalur sah tidak ditutup).
select uji.sama(
  public.simpan_pin('193847', null, '90000000-0000-0000-0000-000000000004', 'de000000-0000-0000-0000-000000000002', 'kunci-uji-hp-admin-0123456789'),
  'PIN tersimpan.', 'admin BOLEH mengganti PIN kasir di cabangnya (peran lebih tinggi)'
);
reset role;
select uji.klaim(null);

-- 4. KORBAN bisa melihat catatan bahwa PIN-nya disentuh orang lain.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (target)
set local role authenticated;
select uji.harap(
  (select count(*) from public.percobaan_simpan_pin ps where ps.target_id = '90000000-0000-0000-0000-000000000004') >= 1,
  'pegawai bisa melihat catatan pemasangan PIN atas dirinya sendiri (dulu tabel ini gelap total)'
);
reset role;
select uji.klaim(null);

-- 5. Pegawai LAIN tidak boleh membaca catatan itu.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama(
  (select count(*) from public.percobaan_simpan_pin ps where ps.target_id = '90000000-0000-0000-0000-000000000004'),
  0::bigint, 'pegawai resto lain tidak melihat catatan PIN pegawai ini'
);
reset role;
select uji.klaim(null);
