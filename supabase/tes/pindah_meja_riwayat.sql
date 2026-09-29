-- UJI F-131: pindah meja harus mengubah pesanan dan menyimpan jejak yang tetap.
select uji.klaim(null);
insert into public.meja (id, cabang_id, nama, area, status)
values
  ('e1310000-0000-0000-0000-000000000001', 'a1a1a1a1-0000-0000-0000-000000000001', 'Meja Asal F131', 'Uji', 'terisi'),
  ('e1310000-0000-0000-0000-000000000002', 'a1a1a1a1-0000-0000-0000-000000000001', 'Meja Tujuan F131', 'Uji', 'kosong');
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, tanggal, tipe, meja_id, status, kunci_idempoten
) values (
  'e1310000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  131, current_date, 'dinein', 'e1310000-0000-0000-0000-000000000001', 'draf', 'uji-f131-pindah'
);

select uji.klaim('90000000-0000-0000-0000-000000000004'); -- kasir cabang Pusat
set local role authenticated;
select public.pindah_meja(
  'e1310000-0000-0000-0000-000000000003',
  'e1310000-0000-0000-0000-000000000001',
  'e1310000-0000-0000-0000-000000000002'
);
select uji.sama(
  (select p.meja_id from public.pesanan p where p.id = 'e1310000-0000-0000-0000-000000000003'),
  'e1310000-0000-0000-0000-000000000002'::uuid,
  'pesanan memakai meja tujuan'
);
select uji.sama(
  (select count(*)::integer from public.pindah_meja_riwayat r
    where r.pesanan_id = 'e1310000-0000-0000-0000-000000000003'
      and r.meja_asal_id = 'e1310000-0000-0000-0000-000000000001'
      and r.meja_tujuan_id = 'e1310000-0000-0000-0000-000000000002'
      and r.pelaku_id = '90000000-0000-0000-0000-000000000004'),
  1,
  'riwayat merekam meja asal, tujuan, dan pelaku'
);
select public.pindah_meja(
  'e1310000-0000-0000-0000-000000000003',
  'e1310000-0000-0000-0000-000000000001',
  'e1310000-0000-0000-0000-000000000002'
);
select uji.sama(
  (select count(*)::integer from public.pindah_meja_riwayat r
    where r.pesanan_id = 'e1310000-0000-0000-0000-000000000003'),
  1,
  'percobaan ulang ke meja yang sama tidak menggandakan riwayat'
);
select uji.sama(
  (select r.dibuat_pada from public.pindah_meja_riwayat r
    where r.pesanan_id = 'e1310000-0000-0000-0000-000000000003'),
  now(),
  'riwayat memakai waktu dari peladen'
);
select uji.sama(
  (select m.status from public.meja m where m.id = 'e1310000-0000-0000-0000-000000000001'),
  'kosong',
  'meja asal dibebaskan setelah pindah'
);
select uji.sama(
  (select m.status from public.meja m where m.id = 'e1310000-0000-0000-0000-000000000002'),
  'terisi',
  'meja tujuan ditandai terisi setelah pindah'
);
select uji.harap_gagal_sebab(
  $$delete from public.pindah_meja_riwayat
     where pesanan_id = 'e1310000-0000-0000-0000-000000000003'$$,
  'permission denied',
  'jejak perpindahan tidak dapat dihapus oleh pengguna aplikasi'
);
reset role;
select uji.klaim(null);
