-- T1-30: menegakkan DoD pencabutan EXECUTE PUBLIC, bukan izin bisnis baru.
-- Inventaris skema efektif menemukan 20 SECURITY DEFINER returns trigger
-- dengan ACL default PUBLIC. PostgreSQL tidak mengizinkan pemanggilan trigger
-- sebagai RPC biasa; ini higiene least-privilege, bukan klaim eksploit baru.
-- Hak EXECUTE diperiksa saat CREATE TRIGGER, bukan saat trigger terpanggil:
-- transaksi kasir/pegawai tetap memakai trigger yang sudah terpasang.
-- Daftar eksplisit agar objek lain/ekstensi/custom di produksi tidak tersapu.
-- 0001–0016 tetap beku; tidak mengubah body/policy/peran/RLS atau data.
revoke all on function
  public.picu_diskon_awal_pesanan(),
  public.picu_diskon_batas(),
  public.picu_diskon_hitung_total(),
  public.picu_diskon_setuju_jujur(),
  public.picu_item_harga_jujur(),
  public.picu_item_pesanan_konsisten(),
  public.picu_izin_peran_bawaan(),
  public.picu_jaga_keanggotaan_cabang(),
  public.picu_jaga_menu_cabang(),
  public.picu_metode_bayar_bawaan(),
  public.picu_pembatalan_jejak(),
  public.picu_pembatalan_sah(),
  public.picu_pembayaran_jujur(),
  public.picu_pengaturan_jejak(),
  public.picu_penyewa_tambahan(),
  public.picu_pesanan_konsisten(),
  public.picu_stok_arah_jujur(),
  public.picu_stok_jumlahkan(),
  public.picu_stok_pergerakan(),
  public.picu_stok_saldo_awal()
from public, anon, authenticated;

grant execute on function
  public.picu_diskon_awal_pesanan(),
  public.picu_diskon_batas(),
  public.picu_diskon_hitung_total(),
  public.picu_diskon_setuju_jujur(),
  public.picu_item_harga_jujur(),
  public.picu_item_pesanan_konsisten(),
  public.picu_izin_peran_bawaan(),
  public.picu_jaga_keanggotaan_cabang(),
  public.picu_jaga_menu_cabang(),
  public.picu_metode_bayar_bawaan(),
  public.picu_pembatalan_jejak(),
  public.picu_pembatalan_sah(),
  public.picu_pembayaran_jujur(),
  public.picu_pengaturan_jejak(),
  public.picu_penyewa_tambahan(),
  public.picu_pesanan_konsisten(),
  public.picu_stok_arah_jujur(),
  public.picu_stok_jumlahkan(),
  public.picu_stok_pergerakan(),
  public.picu_stok_saldo_awal()
to service_role;
