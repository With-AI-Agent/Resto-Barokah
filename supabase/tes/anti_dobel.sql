-- ============================================================================
-- UJI: ANTI-DOBEL (T4-09) — dua perangkat memproses hal yang sama:
--  (1) item dapur: set_status_item idempoten (kunci sama / transisi sama)
--      → tepat SATU perubahan tercatat;
--  (2) tandai_habis dua kali dari dua perangkat → keadaan akhir benar, tanpa
--      kerusakan; setiap sentuhan punya jejak audit;
--  (3) set_stok TANPA kunci idempoten: dua permintaan sengaja = dua pergerakan
--      (kontrak disengaja — koreksi memakai alasan, bukan menimpa).
-- Uji paralel NYATA (2 koneksi) ada di alat/uji-konkuren.py (langkah CI).
-- ============================================================================

-- Data uji: 1 pesanan Cabang Dua dengan 1 item dapur.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f052','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000002', 88, current_date, 'dinein', 'dikirim', 'anti-dobel-uji');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000f152','00000000-0000-0000-0000-00000000f052',
        'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1,27000);
insert into public.stok_bahan (id, penyewa_id, nama, satuan, jumlah)
values ('00000000-0000-0000-0000-00000000e021','11111111-1111-1111-1111-111111111111','Telur','butir',0);
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan)
values ('00000000-0000-0000-0000-00000000e021', 'masuk', 100, 'Saldo awal');
select uji.klaim(null);

-- (1a) Dua perangkat, kunci idempoten SAMA → tepat satu perubahan tercatat.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f152', 'dimasak', 'kunci-dobel-1')->>'diubah')::text),
  'true', 'perangkat pertama: baru → dimasak');
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f152', 'dimasak', 'kunci-dobel-1')->>'diubah')::text),
  'false', 'perangkat kedua dengan kunci sama: ulangan idempoten, bukan perubahan ganda');
reset role;
select uji.sama(
  (select count(*) from public.pesanan_item_status_riwayat r
    where r.pesanan_item_id = '00000000-0000-0000-0000-00000000f152'),
  1::bigint, 'tepat satu baris riwayat status meski dua perangkat menandai');

-- (1b) Perangkat kedua dengan kunci BERBEDA pada transisi yang sama: tidak
--      membuat riwayat kedua (status sudah dimasak).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f152', 'dimasak', 'kunci-dobel-2')->>'diubah')::text),
  'false', 'transisi kembar dengan kunci beda pun tidak mengubah apa pun');
reset role;
select uji.sama(
  (select count(*) from public.pesanan_item_status_riwayat r
    where r.pesanan_item_id = '00000000-0000-0000-0000-00000000f152'),
  1::bigint, 'riwayat status tetap satu baris');

-- (2) Tandai habis dua kali dari dua perangkat: keadaan akhir benar.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002', true);
select public.tandai_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002', true);
reset role;
select uji.sama(
  public.menu_habis('beef0000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000002'),
  true, 'sentuhan ganda tandai_habis: keadaan akhir tetap benar (habis)');

-- (3) set_stok dua kali = dua pergerakan (dokumen kesengajaan, bukan kebocoran).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select public.set_stok('00000000-0000-0000-0000-00000000e021', 5, 'Pemasukan A');
select public.set_stok('00000000-0000-0000-0000-00000000e021', 5, 'Pemasukan B');
reset role;
select uji.sama(
  (select count(*) from public.stok_pergerakan p
    where p.stok_bahan_id = '00000000-0000-0000-0000-00000000e021'
      and p.alasan in ('Pemasukan A', 'Pemasukan B')),
  2::bigint, 'dua permintaan sengaja tercatat dua kali — koreksi lewat alasan, bukan menimpa');
select uji.sama(
  (select b.jumlah from public.stok_bahan b where b.id = '00000000-0000-0000-0000-00000000e021'),
  110::numeric, 'saldo akhir = awal + delta tercatat (100 + 5 + 5)');
