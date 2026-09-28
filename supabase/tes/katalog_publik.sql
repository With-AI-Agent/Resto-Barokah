-- ============================================================================
-- TES KATALOG PUBLIK (T8-01 / ART-10, ART-1)
--
-- Memverifikasi:
--  1. Anon (pelanggan umum tanpa login) dapat mengakses katalog_publik via slug resto.
--  2. Respon memuat nama resto, jam buka, cabang, kategori, dan menu.
--  3. Menu habis per cabang dihormati (habis: true di cabang bersangkutan).
--  4. Harga khusus per cabang dihormati bila disetel.
--  5. Validasi kegagalan untuk slug tidak ditemukan / cabang tidak valid.
--  6. TIDAK ADA kolom sensitif pegawai, keuangan, pelanggan, atau token rahasia.
-- ============================================================================

begin;

-- Siapkan data uji khusus
do $$
declare
  v_penyewa_id uuid;
  v_cabang_a   uuid;
  v_cabang_b   uuid;
  v_kat_id     uuid;
  v_menu_1     uuid;
  v_menu_2     uuid;
  v_res        jsonb;
  v_teks       text;
begin
  -- 1. Buat penyewa khusus katalog
  insert into public.penyewa (nama, slug, status, zona_waktu, mata_uang)
  values ('Warung Barokah Sedap', 'barokah-sedap', 'aktif', 'Asia/Jakarta', 'IDR')
  returning id into v_penyewa_id;

  -- Buat penyewa nonaktif untuk memastikan penolakan
  insert into public.penyewa (nama, slug, status, zona_waktu, mata_uang)
  values ('Warung Tutup Permanen', 'barokah-tutup', 'nonaktif', 'Asia/Jakarta', 'IDR');

  -- Pengaturan jam buka & cara pesan
  insert into public.pengaturan (penyewa_id, jam_buka, cara_pesan)
  values (v_penyewa_id, '10:00 - 22:00 WIB', 'meja')
  on conflict (penyewa_id) do update
    set jam_buka = excluded.jam_buka, cara_pesan = excluded.cara_pesan;

  -- 2. Buat dua cabang
  insert into public.cabang (penyewa_id, nama, alamat, telepon, aktif)
  values (v_penyewa_id, 'Cabang Dago', 'Jl. Dago No. 10', '081234567890', true)
  returning id into v_cabang_a;

  insert into public.cabang (penyewa_id, nama, alamat, telepon, aktif)
  values (v_penyewa_id, 'Cabang Riau', 'Jl. Riau No. 20', '081234567891', true)
  returning id into v_cabang_b;

  -- 3. Buat kategori menu
  insert into public.kategori_menu (penyewa_id, nama, urutan, aktif)
  values (v_penyewa_id, 'Makanan Utama', 1, true)
  returning id into v_kat_id;

  -- 4. Buat menu item
  insert into public.menu_item (penyewa_id, kategori_id, nama, deskripsi, harga, foto_path, urutan, unggulan, jenis, aktif)
  values (v_penyewa_id, v_kat_id, 'Ayam Geprek Barokah', 'Ayam krispi sambal bawang', 25000, 'foto/geprek.jpg', 1, true, 'makanan', true)
  returning id into v_menu_1;

  insert into public.menu_item (penyewa_id, kategori_id, nama, deskripsi, harga, foto_path, urutan, unggulan, jenis, aktif)
  values (v_penyewa_id, v_kat_id, 'Bebek Goreng Sambal Ijo', 'Bebek empuk bumbu rempah', 35000, 'foto/bebek.jpg', 2, false, 'makanan', true)
  returning id into v_menu_2;

  -- Varian untuk menu 1
  insert into public.menu_varian (menu_item_id, nama, tambahan_harga, aktif)
  values (v_menu_1, 'Level 1 Pedas', 0, true),
         (v_menu_1, 'Level 5 Super', 2000, true);

  -- Tambahan untuk menu 1
  insert into public.menu_tambahan (penyewa_id, menu_item_id, nama, harga, aktif)
  values (v_penyewa_id, v_menu_1, 'Ekstra Tahu Tempe', 5000, true);

  -- 5. Set status cabang: di Cabang A bebek habis & ayam harga khusus 27.000
  insert into public.menu_cabang (cabang_id, menu_item_id, harga, aktif, habis)
  values (v_cabang_a, v_menu_1, 27000, true, false),
         (v_cabang_a, v_menu_2, null, true, true); -- Bebek habis di Cabang A

  -- Beralih ke peran anon (pelanggan publik tanpa login)
  set local role anon;
  set local "request.jwt.claims" to '{}';

  -- Uji 1: Panggil katalog publik tanpa cabang
  v_res := public.katalog_publik('barokah-sedap');
  assert (v_res->>'berhasil')::boolean = true, 'Katalog publik wajib berhasil untuk slug yang sah';
  assert v_res->'resto'->>'nama' = 'Warung Barokah Sedap', 'Nama resto harus sesuai';
  assert v_res->'resto'->>'jam_buka' = '10:00 - 22:00 WIB', 'Jam buka harus tampil';
  assert jsonb_array_length(v_res->'daftar_cabang') = 2, 'Harus memuat 2 cabang aktif';
  assert jsonb_array_length(v_res->'kategori') = 1, 'Harus memuat 1 kategori aktif';
  assert jsonb_array_length(v_res->'menu') = 2, 'Harus memuat 2 menu item';

  -- Uji 2: Panggil katalog publik untuk Cabang A (khusus penanda habis & harga cabang)
  v_res := public.katalog_publik('barokah-sedap', v_cabang_a);
  assert (v_res->>'berhasil')::boolean = true, 'Katalog cabang A wajib berhasil';
  assert (v_res->>'cabang_terpilih')::uuid = v_cabang_a, 'Cabang terpilih harus cabang A';

  -- Verifikasi harga khusus Cabang A (27000) dan status habis
  assert (v_res->'menu'->0->>'harga')::int = 27000, 'Harga ayam di cabang A harus 27000';
  assert (v_res->'menu'->0->>'habis')::boolean = false, 'Ayam di cabang A tidak habis';
  assert (v_res->'menu'->1->>'harga')::int = 35000, 'Harga bebek harus tetap harga pusat 35000';
  assert (v_res->'menu'->1->>'habis')::boolean = true, 'Bebek di cabang A wajib berstatus habis: true';

  -- Verifikasi varian dan tambahan muncul pada menu 1
  assert jsonb_array_length(v_res->'menu'->0->'varian') = 2, 'Ayam harus punya 2 varian';
  assert jsonb_array_length(v_res->'menu'->0->'tambahan') = 1, 'Ayam harus punya 1 tambahan';

  -- Uji 3: Panggil katalog publik untuk Cabang B (bebek tidak habis di Cabang B)
  v_res := public.katalog_publik('barokah-sedap', v_cabang_b);
  assert (v_res->'menu'->1->>'habis')::boolean = false, 'Bebek di cabang B tidak boleh habis';
  assert (v_res->'menu'->0->>'harga')::int = 25000, 'Harga ayam di cabang B harus harga pusat 25000';

  -- Uji 4: Validasi penolakan slug tidak ada atau cabang tidak valid
  v_res := public.katalog_publik('barokah-tutup');
  assert (v_res->>'berhasil')::boolean = false, 'Resto nonaktif wajib ditolak';
  assert v_res->>'kode' = 'RESTO_TIDAK_DITEMUKAN', 'Kode resto nonaktif harus RESTO_TIDAK_DITEMUKAN';

  v_res := public.katalog_publik('resto-fiktif-12345');
  assert (v_res->>'berhasil')::boolean = false, 'Slug fiktif harus gagal';
  assert v_res->>'kode' = 'RESTO_TIDAK_DITEMUKAN', 'Kode harus RESTO_TIDAK_DITEMUKAN';

  v_res := public.katalog_publik('');
  assert (v_res->>'berhasil')::boolean = false, 'Slug kosong harus gagal';
  assert v_res->>'kode' = 'SLUG_WAJIB', 'Kode harus SLUG_WAJIB';

  v_res := public.katalog_publik('barokah-sedap', gen_random_uuid());
  assert (v_res->>'berhasil')::boolean = false, 'Cabang asing harus gagal';
  assert v_res->>'kode' = 'CABANG_TIDAK_VALID', 'Kode harus CABANG_TIDAK_VALID';

  -- Uji 5: Verifikasi pencegahan kebocoran data sensitif (ART-10)
  v_res := public.katalog_publik('barokah-sedap', v_cabang_a);
  v_teks := lower(v_res::text);

  assert v_teks not like '%email%', 'Katalog publik dilarang memuat kata email';
  assert v_teks not like '%pin%', 'Katalog publik dilarang memuat kata pin';
  assert v_teks not like '%kata_sandi%', 'Katalog publik dilarang memuat kata sandi';
  assert v_teks not like '%kunci_hash%', 'Katalog publik dilarang memuat kunci rahasia';
  assert v_teks not like '%modal_awal%', 'Katalog publik dilarang memuat modal keuangan';
  assert v_teks not like '%omzet%', 'Katalog publik dilarang memuat data omzet';
  assert v_teks not like '%saldo%', 'Katalog publik dilarang memuat saldo buku besar';
  assert v_teks not like '%audit%', 'Katalog publik dilarang memuat jejak audit';

end $$;

rollback;
