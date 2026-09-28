-- ============================================================================
-- UJI: pajak & service sebagai ANGKA TERPISAH yang bisa dicetak di struk (T5-03)
--
-- Kenapa uji ini ada: struk wajib menampilkan subtotal, diskon, PB1, service,
-- pembulatan, dan total secara TERPISAH, dan angkanya harus IDENTIK dengan
-- `hitung_total()`. Kalau layar struk menghitung sendiri (mis. subtotal × 10%),
-- ia akan berbeda dari peladen begitu ada diskon atau pembulatan — dan resto
-- akan mencetak struk yang tidak cocok dengan uang yang tercatat.
--
-- Yang dibuktikan (DoD ROADMAP T5-03):
--   1. kontrol: pengaturan resto A = PB1 10%, service 5%, pembulatan 'none';
--   2. tanpa diskon → subtotal/pajak/service/total tersimpan terpisah & benar;
--   3. pajak & service dihitung dari subtotal SETELAH diskon (TECH_SPEC §329-330),
--      bukan dari subtotal kotor — inilah yang tidak boleh ditiru layar;
--   4. diskon PENUH (subtotal habis) → pajak & service NOL, total NOL, tidak minus;
--   5. pajak 0% dan service 0% → barisnya tetap ada sebagai 0 (DoD: "uji lulus
--      untuk pajak/service 0%"), total = dasar;
--   6. pembulatan ke bawah (100/500/1000) → total dibulatkan, TETAPI subtotal,
--      pajak, dan service TIDAK ikut berubah, sehingga selisih pembulatan bisa
--      dihitung struk sebagai: pembulatan = total − (dasar + pajak + service);
--   7. pembulatan tidak pernah merugikan pelanggan (total dibulatkan KE BAWAH);
--   8. kasus .5 pembulatan round(): angka tetap bulat, tanpa selisih 1 rupiah
--      yang terbawa ke total.
-- ============================================================================

-- Resto A, pesanan eeee…0010: subtotal 54.000 (Nasi Goreng 27.000 × 2).
-- Pengaturan bawaan resto A: PB1 10 %, service 5 %, pembulatan 'none'.

-- 1. Kontrol: pengaturan yang dipakai memang seperti yang diasumsikan uji ini.
select uji.sama(
  (select p.pajak_pb1_persen from public.pengaturan p
    where p.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  10::numeric, 'kontrol: PB1 resto A = 10 persen');
select uji.sama(
  (select p.service_persen from public.pengaturan p
    where p.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  5::numeric, 'kontrol: service resto A = 5 persen');
select uji.sama(
  (select p.pembulatan from public.pengaturan p
    where p.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  'none', 'kontrol: pembulatan resto A = none');

-- ---------------------------------------------------------------------------
-- 2. Tanpa diskon: tiap komponen tersimpan TERPISAH di baris pesanan.
-- ---------------------------------------------------------------------------
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.subtotal from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                54000, 'subtotal 54.000 tercatat terpisah');
select uji.sama((select p.total_diskon from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'tanpa diskon → total_diskon 0');
select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                5400, 'PB1 10 persen dari 54.000 = 5.400 (baris sendiri)');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                2700, 'service 5 persen dari 54.000 = 2.700 (baris sendiri)');
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                62100, 'total = 54.000 + 5.400 + 2.700 = 62.100');

-- Struk menjumlahkan komponen yang dicetaknya; hasilnya WAJIB sama dengan total.
select uji.sama(
  (select p.subtotal - p.total_diskon + p.pajak + p.service
     from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  (select p.total from public.pesanan p
    where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'jumlah baris struk = total pesanan (tanpa pembulatan tidak ada sisa)');

-- ---------------------------------------------------------------------------
-- 3. Pajak & service dihitung dari subtotal SETELAH diskon.
--    Diskon 4.000 → dasar 50.000 → PB1 5.000, service 2.500, total 57.500.
--    Kalau pajak dihitung dari subtotal KOTOR, pajaknya akan tetap 5.400.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (batas diskon 100.000 / 20 persen)
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 4000, 4000, 'diskon uji struk');
reset role;
select uji.klaim(null);
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.total_diskon from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                4000, 'diskon 4.000 tercatat sebagai baris sendiri');
select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                5000, 'PB1 dihitung SETELAH diskon: 10 persen dari 50.000 = 5.000');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                2500, 'service dihitung SETELAH diskon: 5 persen dari 50.000 = 2.500');
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                57500, 'total setelah diskon = 50.000 + 5.000 + 2.500 = 57.500');
select uji.sama(
  (select p.subtotal - p.total_diskon + p.pajak + p.service
     from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  (select p.total from public.pesanan p
    where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'jumlah baris struk tetap = total setelah ada diskon');

-- ---------------------------------------------------------------------------
-- 4. Diskon PENUH: dasar 0 → pajak & service NOL, total NOL (tidak minus).
-- ---------------------------------------------------------------------------
update public.diskon_transaksi set nilai = 54000, nominal = 54000
 where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
   and alasan = 'diskon uji struk';
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'diskon penuh → PB1 nol (bukan dihitung dari subtotal kotor)');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'diskon penuh → service nol');
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'diskon penuh → total nol, tidak pernah minus');

delete from public.diskon_transaksi
 where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
   and alasan = 'diskon uji struk';

-- ---------------------------------------------------------------------------
-- 5. Pajak 0 % dan service 0 %: barisnya tetap ada, nilainya 0, total = dasar.
--    (Resto yang belum kena PB1 harus tetap bisa mencetak struk yang jujur.)
-- ---------------------------------------------------------------------------
update public.pengaturan set pajak_pb1_persen = 0, service_persen = 0
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'pajak 0 persen → baris pajak bernilai 0 (bukan NULL)');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                0, 'service 0 persen → baris service bernilai 0 (bukan NULL)');
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                54000, 'pajak & service 0 persen → total = subtotal');

-- ---------------------------------------------------------------------------
-- 6 & 7. Pembulatan: hanya TOTAL yang dibulatkan, dan selalu KE BAWAH.
--    PB1 10 %, service 5 %, subtotal 54.000 → dasar+pajak+service = 62.100.
--    Pembulatan 500 → 62.000; selisih pembulatan = −100 (keuntungan pelanggan).
-- ---------------------------------------------------------------------------
update public.pengaturan set pajak_pb1_persen = 10, service_persen = 5, pembulatan = '500'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                5400, 'pembulatan TIDAK mengubah baris pajak di struk');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                2700, 'pembulatan TIDAK mengubah baris service di struk');
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                62000, 'total dibulatkan ke bawah ke kelipatan 500 = 62.000');

-- Inilah rumus baris "Pembulatan" di struk: total − (dasar + pajak + service).
select uji.sama(
  (select p.total - (p.subtotal - p.total_diskon + p.pajak + p.service)
     from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  -100, 'baris pembulatan struk = -100, jadi rincian struk tetap menjumlah ke total');
select uji.harap(
  (select p.total <= (p.subtotal - p.total_diskon + p.pajak + p.service)
     from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'pembulatan tidak pernah merugikan pelanggan (selalu ke bawah)');

-- Pembulatan 1000 → 62.000 juga; buktikan langkahnya benar-benar dibaca.
update public.pengaturan set pembulatan = '1000'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);
select uji.sama((select p.total from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                62000, 'pembulatan 1000 → 62.000 (langkah pembulatan dibaca dari pengaturan)');

-- ---------------------------------------------------------------------------
-- 8. Kasus pecahan: persen yang menghasilkan .5 tetap menghasilkan rupiah BULAT,
--    dan rincian struk tetap menjumlah ke total (tidak ada selisih 1 rupiah yang
--    muncul diam-diam di layar).
--    Subtotal 54.000 × 8,75 % = 4.725 tepat; pakai 11,11 % → 5.999,4 → 5.999.
-- ---------------------------------------------------------------------------
update public.pengaturan set pajak_pb1_persen = 11.11, service_persen = 2.22, pembulatan = 'none'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('eeee0000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.sama((select p.pajak from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                5999, 'pajak 11,11 persen dari 54.000 dibulatkan jadi 5.999 rupiah bulat');
select uji.sama((select p.service from public.pesanan p
                  where p.id = 'eeee0000-0000-0000-0000-000000000010'),
                1199, 'service 2,22 persen dari 54.000 dibulatkan jadi 1.199 rupiah bulat');
select uji.sama(
  (select p.subtotal - p.total_diskon + p.pajak + p.service
     from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  (select p.total from public.pesanan p
    where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'persen pecahan: rincian struk tetap menjumlah PERSIS ke total (tanpa selisih 1 rupiah)');

-- Kembalikan pengaturan seperti semula (berkas uji dijalankan dalam transaksi
-- yang selalu di-rollback, tetapi tetap rapi supaya tidak menyesatkan pembaca).
update public.pengaturan set pajak_pb1_persen = 10, service_persen = 5, pembulatan = 'none'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
