-- ============================================================================
-- UJI: LABEL METODE PEMBAYARAN TIDAK BOLEH DIKARANG
-- Menutup temuan review putaran13 #2 PR-06 (K-3): pembayaran tanpa `metode_id`
-- menerima nama/jenis karangan klien — "Transfer BCA (karangan)" dengan jenis
-- "tunai" tersimpan apa adanya, sehingga rekonsiliasi QRIS/bank kehilangan bahan.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

select uji.harap_gagal_sebab($$insert into public.pembayaran (pesanan_id, kasir_id, metode_id, metode_nama_saat_itu, jenis_saat_itu,
                                   jumlah, diterima, kunci_idempoten)
      values ('eeee0000-0000-0000-0000-000000000010','90000000-0000-0000-0000-000000000004',
              null, 'Transfer BCA (karangan)', 'tunai', 10000, 20000, 'metode-karangan')$$, 'Metode bayar wajib dipilih dari daftar resto — label metode tidak boleh dikarang dari pera', 'pembayaran TANPA metode_id ditolak — label metode tidak boleh dikarang dari perangkat');

-- Jalur sah: metode dari tabel resto, dan LABEL DIAMBIL DARI TABEL (bukan kiriman klien).
insert into public.pembayaran (id, pesanan_id, kasir_id, metode_id, metode_nama_saat_itu, jenis_saat_itu,
                               jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f201','eeee0000-0000-0000-0000-000000000010',
        '90000000-0000-0000-0000-000000000004',
        (select m.id from public.metode_bayar m
          where m.penyewa_id = '11111111-1111-1111-1111-111111111111' and m.jenis = 'tunai' limit 1),
        'NAMA KARANGAN', 'qris', 10000, 20000, 'metode-sah');
select uji.sama(
  (select pb.jenis_saat_itu from public.pembayaran pb where pb.id = '00000000-0000-0000-0000-00000000f201'),
  'tunai', 'jenis pembayaran diambil dari tabel metode_bayar, bukan dari kiriman klien'
);
select uji.sama(
  (select pb.metode_nama_saat_itu = 'NAMA KARANGAN' from public.pembayaran pb where pb.id = '00000000-0000-0000-0000-00000000f201'),
  false, 'nama metode karangan klien ditimpa nama resmi dari tabel'
);
select uji.sama(
  (select pb.kembalian from public.pembayaran pb where pb.id = '00000000-0000-0000-0000-00000000f201'),
  10000, 'kembalian tetap dihitung peladen (20.000 − 10.000)'
);
reset role;
select uji.klaim(null);
