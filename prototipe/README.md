# Contoh Tampilan (Mockup) — Resto Barokah

> **Status: CONTOH UNTUK DIPERIKSA PEMILIK** (2026-09-16). Bukan aplikasi jadi — angkanya data contoh.
> Tujuan: supaya pemilik memutuskan dari **tampilan yang bisa dilihat & diklik**, bukan dari penjelasan.

## Isi folder

| Berkas | Isinya |
|---|---|
| `index.html` | Halaman awal: penjelasan, daftar halaman contoh, dan daftar 10 tema |
| `01-laporan.html` | **Laporan & Pemantauan** — kartu omzet, kas di laci, grafik per jam, papan pesanan aktif (label status berwarna), tabel transaksi, catatan pembatalan |
| `02-kasir.html` | **Kasir (POS)** — kiri: pencarian + tab kategori + kisi menu (menu habis terkunci); kanan: keranjang, Sub total → PB1 → Service → Diskon voucher → **Total**, cara bayar, kembalian, tombol bayar besar |
| `03-katalog.html` | **Katalog pelanggan** (tampak HP) — banner, kategori ikon, menu favorit berfoto, pintu masuk voucher undang-teman, keranjang bawah; + halaman detail menu (level pedas, tambahan, porsi) |
| `04-tema.html` | **Galeri 10 tema** — semua tema berdampingan dalam satu halaman (tiap kartu memakai tokennya sendiri) |
| `css/tokens.css` | **Sistem desain**: 10 tema + komponen dasar. Token 3 lapis (primitif → semantik → komponen) |
| `js/ui.js` | Ganti tema (10 pilihan), ganti kerapatan, tombol +/−, tombol tambah, contoh "Cek voucher" (hanya membaca) |
| `js/pasang-pemilih-tema.py` | Alat penyisip pemilih tema ke semua halaman (sekali pakai) |
| `aset/*.jpg` | **Foto contoh buatan** (nasi goreng, ayam geprek, mie ayam, kopi susu, es teh, pisang goreng, banner) — nanti diganti foto asli Kedai Oasis |
| `aset/font/*.woff2` (23 berkas) | **13 huruf** dari `skills/ui-styling/canvas-fonts` (lisensi OFL), dirampingkan: **1,4 MB → 311 KB**, disimpan lokal (tanpa internet) |
| `uji-kontras.py` | Uji otomatis kontras **semua tema** (token 3 lapis + urai `var()`) |
| `buat-palet.py` | Membuat gambar ikhtisar palet `docs/desain/palet-tema.png` (warna dibaca dari kode) |

## Cara melihat

**Cara 1 — lewat pratinjau (paling mudah):** server contoh tampilan dinyalakan agent, halaman langsung terbuka.

**Cara 2 — di komputer sendiri:**
```bash
cd prototipe
python3 -m http.server 8080      # lalu buka http://localhost:8080
```
Bisa juga dibuka langsung dengan klik-dua-kali `index.html` (tanpa server pun jalan).

## Sepuluh tema

| # | Tema | Kesan | Rujukan / arah gaya | Huruf |
|---|---|---|---|---|
| 1 | **Terang Bersih** *(bawaan)* | Bersih & terang, paling mudah dibaca kasir | gambar pemilik P16/P08 | Outfit + WorkSans |
| 2 | **Hangat Kedai** | Krem & coklat, ramah | P15 Brew & Bliss, P22 | Lora + WorkSans |
| 3 | **Gelap Dapur** | Gelap, nyaman untuk dapur & malam | P17 Jaegar Resto, P03, P31 | Outfit + WorkSans |
| 4 | **Kontras Tinggi** | Hitam-putih, garis tebal (aksesibilitas) | — | huruf sistem |
| 5 | **Bara Panggang** | Hitam pekat + emas, judul HURUF BESAR tinggi | **gambar yang pemilik kirim (P16)** | BigShoulders + InstrumentSans |
| 6 | **Vintage Klasik** | Kertas tua, marun, bingkai garis ganda | arah gaya `vintage-analog-retro-film` | ArsenalSC + CrimsonPro |
| 7 | **Alam Hijau** | Hijau daun, membulat lembut, hiasan daun | arah gaya `organic-biophilic` | NationalPark + WorkSans |
| 8 | **Tropis Segar** | Teal laut, ceria, hiasan ombak | disusun sendiri¹ | Outfit + WorkSans |
| 9 | **Pastel Manis** | Pastel lembut, bentuk tebal "tanah liat" | arah gaya `claymorphism` | Bricolage + Outfit |
| 10 | **Etnik Nusantara** | Ivory, terakota, hiasan motif batik | disusun sendiri¹ | YoungSerif + WorkSans |

¹ *Jujur: saat ditanyakan ke basis data skill (`ui-ux-pro-max`), tidak ada padanan yang cocok untuk kedua arah ini — jadi nilai warnanya disusun sendiri, bukan hasil pencarian basis data.*

**Menambah tema baru itu murah** — sekitar 30 baris nilai warna + huruf, tanpa menyentuh susunan layar.

## Dua tingkat kepadatan (khusus layar kasir)

- **Mode Kasir (padat):** tanpa foto, kisi 4 kolom → banyak menu terlihat, cepat melayani antrean.
- **Mode Katalog (berfoto):** kartu berfoto 3 kolom → untuk pameran menu/tablet pelanggan.

## Hasil uji aturan wajib

| Aturan | Hasil |
|---|---|
| Kontras teks ≥ 4,5:1 · elemen ≥ 3:1 | **130 dari 130 pemeriksaan LOLOS** di **10 tema** (`python3 prototipe/uji-kontras.py`) |
| Area sentuh ≥ 44 px | Tombol, tab, tombol +/−, dan tombol tambah bulat (kini tepat 44 px) |
| Huruf dasar 16 px, jarak baris 1,5 | Terpasang di `tokens.css` |
| Ikon vektor (bukan emoji) | Semua ikon SVG sebaris |
| Umpan balik tiap aksi | +/−, tombol tambah (centang sebentar), "Cek voucher", metode bayar |
| Kurangi gerak | `prefers-reduced-motion` dihormati (animasi dimatikan) |

## Perlengkapan yang dipakai (skill terpasang)

| Skill | Yang diambil |
|---|---|
| `design-system` | Arsitektur token 3 lapis (primitif → semantik → komponen) |
| `ui-ux-pro-max` | Arah gaya & palet (vintage-analog-retro-film, organic-biophilic, claymorphism, dark-mode-oled), pasangan huruf "Restaurant Menu" |
| `ui-styling` | 13 huruf dari `canvas-fonts` (OFL), dirampingkan ke woff2 |
| `frontend-designer`, `web-design-guidelines` | Kontras, ukuran sentuh, fokus keyboard, kurangi gerak, mobile-first |
| `brand` | Gagasan identitas: tema = merek resto, bukan merek platform |

## Yang sengaja BELUM ada di contoh ini

Masuk & PIN · pengiriman pesanan ke dapur (KDS penuh) · cetak struk/tiket · penyimpanan data · hak akses per peran ·
pengaturan resto · tampilan pemilik platform. Semuanya dikerjakan di **Tahap 3 (rancangan teknis)** dan tahap pengembangan.

## Setelah pemilik menyetujui

1. Tema bawaan & pola layar dikunci di `docs/desain/RENCANA_DESAIN_UI.md`.
2. Sistem desain ini dipakai sebagai acuan **Tahap 3 — Tech Spec** (teknologi, struktur data, keamanan).
3. Foto contoh diganti foto asli Kedai Oasis lewat Pengaturan (tanpa koding).
