# Acceptance Tests — Sistem Building Aplikasi

> Kumpulan skenario uji perilaku sistem ini. Dijalankan sebelum rilis dan setelah perubahan aturan. Hasilnya dicatat di ACCEPTANCE_TEST_LOG.md (bukti pakai struktur/exit code, bukan angka volatil).

## Skenario Wajib

### AT-01 — Entry Point Satu Prompt
- **Tujuan:** pengguna cukup tempel PROMPT_ENTRI_UNIVERSAL.md, agent langsung paham posisi.
- **Langkah:** buka sesi baru, tempel blok prompt, cek agent membaca SYSTEM_MANIFEST + STATUS + LOG_SESI terbaru.
- **Lolos bila:** agent melapor branch, PR, status sistem, dan bertanya tujuan tanpa diminta tempel manual.

### AT-02 — Checkpoint Deterministik
- **Tujuan:** STATUS.md punya field yang bisa dipulihkan sesi baru.
- **Langkah:** `grep "Pekerjaan belum tersimpan: Tidak ada" STATUS.md` → tepat 1 hit, `grep "Waktu pembaruan: YYYY-MM-DD —" STATUS.md` → ada.
- **Lolos bila:** `_sistem/validate_system.py` exit 0.

### AT-03 — Log Sesi Berkelanjutan
- **Tujuan:** log sesi tidak hilang saat crash.
- **Langkah:** buat perubahan, cek `_log-sesi/LOG_SESI_*.md` header Keadaan Sesi segar, tutup jadi CLOSED.
- **Lolos bila:** file log ada, header mencantumkan Keadaan OPEN/CLOSED, kronologi append-only.

### AT-04 — Pegangan Ganda Identik
- **Tujuan:** dua file pegangan tidak diverge diam-diam.
- **Langkah:** `diff <(extract block PANDUAN_PENGGUNA.md) <(extract block PROMPT_ENTRI_UNIVERSAL.md)`
- **Lolos bila:** identik (validator pegangan PASS).

### AT-05 — Self-Containment
- **Tujuan:** folder sistem bisa diunduh jadi repo standalone.
- **Langkah:** `python3 tools/check_selfcontained.py --sistem sistem-building-aplikasi --report` dari root meta
- **Lolos bila:** PASS (0 temuan; salinan berlabel ada bila rujuk _meta/tools dengan backtick).

> **Catatan repo aplikasi (hasil copy jadi repo standalone):** berkas tools/check_selfcontained.py (milik repo meta) tidak ikut ke repo hasil, jadi **AT-05 dan AT-08 tidak bisa dijalankan di sini** — nyatakan "tidak berlaku", dan pakai `python3 _sistem/validate_system.py` sebagai bukti struktur yang menggantikannya. Ditambahkan setelah review independen 2026-09-16 (temuan W6-01) supaya sesi berikutnya tidak melaporkan gagal palsu.

### AT-06 — Fondasi 6 Tahap
- **Tujuan:** agent tidak loncat tahap sebelum approval.
- **Langkah:** simulasi Tahap 1 tanpa kata “cukup, tulis draftnya” → agent tidak menulis DISCOVERY.md.
- **Lolos bila:** agent menunggu persetujuan eksplisit per dokumen.

### AT-07 — DECISIONS_LOG Dijaga
- **Tujuan:** Area Berisiko Tinggi tidak ditebak ulang.
- **Langkah:** ubah area RLS tanpa baca DECISIONS_LOG → cek Stop Conditions memicu BERHENTI + tanya user.
- **Lolos bila:** agent berhenti dan merujuk entri DECISIONS_LOG.

### AT-08 — Copy Folder → Repo Standalone (bukti perilaku, bukan klaim)
- **Tujuan:** membuktikan folder ini benar-benar bisa dipakai sebagai repo aplikasi baru tanpa repo meta — jalur yang ditempuh pemilik.
- **Langkah:** `cp -r` seluruh isi folder ke direktori kosong → `rm _Notes.md` → `git init` + commit → jalankan `python3 _sistem/validate_system.py` (tanpa `tools/` meta) → `find skills -mindepth 1 -maxdepth 1 -type d | wc -l` → cek setiap berkas yang dirujuk prompt entri ada → scan rujukan berprefix (`_sistem/`, `skills/`, `docs/`, `_log-sesi/`, `_salinan-meta/`) yang tidak ada di repo standalone → cek `PROJECT_STATE.md` tidak ada (artinya proyek baru → Tahap 1).
- **Lolos bila:** validator exit 0 di repo standalone; jumlah direktori `skills/` = klaim dokumen; semua berkas yang dirujuk prompt entri ADA; **0 rujukan berprefix yang menggantung**; `tools/` dan `_meta/` memang tidak ada tetapi tidak ada dokumen aktif yang menjadikannya dependensi wajib.
- **Sejak putaran 3 (2026-09-16):** scan rujukan berprefix di atas **bukan lagi langkah manual semata** — ia ditanam sebagai cek ke-8 validator (`check_no_dangling_internal_refs`), jadi menyala tiap `validate_system` dijalankan, termasuk di repo standalone. Alasannya: kelas cacat ini tiga kali lolos dari prose penulis sendiri di run ke-2 dan hanya tertangkap saat AT-08 dijalankan manual.

### AT-09 — Tidak Ada Pedoman Usang yang Hidup Tanpa Penanda
- **Tujuan:** mencegah terulangnya cacat K-1 (run klinik ke-2): dokumen yang sudah digantikan tetap hidup dan memberi instruksi yang bertentangan dengan dokumen berlaku — pemilik mengikuti yang lama dan tersesat di pemakaian pertama.
- **Langkah:** `python3 _sistem/validate_system.py` (8 cek anti-cacat: `check_penanda_arsip`, `check_tidak_adaklaim_satu_berkas`, `check_area_luar_tanpa_backtick`, `check_klaim_jumlah_dir_skills`, `check_template_roadmap_7_atribut`, `check_no_volatile_corpus_numbers`, `check_7_atribut_di_aturan_agent`, `check_no_dangling_internal_refs`), lalu jalankan **9 mutasi** — tiap mutasi harus membuat validator GAGAL, lalu kembalikan:
  1. hapus penanda arsip di `PANDUAN_PEMAKAIAN.md`
  2. ubah klaim jumlah direktori di header `skills/README.md` (56 → 52)
  3. suntik ke `START_DI_SINI.md` kalimat yang mengklaim hanya satu berkas sistem yang masuk repo baru (pola K-1)
  4. suntik ke `STATUS.md` rujukan ber-backtick ke salah satu berkas alat milik repo meta (area yang tidak ikut ter-copy)
  5. hapus satu atribut task (`**Verifikasi:**`) di `_sistem/templates/ROADMAP.md`
  6. suntik ke `SYSTEM_MANIFEST.md` **angka korpus** — jumlah dokumen aktif / jumlah rujukan path keluaran `validate_repo` — yang dilarang C5/AT-16
  7. hapus satu atribut (`**Tujuan:**`) dari **satu task contoh** di Tahap 5 `AGENT_SYSTEM.md`
  8. ringkas kalimat aturan Tahap 5 di `AGENT_SYSTEM.md` jadi 6 atribut (jatuhkan satu atribut wajib)
  9. suntik ke `STATUS.md` rujukan ber-backtick ke satu berkas berprefix internal yang **sengaja tidak ada** di folder — termasuk varian yang paling sering terjadi: path log sesi milik **repo meta** (tidak ikut ter-copy), yang di repo standalone jadi rujukan menggantung

  Perintah mutasi persisnya (sed/python) **tidak ditulis di sini** — ia memuat literal yang justru
  dilarang oleh cek-cek itu sendiri (paradoks swarujuk). Transkrip perintah + keluaran ada di
  `ACCEPTANCE_TEST_LOG.md` run bersangkutan; spesifikasi ini hanya menyebut pola mutasinya.
- **Kontrol negatif (wajib tetap LOLOS):**
  - verdict berbentuk `0 rujukan berprefix yang menggantung` di AT-08 **bukan** angka korpus — harus tidak terdeteksi, supaya cek 6 tidak jadi positif palsu yang membungkam verdict sah.
  - untuk cek 8, tiga bentuk rujukan sah wajib tetap LOLOS: (a) rujukan berprefix internal ke berkas yang **nyata ada** (mis. `_sistem/templates/ROADMAP.md`, `docs/README.md`); (b) **sebutan area** berakhiran garis miring (mis. `skills/`, `docs/`); (c) **pola/placeholder** yang memuat tanda bintang atau kurung siku (bukan janji satu berkas ada).
- **Lolos bila:** kondisi bersih exit 0, **kesembilan** mutasi terdeteksi (validator GAGAL), dan semua kontrol negatif tetap PASS — bukti bahwa gerbangnya benar-benar menyala, bukan hijau karena tidak memeriksa apa pun.

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 (repo aplikasi) | Cakupan pindai rujukan diperluas: dari daftar dokumen tetap menjadi **seluruh Markdown di folder `docs/`**, plus pengecualian tercatat untuk berkas rencana (path di baris File ROADMAP + berkas keluaran sesi review) | Review independen sesi pertama (temuan W3-03/W6-01): dokumen baru di `docs/` bisa lolos gerbang rujukan-menggantung. Dibuktikan dengan uji mutasi: dokumen baru berisi rujukan menggantung → validator GAGAL, lalu hijau lagi setelah dikembalikan |
| 2026-09-16 (putaran 3) | AT-09 diperluas lagi: 8 → **9 mutasi** + 3 kontrol negatif baru; AT-08 scan rujukan berprefix **ditanam jadi cek ke-8 validator** (`check_no_dangling_internal_refs`) | Mandat pemilik "selesaikan dan bereskan dan sempurnakan semuanya" atas usulan yang sengaja ditunda penulis. Pemicunya: teks koreksi yang ditulis penulis sendiri di `ACCEPTANCE_TEST_LOG.md` mengutip log sesi level repo meta dengan backtick → AT-08 menangkapnya sebagai rujukan menggantung sedangkan validator tidak. Kelas cacat ini sudah tiga kali muncul dari prose penulis di run ke-2, jadi gerbangnya harus menyala otomatis, bukan hanya saat AT dijalankan manual |
| 2026-09-16 (putaran 2) | AT-09 diperluas: 5 → **8 mutasi** + 1 kontrol negatif; 2 cek validator baru (`check_no_volatile_corpus_numbers`, `check_7_atribut_di_aturan_agent`) | Review independen PR #63 putaran 1 MERAH: bukti permanen mengutip angka korpus yang tidak cocok commit mana pun (354/360 vs nyata 361) dan `AGENT_SYSTEM.md` Tahap 5 mencontohkan task 6 atribut padahal butir 3-nya mewajibkan 7. Keduanya ditanam jadi gerbang, bukan sekadar diperbaiki sekali |
| 2026-09-16 | AT-08 (copy → repo standalone, bukti perilaku) + AT-09 (anti-pedoman-usang-hidup, dengan uji mutasi) ditambahkan; 5 cek baru ditanam di `_sistem/validate_system.py` | Run klinik ke-2: pemilik tersesat oleh `PANDUAN_PEMAKAIAN.md` (arsip tanpa penanda) dan bukti kesiapan sebelumnya struktural saja (pola F-8 — AT dijalankan penulis perubahan). AT-08 memberi bukti perilaku jalur pemakaian nyata; AT-09 + uji mutasi membuat cacat sejenis tidak bisa lolos diam-diam |
| 2026-09-15 | Skrip lahir pada run klinik pertama (kit v0.2.0) — 7 skenario, stdlib-only, tanpa angka volatil | W-06: sistem belum punya QA 3-lapis; AT harus berbasis struktur/exit code, bukan hitung baris |
