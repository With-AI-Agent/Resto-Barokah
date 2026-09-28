# ALAMAT PUBLIK HALAMAN (bukti deploy T0-09)

> Berkas ini ditulis AGEN dari bukti mesin — bukan dari ingatan. Isinya: alamat publik halaman
> yang sudah naik, tanggal, dan cara memeriksanya sendiri.

- **Alamat:** <https://resto-barokah.fatrizmubarok.workers.dev>
- **Pembaruan Terakhir:** 2026-09-28 04:24 WIB · **atas instruksi Lee** ("Lanjut deploy ke Cloudflare dan migrasi Supabase")
- **Isi halaman:** Aplikasi Produksi Lengkap Gelombang 1 (Masuk Pegawai dengan dukungan keyboard fisik, Kasir POS, KDS Dapur/Bar, Pengaturan Cabang & Tema Merek, Status Pemakaian K6, Antrean Offline IndexedDB, Katalog Publik).
- **Mesin:** Cloudflare Workers + Static Assets, pekerja bernama `resto-barokah`, berkas `aplikasi/wrangler.toml`
- **Bukti deploy:** alur *Naikkan Halaman ke Cloudflare* run `36377543616` (commit `a3d543c`) — **HIJAU / SUCCESS**.
- **Bukti halaman hidup:** pemeriksaan otomatis di dalam alur menjawab **HTTP 200** pada `2026-09-28T04:24:45.874Z` (anotasi `ALAMAT-PUBLIK` pada commit `a3d543c`). Terverifikasi via peramban / fetch: layar Masuk Pegawai aktif.
- **Cara memperbarui halaman:** buat berkas penanda `aplikasi/SEBAR-HALAMAN`, commit & push, tunggu alur hijau,
  lalu hapus penandanya. (Alur sengaja hanya menyala lewat penanda supaya tidak ada unggahan tak sengaja.)
- **Cara mematikan/menghapus:** minta agent — pekerja bisa dihapus dari dasbor Cloudflare, atau unggah dihentikan
  dengan menghapus pekerja itu. Tidak ada biaya: paket gratis, berkas statis.
- **Catatan kuota:** paket gratis 100.000 permintaan/hari; halaman statis memakai sedikit. Kalau nanti ada
  pekerja (`workers`) yang boros, itu diperiksa di `docs/DECISIONS_LOG.md`.
