-- PROBE SAYA (versi 2) — PR-08: saldo awal stok tanpa baris buku besar
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin (berizin ubah_stok)
set local role authenticated;
insert into public.stok_bahan (id, penyewa_id, nama, satuan, jumlah)
values ('00000000-0000-0000-0000-00000000f001','11111111-1111-1111-1111-111111111111',
        'Bahan Siluman','kg', 500);
select uji.sama((select jumlah from public.stok_bahan where id='00000000-0000-0000-0000-00000000f001'),
                500::numeric, 'PR-08 NYATA: saldo 500 kg muncul dari ketiadaan');
select uji.sama((select coalesce(sum(jumlah),0) from public.stok_pergerakan
                  where stok_bahan_id='00000000-0000-0000-0000-00000000f001'), 0::numeric,
                'PR-08 NYATA: nol baris buku besar untuk saldo itu');
reset role; select uji.klaim(null);
