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
