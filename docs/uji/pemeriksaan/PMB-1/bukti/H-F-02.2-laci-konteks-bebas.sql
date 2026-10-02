-- PROBE HAKIM H-F-02.2 — apakah "alasan wajib" untuk buka laci TANPA transaksi bisa dilewati?
-- Memanggil RPC sungguhan public.catat_buka_laci (migrasi 0094) dari kursi kasir (authenticated).
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-02.2-laci-konteks-bebas.sql
-- Harapan sehat: hanya konteks 'manual' yang lolos tanpa alasan DITOLAK; konteks lain tanpa transaksi nyata pun wajib beralasan.

-- KONTROL NEGATIF (harus GAGAL ditolak = ALASAN_WAJIB): konteks manual tanpa alasan
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.catat_buka_laci('manual', null)->>'kode'),
  'ALASAN_WAJIB',
  'KONTROL: manual tanpa alasan ditolak'
);

-- UJI 1: klien mengaku konteks cetak_struk_tunai padahal TIDAK ADA transaksi/pembayaran apa pun -> seharusnya ditolak/wajib alasan
select uji.sama(
  (public.catat_buka_laci('cetak_struk_tunai', null)->>'kode'),
  'ALASAN_WAJIB',
  'UJI1: konteks cetak_struk_tunai tanpa transaksi nyata & tanpa alasan -> harus ALASAN_WAJIB'
);

-- UJI 2: konteks karangan sembarang -> seharusnya ditolak (konteks tidak dikenal)
select uji.harap(
  (public.catat_buka_laci('apa_saja_boleh', null)->>'kode') <> 'TERCATAT',
  'UJI2: konteks karangan tanpa alasan tidak boleh TERCATAT'
);
reset role;
