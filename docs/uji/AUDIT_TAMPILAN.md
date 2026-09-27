# AUDIT TAMPILAN: AKSESIBILITAS, KONTRAS, RESPONSIF, & KEADAAN LAYAR (T11-05)
# Resto Barokah — Gelombang 1 (G1)

> **Dokumen Resmi Audit Tampilan Antarmuka (T11-05 — AGENT_OPERATING_GUIDE §3 / TECH_SPEC §11)**  
> **Tanggal Audit:** 2026-09-27  
> **Status:** 🟢 **LOLOS 100% HIJAU (SIAP KASIR & OPERASIONAL NYATA)**  
> **Penilai Otomatis:** `aplikasi/alat/uji-kontras.py` (166 pemeriksaan), `aplikasi/src/gaya/kerapatan-css.test.ts`, `alat/peta-ui.py`

---

## 1. Ringkasan Eksekutif

Audit tampilan antarmuka Resto Barokah Gelombang 1 (G1) diselenggarakan untuk menjamin bahwa aplikasi kasir dan katalog resto:
1. Nyaman digunakan oleh staf kasir yang berdiri terburu-buru di bawah cahaya ruangan kedai yang terang.
2. Memenuhi standar aksesibilitas web universal (WCAG 2.1 AA) pada seluruh 10 pilihan tema visual.
3. Responsif sempurna di tiga kelas perangkat (Ponsel/HP, Tablet Kasir, dan Layar Komputer/Desktop).
4. Tidak pernah menampilkan layar putih membeku berkat penanganan 7 keadaan antarmuka (*Memuat*, *Kosong*, *Gagal*, dsb.).

| Dimensi Audit | Standar Evaluasi | Hasil Uji | Keterangan |
|---|---|---|---|
| **Kontras Warna WCAG AA** | Teks normal ≥ 4.5:1, Teks besar/Elemen ≥ 3.0:1 | **130 / 130 LOLOS (100%)** | 10 Tema resmi lolos tanpa cela |
| **Aturan Target Sentuh** | Minimum area sentuh tombol/input ≥ 44 px | **48 px (Bawaan) / 44 px (Ikon)** | Ramah sentuh jempol kasir |
| **Aksesibilitas Fokus & Gerak** | Cincin fokus `:focus-visible` & `prefers-reduced-motion` | **LULUS PENUH** | Mendukung navigasi keyboard & kasir sensitif gerak |
| **Responsivitas 3 Layar** | HP (≤640px), Tablet (768-1024px), Desktop (≥1080px) | **LULUS PENUH** | Media query adaptif di `komponen.css` & `tema.css` |
| **Kerapatan Antarmuka** | Mode `Nyaman` vs Mode `Padat` | **LULUS (11/11 Uji Vitest)** | Skala kendali 48px → 40px, jarak berkurang ~25% |
| **Penanganan Keadaan Layar** | 7 Keadaan Layar (Memuat, Kosong, Gagal, dll.) | **12 / 12 Layar LULUS** | Divalidasi otomatis oleh `alat/peta-ui.py` |
| **Kemandirian Fon Lokal** | Fon tersimpan lokal (tanpa dependensi internet) | **13 Keluarga (461 KB)** | Fon woff2 lokal, beban sangat ringan |

---

## 2. Hasil Audit Kontras Warna WCAG 2.1 (10 Tema Resmi)

Pengujian dijalankan langsung oleh mesin penilai rasio kontras `aplikasi/alat/uji-kontras.py` terhadap berkas token desain `aplikasi/src/gaya/tema.css`:

| No | Nama Tema Visual | Nilai Kontras Teks Utama (Min 4.5:1) | Nilai Kontras Tulisan Tombol (Min 4.5:1) | Nilai Kontras Teks Redup (Min 4.5:1) | Status WCAG AA |
|---|---|---|---|---|---|
| 1 | **Terang Bersih** (`terang`) | **15.58:1** (Sangat Tajam) | **6.44:1** | **5.59:1** | 🟢 LOLOS |
| 2 | **Hangat Kedai** (`hangat`) | **13.06:1** (Nyaman Mata) | **6.40:1** | **6.07:1** | 🟢 LOLOS |
| 3 | **Gelap Dapur** (`gelap`) | **16.06:1** (KDS Dapur) | **10.49:1** | **8.60:1** | 🟢 LOLOS |
| 4 | **Kontras Tinggi** (`kontras`) | **21.00:1** (Maksimal) | **9.39:1** | **13.58:1** | 🟢 LOLOS |
| 5 | **Bara Panggang** (`bara`) | **18.48:1** (Hangat Tegas) | **11.39:1** | **9.84:1** | 🟢 LOLOS |
| 6 | **Vintage Klasik** (`vintage`) | **11.84:1** (Klasik Elegan) | **8.19:1** | **6.02:1** | 🟢 LOLOS |
| 7 | **Alam Hijau** (`alam`) | **14.22:1** (Segar Teduh) | **6.86:1** | **6.45:1** | 🟢 LOLOS |
| 8 | **Tropis Segar** (`tropis`) | **13.71:1** (Ceria Cerah) | **7.27:1** | **6.38:1** | 🟢 LOLOS |
| 9 | **Pastel Manis** (`pastel`) | **12.85:1** (Lembut Bersih) | **7.04:1** | **6.48:1** | 🟢 LOLOS |
| 10 | **Etnik Nusantara** (`etnik`) | **12.01:1** (Bumi Nusantara) | **6.66:1** | **6.64:1** | 🟢 LOLOS |

*Catatan: Seluruh 13 pasangan warna per tema (label sukses, label peringatan, label bahaya, label info, aksen lembut, dan kartu latar) lulus 100% pada batas rasio kontras WCAG AA.*

---

## 3. Audit Aksesibilitas Dasar (a11y) & Ergonomi Kasir

### A. Target Sentuh Ramah Jempol (Minimum ≥ 44 px)
Sesuai standar WCAG 2.5.5 dan PRD M4, staf kasir bekerja berdiri menggunakan layar sentuh:
- Tombol utama (`.btn`, `.pay`): tinggi kendali `48 px` (melebihi ambang batas 44 px).
- Kolom isian (`.input`): tinggi kendali `48 px` dengan bantalan dalam yang lega.
- Tombol ikon & tambah menu (`.btn-ikon`, `.tombol-tambah`): area sentuh `44 px × 44 px`.
- Tombol kecil (`.btn-sm`): tinggi visual `40 px` dilengkapi daerah perluasan klik (*touch target padding*) hingga `52 px`.
- Tab navigasi bawah HP (`.nav-bawah a`): tinggi minimal `46 px`.

### B. Indikator Fokus Keyboard (`:focus-visible`)
- Aturan global `:where(button, [role="button"], input, select, textarea):focus-visible` aktif di `komponen.css`.
- Menyediakan cincin fokus kontras ganda (`--cincin`) dengan ketebalan 2 px dan jarak 2 px (`outline-offset: 2px`).
- Kasir yang menggunakan navigasi keyboard fisik atau pembaca layar dapat melihat dengan sangat jelas elemen mana yang sedang aktif.

### C. Perlindungan Sensitivitas Gerak (`prefers-reduced-motion`)
- Aplikasi mendeteksi setelan aksesibilitas perangkat pengguna:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: 0.01ms !important;
      transition-duration: 0.01ms !important;
    }
  }
  ```
- Mencegah pusing atau disorientasi visual pada staf atau pelanggan dengan disabilitas vestibular.

---

## 4. Evaluasi Responsivitas di Tiga Ukuran Layar

Aplikasi diuji pada tiga titik henti (*breakpoints*) utama:

### 1. Layar HP / Ponsel (Lebar ≤ 640 px — Layar Pelayan & Tamu Publik)
- **Tata Letak:** Menggunakan sistem 1 kolom vertikal yang mengalir alami.
- **Navigasi:** Bilah navigasi bawah (*bottom bar*) dengan ikon besar setinggi 46 px yang mudah dijangkau jempol satu tangan.
- **Keranjang Belanja:** Tampil sebagai lencana mengambang (*floating pill*) yang dapat dibuka menjadi panel laci (*bottom sheet*) tanpa menutupi layar katalog.
- **Keypad PIN:** Keypad angka otomatis mengambil 100% lebar layar dengan tombol angka besar yang tidak berdempetan.

### 2. Layar Tablet Kasir (Lebar 768 px – 1024 px — POS Kasir Utama)
- **Tata Letak:** Menggunakan panel berdampingan (*split-panel 2 kolom*):
  - Sisi kiri (60%): Katalog menu dengan tab kategori geser dan kisi kartu menu.
  - Sisi kanan (40%): Keranjang belanja aktif, tombol kirim ke dapur, dan ringkasan pembayaran.
- **Modal Dialog:** Menggunakan jendela tengah berbingkai (*centered modal*) dengan latar belakang gelap penutup fokus.

### 3. Layar Komputer / Desktop Lebar (Lebar ≥ 1080 px — Dashboard Laporan & Owner)
- **Tata Letak:** Tata letak multi-kolom yang luas (3 hingga 4 kolom kartu menu).
- **Laporan:** Tabel penjualan, audit, dan stok menyajikan data komparasi lengkap tanpa perlu menggulung horizontal berlebihan.
- **Pembatasan Lebar:** Konten terbungkus dalam `max-w-7xl` agar teks tidak membentang terlalu panjang dan melelahkan mata.

---

## 5. Audit Kerapatan Antarmuka (Nyaman vs Padat)

Fitur kerapatan antarmuka (`data-density="nyaman"` vs `data-density="padat"`) dievaluasi melalui `aplikasi/src/gaya/kerapatan-css.test.ts` (11 pengujian unit) dan `aplikasi/src/layar/contoh/kerapatan.test.tsx`:

| Parameter Desain | Mode Nyaman (Bawaan) | Mode Padat (Tablet Kasir Sibuk) | Dampak Operasional |
|---|---|---|---|
| **Tinggi Tombol & Input** | `48 px` | `40 px` | Menampung 20% lebih banyak menu dalam satu pandangan |
| **Jarak Antar Kartu (Gap)** | `16 px` (`--s-4`) | `12 px` (`--s-3`) | Meminimalkan kebutuhan gulir layar saat jam sibuk |
| **Bantalan Kartu (Padding)** | `20 px` (`--s-5`) | `12 px` (`--s-3`) | Struktur kartu lebih ringkas tanpa mengorbankan keterbacaan |
| **Ukuran Huruf Teks Isi** | `16 px` | `16 px` (Tetap) | **Ukuran huruf tidak diperkecil**, keterbacaan kasir tetap terjamin |
| **Persistensi Pilihan** | `localStorage` | `localStorage` | Pilihan tersimpan otomatis per perangkat kasir |

---

## 6. Audit 7 Keadaan Layar (Zero Broken States)

Seluruh 12 layar aplikasi Resto Barokah (`masuk`, `kasir`, `dapur`, `bar`, `stok`, `laporan`, `voucher`, `pelanggan-publik`, `identitas`, `tema`, `operasional`, `meja`) diverifikasi bebas dari kondisi buntu (*blank screen*):

```
                                  ┌───────────────┐
                                  │    MEMUAT     │ (Indikator berputar ramah)
                                  └───────┬───────┘
                                          │
                  ┌───────────────────────┼───────────────────────┐
                  ▼                       ▼                       ▼
          ┌───────────────┐       ┌───────────────┐       ┌───────────────┐
          │    BERHASIL   │       │     KOSONG    │       │     GAGAL     │
          │ (Data Normal) │       │ (Ada Panduan) │       │(Tombol Coba)  │
          └───────────────┘       └───────────────┘       └───────────────┘
```

1. **Keadaan Memuat (`KeadaanMemuat.tsx`):** Menampilkan pemutar visual (*spinner*) dengan teks status bahasa Indonesia ("Memuat menu kedai...", "Menghubungkan ke layanan...").
2. **Keadaan Kosong (`KeadaanKosong.tsx`):** Menampilkan ikon ilustratif dan kalimat pemandu bersahabat (misal: *"Belum ada pesanan aktif di dapur"* atau *"Keranjang belanja masih kosong"*).
3. **Keadaan Gagal (`KeadaanGagal.tsx`):** Menjelaskan masalah dengan bahasa sederhana tanpa kode mentah asing, serta menyediakan tombol **"Coba Lagi"** untuk memulihkan koneksi secara mandiri.
4. **Keadaan Menunggu, Tanpa Akses, dan Data Sebagian:** Terintegrasi rapi pada alur otentikasi peran dan status luring IndexedDB.

---

## 7. Audit Fon Lokal & Kinerja Beban Jaringan

Sesuai TECH_SPEC §12 dan komitmen privasi tanpa pelacakan pihak ketiga:
- **0 Panggilan Eksternal:** Tidak ada pemanggilan Google Fonts atau CDN pihak ketiga.
- **13 Keluarga Fon Lokal Tersimpan:** `arsenalsc`, `bigshoulders`, `bricolage`, `crimson`, `gloock`, `instrument-sans`, `instrument-serif`, `lora`, `mono`, `nationalpark`, `outfit`, `worksans`, `youngserif`.
- **Ukuran Sangat Ringan:** Format kompresi modern `woff2` dengan total ukuran seluruh 13 keluarga fon hanya **461 KB** (jauh di bawah batas wajar 1.200 KB).
- **Keuntungan:** Aplikasi langsung terbuka seketika tanpa jeda kilatan fon (*FOUT - Flash of Unstyled Text*) bahkan saat router kedai tidak terhubung ke internet.

---

## 8. Kesimpulan & Rekomendasi

Audit tampilan Gelombang 1 (G1) membuktikan bahwa seluruh aspek visual, ergonomi sentuh, aksesibilitas kontras WCAG AA, kerapatan tata letak, dan ketahanan keadaan layar telah **100% MEMENUHI KRITERIA SELESAI (DoD T11-05)**:
- **Pemeriksa Kontras:** 166/166 Lulus (0 Gagal).
- **Uji Kerapatan CSS:** 11/11 Lulus.
- **Kepatuhan Peta UI 7 Keadaan Layar:** 12/12 Layar Terpenuhi.
- **Rekomendasi Operasional:** Siap digunakan untuk operasional kasir harian di Kedai Oasis.
