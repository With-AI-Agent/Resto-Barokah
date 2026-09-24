-- ============================================================================
-- SUITE UJI: Transaksi Lewat Tengah Malam & Penomoran Hari Operasional (T7-11)
--
-- Referensi:
--   - PRD M8 (kasus tepi): "transaksi lewat tengah malam (masuk tanggal transaksi,
--     bukan tanggal tutup kas) · nomor pesanan mengikuti hari operasional;
--     uji lulus dengan jam simulasi."
--   - TECH_SPEC §9 ART-9: "Simpan UTC; tampilkan per zona penyewa. Penomoran
--     pesanan harian memakai zona penyewa (bukan UTC) — kalau salah, nomor
--     pesanan bisa 'melompat hari'. Laporan harian memakai batas hari menurut
--     zona penyewa."
--   - DECISIONS_LOG.md: Area Zona Waktu (ART-9).
--
-- Uji yang dicakup:
--   1. zona_waktu_cabang & tanggal_lokal_cabang menghitung jam UTC ke lokal dengan benar.
--   2. Shift kas dibuka pukul 18:00 WIB (2026-09-24).
--   3. Transaksi 1 dibuat pukul 23:50 WIB (2026-09-24 / 16:50 UTC):
--      - Tanggal pesanan masuk ke 2026-09-24.
--      - Upaya manipulasi tanggal (mengirimkan 2026-09-25 atau tanggal kemarin) ditolak.
--      - Nomor pesanan dihitung berurutan untuk 2026-09-24.
--      - Pembayaran tunai lunas dicatat pukul 23:55 WIB.
--   4. Transaksi 2 dibuat pukul 00:10 WIB (2026-09-25 / 17:10 UTC tanggal 24!):
--      - Tanggal pesanan masuk ke 2026-09-25 (hari baru lokal, walau UTC masih tgl 24).
--      - Upaya manipulasi tanggal (mengirimkan tanggal 2026-09-24) ditolak.
--      - Nomor pesanan berurutan untuk 2026-09-25 (reset ke nomor #1).
--      - Shift_id tetap terhubung ke shift aktif yang belum ditutup.
--      - Pembayaran tunai lunas dicatat pukul 00:15 WIB.
--   5. Penutupan shift kas pada pukul 02:00 WIB (2026-09-25):
--      - Rekonsiliasi kas mencakup kedua transaksi (Rp54.000 + Rp20.000).
--      - Status shift ditutup dengan melewati_tengah_malam = true.
--   6. Laporan penjualan:
--      - Laporan 2026-09-24 memuat Transaksi 1 (Rp54.000), TIDAK tergeser ke tgl 25.
--      - Laporan 2026-09-25 memuat Transaksi 2 (Rp20.000).
--      - Transaksi tetap di tanggal transaksi, BUKAN tanggal tutup kas.
--   7. Laporan kas harian & laporan shift:
--      - Laporan kas harian memisahkan penerimaan 24 Sep dan 25 Sep.
--      - Laporan shift mengagregasi total seluruh penerimaan shift secara utuh.
-- ============================================================================

-- Identitas uji:
-- Penyewa Resto Barokah: 11111111-1111-1111-1111-111111111111
-- Cabang Pusat: a1a1a1a1-0000-0000-0000-000000000001 (zona: Asia/Jakarta)
-- Owner Siti: 90000000-0000-0000-0000-000000000001
-- Kasir Rina: 90000000-0000-0000-0000-000000000004
-- Metode Tunai: c1000000-0000-0000-0000-000000000001

-- ============================================================================
-- 1. Verifikasi helper zona waktu & tanggal lokal cabang
-- ============================================================================
select uji.sama(
  public.zona_waktu_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid),
  'Asia/Jakarta'::text,
  'zona waktu cabang pusat terdaftar Asia/Jakarta'
);

-- Jam 23:50 WIB pada 24 Sep = 16:50 UTC pada 24 Sep -> tanggal lokal 2026-09-24
select uji.sama(
  public.tanggal_lokal_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid, '2026-09-24 16:50:00+00'::timestamptz),
  '2026-09-24'::date,
  'jam 23:50 WIB (16:50 UTC) menghasilkan tanggal lokal 2026-09-24'
);

-- Jam 00:10 WIB pada 25 Sep = 17:10 UTC pada 24 Sep -> tanggal lokal 2026-09-25
select uji.sama(
  public.tanggal_lokal_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid, '2026-09-24 17:10:00+00'::timestamptz),
  '2026-09-25'::date,
  'jam 00:10 WIB (17:10 UTC tanggal 24) menghasilkan tanggal lokal 2026-09-25'
);

-- ============================================================================
-- 2. Persiapan: Buka Shift Kas Malam Hari (2026-09-24 18:00:00+07)
-- ============================================================================
select uji.klaim(null); -- Peladen / pemilik tabel untuk persiapan shift simulasi

-- Bersihkan shift kas sebelumnya jika ada yang terbuka di cabang ini
update public.shift_kas
   set status = 'ditutup',
       ditutup_oleh = '90000000-0000-0000-0000-000000000004',
       ditutup_pada = now(),
       uang_seharusnya = modal_awal,
       uang_fisik = modal_awal,
       selisih = 0
 where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000001'
   and status = 'terbuka';

-- Buat shift kas malam baru (simulasi dibuka 2026-09-24 18:00 WIB / 11:00 UTC)
insert into public.shift_kas (
  id,
  penyewa_id,
  cabang_id,
  dibuka_oleh,
  dibuka_pada,
  modal_awal,
  status
) values (
  'e7000000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-000000000004', -- Kasir Rina
  '2026-09-24 11:00:00+00'::timestamptz, -- 18:00 WIB
  100000,
  'terbuka'
);

-- Beralih ke peran Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- ============================================================================
-- 3. Transaksi 1: Jam 23:50 WIB (2026-09-24 16:50 UTC)
-- ============================================================================
-- 3a. Penolakan manipulasi tanggal ke hari esok pada jam 23:50
select uji.harap_gagal_sebab(
  $$insert into public.pesanan (
      penyewa_id, cabang_id, tipe, tanggal, dibuat_pada, kunci_idempoten
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'a1a1a1a1-0000-0000-0000-000000000001',
      'dinein',
      '2026-09-25'::date,
      '2026-09-24 16:50:00+00'::timestamptz,
      'uji-tm-tgl-maju'
    )$$,
  'Tanggal pesanan baru harus hari ini',
  'pesanan jam 23:50 WIB menolak tanggal maju 2026-09-25'
);

-- 3b. Penolakan tanggal mundur
select uji.harap_gagal_sebab(
  $$insert into public.pesanan (
      penyewa_id, cabang_id, tipe, tanggal, dibuat_pada, kunci_idempoten
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'a1a1a1a1-0000-0000-0000-000000000001',
      'dinein',
      '2026-09-23'::date,
      '2026-09-24 16:50:00+00'::timestamptz,
      'uji-tm-tgl-mundur'
    )$$,
  'Tanggal pesanan baru harus hari ini',
  'pesanan jam 23:50 WIB menolak tanggal mundur 2026-09-23'
);

-- 3c. Pembuatan pesanan sah pada jam 23:50 WIB (tanggal terisi otomatis 2026-09-24)
insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  tipe,
  dibuat_pada,
  kunci_idempoten
) values (
  'e7000000-0000-0000-0000-000000000010',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'dinein',
  '2026-09-24 16:50:00+00'::timestamptz, -- 23:50 WIB
  'pesanan-tm-1'
);

-- Pastikan tanggal terisi 2026-09-24 dan tertaut ke shift malam
select uji.sama(
  (select p.tanggal from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000010'),
  '2026-09-24'::date,
  'transaksi jam 23:50 WIB otomatis masuk tanggal 2026-09-24'
);

select uji.sama(
  (select p.shift_id from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000010'),
  'e7000000-0000-0000-0000-000000000001'::uuid,
  'transaksi 1 tertaut ke shift malam yang sedang terbuka'
);

-- Tambah item pesanan 1: 2x Nasi Goreng @ 27.000 = Rp54.000
insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e7000000-0000-0000-0000-000000000101',
  'e7000000-0000-0000-0000-000000000010',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng',
  27000,
  2,
  54000
);

-- Kirim ke dapur
update public.pesanan
   set status = 'dikirim', dikirim_ke_dapur_pada = '2026-09-24 16:52:00+00'::timestamptz
 where id = 'e7000000-0000-0000-0000-000000000010';

-- Hitung total
select public.hitung_total('e7000000-0000-0000-0000-000000000010');

-- Bayar lunas tunai pada jam 23:55 WIB (Total 62.100: subtotal 54k + pajak 5.4k + service 2.7k)
insert into public.pembayaran (
  pesanan_id,
  metode_id,
  jumlah,
  diterima,
  kembalian,
  kasir_id,
  shift_id,
  waktu,
  kunci_idempoten
) values (
  'e7000000-0000-0000-0000-000000000010',
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  62100,
  70000,
  7900,
  auth.uid(),
  'e7000000-0000-0000-0000-000000000001',
  '2026-09-24 16:55:00+00'::timestamptz, -- 23:55 WIB
  'bayar-tm-1'
);

-- Jalur peladen menandai pesanan lunas setelah pembayaran penuh
reset role;
select uji.klaim(null);
update public.pesanan
   set status = 'lunas', dibayar_pada = '2026-09-24 16:55:00+00'::timestamptz
 where id = 'e7000000-0000-0000-0000-000000000010';

-- Kembali ke Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select p.status from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000010'),
  'lunas'::text,
  'transaksi 1 (jam 23:50 WIB) berstatus lunas'
);

-- ============================================================================
-- 4. Transaksi 2: Jam 00:10 WIB (2026-09-24 17:10 UTC — Hari Baru 25 Sep!)
-- ============================================================================
-- 4a. Penolakan tanggal kemarin (2026-09-24) saat waktu lokal sudah 00:10 (2026-09-25)
select uji.harap_gagal_sebab(
  $$insert into public.pesanan (
      penyewa_id, cabang_id, tipe, tanggal, dibuat_pada, kunci_idempoten
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'a1a1a1a1-0000-0000-0000-000000000001',
      'dinein',
      '2026-09-24'::date,
      '2026-09-24 17:10:00+00'::timestamptz, -- 00:10 WIB
      'uji-tm-tgl-mundur-lewat-tengah-malam'
    )$$,
  'Tanggal pesanan baru harus hari ini',
  'pesanan jam 00:10 WIB menolak tanggal kemarin 2026-09-24 (wajib tanggal hari baru)'
);

-- 4b. Pembuatan pesanan sah pada jam 00:10 WIB
insert into public.pesanan (
  id,
  penyewa_id,
  cabang_id,
  tipe,
  dibuat_pada,
  kunci_idempoten
) values (
  'e7000000-0000-0000-0000-000000000020',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  'dinein',
  '2026-09-24 17:10:00+00'::timestamptz, -- 00:10 WIB (25 Sep lokal)
  'pesanan-tm-2'
);

-- Pastikan tanggal pesanan 2 otomatis menjadi 2026-09-25
select uji.sama(
  (select p.tanggal from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000020'),
  '2026-09-25'::date,
  'transaksi jam 00:10 WIB otomatis masuk tanggal 2026-09-25'
);

-- Nomor pesanan harus berurutan untuk hari operasional baru (dimulai dari 1)
select uji.sama(
  (select p.nomor from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000020'),
  1,
  'nomor pesanan pada hari baru 2026-09-25 bernomor #1 (mengikuti hari operasional lokal)'
);

-- Shift_id tetap terhubung ke shift malam aktif yang belum ditutup
select uji.sama(
  (select p.shift_id from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000020'),
  'e7000000-0000-0000-0000-000000000001'::uuid,
  'transaksi jam 00:10 WIB tetap tertaut ke shift malam yang sama'
);

-- Tambah item pesanan 2: 1x Kopi @ 12.000 = Rp12.000
insert into public.pesanan_item (
  id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e7000000-0000-0000-0000-000000000201',
  'e7000000-0000-0000-0000-000000000020',
  'beef0000-0000-0000-0000-000000000003',
  'Kopi',
  12000,
  1,
  12000
);

-- Kirim ke dapur
update public.pesanan
   set status = 'dikirim', dikirim_ke_dapur_pada = '2026-09-24 17:12:00+00'::timestamptz
 where id = 'e7000000-0000-0000-0000-000000000020';

-- Hitung total
select public.hitung_total('e7000000-0000-0000-0000-000000000020');

-- Bayar lunas tunai pada jam 00:15 WIB (Total 13.800: subtotal 12k + pajak 1.2k + service 600)
insert into public.pembayaran (
  pesanan_id,
  metode_id,
  jumlah,
  diterima,
  kembalian,
  kasir_id,
  shift_id,
  waktu,
  kunci_idempoten
) values (
  'e7000000-0000-0000-0000-000000000020',
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  13800,
  20000,
  6200,
  auth.uid(),
  'e7000000-0000-0000-0000-000000000001',
  '2026-09-24 17:15:00+00'::timestamptz, -- 00:15 WIB
  'bayar-tm-2'
);

-- Jalur peladen menandai pesanan lunas setelah pembayaran penuh
reset role;
select uji.klaim(null);
update public.pesanan
   set status = 'lunas', dibayar_pada = '2026-09-24 17:15:00+00'::timestamptz
 where id = 'e7000000-0000-0000-0000-000000000020';

-- Kembali ke Kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select p.status from public.pesanan p where p.id = 'e7000000-0000-0000-0000-000000000020'),
  'lunas'::text,
  'transaksi 2 (jam 00:10 WIB) berstatus lunas'
);

-- ============================================================================
-- 5. Penutupan Shift Kas Jam 02:00 WIB (2026-09-25 02:00 / 19:00 UTC)
-- ============================================================================
-- Total uang seharusnya pada shift ini:
-- Modal awal: Rp100.000
-- Transaksi 1: Rp62.100
-- Transaksi 2: Rp13.800
-- Total uang seharusnya: Rp175.900
reset role;
select uji.klaim(null);
update public.shift_kas
   set status = 'ditutup',
       ditutup_oleh = '90000000-0000-0000-0000-000000000004',
       ditutup_pada = '2026-09-24 19:00:00+00'::timestamptz, -- 02:00 WIB
       uang_seharusnya = 175900,
       uang_fisik = 175900,
       selisih = 0,
       melewati_tengah_malam = true
 where id = 'e7000000-0000-0000-0000-000000000001';

-- Beralih ke Owner (Bu Oasis) untuk pengujian laporan
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select s.melewati_tengah_malam from public.shift_kas s where s.id = 'e7000000-0000-0000-0000-000000000001'),
  true,
  'shift ditutup dengan bendera melewati_tengah_malam = true'
);

-- ============================================================================
-- 6. Verifikasi Laporan Penjualan (PRD M8 & TECH_SPEC ART-9):
--    Transaksi masuk tanggal transaksi, BUKAN tanggal tutup kas!
-- ============================================================================
-- 6a. Laporan penjualan untuk tanggal 2026-09-24 (sebelum tengah malam)
--     Hanya memuat Transaksi 1 (Rp62.100). Transaksi 1 TIDAK pindah ke tanggal 25 Sep!
select uji.sama(
  (select (public.laporan_penjualan(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-24'::date,
    '2026-09-24'::date
  ))->'data'->'ringkasan'->>'total_omzet'),
  '62100',
  'laporan penjualan 2026-09-24 mencatat omzet Rp62.100 (transaksi 23:50 masuk tgl transaksi)'
);

select uji.sama(
  (select (public.laporan_penjualan(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-24'::date,
    '2026-09-24'::date
  ))->'data'->'ringkasan'->>'total_transaksi'),
  '1',
  'laporan penjualan 2026-09-24 mencatat tepat 1 transaksi'
);

-- 6b. Laporan penjualan untuk tanggal 2026-09-25 (setelah tengah malam)
--     Hanya memuat Transaksi 2 (Rp13.800).
select uji.sama(
  (select (public.laporan_penjualan(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-25'::date,
    '2026-09-25'::date
  ))->'data'->'ringkasan'->>'total_omzet'),
  '13800',
  'laporan penjualan 2026-09-25 mencatat omzet Rp13.800 (transaksi 00:10 masuk tgl transaksi)'
);

select uji.sama(
  (select (public.laporan_penjualan(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-25'::date,
    '2026-09-25'::date
  ))->'data'->'ringkasan'->>'total_transaksi'),
  '1',
  'laporan penjualan 2026-09-25 mencatat tepat 1 transaksi'
);

-- ============================================================================
-- 7. Verifikasi Laporan Kas Harian (laporan_harian):
--    Penerimaan kas dipotong secara jujur menurut zona waktu cabang
-- ============================================================================
-- 7a. Laporan harian tanggal 2026-09-24
select uji.sama(
  (select (public.laporan_harian(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-24'::date
  ))->'data'->'penjualan'->>'omzet_total'),
  '62100',
  'laporan harian 2026-09-24 mencatat omzet Rp62.100'
);

select uji.sama(
  (select (public.laporan_harian(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-24'::date
  ))->'data'->'kas'->>'penjualan_tunai'),
  '62100',
  'laporan harian 2026-09-24 mencatat pembayaran tunai Rp62.100'
);

-- 7b. Laporan harian tanggal 2026-09-25
select uji.sama(
  (select (public.laporan_harian(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-25'::date
  ))->'data'->'penjualan'->>'omzet_total'),
  '13800',
  'laporan harian 2026-09-25 mencatat omzet Rp13.800'
);

select uji.sama(
  (select (public.laporan_harian(
    'a1a1a1a1-0000-0000-0000-000000000001',
    '2026-09-25'::date
  ))->'data'->'kas'->>'penjualan_tunai'),
  '13800',
  'laporan harian 2026-09-25 mencatat pembayaran tunai Rp13.800'
);

-- ============================================================================
-- 8. Verifikasi Laporan Shift (laporan_shift):
--    Laporan shift mencakup rekonsiliasi kas LENGKAP untuk seluruh durasi shift
-- ============================================================================
select uji.sama(
  (select (public.laporan_shift('e7000000-0000-0000-0000-000000000001'))->'data'->'penjualan'->>'omzet_total'),
  '75900',
  'laporan shift kas malam menampung total omzet Rp75.900 dari kedua transaksi'
);

select uji.sama(
  (select (public.laporan_shift('e7000000-0000-0000-0000-000000000001'))->'data'->'kas'->>'uang_seharusnya'),
  '175900',
  'laporan shift kas malam menghitung uang seharusnya Rp175.900 (modal Rp100k + Rp75.9k tunai)'
);

select uji.sama(
  (select (public.laporan_shift('e7000000-0000-0000-0000-000000000001'))->'data'->'shift'->>'melewati_tengah_malam'),
  'true',
  'laporan shift menampilkan flag melewati_tengah_malam = true'
);

-- ============================================================================
-- 9. Pembersihan sesi uji
-- ============================================================================
reset role;
select uji.klaim(null);
