SESI YANG AKU LANJUT: .......... (isi nama cabang sesi di sini; contoh bentuknya: arena/01a0a8a2-resto-barokah)

> BERKAS INI STATIS (tidak berubah tiap batch) — simpan sekali, pakai terus.
> Bagian yang kamu isi HANYA baris pertama di atas. Sisa berkas ini jangan diubah.
> Penjelasan untuk manusia: `PANDUAN_PENGGUNA.md` bagian AL-13 dan `docs/PANDUAN_PEMILIK.md` pertanyaan 2b.

LANGKAH PERTAMA (WAJIB, sebelum menjalankan apa pun di bawah): kamu kemungkinan besar masih berdiri di basis `main` yang tertinggal ratusan commit. Susul dulu cabang yang tertulis di baris pertama:

```
git fetch origin <CABANG-YANG-DIPILIH>:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py
```

- Kalau baris `SESI YANG AKU LANJUT` KOSONG: JANGAN menebak. Tampilkan daftar sesi yang bisa dilanjutkan (cara tanpa alat ada di bagian LANJUT SESI di bawah), laporkan ke Lee, lalu tunggu Lee memilih.
- Kalau baris itu TERISI tetapi cabangnya TIDAK ADA di GitHub (`git ls-remote origin refs/heads/<CABANG-YANG-DIPILIH>` kosong): JANGAN menebak juga — laporkan dan tampilkan daftar sesi.
- Kalau repo ini belum punya `PROJECT_STATE.md` (proyek baru): abaikan baris di atas dan ikuti saja Prompt Pembuka Universal di bawah.

===== PROMPT PEMBUKA UNIVERSAL (identik dengan PROMPT_ENTRI_UNIVERSAL.md) =====

ATURAN BAHASA (wajib, jangan dilanggar): semua komunikasi dengan Lee memakai **bahasa Indonesia** yang sederhana dan mudah dipahami — laporan, ringkasan, pertanyaan, dan kartu sesi. Istilah teknis hanya bila perlu dan langsung dijelaskan singkat. Jangan menjawab dalam bahasa lain kecuali Lee memintanya.

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

===== AKHIR PROMPT PEMBUKA UNIVERSAL =====

===== LANJUT SESI (bagian tetap, tidak berubah tiap batch) =====

Yang TIDAK ditulis di berkas ini — dan memang tidak boleh: keadaan proyek (commit terakhir, CI, butir tertangguh, rencana). Keadaan yang benar SELALU dibaca dari isi repo setelah kamu menyusul cabang di atas: `docs/ops/SIAP-LANJUT.md` (penunjuk keadaan buatan mesin), `PROJECT_STATE.md`, `STATUS.md`, `_log-sesi/LOG_SESI_*.md`, `docs/TERTANGGUH.md`, dan `docs/teknis/REKAM_PESAN_PEMILIK.md`.

Kalau `alat/lanjut-sesi.py` BELUM ADA (kamu masih di basis `main`/cabang lama), pakai cara tanpa alat ini untuk melihat pilihan sesi:

```
git fetch origin '+refs/heads/arena/*:refs/remotes/origin/arena/*'
git for-each-ref --sort=-committerdate --format='%(refname:short)  %(committerdate:short)  %(subject)' refs/remotes/origin/arena/
```

lalu susul cabang yang Lee maksud dengan perintah `git fetch origin <CABANG-YANG-DIPILIH>:refs/remotes/origin/kerja-terakhir` seperti di atas.

Setelah mendarat di ujung cabang yang benar:
- Jalankan `python3 alat/lanjut-sesi.py` → harus LOLOS (handoff segar & ter-push). Kalau menolak, perbaiki dulu; jangan bekerja di atas handoff basi.
- Jalankan `python3 alat/mulai-sesi.py` → cetak KARTU SESI; laporkan ke Lee SEBELUM bekerja.
- `python3 alat/lanjut-sesi.py --daftar-sesi` bila Lee ingin melihat atau mengganti sesi. Cabang yang **belum pernah di-push** ke GitHub tidak bisa dilanjutkan (pekerjaannya belum tersimpan). Cabang sesi **lama** biasanya membawa alat versi lebih tua — laporkan apa adanya, jangan mengarang mekanisme baru.
- Sesi yang **sengaja ditinggalkan** Lee ada di `docs/ops/SESI_DITINGGALKAN.md`. Jangan menyarankan atau memakai sesi di daftar itu tanpa perintah Lee.

Aturan tetap:
- **Base branch tidak perlu diatur** — Lee tidak mengaturnya; cabang kerja dibuat otomatis oleh platform dan tidak bisa diganti.
- **PR:** PR #1 menunjuk cabang sesi lama, jadi pekerjaanmu TIDAK otomatis masuk PR #1. Bila Lee ingin meninjau lewat PR, buka PR BARU dari cabang sesimu (base `main`) dan laporkan tautannya. **JANGAN MERGE** apa pun tanpa keputusan Lee.
- Bila `docs/ops/SIAP-LANJUT.md` menulis "Cabang yang dilanjutkan" BERBEDA dari baris `SESI YANG AKU LANJUT` di atas: yang menang adalah baris di atas (pilihan terbaru Lee). Laporkan bedanya, lalu rapikan catatannya: `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <CABANG-YANG-DIPILIH>`.
