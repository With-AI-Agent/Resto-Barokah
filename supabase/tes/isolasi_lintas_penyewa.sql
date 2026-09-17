-- ============================================================================
-- UJI: isolasi lintas penyewa untuk PINTU FUNGSI (bukan hanya baris/RLS)
-- Temuan audit AUD-3 (2026-09-17, dua laporan) — dua pintu SECURITY DEFINER
-- membocorkan data resto lain kepada pegawai biasa:
--   1) public.total_dibayar(uuid)  → angka uang pesanan resto lain terbaca;
--   2) public.izin_efektif_untuk() & public.boleh_untuk() → izin + batas diskon
--      pegawai resto lain terbaca.
-- RLS hanya menjaga TABEL; fungsi SECURITY DEFINER melewati RLS — karena itu uji
-- ini memeriksa PINTU FUNGSI-nya, bukan tabelnya.
-- ============================================================================

-- Data uji milik RESTO B (dibuat sebagai pemilik tabel, di luar RLS).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b001', '22222222-2222-2222-2222-222222222222',
        'b1b1b1b1-0000-0000-0000-000000000001', 92, current_date, 'dinein', 'draf',
        0, 0, 0, 0, 'isolasi-pesanan-b');
-- Pesanan resto B diberi total (sebagai pemilik tabel, jalur peladen) supaya uangnya bisa dicatat —
-- sejak temuan K-1, pembayaran hanya sah bila total pesanan sudah dihitung.
update public.pesanan set subtotal = 777000, total = 777000
 where id = '00000000-0000-0000-0000-00000000b001';
insert into public.pembayaran (id, pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000b001',
        'Tunai', 'tunai', 777000, 777000, 'isolasi-bayar-b');
insert into public.izin (pengguna_id, kode_izin, boleh, batas_nominal, batas_persen)
values ('90000000-0000-0000-0000-000000000007', 'beri_diskon', true, 777000, 99);

-- 1. Kasir Kedai Oasis (resto A) tidak bisa membaca uang resto B lewat fungsi.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  public.total_dibayar('00000000-0000-0000-0000-00000000b001'),
  0,
  'total_dibayar(pesanan resto B) = 0 untuk kasir resto A (tidak bocor)'
);
-- kontrol positif: pesanan restonya sendiri tetap terbaca angkanya
insert into public.pembayaran (pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 5000, 5000, 'isolasi-bayar-a'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';
select uji.sama(
  public.total_dibayar('eeee0000-0000-0000-0000-000000000010'),
  5000,
  'kontrol: total_dibayar(pesanan restonya sendiri) tetap benar'
);

-- 2. Pintu izin pegawai lain TERTUTUP untuk klien (hak execute dicabut dari authenticated).
select uji.harap_gagal(
  $$select * from public.izin_efektif_untuk('90000000-0000-0000-0000-000000000007', 'beri_diskon')$$,
  'klien tidak lagi bisa memanggil izin_efektif_untuk (pintu izin pegawai lain)'
);
select uji.harap_gagal(
  $$select public.boleh_untuk('90000000-0000-0000-0000-000000000007', 'beri_diskon')$$,
  'klien tidak lagi bisa memanggil boleh_untuk'
);
-- kontrol positif: izin DIRI SENDIRI tetap bisa dibaca (jalur yang dipakai aplikasi)
select uji.sama(
  (select ie.batas_nominal from public.izin_efektif('beri_diskon', 'a1a1a1a1-0000-0000-0000-000000000001') ie),
  25000,
  'kontrol: izin diri sendiri tetap terbaca lewat izin_efektif()'
);
reset role;
select uji.klaim(null);
