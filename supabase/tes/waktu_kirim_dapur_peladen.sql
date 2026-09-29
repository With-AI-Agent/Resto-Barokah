-- ============================================================================
-- UJI: waktu kirim ke dapur = JAM PELADEN, bukan jam perangkat (PMB1-F-132)
-- Antrean dapur diurutkan menurut `dikirim_ke_dapur_pada` (aplikasi/src/hook/useTiketDapur.ts).
-- Dulu nilai kolom itu diambil apa adanya dari `new Date()` perangkat kasir/pelayan → jam HP yang
-- meleset merusak urutan FIFO dapur. Sejak migrasi 0088 pemicu `picu_pesanan_jaga_status` MENIMPA
-- nilai kiriman perangkat dengan `now()` peladen saat draf → dikirim.
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, kunci_idempoten)
values ('e8800000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 'dinein', 'waktu-kirim-peladen');

-- Perangkat mengirim jam yang meleset jauh (tahun 2000).
update public.pesanan set status = 'dikirim', dikirim_ke_dapur_pada = '2000-01-01T00:00:00Z'
 where id = 'e8800000-0000-0000-0000-000000000001';

select uji.sama(
  (select p.dikirim_ke_dapur_pada = now() from public.pesanan p
    where p.id = 'e8800000-0000-0000-0000-000000000001'),
  true, 'waktu kirim ke dapur diisi jam peladen, bukan jam perangkat yang meleset'
);
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'e8800000-0000-0000-0000-000000000001'),
  'dikirim', 'kontrol: pengiriman sah tetap diterima'
);
-- Kontrol negatif: sesudah terkirim, tanda waktu tetap tidak boleh diubah perangkat.
select uji.harap_gagal_sebab($$update public.pesanan set dikirim_ke_dapur_pada = now() + interval '1 hour' where id = 'e8800000-0000-0000-0000-000000000001'$$,
  'Tanda kirim ke dapur tidak boleh diubah atau dihapus', 'tanda waktu kirim tetap terkunci sesudah terkirim');
reset role;
