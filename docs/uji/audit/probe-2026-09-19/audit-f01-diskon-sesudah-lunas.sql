-- PROBE SAYA — Audit F-01: diskon pada pesanan LUNAS mengubah total setelah uang tercatat
update public.pesanan set status='lunas' where id='eeee0000-0000-0000-0000-000000000010';
select uji.sama((select total from public.pesanan where id='eeee0000-0000-0000-0000-000000000010'),
                62100, 'kontrol: total pesanan lunas sebelum diskon = 62100');
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir (beri_diskon 25.000 / 5%)
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', 5, 2700, 'diskon setelah lunas (probe)');
select uji.sama((select total from public.pesanan where id='eeee0000-0000-0000-0000-000000000010') < 62100,
                true, 'F-01 NYATA: total pesanan LUNAS berubah setelah diskon disisipkan');
reset role; select uji.klaim(null);
