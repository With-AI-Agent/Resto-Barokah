-- ============================================================================
-- UJI: STEMPEL "DISETUJUI" PADA DISKON WAJIB TERBUKTI (bukan dikarang klien)
-- Menutup temuan review putaran13 #2 PR-04 (K-3): kasir bisa menulis
-- `disetujui_oleh = <owner>` tanpa PIN/kupon/bukti apa pun, sehingga rekam jejak
-- menunjukkan owner menyetujui hal yang tidak pernah ia lihat.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',2000,2000,'stempel karangan',
              '90000000-0000-0000-0000-000000000002')$$,
  'stempel "disetujui owner" tanpa bukti PIN DITOLAK'
);

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
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',1000,1000,'pakai ulang kupon',
              '90000000-0000-0000-0000-000000000002')$$,
  'satu persetujuan PIN tidak bisa dipakai dua kali'
);
reset role;
select uji.klaim(null);
