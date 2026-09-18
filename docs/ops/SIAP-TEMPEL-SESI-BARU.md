> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat BARU (percakapan baru).
> Dibuat mesin oleh `alat/lanjut-sesi.py`; Prompt Pembuka di bawah diambil apa adanya dari
> sumber kanonik (`PROMPT_ENTRI_UNIVERSAL.md`), jadi tidak bisa menyimpang.

===== MULAI SALIN DARI SINI =====

Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone), lalu mulai dari TAHAP 1 (Discovery) sesuai AGENT_SYSTEM.md.

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut (FONDASI_TAHAP_2_PRD s/d CODING_AKTIF / SIKLUS_BARU).

Setelah kamu tahu posisi kita:

0. JALANKAN BOOTSTRAP SESI: python3 alat/mulai-sesi.py — script ini mencetak KARTU SESI: posisi proyek, keadaan branch/PR, log sesi terbaru, DAFTAR SKILL yang wajib kamu baca untuk fase sekarang, dan berkas fondasi yang wajib dibaca. Kalau script tidak ada/gagal, pakai tabel fase-ke-skill di docs/AGENT_OPERATING_GUIDE.md bagian 2.
1. BACA sungguhan setiap berkas SKILL.md yang tercantum di KARTU SESI (beserta referensi yang ditunjuknya bila relevan) — jangan hanya menyebutnya. Semua skill sudah tersimpan lokal di skills/ (tidak perlu internet, tidak perlu npx). Kalau ada skill yang dibutuhkan fase ini tapi tidak ada di repo, LAPORKAN — jangan dilewati diam-diam.
2. Baca SYSTEM_MANIFEST.md dan STATUS.md (identitas, tahap, pekerjaan belum tersimpan) + PROJECT_STATE.md (posisi sekarang).
2b. Baca docs/teknis/REKAM_PESAN_PEMILIK.md — rekam SEMUA permintaan pemilik (Lee) beserta statusnya. Jangan menutup atau
    mengubah butir di sana tanpa jawaban Lee, dan jangan mengulang pekerjaan yang sudah berstatus selesai di berkas itu.
2c. Bila ada `docs/ops/SIAP-LANJUT.md`, BACA lebih dulu: itu penunjuk keadaan yang dibuat mesin (cabang kerja terakhir, commit, keadaan CI, butir tertangguh, rencana berikutnya). Kalau checkout-mu TIDAK memuat pekerjaan terakhir (mis. kamu mulai dari `main` sedangkan pekerjaan ada di cabang sesi), JANGAN bekerja dulu — susul cabangnya lebih dulu (`git fetch origin <cabang>:refs/remotes/origin/kerja-terakhir && git merge --ff-only origin/kerja-terakhir`), lalu laporkan. 
3. Verifikasi branch/working tree. Ingat fakta platform: branch arena/... dibuat otomatis dan tidak bisa diganti; base branch dipilih di awal sesi (rekomendasi: main); setiap sesi bisa memakai MODEL AI YANG BERBEDA; setelah PR di-merge atau di-close, akses sesi itu hilang. Laporkan branch aktif, jarak commit terhadap main, commit terakhir, dan working tree bersih/kotor. **Kalau pekerjaan sesi sebelumnya belum di-merge dan kamu perlu melihatnya, pilih base branch = cabang arena sesi itu (mis. arena/01a0a8a2-resto-barokah) saat membuat sesi baru — jangan merge PR hanya supaya bisa melihat pekerjaan.**
3b. Kalau ruang kerja baru dinyalakan ulang: (a) pustaka aplikasi bisa hilang → `bash aplikasi/alat/pratinjau.sh` memasang & menyalakan pratinjau; (b) salinan Git lokal bisa mundur ke `main` → `bash alat/pulihkan-git.sh` untuk memeriksa dan `bash alat/pulihkan-git.sh --perbaiki` bila memang tertinggal (tanpa `--hard`/`--force`). JANGAN menulis ulang berkas dari ingatan — ambil dari GitHub.
4. Cek dan laporkan semua PR (gh pr list --state all) — PR menggantung dari sesi lama bisa membuatmu bekerja dari dasar yang ketinggalan.
5. Cari file LOG_SESI_*.md terbaru di _log-sesi/. Kalau keadaannya OPEN, BACA header Keadaan Sesi + kronologi terakhir, lalu LAPORKAN keadaan sesi sebelumnya SEBELUM bertanya tujuan — jangan minta aku menjelaskan ulang konteks yang sudah tercatat di sana.
6. Baca docs/TERTANGGUH.md (buku tunggu) — KARTU SESI sudah mencetak daftar butir terbukanya. Setiap butir berarti ada hal yang SENGAJA ditunda; kamu WAJIB melaporkan jumlah & ID-nya, dan TIDAK BOLEH menutupnya tanpa jawaban pemilik (kecuali bisa dibuktikan dari dokumen yang sudah dikunci — tulis alasannya).
7. Laporkan posisi + KARTU SESI yang sudah terisi (termasuk: "Skill terpasang: N berkas dari M skill", fondasi yang dibaca, posisi sekarang, rencana sesi ini, yang dibutuhkan dariku) — SEBELUM mulai bekerja.
8. Berdasarkan jawabanku tentang tujuan sesi, baca sendiri file yang relevan (docs/*, PROJECT_STATE.md, docs/ROADMAP.md, docs/DECISIONS_LOG.md) — TANPA perlu aku tempel manual.
9. Jangan menulis/mengeksekusi apa pun sebelum tujuan sesi dikonfirmasi.

MODE MARATON (aturan kerja yang disetujui pemilik): bekerjalah terus-menerus dalam batch — satu perintah "lanjut" dariku = kerjakan sebanyak mungkin tugas berikutnya yang TIDAK tertangguh, tanpa bertanya. Hal yang bisa ditunda JANGAN dijadikan pertanyaan: tunda, catat di docs/TERTANGGUH.md (isi: kenapa boleh ditunda, nilai sementara, tenggat fase, siapa yang menjawab), lalu lanjut bekerja. Kamu HANYA boleh berhenti untuk bertanya pada Stop Conditions: (1) keamanan/uang/data pelanggan belum jelas, (2) muncul biaya apa pun, (3) dokumen fondasi bertentangan, (4) mau mengubah keputusan yang sudah dikunci/di DECISIONS_LOG, (5) tindakan merusak/tak bisa dibatalkan (hapus data, force push, deploy publik), (6) butir tertangguh sudah lebih dari 12 atau tenggatnya lewat. Setiap akhir batch: commit + push + perbarui ROADMAP/PROJECT_STATE/STATUS/LOG_SESI + tawarkan jawaban untuk semua butir tertangguh (aku cukup bilang "setuju semua").

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint): WAJIB perbarui PROJECT_STATE.md + STATUS.md + tutup LOG_SESI (CLOSED) + jalankan `python3 alat/lanjut-sesi.py --siapkan` (menyegarkan handoff `docs/ops/SIAP-LANJUT.md` dan berkas siap tempel `docs/ops/SIAP-TEMPEL-SESI-BARU.md`), COMMIT & PUSH semua pekerjaan (tanpa push, pekerjaan bisa hilang dan sesi berikutnya tidak bisa melanjutkan), lalu jalankan `python3 alat/lanjut-sesi.py` sampai LOLOS — barulah laporkan bahwa sesi aman ditutup, sebutkan commit terakhir, dan sebutkan berkas yang disalin Lee untuk lanjut di chat baru.

===== SAMBUNGAN: ARAHAN LANJUT PROYEK (dibuat mesin 2026-09-18) =====

Proyek: **Resto Barokah** — repo `With-AI-Agent/Resto-Barokah`, cabang kerja terakhir
`arena/01a0a8a2-resto-barokah` @ `cdd80b6724845663103cde132273919a4636e2d4`. PR #1 **terbuka** — **JANGAN MERGE**: merge hanya keputusan Lee.

Langkah pertama sesi ini (WAJIB, supaya tidak bekerja dari `main` yang tertinggal ≈123 commit):

```
git fetch origin arena/01a0a8a2-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py
```

Lalu baca `docs/ops/SIAP-LANJUT.md` (penunjuk keadaan: cabang, commit, CI, butir tertangguh,
rencana berikutnya) dan `PROJECT_STATE.md`. Laporkan KARTU SESI ke Lee SEBELUM bekerja.

Ringkas keadaan terakhir: putaran13 (review PR #1 + audit AUD-3 2026-09-18) — 27 temuan
diverifikasi nyata dan ditutup migrasi `0014`; suite SQL 41/41, mutasi 16/16 & 17/17 MERAH,
CI hijau. Sisa pekerjaan terdekat dan pilihannya ada di bagian "Rencana berikutnya" pada
`docs/ops/SIAP-LANJUT.md`.

===== SELESAI SALIN =====
