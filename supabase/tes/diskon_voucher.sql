-- ============================================================================
-- UJI: DISKON VOUCHER — gagal-aman selama mesin voucher belum ada
-- Menutup temuan review putaran11 PR-01 (K-2, jalur uang):
--   Kasir (bawaan `pakai_voucher = true`) bisa mencatat diskon 100% subtotal dengan
--   `jenis='voucher'` tanpa voucher apa pun — batas 25.000 / 5% untuk diskon manual
--   dilewati hanya dengan mengganti label jenis. Tabel `voucher` belum ada dan
--   `voucher_id` masih tanpa kunci asing (menyusul T1-12/T1-19/T1-20), jadi jalur ini
--   DITUTUP dulu (gagal-aman), sama seperti `promo`.
-- ============================================================================

-- 1. Diskon MANUAL sebesar subtotal penuh DITOLAK (kontrol positif: batas izin bekerja).
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir, batas 25.000 / 5%
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 54000, 54000, 'diskon manual penuh')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'kontrol: diskon manual 54.000 ditolak (batas kasir 25.000)');

-- 2. JENIS YANG SAMA, diberi label 'voucher' → sekarang JUGA DITOLAK (temuan PR-01).
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'voucher', null, 54000, 54000, 'voucher karangan')$$, 'Diskon voucher belum aktif \(mesin voucher menunggu T1-12/T1-19/T1-20\)\. Pakai diskon manual', 'diskon "voucher" 100% subtotal TIDAK bisa dicatat kasir (mesin voucher belum ada)');

-- 3. Nilai KECIL pun tidak boleh — supaya jelas yang ditolak adalah JENISNYA, bukan besarnya.
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'voucher', null, 1000, 1000, 'voucher kecil')$$, 'Diskon voucher belum aktif \(mesin voucher menunggu T1-12/T1-19/T1-20\)\. Pakai diskon manual', 'diskon "voucher" sekecil apa pun tetap ditolak selama mesinnya belum ada');

-- 4. Bukti tidak ada sisa baris voucher yang tertinggal dari percobaan di atas.
select uji.sama(
  (select count(*)::bigint from public.diskon_transaksi d
     where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010' and d.jenis = 'voucher'),
  0::bigint,
  'tidak ada satu pun baris diskon voucher yang tersimpan'
);
