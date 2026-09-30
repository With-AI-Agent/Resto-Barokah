# USULAN — KEWAJIBAN "HASIL MASUK GITHUB" (push) PADA SETIAP GILIRAN PMB

> **Sumber:** pesan Lee, 2026-09-30 — *"hasilnya harus masuk github supaya agen di sesi lain
> bisa liat dan bisa integrasikan. Catat itu agar mekanisme ini ditingkatkan jika memang aturan
> ini belum tertanam di mekanisme tersebut."*
> Ditulis oleh: Pembangun arena/01a0eff7-resto-barokah (kartu B-F-03, B-F-04). Berkas ini
> USULAN untuk Perencana (pemilik alat mekanisme) — Pembangun **tidak mengubah** alat mekanisme.

## 1. Hasil pemeriksaan: apakah aturan ini sudah tertanam?

**Sudah tertanam sebagian — sebagai langkah kontrak, dan ditegakkan di tingkat sesi:**

| Tempat | Isi yang sudah ada |
|---|---|
| `PROMPT_GILIRAN.md` (baris 44) | Klaim potongan = "tulis DIKLAIM … lalu **commit + push cabangmu** sebelum bekerja" |
| `PROMPT_GILIRAN.md` (baris 99) | Langkah akhir giliran = "Commit … **+ push cabangmu**" |
| `RANCANGAN_PEMERIKSAAN_BERTAHAP.md` (baris 224, 230, 233) | DIKLAIM di-push agar sesi lain tidak mengambil potongan sama; potongan SELESAI di-push; "setiap sesi push ke cabangnya dan **Perencana menggabungkan**" |
| `PMB-1/README.md` (baris 23) | Integrasi lintas cabang memakai `alat/pmb-integrasi.py origin/<cabang>` — hanya bisa untuk cabang yang **sudah ter-push** |
| `alat/lanjut-sesi.py` | Menolak handoff basi: "commit lokal … belum ter-push … tanpa push, sesi berikutnya tidak bisa melanjutkan"; cabang yang belum pernah di-push tidak bisa dilanjutkan |

## 2. Celah yang tersisa (kenapa perlu ditingkatkan)

1. **Tidak ada BUKTI push pada akhir giliran.** Kartu B (`TEMPLAT_B.md` §4) tidak mewajibkan
   mencatat "ter-push sampai `<sha>`", dan `periksa-pemeriksaan.py` murni lokal — dia tidak bisa
   membedakan giliran yang selesai di-push dari yang hanya commit. Satu-satunya penegak
   (`lanjut-sesi.py`) baru bekerja saat sesi BERIKUTNYA mulai.
2. **Push hanya diwajibkan di dua titik** (klaim & selesai). Commit perbaikan di TENGAH giliran
   (satu commit per temuan) baru sampai GitHub di akhir — bila sesi mati di tengah, pekerjaan
   antara hilang dan sesi lain tidak melihatnya.
3. **Kalimat kontrak belum eksplisit** bahwa "selesai" = "terbukti ter-push" (bukan sekadar
   perintah push diketik).

## 3. Usulan peningkatan mekanisme (keputusan Perencana/Lee)

- (a) `TEMPLAT_B.md` §4 (Rantai bukti): tambah butir wajib "**Ter-push sampai:** `<sha>`" —
  kartu tanpa itu ditolak `periksa-pemeriksaan.py`.
- (b) `PROMPT_GILIRAN.md` §5 langkah akhir: ubah "Commit + push" menjadi "Commit + push
  **terbukti** (tempel keluaran push di laporan)".
- (c) Opsional (mesin): `periksa-pemeriksaan.py --gerbang` menambah cek
  `git fetch origin <cabang> && git merge-base --is-ancestor HEAD origin/<cabang>` sehingga
  "selesai tanpa push" menjadi MERAH, bukan kebiasaan.
- (d) Menerapkan aturan "setiap commit perbaikan langsung di-push" (bukan menumpuk di akhir).

## 3b. Penegasan ulang Lee (2026-09-30, pesan kedua di chat)

Lee mengulang instruksinya secara eksplisit pada hari yang sama: *"Jangan lupa, hasilnya harus masuk
github supaya agen di sesi lain bisa liat dan bisa integrasikan. Catat itu agar mekanisme ini
ditingkatkan jika memang aturan ini belum tertanam di mekanisme tersebut."* Artinya aturan ini
**berlaku mulai sekarang untuk setiap giliran PMB** (bukan sekadar usulan): akhir giliran wajib
melaporkan **"Ter-push sampai `<sha>`"** dan bukti paritas `git rev-parse HEAD` = tip origin.
Sesi pembangun ini menerapkannya sejak kartu B-F-03 dan tidak menunggu alat diubah.

## 4. Yang sudah dijalankan sesi ini (tanpa menunggu perubahan mekanisme)

Semua commit giliran B-F-03 dan B-F-04 **langsung di-push** ke `origin/arena/01a0eff7-resto-barokah`
setiap kali dibuat (lihat kolom Sesi di PAPAN dan kartu B-F-03/B-F-04); akhir tiap giliran dilaporkan
bersama sha terakhir yang ter-push. Praktik ini diusulkan menjadi aturan tertulis lewat butir (d).
