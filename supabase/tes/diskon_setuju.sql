-- ============================================================================
-- UJI: STEMPEL "DISETUJUI" PADA DISKON WAJIB TERBUKTI (bukan dikarang klien)
-- Menutup temuan review putaran13 #2 PR-04 (K-3): kasir bisa menulis
-- `disetujui_oleh = <owner>` tanpa PIN/kupon/bukti apa pun, sehingga rekam jejak
-- menunjukkan owner menyetujui hal yang tidak pernah ia lihat.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',2000,2000,'stempel karangan',
              '90000000-0000-0000-0000-000000000002')$$, 'Persetujuan diskon belum terbukti: penyetuju harus memasukkan PIN-nya sendiri untuk diskon', 'stempel "disetujui owner" tanpa bukti PIN DITOLAK');

-- Diskon biasa (tanpa stempel) tetap boleh — batas izin kasir bekerja.
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010','manual',2000,2000,'pelanggan langganan');
select uji.sama(
  (select count(*) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1::bigint, 'diskon biasa tetap bisa dicatat (penjaga tidak menutup jalur sah)'
);
reset role;
select uji.klaim(null);

-- Jalur sah: penyetuju memasukkan PIN-nya untuk aksi 'beri_diskon' → stempel boleh.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
-- Tumpuk diskon dinyalakan lebih dulu: supaya yang menahan diskon berstempel
-- benar-benar pemicu BUKTI PERSETUJUAN, bukan aturan "satu diskon per transaksi".
update public.pengaturan set tumpuk_diskon = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select public.simpan_pin('738294', null);
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'beri_diskon', 'hp-owner',
                         'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true, 'owner memasukkan PIN-nya untuk aksi beri_diskon di pesanan ini'
);
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
values ('eeee0000-0000-0000-0000-000000000010','manual',6000,6000,'diskon owner','90000000-0000-0000-0000-000000000002');
select uji.sama(
  (select count(*) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  2::bigint, 'diskon berstempel DITERIMA setelah bukti PIN ada (jalur sah terbuka)'
);
-- Kupon sekali pakai: stempel kedua tanpa PIN baru ditolak.
select uji.harap_gagal_sebab($$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',1000,1000,'pakai ulang kupon',
              '90000000-0000-0000-0000-000000000002')$$, 'Persetujuan diskon belum terbukti: penyetuju harus memasukkan PIN-nya sendiri untuk diskon', 'satu persetujuan PIN tidak bisa dipakai dua kali');
reset role;
select uji.klaim(null);

-- ----------------------------------------------------------------------------
-- F-16 (2026-09-20): "PIN benar tetapi tidak berizin" tidak boleh jadi stempel
-- ----------------------------------------------------------------------------
-- Pelayan (tanpa izin beri_diskon) memasukkan PIN-nya untuk aksi beri_diskon:
-- verifikasi menjawab GAGAL, tetapi dulu baris berhasil=true bertahan dan lolos
-- saringan kupon. Kini konsumsi kupon mengecek ulang izin penyetuju.
-- Pesanan dibuat di sini (state antar-berkas persisten; eeee…0014 khusus uji ini).
reset role;
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000014', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 14, current_date, 'dinein', 'dikirim',
        54000, 5400, 2700, 62100, 'f16-stempel');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('eeee0000-0000-0000-0000-000000000014', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 54000);
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan, bukan penyetuju diskon
set local role authenticated;
select public.simpan_pin('618273');
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000005', '618273', 'beri_diskon', 'hp-pelayan',
                         'eeee0000-0000-0000-0000-000000000014')).berhasil,
  false, 'F-16 prasyarat: PIN pelayan ditolak untuk aksi beri_diskon');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir mencoba memakai baris itu
set local role authenticated;
-- Nominal sengaja KECIL (2000 = 3,7%): masih di dalam batas kasir sendiri
-- (25000 / 5%), supaya yang menolak pastilah cek-ulang izin penyetuju (F-16),
-- bukan batas diskon pemohon. Pesan juga dipatok agar alasan tolak tidak tertukar.
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000014','manual',2000,2000,'stempel pelayan',
              '90000000-0000-0000-0000-000000000005')$$,
  'tidak berizin',
  'F-16: kupon dari aksi yang ditolak TIDAK bisa menstempel diskon (alasan: penyetuju tak berizin)');
reset role;
select uji.klaim(null);
