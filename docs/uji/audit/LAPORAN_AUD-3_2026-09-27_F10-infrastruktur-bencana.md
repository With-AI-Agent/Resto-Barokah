# LAPORAN PEMERIKSAAN INDEPENDEN FASE 10 — AGEN 3

- **Nama Agen:** Agen 3 — Spesialis Infrastruktur, Ketahanan Sistem & SOP Bencana
- **Target Cabang:** `arena/01a0d09b-resto-barokah`
- **Komitmen yang diperiksa:** `5f7b38be21f1921663f6286a26ebe62f285f4d99`
  - Sesi audit dikunci ke cabang `arena/01a0e1ee-resto-barokah`, yang di-*branch* tepat dari komitmen `5f7b38be…` milik `arena/01a0d09b-resto-barokah`. `git rev-parse HEAD` = `5f7b38be…` → **pohon yang diperiksa identik dengan target**.
- **Waktu Pemeriksaan:** 2026-09-27, 08:15–09:05 UTC (±50 menit kerja)
- **Format:** sesuai `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §6
- **Status Akhir (Verdict):** **PERLU PERBAIKAN**
  - **2 temuan K-1**, **4 temuan K-2**, **4 temuan K-3**, **2 temuan K-4** = 12 temuan
  - **6 dari 126 gerbang CI terbukti MERAH** pada komitmen ini

---

## 1. Ringkasan Eksekutif Hasil Uji

Saya tidak berhenti pada 10 perintah wajib. **Seluruh 126 perintah CI dieksekusi sungguhan secara lokal**, satu per satu, dengan pencatatan *exit code* dan durasi (Lampiran A). Hasilnya **117 LULUS · 9 GAGAL** dalam 1.431 detik. Dari 9 kegagalan itu, **6 adalah cacat nyata** pada komitmen ini dan **3 adalah artefak lingkungan audit** yang saya pisahkan secara eksplisit (§3.13) supaya tidak ada yang dihukum untuk hal yang bukan salahnya.

Lapisan **disiplin pengujian** proyek ini genuinely kuat dan bukan hiasan. Saya bongkar isi tiap *harness* uji-diri untuk memastikan mutasinya nyata, bukan pura-pura: `periksa-gerbang-ci.py` menolak 41 mutasi (termasuk `continue-on-error`, `|| true`, `if: false`, dan penurunan ambang `npm audit`); `eksekusi-latihan-insiden.mjs` menyuntikkan 5 mutasi sebagai cabang kode sungguhan (`rusak_sumber_baris`, `matikan_rls`, `hilangkan_baris_target`, `gagal_cabut_perangkat`, `gagal_nonaktifkan_akun`); `uji-mutasi-cadangan.py` menolak 7 skenario. Keempat dril Buku Insiden memanggil **RPC asli** (`akhiri_sesi`, `tandai_perangkat_hilang`, `keluar_semua_perangkat`, `set_status_pengguna`, `pegawai_berhenti`, `hasilkan_ringkasan_harian`), bukan tiruan. `npm audit` bersih mutlak: **0 kerentanan dari 322 paket** pada semua tingkat keparahan. Klaim T-016 saya cocokkan ke SQL-nya dan **cocok**: `if v_gagal_akun >= 5` di `0059:114`, `if v_gagal_perangkat >= 12` di `0059:122`, dan `mfa.sql` lulus.

Yang menggagalkan kelulusan adalah kenyataan bahwa **semua bukti hijau itu menguji mekanisme, sedangkan data yang dilindungi mekanisme itu tidak pernah benar-benar dicadangkan**, dan **pipeline-nya sendiri sedang merah**. Tiga hal paling serius: **(1)** `.github/workflows/cadangan.yml:35` memuat kunci enkripsi cadangan sebagai *fallback* yang kini publik — saya buktikan dengan `openssl` bahwa artefak `.enc` bisa dibuka siapa pun; **(2)** karena `SUPABASE_DB_URL` tidak pernah divalidasi dan `pg_dump` bisa absen, `alat/cadangan.sh:79` jatuh diam-diam ke mesin PGlite sehingga "cadangan mingguan terenkripsi" yang diunggah ke GitHub **berisi 192 baris data benih uji**, bukan data produksi — RPO produksi nyata **tak berhingga**, padahal `docs/teknis/PEMULIHAN.md:12` menjanjikan < 24 jam; **(3)** enam gerbang CI merah dari dua akar masalah sepele (dua baris hilang di `periksa-semua.sh`, empat rujukan mati di paket audit ini sendiri).

Ada satu temuan yang perlu saya koreksi dari laporan sementara saya sebelumnya: saya sempat menyebut HSTS `preload` dan `max-age` "tidak dijaga sama sekali". Itu **keliru**. Keduanya **dijaga** oleh `aplikasi/src/lib/keamanan-header.test.ts` (Vitest, 5 tes lulus) yang menegaskan string HSTS secara utuh. Yang benar: `periksa-header.py` memang tidak memeriksanya, tetapi Vitest menutup celah itu. Yang **tidak dijaga oleh gerbang mana pun** adalah `'unsafe-eval'`, `connect-src *`, `upgrade-insecure-requests`, dan `form-action` — dan itu saya buktikan dengan menjalankan assertion asli kedua pemeriksa terhadap CSP yang dirusak (§3, F10-A3-07).

---

## 2. Bukti Eksekusi Perintah Wajib

| # | Perintah | Exit | Keluaran nyata (baris penentu) |
|---|---|---|---|
| 1 | `python3 alat/periksa-gerbang-ci.py` | 0 | `126 gerbang wajib ada` · `HASIL: LOLOS — gerbang CI utuh` · alur lain diawasi: sebar-skema (8 perintah), sebar-halaman (6), cadangan (6) |
| 2 | `python3 alat/periksa-gerbang-ci.py --uji-diri` | 0 | `HASIL: LOLOS` — **41 mutasi ditolak** |
| 3 | `bash alat/pulihkan-cadangan.sh --uji-diri` | 0 | `HASIL UJI-DIRI: 100% LOLOS — Seluruh 5 mutasi berhasil ditolak secara konsisten.` Mutasi 2 tertolak lewat eksepsi nyata: *"Catatan audit bersifat permanen dan tidak dapat diubah atau dihapus."* |
| 4 | `node alat/eksekusi-latihan-insiden.mjs` | 0 | `47 tabel (100% cocok)` · `192 baris (100% cocok, 0 selisih)` · `RLS: SEMUA AKTIF (47/47)` · `FK: VALID & KONSISTEN` · 4 dril OK · `Durasi Uji: 3.57 detik` |
| 5 | `python3 alat/periksa-header.py` | 0 | `HASIL: LOLOS — konfigurasi header keamanan halaman lengkap & fail-closed.` |
| 6 | `python3 alat/periksa-header.py --uji-diri` | 0 | `HASIL: SEMUA UJI DIRI LOLOS` — 5 mutasi tertangkap |
| 7 | `python3 alat/periksa-rahasia.py` | 0 | `2862 berkas terlacak diperiksa · 10 pola kunci` → `HASIL: LOLOS` (171 berkas biner dilewati dengan catatan) |
| 8 | `python3 alat/periksa-rahasia.py --uji-diri` | 0 | `HASIL: LOLOS` — 7 mutasi ditolak |
| 9 | `cd aplikasi && npm audit --audit-level=low` | 0 | `found 0 vulnerabilities` |
| 10 | `cd alat && npm audit --audit-level=low` | 0 | `found 0 vulnerabilities` |
| 11 | `node alat/uji-sql.mjs supabase/tes/mfa.sql` | 0 | 82 migrasi OK · `LULUS supabase/tes/mfa.sql` · `uji: 1 LULUS · 0 GAGAL` |

### 2.1 Bukti pendukung yang saya jalankan di luar daftar wajib

| Perintah | Exit | Hasil nyata |
|---|---|---|
| **Seluruh 126 perintah CI** (Lampiran A) | — | **117 LULUS · 9 GAGAL** · total 1.431 s (23,9 menit) pada sandbox 2 vCPU |
| `bash alat/cadangan.sh uji-pemulihan` | 0 | 6 tahap (dump → gzip → AES-256 → dekripsi → `cmp` identik → pulih *clean slate*) → `HASIL UJI: PEMULIHAN BENCANA BERHASIL 100%` |
| `python3 alat/uji-mutasi-cadangan.py` | 0 | `100% LOLOS — Seluruh 7 skenario mutasi fail-closed tertangkap` |
| `npx vitest run src/lib/keamanan-header.test.ts` | 0 | `Test Files 1 passed` · `Tests 5 passed (5)` |
| `npm ci && npm run build` (aplikasi) | 0 | `✓ built in 2.89s`; `aplikasi/dist/_headers` **terbukti terbentuk** dan ikut lulus `periksa-header.py` |
| `python3 alat/periksa-keamanan-sql.py` | 0 | `HASIL: LOLOS` (search_path + ACL efektif + trigger-only + sapuan RLS + InitPlan) |
| `python3 alat/periksa-migrasi-beku.py` | 0 | `HASIL: LOLOS — repo masih cocok dengan database nyata` |
| `python3 alat/periksa-angka-bukti.py` | 0 | `HASIL: LOLOS — semua angka di klaim Bukti bisa direproduksi atau ditandai jujur` |
| `python3 alat/uji-konkuren.py` (+ 3 varian) | 0 | Konkurensi nyata 2 koneksi PostgreSQL (`pgserver` terpasang via pip) lulus |
| `grep -n "continue-on-error\|\|\| true\|if: false" .github/workflows/*.yml` | 1 (nol cocok) | **Nol** pelemahan di keempat alur kerja |
| `npm audit --json` (aplikasi) | 0 | `{info:0, low:0, moderate:0, high:0, critical:0, total:0}` dari `prod:13, dev:310, optional:53, total:322` paket |

### 2.2 Verifikasi silang klaim T-016 (`docs/teknis/TINJAUAN_KEAMANAN_F10.md`)

| Klaim dokumen | Bukti eksekusi | Status |
|---|---|---|
| Brute-force maks **5×** per akun / 15 menit | `supabase/migrations/0059_catat_percobaan_masuk_tenant.sql:114` → `if v_gagal_akun >= 5 then` | ✅ TERBUKTI |
| **12×** per perangkat / 15 menit | `supabase/migrations/0059_…sql:122` → `if v_gagal_perangkat >= 12 then`; pesan: *"Perangkat terkunci sementara karena 12 kali percobaan salah."* | ✅ TERBUKTI |
| Tangga pemulihan 4 tingkat + *break-glass* 30 menit | `node alat/uji-sql.mjs supabase/tes/mfa.sql` → `1 LULUS · 0 GAGAL`; berkas uji 389 baris mencakup `pulihkan_perangkat`, `batalkan_pemulihan`, antrean berstatus `menunggu`, dan uji lintas-tenant (Pak Joko / Resto B) | ✅ TERBUKTI |
| Kebijakan **Rp 0** (menolak Supabase Pro $25/bln) | Tidak ada panggilan `api.pwnedpasswords.com` di seluruh repo; kendali pengganti (≥12 karakter + TOTP + batas 5×) ada di migrasi | ✅ KONSISTEN |
| HSTS **preload** terpasang | `aplikasi/public/_headers:22` → `max-age=31536000; includeSubDomains; preload`, dan **ditegakkan** oleh `keamanan-header.test.ts` (assertion string utuh) | ✅ TERBUKTI & TERJAGA |
| CSP tanpa **unsafe-eval** | `unsafe-eval` memang tidak ada di `_headers` — **tetapi tidak ada satu gerbang pun yang akan menolaknya bila disisipkan** (F10-A3-07) | ⚠️ SESUAI, TAPI TAK TERJAGA |

### 2.3 Verifikasi mekanisme `_headers` di Cloudflare Workers (bukan Pages)

`aplikasi/wrangler.toml` men-*deploy* ke **Workers Static Assets** (`[assets] directory = "./dist"`, `not_found_handling = "single-page-application"`), bukan Cloudflare Pages. Saya verifikasi ke dokumentasi resmi Cloudflare bahwa `_headers` **didukung natif** oleh Workers Static Assets ("*`_headers` and `_redirects` files are supported natively in Workers with static assets*"), bahwa berkas itu **tidak ikut disajikan** sebagai aset publik, dan bahwa ada batas **2.000 karakter per baris** serta **maksimal 100 aturan**. Saya ukur berkasnya:

```
$ awk '{ printf "%3d  %4d karakter\n", NR, length($0) }' aplikasi/public/_headers | sort -k2 -rn | head -3
 24   387 karakter   (baris Content-Security-Policy — baris terpanjang)
  1   115 karakter
 11    99 karakter
$ grep -c "^  [A-Za-z-]*:" aplikasi/public/_headers
8
```
→ **387/2000 karakter dan 8/100 aturan: jauh di dalam batas.** Tidak ada temuan di sini.

**Yang TIDAK dapat saya verifikasi dari sandbox (dinyatakan jujur):** pengiriman header secara *live*. `curl -sS -I --max-time 25 https://resto-barokah.fatrizmubarok.workers.dev` gagal dengan `curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL` — sandbox tidak punya jalur keluar HTTPS. Kepatuhan header di produksi **belum teruji end-to-end**.

---

## 3. Daftar Temuan Masalah

### F10-A3-01 — Kunci enkripsi cadangan tertulis *hardcoded* di dalam repo sebagai *fallback*
- **Tingkat Keparahan:** **K-1 (Kritis)**
- **Lokasi Berkas & Baris:** `.github/workflows/cadangan.yml:35` (dan pola serupa di `alat/cadangan.sh:225`)
- **Deskripsi Masalah:**
  ```yaml
  KUNCI_ENKRIPSI_CADANGAN: ${{ secrets.KUNCI_ENKRIPSI_CADANGAN || 'kunci-cadangan-bencana-resto-barokah-2026-aman' }}
  ```
  Bila secret GitHub belum/tidak terpasang, alur **tidak gagal** — ia memakai kunci yang kini bersifat publik. Penjaga di `alat/cadangan.sh:54-63` hanya menolak kunci kosong atau < 16 karakter; kunci publik ini 44 karakter sehingga lolos. Konsekuensinya seluruh dump "terenkripsi AES-256-CBC" dapat dibuka oleh siapa pun yang bisa membaca repo — kontributor lama, *fork*, atau publik bila repo terbuka. Klaim pada baris 11–14 berkas yang sama (*"DIENKRIPSI … Kunci enkripsi dibaca dari GitHub Secret"*) dan `docs/teknis/PEMULIHAN.md:14` menjadi tidak benar pada jalur ini.
- **Langkah / Perintah Reproduksi:**
  ```bash
  git ls-files --error-unmatch .github/workflows/cadangan.yml   # → berkas TERLACAK Git
  echo "DATA PELANGGAN: 081234567890 / Budi / meja 12" > rahasia.txt
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in rahasia.txt -out dump.enc \
    -pass "pass:kunci-cadangan-bencana-resto-barokah-2026-aman"
  rm rahasia.txt
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in dump.enc \
    -pass "pass:kunci-cadangan-bencana-resto-barokah-2026-aman"
  # keluaran nyata: DATA PELANGGAN: 081234567890 / Budi / meja 12
  ```
  **Dekripsi berhasil tanpa rahasia apa pun.**
- **Dampak Bisnis (Multi-Tenant / Keamanan):** artefak cadangan (retensi 90 hari di GitHub Artifacts) memuat seluruh 47 tabel lintas tenant — data pribadi pelanggan dan pegawai. Ini pelanggaran **ART-10** sekaligus **UU PDP (UU 27/2022)**. Satu kebocoran artefak = kebocoran massal lintas penyewa. Pemindai `periksa-rahasia.py` **buta** terhadap kasus ini: `POLA_RAHASIA` hanya berisi 10 pola vendor (`sb_secret_`, `sk-`, `xkeysib-`, `GOCSPX-`, …) dan tetap mencetak `LOLOS` saat kunci ini ada di pohon.
- **Rekomendasi Solusi:** hapus klausa `||` dan pakai pola penjaga yang sudah benar di `sebar-skema.yml:65`:
  ```yaml
  test -n "$KUNCI_ENKRIPSI_CADANGAN" || { echo "RAHASIA HILANG: KUNCI_ENKRIPSI_CADANGAN"; exit 1; }
  ```
  Tambahkan pola "literal *passphrase* di blok `env:` alur kerja" ke `alat/periksa-rahasia.py`, **rotasi kunci**, dan perlakukan seluruh artefak `.enc` lama sebagai sudah bocor.

---

### F10-A3-02 — "Cadangan mingguan" diam-diam mencadangkan data benih uji, bukan data produksi
- **Tingkat Keparahan:** **K-1 (Kritis)**
- **Lokasi Berkas & Baris:** `alat/cadangan.sh:79-86` (fallback senyap), `.github/workflows/cadangan.yml:36` (secret tak pernah divalidasi), `alat/eksekusi-cadangan.mjs:143-176` (sumber data), `docs/teknis/PEMULIHAN.md:12` (klaim RPO)
- **Deskripsi Masalah:** `cmd_dump` memakai `pg_dump` **hanya jika** `SUPABASE_DB_URL` terisi **dan** `pg_dump` ada di PATH:
  ```bash
  if [ -n "${SUPABASE_DB_URL:-}" ] && command -v pg_dump >/dev/null 2>&1; then
    pg_dump "$SUPABASE_DB_URL" … > "$berkas_sql"
  else
    node "$AKAR_PROYEK/alat/eksekusi-cadangan.mjs" --dump "$berkas_sql"   # ← data benih PGlite
  fi
  ```
  Tidak ada `test -n "$SUPABASE_DB_URL" || exit 1` di `cadangan.yml` — berbeda dengan `sebar-skema.yml` yang memvalidasi **kedua** secret-nya. `alat/eksekusi-cadangan.mjs` sendiri **tidak pernah membaca** `SUPABASE_DB_URL` (`grep` atas seluruh `.mjs`/`.py`/`.ts` repo: hanya `cadangan.sh:79,81` yang menyebutnya). Alur tetap **hijau**, artefak tetap terunggah, dan tidak ada satu pun pemeriksaan yang membedakan cadangan produksi dari cadangan sintetis. Ini melanggar prinsip **Zero Silent Failure**.
- **Langkah / Perintah Reproduksi:**
  ```bash
  env -u SUPABASE_DB_URL KUNCI_ENKRIPSI_CADANGAN="kunci-audit-eksternal-1234567890" \
    bash alat/cadangan.sh dump-dan-enkripsi /tmp/cad
  #   → "Menggunakan mesin dump internal Resto Barokah (PGlite engine)..."
  #   → "SELESAI: Enkripsi berhasil"   (TETAP SUKSES, exit 0)
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in /tmp/cad/*.enc \
    -pass "pass:kunci-audit-eksternal-1234567890" | gunzip -c > /tmp/dump-audit.sql
  grep -c "11111111-1111-1111-1111-111111111111" /tmp/dump-audit.sql     # → 84
  ```
  Isi artefak yang terbongkar: **29.576 baris SQL, 192 baris data**, seluruhnya data uji —
  `penyewa: 2 · pengguna: 7 · pesanan: 1 · pembayaran: 0 · shift_kas: 0 · catatan_audit: 1`,
  dengan penanda benih yang tak mungkin berasal dari produksi:
  `kunci_idempoten = 'keranjang-uji-uang'`, `alasan = 'stok awal'`, aksi audit `'uji_pra_cadangan'`.
  Jalur kedua juga terbukti senyap: `env SUPABASE_DB_URL="postgresql://u:p@db.internal:5432/postgres" bash alat/cadangan.sh dump-dan-enkripsi /tmp/cad2` pada mesin tanpa `pg_dump` (`command -v pg_dump` → kosong) tetap mencetak `SELESAI: Enkripsi berhasil`.
- **Dampak Bisnis:** RPO produksi yang sesungguhnya **tak berhingga** — tidak satu byte pun data transaksi/kas/stok ratusan gerai pernah tersimpan di luar Supabase. Klaim `docs/teknis/PEMULIHAN.md:12` ("**RPO < 24 Jam (Harian Denyut)**") tidak ditopang mekanisme apa pun: `grep -n "cadangan|dump|backup" alat/eksekusi-denyut.mjs supabase/migrations/0082_denyut_harian_pembersih.sql` → **nol kecocokan**. Bila proyek Supabase jeda atau rusak permanen, pemulihan akan "berhasil 100%" dengan isi kosong — kehilangan seluruh riwayat keuangan tenant dan rantai audit ART-13.
- **Rekomendasi Solusi:** (a) wajibkan `SUPABASE_DB_URL` dengan penjaga `exit 1`; (b) pasang `postgresql-client` di job cadangan dan **hapus** fallback PGlite dari jalur `dump-dan-enkripsi` (biarkan PGlite hanya untuk `uji-pemulihan`); (c) tulis penanda sumber (`pg_dump` vs `pglite`) ke ringkasan alur dan buat gerbang CI yang menolak artefak berpenanda `pglite`; (d) salin artefak ke penyimpanan **di luar GitHub** agar repo bukan satu-satunya titik gagal.

---

### F10-A3-03 — Enam gerbang CI MERAH pada komitmen ini (dua akar masalah)
- **Tingkat Keparahan:** **K-2 (Tinggi)**
- **Lokasi Berkas & Baris:** `.github/workflows/ci.yml:257-258` dan `:275-276` (gerbang), `aplikasi/alat/periksa-semua.sh` (2 baris hilang), `docs/uji/PAKET_AUDIT_F10_3_AGEN.md:118,131` + `docs/uji/PROMPT_AGEN_2_FRONTEND.md:26,31` (4 rujukan mati)
- **Deskripsi Masalah:** dari 126 perintah CI yang saya jalankan, **6 gagal karena cacat nyata**:

  | Gerbang CI | Exit | Akar masalah |
  |---|---|---|
  | `periksa-paritas-ci.py` (#69) | 1 | `periksa-header.py` tidak dicerminkan di `periksa-semua.sh` |
  | `periksa-paritas-ci.py --uji-diri` (#70) | 1 | sama (baseline uji-diri ikut merah) |
  | `periksa-rujukan.py` (#75) | 1 | 4 rujukan mati di paket audit |
  | `periksa-rujukan.py --uji-diri` (#76) | 1 | sama (3 dari 5 kasus uji-diri gagal) |
  | `periksa-bersih.py` (#103) | 1 | **cascade** — ia menjalankan `periksa-rujukan.py` di pohon bersih |
  | `periksa-bersih.py --uji-diri` (#118) | 1 | **cascade** yang sama |

- **Langkah / Perintah Reproduksi:**
  ```bash
  python3 alat/periksa-paritas-ci.py; echo $?
  # PERIKSA PARITAS CI — 126 perintah CI dibandingkan dengan skrip lokal
  # HASIL: GAGAL — perintah CI tidak tercermin di periksa-semua.sh:
  #   [X] python3 alat/periksa-header.py
  #   [X] python3 alat/periksa-header.py --uji-diri
  # 1
  grep -c "periksa-header" aplikasi/alat/periksa-semua.sh   # → 0
  grep -n "periksa-header" .github/workflows/ci.yml          # → 289, 290

  python3 alat/periksa-rujukan.py; echo $?
  # PERIKSA RUJUKAN — 79 dokumen · 3842 rujukan · 2 berkas dipensiun diakui
  # HASIL: GAGAL — 4 rujukan mati
  # 1

  python3 alat/periksa-bersih.py; echo $?
  #   [X] alat/periksa-rujukan.py: MENOLAK (kode 1)
  # HASIL: GAGAL — 1 pemeriksa menolak di pohon bersih: alat/periksa-rujukan.py
  # 1
  ```
  Kedua perintah paritas berada di blok `run: |` langkah *"Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras"* (`ci.yml:248`); `grep -n "set +e\|shell:" .github/workflows/ci.yml` → **kosong**, jadi tidak ada pelemahan shell. *Yang terverifikasi di sandbox: exit code 1. Bahwa langkah GitHub akan merah adalah inferensi dari shell default runner Linux (`bash -e`); GitHub Actions tidak saya jalankan dari sini.*
- **Dampak Bisnis:** klaim paket audit "**126 gerbang CI aktif**" benar secara jumlah (saya buktikan `len(GERBANG_WAJIB) = 126` dan `perintah_ci(ci.yml) = 126`) tetapi pipeline **tidak bisa hijau**. Selama CI merah, 120 gerbang lain (rahasia, header, audit dependensi, mutasi, RLS) praktis tidak menjaga apa pun, dan tim akan terbiasa mengabaikan merah.
- **Rekomendasi Solusi:** (1) tambahkan ke `aplikasi/alat/periksa-semua.sh` di sebelah `periksa-rahasia.py` (baris 157-158):
  ```bash
  (cd "$REPO" && python3 alat/periksa-header.py
  python3 alat/periksa-header.py --uji-diri
  ```
  (2) perbaiki 4 rujukan mati sesuai F10-A3-04. Lalu jalankan ulang ketiganya sampai `HASIL: LOLOS`.

---

### F10-A3-04 — Paket audit F10 sendiri memuat 4 perintah yang menunjuk berkas tidak ada
- **Tingkat Keparahan:** **K-2 (Tinggi)**
- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md:118` dan `:131`; `docs/uji/PROMPT_AGEN_2_FRONTEND.md:26` dan `:31`
- **Deskripsi Masalah:** paket audit yang dibagikan ke Agen 2 menyuruh menjalankan dua berkas yang tidak ada di repo:
  ```
  $ sed -n '118p;131p' docs/uji/PAKET_AUDIT_F10_3_AGEN.md
  python3 aplikasi/alat/periksa-kontras.py
  node alat/uji-mutasi-app.mjs

  $ test -e aplikasi/alat/periksa-kontras.py && echo ADA || echo "TIDAK ADA"
  TIDAK ADA
  $ test -e alat/uji-mutasi-app.mjs && echo ADA || echo "TIDAK ADA"
  TIDAK ADA
  ```
  Jalur yang benar adalah **`aplikasi/alat/uji-kontras.py`** dan **`aplikasi/alat/uji-mutasi-app.mjs`** (persis yang dipakai `ci.yml` pada perintah #6 dan #125).
- **Langkah / Perintah Reproduksi:** `python3 alat/periksa-rujukan.py` → lihat 4 baris `[X]` di atas.
- **Dampak Bisnis:** Agen 2 yang patuh pada paket akan menerima dua galat "berkas tidak ditemukan", kehilangan bukti kontras WCAG AAA dan bukti mutasi kode aplikasi, lalu berisiko menuliskan "tidak dapat diverifikasi" untuk dua area keamanan penting — atau lebih buruk, menyimpulkan cacat yang tidak ada. Ini juga penyebab tidak langsung 4 gerbang CI merah (F10-A3-03).
- **Rekomendasi Solusi:** ganti keempat baris menjadi `python3 aplikasi/alat/uji-kontras.py` dan `node aplikasi/alat/uji-mutasi-app.mjs`, lalu jalankan `python3 alat/periksa-rujukan.py` sampai hijau.

---

### F10-A3-05 — Denyut harian (T10-08) tidak pernah dijadwalkan di mana pun
- **Tingkat Keparahan:** **K-2 (Tinggi)**
- **Lokasi Berkas & Baris:** `supabase/migrations/0082_denyut_harian_pembersih.sql:325-340`, `.github/workflows/*.yml` (nol cron selain cadangan), `docs/ROADMAP.md:123`
- **Deskripsi Masalah:** fungsi `public.denyut_harian()` dibuat dan di-`grant`, tetapi **tidak ada yang memanggilnya secara otomatis**:
  ```bash
  $ grep -n "cron:" .github/workflows/*.yml
  .github/workflows/cadangan.yml:19:    - cron: '0 19 * * 6'      # ← SATU-SATUNYA cron di repo
  $ grep -rn "denyut" .github/workflows/
  TIDAK ADA — denyut tidak dijadwalkan di GitHub Actions sama sekali
  ```
  Blok pg_cron di migrasi 0082 **hanya membuat ekstensi**, tidak pernah mendaftarkan jadwal:
  ```sql
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    -- Pada Supabase hosted yang memiliki pg_cron, jadwal otomatis dapat didaftarkan.
  end if;
  ```
  Tidak ada `cron.schedule(...)` di seluruh repo.
- **Dampak Bisnis:** dua janji operasional gugur sekaligus. (a) `docs/teknis/PEMULIHAN.md:12` menyebut "RPO < 24 Jam (**Harian Denyut**)" — tidak ada denyut harian apa pun, jadi RPO efektif = 7 hari (cadangan mingguan) untuk skema, dan tak berhingga untuk data (F10-A3-02). (b) `docs/ROADMAP.md:123` menyebut mitigasi "proyek gratis tidur setelah 7 hari → dijadwalkan denyut harian (T10-08)" — mitigasi itu tidak terpasang, sehingga proyek Supabase gratis **tetap akan dijeda**, dan `sebar-skema.yml:19-21` sendiri sudah memperingatkan gejala ini. (c) Pembersihan log sementara tidak pernah berjalan → tabel log membengkak tanpa batas.
- **Rekomendasi Solusi:** daftarkan jadwal nyata — `select cron.schedule('denyut-harian', '0 19 * * *', 'select public.denyut_harian()')` di migrasi baru (dengan penjaga `if exists … pg_cron`), **atau** tambahkan alur GitHub Actions ber-`cron` harian yang memanggil RPC itu. Tambahkan gerbang CI yang menolak bila `denyut_harian` tidak terjadwal.

---

### F10-A3-06 — CSP produksi mengizinkan `script-src 'unsafe-inline'` yang tidak diperlukan
- **Tingkat Keparahan:** **K-2 (Tinggi)**
- **Lokasi Berkas & Baris:** `aplikasi/public/_headers:24`
- **Deskripsi Masalah:** `script-src 'self' 'unsafe-inline'` membuat CSP kehilangan fungsi utamanya sebagai penahan XSS — satu lubang injeksi saja (mis. nama menu atau catatan pesanan yang lolos sanitasi) cukup untuk menjalankan skrip penyerang di origin kasir. Tidak ada *nonce*/hash di berkas ini, jadi `'unsafe-inline'` benar-benar aktif. Dan ia **tidak dibutuhkan**:
  ```bash
  $ grep -n "<script" aplikasi/index.html
  14:    <script type="module" src="/src/main.tsx"></script>
  ```
  Hanya satu skrip modul eksternal, nol skrip inline; `grep -n "importScripts\|eval" aplikasi/public/sw.js` → kosong. Direktif lain juga longgar: `img-src … https:` (semua host HTTPS) dan `connect-src … https://*.workers.dev` (subdomain Worker milik siapa pun).
- **Dampak Bisnis:** aplikasi kasir memegang PIN staf, pembayaran, dan data pribadi pelanggan lintas tenant. XSS di origin ini = pencurian sesi `owner_pusat` dan penarikan data tenant lain **tanpa perlu menembus RLS sama sekali**.
- **Rekomendasi Solusi:** buang `'unsafe-inline'` dari `script-src` (pertahankan di `style-src` bila CSS-in-JS membutuhkannya), persempit `img-src` menjadi `'self' data: blob:` + domain yang benar-benar dipakai, dan ganti `https://*.workers.dev` dengan host Worker spesifik milik Lee. **Penting:** `keamanan-header.test.ts` saat ini **mengunci** `img-src 'self' data: blob: https:` sebagai wajib, jadi perketat assertion itu bersamaan — kalau tidak, pengetatan justru akan memerahkan Vitest.

---

### F10-A3-07 — Tidak ada satu gerbang pun yang menangkap `unsafe-eval`, `connect-src *`, atau penghapusan `upgrade-insecure-requests`/`form-action`
- **Tingkat Keparahan:** **K-3 (Sedang)**
- **Lokasi Berkas & Baris:** `alat/periksa-header.py:126-158` dan `:186-232`; `aplikasi/src/lib/keamanan-header.test.ts:29-57`
- **Deskripsi Masalah:** saya jalankan **assertion asli kedua pemeriksa** terhadap CSP yang dirusak. Untuk `periksa-header.py` saya panggil fungsinya langsung atas salinan di `/tmp` (repo tidak disentuh); untuk Vitest saya evaluasi operator `toContain`/`not.toContain` yang persis dipakai berkas uji itu:
  ```
  # periksa-header.py — fungsi periksa_isi_headers() atas salinan /tmp
  LOLOS (TIDAK TERDETEKSI!) :: HSTS: kata 'preload' dihapus
  LOLOS (TIDAK TERDETEKSI!) :: HSTS: max-age 31536000 -> 60
  LOLOS (TIDAK TERDETEKSI!) :: CSP: 'unsafe-eval' DITAMBAHKAN ke script-src
  LOLOS (TIDAK TERDETEKSI!) :: CSP: connect-src dibuka lebar ke *
  LOLOS (TIDAK TERDETEKSI!) :: CSP: default-src 'self' -> default-src *
  LOLOS (TIDAK TERDETEKSI!) :: CSP: upgrade-insecure-requests dihapus
  TERTANGKAP :: X-Content-Type-Options: nosniff dihapus
  TERTANGKAP :: CSP: frame-ancestors 'none' -> 'self'

  # keamanan-header.test.ts — evaluasi assertion aslinya
  TES TETAP HIJAU (!) :: TAMBAH 'unsafe-eval' ke script-src
  TES TETAP HIJAU (!) :: connect-src dibuka ke *
  TES TETAP HIJAU (!) :: upgrade-insecure-requests dihapus
  TES TETAP HIJAU (!) :: form-action dihapus
  ```
  Penyebabnya: Vitest memakai `expect(csp).toContain("script-src 'self'")` — assertion *substring*, sehingga `'self' 'unsafe-inline' 'unsafe-eval'` tetap mengandung `script-src 'self'` dan lolos; dan `periksa-header.py` hanya memeriksa wildcard pada `script-src` (baris 155), tidak pada `default-src`/`connect-src`.
  **Koreksi jujur atas laporan sementara saya:** `preload` dan `max-age` **memang dijaga** — oleh Vitest, yang menegaskan string `max-age=31536000; includeSubDomains; preload` secara utuh. Jadi celah yang benar-benar tak terjaga hanya empat hal di atas.
- **Dampak Bisnis:** konfigurasi hari ini memenuhi mandat, tetapi regresi paling berbahaya (`unsafe-eval`) bisa masuk lewat PR mana pun tanpa satu pun lampu merah.
- **Rekomendasi Solusi:** di `periksa-header.py` tambahkan penolakan `'unsafe-eval'`/`'unsafe-inline'` pada `script-src`, penolakan `*` pada `default-src`/`connect-src`/`img-src`, dan pemeriksaan keberadaan `upgrade-insecure-requests` + `form-action`; lengkapi mutasi uji-dirinya untuk tiap kasus.

---

### F10-A3-08 — Kontrol header keamanan tidak punya dokumen kebijakan sama sekali
- **Tingkat Keparahan:** **K-3 (Sedang)**
- **Lokasi Berkas & Baris:** `aplikasi/public/_headers:1`, `alat/periksa-header.py:2`, `docs/ROADMAP.md:2012` — semuanya merujuk `docs/KEAMANAN.md §16`
- **Deskripsi Masalah:** ketiga berkas itu menyebut `docs/KEAMANAN.md §16` sebagai rujukan pengikat, tetapi §16 berjudul **"Aturan untuk sesi agent berikutnya"** dan tidak menyebut header HTTP sama sekali:
  ```bash
  $ grep -n -i "content-security\|x-frame-options\|strict-transport\|_headers\|CSP" \
      docs/TECH_SPEC.md docs/PRD.md docs/KEAMANAN.md
  (kosong — tidak ada satu pun kecocokan di ketiga dokumen)
  ```
  Jadi kontrol setingkat platform (T10-14) **tidak punya kebijakan tertulis**: tidak ada kriteria terima, tidak ada daftar direktif wajib, dan tidak ada yang bisa dijadikan acuan oleh agen berikutnya.
- **Dampak Bisnis:** tanpa kebijakan tertulis, pengetatan atau pelonggaran CSP jadi keputusan ad-hoc per-PR. Untuk SaaS multi-tenant yang menyasar ratusan gerai, ini justru area yang paling butuh spesifikasi tetap.
- **Rekomendasi Solusi:** tulis satu bagian baru di `docs/KEAMANAN.md` (mis. §17 "Header Keamanan Peramban") yang memuat daftar direktif wajib, alasan tiap direktif, dan larangan `unsafe-eval`; arahkan ketiga rujukan ke bagian itu dan catat di `docs/DECISIONS_LOG.md` ( Area: Kunci & Penerapan) sebagaimana diwajibkan `docs/ROADMAP.md:2016`.

---

### F10-A3-09 — Aksi GitHub Actions dipatok ke *tag*, bukan SHA, dan versi `checkout` tidak seragam
- **Tingkat Keparahan:** **K-3 (Sedang)**
- **Lokasi Berkas & Baris:** `.github/workflows/cadangan.yml:39,42,47,70`; `ci.yml:23,33`; `sebar-halaman.yml:44,47`; `sebar-skema.yml:53,56`
- **Deskripsi Masalah:**
  ```
  cadangan.yml:39:        uses: actions/checkout@v4      ← v4
  cadangan.yml:42:        uses: actions/setup-node@v5
  cadangan.yml:47:        uses: actions/setup-python@v4
  cadangan.yml:70:        uses: actions/upload-artifact@v4
  ci.yml:23:              uses: actions/checkout@v5      ← v5
  ci.yml:33 / sebar-*:    uses: actions/setup-node@v5
  ```
  Semua dipatok ke *tag* yang bisa digeser, bukan ke SHA komitmen. Alur-alur inilah yang memegang `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, dan `CLOUDFLARE_API_TOKEN`. Selain itu `checkout` tidak seragam (v4 di cadangan, v5 di tiga lainnya) — tanda tidak ada kebijakan pemakuan.
- **Dampak Bisnis:** satu *tag* yang dibajak di hulu cukup untuk mencuri token deploy/token database seluruh penyewa. Sisi baiknya sudah ada: `permissions: contents: read` di keempat alur (prinsip hak paling kecil) dan `npx --yes supabase@2.117.0` yang dipatok versi penuh.
- **Rekomendasi Solusi:** pakai pin SHA penuh (`actions/checkout@<40-hex>` + komentar versi), samakan `checkout` ke satu versi, dan tambahkan gerbang CI yang menolak `uses:` berbentuk *tag*. Pertimbangkan `pin-github-action` di CI.

---

### F10-A3-10 — Pemindai rahasia hanya memindai pohon HEAD, bukan riwayat Git
- **Tingkat Keparahan:** **K-3 (Sedang)**
- **Lokasi Berkas & Baris:** `alat/periksa-rahasia.py:48`
- **Deskripsi Masalah:** `subprocess.run(["git", "-C", str(akar), "ls-files"], …)` — hanya berkas yang terlacak **saat ini**. Kunci yang pernah di-*commit* lalu dihapus tetap hidup di riwayat dan tetap bisa diambil dengan `git log -p`/`git cat-file`. Tidak ada pemindaian riwayat (`git rev-list --all` / `gitleaks`/`trufflehog`).
  ```bash
  $ grep -n "ls-files\|rev-list\|log -p" alat/periksa-rahasia.py
  48:    keluaran = subprocess.run(["git", "-C", str(akar), "ls-files"], …).stdout
  ```
  *Catatan jujur:* checkout audit ini hanya punya 1 commit (`git rev-list --count HEAD` → `1`), jadi saya **tidak bisa** membuktikan ada kunci yang tertinggal di riwayat proyek sebenarnya. Yang saya buktikan adalah **cakupan pemeriksanya**, bukan keberadaan kebocoran.
- **Dampak Bisnis:** rotasi kunci yang "sudah dibersihkan" bisa memberi rasa aman palsu. Untuk repo yang dijadikan publik sejak 2026-09-20 (catatan `ci.yml:3-4`), riwayat yang bocor sama berbahayanya dengan HEAD yang bocor.
- **Rekomendasi Solusi:** tambahkan langkah pemindaian riwayat (mis. `gitleaks detect --log-opts "--all"` atau `trufflehog git file://. --since-commit <awal>`) sebagai gerbang CI mingguan, dan catat hasilnya di `docs/KEAMANAN.md`.

---

### F10-A3-11 — Angka bukti "47/47" ditulis *hardcoded* pada keluaran latihan; dokumen masih menyebut 46
- **Tingkat Keparahan:** **K-4 (Rendah / Saran)**
- **Lokasi Berkas & Baris:** `alat/eksekusi-latihan-insiden.mjs:677`; bandingkan `STATUS.md:19`, `PROJECT_STATE.md:19`, `docs/ROADMAP.md:1974`
- **Deskripsi Masalah:** baris 677 mencetak literal `'SEMUA AKTIF (47/47)'` padahal `hasil.paritas.totalTabel` dihitung dinamis (baris 675-676 sudah dinamis, dan baris 699 pada mode laporan juga dinamis):
  ```js
  console.log(`    - Status RLS             : ${hasil.paritas.rlsAktifSemua ? 'SEMUA AKTIF (47/47)' : 'TIDAK LENGKAP'}`)
  ```
  Tiga dokumen masih menulis "**46 tabel** terverifikasi, 192 baris" sementara hasil eksekusi hari ini 47 tabel — walau dokumen itu menandai diri "angka saat itu".
- **Dampak Bisnis:** bukti audit bisa menyesatkan di masa depan; bertentangan dengan semangat `alat/periksa-angka-bukti.py` yang justru lulus.
- **Rekomendasi Solusi:** ganti menjadi `` `SEMUA AKTIF (${hasil.paritas.totalTabel}/${hasil.paritas.totalTabel})` `` dan selaraskan angka tabel di ketiga dokumen.

---

### F10-A3-12 — Rujukan bab Buku Insiden untuk Dril 4 salah
- **Tingkat Keparahan:** **K-4 (Rendah / Saran)**
- **Lokasi Berkas & Baris:** `alat/pulihkan-cadangan.sh` (teks bantuan, dril ke-4); bandingkan `docs/teknis/BUKU_INSIDEN.md`
- **Deskripsi Masalah:** bantuan skrip menulis dril 4 sebagai *"Rekonsiliasi Ringkasan Harian & Privasi UU PDP (§15 / ART-13 & ART-14)"*, tetapi:
  ```
  BUKU_INSIDEN.md:184  ## 10. Cadangan & pemulihan (latihan sebelum pilot)   ← lokasi dril
  BUKU_INSIDEN.md:104  ## 6.  Data pelanggan bocor (kewajiban UU PDP …)      ← lokasi privasi
  BUKU_INSIDEN.md:271  ## 15. Log Insiden (selalu diisi)                     ← yang dirujuk, SALAH
  ```
  §15 adalah tabel log insiden, bukan rekonsiliasi maupun privasi.
- **Dampak Bisnis:** operator yang mengikuti petunjuk saat insiden nyata akan membuka bab yang salah di bawah tekanan waktu.
- **Rekomendasi Solusi:** ubah rujukan menjadi `§6 & §10`.

---

### 3.13 Yang BUKAN temuan (artefak lingkungan audit — dinyatakan eksplisit)

Agar tidak ada yang dihukum untuk hal yang bukan cacat proyek, tiga dari sembilan kegagalan lokal saya **tidak** saya masukkan sebagai temuan:

| Gerbang | Exit | Alasan bukan cacat proyek | Bukti |
|---|---|---|---|
| `npm run cek:supabase` (#10) | 1 | Sandbox audit **tidak punya jalur keluar jaringan** ke `*.supabase.co` — persis seperti ditulis komentar `ci.yml:70-71` | Saya jalankan ulang dengan env yang sama persis seperti `ci.yml` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`): `/auth/v1/health → HTTP 0 (33 ms) fetch failed`, `/rest/v1/ → HTTP 0`. Status 0 = gagal jaringan, **bukan** 401 (kunci salah). |
| `periksa-paket.py` (#107) | 1 | Checkout audit ini adalah **snapshot 1 commit tanpa induk**, sehingga pemeriksa tidak bisa menelusuri riwayat penulis paket | `git rev-list --count HEAD` → `1`; `git log --format="%h %p %s" -1` → kolom induk **kosong**. Semua 68 pelanggaran berbunyi sama: *"penulis terakhir berinduk ?"*. Commit targetnya sendiri ada (`git cat-file -e 597cc77e` → ADA), jadi ini murni soal riwayat yang terpangkas. |
| `periksa-paket.py --uji-diri` (#108) | 1 | Sama — hanya kasus *baseline* yang gagal, keempat kasus mutasi tetap tertangkap | `HASIL: GAGAL — 1 kasus uji-diri tidak sesuai harapan` |

**Kesimpulan yang jujur:** 9 gagal = **6 cacat nyata** + **3 artefak lingkungan**.

---

## 4. Kesimpulan & Rekomendasi untuk Pemilik Platform (Lee)

**Verdict: PERLU PERBAIKAN.** Area Infrastruktur, Ketahanan Sistem & SOP Bencana **belum siap** dinyatakan lulus, dan saya tidak merekomendasikan lanjut ke Fase 11 sebelum F10-A3-01, F10-A3-02, F10-A3-03, dan F10-A3-04 ditutup.

**Yang sudah kuat dan terverifikasi nyata.** 117 dari 126 gerbang CI hijau saat dijalankan sungguhan (1.431 detik, Lampiran A); nol `continue-on-error`/`|| true`/`if:` di keempat alur kerja; empat *harness* uji-diri menolak 41 + 5 + 7 + 5 mutasi yang saya periksa isinya dan memang mutasi nyata; siklus dump → gzip → AES-256 → dekripsi → pulih *clean slate* lulus dengan paritas 47 tabel / 192 baris / RLS 47/47 / FK utuh dalam 3,57 detik; empat dril Buku Insiden memanggil RPC asli; `npm audit` **0 dari 322 paket**; nol kunci vendor bocor di 2.862 berkas terlacak; `_headers` terbukti tersalin ke `dist/` saat build dan mekanisme `_headers` memang didukung Workers Static Assets dengan 387/2.000 karakter per baris serta 8/100 aturan; dan seluruh klaim T-016 (5× brute-force, 12× per perangkat, tangga peran atas, Rp 0) cocok dengan SQL-nya. Disiplin pengujian proyek ini di atas rata-rata dan layak dipertahankan.

**Yang membatalkan kelulusan.** Semua bukti hijau di atas menguji *mekanisme*; *data* yang dilindungi mekanisme itu tidak pernah benar-benar dicadangkan, dan pipeline-nya sendiri sedang merah. Urutan pengerjaan yang saya sarankan:

1. **Hari ini juga — K-1, ±1 jam.** Hapus *fallback* kunci di `cadangan.yml:35` dan `cadangan.sh:225`; pasang `KUNCI_ENKRIPSI_CADANGAN` sebagai secret GitHub yang sesungguhnya; **rotasi kunci**; perlakukan seluruh artefak `.enc` lama (retensi 90 hari) sebagai sudah bocor; tambahkan pola deteksi *passphrase* literal ke `periksa-rahasia.py`.
2. **Hari ini juga — K-2, ±15 menit, langsung memerahkan-ke-hijau CI.** Tambahkan dua baris `periksa-header.py` ke `aplikasi/alat/periksa-semua.sh` (F10-A3-03) dan perbaiki empat rujukan mati di `PAKET_AUDIT_F10_3_AGEN.md` + `PROMPT_AGEN_2_FRONTEND.md` (F10-A3-04). Enam gerbang kembali hijau.
3. **Minggu ini — K-1.** Buat cadangan produksi nyata: wajibkan `SUPABASE_DB_URL` dengan `exit 1`, pasang `postgresql-client` di job cadangan, hapus fallback PGlite dari `dump-dan-enkripsi`, beri penanda sumber pada artefak, dan salin ke penyimpanan di luar GitHub.
4. **Minggu ini — K-2.** Jadwalkan `denyut_harian()` secara nyata (pg_cron `cron.schedule` atau alur Actions ber-`cron` harian), lalu koreksi tabel RPO/RTO di `docs/teknis/PEMULIHAN.md` agar cocok dengan kenyataan.
5. **Awal Fase 11 — K-2/K-3.** Buang `'unsafe-inline'` dari `script-src`, persempit `img-src`/`connect-src` (sambil memperbarui assertion Vitest yang menguncinya), pertajam `periksa-header.py` untuk `unsafe-eval`/`connect-src *`/`upgrade-insecure-requests`/`form-action`, tulis kebijakan header di `docs/KEAMANAN.md`, paksa pin SHA untuk seluruh `uses:`, dan tambahkan pemindaian riwayat Git.
6. **Bukti yang belum bisa saya tutup dari sandbox.** Kepatuhan header secara *live* di `https://resto-barokah.fatrizmubarok.workers.dev` **tidak teruji** (`curl: (35) SSL_ERROR_SYSCALL`, tanpa jalur keluar HTTPS). Minta seseorang menjalankan
   `curl -sI https://resto-barokah.fatrizmubarok.workers.dev | grep -iE 'content-security|strict-transport|x-frame|x-content-type'`
   dari jaringan normal dan lampirkan hasilnya sebagai bukti penutup T10-14.

Seluruh temuan di atas dapat direproduksi dengan perintah yang tercantum di tiap butir. Pemeriksaan dilakukan **hanya-baca** terhadap kode: `git status --porcelain` kosong sebelum laporan ini ditulis, tidak ada berkas kode yang saya ubah, dan tidak ada commit selain penambahan laporan ini sendiri.

---

## Lampiran A — Hasil eksekusi seluruh 126 perintah CI

Dijalankan berurutan pada sandbox audit (2 vCPU / 4 GB, Python 3.11.2, Node v22.22.3, npm 10.9.8),
dengan `working-directory` disamakan persis seperti `.github/workflows/ci.yml`
(perintah #1-5, 8, 9, 10 berjalan di `aplikasi/`, sisanya di akar repo).

**Ringkasan: 126 perintah · 117 LULUS · 9 GAGAL · total 1431 detik (23.8 menit).**

| # | Perintah | cwd | Exit | Detik | Keterangan |
|---|---|---|---|---|---|
| 1 | `npm ci` | `aplikasi` | ✅ 0 | 3.0 |  |
| 2 | `npm run format:check` | `aplikasi` | ✅ 0 | 7.2 |  |
| 3 | `npm run lint` | `aplikasi` | ✅ 0 | 7.1 |  |
| 4 | `npm run typecheck` | `aplikasi` | ✅ 0 | 12.3 |  |
| 5 | `npm test` | `aplikasi` | ✅ 0 | 97.8 |  |
| 6 | `node aplikasi/alat/uji-mutasi-app.mjs` | `.` | ✅ 0 | 198.6 |  |
| 7 | `node aplikasi/alat/uji-mutasi-app.mjs --uji-diri` | `.` | ✅ 0 | 1.2 |  |
| 8 | `npm run build` | `aplikasi` | ✅ 0 | 15.5 |  |
| 9 | `npm audit --audit-level=low` | `aplikasi` | ✅ 0 | 0.4 |  |
| 10 | `npm run cek:supabase` | `aplikasi` | ❌ 1 | 0.2 | artefak lingkungan: sandbox tanpa jalur keluar jaringan (bukan cacat) |
| 11 | `npm ci --prefix alat` | `.` | ✅ 0 | 0.8 |  |
| 12 | `node alat/uji-sql.mjs` | `.` | ✅ 0 | 6.5 |  |
| 13 | `python3 alat/uji-mutasi-0012.py` | `.` | ✅ 0 | 78.2 |  |
| 14 | `python3 alat/uji-mutasi-0014.py` | `.` | ✅ 0 | 89.2 |  |
| 15 | `python3 alat/uji-mutasi-0015.py` | `.` | ✅ 0 | 113.3 |  |
| 16 | `python3 alat/uji-mutasi-0016.py` | `.` | ✅ 0 | 71.9 |  |
| 17 | `python3 alat/uji-mutasi-0017.py` | `.` | ✅ 0 | 41.6 |  |
| 18 | `python3 alat/uji-mutasi-0018.py` | `.` | ✅ 0 | 36.3 |  |
| 19 | `python3 alat/uji-mutasi-0019.py` | `.` | ✅ 0 | 13.8 |  |
| 20 | `python3 alat/uji-mutasi-0041.py` | `.` | ✅ 0 | 15.8 |  |
| 21 | `python3 alat/uji-mutasi-0042.py` | `.` | ✅ 0 | 13.2 |  |
| 22 | `python3 alat/uji-mutasi-0043.py` | `.` | ✅ 0 | 13.2 |  |
| 23 | `python3 alat/uji-mutasi-0045.py` | `.` | ✅ 0 | 16.0 |  |
| 24 | `python3 alat/uji-mutasi-0046.py` | `.` | ✅ 0 | 15.3 |  |
| 25 | `python3 alat/uji-mutasi-0047.py` | `.` | ✅ 0 | 15.5 |  |
| 26 | `python3 alat/uji-mutasi-0048.py` | `.` | ✅ 0 | 15.9 |  |
| 27 | `python3 alat/uji-mutasi-0049.py` | `.` | ✅ 0 | 15.8 |  |
| 28 | `python3 alat/uji-mutasi-0050.py` | `.` | ✅ 0 | 15.5 |  |
| 29 | `python3 alat/uji-mutasi-0051.py` | `.` | ✅ 0 | 16.0 |  |
| 30 | `python3 alat/uji-mutasi-0052.py` | `.` | ✅ 0 | 15.1 |  |
| 31 | `python3 alat/uji-mutasi-0053.py` | `.` | ✅ 0 | 15.0 |  |
| 32 | `python3 alat/uji-mutasi-0054.py` | `.` | ✅ 0 | 16.7 |  |
| 33 | `python3 alat/uji-mutasi-0009.py` | `.` | ✅ 0 | 14.7 |  |
| 34 | `python3 alat/uji-mutasi-0021.py` | `.` | ✅ 0 | 9.8 |  |
| 35 | `python3 alat/uji-mutasi-0022.py` | `.` | ✅ 0 | 28.8 |  |
| 36 | `python3 alat/uji-mutasi-0024.py` | `.` | ✅ 0 | 13.2 |  |
| 37 | `python3 alat/uji-mutasi-0025.py` | `.` | ✅ 0 | 8.4 |  |
| 38 | `python3 alat/uji-mutasi-0028.py` | `.` | ✅ 0 | 22.5 |  |
| 39 | `python3 alat/uji-mutasi-0029.py` | `.` | ✅ 0 | 20.3 |  |
| 40 | `python3 alat/uji-mutasi-0030.py` | `.` | ✅ 0 | 10.5 |  |
| 41 | `python3 alat/uji-mutasi-0031.py` | `.` | ✅ 0 | 10.9 |  |
| 42 | `python3 alat/uji-mutasi-0032.py` | `.` | ✅ 0 | 17.9 |  |
| 43 | `python3 alat/uji-mutasi-0033.py` | `.` | ✅ 0 | 6.7 |  |
| 44 | `python3 alat/uji-mutasi-0035.py` | `.` | ✅ 0 | 8.6 |  |
| 45 | `python3 alat/uji-mutasi-0036.py` | `.` | ✅ 0 | 8.4 |  |
| 46 | `python3 alat/uji-mutasi-0037.py` | `.` | ✅ 0 | 8.3 |  |
| 47 | `python3 alat/uji-mutasi-0038.py` | `.` | ✅ 0 | 8.5 |  |
| 48 | `python3 alat/uji-mutasi-0039.py` | `.` | ✅ 0 | 15.2 |  |
| 49 | `python3 alat/uji-mutasi-0040.py` | `.` | ✅ 0 | 10.4 |  |
| 50 | `python3 -m pip install --quiet --break-system-packages pgserver "psycopg[binary]"` | `.` | ✅ 0 | 2.6 |  |
| 51 | `python3 alat/uji-konkuren.py` | `.` | ✅ 0 | 20.7 |  |
| 52 | `python3 alat/uji-konkuren.py --uji-diri` | `.` | ✅ 0 | 0.2 |  |
| 53 | `python3 alat/uji-konkuren-0022.py` | `.` | ✅ 0 | 15.5 |  |
| 54 | `python3 alat/uji-konkuren-a04.py` | `.` | ✅ 0 | 11.5 |  |
| 55 | `python3 alat/periksa-keamanan-sql.py` | `.` | ✅ 0 | 2.4 |  |
| 56 | `python3 alat/periksa-keamanan-sql.py --uji-diri` | `.` | ✅ 0 | 35.1 |  |
| 57 | `python3 alat/periksa-maraton.py` | `.` | ✅ 0 | 0.0 |  |
| 58 | `python3 alat/periksa-maraton.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 59 | `node alat/uji-edge-pin.mjs` | `.` | ✅ 0 | 0.1 |  |
| 60 | `node alat/uji-edge-verifikasi-pelanggan.mjs` | `.` | ✅ 0 | 0.1 |  |
| 61 | `node alat/uji-edge-akhiri-sesi.mjs` | `.` | ✅ 0 | 0.1 |  |
| 62 | `python3 _sistem/validate_system.py` | `.` | ✅ 0 | 0.2 |  |
| 63 | `python3 alat/periksa-fungsi-pin.py` | `.` | ✅ 0 | 0.0 |  |
| 64 | `python3 alat/periksa-roadmap.py` | `.` | ✅ 0 | 0.1 |  |
| 65 | `python3 alat/periksa-roadmap.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 66 | `python3 alat/periksa-fondasi-independen.py` | `.` | ✅ 0 | 0.4 |  |
| 67 | `python3 alat/audit-independen.py --uji-diri` | `.` | ✅ 0 | 2.0 |  |
| 68 | `python3 alat/ci_target.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 69 | `python3 alat/periksa-paritas-ci.py` | `.` | ❌ 1 | 0.0 | CACAT NYATA — F10-A3-03 |
| 70 | `python3 alat/periksa-paritas-ci.py --uji-diri` | `.` | ❌ 1 | 0.0 | CACAT NYATA — F10-A3-03 |
| 71 | `python3 alat/siapkan-pemeriksaan.py --uji-diri` | `.` | ✅ 0 | 0.2 |  |
| 72 | `python3 alat/uji-kirim-laporan.py` | `.` | ✅ 0 | 4.9 |  |
| 73 | `python3 alat/periksa-panduan.py` | `.` | ✅ 0 | 0.0 |  |
| 74 | `python3 alat/periksa-panduan.py --uji-diri` | `.` | ✅ 0 | 5.3 |  |
| 75 | `python3 alat/periksa-rujukan.py` | `.` | ❌ 1 | 0.1 | CACAT NYATA — F10-A3-04 |
| 76 | `python3 alat/periksa-rujukan.py --uji-diri` | `.` | ❌ 1 | 1.5 | CACAT NYATA — F10-A3-04 |
| 77 | `python3 alat/periksa-temuan-audit.py` | `.` | ✅ 0 | 0.0 |  |
| 78 | `python3 alat/periksa-temuan-audit.py --uji-diri` | `.` | ✅ 0 | 2.4 |  |
| 79 | `python3 alat/periksa-buku-uji.py` | `.` | ✅ 0 | 0.0 |  |
| 80 | `python3 alat/periksa-buku-uji.py --uji-diri` | `.` | ✅ 0 | 1.2 |  |
| 81 | `python3 alat/tambah-uji.py --uji-diri` | `.` | ✅ 0 | 0.4 |  |
| 82 | `python3 alat/peta-ui.py` | `.` | ✅ 0 | 0.1 |  |
| 83 | `python3 alat/peta-ui.py --uji-diri` | `.` | ✅ 0 | 0.2 |  |
| 84 | `python3 aplikasi/alat/periksa-bahasa.py` | `.` | ✅ 0 | 0.0 |  |
| 85 | `python3 aplikasi/alat/periksa-bahasa.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 86 | `python3 aplikasi/alat/periksa-arah.py` | `.` | ✅ 0 | 0.0 |  |
| 87 | `python3 aplikasi/alat/periksa-arah.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 88 | `python3 alat/periksa-bantuan.py` | `.` | ✅ 0 | 0.0 |  |
| 89 | `python3 alat/periksa-bantuan.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 90 | `python3 alat/periksa-audit.py` | `.` | ✅ 0 | 0.0 |  |
| 91 | `python3 alat/periksa-audit.py --uji-diri` | `.` | ✅ 0 | 0.6 |  |
| 92 | `python3 alat/periksa-matriks-izin.py` | `.` | ✅ 0 | 2.2 |  |
| 93 | `python3 alat/periksa-matriks-izin.py --uji-diri` | `.` | ✅ 0 | 4.6 |  |
| 94 | `python3 alat/review-pr.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 95 | `python3 aplikasi/alat/periksa-kerapatan.py` | `.` | ✅ 0 | 0.3 |  |
| 96 | `python3 aplikasi/alat/periksa-kerapatan.py --uji-diri` | `.` | ✅ 0 | 2.8 |  |
| 97 | `python3 aplikasi/alat/periksa-antarmuka.py` | `.` | ✅ 0 | 0.0 |  |
| 98 | `python3 aplikasi/alat/periksa-antarmuka.py --uji-diri` | `.` | ✅ 0 | 2.2 |  |
| 99 | `python3 alat/periksa-rahasia.py` | `.` | ✅ 0 | 2.8 |  |
| 100 | `python3 alat/periksa-rahasia.py --uji-diri` | `.` | ✅ 0 | 29.7 |  |
| 101 | `python3 alat/periksa-header.py` | `.` | ✅ 0 | 0.0 |  |
| 102 | `python3 alat/periksa-header.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 103 | `python3 alat/periksa-bersih.py` | `.` | ❌ 1 | 4.9 | CACAT NYATA — cascade F10-A3-04 |
| 104 | `python3 alat/periksa-gerbang-ci.py` | `.` | ✅ 0 | 0.0 |  |
| 105 | `python3 alat/periksa-kunci-kalibrasi.py` | `.` | ✅ 0 | 0.2 |  |
| 106 | `python3 alat/periksa-kunci-kalibrasi.py --uji-diri` | `.` | ✅ 0 | 4.0 |  |
| 107 | `python3 alat/periksa-paket.py` | `.` | ❌ 1 | 8.9 | artefak lingkungan: snapshot 1 commit tanpa induk (bukan cacat) |
| 108 | `python3 alat/periksa-paket.py --uji-diri` | `.` | ❌ 1 | 12.1 | artefak lingkungan: snapshot 1 commit tanpa induk (bukan cacat) |
| 109 | `python3 alat/lanjut-sesi.py --di-ci` | `.` | ✅ 0 | 0.1 |  |
| 110 | `python3 alat/lanjut-sesi.py --uji-diri` | `.` | ✅ 0 | 1.7 |  |
| 111 | `python3 alat/mulai-sesi.py --uji-diri` | `.` | ✅ 0 | 0.0 |  |
| 112 | `python3 alat/periksa-angka-bukti.py` | `.` | ✅ 0 | 0.0 |  |
| 113 | `python3 alat/periksa-angka-bukti.py --uji-diri` | `.` | ✅ 0 | 0.1 |  |
| 114 | `python3 alat/periksa-migrasi-beku.py` | `.` | ✅ 0 | 0.0 |  |
| 115 | `python3 alat/periksa-migrasi-beku.py --uji-diri` | `.` | ✅ 0 | 0.1 |  |
| 116 | `node aplikasi/alat/catat-alamat.mjs --uji-diri` | `.` | ✅ 0 | 0.1 |  |
| 117 | `python3 alat/periksa-gerbang-ci.py --uji-diri` | `.` | ✅ 0 | 2.0 |  |
| 118 | `python3 alat/periksa-bersih.py --uji-diri` | `.` | ❌ 1 | 20.1 | CACAT NYATA — cascade F10-A3-04 |
| 119 | `python3 aplikasi/alat/periksa-struktur.py` | `.` | ✅ 0 | 0.1 |  |
| 120 | `python3 aplikasi/alat/periksa-node.py` | `.` | ✅ 0 | 0.0 |  |
| 121 | `python3 aplikasi/alat/periksa-node.py --uji-diri` | `.` | ✅ 0 | 2.0 |  |
| 122 | `python3 aplikasi/alat/periksa-komponen-env.py --uji-diri` | `.` | ✅ 0 | 2.1 |  |
| 123 | `python3 aplikasi/alat/periksa-uji.py` | `.` | ✅ 0 | 0.0 |  |
| 124 | `python3 aplikasi/alat/periksa-uji.py --uji-diri` | `.` | ✅ 0 | 1.3 |  |
| 125 | `python3 aplikasi/alat/uji-kontras.py` | `.` | ✅ 0 | 0.0 |  |
| 126 | `python3 aplikasi/alat/uji-kontras.py --uji-diri` | `.` | ✅ 0 | 1.4 |  |

### 10 perintah paling lambat (untuk perencanaan `timeout-minutes: 25` di `ci.yml`)

| Perintah | Detik |
|---|---|
| `node aplikasi/alat/uji-mutasi-app.mjs` | 198.6 |
| `python3 alat/uji-mutasi-0015.py` | 113.3 |
| `npm test` | 97.8 |
| `python3 alat/uji-mutasi-0014.py` | 89.2 |
| `python3 alat/uji-mutasi-0012.py` | 78.2 |
| `python3 alat/uji-mutasi-0016.py` | 71.9 |
| `python3 alat/uji-mutasi-0017.py` | 41.6 |
| `python3 alat/uji-mutasi-0018.py` | 36.3 |
| `python3 alat/periksa-keamanan-sql.py --uji-diri` | 35.1 |
| `python3 alat/periksa-rahasia.py --uji-diri` | 29.7 |

Total 1431 detik pada sandbox 2 vCPU. `ci.yml` memberi `timeout-minutes: 25`; runner GitHub berinti lebih banyak sehingga angka lokal ini **bukan** prediksi waktu CI, hanya data pembanding.
