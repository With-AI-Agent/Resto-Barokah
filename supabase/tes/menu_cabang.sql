-- ============================================================================
-- SUITE UJI: HARGA & KETERSEDIAAN MENU BERBEDA PER CABANG (T9-06 / PRD M11)
--
-- Menguji:
--   1. Penentuan harga: bila tidak diatur -> memakai harga pusat; bila diatur -> harga cabang.
--   2. Verifikasi 2 cabang, 1 menu, harga berbeda.
--   3. Reset harga khusus cabang kembali ke harga pusat (harga = null).
--   4. Menyembunyikan item per cabang (aktif = false).
--   5. Pesanan ke menu yang disembunyikan di cabang bersangkutan ditolak (fail-closed).
--   6. Validasi harga negatif ditolak.
--   7. Isolasi multi-tenant (cabang / menu resto lain ditolak).
--   8. Pembatasan hak akses (kasir tanpa izin ditolak).
--   9. Simpan banyak menu cabang sekaligus (batch update).
--  10. Matriks perbandingan multi-cabang (ambil_perbandingan_menu_cabang).
--  11. Salin konfigurasi antar cabang (salin_harga_cabang).
--  12. Reset seluruh harga cabang ke harga pusat.
--  13. Pencatatan jejak audit kekal di catatan_audit.
-- ============================================================================

begin;

-- Siapkan identitas Owner Pusat Kedai Oasis
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- Data uji yang dipakai:
-- Tenant: 11111111-1111-1111-1111-111111111111
-- Cabang Pusat: a1a1a1a1-0000-0000-0000-000000000001
-- Cabang Dua: a1a1a1a1-0000-0000-0000-000000000002
-- Menu Es Teh: beef0000-0000-0000-0000-000000000002 (harga pusat 8000)
-- Menu Nasi Goreng: beef0000-0000-0000-0000-000000000001 (harga pusat 25000)

-- ----------------------------------------------------------------------------
-- Kasus 1: Harga berlaku awal Es Teh di Cabang Dua adalah harga pusat (8.000)
-- ----------------------------------------------------------------------------
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000002'),
  8000,
  'T906-01: Es Teh di Cabang Dua awal memakai harga pusat 8.000'
);

-- ----------------------------------------------------------------------------
-- Kasus 2: Atur harga khusus Es Teh di Cabang Dua menjadi 10.000
-- ----------------------------------------------------------------------------
select uji.sama(
  (public.simpan_menu_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002',
    'beef0000-0000-0000-0000-000000000002',
    10000,
    true
  )->>'berhasil')::boolean,
  true,
  'T906-02: Berhasil simpan harga khusus Es Teh di Cabang Dua'
);

-- ----------------------------------------------------------------------------
-- Kasus 3: Verifikasi 2 cabang, 1 menu, harga berbeda:
--   Cabang Pusat: 8.000 (harga pusat)
--   Cabang Dua: 10.000 (harga khusus cabang)
-- ----------------------------------------------------------------------------
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001'),
  8000,
  'T906-03a: Es Teh di Cabang Pusat tetap 8.000'
);

select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000002'),
  10000,
  'T906-03b: Es Teh di Cabang Dua memakai harga khusus 10.000 (2 cabang, 1 menu, harga berbeda)'
);

-- ----------------------------------------------------------------------------
-- Kasus 4: Reset harga khusus cabang ke harga pusat (p_harga = null)
-- ----------------------------------------------------------------------------
select uji.sama(
  (public.simpan_menu_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002',
    'beef0000-0000-0000-0000-000000000002',
    null,
    true
  )->>'berhasil')::boolean,
  true,
  'T906-04: Berhasil reset harga khusus cabang kembali ke pusat'
);

select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000002'),
  8000,
  'T906-05: Setelah di-reset, Es Teh di Cabang Dua kembali ke harga pusat 8.000'
);

-- ----------------------------------------------------------------------------
-- Kasus 5: Sembunyikan menu di Cabang Dua (p_aktif = false)
-- ----------------------------------------------------------------------------
select uji.sama(
  (public.simpan_menu_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002',
    'beef0000-0000-0000-0000-000000000002',
    null,
    false
  )->>'berhasil')::boolean,
  true,
  'T906-06: Berhasil sembunyikan Es Teh di Cabang Dua'
);

-- ----------------------------------------------------------------------------
-- Kasus 6: harga_berlaku mengembalikan NULL bila menu disembunyikan di cabang
-- ----------------------------------------------------------------------------
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000002'),
  null,
  'T906-07: harga_berlaku NULL bila menu disembunyikan di cabang tersebut'
);

-- Namun di Cabang Pusat tetap berlaku 8.000
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001'),
  8000,
  'T906-08: Di Cabang Pusat, menu tetap berlaku'
);

-- ----------------------------------------------------------------------------
-- Kasus 7: Mencoba membuat pesanan item yang disembunyikan di cabang ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_pesanan_id uuid := '77777777-0000-0000-0000-000000000001';
  v_tertangkap boolean := false;
begin
  -- Buat pesanan sementara di Cabang Dua
  insert into public.pesanan (
    id, penyewa_id, cabang_id, tipe, status, total, nomor, kunci_idempoten
  ) values (
    v_pesanan_id,
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000002',
    'dinein',
    'draf',
    0,
    995,
    'kunci-t906-01'
  );

  begin
    insert into public.pesanan_item (
      pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
    ) values (
      v_pesanan_id,
      'beef0000-0000-0000-0000-000000000002',
      'Es Teh Manis',
      8000,
      1,
      8000
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Pesanan item pada menu cabang nonaktif seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T906-09: Pesanan item pada menu yang disembunyikan di cabang berhasil ditolak');

-- Pulihkan status aktif Es Teh di Cabang Dua
select uji.sama(
  (public.simpan_menu_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002',
    'beef0000-0000-0000-0000-000000000002',
    null,
    true
  )->>'berhasil')::boolean,
  true,
  'T906-10: Pulihkan status aktif Es Teh di Cabang Dua'
);

-- ----------------------------------------------------------------------------
-- Kasus 8: Menolak harga khusus cabang negatif
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_menu_cabang(
      'a1a1a1a1-0000-0000-0000-000000000002',
      'beef0000-0000-0000-0000-000000000002',
      -5000,
      true
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Harga negatif seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T906-11: Validasi menolak harga khusus cabang negatif');

-- ----------------------------------------------------------------------------
-- Kasus 9: Menolak cabang milik penyewa lain (isolasi tenant)
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_menu_cabang(
      'b1b1b1b1-0000-0000-0000-000000000001', -- Cabang Tunggal (Tenant 2)
      'beef0000-0000-0000-0000-000000000002',
      9000,
      true
    );
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Cabang tidak ditemukan%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Cabang penyewa lain seharusnya ditolak dengan pesan Cabang tidak ditemukan';
  end if;
end;
$$;

select uji.harap(true, 'T906-12: Menolak cabang milik penyewa lain');

-- ----------------------------------------------------------------------------
-- Kasus 10: Menolak menu milik penyewa lain (isolasi tenant)
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_menu_cabang(
      'a1a1a1a1-0000-0000-0000-000000000001',
      'beef0000-0000-0000-0000-000000000004', -- Batagor (Tenant 2)
      15000,
      true
    );
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Menu tidak ditemukan%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Menu penyewa lain seharusnya ditolak dengan pesan Menu tidak ditemukan';
  end if;
end;
$$;

select uji.harap(true, 'T906-13: Menolak menu milik penyewa lain');

-- ----------------------------------------------------------------------------
-- Kasus 11: Pengguna tanpa izin (kasir) ditolak mengatur menu cabang
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Rina (kasir)

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    -- Kasir mencoba menyembunyikan item tanpa mengubah harga
    perform public.simpan_menu_cabang(
      'a1a1a1a1-0000-0000-0000-000000000001',
      'beef0000-0000-0000-0000-000000000002',
      null,
      false
    );
  exception
    when sqlstate 'P0001' then
      if sqlerrm like '%Hanya owner pusat, pemegang izin atur_pengaturan%' then
        v_tertangkap := true;
      end if;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Kasir tanpa izin seharusnya ditolak oleh simpan_menu_cabang';
  end if;
end;
$$;

select uji.harap(true, 'T906-14: Kasir tanpa izin atur_pengaturan ditolak');

-- Kembalikan klaim ke Owner Pusat
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- ----------------------------------------------------------------------------
-- Kasus 12: Simpan banyak menu cabang sekaligus (batch update)
-- ----------------------------------------------------------------------------
select uji.sama(
  (public.simpan_banyak_menu_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002',
    jsonb_build_array(
      jsonb_build_object(
        'menu_item_id', 'beef0000-0000-0000-0000-000000000001',
        'harga', 28000,
        'aktif', true
      ),
      jsonb_build_object(
        'menu_item_id', 'beef0000-0000-0000-0000-000000000003',
        'harga', 15000,
        'aktif', true
      )
    )
  )->>'jumlah')::integer,
  2,
  'T906-15: simpan_banyak_menu_cabang berhasil memproses 2 item'
);

select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'),
  28000,
  'T906-16: Nasi Goreng di Cabang Dua bernilai 28.000 setelah batch update'
);

-- ----------------------------------------------------------------------------
-- Kasus 13: Ambil perbandingan menu multi-cabang (ambil_perbandingan_menu_cabang)
-- ----------------------------------------------------------------------------
do $$
declare
  v_hasil jsonb;
begin
  v_hasil := public.ambil_perbandingan_menu_cabang();

  if not (v_hasil->>'berhasil')::boolean then
    raise exception 'ambil_perbandingan_menu_cabang gagal';
  end if;

  if jsonb_array_length(v_hasil->'daftar_cabang') < 2 then
    raise exception 'Daftar cabang harus memuat minimal 2 cabang';
  end if;

  if jsonb_array_length(v_hasil->'daftar_menu') < 1 then
    raise exception 'Daftar menu tidak boleh kosong';
  end if;
end;
$$;

select uji.harap(true, 'T906-17: ambil_perbandingan_menu_cabang mengembalikan matriks multi-cabang');

-- ----------------------------------------------------------------------------
-- Kasus 14: Salin harga cabang (salin_harga_cabang)
-- ----------------------------------------------------------------------------
-- Buat cabang ke-3 untuk pengujian salin harga
insert into public.cabang (id, penyewa_id, nama, alamat)
values ('a1a1a1a1-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Cabang Tiga', 'Jl. Dago 5');

select uji.sama(
  (public.salin_harga_cabang(
    'a1a1a1a1-0000-0000-0000-000000000002', -- Salin dari Cabang Dua
    'a1a1a1a1-0000-0000-0000-000000000003'  -- Ke Cabang Tiga
  )->>'berhasil')::boolean,
  true,
  'T906-18: salin_harga_cabang berhasil menyalin konfigurasi'
);

select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000003'),
  28000,
  'T906-19: Nasi Goreng di Cabang Tiga berhasil tersalin menjadi 28.000'
);

-- Salin cabang yang sama ditolak
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.salin_harga_cabang(
      'a1a1a1a1-0000-0000-0000-000000000002',
      'a1a1a1a1-0000-0000-0000-000000000002'
    );
  exception
    when sqlstate 'P0001' then
      v_tertangkap := true;
  end;

  if not v_tertangkap then
    raise exception using errcode = '40001', message = 'Salin ke cabang yang sama seharusnya ditolak';
  end if;
end;
$$;

select uji.harap(true, 'T906-20: Salin ke cabang yang sama berhasil ditolak');

-- ----------------------------------------------------------------------------
-- Kasus 15: Reset harga cabang (reset_harga_cabang)
-- ----------------------------------------------------------------------------
select uji.sama(
  (public.reset_harga_cabang('a1a1a1a1-0000-0000-0000-000000000003')->>'berhasil')::boolean,
  true,
  'T906-21: reset_harga_cabang berhasil mereset seluruh menu Cabang Tiga'
);

select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000003'),
  25000,
  'T906-22: Nasi Goreng di Cabang Tiga kembali ke harga pusat 25.000 setelah reset'
);

-- ----------------------------------------------------------------------------
-- Kasus 16: Jejak audit tercatat di catatan_audit
-- ----------------------------------------------------------------------------
select uji.harap(
  exists(
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'simpan_menu_cabang'
  ),
  'T906-23: Catatan audit simpan_menu_cabang tercatat'
);

select uji.harap(
  exists(
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'salin_harga_cabang'
  ),
  'T906-24: Catatan audit salin_harga_cabang tercatat'
);

select uji.harap(
  exists(
    select 1 from public.catatan_audit
     where penyewa_id = '11111111-1111-1111-1111-111111111111'
       and aksi = 'reset_harga_cabang'
  ),
  'T906-25: Catatan audit reset_harga_cabang tercatat'
);

rollback;
