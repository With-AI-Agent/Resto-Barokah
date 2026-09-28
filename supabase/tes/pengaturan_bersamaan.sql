-- ============================================================================
-- supabase/tes/pengaturan_bersamaan.sql
-- Pengujian Kunci Konkurensi Optimistik Pengaturan & Menu Bersamaan (T10-11)
-- TECH_SPEC §5 (M2), PRD M2 / M12 Kasus Tepi, ART-3
--
-- Kasus yang diuji:
-- 1. Dua pengguna membaca pengaturan resto bersamaan (versi V0).
-- 2. Pengguna A menyimpan perubahan lebih dulu (versi naik ke V1).
-- 3. Pengguna B mencoba menyimpan dengan versi lama V0 -> DITOLAK (P0001).
-- 4. Perubahan Pengguna A tidak tertimpa diam-diam di basis data.
-- 5. Kunci konkurensi optimistik pada simpan_operasional (PB1 & Service charge).
-- 6. Kunci konkurensi optimistik pada simpan_menu (harga & status menu).
-- 7. Kunci konkurensi optimistik pada simpan_kategori_menu.
-- 8. Kunci konkurensi optimistik pada simpan_meja.
-- 9. Jejak audit insiden konflik versi tercatat via catat_konflik_pengaturan().
-- 10. Pengguna tanpa izin atau tanpa login (anon) ditolak fail-closed.
-- ============================================================================

-- Gunakan identitas Owner Resto A
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

-- ----------------------------------------------------------------------------
-- Kasus 1 - 4: Konkurensi Optimistik pada simpan_pengaturan
-- ----------------------------------------------------------------------------
do $$
declare
  v_versi_awal timestamptz;
  v_versi_a    timestamptz;
  v_hasil_a    jsonb;
  v_tertangkap boolean := false;
  v_nama_db    text;
begin
  -- 1. Baca versi pengaturan saat ini (disimulasikan dibaca oleh User A & User B bersamaan)
  select versi_pengaturan into v_versi_awal
    from public.pengaturan
   where penyewa_id = '11111111-1111-1111-1111-111111111111';

  if v_versi_awal is null then
    v_versi_awal := now() - interval '1 hour';
    update public.pengaturan
       set versi_pengaturan = v_versi_awal
     where penyewa_id = '11111111-1111-1111-1111-111111111111';
  end if;

  -- 2. Pengguna A menyimpan lebih dulu dengan menyertakan v_versi_awal
  perform pg_sleep(0.01);
  v_hasil_a := public.simpan_pengaturan(
    p_nama_resto => 'Resto Barokah - Versi Pengguna A',
    p_tagline    => 'Masakan Berkah Pilihan Utama',
    p_versi_lama => v_versi_awal
  );

  -- 3. Pengguna B mencoba menyimpan dengan versi lama (v_versi_awal yang sudah basi)
  begin
    perform public.simpan_pengaturan(
      p_nama_resto => 'Resto Barokah - Versi Pengguna B Timpa Diam-diam',
      p_tagline    => 'Slogan Usang',
      p_versi_lama => v_versi_awal
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'GAGAL: Simpanan Pengguna B dengan versi usang seharusnya ditolak P0001!';
  end if;

  -- 4. Verifikasi nilai di database tetap versi Pengguna A
  select nama into v_nama_db
    from public.penyewa
   where id = '11111111-1111-1111-1111-111111111111';

  if v_nama_db <> 'Resto Barokah - Versi Pengguna A' then
    raise exception 'GAGAL: Data pengguna A tertimpa oleh pengguna B! Nama db: %', v_nama_db;
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 1-4: Optimistic locking simpan_pengaturan berhasil mencegah timpaan diam-diam'
);

-- ----------------------------------------------------------------------------
-- Kasus 5: Konkurensi Optimistik pada simpan_operasional (ART-3)
-- ----------------------------------------------------------------------------
do $$
declare
  v_versi_awal timestamptz;
  v_tertangkap boolean := false;
  v_pb1_db     numeric;
begin
  select versi_pengaturan into v_versi_awal
    from public.pengaturan
   where penyewa_id = '11111111-1111-1111-1111-111111111111';

  -- Pengguna A menyimpan tarif PB1 11%
  perform pg_sleep(0.01);
  perform public.simpan_operasional(
    p_pajak_pb1_persen => 11.0,
    p_versi_lama       => v_versi_awal
  );

  -- Pengguna B mencoba mengubah dengan versi awal (basi)
  begin
    perform public.simpan_operasional(
      p_pajak_pb1_persen => 5.0,
      p_versi_lama       => v_versi_awal
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'GAGAL: Pengguna B berhasil menimpa operasional dengan versi basi!';
  end if;

  -- Verifikasi nilai tetap 11.0
  select pajak_pb1_persen into v_pb1_db
    from public.pengaturan
   where penyewa_id = '11111111-1111-1111-1111-111111111111';

  if v_pb1_db <> 11.0 then
    raise exception 'GAGAL: Tarif PB1 tertimpa nilai basi: %', v_pb1_db;
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 5: Optimistic locking simpan_operasional melindungi parameter pajak (ART-3)'
);

-- ----------------------------------------------------------------------------
-- Kasus 6: Konkurensi Optimistik pada simpan_menu
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id     uuid;
  v_menu_id    uuid;
  v_hasil_baru jsonb;
  v_versi_m0   timestamptz;
  v_hasil_a    jsonb;
  v_tertangkap boolean := false;
  v_harga_db   integer;
begin
  select id into v_kat_id
    from public.kategori_menu
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
   limit 1;

  -- Tambah menu untuk pengujian
  v_hasil_baru := public.simpan_menu(
    p_kategori_id => v_kat_id,
    p_nama        => 'Soto Kudus Spesial T10-11',
    p_harga       => 20000,
    p_jenis       => 'makanan'
  );
  v_menu_id := (v_hasil_baru->>'id')::uuid;

  select diubah_pada into v_versi_m0
    from public.menu_item
   where id = v_menu_id;

  -- Pengguna A mengubah harga menjadi 25.000 dengan versi v_versi_m0
  perform pg_sleep(0.01);
  v_hasil_a := public.simpan_menu(
    p_id          => v_menu_id,
    p_kategori_id => v_kat_id,
    p_nama        => 'Soto Kudus Spesial T10-11',
    p_harga       => 25000,
    p_jenis       => 'makanan',
    p_versi_lama  => v_versi_m0
  );

  -- Pengguna B mencoba mengubah harga menjadi 15.000 dengan versi basi (v_versi_m0)
  begin
    perform public.simpan_menu(
      p_id          => v_menu_id,
      p_kategori_id => v_kat_id,
      p_nama        => 'Soto Kudus Spesial T10-11',
      p_harga       => 15000,
      p_jenis       => 'makanan',
      p_versi_lama  => v_versi_m0
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'GAGAL: Pengguna B berhasil menimpa menu dengan versi lama!';
  end if;

  select harga into v_harga_db
    from public.menu_item
   where id = v_menu_id;

  if v_harga_db <> 25000 then
    raise exception 'GAGAL: Harga menu tertimpa nilai basi: %', v_harga_db;
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 6: Optimistic locking simpan_menu menolak versi usang dan melindungi harga menu'
);

-- ----------------------------------------------------------------------------
-- Kasus 7: Konkurensi Optimistik pada simpan_kategori_menu
-- ----------------------------------------------------------------------------
do $$
declare
  v_hasil_baru jsonb;
  v_kat_id     uuid;
  v_versi_k0   timestamptz;
  v_tertangkap boolean := false;
  v_tujuan_db  text;
begin
  v_hasil_baru := public.simpan_kategori_menu(
    p_nama   => 'Minuman Segar T10-11',
    p_urutan => 99,
    p_tujuan => 'bar'
  );
  v_kat_id := (v_hasil_baru->>'id')::uuid;

  select diubah_pada into v_versi_k0
    from public.kategori_menu
   where id = v_kat_id;

  -- Pengguna A mengubah tujuan ke dapur
  perform pg_sleep(0.01);
  perform public.simpan_kategori_menu(
    p_id         => v_kat_id,
    p_nama       => 'Minuman Segar T10-11',
    p_urutan     => 99,
    p_tujuan     => 'dapur',
    p_versi_lama => v_versi_k0
  );

  -- Pengguna B mencoba menyimpan dengan versi lama v_versi_k0
  begin
    perform public.simpan_kategori_menu(
      p_id         => v_kat_id,
      p_nama       => 'Minuman Segar T10-11 Edit Basi',
      p_urutan     => 99,
      p_tujuan     => 'bar',
      p_versi_lama => v_versi_k0
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'GAGAL: Pengguna B berhasil menimpa kategori menu dengan versi usang!';
  end if;

  select tujuan into v_tujuan_db
    from public.kategori_menu
   where id = v_kat_id;

  if v_tujuan_db <> 'dapur' then
    raise exception 'GAGAL: Tujuan kategori menu tertimpa nilai basi: %', v_tujuan_db;
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 7: Optimistic locking simpan_kategori_menu menolak versi usang'
);

-- ----------------------------------------------------------------------------
-- Kasus 8: Konkurensi Optimistik pada simpan_meja
-- ----------------------------------------------------------------------------
do $$
declare
  v_cabang_id  uuid := 'a1a1a1a1-0000-0000-0000-000000000001';
  v_hasil_baru jsonb;
  v_meja_id    uuid;
  v_versi_t0   timestamptz;
  v_tertangkap boolean := false;
  v_area_db    text;
begin
  v_hasil_baru := public.simpan_meja(
    p_cabang_id => v_cabang_id,
    p_nama      => 'Meja Konkuren T10-11',
    p_area      => 'Indoor'
  );
  v_meja_id := coalesce((v_hasil_baru->>'id')::uuid, (v_hasil_baru->'meja'->>'id')::uuid);

  select diubah_pada into v_versi_t0
    from public.meja
   where id = v_meja_id;

  -- Pengguna A mengubah area menjadi VIP
  perform pg_sleep(0.01);
  perform public.simpan_meja(
    p_meja_id    => v_meja_id,
    p_nama       => 'Meja Konkuren T10-11',
    p_area       => 'VIP',
    p_versi_lama => v_versi_t0
  );

  -- Pengguna B mencoba menyimpan dengan versi lama v_versi_t0
  begin
    perform public.simpan_meja(
      p_meja_id    => v_meja_id,
      p_nama       => 'Meja Konkuren T10-11',
      p_area       => 'Outdoor',
      p_versi_lama => v_versi_t0
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception 'GAGAL: Pengguna B berhasil menimpa data meja dengan versi usang!';
  end if;

  select area into v_area_db
    from public.meja
   where id = v_meja_id;

  if v_area_db <> 'VIP' then
    raise exception 'GAGAL: Area meja tertimpa nilai basi: %', v_area_db;
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 8: Optimistic locking simpan_meja menolak versi usang'
);

-- ----------------------------------------------------------------------------
-- Kasus 9: Jejak Audit Insiden Konflik Versi (catat_konflik_pengaturan)
-- ----------------------------------------------------------------------------
do $$
declare
  v_hasil jsonb;
  v_tercatat boolean;
begin
  v_hasil := public.catat_konflik_pengaturan(
    p_entitas      => 'pengaturan',
    p_versi_klien  => now() - interval '10 minutes',
    p_keterangan   => 'Tabrakan saat menyimpan profil restoran'
  );

  if coalesce((v_hasil->>'berhasil')::boolean, false) <> true then
    raise exception 'GAGAL: RPC catat_konflik_pengaturan gagal mengeksekusi!';
  end if;

  select exists (
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'konflik_versi_ditolak'
       and entitas = 'pengaturan'
       and nilai_baru->>'status' = 'ditolak_fail_closed'
  ) into v_tercatat;

  if not v_tercatat then
    raise exception 'GAGAL: Insiden tabrakan versi tidak tercatat di catatan_audit!';
  end if;
end;
$$;

select uji.sama(
  true,
  true,
  'Kasus 9: Insiden penolakan tabrakan versi berhasil dicatat ke catatan_audit'
);

-- ----------------------------------------------------------------------------
-- Kasus 10: Otorisasi & Hak Akses Fail-Closed
-- ----------------------------------------------------------------------------
-- Staf biasa (Pelayan: 90000000-0000-0000-0000-000000000005) tidak boleh simpan menu
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_menu(
    p_nama => 'Menu Terlarang',
    p_kategori_id => 'c0000000-0000-0000-0000-000000000001',
    p_harga => 10000
  );
  $$,
  'tidak memiliki wewenang',
  'Kasus 10a: Staf tanpa wewenang ditolak mengelola menu'
);

reset role;
select uji.klaim(null);

-- Anonim tanpa otentikasi ditolak
set local role anon;
select uji.harap_gagal_sebab(
  $$
  select public.simpan_menu(
    p_nama => 'Menu Anon',
    p_kategori_id => 'c0000000-0000-0000-0000-000000000001',
    p_harga => 10000
  );
  $$,
  'permission denied',
  'Kasus 10b: Panggilan anonim ditolak fail-closed'
);

reset role;
select uji.klaim(null);
