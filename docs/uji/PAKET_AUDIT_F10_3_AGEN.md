# PAKET AUDIT INDEPENDEN FASE 10 — RESTO BAROKAH (3 AGEN)

> **Status:** RESMI & SIAP PAKAI (Disiapkan pada 2026-09-27 setelah penyelesaian tuntas Fase 10 / T10-16).  
> **Target Cabang:** `arena/01a0d09b-resto-barokah`  
> **Komitmen:** 153/193 tugas roadmap tuntas. 0 toleransi kerentanan (`npm audit` 0), 132/132 berkas uji SQL lulus, 126 gerbang CI aktif.

---

## 1. Konteks Arsitektur & Peran Pemilik Platform

Sebelum memulai pengujian, setiap agen pemeriksa **WAJIB** memahami model bisnis dan batasan peran arsitektural Resto Barokah:
1. **Lee adalah Pemilik Platform (SaaS Vendor / `pemilik_platform`),** BUKAN sekadar pemilik satu warung fisik.
   - Aplikasi Resto Barokah dirancang untuk disewakan/dijual secara multi-tenant ke ratusan pemilik resto/kafe/kedai (`owner_pusat`).
   - Setiap resto penyewa memiliki cabang-cabangnya sendiri (`cabang_id`), dikelola oleh `admin_cabang`, dan dioperasikan oleh staf kedai (`kasir`, `pelayan`, `dapur`).
2. **Prinsip Isolasi Mutlak Multi-Tenant (ART-1):**
   - Tidak boleh ada data transaksi, shift, menu, meja, atau keuangan resto A yang bocor atau terlihat oleh resto B.
   - Seluruh tabel publik wajib ber-RLS aktif (`relrowsecurity = true`) dan memfilter berdasarkan `penyewa_saya()` atau tolak-semua.
3. **Prinsip Kekekalan Jejak Audit (ART-13):**
   - Transaksi yang sudah lunas tidak boleh diubah/dihapus secara sembunyi-sembunyi.
   - Seluruh mutasi kas, selisih shift, pembatalan pesanan (void), diskon manual, perubahan konfigurasi, dan pencabutan sesi wajib mencatat entri kriptografis di `public.catatan_audit`.
4. **Prinsip Fail-Closed & Zero Silent Failure:**
   - Setiap kondisi tidak sah wajib melempar eksepsi eksplisit (`raise exception` kode `P0001` atau HTTP 4xx), bukan gagal diam-diam.
5. **Aturan Kerja Agen Pemeriksa:**
   - Agen bekerja secara **hanya-baca (read-only)** pada cabang `arena/01a0d09b-resto-barokah`.
   - Dilarang mengubah kode, membuat commit, atau memodifikasi migrasi database.
   - Setiap temuan wajib dibuktikan dengan perintah eksekusi nyata beserta keluarannya.

---

## 2. Klasifikasi Tingkat Temuan (Severity)

Setiap temuan yang dilaporkan wajib dikategorikan ke salah satu dari 4 tingkat berikut:
- **K-1 (Kritis / Blocker):** Kebocoran data antar-tenant, pencurian uang/manipulasi saldo kasir, bypass otentikasi/RLS, kunci rahasia bocor di repo, atau kegagalan pemulihan bencana.
- **K-2 (Tinggi):** Inkonsistensi data transaksi, tombol antarmuka liar tanpa aksi backend, gagal kirim offline yang menduplikasi pesanan di peladen, atau kegagalan gerbang CI.
- **K-3 (Sedang):** Ketidaksesuaian pesan kesalahan, isu aksesibilitas kontras di tema tertentu, performa kueri lambat, atau perbaikan tata letak UI minor.
- **K-4 (Rendah / Saran):** Rekomendasi perapian kode, penambahan komentar teknis, atau saran penyempurnaan di fase mendatang (Fase 11+).

---

## 3. Paket Pemeriksaan AGEN 1: Spesialis Basis Data, Keamanan SQL & Multi-Tenant

### A. Mandat & Lingkup Kerja
Memeriksa integritas 85 berkas migrasi SQL (`supabase/migrations/`), 132 berkas uji database (`supabase/tes/`), RLS 47 tabel publik, fungsi RPC keuangan dan operasional, perlindungan data sensitif pegawai berhenti, dan ketajaman suite uji mutasi SQL.

### B. Daftar Periksa Wajib Agen 1
1. **Isolasi Multi-Tenant & RLS 47 Tabel:**
   - Verifikasi bahwa seluruh 47 tabel publik mengaktifkan RLS (`relrowsecurity = true`).
   - Verifikasi tidak ada kebocoran baris saat staf Resto A membaca data Resto B.
2. **Kunci Idempoten Menyeluruh (ART-8 / T10-02):**
   - Verifikasi 8 RPC penulisan (`simpan_pesanan`, `bayar_pesanan`, `pakai_voucher`, `buka_shift`, `tutup_shift`, `kas_pergerakan`, `set_stok`, `opname_stok`) menolak duplikasi request dengan kunci sama.
3. **Pencabutan Akses Pegawai Berhenti (T10-12):**
   - Verifikasi RPC `pegawai_berhenti` secara atomik menonaktifkan akun, memutuskan seluruh sesi perangkat, memusnahkan PIN, dan menandai shift terbuka untuk ditutup atasan tanpa merusak nama di riwayat transaksi masa lalu.
4. **Pengaturan Konkurensi Bersamaan (T10-11):**
   - Verifikasi RPC pengaturan menolak penimpaan data versi lama (`p_versi_lama timestamptz`) dengan kode P0001.
5. **Denyut Harian & Retensi Data Sementara (T10-08):**
   - Verifikasi bahwa pembersihan berkala hanya menghapus log sementara (whitelist aman) dan tidak menyentuh tabel inti bisnis.
6. **Ketajaman Pagar Uji Mutasi (Fail-Closed):**
   - Jalankan uji mutasi pada migrasi kunci untuk membuktikan bahwa ketika logika keamanan dirusak sengaja, pengujian SQL terbukti **MERAH**.

### C. Perintah Verifikasi Agen 1
```bash
# 1. Jalankan seluruh suite uji SQL lengkap (132 berkas)
node alat/uji-sql.mjs

# 2. Verifikasi penyisiran RLS 47 tabel publik & uji-diri
python3 alat/periksa-sisir-rls.py
python3 alat/periksa-sisir-rls.py --uji-diri

# 3. Verifikasi cakupan kunci idempoten menyeluruh
python3 alat/periksa-idempoten.py

# 4. Verifikasi matriks izin 6 peran dan fungsi PIN
python3 alat/periksa-matriks-izin.py
python3 alat/periksa-fungsi-pin.py

# 5. Uji ketajaman pagar mutasi SQL (Fail-Closed)
python3 alat/uji-mutasi-0080.py
python3 alat/uji-mutasi-0081.py
python3 alat/uji-mutasi-0082.py
python3 alat/uji-mutasi-0083.py
python3 alat/uji-mutasi-0084.py
python3 alat/uji-mutasi-0085.py
python3 alat/uji-mutasi-0046.py
python3 alat/uji-mutasi-0047.py
python3 alat/uji-mutasi-0049.py
```

---

## 4. Paket Pemeriksaan AGEN 2: Spesialis Frontend, Kepatuhan UI/UX & Peta UI

### A. Mandat & Lingkup Kerja
Memeriksa seluruh layar antarmuka aplikasi di `aplikasi/src/layar/`, verifikasi kepatuhan tombol dan navigasi terhadap `docs/PETA_UI.md`, ketahanan kasir offline (IndexedDB), aksesibilitas kontras WCAG AAA, dan integritas 106+ berkas uji unit Vitest.

### B. Daftar Periksa Wajib Agen 2
1. **Kepatuhan Peta UI (Zero Unmapped Buttons):**
   - Verifikasi dengan mesin bahwa tidak ada tombol antarmuka liar yang tidak terdaftar di `docs/PETA_UI.md`.
   - Verifikasi bahwa setiap aksi terhubung ke izin peran yang sah dan RPC yang sesuai.
2. **Ketahanan Kasir Luring & Antrean IndexedDB (T10-01 s/d T10-04):**
   - Verifikasi modul `antrean-offline.ts` dan hook `useAntrean.ts`.
   - Verifikasi sanitasi data sensitif (PIN kasir tidak tersimpan di antrean IndexedDB).
   - Verifikasi dialog rincian antrean (`StatusAntrean.tsx`): indikator daring/luring, hitungan item tertunda, pesan galat jujur, retry manual per item & massal.
   - Verifikasi skenario simulasi putus-sambung jaringan (`luring.spec.ts`) tidak menduplikasi pesanan.
3. **Aksesibilitas Kontras & Navigasi (WCAG AAA):**
   - Verifikasi 10 tema warna visual (`terang`, `hangat`, `gelap`, `kontras`, dll.) memenuhi rasio kontras teks minimum 4.5:1 (AA) dan 7:1 (AAA).
   - Verifikasi mode kerapatan (`nyaman` vs `padat`).
   - Verifikasi perilaku modal/dialog: tombol Esc menutup modal dan mengembalikan fokus ke elemen pemanggil, klik luar menutup popover.
4. **Layar Pengaturan & Operasional (Fase 9 & 10):**
   - Periksa layar `Identitas.tsx`, `Tampilan.tsx`, `Operasional.tsx`, `Meja.tsx`, `KelolaPegawai.tsx`, `SesiAktif.tsx`, `CabutAkses.tsx`, dan `Peringatan.tsx`.
   - Verifikasi penanganan konflik versi pengaturan (`P0001`) tidak menghilangkan input pengguna.

### C. Perintah Verifikasi Agen 2
```bash
# 1. Jalankan validator Peta UI resmi
python3 alat/peta-ui.py --periksa

# 2. Periksa kesesuaian kontras, kerapatan, dan antarmuka
python3 aplikasi/alat/uji-kontras.py
python3 aplikasi/alat/periksa-kerapatan.py
python3 aplikasi/alat/periksa-antarmuka.py

# 3. Jalankan pengujian unit Vitest (seluruh 106+ berkas uji komponen/hook/lib)
cd aplikasi && npm test -- --run
cd ..

# 4. Jalankan uji ketahanan luring (offline & network flapping)
cd aplikasi && npx vitest run uji/e2e/luring.spec.ts
cd ..

# 5. Uji ketajaman mutasi kode aplikasi
node aplikasi/alat/uji-mutasi-app.mjs
```

---

## 5. Paket Pemeriksaan AGEN 3: Spesialis Infrastruktur, Ketahanan Sistem & SOP Bencana

### A. Mandat & Lingkup Kerja
Memeriksa alur kerja GitHub Actions (126 gerbang CI), keandalan skrip pemulihan bencana PGlite dan latihan Buku Insiden (T10-15), kepatuhan header keamanan Cloudflare (CSP/HSTS/XFO), pemindai kebocoran rahasia (zero-leak), dan tinjauan keamanan MFA / kata sandi bocor (T-016).

### B. Daftar Periksa Wajib Agen 3
1. **Keutuhan Gerbang CI/CD (126 Gerbang Wajib):**
   - Verifikasi bahwa `.github/workflows/ci.yml` menjalankan seluruh pemeriksaan tanpa kelonggaran (`continue-on-error: true` atau `|| true` terlarang).
   - Jalankan mode uji-diri fail-closed pada pemeriksa gerbang CI.
2. **Dril Pemulihan Bencana & Uji Buku Insiden (T10-15):**
   - Jalankan simulasi pemulihan cadangan database ke instans PGlite bersih (*clean slate*).
   - Verifikasi paritas data 100% (47 tabel, 192 baris, seluruh tabel ber-RLS aktif).
   - Jalankan 4 simulasi dril insiden nyata (perangkat kasir hilang, akun dibobol, pegawai keluar mendadak, rekonsiliasi data & privasi pelanggan).
   - Buktikan waktu pemulihan (RTO) jauh di bawah ambang batas darurat 30 menit.
3. **Header Keamanan Peramban (T10-14):**
   - Verifikasi berkas `aplikasi/public/_headers` memuat Content-Security-Policy (CSP) ketat tanpa `unsafe-eval`.
   - Verifikasi `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Permissions-Policy`, dan `Strict-Transport-Security` (HSTS).
   - Jalankan uji verifikasi header dan uji-diri fail-closed.
4. **Pembersihan Rahasia & Audit Dependensi (T10-14):**
   - Jalankan pemindai rahasia `alat/periksa-rahasia.py` di seluruh berkas repo.
   - Verifikasi `npm audit` di folder `aplikasi` dan `alat` mencatat 0 kerentanan (zero vulnerability).
5. **Tinjauan Kode Pemulihan MFA & Kata Sandi Bocor (T-016 / T10-16):**
   - Tinjau analisis pada dokumen `docs/teknis/TINJAUAN_KEAMANAN_F10.md`.
   - Verifikasi efektivitas Tangga Pemulihan Peran Atas dan perlindungan brute-force 5x pada `supabase/tes/mfa.sql`.
   - Verifikasi justifikasi penghematan biaya $25/bulan (kebijakan zero-cost kompensasi tangguh).

### C. Perintah Verifikasi Agen 3
```bash
# 1. Verifikasi gerbang CI/CD dan uji-diri fail-closed
python3 alat/periksa-gerbang-ci.py
python3 alat/periksa-gerbang-ci.py --uji-diri

# 2. Jalankan latihan pemulihan bencana & Buku Insiden (T10-15)
bash alat/pulihkan-cadangan.sh --uji-diri
node alat/eksekusi-latihan-insiden.mjs

# 3. Verifikasi header keamanan peramban & uji-diri
python3 alat/periksa-header.py
python3 alat/periksa-header.py --uji-diri

# 4. Verifikasi pemindaian rahasia seluruh repositori & uji-diri
python3 alat/periksa-rahasia.py
python3 alat/periksa-rahasia.py --uji-diri

# 5. Verifikasi ambang batas ketat audit dependensi
cd aplikasi && npm audit --audit-level=low && cd ..
cd alat && npm audit --audit-level=low && cd ..

# 6. Verifikasi penegakan MFA dan keamanan kredensial SQL
node alat/uji-sql.mjs supabase/tes/mfa.sql
```

---

## 6. Format Laporan Hasil Audit (Wajib Digunakan Setiap Agen)

Setiap agen pemeriksa independen wajib mengirimkan laporannya dengan format terstandar berikut:

```markdown
# LAPORAN PEMERIKSAAN INDEPENDEN FASE 10 — [AGEN 1 / AGEN 2 / AGEN 3]

- **Nama Agen:** [Agen 1: Basis Data & Multi-Tenant / Agen 2: Frontend & UI/UX / Agen 3: Infrastruktur & Bencana]
- **Target Cabang:** `arena/01a0d09b-resto-barokah`
- **Waktu Pemeriksaan:** [Tanggal & Jam]
- **Status Akhir (Verdict):** [BERSIH / PERLU PERBAIKAN / DITOLAK]

## 1. Ringkasan Eksekutif Hasil Uji
[Tuliskan 1-2 paragraf ringkasan temuan dan kualitas sistem di area Anda]

## 2. Bukti Eksekusi Perintah Wajib
- Perintah 1: `[perintah]` -> Keluaran: [LULUS / X LULUS · 0 GAGAL]
- Perintah 2: `[perintah]` -> Keluaran: [LULUS / X LULUS · 0 GAGAL]
...

## 3. Daftar Temuan Masalah (Jika Ada)
Bila ada masalah, gunakan format:
- **ID Temuan:** [F10-A1-01 / F10-A2-01 / F10-A3-01]
- **Tingkat Keparahan:** [K-1 / K-2 / K-3 / K-4]
- **Lokasi Berkas & Baris:** `path/to/file.ext:baris`
- **Deskripsi Masalah:** [Penjelasan kegagalan]
- **Langkah / Perintah Reproduksi:** `[perintah reproduksi]`
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** [Dampak bila tidak diperbaiki]
- **Rekomendasi Solusi:** [Solusi teknis ringkas]

Bila TIDAK ADA masalah ditemukan:
Tuliskan: "TIDAK DITEMUKAN CACAT K-1, K-2, MAUPUN K-3. Seluruh pagar keamanan terverifikasi fail-closed."

## 4. Kesimpulan & Rekomendasi untuk Pemilik Platform (Lee)
[Pernyataan apakah sistem siap melanjutkan ke Fase 11 atau harus ada perbaikan terlebih dahulu]
```
