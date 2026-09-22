-- G3 A-F02: identitas kosong tidak membuktikan pemanggil adalah peladen.
-- Data nyata/non-kosong; kontrol tenant sah, tenant asing, role dan klaim dipisah.
insert into public.pesanan(id,penyewa_id,cabang_id,nomor,kunci_idempoten)
values ('d3240000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111',
'a1a1a1a1-0000-0000-0000-000000000001',3241,'null-identitas-1'),
('d3240000-0000-0000-0000-000000000002','11111111-1111-1111-1111-111111111111',
'a1a1a1a1-0000-0000-0000-000000000001',3242,'null-identitas-2');
insert into public.pesanan_item(pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
select id,'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,2
from public.pesanan where id in ('d3240000-0000-0000-0000-000000000001','d3240000-0000-0000-0000-000000000002');

-- Kontrol penyewa A ber-identitas: pembayaran sendiri terbaca dan hitungan sendiri sah.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembayaran(pesanan_id,metode_id,jumlah,diterima,kunci_idempoten)
select 'd3240000-0000-0000-0000-000000000001',id,1,1,'null-bayar'
from public.metode_bayar where penyewa_id='11111111-1111-1111-1111-111111111111' and nama='Tunai';
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),1,'A02-kontrol-sah: uang tersedia');
select uji.harap(public.hitung_total('d3240000-0000-0000-0000-000000000002') > 0,'A02-kontrol-hitung: tenant sah');
reset role;

-- Kontrol tenant B: pesanan penyewa A tetap tertutup.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),0,'A02-kontrol-asing');
select uji.harap_gagal_sebab($$select public.hitung_total('d3240000-0000-0000-0000-000000000002')$$,
 'Pesanan itu bukan milik resto Anda.', 'A02-asing-hitung');
reset role;

-- Inti A-F02: role authenticated TANPA sub tidak boleh membuka RPC definer.
select uji.klaim(null);
set local role authenticated;
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),0,'A02-null-baca: bukan bypass');
select uji.harap_gagal_sebab($$select public.hitung_total('d3240000-0000-0000-0000-000000000002')$$,
 'Pesanan itu bukan milik resto Anda.', 'A02-null-tulis: bukan bypass');

-- Klaim JSON service_role saja tidak cukup bila role SQL masih authenticated.
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),0,'A02-klaim-palsu-baca');
select uji.harap_gagal_sebab($$select public.hitung_total('d3240000-0000-0000-0000-000000000002')$$,
 'Pesanan itu bukan milik resto Anda.', 'A02-klaim-palsu-tulis');
reset role;

-- Jalur service_role yang eksplisit: role sesi dan klaim JWT cocok.
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),1,'A02-service-role-baca');
select uji.harap(public.hitung_total('d3240000-0000-0000-0000-000000000002') > 0,'A02-service-role-hitung');
reset role;

-- service_role tanpa klaim tidak boleh menjadi pengecualian diam-diam.
select uji.klaim(null);
set local role service_role;
select uji.sama(public.total_dibayar('d3240000-0000-0000-0000-000000000001'),0,'A02-service-tanpa-klaim-tertutup');
select uji.harap_gagal_sebab($$select public.hitung_total('d3240000-0000-0000-0000-000000000002')$$,
 'Pesanan itu bukan milik resto Anda.', 'A02-service-tanpa-klaim-tertutup');
reset role;
select uji.klaim(null);
