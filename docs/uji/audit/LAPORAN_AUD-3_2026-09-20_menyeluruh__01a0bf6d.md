# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-20

- **Auditor:** Arena.ai Agent Mode — sesi independen `arena/01a0bf6d-resto-barokah` (model berbeda dari sesi kerja)
- **Tanggal:** 2026-09-20
- **Tingkat audit:** `AUD-3`
- **Commit yang diaudit:** `cbba40108fa17eca39a438cd25588f23807873fd`
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-20.md`
- **Mode cakupan:** `menyeluruh`
- **Verdict:** `TIDAK-BERSIH`

**Ringkasan keputusan.** Saya memeriksa commit target dalam keadaan detached (`git rev-parse HEAD` = `cbba40108…`, `git status --short` kosong) dan mengaudit pohon itu — bukan HEAD cabang sesi, bukan commit lain. Satu temuan K-2 TERVERIFIKASI (buku insiden menjanjikan kontrol yang belum ada di kode — F-01) serta satu temuan K-1 DUGAAN yang saya telusuri ulang secara independen (kelebihan bayar tanpa koreksi setelah pembayaran parsial + void item sah — F-02) cukup untuk menahan verdict di `TIDAK-BERSIH`. Keduanya memang sudah tercatat terbuka di buku sendiri proyek (`docs/uji/AUDIT_RIWAYAT.md`, 17 baris `TERBUKA` — terverifikasi dengan `python3 alat/periksa-temuan-audit.py`). Inti uang & PIN di database terbukti terpagar rapi secara pembacaan kode (lapisan 0012–0016 menutup temuan putaran-putaran sebelumnya), tetapi beberapa jalur (uji SQL dinamis, uji unit aplikasi, konektivitas live) tidak bisa saya eksekusi dari lingkungan ini — rincinya di §6. Kalibrasi: 15 dari 15 cacat tanaman yang saya yakini ada, ketemu (detail §5).

## 1. Cakupan

Target dibaca dari checkout detached saya pada `cbba40108fa17eca39a438cd25588f23807873fd` (satu-satunya commit yang diaudit). Catatan alat: `python3 alat/audit-independen.py --verifikasi-lingkup` membaca paket paling baru yang ADA DI POHON target (yaitu `AUD-3-2026-09-19…`, target `93a50ba…`) dan mencetak `BEDA COMMIT` — itu quirk alat (paket audit ini baru masuk pohon di commit `cfc6097`, setelah target), bukan indikasi salah commit; paket yang saya patokan adalah berkas SIAP-TEMPEL 2026-09-20 yang disalin ke sesi ini, isinya identik dengan `docs/uji/paket-audit/AUD-3-2026-09-20-SIAP-TEMPEL.md` di `cfc6097`.

**Cakupan menyeluruh: 522 dari 522 berkas pada paket audit.** Cara periksa per kelas berkas: (a) baca penuh — semua migrasi, semua tes SQL (pembuka+inti), Edge Function, seluruh `aplikasi/src/lib`, dokumen pengikat; (b) buka berkas + struktur (pembuka, daftar fungsi/policy, baris kunci) — semua berkas sisanya satu per satu; (c) aset biner (font woff2, gambar desain/prototipe) diverifikasi lewat enumerasi + tanda tangan berkas + pemeriksa mesin (`aplikasi/alat/uji-kontras.py` mengecek berat & keberadaan 19 font). Angka per grup di bawah dihitung dari `git ls-tree -r` commit target dan berjumlah 522 (525 berkas non-`skills` dikurangi 3 di luar cakupan: `_salinan-meta/` 2 + `_Notes.md` 1 — saya setuju dengan pengecualian paket: `_salinan-meta/` adalah arsip provenance sistem pembangun, `_Notes.md` ditandai "hapus"; `skills/` 1803 berkas adalah vendor pihak ketiga, bukan pekerjaan proyek).

| # | Artefak/grup target | Diperiksa | Bukti (perintah/baris) |
|---|---|---:|---|
| 1 | `.github` (3 alur) | 3 | `ci.yml`, `sebar-halaman.yml`, `sebar-skema.yml` dibaca penuh; `git ls-tree -r --name-only cbba40108… .github \| wc -l` → 3 |
| 2 | berkas pengguna di akar (14 `.md` + `.gitignore`) | 15 | `git ls-tree -r --name-only cbba40108… \| awk -F/ 'NF==1'` → 19 (kurangi `_Notes.md`, `package.json`, `package-lock.json` → baris 2-3); tiap berkas dibuka |
| 3 | berkas paket di akar (`package.json`, `package-lock.json`) | 2 | `cat package.json`; `periksa-node.py` membaca lock (187 entri non-opsional) → LOLOS |
| 4 | `_log-sesi` | 5 | `head -6 _log-sesi/LOG_SESI_*.md` (5 berkas: 09-15…09-19) |
| 5 | `_sistem` | 15 | `python3 _sistem/validate_system.py` → PASS; 5 arsip `.md` + 10 template dibuka |
| 6 | `alat` (pemeriksa Python + harness mutasi + fixture contoh) | 48 | `git ls-tree -r --name-only cbba40108… alat \| wc -l` → 48; 18 pemeriksa dijalankan (output §2-3); `uji-mutasi-0015.py` dibaca (butuh PGlite — §6); 15 fixture `contoh-laporan*` dibuka |
| 7 | `aplikasi/src` | 73 | `find aplikasi/src -type f -print \| wc -l` → 73; `lib/{env,supabase,format,tema}.ts` + test dibuka penuh; `aplikasi/src/layar/contoh/LayarContoh.tsx:1-304` dibaca; 32 aset font di-enumerasi |
| 8 | `aplikasi/alat` | 12 | `git ls-tree -r --name-only cbba40108… aplikasi/alat \| wc -l` → 12; 9 pemeriksa Python dijalankan (output §2 baris 5); `aplikasi/alat/cek-supabase.mjs` + `uji-mutasi-app.mjs` + `pratinjau.sh` dibuka |
| 9 | `aplikasi` (konfigurasi) | 15 | `git ls-tree -r --name-only cbba40108… aplikasi \| awk -F/ 'NF==2' \| wc -l` → 15; `aplikasi/tsconfig.app.json:2` (`strict`), `aplikasi/vite.config.ts` (host+allowedHosts), `aplikasi/wrangler.toml` dibaca |
| 10 | `aplikasi/public` | 2 | `git ls-tree -r --name-only cbba40108… aplikasi/public \| wc -l` → 2; `aplikasi/public/robots.txt:4` (`Disallow: /`) |
| 11 | `docs` (fondasi, 11) | 11 | `git ls-tree -r --name-only cbba40108… docs \| awk -F/ 'NF==2' \| wc -l` → 11; `docs/KEAMANAN.md` §1-4 + `docs/TECH_SPEC.md` §6-8 + 9 berkas lain dibuka |
| 12 | `docs/ops` | 8 | `git ls-tree -r --name-only cbba40108… docs/ops \| wc -l` → 8; `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` + `LANGKAH_PEMILIK_SEKARANG.md` dibaca penuh |
| 13 | `docs/teknis` | 6 | `git ls-tree -r --name-only cbba40108… docs/teknis \| wc -l` → 6; `docs/teknis/BUKU_INSIDEN.md` dibaca penuh (temuan F-01) |
| 14 | `docs/desain` | 59 | `find docs/desain -type f -print \| wc -l` → 59 (2 dokumen `.md` dibaca penuh; 57 aset gambar di-enumerasi + tanda tangan berkas) |
| 15 | `docs/uji` | 110 | `git ls-tree -r --name-only cbba40108… docs/uji \| wc -l` → 110; `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` dibaca penuh; 14 berkas paket lama + 19 laporan lama + 17 laporan review PR + probe dibuka (pembuka/struktur) |
| 16 | `prototipe` | 58 | `git ls-tree -r --name-only cbba40108… prototipe \| wc -l` → 58; 15 berkas teks dibuka (README, 5 HTML, 3 JS, 3 CSS, 2 alat Python); 43 aset gambar di-enumerasi |
| 17 | `supabase/migrations` | 17 | `git ls-tree -r --name-only cbba40108… supabase/migrations \| wc -l` → 17; `supabase/migrations/0016_penutup_celah_pin_putaran18.sql:47-96` (pembatas PIN) — 16 migrasi dibaca (0001–0006, 0009–0011, 0015, 0016 penuh; 0007/0008/0012–0014 inti: semua policy, trigger, grant/revoke) + `.gitkeep` |
| 18 | `supabase/tes` | 59 | `git ls-tree -r --name-only cbba40108… supabase/tes \| wc -l` → 59; 58 berkas uji SQL dibuka satu per satu (pembuka+inti; asersi dibaca) + `.gitkeep` |
| 19 | `supabase/functions` | 2 | `git ls-tree -r --name-only cbba40108… supabase/functions \| wc -l` → 2; `supabase/functions/verifikasi_pin/index.ts:1-172` dibaca penuh |
| 20 | `supabase` (akar) | 2 | `git ls-tree -r --name-only cbba40108… supabase \| awk -F/ 'NF==2' \| wc -l` → 2; `supabase/README.md` + `config.toml` (ramping, tanpa `env(...)`) dibaca |
| 21 | kontrak uang & izin (lembaga) | 3 berkas | `docs/TECH_SPEC.md:302-340` (§6 variabel), `docs/PRD.md` Aturan Bisnis 7 & 11, `docs/KEAMANAN.md:44-96` — dibaca |
| 22 | migrasi penutup terbaru (inti uang) | 2 migrasi | `nl -ba supabase/migrations/0015_penutup_celah_putaran16.sql` (1146 baris) & `0016_penutup_celah_pin_putaran18.sql` (469 baris) dibaca penuh |
| 23 | Edge Function PIN + pemeriksanya | 2 berkas | `supabase/functions/verifikasi_pin/index.ts` + `python3 alat/periksa-fungsi-pin.py` → 14/14 lolos |
| 24 | bahan kalibrasi | 5 berkas | `git ls-tree -r --name-only cbba40108… docs/uji/kalibrasi/bahan-2026-09-17 \| wc -l` → 5; dibaca penuh; rincian temuan di §5 |

### 1a. Berkas untuk pengguna

Saya menelusuri berkas berikut dengan mata pengguna non-teknis (apakah langkahnya bisa dilakukan orang yang tidak menulis kode?), bukan hanya sebagai sumber klaim. Hasil utamanya: buku-buku induknya lengkap dan konsisten (Bagian A–H + 15 alur + C1–C5 prompt), tetapi **buku insiden menjanjikan fitur yang belum ada** (F-01) dan dua berkas ops menyebut "14 berkas tabel" padahal kini 16 (F-04).

| # | Berkas pengguna | Pemeriksaan cara pengguna | Bukti |
|---|---|---|---|
| 1 | `PANDUAN_PENGGUNA.md` (778 baris), `START_DI_SINI.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `PROFIL_PENGGUNA.md`, `STATUS.md`, `PROJECT_STATE.md` | Alur AL-1…AL-15 dibaca dari sudut Lee: kalimat pemantik, langkah, bukti yang diterima, "kalau macet" ada di tiap alur; prompt C1–C5 utuh dan sama dengan templat mesin; `STATUS.md` dibaca sebagai papan keadaan, bukan bukti runtime. | `grep -n "^### AL-\|^## Bagian" PANDUAN_PENGGUNA.md` → 15 alur + 8 bagian; `python3 alat/periksa-panduan.py` → LOLOS (778 baris; rujukan hidup) |
| 2 | `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, `SIAP_AKUN_PEMILIK.md`, `ALAMAT_PUBLIK.md`, `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` + template | Langkah "tempel 3 rahasia ke GitHub" tanpa perintah untuk diketik — bisa dilakukan pemilik; klaim "0015+0016 kini HIDUP di proyek nyata" dicek ke API GitHub (run sebar skema `35516000988` → success); alamat publik + izin pemilik ("Boleh naik") tercatat. | `gh api …/actions/runs/35516000988` → `success`; `grep -n "SELESAI" docs/ops/LANGKAH_PEMILIK_SEKARANG.md` |
| 3 | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` + paket audit yang disalin ke sesi ini | Prompt memperingatkan jebakan nyata (jangan salin templat, salin SIAP-TEMPEL); SHA target, 522 berkas, 18 grup, minimum artefak/klaim/serangan, dan perintah validasi cocok dengan yang saya kerjakan. | `grep -n "Commit yang diaudit\|522" docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a-SIAP-TEMPEL.md` (paket 2026-09-20 identik isinya, masuk pohon di `cfc6097`) |
| 4 | `docs/teknis/BUKU_INSIDEN.md`, `BUKU_UJI_PEMILIK.md`, `docs/PANDUAN_PEMILIK.md` | Buku insiden dibaca sebagai pemilik yang sedang panik: 11 skenario punya langkah+hasil-harapan, TETAPI bagian 2/3/4/7/10 menunjuk menu & fitur yang tidak ada di kode hari ini (Perangkat & Sesi, MFA, Jejak Audit, antrean offline, cadangan mingguan) → F-01. `BUKU_UJI_PEMILIK.md` 13 baris, tiap baris punya langkah ≤5 + kolom hasil (dijaga mesin). | `grep -n "Perangkat & Sesi\|MFA\|Jejak Audit\|Cadangan otomatis" docs/teknis/BUKU_INSIDEN.md`; `python3 alat/periksa-buku-uji.py` → LOLOS (13 baris) |

### Perbedaan paket dan target

Paket `AUD-3-2026-09-20` (yang disalin ke sesi saya) dibuat di commit `cfc6097` — DUA commit setelah target — dan sengaja mengikat audit ke commit SEBELUMNYA, `cbba40108…` (CI-nya hijau, run `35518950919`, terverifikasi `gh api repos/With-AI-Agent/Resto-Barokah/actions/runs/35518950919` → `success`, `head_sha` = target). Pohon non-vendored target = 522 berkas, persis angka paket. Tidak ada perbedaan berkela yang perlu dikoreksi; paket tidak menyebut "16 migrasi" melainkan merujuk skema terkini — saya menghitung sendiri: 16 `.sql` (0001–0016). Satu selisih angka yang saya temukan: paket/klaim T0-05 menyebut "8 nama variabel" sementara `.env.example` memuat 9 NAMA (8 baris tabel TECH_SPEC §6, baris `GOOGLE_CLIENT_ID/SECRET` = dua nama) — artefak penghitungan, bukan cacat (seluruh nama TECH_SPEC hadir; terverifikasi `grep -cE '^[A-Z_]+=|^# [A-Z_]+=' aplikasi/.env.example` → 9).

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T0-00: `DAFTAR_KUNCI_PEMILIK_NONSECRET.md` berisi nilai yang sama persis dengan CI; service_role TIDAK ada di repo (ROADMAP T0-00) | `cat docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md`; `grep -n "VITE_SUPABASE" .github/workflows/ci.yml`; `python3 alat/periksa-rahasia.py`; `git log --all -p \| grep -E "sb_service_role\|eyJhbGciOi"` | TERBUKTI — URL & kunci publik sama persis di berkas & CI; pemeriksa rahasia LOLOS; riwayat Git bersih (yang ketemu hanya fixture uji-diri & fixture skill vendor) |
| 2 | T0-01: 19 berkas font woff2, 13 keluarga, tanpa internet (ROADMAP T0-01) | `find aplikasi/src/gaya/aset -name '*.woff2' \| wc -l` → 19; `python3 aplikasi/alat/uji-kontras.py` → "13 keluarga huruf tersimpan (woff2)" | TERBUKTI (19/13 cocok; berat kini 461 KB vs 487 KB saat klaim — perubahan selaras, bukan pelanggaran) |
| 3 | T0-02: TypeScript ketat aktif (ROADMAP T0-02) | `grep -n "strict\|noUnused" aplikasi/tsconfig.app.json` | TERBUKTI — `strict: true` + `noUnusedLocals` + `noUnusedParameters` |
| 4 | T0-03: `aplikasi/src/gaya/token/tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css` (ROADMAP T0-03) | `cmp aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` | TERBUKTI — output kosong (identik) |
| 5 | T0-04: `uji-kontras.py` 166 lolos/0 gagal; 10 komponen env OK; 76 uji hijau dalam 10 berkas (ROADMAP T0-04) | `python3 aplikasi/alat/uji-kontras.py`; `python3 aplikasi/alat/periksa-komponen-env.py`; `python3 aplikasi/alat/periksa-uji.py` | TERBUKTI (angka saat klaim) — ulang hari ini: 166 lolos/0 gagal, 10 OK, dan 97 uji terbaca (bertambah sejak klaim, jumlah berkas uji tetap 10); `npm test` sendiri tidak bisa saya jalankan (§6) |
| 6 | T0-05: `.env.example` memuat semua nama variabel TECH_SPEC §6, hanya 2 aktif (ROADMAP T0-05) | `grep -nE '^[A-Z_]+=|^# [A-Z_]+=' aplikasi/.env.example` | TERBUKTI — 9 nama (8 baris tabel; `GOOGLE_CLIENT_ID/SECRET` satu baris) semua hadir; hanya 2 berawalan `VITE_` aktif; 7 rahasia dikomentari tanpa nilai |
| 7 | T0-06: salinan bersih bisa `npm ci` + `build` hijau tanpa internet (ROADMAP T0-06) | Tidak bisa dieksekusi — install dilarang & `node_modules` tidak ada | TIDAK BISA DIBUKTIKAN di sini — alur `ci.yml` menjalankan `npm ci` + `typecheck` + `build` di tiap push (baca `ci.yml`), dan CI target hijau (baris 12) |
| 8 | T0-08: koneksi Supabase nyata dengan kunci publik, terbuktikan di CI (run `35432334878`) (ROADMAP T0-08) | `gh api repos/With-AI-Agent/Resto-Barokah/actions/runs/35432334878`; `curl https://bdvjirmbuqelmduztryj.supabase.co/auth/v1/health` (langsung) | TERBUKTI VIA CATATAN CI — run `success` (head `638820d`); jalur HTTP langsung dari sandbox GAGAL (HTTP 000 — sandbox tanpa egress ke `*.supabase.co`), jadi bukti live tidak saya ulang dari sini |
| 9 | T0-09: halaman naik ke Cloudflare, run `35440300274` & `35440432817` hijau, HTTP 200 (ROADMAP T0-09) | `gh api …/runs/35440300274` & `…/35440432817` | TERBUKTI VIA CATATAN CI — keduanya `success` (alur *Naikkan Halaman*); `curl` langsung tidak bisa (§6) |
| 10 | T1-10: empat pagar uang ada di database (total>0 sebelum bayar, tidak melebihi total, diskon berbatas, pembatalan beralasan) (ROADMAP T1-10) | Baca penuh `0010_pembayaran.sql` (penjaga 1–4) + 58 berkas `supabase/tes` (pembuka skenario) | TERBUKTI SECARA STATIS — keempat penjaga ada di kode dengan uji regresi bernama; eksekusi SQL dinamis hanya di CI (PGlite tidak terpasang di sini, §6) |
| 11 | PIN: hash di tabel terpisah tak terbaca klien, 6 angka, pembatas 5/akun & 12/perangkat per 15 menit (ROADMAP T1-23, `docs/KEAMANAN.md` §2) | `python3 alat/periksa-fungsi-pin.py`; baca `0006`, `0011`, `0016` (tubuh `verifikasi_pin`/`simpan_pin` final) | TERBUKTI — 14/14 pemeriksa lolos; `pin_hash` di `kredensial_pin` (revoke dari klien); pembatas terpasang di `0016:84-96` — CATATAN: lapis per-perangkat memakai nama perangkat kiriman klien (F-03) |
| 12 | CI hijau pada commit yang diaudit | `gh api repos/With-AI-Agent/Resto-Barokah/actions/runs/35518950919` | TERBUKTI — `success`, `head_sha` = `cbba40108fa17eca39a438cd25588f23807873fd`, event `pull_request`, 2026-09-20 |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | Anon memanggil fungsi SECURITY DEFINER yang membocorkan data | Pemindai state-final per 16 migrasi (Python): fungsi definer + revoke/grant execute terakhir | DITOLAK (baik) — satu-satunya definer callable-anon: `harga_berlaku`/`menu_habis`, keduanya tersaring `penyewa_id = public.penyewa_saya()` → NULL untuk anon → 0 baris (`0007:128-142`, `0007:190-205`) |
| 2 | RLS berdasarkan `user_metadata`/`auth.role()` (palsu oleh klien) | `grep -rn "user_metadata\|raw_user_meta_data\|auth\.role()" supabase/` | DITOLAK (baik) — 0 kecocokan; identitas hanya lewat helper yang membaca `auth.uid()`/JWT claim |
| 3 | View bypass RLS | `grep -rni "create.*view" supabase/migrations/` | DITOLAK (baik) — tidak ada view sama sekali |
| 4 | Search-path injection via definer (fungsi di skema lain) | Pemindai: header tiap fungsi definer wajib `search_path = public, pg_temp` | DITOLAK (baik) — 0 definer tanpa `pg_temp` |
| 5 | Old overload: klien memaksa `verifikasi_pin` 4-argumen versi 0011 (tanpa guard F-15) via PostgREST | `grep -n "drop function.*verifikasi_pin\|verifikasi_pin(uuid, text, text, text" supabase/migrations/*.sql` | NETRAL — overload 4-argumen di-`drop function` di `0012:242`; yang hidup hanya versi 5-argumen 0016 |
| 6 | Akun nonaktif (JWT masih sah) menguji PIN pegawai resto lain (F-15) | Baca tubuh final `verifikasi_pin` 0016: guard `if public.penyewa_saya() is null then return …` (baris 58-61) DITEMPATKAN SEBELUM kredensial disentuh | DITOLAK (baik) — jawaban netral 'PIN tidak dikenali.' sebelum percobaan PIN |
| 7 | admin_cabang membaca izin pegawai cabang lain (F-10) | Baca policy final `izin_pilih` (`0015` bagian 11) | DITOLAK (baik) — admin hanya melihat pegawai di `cabang_saya()` |
| 8 | Kasir menuliskan angka uang (subtotal/pajak/total) dari perangkat | Baca `picu_pesanan_jaga_uang` (`0010`) + `supabase/tes/gerbang_uang.sql` | DITOLAK (baik) — INSERT/UPDATE angka non-nol raise; `peran_peladen()` sengaja BUKAN definer (dijelaskan di komentar kode) |
| 9 | Kasir men-overshoot pembayaran (jumlah + yang sudah dibayar > total) | Baca `picu_pembayaran_jujur` final (`0015:585-682`): kunci baris `for update` + `total_dibayar()+new.jumlah > total` → raise | DITOLAK (baik) — plus idempoten `(pesanan_id, kunci_idempoten)` unik & baris append-only (tanpa policy UPDATE untuk authenticated) |
| 10 | **Pembayaran parsial lalu void item sah sebelum dapur** → total turun di bawah uang yang sudah masuk (skenario saya: 2 item × 25.000; bayar 50.000; void 1 item resmi) | Telusur kode: `hitung_total` (`0015:455-539`) menghitung ulang TANPA memeriksa `total_dibayar`; `picu_item_jaga` hanya membekukan pesanan `lunas/batal`; tidak ada mekanisme koreksi/refund (tabel kas belum ada, Fase 7) | **GAGAL (rapuh) — DUGAAN** — kelebihan bayar 25.000 bertahan di `pembayaran` tanpa baris koreksi; sesuai sisa temuan terbuka proyek I F-17 → lihat F-02 |
| 11 | Kasir memberi diskon dengan kolom `persen` kosong untuk melewati batas persen (B F-06) | Baca `picu_diskon_batas` final (`0013:39-44`): `v_persen` dihitung dari `nilai/subtotal`, bukan kolom klien | DITOLAK (baik) — subtotal 0 → pakai persen kiriman, kosong → 100% (paling ketat) |
| 12 | Kasir mencatat diskon `jenis='voucher'`/`'promo'` 100% tanpa mesin voucher (PR-01) | Baca `0013:50-63` | DITOLAK (baik) — fail-closed: raise "belum aktif (menunggu T1-12/T1-19/T1-20)" |
| 13 | Kasir mengarang persetujuan void: menuliskan `disetujui_oleh=<owner>` tanpa PIN | Baca `picu_pembatalan_sah` final (`0015:682-810`) + `0016` bagian 2: kupon `percobaan_pin` terikat `pesanan_id`, `dipakai_pada is null`, 5 menit, `for update`, lalu izin dicek ulang saat konsumsi | DITOLAK (baik) — satu PIN = satu pesanan, sekali pakai, dan "PIN benar" bukan otorisasi (cek ulang `boleh_untuk`) |
| 14 | Kasir mengarang stempel `dibayar_pada`/`alasan_batal` via UPDATE biasa (F-06) | Baca `picu_pesanan_jejak_jujur` final (`0015:810-909`) | DITOLAK (baik) — perubahan stempel lifecycle di luar jalur peladen raise; kasir_id/tanggal/nomor beku |
| 15 | Rahasia (service_role/JWT/`sk_live`) terselip di riwayat Git (repo PUBLIK sejak 2026-09-20) | `git log --all -p \| grep -E "sb_service_role\|eyJhbGciOi\|sk_live\|resend_\|x-default-token"` | DITOLAK (baik) — hanya fixture uji-diri (`Kunci uji:` palsu) & fixture skill vendor |
| 16 | "Uji hijau tapi palsu": harness mutasi menghitung kegagalan lingkungan sebagai bukti | Baca `alat/uji-mutasi-0015.py` + `alat/klasifikasi_mutasi.py` (hanya merah dari asersi `supabase/tes` yang dihitung; salinan rusak → `BUKAN BUKTI`) | TIDAK BISA DIEKSEKUSI di sini (PGlite tidak terpasang) — desainnya benar secara pembacaan; batasan di §6 |

## 4. Temuan

### [F-01] Buku insiden menjanjikan kontrol yang belum ada di kode — pemilik yang mengikuti langkahnya akan macet
- **Tingkat:** K-2
- **Artefak:** `docs/teknis/BUKU_INSIDEN.md` §2, §3, §4, §7, §10 (baris: "Pengaturan → Perangkat & Sesi → … → Cabut", "Atur ulang kunci kedua (MFA)", "Periksa jejak audit (Pengaturan → Jejak Audit)", "pesanan masuk antrean lokal", "Cadangan otomatis berjalan mingguan")
- **Klaim yang dilanggar:** janji dokumen pengikat ke pengguna non-teknis (PROTOKOL §2b butir 2: buku pengguna) vs keadaan kode — kontrol-kontrol itu adalah tugas Fase 1B/10 yang belum dikerjakan
- **Bukti:** `grep -n "create table if not exists public.perangkat\|sesi_perangkat" supabase/migrations/*.sql` → 0 hasil (tabel perangkat/sesi tidak ada); `grep -rli "totp\|mfa" supabase/migrations/*.sql` → 0; `grep -l "catatan_audit" supabase/migrations/*.sql` → 0; `ls .github/workflows/` → hanya `ci.yml`, `sebar-halaman.yml`, `sebar-skema.yml` (tidak ada alur cadangan mingguan); `ls aplikasi/src/lib/antrean-offline.ts` → tidak ada (masih "berkas rencana" menurut `periksa-struktur.py`)
- **Skenario gagal:** HP kasir dicuri saat jam sibuk → owner membuka BUKU_INSIDEN → langkah 1 "cabut perangkat dari Pengaturan → Perangkat & Sesi" tidak bisa dilakukan karena menu itu tidak ada di aplikasi (aplikasi masih kerangka Fase 0); owner tidak tahu jalur yang sebenarnya (nonaktifkan akun + ganti PIN) sampai bertanya
- **Dugaan penyebab:** buku insiden ditulis utuh untuk keadaan FINAL (Fase 1B+10) demi stabilitas prosedur, padahal proyek masih Fase 1; catatan jujur sudah ada di §8/§10 untuk dua kasus (denyut pg_cron, `PEMULIHAN.md`), tetapi tidak untuk bagian 2/3/4/7/10
- **Cara membuktikan perbaikan:** setelah T1-24/T1-25 (perangkat/sesi) + T1-27 (jejak audit) + T10-10 (cadangan) mendarat: ulang grep di atas — tabel/workflow terkait harus ADA; sampai saat itu, buku wajib memetik bagian yang belum tersedia ("fitur ini belum terpasang — jalur sementara: …") sesuai temuan terbuka proyek I F-08 → `T1-45` di `docs/uji/AUDIT_RIWAYAT.md`
- **Status verifikasi:** TERVERIFIKASI (pembacaan kode + grep; bukan klaim)

### [F-02] Pembayaran parsial + void item sah sebelum dapur = kelebihan bayar tanpa koreksi tercatat
- **Tingkat:** K-1 (dugaan)
- **Artefak:** `supabase/migrations/0015_penutup_celah_putaran16.sql` (`hitung_total` baris 455-539; `picu_item_jaga` baris 909-1031) + `0013` (`picu_pembatalan_sah`/`picu_pembatalan_jejak`)
- **Klaim yang dilanggar:** prinsip `docs/KEAMANAN.md` §1.5 "Tidak ada angka uang dari perangkat" & ART-4 (riwayat uang harus bisa dijelaskan) — selisih kas tanpa baris koreksi merusak rekonsiliasi
- **Bukti:** (1) `hitung_total` menghitung ulang `subtotal/pajak/service/total` dari baris item non-batal TANPA satu pun pemeriksaan terhadap `public.total_dibayar(pesanan_id)` — `grep -n "total_dibayar" supabase/migrations/0015_penutup_celah_putaran16.sql` → 0 kecocokan; (2) pembekuan pasca-pembayaran hanya menyandarkan pada status `lunas/batal` (`picu_item_jaga` 2b: `if coalesce(v_pesanan.status, '') in ('lunas','batal')`) — dan di commit ini TIDAK ADA jalur yang menyetel `lunas` (grep `set status = 'lunas'` di semua migrasi → 0; transisi lunas milik Fase 5, T5-02); (3) tidak ada mekanisme refund/koreksi (tabel kas = Fase 7, belum ada); (4) `picu_pembatalan_sah` memeriksa izin/tahap/PIN/nilai-kerugian tetapi TIDAK memeriksa `total_dibayar`
- **Skenario gagal:** kasir mencatat pembayaran 50.000 (valid: ≤ total 50.000) → pesanan masih `draf` → void resmi 1 item 25.000 (tahap `sebelum_dapur`, kasir berizin, alasan valid) → `hitung_total` menurunkan `pesanan.total` ke 25.000 → data kini: `sum(pembayaran)=50.000 > total=25.000` dengan nol baris yang menjelaskan 25.000; bila kasir mengembalikan uang tunai, selisih itu tidak pernah tercatat
- **Dugaan penyebab:** penjaga "uang tidak boleh melebihi total" dipasang di sisi PENCATATAN pembayaran (benar), tetapi pemicu hitung-ulang item tidak punya counterpart di sisi penurunan total; jalur koreksi (kas/shift) memang belum dibangun
- **Cara membuktikan perbaikan:** uji SQL baru (PGlite/Supabase nyata): bayar parsial → void item sah → asersi `sum(pembayaran.jumlah) <= pesanan.total` ATAU baris koreksi/refund muncul; atau penjaga di `hitung_total`: bila `total_dibayar > total baru`, tolak/reject koreksi resmi. Menyelesaikan sisa temuan terbuka proyek I F-17 → `T1-45`
- **Status verifikasi:** DUGAAN (penelusuran kode penuh; eksekusi dinamis tidak mungkin di lingkungan ini — §6)

### [F-03] Lapis kedua pembatas PIN (12×/perangkat) memakai nama perangkat kiriman klien — penyerang memutar nama dan tidak pernah terkumpul
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0016_penutup_celah_pin_putaran18.sql` baris 73-82 (`v_perangkat := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui')` lalu `v_gagal_alat` dihitung per `pp.perangkat = v_perangkat`)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §2 "PIN ditebak (batas 5×/15 menit per akun & 12×/15 menit per perangkat …)" — lapis per-perangkat hanya berarti bila perangkat TERVERIFIKASI
- **Bukti:** `v_perangkat` berasal dari argumen RPC yang diisi klien; `supabase/functions/verifikasi_pin/index.ts` meneruskan `perangkat` dari body apa adanya; tidak ada tabel perangkat di commit ini (F-01) sehingga tidak ada cara memvalidasi `perangkat` itu; `percobaan_pin.perangkat` = teks bebas
- **Skenario gagal:** penyerang dengan satu akun sah sah menggeledah PIN atasan: kirim `perangkat` berbeda tiap panggilan → `v_gagal_alat` selalu 1 → batas 12 tidak pernah menyala; yang tersisa hanya batas 5×/akun/15 menit (≈ 480 tebakan/hari — lambat, tetapi kontrol kedua yang diiklankan tidak bekerja)
- **Dugaan penyebab:** perangkat terdaftar adalah Fase 1B (T1-24); sampai saat itu nama perangkat memang tak bisa diverifikasi — proyek sudah mencatatnya jujur di `docs/KEAMANAN.md` §2 ("Catatan jujur … lapis per perangkat masih memakai nama perangkat yang dikirim klien") dan di buku temuan (B F-11 → T1-24)
- **Cara membuktikan perbaikan:** setelah T1-24: `percobaan_pin.perangkat` harus di-binding ke `perangkat_id` terdaftar (bukan teks klien); uji SQL: 13 percobaan dengan nama perangkat berbeda atas akun yang sama → yang ke-13 DITOLAK
- **Status verifikasi:** TERVERIFIKASI (pembacaan kode; efeknya terukur di atas)

### [F-04] Angka basi "14 berkas tabel/migrasi" di dua berkas pemilik padahal skema kini 16 dan 0015+0016 sudah hidup
- **Tingkat:** K-3
- **Artefak:** `.github/workflows/sebar-skema.yml` (baris 3: "menyebar 14 berkas migrasi") dan `docs/ops/SIAP_AKUN_PEMILIK.md` ("14 berkas tabel pertama sudah tersebar ke database nyata")
- **Klaim yang dilanggar:** akuratus dokumen operasional (PROTOKOL §2b butir 5: dok harus selaras kenyataan) — `LANGKAH_PEMILIK_SEKARANG.md` di berkas yang sama sendiri menyatakan "migrasi 0015+0016 kini HIDUP di proyek nyata" (run `35516000988` → success, terverifikasi)
- **Bukti:** `ls supabase/migrations/*.sql | wc -l` → 16; `gh api …/runs/35516000988` → `success` (Sebar Skema); komentar workflow tidak diperbarui setelah `0015`/`0016` disebar
- **Skenario gagal:** pemilik/agent sesi baru membaca "14 berkas" → menyimpulkan `0015`/`0016` belum tersebar → meminta sebar ulang yang tidak perlu (alurnya idempoten, jadi risiko kecil — tetapi kebingungan di jalur uang selalu mahal)
- **Dugaan penyebab:** komentar ditulis saat skema = 14 berkas; penyebar berikutnya memakai alur yang sama tanpa menyunting komentar
- **Cara membuktikan perbaikan:** `grep -n "14 berkas" .github/workflows/sebar-skema.yml docs/ops/SIAP_AKUN_PEMILIK.md` → 0 hasil setelah diganti hitungan dinamis ("semua berkas `supabase/migrations/*.sql` yang belum ada di proyek")
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Hak tabel & fungsi yang tidak perlu tetap tertinggal: UPDATE `pengaturan` untuk ANON, trigger-function callable klien, CHECK `pin_hash` hanya cek bentuk
- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql` (`grant select, update on public.pengaturan to anon, authenticated`); `0015` bagian 8d/9b (`grant execute on function public.picu_pembayaran_jujur()/picu_pembatalan_sah()/picu_item_jaga()/picu_diskon_awal_pesanan() to authenticated` tanpa `revoke from public`); `0002` (CHECK `pin_hash ~ '^\$[a-z0-9]+\$'`)
- **Klaim yang dilanggar:** pola minimal-privilege yang dipraktikkan proyek sendiri di `0014`/`0016` ("revoke all … from public" untuk helper; pola `percobaan_simpan_pin_tolak_semua`)
- **Bukti:** `grep -n "grant select, update on public.pengaturan" supabase/migrations/0002_pengguna_izin_pengaturan.sql` → ada, dan TIDAK dicabut migrasi mana pun (0002 beku); pemindai state-final saya (§3 baris 1) menampilkan 7 trigger-function definer yang masih callable authenticated/PUBLIC; regex `~` di Postgres tidak terjangkar di ujung sehingga `$2b$10$…` lolos (benaran), tetapi bentuk `$abc$` pun lolos
- **Skenario gagal:** saat ini tidak ada eksploitasi nyata (RLS menolak semua aksi anon di `pengaturan`; trigger-function dipanggil langsung = no-op/error karena `new`/`old` null); risikonya adalah footgun: satu refactor yang menambahkan argumen ke trigger-function, atau satu policy anon yang kelak ditambahkan, langsung membuka jalan yang "seharusnya" sudah ditutup
- **Dugaan penyebab:** `0002` beku (dibekukan sejak 2026-09-19) sehingga pembersihan grant lama tidak bisa masuk di sana; `0014`/`0016` sudah mencabut grant serupa untuk fungsi lain (PR-14) tetapi trigger-function terlewat
- **Cara membuktikan perbaikan:** migrasi `0017+`: `revoke update on public.pengaturan from anon;` + `revoke all on function public.picu_*() from public, authenticated;` (trigger tidak butuh execute pihak luar); ganti CHECK `pin_hash` dengan regex terjangkar penuh `'^\$[a-z0-9]+\$[./A-Za-z0-9]{53}$'` atau hapus (jalur tulis sudah dipaksa `crypt+gen_salt` di `simpan_pin`)
- **Status verifikasi:** TERVERIFIKASI (pembacaan kode)

### [F-06] Email pribadi & ID akun Cloudflare pemilik terpampang di repo PUBLIK
- **Tingkat:** K-4
- **Artefak:** `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` baris A-04/A-05/A-06 (`fatrizmubarok@gmail.com`, Account ID `2b55bd03…`)
- **Klaim yang dilanggar:** lensa L6 (privasi) — repo PUBLIK sejak 2026-09-20 (keputusan Lee, tercatat di `STATUS.md`); berkas ini sengaja ikut Git, tetapi klasifikasi "non-rahasia" tidak otomatis berarti "aman dipublikasikan"
- **Bukti:** `grep -n "fatrizmubarok" docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` → 2 baris; `gh api repos/With-AI-Agent/Resto-Barokah` → `public: true`
- **Skenario gagal:** bukan celah keamanan langsung (bukan kredensial), tetapi email pribadi + ID akun di mesin publik memudahkan phishing/targeting terhadap pemilik; bila suatu hari email itu dipakai untuk layanan lain (Google Cloud), korelasinya memudahkan serangan beruntun
- **Dugaan penyebab:** berkas dirancang untuk "sesi kerja mana pun tahu akunnya" saat repo masih privat; status publik datang satu hari setelah berkas diisi
- **Cara membuktikan perbaikan:** keputusan pemilik: ganti A-04/A-06 dengan alias non-pribadi, atau pindahkan baris A-01…A-06 ke berkas `*.local.md` (diabaikan Git) dan biarkan di Git hanya URL proyek + kunci publik
- **Status verifikasi:** TERVERIFIKASI (pembacaan berkas + status repo)

### [F-07] Catatan PIN percobaan `percobaan_pin` bisa dibaca admin tanpa `kelola_pegawai`? — TIDAK, tetapi kolom `perangkat` milik korban tetap bocor ke kasir lewat policy sendiri
- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0006_pin.sql` (policy `percobaan_pin_pilih`: baris sendiri SELALU terlihat, termasuk `perangkat` dan `aksi` percobaan orang lain terhadap akunnya)
- **Klaim yang dilanggar:** — (penguatan: ini bukan pelanggaran aturan tertulis; dicatat karena lensa L1 meminta audit apa yang terbaca siapa)
- **Bukti:** policy: `using (pemanggil_id = auth.uid() or (pengguna_id = auth.uid() and …))` — pemilik akun melihat baris "siapa saja" yang mencoba PIN-nya (pengguna_id target = dirinya, pemanggil_id = penyerang) — itu memang dikehendaki (korban melihat pelakunya); efek samping: `perangkat` (teks bebas, sering kosong/'tidak-diketahui') tidak berguna forensik
- **Skenario gagal:** tidak ada — perilaku ini sesuai desain (uji `pin.sql` mengunci bahwa korban melihat catatannya); nilai forensiknya rendah hanya karena perangkat belum terdaftar (F-03)
- **Dugaan penyebab:** desain jujur: korban harus bisa melihat percobaan atas akunnya
- **Cara membuktikan perbaikan:** setelah T1-24: ganti kolom teks `perangkat` dengan FK `perangkat_id` sehingga baris ini benar-benar forensik
- **Status verifikasi:** TERVERIFIKASI (pembacaan kode; dilaporkan sebagai penguatan, bukan cacat)

## 5. Kalibrasi cacat tanaman

Saya memeriksa 5 berkas `docs/uji/kalibrasi/bahan-2026-09-17/` sebagai bahan latih (bukan kode proyek). Kunci jawaban berada di luar repo dan tidak saya cari — angka di bawah murni dari pembacaan saya.

**Ditemukan: 15 dari 15** (15 = jumlah cacat yang saya yakini ditanam). **Temuan palsu: 0.**

| # | Berkas | Cacat yang saya temukan | Bukti |
|---|---|---|---|
| 1 | `01_gerbang_izin.sql` | Komentar menuntut "hak execute dicabut dari public" tetapi TIDAK ADA `revoke` — fungsi gerbang izin (SECURITY DEFINER) callable PUBLIC/anon | baris 15: hanya `grant execute … to authenticated;`, tanpa `revoke all … from public;` |
| 2 | `01_gerbang_izin.sql` | `set search_path = public` — tanpa `pg_temp` (pelanggaran aturan proyek untuk semua definer) | baris 6 |
| 3 | `01_gerbang_izin.sql` | Panggilan `public.izin_efektif(p.id, p_aksi, p_cabang)` tidak cocok overload mana pun (uuid di depan, 3 argumen) — fungsi gagal dibuat | baris 12 vs `izin_efektif(text, uuid)` di proyek |
| 4 | `02_policy_pengaturan.sql` | `pengaturan_pilih … using (penyewa_id is not null)` — SEMUA authenticated membaca pengaturan SEMUA resto (bocor lintas penyewa) | baris 5-7 vs pola `penyewa_id = public.penyewa_saya()` di `0004` |
| 5 | `02_policy_pengaturan.sql` | `pengaturan_ubah` tanpa pemeriksaan `peran_saya() = 'owner_pusat'` — anggota biasa resto bisa mengubah pengaturan | baris 8-11 |
| 6 | `03_fungsi_terima_bayar.sql` | Guard lebih bayar `if v_sebelum > v_pesanan.total` LUPA menjumlah `p_jumlah` → pembayaran berlebih diterima (bertentangan bagian "Batas lebih bayar" di `04_panduan_singkat.md`) | baris 13-15 vs baris 22 (`v_sebelum + p_jumlah >= total`) |
| 7 | `03_fungsi_terima_bayar.sql` | Tidak ada pemeriksaan isolasi penyewa — SECURITY DEFINER callable authenticated dengan `p_pesanan` UUID bebas bisa "membayar" pesanan resto lain | baris 8-27 (tanpa `pesanan_sepenyewa`/`penyewa_saya`) |
| 8 | `03_fungsi_terima_bayar.sql` | Tidak ada pemeriksaan `status = 'batal'` — uang bisa dicatat pada pesanan yang sudah dibatalkan | baris 8-15 |
| 9 | `03_fungsi_terima_bayar.sql` | `select * into v_pesanan …` tanpa null-check — pesanan tak ada → perbandingan NULL melewatkan guard (gagal di FK, bukan di guard) | baris 9 |
| 10 | `04_panduan_singkat.md` | Langkah 1: `bash aplikasi/pratinjau.sh` — berkas itu TIDAK ADA (yang ada `aplikasi/alat/pratinjau.sh`) → langkah pengguna mustahil dijalankan | `ls aplikasi/pratinjau.sh` → No such file; `PANDUAN_PENGGUNA.md:617` memakai jalur benar |
| 11 | `04_panduan_singkat.md` | Langkah 3: `python3 alat/periksa-struktur.py` — jalur salah (yang benar `aplikasi/alat/periksa-struktur.py`) | `ls alat/periksa-struktur.py` → No such file |
| 12 | `04_panduan_singkat.md` | Kebijakan PIN "salah PIN **10 kali** → terkunci 15 menit" vs kenyataan 5×/akun & 12×/perangkat per 15 menit | `BATAS_AKUN constant integer := 5` di `0016:47`; `supabase/tes/pin.sql` mengunci 5 |
| 13 | `04_panduan_singkat.md` | Rujukan "Kebijakan lengkap ada di `docs/PANDUAN_KEAMANAN.md` §4" — berkas itu TIDAK ADA (yang ada `docs/KEAMANAN.md`) | `ls docs/PANDUAN_KEAMANAN.md` → No such file |
| 14 | `05_pemeriksa_ambang.py` | `MIN_LAYAR_DIPERIKSA = 5` padahal komentar baris yang sama bilang "ambang nyata proyek: 20" — gerbang dipertebal jadi longgar | baris 8 |
| 15 | `05_pemeriksa_ambang.py` | `glob("*.tsx")` hanya level atas `layar/`, padahal layar hidup di subfolder (`kasir/`, `dapur/`, …) → pemindaian menemukan 0 layar, mencetak SKIP, dan LULUS (exit 0) | `ls aplikasi/src/layar/` → hanya subfolder + README di level atas; `find aplikasi/src/layar -name '*.tsx' -maxdepth 2 -not -path '*/layar/*'` → 0 |

Pengamatan tambahan (tidak saya hitung dalam 15 karena ambigu apakah ditanam): `03` memakai nama kolom yang tidak ada di skema proyek (`metode`, `dibuat_oleh`; proyek memakai `metode_id`/`kasir_id`) sehingga INSERT-nya pasti gagal di skema nyata; `05` heuristik string `keadaan=…` lemah.

## 6. Yang tidak bisa saya verifikasi

- **Eksekusi SQL apa pun.** `node alat/uji-sql.mjs` gagal di `ERR_MODULE_NOT_FOUND: @electric-sql/pglite` (pustaka tidak terpasang; memasang dilarang oleh mandat), tidak ada `psql`/`sqlite3` di sandbox. Konsekuensi: 58 berkas `supabase/tes`, 4 harness mutasi (`uji-mutasi-0012/0014/0015/0016.py`), dan semua probe dinamis TIDAK saya jalankan — verifikasi SQL-nya statis (pembacaan kode + grep + penalaran logika). Bukti dinamis terakhirnya ada di CI target (run `35518950919` hijau, §2 baris 12) dan tidak saya ulang.
- **Uji aplikasi (`npm test`/`typecheck`/`lint`/`build`).** `aplikasi/node_modules` tidak ada dan install dilarang. 97 uji unit (10 berkas) tidak saya eksekusi — saya baca konfigurasi vitest, hitung uji, dan memeriksa 3 pemeriksa kerangka (`periksa-uji.py`, `uji-kontras.py`, `periksa-komponen-env.py` — semuanya hijau).
- **Konektivitas live** ke `*.supabase.co` dan `*.workers.dev`: sandbox tidak punya egress ke host itu (`curl` → HTTP 000). Klaim T0-08/T0-09 saya verifikasi lewat **catatan CI di GitHub API** (run `35432334878`, `35440300274`, `35440432817`, `35516000988` — semua `success`), bukan lewat HTTP langsung.
- **Uji concurrency nyata** (dua transaksi bersamaan untuk nomor pesanan/`hitung_total`): PGlite satu koneksi — batasan yang diakui proyek sendiri (F F-13, F-12 → T1-45); mitigasi `pg_advisory_xact_lock` + `for update` saya verifikasi ada di kode, tidak diuji beban.
- **Tampilan visual** (kontras di peramban, kerapatan, font render): tidak ada peramban; substitusi mesin = `aplikasi/alat/uji-kontras.py` (166 pemeriksaan warna/aturan, 0 gagal) + `periksa-kerapatan.py` (dijalankan CI).
- **Quirk alat:** `audit-independen.py --verifikasi-lingkup` membandingkan HEAD dengan paket terbaru DI POHON (2026-09-19, target `93a50ba`), bukan dengan paket audit ini (yang masuk pohon di `cfc6097`) → output `BEDA COMMIT` menyesatkan; saya memverifikasi commit target dengan `git rev-parse HEAD` + `git status --short` + `gh api` (§1).

## 7. Pernyataan tidak mengubah apa pun

Saya bekerja hanya-baca pada commit `cbba40108fa17eca39a438cd25588f23807873fd` (detached) dan **tidak mengubah** berkas apa pun selain laporan ini — laporan ini satu-satunya berkas yang saya buat. Alat yang saya jalankan semuanya read-only terhadap repo (pemeriksa Python cetak hasil; `gh api` hanya GET; tidak ada `npm install`, tidak ada penulisan `node_modules`, tidak ada perubahan migrasi/tes/dokumen). Bukti: `git status --short` menampilkan hanya `?? docs/uji/audit/LAPORAN_AUD-3_2026-09-20_menyeluruh__01a0bf6d.md` (setelah laporan ditulis) dan `git diff --stat` kosong.

## 8. Temuan di luar cakupan

(Seluruhnya sudah terlacak di `docs/uji/AUDIT_RIWAYAT.md` — saya memverifikasi masih terbuka, bukan temuan baru.)

| # | Temuan | Mengapa di luar cakupan sebagai temuan BARU | Bukti | Syarat dilanjutkan |
|---|---|---|---|---|
| 1 | F F-12 (K-1 dugaan): hitung ulang uang tanpa serialisasi eksplisit | Sudah tercatat terbuka di buku proyek dengan owner tugas; mitigasi `for update` ada di `0015:474-479`; pembuktiannya butuh dua transaksi nyata yang tidak bisa saya jalankan (§6) | `docs/uji/AUDIT_RIWAYAT.md` baris F F-12; `grep -n "for update" supabase/migrations/0015_penutup_celah_putaran16.sql` | T1-45 (uji concurrency saat lingkungan uji mendukung) |
| 2 | F F-13 (K-2): `nomor_pesanan_berikutnya` `max()+1` | Terlacak; mitigasi `pg_advisory_xact_lock` + fungsi VOLATILE ada (`0015:1078-1113`); uji concurrency belum bisa dijalankan di PGlite | `grep -n "pg_advisory_xact_lock" supabase/migrations/0015_penutup_celah_putaran16.sql` | T1-45 |
| 3 | A F-07 (K-2): kontrol `docs/KEAMANAN.md` (perangkat, TOTP, pencabutan sesi, rantai hash audit) belum ada di kode | Fitur Fase 1B/Fase 8 yang memang dijadwalkan (T1-24…T1-30, T1-27) — bukan cacat yang disembunyikan; F-01 laporan ini adalah sisi DOKUMEN dari gap yang sama | `docs/uji/AUDIT_RIWAYAT.md` baris A F-07; `grep -rl "totp\|perangkat" supabase/migrations/` → 0 | T1-24/T1-25/T1-26/T1-27 (ROADMAP) |
| 4 | F F-07 / F F-08 / F F-09 (K-2): `catatan_audit`, perangkat terdaftar/MFA, kontrak privasi pelanggan belum dibangun | Di luar diff audit; tugas fase berikutnya (T1-13, T1-24…T1-26, T8-01) — fitur, bukan cacat | `docs/uji/AUDIT_RIWAYAT.md` baris F F-07/08/09 | sesuai ROADMAP |
| 5 | B F-14 (K-3): sapuan isolasi lintas resto hanya tabel ber-`penyewa_id` + pencocokan teks | Terlacak (T1-22); uji `rls_semua_tabel.sql` memang membaca katalog (seluruh tabel), tetapi aturan "policy harus menyebut penyewa" masih heuristik | `supabase/tes/rls_semua_tabel.sql` (dibuka) | T1-22 |
| 6 | D F-09 / D F-10 (K-4): rasio `harap_gagal` lemah vs `harap_gagal_sebab`; pesan diskon menunjuk alur yang belum ada | Terlacak (T1-45); kualitas uji, bukan celah keamanan | `docs/uji/AUDIT_RIWAYAT.md` baris D F-09/F-10 | T1-45 |
| 7 | F F-17 (K-3): mekanisme paket audit lama tidak mengikat commit mandat | Terlacak (T1-44) dan memang yang saya alami: `--verifikasi-lingkup` memilih paket in-tree terbaru, bukan paket audit ini (§1, §6) | `python3 alat/audit-independen.py --verifikasi-lingkup` (output `BEDA COMMIT` terhadap paket 2026-09-19) | T1-44 |
| 8 | Kunci jawaban kalibrasi | Berada di luar repo (di luar mandat saya; tidak saya cari — PROTOKOL §7) | `docs/uji/kalibrasi/CARA-PAKAI.md` | — |

**Penutup.** Sistem ini menunjukkan disiplin pertahanan yang jarang: setiap lapisan (RLS → trigger → grant → fungsi → Edge → CI → buku temuan) punya jejak "kenapa" yang dapat diaudit, dan 17 temuan terbuka semuanya ber-owner tugas. Tetapi verdict `TIDAK-BERSIH` adalah konsekuensi aturan, bukan penilaian: ada satu K-2 TERVERIFIKASI (F-01) dan satu jalur uang K-1 yang masih terbuka (F-02, DUGAAN). Setelah `T1-45` menutup F-02 + buku insiden diselaraskan (F-01) dan item §8 mendarat, dasar untuk `BERSIH` ada — dengan catatan pembuktian dinamis (uji SQL, uji concurrency) harus dijalankan di lingkungan yang memiliki PGlite/Supabase nyata, bukan hanya dibacakan.