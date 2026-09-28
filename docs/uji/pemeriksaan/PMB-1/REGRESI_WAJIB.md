# REGRESI WAJIB — PMB-1

> Dua kelas hal yang **wajib** dicek ulang walau "sudah pernah selesai", karena riwayat proyek membuktikan keduanya bisa kambuh.

## A. 117 temuan audit lama (harus tetap tertutup)

Daftar induk: `docs/uji/AUDIT_RIWAYAT.md` §1b dan `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md` (dijaga `python3 alat/periksa-temuan-audit.py`).
Aturan PMB: setiap kartu potongan memuat bagian **"7. Regresi temuan lama"** — pemeriksa mencari temuan lama yang artefaknya berada
dalam lingkup potongannya (cari ID/berkas di kedua daftar itu), lalu membuktikan **hari ini** bahwa penutupnya masih berlaku
(perintah → hasil). Temuan lama yang kambuh dicatat sebagai temuan baru di Buku Besar dengan rujukan ID lamanya.

## B. Klaim `[x]` ROADMAP yang menuntut pelaksanaan nyata (OTOMATIS)

<!-- OTOMATIS:MULAI -->
_Disusun mesin oleh `python3 alat/susun-matriks-telusur.py`: **35** tugas `[x]` yang DoD/Verifikasinya memuat kata pelaksanaan nyata (pemilik, perangkat, printer, HP, tanda tangan, pelatihan, …). Ini daftar untuk **disisir**, bukan vonis: potongan penyisir wajib menuntut bukti pelaksanaan tiap baris, atau mencatat temuan kelas "klaim vs kenyataan" (contoh nyata: T11-02/04/09/10/12, REKAM §31)._

| Tugas | Fase | Baris ROADMAP | Kata pemicu di DoD/Verifikasi | Potongan penyisir |
|---|---|---|---|---|
| T0-00 | 0 | 45 | dashboard, Lee, pemilik | F-08 |
| T0-01 | 0 | 54 | nyata | F-08 |
| T0-04 | 0 | 81 | pemilik | F-08 |
| T0-07 | 0 | 108 | nyata | F-08 |
| T0-09 | 0 | 128 | di luar jaringan | F-08 |
| T0-10 | 0 | 140 | nyata | F-08 |
| T0-11 | 0 | 151 | nyata | F-08 |
| T0-14 | 0 | 178 | LEE, Lee | F-08 |
| T1-03 | 1 | 207 | nyata, pemilik | F-08 |
| T1-05 | 1 | 225 | pemilik | F-08 |
| T1-06 | 1 | 234 | HP | F-08 |
| T1-10 | 1 | 270 | nyata, pemilik | F-08 |
| T1-25 | 1B | 422 | pemilik | F-08 |
| T1-28 | 1B | 450 | pemilik | F-08 |
| T1-36 | 1B | 479 | pemilik | F-08 |
| T1-31 | 1C | 515 | Lee | F-08 |
| T1-35 | 1C | 551 | pemilik | F-08 |
| T1-39 | 1C | 562 | Lee | F-08 |
| T1-43 | 1C | 598 | Lee, pemilik | F-08 |
| T2-14 | 2 | 785 | pemilik | F-09 |
| T2-15 | 2 | 794 | pemilik | F-09 |
| T3-11 | 3 | 940 | HP | F-09 |
| T7-10 | 7 | 1602 | pemilik, tanda tangan | F-10 |
| T8-02 | 8 | 1644 | HP | F-10 |
| T8-03 | 8 | 1653 | HP | F-10 |
| T8-05 | 8 | 1671 | HP | F-10 |
| T8-06 | 8 | 1680 | HP | F-10 |
| T8-15 | 8 | 1765 | pemilik | F-10 |
| T9-10 | 9 | 1858 | dashboard, pemilik | F-10 |
| T9-12 | 9 | 1876 | Lee, pemilik | F-10 |
| T10-04 | 10 | 1916 | nyata | F-10 |
| T10-07 | 10 | 1943 | pemilik | F-10 |
| T10-13 | 10 | 2001 | pemilik | F-10 |
| T10-15 | 10 | 2019 | nyata | F-10 |
| T10-16 | 10 | 2028 | nyata, pemilik | F-10 |
<!-- OTOMATIS:SELESAI -->
