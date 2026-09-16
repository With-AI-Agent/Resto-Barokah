# Prompt Entri Universal — Sistem Building Aplikasi

> Salin **seluruh blok** di bawah ke chat pertama setiap sesi baru (sesi fondasi, coding, audit, atau lanjut). Agent akan otomatis terorientasi tanpa perlu kamu tempel manual file lain.

```
Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone), lalu mulai dari TAHAP 1 (Discovery) sesuai AGENT_SYSTEM.md.

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut (FONDASI_TAHAP_2_PRD s/d CODING_AKTIF / SIKLUS_BARU).

Setelah kamu tahu posisi kita:

0. JALANKAN BOOTSTRAP SESI: python3 alat/mulai-sesi.py — script ini mencetak KARTU SESI: posisi proyek, keadaan branch/PR, log sesi terbaru, DAFTAR SKILL yang wajib kamu baca untuk fase sekarang, dan berkas fondasi yang wajib dibaca. Kalau script tidak ada/gagal, pakai tabel fase-ke-skill di docs/AGENT_OPERATING_GUIDE.md bagian 2.
1. BACA sungguhan setiap berkas SKILL.md yang tercantum di KARTU SESI (beserta referensi yang ditunjuknya bila relevan) — jangan hanya menyebutnya. Semua skill sudah tersimpan lokal di skills/ (tidak perlu internet, tidak perlu npx). Kalau ada skill yang dibutuhkan fase ini tapi tidak ada di repo, LAPORKAN — jangan dilewati diam-diam.
2. Baca SYSTEM_MANIFEST.md dan STATUS.md (identitas, tahap, pekerjaan belum tersimpan) + PROJECT_STATE.md (posisi sekarang).
3. Verifikasi branch/working tree. Ingat fakta platform: branch arena/... dibuat otomatis dan tidak bisa diganti; base branch dipilih di awal sesi (rekomendasi: main); setiap sesi bisa memakai MODEL AI YANG BERBEDA; setelah PR di-merge atau di-close, akses sesi itu hilang. Laporkan branch aktif, jarak commit terhadap main, commit terakhir, dan working tree bersih/kotor.
4. Cek dan laporkan semua PR (gh pr list --state all) — PR menggantung dari sesi lama bisa membuatmu bekerja dari dasar yang ketinggalan.
5. Cari file LOG_SESI_*.md terbaru di _log-sesi/. Kalau keadaannya OPEN, BACA header Keadaan Sesi + kronologi terakhir, lalu LAPORKAN keadaan sesi sebelumnya SEBELUM bertanya tujuan — jangan minta aku menjelaskan ulang konteks yang sudah tercatat di sana.
6. Laporkan posisi + KARTU SESI yang sudah terisi (termasuk: "Skill terpasang: N berkas dari M skill", fondasi yang dibaca, posisi sekarang, rencana sesi ini, yang dibutuhkan dariku) — SEBELUM mulai bekerja.
7. Berdasarkan jawabanku tentang tujuan sesi, baca sendiri file yang relevan (docs/*, PROJECT_STATE.md, ROADMAP.md, DECISIONS_LOG.md) — TANPA perlu aku tempel manual.
8. Jangan menulis/mengeksekusi apa pun sebelum tujuan sesi dikonfirmasi.

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint): WAJIB perbarui PROJECT_STATE.md + STATUS.md + tutup LOG_SESI (CLOSED), COMMIT & PUSH semua pekerjaan (tanpa push, pekerjaan bisa hilang dan sesi berikutnya tidak bisa melanjutkan), lalu laporkan bahwa sesi aman ditutup.
```

> Catatan: blok di atas **identik** dengan §2 PANDUAN_PENGGUNA.md di folder yang sama. Kalau mengubah salah satu, ubah keduanya. Prompt ini portabel — memakai path relatif `sistem-building-aplikasi/` yang tetap benar bila folder diunduh jadi repo standalone (tinggal sesuaikan root).
