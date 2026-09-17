# LAPORAN REVIEW PR INDEPENDEN — contoh buruk — 2026-09-17

- **Paket review:** `alat/contoh-laporan-review/paket-contoh.md`
- **Commit yang direview:** `0000000000000000000000000000000000000000`
- **Tingkat risiko:** Merah
- **Verdict:** BERSIH

## 1. Cakupan diff
| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `alat/review-pr.py` | Merah | ya | dilihat |
| 2 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` | Merah | ya | dilihat |
| 3 | `PANDUAN_PENGGUNA.md` | Kuning | ya | dilihat |
| 4 | `docs/ROADMAP.md` | Kuning | ya | dilihat |
| 5 | `docs/uji/REVIEW_PR_RIWAYAT.md` | Hijau | ya | dilihat |

## 2. Klaim yang dibantah
| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | Alat menolak laporan buruk | dijalankan | bagus |
| 2 | Paket bagus | dilihat | bagus |
| 3 | Tidak ada rujukan mati | dilihat | bagus |
| 4 | Dokumen lengkap | dilihat | bagus |
| 5 | Verdict tidak bisa naik | dilihat | bagus |

## 3. Pemeriksaan gerbang
| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | LOLOS |
| 2 | `node alat/uji-sql.mjs` | LOLOS |
| 3 | `python3 _sistem/validate_system.py` | PASS |
| 4 | `python3 alat/review-pr.py --uji-diri` | LOLOS |
| 5 | `git status` | bersih |

## 4. Temuan
### [PR-01] Ada masalah pada berkas izin
- **Tingkat:** K-1
- **Artefak:** supabase/tes/izin.sql:10
- **Klaim yang dilanggar:** izin harus ketat
- **Bukti:** kelihatannya rapuh
- **Skenario gagal:** entah
- **Dugaan penyebab:** kurang teliti
- **Cara membuktikan perbaikan:** diperbaiki
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman
Tidak ada.

## 6. Yang tidak bisa saya verifikasi
- tidak ada

## 7. Pernyataan tidak mengubah apa pun
Saya tidak mengubah berkas apa pun.
