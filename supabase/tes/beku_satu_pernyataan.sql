-- G3 A-F01/A-F03: pembayaran dan perubahan jejak dalam satu statement.
-- 0022 menjaga statement berikutnya, tetapi trigger biasa tidak melihat baris
-- pembayaran dari sibling data-modifying CTE pada snapshot statement yang sama.
-- Regresi ini sengaja mematok BY-201, bukan sekadar "ada error".

insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tipe, catatan, kunci_idempoten)
values ('d3240000-0000-0000-0000-000000000010',
        '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 3240,
        'dinein', 'catatan-awal', 'satu-pernyataan-01');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu,
                                 harga_saat_itu, qty, catatan)
values ('d3240000-0000-0000-0000-000000000011',
        'd3240000-0000-0000-0000-000000000010',
        'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 2, 'item-awal');
-- Panggilan langsung dari jalur peladen memakai role + klaim yang cocok;
-- identitas kosong saja bukan lagi tanda kepercayaan.
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select public.hitung_total('d3240000-0000-0000-0000-000000000010');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Urutan yang terbukti lolos pada target: CTE mencatat uang dahulu, UPDATE utama
-- mengubah jejak. Pagar wajib melihat pembayaran yang lahir dari statement yang sama.
select uji.harap_gagal_sebab($q$
with bayar as (
  insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima,
                                 kunci_idempoten)
  select 'd3240000-0000-0000-0000-000000000010', id, 1, 1,
         'satu-pernyataan-catatan'
    from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and nama = 'Tunai'
  returning id
)
update public.pesanan
   set catatan = 'tidak boleh lolos'
 where id = 'd3240000-0000-0000-0000-000000000010'
$q$, 'BY-201', 'satu-pernyataan header: pembayaran + catatan');

-- Jalur item juga harus tertutup, bukan hanya header.
select uji.harap_gagal_sebab($q$
with bayar as (
  insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima,
                                 kunci_idempoten)
  select 'd3240000-0000-0000-0000-000000000010', id, 1, 1,
         'satu-pernyataan-item'
    from public.metode_bayar
   where penyewa_id = '11111111-1111-1111-1111-111111111111'
     and nama = 'Tunai'
  returning id
)
update public.pesanan_item
   set catatan = 'tidak boleh lolos'
 where id = 'd3240000-0000-0000-0000-000000000011'
$q$, 'BY-201', 'satu-pernyataan item: pembayaran + catatan');

-- Kontrol penting: sebelum ada pembayaran, perubahan jejak tetap sah.
update public.pesanan
   set catatan = 'boleh sebelum bayar'
 where id = 'd3240000-0000-0000-0000-000000000010';
select uji.sama((select catatan from public.pesanan
                  where id = 'd3240000-0000-0000-0000-000000000010'),
                'boleh sebelum bayar',
                'kontrol perubahan sebelum pembayaran');

reset role;
select uji.klaim(null);
