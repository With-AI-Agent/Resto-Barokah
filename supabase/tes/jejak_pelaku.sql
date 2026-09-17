-- ============================================================================
-- UJI: jejak pelaku uang diisi SISTEM, tidak bisa dikarang klien
-- Temuan audit AUD-3 K-2 (A F-05, 2026-09-17): kolom pelaku diisi dari nilai
-- kiriman klien bila tidak kosong, sehingga kasir bisa menuliskan nama owner
-- (atau rekannya) di baris pembayaran/diskon. Karena barisnya append-only,
-- kesalahan atribusi itu permanen dan merusak laporan "siapa mengerjakan apa".
-- Aturan yang dikunci: pelaku SELALU pemanggil (auth.uid()); nilai lain = DITOLAK.
-- ============================================================================

-- Kasir masuk; sasaran menulis nama owner (pegawai lain di resto yang sama).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal(
  $$insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kasir_id, kunci_idempoten)
      select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 1000,
             '90000000-0000-0000-0000-000000000002', 'jejak-kasir-palsu'
        from public.metode_bayar mb
       where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai'$$,
  'kasir tidak bisa menuliskan nama ORANG LAIN sebagai kasir pembayaran'
);
select uji.harap_gagal(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan, pelaku_id)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2000, 2000, 'uji jejak',
              '90000000-0000-0000-0000-000000000002')$$,
  'kasir tidak bisa menuliskan nama ORANG LAIN sebagai pelaku diskon'
);

-- Kontrol positif: pelaku terisi otomatis dengan pemanggil saat dibiarkan kosong.
insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 1000, 'jejak-kasir-benar'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';
select uji.sama(
  (select pb.kasir_id from public.pembayaran pb where pb.kunci_idempoten = 'jejak-kasir-benar'),
  '90000000-0000-0000-0000-000000000004'::uuid,
  'kasir pembayaran terisi otomatis dengan pemanggil'
);
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2000, 2000, 'uji jejak pelaku');
select uji.sama(
  (select d.pelaku_id from public.diskon_transaksi d where d.alasan = 'uji jejak pelaku'),
  '90000000-0000-0000-0000-000000000004'::uuid,
  'pelaku diskon terisi otomatis dengan pemanggil'
);
reset role;
select uji.klaim(null);
