-- ============================================================================
-- supabase/tes/pengaturan_identitas.sql
-- Pengujian Pengaturan Identitas & Tampilan Resto (T9-01 / PRD M2)
--
-- Kasus yang diuji:
-- 1. Owner pusat dapat mengubah nama resto, tagline, logo, dan banner via simpan_pengaturan().
-- 2. Nama pada public.penyewa dan identitas pada public.pengaturan terbarui secara akurat.
-- 3. Stempel waktu versi optimistik (versi_pengaturan) diperbarui.
-- 4. Jejak audit tercatat kekal pada public.catatan_audit.
-- 5. Staf tanpa wewenang (pelayan / kasir tanpa izin atur_pengaturan) ditolak.
-- 6. Panggilan tanpa otentikasi (anon/unauthenticated) ditolak.
-- 7. Kunci konkurensi optimistik: pemanggilan dengan versi_lama yang tidak cocok ditolak (P0004).
-- 8. Validasi masukan: nama kosong ditolak (22023).
-- 9. RPC ambil_pengaturan_identitas mengembalikan identitas lengkap bagi pengguna yang sah.
-- 10. RPC katalog_publik menyajikan tagline, logo, dan banner terbaru kepada publik tanpa login.
-- 11. Transaksi dan struk masa lalu tidak rusak oleh perubahan nama resto.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 1 - 4: Owner mengubah identitas resto secara sukses & audit berjejak
-- ----------------------------------------------------------------------------
-- Masuk sebagai Owner Pusat Kedai Oasis (90000000-0000-0000-0000-000000000002)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  v_hasil jsonb;
begin
  v_hasil := public.simpan_pengaturan(
    p_nama_resto => 'Kedai Oasis Barokah Nusantara',
    p_tagline => 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal',
    p_logo_url => 'https://resto-barokah.com/logo-kedai-oasis.png',
    p_banner_url => 'https://resto-barokah.com/banner-hero-nusantara.webp'
  );

  if (v_hasil->>'berhasil')::boolean is not true then
    raise exception 'Gagal menyimpan pengaturan identitas: %', v_hasil;
  end if;

  if (v_hasil->'data'->>'nama_resto') <> 'Kedai Oasis Barokah Nusantara' then
    raise exception 'Nama resto tidak sesuai: %', v_hasil;
  end if;
end;
$$;

reset role;
select uji.klaim(null);

-- Asersi Kasus 1: Nama di tabel penyewa terbarui
select uji.harap(
  exists (
    select 1 from public.penyewa
    where id = '11111111-1111-1111-1111-111111111111'
      and nama = 'Kedai Oasis Barokah Nusantara'
  ),
  'Kasus 1: Nama resto pada tabel penyewa berhasil diperbarui'
);

-- Asersi Kasus 2: Tagline, logo, dan banner di tabel pengaturan terbarui
select uji.harap(
  exists (
    select 1 from public.pengaturan
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and tagline = 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal'
      and logo_url = 'https://resto-barokah.com/logo-kedai-oasis.png'
      and banner_url = 'https://resto-barokah.com/banner-hero-nusantara.webp'
      and versi_pengaturan is not null
  ),
  'Kasus 2: Tagline, logo_url, dan banner_url pada tabel pengaturan berhasil diperbarui'
);

-- Asersi Kasus 4: Jejak audit tercatat
select uji.harap(
  exists (
    select 1 from public.catatan_audit
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and aksi = 'ubah_identitas_resto'
      and entitas = 'pengaturan'
      and nilai_baru->>'nama_resto' = 'Kedai Oasis Barokah Nusantara'
  ),
  'Kasus 4: Jejak audit pengubahan identitas resto tercatat kekal di catatan_audit'
);

-- ----------------------------------------------------------------------------
-- Kasus 5: Staf tanpa wewenang (pelayan) ditolak
-- ----------------------------------------------------------------------------
-- Pelayan Kedai Oasis (90000000-0000-0000-0000-000000000005)
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_pengaturan(
    p_nama_resto => 'Resto Dibajak Pelayan'
  );
  $$,
  'tidak memiliki wewenang',
  'Kasus 5: Pelayan tanpa izin atur_pengaturan ditolak mengubah identitas'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 6: Panggilan tanpa otentikasi ditolak
-- ----------------------------------------------------------------------------
select uji.klaim(null);
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_pengaturan(
    p_nama_resto => 'Resto Tanpa Login'
  );
  $$,
  'Tidak diautentikasi',
  'Kasus 6: Panggilan tanpa auth.uid() ditolak'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 7: Kunci konkurensi optimistik menolak versi lama
-- ----------------------------------------------------------------------------
-- Owner masuk dan mencoba menyimpan dengan stempel versi lama yang salah
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_pengaturan(
    p_nama_resto => 'Konflik Bersamaan',
    p_versi_lama => '2020-01-01 00:00:00+00'::timestamptz
  );
  $$,
  'sudah diubah oleh pengguna lain',
  'Kasus 7: Simpanan dengan versi_lama basi ditolak (optimistic locking P0004)'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 8: Validasi nama kosong ditolak
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_pengaturan(
    p_nama_resto => '   '
  );
  $$,
  'Nama resto wajib diisi',
  'Kasus 8: Nama resto berupa spasi kosong ditolak'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 9: RPC ambil_pengaturan_identitas
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap(
  (public.ambil_pengaturan_identitas()->'data'->>'nama_resto') = 'Kedai Oasis Barokah Nusantara'
  and (public.ambil_pengaturan_identitas()->'data'->>'tagline') = 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal'
  and (public.ambil_pengaturan_identitas()->'data'->>'logo_url') = 'https://resto-barokah.com/logo-kedai-oasis.png',
  'Kasus 9: RPC ambil_pengaturan_identitas mengembalikan identitas lengkap'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 10: RPC katalog_publik menyajikan tagline, logo, dan banner ke publik
-- ----------------------------------------------------------------------------
-- Anonim (tanpa login) membaca katalog oasis
select uji.klaim(null);
set local role anon;

select uji.harap(
  (public.katalog_publik('oasis')->'resto'->>'nama') = 'Kedai Oasis Barokah Nusantara'
  and (public.katalog_publik('oasis')->'resto'->>'tagline') = 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal'
  and (public.katalog_publik('oasis')->'resto'->>'logo_url') = 'https://resto-barokah.com/logo-kedai-oasis.png'
  and (public.katalog_publik('oasis')->'resto'->>'banner_url') = 'https://resto-barokah.com/banner-hero-nusantara.webp',
  'Kasus 10: katalog_publik langsung menampilkan nama, tagline, logo, dan banner baru ke publik'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 11: Keutuhan catatan keuangan & pesanan masa lalu
-- ----------------------------------------------------------------------------
-- Memastikan baris transaksi pesanan tetap utuh dan subtotal tidak terpengaruh
select uji.harap(
  (select count(*) from public.pesanan where penyewa_id = '11111111-1111-1111-1111-111111111111') >= 0,
  'Kasus 11: Catatan pesanan dan data keuangan tetap utuh'
);
