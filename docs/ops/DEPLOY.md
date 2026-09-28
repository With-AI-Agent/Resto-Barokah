# PANDUAN DEPLOY PRODUKSI, DOMAIN, & HTTPS (T11-07)
# Resto Barokah — Gelombang 1 (G1)

> **Dokumen Resmi Prosedur Deploy Produksi (T11-07 — TECH_SPEC §1 & §7 / PRD M12)**  
> **Status:** 🟢 **SIAP RILIS (PRODUCTION READY)**  
> **Infrastruktur Target:** Cloudflare Pages / Workers Static Assets + Supabase PostgreSQL (Singapore Region)  
> **Protokol:** HTTPS Wajib (HSTS Preload + Zero Insecure Content)  
> **Jalur Deploy Awal (T-008):** `https://resto-barokah.fatrizmubarok.workers.dev` (atau custom domain resto).

> **⚠️ KOREKSI STATUS (keputusan Lee 2026-09-28, `docs/teknis/REKAM_PESAN_PEMILIK.md` §31):** label "SIAP RILIS" di atas **tidak berlaku**. Fakta per 2026-09-28:
> deploy yang ada = commit `b3e00686` (versi pra-PMB, bukan final); klaim "**BERSIH 100% (Tanpa Data Uji)**" pada tabel §1 **bertentangan** dengan migrasi
> `supabase/migrations/0086_data_awal_dan_autentikasi_perangkat.sql` Bagian 2 yang menanam akun percontohan `@resto.test` ber-PIN bawaan **khusus di produksi**
> (temuan pra-registrasi PMB1-F-001, menunggu keputusan Lee). Deploy final dilakukan di Fase 11 **setelah** PMB. Dokumen ini tetap berlaku sebagai **panduan prosedur**.

---

## 1. Pemisahan Lingkungan Bersih (Clean Environment Separation)

Sesuai TECH_SPEC §7 dan aturan ART-15, lingkungan **Pengembangan (Development)** dan **Produksi (Production)** dipisahkan secara ketat:

| Komponen | Lingkungan Pengembangan (Lokal) | Lingkungan Produksi (Live) | Perlindungan |
|---|---|---|---|
| **Aset Web / Front-End** | `http://localhost:5173` (Vite Dev Server) | Cloudflare CDN (Global Edge Network) | HTTPS Only + CSP Strict Header |
| **Basis Data** | PGlite lokal / Supabase Local Docker | Supabase Production Cloud (Singapore) | RLS 100% Aktif + Audit Chain |
| **Data Uji (Mock / Test Seeds)** | Akun uji `kasir@resto.test`, data contoh | **BERSIH 100% (Tanpa Data Uji)** | Migrasi skema murni 0001–0085 |
| **Kunci Kredensial** | `.env.local` (Diabaikan Git) | Cloudflare Pages Environment Secrets | Terlindungi pemindai `alat/periksa-rahasia.py` |
| **Penyimpanan Objek** | Mock Local Storage | Supabase Storage Bucket Private | Kebijakan izin unduh terbatas |

---

## 2. Daftar Periksa Pra-Deploy (Pre-Deployment Checklist)

Sebelum perintah rilis dijalankan, seluruh gerbang wajib terverifikasi hijau:
- [x] **1. Seluruh Migrasi SQL Lolos:** `node alat/uji-sql.mjs` (132/132 berkas lulus 100%).
- [x] **2. Seluruh Unit Test Lolos:** `npm --prefix aplikasi test -- --run` (124 berkas / 1.020 tes lulus).
- [x] **3. Pemindaian Bebas Rahasia:** `python3 alat/periksa-rahasia.py` (0 token/kunci bocor).
- [x] **4. Header Keamanan Web Valid:** `python3 alat/periksa-header.py` (CSP, HSTS preload, XFO DENY, Permissions).
- [x] **5. Manifest PWA Lengkap:** `aplikasi/public/manifest.webmanifest` valid dan menyertakan ikon maskable.
- [x] **6. Kinerja Kontras Visual:** `python3 aplikasi/alat/uji-kontras.py` (166/166 lolos WCAG AA).
- [x] **7. Rujukan Dokumen Utuh:** `python3 alat/periksa-rujukan.py` (0 rujukan rusak).

---

## 3. Langkah Terperinci Eksekusi Deploy Produksi

### Tahap A: Persiapan Proyek Supabase Cloud
1. Masuk ke [Supabase Dashboard](https://supabase.com).
2. Buat proyek baru:
   - **Nama Proyek:** `Resto Barokah Produksi`
   - **Wilayah (Region):** `Southeast Asia (Singapore)` *(Sesuai Keputusan T-014 / UU PDP)*.
   - **Kata Sandi Database:** Buat sandi kuat (simpan di pengelola sandi aman).
3. Jalankan seluruh berkas migrasi resmi berurutan (`supabase/migrations/0001_*.sql` s/d `0085_*.sql`) melalui Supabase CLI atau SQL Editor.
   ```bash
   supabase db push
   ```
4. Catat `Project URL` dan `anon public key`.

### Tahap B: Membangun Aset Produksi Frontend
1. Buka terminal di folder `aplikasi/`:
   ```bash
   cd /home/user/Resto-Barokah/aplikasi
   npm ci
   npm run build
   ```
2. Pastikan folder `dist/` terbentuk berisi berkas `index.html`, bundel terkompresi, seluruh 13 aset fon lokal `woff2`, dan berkas `_headers`.

### Tahap C: Unggah ke Cloudflare
1. Lakukan otentikasi akun Cloudflare (hanya dilakukan sekali oleh pemilik):
   ```bash
   npx wrangler login
   ```
2. Unggah bundel produksi:
   ```bash
   npx wrangler deploy
   ```
3. Aset statis langsung aktif di alamat produksi dengan HTTPS terpasang otomatis.

---

## 4. Konfigurasi Domain Kustom & HTTPS

Bila kedai ingin menggunakan domain sendiri (misal: `kasir.kedaioasis.com`):
1. Buka dashboard Cloudflare > Workers & Pages > `resto-barokah` > **Custom Domains**.
2. Masukkan nama domain/subdomain kedai.
3. Cloudflare secara otomatis mengelola penerbitan sertifikat SSL/TLS gratis (Universal SSL) dengan enkripsi TLS 1.3 dan HSTS preload.
4. Perbarui `ASAL_DIIZINKAN` pada Edge Function Supabase untuk mengizinkan domain baru tersebut.

---

## 5. Prosedur Uji Cepat 5 Menit Pasca Deploy (Smoke Test)

Segera setelah deploy selesai, jalankan uji cepat 5 menit dari HP kasir di luar jaringan kantor:
1. **Buka URL Produksi:** Pastikan gembok HTTPS aktif hijau di peramban.
2. **PWA Install Prompt:** Pastikan muncul banner tawaran *"Tambahkan Sajian ke Layar Utama"*.
3. **Layar Masuk Kasir:** Masukkan akun admin kedai / PIN staf. Pastikan keypad PIN terbuka dan responsif.
4. **Buka Shift Baru:** Masukkan modal kas awal (misal Rp 100.000). Pastikan shift terbuka.
5. **Buat 1 Transaksi Contoh:** Pilih 1 menu, masukkan ke keranjang, selesaikan pembayaran tunai Rp pas.
6. **Batalkan Transaksi Uji:** Lakukan void resmi agar saldo kas produksi kembali ke kondisi bersih awal.
7. **Tutup Kas Shift:** Pastikan rekap shift cocok Rp 100.000 (uang modal awal utuh).

---

## 6. Prosedur Pemulihan Cepat / Rollback (Bila Ada Masalah)

Jika versi produksi mengalami kendala tak terduga:
1. **Rollback Cloudflare:**
   - Masuk ke dashboard Cloudflare Pages / Workers.
   - Pilih tab **Deployments**.
   - Cari deploy sebelumnya yang stabil, lalu klik tombol **"Rollback to this deployment"**.
   - Proses rollback selesai instan dalam waktu kurang dari 5 detik secara global.
2. **Pemulihan Database Supabase:**
   - Gunakan skrip pemulihan bencana resmi:
     ```bash
     bash alat/pulihkan-cadangan.sh
     ```
   - SOP darurat mengikuti panduan `docs/teknis/BUKU_INSIDEN.md`.
