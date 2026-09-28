-- ============================================================================
-- 0021 · kunci tulis diskon — serialisasi jalur cap (temuan AUD-3 F-12, K-1 DUGAAN)
-- ----------------------------------------------------------------------------
-- Temuan: hitung-ulang uang + cap diskon tanpa serialisasi eksplisit — dua kasir
-- yang mencatat diskon bersamaan sama-sama membaca jumlah lama lalu saling menimpa
-- (write-skew): cap jebol tanpa satu pun error.
--
-- Bukti mekanisme (analisis, bukan tebakan — PGlite satu koneksi sehingga dua
-- transaksi nyata belum bisa dijalankan di lingkungan uji):
--   1. `hitung_total` (§6 `0015`) SUDAH mengunci baris pesanan — tetapi kuncinya
--      diambil di pemicu AFTER (`diskon_hitung_total`), yaitu SESUDAH keputusan
--      cap dibuat di pemicu BEFORE (`diskon_batas`, tanpa kunci). Kunci AFTER
--      menyeragamkan hitungan, bukan penerimaan.
--   2. `hitung_total` TIDAK menegakkan cap (hanya menjumlahkan + menjepit ke nol;
--      komentarnya memercayakan cap ke "pemicu diskon") — jadi penerimaan ganda
--      tidak pernah ditolak sesudahnya.
--   3. Tidak ada konstrain unik/pengecualian di `diskon_transaksi` sebagai jaring
--      terakhir.
-- Perbaikan: baris pesanan DIKUNCI (`for update`) di pemicu BEFORE PERTAMA
-- (`diskon_awal_pesanan` — berjalan paling dulu menurut abjad) — pola yang sama
-- dengan kunci pembayaran 0012 (PR-16). Akibatnya penulisan diskon kedua menunggu
-- sampai yang pertama ter-commit, lalu pemeriksaannya (status + cap) melihat angka
-- yang benar. Efek samping yang disengaja: pemeriksaan status lunas/batal ikut
-- stabil terhadap pembayaran bersamaan (jalur bayar juga mengunci baris yang sama).
--
-- Batas jujur: uji dua-transaksi-nyata tetap menunggu lingkungan (sama seperti
-- F-13); yang dijaga mesin = SIFAT kunci (ada di badan kedua fungsi) lewat
-- `supabase/tes/uang_kunci.sql` + mutasi wajib-MERAH `alat/uji-mutasi-0021.py`.
-- Temuan tetap TERBUKA (dipagari) sampai uji concurrency bisa dijalankan.
-- ============================================================================

create or replace function public.picu_diskon_awal_pesanan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan_id uuid;
  v_status     text;
begin
  -- Baris yang dihapus tidak punya NEW; ambil id dari sisi yang tersedia.
  if tg_op = 'DELETE' then
    v_pesanan_id := old.pesanan_id;
  else
    v_pesanan_id := new.pesanan_id;
  end if;

  -- KUNCI BARIS PESANAN (temuan AUD-3 F-12, K-1 DUGAAN): tanpa `for update` di
  -- pemicu BEFORE pertama ini, dua penulisan diskon bersamaan sama-sama membaca
  -- jumlah/cap lama lalu saling menimpa (kunci AFTER di hitung_total datang
  -- terlambat untuk keputusan penerimaan). Dengan mengunci barisnya, penulisan
  -- kedua menunggu sampai yang pertama ter-commit dan melihat angka yang benar —
  -- pola yang sama dengan kunci pembayaran 0012 (PR-16).
  select p.status into v_status
    from public.pesanan p where p.id = v_pesanan_id
     for update;

  if v_status in ('lunas', 'batal') then
    raise exception 'Pesanan yang sudah % tidak boleh lagi ditambah/diubah/dihapus diskonnya — uang sudah tercatat. Jalur sah: pembatalan/void resmi (berikut persetujuan PIN atasan bila dapur sudah mulai).', v_status;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end
$$;
