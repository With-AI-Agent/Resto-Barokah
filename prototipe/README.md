# Contoh Tampilan (Mockup) — Resto Barokah

> **Status: CONTOH UNTUK DIPERIKSA PEMILIK** (2026-09-16). Bukan aplikasi jadi — angkanya data contoh, tidak ada data yang disimpan.
> Tujuan: supaya pemilik memutuskan dari **tampilan yang bisa dilihat & diklik**, bukan dari penjelasan.
> Ronde 2 → ronde 3: seluruh sistem desain ditulis ulang ("KERAJINAN") sesudah mempelajari ulang gambar kiriman pemilik (P16 Grill & Co., P32 POS).

## Isi folder

| Berkas | Isinya |
|---|---|
| `index.html` | Halaman awal: hero berfoto, 4 kartu pintu masuk (laporan/kasir/katalog/tema), deretan 10 tombol tema, contoh "detail yang membuat terasa mahal", catatan jujur |
| `01-laporan.html` | **Laporan & Pemantauan** — kartu angka + grafik, papan pesanan berlabel status, tabel transaksi, catatan pembatalan, bilah kaca "tutup kas" (lapis mengambang dengan hitung selisih) |
| `02-kasir.html` | **Kasir (POS)** — rel menu berikon, kisi menu berfoto (menu habis terkunci), panel keranjang kaca: Sub total → PB1 10% → Service 5% → Diskon → **Total**, cara bayar, uang diterima/kembalian, lapis bayar & lapis batal berjenjang |
| `03-katalog.html` | **Katalog pelanggan** — tiga layar HP: beranda (hero, kategori bulat, menu favorit, banner promo, bilah keranjang kaca + tombol tengah menonjol), detail menu (level pedas, porsi, tambahan, jumlah), halaman voucher undang-teman |
| `04-tema.html` | **Galeri 10 tema** — tiap tema dalam kartu berisi HP mini, palet warna + kode heksa (dibaca dari warna aslinya), tombol "Pakai tema ini" |
| `css/tokens.css` | **Sistem desain** (v3 "KERAJINAN"): 10 tema, 13 `@font-face` lokal, token 3 lapis (primitif → semantik → komponen), tangga jarak 4 px, tangga huruf, 4 tingkat bayangan berwarna, glow, kaca/blur, pola, seluruh komponen + mode kurangi gerak |
| `js/ui.js` | Tanpa pustaka luar: pemilih 10 tema (dibangun otomatis, swatch dibaca dari warna asli), 2 kerapatan, keranjang hidup (hitung ulang tiap angka berubah), Cek voucher (hanya membaca) & Pakai voucher, lapis mengambang (Esc/klik luar menutup), pesan singkat (toast), animasi masuk berjenjang, jam berjalan |
| `aset/*.jpg` (13 foto) | **Foto contoh buatan** — nasi goreng, ayam geprek, mie ayam, sate, gado-gado, kopi susu, es teh, es kelapa, pisang goreng, kue coklat, banner, interior, hero. Nanti diganti foto asli Kedai Oasis |
| `aset/font/*.woff2` (19 berkas, 13 keluarga) | Huruf dari `skills/ui-styling/canvas-fonts` (lisensi OFL, berkas lisensi ikut disimpan), dirampingkan ke woff2 **504 KB** — tampil sama walau internet mati |
| `uji-kontras.py` | Uji otomatis: **130 pemeriksaan kontras** (13 pasangan × 10 tema) + **36 aturan desain** (kelengkapan token, tangga jarak/huruf, area sentuh, cincin fokus, kurangi gerak, bayangan berlapis, huruf tersimpan) |
| `alat/periksa-halaman.py` | Periksa halaman: aset ada, id lapis mengambang cocok, kaitan JS ada, tag seimbang, 10 tema tersedia, token terdefinisi |
| `alat/gambar.js` + `alat/mockup.js` | Penggambar **papan bukti** (Node + `@napi-rs/canvas`) yang membaca warna dari `tokens.css` dan huruf asli dari skill → hasil: 5 papan di `docs/desain/mockup/` |
| `buat-palet.py` | Menggambar `docs/desain/palet-tema.png` (warna & nama huruf dibaca langsung dari `tokens.css`) |
| `buat-galeri-tema.py` | Membuat `04-tema.html` dari satu daftar tema (10 kartu jadi seragam, tidak ada salah tulis) |

## Cara melihat

**Cara 1 — lewat pratinjau:** server contoh tampilan sudah dinyalakan, halaman langsung terbuka.

**Cara 2 — di komputer sendiri:**
```bash
cd prototipe
python3 -m http.server 8080      # lalu buka http://localhost:8080
```
Bisa juga dibuka langsung dengan klik-dua-kali `index.html` (tanpa server pun jalan).

## Sepuluh tema

| # | Tema | Kesan | Rujukan / arah gaya | Huruf (judul + isi) |
|---|---|---|---|---|
| 1 | **Terang Bersih** *(bawaan)* | Bersih & terang, paling mudah dibaca kasir | gambar pemilik P16/P08 | Outfit + Work Sans |
| 2 | **Hangat Kedai** | Krem & coklat, ramah | P15 Brew & Bliss, P22 | Lora + Work Sans |
| 3 | **Gelap Dapur** | Gelap, nyaman untuk dapur & malam | P17 Jaegar Resto, P03, P31 | Outfit + Work Sans |
| 4 | **Kontras Tinggi** | Hitam-putih, garis tegas (aksesibilitas) | — | huruf sistem |
| 5 | **Bara Panggang** | Arang + emas, judul HURUF BESAR | **gambar yang pemilik kirim (P16)** | Big Shoulders + Instrument Sans |
| 6 | **Vintage Klasik** | Kertas tua, marun, pola bintik | arah gaya `vintage-analog-retro-film` | Arsenal SC + Crimson Pro |
| 7 | **Alam Hijau** | Hijau daun, membulat lembut, pola daun | arah gaya `organic-biophilic` | Gloock + Work Sans |
| 8 | **Tropis Segar** | Teal laut, ceria, pola ombak | disusun sendiri¹ | Outfit + Work Sans |
| 9 | **Pastel Manis** | Pastel lembut, bayangan ganda | arah gaya `claymorphism` | Bricolage Grotesque + Outfit |
| 10 | **Etnik Nusantara** | Ivory, terakota, pola batik | disusun sendiri¹ | Young Serif + Work Sans |

¹ *Jujur: saat ditanyakan ke basis data skill (`ui-ux-pro-max`), tidak ada padanan yang cocok untuk kedua arah ini — jadi nilai warnanya disusun sendiri, bukan hasil pencarian basis data.*

**Menambah tema baru itu murah** — sekitar 35 baris nilai warna + huruf, tanpa menyentuh susunan layar.

## Dua tingkat kepadatan (khusus layar kasir)

- **Mode Kasir (padat):** tanpa keterangan panjang, kisi 4 kolom → banyak menu terlihat, cepat melayani antrean.
- **Mode Katalog (nyaman):** kartu berfoto 3 kolom → untuk pameran menu/tablet pelanggan.

## Hasil uji aturan wajib

| Aturan | Hasil |
|---|---|
| Kontras teks ≥ 4,5:1 · elemen ≥ 3:1 | **130 dari 130 LOLOS** di 10 tema (`python3 uji-kontras.py`) |
| 36 aturan desain (tangga jarak, huruf, sentuh, fokus, bayangan, huruf offline) | **36 dari 36 LOLOS** — total **166 lolos, 0 gagal** |
| Halaman & aset | **183 dari 183 LOLOS** (`python3 alat/periksa-halaman.py`) |
| Area sentuh ≥ 44 px | `.btn`, `.input`, `.tab`, `.tombol-tambah`, `.nav-bawah a` ≥ 44 px; `.btn-sm` & tombol segmen diperluas ke ~44–52 px lewat lapisan tak terlihat |
| Cincin fokus keyboard | Aturan `:where(a,button,summary,input,…):focus-visible` + 4 komponen khusus |
| Huruf dasar 16 px, jarak baris 1,5 | Terpasang di `tokens.css` |
| Ikon vektor (bukan emoji) | Semua ikon SVG sebaris |
| Umpan balik tiap aksi | Tambah/kurang, toast, "Cek voucher", metode bayar, tutup kas |
| Kurangi gerak | `prefers-reduced-motion` mematikan animasi (daun bukti: bagian `@media` di `tokens.css`) |
| Bahasa | Seluruhnya Bahasa Indonesia, tanpa istilah asing bila ada padanan |

## Perlengkapan yang dipakai (skill terpasang)

| Skill | Yang diambil |
|---|---|
| `design-system` | Arsitektur token 3 lapis (primitif → semantik → komponen) |
| `ui-ux-pro-max` | Arah gaya & palet (vintage film, biophilic, claymorphism, OLED), pasangan huruf |
| `ui-styling` | 13 huruf dari `canvas-fonts` (OFL) + huruf TTF asli untuk papan bukti |
| `frontend-designer`, `web-design-guidelines` | Kontras, area sentuh, fokus keyboard, kurangi gerak, mobile-first |
| `brand` | Gagasan identitas: tema = merek resto, bukan merek platform |

## Yang sengaja BELUM ada di contoh ini

Masuk & PIN · pengiriman pesanan ke dapur (KDS penuh) · cetak struk/tiket · penyimpanan data · hak akses per peran ·
pengaturan resto · tampilan pemilik platform. Semuanya dikerjakan di **Tahap 3 (rancangan teknis)** dan tahap pengembangan.

## Setelah pemilik menyetujui

1. Tema bawaan & pola layar dikunci di `docs/desain/RENCANA_DESAIN_UI.md`.
2. Sistem desain ini dipakai sebagai acuan **Tahap 3 — Tech Spec** (teknologi, struktur data, keamanan).
3. Foto contoh diganti foto asli Kedai Oasis lewat Pengaturan (tanpa koding).
