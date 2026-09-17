-- ============================================================================
-- UJI: STATUS AWAL PESANAN — hanya `draf` dari perangkat
-- Menutup temuan review putaran11 PR-02 (K-3, jejak/status):
--   Penjaga status (`0009`) hanya dipasang pada UPDATE, sehingga kasir bisa membuat
--   pesanan yang LAHIR `batal` (tanpa satu pun baris `pembatalan` → Aturan Bisnis 7
--   dilewati) atau lahir `lunas` (tanpa pembayaran; merusak arti laporan penjualan).
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;

select uji.harap_gagal(
  $$insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
      values ('00000000-0000-0000-0000-00000000a001','11111111-1111-1111-1111-111111111111',
              'a1a1a1a1-0000-0000-0000-000000000001', 801, current_date, 'dinein', 'batal', 'status-batal')$$,
  'pesanan tidak boleh LAHIR berstatus batal (pembatalan wajib berjejak)'
);

select uji.harap_gagal(
  $$insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
      values ('00000000-0000-0000-0000-00000000a002','11111111-1111-1111-1111-111111111111',
              'a1a1a1a1-0000-0000-0000-000000000001', 802, current_date, 'dinein', 'lunas', 'status-lunas')$$,
  'pesanan tidak boleh LAHIR berstatus lunas (belum ada pembayaran)'
);

select uji.harap_gagal(
  $$insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, dikirim_ke_dapur_pada, kunci_idempoten)
      values ('00000000-0000-0000-0000-00000000a003','11111111-1111-1111-1111-111111111111',
              'a1a1a1a1-0000-0000-0000-000000000001', 803, current_date, 'dinein', 'draf', now(), 'status-kirim')$$,
  'pesanan baru tidak boleh membawa tanda kirim ke dapur'
);

select uji.harap_gagal(
  $$insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, dibatalkan_pada, kunci_idempoten)
      values ('00000000-0000-0000-0000-00000000a004','11111111-1111-1111-1111-111111111111',
              'a1a1a1a1-0000-0000-0000-000000000001', 804, current_date, 'dinein', 'draf', now(), 'status-batal-pada')$$,
  'pesanan baru tidak boleh membawa tanda batas/dibatalkan_pada'
);

-- Kontrol: pesanan DRAF biasa tetap boleh dibuat kasir (penjaga tidak menutup jalur sah).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000a005','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 805, current_date, 'dinein', 'draf', 'status-draf-sah');
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000a005'),
  'draf', 'kontrol: kasir tetap bisa membuat pesanan draf biasa'
);

-- Kontrol: jalur PELADEN (pemilik tabel) tetap bebas — penyiapan/impor tidak diblokir.
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'dikirim', 'kontrol: pesanan yang disiapkan data uji tetap berstatus dikirim (jalur peladen bebas)'
);
