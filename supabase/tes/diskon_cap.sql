-- ============================================================================
-- UJI: DISKON — jenis yang belum punya mesin, subtotal nol, dan CAP TOTAL
-- Menutup temuan review PR putaran8 (0012):
--   * PR-01  : `jenis='promo'` melewati SELURUH pemeriksaan izin (kasir bisa
--              mencatat diskon 100% subtotal tanpa persetujuan).
--   * PR-01b : diskon bisa DITANAM saat subtotal masih 0 (baris append-only,
--              tidak bisa dihapus klien → potongan menempel).
--   * PR-02  : `pengaturan.batas_maks_potongan_*` tidak pernah dibaca; dengan
--              tumpuk diskon nyala, kasir memecah diskon sampai 100% subtotal.
-- ============================================================================

-- 1. `promo` DITOLAK selama mesinnya belum ada (TEMUAN PR-01).
--    Nominalnya sengaja KECIL dan jujur (1.000 = 1,85% dari 54.000): jauh di dalam batas
--    izin kasir (25.000 / 5%) DAN di dalam cap bawaan resto → yang menahan di sini
--    benar-benar cabang `promo`, bukan aturan lain yang kebetulan menangkapnya.
--    (Dulu nominalnya 54.000 = 100% subtotal; sejak cap bawaan diturunkan ke 50% di 0014,
--    angka itu ditolak cap sehingga uji ini berhenti membuktikan apa pun — kesalahan yang
--    ditemukan lewat bukti mutasi M1.)
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir, batas 25.000 / 5%
set local role authenticated;
select uji.sama(
  (select ie.batas_nominal from public.izin_efektif('beri_diskon', 'a1a1a1a1-0000-0000-0000-000000000001') ie),
  25000, 'kontrol: kasir memang berbatas 25.000'
);
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'promo', 2, 1000, 1000, 'promo karangan kasir')$$, 'Diskon promo otomatis belum aktif \(menunggu T1-19/T1-20\)\. Pakai diskon manual dengan perse', 'diskon jenis promo DITOLAK (mesin promo belum ada — dulu lolos tanpa pemeriksaan)');
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'entah', null, 1000, 1000, 'jenis karangan')$$, 'Jenis diskon tidak dikenal: entah', 'jenis diskon di luar daftar ditolak');

-- 2. Diskon DITOLAK saat subtotal pesanan masih 0 (TEMUAN laporan C / PR-01).
--    Sekarang subtotal wajib sudah tercatat lebih dulu; kalau belum, tidak ada
--    potongan yang bisa "ditanam" lebih awal.
reset role;
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000d001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 95, current_date, 'dinein', 'draf', 'diskon-subtotal-nol');
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
--    (Nilainya sengaja KECIL dan di dalam batas kasir, persen diisi jujur: yang menahan
--     di sini murni penjaga "subtotal belum ada", bukan batas izin per baris.)
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('00000000-0000-0000-0000-00000000d001', 'manual', 1, 2000, 2000, 'diskon sebelum ada item')$$, 'Subtotal pesanan belum tercatat — diskon belum boleh dicatat \(hitung pesanan dulu\)', 'diskon DITOLAK selama subtotal pesanan masih 0 (dulu ditanam lebih dulu)');
reset role;

-- 3. CAP TOTAL resto dibaca (TEMUAN PR-02): tumpuk diskon nyala + cap 10% / Rp5.000.
--    Diskon per barisnya kecil (di dalam batas kasir), tetapi TOTAL-nya melampaui cap.
update public.pengaturan
   set tumpuk_diskon = true,
       batas_maks_potongan_persen = 10,
       batas_maks_potongan_nominal = 5000
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan set subtotal = 54000, total = 62100
 where id = 'eeee0000-0000-0000-0000-000000000010';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
-- Baris pertama: 2.700 (5% dari 54.000) — masih di dalam cap Rp5.000 → diterima.
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 5, 2700, 2700, 'diskon pertama');
select uji.sama(
  (select sum(d.nilai)::int from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  2700, 'diskon pertama (2.700) diterima — masih di dalam cap'
);
-- Baris kedua: total jadi 5.400 > cap Rp5.000 → DITOLAK.
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', 5, 2700, 2700, 'diskon kedua')$$, 'Total potongan \(', 'diskon kedua DITOLAK karena TOTAL potongan melampaui cap nominal resto (Rp5.000)');
-- Cap persen juga berlaku walau nominalnya masih kecil.
reset role;   -- perubahan pengaturan dilakukan owner/peladen, bukan kasir
update public.pengaturan set batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 5, 2700, 2700, 'diskon kedua (cap persen 10%)');
select uji.sama(
  (select count(*) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  2::bigint, 'diskon kedua diterima selagi total (5.400) masih di dalam cap persen 10%'
);
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', 1, 1000, 1000, 'diskon ketiga')$$, 'Total potongan \(', 'diskon ketiga DITOLAK karena TOTAL potongan (6.400) melampaui cap persen resto (10%)');

-- 4. Batas izin PER BARIS masih berlaku (tidak dilemahkan oleh cap baru).
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 20000, 20000, 'di atas batas kasir')$$, 'Diskon ini melebihi batas izin Anda\. Minta persetujuan atasan \(PIN\)', 'diskon 20.000 oleh kasir (batas 25.000/5%) tetap ditolak karena persen 37%');

reset role;
select uji.klaim(null);
