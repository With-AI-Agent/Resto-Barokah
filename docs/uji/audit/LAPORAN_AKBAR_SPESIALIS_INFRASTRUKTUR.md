# LAPORAN AKBAR — SPESIALIS INFRASTRUKTUR & SOP BENCANA

| Isi | Keterangan |
|---|---|
| **Auditor** | Agen Spesialis Infrastruktur & SOP Bencana (sesi audit terpisah, Arena Agent Mode) |
| **Tanggal** | 2026-09-27 |
| **Tingkat audit** | Pemeriksaan Akbar Fase 0–Fase 10 · jalur horizontal Infrastruktur (setara AUD-2 terarah + uji bunuh mandiri) |
| **Commit yang diaudit** | `0fc63c7e8d4007007380b8fcfc3b74a0d8010963` (cabang `arena/01a0e266-resto-barokah`, SHA diverifikasi `git rev-parse HEAD`) |
| **Paket audit** | `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` + `docs/uji/PROMPT_AKBAR_SPESIALIS_INFRASTRUKTUR.md` + `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` |
| **Mode** | HANYA-BACA (read-only) — tidak mengubah satu pun berkas sumber; laporan ini satu-satunya berkas yang dibuat auditor |
| **Verdict** | **TIDAK-BERSIH — MEMERLUKAN PERBAIKAN sebelum Fase 11** (3 temuan K-2 terverifikasi, 4 temuan K-3, 1 saran K-4) |

---

## 1. Ringkasan Eksekutif (Bahasa Manusia)

Lee, aku sudah memeriksa lima mesin pengaman yang kamu tugaskan: **pemindai kunci rahasia, aturan CSP halaman web, enkripsi cadangan AES-256, 4 dril Buku Insiden, dan denyut harian + penjaga 126 gerbang CI**. Lima perintah uji mesin wajib yang tertulis di naskah prompt **semuanya lulus**, dan aku tidak berhenti di situ: aku mengulanginya dengan uji bunuh mandiri (menyusupkan kunci palsu, merusak header, menebak kunci yang salah, dan lainnya) untuk membuktikan mesin-mesin ini benar-benar bisa MENOLAK, bukan sekadar terlihat hijau.

**Kabar baiknya:** pemindai rahasia memeriksa 2.869 berkas terlacak dengan 10 pola kunci dan terbukti menolak semuanya; CSP `script-src 'self'` benar-benar bersih dari `unsafe-inline`/`unsafe-eval`; cadangan benar-benar dienkripsi AES-256-CBC + PBKDF2 100.000 iterasi (terbukti secara empiris); latihan pemulihan ke database 100% kosong memulihkan **47 tabel & 192 baris dengan paritas 100%, RLS 47/47 aktif**, dan **keempat dril Buku Insiden (perangkat hilang, akun dibobol, pegawai berhenti, rekap harian & privasi UU PDP) berjalan sempurna**.

**Kabar yang harus kamu tindak:** mesin **denyut harian yang dijanjikan menjaga Supabase Free tidak tidur ternyata tidak pernah menyentuh database produksi** — yang berjalan hanyalah simulasi lokal di dalam mesin GitHub. Bahkan berkas jadwalnya (`denyut-harian.yml` dan `cadangan.yml`) **belum aktif sama sekali di GitHub** karena jadwal otomatis GitHub hanya mau jalan dari cabang utama (`main`), sementara `main` belum memuat berkas-berkas itu. Ada pula beberapa celah kecil: format kunci OpenAI modern (`sk-proj-`) lolos dari pemindai, dan alur cadangan mingguan bisa tetap hijau sambil mengunggah cadangan yang mustahil dipulihkan bila lupa memasang rahasia di GitHub.

Ringkasnya: **inti keamanan & kebencanaan sangat solid, tetapi lapis "denyut harian" yang menopangnya belum bekerja ujung-ke-ujung.** Semua temuan punya perbaikan yang kecil dan jelas.

---

## 2. Tabel Bukti Pengujian

### 2a. Perintah uji mesin wajib (PROMPT_AKBAR_SPESIALIS_INFRASTRUKTUR §3)

| No | Perintah terminal | Hasil | Angka kunci |
|---|---|---|---|
| 1 | `python3 alat/periksa-rahasia.py` | **LOLOS** | 2.869 berkas terlacak diperiksa · 10 pola kunci · aturan abaikan ada · 0 temuan |
| 2 | `python3 alat/periksa-rahasia.py --uji-diri` | **LOLOS** | 7/7 mutasi ditolak tepat (kunci JWT, sb_secret_, Brevo, Google OAuth, hapus `.gitignore`, hapus formulir) |
| 3 | `python3 alat/periksa-header.py` | **LOLOS** | `aplikasi/public/_headers` terverifikasi utuh; setelah build: `aplikasi/dist/_headers` pun terverifikasi utuh |
| 4 | `python3 alat/periksa-header.py --uji-diri` | **LOLOS** | 9/9 mutasi tertangkap (hapus CSP, X-Frame-Options bukan DENY, object-src hilang, wildcard, unsafe-eval, **unsafe-inline**, dst.) |
| 5 | `node alat/eksekusi-latihan-insiden.mjs --uji-diri` | **LOLOS** | 6/6 skenario: baseline lulus + 5 mutasi (selisih baris, baris audit hilang, RLS dimatikan, gagal cabut sesi, gagal nonaktifkan akun) ditolak tepat |
| 6 | `bash alat/pulihkan-cadangan.sh latihan` | **LOLOS** | Clean-slate: **47 tabel, 192 baris, 0 selisih, RLS 47/47**, FK valid; **4/4 dril insiden sukses**; durasi 3,88 detik (RTO < 30 menit terpenuhi) |
| 7 | `python3 alat/periksa-gerbang-ci.py` | **LOLOS** | **126 gerbang wajib** ada, tanpa pelemahan; alur lain diawasi: sebar-skema 8, sebar-halaman 6, cadangan 7, denyut-harian 3 perintah |
| 8 | `python3 alat/periksa-gerbang-ci.py --uji-diri` | **LOLOS** | 42 skenario (1 kontrol + 41 mutasi: hapus gerbang, `\|\| true`, `if: false`, `continue-on-error`, `fetch-depth 0→1`, dst.) **semua ditolak tepat** |

### 2b. Uji bunuh & verifikasi tambahan yang kujalankan sendiri

| No | Perintah / uji | Hasil |
|---|---|---|
| 9 | Harness mandiri: tanam **10 pola kunci satu per satu** di repo mini `/tmp` (JWT, private key, sbp_, sb_secret_, sk-, re_, AKIA, xkeysib-, GOCSPX-, ghp_) → panggil `periksa()` | 9 dari 10 **DITOLAK**; pola `sk-proj-` (format OpenAI modern) **LOLOS** → jadi temuan F-04 |
| 10 | Harness mandiri: `.env` dan `rahasia.local.md` dipaksa terlacak (`git add -f`) | Keduanya **DITOLAK** (fail-closed terbukti di luar uji-diri resmi) |
| 11 | Uji bunuh CSP 8 mutasi mandiri (`script-src` + `'unsafe-inline'`, `'unsafe-eval'`, `*`, hapus HSTS/XFO/nosniff/upgrade-insecure-requests) | Semua **DITOLAK** dengan pesan galat yang tepat; baseline & `style-src 'unsafe-inline'` (diizinkan aturan) diterima |
| 12 | `npm run build` (vite) lalu `diff aplikasi/public/_headers aplikasi/dist/_headers` | **IDENTIK** — salinan `dist/_headers` terbukti bersih dari build nyata, bukan klaim |
| 13 | Uji bunuh AES: enkripsi tanpa kunci (lokal), kunci <16 karakter, dekripsi kunci salah, dekripsi `-iter 1`, dekripsi `-iter 100000`, mode `CI=true` tanpa kunci | Tanpa kunci → **gagal-tertutup**; kunci pendek → **ditolak**; kunci salah → **gagal + berkas keluaran dibersihkan**; `-iter 1` → **ditolak**, `-iter 100000` → **sukses & isi identik 100%** (PBKDF2 100.000 terbukti empiris); `CI=true` → kunci ephemeral + **alur tetap lanjut** → temuan F-05 |
| 14 | `python3 alat/uji-mutasi-cadangan.py` (langkah resmi `cadangan.yml`) | **LOLOS** — 7/7 (kontrol hijau + 6 mutasi: tanpa kunci, kunci lemah, kunci salah, ciphertext rusak, SQL korup, data penyewa hilang) |
| 15 | `bash alat/cadangan.sh uji-pemulihan` (langkah resmi `cadangan.yml`) | **LOLOS** — rantai dump→gzip→AES-256→dekripsi→pulih ke database kosong utuh 100% |
| 16 | `python3 alat/denyut.py --uji-diri` | **LOLOS** — whitelist tabel valid, retensi 0 hari ditolak, denyut lokal berjalan |
| 17 | Baca kode: `alat/eksekusi-denyut.mjs`, `.github/workflows/denyut-harian.yml`, `supabase/migrations/0082_denyut_harian_pembersih.sql` | `const pg = new PGlite()` **tanpa koneksi produksi**; workflow tanpa env/secret Supabase; **0 `cron.schedule`** terdaftar di seluruh repo → temuan F-01, F-03 |
| 18 | `gh workflow list` · `gh run list --workflow=denyut-harian.yml` · `git ls-tree -r origin/main` | `denyut-harian` & `cadangan` **tidak terdaftar** (404) · `origin/main` **tidak memuat** `.github/workflows/` → jadwal otomatis belum bisa berjalan → temuan F-02 |
| 19 | `gh run view 36312424923` (run CI untuk commit `0fc63c7`) + replika lokal `python3 _sistem/validate_system.py` | CI **MERAH** di langkah "Pemeriksa fondasi…" — validator menolak 5 rujukan backtick laporan Akbar yang belum dibuat → temuan F-07 |
| 20 | Hitung programatik `GERBANG_WAJIB` di `alat/periksa-gerbang-ci.py` | Tepat **126** gerbang, cocok dengan klaim |

---

## 3. Evaluasi Keamanan Rahasia & Header Web

### 3a. Pemindai kunci rahasia (`alat/periksa-rahasia.py`)

- **Cakupan pola = 10, persis seperti klaim:** JWT panjang, kunci privat, `sbp_` (Supabase), `sb_secret_` (Supabase baru), `sk-` (OpenAI/Resend), `re_` (Resend), `AKIA` (AWS), `xkeysib-` (Brevo), `GOCSPX-` (Google OAuth), `gh[pousr]_` (GitHub). Seluruh penyedia yang disebut mandat tercakup.
- **Fail-closed terbukti dua arah:** salinan utuh diterima (kode 0), semua kerusakan ditolak (kode 1) — melalui `--uji-diri` resmi (7/7) **dan** uji bunuh mandiriku di repo mini (pola nyata satu per satu + berkas rahasia `.env`/`.local.md` yang dipaksa terlacak → ditolak).
- **Kebijakan berkas rahasia:** pola `*.local`, `*.local.md`, `.env` wajib ada di `.gitignore` (dijaga), tidak ada berkas rahasia yang terlacak, dan formulir kosong `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` yang ikut Git (berkas kerja terisinya memang tidak ikut Git). Pemindai memeriksa `git ls-files` — cakupan yang tepat untuk menjaga Git, dan 2.869 berkas terlacak hari ini **bersih**.
- **Satu celah pola (F-04):** `sk-proj-…`/`sk-svcacct-…` (format kunci OpenAI yang beredar sekarang) dan badan `sk-` yang mengandung `-`/`_` tidak tertangkap regex `sk-[A-Za-z0-9]{20,}` — terbukti dengan uji bunuh.

### 3b. Header keamanan web (CSP & Cloudflare)

`aplikasi/public/_headers` (dan `aplikasi/dist/_headers` hasil build — **terbukti identik** lewat `vite build` + `diff`) memenuhi seluruh tuntutan mandat:

| Direktif / Header | Nilai di berkas | Status |
|---|---|---|
| `script-src` | `'self'` — **tanpa** `'unsafe-inline'`, **tanpa** `'unsafe-eval'`, tanpa `*` | ✅ sesuai larangan keras |
| `X-Frame-Options` | `DENY` | ✅ |
| `X-Content-Type-Options` | `nosniff` | ✅ |
| `upgrade-insecure-requests` | ada | ✅ |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` (HSTS preload utuh) | ✅ |
| `frame-ancestors` / `object-src` | `'none'` / `'none'` | ✅ |
| `base-uri` / `form-action` | `'self'` / `'self'` | ✅ |
| `default-src` / `connect-src` | `'self'` + daftar domain sah (Supabase, Workers, Resend) tanpa wildcard | ✅ |

Pemeriksa `alat/periksa-header.py` menolak setiap kerusakan (9 mutasi resmi + 8 uji bunuh mandiriku, termasuk `'unsafe-inline'` yang disusupkan ke `script-src` → tertangkap). Penjaga ini juga ikut CI (`periksa-header.py` + `--uji-diri` di `ci.yml`), jadi pelemahan header akan merah sebelum masuk. Catatan: `style-src` masih memuat `'unsafe-inline'` — **ini diizinkan** oleh aturan (larangan keras hanya untuk `script-src`), dicatat sebagai saran K-4.

---

## 4. Evaluasi Pemulihan Cadangan & Dril Insiden

### 4a. Enkripsi AES-256 (`alat/cadangan.sh`)

| Klaim mandat | Bukti | Status |
|---|---|---|
| AES-256-CBC | `openssl enc -aes-256-cbc -salt` — amplop `Salted__` terverifikasi pada berkas keluaran | ✅ |
| PBKDF2 100.000 iterasi | Uji bunuh empiris: dekripsi `-iter 1` **ditolak**, `-iter 100000` **sukses** → iterasi 100.000 benar-benar dipakai | ✅ |
| Kunci aman: ephemeral acak di CI | `CI=true` tanpa `KUNCI_ENKRIPSI_CADANGAN` → kunci acak dibuat + peringatan (sesuai desain) — dengan konsekuensi operasional yang kutemukan di F-05 | ✅ (dengan catatan) |
| Fail-closed di lokal | Tanpa kunci → `GALAT … belum disetel` + berhenti; kunci <16 karakter → ditolak | ✅ |
| Kunci salah / berkas rusak | Dekripsi kunci salah → gagal + berkas keluaran dihapus; ciphertext dirusak → ditolak (7/7 `uji-mutasi-cadangan.py`) | ✅ |
| Plaintext dibersihkan | `dump-dan-enkripsi` menghapus `.sql`/`.sql.gz` mentah setelah enkripsi; SHA-256 dibuat | ✅ |

### 4b. Latihan pemulihan ke database 100% kosong (clean slate)

Eksekusi `bash alat/pulihkan-cadangan.sh latihan` (mesin `alat/eksekusi-latihan-insiden.mjs`, PGlite):

- **47 tabel pulih, 192 baris pulih, selisih 0 (paritas 100%)** — persis angka yang dimandatkan.
- **RLS aktif 47/47** (fail-closed: bila ada tabel tanpa RLS, latihan menolak — dibuktikan Mutasi 3 uji-diri).
- Integritas relasi (FK) **valid & konsisten**.
- Catatan audit permanen tidak bisa diubah/dihapus (Mutasi 2 yang mencoba menghapus baris audit ditolak dengan pesan "Catatan audit bersifat permanen").

### 4c. Empat dril Buku Insiden (`docs/teknis/BUKU_INSIDEN.md`)

| Dril | Bagian Buku Insiden | Hasil eksekusi pada database hasil pulih |
|---|---|---|
| 1. Perangkat kasir hilang/dicuri | §2 | ✅ Perangkat ditandai hilang, **sesi aktif seketika dicabut**, PIN direset, audit tercatat |
| 2. Akun diduga dibobol | §4 | ✅ Akun dinonaktifkan, **seluruh sesi dicabut**, PIN diganti, jejak audit lengkap |
| 3. Pegawai berhenti mendadak | §5 (T10-12) | ✅ Akun dinonaktifkan, PIN dimusnahkan, shift terbuka ditandai `perlu_tutup_atasan`, **riwayat transaksi lama tetap utuh** |
| 4. Rekap harian & privasi UU PDP | §6 & §10 (ART-13/ART-14) | ✅ Deteksi pergantian perangkat tercatat, rantai audit valid, data pribadi pelanggan terlindungi |

Ketahanan mesin dril diuji dengan 5 mutasi kegagalan (selisih baris, baris audit hilang, RLS mati, gagal cabut sesi, gagal nonaktifkan akun) — **semua ditolak tepat** (6/6 termasuk baseline).

---

## 5. Evaluasi Denyut Harian & Integritas CI

### 5a. Yang benar

- `denyut-harian.yml` memuat `cron: '0 19 * * *'` = **02:00 WIB** (19:00 UTC, WIB = UTC+7) setiap hari + `workflow_dispatch`, dengan `concurrency` guard dan timeout — jadwalnya **benar secara rumus**.
- Mesinnya (`alat/denyut.py` + `alat/eksekusi-denyut.mjs`) sehat: whitelist **9 tabel sementara** yang boleh dibersihkan, **27 tabel inti** (keuangan, pesanan, audit, stok, pelanggan) dilindungi penuh, retensi bawaan **30 hari** dengan validasi 1–365 hari, uji-diri lulus, dan SQL-nya (`supabase/migrations/0082_denyut_harian_pembersih.sql`) memuat fungsi `denyut_harian()`, `bersihkan_data_sementara()`, `ambil_log_jadwal()` + tabel `log_jadwal` ber-RLS.
- **126 gerbang CI** terhitung persis 126 di `GERBANG_WAJIB`; `periksa-gerbang-ci.py` lulus dan **41 mutasi pelemahan** (hapus langkah, `|| true`, `if: false`, `continue-on-error`, `fetch-depth 1`, ubah rilis jadi build biasa, dst.) semuanya ditolak — prinsip *no silent bypass* terbukti. Alur di luar `ci.yml` (sebar-skema, sebar-halaman, cadangan, denyut-harian) juga diawasi.

### 5b. Yang tidak berjalan ujung-ke-ujung (dasar temuan F-01 s/d F-03, F-07)

- Eksekutor denyut **hanya** berbicara ke PGlite lokal di dalam runner GitHub (`alat/eksekusi-denyut.mjs` baris `const pg = new PGlite()`, tanpa `SUPABASE_DB_URL`/API apa pun), dan `denyut-harian.yml` **tidak memuat satu pun rahasia/env** yang menghubungkannya ke proyek Supabase. Tidak ada `cron.schedule` yang didaftarkan di migrasi mana pun (blok pg_cron di 0082 hanya `create extension`, tanpa pendaftaran jadwal).
- Berkas jadwalnya sendiri belum aktif di GitHub: `gh run list --workflow=denyut-harian.yml` → **404**, dan `origin/main` (cabang bawaan) **tidak memuat** `.github/workflows/` sama sekali. Aturan GitHub: pemicu `schedule` hanya berjalan **bila berkas workflow ada di cabang bawaan** ([docs.github.com](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows)).
- CI pada commit yang diaudit **merah** di langkah "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras" — akar masalah: `_sistem/validate_system.py` menolak 5 rujukan ber-backtick ke berkas laporan Akbar yang belum dibuat (termasuk laporan ini, yang akan menggugurkan 1 dari 5).

---

## 6. Daftar Temuan (K-1 s/d K-4)

### [F-01] Denyut harian anti-tidur tidak pernah menyentuh basis data produksi Supabase

- **Tingkat:** K-2 (Tinggi)
- **Artefak:** `alat/eksekusi-denyut.mjs:83` (`const pg = new PGlite()`) · `.github/workflows/denyut-harian.yml:22-24,43-47` · `supabase/migrations/0082_denyut_harian_pembersih.sql:325-339`
- **Klaim yang dilanggar:** PROMPT_AKBAR_SPESIALIS_INFRASTRUKTUR §2.4 — "menjaga proyek Supabase Free Tier tidak tidur"; ROADMAP T10-08 Tujuan — "proyek gratis tidak tidur".
- **Bukti (perintah → hasil):** `grep -rn "cron.schedule" supabase/ alat/ .github/` → **0 pendaftaran jadwal** (hanya komentar "dapat didaftarkan"); `sed -n '1,110p' alat/eksekusi-denyut.mjs` → PGlite tanpa koneksi jarak jauh; `cat .github/workflows/denyut-harian.yml` → tanpa env/secret Supabase; `python3 alat/denyut.py --semua` → hanya menulis `log_jadwal` di PGlite runner yang musnah saat job selesai.
- **Skenario gagal:** Kedai libur / trafik API < 7 hari → Supabase Free otomatis **pause proyek** ([Supabase Production Checklist](https://supabase.com/docs/guides/deployment/going-into-prod)) → seluruh aplikasi multi-tenant mati sampai Lee membuka dashboard dan me-restore manual; workflow GitHub tetap hijau sehingga tidak ada tanda bahaya.
- **Dugaan penyebab:** denyut dirancang sebagai simulasi/ujian fungsi SQL di PGlite; jembatan ke produksi (langkah CI yang memanggil RPC via `SUPABASE_DB_URL`, atau `cron.schedule` di produksi) tidak pernah dibangun.
- **Cara membuktikan perbaikan:** tambah langkah di `denyut-harian.yml` yang menjalankan `select public.denyut_harian();` dan `select public.bersihkan_data_sementara(30);` terhadap `SUPABASE_DB_URL` (mis. via `psql`), lalu buktikan baris baru di `public.log_jadwal` **pada proyek produksi**; alternatif: daftarkan `cron.schedule('denyut-harian', '0 19 * * *', ...)` lewat migrasi. Hijau = log produksi bertambah tiap hari.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Workflow berjadwal `denyut-harian.yml` & `cadangan.yml` belum aktif di GitHub — jadwal 02:00 WIB tidak pernah berjalan otomatis

- **Tingkat:** K-2 (Tinggi)
- **Artefak:** `.github/workflows/denyut-harian.yml:22-23` · `.github/workflows/cadangan.yml:23-24` · keadaan `origin/main`
- **Klaim yang dilanggar:** PROMPT_AKBAR §2.4 — "berjalan otomatis setiap hari pukul 02:00 WIB"; T10-10 DoD — "pg_dump mingguan berjalan otomatis".
- **Bukti (perintah → hasil):** `gh workflow list` → hanya CI, DIAG, sebar-halaman, sebar-skema (denyut & cadangan **tidak ada**); `gh run list --workflow=denyut-harian.yml` → **HTTP 404** (workflow tak dikenal server); `git ls-tree -r --name-only origin/main | grep workflows` → **tidak ada** `.github/workflows/` di cabang bawaan; aturan resmi GitHub: *"This event will only trigger a workflow run if the workflow file exists on the default branch. Scheduled workflows will only run on the default branch."* ([docs.github.com](https://docs.github.com/actions/using-workflows/events-that-trigger-workflows)).
- **Skenario gagal:** Percaya denyut 02:00 WIB & cadangan Minggu 02:00 WIB sudah jalan, padahal tidak pernah terjadwal → F-01 tetap terjadi, dan saat bencana ternyata **tidak pernah ada artefak cadangan mingguan** yang tersimpan.
- **Dugaan penyebab:** seluruh pekerjaan hidup di cabang arena; `main` (cabang bawaan) masih pohon lama; pemicu `schedule`/`workflow_dispatch` mensyaratkan berkas di cabang bawaan.
- **Cara membuktikan perbaikan:** gabungkan (merge) `.github/workflows/denyut-harian.yml` & `cadangan.yml` ke cabang bawaan (atau jadikan cabang yang memuatnya sebagai default), lalu `gh run list --workflow=denyut-harian.yml` menampilkan run `schedule` pertama; bukti tambahan: run manual `workflow_dispatch` berhasil dari UI.
- **Status verifikasi:** TERVERIFIKASI

### [F-03] Pembersih data sementara retensi 30 hari juga hanya berjalan pada simulasi lokal

- **Tingkat:** K-3 (Sedang)
- **Artefak:** `alat/denyut.py:127-150` (`jalankan_bersihkan`) · `alat/eksekusi-denyut.mjs:83,121-123`
- **Klaim yang dilanggar:** PROMPT_AKBAR §2.4 — "membersihkan berkas retensi 30 hari"; T10-08 Tujuan — "data sementara tidak menumpuk".
- **Bukti (perintah → hasil):** `python3 alat/denyut.py --bersihkan` → memanggil `public.bersihkan_data_sementara(30)` pada PGlite runner, bukan produksi (jejak sama dengan F-01); hasil pembersihan (`percobaan_pin`, token kadaluwarsa, sesi usang) hanya ada di database sementara CI.
- **Skenario gagal:** Berbulan-bulan pemakaian produksi → tabel percobaan/token/sesi usang menumpuk → kuota 500 MB Free Plan tergerus; kalau nyaris penuh, pembersihan darurat manual di tengah jam sibuk.
- **Dugaan penyebab:** sama dengan F-01 (tidak ada jalur eksekusi ke produksi).
- **Cara membuktikan perbaikan:** langkah CI yang sama dengan F-01 mengeksekusi `bersihkan_data_sementara(30)` ke produksi; bukti: `select * from log_jadwal where jenis='pembersihan'` di proyek Supabase menampilkan baris harian dengan jumlah terhapus wajar.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Pola `sk-` pemindai rahasia tidak menangkap format kunci OpenAI modern (`sk-proj-`, `sk-svcacct-`, badan ber-hyphen/underscore)

- **Tingkat:** K-3 (Sedang)
- **Artefak:** `alat/periksa-rahasia.py:38` (`re.compile(r"\bsk-" + r"[A-Za-z0-9]{20,}")`)
- **Klaim yang dilanggar:** PROMPT_AKBAR §2.1 — "memeriksa … terhadap 10 pola kunci rahasia (… OpenAI …)".
- **Bukti (perintah → hasil):** harness `/tmp` (fungsi `periksa()` dipanggil langsung): `sk-` + 30 alnum → **DITOLAK**; `sk-proj-` + 40 alnum → **LOLOS**; `sk-svcacct-…` → **LOLOS**; `sk-` badan ber-underscore → **LOLOS**. Uji-diri resmi tidak memuat mutasi format ini.
- **Skenario gagal:** Kontributor tidak sengaja meng-commit kunci OpenAI format baru → pemindai hijau → kunci bocor ke riwayat Git.
- **Dugaan penyebab:** regex disusun untuk format lama `sk-` + alnum polos; tanda hubung/underscore memutus kelas karakter `[A-Za-z0-9]{20,}`.
- **Cara membuktikan perbaikan:** perluas pola (mis. `\bsk-[A-Za-z0-9_-]{16,}` atau tambah `\bsk-(proj|svcacct|ant)-`), tambah mutasi `sk-proj-` ke `--uji-diri`; hijau = harness di atas menolak keempatnya + `python3 alat/periksa-rahasia.py --uji-diri` lulus.
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Alur cadangan mingguan tetap hijau saat `KUNCI_ENKRIPSI_CADANGAN` belum disetel — artefak terenkripsi yang mustahil dipulihkan tetap diunggah

- **Tingkat:** K-3 (Sedang)
- **Artefak:** `alat/cadangan.sh:57-67` (`pastikan_kunci` cabang CI) · `.github/workflows/cadangan.yml:41-42,70-79`
- **Klaim yang dilanggar:** T10-10 DoD — cadangan harus dapat dipulihkan ("pemulihan diuji ke basis data kosong"); header `cadangan.yml` — "Kunci enkripsi dibaca dari GitHub Secret" (tanpa menyebut fallback ephemeral).
- **Bukti (perintah → hasil):** `CI=true GITHUB_ACTIONS=true env -u KUNCI_ENKRIPSI_CADANGAN bash alat/cadangan.sh enkripsi …` → "PERINGATAN KEAMANAN … Menghasilkan kunci ephemeral acak" lalu **enkripsi tetap dilanjutkan** dan artefak `.enc` tetap dibuat; kunci dibuang setelah job → artefak tidak bisa dibuka siapa pun, alur tetap **hijau**, `upload-artifact` tetap berjalan.
- **Skenario gagal:** Secret kedaluwarsa/terhapus → setiap Minggu artefak "cadangan-resto-barokah" muncul sukses → saat bencana nyata tidak ada satu pun yang bisa didekripsi → kehilangan data permanen.
- **Dugaan penyebab:** kompromi desain anti-bocor (lebih baik tak terbaca daripada plaintext bocor) tanpa pemisahan mode: mode produksi seharusnya **menolak jalan** bila kunci tak tersedia (pola yang sudah benar dipakai `sebar-halaman.yml`: `test -n "$CLOUDFLARE_API_TOKEN" || exit 1`).
- **Cara membuktikan perbaikan:** di `cadangan.yml` tambah langkah validasi `test -n "$KUNCI_ENKRIPSI_CADANGAN"` yang `exit 1` sebelum dump-dan-enkripsi; hijau = run tanpa secret **merah**, dengan secret **hijau** + artefak bisa `dekripsi` ulang.
- **Status verifikasi:** TERVERIFIKASI

### [F-06] Saat `SUPABASE_DB_URL` kosong, "cadangan mingguan" berubah menjadi dump simulasi PGlite yang diunggah sebagai cadangan

- **Tingkat:** K-3 (Sedang)
- **Artefak:** `alat/cadangan.sh:96-105` (cabang `else` + `WAJIB_DB_PRODUKSI`) · `.github/workflows/cadangan.yml:42` (tidak menyetel `WAJIB_DB_PRODUKSI: 1`)
- **Klaim yang dilanggar:** T10-10 Tujuan — "data kedai tidak hilang selamanya"; pemulihan harus dari data produksi.
- **Bukti (perintah → hasil):** baca `cmd_dump` — tanpa `SUPABASE_DB_URL`, skrip mencetak peringatan lalu memanggil `alat/eksekusi-cadangan.mjs --dump` (PGlite: 82 migrasi + benih uji), hasilnya dienkripsi & diunggah `upload-artifact` dengan nama `cadangan-resto-barokah`; sakelar `WAJIB_DB_PRODUKSI=1` yang tersedia untuk gagal-tertutup **tidak dipasang** di workflow.
- **Skenario gagal:** Secret `SUPABASE_DB_URL` lupa dipasang saat pilot → artefak mingguan berisi data contoh, bukan data kedai; saat bencana, pemulihan "berhasil" memulihkan data palsu sementara data asli hilang.
- **Dugaan penyebab:** fallback simulasi memang dibutuhkan pra-produksi (tidak ada DB produksi), tetapi tidak ada gerbang yang membedakan "latihan" dan "produksi".
- **Cara membuktikan perbaikan:** set `WAJIB_DB_PRODUKSI: 1` pada env `cadangan.yml` (atau step `test -n "$SUPABASE_DB_URL"`) mulai Fase 11; hijau = tanpa secret run **merah**; dengan secret, isi dump memuat data produksi nyata.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Commit yang diaudit ber-CI merah: validator menolak 5 rujukan laporan Akbar yang belum dibuat

- **Tingkat:** K-2 (Tinggi — kriteria PAKET §2.2 "tidak ada skrip CI yang merah")
- **Artefak:** `docs/uji/PROMPT_AKBAR_*.md:39-40` (rujukan ber-backtick ke `docs/uji/audit/LAPORAN_AKBAR_*.md`) · `_sistem/validate_system.py`
- **Klaim yang dilanggar:** PAKET_PEMERIKSAAN_AKBAR §2.2 & §2.3 — 0 temuan mayor, 100% mesin hijau.
- **Bukti (perintah → hasil):** `gh run view 36312424923` (CI push untuk commit `0fc63c7`, persis commit yang diaudit) → job "Periksa" **X** di langkah "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras"; replika lokal `python3 _sistem/validate_system.py` → **GAGAL** dengan 5 rujukan menggantung: `LAPORAN_AKBAR_AUDITOR_UTAMA.md`, `LAPORAN_AKBAR_PEMERIKSA_FASE.md`, `LAPORAN_AKBAR_SPESIALIS_DATA.md`, `LAPORAN_AKBAR_SPESIALIS_FRONTEND.md`, `LAPORAN_AKBAR_SPESIALIS_INFRASTRUKTUR.md`.
- **Skenario gagal:** Cabang tidak bisa digabung selama gerbang merah; klaim "100% mesin hijau" pada dokumen pemeriksaan akbar tidak bisa dinyatakan.
- **Dugaan penyebab:** efek ayam-telur paket Akbar — naskah prompt memakai backtick untuk berkas laporan yang memang baru dibuat "saat pelaporan"; validator (repo standalone AT-08) menolak rujukan ke berkas yang belum ada. **Bukan** kelemahan gerbang — gerbang justru bekerja benar (fail-closed). Sifatnya transisi: laporan ini sendiri menggugurkan 1 dari 5 rujukan (terverifikasi: `validate_system.py` setelah laporan ditulis kini menunjuk 4, bukan 5).
- **Cara membuktikan perbaikan:** setelah kelima laporan spesialis masuk → `python3 _sistem/validate_system.py` lulus dan CI commit berikutnya hijau; alternatif lebih cepat: ubah rujukan di naskah prompt menjadi provenance tanpa backtick (sesuai saran validator).
- **Status verifikasi:** TERVERIFIKASI

### [F-08] `style-src` masih memuat `'unsafe-inline'` (diizinkan aturan saat ini)

- **Tingkat:** K-4 (Saran)
- **Artefak:** `aplikasi/public/_headers:23`
- **Klaim yang dilanggar:** tidak ada — larangan keras mandat hanya untuk `script-src`; ini peningkatan ketahanan lanjutan.
- **Bukti (perintah → hasil):** `grep style-src aplikasi/public/_headers` → `style-src 'self' 'unsafe-inline'`; uji bunuh membuktikan pemeriksa memang mengizinkannya (sesuai aturan) dan tetap menolak `unsafe-inline` di `script-src`.
- **Skenario gagal:** injeksi gaya (style-based XSS/UI-redressing) bila suatu saat ada celah penyisipan atribut `style`.
- **Dugaan penyebab:** SPA butuh gaya inline komponen; nonce/hash belum diterapkan.
- **Cara membuktikan perbaikan (bertahap, pasca-Fase 11):** pindahkan ke nonce/hash CSP atau pisahkan gaya inline ke berkas; hijau = `script-src`/`style-src` tanpa `unsafe-inline` + seluruh uji UI tetap lulus.
- **Status verifikasi:** TERVERIFIKASI

**Rekap:** K-1: 0 · K-2: 3 (F-01, F-02, F-07) · K-3: 4 (F-03, F-04, F-05, F-06) · K-4: 1 (F-08).

---

## 7. Kesimpulan & Rekomendasi

**Kesimpulan: MEMERLUKAN PERBAIKAN — belum layak dinyatakan LULUS MUTLAK untuk Fase 11** (ada 3 temuan K-2 terverifikasi; kriteria PAKET §2 mensyaratkan 0 K-2).

Yang perlu kamu pegang, Lee: **mesin-mesin pengaman inti yang diuji naskah ini nyata dan kuat** — pemindai rahasia, CSP tanpa `unsafe-inline`, enkripsi AES-256-CBC PBKDF2 100.000, pemulihan clean-slate paritas 100% (47 tabel/192 baris/RLS 47/47), 4 dril Buku Insiden, dan 126 gerbang CI semuanya lulus uji mesin **dan** uji bunuh. Yang belum tuntas adalah **urat nadi operasionalnya**: denyut harian belum menyentuh produksi (F-01, F-03), jadwal otomatisnya bahkan belum aktif di GitHub (F-02), plus tiga jaring pengaman konfigurasi (F-04 s/d F-06) dan CI yang sedang merah karena rujukan laporan (F-07).

**Rekomendasi (berurutan):**
1. **F-01 & F-03** — sambungkan denyut + pembersih ke `SUPABASE_DB_URL` di `denyut-harian.yml` (atau daftarkan `cron.schedule` di produksi). Ini yang menjamin kedai tidak "mati mendadak" setelah libur panjang.
2. **F-02** — bawa `denyut-harian.yml` & `cadangan.yml` ke cabang bawaan (`main`) supaya jadwal 02:00 WIB benar-benar hidup; verifikasi dengan `gh run list`.
3. **F-05 & F-06** — pasang gerbang `test -n` untuk `KUNCI_ENKRIPSI_CADANGAN` & `SUPABASE_DB_URL` (atau `WAJIB_DB_PRODUKSI: 1`) di `cadangan.yml` sejak hari pertama pilot — pola fail-closed-nya sudah ada di `sebar-halaman.yml`, tinggal ditiru.
4. **F-04** — perluas pola `sk-` + tambah mutasi `sk-proj-` di uji-diri pemindai (± 10 menit kerja).
5. **F-07** — masukkan kelima laporan spesialis (atau ubah rujukan jadi tanpa backtick) sampai `validate_system.py` hijau lagi.
6. **F-08** — catat untuk pasca-pilot: hardening `style-src`.

Setelah 1–5 selesai, minta auditor (sesi ini atau sesi baru) memverifikasi ulang enam perintah hijau itu — putaran perbaikan-verify cukup sekali, karena semua temuan berakar pada "jalur ke produksi belum dipasang", bukan cacat desain besar.

---

## 8. Batas verifikasi & pernyataan tidak mengubah apa pun

**Yang tidak bisa saya verifikasi (jujur):**
1. Tidak punya akses ke proyek Supabase/Cloudflare produksi maupun GitHub Secrets (`gh secret list` → HTTP 403) — jadi "apakah secret sudah dipasang di GitHub" tidak bisa dipastikan; temuan F-05/F-06 disusun sebagai risiko kondisional yang tetap harus ditutup gerbangnya.
2. Eksekusi nyata pukul 02:00 WIB tidak bisa diamati hari ini — dan menurut bukti F-02 memang belum akan pernah terpicu sampai berkasnya ada di cabang bawaan.
3. Klaim "menjaga Supabase tidak tidur" hanya bisa diuji setelah F-01 diperbaiki (butuh panggilan jaringan ke proyek nyata).
4. Angka "132 berkas uji SQL" dan "123 berkas uji frontend" dari kriteria PAKET §2.3 di luar cakupan peranku (Spesialis Data & Frontend) — tidak aku periksa di sini.
5. **Keterbatasan independensi:** audit ini berjalan di sesi terpisah dan hanya-baca, tetapi berasal dari keluarga model yang mungkin sama dengan pembangun (Protokol §14 butir 2) — dikompensasi dengan uji bunuh mandiri dan bukti terminal yang bisa direproduksi ulang.

**Pernyataan tidak mengubah apa pun:** laporan ini **tidak mengubah** berkas alur CI/CD, skrip cadangan, header produksi, atau kode apa pun — seluruh pengujian dijalankan pada salinan sementara `/tmp`, PGlite, dan build `aplikasi/dist/` (diabaikan Git). Laporan ini adalah **satu-satunya berkas** yang aku buat. Bukti `git status --short` saat laporan selesai disusun: hanya `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_INFRASTRUKTUR.md` (berkas laporan ini sendiri) yang tercatat sebagai tambahan.

---

## 9. Penutup Chat

**Posisi Sekarang:** Audit infrastruktur & SOP bencana Fase 0–10 atas commit `0fc63c7` **selesai**. 5 perintah uji mesin wajib + ±30 uji bunuh mandiri tercatat di §2; laporan lengkap ada di `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_INFRASTRUKTUR.md`. Verdict: **MEMERLUKAN PERBAIKAN** (3 K-2, 4 K-3, 1 K-4) — inti pengaman solid, denyut harian & jadwal GitHub yang belum menyala.

**Rencana Selanjutnya:** Tunggu keputusanmu — perbaikan terarah F-01 s/d F-07 (kebanyakan menambahkan langkah CI yang menyentuh produksi + merge workflow ke `main`), lalu verifikasi ulang enam perintah hijau. Pemeriksa spesialis lain (Data, Frontend, Auditor Utama, Pemeriksa Fase) tetap diperlukan untuk gerbang LULUS MUTLAK penuh.

**Langkah Lee:** (1) Putuskan: perbaiki dulu temuan K-2 ini sebelum lanjut, atau jalankan dulu 3 spesialis lain paralel? (2) Kalau setuju perbaiki, konfirmasi apakah `SUPABASE_DB_URL` & `KUNCI_ENKRIPSI_CADANGAN` sudah benar-benar terpasang di GitHub Secrets supaya gerbang fail-closed di F-05/F-06 aman dinyalakan; (3) Setujui pembawaan `denyut-harian.yml` & `cadangan.yml` ke `main` (atau tunjuk cabang bawaan lain) supaya jadwal 02:00 WIB hidup.
