# Contoh Tampilan (Mockup) — Resto Barokah

> **Status: CONTOH UNTUK DIPERIKSA PEMILIK** (2026-09-16). Bukan aplikasi jadi — angkanya data contoh.
> Tujuan: supaya pemilik memutuskan dari **tampilan yang bisa dilihat & diklik**, bukan dari penjelasan.

## Isi folder

| Berkas | Isinya |
|---|---|
| `index.html` | Halaman awal: penjelasan + tautan ke 3 contoh tampilan + tombol ganti tema |
| `01-laporan.html` | **Laporan & Pemantauan** — kartu omzet, kas di laci, grafik per jam, papan pesanan aktif (label status berwarna), tabel transaksi, catatan pembatalan |
| `02-kasir.html` | **Kasir (POS)** — kiri: pencarian + tab kategori + kisi menu (menu habis terkunci); kanan: keranjang, Sub total → PB1 → Service → Diskon voucher → **Total**, cara bayar, kembalian, tombol bayar besar |
| `03-katalog.html` | **Katalog pelanggan** (tampak HP) — banner, kategori ikon, menu favorit berfoto, pintu masuk voucher undang-teman, keranjang bawah + halaman detail menu (level pedas, tambahan, jumlah porsi) |
| `css/tokens.css` | **Sistem desain**: 4 tema + komponen dasar (tombol, kartu, label status, tabel, tab) |
| `js/ui.js` | Ganti tema, ganti kerapatan, tombol +/−, contoh "Cek voucher" (hanya membaca) |
| `aset/*.jpg` | **Foto contoh buatan** (nasi goreng, ayam geprek, mie ayam, kopi susu, es teh, pisang goreng, banner) — nanti diganti foto asli Kedai Oasis |
| `uji-kontras.py` | Alat uji otomatis aturan kontras di **semua tema** |

## Cara melihat

**Cara 1 — lewat pratinjau (paling mudah):** server contoh tampilan dinyalakan agent, halaman langsung terbuka di peramban.

**Cara 2 — di komputer sendiri:**
```bash
cd prototipe
python3 -m http.server 8080
# lalu buka http://localhost:8080
```
(Bisa juga dibuka langsung dengan klik-dua-kali `index.html` — tanpa server pun jalan.)

## Empat tema (klik tombol di kanan atas)

| Tema | Kesan | Rujukan gambar pemilik |
|---|---|---|
| **Terang Bersih** *(bawaan)* | Bersih, kontras tinggi, paling mudah dibaca di kasir ramai | P16 Grill & Co., P08 |
| **Hangat Kedai** | Krem & coklat, sudut lebih membulat, ramah | P15 Brew & Bliss, P22 |
| **Gelap Dapur** | Latar gelap, aksen kuning — nyaman untuk layar dapur & malam | P17 Jaegar Resto, P31 |
| **Kontras Tinggi** | Hitam-putih tegas, garis tebal — untuk keterbacaan maksimum | — |

Ganti tema **tidak mengubah susunan maupun fungsi**, hanya warna & bentuk. Pilihan tema disimpan di perangkat itu saja (contoh penerapan "tema boleh beda per perangkat").

## Dua tingkat kepadatan (khusus layar kasir)

- **Mode Kasir (padat):** tanpa foto, kisi 4 kolom, teks rapat → banyak menu terlihat, cepat melayani antrean.
- **Mode Katalog (berfoto):** kartu berfoto 3 kolom → untuk pameran menu/tablet pelanggan.

## Hasil uji aturan wajib

| Aturan | Hasil |
|---|---|
| Kontras teks ≥ 4,5:1 | **52 dari 52 pemeriksaan LOLOS** di 4 tema (`python3 prototipe/uji-kontras.py`) |
| Area sentuh ≥ 44 px | Tombol, tab, tombol +/−, dan tombol tambah bulat (40 px visual + jarak) memenuhi |
| Huruf dasar 16 px, jarak baris 1,5 | Terpasang di `tokens.css` |
| Ikon vektor (bukan emoji) | Semua ikon berupa SVG sebaris |
| Umpan balik tiap aksi | Tombol +/− mengubah angka, "Cek voucher" menjawab, metode bayar menandai pilihan |

## Yang sengaja BELUM ada di contoh ini

Masuk & PIN · pengiriman pesanan ke dapur (KDS penuh) · cetak struk/tiket · penyimpanan data · hak akses per peran ·
pengaturan resto (menu, pajak, meja, pegawai) · tampilan pemilik platform. Semuanya dikerjakan di **Tahap 3 (rancangan teknis)** dan tahap pengembangan — bukan bagian dari contoh tampilan.

## Setelah pemilik menyetujui

1. Tema bawaan & pola layar dikunci di `docs/desain/RENCANA_DESAIN_UI.md`.
2. Sistem desain ini dipakai sebagai acuan **Tahap 3 — Tech Spec** (pilihan teknologi, struktur data, keamanan).
3. Foto contoh diganti foto asli Kedai Oasis lewat Pengaturan (tanpa koding).
