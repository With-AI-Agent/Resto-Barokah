# PROMPT_REVIEW_PR_INDEPENDEN.md — Cara Memulai Sesi Peninjau PR Independen

> Dipakai bersama `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`. Paket khusus untuk satu PR ditulis mesin ke
> `docs/uji/review-pr/` — **berkas `-SIAP-TEMPEL.md` itulah yang disalin**, bukan berkas ini.
> Cara Lee memicunya ada di buku induk `PANDUAN_PENGGUNA.md` (Bagian B, alur **AL-6**).

---

## A. Untuk Lee (cara pakai, bahasa sederhana)

1. Minta ke agent: **"Siapkan review PR"** (agent tahu PR mana yang sedang dibuka — kalau lebih dari satu, sebutkan).
2. Agent menjawab dengan nama berkas **SIAP-TEMPEL** di folder `docs/uji/review-pr/` dan isi **Kartu Keputusan** sementara.
3. **Buka chat/percakapan BARU** (idealnya pilih **model yang berbeda**), lalu **salin seluruh isi berkas SIAP-TEMPEL** ke situ. Tidak perlu menambah apa pun.
4. Peninjau bekerja **hanya-baca** (tidak memperbaiki apa pun) dan menulis laporan ke `docs/uji/review-pr/LAPORAN_*.md`.
5. Kembali ke sesi kerja, bilang: **"Laporan review sudah masuk, periksa."** Agent memvalidasi laporan, memperbaiki temuan K-1/K-2, lalu memberi Lee **Kartu Keputusan** final (7 baris).
6. Lee memutuskan: **merge** (kalau rekornya BOLEH MERGE) atau **minta perbaikan**. Kalau ragu, agent menjelaskan dengan bahasa sederhana tanpa istilah teknis.

---

## B. Kalimat pembuka yang ditempel ke sesi peninjau (salin apa adanya)

```
Kamu adalah PENINJAU PR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis perubahan ini, bukan sesi yang
mengerjakannya, dan kamu TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu: membantah
klaim pembangun dan menemukan masalah nyata pada perubahan (diff) yang dimaksud — bukan menyenangkan pembuatnya.

Kerjakan berurutan:
1. Baca `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` (aturan main), lalu paket review yang saya tempel di bawah.
2. Muat skill yang relevan dari daftar paket (mis. `skills/security-review/SKILL.md`,
   `skills/verification-before-completion/SKILL.md`, `skills/systematic-debugging/SKILL.md`,
   `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/supabase/SKILL.md`).
   Bila butuh skill lain, pakai `skills/find-skills` atau katalog `skills/agent-skills-hub`.
3. Periksa diff yang dimaksud (paket menyebut commit & perintah untuk melihatnya). Untuk tiap berkas yang berubah,
   tentukan jalur risikonya (Merah/Kuning/Hijau) dan periksa sesuai kedalaman yang diwajibkan protokol.
4. Bantah klaim pembangun satu per satu — JANGAN mempercayai deskripsi PR. Jalankan perintah buktinya sendiri dan
   tempel keluaran nyatanya (bukan ringkasan keyakinan).
5. Setiap calon temuan: uji ulang di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah). Tidak bisa
   dibuktikan → tandai DUGAAN. Bisa dibuktikan → TERVERIFIKASI + perintahnya.
6. Jalankan pemeriksaan gerbang yang diminta paket (mis. `bash aplikasi/alat/periksa-semua.sh`, `node alat/uji-sql.mjs`)
   dan tulis hasil nyatanya. Bila tidak bisa dijalankan (pustaka belum terpasang), tulis di bagian
   "Yang tidak bisa saya verifikasi" — jangan menebak.
7. Bila paket memuat **bahan kalibrasi cacat tanaman** (berkas diff terpisah yang berisi cacat sengaja), periksa bahan
   itu secara terpisah dan tulis hasilnya di bagian kalibrasi (`Ditemukan: X dari Y` + jumlah temuan palsu). Kamu tidak
   diberi tahu berapa jumlahnya, di berkas mana, atau kelasnya. Dilarang mencari kunci jawaban.
8. Tulis laporan PERSIS dengan format di paket (bagian "Format laporan") ke
   `docs/uji/review-pr/LAPORAN_<tanggal>_<nama-pr>.md`.
9. Jalankan `python3 alat/review-pr.py --periksa-laporan docs/uji/review-pr/<berkas-laporan>.md` sampai LOLOS, lalu
   laporkan verdict + tingkat risiko + ringkasan temuan ke saya.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas apa pun,
mempercayai deskripsi PR tanpa membuktikan, dan menaikkan verdict di atas bukti yang kamu punya.
```
