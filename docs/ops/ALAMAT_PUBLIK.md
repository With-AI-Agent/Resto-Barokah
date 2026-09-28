# ALAMAT PUBLIK HALAMAN (bukti deploy T0-09)

> Berkas ini ditulis AGEN dari bukti mesin — bukan dari ingatan. Isinya: alamat publik halaman
> yang sudah naik, tanggal, dan cara memeriksanya sendiri.

- **Alamat:** <https://resto-barokah.fatrizmubarok.workers.dev>
- **Pembaruan Terakhir:** 2026-09-28 07:51 WIB · **atas instruksi Lee** (Perbaikan tuntas galat login AK-601 [42703 created_at -> dibuat_pada], search_path kripto, SW v2, & pencegahan tabrakan nama perangkat)
- **Isi halaman:** Aplikasi Produksi Lengkap Gelombang 1 (Portal Autentikasi Anggun dengan Kontrol Segmen, Layar Masuk Pegawai dengan PIN & Keyboard Fisik, Layar Masuk Pelanggan Responsif, Service Worker PWA v2, Katalog Menu Digital Publik, Seed Data Kedai Oasis Lengkap).
- **Mesin:** Cloudflare Workers + Static Assets, pekerja bernama `resto-barokah`, berkas `aplikasi/wrangler.toml`
- **Bukti deploy:** alur *Naikkan Halaman ke Cloudflare* run `36393774418` (commit `b3e0068`) — **HIJAU / SUCCESS**.
- **Bukti skema Supabase:** alur *Sebar Skema ke Supabase* run `36393774425` (migrasi `0087_perbaiki_search_path_kripto_dan_rpc.sql`) — **HIJAU / SUCCESS**.
- **Bukti halaman hidup:** pemeriksaan otomatis menjawab **HTTP 200** pada `2026-09-28T07:50:22Z`. Terverifikasi via peramban / fetch: portal masuk Resto Barokah aktif dan mulus.
- **Cara memperbarui halaman:** buat berkas penanda `aplikasi/SEBAR-HALAMAN`, commit & push, tunggu alur hijau,
  lalu hapus penandanya. (Alur sengaja hanya menyala lewat penanda supaya tidak ada unggahan tak sengaja.)
- **Cara mematikan/menghapus:** minta agent — pekerja bisa dihapus dari dasbor Cloudflare, atau unggah dihentikan
  dengan menghapus pekerja itu. Tidak ada biaya: paket gratis, berkas statis.
- **Catatan kuota:** paket gratis 100.000 permintaan/hari; halaman statis memakai sedikit. Kalau nanti ada
  pekerja (`workers`) yang boros, itu diperiksa di `docs/DECISIONS_LOG.md`.
