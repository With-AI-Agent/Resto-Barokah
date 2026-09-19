# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-19

- **Auditor:** Arena.ai Agent Mode — sesi auditor `arena/01a0bbcb-resto-barokah` (hanya-baca; model tidak diungkap sesuai kebijakan platform)
- **Tanggal:** 2026-09-19
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `4830b5a4f876744ecb37e2f4495c6df234376752` (HEAD detached; seluruh perintah bukti di laporan ini dijalankan pada pohon kerja commit itu. Paket audit ditempel pemilik di chat; berkasnya tersimpan di FETCH_HEAD `fd0b330` dan **belum ter-commit** pada commit auditan — lihat bagian 6)
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md`
- **Mode cakupan:** menyeluruh
- **Verdict:** TIDAK-BERSIH

## 1. Cakupan

Cakupan menyeluruh: 480 dari 480 berkas

Kejujuran tentang kedalaman: **semua** berkas dalam lingkup saya buka dan periksa, tetapi kedalamannya berbeda — sebagian besar dibaca penuh (migrasi SQL, uji SQL, fungsi, workflow, dokumen pengikat, pemeriksa), sebagian dibaca kepala/fragmen dengan verifikasi silang lewat pemeriksa yang saya jalankan sendiri (laporan/paket mesin, berkas sesi, konfigurasi), aset biner (19 huruf `.woff2`, gambar) diverifikasi lewat keberadaan-jumlah-integritas rujukan (`find`, `cmp`, `uji-kontras.py`, `periksa-struktur.py`), dan gambar tidak dapat saya lihat secara visual sesi ini (lihat bagian 6). Pengecualian yang saya setujui sesuai paket: `skills/` (pihak ketiga, 9 SKILL.md tetap saya muat sesuai §5 paket), `_salinan-meta/`, `_Notes.md` — alasan pengecualian masuk akal dan saya terima.

| # | Grup | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|
| 1 | aplikasi/src (73) | 73 | Dibaca: `App.tsx`, `main.tsx`, `lib/env.ts`, `lib/supabase.ts`, `lib/tema.ts`, `lib/format.ts`, `hook/useTema.ts`, `hook/useJam.ts`, `layar/contoh/LayarContoh.tsx`, 12 komponen, 4 css, 11 berkas uji (kepala+greps). Bukti alat: `python3 aplikasi/alat/uji-kontras.py` → 166 lolos·0 gagal; `cmp aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` → identik; `ls aplikasi/src/gaya/aset/font/*.woff2 \| wc -l` → 19; `python3 aplikasi/alat/periksa-uji.py` → 86 uji/11 berkas OK. |
| 2 | aplikasi/alat (10) | 10 | Semua dibaca (kepala) / dijalankan: `uji-kontras.py`, `periksa-komponen-env.py` (10 OK·0 GAGAL), `periksa-uji.py`, `cek-supabase.mjs`, `catat-alamat.mjs`, `periksa-struktur.py`, `periksa-antarmuka.py`, `periksa-kerapatan.py`, `periksa-semua.sh`, `pratinjau.sh` (kepala tiap berkas). |
| 3 | aplikasi konfigurasi (17) | 17 | `package.json` (skrip lengkap + `cek:supabase`), `tsconfig.app.json`/`tsconfig.node.json` (strict + 4 flag ketat), `vite.config.ts`, `vitest.config.ts` (css:true), `.prettierrc.json`, `eslint.config.js`, `wrangler.toml`, `index.html` (`<meta name="theme-color"/>` kosong → diisi dari token), `.env.example` (8 nama var), `.gitignore`, `README.md`, package-lock (keberadaan). |
| 4 | supabase/migrations (16) | 16 | Seluruh 15 migrasi dibaca penuh lintas sesi audit ini (0001–0015, termasuk pemicu & policy); `.gitkeep` keberadaan. Bukti: `supabase/migrations/0015_penutup_celah_putaran16.sql:289-290` (grant/revoke yang diperiksa); `python3 alat/periksa-migrasi-beku.py` → LOLOS (BEKU=14); hitungan tabel = 26 (bukti di bagian 2 #18). |
| 5 | supabase/tes (47) | 47 | 46 berkas `.sql` dibaca (penuh/greps per asersi) + `.gitkeep`; `ls supabase/tes/*.sql \| wc -l` → 46. Contoh dalam: `rls_penyewa.sql`, `persetujuan_void.sql` (panggilan 5-argumen `verifikasi_pin`), `status_pesanan.sql`. |
| 6 | supabase/functions (2) | 2 | `verifikasi_pin/index.ts` dibaca penuh (CORS `*`:28; body RPC 4 param:77-81; tanpa `console` rahasia) + `.gitkeep`. |
| 7 | supabase akar (2) | 2 | `supabase/README.md` (cara pasang migrasi) & `config.toml` (db_schemas, extra_search_path `["public","extensions"]`, seed.sql direncanakan) dibaca. |
| 8 | alat (43) | 43 | Dibaca/dijalankan: `uji-sql.mjs`, `audit-independen.py` (badan kalibrasi), `review-pr.py` (jalur kalibrasi PR + `bahan_bocor_di_repo`), `periksa-rahasia.py`, `periksa-bersih.py`, `periksa-rujukan.py`, `periksa-temuan-audit.py`, `periksa-fondasi-independen.py`, `periksa-roadmap.py`, `periksa-panduan.py`, `periksa-gerbang-ci.py`, `periksa-angka-bukti.py`, `periksa-paket.py`, `periksa-buku-uji.py`, `periksa-fungsi-pin.py`, `periksa-kunci-kalibrasi.py`, `periksa-migrasi-beku.py`, `uji-mutasi-0012/0014/0015.py`, `bantu_uji_diri.py`, `mulai-sesi.py`, `lanjut-sesi.py`, `kalibrasi-cacat.json` (disonde struktural — temuan F-01), `sql/data-uji.sql`, `contoh-laporan*/` (8+7 berkas), `pulihkan-git.sh`, `uji-database.sh`, `package.json`. Semua pemeriksa Python yang bisa dijalankan → LOLOS. |
| 9 | _sistem (15) | 15 | `validate_system.py` dijalankan → PASS; 4 dokumen audit arsip + `templates/` (8) + kepala tiap berkas dibaca. |
| 10 | docs fondasi (11) | 11 | `KEAMANAN.md` (grep + baca §3/§11), `ROADMAP.md` (T0/T1 + Bukti), `TECH_SPEC.md` §6/§12, `PRD.md`, `DISCOVERY.md`, `SPESIFIKASI_UI.md`, `AGENT_OPERATING_GUIDE.md`, `PANDUAN_PEMILIK.md`, `DECISIONS_LOG.md` (keputusan F-05/beku), `TERTANGGUH.md` (butir tunggu), `README.md`. |
| 11 | docs/uji (88) | 88 | Protokol & prompt audit/review dibaca; `AUDIT_RIWAYAT.md` §1b (31 baris temuan) dibaca; `kalibrasi/` 7 berkas dibaca penuh; `paket-audit/` (9) & `audit/` (10 laporan + probe) & `review-pr/` (20+) dibaca kepala/fragmen + verifikasi `periksa-paket.py`/`periksa-temuan-audit.py` LOLOS. |
| 12 | docs/teknis (6) | 6 | `BUKU_INSIDEN.md` (rujukan hidup — `periksa-rujukan.py` LOLOS), `REKAM_PESAN_PEMILIK.md`, 3 DISKUSI, `USULAN_KEAMANAN…` (kepala tiap berkas). |
| 13 | docs/ops (8) | 8 | `SIAP_AKUN_PEMILIK.md`, `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (dibaca penuh — hanya nilai non-rahasia), `LANGKAH_PEMILIK_SEKARANG.md` (bukti F-03), `SIAP-LANJUT.md`, `ALAMAT_PUBLIK.md`, `SESI_DITINGGALKAN.md`, `SIAP-TEMPEL-SESI-BARU.md`, `DAFTAR_KUNCI_PEMILIK.template.md`. |
| 14 | docs/desain (59) | 59 | `RENCANA_DESAIN_UI.md` + `PENILAIAN_REFERENSI.md` dibaca (34 gambar pemilik tercatat); `mockup/` (5 papan), `referensi/` (13) + `referensi/pemilik/` (34) diverifikasi keberadaan/penamaan (gambar tidak dapat dilihat visual — bagian 6). |
| 15 | prototipe (58) | 58 | `uji-kontras.py` dijalankan → 166 lolos·0 gagal; `tokens.css` identik `tema.css` (`cmp`); `README.md`, `css/`, `js/ui.js`, `alat/`, `aset/` (14), 5 html dibaca kepala/keberadaan. |
| 16 | _log-sesi (5) | 5 | 5 log sesi dibaca kepala + `LOG_SESI_2026-09-19.md` (putaran 18→18c). |
| 17 | berkas pengguna di akar (17) | 17 | `START_DI_SINI.md`, `PANDUAN_PENGGUNA.md` (747 baris — struktur + sampel prompt), `STATUS.md`, `PROFIL_PENGGUNA.md`, `AGENT_SYSTEM.md`, `PROJECT_STATE.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `PROMPT_SESI_BARU.md`, `SYSTEM_MANIFEST.md`, `10_LOG_SESI.md`, `REKAM-KLINIK.md`, `ACCEPTANCE_TESTS.md`, `ACCEPTANCE_TEST_LOG.md`, `PANDUAN_PEMAKAIAN.md` (arsip bertanda), `package.json`, `package-lock.json`, `.gitignore`. |
| 18 | .github/workflows (3) | 3 | `ci.yml` (gerbang lengkap), `sebar-skema.yml` (penanda + dry-run + komentar "14 berkas" — F-03), `sebar-halaman.yml` (penanda + akun non-rahasia + `set -euo pipefail`) semuanya dibaca penuh. |

### 1a. Berkas untuk pengguna

Saya memeriksa berkas pengguna dengan cara pandang pemilik non-teknis (apakah langkah bisa diikuti apa adanya, apakah prompt bisa disalin dan bekerja, apakah ada rujukan mati):

| Berkas untuk pengguna | Cara diperiksa (cara pengguna) | Hasil (bukti: `perintah` / `berkas:baris`) |
|---|---|---|
| `PANDUAN_PENGGUNA.md` | Buku induk 747 baris: §0 cara pakai 30 detik, Bagian A–H (14 alur, semua prompt, mekanisme, perintah, istilah, kalau ada masalah) + `python3 alat/periksa-panduan.py` | **Bagus & hidup**: pemeriksa LOLOS (83 rujukan hidup, prompt identik kanonik); struktur alur bernomor mudah diikuti awam; prompt C4 (audit independen) identik dengan `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` (frasa khas cocok di keduanya). |
| `START_DI_SINI.md` | Entry point: peta baca minimum, cara pasang alat (`npm ci --prefix alat` lalu `aplikasi`), larangan `npm ci` di akar dijelaskan dengan alasan (temuan F-14) | Dapat diikuti non-teknis; perintah yang ditulis ada semua (diperiksa `test -e`); urutan pasang benar. |
| `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` | "3 rahasia di GitHub (±5 menit)" — satu-satunya daftar aksi pemilik saat ini | Langkahnya sendiri sahih, TETAPI klaim penutup **"Fase 0 tuntas. Tidak ada lagi langkah yang menunggu kamu di daftar ini"** (`docs/ops/LANGKAH_PEMILIK_SEKARANG.md:18`) menyesatkan: migrasi 0015 belum tersebar ke proyek nyata dan hanya pemilik yang bisa memicunya — lihat temuan **F-03**. |
| `docs/teknis/BUKU_INSIDEN.md` | Buku darurat bahasa manusia; urutan langkah + Log Insiden | Rujukannya hidup (`periksa-rujukan.py` LOLOS — dulu pernah menyuruh memakai alat yang tak ada, kini diperbaiki); struktur "jangan melompati langkah" sesuai keadaan panik. |
| `docs/ops/SIAP_AKUN_PEMILIK.md` + `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` | Panduan ±30 menit tanpa coding; formulir kunci pemisah rahasia/non-rahasia | Anotasi SELESAI jujur (menyebut 2 langkah lanjutan); formulir hanya berisi nilai non-rahasia (URL, kunci publishable, id proyek, region, id akun Cloudflare) — tanpa `service_role`. |
| `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, `docs/PANDUAN_PEMILIK.md`, `docs/uji/BUKU_UJI_PEMILIK.md`, `docs/ops/*` lainnya | Prompt siap-salin; ringkasan 3 perintah besar; buku uji pemilik (ID `P-nn`/`U-nn` dijaga `periksa-buku-uji.py`) | Semua prompt/rujukan hidup; buku uji dijaga mesin LOLOS; `SIAP-LANJUT.md` menyertakan instruksi ke auditor baru. |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T0-00: nilai non-rahasia (URL, kunci publik, id, region Singapore, id Cloudflare) diserahkan via `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`); `service_role` tak pernah masuk repo | `git show -s bd68685` → "Input DAFTAR_KUNCI_PEMILIK_NONSECRET" 2026-09-19 ✓; baca penuh berkas; `python3 alat/periksa-rahasia.py` → LOLOS; scan pola `sb_secret\|eyJ\|service_role=` di HEAD | **TERVERIFIKASI** — berkas berisi persis nilai non-rahasia itu; tanpa rahasia; `git log -S "sbp_"` hanya menemukan instruksi pembuatan token (teks), bukan nilai. |
| 2 | T0-01: `npm run dev` HTTP 200; 7 folder layar + folder supabase ada; **19 berkas .woff2** | `find aplikasi/src/gaya/aset -name '*.woff2' \| wc -l` → 19; `ls aplikasi/src/layar/` → 7 folder + README; dev server tak dijalankan (bagian 6) | **SEBAGIAN TERVERIFIKASI** — struktur & 19 huruf persis; HTTP 200 tidak bisa dijalankan (larangan memasang). |
| 3 | T0-02: ESLint 9.39/TS 8.70/Prettier 3.9/TS 5.7 ketat; gerbang terbukti menyala lewat uji mutasi | Baca `eslint.config.js`, `tsconfig.app.json` (strict, noUnusedLocals/Parameters/noFallthrough/noUncheckedSideEffectImports), `.prettierrc.json`; `timeout 40 gh run view 35121292973/35120922393/35121062046` | **SEBAGIAN** — konfigurasi ketat ✓ & 3 run MERAH historis terbukti via gh ✓; versi terpasang tak bisa diverifikasi tanpa node_modules (bagian 6). |
| 4 | T0-03: `tema.css` identik `tokens.css`; 19 huruf; kode tema sama; `theme-color` dari token | `cmp aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` → identik; `uji-kontras.py` (166 lolos memuat cek kode tema); `index.html` `<meta name="theme-color"/>` tanpa nilai + `tema.ts:115-117` mengisi dari `--accent` | **TERVERIFIKASI** — semua cocok persis. Catatan kecil: teks Bukti menulis `src/lib/tema.ts` (jalur tak resolve dari akar) → F-08. |
| 5 | T0-04: uji-kontras **166 lolos · 0 gagal** (130 warna + 36 desain); 10 komponen; 76 uji/10 berkas (angka saat itu) | `python3 aplikasi/alat/uji-kontras.py` → "166 lolos, 0 gagal — 10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain"; `python3 aplikasi/alat/periksa-komponen-env.py` → 10 OK·0 GAGAL; `periksa-uji.py` → kini 86 uji/11 berkas | **TERVERIFIKASI** — angka uji-kontras persis; klaim 76/10 beranotasi "angka saat itu" dan bertambah jujur (86/11 kini, dijaga `periksa-angka-bukti.py`). |
| 6 | T0-05: `.env.example` memuat 8 nama var TECH_SPEC §6; hanya 2 `VITE_` aktif; `.env` diabaikan Git | Baca `.env.example` (2 aktif + 7 komentar rahasia tanpa awalan VITE_, termasuk DENYUT_URL); `git check-ignore aplikasi/.env` | **TERVERIFIKASI**. |
| 7 | T0-06: salinan bersih + `npm ci` → semua hijau mengikuti README | Tidak dijalankan (larangan memasang); langkah README diverifikasi teksual + `periksa-semua.sh` dibaca | **TIDAK DAPAT DIJALANKAN** — dilaporkan sebagai keterbatasan (bagian 6), bukan bantahan. |
| 8 | T0-07: CI menyala di tiap push/PR; 3 run MERAH bukti gerbang bekerja | `timeout 40 gh run view` untuk 3 run tsb + `gh run list` cabang sesi | **TERVERIFIKASI** (3 run merah sesuai klaim). Catatan: run CI pada commit auditan `4830b5a` sendiri **cancelled** (digantikan run `ef2a809` 8 detik kemudian yang hijau) → temuan F-02. |
| 9 | T0-08: penanda sebar-skema: gagal tanpa rahasia (35433200326), hijau tanpa kerja (35433237658); langkah-11 success (35432334878); baca katalog HTTP 200 (35435414653) | `timeout 40 gh run list/view` per run | **TERVERIFIKASI** — semua run & status sesuai klaim. |
| 10 | T0-09: penanda sebar-halaman: 35433200375 / 35433237656; alamat publik dicatat | gh + `docs/ops/ALAMAT_PUBLIK.md` (run 35440300274 & 35440432817 hijau, `https://resto-barokah.fatrizmubarok.workers.dev`) | **TERVERIFIKASI**. |
| 11 | T0-10: 76 uji/10 berkas saat itu; kerangka siap; jumlah berkas uji bertambah | `periksa-uji.py` → 86 uji/11 berkas kini; anotasi "angka saat itu" ada | **TERVERIFIKASI sebagai klaim ber-tanggal** (angka segar kini 86/11 — bukan pemalsuan). |
| 12 | T1-01: rls_penyewa — anon 0 baris; kasir A hanya 2 cabangnya; resto B tak melihat resto A | Verifikasi statis: baca `0001` (policy `penyewa_saya()`) + `rls_penyewa.sql` berisi asersi persis klaim | **VERIFIKASI STATIS SESUAI** (suite tak dijalankan — bagian 6). |
| 13 | T1-02: rls_pengguna — kasir hanya dirinya; admin cabang 3 pegawai; owner seluruh resto | Baca `0002` policy `pengguna_pilih` + isi `rls_pengguna.sql` | **VERIFIKASI STATIS SESUAI**. |
| 14 | T1-03: helper untuk 7 akun (pemilik platform tanpa penyewa, pelayan 2 cabang, dst.) | Baca `0003_helper_identitas.sql` + `helper.sql` (7 klaim `uji.sama`) | **VERIFIKASI STATIS SESUAI**. |
| 15 | T1-04: uji membaca katalog PostgreSQL (bukan nama tabel hardcode) — tabel baru otomatis diperiksa | Baca `rls_semua_tabel.sql` (query `pg_tables`/`pg_policies`) — klaim benar secara desain | **VERIFIKASI STATIS SESUAI**; keterbatasan RLS runtime di bagian 6. |
| 16 | T1-05: 10 kode izin + 50 baris izin_peran per resto otomatis; gerbang `boleh()` | `grep -c "insert into public.izin_kode" 0005` → 10 nilai; izin_peran 5 peran × 10 izin; `boleh(aksi[, nominal][, persen])` di `0005`; uji `izin.sql` | **VERIFIKASI STATIS SESUAI**. |
| 17 | T1-06: PIN hanya hash (`crypt`+`gen_salt('bf',10)`), DB menolak non-hash via CHECK; kredensial_pin dicabut dari klien | `0006` (CHECK `pin_hash ~ '^\$[a-z0-9]+\$'`), `0011` (`revoke ... kredensial_pin`), `pin.sql`/`kredensial_pin.sql`/`pin_bukan_oracle.sql` | **VERIFIKASI STATIS SESUAI**; pesan kembar PIN dinetralkan di 0015 bagian 5. |
| 18 | T1-07: 7 tabel katalog, semua RLS; **16 tabel saat itu, 26 hari ini** | `grep -h "create table" supabase/migrations/*.sql \| wc -l` → 26; `grep -c "enable row level security"` → 26 | **TERVERIFIKASI** — 26 tabel hari ini, semua RLS aktif. |
| 19 | T1-08: nama meja unik per cabang ("Meja 5" boleh di 2 cabang, ditolak di cabang sama) | `grep -n "unique" supabase/migrations/0008_meja.sql` → `unique (cabang_id, nama)` | **TERVERIFIKASI**. |
| 20 | T1-09: salinan beku `nama_saat_itu`/`harga_saat_itu` NOT NULL; harga naik setelah pesanan tak mengubah pesanan lama | `0009` kolom NOT NULL + pemicu `picu_item_jaga`; `pesanan.sql` memuat skenario naik 25.000→31.000 | **VERIFIKASI STATIS SESUAI**. |
| 21 | T1-10: 4 tabel baru (pembayaran, metode_bayar, diskon_transaksi, pembatalan); 23 tabel saat itu | `0010` memuat 4 tabel tsb + pemicu `picu_pembayaran_jujur`/jaga_uang; hitungan historis konsisten dengan 26 kini | **VERIFIKASI STATIS SESUAI**. |
| 22 | T1-23: peran tunggal (`pengguna_cabang.peran` dihapus); PIN 6 digit; uji baru | `0011` `alter table ... drop column peran` ✓; CHECK 6 digit ✓; `peran_tunggal.sql` ada | **TERVERIFIKASI**. |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | Palsukan penanda transaksi (`resto.pembatalan_pesanan`) untuk void tanpa PIN | Analisis ulang probe pembangun `docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql` (memakai `set_config('request.jwt.claims',…)`) + riset PostgREST (lihat referensi) | Cacat nyata di level SQL **terbukti**; namun jalur produksi kasir via API tidak bisa memanggil `set_config` (pg_catalog tak terekspos) → klasifikasi "K-1 produksi" dinuansakan → **F-10**. |
| 2 | Baca hitungan pesanan resto lain lewat RPC terekspos | `pr03-bocor-nomor.sql` + audit grant: `0014:419-420` mencabut dari `public` tapi tetap `grant authenticated` tanpa saringan penyewa; `0015:289-290` memperbaiki | Pra-0015: **bocor terbukti** (kasir B baca resto A) — dan produksi masih di 0014 → **F-03**. |
| 3 | Cari policy RLS longgar lintas penyewa di 26 tabel | Baca semua policy `0001`–`0015`; cari predikat tanpa `penyewa_saya()`/`cabang_saya()` | **Tidak ditemukan** — semua policy ber-penyewa memakai helper; konsisten dengan `rls_semua_tabel.sql` (katalog-driven). |
| 4 | Naik peran/menyamar: kasir mengubah izin/peran/pegawai | `izin_*` revoke dari authenticated; `picu_pengguna_jujur`; peran tunggal `0011`; policy `pengguna_pilih` | **Ditolak benar** (verifikasi statis penuh). |
| 5 | Penipuan uang: nominal negatif/nol, bayar lebih, lompat `lunas`, dobel, ubah harga pasca-pesanan, diskon lewat batas/sesudah lunas | Pemicu `0010`/`0012`/`0014` + uji `gerbang_uang.sql`, `diskon_*.sql`, `uang_peladen.sql`, `pembayaran.sql` | **Ditolak benar** (CHECK jumlah>0, `hitung_total`, penolak status klien, pembekuan diskon pasca-lunas 0015). |
| 6 | Ubah baris `pesanan` SETELAH lunas (kolom non-uang) | Enumerasi pemicu before-update di `public.pesanan` (0009 jaga_status, 0010 jaga_uang, 0014 jejak_jujur) + policy `pesanan_ubah` + grep uji | **Celah ditemukan**: `meja_id`/`tipe`/`catatan`/`dibayar_pada`/`dibatalkan_pada`/`alasan_batal`/`shift_id` tak dijaga → **F-07**. |
| 7 | Void tanpa izin; kupon palsu; kupon lintas pesanan | `0012:407` (`pp.pesanan_id = new.pesanan_id`) + `persetujuan_void.sql` | DB menolak benar; **tetapi** jalur Edge Function hanya mengirim 4 param → kupon sah tak mungkin via jalur resmi klien → **F-04**. |
| 8 | Brute-force PIN; pakai jawaban error sebagai oracle | `0012` BATAS_AKUN=5/BATAS_PERANGKAT=12 per 15 menit; pesan netral 0015 bagian 5; `pin_bukan_oracle.sql` | Dibatasi benar; rotasi nama perangkat (B F-11) memang melemahkan lapis ke-2 — **sudah tercatat jujur** TERBUKA/T1-24 (bukan temuan baru). |
| 9 | Curi rahasia dari repo/riwayat | `periksa-rahasia.py` LOLOS; grep pola `sb_secret\|eyJ…\|service_role=`; `git log -S "sbp_"`; baca NONSECRET (hanya publishable); CI memakai `secrets.` context | **Tidak ada kebocoran kunci** (NONSECRET hanya kunci publik by design). |
| 10 | Shadow API: fungsi `public` yang bisa dipanggil siapa saja | Enumerasi `grant execute`/`revoke` lintas migrasi + cek `search_path` tiap fungsi istimewa | Pra-0015: `nomor_pesanan_berikutnya` callable semua authenticated (F-03); semua fungsi SECURITY DEFINER memaku `search_path` dengan `pg_temp` ✓. |
| 11 | Racuni CI/deploy: injeksi workflow, unggah diam-diam | Baca 3 workflow: `permissions: contents: read`, pemicu berkas-penanda, satu blok `set -euo pipefail`, `concurrency`, tanpa `pull_request_target`, secret tak tercetak, penanda tak tersisa (`ls supabase/SEBAR-SKEMA aplikasi/SEBAR-HALAMAN` → tidak ada) | **Tidak ditemukan jalur**; catatan pengerasan pin-SHA di bagian 8. |
| 12 | Suntik kunci idempoten ganda / pesanan dobel | `0009` unique `kunci_idempoten` + `pesanan.sql` | **Ditolak benar**. |
| 13 | XSS/injeksi lewat layar contoh Fase 0 | Baca `LayarContoh.tsx` + 12 komponen + `format.ts`: tanpa `dangerouslySetInnerHTML`, tanpa penyusun SQL di klien; `env.ts` tak meledak saat kosong (`ujiSambungan` dua jalur) | **Bersih**. |
| 14 | Uji ketajaman pemeriksa (gerbang tumpul?) | Jalankan/analisis `--uji-diri` (`bantu_uji_diri.py` dipakai uji-kontras, periksa-panduan, dsb.); `periksa-fungsi-pin.py` tak mengunci daftar parameter; generator 1b paket menghasilkan label palsu | **Dua gerbang tumpul ditemukan** → F-04 (pendamping) & F-05; plus temuan F-01 pada mekanisme kalibrasi. |
| 15 | Drift repo↔produksi lewat GitHub API | `gh run list --workflow "Sebar Skema…"` vs `git cat-file -e 9cb93e0:supabase/migrations/0015_…` vs waktu commit 0015 | **Drift terbukti**: produksi=14 migrasi; 0015 tak pernah tersebar → **F-03**. |
| 16 | Bocorkan kejujuran angka klaim (Bukti basi?) | `periksa-angka-bukti.py` LOLOS; cek silang angka segar (86/11 uji, 26 tabel, 46 berkas uji) vs klaim ber-tanggal | Angka klaim beranotasi tanggal & penjaga angka hidup; **kecuali** dua kalimat basi → F-03 & F-06. |
| 17 | Curang kalibrasi: cari tahu cacat tanaman dari dalam repo | Sondase struktural `alat/kalibrasi-cacat.json` (skema + boolean saja, nilai tak dibaca) | **Kunci de-facto ditemukan di dalam repo** → **F-01** (K-2) + pengungkapan insiden di bagian 5. |

**Lensa L1–L6 (semua dijalankan):**
- **L1 Ancaman & akses:** serangan 1–4, 9–11, 17. Hasil: RLS & peran solid; celah ditemukan di mekanisme audit sendiri (F-01) dan paparan pra-0015 di produksi (F-03).
- **L2 Uang & jejak:** serangan 5–7, 12. Hasil: angka uang dikunci mati oleh pemicu; jejak `jejak_pelaku` tak bisa dipalsukan klien; celah kecil kolom non-uang pasca-lunas (F-07).
- **L3 Kesepakatan dokumen:** serangan 16 + baca silang PRD/TECH_SPEC/KEAMANAN/ROADMAP vs kode. Hasil: janji inti punya kode+uji; dua kalimat pengikat basi (F-03, F-06) + satu jalur rujukan mati kecil (F-08).
- **L4 Mutu uji:** serangan 13–15 + kalibrasi. Hasil: `harap_gagal_sebab` ada (menjawab kekhawatiran sebab-kegagalan); uji-diri luas; gerbang tumpul: parameter edge function tak diuji/dikunci (F-04), generator 1b salah label (F-05), klasifikasi K-1 produksi dinuansakan (F-10).
- **L5 Lapangan & UI:** uji-kontras 166/0 (tinggi sentuh ≥44px, 10 tema, 2 kerapatan), 3 keadaan halaman di layar contoh, pesan galat bahasa manusia di `env.ts`/fungsi PIN; layar nyata kasir belum dibangun (Fase 0) — tidak ada tombol mati yang dijanjikan hari ini (SPESIFIKASI_UI dijaga).
- **L6 Privasi & kepatuhan:** belum ada data pelanggan di skema (pesanan tanpa kolom pelanggan; voucher/tabel pelanggan belum dibuat — T-011 menyatakan kebijakan privasi wajib sebelum F8, jujur tercatat); rahasia tak pernah masuk repo/log (serangan 9); UU PDP & region Singapore tercatat di KEAMANAN §11.

## 4. Temuan

### [F-01] Kunci jawaban kalibrasi cacat tanaman tetap bisa dibaca dari dalam repo — penutupan D F-05 tidak tuntas
- **Tingkat:** K-2
- **Artefak:** `alat/kalibrasi-cacat.json` (10 item), `alat/review-pr.py:34-40` & `kalibrasi_pr_siapkan` (:801-826) & `bahan_bocor_di_repo`, `alat/audit-independen.py:1099-1165`, `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 (tabel tiga jalur), `docs/uji/BERKAS_PENSIUN.md` baris #1
- **Klaim yang dilanggar:** "Kunci jawaban kalibrasi disimpan di luar repo" (paket §0b; PROTOKOL §7) dan prinsip D F-05 (K-2, 2026-09-19) yang tertulis sendiri di `review-pr.py:34-36`: *"bahan kalibrasi review PR TIDAK PERNAH ditulis di dalam repo. Diff terhadap migrasi NYATA = kunci jawaban: siapa pun yang bisa membaca repo … tahu persis baris mana yang ditanam cacat, sehingga skor 'Ditemukan X dari Y' bisa dipalsukan."*
- **Bukti:** `python3` sondase struktural `alat/kalibrasi-cacat.json` (nilai TIDAK dibaca — hanya skema/boolean) → tiap item memuat field `berkas`, `cari` (potongan asli), `ganti` (potongan cacat), `kelas`, `tingkat`, `ringkas`, `harapan_mesin`; **10 dari 10 jalur `berkas` ada di pohon kerja** (berkas proyek nyata). `sed -n '1099,1165p' alat/audit-independen.py` → `mode_kalibrasi_siapkan` menanam cacat dengan `teks.replace(c["cari"], c["ganti"], 1)` persis; `sed -n '801,826p' alat/review-pr.py` → jalur PR sama, dengan pengacakan berbibir tanggal (komentar: "menebak dari katalog tidak lagi menolong"). `sed -n` `bahan_bocor_di_repo` → penjaga bocor hanya memeriksa `pr-bahan-*.diff` dan nama mengandung `KUNCI` — **katalog tidak diperiksa siapa pun**.
- **Skenario gagal:** peninjau PR (manusia/AI dengan akses baca repo — pekerjaannya membaca repo) menerima paket review berisi diff bahan kalibrasi → membuka `alat/kalibrasi-cacat.json` → mencocokkan baris diff dengan string `ganti` → mengetahui identitas, kelas, dan tingkat setiap cacat yang ditanam → mengarang laporan kalibrasi "Ditemukan: X dari X" sempurna → gerbang anti-teater yang menentukan kepercayaan verdict review menjadi bisa dipalsukan.
- **Dugaan penyebab:** penutupan D F-05 (2026-09-19) mengeluarkan **berkas bahan** (`pr-bahan-2026-09-17.diff`) dari repo dan memindahkan pembuatan bahan ke `/tmp`, tetapi **katalog sumbernya** (yang memuat pasangan cari/ganti = isi kunci untuk semua set berikutnya) tertinggal di repo. Mitigasi pengacakan (temuan luar-cakupan putaran8 #3) keliru memodelkan ancaman sebagai "menebak" (pra-hoc), padahal ancaman sebenarnya adalah "mencocokkan" (pasca-hoc: bahan memuat string `ganti` persis) — pengacakan tidak menutupnya.
- **Cara membuktikan perbaikan:** katalog (atau minimal pasangan `cari`/`ganti`-nya) pindah ke luar repo ATAU bahan dibangun tanpa pasangan yang bisa dicocokkan dari repo; `bahan_bocor_di_repo()` diperluas supaya `python3 alat/review-pr.py --kalibrasi-pr-siapkan` **GAGAL** selama katalog masih di repo; uji-diri untuk kasus itu ditambahkan.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Paket audit menargetkan commit yang CI-nya tidak pernah hijau — D F-04 berulang
- **Tingkat:** K-3
- **Artefak:** commit auditan `4830b5a`; `.github/workflows/ci.yml`; `docs/uji/AUDIT_RIWAYAT.md` §1b baris D F-04 (TERBUKA → T1-44)
- **Klaim yang dilanggar:** aturan yang sudah tercatat sendiri: "paket hanya boleh menargetkan commit ber-CI hijau" (penutup D F-04, T1-44).
- **Bukti:** `timeout 40 gh run list --branch arena/01a0b7d1-resto-barokah --workflow CI --limit 8` → kedua run untuk `4830b5a` (`35447609275`, `35447607042`) berstatus **cancelled** (ditimpa push `ef2a809` ±8 detik kemudian); run hijau terdekat adalah `35447616802` pada `ef2a809` dan `35448193549` pada `fd0b330`. Jadi tidak ada satu pun run CI hijau untuk pohon yang diaudit.
- **Skenario gagal:** cacat yang hanya muncul pada pohon `4830b5a` (bukan pada `ef2a809`) tidak akan pernah tertangkap CI, sementara paket mengarahkan auditor percaya commit itu ter-verifikasi.
- **Dugaan penyebab:** paket dibuat beberapa commit setelah `4830b5a`; pengecekan "CI hijau pada commit target" (T1-44) belum diimplementasikan saat paket ini dibuat.
- **Cara membuktikan perbaikan:** `alat/periksa-paket.py` (atau pembuat paket) menolak membuild paket bila `gh run list --commit <target>` tidak menemukan run `success`, dan paket berikutnya hanya menargetkan commit ber-CI hijau.
- **Status verifikasi:** TERVERIFIKASI

### [F-03] Drift repo↔produksi: migrasi 0015 (penutup K-1/K-2 putaran16) belum tersebar, tetapi dokumen pemilik menyatakan "Fase 0 tuntas — tidak ada lagi langkah yang menunggu"
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0015_penutup_celah_putaran16.sql`; `docs/ops/LANGKAH_PEMILIK_SEKARANG.md:18,56-57`; `STATUS.md:30,34-35`; `.github/workflows/sebar-skema.yml:3`; `alat/periksa-migrasi-beku.py:194`
- **Klaim yang dilanggar:** STATUS.md menyatakan temuan paling berbahaya "DITUTUP" lewat 0015 (K-1 penanda palsu, K-2a/b void & diskon, K-2c nomor pesanan, dst.); LANGKAH_PEMILIK_SEKARANG.md: "Fase 0 tuntas. Tidak ada lagi langkah yang menunggu kamu di daftar ini" dan "tabel sudah disebar".
- **Bukti:** `timeout 40 gh run list --workflow "Sebar Skema ke Supabase (disengaja, milik pemilik)" --limit 5` → run terakhir `35435654918` (success) pada head `9cb93e0` pukul **09:47Z**; `git cat-file -e 9cb93e0:supabase/migrations/0015_penutup_celah_putaran16.sql` → **fatal: path … tidak ada** (produksi = 0001–0014); `git log --oneline -- supabase/migrations/0015_…` → 0015 masuk **11:47–12:21Z** (`515b4b2`, `6e6e5b0`, `267d890`) — SETELAH penyebaran terakhir, dan tidak ada run sebar-skema sesudahnya; penanda `supabase/SEBAR-SKEMA` sudah dihapus (tidak ada). Konsekuensi: perilaku yang dibuktikan nyata oleh probe pembangun pra-0015 (`docs/uji/audit/probe-2026-09-19/`: pr01 penanda palsu, pr02 void-satu-item membatalkan seluruh pesanan, pr03 kasir resto B membaca hitungan resto A) **masih hidup di database produksi**. Pelengkap basi: komentar `sebar-skema.yml:3` masih "menyebar 14 berkas migrasi" (kini 15) dan pesan sukses `periksa-migrasi-beku.py:194` "repo masih cocok dengan database nyata" — kini keliru (repo memuat 0015, database tidak).
- **Skenario gagal:** pemilik membaca "Fase 0 tuntas / tidak ada langkah menunggu" dan menganggap produksi sudah memuat semua perbaikan; begitu ada pengguna/pegawai pertama (Fase 2+), celah K-1/K-2 yang "sudah ditutup" ternyata masih terbuka di database nyata, dan tidak ada satu pun dokumen yang menyuruh pemilik memicu sebar ulang.
- **Dugaan penyebab:** maraton T1-45 masih berjalan saat commit auditan; alur sebar memang "disengaja" (pemicu pemilik), tetapi daftar aksi pemilik (`LANGKAH_PEMILIK_SEKARANG.md`) disegarkan pada saat 0014 dan tidak diperbarui setelah 0015 masuk.
- **Cara membuktikan perbaikan:** baris tunggu baru muncul di `LANGKAH_PEMILIK_SEKARANG.md` ("sebar 0015"), atau 0015 tersebar: `gh run list --workflow "Sebar Skema…"` menampilkan run baru hijau di commit ≥`267d890`, dan komentar workflow + pesan penjaga migrasi-beku disegarkan.
- **Status verifikasi:** TERVERIFIKASI (dampak hari ini rendah — proyek nyata belum berpengguna dan tanpa data — karena itu K-3, bukan K-2; bila sudah ada pengguna nyata, temuan ini naik kelas ke K-2.)

### [F-04] Edge Function `verifikasi_pin` hanya mengirim 4 argumen — kupon persetujuan terikat pesanan mustahil dihasilkan lewat jalur resmi klien (sudah tercatat D F-02, tetap ada)
- **Tingkat:** K-3
- **Artefak:** `supabase/functions/verifikasi_pin/index.ts:77-81`; `supabase/migrations/0012_penutup_celah_review.sql:407`; `supabase/tes/persetujuan_void.sql:43,69`; `alat/periksa-fungsi-pin.py`
- **Klaim yang dilanggar:** KEAMANAN §aturan PIN (persetujuan void sesudah dapur wajib kupon yang terbukti); TECH_SPEC jalur Edge Function sebagai gerbang PIN klien.
- **Bukti:** `sed -n '77,81p' supabase/functions/verifikasi_pin/index.ts` → body RPC hanya `{p_pengguna_id, p_pin, p_aksi, p_perangkat}` (tanpa `p_pesanan_id`); `grep -n "pp.pesanan_id" supabase/migrations/0012_penutup_celah_review.sql` → `and pp.pesanan_id = new.pesanan_id` (kupon wajib terikat pesanan); `supabase/tes/persetujuan_void.sql:43` memanggil `verifikasi_pin(…, 'void_sesudah_dapur', 'hp-atasan', <pesanan_id>)` (5 argumen) — uji hanya menempuh jalur RPC langsung, tidak pernah jalur Edge Function; `grep -n "p_pesanan\|param" alat/periksa-fungsi-pin.py` → tidak ada pemeriksaan kelengkapan parameter.
- **Skenario gagal:** kasir menyetujui pembatalan item lewat aplikasi (jalur Edge Function yang dijanjikan) → kupon tidak pernah terikat pesanan → `picu_pembatalan_sah` menolak → void sesudah dapur buntu dari perangkat kasir (fail-closed, fitur rusak), atau pembangun tergoda memanggil RPC melewati Edge Function.
- **Dugaan penyebab:** fungsi Deno ditulis sebelum kupon diikat pesanan (0012) dan tidak ikut diperbarui; temuan ini sudah tercatat sebagai D F-02 (TERBUKA → T1-45) — audit ini memverifikasi ulang secara independen bahwa belum diperbaiki pada `4830b5a`.
- **Cara membuktikan perbaikan:** Edge meneruskan `p_pesanan_id`, ada uji ujung-ke-ujung jalur Edge, dan `periksa-fungsi-pin.py` mengunci daftar parameter wajib.
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Tabel 1b paket audit: 11 baris "berkasnya TIDAK ADA: laporkan!" yang PALSU (sudah tercatat D F-03, tetap ada di paket ini)
- **Tingkat:** K-3
- **Artefak:** `docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md` bagian 1b (berkas di FETCH_HEAD `fd0b330`); generator `alat/audit-independen.py`
- **Klaim yang dilanggar:** catatan mesin bagian 1: "daftar di atas SUDAH disaring — hanya berkas yang benar-benar ada"; baris 1b berlabel "(sudah [x] — berkasnya TIDAK ADA: laporkan!)" menginstruksikan auditor melaporkan berkas yang nyatanya ada.
- **Bukti:** `test -e` untuk `alat/periksa-roadmap.py`, `alat/periksa-panduan.py`, `_sistem/validate_system.py`, `aplikasi/alat/uji-kontras.py`, `aplikasi/alat/periksa-komponen-env.py`, `aplikasi/alat/catat-alamat.mjs`, `alat/uji-sql.mjs`, `alat/uji-mutasi-0012.py` → **semua ADA**; glob `aplikasi/src/komponen/*.tsx` → cocok 12 berkas; satu entri bahkan memuat baris-baru di tengah jalur (`node\n    aplikasi/alat/catat-alamat.mjs`) — string perintah backtick dan glob diperlakukan sebagai jalur berkas literal.
- **Skenario gagal:** auditor yang patuh pada instruksi "laporkan!" akan mengarang ≥9 temuan palsu; pemilik menerima laporan penuh temuan bohong; sinyal temuan mesin jadi tak dipercaya.
- **Dugaan penyebab:** generator 1b mengekstrak token backtick dari teks ROADMAP (termasuk perintah `python3 …`/`node …`) lalu menguji keberadaannya sebagai jalur — ditemukan D F-03 (TERBUKA → T1-45), belum diperbaiki saat paket ini dibuat.
- **Cara membuktikan perbaikan:** generator menyaring prefiks perintah & mengembangkan glob; uji-diri kasus "perintah backtick" ditambahkan; paket berikutnya tak memuat baris "TIDAK ADA" palsu.
- **Status verifikasi:** TERVERIFIKASI

### [F-06] KEAMANAN.md §3 butir 5 basi: `hitung_total()` dinyatakan "belum mendarat" padahal sudah hidup di 0014 dan sudah ikut tersebar ke produksi
- **Tingkat:** K-3
- **Artefak:** `docs/KEAMANAN.md:24`; `supabase/migrations/0014_penutup_celah_putaran13.sql:52`
- **Klaim yang dilanggar:** KEAMANAN.md dokumen pengikat: "Fungsi tunggal `hitung_total()` (T1-15) **belum mendarat** — jangan dibaca sebagai sudah ada".
- **Bukti:** `grep -n "create or replace function public.hitung_total" supabase/migrations/0014_…` → baris 52 (commit `2ce4fab`, 2026-09-18 08:25Z); `git log -1 -- docs/KEAMANAN.md` → `1bbc250` 2026-09-19 07:10Z — dokumen direvisi **setelah** 0014 mendarat tetapi kalimat itu tetap "belum mendarat"; 0014 termasuk 14 migrasi yang **sudah** tersebar ke produksi (lihat F-03), jadi fungsi itu hidup di database nyata. (Tugas T1-15 memang belum lengkap — `pembulatan` belum dibaca oleh fungsi (grep kosong, menyusul T1-16) dan `supabase/tes/uang.sql` belum ada — tetapi kalimat yang benar adalah "versi awal sudah mendarat, belum lengkap", bukan "belum mendarat".)
- **Skenario gagal:** peninjau/pembangun sesi berikutnya membaca dokumen keamanan pengikat dan salah menyimpulkan tidak ada penghitungan uang sisi-peladen (atau mengulang pembangunan); ketidaksesuaian dokumen↔kenyataan di dokumen yang mengikat adalah kelas cacat yang proyek ini sendiri larang.
- **Dugaan penyebab:** perluasan temuan D F-06 (ROADMAP T1-15/T1-17 belum dicatat silang) sudah diusulkan ke T1-45, tetapi kalimat KEAMANAN.md:24 terlewat saat revisi 2026-09-19.
- **Cara membuktikan perbaikan:** kalimat disegarkan ("sudah mendarat di 0014, tanpa pembulatan — lengkap di T1-15/T1-16"); `grep -n "belum mendarat" docs/KEAMANAN.md` → kosong.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Kolom non-uang pesanan bisa diubah klien SETELAH lunas/batal — pembekuan "pesanan tertutup" hanya ditegakkan pada item
- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0009_pesanan.sql` (policy `pesanan_ubah`; `picu_pesanan_jaga_status`), `0010_pembayaran.sql` (`picu_pesanan_jaga_uang`), `0014_penutup_celah_putaran13.sql` (`picu_pesanan_jejak_jujur` + komentar niat "Pesanan yang sudah lunas/batal TIDAK boleh diubah lagi" pada `picu_item_jaga`)
- **Klaim yang dilanggar:** niat yang tertulis di 0014 (pesanan lunas/batal tidak boleh diubah lagi) dan janji laporan yang jujur (ART "riwayat tidak berubah artinya").
- **Bukti:** enumerasi seluruh pemicu before-update pada `public.pesanan`: `grep -rn "before update on public.pesanan\|before insert or update on public.pesanan" supabase/migrations/*.sql` → hanya 3 pemicu (jaga_status, jaga_uang, jejak_jujur) — tidak satu pun menolak perubahan `meja_id`, `tipe`, `catatan`, `dibayar_pada`, `dibatalkan_pada`, `alasan_batal`, `shift_id` pada baris berstatus lunas/batal; policy `pesanan_ubah` mengizinkan kasir/pelayan cabang melakukan UPDATE; `grep -rln "set meja_id\|set tipe\|set catatan" supabase/tes/` → **tidak ada uji** untuk mutasi pasca-lunas pada baris pesanan (uji hanya menyangkut `pesanan_item` — `item_penjaga.sql`, `diskon_sesudah_lunas.sql`).
- **Skenario gagal:** kasir memindahkan pesanan sudah-lunas ke meja lain / mengubah tipe dinein→takeaway / menulis `dibayar_pada` pada pesanan belum lunas / menempel `shift_id` sembarang (kolom tanpa kunci asing, menyusul T1-11) → laporan okupansi meja, laporan waktu-bayar, dan rekap shift (Fase 7) terdistorsi; sejarah pesanan tidak lagi beku.
- **Dugaan penyebab:** pembekuan pasca-tutup diimplementasikan bertahap per gugus kolom (uang → status → item) dan gugus "atribut baris pesanan" belum digarap; `shift_id` memang menunggu T1-11.
- **Cara membuktikan perbaikan:** pemicu before-update menolak perubahan kolom-kolom itu bila `old.status in ('lunas','batal')` (dan `dibayar_pada`/`dibatalkan_pada` hanya boleh peladen), plus uji regresi `pesanan_pasca_lunas.sql` yang merah bila penjaga dihapus.
- **Status verifikasi:** TERVERIFIKASI (dibuktikan dari enumerasi policy+pemicu+grant; tidak dijalankan di basis data — keterbatasan bagian 6. Tidak menyentuh angka uang.)

### [F-08] Rujukan jalur `src/lib/tema.ts` di Bukti T0-03 tidak bisa di-resolve dari akar repo
- **Tingkat:** K-4
- **Artefak:** `docs/ROADMAP.md:79`
- **Klaim yang dilanggar:** kaidah rujukan hidup proyek (jalur ber-backtick harus ada).
- **Bukti:** `grep -n "src/lib/tema.ts" docs/ROADMAP.md` → baris 79 menulis "10 kode tema di `src/lib/tema.ts`" (tanpa prefiks `aplikasi/`); `test -e src/lib/tema.ts` → tidak ada; yang benar `aplikasi/src/lib/tema.ts` (ada). Catatan: baris 1b paket untuk entri ini justru akurat menandainya (satu-satunya baris "TIDAK ADA" yang benar).
- **Skenario gagal:** pembaca menyalin jalur itu untuk membuka berkas → gagal; pemeriksa rujukan yang memeriksa dari akar akan salah tolak.
- **Dugaan penyebab:** singkatan prosa "relatif ke aplikasi/" pada teks Bukti 2026-09-16.
- **Cara membuktikan perbaikan:** `sed -i 's|`src/lib/tema.ts`|`aplikasi/src/lib/tema.ts`|' docs/ROADMAP.md` + `python3 alat/periksa-roadmap.py` tetap LOLOS.
- **Status verifikasi:** TERVERIFIKASI

### [F-09] CORS `Access-Control-Allow-Origin: '*'` pada Edge Function verifikasi_pin
- **Tingkat:** K-4
- **Artefak:** `supabase/functions/verifikasi_pin/index.ts:28`
- **Klaim yang dilanggar:** praktik terbaik pembatasan asal (OWASP: wildcard CORS hanya bila memang publik); tidak melanggar janji eksplisit proyek.
- **Bukti:** `grep -n "Access-Control-Allow-Origin" supabase/functions/verifikasi_pin/index.ts` → `'*'` (baris 28).
- **Skenario gagal:** terbatas — fungsi mengautentikasi lewat header `Authorization` (bukan kuki), jawabannya hanya `{berhasil, sisa_percobaan, pesan}`, dan API Supabase sendiri memakai pola serupa; situs jahat tidak memperoleh kemampuan baru yang tidak bisa ia dapat dengan `fetch` + token. Karena itu K-4 (pengerasan), bukan celah aktif.
- **Dugaan penyebab:** meniru pola umum endpoint Supabase tanpa mempertimbangkan pembatasan asal eksplisit.
- **Cara membuktikan perbaikan:** asal dibatasi ke domain aplikasi (`https://resto-barokah.fatrizmubarok.workers.dev` + localhost dev), atau keputusan "biarkan `*`" dicatat di DECISIONS_LOG dengan alasan.
- **Status verifikasi:** TERVERIFIKASI

### [F-10] Klasifikasi "K-1 produksi" pada temuan penanda-palsu (putaran16) melebihi eksploitabilitas produksi nyata — perbaikan tetap benar
- **Tingkat:** K-4
- **Artefak:** `docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql`; `supabase/migrations/0015_penutup_celah_putaran16.sql` bagian 1; `alat/uji-sql.mjs` (harness)
- **Klaim yang dilanggar:** akurasi klasifikasi temuan (K-1 = uang/data terancam nyata di produksi).
- **Bukti:** probe pr01 membuktikan cacat dengan `set_config('request.jwt.clams', …)` — perintah SQL langsung di harness. Di produksi, klien kasir hanya menempuh PostgREST (`/rest/v1/rpc/…`) dan `pg_catalog` **tidak diizinkan** masuk `db-schemas` (dokumentasi PostgREST: "pg_catalog and information_schema are not allowed in db-schemas… cannot be accessed directly" — lihat referensi), jadi `set_config` tidak bisa dipanggil pelanggan; memalsukan klaim JWT menuntut koneksi SQL langsung (kredensial rahasia). Jadi "kasir bisa memalsukan penanda" benar di level basis data, tetapi jalur serang produksi bagi kasir tidak tersedia.
- **Skenario gagal:** (bukan skenario serangan, melainkan skenario misklasifikasi) pemilik menilai risiko berdasarkan label K-1 dan mengalokasikan respons darurat untuk celah yang secara praktis butuh akses SQL langsung; sekaligus harness memang over-approksimasi kekuatan penyerang — yang justru membuat 0015 penting sebagai defense-in-depth bila kelak ada jalur SQL lain.
- **Dugaan penyebab:** probe ditulis untuk membuktikan cacat pemicu di level DB (memang itu fungsinya) dan label K-1 ditulis dari sudut pandang "pemilik basis data".
- **Cara membuktikan perbaikan:** catatan pada laporan/riwayat bahwa eksploitasi produksi menuntut koneksi SQL langsung, atau tambahkan justifikasi klasifikasi; 0015 tetap dipertahankan.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

**Ditemukan: 12 dari 12** (12 = jumlah cacat yang saya yakini ditanam) · **Temuan palsu: 0** (tidak ada temuan yang saya tarik tanpa bukti).

Analisis dilakukan dengan membaca kelima berkas `docs/uji/kalibrasi/bahan-2026-09-17/` seperti kode/dokumen sungguhan, sebelum saya menyentuh apa pun di luar foldernya (kronologi insiden di bawah).

| # | Berkas | Cacat yang saya temukan | Kelas | Bukti |
|---|---|---|---|---|
| 1 | `01_gerbang_izin.sql` | `set search_path = public` pada fungsi SECURITY DEFINER **tanpa `pg_temp`** — konvensi proyek selalu `public, pg_temp`; tanpa `pg_temp` eksplisit, skema temp diperiksa lebih dulu sehingga objek `public` bisa dibayangi dari `pg_temp` (pembajakan search_path fungsi istimewa) | K-2 | definisi fungsi `boleh()` + bandingkan semua migrasi nyata (`set search_path = public, pg_temp`) |
| 2 | `01_gerbang_izin.sql` | **Tidak ada `revoke execute … from public`** padahal komentar berkas itu sendiri mewajibkan "hak execute dicabut dari public" — EXECUTE default diberikan ke PUBLIC, jadi fungsi istimewa itu tetap bisa dipanggil peran mana pun (termasuk anon) | K-2 | `grant execute to authenticated` tanpa revoke sebelumnya |
| 3 | `02_policy_pengaturan.sql` | Policy SELECT `using (penyewa_id is not null)` → setiap pengguna terautentikasi bisa membaca baris pengaturan **semua penyewa** (bocor lintas penyewa); policy UPDATE-nya benar (`penyewa_saya()`) | K-1 | bandingkan policy `pengaturan_ubah` yang benar di berkas yang sama |
| 4 | `03_fungsi_terima_bayar.sql` | Cek lebih-bayar membandingkan `v_sebelum > v_pesanan.total` **sebelum** pembayaran baru dijumlahkan — seharusnya `v_sebelum + p_jumlah > total`; pembayaran yang melampaui total lolos | K-1 | blok `if v_sebelum > v_pesanan.total then raise …` sebelum `insert` |
| 5 | `03_fungsi_terima_bayar.sql` | Fungsi SECURITY DEFINER **tanpa pemeriksaan kepemilikan/penyewa** atas `p_pesanan` — pemanggil lintas penyewa bisa membayar/melunasi pesanan resto lain | K-2 | tidak ada `pesanan_sepenyewa()`/`penyewa_saya()` di badan fungsi |
| 6 | `03_fungsi_terima_bayar.sql` | `set search_path = public` tanpa `pg_temp` (kelas yang sama dengan #1, pada fungsi uang) | K-2 | definisi fungsi |
| 7 | `04_panduan_singkat.md` | Menyuruh `bash aplikasi/pratinjau.sh` — berkas itu **tidak ada** (nyatanya `aplikasi/alat/pratinjau.sh`) | K-3 (langkah pengguna tak bisa dijalankan) | `test -e aplikasi/pratinjau.sh` → tidak ada; `test -e aplikasi/alat/pratinjau.sh` → ada |
| 8 | `04_panduan_singkat.md` | "Salah PIN **10 kali** berturut-turut → akun terkunci 15 menit" — kebijakan nyata **5 kali**/15 menit per akun | K-3 | `supabase/migrations/0012_penutup_celah_review.sql:257` `BATAS_AKUN constant integer := 5` |
| 9 | `04_panduan_singkat.md` | Merujuk `docs/PANDUAN_KEAMANAN.md` — **tidak ada** (nyatanya `docs/KEAMANAN.md`) | K-3 | `test -e docs/PANDUAN_KEAMANAN.md` → tidak ada |
| 10 | `04_panduan_singkat.md` | Menyuruh `python3 alat/periksa-struktur.py` — **tidak ada** di jalur itu (nyatanya `aplikasi/alat/periksa-struktur.py`) | K-3 | `test -e alat/periksa-struktur.py` → tidak ada |
| 11 | `05_pemeriksa_ambang.py` | Glob `src/layar/*.tsx` **tidak rekursif** — layar proyek nyata hidup di subfolder (`layar/contoh/`), jadi pemeriksa selalu menemukan 0 layar | K-3 (L4) | `glob("*.tsx")` vs struktur nyata `aplikasi/src/layar/contoh/LayarContoh.tsx` |
| 12 | `05_pemeriksa_ambang.py` | Cabang `SKIP` di bawah ambang `return 0` — pemeriksa **gagal-terbuka** (selalu hijau saat masih sedikit layar; dikombinasikan #11, selamanya) | K-3 (L4) | `if len(layar) < MIN_LAYAR: print('SKIP'); return 0` |

Catatan di luar hitungan (bukan cacat yang saya yakini sengaja ditanam, dicatat apa adanya): pada `01_gerbang_izin.sql`, `and public.izin_efektif(…)` dipakai dalam konteks boolean — bila `izin_efektif` mengembalikan TABLE seperti di proyek nyata, SQL itu tidak sahih; saya tidak menghitungnya sebagai cacat karena bahan kalibrasi adalah dunia tersendiri.

**Pengungkapan insiden (wajib):** setelah analisis kalibrasi selesai, saat menyapu grup `alat/` untuk mode menyeluruh saya menemukan `alat/kalibrasi-cacat.json` (temuan F-01). Sesuai aturan "menemukan kunci wajib dilaporkan", saya laporkan: (a) analisis kalibrasi saya **sudah selesai** sebelum berkas itu ditemukan; (b) saya **tidak membaca nilai** cacat apa pun — hanya skema field dan uji boolean; (c) uji boolean menunjukkan **0 dari 10** item katalog menunjuk berkas di `bahan-2026-09-17/`, jadi katalog itu bukan kunci untuk bahan yang saya periksa; (d) penilaian akhir tetap milik pembangun — bila pembangun menilai penemuan ini membatalkan kalibrasi saya, saya terima.

## 6. Yang tidak bisa saya verifikasi

- **Semua uji yang butuh pustaka** tidak dijalankan (aturan audit: tidak memasang apa pun): `node alat/uji-sql.mjs` (46 berkas SQL), `alat/uji-mutasi-0012/0014/0015.py`, `cd aplikasi && npm test` (86 uji), `npm run lint`/`typecheck`, `npm audit` (klaim "0 kerentanan" dari audit A F-09). Sebagai gantinya: verifikasi statis penuh (migrasi + berkas uji dibaca; asersi dicocokkan dengan klaim) dan seluruh pemeriksa Python yang bisa dijalankan → **semua LOLOS** (periksa-bersih, periksa-rahasia, periksa-rujukan, periksa-temuan-audit, periksa-fondasi-independen, periksa-roadmap, periksa-panduan, periksa-gerbang-ci, periksa-angka-bukti, periksa-paket, periksa-buku-uji, periksa-fungsi-pin, periksa-migrasi-beku, periksa-kunci-kalibrasi, uji-kontras aplikasi & prototipe, periksa-komponen-env, periksa-uji, validate_system).
- **Versi pustaka terpasang** (ESLint 9.39 / typescript-eslint 8.70 / Prettier 3.9 / TypeScript 5.7 / vitest 5.0.1) — hanya versi di `package.json` yang bisa dibaca.
- **`npm run dev` HTTP 200** dan perilaku peramban nyata (tangkapan layar, tema visual) — tidak dijalankan.
- **Perilaku basis data secara runtime** (RLS, pemicu) — tidak ada PostgreSQL/PGlite terpasang; semua klaim perilaku SQL di laporan ini adalah hasil pembacaan kode + uji statis + probe pembangun yang terdokumentasi, bukan eksekusi saya sendiri. Karena itu F-07 berstatus verifikasi statis (enumerasi lengkap policy+pemicu+grant).
- **Proyek Supabase nyata tidak saya probe langsung** (di luar cakupan audit repo; hanya membaca bukti run CI via `gh` dan dokumen). Jadi apakah pendaftaran akun mandiri terbuka di proyek nyata (relevan untuk paparan F-03) tidak diverifikasi.
- **Gambar** (referensi desain 47, papan mockup, aset prototipe) tidak dapat dilihat secara visual oleh sesi ini — diperiksa keberadaan, penamaan, dan integritas rujukannya saja.
- **Berkas paket audit** ada di FETCH_HEAD (`fd0b330`), belum ter-commit pada commit auditan — angka/tabel paket saya kutip dari salinan itu.
- **Kunci jawaban kalibrasi** berada di luar repo; skor "X dari Y" saya adalah klaim auditor, dinilai pembangun.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan tidak mengubah apa pun di luar laporan ini. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah.
Bukti: perintah `git status --short` yang saya jalankan menampilkan hanya berkas laporan ini.

```
$ git status --short
?? docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbcb.md
```

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 8-01 | `persistSession: true` pada klien supabase-js (`aplikasi/src/lib/supabase.ts`) — sesi disimpan di localStorage; bila kelak ada XSS, token bisa diambil. Default pustaka, Fase 0, belum ada data. Catatan pengerasan (CSP + pertimbangan cookie/httpOnly), bukan pelanggaran janji hari ini. | L1 aplikasi klien belum menjadi cakupan uji runtime Fase 0 | `grep -n "persistSession" aplikasi/src/lib/supabase.ts` | Audit keamanan aplikasi saat Fase 2 (layar masuk nyata) |
| 8-02 | GitHub Actions memakai tag versi (`actions/checkout@v5`, `setup-node@v5`) tanpa pin SHA — permukaan supply-chain standar | Di luar lensa L1–L6 paket (bukan uang/data/janji) | `.github/workflows/*.yml` | Audit infrastruktur/supply-chain |
| 8-03 | `supabase/config.toml` memuat blok `[seed]` sql (`./seed.sql`) — berkas seed belum ada; Supabase CLI akan mengabaikannya, tapi konfigurasi menunjuk berkas yang belum dibuat | Rencana T1-21 yang tercatat jujur | `supabase/config.toml` + ROADMAP T1-21 | Audit ulang saat T1-21 dikerjakan |
| 8-04 | D F-08 (advisory lock `nomor_pesanan_berikutnya`) masih TERBUKA dan tercatat T1-45 — verifikasi ulang saya: `grep -rn "pg_advisory" supabase/migrations/*.sql` → kosong (dua kasir bersamaan bisa mendapat nomor sama; tabrakan belum dijaga) | Sudah temuan tercatat (bukan baru), dilaporkan untuk konfirmasi status | grep di atas + AUDIT_RIWAYAT §1b D F-08 | T1-45 |
| 8-05 | B F-11 (lapis ke-2 pembatas PIN memakai nama perangkat kiriman klien) masih TERBUKA/T1-24 — kejujuran dokumentasi terkonfirmasi (KEAMANAN.md mencatat catatan jujur F-11) | Temuan tercatat; konfirmasi status | `docs/KEAMANAN.md` catatan F-11 + `supabase/tes/percobaan_pin_perangkat.sql` | T1-24 |
| 8-06 | Dua salinan `uji-kontras.py` (aplikasi vs prototipe) berbeda secara **disengaja** (versi aplikasi membaca token aplikasi + punya uji-diri) — bukan drift; dicatat supaya tidak salah tuduh | Verifikasi positif | `diff aplikasi/alat/uji-kontras.py prototipe/uji-kontras.py` (docstring menjelaskan) | — |

### Referensi eksternal yang dipakai untuk menilai perilaku sistem luar

- PostgREST — schemas & `db-schemas` (pg_catalog/information_schema tidak diizinkan, tak bisa diakses langsung): https://docs.postgrest.org/en/latest/references/api/schemas.html → dasar F-10.
- Supabase — PGRST106 (skema terekspos & exposure): https://supabase.com/docs/guides/troubleshooting/pgrst106-the-schema-must-be-one-of-the-following-error-when-querying-an-exposed-schema → konfirmasi mekanisme exposure RPC.
- Pentestly — Supabase security best practices (fungsi di skema terekspos = "shadow API"): https://www.pentestly.io/blog/supabase-security-best-practices-2025-guide → dasar serangan 2 & 10.
.
/supabase-security-best-practices-2025-guide → dasar serangan 2 & 10.
.
