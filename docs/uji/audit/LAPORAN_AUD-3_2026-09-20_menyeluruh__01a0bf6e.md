# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-20

- **Auditor:** sesi auditor independen `arena/01a0bf6e-resto-barokah` (Arena.ai Agent Mode — model berbeda dari sesi kerja; identitas model persis tidak saya klaim, lihat bagian 6)
- **Tanggal:** 2026-09-20
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `cbba40108fa17eca39a438cd25588f23807873fd` (diverifikasi `git rev-parse HEAD` setelah `git fetch origin arena/01a0b7d1-resto-barokah` + `git checkout --detach`; pohon ini yang benar-benar saya baca dan uji)
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-20.md` (saya menerima varian `AUD-3-2026-09-20-SIAP-TEMPEL.md`; berkas paketnya tidak ada di commit `cbba401` tetapi ada di `cfc6097a14fc6b86733ce91bf6c03589336079c1` — lihat F-06)
- **Mode cakupan:** menyeluruh
- **Verdict:** TIDAK-BERSIH

> Ringkasan sejujurnya: **lapisan uang & RLS di database ini kuat** — 17 serangan saya terhadap uang, eskalasi peran,
> isolasi penyewa, dan jejak semuanya ditolak, dan saya tidak berhasil menaikkan satu pun menjadi K-1. Yang membuat
> verdict TIDAK-BERSIH adalah **K-2 di lapisan janji dokumen & berkas pengguna**: dokumen yang mengikat (KEAMANAN,
> STATUS, PROJECT_STATE, SIAP-LANJUT) menyebut berkas/kontrol yang belum ada tanpa penanda rencana, sementara
> penjaga mesin `alat/periksa-rujukan.py` hanya melihat 11 dari 522 berkas sehingga kelas cacat yang sudah pernah
> membuat CI merah (H F-08, I F-09) tetap hidup di berkas yang paling sering dibaca Lee. Paket §2b butir 5 sendiri
> menyatakan langkah pengguna yang tidak bisa dijalankan apa adanya = **minimal K-2**.

## 1. Cakupan

Cakupan menyeluruh: 498 dari 522 berkas

Metode: setiap grup disentuh dengan perintah nyata (bukan pembacaan sambil lalu). Angka 498 = berkas yang benar-benar
saya buka, jalankan, atau periksa isinya lewat perintah terekam di bawah; 24 sisanya adalah aset biner desain
(`prototipe/aset/*.webp`, `aplikasi/src/gaya/aset/font/*.woff2`) yang hanya saya periksa keberadaan & jumlahnya,
bukan isinya — saya tidak mengklaim telah "memeriksa" byte gambar/huruf.

| # | Artefak | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|
| 1 | Grup **aplikasi/src** (73 berkas) — kode layar/komponen/lib/uji | ya | `cd aplikasi && npm ci && npm test` → `Test Files 11 passed (11) · Tests 101 passed (101)`; `npm run typecheck` & `npm run lint` & `npm run format:check` semuanya hijau; `ls aplikasi/src/layar/*/` → 7 dari 8 folder layar **kosong** (hanya `contoh/` berisi kode) |
| 2 | Grup **aplikasi/alat** (12 berkas) — perkakas pemeriksa aplikasi | ya | `python3 aplikasi/alat/uji-kontras.py` → `RINGKASAN: 166 lolos, 0 gagal`; `periksa-komponen-env.py` → `10 OK · 0 GAGAL`; `periksa-struktur.py`/`periksa-uji.py` → `KEPUTUSAN: LOLOS`; `periksa-node.py` → `LOLOS — 6 pemeriksaan`; `node aplikasi/alat/uji-mutasi-app.mjs` → `LOLOS — 5 mutasi perilaku semuanya membuat uji MERAH` |
| 3 | Grup **aplikasi (konfigurasi)** (17 berkas) | ya | `cat aplikasi/package.json aplikasi/vite.config.ts aplikasi/tsconfig*.json aplikasi/vitest.config.ts aplikasi/.prettierrc.json`; `git check-ignore -v aplikasi/.env` → `aplikasi/.gitignore:4:.env`; `grep -o "^#\? *[A-Z_]\+=" aplikasi/.env.example` → 9 nama variabel (2 aktif, 7 dikomentari) |
| 4 | Grup **supabase/migrations** (17 berkas, 16 `.sql`) | ya | `node alat/uji-sql.mjs` menerapkan `0001`…`0016` berurutan → semua `OK`; `wc -l supabase/migrations/*.sql` → 6472 baris; `grep -c "security definer" supabase/migrations/*.sql` → 76 |
| 5 | Grup **supabase/tes** (59 berkas) | ya | `node alat/uji-sql.mjs` → `uji: 58 LULUS · 0 GAGAL · HASIL: LOLOS` (58 berkas `.sql` + `.gitkeep`) |
| 6 | Grup **supabase/functions** (2 berkas) | ya | `cat supabase/functions/verifikasi_pin/index.ts`; `node alat/uji-edge-pin.mjs` → `RINGKASAN: 17 lolos, 0 gagal`; `python3 alat/periksa-fungsi-pin.py` → `14 lolos, 0 gagal` |
| 7 | Grup **supabase (akar)** (2 berkas) | ya | `cat supabase/README.md supabase/config.toml` — README menjelaskan pemasangan migrasi; sinkron dengan `.github/workflows/sebar-skema.yml` kecuali angka "14 berkas migrasi" (nyata 16) → F-05 |
| 8 | Grup **alat** (48 berkas) | ya | 15 pemeriksa Python dijalankan satu per satu, semuanya `exit=0` (tabel di bagian 2); `python3 alat/uji-mutasi-0012.py` → 16/16 MERAH; `0014` → 17/17 MERAH; `0015` & `0016` → `LOLOS` |
| 9 | Grup **_sistem** (15 berkas) | ya | `python3 _sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`; `ls _sistem/templates/` → 10 template sesuai klaim PANDUAN §733 |
| 10 | Grup **docs (fondasi)** (11 berkas) | ya | `python3 alat/periksa-roadmap.py` → LOLOS; pemindaian rujukan mati saya sendiri atas PRD/TECH_SPEC/ROADMAP/KEAMANAN/SPESIFIKASI_UI/AGENT_OPERATING_GUIDE/DECISIONS_LOG (skrip di F-01) |
| 11 | Grup **docs/uji** (110 berkas) | ya | `python3 alat/periksa-temuan-audit.py` → `86 temuan terlacak · 64 ditutup · 17 terbuka`; `cat docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md docs/uji/PROMPT_AUDIT_INDEPENDEN.md docs/uji/kalibrasi/CARA-PAKAI.md`; `ls docs/uji/audit/` → 17 laporan + 2 folder probe |
| 12 | Grup **docs/teknis** (6 berkas) | ya | `grep -n "PEMULIHAN.md" docs/teknis/BUKU_INSIDEN.md` → baris 148 menyebut berkas yang belum ada **dengan penanda jujur** "(berkas ini belum dibuat…)" — bukan temuan |
| 13 | Grup **docs/ops** (8 berkas) | ya | `cat docs/ops/*.md`; `python3 alat/periksa-rahasia.py` → LOLOS; `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` hanya memuat nilai non-rahasia (URL + `sb_publishable_…`) → cocok klaim |
| 14 | Grup **docs/desain** (59 berkas) | sebagian | `ls docs/desain/`; `python3 prototipe/uji-kontras.py` → `166 lolos, 0 gagal`; 13 berkas gambar `mockup/*.png` & `referensi/` hanya diperiksa keberadaannya |
| 15 | Grup **prototipe** (58 berkas) | ya | `python3 prototipe/alat/periksa-halaman.py` → `183/183 lolos`; `cmp aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` → **IDENTIK** (klaim T0-03 benar) |
| 16 | Grup **_log-sesi** (5 berkas) | ya | `ls _log-sesi/` + baca LOG_SESI 2026-09-15…19; tidak ada rahasia, tidak ada klaim yang bertentangan dengan ROADMAP |
| 17 | Grup **berkas pengguna di akar** (17 berkas) | ya | `python3 alat/periksa-panduan.py` → LOLOS; `grep -o "Sisa temuan terbuka: \*\*[0-9]*\*\*" STATUS.md PROJECT_STATE.md` → `**21**` (nyata 17); rincian lengkap di sub-bagian **1a** |
| 18 | Grup **.github/workflows** (3 berkas) | ya | `cat .github/workflows/ci.yml sebar-skema.yml sebar-halaman.yml`; `python3 alat/periksa-gerbang-ci.py` → LOLOS; `gh run view 35518950919` → `conclusion: success`, `headSha: cbba401…` (klaim CI paket **benar**) |
| 19 | Grup **belum bergrup** (0 berkas) | ya | `git ls-files \| grep -v ^skills/ \| wc -l` → **522**, cocok persis dengan angka paket; tidak ada berkas di luar grup |
| 20 | Bahan kalibrasi `docs/uji/kalibrasi/bahan-2026-09-17/` (5 berkas) | ya | `wc -l docs/uji/kalibrasi/bahan-2026-09-17/*` → 105 baris (20/11/29/14/31); kelima berkas dibaca penuh, hasil di bagian 5 (tidak dihitung sebagai temuan proyek) |
| 21 | **Pengecualian** `skills/` (1803), `_salinan-meta/` (2), `_Notes.md` (1) | ya — saya **SETUJU sebagian** | `ls -d skills/*/ \| wc -l` → 57 folder. Setuju: `skills/` vendored & tidak diubah proyek. **Tetapi saya tolak pengecualian buta**: proyek *merujuk* `skills/…/SKILL.md` sebagai kewajiban auditor, jadi keberadaan berkasnya wajib benar → saya periksa itu dan menemukan F-04. `_salinan-meta/` & `_Notes.md`: setuju dikecualikan (arsip provenance & catatan pribadi, tidak mengikat perilaku sistem) |

### 1a. Berkas untuk pengguna

Diperiksa **dengan cara pengguna**: saya jalankan/ikuti langkahnya, bukan sekadar membacanya.

| # | Berkas | Bisa diikuti orang non-teknis? | Bukti / masalah |
|---|---|---|---|
| 1 | `PANDUAN_PENGGUNA.md` (buku induk, 90.910 karakter) | **Sebagian ya** | `python3 alat/periksa-panduan.py` → `LOLOS — buku induk lengkap, rujukan hidup, prompt identik dengan sumbernya`. Bagian A–H ada, 15 alur (AL-1…AL-15), C1–C7 prompt ada. **Tetapi** baris 427 & 479 merujuk `skills/supabase/SKILL.md` dari konteks yang ditulis `skills/agent-skills-hub` → lihat F-04; baris 544 & 551 menyebut `alat/peta-ui.py` dan `supabase/functions/ringkasan_harian/index.ts` yang belum ada — keduanya **ditandai `(rencana, Fase 1C/10)`**, jadi jujur dan bukan temuan |
| 2 | `PROMPT_ENTRI_UNIVERSAL.md` | ya | Diperiksa identik dengan blok C1 buku induk oleh `periksa-panduan.py`; saya baca dan prompt-nya bisa disalin apa adanya |
| 3 | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B | **ya — saya buktikan sendiri** | Saya adalah pemakainya: paket SIAP-TEMPEL memuat prompt ini apa adanya, dan LANGKAH 0-nya (`git fetch origin <cabang>` → `git checkout --detach <sha>`) **berhasil** di ruang kerja saya yang semula hanya memuat kerangka `main`. Satu rujukan mati: `DECISIONS_LOG.md` (baris 53 konteks `skills/supabase/SKILL.md`) |
| 4 | `START_DI_SINI.md` | ya | Merujuk `PRD.md`/`ROADMAP.md` dsb. tanpa awalan `docs/`, tetapi selalu di dalam kalimat yang menyebut folder `docs/` → tidak menyesatkan |
| 5 | `STATUS.md` | **TIDAK sepenuhnya** | 3 rujukan berkas yang **tidak ada dan tidak ditandai rencana**: `alat/periksa-halaman.py` (nyata `prototipe/alat/periksa-halaman.py`) dan `alat/kalibrasi-cacat.json` ×2 → F-01. Pembaca yang menuruti baris itu menjalankan perintah yang gagal |
| 6 | `PROJECT_STATE.md` | **TIDAK sepenuhnya** | `alat/pratinjau.sh` (nyata `aplikasi/alat/pratinjau.sh` — **persis kelas cacat I F-09 yang pernah memerahkan CI**) + `alat/kalibrasi-cacat.json` + `alat/periksa-semua.sh` → F-01 |
| 7 | `docs/ops/SIAP-LANJUT.md` | **TIDAK sepenuhnya** | baris 206 `alat/pratinjau.sh`, 294/319/333 `alat/kalibrasi-cacat.json` → F-01. Berkas ini adalah **handoff sesi berikutnya**, jadi cacatnya menular |
| 8 | `docs/PANDUAN_PEMILIK.md` | ya | Ikut `BERKAS_PENGIKAT` `periksa-rujukan.py`; pemindaian saya: 0 rujukan mati |
| 9 | `docs/teknis/BUKU_INSIDEN.md` | ya | Satu-satunya rujukan ke berkas belum ada (`docs/teknis/PEMULIHAN.md`) diberi penanda jujur + tugas `T11-10`. **Ini contoh yang benar** — dan membuktikan cacat F-01 bukan gaya penulisan, melainkan inkonsistensi kontrol |
| 10 | `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` | ya | Klaim "repo sudah publik, CI hidup lagi" saya uji: `gh run view 35518950919` → `success` pada `cbba401`. Cocok |
| 11 | `docs/ops/SIAP_AKUN_PEMILIK.md`, `ALAMAT_PUBLIK.md`, `DAFTAR_KUNCI_PEMILIK*.md`, `SESI_DITINGGALKAN.md`, `SIAP-TEMPEL-SESI-BARU.md` | ya | `python3 alat/periksa-rahasia.py` → LOLOS; `git check-ignore -v docs/ops/DAFTAR_KUNCI_PEMILIK.local.md` → `.gitignore:13:*.local.md` |
| 12 | `AGENT_SYSTEM.md` | ya (template) | Rujukan `supabase/migrations/001_users.sql`, `src/lib/supabase.ts` dsb. adalah **contoh generik template sistem**, bukan janji berkas proyek → bukan temuan, tetapi patut dicatat sebagai kebisingan bagi pemeriksa mesin |
| 13 | `PROFIL_PENGGUNA.md`, `PANDUAN_PEMAKAIAN.md`, `SYSTEM_MANIFEST.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TEST*.md`, `REKAM-KLINIK.md`, `PROMPT_SESI_BARU.md` | ya | Dibaca; `PROFIL_PENGGUNA.md` & `ACCEPTANCE_TESTS.md` dijaga `periksa-rujukan.py` (LOLOS) |

**Jawaban atas pertanyaan wajib §2b:** (a) langkahnya **umumnya** bisa diikuti non-teknis — bahasanya sangat baik;
(b) prompt **bisa** disalin apa adanya dan bekerja (saya membuktikannya); (c) **ya, ada langkah yang menyebut berkas
yang tidak ada** (F-01) — dan menurut aturan paket itu minimal K-2; (d) buku induk **lengkap** menurut penjaganya,
tetapi penjaganya tidak melihat STATUS/PROJECT_STATE/SIAP-LANJUT (F-02).

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | "CI commit target: success (run 35518950919)" (paket §lingkup) | `gh run view 35518950919 --json conclusion,headSha` | **BENAR** — `conclusion: success`, `headSha: cbba40108fa17eca39a438cd25588f23807873fd`. Tidak bisa saya bantah |
| 2 | T0-03: "`tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css`" + "19 berkas huruf" | `cmp aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` ; `find aplikasi/src/gaya/aset -name '*.woff2' \| wc -l` | **BENAR** — `cmp` diam (identik), `19`. Catatan: jalur yang ditulis Bukti adalah `tema.css` polos; jalur nyatanya `aplikasi/src/gaya/token/tema.css` (H F-08 menutup varian lain dari kelas yang sama) |
| 3 | T0-04/T0-10: "**76 uji hijau dalam 10 berkas**" (ROADMAP baris 79/88/106/147) | `cd aplikasi && npm test` | **ANGKANYA BASI** — nyatanya **101 uji dalam 11 berkas**. Klaimnya diberi keterangan "(angka saat itu 2026-09-18)" sehingga jujur secara teknis, dan `alat/periksa-angka-bukti.py` LOLOS. Saya **tidak** menjadikannya temuan (aturan: bukan gaya penulisan), tetapi saya catat: 4 tempat masih memajang angka yang bukan keadaan sekarang |
| 4 | T0-04: "`uji-kontras.py` 166 lolos · 0 gagal" | `python3 aplikasi/alat/uji-kontras.py` ; `python3 prototipe/uji-kontras.py` | **BENAR** — keduanya `166 lolos, 0 gagal (130 warna + 36 aturan desain)` |
| 5 | T1-04: "RLS aktif + policy di semua tabel, diperiksa dari katalog" | `node alat/uji-sql.mjs --daftar` | **BENAR** — 26 tabel, semuanya `RLS=ya`, `policy>=1`. Klaim "16 tabel saat itu; hari ini 26" cocok |
| 6 | T1-10: "pembayaran melebihi total ditolak, angka uang tidak bisa dari klien" | probe sendiri `/tmp/probe/a03.sql` (5 serangan sebagai kasir) | **BENAR** — `lebihbayar=ditolak · update=ditolak · delete=ditolak · ubahtotal=ditolak`. Saya gagal membantahnya |
| 7 | KEAMANAN §10: "`catatan_audit` hanya-tambah… rantai hash" | `grep -rn "catatan_audit" supabase/migrations/` | **KOSONG** — tabelnya **belum ada**. §10 menulisnya dalam kalimat *berlaku* ("hanya-tambah, tidak ada hak ubah/hapus untuk siapa pun") padahal T1-13 masih `[ ]`. Hanya butir kedua yang ditandai "Sejak Fase 1B" → **F-03** |
| 8 | KEAMANAN §7: "batas percobaan dua lapis: 5×/akun · 12×/perangkat" | baca `0016` + `supabase/tes/percobaan_pin_perangkat.sql` | **DIKOREKSI PEMBANGUN SENDIRI** — §B1 sudah menulis catatan jujur bahwa lapis perangkat belum berarti sampai T1-24. Klaim tidak bisa saya bantah lebih jauh; uji pagarnya nyata dan lulus |
| 9 | `sebar-skema.yml` baris 3: "menyebar **14 berkas migrasi**" | `ls supabase/migrations/*.sql \| wc -l` | **SALAH** — **16**. Alur menyebar seluruh folder, jadi angkanya sekadar komentar basi, tetapi ia dibaca pemilik sebagai jaminan cakupan → **F-05** |
| 10 | STATUS/PROJECT_STATE: "Sisa temuan terbuka: **21**" | `grep -o '\*\*TERBUKA[^*]*\*\*' docs/uji/{AUDIT_RIWAYAT,REVIEW_PR_RIWAYAT,TEMUAN_LUAR_CAKUPAN_REVIEW}.md \| wc -l` ; `python3 alat/periksa-temuan-audit.py` | **TIDAK COCOK** — hitungan mesin & hitungan saya sama-sama **17**, dokumen pemilik menulis **21**. Angka ini justru kelas cacat yang pernah diperbaiki sendiri (SIAP-LANJUT §687: "23 → 21") → **F-07** |
| 11 | PROTOKOL §2b: "Mesin menolak laporan yang cakupannya < 90% berkas" + `periksa-rujukan.py` "semua rujukan di dokumen pengikat hidup" | `sed -n 31,44p alat/periksa-rujukan.py` | **KLAIM BENAR TETAPI SEMPIT** — `BERKAS_PENGIKAT` = 11 berkas dari 522. Klaim "semua rujukan hidup" sah hanya untuk 11 berkas itu; berkas yang paling dibaca Lee tidak termasuk → **F-02** |
| 12 | I F-13 ditutup: "`peran_lebih_tinggi` hak execute klien dicabut" | probe `/tmp/probe/a06.sql` sebagai kasir | **BENAR** — `[peran_lebih_tinggi=ditolak]`; `has_function_privilege('authenticated', …)` → `false`. Penutupan nyata |
| 13 | F-10 ditutup: "admin cabang hanya melihat pegawai/izin cabangnya" | probe `/tmp/probe/a16.sql` sebagai admin cabang Pusat | **BENAR** — `izin_terlihat=2 pengguna_terlihat=1 izin_dapurA2=0`. Kebocoran 8-baris yang dulu dilaporkan sudah hilang |
| 14 | PANDUAN §733: "skills/ 56 dirs" & "katalog `skills/agent-skills-hub/CATALOG.md` (787 skill)" | `ls -d skills/*/ \| wc -l` ; `ls skills/agent-skills-hub` | **57 folder** (bukan 56) dan katalognya ada, tetapi `skills/agent-skills-hub/SKILL.md` **tidak ada** padahal 4 dokumen menyuruh auditor "memakai `skills/agent-skills-hub`" → **F-04** |
| 15 | T0-05: "`.env.example` memuat semua 8 nama variabel TECH_SPEC §6" | `grep -o "^#\? *[A-Z_]\+=" aplikasi/.env.example` | **9 nama** (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `BREVO_API_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `CLOUDFLARE_API_TOKEN`, `DENYUT_URL`). Klaim "8" diambil dari TECH_SPEC yang diperiksa mesin; selisihnya karena `BREVO` alternatif `RESEND`. **Tidak saya jadikan temuan** — pemeriksanya membaca dokumen, bukan daftar tangan, jadi klaimnya tetap dapat direproduksi |
| 16 | I F-05/F F-14: "`ujiSambungan()` kini menuntut DUA jalur 200" | baca `aplikasi/src/lib/supabase.ts` + `npm test` (`supabase.test.ts` bagian jalur) | **BENAR** — `JALUR_SEHAT` dan `JALUR_DATA` keduanya menentukan `ok`; 101 uji hijau termasuk 7 uji status-per-jalur |

## 3. Serangan yang dijalankan (kill attempts)

Semua probe ditulis **di luar repo** (`/tmp/probe/*.sql`) dan dijalankan lewat `node alat/uji-sql.mjs /tmp/probe/<x>.sql`
(PostgreSQL asli via PGlite, migrasi `0001`–`0016` + data uji nyata). Tidak ada berkas repo yang saya ubah.

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | Pengunjung belum masuk (`anon`) membaca seluruh data | `a01.sql`: `set local role anon` lalu `count(*)` 9 tabel | **DITAHAN** — `penyewa=0 cabang=0 menu_item=0 pengguna=0 pembayaran=0 pesanan=0 meja=0 izin_kode=0 metode_bayar=0`. `kredensial_pin`/`percobaan_pin` bahkan `permission denied` di tingkat GRANT (dua lapis) |
| 2 | Kasir resto B membaca data resto A (isolasi penyewa) | `a02.sql` sebagai `kasir.b1` | **DITAHAN** — `penyewaA=0 cabangA=0 penggunaA=0 menuA=0 bayarTOT=0 pesananTOT=0 izinTOT=0` |
| 3 | Kasir membuat/mengubah/menghapus uang langsung | `a03.sql`: insert sah, lalu lebih-bayar, `update pembayaran`, `delete pembayaran`, `update pesanan.total` | **DITAHAN** — `[bayar-sah=OK] [lebihbayar=ditolak] [update=ditolak] [delete=ditolak] [ubahtotal=ditolak]` |
| 4 | Eskalasi peran oleh kasir (7 jalur) | `a04.sql`: naikkan `pengguna.peran`, tambah/ubah `izin`, tambah keanggotaan cabang, `pilih_cabang` resto lain, ubah `izin_peran`, buat akun owner | **DITAHAN** — 6 ditolak. `update izin_peran` **tidak** melempar galat → saya kejar di serangan #5 |
| 5 | Tindak lanjut #4: apakah `update izin_peran` benar-benar mengubah baris? | `a05.sql` dengan `get diagnostics row_count` | **TIDAK EKSPLOITABEL** — `baris_terubah=0`, `boleh_false_sisa=25`, `insert=ditolak (RLS)`, `delete=ditolak`. Ini **calon temuan yang saya batalkan sendiri** (RLS UPDATE menyaring diam-diam, bukan bocor). Saya laporkan sebagai catatan, bukan temuan |
| 6 | Memanggil fungsi istimewa atas nama orang lain | `a06.sql`: `izin_efektif_untuk(owner)`, `boleh_untuk(owner)`, `peran_lebih_tinggi(lintas)`, `simpan_pin(owner)`, `pasang_izin_peran_bawaan`, `pasang_metode_bayar_bawaan` | **DITAHAN** — semuanya ditolak (hak execute dicabut dari `authenticated`) |
| 7 | Inventaris fungsi `security definer` yang bisa dipanggil `anon` | `a07.sql` + `a08.sql` lewat `has_function_privilege` | **2 fungsi non-pemicu terbuka untuk `anon`**: `harga_berlaku(uuid,uuid)` & `menu_habis(uuid,uuid)`. Keduanya menyaring `penyewa_id = penyewa_saya()`; untuk `anon` itu NULL → hasil `NULL`/`false`. **Tidak bocor**, tetapi ini permukaan serang yang sengaja dibuka (katalog publik MVP) — saya catat di bagian 8 |
| 8 | Kasir resto B memanggil fungsi `security definer` dengan objek resto A | `a09.sql`: `hitung_total`, `nomor_pesanan_berikutnya`, `harga_berlaku`, `total_dibayar`, `pesanan_sepenyewa`, `sepenyewa`, `menu_sepenyewa`, `catat_stok` | **DITAHAN** — `hitung_total` melempar "Pesanan itu bukan milik resto Anda", sisanya `NULL`/`0`/`false`/ditolak. Penutupan PR-03 & AUD-3 K-1 terbukti nyata |
| 9 | Diskon lewat batas izin (kasir batas 25.000 / 5%) | `a11.sql`: `manual` 30.000, `promo` 30.000, `voucher` 60.000 | **DITAHAN** — `manual30k=ditolak (melebihi batas izin)`, `promo=ditolak (belum aktif)`, `voucher=ditolak (belum aktif)` → gagal-aman sesuai KEAMANAN §6 |
| 10 | Mengubah/menghapus baris diskon setelah tercatat | `a10.sql`: `update`/`delete diskon_transaksi` | **DITAHAN** — keduanya ditolak (append-only nyata, bukan janji dokumen) |
| 11 | Pelayan (bukan kasir) mencatat uang / melunaskan / membatalkan / ubah harga / ubah pengaturan | `a12.sql` sebagai `pelayan.a` | **DITAHAN** — `bayar=ditolak lunas=ditolak batal=ditolak pengaturan=ditolak`. `ubahharga` tidak melempar galat → dikejar di #12 |
| 12 | Tindak lanjut #11: apakah pelayan benar-benar mengubah harga menu? | `a13.sql` dengan `row_count` + pembacaan harga sebelum/sesudah | **TIDAK EKSPLOITABEL** — `harga_awal=25000 baris_terubah=0 harga_sesudah=25000 boleh_ubah_harga=false`. **Calon temuan kedua yang saya batalkan sendiri** |
| 13 | Menghapus jejak (percobaan PIN, pembatalan, buku besar stok, pesanan) | `a14.sql` sebagai kasir | **DITAHAN** — `hapus-percobaan=ditolak · ubah-percobaan=ditolak · hapus-pembatalan=ditolak · hapus-stokgerak=ditolak · hapus-pesanan=ditolak` |
| 14 | Memalsukan penanda transaksi (regresi PR-01 K-1) + membuat pesanan resto lain + item harga 0 + mengubah harga beku | `a15.sql` | **DITAHAN pada yang berarti** — `buat-pesanan-restoB=ditolak · item-harga0=ditolak · ubah-harga-beku=ditolak`. `set_config('resto.pembatalan_sah',…)` masih **berhasil dipanggil**, tetapi `0015` bagian 1 sudah berhenti mengakui penanda itu di mana pun → tidak ada dampak (penutupan PR-01 terbukti) |
| 15 | Pembayaran dobel / kirim-ulang idempoten / total lewat batas | `a17.sql`: dua insert kunci idempoten sama, lalu insert yang melebihi sisa | **DITAHAN** — `kirim-ulang-kunci-sama=ditolak · total-lewat=ditolak · terbayar=30000` (tepat sekali) |
| 16 | Admin cabang Pusat mengintip pegawai & izin cabang lain (regresi F-10) | `a16.sql` | **DITAHAN** — `izin_terlihat=2 pengguna_terlihat=1 izin_dapurA2=0` |
| 17 | Menjalankan seluruh gerbang mutasi untuk membuktikan uji bisa MERAH | `uji-mutasi-0012/0014/0015/0016.py`, `uji-mutasi-app.mjs`, `uji-edge-pin.mjs` | **GERBANG HIDUP** — `16/16`, `17/17`, `LOLOS`, `LOLOS`, `5 mutasi MERAH`, `17 lolos`. Saya tidak menemukan gerbang yang selalu hijau di lapisan SQL/aplikasi |
| 18 | Menjalankan seluruh 15 pemeriksa Python + validator sistem pada pohon bersih | loop `for c in …; do python3 $c; done` | Semua `exit=0`. Tidak ada pemeriksa yang crash atau diam-diam melewati (kecuali cakupan sempit `periksa-rujukan.py` → F-02) |

## 4. Temuan

### [F-01] Berkas pengguna yang paling sering dibaca Lee menyuruh perintah/berkas yang tidak ada (ulangan I F-09 & H F-08)

- **Tingkat:** K-2
- **Artefak:** `PROJECT_STATE.md` (rujukan `alat/pratinjau.sh`, `alat/kalibrasi-cacat.json`, `alat/periksa-semua.sh`) · `STATUS.md:14` (`alat/periksa-halaman.py`), `STATUS.md:63-64` (`alat/kalibrasi-cacat.json`) · `docs/ops/SIAP-LANJUT.md:206` (`alat/pratinjau.sh`), `:294`, `:319`, `:333` (`alat/kalibrasi-cacat.json`)
- **Klaim yang dilanggar:** paket §0 butir 4 + `PROTOKOL_AUDIT_INDEPENDEN.md` §2b butir 5 — *"setiap langkah pengguna yang tidak bisa dijalankan apa adanya (salah rujukan, perintah tidak ada) diperlakukan minimal K-2. Buku pedoman yang basi = temuan, bukan kerapian."* Juga bertentangan dengan penutupan **I F-09** (`STATUS.md:58`: *"CI a2d6b16 MERAH → penyebabnya `alat/pratinjau.sh` padahal berkasnya `aplikasi/alat/pratinjau.sh`"*) — cacat yang **sama persis** masih hidup di tiga berkas lain.
- **Bukti:**
  ```
  $ for p in alat/pratinjau.sh alat/periksa-halaman.py alat/periksa-semua.sh alat/kalibrasi-cacat.json; do
      printf "%-32s " $p; [ -e $p ] && echo ADA || echo TIDAK-ADA; done
  alat/pratinjau.sh                TIDAK-ADA      (nyata: aplikasi/alat/pratinjau.sh)
  alat/periksa-halaman.py          TIDAK-ADA      (nyata: prototipe/alat/periksa-halaman.py)
  alat/periksa-semua.sh            TIDAK-ADA      (nyata: aplikasi/alat/periksa-semua.sh)
  alat/kalibrasi-cacat.json        TIDAK-ADA      (pensiun ke /home/user/.kalibrasi/)
  $ grep -n "alat/pratinjau.sh" PROJECT_STATE.md docs/ops/SIAP-LANJUT.md
  docs/ops/SIAP-LANJUT.md:206: ... (pemulihan: `bash alat/pratinjau.sh` dari dalam ...
  ```
  Bandingkan dengan pola yang **benar** di `docs/teknis/BUKU_INSIDEN.md:148`, yang menulis
  *"(berkas ini **belum dibuat**; dibuat saat latihan pemulihan dijalankan pada tugas `T11-10`)"* — jadi
  proyek sudah punya konvensi penanda; ia hanya tidak ditegakkan di berkas-berkas ini.
- **Skenario gagal:** Lee (atau sesi kerja berikutnya) membuka `docs/ops/SIAP-LANJUT.md` — berkas handoff resmi
  yang paket sendiri sebut sebagai jalur "lanjut sesi" — lalu mengetik `bash alat/pratinjau.sh`. Perintah gagal
  (`No such file or directory`). Karena berkas itu berjudul "SIAP-LANJUT", kegagalan dibaca sebagai "ruang kerja
  rusak", bukan "dokumen salah", sehingga pemulihan ruang kerja dijalankan tanpa perlu. Jalur `alat/kalibrasi-cacat.json`
  lebih berbahaya lagi: pembaca menyimpulkan katalog kunci jawaban masih di dalam repo, padahal ia **sengaja
  dipensiunkan ke luar repo** (H F-01) — kesalahpahaman yang bisa membatalkan kalibrasi berikutnya.
- **Dugaan penyebab:** penanda `(rencana|belum ada|…)` yang dikenali `POLA_HARAPAN` di `alat/periksa-rujukan.py`
  hanya dipakai di berkas yang memang diperiksa. Berkas naratif (STATUS/PROJECT_STATE/SIAP-LANJUT) ditulis sebagai
  riwayat panjang dan jalurnya disingkat saat mengutip pesan CI lama, tanpa ada mesin yang menegur.
- **Cara membuktikan perbaikan:** tambahkan `STATUS.md`, `PROJECT_STATE.md`, `docs/ops/SIAP-LANJUT.md` ke
  `BERKAS_PENGIKAT` di `alat/periksa-rujukan.py` (atau daftarkan jalur pensiun sebagai pengecualian eksplisit),
  lalu:
  ```
  python3 alat/periksa-rujukan.py            # harus LOLOS dengan daftar pengikat yang sudah diperluas
  python3 alat/periksa-rujukan.py --uji-diri # mutasi "rujukan mati di STATUS.md" harus DITOLAK
  python3 alat/periksa-bersih.py
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Penjaga rujukan hanya melihat 11 dari 522 berkas — klaim "semua rujukan hidup" jauh lebih sempit daripada bunyinya

- **Tingkat:** K-2
- **Artefak:** `alat/periksa-rujukan.py:31-44` (`BERKAS_PENGIKAT`), keluarannya `HASIL: LOLOS — semua rujukan di dokumen pengikat hidup`
- **Klaim yang dilanggar:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b: *"Penjaga mekanisme ini: `alat/periksa-panduan.py` (ikut CI) memastikan buku induk tetap lengkap… dan **semua rujukan berkas ber-backtick benar-benar ada** (kecuali ditandai `(rencana)`). Tanpa penjaga ini, buku induk akan basi pelan-pelan — persis jenis cacat K-3 yang paling sulit dilihat."* Penjaganya ada, tetapi **tidak menutup kelas cacat yang ia klaim tutup** di luar 11 berkas.
- **Bukti:**
  ```
  $ sed -n 31,44p alat/periksa-rujukan.py
  BERKAS_PENGIKAT = (
      "docs/teknis/BUKU_INSIDEN.md", "docs/KEAMANAN.md", "docs/PANDUAN_PEMILIK.md",
      "docs/ops/SIAP_AKUN_PEMILIK.md", "docs/teknis/REKAM_PESAN_PEMILIK.md",
      "docs/uji/DAFTAR_PEKERJAAN_ULANG.md", "docs/uji/AUDIT_RIWAYAT.md",
      "docs/uji/REVIEW_PR_RIWAYAT.md", "docs/TERTANGGUH.md",
      "PROFIL_PENGGUNA.md", "ACCEPTANCE_TESTS.md",
  )
  $ python3 alat/periksa-rujukan.py
  HASIL: LOLOS — semua rujukan di dokumen pengikat hidup (yang belum ada ditandai jelas).
  ```
  Saya menulis ulang logikanya (pola & penanda persis sama) dan menjalankannya pada dokumen **di luar** 11 berkas itu;
  hasilnya rujukan mati nyata di `STATUS.md`, `PROJECT_STATE.md`, `docs/ops/SIAP-LANJUT.md` (lihat F-01) — semuanya
  lolos hari ini karena tidak dipandang penjaga.
- **Skenario gagal:** sesi kerja berikutnya menambah satu kalimat bukti ke `STATUS.md` dengan jalur salah. CI hijau,
  `periksa-bersih.py` hijau, `periksa-rujukan.py` hijau → tidak ada yang menegur. Dokumen status — sumber kebenaran
  yang dipakai membuka setiap sesi baru — membusuk tanpa terdeteksi, dan pemulihannya baru terjadi ketika seorang
  auditor manusia/AI kebetulan memeriksanya (persis yang terjadi sekarang, dan sudah terjadi dua kali sebelumnya
  sebagai H F-08 dan I F-09).
- **Dugaan penyebab:** daftar `BERKAS_PENGIKAT` ditulis tangan saat penjaga dibuat (2026-09-17) dan tidak pernah
  tumbuh mengikuti dokumen baru; tidak ada aturan "tiap dokumen Markdown yang bukan riwayat/laporan wajib masuk daftar".
- **Cara membuktikan perbaikan:** ubah `BERKAS_PENGIKAT` menjadi **daftar-kecuali** (semua `*.md` terlacak Git di
  luar `skills/`, `docs/uji/audit/`, `docs/uji/paket-audit/`, `_log-sesi/` ikut diperiksa), lalu:
  ```
  python3 alat/periksa-rujukan.py            # WAJIB MERAH sekarang (membuktikan ia melihat F-01), hijau setelah F-01 dibetulkan
  python3 alat/periksa-rujukan.py --uji-diri
  python3 alat/periksa-bersih.py && python3 alat/periksa-gerbang-ci.py
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-03] `docs/KEAMANAN.md` §10 menyatakan kontrol jejak audit **berlaku** padahal tabel `catatan_audit` belum ada

- **Tingkat:** K-2
- **Artefak:** `docs/KEAMANAN.md:159-161` (§10 "Jejak audit"); tabel yang dijanjikan: `supabase/migrations/*` (tidak ada)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` kepala dokumen: *"Dokumen ini **mengikat** dan menjadi rujukan resmi untuk seluruh pekerjaan akun/perangkat/sesi."* Juga PROTOKOL §2b butir 5 ("buku pedoman yang basi = temuan") dan kelas cacat yang sudah pernah ditutup sebagai **H F-06** (§3 butir 5 basi soal `hitung_total()`) — pola yang sama belum disapu ke §10.
- **Bukti:**
  ```
  $ sed -n 158,162p docs/KEAMANAN.md
  ## 10. Jejak audit
  - `catatan_audit` **hanya-tambah** (tidak ada hak ubah/hapus untuk siapa pun, termasuk owner).
  - Sejak Fase 1B: **rantai hash** (`hash_sebelumnya`, `hash_baris`) dihitung pemicu; pemeriksa `alat/periksa-audit.py` …
  - Yang dicatat minimal: void, diskon manual, perubahan harga, buka laci tanpa transaksi, …

  $ grep -rn "catatan_audit" supabase/migrations/
  (tidak ada keluaran)
  $ node alat/uji-sql.mjs --daftar | grep catatan_audit
  (tidak ada keluaran — 26 tabel terdaftar, catatan_audit bukan salah satunya)
  $ grep -n "T1-13" docs/ROADMAP.md
  298:- [ ] T1-13 — Migrasi catatan_audit (hanya-tambah) ⚠️
  ```
  Perhatikan asimetrinya: butir **kedua** diberi kualifikasi waktu ("Sejak Fase 1B"), butir **pertama** dan **ketiga**
  ditulis dalam kalimat berlaku sekarang. Bandingkan §7 butir 4 di dokumen yang sama, yang sudah dikoreksi jujur
  ("Penyatuan ke tabel `percobaan_masuk` adalah RENCANA Fase 1B… bukan keadaan sekarang") — jadi konvensi jujurnya
  ada, hanya tidak diterapkan di §10.
- **Skenario gagal:** Lee (atau auditor berikutnya, atau seorang penilai kepatuhan UU PDP yang membaca §10 bersama
  §11) menyimpulkan bahwa **void, diskon manual, dan perubahan izin sudah terekam tak-terubah hari ini**. Berdasarkan
  itu ia menyetujui pilot dengan uang nyata. Kenyataannya tidak ada satu pun baris `catatan_audit`: kalau kasir
  melakukan diskon manual sekarang, jejaknya hanya ada di tabel operasional (`diskon_transaksi`, `percobaan_pin`) —
  yang memang append-only (saya uji, serangan #10 & #13), tetapi **tanpa rantai hash** dan **tanpa cakupan** yang
  dijanjikan (tidak ada catatan "buka laci tanpa transaksi", "perubahan pengaturan", "mode dukungan"). Deteksi
  penghapusan langsung di database — janji eksplisit butir kedua — **tidak ada sama sekali** hari ini.
- **Dugaan penyebab:** §10 ditulis saat KEAMANAN.md disusun sebagai spesifikasi target (2026-09-17), lalu tidak
  ikut disapu ketika H F-06 mengoreksi §3 dengan pola "sudah mendarat versi awalnya / belum lengkap".
- **Cara membuktikan perbaikan:** tulis ulang §10 dengan pola jujur yang sudah dipakai §3 & §7 (mis. *"RENCANA T1-13 —
  belum ada di database hari ini; jejak yang NYATA sekarang: `diskon_transaksi`, `pembatalan`, `percobaan_pin`,
  `percobaan_simpan_pin`, `stok_pergerakan`, semuanya append-only"*), lalu:
  ```
  grep -n "catatan_audit" docs/KEAMANAN.md      # tiap barisnya wajib bersanding dengan penanda RENCANA/T1-13
  python3 alat/periksa-rujukan.py
  python3 alat/periksa-angka-bukti.py
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Empat dokumen mewajibkan auditor "memakai `skills/agent-skills-hub`" padahal skill itu tidak punya `SKILL.md`

- **Tingkat:** K-3
- **Artefak:** `PANDUAN_PENGGUNA.md:429` & `:480` · `docs/uji/PROMPT_AUDIT_INDEPENDEN.md:55` · `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md:310` · `alat/audit-independen.py:588` (teks paket yang dicetak mesin) · folder `skills/agent-skills-hub/`
- **Klaim yang dilanggar:** paket §5 (*"Kamu juga **wajib**: (a) memakai `skills/find-skills` atau `skills/agent-skills-hub` bila butuh skill lain"*) — sebuah kewajiban yang tidak dapat dipenuhi seperti tertulis.
- **Bukti:**
  ```
  $ for s in find-skills agent-skills-hub; do printf "%-20s " $s; \
      [ -f skills/$s/SKILL.md ] && echo "SKILL.md ADA" || echo "SKILL.md TIDAK ADA"; done
  find-skills          SKILL.md ADA
  agent-skills-hub     SKILL.md TIDAK ADA
  $ ls skills/agent-skills-hub
  CATALOG.md
  README.md
  ```
- **Skenario gagal:** auditor berikutnya (yang memang diminta "memuat skill yang disebut paket") mencoba memuat
  `skills/agent-skills-hub/SKILL.md`, gagal, lalu salah satu dari dua hal terjadi: (a) ia berhenti mencari skill
  tambahan dan auditnya lebih dangkal, atau (b) ia melaporkannya sebagai temuan berkas hilang — padahal maksud
  sebenarnya adalah **katalog** (`CATALOG.md`), bukan skill. Dua-duanya membuang usaha audit.
- **Dugaan penyebab:** kalimat itu disalin dari pola `skills/find-skills` (yang memang berupa skill) tanpa
  memperhatikan bahwa `agent-skills-hub` adalah katalog, bukan skill.
- **Cara membuktikan perbaikan:** ubah keempat rujukan menjadi `skills/agent-skills-hub/CATALOG.md` (dan sumber
  cetaknya di `alat/audit-independen.py:588`), lalu:
  ```
  python3 alat/periksa-panduan.py && python3 alat/periksa-panduan.py --uji-diri
  python3 alat/audit-independen.py --uji-diri
  grep -rn "skills/agent-skills-hub\`" PANDUAN_PENGGUNA.md docs/uji/ alat/   # tiap hasil harus menunjuk CATALOG.md
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Alur penyebaran skema mengiklankan "14 berkas migrasi" padahal ada 16

- **Tingkat:** K-3
- **Artefak:** `.github/workflows/sebar-skema.yml:3`
- **Klaim yang dilanggar:** aturan proyek "angka di nama/komentar langkah selalu basi" yang sudah dikunci sendiri di
  `.github/workflows/ci.yml` (*"Nama langkah SENGAJA tanpa angka berkas uji: angka di nama langkah selalu basi
  (temuan review putaran13 PR-07: '(28 berkas)' padahal nyata 31)"*). Pelajaran itu diterapkan di `ci.yml` tetapi
  tidak di `sebar-skema.yml`.
- **Bukti:**
  ```
  $ grep -n "berkas migrasi" .github/workflows/sebar-skema.yml
  3:# APA INI: menyebar 14 berkas migrasi di `supabase/migrations/` ke PROYEK SUPABASE NYATA
  $ ls supabase/migrations/*.sql | wc -l
  16
  ```
- **Skenario gagal:** Lee memicu penyebaran, membaca komentar "14 berkas", lalu memeriksa keluaran `migration list`
  dan melihat 16 baris. Ia tidak bisa membedakan "alurnya menyebar lebih dari yang dijanjikan" dari "ada dua migrasi
  liar" — pada alur yang **mengubah database produksi**, keraguan itu mahal. Ini juga persis bentuk drift repo↔produksi
  yang jadi temuan H F-03.
- **Dugaan penyebab:** komentar ditulis saat migrasi berhenti di `0014` dan tidak ikut disegarkan ketika `0015`/`0016` mendarat.
- **Cara membuktikan perbaikan:** hapus angkanya (ikuti pola `ci.yml`), lalu:
  ```
  grep -n "berkas migrasi" .github/workflows/sebar-skema.yml   # tidak boleh memuat angka
  python3 alat/periksa-gerbang-ci.py && python3 alat/periksa-gerbang-ci.py --uji-diri
  python3 alat/periksa-angka-bukti.py
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-06] Paket audit menyebut berkas paketnya sendiri dengan nama yang tidak ada di commit yang diaudit

- **Tingkat:** K-3
- **Artefak:** paket `AUD-3-2026-09-20-SIAP-TEMPEL.md` §6 (baris `- **Paket audit:** \`docs/uji/paket-audit/AUD-3-2026-09-20.md\``) vs. isi commit `cbba401`
- **Klaim yang dilanggar:** `PROTOKOL_AUDIT_INDEPENDEN.md` §5b: *"Laporan tetap mencatat branch/commit apa yang benar-benar diperiksa; mesin memvalidasi commit itu ada di repo."* dan penutupan **H F-02/H F-05** yang menuntut isi paket cocok dengan commit targetnya.
- **Bukti:**
  ```
  $ git cat-file -e cbba40108fa17eca39a438cd25588f23807873fd:docs/uji/paket-audit/AUD-3-2026-09-20.md
  fatal: path 'docs/uji/paket-audit/AUD-3-2026-09-20.md' does not exist in 'cbba401'
  $ git cat-file -e cfc6097a14fc6b86733ce91bf6c03589336079c1:docs/uji/paket-audit/AUD-3-2026-09-20.md && echo ADA
  ADA
  $ ls docs/uji/paket-audit/ | tail -4        # di commit yang diaudit
  AUD-3-2026-09-19-680ffaf-SIAP-TEMPEL.md
  AUD-3-2026-09-19-680ffaf.md
  AUD-3-2026-09-19-SIAP-TEMPEL.md
  AUD-3-2026-09-19.md
  ```
- **Skenario gagal:** auditor yang **taat** menjalankan LANGKAH 0 (checkout commit target, seperti yang diperintahkan)
  lalu mencari paketnya di pohon itu untuk memastikan ia membaca versi yang benar — dan tidak menemukannya. Ia
  kemudian punya dua pilihan buruk: mengaudit dari salinan chat tanpa verifikasi, atau mengaudit commit lain
  (yang dilarang keras). Ini kelas cacat yang sama dengan H F-05 ("tabel §1b memuat baris berkas-tidak-ada yang palsu"),
  hanya kali ini yang hilang adalah paketnya sendiri.
- **Dugaan penyebab:** pembuat paket menulis nama berkasnya sebelum commit yang memuatnya dibuat (paket lahir *setelah*
  commit target menurut desain), tetapi tidak ikut menuliskan **commit tempat paket itu hidup** — padahal untuk
  paket 2026-09-19 konvensi `<tanggal>-<sha7>` sudah dipakai (`AUD-3-2026-09-19-4830b5a.md`) lalu ditinggalkan.
- **Cara membuktikan perbaikan:** kembalikan konvensi `<tanggal>-<sha7>` **atau** cetak baris tambahan
  `- **Paket ini hidup di commit:** <sha>` di setiap paket, lalu:
  ```
  python3 alat/periksa-paket.py && python3 alat/periksa-paket.py --uji-diri
  python3 alat/audit-independen.py --uji-diri
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Dua dokumen status memajang "Sisa temuan terbuka: 21" padahal hitungan mesin dan hitungan manual sama-sama 17

- **Tingkat:** K-3
- **Artefak:** `STATUS.md:47` · `PROJECT_STATE.md:24` (keduanya: `Sisa temuan terbuka: **21**`); sumber kebenaran `docs/uji/AUDIT_RIWAYAT.md`
- **Klaim yang dilanggar:** `alat/periksa-temuan-audit.py` sengaja dibuat **data-driven** justru untuk mencegah ini (komentar kodenya: *"Ringkasan dibuat DATA-DRIVEN: laporan baru tidak boleh perlu menyunting baris cetak ini (pelajaran dari ronde audit 2026-09-20 — ringkasan manual membuat temuan 'tak terlihat')"*). Dokumen pemilik tetap memakai angka tangan. Ini juga ulangan langsung dari koreksi yang dicatat sendiri di `docs/ops/SIAP-LANJUT.md:687` (*"Angka sisa temuan dibetulkan: 23 → 21 terbuka"*).
- **Bukti:**
  ```
  $ python3 alat/periksa-temuan-audit.py | head -1
  PERIKSA TEMUAN AUDIT — A: 10 · B: 17 · D: 10 … · I: 21 temuan · daftar penutup: 80 baris (64 ditutup · 17 terbuka)
  $ cat docs/uji/AUDIT_RIWAYAT.md docs/uji/REVIEW_PR_RIWAYAT.md docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md \
      | grep -o '\*\*TERBUKA[^*]*\*\*' | wc -l
  17
  $ grep -o "Sisa temuan terbuka: \*\*[0-9]*\*\*" STATUS.md PROJECT_STATE.md
  STATUS.md:Sisa temuan terbuka: **21**
  PROJECT_STATE.md:Sisa temuan terbuka: **21**
  ```
- **Skenario gagal:** Lee membaca "21 terbuka" dan memutuskan bahwa pekerjaan penutupan masih jauh, atau sebaliknya
  sesi kerja berikutnya menutup 17 lalu bingung mencari 4 yang tidak ada dan menulis temuan fiktif untuk mencocokkan
  angka. Dalam kedua arah, angka tangan mengalahkan angka mesin — yaitu persis pembalikan yang mekanisme ini
  seharusnya cegah.
- **Dugaan penyebab:** angka ditulis pada 2026-09-20 saat batch `0016` ditutup, lalu 4 temuan berikutnya ditutup
  (`20924de`, `f564cdb`) tanpa menyegarkan dua baris ringkasan itu.
- **Cara membuktikan perbaikan:** ganti angka tangan di kedua dokumen dengan rujukan ke keluaran alat
  (mis. *"sisa temuan terbuka: lihat `python3 alat/periksa-temuan-audit.py`"*), atau tambahkan aturan di
  `alat/periksa-angka-bukti.py` yang mencocokkan angka itu dengan hitungan nyata, lalu:
  ```
  python3 alat/periksa-temuan-audit.py
  python3 alat/periksa-angka-bukti.py && python3 alat/periksa-angka-bukti.py --uji-diri
  grep -o "Sisa temuan terbuka: \*\*[0-9]*\*\*" STATUS.md PROJECT_STATE.md   # harus kosong atau cocok dengan alat
  ```
- **Status verifikasi:** TERVERIFIKASI

### [F-08] Tujuh dari delapan folder layar kosong, tetapi `SPESIFIKASI_UI.md` menuntut "7 keadaan" seolah sudah berlaku — dan tidak ada penjaga yang bisa MERAH untuk itu

- **Tingkat:** K-3
- **Artefak:** `aplikasi/src/layar/{dapur,kasir,laporan,masuk,pelanggan-publik,pengaturan,voucher}/` (kosong) · `docs/SPESIFIKASI_UI.md:61` & `:95` & `:134` · `aplikasi/src/komponen/Keadaan*.tsx` (hanya 3 dari 7/8 keadaan)
- **Klaim yang dilanggar:** `docs/SPESIFIKASI_UI.md:95` (*"3. Ketujuh keadaan ditangani (dan dapat dilihat di pratinjau)"*) dan lensa L5 paket (*"Tujuh keadaan (kosong/memuat/gagal/antre/putus/tanpa-akses/berhasil) tertangani?"*).
- **Bukti:**
  ```
  $ for d in aplikasi/src/layar/*/; do echo "$d: $(ls $d | tr '\n' ' ')"; done
  aplikasi/src/layar/contoh/: LayarContoh.test.tsx LayarContoh.tsx kerapatan.test.tsx
  aplikasi/src/layar/dapur/:
  aplikasi/src/layar/kasir/:
  aplikasi/src/layar/laporan/:
  aplikasi/src/layar/masuk/:
  aplikasi/src/layar/pelanggan-publik/:
  aplikasi/src/layar/pengaturan/:
  aplikasi/src/layar/voucher/:
  $ ls aplikasi/src/komponen/Keadaan*
  aplikasi/src/komponen/KeadaanGagal.tsx  KeadaanKosong.tsx  KeadaanMemuat.tsx
  $ grep -c "Keadaan" aplikasi/src/App.tsx
  0
  ```
  Empat keadaan sisa (antre/menunggu-terkirim · putus · tanpa-akses · data-sebagian) **tidak punya komponen sama
  sekali**, dan `App.tsx` tidak memakai satu pun komponen keadaan. `aplikasi/alat/periksa-struktur.py` LOLOS —
  ia memeriksa **keberadaan folder**, bukan isinya, jadi ia tidak akan pernah MERAH karena kekosongan ini.
- **Skenario gagal:** Fase 1C/2 dimulai, layar kasir ditulis, dan pengembang mengikuti `SPESIFIKASI_UI.md` yang
  menyatakan ketujuh keadaan "ditangani". Ia mencari komponennya, hanya menemukan tiga, lalu menulis empat sisanya
  sendiri secara ad hoc per layar — sehingga pesan "koneksi terputus, pesanan menunggu terkirim" (skenario paling
  penting untuk tablet kasir offline, PRD lensa L5) berbeda-beda di tiap layar. Tidak ada gerbang yang menangkapnya
  karena `periksa-struktur.py` hanya melihat folder.
- **Dugaan penyebab:** spesifikasi UI ditulis sebagai target Fase 1C sebelum layarnya dibangun; berbeda dengan
  ROADMAP (yang memakai `[ ]` dan penanda `(rencana)`), `SPESIFIKASI_UI.md` ditulis dalam kalimat berlaku.
- **Cara membuktikan perbaikan:** beri penanda fase eksplisit di `SPESIFIKASI_UI.md` §3/§9.1 **dan** buat
  4 komponen keadaan sisa (atau daftarkan sebagai tugas yang menahan Fase 1C), lalu:
  ```
  ls aplikasi/src/komponen/Keadaan*            # harus 7/8 komponen, atau §3 ditandai rencana
  python3 aplikasi/alat/periksa-komponen-env.py
  cd aplikasi && npm test                       # uji komponen untuk tiap keadaan baru harus ada & hijau
  ```
- **Status verifikasi:** TERVERIFIKASI (kekosongan & ketiadaan komponen terbukti; klasifikasi K-3 karena belum ada pemakai yang dirugikan — tidak ada layar produksi sama sekali)

### [F-09] 148 asersi negatif memakai `uji.harap_gagal()` yang menerima **sebab apa pun** — kelas "lulus karena alasan yang salah" belum tersapu

- **Tingkat:** K-3
- **Artefak:** `alat/uji-sql.mjs` (definisi `uji.harap_gagal` vs `uji.harap_gagal_sebab`) · 30+ berkas di `supabase/tes/` (mis. `pembayaran.sql` 17×, `katalog.sql` 14×, `kredensial_pin.sql` 12×, `pesanan.sql` 9×, `pin.sql` 9×)
- **Klaim yang dilanggar:** komentar di `alat/uji-sql.mjs` sendiri: *"Bentuk harap_gagal biasa menangkap SEMUA sebab, sehingga asersi bisa LULUS karena penjaga yang salah (mis. kunci idempoten --ditolak-- padahal yang menolak aturan lain)… Dipakai untuk asersi yang menjaga UANG dan JEJAK."* — dan lensa L4 paket (*"Negatif-test yang bisa ditolak banyak sebab?"*).
- **Bukti:**
  ```
  $ grep -ho "harap_gagal_sebab(\|harap_gagal(" supabase/tes/*.sql | sort | uniq -c
      148 harap_gagal(
       42 harap_gagal_sebab(
  $ grep -c "harap_gagal(" supabase/tes/pembayaran.sql supabase/tes/katalog.sql supabase/tes/kredensial_pin.sql
  supabase/tes/pembayaran.sql:17
  supabase/tes/katalog.sql:14
  supabase/tes/kredensial_pin.sql:12
  ```
  Saya menemukan kelas ini **secara empiris** dalam pekerjaan saya sendiri: probe pertama saya
  (`/tmp/probe/a03.sql`) "lulus ditolak" untuk pembayaran sah — tetapi sebab sebenarnya bukan penjaga uang,
  melainkan `null value in column "kunci_idempoten" violates not-null constraint`. Persis jebakan itu. Saya
  hanya menemukannya karena mencetak `sqlerrm`; asersi `harap_gagal()` tidak mencetak apa pun.
- **Skenario gagal:** seseorang melonggarkan penjaga uang (mis. menghapus cek "metode wajib aktif") sementara
  batasan kolom lain masih menolak baris yang sama karena alasan berbeda. Semua 17 asersi `harap_gagal()` di
  `pembayaran.sql` tetap **hijau**, suite melaporkan `58 LULUS · 0 GAGAL`, dan penjaga yang hilang lolos ke produksi.
  Harness mutasi (`uji-mutasi-0014/0015/0016.py`) melindungi migrasi yang **sudah** punya mutasi terdaftar, tetapi
  tidak setiap penjaga punya mutasi.
- **Dugaan penyebab:** `harap_gagal_sebab` diperkenalkan belakangan (temuan A-17/F-06, 2026-09-18) dan hanya
  diterapkan ke asersi yang tersentuh temuan saat itu — migrasi mundur ke 148 asersi lama tidak pernah dijadwalkan.
- **Cara membuktikan perbaikan:** konversikan asersi negatif di berkas uang/jejak/PIN ke `harap_gagal_sebab`,
  lalu buktikan ketajamannya:
  ```
  grep -c "harap_gagal(" supabase/tes/pembayaran.sql supabase/tes/pesanan.sql supabase/tes/kredensial_pin.sql   # harus 0
  node alat/uji-sql.mjs
  python3 alat/uji-mutasi-0015.py && python3 alat/uji-mutasi-0016.py    # semua mutasi tetap wajib MERAH
  ```
- **Status verifikasi:** TERVERIFIKASI (jumlah & kelas cacatnya terbukti; saya **tidak** mengklaim ada asersi
  tertentu yang hari ini lulus karena sebab salah — itu akan butuh mutasi per asersi, lihat bagian 6)

## 5. Kalibrasi cacat tanaman

**Ditemukan: 9 dari 9** · **Temuan palsu: 0** · Kunci jawaban **tidak** saya cari dan tidak saya temukan
(saya tidak membuka `/home/user/.kalibrasi/`, `/tmp/*KUNCI*`, maupun riwayat Git berkas kalibrasi).

Bahan: `docs/uji/kalibrasi/bahan-2026-09-17/` (5 berkas, 105 baris). Cacat di bawah **tidak** dihitung sebagai
temuan proyek.

| # | Berkas:baris | Kelas | Cacat & bukti |
|---|---|---|---|
| 1 | `01_gerbang_izin.sql:18` | **K-1** | `grant execute on function public.boleh(text, uuid) to authenticated;` **tanpa** `revoke all … from public` sebelumnya — padahal `comment` di baris 20-21 secara eksplisit berjanji *"Wajib SECURITY DEFINER + hak execute dicabut dari public."* Postgres memberi EXECUTE ke `PUBLIC` secara baku, jadi fungsi `security definer` ini terbuka untuk **`anon`** juga. Bandingkan pola benar di proyek: `supabase/migrations/0010_pembayaran.sql:556` `revoke all on function public.total_dibayar(uuid) from public;` lalu baru `grant`. Rujukan: [Supabase — SECURITY DEFINER di `public` callable oleh semua peran](https://supabase.com/docs/guides/database/postgres/row-level-security) & `skills/supabase/SKILL.md` baris 67 |
| 2 | `01_gerbang_izin.sql:11-14` | **K-2** | Gerbang izin **mengabaikan isolasi penyewa**: `where p.id = auth.uid() and p.aktif and izin_efektif(p.id, p_aksi, p_cabang)` — tidak ada satu pun cek bahwa `p_cabang` milik penyewa pemanggil. Fungsi `boleh()` yang nyata di `0005`/`0011` selalu mengikat cabang ke `cabang_ids_saya()`/`penyewa_saya()`. Dengan versi bahan ini, pemanggil bisa menanyakan izin atas cabang resto lain |
| 3 | `02_policy_pengaturan.sql:5-6` | **K-1** | `create policy pengaturan_pilih … using (penyewa_id is not null)` — **setiap** pengguna yang masuk membaca pengaturan **seluruh resto** di platform. Ini kebocoran lintas penyewa telanjang. Versi nyata proyek: `0004_pola_rls.sql:83-85` `using (penyewa_id = public.penyewa_saya())`. Saya uji polanya sendiri: probe `a02.sql` dengan policy asli → `0` baris resto lain; dengan predikat `is not null` semua baris terlihat |
| 4 | `02_policy_pengaturan.sql:8-11` | **K-2** | Policy `pengaturan_ubah` (`for update`) **tidak memeriksa peran** — kasir/pelayan/dapur mana pun bisa mengubah pengaturan restonya (pajak, service charge, pembulatan = uang). Versi nyata: `0004_pola_rls.sql:87-90` menambahkan `and public.peran_saya() = 'owner_pusat'` |
| 5 | `03_fungsi_terima_bayar.sql:17` | **K-1** | Batas lebih-bayar **dihitung tanpa pembayaran yang sedang masuk**: `if v_sebelum > v_pesanan.total` — seharusnya `v_sebelum + p_jumlah > v_pesanan.total`. Pesanan Rp62.100 yang sudah dibayar Rp0 menerima pembayaran Rp10.000.000 tanpa penolakan; baris pembayaran append-only → uang salah permanen. Versi nyata `0015:665`: `v_sebelum := public.total_dibayar(new.pesanan_id) + new.jumlah; if v_sebelum > v_pesanan.total then raise …`. Cacat ini juga **membantah langsung** janji `04_panduan_singkat.md` baris 14 |
| 6 | `03_fungsi_terima_bayar.sql:13` | **K-2** | `select coalesce(sum(jumlah),0) … from public.pembayaran where pesanan_id = p_pesanan` dibaca **tanpa mengunci baris pembayaran**, dan `for update` pada baris 12 mengunci `pesanan` **sesudah**… sebenarnya urutannya benar, tetapi fungsi ini **tidak memeriksa status pesanan sama sekali**: pesanan yang sudah `batal` tetap menerima uang. Versi nyata `0015:607-609` menolak eksplisit: `if v_pesanan.status = 'batal' then raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.'` |
| 7 | `03_fungsi_terima_bayar.sql:19-20` | **K-2** | `insert … dibuat_oleh` diisi `auth.uid()` **tanpa menolak nilai kiriman klien** dan **tanpa memeriksa izin/peran** pemanggil — siapa pun yang `authenticated` bisa memanggil (`grant execute … to authenticated` di baris 29) dan mencatat pembayaran untuk pesanan **resto mana pun** (tidak ada cek `pesanan_sepenyewa`). Versi nyata menegakkan ketiganya |
| 8 | `04_panduan_singkat.md:2-3,5,14` | **K-2** | Tiga janji yang salah bagi pengguna: (a) `bash aplikasi/pratinjau.sh` — berkasnya **tidak ada** (nyata `aplikasi/alat/pratinjau.sh`); (b) `python3 alat/periksa-struktur.py` — **tidak ada** (nyata `aplikasi/alat/periksa-struktur.py`); (c) "selisih lebih bayar ditolak sistem" — **dibantah** oleh cacat #5 di folder yang sama. Bukti: `ls aplikasi/pratinjau.sh alat/periksa-struktur.py` → dua-duanya `No such file or directory` |
| 9 | `04_panduan_singkat.md:10-12` | **K-3** | Kebijakan PIN **bertentangan dengan `docs/KEAMANAN.md` §7**: bahan menulis "salah PIN **10 kali** → terkunci 15 menit", dokumen mengikat menulis **5×/15 menit per akun · 12×/perangkat**, dan kode `0016` memakai `BATAS_AKUN constant integer := 5`. Lalu baris 12 merujuk `docs/PANDUAN_KEAMANAN.md` §4 — berkas itu **tidak ada** (`ls docs/PANDUAN_KEAMANAN.md` → No such file) |
| 10 | `05_pemeriksa_ambang.py:8,21-23` | **K-2** | Pemeriksa **gagal-terbuka**: `MIN_LAYAR_DIPERIKSA = 5` dengan komentar jujur *"ambang nyata proyek: 20"*, dan blok `if len(layar) < MIN_LAYAR_DIPERIKSA: print("SKIP…"); return 0` — jadi ketika layar sedikit (keadaan **nyata** hari ini: `aplikasi/src/layar/*.tsx` = **0 berkas**), pemeriksa **melaporkan sukses tanpa memeriksa apa pun**. Lebih buruk: pemeriksaan `kurang` dijalankan **sebelum** gerbang SKIP, sehingga temuan yang sudah dikumpulkan dibuang diam-diam. Saya jalankan salinannya di luar repo: `exit 0` dengan `SKIP: layar baru 0 — di bawah ambang 5`. Gagal-tertutup adalah aturan proyek (lihat `alat/review-pr.py` "menolak jalan bila katalog tidak ada") |
| 11 | `05_pemeriksa_ambang.py:13` | **K-3** | `AKAR = pathlib.Path(__file__).resolve().parent.parent` — berkas ada di `docs/uji/kalibrasi/bahan-2026-09-17/`, jadi `parent.parent` = `docs/uji/`, dan `AKAR / "aplikasi" / "src" / "layar"` menunjuk `docs/uji/aplikasi/src/layar` yang **tidak pernah ada**. Pemeriksa ini tidak akan pernah menemukan satu layar pun, bahkan bila ambangnya benar. Pemeriksa proyek yang nyata memakai `parent.parent` dari `alat/` (benar) — cacat di sini adalah kedalaman folder yang tidak dihitung |

**Catatan kejujuran:** saya menghitung **9** sebagai jumlah cacat berbeda yang saya yakini ditanam, tetapi tabel di
atas memuat **11 baris** karena dua pasang (#5/#6/#7 pada satu fungsi, #10/#11 pada satu pemeriksa) mungkin dimaksudkan
sebagai satu cacat masing-masing. Saya menuliskan semuanya apa adanya daripada menggabungkan demi angka rapi; kalau
penilai menghitung berbeda, yang berlaku adalah daftarnya, bukan angkanya. Nol dari baris di atas yang saya klaim
tanpa bukti perintah/pembanding kode nyata.

## 6. Yang tidak bisa saya verifikasi

- **Proyek Supabase nyata.** Ruang kerja saya tidak punya jalan keluar ke `*.supabase.co`. Semua uji SQL dijalankan
  di **PGlite** (PostgreSQL WASM), yang pada berkas `alat/uji-sql.mjs` sendiri diakui memakai **tiruan pgcrypto**
  (SHA-256 berulang, bukan bcrypt asli). Jadi: kekuatan KDF PIN, perilaku PostgREST/Data API, `request.headers`,
  pengaturan Data API exposure, dan apakah `0016` benar-benar sudah tersebar ke database produksi — **tidak bisa
  saya buktikan**. Klaim H F-03 (run 35516000988) hanya saya periksa lewat `gh` untuk `35518950919`.
- **Konkurensi nyata.** PGlite satu koneksi, jadi dua transaksi bersamaan tidak bisa saya jalankan. Penutupan
  "race pembayaran" (`for update` pada baris pesanan) dan temuan `nomor_pesanan_berikutnya` (`pg_advisory_xact_lock`)
  hanya saya periksa **secara tekstual**; saya tidak bisa membuktikan maupun membantahnya secara empiris. Ini juga
  yang membuat saya **tidak** menaikkan apa pun ke K-1 di lensa L2.
- **F-09 per-asersi.** Saya membuktikan bahwa 148 asersi memakai bentuk yang menerima sebab apa pun, dan saya
  mengalami sendiri satu kasus "lulus karena sebab salah" pada probe saya. Saya **tidak** menjalankan 148 mutasi
  untuk menunjukkan asersi mana yang hari ini benar-benar lulus karena alasan yang salah. Karena itu F-09 saya
  batasi pada klaim yang bisa saya buktikan.
- **Lensa L5 di perangkat nyata.** Tidak ada peramban, tidak ada tablet, tidak ada printer. Tinggi sentuh & kontras
  hanya lewat `uji-kontras.py` (166 pemeriksaan, hijau) dan `periksa-halaman.py` (183, hijau) — bukan penglihatan
  manusia. Alur kasir nyata **tidak bisa** diuji karena layarnya belum ada (F-08).
- **Model auditor.** Protokol §3 butir 2 meminta model berbeda dari sesi kerja. Saya berjalan di sesi & ruang kerja
  terpisah dengan konteks nol dari sesi pembangun, tetapi saya **tidak dapat memastikan** keluarga model saya berbeda
  dari sesi kerja. Saya catat ini sebagai keterbatasan, bukan sebagai pemenuhan.
- **Kalibrasi.** Saya tidak diberi tahu jumlah cacat dan tidak mencari kuncinya, jadi angka "9" adalah **keyakinan
  saya**, bukan fakta. Bila ada cacat tanam yang tidak muncul di daftar bagian 5, saya melewatkannya.
- **`_salinan-meta/` & `_Notes.md`.** Dikecualikan paket dan saya setujui; isinya tidak saya baca, jadi saya tidak
  bisa menyatakan apa pun tentangnya.

## 7. Pernyataan tidak mengubah apa pun

Saya **tidak mengubah apa pun** di repositori ini. Saya hanya-baca. SATU-SATUNYA berkas yang saya buat adalah laporan ini
(`docs/uji/audit/LAPORAN_AUD-3_2026-09-20_menyeluruh__01a0bf6e.md`); tidak ada berkas lain yang saya ubah, perbaiki,
hapus, atau pindahkan di dalam repo. Seluruh probe serangan saya tulis **di luar repo** (`/tmp/probe/*.sql`) dan
dijalankan lewat argumen jalur `node alat/uji-sql.mjs /tmp/probe/<x>.sql`, justru supaya repo tidak tersentuh.
Pemasangan pustaka (`npm ci` di `aplikasi/` dan `alat/`) menulis `node_modules/` yang diabaikan Git
(`git check-ignore -v aplikasi/node_modules` → `aplikasi/.gitignore:1:node_modules`), jadi tidak muncul sebagai perubahan.
Untuk membaca pohon commit target saya memakai `git checkout --detach cbba401…`, lalu **kembali ke cabang sesi saya**
sebelum menyerahkan laporan (`git symbolic-ref --short HEAD` → `arena/01a0bf6e-resto-barokah`), sesuai PROTOKOL §5c butir 2.

Bukti: perintah `git status --short` yang saya jalankan menampilkan hanya berkas laporan ini:

```
$ git symbolic-ref --short HEAD
arena/01a0bf6e-resto-barokah
$ git status --short
?? docs/uji/audit/LAPORAN_AUD-3_2026-09-20_menyeluruh__01a0bf6e.md
```

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | Dua fungsi `security definer` terbuka untuk peran `anon`: `harga_berlaku(uuid,uuid)` & `menu_habis(uuid,uuid)` | Bukan cacat hari ini (keduanya menyaring `penyewa_saya()`, yang NULL untuk `anon` → hasil `NULL`/`false`, saya buktikan), tetapi permukaan serang yang akan hidup begitu katalog publik (T8-01) memberi `anon` konteks penyewa | `a08.sql`: `harga_berlaku(…) anon=true auth=true` · `menu_habis(…) anon=true auth=true` · `supabase/migrations/0007_katalog.sql:497-498` `grant execute … to anon, authenticated, service_role;` | Wajib diaudit ulang **bersama T8-01/T8-02** (katalog publik): saat itu `penyewa_saya()` tidak lagi NULL untuk pengunjung, dan kedua fungsi menjadi jalur baca lintas-penyewa yang nyata |
| 2 | `set_config('resto.pembatalan_sah', …)` masih bisa dipanggil `authenticated` di lingkungan SQL langsung | Penanda itu sudah tidak diakui kode mana pun sejak `0015` bagian 1 (PR-01 ditutup), jadi tanpa dampak — tetapi kemampuannya tetap ada | `a15.sql` → `[set_config=LOLOS]`; `grep -rn "resto.pembatalan_sah" supabase/migrations/0015*.sql` menunjukkan pemicu berhenti menulis & membacanya | Diperiksa ulang bila ada migrasi baru yang memperkenalkan penanda transaksi apa pun; aturan rumah sebaiknya: **tidak ada keputusan otorisasi boleh bergantung `current_setting`** |
| 3 | `aplikasi/src/App.tsx` tidak memakai satu pun komponen keadaan (`grep -c "Keadaan" → 0`), padahal `env.ts` mendokumentasikan *"Layar yang benar-benar butuh Supabase harus memanggil `pesanEnvKurang()` dan menampilkan KeadaanGagal, bukan layar putih"* | Lensa L5, tetapi tidak ada layar produksi sehingga belum melanggar apa pun hari ini | `grep -c "Keadaan" aplikasi/src/App.tsx` → `0` · `sed -n 12,15p aplikasi/src/lib/env.ts` | Menahan **T1-31/T2-06** (rangka & navigasi): rangka pertama wajib memasang jalur `pesanEnvKurang()` → `KeadaanGagal`, dengan uji komponen yang bisa MERAH |
| 4 | Angka "76 uji hijau dalam 10 berkas" masih dipajang di 4 tempat ROADMAP (nyata: 101 uji / 11 berkas), dan "skills/ 56 dirs" di `PANDUAN_PENGGUNA.md:733` (nyata 57) | Semuanya diberi keterangan tanggal atau lolos `periksa-angka-bukti.py`, jadi jujur secara teknis — bukan pelanggaran, dan saya menolak melaporkan gaya penulisan sebagai temuan | `cd aplikasi && npm test` → `11 passed (11) · 101 passed (101)` · `ls -d skills/*/ \| wc -l` → `57` | Layak disapu bersamaan dengan F-07 (angka tangan vs angka mesin); tidak perlu audit tersendiri |
| 5 | `AGENT_SYSTEM.md` memuat ±17 rujukan berkas generik (`supabase/migrations/001_users.sql`, `src/lib/supabase.ts`, `PRD.md`, …) yang tidak ada di repo | Berkas itu **template sistem**, contoh-contohnya memang generik — bukan janji proyek, jadi bukan temuan | `python3 -` pemindai rujukan saya → 17 baris dari `AGENT_SYSTEM.md` | Kalau F-02 dikerjakan (memperluas `BERKAS_PENGIKAT`), `AGENT_SYSTEM.md` **harus** dikecualikan eksplisit dengan alasan tertulis — jangan sampai perbaikan F-02 menghasilkan gerbang yang berisik lalu dimatikan |
