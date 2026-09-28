-- ============================================================================
-- UJI MATRIKS IZIN 6 PERAN × SEMUA AKSI & RPC (T1-29, ART-2, ART-15)
-- ============================================================================
-- 6 Peran:
--   1. pemilik_platform (90000000-0000-0000-0000-000000000001)
--   2. owner_pusat      (90000000-0000-0000-0000-000000000002)
--   3. admin_cabang     (90000000-0000-0000-0000-000000000003)
--   4. kasir            (90000000-0000-0000-0000-000000000004)
--   5. pelayan          (90000000-0000-0000-0000-000000000005)
--   6. dapur            (90000000-0000-0000-0000-000000000006)
--
-- Membuktikan matriks izin positif & penolakan negatif secara fail-closed.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PEMILIK PLATFORM: Akses resto ditolak kecuali via mode dukungan (hanya-baca)
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), false, 'pemilik_platform tidak punya izin atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), false, 'pemilik_platform tidak punya izin kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), false, 'pemilik_platform tidak punya izin lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), false, 'pemilik_platform tidak punya izin ubah_harga');
select uji.sama(public.boleh('ubah_stok'), false, 'pemilik_platform tidak punya izin ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), false, 'pemilik_platform tidak punya izin void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), false, 'pemilik_platform tidak punya izin void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), false, 'pemilik_platform tidak punya izin beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), false, 'pemilik_platform tidak punya izin pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), false, 'pemilik_platform tidak punya izin tutup_kas');

-- Hak khusus: hanya pemilik_platform yang boleh memanggil masuk_mode_dukungan
select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Investigasi matriks izin platform 6 peran', 30)->>'berhasil')::boolean),
  true,
  'pemilik_platform berhak masuk mode dukungan'
);
select uji.sama(
  (select (public.keluar_mode_dukungan('11111111-1111-1111-1111-111111111111')->>'berhasil')::boolean),
  true,
  'pemilik_platform berhak keluar mode dukungan'
);

-- ============================================================================
-- 2. OWNER PUSAT: Memiliki kewenangan tertinggi di restonya
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), true, 'owner_pusat boleh atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), true, 'owner_pusat boleh kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), true, 'owner_pusat boleh lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), true, 'owner_pusat boleh ubah_harga');
select uji.sama(public.boleh('ubah_stok'), true, 'owner_pusat boleh ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), true, 'owner_pusat boleh void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), true, 'owner_pusat boleh void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), true, 'owner_pusat boleh beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), true, 'owner_pusat boleh pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), true, 'owner_pusat boleh tutup_kas');

-- Dilarang masuk mode dukungan (hanya untuk pemilik platform)
select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Coba akses dukungan platform')->>'berhasil')::boolean),
  false,
  'owner_pusat ditolak masuk mode dukungan'
);

-- ============================================================================
-- 3. ADMIN CABANG: Operasional manajerial cabang (tanpa atur_pengaturan resto)
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), false, 'admin_cabang TIDAK boleh atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), true, 'admin_cabang boleh kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), true, 'admin_cabang boleh lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), true, 'admin_cabang boleh ubah_harga bawaan');
select uji.sama(public.boleh('ubah_stok'), true, 'admin_cabang boleh ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), true, 'admin_cabang boleh void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), true, 'admin_cabang boleh void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), true, 'admin_cabang boleh beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), true, 'admin_cabang boleh pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), true, 'admin_cabang boleh tutup_kas');

-- Batas diskon admin_cabang bawaan (50.000 / 10%)
select uji.sama(public.boleh('beri_diskon', 50000, 10), true, 'diskon admin_cabang 50rb 10% diizinkan');
select uji.sama(public.boleh('beri_diskon', 50001, 10), false, 'diskon admin_cabang >50rb ditolak');

-- ============================================================================
-- 4. KASIR: Operasional kasir, diskon kecil & pembatalan awal
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), false, 'kasir TIDAK boleh atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), false, 'kasir TIDAK boleh kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), false, 'kasir TIDAK boleh lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), false, 'kasir TIDAK boleh ubah_harga');
select uji.sama(public.boleh('ubah_stok'), false, 'kasir TIDAK boleh ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), true, 'kasir boleh void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), false, 'kasir TIDAK boleh void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), true, 'kasir boleh beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), true, 'kasir boleh pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), true, 'kasir boleh tutup_kas');

-- Batas diskon kasir bawaan (25.000 / 5%)
select uji.sama(public.boleh('beri_diskon', 25000, 5), true, 'diskon kasir 25rb 5% diizinkan');
select uji.sama(public.boleh('beri_diskon', 25001, 5), false, 'diskon kasir >25rb ditolak');
select uji.sama(public.boleh('beri_diskon', 20000, 6), false, 'diskon kasir >5% ditolak');

-- ============================================================================
-- 5. PELAYAN: Pesanan meja, voucher (tanpa diskon manual & void)
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), false, 'pelayan TIDAK boleh atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), false, 'pelayan TIDAK boleh kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), false, 'pelayan TIDAK boleh lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), false, 'pelayan TIDAK boleh ubah_harga');
select uji.sama(public.boleh('ubah_stok'), false, 'pelayan TIDAK boleh ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), false, 'pelayan TIDAK boleh void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), false, 'pelayan TIDAK boleh void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), false, 'pelayan TIDAK boleh beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), true, 'pelayan boleh pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), false, 'pelayan TIDAK boleh tutup_kas');

-- ============================================================================
-- 6. DAPUR: Pembaruan status item masak & stok bahan
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;

select uji.sama(public.boleh('atur_pengaturan'), false, 'dapur TIDAK boleh atur_pengaturan');
select uji.sama(public.boleh('kelola_pegawai'), false, 'dapur TIDAK boleh kelola_pegawai');
select uji.sama(public.boleh('lihat_laporan'), false, 'dapur TIDAK boleh lihat_laporan');
select uji.sama(public.boleh('ubah_harga'), false, 'dapur TIDAK boleh ubah_harga');
select uji.sama(public.boleh('ubah_stok'), true, 'dapur boleh ubah_stok');
select uji.sama(public.boleh('void_sebelum_dapur'), false, 'dapur TIDAK boleh void_sebelum_dapur');
select uji.sama(public.boleh('void_sesudah_dapur'), false, 'dapur TIDAK boleh void_sesudah_dapur');
select uji.sama(public.boleh('beri_diskon'), false, 'dapur TIDAK boleh beri_diskon');
select uji.sama(public.boleh('pakai_voucher'), false, 'dapur TIDAK boleh pakai_voucher');
select uji.sama(public.boleh('tutup_kas'), false, 'dapur TIDAK boleh tutup_kas');

rollback;
