-- ============================================================================
-- DATA UJI (hanya untuk pengujian lokal & CI — JANGAN dipakai di produksi)
--
-- Dibuat SEBELUM berkas uji dijalankan dan dilakukan sebagai pemilik tabel
-- (melewati RLS), supaya setiap berkas uji bisa langsung memeriksa isolasi.
-- Dipakai ID tetap agar uji mudah dibaca dan hasilnya sama setiap kali.
--
-- Peta data:
--   Penyewa A = "Kedai Oasis"  · cabang A1 (Pusat) & A2 (Cabang Dua)
--   Penyewa B = "Warung Bandung" · cabang B1 (Tunggal)
--   Peran yang diuji: pemilik_platform · owner_pusat · admin_cabang · kasir ·
--                     pelayan (merangkap 2 cabang) · dapur
-- ============================================================================

insert into auth.users (id, email) values
  ('90000000-0000-0000-0000-000000000001', 'platform@contoh.test'),
  ('90000000-0000-0000-0000-000000000002', 'owner.a@contoh.test'),
  ('90000000-0000-0000-0000-000000000003', 'admin.a1@contoh.test'),
  ('90000000-0000-0000-0000-000000000004', 'kasir.a1@contoh.test'),
  ('90000000-0000-0000-0000-000000000005', 'pelayan.a@contoh.test'),
  ('90000000-0000-0000-0000-000000000006', 'dapur.a2@contoh.test'),
  ('90000000-0000-0000-0000-000000000007', 'kasir.b1@contoh.test');

insert into public.penyewa (id, nama, slug, zona_waktu) values
  ('11111111-1111-1111-1111-111111111111', 'Kedai Oasis', 'oasis', 'Asia/Jakarta'),
  ('22222222-2222-2222-2222-222222222222', 'Warung Bandung', 'bandung', 'Asia/Jakarta');

insert into public.cabang (id, penyewa_id, nama, alamat) values
  ('a1a1a1a1-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Pusat', 'Jl. Merdeka 1'),
  ('a1a1a1a1-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Cabang Dua', 'Jl. Asia Afrika 2'),
  ('b1b1b1b1-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Tunggal', 'Jl. Braga 3');

insert into public.pengguna (id, penyewa_id, nama, email, peran) values
  ('90000000-0000-0000-0000-000000000001', null, 'Pemilik Platform', 'platform@contoh.test', 'pemilik_platform'),
  ('90000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Bu Oasis', 'owner.a@contoh.test', 'owner_pusat'),
  ('90000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Pak Andi', 'admin.a1@contoh.test', 'admin_cabang'),
  ('90000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'Rina', 'kasir.a1@contoh.test', 'kasir'),
  ('90000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'Dedi', 'pelayan.a@contoh.test', 'pelayan'),
  ('90000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'Sari', 'dapur.a2@contoh.test', 'dapur'),
  ('90000000-0000-0000-0000-000000000007', '22222222-2222-2222-2222-222222222222', 'Ujang', 'kasir.b1@contoh.test', 'kasir');

-- Dedi (pelayan) merangkap dua cabang; perannya bisa berbeda per cabang.
insert into public.pengguna_cabang (pengguna_id, cabang_id, peran) values
  ('90000000-0000-0000-0000-000000000003', 'a1a1a1a1-0000-0000-0000-000000000001', 'admin_cabang'),
  ('90000000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000001', 'kasir'),
  ('90000000-0000-0000-0000-000000000005', 'a1a1a1a1-0000-0000-0000-000000000001', 'pelayan'),
  ('90000000-0000-0000-0000-000000000005', 'a1a1a1a1-0000-0000-0000-000000000002', 'pelayan'),
  ('90000000-0000-0000-0000-000000000006', 'a1a1a1a1-0000-0000-0000-000000000002', 'dapur'),
  ('90000000-0000-0000-0000-000000000007', 'b1b1b1b1-0000-0000-0000-000000000001', 'kasir');

-- Centang izin (M3): owner & admin lengkap, kasir terbatas, dapur hampir kosong.
insert into public.izin (pengguna_id, kode_izin, boleh, batas_nominal, batas_persen) values
  ('90000000-0000-0000-0000-000000000002', 'lihat_laporan', true, null, null),
  ('90000000-0000-0000-0000-000000000002', 'atur_pengaturan', true, null, null),
  ('90000000-0000-0000-0000-000000000002', 'beri_diskon', true, 100000, 20),
  ('90000000-0000-0000-0000-000000000003', 'beri_diskon', true, 50000, 10),
  ('90000000-0000-0000-0000-000000000003', 'ubah_harga', true, null, null),
  ('90000000-0000-0000-0000-000000000004', 'beri_diskon', true, 25000, 5),
  ('90000000-0000-0000-0000-000000000004', 'void_sebelum_dapur', true, null, null),
  ('90000000-0000-0000-0000-000000000006', 'ubah_stok', true, null, null);

insert into public.pengaturan (penyewa_id, pajak_pb1_persen, service_persen, cara_pesan, header_struk) values
  ('11111111-1111-1111-1111-111111111111', 10, 5, 'campur', 'Kedai Oasis'),
  ('22222222-2222-2222-2222-222222222222', 10, 0, 'kasir', 'Warung Bandung');

-- ---------------------------------------------------------------------------
-- Katalog & stok (dipakai uji T1-07 & uji pesanan)
-- ---------------------------------------------------------------------------
insert into public.kategori_menu (id, penyewa_id, nama, urutan) values
  ('cafe0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Makanan', 1),
  ('cafe0000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Minuman', 2),
  ('cafe0000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'Makanan', 1);

insert into public.menu_item (id, penyewa_id, kategori_id, nama, harga, jenis, unggulan) values
  ('beef0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'cafe0000-0000-0000-0000-000000000001', 'Nasi Goreng', 25000, 'makanan', true),
  ('beef0000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'cafe0000-0000-0000-0000-000000000002', 'Es Teh', 8000, 'minuman', false),
  ('beef0000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'cafe0000-0000-0000-0000-000000000002', 'Kopi', 12000, 'minuman', false),
  ('beef0000-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'cafe0000-0000-0000-0000-000000000003', 'Mie Ayam', 20000, 'makanan', true);

insert into public.menu_varian (menu_item_id, nama, tambahan_harga) values
  ('beef0000-0000-0000-0000-000000000001', 'Reguler', 0),
  ('beef0000-0000-0000-0000-000000000001', 'Jumbo', 5000),
  ('beef0000-0000-0000-0000-000000000002', 'Panas', 0),
  ('beef0000-0000-0000-0000-000000000002', 'Es', 1000);

insert into public.menu_tambahan (id, penyewa_id, menu_item_id, nama, harga) values
  ('fade0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', null, 'Telur Ceplok', 5000),
  ('fade0000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'beef0000-0000-0000-0000-000000000001', 'Kerupuk', 2000);

-- Cabang Pusat: Nasi Goreng lebih mahal; Es Teh ditandai habis.
-- Cabang Dua: Kopi lebih mahal.
insert into public.menu_cabang (cabang_id, menu_item_id, harga, habis) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 27000, false),
  ('a1a1a1a1-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000002', null, true),
  ('a1a1a1a1-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000003', 13000, false);

insert into public.stok_bahan (id, penyewa_id, nama, satuan, minimum, dipantau) values
  ('beef1000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Beras', 'kg', 5, true),
  ('beef1000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Minyak', 'liter', 2, true),
  ('beef1000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'Mie', 'kg', 3, true);

-- Saldo diisi LEWAT buku besar (bukan ditulis langsung) supaya pemicunya ikut terbukti.
insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah, alasan) values
  ('11111111-1111-1111-1111-111111111111', 'beef1000-0000-0000-0000-000000000001', 'masuk', 20, 'stok awal'),
  ('11111111-1111-1111-1111-111111111111', 'beef1000-0000-0000-0000-000000000002', 'masuk', 5, 'stok awal'),
  ('22222222-2222-2222-2222-222222222222', 'beef1000-0000-0000-0000-000000000003', 'masuk', 10, 'stok awal');

-- ---------------------------------------------------------------------------
-- Meja (dipakai uji T1-08 & uji pesanan)
-- ---------------------------------------------------------------------------
insert into public.meja (id, cabang_id, nama, area, status) values
  ('aaa00000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001', 'Meja 1', 'Dalam', 'kosong'),
  ('aaa00000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001', 'Meja 2', 'Teras', 'terisi'),
  ('aaa00000-0000-0000-0000-000000000003', 'a1a1a1a1-0000-0000-0000-000000000002', 'Meja 1', 'Dalam', 'kosong'),
  ('aaa00000-0000-0000-0000-000000000004', 'b1b1b1b1-0000-0000-0000-000000000001', 'Meja 1', null, 'kosong');

-- ---------------------------------------------------------------------------
-- Uang: satu pesanan contoh dengan SALINAN harga & total dari "peladen"
-- (data uji berjalan sebagai pemilik tabel, jadi penjaga angka uang tidak berlaku)
-- ---------------------------------------------------------------------------
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, meja_id,
                            status, subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 10, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'dikirim',
        54000, 5400, 2700, 62100, 'keranjang-uji-uang');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = 'eeee0000-0000-0000-0000-000000000010';

insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000010', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 54000);

