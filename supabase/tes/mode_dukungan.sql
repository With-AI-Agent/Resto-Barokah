-- ============================================================================
-- UJI: Mode Dukungan Pemilik Platform (T1-28, ART-15)
-- ============================================================================

begin;

-- 1. Kasir / Owner Pusat mencoba masuk mode dukungan -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir (Rina)
set local role authenticated;

select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Bantu perbaikan data pesanan')->>'berhasil')::boolean),
  false,
  'Kasir ditolak masuk mode dukungan'
);

select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner (Bu Oasis)

select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Bantu perbaikan data pesanan')->>'berhasil')::boolean),
  false,
  'Owner pusat ditolak masuk mode dukungan'
);

-- 2. Pemilik platform mencoba masuk dengan alasan terlalu pendek (< 10 karakter) -> DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000001'); -- Pemilik Platform

select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'bantu')->>'berhasil')::boolean),
  false,
  'Alasan pendek (< 10 karakter) ditolak'
);

-- 3. Pemilik platform TANPA mode dukungan membaca menu penyewa -> 0 baris
select uji.sama(
  (select count(*)::int from public.menu_item where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Pemilik platform tanpa mode dukungan tidak bisa melihat menu penyewa (0 baris)'
);

-- 4. Pemilik platform MASUK mode dukungan sah (60 menit) -> BERHASIL
select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Investigasi laporan kendala cetak struk kasir', 60)->>'berhasil')::boolean),
  true,
  'Pemilik platform berhasil mengaktifkan mode dukungan'
);

-- 5. Pemilik platform DENGAN mode dukungan membaca menu penyewa -> BERHASIL (melihat data)
select uji.harap(
  (select count(*)::int from public.menu_item where penyewa_id = '11111111-1111-1111-1111-111111111111') > 0,
  'Pemilik platform dengan mode dukungan aktif dapat membaca data menu penyewa'
);

-- Owner penyewa dapat melihat jejak audit mode dukungan (ART-15)
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner (Bu Oasis)
select uji.harap(
  exists (
    select 1
      from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and pelaku_id = '90000000-0000-0000-0000-000000000001'
       and aksi = 'masuk_mode_dukungan'
  ),
  'Aksi masuk mode dukungan tercatat pada catatan_audit resto penyewa dan terlihat oleh owner'
);

-- 6. Pemilik platform DENGAN mode dukungan mencoba MENULIS (INSERT) menu -> DITOLAK (HANYA-BACA)
select uji.klaim('90000000-0000-0000-0000-000000000001'); -- Pemilik Platform

select uji.harap_gagal_sebab(
  $$insert into public.menu_item (penyewa_id, kategori_id, nama, harga) values ('11111111-1111-1111-1111-111111111111', 'beef0000-0000-0000-0000-000000000001', 'Menu Liar Platform', 50000)$$,
  'violates row-level security policy|permission denied',
  'Penulisan data penyewa oleh pemilik platform dalam mode dukungan tetap ditolak (hanya-baca)'
);

-- 7. Pemilik platform KELUAR mode dukungan -> BERHASIL
select uji.sama(
  (select (public.keluar_mode_dukungan('11111111-1111-1111-1111-111111111111')->>'berhasil')::boolean),
  true,
  'Pemilik platform berhasil mengakhiri mode dukungan'
);

-- 8. Pemilik platform membaca kembali menu penyewa -> 0 baris (akses tertutup kembali)
select uji.sama(
  (select count(*)::int from public.menu_item where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Setelah keluar mode dukungan, data penyewa kembali tidak terlihat (0 baris)'
);

-- Owner penyewa melihat jejak audit keluar mode dukungan
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner
select uji.harap(
  exists (
    select 1
      from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and pelaku_id = '90000000-0000-0000-0000-000000000001'
       and aksi = 'keluar_mode_dukungan'
  ),
  'Aksi keluar mode dukungan tercatat pada catatan_audit resto penyewa dan terlihat oleh owner'
);

rollback;
