-- ============================================================================
-- UJI: katalog (kategori, menu, varian, tambahan, harga per cabang) & stok (T1-07)
-- Membuktikan: harga berbeda per cabang benar-benar berlaku (dan jatuh ke harga
-- pusat bila tidak diatur), katalog & stok terpisah rapi antar-resto, hanya yang
-- berhak boleh mengubah harga, dan angka stok tidak bisa menyimpang dari buku
-- besarnya.
-- ============================================================================

-- 1. Sebelum masuk: tidak ada satu baris pun katalog/stok yang terlihat.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.kategori_menu), 0::bigint, 'anon tidak melihat kategori');
select uji.sama((select count(*) from public.menu_item), 0::bigint, 'anon tidak melihat menu');
select uji.sama((select count(*) from public.menu_varian), 0::bigint, 'anon tidak melihat varian');
select uji.sama((select count(*) from public.menu_tambahan), 0::bigint, 'anon tidak melihat tambahan');
select uji.sama((select count(*) from public.menu_cabang), 0::bigint, 'anon tidak melihat harga cabang');
select uji.sama((select count(*) from public.stok_bahan), 0::bigint, 'anon tidak melihat bahan stok');
select uji.sama((select count(*) from public.stok_pergerakan), 0::bigint, 'anon tidak melihat buku besar stok');
reset role;
select uji.klaim(null);

-- 2. Kasir Kedai Oasis melihat katalog restonya, BUKAN katalog resto lain.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select count(*) from public.kategori_menu), 2::bigint, 'kasir A melihat 2 kategori');
select uji.sama((select count(*) from public.menu_item), 3::bigint, 'kasir A melihat 3 menu');
select uji.sama((select count(*) from public.menu_varian), 4::bigint, 'kasir A melihat 4 varian');
select uji.sama((select count(*) from public.menu_tambahan), 2::bigint, 'kasir A melihat 2 tambahan');
select uji.sama((select count(*) from public.menu_cabang), 2::bigint, 'kasir A melihat 2 baris harga cabang (hanya cabang tempatnya bertugas)');
select uji.sama(
  (select count(*) from public.menu_cabang where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'),
  0::bigint,
  'kasir Pusat tidak melihat harga cabang lain'
);
select uji.sama((select count(*) from public.stok_bahan), 2::bigint, 'kasir A melihat 2 bahan');
select uji.harap(
  (select count(*) from public.menu_item where penyewa_id = '22222222-2222-2222-2222-222222222222') = 0,
  'menu resto lain TIDAK terlihat'
);
select uji.harap(
  (select count(*) from public.stok_pergerakan where penyewa_id = '22222222-2222-2222-2222-222222222222') = 0,
  'buku besar stok resto lain TIDAK terlihat'
);

-- 3. HARGA PER CABANG: harga khusus menang; kalau tidak diatur → harga pusat.
select uji.sama(public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001'), 27000, 'Nasi Goreng di Pusat memakai harga cabang (27.000)');
select uji.sama(public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'), 25000, 'Nasi Goreng di Cabang Dua memakai harga pusat (25.000)');
select uji.sama(public.harga_berlaku('beef0000-0000-0000-0000-000000000003', 'a1a1a1a1-0000-0000-0000-000000000002'), 13000, 'Kopi di Cabang Dua memakai harga cabang (13.000)');
select uji.sama(public.harga_berlaku('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001'), 8000, 'Es Teh di Pusat memakai harga pusat karena barisnya tidak berharga');
select uji.sama(public.harga_berlaku('beef0000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000001'), null, 'menu resto lain tidak bisa diintip lewat harga_berlaku');

-- 4. Penanda habis hanya berlaku di cabang yang menandainya.
select uji.sama(public.menu_habis('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001'), true, 'Es Teh habis di Pusat');
select uji.sama(public.menu_habis('beef0000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000002'), false, 'Es Teh TIDAK habis di Cabang Dua');
select uji.sama(public.menu_habis('beef0000-0000-0000-0000-000000000004', 'a1a1a1a1-0000-0000-0000-000000000001'), false, 'menu resto lain tidak dianggap habis');

-- 5. Kasir tidak boleh mengubah katalog (bukan haknya).
select uji.harap_gagal(
  $$insert into public.menu_item (penyewa_id, kategori_id, nama, harga, jenis) values ('11111111-1111-1111-1111-111111111111', 'cafe0000-0000-0000-0000-000000000001', 'Menu Kasir', 10000, 'makanan')$$,
  'kasir tidak boleh menambah menu'
);
select uji.harap_gagal(
  $$insert into public.stok_bahan (penyewa_id, nama, satuan) values ('11111111-1111-1111-1111-111111111111', 'Bahan Kasir', 'kg')$$,
  'kasir tidak boleh menambah bahan stok'
);

-- Untuk update, RLS MENYARING (bukan melempar error): buktinya = tidak ada baris
-- yang berubah. Dibandingkan dengan membaca ulang sebagai pemilik tabel.
update public.menu_item set harga = 1 where id = 'beef0000-0000-0000-0000-000000000001';
reset role;
select uji.klaim(null);
select uji.sama(
  (select mi.harga from public.menu_item mi where mi.id = 'beef0000-0000-0000-0000-000000000001'),
  25000,
  'kasir tidak bisa mengubah harga menu (harga tetap 25.000)'
);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 6. Admin cabang boleh mengubah katalog restonya, tetapi tidak bisa mencicil ke resto lain.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
insert into public.menu_item (penyewa_id, kategori_id, nama, harga, jenis)
values ('11111111-1111-1111-1111-111111111111', 'cafe0000-0000-0000-0000-000000000001', 'Sate Ayam', 22000, 'makanan');
select uji.sama((select count(*) from public.menu_item), 4::bigint, 'admin cabang berhasil menambah menu');
select uji.harap_gagal(
  $$insert into public.menu_item (penyewa_id, kategori_id, nama, harga, jenis) values ('22222222-2222-2222-2222-222222222222', 'cafe0000-0000-0000-0000-000000000001', 'Sisipan', 5000, 'makanan')$$,
  'menu tidak bisa disisipkan ke resto lain'
);
select uji.harap_gagal(
  $$insert into public.menu_cabang (cabang_id, menu_item_id, harga) values ('b1b1b1b1-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 99000)$$,
  'harga cabang tidak bisa dipasang di cabang resto lain'
);
reset role;
select uji.klaim(null);

-- 7. Penanda "habis" = tugas harian (izin ubah_stok), mengubah HARGA tetap terbatas.
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- Sarif, dapur di Cabang Dua
set local role authenticated;
insert into public.menu_cabang (cabang_id, menu_item_id, habis)
values ('a1a1a1a1-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000001', true);
select uji.sama(
  public.menu_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'),
  true,
  'dapur ber-izin ubah_stok boleh menandai menu habis di cabangnya'
);
select uji.harap_gagal(
  $$insert into public.menu_cabang (cabang_id, menu_item_id, harga) values ('a1a1a1a1-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000002', 5000)$$,
  'dapur TIDAK boleh menetapkan harga cabang saat menyisipkan baris baru'
);
select uji.harap_gagal(
  $$update public.menu_cabang set harga = 1000 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002' and menu_item_id = 'beef0000-0000-0000-0000-000000000003'$$,
  'dapur TIDAK boleh mengubah harga cabang'
);
reset role;
select uji.klaim(null);

-- Admin cabang Pusat TIDAK boleh mengubah harga cabang lain (bukan cabangnya).
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
update public.menu_cabang set harga = 14000
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002' and menu_item_id = 'beef0000-0000-0000-0000-000000000003';
select uji.sama((select count(*) from public.menu_cabang), 2::bigint, 'admin Pusat hanya melihat harga 2 baris cabangnya');
reset role;
-- Dibaca sebagai kasir Pusat (harga_berlaku selalu dinilai milik resto pengguna
-- yang sedang masuk — jadi harus ada yang masuk untuk mengukur akibatnya).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000003', 'a1a1a1a1-0000-0000-0000-000000000002'),
  13000,
  'harga cabang lain TIDAK berubah oleh admin cabang Pusat'
);
reset role;
select uji.klaim(null);

-- Owner pusat boleh mengurus seluruh cabang restonya (13.000 → 14.000).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select count(*) from public.menu_cabang),
  4::bigint,
  'owner pusat melihat harga di semua cabang restonya (3 baris data uji + 1 baris yang tadi disisipkan dapur)'
);
update public.menu_cabang set harga = 14000
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002' and menu_item_id = 'beef0000-0000-0000-0000-000000000003';
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000003', 'a1a1a1a1-0000-0000-0000-000000000002'),
  14000,
  'owner pusat boleh mengubah harga cabang (13.000 → 14.000)'
);

-- 8. STOK: saldo hanya berubah lewat buku besar.
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur, punya izin ubah_stok
set local role authenticated;
select uji.sama(
  (select b.jumlah from public.stok_bahan b where b.id = 'beef1000-0000-0000-0000-000000000001'),
  20::numeric,
  'saldo awal Beras 20 kg (diisi lewat buku besar pada data uji)'
);
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'keluar', -3, 'dipakai memasak'),
  17::numeric,
  'catat keluar 3 kg → saldo 17 kg'
);
select uji.sama(
  public.catat_stok('beef1000-0000-0000-0000-000000000001', 'opname', -2, 'hitung ulang, ada yang tumpah'),
  15::numeric,
  'opname mengurangi selisih 2 kg → saldo 15 kg'
);
select uji.harap_gagal(
  $$select public.catat_stok('beef1000-0000-0000-0000-000000000001', 'koreksi', 1, null)$$,
  'koreksi tanpa alasan ditolak'
);
select uji.harap_gagal(
  $$update public.stok_bahan set jumlah = 999 where id = 'beef1000-0000-0000-0000-000000000001'$$,
  'saldo stok TIDAK boleh ditulis langsung (harus lewat buku besar)'
);
update public.stok_bahan set minimum = 4 where id = 'beef1000-0000-0000-0000-000000000001';
select uji.sama(
  (select b.minimum from public.stok_bahan b where b.id = 'beef1000-0000-0000-0000-000000000001'),
  4::numeric,
  'yang berizin ubah_stok boleh mengubah batas minimum (bukan saldonya)'
);
reset role;
select uji.klaim(null);

-- 9. Buku besar stok: hanya bisa bertambah, tidak bisa diubah/dihapus.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
-- Buku besar bersifat hanya-bertambah: hak ubah & hapus MEMANG tidak diberikan,
-- jadi perintahnya ditolak langsung (bukan disaring diam-diam).
select uji.harap_gagal(
  $$update public.stok_pergerakan set jumlah = 999 where stok_bahan_id = 'beef1000-0000-0000-0000-000000000001'$$,
  'buku besar stok tidak bisa diubah'
);
select uji.harap_gagal(
  $$delete from public.stok_pergerakan where stok_bahan_id = 'beef1000-0000-0000-0000-000000000001'$$,
  'buku besar stok tidak bisa dihapus'
);
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.stok_pergerakan where stok_bahan_id = 'beef1000-0000-0000-0000-000000000001'),
  3::bigint,
  'buku besar stok tetap 3 baris (ubah & hapus tidak berpengaruh)'
);
select uji.harap(
  not exists (select 1 from public.stok_pergerakan where jumlah = 999),
  'tidak ada baris buku besar yang berubah nilainya'
);

-- 10. Buku besar tidak bisa dicicil ke bahan resto lain (dan penyewa_id tidak bisa dipalsukan).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah) values ('11111111-1111-1111-1111-111111111111', 'beef1000-0000-0000-0000-000000000003', 'masuk', 5)$$,
  'tidak boleh mencatat pergerakan untuk bahan resto lain'
);
select uji.harap_gagal(
  $$insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah) values ('22222222-2222-2222-2222-222222222222', 'beef1000-0000-0000-0000-000000000001', 'masuk', 5)$$,
  'penyewa_id yang dipalsukan ditolak tegas'
);
-- Dan bila klien tidak mengirim penyewa_id sama sekali, diisi otomatis dari bahannya.
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan) values ('beef1000-0000-0000-0000-000000000002', 'masuk', 2, 'titipan supplier');
reset role;
select uji.sama(
  (select sp.penyewa_id from public.stok_pergerakan sp
    where sp.stok_bahan_id = 'beef1000-0000-0000-0000-000000000002' and sp.alasan = 'titipan supplier'),
  '11111111-1111-1111-1111-111111111111'::uuid,
  'penyewa_id catatan stok diisi otomatis dari bahannya'
);
select uji.sama(
  (select b.jumlah from public.stok_bahan b where b.id = 'beef1000-0000-0000-0000-000000000002'),
  7::numeric,
  'saldo Minyak ikut bertambah lewat buku besar (5 + 2)'
);
select uji.klaim(null);

-- 11. Kasir (tanpa izin ubah_stok) tidak bisa mencatat pergerakan stok.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$select public.catat_stok('beef1000-0000-0000-0000-000000000001', 'masuk', 5, 'titipan')$$,
  'kasir tanpa izin ubah_stok tidak boleh mencatat stok'
);
reset role;
select uji.klaim(null);

-- 12. Tambahan yang menempel ke menu wajib satu resto dengan menunya.
select uji.klaim(null);
select uji.harap_gagal(
  $$insert into public.menu_tambahan (penyewa_id, menu_item_id, nama, harga) values ('11111111-1111-1111-1111-111111111111', 'beef0000-0000-0000-0000-000000000004', 'Sambal', 1000)$$,
  'tambahan tidak boleh menempel ke menu resto lain'
);

-- 13. Resto lain tidak melihat apa pun dari katalog Kedai Oasis.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.menu_item), 1::bigint, 'kasir resto B melihat 1 menu (miliknya sendiri)');
select uji.sama((select count(*) from public.kategori_menu), 1::bigint, 'kasir resto B melihat 1 kategori (miliknya sendiri)');
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001'),
  null,
  'harga menu Kedai Oasis tidak bisa diintip resto lain'
);
reset role;
select uji.klaim(null);
