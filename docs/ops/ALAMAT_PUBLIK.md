# ALAMAT PUBLIK HALAMAN (bukti deploy T0-09)

> Berkas ini ditulis AGEN dari bukti mesin — bukan dari ingatan. Isinya: alamat publik halaman
> yang sudah naik, tanggal, dan cara memeriksanya sendiri.

- **Alamat:** <https://resto-barokah.fatrizmubarok.workers.dev>
- **Dibuat:** 2026-09-19 · **atas izin pemilik** (Lee menulis "Boleh naik" di chat — deploy publik = tindakan
  tak bisa dibatalkan, jadi izin itu wajib dicatat)
- **Isi halaman:** kerangka aplikasi Fase 0 (halaman contoh + 10 komponen dasar). **Tidak ada** data pelanggan,
  tidak ada menu asli kedai, tidak ada kunci rahasia.
- **Mesin:** Cloudflare Workers + Static Assets, pekerja bernama `resto-barokah`, berkas `aplikasi/wrangler.toml`
- **Bukti deploy:** alur *Naikkan Halaman ke Cloudflare* run `35440300274` (unggahan pertama) dan `35440432817`
  (unggahan ulang + pencatatan alamat) — keduanya **hijau**.
- **Bukti halaman hidup:** pemeriksaan otomatis di dalam alur menjawab **HTTP 200** (anotasi `ALAMAT-PUBLIK`
  pada commit `705ed0f`). Cara memeriksa sendiri: buka alamatnya di peramban, atau jalankan
  `node aplikasi/alat/catat-alamat.mjs` di komputer yang punya token Cloudflare.
- **Cara memperbarui halaman:** buat berkas penanda `aplikasi/SEBAR-HALAMAN`, commit & push, tunggu alur hijau,
  lalu hapus penandanya. (Alur sengaja hanya menyala lewat penanda supaya tidak ada unggahan tak sengaja.)
- **Cara mematikan/menghapus:** minta agent — pekerja bisa dihapus dari dasbor Cloudflare, atau unggah dihentikan
  dengan menghapus pekerja itu. Tidak ada biaya: paket gratis, berkas statis.
- **Catatan kuota:** paket gratis 100.000 permintaan/hari; halaman statis memakai sedikit. Kalau nanti ada
  pekerja (`workers`) yang boros, itu diperiksa di `docs/DECISIONS_LOG.md`.
