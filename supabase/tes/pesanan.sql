-- ============================================================================
-- UJI: pesanan & item dengan salinan harga (T1-09, ART-3 & ART-4)
-- Membuktikan yang paling penting: pesanan lama TIDAK berubah artinya walau
-- harga menu diubah kemudian, salinan beku tidak bisa ditulis ulang, nomor
-- unik per cabang per tanggal, kunci idempoten mencegah pesanan ganda, dan
-- pesanan antar-resto/antar-cabang tidak bocor.
-- ============================================================================

-- 1. Sebelum masuk: tidak ada pesanan yang terlihat.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.pesanan), 0::bigint, 'anon tidak melihat pesanan');
select uji.sama((select count(*) from public.pesanan_item), 0::bigint, 'anon tidak melihat item pesanan');
reset role;
select uji.klaim(null);

-- 2. Kasir Pusat membuat pesanan makan di tempat untuk Meja 1.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, meja_id, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 1, current_date, 'dinein',
        'aaa00000-0000-0000-0000-000000000001', 'keranjang-uji-1');

-- Salinan nama & harga WAJIB diisi saat itu (harga Nasi Goreng di Pusat = 27.000).
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 54000);
select uji.sama((select count(*) from public.pesanan), 2::bigint, 'kasir melihat pesanannya sendiri + 1 pesanan data uji di cabangnya');
select uji.sama((select count(*) from public.pesanan_item), 2::bigint, 'item pesanan tersimpan (1 baru + 1 data uji)');
reset role;
select uji.klaim(null);

-- 3. Salinan harga TIDAK boleh kosong (harga_saat_itu WAJIB).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, qty) values ('eeee0000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000002', 'Es Teh', 1)$$,
  'item tanpa harga saat itu ditolak database'
);

-- 4. INTI ART-3: harga menu diubah setelah pesanan dibuat → pesanan lama TIDAK berubah.
reset role;
select uji.klaim(null);
update public.menu_item set harga = 31000 where id = 'beef0000-0000-0000-0000-000000000001';
update public.menu_cabang set harga = 33000
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001' and menu_item_id = 'beef0000-0000-0000-0000-000000000001';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select pi.harga_saat_itu from public.pesanan_item pi where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000001'),
  27000,
  'harga tercatat di pesanan lama tetap 27.000 walau harga menu naik jadi 33.000'
);
select uji.sama(
  public.harga_berlaku('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001'),
  33000,
  'menu yang sama sekarang berharga 33.000 di Pusat (pesanan baru memakai harga baru)'
);

-- 5. Salinan beku tidak bisa ditulis ulang — walau oleh kasir maupun admin.
-- TEMUAN AUDIT A-17/F-06: asersi ini dulu lulus karena pemicu HARGA JUJUR menyala
-- ("Harga menu ini Rp33.000 …"), bukan karena salinan beku dijaga. Sebabnya sekarang
-- diperiksa supaya yang diuji memang penjaga salinan harga.
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set harga_saat_itu = 1000 where pesanan_id = 'eeee0000-0000-0000-0000-000000000001'$$,
  'perlu izin ubah harga',
  'harga yang sudah tercatat tidak boleh diubah tanpa izin ubah harga'
);
select uji.harap_gagal(
  $$update public.pesanan_item set nama_saat_itu = 'Nama Karangan' where pesanan_id = 'eeee0000-0000-0000-0000-000000000001'$$,
  'nama yang sudah tercatat tidak boleh diubah'
);
-- Menghapus memang TIDAK diizinkan sama sekali (bukan sekadar disaring):
-- pesanan hanya boleh dibatalkan supaya jejaknya tetap ada.
select uji.harap_gagal(
  $$delete from public.pesanan_item where pesanan_id = 'eeee0000-0000-0000-0000-000000000001'$$,
  'item pesanan tidak bisa dihapus'
);
select uji.harap_gagal(
  $$delete from public.pesanan where id = 'eeee0000-0000-0000-0000-000000000001'$$,
  'pesanan tidak bisa dihapus'
);
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.pesanan where id = 'eeee0000-0000-0000-0000-000000000001'),
  1::bigint,
  'pesanan tidak bisa dihapus (harus dibatalkan, bukan dihilangkan jejaknya)'
);

-- 6. Nomor pesanan DIBUAT SISTEM (review putaran13 #2 PR-03) dan kunci idempoten
--    mencegah pesanan ganda. Dulu klien boleh memilih nomornya sendiri — pesanan
--    bisa "bernomor sama" di hari berbeda atau nomor dipakai untuk menandai struk
--    palsu. Sekarang angka kiriman klien DIIABAIKAN; uniknya dijaga kunci
--    (cabang_id, tanggal, nomor) di database.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pesanan (penyewa_id, cabang_id, nomor, tanggal, kunci_idempoten)
values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 1, current_date, 'keranjang-lain');
select uji.sama(
  (select p.nomor from public.pesanan p where p.kunci_idempoten = 'keranjang-lain'),
  (select max(x.nomor) from public.pesanan x
    where x.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001' and x.tanggal = current_date),
  'nomor pesanan dibuat sistem (angka kiriman klien = 1 diabaikan, tersimpan nomor urut peladen)'
);
select uji.sama(
  (select p.nomor from public.pesanan p where p.kunci_idempoten = 'keranjang-lain') <> 1,
  true,
  'angka nomor yang DIMINTA klien (1) tidak dipakai — nomor diisi peladen'
);
select uji.sama(
  (select count(*) from (
     select p.nomor from public.pesanan p
      where p.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001' and p.tanggal = current_date
      group by p.nomor having count(*) > 1) ganda),
  0::bigint,
  'tidak ada nomor ganda di cabang & tanggal yang sama'
);
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, nomor, tanggal, kunci_idempoten) values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 2, current_date, 'keranjang-uji-1')$$,
  'kunci idempoten yang sama tidak bisa menyimpan pesanan dua kali'
);

-- 7. Meja cabang lain tidak boleh dipakai; cabang resto lain juga tidak.
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, meja_id, kunci_idempoten) values ('11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 'aaa00000-0000-0000-0000-000000000003', 'keranjang-salah-meja')$$,
  'meja Cabang Dua tidak boleh dipakai pesanan cabang Pusat'
);
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, kunci_idempoten) values ('22222222-2222-2222-2222-222222222222', 'a1a1a1a1-0000-0000-0000-000000000001', 'keranjang-resto-salah')$$,
  'penyewa_id yang tidak sesuai cabangnya ditolak'
);
-- TEMUAN AUDIT A-17/F-06: asersi ini dulu lulus karena pemicu KONSISTENSI PENYEWA
-- ("Cabang dan pesanan harus berada di resto yang sama"), bukan karena policy lingkup
-- cabang. Keduanya penjaga sah, tetapi sebabnya harus disebut supaya tidak menyesatkan.
select uji.harap_gagal_sebab(
  $$insert into public.pesanan (penyewa_id, cabang_id, kunci_idempoten) values ('11111111-1111-1111-1111-111111111111', 'b1b1b1b1-0000-0000-0000-000000000001', 'keranjang-cabang-lain')$$,
  'resto yang sama|cabang',
  'kasir Pusat tidak boleh membuat pesanan di cabang lain'
);
select uji.harap_gagal(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty) values ('eeee0000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000004', 'Mie Ayam', 20000, 1)$$,
  'menu resto lain tidak boleh masuk ke pesanan ini'
);
reset role;
select uji.klaim(null);

-- 8. Dapur boleh memajukan status item (baru → dimasak → siap), kasir boleh
--    membatalkan SATU item tanpa menghapus barisnya.
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur di Cabang Dua
set local role authenticated;
update public.pesanan_item set status = 'dimasak' where pesanan_id = 'eeee0000-0000-0000-0000-000000000001';
reset role;
select uji.klaim(null);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000001'),
  'baru',
  'dapur Cabang Dua tidak bisa mengubah status item pesanan cabang Pusat'
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
update public.pesanan_item set status = 'batal' where pesanan_id = 'eeee0000-0000-0000-0000-000000000001';
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.pesanan_id = 'eeee0000-0000-0000-0000-000000000001'),
  'batal',
  'kasir cabangnya boleh membatalkan item (baris tetap ada)'
);
select uji.harap_gagal(
  $$update public.pesanan set status = 'entah' where id = 'eeee0000-0000-0000-0000-000000000001'$$,
  'status pesanan di luar daftar resmi ditolak'
);
reset role;
select uji.klaim(null);

-- 9. Daftar status resmi = TECH_SPEC §4.3.
select uji.sama(
  (select count(*) from pg_constraint
    where conname = 'pesanan_status_check'
      and pg_get_constraintdef(oid) like '%dimasak%'
      and pg_get_constraintdef(oid) like '%lunas%'),
  1::bigint,
  'daftar status pesanan memuat draf/dikirim/dimasak/siap/lunas/batal'
);

-- 10. Resto & cabang lain tidak melihat pesanan ini.
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto B
set local role authenticated;
select uji.sama((select count(*) from public.pesanan), 0::bigint, 'resto lain tidak melihat pesanan Kedai Oasis');
select uji.sama((select count(*) from public.pesanan_item), 0::bigint, 'resto lain tidak melihat item pesanan Kedai Oasis');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur Cabang Dua
set local role authenticated;
select uji.sama((select count(*) from public.pesanan), 0::bigint, 'cabang lain tidak melihat pesanan cabang Pusat');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner pusat
set local role authenticated;
select uji.sama((select count(*) from public.pesanan), 3::bigint, 'owner pusat melihat pesanan seluruh cabang restonya (3: 1 data uji + 2 buatan kasir)');
reset role;
select uji.klaim(null);
