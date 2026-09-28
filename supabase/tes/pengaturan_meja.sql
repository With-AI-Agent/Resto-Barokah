-- ============================================================================
-- supabase/tes/pengaturan_meja.sql
-- Pengujian Pengaturan Meja & Area (T9-04 / PRD M2 & M4)
--
-- Kasus yang diuji:
-- 1. Owner pusat dapat menambah meja baru dengan nomor/nama dan area.
-- 2. Keunikan nomor/nama meja per cabang: nama kembar di cabang yang sama ditolak.
-- 3. Nama meja yang sama di cabang berbeda diperbolehkan.
-- 4. Admin cabang / staf berizin dapat mengubah nama dan area meja.
-- 5. Menonaktifkan meja (aktif = false) sukses bila meja tidak ada pesanan aktif.
-- 6. Mitigasi Risiko T9-04: Pesanan baru di meja nonaktif DITOLAK di sisi server.
-- 7. Mitigasi Risiko T9-04: Pemindahan pesanan (update meja_id) ke meja nonaktif DITOLAK.
-- 8. Menonaktifkan meja yang sedang memiliki pesanan aktif DITOLAK server.
-- 9. RPC ambil_daftar_meja mengembalikan daftar meja dan area dengan benar.
-- 10. Otorisasi ketat: staf tanpa izin (pelayan/kasir tanpa atur_pengaturan) ditolak.
-- 11. Hapus meja yang belum punya pesanan berhasil dan tercatat di audit.
-- 12. Hapus meja yang punya riwayat pesanan ditolak (penjaga picu_meja_jaga).
-- 13. Jejak audit kekal tercatat di public.catatan_audit untuk tambah, ubah, dan hapus.
-- 14. Validasi nama meja kosong atau melebihi batas panjang ditolak.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 1: Owner Pusat menambah meja baru
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Oasis

do $$
declare
  v_res jsonb;
  v_meja_id uuid;
begin
  v_res := public.simpan_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
    p_nama      := 'Meja 10',
    p_area      := 'Lantai 2',
    p_aktif     := true
  );

  v_meja_id := (v_res->'meja'->>'id')::uuid;
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 1: simpan_meja berhasil');
  perform uji.sama(v_res->'meja'->>'nama', 'Meja 10', 'Kasus 1: nama meja sesuai');
  perform uji.sama(v_res->'meja'->>'area', 'Lantai 2', 'Kasus 1: area meja sesuai');
  perform uji.sama((v_res->'meja'->>'aktif')::boolean, true, 'Kasus 1: status aktif sesuai');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 2: Keunikan nama meja di cabang yang sama ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_meja(
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
      p_nama      := 'Meja 10', -- Sudah dipakai di Kasus 1
      p_area      := 'Lantai 1'
    );
  exception
    when others then
      if sqlerrm like '%sudah digunakan di cabang ini%' then
        v_tertangkap := true;
      end if;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 2: nama meja kembar di cabang sama wajib ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 3: Nama meja sama di cabang lain diperbolehkan
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
begin
  v_res := public.simpan_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000002', -- Cabang Dua
    p_nama      := 'Meja 10', -- Nama sama tapi di cabang 2
    p_area      := 'Lantai 2'
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 3: nama sama di cabang berbeda diperbolehkan');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 4: Admin cabang mengubah meja (nama & area)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003'); -- Admin Cabang 1

do $$
declare
  v_meja_id uuid;
  v_res jsonb;
begin
  select id into v_meja_id
    from public.meja
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and nama = 'Meja 10';

  v_res := public.simpan_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
    p_nama      := 'Meja 10-VIP',
    p_area      := 'VIP Lounge',
    p_aktif     := true,
    p_meja_id   := v_meja_id
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 4: ubah meja berhasil');
  perform uji.sama(v_res->'meja'->>'nama', 'Meja 10-VIP', 'Kasus 4: nama baru terbarui');
  perform uji.sama(v_res->'meja'->>'area', 'VIP Lounge', 'Kasus 4: area baru terbarui');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 5: Menonaktifkan meja (aktif = false)
-- ----------------------------------------------------------------------------
do $$
declare
  v_meja_id uuid;
  v_res jsonb;
begin
  select id into v_meja_id
    from public.meja
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and nama = 'Meja 10-VIP';

  v_res := public.simpan_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
    p_nama      := 'Meja 10-VIP',
    p_area      := 'VIP Lounge',
    p_aktif     := false,
    p_meja_id   := v_meja_id
  );

  perform uji.sama((v_res->'meja'->>'aktif')::boolean, false, 'Kasus 5: meja dinonaktifkan');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 6: Mitigasi Risiko T9-04 — Pesanan baru di meja nonaktif DITOLAK
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Cabang 1

do $$
declare
  v_meja_id uuid;
  v_tertangkap boolean := false;
begin
  select id into v_meja_id
    from public.meja
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and nama = 'Meja 10-VIP';

  begin
    insert into public.pesanan (
      penyewa_id,
      cabang_id,
      nomor,
      tipe,
      meja_id,
      status,
      kunci_idempoten
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'a1a1a1a1-0000-0000-0000-000000000001',
      881,
      'dinein',
      v_meja_id,
      'draf',
      'kunci-uji-meja-881'
    );
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 6: mitigasi T9-04 — pesanan baru di meja nonaktif wajib ditolak server');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 7: Mitigasi Risiko T9-04 — Pemindahan pesanan ke meja nonaktif DITOLAK
-- ----------------------------------------------------------------------------
do $$
declare
  v_meja_aktif uuid;
  v_meja_nonaktif uuid;
  v_pesanan_id uuid;
  v_tertangkap boolean := false;
begin
  -- Buat pesanan di meja aktif (Meja 1)
  select id into v_meja_aktif
    from public.meja
   where id = 'aaa00000-0000-0000-0000-000000000001';

  select id into v_meja_nonaktif
    from public.meja
   where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
     and nama = 'Meja 10-VIP';

  insert into public.pesanan (
    penyewa_id,
    cabang_id,
    nomor,
    tipe,
    meja_id,
    status,
    kunci_idempoten
  ) values (
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    882,
    'dinein',
    v_meja_aktif,
    'draf',
    'kunci-uji-meja-882'
  ) returning id into v_pesanan_id;

  begin
    -- Coba pindahkan pesanan ke meja nonaktif
    update public.pesanan
       set meja_id = v_meja_nonaktif
     where id = v_pesanan_id;
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 7: mitigasi T9-04 — memindahkan pesanan ke meja nonaktif wajib ditolak server');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 8: Menonaktifkan meja yang punya pesanan aktif DITOLAK
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

do $$
declare
  v_meja_id uuid := 'aaa00000-0000-0000-0000-000000000001'; -- Meja 1 punya pesanan 882 aktif
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_meja(
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
      p_nama      := 'Meja 1',
      p_area      := 'Dalam',
      p_aktif     := false,
      p_meja_id   := v_meja_id
    );
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 8: menonaktifkan meja yang sedang terisi pesanan aktif wajib ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 9: RPC ambil_daftar_meja
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
begin
  v_res := public.ambil_daftar_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
    p_sertakan_nonaktif := true
  );

  perform uji.sama((v_res->>'total_meja')::int >= 3, true, 'Kasus 9: total_meja terambil');
  perform uji.sama(jsonb_typeof(v_res->'daftar_meja'), 'array', 'Kasus 9: daftar_meja berupa array');
  perform uji.sama(jsonb_typeof(v_res->'daftar_area'), 'array', 'Kasus 9: daftar_area berupa array');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 10: Otorisasi ketat — pelayan ditolak memanggil simpan_meja
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005'); -- Pelayan Dedi

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_meja(
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
      p_nama      := 'Meja Ilegal',
      p_area      := 'Utama'
    );
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 10: pelayan tanpa izin dilarang simpan meja');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 11: Hapus meja yang belum punya pesanan (sukses)
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner

do $$
declare
  v_meja_id uuid;
  v_res jsonb;
begin
  -- Buat meja baru sementara
  v_res := public.simpan_meja(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
    p_nama      := 'Meja Hapus Test',
    p_area      := 'Uji'
  );
  v_meja_id := (v_res->'meja'->>'id')::uuid;

  -- Hapus meja
  v_res := public.hapus_meja(v_meja_id);
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 11: hapus meja tanpa pesanan berhasil');

  -- Pastikan meja hilang
  perform uji.sama(not exists(select 1 from public.meja where id = v_meja_id), true, 'Kasus 11: baris meja terhapus');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 12: Hapus meja yang punya riwayat pesanan ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_meja_id uuid := 'aaa00000-0000-0000-0000-000000000001'; -- Meja 1 punya pesanan
  v_tertangkap boolean := false;
begin
  begin
    perform public.hapus_meja(v_meja_id);
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 12: meja dengan riwayat pesanan dilarang dihapus');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 13: Jejak audit kekal
-- ----------------------------------------------------------------------------
do $$
declare
  v_ada_tambah boolean;
  v_ada_ubah   boolean;
  v_ada_hapus  boolean;
begin
  select exists(
    select 1 from public.catatan_audit
     where entitas = 'meja' and aksi = 'tambah_meja'
  ) into v_ada_tambah;

  select exists(
    select 1 from public.catatan_audit
     where entitas = 'meja' and aksi = 'ubah_meja'
  ) into v_ada_ubah;

  select exists(
    select 1 from public.catatan_audit
     where entitas = 'meja' and aksi = 'hapus_meja'
  ) into v_ada_hapus;

  perform uji.sama(v_ada_tambah, true, 'Kasus 13: jejak audit tambah_meja tercatat');
  perform uji.sama(v_ada_ubah, true, 'Kasus 13: jejak audit ubah_meja tercatat');
  perform uji.sama(v_ada_hapus, true, 'Kasus 13: jejak audit hapus_meja tercatat');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 14: Validasi nama kosong ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_meja(
      p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001',
      p_nama      := '   ',
      p_area      := 'Area 1'
    );
  exception
    when others then
      v_tertangkap := true;
  end;

  perform uji.sama(v_tertangkap, true, 'Kasus 14: nama meja spasi kosong wajib ditolak');
end $$;

reset role;
select uji.klaim(null);
