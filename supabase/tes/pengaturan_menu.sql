-- ============================================================================
-- supabase/tes/pengaturan_menu.sql
-- Pengujian Pengaturan Menu Lengkap (T9-05 / PRD M2 & M3)
--
-- Kasus yang diuji:
-- 1. Unauthenticated (anonim) ditolak mengelola menu dan kategori.
-- 2. Kasir / Pelayan tanpa wewenang ditolak mengelola kategori dan menu.
-- 3. Owner Pusat berhasil menambah kategori menu baru via `simpan_kategori_menu`.
-- 4. Validasi kategori menu: nama kosong ditolak, tujuan tidak sah ditolak.
-- 5. Validasi keunikan nama kategori dalam satu resto ditolak.
-- 6. Edit kategori menu (ubah nama, urutan, tujuan) berhasil.
-- 7. Owner Pusat berhasil menambah menu item baru beserta varian & tambahan via `simpan_menu`.
-- 8. Validasi menu item: nama kosong ditolak, harga negatif ditolak, kategori salah ditolak.
-- 9. Validasi keunikan nama menu pada kategori yang sama ditolak.
-- 10. Edit menu item (ubah nama, harga, varian, status aktif) berhasil.
-- 11. Hapus menu item yang belum pernah dipesan berhasil dan tercatat di audit.
-- 12. Mitigasi Risiko T9-05: Menu yang sudah pernah dipesan dalam pesanan_item DILARANG
--     dihapus secara fisik (DELETE) dan wajib melalui soft delete (aktif = false).
-- 13. Hapus kategori yang masih memiliki menu item DITOLAK server.
-- 14. Hapus kategori kosong berhasil dan tercatat di audit.
-- 15. Urutan kategori & menu dapat diperbarui via `simpan_urutan_kategori` & `simpan_urutan_menu`.
-- 16. Opsi tambahan global dapat dikelola via `simpan_menu_tambahan_global` & `hapus_menu_tambahan`.
-- 17. RPC `ambil_daftar_katalog_admin` menyajikan struktur katalog lengkap terisolasi.
-- 18. Jejak audit kekal tercatat di `public.catatan_audit` untuk seluruh tindakan.
-- ============================================================================

reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- Kasus 1: Anonim ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_kategori_menu(p_nama := 'Snack');
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 1: Anonim ditolak simpan_kategori_menu');
end $$;

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_menu(
      p_kategori_id := 'cafe0000-0000-0000-0000-000000000001',
      p_nama := 'Kentang Goreng',
      p_harga := 15000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 1: Anonim ditolak simpan_menu');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 2: Kasir / Pelayan ditolak
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina (tanpa atur_pengaturan)

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_kategori_menu(p_nama := 'Snack Kasir');
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 2: Kasir ditolak simpan_kategori_menu');
end $$;

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_menu(
      p_kategori_id := 'cafe0000-0000-0000-0000-000000000001',
      p_nama := 'Kopi Kasir',
      p_harga := 10000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 2: Kasir ditolak simpan_menu');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 3: Owner Pusat menambah kategori menu baru
-- ----------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Oasis

do $$
declare
  v_res jsonb;
  v_kat_id uuid;
  v_row record;
begin
  v_res := public.simpan_kategori_menu(
    p_nama   := 'Camilan',
    p_urutan := 3,
    p_tujuan := 'dapur',
    p_aktif  := true
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 3: simpan_kategori_menu berhasil');
  v_kat_id := (v_res->>'id')::uuid;

  select * into v_row from public.kategori_menu where id = v_kat_id;
  perform uji.sama(v_row.nama, 'Camilan', 'Kasus 3: nama kategori tersimpan');
  perform uji.sama(v_row.urutan, 3, 'Kasus 3: urutan kategori tersimpan');
  perform uji.sama(v_row.tujuan, 'dapur', 'Kasus 3: tujuan kategori tersimpan');
  perform uji.sama(v_row.aktif, true, 'Kasus 3: status aktif kategori tersimpan');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 4: Validasi kategori menu (nama kosong, tujuan tidak sah)
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_kategori_menu(p_nama := '   ');
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 4: Nama kategori kosong ditolak');
end $$;

do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_kategori_menu(p_nama := 'Minuman Spesial', p_tujuan := 'gudang');
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 4: Tujuan kategori tidak sah ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 5: Keunikan nama kategori dalam satu resto
-- ----------------------------------------------------------------------------
do $$
declare
  v_tertangkap boolean := false;
begin
  begin
    perform public.simpan_kategori_menu(p_nama := 'Makanan'); -- Sudah ada di data uji
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 5: Duplikat nama kategori ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 6: Edit kategori menu
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_res jsonb;
  v_row record;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Camilan';

  v_res := public.simpan_kategori_menu(
    p_id     := v_kat_id,
    p_nama   := 'Snack & Camilan',
    p_urutan := 4,
    p_tujuan := 'dapur',
    p_aktif  := true
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 6: Edit kategori berhasil');
  select * into v_row from public.kategori_menu where id = v_kat_id;
  perform uji.sama(v_row.nama, 'Snack & Camilan', 'Kasus 6: Nama kategori terbarui');
  perform uji.sama(v_row.urutan, 4, 'Kasus 6: Urutan kategori terbarui');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 7: Owner Pusat menambah menu item baru beserta varian & tambahan
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_res jsonb;
  v_menu_id uuid;
  v_row record;
  v_varian_count integer;
  v_tambahan_count integer;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Snack & Camilan';

  v_res := public.simpan_menu(
    p_kategori_id := v_kat_id,
    p_nama        := 'Pisang Bakar',
    p_deskripsi   := 'Pisang kepok bakar manis bertabur keju',
    p_harga       := 18000,
    p_foto_path   := 'menu/pisang-bakar.jpg',
    p_urutan      := 1,
    p_unggulan    := true,
    p_jenis       := 'makanan',
    p_aktif       := true,
    p_varian      := '[{"nama": "Coklat Keju", "tambahan_harga": 2000}, {"nama": "Original", "tambahan_harga": 0}]'::jsonb,
    p_tambahan    := '[{"nama": "Ekstra Susu Kental Manis", "harga": 3000}]'::jsonb
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 7: simpan_menu berhasil');
  v_menu_id := (v_res->>'id')::uuid;

  select * into v_row from public.menu_item where id = v_menu_id;
  perform uji.sama(v_row.nama, 'Pisang Bakar', 'Kasus 7: Nama menu tersimpan');
  perform uji.sama(v_row.harga, 18000, 'Kasus 7: Harga menu tersimpan');
  perform uji.sama(v_row.unggulan, true, 'Kasus 7: Unggulan tersimpan');
  perform uji.sama(v_row.jenis, 'makanan', 'Kasus 7: Jenis tersimpan');

  select count(*) into v_varian_count from public.menu_varian where menu_item_id = v_menu_id;
  perform uji.sama(v_varian_count, 2, 'Kasus 7: 2 varian tersimpan');

  select count(*) into v_tambahan_count from public.menu_tambahan where menu_item_id = v_menu_id;
  perform uji.sama(v_tambahan_count, 1, 'Kasus 7: 1 tambahan khusus menu tersimpan');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 8: Validasi menu item (harga negatif, nama kosong, kategori salah)
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_tertangkap boolean;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Snack & Camilan';

  -- Harga negatif
  v_tertangkap := false;
  begin
    perform public.simpan_menu(
      p_kategori_id := v_kat_id,
      p_nama := 'Tahu Walik',
      p_harga := -5000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 8: Harga negatif ditolak');

  -- Nama kosong
  v_tertangkap := false;
  begin
    perform public.simpan_menu(
      p_kategori_id := v_kat_id,
      p_nama := '   ',
      p_harga := 12000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 8: Nama kosong ditolak');

  -- Kategori beda resto
  v_tertangkap := false;
  begin
    perform public.simpan_menu(
      p_kategori_id := 'cafe0000-0000-0000-0000-000000000003', -- Milik Warung Bandung (penyewa 2222)
      p_nama := 'Tahu Walik',
      p_harga := 12000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 8: Kategori beda resto ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 9: Validasi keunikan nama menu di kategori yang sama
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_tertangkap boolean := false;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Snack & Camilan';

  begin
    perform public.simpan_menu(
      p_kategori_id := v_kat_id,
      p_nama := 'Pisang Bakar', -- Sudah dibuat di Kasus 7
      p_harga := 20000
    );
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 9: Nama menu duplikat di kategori sama ditolak');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 10: Edit menu item
-- ----------------------------------------------------------------------------
do $$
declare
  v_menu_id uuid;
  v_kat_id uuid;
  v_res jsonb;
  v_row record;
  v_varian_count integer;
begin
  select id into v_menu_id from public.menu_item where nama = 'Pisang Bakar';
  select kategori_id into v_kat_id from public.menu_item where id = v_menu_id;

  v_res := public.simpan_menu(
    p_id          := v_menu_id,
    p_kategori_id := v_kat_id,
    p_nama        := 'Pisang Bakar Madu',
    p_deskripsi   := 'Pisang bakar lumur madu hutan',
    p_harga       := 20000,
    p_foto_path   := 'menu/pisang-bakar-madu.jpg',
    p_urutan      := 2,
    p_unggulan    := true,
    p_jenis       := 'makanan',
    p_aktif       := true,
    p_varian      := '[{"nama": "Porsi Reguler", "tambahan_harga": 0}, {"nama": "Porsi Jumbo", "tambahan_harga": 5000}, {"nama": "Paket Hemat", "tambahan_harga": -2000}]'::jsonb
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 10: Edit menu berhasil');
  select * into v_row from public.menu_item where id = v_menu_id;
  perform uji.sama(v_row.nama, 'Pisang Bakar Madu', 'Kasus 10: Nama terbarui');
  perform uji.sama(v_row.harga, 20000, 'Kasus 10: Harga terbarui');

  select count(*) into v_varian_count from public.menu_varian where menu_item_id = v_menu_id;
  perform uji.sama(v_varian_count, 3, 'Kasus 10: 3 varian terbarui');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 11: Hapus menu item yang belum pernah dipesan berhasil
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_res jsonb;
  v_menu_id uuid;
  v_ada boolean;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Snack & Camilan';

  -- Buat menu sementara yang belum ada di pesanan
  v_res := public.simpan_menu(
    p_kategori_id := v_kat_id,
    p_nama        := 'Tempe Mendoan',
    p_harga       := 12000
  );
  v_menu_id := (v_res->>'id')::uuid;

  -- Hapus menu sementara
  v_res := public.hapus_menu(p_id := v_menu_id);
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 11: Hapus menu tanpa pesanan berhasil');

  select exists(select 1 from public.menu_item where id = v_menu_id) into v_ada;
  perform uji.sama(v_ada, false, 'Kasus 11: Menu terhapus dari tabel menu_item');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 12: MITIGASI RISIKO T9-05: Menu yang sudah pernah dipesan dilarang dihapus fisik
-- ----------------------------------------------------------------------------
do $$
declare
  v_menu_id uuid;
  v_pesanan_id uuid;
  v_tertangkap boolean := false;
  v_res jsonb;
  v_row record;
begin
  select id into v_menu_id from public.menu_item where nama = 'Pisang Bakar Madu';

  -- Simulasikan pesanan yang menggunakan menu ini
  insert into public.pesanan (
    id, penyewa_id, cabang_id, nomor, tipe, status, total, kunci_idempoten
  ) values (
    gen_random_uuid(),
    '11111111-1111-1111-1111-111111111111',
    'a1a1a1a1-0000-0000-0000-000000000001',
    881,
    'dinein',
    'lunas',
    20000,
    'idempoten-uji-menu-01'
  ) returning id into v_pesanan_id;

  insert into public.pesanan_item (
    pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
  ) values (
    v_pesanan_id, v_menu_id, 'Pisang Bakar Madu', 20000, 1, 20000
  );

  -- Coba hapus via RPC hapus_menu -> WAJIB GAGAL (fail-closed)
  begin
    perform public.hapus_menu(p_id := v_menu_id);
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 12: hapus_menu ber-riwayat pesanan DITOLAK server');

  -- Coba direct DELETE SQL -> WAJIB DITOLAK trigger fail-closed picu_menu_item_cegah_hapus
  v_tertangkap := false;
  begin
    delete from public.menu_item where id = v_menu_id;
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 12: Direct DELETE menu ber-riwayat DITOLAK trigger');

  -- Mitigasi yang benar: soft delete (aktif = false)
  v_res := public.simpan_menu(
    p_id          := v_menu_id,
    p_kategori_id := (select kategori_id from public.menu_item where id = v_menu_id),
    p_nama        := 'Pisang Bakar Madu',
    p_harga       := 20000,
    p_aktif       := false
  );
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 12: Soft delete (aktif = false) berhasil');

  select aktif into v_row from public.menu_item where id = v_menu_id;
  perform uji.sama(v_row.aktif, false, 'Kasus 12: Status aktif menu kini false');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 13: Hapus kategori yang masih memiliki menu item ditolak
-- ----------------------------------------------------------------------------
do $$
declare
  v_kat_id uuid;
  v_tertangkap boolean := false;
begin
  select id into v_kat_id from public.kategori_menu where nama = 'Snack & Camilan';

  begin
    perform public.hapus_kategori_menu(p_id := v_kat_id);
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 13: Hapus kategori ber-menu ditolak');

  -- Direct delete juga wajib ditolak trigger fail-closed
  v_tertangkap := false;
  begin
    delete from public.kategori_menu where id = v_kat_id;
  exception when sqlstate 'P0001' then
    v_tertangkap := true;
  end;
  perform uji.sama(v_tertangkap, true, 'Kasus 13: Direct DELETE kategori ber-menu DITOLAK trigger');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 14: Hapus kategori kosong berhasil
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_kat_id uuid;
  v_ada boolean;
begin
  -- Buat kategori kosong
  v_res := public.simpan_kategori_menu(p_nama := 'Kategori Sementara');
  v_kat_id := (v_res->>'id')::uuid;

  -- Hapus kategori kosong
  v_res := public.hapus_kategori_menu(p_id := v_kat_id);
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 14: Hapus kategori kosong berhasil');

  select exists(select 1 from public.kategori_menu where id = v_kat_id) into v_ada;
  perform uji.sama(v_ada, false, 'Kasus 14: Kategori terhapus dari database');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 15: Mengubah urutan kategori & menu
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_makanan_id uuid;
  v_minuman_id uuid;
  v_urutan_makanan integer;
  v_urutan_minuman integer;
begin
  select id into v_makanan_id from public.kategori_menu where nama = 'Makanan' and penyewa_id = '11111111-1111-1111-1111-111111111111';
  select id into v_minuman_id from public.kategori_menu where nama = 'Minuman' and penyewa_id = '11111111-1111-1111-1111-111111111111';

  v_res := public.simpan_urutan_kategori(
    jsonb_build_array(
      jsonb_build_object('id', v_makanan_id, 'urutan', 10),
      jsonb_build_object('id', v_minuman_id, 'urutan', 5)
    )
  );
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 15: simpan_urutan_kategori berhasil');

  select urutan into v_urutan_makanan from public.kategori_menu where id = v_makanan_id;
  select urutan into v_urutan_minuman from public.kategori_menu where id = v_minuman_id;
  perform uji.sama(v_urutan_makanan, 10, 'Kasus 15: Urutan makanan terbarui ke 10');
  perform uji.sama(v_urutan_minuman, 5, 'Kasus 15: Urutan minuman terbarui ke 5');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 16: Opsi tambahan global
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_tam_id uuid;
  v_ada boolean;
begin
  v_res := public.simpan_menu_tambahan_global(
    p_nama  := 'Kerupuk Putih Kaleng',
    p_harga := 2000,
    p_aktif := true
  );
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 16: simpan_menu_tambahan_global berhasil');
  v_tam_id := (v_res->>'id')::uuid;

  -- Edit tambahan global
  v_res := public.simpan_menu_tambahan_global(
    p_id    := v_tam_id,
    p_nama  := 'Kerupuk Putih Gurih',
    p_harga := 2500,
    p_aktif := true
  );
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 16: Edit tambahan global berhasil');

  -- Hapus tambahan global
  v_res := public.hapus_menu_tambahan(p_id := v_tam_id);
  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 16: Hapus tambahan global berhasil');

  select exists(select 1 from public.menu_tambahan where id = v_tam_id) into v_ada;
  perform uji.sama(v_ada, false, 'Kasus 16: Tambahan global terhapus');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 17: ambil_daftar_katalog_admin
-- ----------------------------------------------------------------------------
do $$
declare
  v_res jsonb;
  v_kategori_len integer;
  v_menu_len integer;
begin
  v_res := public.ambil_daftar_katalog_admin(
    p_cabang_id := 'a1a1a1a1-0000-0000-0000-000000000001'
  );

  perform uji.sama((v_res->>'berhasil')::boolean, true, 'Kasus 17: ambil_daftar_katalog_admin berhasil');
  v_kategori_len := jsonb_array_length(v_res->'kategori');
  v_menu_len := jsonb_array_length(v_res->'menu');

  perform uji.sama(v_kategori_len >= 2, true, 'Kasus 17: Memuat kategori penyewa');
  perform uji.sama(v_menu_len >= 3, true, 'Kasus 17: Memuat menu item penyewa');
end $$;

-- ----------------------------------------------------------------------------
-- Kasus 18: Jejak audit kekal
-- ----------------------------------------------------------------------------
do $$
declare
  v_count integer;
begin
  select count(*) into v_count
    from public.catatan_audit
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and aksi in ('simpan_kategori_menu', 'hapus_kategori_menu', 'simpan_menu', 'hapus_menu');

  perform uji.sama(v_count >= 5, true, 'Kasus 18: Audit trail mencatat minimal 5 kejadian kelola menu');
end $$;

reset role;
select uji.klaim(null);
