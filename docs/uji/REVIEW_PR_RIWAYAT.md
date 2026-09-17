# RIWAYAT REVIEW PR INDEPENDEN

> Dijaga oleh agent. Setiap review PR (RV-2) dan hasil kalibrasi (RV-3) dicatat di sini.
> Aturan: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`. Cara Lee memicu: `PANDUAN_PENGGUNA.md` Bagian B (alur AL-6).

## 1. Riwayat review PR

| # | Tanggal | PR / cabang | Commit direview | Jalur risiko | Peninjau (sesi/model) | Temuan K-1 | K-2 | K-3 | K-4 | Skor kalibrasi | Verdict | Keputusan Lee | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `be69049` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Mekanisme baru dipasang; paket siap dibuat dengan `python3 alat/review-pr.py --siapkan --dasar origin/main --nama pr-01` |
| 1b | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `4fccc9d` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Paket `pr-01-putaran5` (berkasnya tetap tersimpan sebagai riwayat) — **digantikan** oleh baris 2 karena kode sudah jauh berubah: perbaikan K-1/K-2 dari audit AUD-3 |
| 2 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `00e7ce6` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Paket `pr-01-putaran6` (berkasnya tetap tersimpan sebagai riwayat) — **digantikan** oleh baris 3 karena tip sudah bergerak (T1-23 mendarat). Isi: perbaikan audit AUD-3 K-1/K-2 memuat semua perbaikan audit AUD-3 K-1/K-2 **dan** perbaikan mekanisme paket-basi. |
| 3 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `183a3c1` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | Paket `pr-01-putaran7` — **digantikan** baris 4 (tip bergerak: putaran verifikasi + Buku Uji Pemilik). Isi: `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran7-SIAP-TEMPEL.md`** (331 berkas · +41641/−132; menambahkan **T1-23**: peran tunggal + PIN 6 angka unik & kuat, migrasi 0011, 6 uji mutasi). Lee: buka chat baru (idealnya model berbeda) → salin seluruh berkas SIAP-TEMPEL → setelah selesai bilang "Laporan review sudah masuk, periksa" |
| 4 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `7e8c0b9` | Merah | **3 sesi peninjau (Lee), SELESAI** | 19 | 5 | 7 | 8 | **4/4 · 0 temuan palsu (LULUS)** | **TIDAK-BERSIH ×3** | **JANGAN MERGE (Lee, 2026-09-17)** | Tiga laporan tersimpan di `docs/uji/review-pr/LAPORAN_2026-09-17_pr-01-putaran8__*.md` (28·9·20, 11·9·11, 40·9·9 baris) — semuanya **LOLOS kontrak** dan **TIDAK-BERSIH**. Semua temuan lapis-database ditutup migrasi `0012` + 7 uji baru (bukti mutasi 12/12 MERAH di `alat/uji-mutasi-0012.py`); temuan dokumen dikoreksi; temuan mekanisme dikerjakan di commit berikutnya. |
| 5 | 2026-09-17 | PR #1 (`arena/01a0a8a2-resto-barokah`) | `b8679ec` | Merah | **menunggu sesi peninjau** | — | — | — | — | belum disiapkan | — | — | **Digantikan baris 6** (tip bergerak: penutupan temuan putaran8). Paket `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran9-SIAP-TEMPEL.md` (346 berkas · +42946/−132; di atas putaran8 menambahkan **cacat "kontrol mati" Nyaman/Padat** + uji/penjaga kerapatan + lembar kunci pemilik + **perbaikan cacat CI rujukan menggantung & penjaga `alat/periksa-bersih.py`**). Lee: buka chat baru (idealnya model berbeda) → salin seluruh berkas SIAP-TEMPEL → setelah selesai bilang "Laporan review sudah masuk, periksa" |

## 2. Riwayat kalibrasi review PR (RV-3)

| # | Tanggal | Bahan | Jumlah cacat | Ditemukan | Temuan palsu | Lulus? | Catatan |
|---|---|---|---|---|---|---|---|
| 1 | 2026-09-17 | `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` (4 cacat: P1 izin `boleh()` · P2 policy pengaturan · P3 pagar lebih bayar · P4 akun nonaktif kehilangan cabang) | 4 | **4** | **0** | **LULUS** | Laporan peninjau ke-3: "Ditemukan: 4 dari 4 · temuan palsu: 0". Bahan lama korup (`git apply` gagal — temuan PR-06/PR-04); pembuatnya diperbaiki: penanda "SENGAJA" dibuang SEBELUM diff (hitungan hunk selalu sah), pengambilan diff tidak lagi lewat pembungkus yang memangkas baris konteks, dan penjaga baru `git apply --check --reverse` menolak bahan yang tidak bisa dipasang. Bukti cacat tanaman benar-benar bisa ditangkap (harapan_mesin): diterapkan di salinan → `uji: 16 LULUS · 5 GAGAL` (gerbang_uang, izin, pembayaran, rls_pengguna, rls_semua_tabel). |

## 3. Cacat yang lolos ke `main` (angka kejujuran)

| # | Tanggal | Lolos dari review | Jenis | Ditemukan oleh | Perbaikan |
|---|---|---|---|---|---|
| — | (belum ada — belum ada merge ke `main`) | — | — | — | — |

## 4. Log keputusan dokumen & alat

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` + `alat/review-pr.py` + `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` dibuat; tingkatan RV-1…RV-3; Kartu Keputusan untuk Lee | Permintaan Lee: ia tidak bisa menilai *Files changed*; riset industri 2026 (reviewer AI = laporan + klasifikasi risiko, bukan pemberi approve; keputusan merge tetap manusia; kedalaman review mengikuti risiko) |
| 2026-09-17 | **Cacat kelas "hanya sehat di komputer sendiri" (ditemukan CI, bukan gerbang lokal).** Kiriman `896c5b4` GAGAL di CI: enam dokumen menulis rujukan ber-backtick ke berkas kerja lembar kunci yang **tidak ikut Git** — di komputer sendiri semuanya hijau karena berkasnya ada, di salinan bersih rujukannya menggantung | `periksa-semua` di komputer sendiri tidak cukup: berkas hasil kerja lokal menutupi cacat. **Perbaikan:** rujukan diarahkan ke formulir `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` (ikut Git), nama berkas kerja ditulis tanpa backtick, dan penjaga baru `alat/periksa-bersih.py` menyalin **hanya berkas terlacak `git ls-files`** lalu menjalankan 5 pemeriksa dokumen di salinan bersih itu. **Bukti bisa MERAH:** 2 uji mutasi (rujukan ke berkas non-Git · pemeriksa dokumen dihapus) → ditolak; masuk `periksa-semua.sh` + CI. Kiriman `b8679ec` hijau di CI. |
| 2026-09-17 | **Cacat mekanisme (ditemukan sendiri saat menyegarkan paket): paket review bisa mengikat commit BASI.** `--pr` memakai ref pelacak lokal (`origin/<cabang>`) yang ketinggalan dari GitHub → paket baru menunjuk `a003d2d` padahal kepala PR `ec875b9` | Ref lokal bisa basi setelah push dari sesi lain/reset; peninjau akan menilai kode lama tanpa tahu. **Perbaikan:** `--pr` kini membaca `headRefOid` dari GitHub, **menyegarkan** ref pelacak dulu, lalu **menolak membuat paket (fail-closed)** bila masih beda. **Bukti bisa MERAH:** dengan `gh` tiruan yang melaporkan sha berbeda → `GAGAL … paket TIDAK dibuat` (0 berkas dibuat); dengan sha benar → paket normal. `--kesiapan` kini `SIAP` untuk `ec875b9b` |
