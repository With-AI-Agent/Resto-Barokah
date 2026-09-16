# Acceptance Test Log — Sistem Building Aplikasi

> Bukti eksekusi skenario ACCEPTANCE_TESTS.md — dicatat per run. Angka stabil dikutip, rujukan volatil tidak dikutip.

## Run 2026-09-15 — Run Klinik Pertama (kit v0.2.0, panggung rawat inap)

- **Tanggal:** 2026-09-15
- **Pelaksana:** agent sesi arena/01a0a48f-pembangun-sistem (run klinik pertama, rawat inap)
- **Kit:** v0.2.0 (master in-place, rawat inap — tanpa salin kit)
- **Target:** sistem/sistem-building-aplikasi (rename SISTEM-BUILDING-APLIKASI → sistem-building-aplikasi)

### Hasil Skenario

| Skenario | Hasil | Bukti |
|---|---|---|
| AT-01 Entry Point | PASS | PROMPT_ENTRI_UNIVERSAL.md + PANDUAN_PENGGUNA.md blok identik (validator pegangan PASS) |
| AT-02 Checkpoint | PASS | STATUS.md field Pekerjaan belum tersimpan: Tidak ada tepat 1x, Waktu pembaruan: 2026-09-15 — Verifikasi D lulus + REKAM-KLINIK cap v0.2.0 + Panen nihil; validate_system.py PASS |
| AT-03 Log Sesi | PASS | _log-sesi/LOG_SESI_2026-09-15.md CLOSED; 10_LOG_SESI.md ada |
| AT-04 Pegangan Identik | PASS | diff blok PANDUAN vs PROMPT = identik (validator pegangan PASS) |
| AT-05 Self-Containment | PASS | tools/check_selfcontained.py --sistem sistem-building-aplikasi --report PASS (1 salinan berlabel, 0 temuan) |
| AT-06 Fondasi Gerbang | PASS | AGENT_SYSTEM.md §Tahap 1-6 menunggu "cukup, tulis draftnya" — agen tidak menulis tanpa approval |
| AT-07 DECISIONS_LOG | PASS | AGENT_SYSTEM.md §DECISIONS_LOG mewajibkan baca + STOP bila ubah Area Berisiko Tinggi |

### Verifikasi Alat (Tahap D)

- _sistem/validate_system.py: PASS
- tools/validate_repo.py: PASS 0 warning (102 docs/327 refs/4 sistem)
- tools/check_selfcontained.py --semua: PASS (4 sistem)
- tools/test_failure_injection.py: PASS 72 skenario (15 sintetis + 13 unit nyata + 14 PR-11 + 10 check_selfcontained + 20 review_prompt)
- tools/backup_verify.py: PASS (backup 36 files, restore OK)
- tools/build_template.py: PASS (smoke extract + template clean)

### Catatan

Run ini adalah run pertama Klinik (pola F-8) — AT dijalankan penulis perubahan; verifikasi pihak kedua = review independen PR ini + run berikutnya. Panen F = nihil (tidak ada cacat baru di luar C-01…C-06).

## Run 2026-09-16 — Run Klinik Ke-2 (kit v0.2.0, panggung rawat inap, audit menyeluruh)

- **Tanggal:** 2026-09-16
- **Pelaksana:** agent sesi arena/01a0a7d3-pembangun-sistem (run klinik ke-2, rawat inap)
- **Kit:** v0.2.0 (master in-place — cap REKAM-KLINIK run 1 juga v0.2.0, jadi tanpa tawaran naik versi, tidak fail-closed)
- **Pemicu:** pemilik mau memakai sistem ini tapi ragu "beneran siap pakai dan aman", setelah menemukan `PANDUAN_PEMAKAIAN.md` yang menyebut hanya `AGENT_SYSTEM.md` yang masuk repo baru. Permintaan pemilik: audit + pemeriksaan mendalam, **baca dan periksa semua berkas folder tanpa terkecuali, termasuk berkas khusus pengguna**.
- **Lingkup yang dibaca:** 13 berkas root, 4 arsip audit + validator + 10 template di `_sistem/`, `docs/README.md`, `_log-sesi/` arsip, `_salinan-meta/`, `skills/README.md` + 2 `CATALOG.md`, dan inventaris 1.802 berkas vendor di `skills/` (scan keamanan, bukan baca satu-satu — konten vendor pihak ketiga).

### Hasil Skenario

| Skenario | Hasil | Bukti |
|---|---|---|
| AT-01 Entry Point | PASS | `PROMPT_ENTRI_UNIVERSAL.md` + blok pertama `PANDUAN_PENGGUNA.md` identik (cek validator `check_pegangan` PASS); semua berkas yang dirujuk prompt ADA di repo hasil copy (AT-08 butir 6) |
| AT-02 Checkpoint | PASS | `STATUS.md` `**Pekerjaan belum tersimpan:** Tidak ada` tepat 1x + `**Waktu pembaruan:** 2026-09-16 — Run klinik ke-2 …`; validator exit 0 |
| AT-03 Log Sesi | PASS | `10_LOG_SESI.md` (7 aturan) + `_log-sesi/LOG_SESI_2026-09-15.md` CLOSED berpenanda arsip; log run ke-2 di level repo meta: _log-sesi/LOG_SESI_2026-09-16.md (di luar folder ini, jadi ditulis sebagai provenance tanpa backtick) |
| AT-04 Pegangan Identik | PASS | cek `check_pegangan` PASS (blok prompt tidak diubah run ini) |
| AT-05 Self-Containment | PASS | `tools/check_selfcontained.py --sistem sistem-building-aplikasi --report` → temuan 0, `HASIL SISTEM: PASS` (1 salinan berlabel `_salinan-meta/PLATFORM_LMARENA.md`) |
| AT-06 Fondasi Gerbang | PASS (bukti dokumen) | `AGENT_SYSTEM.md` Tahap 1-6: "JANGAN tulis dokumen final sebelum user bilang 'cukup, tulis draftnya'" — **belum diuji perilaku nyata** (butuh run Fondasi pertama); dinyatakan apa adanya, bukan diklaim teruji |
| AT-07 DECISIONS_LOG | PASS (bukti dokumen) | `AGENT_SYSTEM.md` § Aturan Mengikat + Stop Conditions — sama seperti AT-06, bukti dokumen |
| **AT-08 Copy → Repo Standalone** | **PASS** | `cp -r` ke `/tmp/app-uji` + `rm _Notes.md` + `git init` + commit `d779211`: validator lokal **exit 0 tanpa `tools/`**; `find skills -mindepth 1 -maxdepth 1 -type d \| wc -l` = **56**; `du -sh skills` = **26M**; 1.832 berkas; `.git` 14M; `tools/` TIDAK ada, `_meta/` TIDAK ada, `PROJECT_STATE.md` TIDAK ada (→ proyek baru, Tahap 1); 14 berkas yang dirujuk prompt entri **semua ADA**; **rujukan berprefix menggantung = 0** (run final; pada run pertama cek ini menangkap 3 rujukan menggantung yang justru berasal dari prose log run ke-2 sendiri — rujukan ke log level repo meta, path upstream Archive.zip, dan nama berkas terpotong elipsis — ketiganya diperbaiki, bukan dikecualikan) |
| **AT-09 Anti-Pedoman-Usang-Hidup** | **PASS (5/5 mutasi terdeteksi)** | Kondisi bersih exit 0; mutasi (a) penanda arsip `PANDUAN_PEMAKAIAN.md` dihapus → GAGAL, (b) header `skills/README.md` 56→52 dirs → GAGAL, (c) suntik "hanya `AGENT_SYSTEM.md`" ke `START_DI_SINI.md` → GAGAL, (d) suntik `` tools/validate_repo.py `` ke `STATUS.md` → GAGAL, (e) atribut `**Verifikasi:**` dihapus dari `_sistem/templates/ROADMAP.md` → GAGAL; semua dikembalikan → PASS lagi |

### Verifikasi Alat (Tahap D, keluaran mentah)

- `python3 sistem/sistem-building-aplikasi/_sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`, exit 0 (**9 berkas wajib** + 5 cek baru run ke-2)
- `python3 tools/validate_repo.py` → `VALIDATION PASSED: 29 required files and Markdown invariants checked` / `SYSTEMS CHECKED: 4 registered + pilot excluded by design` / `WARNINGS: none` / **0 unresolved**.
  - **Angka coverage (jumlah dokumen aktif & rujukan path) SENGAJA TIDAK DIKUTIP** — aturan meta C5 + AT-16 (di repo meta: _meta/00_CARA_KERJA_META.md § Bukti numerik permanen C5 + _meta/ACCEPTANCE_TESTS.md AT-16 — ditulis sebagai provenance tanpa backtick karena area itu tidak ikut ter-copy): angka itu dihitung dari korpus dan berubah setiap ada entri log baru, **dilarang dikutip di bukti permanen termasuk bila dipin ke SHA**. Run ini membuktikannya sendiri: hitungan nyata 339 (base) → 361 (tiap commit sejak `e438cee`), sedangkan draf pertama log ini sempat mengutip 354 dan body PR sempat mengutip 360 — **dua-duanya tidak cocok commit mana pun** (temuan reviewer R-1, putaran 1). Yang permanen = verdict + perintah reproduksi: `python3 tools/validate_repo.py`.
  - Catatan jujur: sempat **2 warning** (`AGENT_SYSTEM.md:150-151` unresolved `discovery-interview-prep/SKILL.md`, `prd-development/SKILL.md`) akibat teks baru run ini → diperbaiki jadi path penuh → 0 unresolved. Tidak dibiarkan lolos.
- `python3 tools/check_selfcontained.py --semua --report` → `HASIL AKHIR: PASS` (4 sistem); building: **temuan 0**, salinan berlabel 1 (`_salinan-meta/PLATFORM_LMARENA.md`, perbedaan: tidak ada). Hitungan "rujukan historis" dan "sebutan area" tidak dikutip karena alasan yang sama (volatil terhadap penulisan dokumen).
- **Catatan append-only:** bagian run ke-1 di berkas ini (baris ~27) masih mengutip `102 docs/327 refs` — itu riwayat yang sudah ter-merge di `main` dan **tidak diedit** (koreksi = entri baru, bukan menulis ulang riwayat). Penyimpangan lama itu dilaporkan ke pemilik sebagai housekeeping meta, bukan diperbaiki diam-diam.
- `python3 tools/test_failure_injection.py` → `FAILURE-INJECTION TESTS PASSED: 72 scenarios (15 sintetis + 13 unit nyata + 14 regresi review PR-11 + 10 regresi check_selfcontained + 20 regresi review_prompt)`
- Tidak dijalankan run ini: tools/backup_verify.py, tools/build_template.py (PASS pada PR #59; tidak ada berkas yang mereka uji yang diubah run ini)

### Scan keamanan `skills/` (read-only, 1.802 berkas / 26M)

- Kredensial nyata (`ghp_`, `sk-`, `AKIA`, `xox*`, `-----BEGIN … PRIVATE KEY`): **0**; `.env`/`.pem`/`.key`/nested `.git`: **0**
- `curl … | sh`: **1**, sebagai teks dokumentasi di `skills/README.md` (bukan perintah); `base64 -d | sh`: 0; `eval(`: 0
- `rm -rf`: **11** — semua di skrip/CI/docs vendor dengan target variabel lokal (`$SESSION_DIR`, `$TEMP_DIR`, `.probe`, DerivedData); `sudo`: **4** — semua `sudo xcode-select -s` (docs/CI iOS)
- 37 berkas ber-bit executable + 127 skrip `sh/py/js/ts` (wajar untuk skill vendor); skill Google butuh OAuth browser
- **Kesimpulan:** tidak ada indikasi malware atau kebocoran kredensial. Risiko nyata = bobot 26M per repo aplikasi (keputusan pemilik) + 5 folder skill di-rename terhadap `name:` upstream (catatan `skills/README.md` § Integritas vendor)

### Temuan yang diperbaiki (11 Critical + 9 Minor)

Critical: K-1 dua pedoman aktif bertentangan (`PANDUAN_PEMAKAIAN.md` vs `PANDUAN_PENGGUNA.md`); K-2 manifest basi (dokumen wajib, 7 vs 10 template, 8.1M/52 dirs); K-3 RINGKASAN cadangan basi total (W-09); K-4 `STATUS.md` narasi run "sedang berjalan"/"Merge PR (G-Final)"; K-5 `AGENT_SYSTEM.md` melarang folder `panduan-owner` yang tidak ada; K-6 kalimat ganda akhir Tahap 5; K-7 aturan branch deskriptif bertentangan dengan fakta platform branch `arena/...` otomatis (juga di `_sistem/templates/AGENT_OPERATING_GUIDE.md`); K-8 `_sistem/templates/ROADMAP.md` mencontohkan bentuk singkat yang DILARANG `AGENT_SYSTEM.md` Tahap 5; K-9 LANGKAH 0 bisa deadlock di sesi perawatan sistem (profil sengaja kosong → "JANGAN lanjut ke proyek"); K-10 `skills/README.md` 9 kontradiksi internal (header 26M/56 dirs vs "Registrasi 8.1M, 52 dirs", "hemat 85%", ukuran per-skill basi, `banner` vs `banner-design`, `awesome-agent-skills` 224K vs 16K nyata, 18 vs 17 sub-skill, hub 35M/42k vs 71M/787 valid); K-11 angka katalog `248+797`/`1045` tidak selaras dengan `CATALOG.md` (787 skill valid dari 797 direktori).

Minor: M-1 perintah copy `commit -m "… 8.1M"`; M-2 `skills/vercel-deploy/Archive.zip` (TIDAK dihapus — lihat catatan pembatalan); M-3 bukti kesiapan struktural saja (→ AT-08 dry-run); M-4 `REKAM-KLINIK.md` tanpa penanda arsip saat ikut ter-copy; M-5 arsip `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md` menyebut "skills/ 8.1M" sebagai keadaan kini; M-6 6 direktori agregat tanpa `SKILL.md` di akar (aturan resolve belum eksplisit); M-7 rujukan `_cadangan-claude/` ber-backtick di dokumen aktif (area yang tidak ikut keluar dari master); M-8 `_Notes.md` (catatan pribadi + tautan chat) ikut ter-copy ke repo aplikasi tanpa penanda; M-9 `docs/README.md` menyebut folder "kosong" padahal berisi `README.md`, dan menyebut "keenamnya" tanpa menyebut 10 template.

### Catatan pembatalan item rencana (jujur, bukan disamarkan)

Item 8 rencana (disetujui pemilik di G-Rencana) adalah **hapus `skills/vercel-deploy/Archive.zip`** sebagai sampah biner. Bukti baru membatalkannya: berkas itu **bagian dari repo upstream** vercel-labs/agent-skills (path upstream skills/deploy-to-vercel/Archive.zip — folder lokal kita `skills/vercel-deploy/`, ukuran identik 11.314 bytes; `SKILL.md` 11.786 bytes juga identik) — menghapusnya akan **membatalkan jaminan "byte-identik dengan `npx`"** yang dijanjikan `skills/README.md` dan membuat `npx skills update` melihat selisih. Tindakan yang diambil: **dipertahankan + didokumentasikan** (`skills/README.md` § Integritas vendor butir 2: jangan diekstrak/dipakai). Penyimpangan dari rencana ini dilaporkan ke pemilik di G-Final; pemilik tetap boleh memerintahkan penghapusan.

### Catatan pola F-8 (verifikasi pihak kedua)

Run ini kembali dijalankan oleh penulis perubahan (agent yang sama yang memperbaiki). Yang membedakan dari run 1: AT-08/AT-09 memberi **bukti eksekusi** (dry-run nyata + uji mutasi 5/5), bukan hanya bukti baca dokumen, dan review independen PR ini menjadi verifikasi pihak kedua. AT-06/AT-07 tetap **bukti dokumen** — dinyatakan apa adanya; verifikasi perilaku sesungguhnya = run Fondasi Tahap 1 pertama di repo aplikasi nyata.

### Panen (Tahap F)

**Tidak nihil.** Satu cacat di luar katalog C-01…C-06 ditemukan dan diusulkan jadi butir baru: **C-07 "Dokumen Pengganti yang Tidak Dipensiunkan (superseded-but-live)"** — ditambah ke `sistem/sistem-klinik/_sistem/02_KATALOG_CACAT.md` lewat mekanisme promosi (Aturan Promosi butir 4). Celah aturan kit yang ketahuan: Kebijakan Lebur melarang overwrite/hapus tanpa izin (benar), tetapi **tidak ada butir yang mewajibkan dokumen yang digantikan diberi penanda arsip** — akibatnya run 1 meninggalkan pedoman lama yang hidup dan menyesatkan. Usulan: penanda arsip jadi bagian Kontrak Tanaman/planting checklist.

## Run 2026-09-16 (putaran 2) — Perbaikan temuan review independen PR #63

- **Tanggal:** 2026-09-16
- **Pelaksana:** agent sesi arena/01a0a7d3-pembangun-sistem (penulis PR; reviewer = sesi independen lain)
- **Pemicu:** review independen PR #63 **putaran 1 = MERAH** (4 temuan R-1…R-4 + 2 catatan pra-ada). Semua gerbang fungsional direproduksi HIJAU oleh reviewer; yang MERAH adalah **angka di bukti permanen yang tidak cocok commit mana pun**.
- **Sikap terhadap temuan:** direproduksi sendiri dulu, bukan dipercaya/dibantah. Hasil reproduksi penulis = **sama persis** dengan reviewer: hitungan rujukan nyata 361 di setiap commit sejak `e438cee` (339 di base..`40cfb06`) → angka 354 dan 360 tidak cocok commit mana pun; berkas validator di base = **108 baris** (bukan 154); `du -sb skills` head = **23.104.989** vs kutipan 23.099.842 (selisih = pembesaran `skills/README.md` oleh PR ini sendiri); `AGENT_SYSTEM.md` = **50.527 bytes** (bukan "46K").

### Akar penyebab (satu, bukan empat)

Keempat temuan adalah **satu pola**: angka yang dihitung dari korpus/berkas yang kita sunting sendiri ditulis ke bukti permanen, lalu basi pada commit yang sama yang menuliskannya. Aturan meta sudah melarangnya (C5 "Bukti numerik permanen" + AT-16: dilarang dikutip **termasuk bila dipin ke SHA**) — run ini melanggar aturan yang justru sedang dikuatkan. Maka perbaikannya **bukan memperbarui angkanya** (itu hanya mengulang siklus), melainkan:

1. **Buang** angka korpus dari dokumen permanen: indeks sistem di repo meta (area luar folder → ditulis sebagai provenance tanpa backtick), `REKAM-KLINIK.md`, dan transkrip ini. Yang dikutip = verdict (`PASS`, `0 warning`, `0 unresolved`) + perintah reproduksi.
2. **Buang** total byte eksak `skills/` dari `skills/README.md` (3 tempat) + `_cadangan-claude/RINGKASAN_…` — besaran itu bergerak tiap kali README-nya disunting. Yang tetap: `du -sh` kasar, jumlah direktori (ditegakkan validator terhadap hitungan nyata), jumlah berkas, dan perintah ukur.
3. **Buang** klaim ukuran `AGENT_SYSTEM.md` dari Log Keputusan `PANDUAN_PENGGUNA.md` (bukan diganti angka lain).
4. **Tanam gerbang** supaya pola ini tidak bisa kembali: cek ke-6 `check_no_volatile_corpus_numbers` (angka korpus + transisi jumlah baris dilarang di 11 dokumen keadaan; transkrip append-only dikecualikan karena riwayat ter-merge tidak boleh ditulis ulang) dan cek ke-7 `check_7_atribut_di_aturan_agent` (kalimat aturan Tahap 5 + **tiap task contoh** wajib memuat 7 atribut).

### Perbaikan 2 catatan pra-ada (di luar temuan reviewer, ikut dikerjakan)

- `SYSTEM_MANIFEST.md` baris Acceptance masih menyebut "(0.1.0 / Siap dipakai — G-Rencana 2026-09-15)" padahal Versi = 0.2.0 → disegarkan (riwayat 0.1.0 tetap disebut sebagai sebelumnya).
- `AGENT_SYSTEM.md` Tahap 5: **contoh inline task hanya memuat 6 atribut** (tanpa `Tujuan`) dan kalimat aturannya juga hanya menyebut 6 — bertentangan dengan butir 3 di berkas yang sama ("WAJIB punya 7 atribut lengkap") → contoh ditulis ulang ke bentuk 7 atribut per task (selaras `_sistem/templates/ROADMAP.md`) + kalimat aturan menyebut ketujuhnya. Ini keluarga C-07 (dokumen bertentangan dengan dirinya sendiri).

### Hasil Skenario (diulang penuh pada keadaan final)

| Skenario | Hasil | Bukti |
|---|---|---|
| AT-08 Copy → Repo Standalone | **PASS** | `cp -r` ke `/tmp/at` + `rm _Notes.md` + `git init` + commit → validator lokal **exit 0 tanpa `tools/`**; 56 direktori `skills/`; `du -sh` 26M; **1.832 berkas** (di luar `.git`); `.git` 14M; `tools/`, `_meta/`, `PROJECT_STATE.md` TIDAK ada; **rujukan konkret menggantung = 0**; `git status --porcelain` bersih setelah semua mutasi dipulihkan |
| AT-09 Anti-Pedoman-Usang-Hidup | **PASS — 8/8 mutasi terdeteksi + kontrol negatif lolos** | M1 penanda arsip dihapus → GAGAL · M2 header 56→52 dirs → GAGAL · M3 klaim satu berkas disuntik → GAGAL · M4 rujukan ber-backtick ke alat master → GAGAL · M5 atribut template ROADMAP dihapus → GAGAL · **M6 angka korpus disuntik ke manifest → GAGAL (cek baru)** · **M7 `Tujuan` dihapus dari satu task contoh → GAGAL (cek baru, per-task)** · **M8 kalimat aturan jadi 6 atribut → GAGAL (cek baru)** · **M9 kontrol negatif: verdict "0 rujukan menggantung" tetap PASS** (bukan positif palsu) |

### Verifikasi Alat (putaran 2, keadaan final)

- `python3 _sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`, exit 0 (9 berkas wajib + **7 cek** anti-cacat)
- `python3 tools/validate_repo.py` → `VALIDATION PASSED`, `WARNINGS: none`, **0 unresolved**, `SYSTEMS CHECKED: 4 registered + pilot excluded by design` — angka coverage tidak dikutip (C5/AT-16)
- `python3 tools/check_selfcontained.py --semua` → `HASIL AKHIR: PASS`
- `python3 tools/test_failure_injection.py` → `FAILURE-INJECTION TESTS PASSED: 72 scenarios`
- `python3 sistem/sistem-klinik/_sistem/validate_system.py` → `SYSTEM-KLINIK VALIDATOR: PASS`

### Kesalahan agent pada putaran ini (dicatat, bukan dihaluskan)

1. Draf pertama transkrip putaran 2 mengutip path area meta dengan backtick → **2 temuan validator** → ditulis ulang sebagai provenance.
2. Spesifikasi AT-09 di `ACCEPTANCE_TESTS.md` sempat **memuat literal terlarang** (kalimat klaim satu berkas, nama berkas alat master, contoh angka korpus) sehingga melanggar ceknya sendiri — paradoks swarujuk. Diperbaiki: spesifikasi menyebut **pola** mutasinya saja, perintah persisnya hidup di transkrip ini.
3. Skrip uji mutasi pertama punya bug pemulihan (`cp` menimpa ke root, bukan ke path asal) sehingga M2 tidak pernah dipulihkan dan 4 mutasi berikutnya melaporkan temuan yang salah. Diperbaiki: pemulihan lewat `git checkout -- . && git clean -fdq`, lalu seluruh suite diulang dari salinan bersih.
4. Riwayat git lokal sempat **hilang** (sandbox di-restore: HEAD jatuh ke base, commit lokal lenyap) sementara working tree utuh. Dipulihkan dengan `git fetch origin <branch>` + verifikasi isi identik + `git reset FETCH_HEAD` — **tanpa** force-push dan tanpa kehilangan satu pun perubahan.

### Catatan append-only (putaran 2) — diperbarui setelah keputusan pemilik 2026-09-16

Bagian run ke-2 putaran 1 di berkas ini sempat mengutip angka coverage (`354`); entri itu **dikoreksi di tempat** karena PR-nya **belum di-merge** (masih satu unit kerja yang sama, bukan riwayat pihak lain) — reviewer putaran 2 memeriksa keputusan ini dan menerimanya (numstat base→head berkas ini tetap **0 delesi**, tidak ada baris milik `main` yang berubah).

**Koreksi atas riwayat ter-merge (baris ~27, bagian run ke-1):** baris `- tools/validate_repo.py: PASS 0 warning (102 docs/327 refs/4 sistem)` mengutip angka korpus yang **kini dilarang** oleh aturan meta C5 + AT-16 (dan oleh cek `check_no_volatile_corpus_numbers` di `_sistem/validate_system.py`). Baris itu ** SENGAJA TIDAK DIEDIT**: ia sudah ter-merge di `main` lewat PR #59, dan menulis ulang riwayat ter-merge dilarang (append-only; koreksi = entri baru). Yang benar: verdict-nya (`PASS 0 warning`) tetap sah dan masih bisa direproduksi dengan `python3 tools/validate_repo.py`; **angka coverage-nya tidak boleh dipakai lagi sebagai bukti** dan tidak boleh ditiru di run berikutnya. Pemilik memutuskan 2026-09-16 ("diperbaiki semuanya sekarang, supaya sekalian") bahwa penandaan ini dilakukan di PR ini juga, bukan ditunda ke run housekeeping tersendiri.

**Koreksi angka di log sesi (append-only):** entri log sesi level repo meta: _log-sesi/LOG_SESI_2026-09-16.md (di luar folder ini — ditulis sebagai provenance tanpa backtick supaya tidak jadi rujukan menggantung di repo standalone) sempat menulis validator "226→303 baris". Nyata: **308 baris** di `590acd1` maupun di head, dengan **12 fungsi `check_*`** (5 bawaan + 7 ditanam run ke-2). Ditemukan reviewer putaran 2 (catatan non-penghalang); dikoreksi lewat entri baru di log, bukan dengan menyunting entri lama.

## Run 2026-09-16 (putaran 3) — mandate pemilik "selesaikan, bereskan, sempurnakan semuanya"

**Konteks:** review independen PR #63 putaran 2 = HIJAU. Penulis menunda dua hal supaya delta pasca-verdict tetap minimal; pemilik lalu memandatkan semuanya dikerjakan. Putaran ini **bukan** perbaikan temuan review — isinya: (1) gerbang baru untuk kelas cacat yang tiga kali lolos dari penulis sendiri, (2) housekeeping meta yang tertunda, (3) panen C-07 ke kit Klinik (bukti di ACCEPTANCE_TEST_LOG sistem klinik).

### Cek ke-8: scan rujukan AT-08 ditanam jadi gerbang permanen

- Cek baru `check_no_dangling_internal_refs` di `_sistem/validate_system.py`: token ber-backtick berprefix internal (`_sistem/`, `skills/`, `docs/`, `_log-sesi/`, `_salinan-meta/`) wajib nyata ada di dalam folder. Vendor di dalam `skills/` tidak dipindai (rujukan internal skill = positif palsu).
- **Pemicu nyata (bukan teoritis):** teks koreksi yang ditulis penulis sendiri di bagian putaran 2 berkas ini mengutip log sesi level repo meta dengan backtick → scan AT-08 menangkapnya sebagai rujukan menggantung, validator tidak. Ini **kali ketiga** pola yang sama di run ke-2 (sebelumnya: rujukan path master-only di `AGENT_SYSTEM.md`, lalu rujukan alat meta di transkrip).
- Total fungsi cek sekarang **13** (5 bawaan + 8 ditanam run ke-2).

**Uji mutasi cek ke-8** (mutasi di pohon kerja, dipulihkan dengan `git checkout -- <berkas yang sudah di-commit>`; keadaan akhir diverifikasi bersih):

| # | Mutasi | Hasil |
|---|---|---|
| M11 | suntik ke `STATUS.md` rujukan ber-backtick ke path internal yang tidak ada di folder (di bawah `_sistem/templates/`) | **GAGAL** — "rujukan ber-backtick … tidak ada di dalam folder — di repo standalone (AT-08) ini jadi rujukan menggantung" |
| M12 | suntik ke `STATUS.md` rujukan ber-backtick ke log sesi level repo meta di bawah `_log-sesi/` (varian yang benar-benar terjadi) | **GAGAL** — pesan sama |
| N1 | kontrol negatif: rujukan berprefix internal ke berkas yang **nyata ada** (`_sistem/templates/ROADMAP.md`, `docs/README.md`) | **PASS** |
| N2 | kontrol negatif: sebutan area berakhiran garis miring (`skills/`, `docs/`) | **PASS** |
| N3 | kontrol negatif: pola/placeholder bertanda bintang dan kurung siku | **PASS** |

Catatan proses yang jujur: saat menulis spesifikasi AT-09 untuk cek ini, prosa penulis sendiri ("AT-08 menangkap 1 rujukan menggantung") **tertangkap cek anti-angka-korpus** (cek ke-6) — redaksinya dibuang angkanya. Gerbangnya bekerja pada penulisnya sendiri.

### AT-09 penuh (9 mutasi + 4 kontrol negatif) — LULUS

Semua mutasi M1-M8 dari putaran 2 diulang di head putaran 3 dan tetap **GAGAL** (terdeteksi): penanda arsip `PANDUAN_PEMAKAIAN.md`; klaim jumlah direktori di header `skills/README.md`; klaim satu berkas di `START_DI_SINI.md`; rujukan ber-backtick master-only di `STATUS.md`; atribut task di `_sistem/templates/ROADMAP.md`; angka korpus di `SYSTEM_MANIFEST.md`; atribut `Tujuan` hilang dari satu task contoh `AGENT_SYSTEM.md`; kalimat aturan Tahap 5 jadi 6 atribut; **ditambah M11/M12** di atas. Kontrol negatif: N1-N3 di atas **plus** verdict "0 rujukan … menggantung" tetap **PASS** (tidak jadi positif palsu cek ke-6).

### AT-08 (copy → repo standalone) — diulang di head putaran 3, LULUS

`cp -r` seluruh isi folder ke direktori kosong → hapus `_Notes.md` → `git init` + commit → jalankan validator dari salinan (tanpa alat meta):

- `python3 _sistem/validate_system.py` → **PASS**, exit 0 (9 berkas wajib + 8 cek, termasuk cek ke-8 yang baru)
- `find skills -mindepth 1 -maxdepth 1 -type d | wc -l` → **56** = klaim dokumen; `du -sh skills` → **26M**
- berkas di salinan (di luar `.git`) → **1.832**; `tools/`, `_meta/`, `PROJECT_STATE.md` → **tidak ada** (sesuai desain)
- scan rujukan berprefix internal → **0 menggantung**

### Housekeeping meta (bagian dari putaran ini, di luar folder sistem)

5 artefak review/audit yang tergeletak di root repo **dipindah, bukan dihapus** ke _meta/_internal/arsip-review-2026-09-16/ (ditulis tanpa backtick: area itu milik repo meta dan tidak ikut ter-copy) + README arsip + banner arsip di kepala 3 berkas `REVIEW_*`; isi asli tidak disunting. Dua berkas audit terbukti duplikat byte-identik (md5) dari salinan kanonik di `_sistem/`. Temuan yang **tidak** ditindak sendiri (cabang remote tanpa PR yang memegang bukti review pihak lain; log sesi OPEN milik sesi lain) didokumentasikan di _meta/_internal/HOUSEKEEPING_2026-09-16.md dengan rekomendasi + perintah, karena tindakan destruktif lintas sesi butuh izin per-item (Kebijakan Lebur Aturan 2).

Rujukan yang tadinya menunjuk path root disesuaikan di `REKAM-KLINIK.md` — kalau tidak, pemindahan itu justru menciptakan rujukan menggantung (kelas cacat yang baru saja ditanam gerbangnya).

### Verifikasi struktural putaran 3 (tanpa angka korpus — C5/AT-16)

- `python3 _sistem/validate_system.py` → **PASS** (9 berkas wajib + 8 cek)
- `python3 tools/validate_repo.py` → **PASS, WARNINGS: none, 0 unresolved**
- `python3 tools/check_selfcontained.py --semua` → **HASIL AKHIR: PASS**
- `python3 tools/test_failure_injection.py` → **PASSED: 72 skenario**
- `python3 sistem/sistem-klinik/_sistem/validate_system.py` → **PASS** (sistem yang dipanen tetap hijau; sebelum kit disinkron cek barunya **GAGAL** = bukti menyala)
