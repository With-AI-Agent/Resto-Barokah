# DAFTAR TUNGGU (TERTANGGUH) — hal yang ditunda & WAJIB dibaca setiap sesi

> **Atas permintaan pemilik 2026-09-16:** agent bekerja **terus-menerus (mode maraton)** dan hanya berhenti
> kalau benar-benar butuh keputusan pemilik. Hal yang bisa ditunda → **ditunda, DICATAT di sini, lalu kerja lanjut**.
>
> **Aturan mengikat (lihat `docs/AGENT_OPERATING_GUIDE.md` §13):**
> 1. Berkas ini **dibaca setiap sesi** (dibacakan otomatis oleh `alat/mulai-sesi.py` di KARTU SESI) dan **wajib dilaporkan** ke pemilik.
> 2. Butir terbuka **tidak boleh ditutup tanpa jawaban pemilik** — kecuali bisa dibuktikan dari dokumen yang sudah dikunci (tulis alasannya).
> 3. **Batas penumpukan: maksimum 12 butir terbuka.** Lewat itu → agent WAJIB berhenti & meminta pemilik memutuskan.
> 4. **Tenggat mengikat:** butir yang tenggatnya sudah lewat = **hard stop** untuk fase itu.
> 5. Setiap akhir batch, agent menawarkan jawaban untuk semua butir terbuka (pemilik cukup bilang **"setuju semua"**).
> 6. **Yang tidak pernah ditunda:** keamanan/uang/data pelanggan yang belum jelas · biaya apa pun · perubahan keputusan
>    yang sudah dikunci · tindakan merusak/tak bisa dibatalkan (hapus data, force push, deploy publik).

## Cara mencatat butir baru

Tambahkan baris di tabel **Butir terbuka** dengan bentuk:

`| T-000 | 2026-09-16 | <hal yang ditunda> | <kenapa boleh ditunda / tidak menghambat> | <nilai/placeholder yang dipakai sekarang> | <wajib selesai sebelum> | <pemilik/agent> | [ ] terbuka |`

Kalau sudah dijawab → pindahkan barisnya ke tabel **Butir selesai** dengan status `[x] selesai` + tanggal + jawabannya.

## Butir terbuka

| ID | Tanggal | Hal yang ditangguhkan | Kenapa boleh ditunda | Nilai sementara yang dipakai | Wajib selesai sebelum | Dijawab oleh | Status |
|---|---|---|---|---|---|---|---|
| T-001 | 2026-09-16 | **Nama produk platform** (kandidat: Langgan · Baraka · **Sajian** · Rame · Nota) | Tidak menghambat coding: hanya dipakai di judul aplikasi, manifest, dan domain | **"Sajian"** (bisa diganti 1 baris) | F0 tugas manifest PWA | pemilik | [ ] terbuka |
| T-002 | 2026-09-16 | **Merek & tipe printer** Kedai Oasis + cara menyambungnya (Bluetooth/USB) | Belum dipakai sampai fase cetak; bisa dibangun lebih dulu dengan jalur cadangan digital | Protokol ESC/POS generik + cadangan digital | **F6 (cetak termal) mulai** | pemilik (tanya pengelola kedai) | [ ] terbuka |
| T-003 | 2026-09-16 | **Daftar perangkat** yang dipakai (Android/iPhone/komputer) | Tidak menghambat: cadangan digital wajib; iPhone hanya perlu uji tambahan | Uji utama Android/Windows (Web Bluetooth didukung) | F11 (uji terima & uji perangkat) | pemilik | [ ] terbuka |
| T-004 | 2026-09-16 | Apakah **semua pegawai punya email aktif** | Baru relevan saat penyiapan akun pegawai | Email + PIN; bila ada yang belum punya → opsi "admin membuatkan" | F2 (masuk aplikasi) saat penyiapan | pemilik | [ ] terbuka |
| T-005 | 2026-09-16 | **Nilai pajak (PB1) & service charge nyata**, jam operasional, jumlah shift | Semuanya pengaturan yang bisa diubah tanpa koding (bawaan 10% & 5%) | PB1 10% · service 5% · 1 shift | F7 (kas & laporan) saat penyiapan Kedai Oasis | pemilik | [ ] terbuka |
| T-006 | 2026-09-16 | **Tema bawaan aplikasi** (rekomendasi agent: "Terang Bersih") | Bisa diganti kapan saja tanpa koding (10 tema sudah jadi) | "Terang Bersih" | F9 (pengaturan tampilan) | pemilik | [ ] terbuka |
| T-007 | 2026-09-16 | **Domain email sendiri** untuk pengiriman email verifikasi (Resend) | Email bisa jalan tanpa domain (batas lebih kecil & nama pengirim kurang rapi) | Kirim lewat Resend tanpa domain khusus | F8 (voucher/pelanggan) saat uji email nyata | pemilik | [ ] terbuka |
| T-008 | 2026-09-16 | **Alamat domain aplikasi** (mis. sajian.app) | Baru dipakai saat deploy produksi | Domain sementara dari Cloudflare (gratis, *.workers.dev) | F11 (deploy produksi) | pemilik | [ ] terbuka |
| T-009 | 2026-09-16 | **Aset sistem `skills/` (±26 MB) tetap dibawa di repo aplikasi?** | Tidak menghambat; hanya soal berat repo & kecepatan unduh | Tetap dibawa (dibutuhkan bootstrap skill tiap sesi) | F0 (rapikan repo aplikasi) | pemilik | [ ] terbuka |

## Butir selesai

| ID | Selesai | Hal | Jawaban/akhirnya |
|---|---|---|---|
| — | — | (belum ada) | — |
