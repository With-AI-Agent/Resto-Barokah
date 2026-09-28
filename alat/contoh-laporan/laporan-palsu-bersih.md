# LAPORAN AUDIT INDEPENDEN — AUD-2 — 2026-09-17

- **Auditor:** sesi-auditor-palsu
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-2
- **Commit yang diaudit:** `961d193c3f839a050e2ed69c0808c4cdb21b26a7`
- **Paket audit:** `docs/uji/paket-audit/AUD-2-2026-09-17.md`
- **Verdict:** BERSIH

## 1. Cakupan

| # | Artefak | Diperiksa | Bukti |
|---|---|---|---|
| 1 | `supabase/migrations/0004_pola_rls.sql` | ya | `grep -n penyewa_saya 0004` → ada |
| 2 | `supabase/migrations/0005_izin_berjenjang.sql` | ya | `grep -n revoke 0005` → ada |
| 3 | `supabase/migrations/0006_pin.sql` | ya | `grep -n BATAS_AKUN 0006` → 5 |
| 4 | `supabase/migrations/0010_pembayaran.sql` | ya | `sed -n 290,300p 0010` → ada |
| 5 | `docs/KEAMANAN.md` | ya | `grep -n batas docs/KEAMANAN.md` → ada |
| 6 | `alat/periksa-roadmap.py` | ya | `python3 alat/periksa-roadmap.py` → LOLOS |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T1-10 pembayaran tidak melebihi total | baca kode | TERBUKTI |
| 2 | T1-06 PIN hash | baca kode | TERBUKTI |
| 3 | T1-04 RLS semua tabel | jalankan pemeriksa | TERBUKTI |
| 4 | Dokumen 5×/15 menit | baca dokumen | TERBUKTI |
| 5 | Dokumen satu peran | baca kode | TERBANTAH (lihat F-01) |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | anon panggil boleh() | jalankan | ditolak |
| 2 | kasir tulis uang | jalankan | ditolak |
| 3 | baca lintas resto | jalankan | 0 baris |
| 4 | hapus audit | jalankan | belum ada tabel |
| 5 | perangkat tidak terdaftar | jalankan | belum ada fitur |

## 4. Temuan

### [F-01] Policy pembayaran memakai `true` sehingga semua penyewa bisa membaca
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:120`
- **Klaim yang dilanggar:** ART-1 (isolasi penyewa)
- **Bukti:** `grep -n "using (true)" supabase/migrations/0010_pembayaran.sql` → 1 baris
- **Skenario gagal:** kasir resto B melihat pembayaran resto A
- **Dugaan penyebab:** policy ditulis cepat
- **Cara membuktikan perbaikan:** `node alat/uji-sql.mjs` (uji isolasi pembayaran)
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

(tidak dijalankan — AUD-2)

## 6. Yang tidak bisa saya verifikasi

- Perilaku Supabase nyata.

## 7. Pernyataan tidak mengubah apa pun

Saya tidak mengubah berkas apa pun. Bukti: `git status --short` kosong.

## 8. Temuan di luar cakupan

(tidak ada)
