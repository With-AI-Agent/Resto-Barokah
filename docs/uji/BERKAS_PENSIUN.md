# Berkas yang SENGAJA dikeluarkan dari repo (daftar pensiun)

> **Kenapa ada:** berkas kadang harus keluar dari keadaan sekarang repo — mis. karena isinya
> ternyata **kunci jawaban** bagi latihan kalibrasi peninjau (temuan audit D F-05, 2026-09-19).
> Tanpa daftar ini, dua hal buruk terjadi: (a) rujukan lama ke berkas itu di riwayat/paket/laporan
> dibaca mesin sebagai **rujukan menggantung** dan riwayat yang jujur jadi dianggap cacat;
> (b) tidak ada jejak **siapa memutuskan, kapan, dan kenapa** — padahal menghapus berkas tanpa
> jejak itu sendiri kelas cacat (audit D F-04/F-06 soal ketertelusuran).
>
> **Dijaga mesin:** `alat/periksa-kunci-kalibrasi.py` (aturan D: daftar wajib ada, tiap jalur di
> daftar **tidak boleh** muncul lagi di repo, dan bekas pensiun wajib jujur menyebut riwayat Git)
> + `_sistem/validate_system.py` (jalur di daftar ini tidak lagi dihitung rujukan menggantung).

| # | Berkas (jalur) | Dikeluarkan | Diputuskan oleh | Alasan | Nasib isi |
|---|---|---|---|---|---|
| 1 | `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` | 2026-09-19 | Lee (izin 2026-09-19), diusulkan audit D F-05 | berkas itu diff dari migrasi **NYATA** ke versi cacat — siapa pun yang bisa membaca repo (termasuk peninjau yang sedang dikalibrasi) tahu persis baris mana yang ditanami cacat, jadi skor `Ditemukan: X dari Y` bisa dipalsukan | masih ada **di riwayat Git** (`git log --all`) → karena itu bahan itu **PENSIUN**: tidak dipakai lagi untuk menilai ketajaman; bahan baru disiapkan **di luar repo** (`/tmp/kalibrasi-pr`) dan isinya disematkan ke paket review |

**Aturan pemakaian daftar ini:**

1. Jalur di tabel boleh tetap disebut **berbacktick** di riwayat, paket, dan laporan sebagai provenance —
   validator memperlakukannya sebagai berkas yang sengaja tidak ada, bukan rujukan menggantung.
2. Kalau berkas yang sudah dipensiunkan **muncul lagi** di repo → penjaga menolak (berarti ia
   dikembalikan tanpa keputusan).
3. Menambah baris wajib lewat **keputusan Lee**; agent tidak boleh memensiunkan berkas sendiri.
4. Menghapus berkas dari repo **tidak** menghapusnya dari riwayat Git. Bila kelak pemilik ingin
   benar-benar bersih, itu tindakan destruktif (tulis ulang riwayat + force push) yang **wajib**
   keputusan Lee — dicatat juga di `docs/DECISIONS_LOG.md` 2026-09-19.
