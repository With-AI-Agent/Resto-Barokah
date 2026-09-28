-- ============================================================================
-- UJI: batas PERSEN diskon dihitung dari UANG, bukan dari kolom kiriman klien
-- Temuan audit AUD-3 K-2 (B F-06, 2026-09-17): pemicu memakai
-- `coalesce(new.persen, 0)`, sehingga mengosongkan kolom `persen` membuat batas
-- persen tidak diperiksa sama sekali — kasir (batas 25.000 / 5 %) bisa memberi
-- diskon 20.000 pada subtotal 54.000 (= 37 %).
-- Aturan yang dikunci: persen efektif = nilai diskon / subtotal pesanan.
-- ============================================================================

-- Pesanan uji: subtotal 54.000, kasir batas 25.000 / 5 persen.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select ie.batas_nominal from public.izin_efektif('beri_diskon', 'a1a1a1a1-0000-0000-0000-000000000001') ie),
  25000, 'kontrol: batas nominal kasir 25.000'
);
select uji.sama(
  (select ie.batas_persen from public.izin_efektif('beri_diskon', 'a1a1a1a1-0000-0000-0000-000000000001') ie),
  5::numeric, 'kontrol: batas persen kasir 5 persen'
);

-- 1. Kolom persen diisi jujur → ditolak (sudah berlaku sebelumnya).
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', 37, 20000, 20000, 'persen jujur')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'diskon 37 persen DITOLAK bila kolom persen diisi jujur');

-- 2. Kolom persen DIKOSONGKAN → tetap ditolak (inilah cacat yang ditutup).
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 20000, 20000, 'persen kosong')$$, 'Diskon ini melebihi batas izin Anda — minta atasan \(pemilik/admin\) yang memproses', 'diskon 37 persen DITOLAK walau kolom persen dikosongkan (persen dihitung dari uang)');

-- 3. Kolom persen dikosongkan TETAPI nilai diskonnya di bawah kedua batas → diterima.
select uji.sama(
  (select public.boleh('beri_diskon', 2000, 3.7)),
  true, 'kontrol: diskon 2.000 (3,7 persen) memang di dalam batas kasir'
);
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2000, 2000, 'diskon kecil sah');
select uji.sama(
  (select d.nilai from public.diskon_transaksi d where d.alasan = 'diskon kecil sah'),
  2000, 'diskon kecil di dalam batas tetap DITERIMA (penjaga tidak memblokir yang sah)'
);
reset role;
select uji.klaim(null);
