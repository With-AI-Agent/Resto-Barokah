-- ============================================================================
-- UJI: penanda pembatalan TIDAK BOLEH bisa dipalsukan (temuan K-1, review PR-01)
-- ============================================================================
-- Yang dibuktikan berkas ini (semuanya dari kursi KASIR, bukan pemilik tabel):
--   1. KONTROL — membatalkan item sesudah dapur tanpa baris pembatalan → DITOLAK.
--   2. SERANGAN UTAMA (inti temuan K-1) — kasir menulis penanda transaksi sendiri
--      (`set_config('resto.pembatalan_pesanan', …)`) lalu mengulang pembatalan → WAJIB
--      MASIH DITOLAK. Sebelum perbaikan migrasi 0015, serangan ini BERHASIL.
--   3. Penanda palsu juga tidak boleh melegalkan pengecilan jumlah (qty turun).
--   4. Penanda palsu berisi id pesanan LAIN juga tidak berpengaruh.
--   5. Tidak ada satu pun baris item yang benar-benar berubah (jejak & kerugian utuh).
--
-- Pesanan uji: `eeee0000-…-0010` (kasir A1, sudah dikirim ke dapur 5 menit lalu).
-- Berkas ini hanya MENGUJI PENOLAKAN — tidak mengubah keadaan data uji, supaya berkas
-- uji lain yang memakai pesanan yang sama tetap berjalan seperti sebelumnya.
-- Jalur SAH (PIN atasan → baris pembatalan → item ikut batal) sudah diuji berkas lain:
-- `supabase/tes/item_penjaga.sql` §5 dan `supabase/tes/persetujuan_void.sql`.
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;

-- 1. KONTROL: tanpa apa pun, pembatalan item sesudah dapur memang sudah ditolak.
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'batal'
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'pembatalan',
  'kontrol: pembatalan item sesudah dapur tanpa baris resmi → DITOLAK'
);

-- 2. SERANGAN K-1: kasir memasang penanda transaksi sendiri, lalu mengulang.
select set_config('resto.pembatalan_pesanan', 'eeee0000-0000-0000-0000-000000000010', true);
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'batal'
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'pembatalan',
  'K-1: penanda transaksi PALSU tidak lagi diakui → pembatalan tetap DITOLAK'
);

-- 3. Penanda palsu tidak melegalkan pengecilan jumlah.
select set_config('resto.pembatalan_pesanan', 'eeee0000-0000-0000-0000-000000000010', true);
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set qty = 1
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'pembatalan',
  'K-1: pengecilan jumlah sesudah dapur dengan penanda palsu → DITOLAK'
);

-- 4. Penanda berisi pesanan lain juga tidak berpengaruh (tidak ada "kunci ajaib").
select set_config('resto.pembatalan_pesanan', 'eeee0000-0000-0000-0000-000000000001', true);
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'batal'
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'pembatalan',
  'K-1: penanda untuk pesanan lain tidak membuka apa pun → DITOLAK'
);

-- 5. Keadaan data: tidak ada item yang berubah, tidak ada baris pembatalan karangan.
select uji.sama(
  (select count(*) from public.pesanan_item
    where pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and status = 'batal'),
  0::bigint,
  'tidak ada item yang benar-benar batal (angka kerugian & tagihan utuh)'
);
select uji.sama(
  (select count(*) from public.pembatalan
    where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  0::bigint,
  'tidak ada baris pembatalan karangan (jejak tetap bersih)'
);
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'dikirim',
  'status pesanan tidak berubah oleh percobaan di atas'
);

reset role;
select uji.klaim(null);
