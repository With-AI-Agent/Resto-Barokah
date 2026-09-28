-- ============================================================================
-- UJI: SUMBER KEBENARAN MENU HABIS (T4-05) — tandai_habis dari dapur, jejak
-- siapa & kapan, pencabutan butuh izin ubah_stok, riwayat hanya-tambah.
-- Kontrak lama yang MENANG: katalog.sql (menu_habis baca, RLS penanda harian).
-- ============================================================================

-- 1. Anonim tidak boleh memanggil tandai_habis.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002', true)$$,
  'permission denied|tidak diizinkan',
  'anon ditolak memanggil tandai_habis');
reset role;

-- 2. Kasir (tanpa izin ubah_stok) tidak boleh menandai — apalagi mencabut.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001', true)$$,
  'tidak berizin',
  'kasir tanpa izin ubah_stok tidak boleh menandai menu habis');
select uji.harap_gagal_sebab(
  $$select public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001', false)$$,
  'tidak berizin',
  'pencabutan penanda habis juga butuh izin (kasir ditolak)');
reset role;

-- 3. Dapur (berizin ubah_stok) menandai habis di cabangnya: satu sentuhan.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002', true)->>'habis')::text),
  'true', 'dapur menandai Nasi Goreng habis di Cabang Dua');
reset role;
select uji.sama(
  public.menu_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'),
  true, 'menu_habis langsung membaca kebenaran dari database (tanpa refresh manual)');
select uji.sama(
  public.menu_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001'),
  false, 'penanda hanya berlaku di cabang yang menandainya');

-- 4. Jejak siapa & kapan tercatat.
select uji.sama(
  (select count(*) from public.menu_habis_riwayat r
    where r.menu_item_id = 'beef0000-0000-0000-0000-000000000001'
      and r.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'
      and r.habis is true
      and r.pelaku_id = '90000000-0000-0000-0000-000000000006'
      and r.waktu is not null),
  1::bigint, 'riwayat mencatat siapa (dapur) dan kapan menandai habis');

-- 5. Pencabutan oleh pemilik izin sah + tercatat juga.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002', false)->>'habis')::text),
  'false', 'pencabutan oleh pemilik izin ubah_stok berhasil');
reset role;
select uji.sama(
  public.menu_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'),
  false, 'penanda habis tercabut');
select uji.sama(
  (select count(*) from public.menu_habis_riwayat r
    where r.menu_item_id = 'beef0000-0000-0000-0000-000000000001'
      and r.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'),
  2::bigint, 'pencabutan pun meninggalkan jejak — riwayat tidak menghapus catatan lama');

-- 6. Riwayat hanya-tambah: tidak bisa diubah / dihapus.
select uji.harap_gagal_sebab(
  $$update public.menu_habis_riwayat set habis = false where habis is true$$,
  'hanya-tambah',
  'riwayat penanda habis tidak boleh diubah');
select uji.harap_gagal_sebab(
  $$delete from public.menu_habis_riwayat$$,
  'hanya-tambah',
  'riwayat penanda habis tidak boleh dihapus');

-- 7. Menu penyewa lain tidak dikenali (isolasi resto).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.tandai_habis('beef0000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000002', true)$$,
  'tidak ditemukan di resto ini',
  'menu resto lain ditolak tandai_habis');
reset role;
