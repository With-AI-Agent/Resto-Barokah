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
| T-002 | 2026-09-16 | **Merek & tipe printer** Kedai Oasis + cara menyambungnya (Bluetooth/USB) | Belum dipakai sampai fase cetak; bisa dibangun lebih dulu dengan jalur cadangan digital | Protokol ESC/POS generik + cadangan digital | **F6 (cetak termal) mulai** | pemilik (tanya pengelola kedai) | [ ] terbuka |
| T-003 | 2026-09-16 | **Daftar perangkat** yang dipakai (Android/iPhone/komputer) | Tidak menghambat: cadangan digital wajib; iPhone hanya perlu uji tambahan | Uji utama Android/Windows (Web Bluetooth didukung) | F11 (uji terima & uji perangkat) | pemilik | [ ] terbuka |
| T-010 | 2026-09-16 | **Pelatihan pegawai & penunjukan admin cabang** Kedai Oasis | Baru dibutuhkan di akhir gelombang; tidak menghambat pembangunan | Panduan pegawai 1 halaman (T11-09) + daftar uji terima | F11 (uji terima & pelatihan) | pemilik | [ ] terbuka |
| T-011 | 2026-09-16 | **Kebijakan privasi & persetujuan data pelanggan** (PRD §10.7) | Harus ada SEBELUM data pelanggan dikumpulkan; sekarang belum ada data siapa pun | Agent menyiapkan draf sederhana berbahasa Indonesia + kotak persetujuan saat pendaftaran | **sebelum F8 (data pelanggan masuk)** | agent (draf) → pemilik (tinjau) | [ ] terbuka |
| T-012 | 2026-09-16 | **Di mana berkas cadangan mingguan disimpan** (akun penyimpanan milik pemilik) | Belum dibutuhkan sampai ada data nyata; sampai itu cadangan diuji ke berkas lokal sesi | Artefak terenkripsi di GitHub Actions (masa simpan 90 hari, gratis) | **sebelum T10-10 selesai** | pemilik | [ ] terbuka |
| T-013 | 2026-09-16 | **Siapa yang boleh menutup shift kasir yang ditinggal pegawai berhenti** | Aturan sementara sudah aman (harus atasan); hanya perlu ditegaskan siapa 'atasan' di Kedai Oasis | Admin cabang atau owner | F7 (kas & shift) selesai | pemilik | [ ] terbuka |

## Butir selesai

| ID | Selesai | Hal | Jawaban/akhirnya |
|---|---|---|---|
| T-001 | 2026-09-16 | Nama produk platform | **Dipakai nama kerja "Sajian"** atas usul agent (pemilik menyerahkan keputusan). Bisa diganti kapan saja tanpa koding — kalau pemilik memilih nama lain, buat butir baru. |
| T-004 | 2026-09-16 | Apakah semua pegawai punya email aktif | **Asumsi: ya**; kalau ada yang belum punya, admin membuatkan email saat penyiapan akun pegawai (opsi sudah ada di T2-03). |
| T-005 | 2026-09-16 | Nilai pajak & service charge, jam operasional, jumlah shift | **Nilai awal: PB1 10% · service 5% · 1 shift.** Nilai nyata diisi saat penyiapan Kedai Oasis; semuanya pengaturan yang bisa diubah tanpa koding. |
| T-006 | 2026-09-16 | Tema bawaan aplikasi | **"Terang Bersih"** (bisa diganti kapan saja, 10 tema sudah tersedia). |
| T-007 | 2026-09-16 | Domain email sendiri untuk Resend | **Mulai tanpa domain khusus** (kirim lewat Resend). Ditinjau ulang bila email verifikasi sering masuk folder spam. |
| T-008 | 2026-09-16 | Alamat domain aplikasi | **Mulai dengan alamat gratis `*.workers.dev`.** Domain sendiri menyusul bila pemilik sudah siap; penggantian tidak butuh ubah kode. |
| T-009 | 2026-09-16 | Aset sistem `skills/` (±26 MB) di repo aplikasi | **Tetap dibawa** — dibutuhkan bootstrap sesi (`alat/mulai-sesi.py`) agar agent baru otomatis memasang skill. Ditinjau ulang bila repo terasa berat. |
