-- ============================================================================
-- UJI: pembayaran, metode bayar, diskon, pembatalan (T1-10)
-- Membuktikan pagar-pagar uang yang paling penting:
--   * angka uang pesanan tidak bisa dikarang dari perangkat (kasir ditolak,
--     fungsi peladen boleh);
--   * satu pembayaran = satu baris tercatat (tidak dobel, tidak diubah/dihapus);
--   * tunai wajib menyebut uang diterima & kembalian dihitung database;
--     bukan tunai wajib menyebut referensi;
--   * pembayaran tidak boleh melebihi total pesanan;
--   * diskon melebihi batas izin → ditolak; diskon kedua ditolak kecuali resto
--     mengizinkan tumpuk diskon;
--   * pembatalan tanpa alasan → ditolak; tahap harus sesuai; setelah dapur
--     mulai wajib disetujui pengguna berizin; nilai kerugian dari salinan harga.
-- ============================================================================

-- Pesanan uji: eeee…0010 (cabang Pusat, subtotal 54.000, total 62.100, sudah dikirim ke dapur).

-- 1. Sebelum masuk: tidak ada uang yang terlihat.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.pembayaran), 0::bigint, 'anon tidak melihat pembayaran');
select uji.sama((select count(*) from public.diskon_transaksi), 0::bigint, 'anon tidak melihat diskon');
select uji.sama((select count(*) from public.pembatalan), 0::bigint, 'anon tidak melihat pembatalan');
select uji.sama((select count(*) from public.metode_bayar), 0::bigint, 'anon tidak melihat metode bayar');
reset role;
select uji.klaim(null);

-- 2. Metode bayar bawaan tersedia per resto, dan hanya owner/admin yang mengubahnya.
select uji.sama(
  (select count(*) from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  4::bigint,
  'resto punya 4 metode bayar bawaan'
);
select uji.sama(
  (select count(*) from public.metode_bayar where penyewa_id = '22222222-2222-2222-2222-222222222222'),
  4::bigint,
  'resto kedua juga punya metode bayar bawaan (terpasang otomatis)'
);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
select uji.sama((select count(*) from public.metode_bayar), 4::bigint, 'kasir melihat metode bayar restonya');
select uji.harap_gagal(
  $$insert into public.metode_bayar (penyewa_id, nama, jenis) values ('11111111-1111-1111-1111-111111111111', 'Metode Kasir', 'tunai')$$,
  'kasir tidak boleh menambah metode bayar'
);

-- 3. TUNai: uang diterima wajib, kembalian dihitung database.
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'Tunai', 'tunai', 50000, 'bayar-tanpa-diterima')$$,
  'pembayaran tunai tanpa uang diterima ditolak'
);
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'Tunai', 'tunai', 50000, 40000, 'bayar-kurang')$$,
  'uang diterima lebih kecil dari jumlah bayar ditolak'
);
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 'QRIS', 'non_tunai', 10000, 'bayar-tanpa-referensi')$$,
  'pembayaran bukan tunai tanpa referensi ditolak'
);

insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 50000, 100000, 'bayar-1'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';

select uji.sama(
  (select pb.kembalian from public.pembayaran pb where pb.kunci_idempoten = 'bayar-1'),
  50000,
  'kembalian dihitung database (100.000 - 50.000)'
);
select uji.sama(
  (select pb.jenis_saat_itu from public.pembayaran pb where pb.kunci_idempoten = 'bayar-1'),
  'tunai',
  'jenis pembayaran diambil dari metode bayar (bukan dikirim perangkat)'
);

-- 4. Tidak boleh dobel (kunci idempoten sama) & tidak boleh melebihi total pesanan.
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010', null, 50000, 100000, 'bayar-1')$$,
  'pembayaran dengan kunci idempoten sama ditolak (tidak boleh dobel)'
);
reset role;
select uji.klaim(null);

-- Uang yang sudah masuk 50.000, total pesanan 62.100 → baris 20.000 berikutnya
-- akan menjadi 70.000, jadi HARUS ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 20000, 30000, 'bayar-3'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'total pembayaran tidak boleh melebihi total pesanan'
);
select uji.harap_gagal(
  $$update public.pembayaran set jumlah = 1 where kunci_idempoten = 'bayar-1'$$,
  'baris pembayaran tidak bisa diubah'
);
select uji.harap_gagal(
  $$delete from public.pembayaran where kunci_idempoten = 'bayar-1'$$,
  'baris pembayaran tidak bisa dihapus'
);
reset role;
select uji.klaim(null);

-- 5. ANGKA UANG pesanan tidak bisa dikarang dari perangkat.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$update public.pesanan set total = 1 where id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'kasir tidak boleh mengubah total pesanan langsung'
);
reset role;
select uji.klaim(null);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  62100,
  'total pesanan tetap 62.100 setelah percobaan ubah dari kasir'
);

-- Jalur SAH: fungsi peladen (SECURITY DEFINER) boleh mengubah angka uang.
create or replace function public._uji_set_total(p_pesanan_id uuid, p_subtotal integer, p_total integer)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  update public.pesanan set subtotal = p_subtotal, total = p_total where id = p_pesanan_id;
end $$;
select public._uji_set_total('eeee0000-0000-0000-0000-000000000010', 54000, 62100);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  62100,
  'fungsi peladen boleh menetapkan angka uang'
);
-- Percobaan mengarang total harus dijalankan SEBAGAI KASIR (kalau dijalankan
-- sebagai pemilik tabel, penjaga memang tidak berlaku — itu jalur peladen).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, kunci_idempoten, total) values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'pesanan-total-karangan', 5000)$$,
  'pesanan baru dengan total karangan ditolak'
);
reset role;
select uji.klaim(null);

-- 6. DISKON: melebihi batas izin kasir (25.000 / 5%) → ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 30000, 30000, 'minta diskon besar')$$,
  'diskon melebihi batas nominal kasir ditolak'
);
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, persen, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 3000, 20, 3000, 'diskon persen besar')$$,
  'diskon melebihi batas persen kasir ditolak'
);
-- CATATAN: dulu di sini tertulis 20.000 — padahal 20.000 dari subtotal 54.000 = 37 %,
-- jauh di atas batas kasir 5 %. Uji ini LULUS karena sebab yang salah (pemeriksaan persen
-- dilewati saat kolom `persen` kosong — temuan audit AUD-3 K-2/B F-06). Sekarang nilainya
-- 2.000 (3,7 %) supaya benar-benar "diskon dalam batas kasir".
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 2000, 2000, 'pelanggan langganan');
select uji.sama(
  (select count(*) from public.diskon_transaksi where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1::bigint,
  'diskon dalam batas kasir berhasil dicatat'
);

-- Diskon KEDUA: ditolak karena resto belum mengizinkan tumpuk diskon.
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1000, 1000, 'diskon kedua')$$,
  'diskon kedua ditolak saat tumpuk diskon belum diizinkan'
);
reset role;
select uji.klaim(null);

-- Pemilik restoran mengizinkan tumpuk diskon → diskon kedua boleh.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1000, 1000, 'tambahan kecil');
select uji.sama(
  (select count(*) from public.diskon_transaksi where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  2::bigint,
  'diskon kedua boleh setelah owner mengizinkan tumpuk diskon'
);

-- Diskon manual tanpa alasan ditolak; diskon melebihi subtotal ditolak.
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1000, 1000)$$,
  'diskon manual tanpa alasan ditolak'
);
reset role;
select uji.klaim(null);
-- Diskon yang membuat TOTAL diskon melebihi subtotal: diuji sebagai OWNER
-- (tanpa batas nominal), supaya penolakannya benar-benar dari aturan subtotal,
-- bukan dari batas izin kasir. Diskon yang ada: 20.000 + 1.000 = 21.000;
-- ditambah 40.000 menjadi 61.000 > subtotal 54.000 → harus ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 40000, 40000, 'diskon besar melebihi subtotal')$$,
  'total diskon melebihi subtotal pesanan ditolak'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Dapur tidak berizin memberi diskon (walau PIN-nya benar sekalipun).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1000, 1000, 'coba-coba dapur')$$,
  'dapur tidak boleh memberi diskon'
);
reset role;
select uji.klaim(null);

-- 7. PEMBATALAN: tanpa alasan → ditolak; tahap harus sesuai keadaan pesanan.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
-- Alasan kosong diuji dengan TAHAP & PENYETUJU yang sudah benar, supaya
-- penolakannya benar-benar datang dari aturan "wajib beralasan" — bukan dari
-- aturan tahap. (Kekeliruan ini pernah lolos: uji yang lulus karena sebab lain.)
select uji.harap_gagal(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', '   ')$$,
  'pembatalan dengan alasan kosong ditolak walau tahap & penyetujunya sah'
);
-- Pasangan positifnya: kalimat yang sama dengan alasan benar → diterima.
-- SEJAK AUDIT AUD-3 K-2 (A F-03): persetujuan harus TERBUKTI — penyetuju memasukkan
-- PIN-nya sendiri untuk aksi void_sesudah_dapur (bukan sekadar namanya ditulis).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (penyetuju)
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null), 'PIN tersimpan.', 'owner memasang PIN untuk hak menyetujui');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'hp-atasan')).berhasil,
  true, 'PIN penyetuju diverifikasi untuk aksi void_sesudah_dapur'
);
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kembali sebagai kasir
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'alasan benar sebagai pembanding');
select uji.sama(
  (select count(*) from public.pembatalan where alasan = 'alasan benar sebagai pembanding'),
  1::bigint,
  'pembatalan dengan alasan benar diterima (pembanding)'
);
select uji.harap_gagal(
  $$insert into public.pembatalan (pesanan_id, tahap, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'sebelum_dapur', 'salah input')$$,
  'tahap sebelum_dapur ditolak bila pesanan sudah dikirim ke dapur'
);
select uji.harap_gagal(
  $$insert into public.pembatalan (pesanan_id, tahap, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', 'salah input')$$,
  'pembatalan setelah dapur mulai tanpa penyetuju ditolak'
);
select uji.harap_gagal(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan) values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', '90000000-0000-0000-0000-000000000006', 'minta dapur menyetujui')$$,
  'penyetuju tanpa izin void sesudah dapur ditolak'
);

-- Disetujui owner (punya izin) → diterima, dan nilai kerugian dihitung dari salinan harga.
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur', '90000000-0000-0000-0000-000000000002', 'pelanggan membatalkan, makanan sudah dimasak', true);
select uji.sama(
  (select pb.nilai_kerugian from public.pembatalan pb where pb.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' limit 1),
  54000,
  'nilai kerugian dihitung dari salinan subtotal pesanan (54.000)'
);
reset role;
select uji.klaim(null);

-- 8. Isolasi antar resto untuk seluruh tabel uang.
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto B
set local role authenticated;
select uji.sama((select count(*) from public.pembayaran), 0::bigint, 'resto lain tidak melihat pembayaran');
select uji.sama((select count(*) from public.diskon_transaksi), 0::bigint, 'resto lain tidak melihat diskon');
select uji.sama((select count(*) from public.pembatalan), 0::bigint, 'resto lain tidak melihat pembatalan');
select uji.sama((select count(*) from public.metode_bayar), 4::bigint, 'resto lain hanya melihat metode bayarnya sendiri');
reset role;
select uji.klaim(null);
