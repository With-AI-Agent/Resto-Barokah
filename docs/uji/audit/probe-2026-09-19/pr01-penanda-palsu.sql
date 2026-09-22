-- PROBE SAYA (sesi kerja) untuk temuan review PR-01
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir cabang A1
set local role authenticated;

-- 1) KONTROL: tanpa penanda apa pun, item sesudah dapur TIDAK boleh dibatalkan
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status='batal'
     where pesanan_id = 'eeee0000-0000-0000-0000-000000000010'$$,
  'pembatalan', 'kontrol: item sesudah dapur tanpa baris pembatalan → DITOLAK');

-- 2) SERANGAN: kasir memasang penanda transaksi sendiri, lalu mengulang
select set_config('resto.pembatalan_pesanan', 'eeee0000-0000-0000-0000-000000000010', true);
update public.pesanan_item set status='batal'
 where pesanan_id = 'eeee0000-0000-0000-0000-000000000010';

select uji.sama(
  (select count(*) from public.pesanan_item
    where pesanan_id='eeee0000-0000-0000-0000-000000000010' and status='batal'), 1::bigint,
  'HASIL: item SESUDAH DAPUR berhasil dibatalkan tanpa PIN & tanpa jejak');
select uji.sama((select count(*) from public.pembatalan), 0::bigint,
  'HASIL: tidak ada satu pun baris pembatalan');
reset role; select uji.klaim(null);
