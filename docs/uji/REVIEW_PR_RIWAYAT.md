# RIWAYAT REVIEW PR INDEPENDEN

> Dijaga oleh agent. Setiap review PR (RV-2) dan hasil kalibrasi (RV-3) dicatat di sini.
> Aturan: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`. Cara Lee memicu: `PANDUAN_PENGGUNA.md` Bagian B (alur AL-6).

## 1. Riwayat review PR

| # | Tanggal | PR / cabang | Commit direview | Jalur risiko | Peninjau (sesi/model) | Temuan K-1 | K-2 | K-3 | K-4 | Skor kalibrasi | Verdict | Keputusan Lee | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `be69049` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Mekanisme baru dipasang; paket siap dibuat dengan `python3 alat/review-pr.py --siapkan --dasar origin/main --nama pr-01` |
| 1b | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `4fccc9d` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Paket `pr-01-putaran5` (berkasnya tetap tersimpan sebagai riwayat) — **digantikan** oleh baris 2 karena kode sudah jauh berubah: perbaikan K-1/K-2 dari audit AUD-3 |
| 2 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `00e7ce6` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Paket `pr-01-putaran6` (berkasnya tetap tersimpan sebagai riwayat) — **digantikan** oleh baris 3 karena tip sudah bergerak (T1-23 mendarat). Isi: perbaikan audit AUD-3 K-1/K-2 memuat semua perbaikan audit AUD-3 K-1/K-2 **dan** perbaikan mekanisme paket-basi. |
| 3 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `183a3c1` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | **Paket berlaku: `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran7-SIAP-TEMPEL.md`** (331 berkas · +41641/−132; menambahkan **T1-23**: peran tunggal + PIN 6 angka unik & kuat, migrasi 0011, 6 uji mutasi). Lee: buka chat baru (idealnya model berbeda) → salin seluruh berkas SIAP-TEMPEL → setelah selesai bilang "Laporan review sudah masuk, periksa" |

## 2. Riwayat kalibrasi review PR (RV-3)

| # | Tanggal | Bahan | Jumlah cacat | Ditemukan | Temuan palsu | Lulus? | Catatan |
|---|---|---|---|---|---|---|---|
| — | (belum ada) | — | — | — | — | — | Bahan dibuat dengan `python3 alat/review-pr.py --kalibrasi-pr-siapkan` |

## 3. Cacat yang lolos ke `main` (angka kejujuran)

| # | Tanggal | Lolos dari review | Jenis | Ditemukan oleh | Perbaikan |
|---|---|---|---|---|---|
| — | (belum ada — belum ada merge ke `main`) | — | — | — | — |

## 4. Log keputusan dokumen & alat

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` + `alat/review-pr.py` + `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` dibuat; tingkatan RV-1…RV-3; Kartu Keputusan untuk Lee | Permintaan Lee: ia tidak bisa menilai *Files changed*; riset industri 2026 (reviewer AI = laporan + klasifikasi risiko, bukan pemberi approve; keputusan merge tetap manusia; kedalaman review mengikuti risiko) |
| 2026-09-17 | **Cacat mekanisme (ditemukan sendiri saat menyegarkan paket): paket review bisa mengikat commit BASI.** `--pr` memakai ref pelacak lokal (`origin/<cabang>`) yang ketinggalan dari GitHub → paket baru menunjuk `a003d2d` padahal kepala PR `ec875b9` | Ref lokal bisa basi setelah push dari sesi lain/reset; peninjau akan menilai kode lama tanpa tahu. **Perbaikan:** `--pr` kini membaca `headRefOid` dari GitHub, **menyegarkan** ref pelacak dulu, lalu **menolak membuat paket (fail-closed)** bila masih beda. **Bukti bisa MERAH:** dengan `gh` tiruan yang melaporkan sha berbeda → `GAGAL … paket TIDAK dibuat` (0 berkas dibuat); dengan sha benar → paket normal. `--kesiapan` kini `SIAP` untuk `ec875b9b` |
