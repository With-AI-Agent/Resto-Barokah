# LAPORAN REVIEW PR INDEPENDEN — contoh buruk 2 — 2026-09-17

- **Paket review:** `alat/contoh-laporan-review/paket-contoh.md`
- **Commit yang direview:** `0000000000000000000000000000000000000000`
- **Tingkat risiko:** Hijau
- **Verdict:** BERSIH

## 1. Cakupan diff
| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `alat/review-pr.py` | Merah | ya | `cat` |
| 2 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` | Merah | ya | `cat` |
| 3 | `PANDUAN_PENGGUNA.md` | Kuning | ya | `cat` |

## 2. Klaim yang dibantah
| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | Alat benar | dilihat | benar |
| 2 | Dokumen benar | dilihat | benar |

## 3. Pemeriksaan gerbang
| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | LOLOS |

## 4. Temuan
(tidak ada temuan)

## 5. Kalibrasi cacat tanaman
Tidak diminta.

## 6. Yang tidak bisa saya verifikasi
(tidak ada)

## 7. Pernyataan tidak mengubah apa pun
Saya tidak mengubah berkas apa pun.
