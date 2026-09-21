-- ============================================================================
-- UJI: ALUR UANG HIDUP — angka uang dihitung PELADEN (hitung_total)
-- Menutup temuan audit AUD-3 2026-09-18 F-01 (K-1): pesanan buatan klien selalu
-- bertotal 0, kasir dilarang membetulkan, dan pembayaran yang benar DITOLAK —
-- jadi uang tidak pernah bisa dicatat. Keputusan terkunci 2026-09-16
-- ("uang dihitung di peladen, satu fungsi hitung_total") kini benar-benar ada.
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

-- 1. Pesanan lahir dengan angka 0 (klien tidak boleh mengisi angka uang).
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, meja_id, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f001','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001','dinein','aaa00000-0000-0000-0000-000000000002','uang-peladen');
select uji.sama(
  (select p.total from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f001'),
  0, 'pesanan baru lahir bertotal 0 (angka diisi peladen, bukan klien)'
);

-- 2. Tambah 2 Nasi Goreng @27.000 → header MENGIKUTI item tanpa dipanggil manual.
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
values ('00000000-0000-0000-0000-00000000f001','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2);
select uji.sama(
  (select p.subtotal from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f001'),
  54000, 'subtotal header = 54.000 setelah 2 item (dulu tetap 0)'
);
select uji.sama(
  (select p.pajak from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f001'),
  5400, 'PB1 10% dihitung dari pengaturan resto'
);
select uji.sama(
  (select p.service from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f001'),
  2700, 'service 5% dihitung dari pengaturan resto'
);
select uji.sama(
  (select p.total from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f001'),
  62100, 'total = 54.000 + 5.400 + 2.700 = 62.100'
);

-- 3. KASIR TETAP TIDAK BOLEH menulis angka uang langsung (penjaga 0010 hidup).
select uji.harap_gagal_sebab($$update public.pesanan set total = 1 where id = '00000000-0000-0000-0000-00000000f001'$$, 'Angka uang pesanan hanya boleh diubah oleh fungsi perhitungan peladen \(hitung_total\)', 'kasir masih dilarang mengarang angka uang pesanan');

-- 4. UANG BISA DICATAT (inti perbaikan): bayar tunai 62.100 dari pesanan itu.
insert into public.pembayaran (pesanan_id, kasir_id, metode_id, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f001','90000000-0000-0000-0000-000000000004',
        (select m.id from public.metode_bayar m
          where m.penyewa_id = '11111111-1111-1111-1111-111111111111' and m.jenis = 'tunai' limit 1),
        62100, 100000, 'uang-peladen-bayar');
select uji.sama(
  (select count(*) from public.pembayaran pb where pb.pesanan_id = '00000000-0000-0000-0000-00000000f001'),
  1::bigint, 'pembayaran Rp62.100 DITERIMA — alur kasir bisa selesai (dulu buntu)'
);
select uji.sama(
  (select pb.kembalian from public.pembayaran pb where pb.kunci_idempoten = 'uang-peladen-bayar'),
  37900, 'kembalian dihitung peladen: 100.000 − 62.100 = 37.900'
);

-- 5. T-025(a): void sesudah bayar kini DITOLAK; tagihan dan uang tetap selaras.
select uji.harap_gagal_sebab(
 $$insert into public.pembatalan(pesanan_id,tahap,alasan)
 values ('00000000-0000-0000-0000-00000000f001','sebelum_dapur','sesudah bayar')$$,
 'BY-201', 'void sesudah bayar ditolak meskipun lewat jalur resmi');
select uji.sama((select total from public.pesanan where id='00000000-0000-0000-0000-00000000f001'),
 62100, 'tagihan yang dibayar tidak turun menjadi nol');
-- Kontrol perhitungan void SEBELUM bayar tetap diuji pada pesanan terpisah.
insert into public.pesanan(id,penyewa_id,cabang_id,kunci_idempoten)
values('00000000-0000-0000-0000-00000000f002','11111111-1111-1111-1111-111111111111',
 'a1a1a1a1-0000-0000-0000-000000000001','uang-peladen-void');
insert into public.pesanan_item(pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
values('00000000-0000-0000-0000-00000000f002','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2);
insert into public.pembatalan(pesanan_id,tahap,alasan)
values('00000000-0000-0000-0000-00000000f002','sebelum_dapur','sebelum bayar');
select uji.sama((select total from public.pesanan where id='00000000-0000-0000-0000-00000000f002'),
 0, 'void sebelum bayar menghitung ulang ke nol');

reset role;
select uji.klaim(null);

-- 6. Fungsi hitung_total memang ada dan boleh dipanggil pemilik pesanan.
select uji.sama(
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'hitung_total'),
  1::bigint, 'fungsi peladen hitung_total ADA (keputusan terkunci 2026-09-16)'
);
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto LAIN
set local role authenticated;
select uji.harap_gagal_sebab($$select public.hitung_total('00000000-0000-0000-0000-00000000f001')$$, 'Pesanan itu bukan milik resto Anda', 'kasir resto lain TIDAK boleh menghitung pesanan resto ini (isolasi lintas penyewa)');
reset role;
select uji.klaim(null);
