-- ============================================================================
-- UJI: uang yang sudah TERCATAT tidak boleh ditulis ulang lewat diskon (temuan audit D F-01)
-- ============================================================================
-- Temuan aslinya (probe `docs/uji/audit/probe-2026-09-19/audit-f01-diskon-sesudah-lunas.sql`):
-- pesanan sudah `lunas` — uang diterima & tercatat — lalu kasir menyisipkan baris diskon;
-- pemicu hitung-ulang mengubah `pesanan.total` SESUDAH lunas, tanpa penjelasan resmi.
--
-- Yang dibuktikan berkas ini:
--   1. KONTROL — pada pesanan yang masih hidup, kasir berizin boleh mencatat diskon.
--   2. SESUDAH LUNAS: menambah diskon dari perangkat → DITOLAK, sebabnya tentang status.
--   3. SESUDAH LUNAS: mengubah nilai diskon lama → DITOLAK (sabuk lapis kedua — jalur
--      perangkat memang sudah ditutup RLS karena tidak ada kebijakan UPDATE).
--   4. SESUDAH LUNAS: menghapus baris diskon → DITOLAK.
--   5. Angka uang pesanan lunas TIDAK berubah sedikit pun setelah ketiga percobaan itu.
--   6. PESANAN BATAL: menambah diskon → DITOLAK karena STATUS (membuktikan pemicu status
--      berjalan sebelum pemicu nilai `diskon_batas`; kalau urutannya tertukar, penolakan
--      akan berbunyi tentang nilai diskon dan uji ini MERAH).
-- ============================================================================

-- Penyiapan (pemilik tabel): dua pesanan Cabang A1, satu item masing-masing.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('d2000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 951, current_date, 'dinein', 'draf', 'diskon-lunas-1'),
       ('d2000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 952, current_date, 'dinein', 'draf', 'diskon-lunas-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('d2000000-0000-0000-0000-0000000000a1', 'd2000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('d2000000-0000-0000-0000-0000000000b1', 'd2000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);

-- 1. KONTROL: kasir (izin diskon 5% / Rp25.000) mencatat diskon 5% pada pesanan hidup.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
values ('d2000000-0000-0000-0000-000000000001', 'manual', 5, 1350, 'kontrol: diskon sebelum lunas');
reset role;
select uji.sama(
  (select coalesce(sum(d.nilai), 0)::bigint from public.diskon_transaksi d
    where d.pesanan_id = 'd2000000-0000-0000-0000-000000000001'),
  1350::bigint, 'kontrol: diskon sah pada pesanan yang masih hidup'
);

-- Uang pesanan sudah diterima & tercatat (ditetapkan peladen).
update public.pesanan set status = 'lunas' where id = 'd2000000-0000-0000-0000-000000000001';
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd2000000-0000-0000-0000-000000000001'),
  'lunas', 'kontrol: pesanan sekarang berstatus lunas (uang sudah tercatat)'
);
-- CATATAN (aturan uang diperbaiki 2026-09-20, temuan AUD-3 F-01): pajak & service kini
-- dihitung dari subtotal SETELAH diskon → dasar = 27.000 − 1.350 = 25.650; PB1 10% = 2.565;
-- service 5% = 1.283; total = 25.650 + 2.565 + 1.283 = 29.498 (bukan 29.700 cara lama).
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'd2000000-0000-0000-0000-000000000001'),
  29498, 'kontrol: total sesudah lunas = (27.000 − 1.350) + PB1 2.565 + service 1.283'
);

-- 2. SERANGAN F-01: kasir menyisipkan diskon sesudah lunas → WAJIB DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
      values ('d2000000-0000-0000-0000-000000000001', 'manual', 5, 1350, 'diskon sesudah lunas')$$,
  'lunas',
  'F-01: diskon sesudah lunas DITOLAK dengan sebab tentang status pesanan'
);
reset role;

-- 3–4. Sabuk lapis kedua (dijalankan sebagai peladen, jadi RLS tidak menyamarkan sebabnya):
--      baris diskon lama tidak boleh diubah maupun dihapus sesudah lunas.
select uji.harap_gagal_sebab(
  $$update public.diskon_transaksi set nilai = 20000
     where pesanan_id = 'd2000000-0000-0000-0000-000000000001'$$,
  'lunas', 'F-01: diskon lama tidak bisa DIPERBESAR sesudah lunas'
);
select uji.harap_gagal_sebab(
  $$delete from public.diskon_transaksi
     where pesanan_id = 'd2000000-0000-0000-0000-000000000001'$$,
  'lunas', 'F-01: diskon lama tidak bisa DIHAPUS sesudah lunas'
);

-- 5. Angka uang pesanan lunas tidak berubah (diskon 1.350 tetap satu-satunya).
select uji.sama(
  (select coalesce(sum(d.nilai), 0)::bigint from public.diskon_transaksi d
    where d.pesanan_id = 'd2000000-0000-0000-0000-000000000001'),
  1350::bigint, 'F-01: tidak ada baris diskon baru yang lolos'
);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'd2000000-0000-0000-0000-000000000001'),
  29498, 'F-01: total pesanan lunas TIDAK berubah (angka beku sesudah uang tercatat)'
);

-- 6. Pesanan yang sudah BATAL juga tidak boleh menerima diskon; sebabnya harus tentang status.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembatalan (pesanan_id, tahap, alasan)
values ('d2000000-0000-0000-0000-000000000002', 'sebelum_dapur', 'pelanggan batal');
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd2000000-0000-0000-0000-000000000002'),
  'batal', 'kontrol: pesanan kedua sudah batal'
);
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
      values ('d2000000-0000-0000-0000-000000000002', 'manual', 5, 1350, 'diskon pesanan batal')$$,
  'batal',
  'F-01: diskon pada pesanan batal DITOLAK karena STATUS (bukan karena nilai/subtotal 0)'
);
select uji.klaim(null);
