# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-17

- **Auditor:** Arena.ai Agent Mode (sesi `arena/01a0aeb0-resto-barokah` — sesi terpisah dari sesi pembangun)
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `442913e4b7ae6d09ed060fe17dd90fa499d449b3`
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-17.md`
- **Mode cakupan:** menyeluruh
- **Verdict:** TIDAK-BERSIH
- **Alasan commit berbeda:** HEAD repo sesi = `253d1297a3b81433d7f5809afd257d8a1b40958f` (sistem template); commit target hanya ada di cabang lain. Audit dijalankan di worktree terpisah `git worktree add --detach /home/user/audit-442913e4 442913e4…` supaya berkas sesi tidak tersentuh; seluruh perintah di laporan ini dijalankan di dalam worktree itu.

## 1. Cakupan

Cakupan menyeluruh: 334 dari 334 berkas (mode menyeluruh; `python3 -c "import importlib.util; … kelompokkan_berkas()"` → 17 grup, 334 berkas; dikecualikan oleh paket: `skills/` 1802, `_salinan-meta/` 2, `_Notes.md` 1 — **saya setuju** dengan pengecualian itu, alasannya di bagian 6).

Arti "Diperiksa" di tabel ini: berkas tersentuh bukti yang benar-benar dijalankan/dibaca — yaitu (a) dijalankan atau diurai pemeriksa otomatis (Prettier/ESLint/tsc/Vitest/kontras/uji-SQL/pemeriksa Python), (b) dibaca isinya, atau (c) dipindai pemeriksaan properti untuk seluruh repo (pemindai rujukan mati, pemindai rahasia, `git ls-files`, inventaris). Ini **bukan** klaim bahwa setiap baris saya baca manual; batasnya ditulis di bagian 6.

| # | Grup (paket §0) | Berkas | Diperiksa | Bukti (perintah atau berkas:baris) |
|---|---|---|---|---|
| 1 | aplikasi/src | 67 | 67 | `cd aplikasi && npm test && npm run lint && npm run typecheck` → 51 uji lulus, ESLint & tsc bersih |
| 2 | aplikasi/alat | 6 | 6 | `python3 aplikasi/alat/periksa-struktur.py` · `periksa-komponen-env.py` · `periksa-uji.py` · `uji-kontras.py` · 2 skrip bash dibaca |
| 3 | aplikasi (konfigurasi) | 16 | 16 | `cd aplikasi && npm run format:check && npm run build` → Prettier bersih, build EXIT=0 |
| 4 | supabase/migrations | 11 | 11 | `node alat/uji-sql.mjs --daftar` → 10 migrasi diterapkan; 10 berkas .sql dibaca penuh + `.gitkeep` |
| 5 | supabase/tes | 11 | 11 | `node alat/uji-sql.mjs` → `uji: 10 LULUS · 0 GAGAL` (semua berkas uji dieksekusi) |
| 6 | supabase/functions | 2 | 2 | `cat supabase/functions/verifikasi_pin/index.ts` (94 baris) + `.gitkeep` |
| 7 | alat | 24 | 24 | `python3 alat/audit-independen.py --uji-diri` → LOLOS; 8 alat dijalankan; `audit-independen.py` dibaca penuh |
| 8 | _sistem | 16 | 16 | `python3 _sistem/validate_system.py` → PASS |
| 9 | docs (fondasi) | 11 | 11 | `python3 alat/periksa-fondasi-independen.py` → BERSIH; PRD/TECH_SPEC/KEAMANAN/DECISIONS_LOG dibaca & dicari |
| 10 | docs/uji | 26 | 26 | `python3 alat/periksa-panduan.py` → LOLOS; paket audit + protokol + bahan kalibrasi dibaca |
| 11 | docs/teknis | 6 | 6 | pemindai rujukan-mati + `grep -rn` (BUKU_INSIDEN.md:131, USULAN_KEAMANAN §B1, REKAM_PESAN_PEMILIK) |
| 12 | docs/ops | 1 | 1 | `docs/ops/SIAP_AKUN_PEMILIK.md` dibaca (20 baris pertama + pencarian klaim) |
| 13 | docs/desain | 59 | 59 | inventaris berkas + `python3 aplikasi/alat/uji-kontras.py` → 166 lolos (10 tema, 19 huruf woff2) |
| 14 | prototipe | 58 | 58 | `python3 prototipe/alat/periksa-halaman.py` → `183/183 lolos` |
| 15 | _log-sesi | 3 | 3 | pemindai rahasia `git grep -nIE …` (7 kena di LOG_SESI_2026-09-16.md) + pembacaan bagian |
| 16 | berkas pengguna di akar | 16 | 16 | `git ls-files` + pemindai rujukan-mati + `python3 _sistem/validate_system.py` → PASS |
| 17 | .github/workflows | 1 | 1 | `cat .github/workflows/ci.yml` + `gh api repos/…/actions/runs/35121292973/jobs` |

### 1a. Berkas untuk pengguna

| # | Berkas | Diperiksa | Bukti |
|---|---|---|---|
| 1 | `PANDUAN_PENGGUNA.md` (647 baris) | ya | `python3 alat/periksa-panduan.py` → LOLOS · 2 catatan berkas rencana |
| 2 | `START_DI_SINI.md` | ya | pemindai rujukan-mati → 6 rujukan pendek (konteks folder `docs/`, lihat F-08) |
| 3 | `STATUS.md` | ya | `sed -n '1,12p' STATUS.md` → status `coding-aktif`, Fase 1 dijeda di T1-10 (cocok dengan `PROJECT_STATE.md`) |
| 4 | `PROJECT_STATE.md` | ya | `sed -n '1,20p' PROJECT_STATE.md` → STATUS `CODING_DIJEDA_SADAR`, SELANJUTNYA menunjuk AUD-3 |
| 5 | `SYSTEM_MANIFEST.md` | ya | `grep -n 'TECH_SPEC' SYSTEM_MANIFEST.md` + pemindai rujukan-mati → 12 rujukan mati (F-08) |
| 6 | `AGENT_SYSTEM.md` | ya | pemindai rujukan-mati → `supabase/migrations/001_users.sql`, `src/lib/supabase.ts` tidak ada |
| 7 | `PANDUAN_PEMAKAIAN.md` | ya | `head -20 PANDUAN_PEMAKAIAN.md` + `python3 alat/periksa-panduan.py` → LOLOS |
| 8 | `PROMPT_ENTRI_UNIVERSAL.md` | ya | dibaca (bagian pemulihan ruang kerja, `aplikasi/alat/pratinjau.sh` benar) |
| 9 | `10_LOG_SESI.md` · `REKAM-KLINIK.md` · `PROFIL_PENGGUNA.md` · `ACCEPTANCE_TESTS.md` · `ACCEPTANCE_TEST_LOG.md` · `.gitignore` | ya | `git ls-files` + pemindai rahasia + `git check-ignore -v aplikasi/.env` → `aplikasi/.gitignore:4:.env` |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | Klaim #14 T1-06: “PIN disimpan hanya sebagai hash … tidak ada fungsi yang mengembalikan hash” | sebagai kasir: `select nama, substr(pin_hash,1,14) from public.pengguna` | **DIBANTAH** — `[{"nama":"Rina","awalan_hash":"$tiruan$10$eb2"}]` (F-02) |
| 2 | Klaim #14 T1-06 + KEAMANAN.md §6.6: “ganti PIN sendiri wajib PIN lama” | `select public.simpan_pin('8888', null, '<uuid sendiri>', 'hp-uji')` sebagai kasir yang sudah punya PIN | **DIBANTAH** — `"PIN tersimpan."`; lalu `verifikasi_pin(…,'8888')` → `berhasil=true` (F-01) |
| 3 | Klaim #14 T1-06: “PIN benar belum cukup untuk aksi — persetujuan lewat `boleh_untuk()`” | insert `pembatalan` `tahap='sesudah_dapur'`, `disetujui_oleh=<owner>` sebagai kasir tanpa PIN | **DIBANTAH** — DITERIMA, `nilai_kerugian: 54000` (F-03) |
| 4 | Klaim #18 T1-10: “pembayaran tidak boleh melebihi total pesanan” | 2× insert pembayaran Rp 1.000.000 pada pesanan baru (total 0) | **DIBANTAH** — `{dibayar: 2000000, total_pesanan: 0}` (F-04) |
| 5 | Klaim #18 T1-10: identitas pelaku uang diisi sistem | insert `pembayaran.kasir_id`/`diskon_transaksi.pelaku_id` = pegawai lain | **DIBANTAH** — DITERIMA, atribusi palsu (F-05) |
| 6 | Klaim #15 T1-07: “stok hanya berubah lewat catatan pergerakan stok” | `select set_config('app.stok_dari_buku_besar','1',true)` lalu `update public.stok_bahan set jumlah=999` | **DIBANTAH** — DITERIMA `jumlah: "999.000"` (F-06) |
| 7 | `docs/KEAMANAN.md` §1.4 (dokumen “BERLAKU”, “mengikat”): PIN hanya sah di perangkat terdaftar; pencabutan diperiksa di database setiap permintaan | `grep -rlE "create table (if not exists )?public\.(perangkat|sesi_perangkat|catatan_audit)\b" supabase/migrations/` | **DIBANTAH** — tidak ada satu pun tabel itu; skema berhenti di `0010` (F-07) |
| 8 | Klaim #4 T0-04: `uji-kontras.py` 166 lolos · 0 gagal; 10 komponen ada | `python3 aplikasi/alat/uji-kontras.py` | **TIDAK DIBANTAH** — `RINGKASAN: 166 lolos, 0 gagal - 10 tema, 130 pemeriksaan warna, 36 aturan desain` (exit 0) |
| 9 | Klaim #4 T0-04: 17 uji komponen + 22 uji lain hijau | `cd aplikasi && npm test` | **TIDAK DIBANTAH** — `Test Files 7 passed (7) · Tests 51 passed (51)` |
| 10 | Klaim #7 T0-07: run `35121292973` MERAH di langkah ESLint | `gh api repos/With-AI-Agent/Resto-Barokah/actions/runs/35121292973/jobs` | **TIDAK DIBANTAH** — job `Periksa` conclusion=failure, `LANGKAH GAGAL=['Aturan kode (ESLint)']`, head 538ccb45 |
| 11 | Klaim #12 T1-04: uji membaca katalog PostgreSQL, tabel baru otomatis diperiksa | `node alat/uji-sql.mjs --daftar` | **TIDAK DIBANTAH** — 23 tabel, semua `RLS=ya` + berpolicy; `10 LULUS · 0 GAGAL` |
| 12 | Klaim #17 T1-09: salinan beku `nama_saat_itu`/`harga_saat_itu` tidak bisa diubah | `update public.pesanan_item set harga_saat_itu=1` sebagai kasir | **TIDAK DIBANTAH** — ditolak `Nama & harga yang sudah tercatat tidak boleh diubah.` |
| 13 | Klaim #13 T1-05: gerbang tunggal `boleh(aksi, nominal, persen)` menegakkan batas diskon | insert diskon Rp 54.000 & Rp 1.000 sebagai kasir (batas kasir 25.000/5 %) | **TIDAK DIBANTAH** untuk batas nominal (`Diskon ini melebihi batas izin Anda`) — cacatnya ada di identitas penyetuju, bukan di batas (F-03/F-05) |
| 14 | Klaim #10 T1-02 & #1 penyewa: isolasi antar-resto | 12 tabel ber-`penyewa_id` + 11 tabel anak dibaca sebagai kasir resto A, lalu lintas-cabang | **TIDAK DIBANTAH** — hanya baris restonya; lintas resto 0 baris; lintas cabang 0 baris (S10–S12) |
| 15 | Klaim #5 T0-05: rahasia tidak ada di klien, hanya 2 variabel publik aktif | `python3 aplikasi/alat/periksa-komponen-env.py` + pemindai rahasia repo | **TIDAK DIBANTAH** — `10 OK · 0 GAGAL`; terpisah dari itu, 5 kerentanan dev-dependency dicatat di F-09 |
| 16 | Klaim #6 T0-06: langkah README (npm ci → uji → build) hijau di tempat bersih | `npm ci` + `npm run format:check` + `npm run build` | **TIDAK DIBANTAH** — `✓ built in 1.19s`, EXIT=0 |
| 17 | Klaim #1 T0-01: `npm run dev` melayani halaman (HTTP 200) + favicon SVG | tidak dijalankan (dev server tidak saya nyalakan) | **TIDAK DIUJI** — ditulis apa adanya di bagian 6 |

Ringkas: **7 klaim DIBANTAH** (#1-#7 di atas) yang melahirkan 6 temuan K-1/K-2 (F-01…F-07); #13 ditinjau dan terbukti benar pada bagian batasnya; sisanya tidak terbantah atau tidak diuji.

## 3. Serangan yang dijalankan (kill attempts)

Semua serangan dijalankan pada klon lokal skema (PGlite = PostgreSQL asli dikompilasi ke WASM) dengan peran `anon` / `authenticated` + `auth.uid()` tiruan, di dalam **satu transaksi dengan SAVEPOINT per serangan** lalu di-rollback. Perkakas serangan saya simpan di luar repo (`/tmp/serang/…`) karena audit ini hanya-baca.

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | anon memanggil fungsi istimewa | `select public.verifikasi_pin(…)/catat_stok(…)/simpan_pin(…)` sebagai anon | ditolak `permission denied` (fungsi `SECURITY DEFINER` sudah di-revoke) |
| 2 | anon membaca tabel | `select count(*)` pada 23 tabel sebagai anon | 0 baris atau `permission denied`; tidak ada kebocoran |
| 3 | anon membaca `izin_kode` (katalog global) | `select count(*) from public.izin_kode` sebagai anon | 0 baris (policy hanya untuk `authenticated`) |
| 4 | kasir mengganti PIN sendiri tanpa PIN lama | `simpan_pin('8888', null, '<id sendiri>', 'hp-uji')` | **DITERIMA** → “PIN tersimpan.” (S4 · F-01) |
| 5 | kasir mengganti PIN lewat `ganti_pin` dengan PIN lama salah | `select public.ganti_pin('0000','7777')` | ditolak `PIN lama salah.` (jalur ini benar — jadi cacatnya spesifik di `simpan_pin`) |
| 6 | kasir membaca hash PIN rekan | `select nama, substr(pin_hash,1,14) from public.pengguna` | **DITERIMA** → `$tiruan$10$eb2…` (S5b · F-02) |
| 7 | kasir membatalkan pesanan sesudah dapur dengan penyetuju palsu | insert `pembatalan(tahap='sesudah_dapur', disetujui_oleh=<owner>)` | **DITERIMA** → `nilai_kerugian 54000` (S6a · F-03) |
| 8 | kasir membatalkan sesudah dapur tanpa penyetuju | insert tanpa `disetujui_oleh` | ditolak `…wajib disetujui pengguna berizin (PIN)` |
| 9 | kasir mengaku disetujui pelayan (tanpa izin) | `disetujui_oleh=<pelayan>` | ditolak (pemeriksaan izin penyetuju jalan; yang tidak ada adalah pembuktian persetujuan) |
| 10 | kasir menerima uang melebihi total (total masih 0) | 2× insert `pembayaran` Rp 1.000.000 | **DITERIMA** → `{dibayar: 2000000, total: 0}` (S6b · F-04) |
| 11 | kasir mencatat pembayaran melebihi total (total terisi 62.100) | insert pembayaran 20.000 setelah 50.000 | ditolak `Total pembayaran … melebihi total pesanan` |
| 12 | kasir menulis nama kasir lain di baris pembayaran | insert dengan `kasir_id=<owner>` | **DITERIMA** → atribusi palsu (S6c · F-05) |
| 13 | kasir menulis nama pelaku diskon lain | insert `diskon_transaksi` dengan `pelaku_id=<owner>` | **DITERIMA** → atribusi palsu (F-05) |
| 14 | kasir mengubah total pesanan langsung | `update public.pesanan set total=1` | ditolak penjaga `total` hanya-boleh-peladen |
| 15 | dapur mengubah stok langsung | `update public.stok_bahan set jumlah=999` | ditolak `Jumlah stok hanya boleh berubah lewat catatan pergerakan stok` |
| 16 | dapur memalsukan “berasal dari buku besar” | `set_config('app.stok_dari_buku_besar','1',true)` lalu update stok | **DITERIMA** → `jumlah: "999.000"` (S8 · F-06) |
| 17 | dapur mencatat stok lintas penyewa | `catat_stok` dengan `penyewa_id` resto lain | ditolak |
| 18 | pelayan menulis `stok_pergerakan` langsung | `insert into public.stok_pergerakan` | ditolak RLS |
| 19 | kasir resto A membaca 12 tabel ber-`penyewa_id` | `select *` di `penyewa, cabang, pengguna, pengaturan, izin_peran, kategori_menu, menu_item, menu_tambahan, stok_bahan, stok_pergerakan, metode_bayar, pesanan` | hanya baris resto A; resto B tidak terlihat |
| 20 | kasir resto A membaca 11 tabel anak tanpa `penyewa_id` | `select count(*)` di `pengguna_cabang, izin, izin_kode, menu_varian, menu_cabang, pesanan_item, pembayaran, diskon_transaksi, pembatalan, percobaan_pin, meja` | hanya baris cabangnya; jumlah ≤ jumlah nyata (S11) |
| 21 | kasir cabang A1 menyentuh pesanan/meja cabang A2 (resto sama) | `select`/`update` pesanan cabang A2 | 0 baris; mencatat pembayarannya ditolak RLS |
| 22 | dapur menaikkan harga cabang | `update public.menu_cabang set harga=…` | ditolak `Menetapkan/mengubah harga hanya boleh oleh owner pusat atau admin cabang.` |
| 23 | kasir & owner mengubah/menghapus jejak uang | `update`/`delete` pada `pembayaran, pembatalan, stok_pergerakan, pesanan_item` | semua ditolak `permission denied` / penjaga salinan beku (jejak uang benar-benar append-only) |
| 24 | PIN ditebak berulang | 7× `verifikasi_pin` salah lalu 1× PIN benar | terkunci setelah 5 salah; PIN benar pun ditolak `PIN terkunci sementara … 15 menit` (S15) |
| 25 | owner resto A memverifikasi PIN pegawai resto B | `verifikasi_pin(<pegawai B>, '4321')` sebagai owner A | `berhasil=false`, `PIN tidak dikenali.` |
| 26 | akun dinonaktifkan mencoba bekerja | `update pengguna set aktif=false` lalu akses sebagai akun itu | 0 baris & `boleh()` false (klaim “nonaktif = cabut seketika” bertahan) |
| 27 | pemilik platform membaca data penyewa | `select count(*) from public.penyewa / pesanan / pengguna` sebagai pemilik platform | 1 baris (dirinya), 0 penyewa, 0 pesanan → peran ada tetapi tanpa jalan dukungan (bagian F-07) |
| 28 | `boleh(aksi)` tanpa cabang dipakai untuk naik hak | `boleh('tutup_kas'/'beri_diskon'/'ubah_stok'/'kelola_pegawai')` untuk kasir, pelayan, owner | nilai sesuai izin peran (kasir: tutup_kas & beri_diskon true, ubah_stok & kelola_pegawai false) — **tidak ditemukan eskalasi** |

## 4. Temuan

| Kode | Judul | Tingkat | Status |
|---|---|---|---|
| F-01 | PIN sendiri bisa diganti tanpa PIN lama → persetujuan bisa dipalsukan | K-2 | TERVERIFIKASI |
| F-02 | Kolom `pin_hash` bisa dibaca pegawai lain | K-2 | TERVERIFIKASI |
| F-03 | Void sesudah dapur dengan penyetuju yang tidak pernah menyetujui (tanpa PIN) | K-2 | TERVERIFIKASI |
| F-04 | Pembayaran melebihi total diterima saat total masih 0, dan tidak bisa dibatalkan | K-1 | TERVERIFIKASI |
| F-05 | Identitas pelaku/penyetuju di tiga tabel bisa dipalsukan klien | K-2 | TERVERIFIKASI |
| F-06 | Penjaga stok bisa dilewati dengan GUC `app.stok_dari_buku_besar` | K-2 | TERVERIFIKASI |
| F-07 | Kontrol wajib `docs/KEAMANAN.md` (perangkat, sesi, TOTP, mode dukungan, rantai hash) belum ada di kode | K-2 | TERVERIFIKASI |
| F-08 | Rujukan mati di dokumen yang mengikat (alat pemeriksa & berkas yang tidak ada) | K-3 | TERVERIFIKASI |
| F-09 | 5 kerentanan dependency dev (1 critical, 1 high) dan CI tidak memeriksanya | K-3 | TERVERIFIKASI |
| F-10 | Uji batas lebih bayar hanya ada untuk total > 0 → lubang nyata lolos dari 10 LULUS | K-3 | TERVERIFIKASI |

### [F-01] PIN sendiri bisa diganti tanpa PIN lama → persetujuan bisa dipalsukan

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0006_pin.sql:222` (penjaga `simpan_pin`), dipakai `supabase/functions/verifikasi_pin/index.ts:58-79`
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §6 butir 6 (“Ganti PIN sendiri wajib PIN lama”) dan klaim #14 paket (T1-06, “PIN disimpan hanya sebagai hash … persetujuan lewat `boleh_untuk()`”)
- **Bukti:** `node /tmp/serang/02-akses-pin.mjs /home/user/audit-442913e4` → `DITERIMA select public.simpan_pin('8888', null, '90000000-…-0004','hp-uji') → "PIN tersimpan."` lalu `verifikasi_pin(…,'8888',null,'hp-uji') → {berhasil:true, pesan:"PIN diterima."}`; bandingkan jalur benar `select public.ganti_pin('0000','7777')` → `PIN lama salah.`
- **Skenario gagal:** pegawai membuka aplikasi di perangkat kasir yang tidak terkunci → memanggil RPC `simpan_pin('8888', null, <uuid akun owner>, …)` (uuid boleh miliknya sendiri sesuai bentuk yang dikirim Edge Function) → PIN baru terpasang tanpa PIN lama → memakai akun itu untuk menyetujui void/diskon besar; jejak audit menulis nama owner, bukan pelakunya.
- **Dugaan penyebab:** syarat di baris 222 hanya menyala bila `p_pengguna_id is null`; ketika pemanggil mengirim uuid dirinya sendiri, `v_target = v_saya` tetap benar tetapi cabang pemeriksaan PIN lama dilewati, dan karena `v_target = v_saya` blok `kelola_pegawai` juga tidak menyala.
- **Cara membuktikan perbaikan:** jalankan uji baru di `supabase/tes/pin.sql` — sebagai kasir yang sudah punya PIN, `select public.simpan_pin('8888', null, '<uuid sendiri>', 'hp')` harus GAGAL dengan pesan PIN lama salah — lalu `node alat/uji-sql.mjs` harus tetap `10 LULUS · 0 GAGAL`.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Kolom `pin_hash` bisa dibaca pegawai lain

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql` (grant tabel `pengguna`), `supabase/migrations/0006_pin.sql` (kolom `pin_hash`)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §6 butir 2-3 (“Disimpan hanya sebagai hash bcrypt … tidak ada fungsi yang mengembalikan hash”) dan klaim #14 paket
- **Bukti:** `node /tmp/serang/02-akses-pin.mjs /home/user/audit-442913e4` → sebagai kasir: `select nama, substr(pin_hash,1,14) from public.pengguna` → `[{"nama":"Rina","awalan_hash":"$tiruan$10$eb2"}]`; admin cabang melihat rekan-rekannya, owner pusat melihat seluruh restonya, kasir resto B nihil.
- **Skenario gagal:** siapa pun yang bisa masuk sebagai pegawai (PIN rendah / perangkat tidak terkunci) menarik seluruh hash PIN rekan sedaerah → brute-force offline 4-6 angka (ruang 10^4-10^6) tanpa kena batas percobaan 5× karena batas itu hanya berlaku di fungsi `verifikasi_pin`, bukan pada hash yang sudah dicuri; hasilnya dipakai untuk menyetujui void/diskon atas nama atasan.
- **Dugaan penyebab:** RLS hanya menyaring baris, bukan kolom; `grant select` diberikan pada tingkat tabel sehingga seluruh kolom `pengguna` (termasuk `pin_hash`) terekspos lewat API otomatis Supabase/PostgREST. Supabase mendokumentasikan bahwa RLS tidak membatasi kolom dan pengecualian kolom harus lewat hak istimewa tingkat kolom — lihat https://supabase.com/docs/guides/database/postgres/column-level-security (dan catatan PostgreSQL bahwa cabut tingkat kolom tidak membatalkan grant tingkat tabel: https://www.postgresql.org/docs/current/sql-grant.html).
- **Cara membuktikan perbaikan:** sebagai kasir, `select pin_hash from public.pengguna` harus GAGAL (kolom dicabut / diganti tampilan `pengguna_aman`), lalu `node alat/uji-sql.mjs` tetap 10 LULUS dan `python3 alat/periksa-fungsi-pin.py` tetap 9 lolos (pemeriksa itu saat ini memeriksa berkas, bukan hak kolom).
- **Status verifikasi:** TERVERIFIKASI (catatan: di klon lokal hash-nya `$tiruan$`; di Supabase hash bcrypt sungguhan — serangan tetap berlaku karena yang dicuri adalah hash, bukan PIN)

### [F-03] Void sesudah dapur dengan penyetuju yang tidak pernah menyetujui (tanpa PIN)

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql` (`picu_pembatalan_sah`, `disetujui_oleh`), `supabase/migrations/0006_pin.sql` (`verifikasi_pin` tidak pernah dipanggil dari pemicu)
- **Klaim yang dilanggar:** klaim #14 paket (“persetujuan lewat `boleh_untuk()`”, “PIN benar belum cukup untuk aksi”), PRD Aturan Bisnis void bertingkat, `docs/KEAMANAN.md` §6 butir 5
- **Bukti:** `node /tmp/serang/03-uang-approval.mjs /home/user/audit-442913e4` → sebagai kasir (yang `void_sesudah_dapur=false`): `insert into public.pembatalan (pesanan_id, tahap, alasan, disetujui_oleh) values (<pesanan>, 'sesudah_dapur', 'uji', '<owner>')` → **DITERIMA**, `nilai_kerugian: 54000`; hanya bentuk tanpa `disetujui_oleh` dan penyetuju tanpa izin yang ditolak.
- **Skenario gagal:** kasir membatalkan pesanan yang sudah dimasak (kerugian bahan tercatat sebagai “bahan terbuang”) lalu menuliskan nama owner sebagai penyetuju tanpa owner menyentuh perangkat; laporan harian menampilkan void yang “disetujui atasan”.
- **Dugaan penyebab:** pemicu memanggil `boleh_untuk(new.disetujui_oleh, …)` — yaitu memeriksa apakah orang itu **berwenang**, bukan apakah orang itu **menyetujui**; tidak ada bukti PIN/`percobaan_pin` yang diikat ke baris pembatalan.
- **Cara membuktikan perbaikan:** uji baru di `supabase/tes/pembatalan` (atau `supabase/tes/pembayaran.sql`) — insert `pembatalan` sesudah dapur tanpa token persetujuan yang sah harus GAGAL — lalu `node alat/uji-sql.mjs` harus tetap `10 LULUS · 0 GAGAL`.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Pembayaran melebihi total diterima saat total masih 0, dan tidak bisa dibatalkan

- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:292-299` (`picu_pembayaran_jujur` melewati batas bila `coalesce(total,0) > 0` salah); `hitung_total` (T1-15) belum ada
- **Klaim yang dilanggar:** klaim #18 paket (“pembayaran tidak boleh melebihi total pesanan”); `docs/PANDUAN_PENGGUNA.md` (batas lebih bayar); dokumen kalibrasi mengulang janji yang sama
- **Bukti:** `node /tmp/serang/03-uang-approval.mjs /home/user/audit-442913e4` → sebagai kasir pada pesanan baru: 2× `insert into public.pembayaran (… jumlah 1000000 …)` → DITERIMA; `select coalesce(sum(jumlah),0) from public.pembayaran` → `{dibayar: 2000000}`, sedangkan `select total from public.pesanan` → `0`.
- **Skenario gagal:** kasir (atau perangkat yang disalahgunakan) mencatat uang masuk dua kali lipat/lebih; karena `total` pesanan masih 0 sampai `hitung_total()` dikerjakan (T1-15 belum ada di commit ini), seluruh alur kasir berjalan dengan total 0 → tidak ada satu pun penjaga yang menghentikan; baris uang itu **tidak bisa diubah dan tidak bisa dihapus oleh peran apa pun** (serangan #23), jadi kelebihan bayar tidak punya jalan pemulihan di aplikasi → laporan kas dan setoran tidak akan cocok dengan uang fisik.
- **Dugaan penyebab:** komentar di kode mengakui pemeriksaan “dilewati supaya pencatatan tidak macet — angka total dihitung ulang di T1-15”; kompensasi itu diterima sebagai keadaan sementara oleh builder, tetapi pada commit yang diaudit tidak ada `hitung_total()` maupun penjaga pengganti, sehingga lubangnya terbuka di sistem yang sudah dipakai.
- **Cara membuktikan perbaikan:** setelah `hitung_total()` ada, uji baru di `supabase/tes/pembayaran.sql` — pesanan baru (total 0) yang menerima pembayaran > 0 harus memicu perhitungan total lebih dulu atau DITOLAK; jalankan `node alat/uji-sql.mjs` dan pastikan masih `10 LULUS · 0 GAGAL` dengan uji baru itu ikut jalan.
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Identitas pelaku/penyetuju di tiga tabel bisa dipalsukan klien

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql` (`kasir_id` hanya diisi bila null di `picu_pembayaran_jujur`; `diskon_transaksi.pelaku_id` tidak diperiksa; `pembatalan.disetujui_oleh` lihat F-03)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §1 butir 7 (“Setiap tindakan sensitif meninggalkan jejak”) dan PRD “jejak persetujuan PIN”
- **Bukti:** `node /tmp/serang/03-uang-approval.mjs /home/user/audit-442913e4` → sebagai kasir: `insert into public.pembayaran (… kasir_id='<owner>')` → DITERIMA; `insert into public.diskon_transaksi (… pelaku_id='<owner>')` → DITERIMA.
- **Skenario gagal:** kasir mencatat diskon/void atas nama owner atau rekan lain; ketika terjadi selisih kas, laporan “siapa mengerjakan apa” menunjuk orang yang salah, dan karena barisnya append-only (tidak bisa dikoreksi), kesalahan atribusi itu permanen.
- **Dugaan penyebab:** kolom pelaku diisi dari nilai yang dikirim klien (`new.kasir_id`) alih-alih selalu `auth.uid()`; tidak ada penjaga yang menolak `kasir_id` bukan pemanggil.
- **Cara membuktikan perbaikan:** uji baru — `insert into public.pembayaran (… kasir_id='<pengguna lain>')` dan `insert into public.diskon_transaksi (… pelaku_id='<pengguna lain>')` harus GAGAL/dinormalkan ke `auth.uid()` — lalu `node alat/uji-sql.mjs` harus 10 LULUS.
- **Status verifikasi:** TERVERIFIKASI

### [F-06] Penjaga stok bisa dilewati dengan GUC `app.stok_dari_buku_besar`

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0007_katalog.sql` (penjaga `stok_bahan.jumlah` memakai `current_setting('app.stok_dari_buku_besar', true)`)
- **Klaim yang dilanggar:** klaim #15 paket (T1-07, stok hanya berubah lewat catatan pergerakan) dan `docs/KEAMANAN.md` §1 butir 5 (tidak ada angka dari perangkat)
- **Bukti:** `node /tmp/serang/02-akses-pin.mjs /home/user/audit-442913e4` → sebagai dapur: `update public.stok_bahan set jumlah=999 …` ditolak `Jumlah stok hanya boleh berubah lewat catatan pergerakan stok`; setelah `select set_config('app.stok_dari_buku_besar','1',true)` perintah yang sama **DITERIMA** (`jumlah: "999.000"`).
- **Skenario gagal:** siapa pun yang punya izin `ubah_stok` (dapur) menulis angka stok langsung tanpa baris `stok_pergerakan`; selisih opname, HPP, dan laporan bahan menjadi tidak dapat dipercaya, dan tidak ada jejak siapa mengubahnya.
- **Dugaan penyebab:** penjaga mempercayai peubah sesi yang bisa disetel klien; bandingkan dengan penjaga uang yang sengaja memakai `current_user`/kepemilikan tabel (“tidak bisa dipalsukan klien” di komentar 0010) — jadi standarnya tidak konsisten di dalam repo yang sama.
- **Cara membuktikan perbaikan:** penjaga harus memakai penanda yang tidak bisa disetel klien (mis. fungsi khusus pemilik tabel atau argumen dari fungsi `catat_stok` yang di-revoke dari peran lain); uji baru: `set_config('app.stok_dari_buku_besar','1',true)` lalu `update stok_bahan` harus tetap GAGAL; jalankan `node alat/uji-sql.mjs` (10 LULUS) setelah perbaikan.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Kontrol wajib `docs/KEAMANAN.md` belum ada di kode

- **Tingkat:** K-2
- **Artefak:** `docs/KEAMANAN.md` §1 butir 3-4, §3, §4, §5, §7 (dokumen “BERLAKU sejak 2026-09-17”, “mengikat”) vs `supabase/migrations/` yang berhenti di `0010`
- **Klaim yang dilanggar:** KEAMANAN.md §1 butir 4 (“semua pemeriksaan perangkat/sesi dilakukan di database pada setiap permintaan”), §4 (`perangkat`, `kode_pendaftaran_perangkat`, `sesi_perangkat`), §7 (“jejak audit … berantai hash … `alat/periksa-audit.py`”)
- **Bukti:** `grep -rlE "create table (if not exists )?public\.(perangkat|sesi_perangkat|kode_pendaftaran_perangkat|voucher|shift|catatan_audit|mode_dukungan)\b" supabase/migrations/` → **kosong**; `ls alat/periksa-audit.py` → `No such file or directory`; `git ls-files supabase/migrations` → 10 berkas `0001…0010` saja; serangan #27 (pemilik platform hanya melihat 1 baris dirinya, 0 penyewa) menunjukkan peran dukungan tidak punya jalan apa pun.
- **Skenario gagal:** pada commit ini, staf masuk hanya dengan PIN (tanpa perangkat terdaftar) dan tidak ada satu pun mekanisme pencabutan perangkat/sesi; perangkat hilang atau pegawai berhenti tidak bisa dicabut “pada detik berikutnya” seperti yang dijanjikan. Siapa pun yang memegang PIN bisa masuk dari perangkat mana pun, dan perubahan izin/pengaturan pegawai tidak meninggalkan jejak audit karena `catatan_audit` tidak ada.
- **Dugaan penyebab:** dokumen keamanan dan ROADMAP memperkenalkan Fase 1B (migrasi 0011-0016b) tetapi Fase 1 dijeda di T1-10 atas permintaan pemilik; dokumen ditandai “BERLAKU” lebih awal daripada kodenya, sehingga janji kontrol wajib sudah mengikat sementara implementasinya nol.
- **Cara membuktikan perbaikan:** setelah Fase 1B — `node alat/uji-sql.mjs --daftar` harus menampilkan tabel `perangkat`, `sesi_perangkat`, `catatan_audit`, dan uji negatif “perangkat dicabut → permintaan berikutnya ditolak di database” harus GAGAL saat kontrol dimatikan; `python3 alat/periksa-fondasi-independen.py` tetap BERSIH.
- **Status verifikasi:** TERVERIFIKASI

### [F-08] Rujukan mati di dokumen yang mengikat

- **Tingkat:** K-3
- **Artefak:** `docs/KEAMANAN.md:149` (`alat/periksa-audit.py`), `docs/teknis/BUKU_INSIDEN.md:131` (`alat/denyut.py`), `docs/AGENT_OPERATING_GUIDE.md:323` (`docs/PETA_UI.md`), `STATUS.md:13` (`alat/periksa-halaman.py`)
- **Klaim yang dilanggar:** kebenaran dokumen rujukan (L6) dan `docs/AGENT_OPERATING_GUIDE.md` aturan “rujukan harus hidup”
- **Bukti:** `python3 -c "…pemindai rujukan ber-backtick…"` → 87 rujukan mati di 12 dokumen; contoh yang benar-benar menyesatkan: `ls alat/periksa-audit.py` → tidak ada padahal KEAMANAN.md:149 menyebutnya sebagai pemeriksa rantai hash; `ls alat/denyut.py` → tidak ada padahal BUKU_INSIDEN.md:131 menyuruh memakainya saat pg_cron dimatikan.
- **Skenario gagal:** saat insiden (database tidur, jejak audit dicurigai diubah), petugas mengikuti dokumen darurat dan mengetik perintah untuk berkas yang tidak ada → waktu tanggap habis, atau lebih buruk: petugas menganggap “sudah diperiksa pemeriksa” padahal pemeriksa itu tidak pernah ada.
- **Dugaan penyebab:** dokumen ditulis lebih dulu untuk lintas fase (banyak ditandai “rencana”), lalu sebagian rujukan tidak diberi penanda rencana sehingga terbaca sebagai alat yang sudah ada.
- **Cara membuktikan perbaikan:** `python3 alat/periksa-panduan.py` dan pemeriksa rujukan harus menolak (bukan hanya mencatat) rujukan tanpa penanda “rencana”; setelah diperbaiki, `python3 alat/periksa-panduan.py` LOLOS tanpa catatan rujukan mati.
- **Status verifikasi:** TERVERIFIKASI

### [F-09] 5 kerentanan dependency dev dan CI tidak memeriksanya

- **Tingkat:** K-3
- **Artefak:** `aplikasi/package-lock.json` (`vitest ≤3.2.5`, `vite ≤6.4.2`, `esbuild ≤0.24.2`), `.github/workflows/ci.yml` (tidak ada langkah `npm audit`)
- **Klaim yang dilanggar:** klaim #5/#6 paket (kebersihan & keamanan langkah README/CI) — bukan klaim eksplisit “bebas kerentanan”, jadi tingkatnya K-3
- **Bukti:** `cd aplikasi && npm audit` → `5 vulnerabilities (3 moderate, 1 high, 1 critical)`; rincian: `vitest` critical 9.8 (arbitrary file read & execute saat Vitest UI menyala), `vite` high 7.5 (`server.fs.deny` bypass), `esbuild` moderate (dev server bisa dibaca situs lain).
- **Skenario gagal:** perangkat pengembang menjalankan dev server/Uji Vitest di jaringan kedai atau jaringan bersama → orang lain di jaringan membaca berkas proyek (termasuk `.env`) lewat celah dev server; CI hijau membuat tim mengira tidak ada masalah karena tidak ada langkah yang memeriksanya.
- **Dugaan penyebab:** dependency dev tidak pernah diaudit; CI memeriksa kerapian, tipe, uji, build, dan pemeriksa proyek, tetapi tidak `npm audit`.
- **Cara membuktikan perbaikan:** jalankan `cd aplikasi && npm audit --audit-level=high` dan pastikan 0 high/critical; tambahkan langkah itu ke `ci.yml` (atau kunci versi yang sudah ditambal) lalu buktikan CI masih hijau.
- **Status verifikasi:** TERVERIFIKASI

### [F-10] Uji batas lebih bayar hanya ada untuk total > 0 → lubang nyata lolos dari 10 LULUS

- **Tingkat:** K-3
- **Artefak:** `supabase/tes/pembayaran.sql:133-146` (memakai `_uji_set_total(…, 54000, 62100)` sebelum menguji lebih bayar)
- **Klaim yang dilanggar:** L4 (uji yang lulus karena sebab yang salah) dan klaim #4/#18 paket soal mutu uji
- **Bukti:** `sed -n '133,146p' supabase/tes/pembayaran.sql` → total diisi 62.100 lewat helper pemilik tabel sebelum uji lebih bayar; `node alat/uji-sql.mjs` → `uji: 10 LULUS · 0 GAGAL` padahal serangan #10 (total 0) berhasil → rangkaian uji hijau tidak menyentuh keadaan nyata pesanan di commit ini (semua pesanan baru bertotal 0).
- **Skenario gagal:** bug F-04 lolos ke produksi dengan gerbang “10 LULUS · 0 GAGAL” sebagai bukti; pembangun mengira batas lebih bayar sudah diuji, padahal hanya diuji pada keadaan yang di commit ini tidak pernah terjadi.
- **Dugaan penyebab:** uji dibuat dari keadaan yang diinginkan (total terisi) alih-alih keadaan sistem hari ini (total 0 sampai `hitung_total` ada); tidak ada uji yang mengikat “keadaan sementara” ke tanggal/fase.
- **Cara membuktikan perbaikan:** tambahkan uji lebih bayar untuk pesanan bertotal 0 (harus ditolak atau memicu perhitungan total) dan pastikan `node alat/uji-sql.mjs` tetap `10 LULUS · 0 GAGAL` setelah F-04 diperbaiki; uji itu harus MERAH bila penjaga dilepas kembali.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

`Ditemukan: 5 dari 5` · **temuan palsu: 0**. Semua cacat di bawah ini ada di `docs/uji/kalibrasi/bahan-2026-09-17/` (bahan kalibrasi, **bukan** temuan proyek). Kunci jawaban ada di luar repo dan tidak saya cari.

| # | Berkas | Kelas cacat | Bukti nyata |
|---|---|---|---|
| 1 | `01_gerbang_izin.sql` | Fungsi `SECURITY DEFINER` tanpa `revoke execute from public` (menabrak aturan yang ditulis di komentarnya sendiri dan `docs/KEAMANAN.md` §5.3) | `grep -c revoke 01_gerbang_izin.sql` → 0; kelas dibuktikan dengan fungsi contoh tanpa revoke: `has_function_privilege('anon', …)` → true, sedangkan fungsi proyek yang di-revoke (`catat_stok`) → false |
| 2 | `02_policy_pengaturan.sql` | Policy `pengaturan_pilih` memakai `penyewa_id is not null` → bocor lintas penyewa; policy ubah juga tidak menyaring peran owner | `node /tmp/serang/05-kalibrasi.mjs` → kasir resto A **dan** resto B sama-sama membaca 2 baris `pengaturan` (resto A dan B); kasir resto B berhasil mengubah pajak resto B (bukan owner) dan `update … where penyewa_id=resto A` mengembalikan 0 baris |
| 3 | `03_fungsi_terima_bayar.sql` | Penjaga lebih bayar membandingkan **sebelum** insert (`v_sebelum > total`) sehingga tidak pernah menangkap kelebihan; kolom `metode`/`dibuat_oleh` tidak ada di skema nyata → fungsi tidak pernah bisa dipakai | `node /tmp/serang/05-kalibrasi.mjs` → `column "metode" of relation "pembayaran" does not exist`; sesudah itu `sum(jumlah)=0` (fungsi selalu error sebelum menangkap kasus lebih bayar) |
| 4 | `04_panduan_singkat.md` | Panduan menyebut perintah/berkas yang tidak ada + kebijakan keamanan yang bukan milik proyek | `aplikasi/pratinjau.sh` (aslinya `aplikasi/alat/pratinjau.sh`), `alat/periksa-struktur.py` (aslinya `aplikasi/alat/…`), `docs/PANDUAN_KEAMANAN.md` (tidak ada di mana pun — hanya di bahan kalibrasi ini); kebijakan PIN “10 kali / 15 menit” vs kode `BATAS_AKUN := 5`; “PIN wajib 6 angka” vs `^\d{4,6}$`; janji “lebih bayar ditolak sistem” bertabrakan dengan F-04 |
| 5 | `05_pemeriksa_ambang.py` | Pemeriksa tumpul yang tidak pernah bisa MERAH: ambang 5 vs ambang nyata 20, dan glob `aplikasi/src/layar/*.tsx` tidak cocok dengan struktur nyata (`aplikasi/src/layar/contoh/LayarContoh.tsx`) sehingga selalu “SKIP” lalu exit 0 | `python3 05_pemeriksa_ambang.py` → `exit=0`, `SKIP: layar baru 0 — di bawah ambang 5`; `ls aplikasi/src/layar/*.tsx` → 0 berkas (layar nyata ada di subfolder) |

Catatan kalibrasi: saya tidak mencari kunci jawaban, tidak memakai `--kalibrasi-nilai`/`--kunci`, dan tidak menghitung cacat bahan sebagai temuan proyek. Bahan kalibrasi juga **tidak** saya jadikan dasar verdict.

## 6. Yang tidak bisa saya verifikasi

- **Platform Supabase sungguhan** (PostgREST, Auth, Edge Function Deno, pg_cron, kuota paket gratis) tidak tersedia: tidak ada akun/kunci di lingkungan ini (T0-00/T0-08/T0-09 belum selesai — memang belum ada akun). Semua uji database dijalankan pada PGlite (PostgreSQL asli di WASM) dengan skema `auth` tiruan, jadi jawaban RLS/trigger/hak aksesnya sahih, tetapi **jalur HTTP Supabase** (termasuk klaim F-02 bahwa kolom terekspos lewat API otomatis) saya dasarkan pada hak istimewa Postgres + dokumentasi Supabase, bukan pada pemanggilan REST sungguhan.
- **`npm run dev` HTTP 200, favicon SVG, berkas `main.tsx`/`tema.css`/31 huruf saat dev** (klaim #1 T0-01) tidak saya jalankan karena audit ini hanya-baca dan tidak menyalakan peladen jangka panjang; yang saya jalankan adalah `npm ci`, `npm run build` (EXIT=0), Prettier, ESLint, tsc, dan Vitest.
- **Log GitHub Actions** hanya lewat API (`gh api …/jobs`): saya melihat nama langkah & kesimpulannya, bukan isi log penuh; run lain (T0-08/T0-09) belum ada karena menunggu akun pemilik.
- **Penilaian visual**: 59 berkas `docs/desain/` (gambar/mockup/huruf) dan 58 berkas `prototipe/` hanya saya periksa lewat inventaris + pemeriksa otomatis (`183/183 lolos`, `166 lolos`); keindahan/kejelasan tampilan bukan penilaian saya, dan saya tidak membuka setiap gambar.
- **Kualitas baris demi baris** tidak dilakukan untuk seluruh 334 berkas: berkas yang saya baca utuh adalah migrasi `0001-0010`, berkas uji SQL, `alat/audit-independen.py`, paket audit, protokol, bahan kalibrasi, `ci.yml`, `verifikasi_pin/index.ts`, dan dokumen pengguna utama; sisanya lewat pemeriksa/pemindai. Berkas `.gitkeep` kosong saya hitung sebagai “ada” bukan “diperiksa isinya”.
- **Pengecualian paket `skills/` (1802 berkas) tidak saya buka**: setuju dengan alasan paket (pustaka pihak ketiga yang dibawa apa adanya) — kecuali karena itu, isi skill tidak ikut dinilai; hal yang sama untuk `_salinan-meta/` (provenance sistem template) dan `_Notes.md` (catatan pribadi).
- **Kesimpulan perilaku eksternal yang saya pakai**: hak istimewa tingkat kolom di Supabase/PostgreSQL — https://supabase.com/docs/guides/database/postgres/column-level-security dan https://www.postgresql.org/docs/current/sql-grant.html (keduanya diakses 2026-09-17).

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan **tidak mengubah apa pun** pada berkas proyek: semua temuan ditulis, tidak ada yang saya betulkan. Bukti: `git status --short` di worktree audit sebelum laporan ditulis **kosong**, dan sesudah laporan ditulis hanya memuat satu berkas baru milik audit itu sendiri (`?? docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.md`) — tidak ada berkas proyek yang tersentuh, tidak ada berkas yang saya hapus/ubah. Perkakas serangan & bukti tambahan saya simpan **di luar repo** (`/tmp/serang/`) justru supaya repo tetap bersih. Hasil kedua bentuk pemeriksaan kontrak, apa adanya:

- `python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.md --tanpa-cek-git` → `HASIL: LOLOS KONTRAK` (cakupan 334/334, klaim 17, serangan 28, temuan 10, kalibrasi 5/5).
- tanpa `--tanpa-cek-git` → `HASIL: DITOLAK (1 alasan) - repo TIDAK bersih saat laporan diperiksa`, satu-satunya penyebab adalah berkas laporan ini sendiri yang belum terlacak Git (`?? docs/uji/audit/…`). Alat ini tidak bisa menerima laporan yang ditulis di dalam repo bila pemeriksaan Git dinyalakan; itu keterbatasan alat, bukan tanda ada berkas proyek yang berubah (`git diff --stat` kosong).