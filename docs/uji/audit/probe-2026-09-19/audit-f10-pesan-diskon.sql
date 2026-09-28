select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null), 'PIN tersimpan.', 'owner memasang PIN');
reset role; select uji.klaim(null);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (batas 25.000/5%)
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010','manual',15,8100,'kasir coba diskon 15%')$$,
  'melebihi batas', 'kontrol: diskon 15% kasir ditolak');
reset role; select uji.klaim(null);
