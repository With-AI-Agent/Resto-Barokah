-- PROBE SAYA (versi 2) untuk PR-02 — kasir berizin void pra-dapur
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000d002','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 902, current_date, 'dinein', 'draf',
        81000, 8100, 4050, 93150, 'probe-d002');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000d002','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1,27000),
       ('00000000-0000-0000-0000-00000000d002','beef0000-0000-0000-0000-000000000002','Es Teh',27000,2,54000);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina (kasir, berizin void pra-dapur)
set local role authenticated;
select uji.sama(public.boleh('void_sebelum_dapur'), true, 'kontrol: kasir berizin void pra-dapur');

insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('00000000-0000-0000-0000-00000000d002',
        (select id from public.pesanan_item where pesanan_id='00000000-0000-0000-0000-00000000d002'
          order by nama_saat_itu limit 1),
        'sebelum_dapur', 'satu item dibatalkan pelanggan');

select uji.sama((select status from public.pesanan where id='00000000-0000-0000-0000-00000000d002'),
                'batal', 'PR-02 NYATA: void SATU item ikut membatalkan SELURUH pesanan');
select uji.sama((select count(*) from public.pesanan_item
                  where pesanan_id='00000000-0000-0000-0000-00000000d002' and status <> 'batal'),
                1::bigint, 'PR-02 NYATA: masih ada item hidup padahal pesanan sudah batal');
select uji.harap_gagal_sebab(
  $$insert into public.pembayaran (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
      values ('00000000-0000-0000-0000-00000000d002', null, 'Tunai', 'tunai', 54000, 54000, 'probe-bayar-sisa')$$,
  'batal', 'PR-02 NYATA: pembayaran item yang masih hidup DITOLAK karena pesanan sudah batal');
reset role; select uji.klaim(null);
