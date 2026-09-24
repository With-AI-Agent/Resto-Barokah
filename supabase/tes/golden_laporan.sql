-- ============================================================================
-- UJI GOLDEN: Laporan = Data Mentah (T7-12 · TECH_SPEC §11)
--
-- Tujuan:
--   Membuktikan secara matematis dan deterministik bahwa seluruh angka laporan
--   (omzet, subtotal, pajak, service, diskon, rincian metode pembayaran,
--   kategori menu, pembatalan/kerugian bahan, dan rekonsiliasi kas shift)
--   SAMA PERSIS (selisih = 0) dengan hasil kalkulasi langsung dari tabel
--   data mentah transaksi untuk 1 hari operasional penuh.
--
-- Kasus Tepi yang Dicakup (DoD & Mitigasi Risiko T7-12):
--   1. Transaksi reguler bayar tunai (makanan & minuman).
--   2. Transaksi diskon manual kasir + bayar non-tunai (QRIS).
--   3. Transaksi diskon voucher promo + pembayaran campuran / split payment (Tunai + QRIS).
--   4. Transaksi dengan pembatalan parsial (void pra-dapur, nilai kerugian = 0).
--   5. Transaksi pembatalan total pasca-dapur dengan persetujuan PIN atasan (bahan terbuang, nilai kerugian nyata).
--   6. Pergerakan kas laci: kas masuk, kas keluar operasional, dan setoran brankas.
--   7. Koreksi modal awal shift dengan persetujuan PIN atasan (append-only ledger).
--   8. Rekonsiliasi tutup shift kasir: uang seharusnya vs fisik (selisih = 0).
--
-- Verifikasi:
--   Semua asersi membuktikan: |angka_laporan - angka_mentah| = 0.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Pembersihan data transaksi awal agar kanvas pengujian murni & terisolasi
-- ---------------------------------------------------------------------------
delete from public.pembatalan;
delete from public.pembayaran;
delete from public.diskon_transaksi;
delete from public.pesanan_item;
delete from public.kas_pergerakan;
delete from public.koreksi_modal_shift;
delete from public.shift_kas;
delete from public.pesanan;

-- Normalisasi harga dan status menu di Cabang Pusat agar konsisten dengan katalog dasar
update public.menu_cabang
   set harga = 25000, habis = false
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and menu_item_id = 'beef0000-0000-0000-0000-000000000001';

update public.menu_cabang
   set habis = false
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and menu_item_id = 'beef0000-0000-0000-0000-000000000002';

-- Buat tabel temporer untuk menampung ID dan variabel pengujian
create temp table _golden_konteks (
  penyewa_id       uuid,
  cabang_id        uuid,
  shift_id         uuid,
  kasir_id         uuid,
  owner_id         uuid,
  metode_tunai_id  uuid,
  metode_qris_id   uuid,
  menu_nasgor_id   uuid,
  menu_esteh_id    uuid,
  menu_kopi_id     uuid,
  hari_operasional date
);

insert into _golden_konteks values (
  '11111111-1111-1111-1111-111111111111'::uuid,
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  null,
  '90000000-0000-0000-0000-000000000004'::uuid, -- Rina (Kasir A1)
  '90000000-0000-0000-0000-000000000002'::uuid, -- Bu Oasis (Owner Pusat)
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS' limit 1),
  'beef0000-0000-0000-0000-000000000001'::uuid, -- Nasi Goreng (25.000, makanan)
  'beef0000-0000-0000-0000-000000000002'::uuid, -- Es Teh (8.000, minuman)
  'beef0000-0000-0000-0000-000000000003'::uuid, -- Kopi (12.000, minuman)
  current_date
);

grant all on table _golden_konteks to authenticated;

-- Setup PIN owner Bu Oasis agar dapat menyetujui koreksi modal dan void pasca-dapur
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789');
reset role;

-- ---------------------------------------------------------------------------
-- 1. Buka Shift Kasir & Koreksi Modal Awal
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004'); -- Kasir Rina
set local role authenticated;

-- Kasir membuka shift dengan modal awal 150.000
select public.buka_shift(
  p_modal_awal := 150000,
  p_cabang_id  := (select cabang_id from _golden_konteks),
  p_catatan    := 'Buka shift kasir pagi hari golden test'
);

-- Catat ID shift ke konteks
update _golden_konteks
   set shift_id = (
     select id from public.shift_kas
      where cabang_id = (select cabang_id from _golden_konteks)
        and status = 'terbuka'
      order by dibuka_pada desc
      limit 1
   );

-- Owner Bu Oasis menyetujui koreksi modal awal menjadi 200.000 (+50.000 receh brankas)
select (public.verifikasi_pin(
  '90000000-0000-0000-0000-000000000002'::uuid,
  '738294',
  'koreksi_modal_shift',
  'de000000-0000-0000-0000-000000000001'::uuid,
  'kunci-uji-hp-owner-0123456789'
)).berhasil;

-- Terapkan koreksi modal awal
select public.koreksi_modal_shift(
  (select shift_id from _golden_konteks),
  200000,
  'Koreksi uang receh pecahan Rp5.000 tertinggal di brankas',
  '90000000-0000-0000-0000-000000000002'::uuid
);

-- ---------------------------------------------------------------------------
-- 2. Pergerakan Kas Laci (Kas Masuk, Kas Keluar, Setoran Brankas)
-- ---------------------------------------------------------------------------
-- Kas Masuk: Rp30.000 (tukar modal receh)
select public.kas_pergerakan(
  p_jenis           := 'masuk',
  p_jumlah          := 30000,
  p_alasan          := 'Tambah modal receh kembalian',
  p_cabang_id       := (select cabang_id from _golden_konteks),
  p_kunci_idempoten := 'golden-kas-masuk-01'
);

-- Kas Keluar: Rp25.000 (beli es batu darurat)
select public.kas_pergerakan(
  p_jenis           := 'keluar',
  p_jumlah          := 25000,
  p_alasan          := 'Beli es batu darurat kedai',
  p_cabang_id       := (select cabang_id from _golden_konteks),
  p_kunci_idempoten := 'golden-kas-keluar-01'
);

-- Setoran Brankas: Rp50.000 (setor uang tunai tengah hari)
select public.kas_pergerakan(
  p_jenis           := 'setoran',
  p_jumlah          := 50000,
  p_alasan          := 'Setoran brankas tengah hari',
  p_cabang_id       := (select cabang_id from _golden_konteks),
  p_kunci_idempoten := 'golden-kas-setoran-01'
);

-- ---------------------------------------------------------------------------
-- 3. Transaksi 1: Pesanan Reguler, Pembayaran Tunai
--    Item: 2x Nasi Goreng (50.000) + 2x Es Teh (16.000) = Subtotal 66.000
--    Pajak 10% (6.600) + Service 5% (3.300) = Total 75.900
-- ---------------------------------------------------------------------------
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, shift_id, kunci_idempoten
) values (
  'e1000000-0000-0000-0000-000000000001'::uuid,
  (select penyewa_id from _golden_konteks),
  (select cabang_id from _golden_konteks),
  'dinein',
  'draf',
  (select shift_id from _golden_konteks),
  'golden-pesanan-01'
);

insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal) values
  ('e1000000-0000-0000-0000-000000000001'::uuid, (select menu_nasgor_id from _golden_konteks), 'Nasi Goreng', 25000, 2, 50000),
  ('e1000000-0000-0000-0000-000000000001'::uuid, (select menu_esteh_id from _golden_konteks), 'Es Teh', 8000, 2, 16000);

update public.pesanan
   set status = 'dikirim',
       dikirim_ke_dapur_pada = now()
 where id = 'e1000000-0000-0000-0000-000000000001'::uuid;

select public.hitung_total('e1000000-0000-0000-0000-000000000001'::uuid);

-- Bayar tunai Rp75.900 (uang diterima Rp80.000)
select public.bayar_pesanan(
  'e1000000-0000-0000-0000-000000000001'::uuid,
  (select metode_tunai_id from _golden_konteks),
  75900,
  80000,
  null,
  'golden-bayar-01'
);

-- ---------------------------------------------------------------------------
-- 4. Transaksi 2: Diskon Manual Kasir (Rp2.000) + Pembayaran QRIS
--    Item: 2x Nasi Goreng (50.000). Diskon 2.000 (4% <= 5%).
--    Subtotal setelah diskon = 48.000.
--    Pajak 10% (4.800) + Service 5% (2.400) = Total 55.200
-- ---------------------------------------------------------------------------
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, shift_id, kunci_idempoten
) values (
  'e1000000-0000-0000-0000-000000000002'::uuid,
  (select penyewa_id from _golden_konteks),
  (select cabang_id from _golden_konteks),
  'dinein',
  'draf',
  (select shift_id from _golden_konteks),
  'golden-pesanan-02'
);

insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal) values
  ('e1000000-0000-0000-0000-000000000002'::uuid, (select menu_nasgor_id from _golden_konteks), 'Nasi Goreng', 25000, 2, 50000);

insert into public.diskon_transaksi (
  pesanan_id, jenis, nominal, nilai, alasan, pelaku_id
) values (
  'e1000000-0000-0000-0000-000000000002'::uuid,
  'manual',
  2000,
  2000,
  'Diskon promo tetangga kedai',
  '90000000-0000-0000-0000-000000000004'::uuid
);

update public.pesanan
   set status = 'dikirim',
       dikirim_ke_dapur_pada = now()
 where id = 'e1000000-0000-0000-0000-000000000002'::uuid;

select public.hitung_total('e1000000-0000-0000-0000-000000000002'::uuid);

-- Bayar QRIS Rp55.200
select public.bayar_pesanan(
  'e1000000-0000-0000-0000-000000000002'::uuid,
  (select metode_qris_id from _golden_konteks),
  55200,
  55200,
  'QRIS-GOLDEN-002',
  'golden-bayar-02'
);

-- ---------------------------------------------------------------------------
-- 5. Transaksi 3: Diskon Manual Atasan (Rp10.000) + Pembayaran Campuran
--    Item: 2x Nasi Goreng (50.000) + 2x Kopi (24.000) = Subtotal 74.000
--    Diskon Manual Atasan: Rp10.000 (persetujuan PIN Owner Bu Oasis) -> Subtotal bersih = 64.000
--    Pajak 10% (6.400) + Service 5% (3.200) = Total 73.600
--    Split Payment: Tunai Rp40.000 + QRIS Rp33.600
-- ---------------------------------------------------------------------------
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, shift_id, kunci_idempoten
) values (
  'e1000000-0000-0000-0000-000000000003'::uuid,
  (select penyewa_id from _golden_konteks),
  (select cabang_id from _golden_konteks),
  'dinein',
  'draf',
  (select shift_id from _golden_konteks),
  'golden-pesanan-03'
);

insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal) values
  ('e1000000-0000-0000-0000-000000000003'::uuid, (select menu_nasgor_id from _golden_konteks), 'Nasi Goreng', 25000, 2, 50000),
  ('e1000000-0000-0000-0000-000000000003'::uuid, (select menu_kopi_id from _golden_konteks), 'Kopi', 12000, 2, 24000);

-- Owner Bu Oasis menyetujui diskon manual Rp10.000 untuk pesanan ini
select (public.verifikasi_pin(
  '90000000-0000-0000-0000-000000000002'::uuid,
  '738294',
  'beri_diskon',
  'de000000-0000-0000-0000-000000000001'::uuid,
  'kunci-uji-hp-owner-0123456789',
  'e1000000-0000-0000-0000-000000000003'::uuid
)).berhasil;

insert into public.diskon_transaksi (
  pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh
) values (
  'e1000000-0000-0000-0000-000000000003'::uuid,
  'manual',
  10000,
  10000,
  'Diskon atasan untuk tamu VIP',
  '90000000-0000-0000-0000-000000000002'::uuid
);

update public.pesanan
   set status = 'dikirim',
       dikirim_ke_dapur_pada = now()
 where id = 'e1000000-0000-0000-0000-000000000003'::uuid;

select public.hitung_total('e1000000-0000-0000-0000-000000000003'::uuid);

-- Pembayaran 1: Tunai Rp40.000 (status masih belum lunas)
select public.bayar_pesanan(
  'e1000000-0000-0000-0000-000000000003'::uuid,
  (select metode_tunai_id from _golden_konteks),
  40000,
  40000,
  null,
  'golden-bayar-03a'
);

-- Pembayaran 2: Pelunasan sisa Rp33.600 dengan QRIS
select public.bayar_pesanan(
  'e1000000-0000-0000-0000-000000000003'::uuid,
  (select metode_qris_id from _golden_konteks),
  33600,
  33600,
  'QRIS-GOLDEN-003b',
  'golden-bayar-03b'
);

-- ---------------------------------------------------------------------------
-- 6. Transaksi 4: Pembatalan Parsial Pra-Dapur (Void Tanpa Kerugian Bahan)
--    Item: 1x Nasi Goreng (25.000) + 1x Es Teh (8.000) + 1x Kopi (12.000)
--    Kopi dibatalkan sebelum dapur masak -> nilai kerugian = 0.
--    Item tersisa: Nasi Goreng (25.000) + Es Teh (8.000) = Subtotal 33.000
--    Pajak 10% (3.300) + Service 5% (1.650) = Total 37.950
--    Bayar Tunai Rp37.950
-- ---------------------------------------------------------------------------
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, shift_id, kunci_idempoten
) values (
  'e1000000-0000-0000-0000-000000000004'::uuid,
  (select penyewa_id from _golden_konteks),
  (select cabang_id from _golden_konteks),
  'dinein',
  'draf',
  (select shift_id from _golden_konteks),
  'golden-pesanan-04'
);

insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal) values
  ('e1000000-0000-0000-0000-00000000004a'::uuid, 'e1000000-0000-0000-0000-000000000004'::uuid, (select menu_nasgor_id from _golden_konteks), 'Nasi Goreng', 25000, 1, 25000),
  ('e1000000-0000-0000-0000-00000000004b'::uuid, 'e1000000-0000-0000-0000-000000000004'::uuid, (select menu_esteh_id from _golden_konteks), 'Es Teh', 8000, 1, 8000),
  ('e1000000-0000-0000-0000-00000000004c'::uuid, 'e1000000-0000-0000-0000-000000000004'::uuid, (select menu_kopi_id from _golden_konteks), 'Kopi', 12000, 1, 12000);

-- Catat pembatalan kopi pra-dapur
insert into public.pembatalan (
  pesanan_id, pesanan_item_id, tahap, alasan, nilai_kerugian, bahan_terbuang, pelaku_id
) values (
  'e1000000-0000-0000-0000-000000000004'::uuid,
  'e1000000-0000-0000-0000-00000000004c'::uuid,
  'sebelum_dapur',
  'Tamu membatalkan kopi sebelum diracik',
  0,
  false,
  '90000000-0000-0000-0000-000000000004'::uuid
);

update public.pesanan
   set status = 'dikirim',
       dikirim_ke_dapur_pada = now()
 where id = 'e1000000-0000-0000-0000-000000000004'::uuid;

select public.hitung_total('e1000000-0000-0000-0000-000000000004'::uuid);

-- Bayar tunai Rp37.950
select public.bayar_pesanan(
  'e1000000-0000-0000-0000-000000000004'::uuid,
  (select metode_tunai_id from _golden_konteks),
  37950,
  40000,
  null,
  'golden-bayar-04'
);

-- ---------------------------------------------------------------------------
-- 7. Transaksi 5: Pembatalan Total Pasca-Dapur (Bahan Terbuang, Rugi Nyata)
--    Item: 1x Nasi Goreng (25.000). Dimasak di dapur lalu tamu kabur.
--    Persetujuan PIN atasan Bu Oasis (738294).
--    Status pesanan menjadi 'batal', kerugian 25.000. Tidak ada omzet lunas.
-- ---------------------------------------------------------------------------
insert into public.pesanan (
  id, penyewa_id, cabang_id, tipe, status, shift_id, kunci_idempoten
) values (
  'e1000000-0000-0000-0000-000000000005'::uuid,
  (select penyewa_id from _golden_konteks),
  (select cabang_id from _golden_konteks),
  'dinein',
  'draf',
  (select shift_id from _golden_konteks),
  'golden-pesanan-05'
);

insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal) values
  ('e1000000-0000-0000-0000-00000000005a'::uuid, 'e1000000-0000-0000-0000-000000000005'::uuid, (select menu_nasgor_id from _golden_konteks), 'Nasi Goreng', 25000, 1, 25000);

update public.pesanan
   set status = 'dikirim',
       dikirim_ke_dapur_pada = now() - interval '15 minutes'
 where id = 'e1000000-0000-0000-0000-000000000005'::uuid;

select public.hitung_total('e1000000-0000-0000-0000-000000000005'::uuid);

-- Owner menyetujui void pasca-dapur dengan PIN
select (public.verifikasi_pin(
  '90000000-0000-0000-0000-000000000002'::uuid,
  '738294',
  'void_sesudah_dapur',
  'de000000-0000-0000-0000-000000000001'::uuid,
  'kunci-uji-hp-owner-0123456789',
  'e1000000-0000-0000-0000-000000000005'::uuid
)).berhasil;

insert into public.pembatalan (
  pesanan_id, pesanan_item_id, tahap, alasan, nilai_kerugian, bahan_terbuang, pelaku_id, disetujui_oleh
) values (
  'e1000000-0000-0000-0000-000000000005'::uuid,
  'e1000000-0000-0000-0000-00000000005a'::uuid,
  'sesudah_dapur',
  'Tamu kabur tanpa membayar setelah pesanan selesai dimasak',
  25000,
  true,
  '90000000-0000-0000-0000-000000000004'::uuid,
  '90000000-0000-0000-0000-000000000002'::uuid
);

update public.pesanan
   set status = 'batal',
       dibatalkan_pada = now(),
       alasan_batal = 'Tamu kabur tanpa membayar setelah pesanan selesai dimasak'
 where id = 'e1000000-0000-0000-0000-000000000005'::uuid;

-- ---------------------------------------------------------------------------
-- 8. Tutup Shift Kasir (Rekonsiliasi Pas: Selisih = 0)
--    Modal Awal (Terkoreksi): 200.000
--    Penjualan Tunai: 75.900 (P1) + 40.000 (P3) + 37.950 (P4) = 153.850
--    Kas Masuk: 30.000
--    Kas Keluar: 25.000
--    Setoran: 50.000
--    Uang Seharusnya = 200.000 + 153.850 + 30.000 - 25.000 - 50.000 = 308.850
-- ---------------------------------------------------------------------------
select public.tutup_shift(
  p_uang_fisik     := 308850,
  p_alasan_selisih := '',
  p_catatan        := 'Tutup shift golden test - uang fisik pas',
  p_shift_id       := (select shift_id from _golden_konteks)
);

-- ===========================================================================
-- BUKTI GOLDEN: Hitung Langsung dari Tabel Data Mentah Transaksi
-- ===========================================================================
-- Masuk sebagai Owner Bu Oasis untuk menarik data mentah & laporan resmi
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

create temp table _golden_mentah as
select
  -- Ringkasan Penjualan Lunas
  count(distinct p.id)::integer                as mentah_transaksi_count,
  coalesce(sum(p.subtotal), 0)::integer        as mentah_subtotal,
  coalesce(sum(p.pajak), 0)::integer           as mentah_pajak,
  coalesce(sum(p.service), 0)::integer         as mentah_service,
  coalesce(sum(p.total_diskon), 0)::integer    as mentah_diskon,
  coalesce(sum(p.total), 0)::integer           as mentah_omzet,
  -- Nilai Rata-rata Transaksi
  round(sum(p.total)::numeric / count(distinct p.id))::integer as mentah_rata_rata
from public.pesanan p
where p.status = 'lunas'
  and p.cabang_id = (select cabang_id from _golden_konteks)
  and p.tanggal = (select hari_operasional from _golden_konteks);

-- Agregasi Pembayaran Mentah
create temp table _golden_bayar as
select
  coalesce(sum(case when pb.jenis_saat_itu = 'tunai' then pb.jumlah else 0 end), 0)::integer as mentah_tunai,
  coalesce(sum(case when pb.jenis_saat_itu = 'non_tunai' then pb.jumlah else 0 end), 0)::integer as mentah_non_tunai,
  coalesce(sum(pb.jumlah), 0)::integer as mentah_total_bayar,
  count(pb.id)::integer as mentah_jumlah_pembayaran
from public.pembayaran pb
join public.pesanan p on p.id = pb.pesanan_id
where p.status = 'lunas'
  and p.cabang_id = (select cabang_id from _golden_konteks)
  and p.tanggal = (select hari_operasional from _golden_konteks);

-- Agregasi Item Menu Mentah
create temp table _golden_menu as
select
  coalesce(sum(pi.qty), 0)::integer as mentah_total_porsi,
  coalesce(sum(pi.subtotal), 0)::integer as mentah_omzet_menu,
  coalesce(sum(case when mi.jenis = 'makanan' then pi.subtotal else 0 end), 0)::integer as mentah_omzet_makanan,
  coalesce(sum(case when mi.jenis = 'minuman' then pi.subtotal else 0 end), 0)::integer as mentah_omzet_minuman,
  coalesce(sum(case when mi.jenis not in ('makanan', 'minuman') then pi.subtotal else 0 end), 0)::integer as mentah_omzet_lainnya
from public.pesanan_item pi
join public.pesanan p on p.id = pi.pesanan_id
left join public.menu_item mi on mi.id = pi.menu_item_id
where p.status = 'lunas'
  and p.cabang_id = (select cabang_id from _golden_konteks)
  and p.tanggal = (select hari_operasional from _golden_konteks);

-- Agregasi Diskon Mentah
create temp table _golden_diskon as
select
  coalesce(sum(case when dt.jenis = 'manual' then dt.nilai else 0 end), 0)::integer as mentah_diskon_manual,
  coalesce(sum(case when dt.jenis in ('voucher', 'promo') then dt.nilai else 0 end), 0)::integer as mentah_voucher,
  coalesce(sum(dt.nilai), 0)::integer as mentah_biaya_promosi
from public.diskon_transaksi dt
join public.pesanan p on p.id = dt.pesanan_id
where p.status = 'lunas'
  and p.cabang_id = (select cabang_id from _golden_konteks)
  and p.tanggal = (select hari_operasional from _golden_konteks);

-- Agregasi Pembatalan Mentah
create temp table _golden_batal as
select
  count(*)::integer as mentah_batal_count,
  coalesce(sum(b.nilai_kerugian), 0)::integer as mentah_nilai_kerugian
from public.pembatalan b
join public.pesanan p on p.id = b.pesanan_id
where p.cabang_id = (select cabang_id from _golden_konteks)
  and p.tanggal = (select hari_operasional from _golden_konteks);

-- Agregasi Kas Shift Mentah (hitung langsung dari tabel shift_kas, pembayaran, dan kas_pergerakan)
create temp table _golden_shift as
select
  s.modal_awal::integer                                                as mentah_modal_awal,
  (select coalesce(sum(pb.jumlah), 0)::integer
     from public.pembayaran pb
    where pb.shift_id = s.id and pb.jenis_saat_itu = 'tunai')          as mentah_penjualan_tunai,
  (select coalesce(sum(pb.jumlah), 0)::integer
     from public.pembayaran pb
    where pb.shift_id = s.id and pb.jenis_saat_itu = 'non_tunai')      as mentah_penjualan_nontunai,
  (select coalesce(sum(kp.jumlah), 0)::integer
     from public.kas_pergerakan kp
    where kp.shift_id = s.id and kp.jenis = 'masuk')                   as mentah_total_kas_masuk,
  (select coalesce(sum(kp.jumlah), 0)::integer
     from public.kas_pergerakan kp
    where kp.shift_id = s.id and kp.jenis = 'keluar')                  as mentah_total_kas_keluar,
  (select coalesce(sum(kp.jumlah), 0)::integer
     from public.kas_pergerakan kp
    where kp.shift_id = s.id and kp.jenis = 'setoran')                 as mentah_total_setoran,
  s.uang_seharusnya::integer                                           as mentah_uang_seharusnya,
  s.uang_fisik::integer                                                as mentah_uang_fisik,
  s.selisih::integer                                                   as mentah_selisih_kas
from public.shift_kas s
where s.id = (select shift_id from _golden_konteks);

-- ===========================================================================
-- EKSEKUSI LAPORAN RESMI (RPC)
-- ===========================================================================
create temp table _golden_hasil_rpc as
select
  public.laporan_penjualan(
    (select cabang_id from _golden_konteks),
    (select hari_operasional from _golden_konteks),
    (select hari_operasional from _golden_konteks)
  ) as rpc_penjualan,
  public.laporan_menu(
    (select cabang_id from _golden_konteks),
    (select hari_operasional from _golden_konteks),
    (select hari_operasional from _golden_konteks),
    'nilai'
  ) as rpc_menu,
  public.laporan_harian(
    (select cabang_id from _golden_konteks),
    (select hari_operasional from _golden_konteks)
  ) as rpc_harian,
  public.laporan_shift(
    (select shift_id from _golden_konteks)
  ) as rpc_shift;

-- ---------------------------------------------------------------------------
-- 1. Uji Golden Laporan Penjualan (public.laporan_penjualan) vs Data Mentah
-- ---------------------------------------------------------------------------
-- Omzet Total: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_omzet' from _golden_hasil_rpc)::integer -
   (select mentah_omzet from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Total Omzet Laporan Penjualan = 0'
);

-- Subtotal: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_subtotal' from _golden_hasil_rpc)::integer -
   (select mentah_subtotal from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Subtotal Laporan Penjualan = 0'
);

-- Pajak: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_pajak' from _golden_hasil_rpc)::integer -
   (select mentah_pajak from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Pajak Laporan Penjualan = 0'
);

-- Service Charge: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_service' from _golden_hasil_rpc)::integer -
   (select mentah_service from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Service Charge Laporan Penjualan = 0'
);

-- Total Diskon: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_diskon' from _golden_hasil_rpc)::integer -
   (select mentah_diskon from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Total Diskon Laporan Penjualan = 0'
);

-- Jumlah Transaksi: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'total_transaksi' from _golden_hasil_rpc)::integer -
   (select mentah_transaksi_count from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Jumlah Transaksi Laporan Penjualan = 0'
);

-- Nilai Rata-rata Transaksi: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'ringkasan'->>'rata_rata_transaksi' from _golden_hasil_rpc)::integer -
   (select mentah_rata_rata from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Rata-rata Transaksi Laporan Penjualan = 0'
);

-- Omzet Jenis Makanan: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'jenis_menu'->>'omzet_makanan' from _golden_hasil_rpc)::integer -
   (select mentah_omzet_makanan from _golden_menu)),
  0,
  'T7-12 Golden: Selisih Omzet Makanan Laporan Penjualan = 0'
);

-- Omzet Jenis Minuman: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_penjualan->'data'->'jenis_menu'->>'omzet_minuman' from _golden_hasil_rpc)::integer -
   (select mentah_omzet_minuman from _golden_menu)),
  0,
  'T7-12 Golden: Selisih Omzet Minuman Laporan Penjualan = 0'
);

-- Rincian Metode Tunai: Laporan = Mentah (Selisih = 0)
select uji.sama(
  (
    (select (elem->>'total_nominal')::integer
       from jsonb_array_elements((select rpc_penjualan->'data'->'per_metode' from _golden_hasil_rpc)) elem
      where elem->>'metode_nama' = 'Tunai') -
    (select mentah_tunai from _golden_bayar)
  ),
  0,
  'T7-12 Golden: Selisih Nominal Pembayaran Tunai di Laporan = 0'
);

-- Rincian Metode QRIS: Laporan = Mentah (Selisih = 0)
select uji.sama(
  (
    (select (elem->>'total_nominal')::integer
       from jsonb_array_elements((select rpc_penjualan->'data'->'per_metode' from _golden_hasil_rpc)) elem
      where elem->>'metode_nama' = 'QRIS') -
    (select mentah_non_tunai from _golden_bayar)
  ),
  0,
  'T7-12 Golden: Selisih Nominal Pembayaran QRIS di Laporan = 0'
);

-- Total Seluruh Metode Pembayaran = Total Omzet (Selisih = 0)
select uji.sama(
  (
    (select coalesce(sum((elem->>'total_nominal')::integer), 0)::integer
       from jsonb_array_elements((select rpc_penjualan->'data'->'per_metode' from _golden_hasil_rpc)) elem) -
    (select mentah_omzet from _golden_mentah)
  )::integer,
  0,
  'T7-12 Golden: Total Seluruh Metode Bayar Sama dengan Total Omzet (Selisih = 0)'
);

-- ---------------------------------------------------------------------------
-- 2. Uji Golden Laporan Menu (public.laporan_menu) vs Data Mentah
-- ---------------------------------------------------------------------------
-- Total Porsi Terjual: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_menu->'data'->'ringkasan'->>'total_porsi' from _golden_hasil_rpc)::integer -
   (select mentah_total_porsi from _golden_menu)),
  0,
  'T7-12 Golden: Selisih Total Porsi Terjual di Laporan Menu = 0'
);

-- Total Omzet Menu: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_menu->'data'->'ringkasan'->>'total_omzet_menu' from _golden_hasil_rpc)::integer -
   (select mentah_omzet_menu from _golden_menu)),
  0,
  'T7-12 Golden: Selisih Total Omzet di Laporan Menu = 0'
);

-- Total Diskon Manual: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_menu->'data'->'ringkasan'->>'total_diskon_manual' from _golden_hasil_rpc)::integer -
   (select mentah_diskon_manual from _golden_diskon)),
  0,
  'T7-12 Golden: Selisih Total Diskon Manual di Laporan Menu = 0'
);

-- Total Voucher: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_menu->'data'->'ringkasan'->>'total_voucher' from _golden_hasil_rpc)::integer -
   (select mentah_voucher from _golden_diskon)),
  0,
  'T7-12 Golden: Selisih Total Voucher di Laporan Menu = 0'
);

-- Total Biaya Promosi: Diskon Manual + Voucher (Selisih = 0)
select uji.sama(
  ((select rpc_menu->'data'->'ringkasan'->>'total_biaya_promosi' from _golden_hasil_rpc)::integer -
   (select mentah_biaya_promosi from _golden_diskon)),
  0,
  'T7-12 Golden: Selisih Total Biaya Promosi di Laporan Menu = 0'
);

-- Peringkat 1 (Nasi Goreng: 7 porsi, total Rp175.000)
select uji.sama(
  (
    select (elem->>'qty_terjual')::integer
      from jsonb_array_elements((select rpc_menu->'data'->'peringkat_menu' from _golden_hasil_rpc)) elem
     where elem->>'nama_menu' = 'Nasi Goreng'
  ),
  7,
  'T7-12 Golden: Kuantitas Nasi Goreng Terjual = 7 Porsi'
);

select uji.sama(
  (
    select (elem->>'total_omzet')::integer
      from jsonb_array_elements((select rpc_menu->'data'->'peringkat_menu' from _golden_hasil_rpc)) elem
     where elem->>'nama_menu' = 'Nasi Goreng'
  ),
  175000,
  'T7-12 Golden: Total Omzet Nasi Goreng = Rp175.000'
);

-- ---------------------------------------------------------------------------
-- 3. Uji Golden Laporan Kas Harian (public.laporan_harian) vs Data Mentah
-- ---------------------------------------------------------------------------
-- Omzet Total Laporan Harian: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_harian->'data'->'penjualan'->>'omzet_total' from _golden_hasil_rpc)::integer -
   (select mentah_omzet from _golden_mentah)),
  0,
  'T7-12 Golden: Selisih Total Omzet Laporan Harian = 0'
);

-- Kas Masuk Laporan Harian: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_harian->'data'->'kas'->>'kas_masuk' from _golden_hasil_rpc)::integer -
   (select mentah_total_kas_masuk from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Total Kas Masuk Laporan Harian = 0'
);

-- Kas Keluar Laporan Harian: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_harian->'data'->'kas'->>'kas_keluar' from _golden_hasil_rpc)::integer -
   (select mentah_total_kas_keluar from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Total Kas Keluar Laporan Harian = 0'
);

-- Setoran Brankas Laporan Harian: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_harian->'data'->'kas'->>'setoran' from _golden_hasil_rpc)::integer -
   (select mentah_total_setoran from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Total Setoran Laporan Harian = 0'
);

-- ---------------------------------------------------------------------------
-- 4. Uji Golden Laporan Shift Kasir (public.laporan_shift) vs Data Mentah
-- ---------------------------------------------------------------------------
-- Modal Awal Shift: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_shift->'data'->'kas'->>'modal_awal' from _golden_hasil_rpc)::integer -
   (select mentah_modal_awal from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Modal Awal Shift = 0'
);

-- Penjualan Tunai Shift: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_shift->'data'->'kas'->>'penjualan_tunai' from _golden_hasil_rpc)::integer -
   (select mentah_penjualan_tunai from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Penjualan Tunai Shift = 0'
);

-- Penjualan Non-Tunai Shift: Laporan = Mentah (Selisih = 0)
select uji.sama(
  ((select rpc_shift->'data'->'kas'->>'penjualan_non_tunai' from _golden_hasil_rpc)::integer -
   (select mentah_penjualan_nontunai from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Penjualan Non-Tunai Shift = 0'
);

-- Uang Seharusnya Shift: Laporan = Mentah (Selisih = 0)
-- (modal 200.000 + tunai 153.850 + kas masuk 30.000 - kas keluar 25.000 - setoran 50.000 = 308.850)
select uji.sama(
  ((select rpc_shift->'data'->'kas'->>'uang_seharusnya' from _golden_hasil_rpc)::integer -
   (select mentah_uang_seharusnya from _golden_shift)),
  0,
  'T7-12 Golden: Selisih Uang Seharusnya Shift = 0'
);

-- Uang Fisik dan Selisih Rekonsiliasi (Selisih Kas = 0)
select uji.sama(
  (select rpc_shift->'data'->'kas'->>'selisih' from _golden_hasil_rpc)::integer,
  0,
  'T7-12 Golden: Rekonsiliasi Fisik vs Seharusnya Pas (Selisih = 0)'
);

-- ---------------------------------------------------------------------------
-- 5. Uji Golden View Laporan Pembatalan (public.laporan_pembatalan) vs Data Mentah
-- ---------------------------------------------------------------------------
-- Jumlah Baris Pembatalan: View = Mentah (Selisih = 0)
select uji.sama(
  (
    (select count(*)::integer from public.laporan_pembatalan
      where cabang_id = (select cabang_id from _golden_konteks)
        and tanggal = (select hari_operasional from _golden_konteks)) -
    (select mentah_batal_count from _golden_batal)
  ),
  0,
  'T7-12 Golden: Selisih Baris Laporan Pembatalan = 0'
);

-- Total Nilai Kerugian Pembatalan: View = Mentah (Selisih = 0)
select uji.sama(
  (
    (select coalesce(sum(nilai_kerugian), 0)::integer from public.laporan_pembatalan
      where cabang_id = (select cabang_id from _golden_konteks)
        and tanggal = (select hari_operasional from _golden_konteks)) -
    (select mentah_nilai_kerugian from _golden_batal)
  ),
  0,
  'T7-12 Golden: Selisih Nilai Kerugian Pembatalan = 0'
);

-- Pembatalan Pasca-Dapur Menandai Bahan Terbuang Benar
select uji.sama(
  (
    select bahan_terbuang
      from public.laporan_pembatalan
     where tahap = 'sesudah_dapur'
     limit 1
  ),
  true,
  'T7-12 Golden: Pembatalan pasca-dapur tercatat sebagai bahan terbuang'
);

-- ---------------------------------------------------------------------------
-- 6. Uji Golden View Koreksi Modal (public.laporan_koreksi_modal) vs Data Mentah
-- ---------------------------------------------------------------------------
select uji.sama(
  (
    select selisih
      from public.laporan_koreksi_modal
     where shift_id = (select shift_id from _golden_konteks)
     limit 1
  ),
  50000,
  'T7-12 Golden: Selisih Koreksi Modal Awal Tercatat Tepat Rp50.000'
);

select uji.sama(
  (
    select modal_awal_baru
      from public.laporan_koreksi_modal
     where shift_id = (select shift_id from _golden_konteks)
     limit 1
  ),
  200000,
  'T7-12 Golden: Modal Awal Baru Tercatat Tepat Rp200.000'
);

-- Selesai: reset peran
reset role;
select uji.klaim(null);
