# Prompt Entri Universal — Sistem Building Aplikasi

> Salin **seluruh blok** di bawah ke chat pertama setiap sesi baru (sesi fondasi, coding, audit, atau lanjut). Agent akan otomatis terorientasi tanpa perlu kamu tempel manual file lain.

```
Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone), lalu mulai dari TAHAP 1 (Discovery) sesuai AGENT_SYSTEM.md.

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut (FONDASI_TAHAP_2_PRD s/d CODING_AKTIF / SIKLUS_BARU).

Setelah kamu tahu posisi kita:

1. Baca SYSTEM_MANIFEST.md dan STATUS.md di folder sistem-building-aplikasi/ (atau root bila standalone) untuk paham identitas, tahap, dan pekerjaan belum tersimpan.
2. Verifikasi kondisi branch/working tree — branch arena/... dibuat otomatis platform lmarena; jangan asumsi main. Laporkan branch aktif, commit terakhir, dan working tree bersih/kotor.
3. Cek dan laporkan semua PR yang masih terbuka (gh pr list --state all) — PR menggantung dari sesi lama bisa membuatmu bekerja dari dasar ketinggalan.
4. Cari file LOG_SESI_*.md terbaru (di _log-sesi/ atau folder sistem-building-aplikasi/_log-sesi/). Kalau keadaannya OPEN, BACA dan laporkan keadaan sesi sebelumnya SEBELUM bertanya tujuan — jangan minta aku menjelaskan ulang konteks yang sudah tercatat di sana.
5. Laporkan posisi: sedang di tahap/fase apa, dan apa yang akan kamu kerjakan sekarang — sebelum mulai bekerja.
6. Berdasarkan jawabanku tentang tujuan sesi, baca sendiri file yang relevan (/docs/*, PROJECT_STATE.md, DECISIONS_LOG.md) — TANPA perlu aku tempel manual.
7. Jangan menulis/eksekusi apa pun sebelum tujuan sesi dikonfirmasi.

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint), WAJIB update PROJECT_STATE.md + STATUS.md + tutup LOG_SESI (CLOSED) supaya sesi berikutnya tahu harus lanjut dari mana.
```

> Catatan: blok di atas **identik** dengan §2 PANDUAN_PENGGUNA.md di folder yang sama. Kalau mengubah salah satu, ubah keduanya. Prompt ini portabel — memakai path relatif `sistem-building-aplikasi/` yang tetap benar bila folder diunduh jadi repo standalone (tinggal sesuaikan root).
