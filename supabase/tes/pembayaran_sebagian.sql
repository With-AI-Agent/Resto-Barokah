-- ============================================================================
-- UJI T5-11 — pembayaran sebagian & tagihan ditinggal (keputusan MVP)
-- ============================================================================
-- KEPUTUSAN MVP yang dibuktikan di sini: "split bill" resmi adalah pekerjaan
-- fase 2. Untuk MVP, pembayaran sebagian dicatat sebagai **dua baris pembayaran
-- terpisah pada SATU pesanan** — bukan dua pesanan, dan bukan satu baris yang
-- ditimpa berkali-kali. Perbedaan itu penting untuk laporan: tiap kali uang
-- berpindah tangan harus punya barisnya sendiri (metode, jumlah, waktu), supaya
-- kas bisa dicocokkan per metode di akhir shift.
--
-- Yang dibuktikan berkas ini:
--   1. Bayar sebagian → pesanan BELUM lunas, sisa tercatat benar.
--   2. Pelunasan dengan metode BERBEDA → dua baris pembayaran terpisah bertahan
--      (yang pertama tidak ditimpa/dihapus), dan pesanan baru jadi lunas.
--   3. Jumlah baris pembayaran = 2 → inilah arti "dua transaksi terpisah".
--   4. Total uang masuk = total pesanan, tidak lebih (tidak ada kelebihan diam).
--   5. TAGIHAN DITINGGAL: pesanan yang belum lunas tetap bisa ditemukan beserta
--      UMURNYA (berapa lama menggantung) — dasar penanda umur di layar
--      `DaftarTagihan.tsx`.
--   6. Sesudah lunas, pesanan beku (pagar 0022 tetap bekerja) — pembayaran
--      ketiga ditolak, jadi "sebagian" tidak bisa dipakai menyelundupkan uang.
--
-- Pesanan uji dibuat di dalam berkas ini (id khusus `d8…`) supaya tidak
-- mengganggu pesanan contoh milik berkas uji lain.
-- ============================================================================

-- Penyiapan (sebagai pemilik tabel): satu pesanan Cabang A1, satu item 30.000.
--
-- CATATAN PENTING yang ditemukan saat menulis uji ini: angka `total` yang kita
-- tulis di sini TIDAK dipercaya. Peladen menghitung ulang sendiri (pajak 10 % +
-- service 5 %) sehingga total yang SAH menjadi 34.500. Itu memang pagarnya —
-- perangkat kasir tidak boleh menentukan jumlah tagihan. Karena itu uji ini
-- membayar 20.000 + 14.500, bukan 20.000 + 10.000.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, total_diskon, pajak, service, total, kunci_idempoten)
values ('d8000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 981, current_date, 'dinein', 'dikirim',
        30000, 0, 0, 0, 30000, 'bayar-sebagian-1');

insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('d8000000-0000-0000-0000-0000000000a1', 'd8000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 30000, 1, 30000);

-- ---------------------------------------------------------------------------
-- 1. Bayar SEBAGIAN (tunai 20.000 dari 30.000) → belum lunas.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;

select uji.sama(
  (public.bayar_pesanan(
     'd8000000-0000-0000-0000-000000000001',
     (select mb.id from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111'
         and mb.jenis = 'tunai' and mb.aktif limit 1),
     20000, 20000, null, 'sebagian-1'
   ) ->> 'lunas')::boolean,
  false, 'T5-11: bayar sebagian TIDAK melunasi pesanan'
);

select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd8000000-0000-0000-0000-000000000001'),
  'dikirim', 'T5-11: pesanan tetap berjalan selama masih ada sisa'
);

-- ---------------------------------------------------------------------------
-- 5. TAGIHAN DITINGGAL: pesanan belum lunas bisa ditemukan beserta umurnya.
--    (Diperiksa di sini, selagi pesanan memang belum lunas.)
-- ---------------------------------------------------------------------------
select uji.sama(
  (select count(*) from public.pesanan p
    where p.id = 'd8000000-0000-0000-0000-000000000001'
      and p.status <> 'lunas'
      and p.dibayar_pada is null),
  1::bigint, 'T5-11: tagihan yang ditinggal masih terdaftar sebagai belum lunas'
);
select uji.harap(
  (select p.dibuat_pada is not null from public.pesanan p
    where p.id = 'd8000000-0000-0000-0000-000000000001'),
  'T5-11: pesanan punya waktu dibuat — dasar penanda UMUR tagihan di layar'
);

-- ---------------------------------------------------------------------------
-- 2. Pelunasan dengan metode BERBEDA (non-tunai 10.000 + referensi).
-- ---------------------------------------------------------------------------
select uji.sama(
  (public.bayar_pesanan(
     'd8000000-0000-0000-0000-000000000001',
     (select mb.id from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111'
         and mb.jenis <> 'tunai' and mb.aktif limit 1),
     14500, null, 'REF-T511', 'sebagian-2'
   ) ->> 'lunas')::boolean,
  true, 'T5-11: sisa dilunasi dengan metode berbeda → pesanan lunas'
);

-- ---------------------------------------------------------------------------
-- 3. DUA baris pembayaran terpisah — inti keputusan MVP.
-- ---------------------------------------------------------------------------
select uji.sama(
  (select count(*) from public.pembayaran b
    where b.pesanan_id = 'd8000000-0000-0000-0000-000000000001'),
  2::bigint, 'T5-11: pembayaran sebagian tercatat sebagai DUA baris terpisah'
);
select uji.sama(
  (select count(distinct b.metode_id) from public.pembayaran b
    where b.pesanan_id = 'd8000000-0000-0000-0000-000000000001'),
  2::bigint, 'T5-11: kedua metode tersimpan sendiri-sendiri (bisa dicocokkan per kas)'
);
select uji.sama(
  (select b.jumlah from public.pembayaran b
    where b.pesanan_id = 'd8000000-0000-0000-0000-000000000001'
    order by b.waktu limit 1),
  20000, 'T5-11: baris pertama TIDAK ditimpa oleh pelunasan'
);

-- ---------------------------------------------------------------------------
-- 4. Total uang masuk persis sama dengan total pesanan.
-- ---------------------------------------------------------------------------
select uji.sama(
  (select sum(b.jumlah)::integer from public.pembayaran b
    where b.pesanan_id = 'd8000000-0000-0000-0000-000000000001'),
  34500, 'T5-11: jumlah dua pembayaran = total pesanan SAH dari peladen (tidak ada kelebihan diam)'
);
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'd8000000-0000-0000-0000-000000000001'),
  'lunas', 'T5-11: pesanan lunas setelah sisa tertutup'
);

-- ---------------------------------------------------------------------------
-- 6. Sesudah lunas, pesanan BEKU — "sebagian" tidak bisa menyelundupkan uang.
-- ---------------------------------------------------------------------------
-- Penolakannya berupa kesalahan yang membatalkan perintah (bukan jawaban
-- "berhasil: false"), supaya tidak ada jalan tengah yang menyisakan baris uang.
select uji.harap_gagal_sebab($$
  select public.bayar_pesanan(
     'd8000000-0000-0000-0000-000000000001',
     (select mb.id from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111'
         and mb.jenis = 'tunai' and mb.aktif limit 1),
     5000, 5000, null, 'sebagian-3')
$$, 'melebihi total pesanan',
  'T5-11: pembayaran sesudah lunas DITOLAK (uang tidak bisa diselundupkan lewat jalur sebagian)'
);
select uji.sama(
  (select count(*) from public.pembayaran b
    where b.pesanan_id = 'd8000000-0000-0000-0000-000000000001'),
  2::bigint, 'T5-11: penolakan tidak menambah baris uang'
);

reset role;
select uji.klaim(null);

-- Bersih-bersih supaya berkas uji lain tidak terpengaruh.
delete from public.pembayaran where pesanan_id = 'd8000000-0000-0000-0000-000000000001';
delete from public.pesanan_item where pesanan_id = 'd8000000-0000-0000-0000-000000000001';
delete from public.pesanan where id = 'd8000000-0000-0000-0000-000000000001';
