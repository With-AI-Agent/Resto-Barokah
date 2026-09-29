-- UJI F-132: waktu kirim dapur harus dibuat peladen, bukan jam perangkat.
-- RPC hanya menerima id pesanan dan menulis waktu dengan now() pada PostgreSQL.

select uji.klaim(null);
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten
) values (
  'e1320000-0000-0000-0000-000000000001',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  132, current_date, 'dinein', 'draf', 'uji-f132-waktu-peladen'
);
insert into public.pesanan_item (
  pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal
) values (
  'e1320000-0000-0000-0000-000000000001',
  'beef0000-0000-0000-0000-000000000001',
  'Nasi Goreng', 27000, 1, 27000
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- kasir cabang Pusat
set local role authenticated;
select public.kirim_pesanan('e1320000-0000-0000-0000-000000000001');
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'e1320000-0000-0000-0000-000000000001'),
  'dikirim',
  'kasir mengirim pesanan lewat RPC resmi'
);
select uji.sama(
  (select p.dikirim_ke_dapur_pada from public.pesanan p where p.id = 'e1320000-0000-0000-0000-000000000001'),
  now(),
  'waktu kirim berasal dari waktu transaksi pada peladen'
);
select uji.sama(
  public.kirim_pesanan('e1320000-0000-0000-0000-000000000001'),
  (select p.dikirim_ke_dapur_pada from public.pesanan p where p.id = 'e1320000-0000-0000-0000-000000000001'),
  'percobaan ulang tidak mengganti stempel waktu yang sudah sah'
);
select uji.harap_gagal_sebab(
  $$select public.kirim_pesanan(
    'e1320000-0000-0000-0000-000000000001'::uuid,
    '2000-01-01T00:00:00Z'::timestamptz
  )$$,
  'function public.kirim_pesanan',
  'klien tidak dapat mengirim timestamp buatan sebagai argumen RPC'
);
reset role;
select uji.klaim(null);
