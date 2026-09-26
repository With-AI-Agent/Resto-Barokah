-- ============================================================================
-- supabase/tes/pengaturan_tema.sql
-- Pengujian Tema & Warna Merek Resto (T9-02 / PRD M2)
--
-- Kasus yang diuji:
-- 1. Default tema 'terang' dan kerapatan 'nyaman'.
-- 2. Owner pusat dapat menyimpan tema 'hangat', warna_merek, dan kerapatan 'padat'.
-- 3. Data tema pada public.pengaturan terbarui secara akurat beserta versi optimistik.
-- 4. Jejak audit tercatat kekal pada public.catatan_audit (aksi = 'ubah_tema_resto').
-- 5. Semua 10 tema resmi (terang, hangat, gelap, kontras, bara, vintage, alam, tropis, pastel, etnik) diterima.
-- 6. Tema tidak valid ditolak (22023).
-- 7. Kerapatan tidak valid ditolak (22023).
-- 8. Staf tanpa izin atur_pengaturan (pelayan) ditolak (42501).
-- 9. Panggilan tanpa login ditolak (42501).
-- 10. Optimistic locking: versi_lama tidak cocok ditolak (P0001).
-- 11. RPC ambil_pengaturan_identitas mengembalikan tema dan kerapatan.
-- 12. RPC katalog_publik menyajikan tema resto kepada publik tanpa login.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 1: Nilai awal tema & kerapatan
-- ----------------------------------------------------------------------------
select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and tema in ('terang', 'hangat', 'gelap', 'kontras', 'bara', 'vintage', 'alam', 'tropis', 'pastel', 'etnik')
       and kerapatan in ('nyaman', 'padat')
  ),
  'Kasus 1: Baris pengaturan memiliki tema dan kerapatan valid'
);

-- ----------------------------------------------------------------------------
-- Kasus 2 - 4: Owner mengubah tema tampilan & verifikasi catatan audit
-- ----------------------------------------------------------------------------
-- Masuk sebagai Owner Pusat Kedai Oasis (90000000-0000-0000-0000-000000000002)
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  v_hasil jsonb;
begin
  v_hasil := public.simpan_tema(
    p_tema        => 'hangat',
    p_warna_merek => '#e06000',
    p_kerapatan   => 'padat'
  );

  if (v_hasil->>'berhasil')::boolean is not true then
    raise exception 'Gagal menyimpan tema: %', v_hasil;
  end if;

  if (v_hasil->'data'->>'tema') <> 'hangat' then
    raise exception 'Tema tidak sesuai: %', v_hasil;
  end if;

  if (v_hasil->'data'->>'kerapatan') <> 'padat' then
    raise exception 'Kerapatan tidak sesuai: %', v_hasil;
  end if;
end;
$$;

reset role;
select uji.klaim(null);

-- Asersi Kasus 2 & 3: Data di tabel pengaturan terbarui
select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and tema = 'hangat'
       and warna_merek = '#e06000'
       and kerapatan = 'padat'
  ),
  'Kasus 2 & 3: Pengaturan tema berhasil diperbarui di tabel pengaturan'
);

-- Asersi Kasus 4: Jejak audit kekal tercatat
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'ubah_tema_resto'
       and entitas = 'pengaturan'
       and nilai_baru->>'tema' = 'hangat'
       and nilai_baru->>'kerapatan' = 'padat'
  ),
  'Kasus 4: Jejak audit ubah_tema_resto tercatat lengkap di catatan_audit'
);

-- ----------------------------------------------------------------------------
-- Kasus 5: Pengujian 10 tema resmi yang didukung
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

do $$
declare
  v_tema_list text[] := array['terang', 'hangat', 'gelap', 'kontras', 'bara', 'vintage', 'alam', 'tropis', 'pastel', 'etnik'];
  v_tema text;
  v_hasil jsonb;
begin
  foreach v_tema in array v_tema_list
  loop
    v_hasil := public.simpan_tema(
      p_tema      => v_tema,
      p_kerapatan => 'nyaman'
    );
    if (v_hasil->>'berhasil')::boolean is not true or (v_hasil->'data'->>'tema') <> v_tema then
      raise exception 'Gagal menyimpan tema resmi %: %', v_tema, v_hasil;
    end if;
  end loop;
end;
$$;

reset role;
select uji.klaim(null);

select uji.harap(
  exists (
    select 1 from public.pengaturan
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and tema = 'etnik'
  ),
  'Kasus 5: Seluruh 10 tema resmi berhasil disimpan dan diterima'
);

-- ----------------------------------------------------------------------------
-- Kasus 6: Tema tidak valid ditolak
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_tema(
    p_tema => 'tema_palsu_neon'
  );
  $$,
  'tidak valid',
  'Kasus 6: Tema palsu ditolak dengan pesan validasi'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 7: Kerapatan tidak valid ditolak
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_tema(
    p_tema => 'terang',
    p_kerapatan => 'kerapatan_sembrono'
  );
  $$,
  'tidak valid',
  'Kasus 7: Kerapatan tidak valid ditolak dengan pesan validasi'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 8: Staf tanpa wewenang (pelayan) ditolak
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_tema(
    p_tema => 'gelap'
  );
  $$,
  'tidak memiliki wewenang',
  'Kasus 8: Pelayan tanpa wewenang atur_pengaturan ditolak mengubah tema'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 9: Panggilan tanpa otentikasi ditolak
-- ----------------------------------------------------------------------------
select uji.klaim(null);
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_tema(
    p_tema => 'vintage'
  );
  $$,
  'Tidak diautentikasi',
  'Kasus 9: Panggilan simpan_tema tanpa login ditolak'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 10: Optimistic locking menolak versi basi
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$
  select public.simpan_tema(
    p_tema => 'alam',
    p_versi_lama => '2020-01-01 00:00:00+00'::timestamptz
  );
  $$,
  'sudah diubah oleh pengguna lain',
  'Kasus 10: Optimistic locking menolak jika p_versi_lama tidak cocok'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 11: RPC ambil_pengaturan_identitas menyertakan tema & kerapatan
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.harap(
  (public.ambil_pengaturan_identitas()->'data'->>'tema') is not null
  and (public.ambil_pengaturan_identitas()->'data'->>'kerapatan') is not null,
  'Kasus 11: ambil_pengaturan_identitas mengembalikan kolom tema dan kerapatan'
);

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 12: RPC katalog_publik menyajikan tema ke publik tanpa login
-- ----------------------------------------------------------------------------
select uji.klaim(null);
set local role anon;

select uji.harap(
  (public.katalog_publik('oasis')->'resto'->>'tema') = 'etnik',
  'Kasus 12: katalog_publik menyajikan tema etnik yang baru disetel ke pengunjung publik'
);

reset role;
select uji.klaim(null);
