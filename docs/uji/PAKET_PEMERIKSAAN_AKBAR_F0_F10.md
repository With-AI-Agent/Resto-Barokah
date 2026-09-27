# PAKET PEMERIKSAAN AKBAR MENYELURUH (FASE 0 s/d FASE 10)
# Resto Barokah — Gerbang Kesiapan Sebelum Pilot Lapangan (Penutup Fase 10)

> **Untuk Pemilik Platform (Lee):** Dokumen ini adalah panduan resmi pemeriksaan besar-besaran yang sangat teliti dan mendalam untuk memeriksa seluruh hasil kerja Fase 0 hingga Fase 10 sebelum melangkah ke Fase 11 (Uji Lapangan & Pilot Kedai Nyata).
> Pemeriksaan dilakukan dalam **Arsitektur Dua Dimensi (Matriks Silang)**:
> 1. **Pemeriksaan Vertikal (Jejak Sejarah):** Membedah fase per fase dari Fase 0 sampai Fase 10 secara urut.
> 2. **Pemeriksaan Horizontal (Spesialisasi Teknis):** Tiga pemeriksa independen yang mendalami Data, Frontend, dan Keamanan.
> 3. **Pemeriksaan Holistik (Auditor Utama):** Menguji alur bisnis utuh dari kacamata Lee sebagai Pemilik Platform SaaS multi-tenant.

---

## 1. Pembagian Peran & Tanggung Jawab

| No | Peran Pemeriksa | Sasaran Utama | Berkas Naskah Prompt Siap Salin |
|---|---|---|---|
| 1 | **Auditor Utama (Holistik)** | Alur bisnis SaaS hulu ke hilir, isolasi antar penyewa resto, simulasi skenario nyata dari pendaftaran hingga rekap omzet, keselarasan janji PRD & TECH_SPEC. | `docs/uji/PROMPT_AKBAR_AUDITOR_UTAMA.md` |
| 2 | **Spesialis Basis Data & Keuangan** | 85 migrasi SQL, 132 berkas uji SQL, RLS 47 tabel, RPC penulisan & idempoten (ART-8), presisi uang/PB1/service charge sampai rupiah terkecil. | `docs/uji/PROMPT_AKBAR_SPESIALIS_DATA.md` |
| 3 | **Spesialis Frontend & Antarmuka** | Seluruh layar kasir/pelayan/dapur/manajer, pengetikan keyboard fisik PIN kasir, ketahanan antrean offline (IndexedDB), responsivitas di tablet/HP, aksesibilitas kontras WCAG AAA. | `docs/uji/PROMPT_AKBAR_SPESIALIS_FRONTEND.md` |
| 4 | **Spesialis Infrastruktur & SOP Bencana** | Kunci rahasia, enkripsi cadangan AES-256, SOP Buku Insiden 4 skenario darurat, kebijakan CSP tanpa unsafe-inline, alur denyut cron harian (02:00 WIB), 126 gerbang CI. | `docs/uji/PROMPT_AKBAR_SPESIALIS_INFRASTRUKTUR.md` |
| 5 | **Pemeriksa Riwayat Fase (0–10)** | Menelusuri kepatuhan bertahap tiap fase (Fase 0 s/d Fase 10) untuk membuktikan tidak ada utang teknis atau janji yang tertinggal. | `docs/uji/PROMPT_AKBAR_PEMERIKSA_FASE.md` |

---

## 2. Kriteria Kelulusan (Pass / Fail Criteria)

Pemeriksaan dinyatakan **LULUS MUTLAK** bila:
1. **0 Temuan Kritis (K-1):** Tidak ada kebocoran data antar penyewa resto (*zero cross-tenant leak*), tidak ada salah hitung uang, tidak ada kunci rahasia bocor di repositori.
2. **0 Temuan Mayor (K-2):** Tidak ada tombol mati (*unhandled button*), tidak ada alur kasir/dapur yang macet, tidak ada skrip CI yang merah.
3. **100% Mesin Penguji Hijau:** Seluruh 126 gerbang CI, 132 berkas uji SQL, 123 berkas pengujian frontend Vitest, dan seluruh suite uji-diri fail-closed lulus tanpa pengecualian.

---

## 3. Format Pelaporan untuk Agen Pemeriksa

Setiap agen yang ditugaskan wajib melaporkan hasilnya dalam berkas markdown di folder `docs/uji/audit/` dengan format:
`docs/uji/audit/LAPORAN_AKBAR_<KODE_PERAN>_<TANGGAL>.md` (akan dibuat saat pelaporan)

Isi laporan wajib memuat:
1. **Ringkasan Eksekutif (Bahasa Manusia):** Penjelasan singkat tanpa jargon tentang apa yang ditemukan.
2. **Tabel Bukti Pengujian:** Daftar perintah yang dijalankan beserta hasilnya.
3. **Daftar Temuan (jika ada):** Dikelompokkan berdasarkan tingkat keparahan (K-1 Kritis, K-2 Mayor, K-3 Minor, K-4 Saran).
4. **Kesimpulan:** Pernyataan tegas apakah sistem dinyatakan SIAP untuk Fase 11 atau MEMERLUKAN PERBAIKAN.
