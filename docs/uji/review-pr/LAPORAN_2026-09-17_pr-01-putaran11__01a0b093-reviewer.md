# LAPORAN REVIEW PR INDEPENdEN — pr-01-putaran11 — 2026-09-17

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran11.md` (dan `--SIAP-TEMPEL`)
- **Commit yang direview:** `750889abf3055cdc1019490b9f3e4bbd10eb8062`
- **Tingkat risiko:** Merah
- **Verdict:** BERSIH-DENGAN-CATATAN

> Catatan metode: saya bekerja dari salinan `git archive` commit `750889ab` ke `/tmp/pr` (bukan
> repo kerja), lalu menginstal `aplikasi/node_modules` (264 paket) dan `alat/node_modules/@electric-sql/pglite`
> agar gerbang bisa dijalankan apa adanya. Semua perintah di bawah dijalankan di salinan itu. Repo kerja
> (`arena/01a0b093`) tidak saya ubah sama sekali.

## 1. Cakupan diff

**Jumlah berkas changed:** 369 · **+47630 / −132** (`git diff --stat origin/main 750889ab`).
Jalur risiko mesin: Merah 66 · Kuning 117 · Hijau 186. Saya memeriksa kedalaman L1 (ancaman & akses),
L2 (uang & jejak), dan L4 (mutu uji) sesuai wajib Jalur Merah.

| # | Berkas | Jalur | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `.github/workflows/ci.yml` (baru) | Merah | Ya | `git diff origin/main 750889ab -- .github/workflows/ci.yml` — 94 baris, semua langkah gerbang |
| 2 | `supabase/migrations/0012_penutup_celah_review.sql` (baru, 837 baris) | Merah | Ya (dibaca utuh) | baca `supabase/migrations/0012_penutup_celah_review.sql` |
| 3 | `supabase/migrations/0001..0011_*.sql` | Merah | Ya (difftar) | `node alat/uji-sql.mjs --daftar` |
| 4 | `alat/periksa-buku-uji.py`, `alat/review-pr.py`, `alat/audit-independen.py`, `alat/periksa-struktur.py`, `alat/periksa-rahasia.py`, `alat/periksa-bersih.py`, `alat/periksa-panduan.py`, `alat/periksa-roadmap.py` | Merah/Kuning | Ya | dijalankan (lihat §3) |
| 5 | `aplikasi/alat/periksa-semua.sh`, `aplikasi/alat/periksa-struktur.py` | Merah | Ya | `bash aplikasi/alat/periksa-semua.sh` LOLOS |
| 6 | `alat/uji-sql.mjs`, `alat/uji-database.sh`, `alat/uji-mutasi-0012.py` | Merah | Ya | dijalankan (lihat §3) |
| 7 | `docs/uji/BUKU_UJI_PEMILIK.md` (U-01..U-07) | Kuning | Ya | grep `U-0[2-4]` |
| 8 | `PANDUAN_PENGGUNA.md` (Bagian E) | Kuning | Ya | grep `## Bagian E` |
| 9 | `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` | Kuning | Ya (terpisah, §5) | `git apply` ke salinan + jalankan tes |
| 10 | 186 berkas Hijau (dokumen non-fondasi, aset desain, catatan sesi, `skills/**`) | Hijau | Tidak (hanya lewat gerbang) | gerbang §3 hijau; tidak dibaca per-berkas |

**Yang tidak diperiksa per-berkas:** 186 berkas Hijau (mayoritas dokumen naratif & aset desain) —
hanya dilindungi oleh gerbang otomatis (`_sistem/validate_system.py`, `periksa-panduan.py`,
`periksa-rahasia.py`, `periksa-bersih.py`), tidak dibaca satu per satu. Saya juga tidak membedah
`setiap` baris 117 berkas Kuning; yang diuji adalah pemeriksanya, bukan isi naratifnya.

## 2. Klaim yang dibantah

| # | Klaim (dari paket) | Cara membantah (perintah nyata) | Hasil nyata |
|---|---|---|---|
| 1 | U-04 kini: bilang `Siapkan review PR.`, lalu salin berkas | `grep -n "Siapkan review PR\.\|salin SELURUH isi berkas" docs/uji/BUKU_UJI_PEMILIK.md` | **TERVERIFIKASI** baris 46 U-04 berbunyi persis: "Bilang `Siapkan review PR.` … salin SELURUH isi berkas itu". Klaim benar. |
| 2 | Penjaga `periksa-buku-uji.py` menerima pola itu **hanya bila menyebut folder** | Mutasi: hapus frasa `paling baru` DAN rujukan `docs/uji/review-pr/` dari baris U-04, lalu `python3 alat/periksa-buku-uji.py` | **DIBANTAH (sebagian).** Setelah kedua frasa dihapus, pemeriksa tetap **LOLOS (exit 0)**. Guard HANYA menolak bila disebut **nama paket tetap yang basi** (`PKT-…SIAP-TEMPEL.md` lama); ia TIDAK mewajibkan penyebutan folder `review-pr`/kata `paling baru`. Klaim "hanya bila menyebut folder" tidak akurat. (Bukti mutasi ada di §4 PR-02.) |
| 3 | `bash aplikasi/alat/periksa-semua.sh` memasang `aplikasi/node_modules` | `sed -n '1,40p' aplikasi/alat/periksa-semua.sh` + jalankan skrip | **TERVERIFIKASI.** Skrip mengecek `if [ ! -x "$APLIKASI/node_modules/.bin/prettier" ]; then npm ci …` dan juga memasang `alat/node_modules/@electric-sql/pglite`. Saat dijalankan di salinan baru (tanpa node_modules) ia memasang keduanya lalu lanjut. Klaim benar. |
| 4 | Perintah uji database dibungkus `bash alat/uji-database.sh` (memasang sendiri) | `cat alat/uji-database.sh` | **TERVERIFIKASI.** Skrip: `if [ ! -d "alat/node_modules/@electric-sql/pglite" ]; then npm ci --prefix alat …; fi` lalu `exec node alat/uji-sql.mjs`. Ia memasang pustakanya sendiri. Klaim benar. |
| 5 | Penjaga baru `aplikasi/alat/periksa-struktur.py`: kedua skrip WAJIB memeriksa | `python3 aplikasi/alat/periksa-struktur.py` → cari "perintah buku uji" | **TERVERIFIKASI.** `uji_perintah_buku_uji` mengecek `aplikasi/alat/periksa-semua.sh` (penanda `$APLIKASI/node_modules/.bin/prettier` & `$REPO/alat/node_modules/@electric-sql/pglite`) dan `alat/uji-database.sh` (penanda `alat/node_modules/@electric-sql/pglite` & `npm ci --prefix alat`). Hasil: "dua perintah uji memasang pustakanya sendiri … LOLOS". Klaim benar. |
| 6 | Buku Uji U-02/U-03 + log buku disegarkan; PANDUAN Bagian E menambah baris | `grep -n "Uji semuanya\.\|SEMUA PEMERIKSAAN LOLOS\|uji: <jumlah> LULUS" docs/uji/BUKU_UJI_PEMILIK.md`; `grep -n "## Bagian E" PANDUAN_PENGGUNA.md` | **TERVERIFIKASI.** U-02 mengharap "SEMUA PEMERIKSAAN LOLOS." (cocok keluaran `periksa-semua.sh`); U-03 mengharap "`uji: <jumlah> LULUS · 0 GAGAL` dan `HASIL: LOLOS`" (cocok `uji-sql.mjs`). PANDUAN Bagian E ada (baris 496) berisi tabel perintah + cara pakai + arti bila GAGAL. Klaim benar. |
| 7 | `Uji semuanya.` = kalimat biasa di chat → agent menjalankan | `grep -n "Uji semuanya\." docs/uji/BUKU_UJI_PEMILIK.md PANDUAN_PENGGUNA.md` | **TERVERIFIKASI (klaim dokumentasi).** Buku U-02 & PANDUAN menyatakan kalimat itu memicu agent menjalankan seluruh pemeriksa. Ini klaim perilaku agent, bukan yang bisa saya jalankan langsung; konsisten dengan keluaran `periksa-semua.sh` yang saya jalankan. |
| 8 | `Uji database.` = kalimat biasa → agent menjalankan `node alat/uji-sql.mjs` | `grep -n "Uji database\." docs/uji/BUKU_UJI_PEMILIK.md` + `cat alat/uji-database.sh` | **TERVERIFIKASI.** U-03 menyatakan kalimat itu; agent sebenarnya menjalankan `bash alat/uji-database.sh` yang membungkus `node alat/uji-sql.mjs`. Klaim "agent menjalankan node alat/uji-sql.mjs" konsisten. |
| 9 | Uji otomatis membuktikan perilaku baru/bebas regresi **pada commit ini** (bukan sebelumnya) | `python3 alat/uji-mutasi-0012.py` (target migrasi 0012 = isi PR ini) | **TERVERIFIKASI.** Harness mutasi menargetkan tepat migrasi `0012_penutup_celah_review.sql` (perubahan commit ini): 12/12 mutasi wajib MERAH, lalu pemulihan hijau (lihat §3 #6). Bukti perilaku baru ada di commit ini, bukan commit lampau. |
| 10 | Tidak ada gerbang keamanan/CI yang dilemahkan (ambang diturunkan, uji dimatikan, revoke/hak dicabut dihapus) | `git diff origin/main 750889ab \| grep -nE "^-.*(revoke\|security definer\|using \(true\)\|grant .*to (public\|anon))"` + baca `ci.yml` utuh | **SEBAGIAN — lihat catatan.** Tidak ada revoke/security-definer/grant ke public yang dihapus di diff. `ci.yml` adalah BERKAS BARU (penguatan, bukan pelemahan). **TETAPI** langkah "Uji SQL" di CI memakai `node alat/uji-sql.mjs --daftar` yang HANYA mencantumkan tabel, **tidak menjalankan 28 tes SQL** (lihat temuan PR-01). Jadi klaim "tidak ada yang dilemahkan" secara harfiah benar, namun CI tidak menjalankan seluruh tes SQL — celah cakupan, bukan pelemahan ambang. |
| 11 | Perubahan jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API) | `node alat/uji-sql.mjs`; mutasi M9/M9b/M11 di `uji-mutasi-0012.py`; demo longgarkan RLS (§3 #7) | **TERVERIFIKASI (dengan catatan).** Penjaganya ada di BADAN fungsi/trigger `SECURITY DEFINER` (mis. `picu_diskon_batas`, `picu_pembayaran_jujur`, `catat_stok`, `izin_efektif_untuk`, `picu_pengaturan_jejak`) sehingga berlaku siapa pun pemanggilnya — bukan dipercaya dari klien. Bukti: mutasi M9 (cek keanggotaan cabang dimatikan) → `izin_efektif_untuk.sql` MERAH; demo longgarkan policy `cabang_pilih` → `rls_penyewa.sql` MERAH. Jadi tidak bisa dilewati lewat RPC langsung. Catatan: `pilih_cabang`/`catat_stok` memang bisa dipanggil langsung oleh `authenticated`, tapi badan fungsi tetap menegakkan izin (`boleh('ubah_stok')`, verifikasi keanggotaan cabang). |
| 12 | Dokumen yang menyatakan perilaku (fondasi, buku induk, panduan Lee) sudah ikut diperbarui — tidak ada klaim basi | `python3 alat/periksa-panduan.py`, `python3 alat/periksa-buku-uji.py`, `python3 _sistem/validate_system.py` (semua LOLOS) | **TERVERIFIKASI.** Ketiga pemeriksa dokumen LOLOS; U-04 tidak lagi menyebut nama paket tetap basi (sudah pola "berkas SIAP-TEMPEL paling baru di `docs/uji/review-pr/`"); `periksa-buku-uji.py --uji-diri` menolak paket basi. Tidak ada klaim basi yang tertangkap. |

## 3. Pemeriksaan gerbang

| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | **EXIT 0 — "SEMUA PEMERIKSAAN LOLOS."** Rincian: Prettier OK · ESLint bersih · `tsc -b` OK · **66 unit test lulus (9 file)** · `vite build` OK (238 KB JS) · `npm audit` **0 kerentanan** · `uji-sql.mjs` **28 LULUS · 0 GAGAL** · mutasi 0012 **12/12 MERAH + pulih hijau** · `validate_system` PASS · `periksa-roadmap` LOLOS (192 tugas) · `periksa-panduan` LOLOS (687 baris) · `audit-independen --uji-diri` LOLOS · `review-pr --uji-diri` LOLOS · `periksa-buku-uji` LOLOS · `periksa-rahasia` LOLOS · `periksa-bersih` LOLOS · `periksa-struktur` LOLOS · `periksa-kerapatan` **166 lolos, 0 gagal**. |
| 2 | `node alat/uji-sql.mjs` | **uji: 28 LULUS · 0 GAGAL — HASIL: LOLOS.** (RLS penyewa/cabang, izin, diskon cap/persen, harga item, pembayaran, stok arah, PIN, persetujuan void, jejak pelaku/pengaturan, peran tunggal, isolasi lintas penyewa, dll.) |
| 3 | `git diff origin/main...750889ab` (baca diff sungguhan) | **369 berkas · +47630 / −132.** Temuan di luar deskripsi: `ci.yml` adalah BERKAS BARU (tidak ada di `main`) dan langkah SQL-nya memakai `--daftar` (lihat PR-01); migrasi `0012` baru 837 baris; 28 berkas `supabase/tes/*.sql` baru; dokumen panduan/buku diperbarui. Tidak ada penghapusan gerbang keamanan. |
| 4 | `python3 _sistem/validate_system.py` + `periksa-roadmap.py` + `periksa-panduan.py` | `validate_system` → **PASS**; `periksa-roadmap` → **LOLOS** (192 tugas, 12 fitur M1–M12, 7× atribut); `periksa-panduan` → **LOLOS** (687 baris, rujukan hidup). |
| 5 | `python3 alat/audit-independen.py --uji-diri` + `python3 alat/review-pr.py --uji-diri` | `audit-independen --uji-diri` → **TERKALIBRASI / LOLOS** (menolak laporan buruk, menerima baik). `review-pr --uji-diri` → **LOLOS** (6 kasus buruk ditolak, 1 kasus baik diterima). Mekanisme tidak tumpul. |
| 6 | `python3 alat/uji-mutasi-0012.py` (mutasi gerbang, wajib Jalur Merah) | **KONTROL hijau → 12/12 mutasi WAJIB MERAH → pemulihan hijau.** M1 promo dibuka, M2 cap tidak dibaca, M4 harga bebas, M5 subtotal klien, M6 bukti PIN berulang, M7 pelaku dikarang, M8 stok keluar nambah, M9/M9b izin cabang, M10 kunci silang PIN, M11 akun nonaktif, M3k gabungan — semuanya MERAH; setelah pulih semua hijau. |
| 7 | Uji RLS/izin GAGAL saat dilonggarkan (wajib Jalur Merah) | LoLonggarkan policy `cabang_pilih` (`using (penyewa_id = public.penyewa_saya())` → `using (true)`) lalu `node alat/uji-sql.mjs supabase/tes/rls_penyewa.sql` → **GAGAL** ("tanpa identitas: cabang tidak terlihat (dapat 3, harap 0)"). Pulihkan → **LOLOS (1 LULUS)**. Juga: mutasi M9 (`izin_efektif_untuk.sql` MERAH) & M11 (`cabang_sesi.sql` MERAH) membuktikan izin menolak bila dilonggarkan. |
| 8 | Rencana pemulihan & sisa risiko (wajib Jalur Merah) | Lihat § kalimat di bawah. |

**Rencana pemulihan** (bila perubahan ini salah): migrasi `0012` sifatnya *additive* (fungsi/trigger baru + kolom `percobaan_pin`). Untuk mengamankan: (a) `git revert 750889ab` di cabang kerja lalu jalankan ulang migrasi dari `0011` ke bawah, atau (b) terbitkan migrasi kompensasi `0013` yang `DROP` objek `0012` (trigger `pesanan_item_harga_jujur`, `pengaturan_jaga_jejak`, fungsi `picu_*`, `izin_efektif_untuk` versi baru, tabel `sesi_cabang`). Karena semua penjaga berada di DB, cukup satu migrasi kompensasi untuk menonaktifkannya tanpa menyentuh aplikasi.

**Sisa risiko (bahasa sederhana):** (1) Penjaga ada di dalam database (trigger/fungsi), jadi kasir tidak bisa memalsukan diskon, harga, atau pembayaran lewat layar — tapi ia hanya sekuat tes yang mengujinya. (2) Bila suatu saat ada migrasi baru yang melonggarkan satu penjaga TANPA menyertakan tes mutasi, harness ini bisa lolos (lihat cacat kalibrasi #1 di §5 yang memang tidak tertangkap tes otomatis). (3) CI saat ini tidak menjalankan ke-28 tes SQL (hanya `--daftar` + subset mutasi), sehingga regresi di tabel non-0012 bisa luput (temuan PR-01).

## 4. Temuan

### [PR-01] CI tidak menjalankan seluruh suite uji SQL (hanya `--daftar` + subset mutasi)
- **Tingkat:** K-3
- **Artefak:** `.github/workflows/ci.yml` — langkah "Uji SQL — RLS, isolasi resto & fungsi identitas": `run: node alat/uji-sql.mjs --daftar`
- **Klaim yang dilanggar:** Klaim #10 ("tidak ada gerbang … yang dilemahkan") secara harfiah benar (CI baru, tak ada ambang diturunkan), **tetapi** langkah yang diberi label "Uji SQL" tidak mengeksekusi satupun dari 28 tes SQL — sehingga gerbang CI tidak sekuat yang disangka.
- **Bukti:** `git diff origin/main 750889ab -- .github/workflows/ci.yml` → baris `node alat/uji-sql.mjs --daftar`. Opsi `--daftar` hanya mencetak daftar tabel/RLS/policy (`uji-sql.mjs`: `if (hanyaDaftar) { … print daftar … }`), **tidak menjalankan berkas `supabase/tes/*.sql`**. Dari 28 berkas tes, harness mutasi `uji-mutasi-0012.py` hanya menjalankan 8 (`cabang_sesi, diskon_cap, harga_item, izin_efektif_untuk, jejak_pengaturan, persetujuan_void, pin_kunci_silang, stok_arah`). Sisanya **20 berkas tes tidak pernah dieksekusi di CI**.
- **Skenario gagal:** Suatu commit memasukkan regresi pada `rls_penyewa.sql`/`pembayaran.sql`/`pin.sql`/dll (tabel 0001–0011). Karena CI hanya `--daftar` + 8 tes mutasi, commit tersebut tetap **hijau** di GitHub namun RLS/uang rusak. Penjaga lokal `periksa-semua.sh` akan menangkapnya, tapi gerbang CI (yang jadi syarat merge) tidak.
- **Dugaan penyebab:** `--daftar` mungkin sengaja dipakai agar CI cepat / karena mengira mutasi sudah mencakup semua; atau keliru mengira `--daftar` = menjalankan tes.
- **Cara membuktikan perbaikan:** ganti langkah CI menjadi `node alat/uji-sql.mjs` (tanpa `--daftar`) sehingga 28 tes benar-benar jalan; atau tambahkan satu langkah eksplisit `node alat/uji-sql.mjs` di samping mutasi. Setelah diperbaiki, jalankan `node alat/uji-sql.mjs` di CI harus mencetak `uji: 28 LULUS · 0 GAGAL — HASIL: LOLOS`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] `periksa-buku-uji.py` tidak mewajibkan penyebutan folder "review-pr"/"paling baru" (klaim #2 tidak akurat)
- **Tingkat:** K-3
- **Artefak:** `alat/periksa-buku-uji.py` — fungsi `_cek_paket_disebut()` (blok `if not disebut:`)
- **Klaim yang dilanggar:** Klaim #2 paket ("penjaga menerima pola itu **hanya bila menyebut folder**") tidak akurat. Guard hanya menolak bila buku menyebut **nama paket tetap yang basi** (`PKT-…SIAP-TEMPEL.md` lama); ia tetap **LOLOS** bila U-04 sama sekali tidak merujuk folder `review-pr` maupun kata "paling baru".
- **Bukti:** Di salinan `/tmp/pr`, hapus frasa `paling baru` DAN rujukan `docs/uji/review-pr/` dari baris U-04 (jadikan "berkas SIAP-TEMPEL" tanpa keduanya). Jalankan `python3 alat/periksa-buku-uji.py` → **EXIT 0, "HASIL: LOLOS"**. Setelah dikembalikan, tetap LOLOS. (Sebaliknya `--uji-diri` membuktikan nama paket basi DITOLAK — jadi guard bukan rusak, hanya lebih longgar dari klaim.)
- **Skenario gagal:** Suatu edit menghapus instruksi "pakai paket paling baru di docs/uji/review-pr/" dari U-04 (mis. kembali ke "buka chat baru lalu tempel apa saja"). Guard tidak menangkapnya; buku bisa menuntun Lee menempelkan paket basi/sembarang ke sesi peninjau.
- **Dugaan penyebab:** `_cek_paket_disebut` mengembalikan tanpa error bila tidak ada nama paket DAN tidak ada pasangan ("review-pr" + "paling baru") — jadi "tidak menyebut apa-apa" dianggap boleh.
- **Cara membuktikan perbaikan:** ubah guard agar bila U-04 ada, ia **wajib** mengandung rujukan folder `review-pr` DAN kata "paling baru" (atau nama paket yang benar-benar ada & terbaru); jika tidak, `errs.append(...)`. Setelah diperbaiki, mutasi hapus-kedua-frasa harus menghasilkan GAGAL.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Bahan: `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` (4 hunk). Saya salin repo ke `/tmp/pr-kal` (`git archive` + `git apply docs/uji/kalibrasi/pr-bahan-2026-09-17.diff`), lalu jalankan `node alat/uji-sql.mjs`.

**Ditemukan: 4 dari 4 · temuan palsu: 0**

Daftar cacat tanaman yang saya temukan (dari ke-4 hunk):
1. **`supabase/migrations/0003_helper_identitas.sql`** — baris `join public.pengguna p on p.id = pc.pengguna_id and p.aktif` dihilangkan. Akibat: `cabang_saya()` tetap mengembalikan cabang untuk **akun nonaktif** (seharusnya kehilangan akses). *Hanya tertangkap lewat baca kode; TIDAK tertangkap tes otomatis* (tidak ada tes yang gagal untuk hunk ini saat diff diterapkan).
2. **`supabase/migrations/0004_pola_rls.sql`** — policy `pengaturan_pilih` diubah `using (penyewa_id = public.penyewa_saya())` → `using (penyewa_id is not null)`. Akibat: **kebocoran lintas-penyewa** — user terautentikasi bisa melihat `pengaturan` resto lain. *Tertangkap tes*: `rls_pengguna.sql` (owner pusat lihat 2, harap 1) dan `rls_semua_tabel.sql` ("pengaturan membocorkan 1 baris milik resto lain") → keduanya GAGAL.
3. **`supabase/migrations/0005_izin_berjenjang.sql`** — baris `revoke all on function public.boleh(text, uuid) from public;` dihapus. Akibat: overload `boleh(text,uuid)` kini **bisa dipanggil langsung oleh public/anon** (seharusnya tidak). *Tertangkap tes*: `izin.sql` → "anon tidak boleh memanggil boleh()" GAGAL.
4. **`supabase/migrations/0012_penutup_celah_review.sql`** — cabang `jenis = 'promo'` diubah `raise exception …` → `null;`. Akibat: **PR-01 kembali terbuka** — kasir bisa mencatat diskon 100% via jenis promo tanpa pemeriksaan. *Tertangkap tes*: `diskon_cap.sql` → "perintah tidak ditolak (diskon jenis promo …)" GAGAL.

Total saat diff diterapkan: `uji: 24 LULUS · 4 GAGAL` (vs `28 LULUS` di repo bersih) — ke-4 kegagalan persis memetakan ke ke-4 hunk di atas. Tidak ada tes yang gagal yang BUKAN berasal dari bahan kalibrasi (0 temuan palsu).

## 6. Yang tidak bisa saya verifikasi

- **Perilaku "agent menjalankan" (klaim #7/#8):** saya tidak bisa menjalankan agent sesi kerja untuk membukti `Uji semuanya.`/`Uji database.` benar-benar memicu pemeriksa di chat. Saya hanya memverifikasi dokumentasinya konsisten dengan keluaran `periksa-semua.sh` / `uji-sql.mjs` yang saya jalankan.
- **Koneksi Supabase nyata:** `uji-sql.mjs` berjalan di PGlite (PostgreSQL-in-WASM), bukan instance Supabase produksi. Uji RLS/izin valid untuk logika SQL, tapi belum divalidasi terhadap konfigurasi Auth/Supabase hidup (mis. klaim JWT asli, `service_role`).
- **`npm audit --audit-level=low` di CI vs lokal:** lokal 0 kerentanan; di CI tergantung lockfile yang sama (saya pakai `npm ci` dari lockfile repo, jadi setara).
- **186 berkas Hijau & sebagian 117 berkas Kuning:** tidak dibaca per-berkas (hanya lewat gerbang). Ada kemungkinan cacat naratif yang tak tertangkap gerbang dokumen, namun di luar kedalaman wajib Jalur Merah.
- **Kunci kalibrasi:** sesuai aturan, saya TIDAK mencari kunci jawaban; penilaian "4 dari 4" murni dari hasil `git apply` + `uji-sql.mjs` di salinan.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca, **bukan** sesi penulis PR (sesi berbeda/model berbeda). SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah di repo kerja. Bukti: `git status --short` di repo kerja (`arena/01a0b093-resto-barokah`) **hanya** menampilkan berkas laporan ini (lihat §8/commit). Seluruh perintah di atas saya jalankan di salinan `/tmp/pr` (hasil `git archive`), bukan di repo kerja.

## 8. Temuan di luar cakupan diff (WAJIB)

| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
| 1 | `owner_pusat` tidak punya baris `pengguna_cabang`, sehingga `pilih_cabang()` selalu menolak ("Anda tidak bertugas di cabang itu") → `cabang_saya()` selalu `null` untuk owner pusat. | Bukan diubah oleh diff ini; perilaku diturunkan dari `0003`/`0012` (sudah ada di base). Saya temukan saat menelusuri `cabang_saya()`/`pilih_cabang` untuk klaim #11. | Baca `0012_penutup_celah_review.sql` → `pilih_cabang` (wajib `pengguna_cabang` aktif) & `cabang_saya()` (join `pengguna_cabang`). Owner pusat tak punya baris itu. | DUGAAN (belum saya buktikan dengan tes konkret). Periksa apakah policy yang memakai `cabang_saya()` tetap memberi owner pusat akses penuh lewat `peran_saya()='owner_pusat'`; bila ada policy yang HANYA bergantung `cabang_saya()`, owner pusat bisa kehilangan akses. |
| 2 | `periksa-semua.sh` butuh repo Git agar `periksa-bersih.py` lolos (langkah terakhir). Di salinan `git archive` (tanpa `.git`) langkah itu GAGAL "tidak ada berkas terlacak". | Ini artefak cara saya menjalankan gerbang (snapshot tanpa .git), bukan cacat PR. Saya perbaiki dengan `git init` di salinan → LOLOS. | Log: "PERIKSA POHON BERSIH: GAGAL — tidak ada berkas terlacak" lalu (setelah `git init`+commit) "SEMUA PEMERIKSAAN LOLOS." | Tidak perlu tindakan PR; dicatat agar tidak salah dilaporkan sebagai kegagalan gerbang. |
| 3 | `uji-mutasi-0012.py` hanya menjalankan 8 dari 28 berkas tes SQL sebagai kontrol; sisa 20 hanya berjalan lewat `node alat/uji-sql.mjs` penuh (yang CI tidak jalankan — lihat PR-01). | Terkait dengan temuan PR-01 (cakupan CI), tapi akarnya ada di desain harness mutasi + `ci.yml`, bukan satu baris di diff yang "salah". | `grep` daftar tes di `uji-mutasi-0012.py` vs `ls supabase/tes/*.sql` (28 total, 8 di harness). | Tutup lewat perbaikan PR-01 (jalankan `node alat/uji-sql.mjs` penuh di CI). |

**Ringkasan verdict:** Gerbang otomatis (periksa-semua, uji SQL 28/28, mutasi 12/12, RLS gagal-saat-dilonggarkan, pemeriksa dokumen & --uji-diri) **semua hijau** di commit ini. Migrasi `0012` merupakan penutup celah keamanan yang kuat dan terbukti. Dua catatan moderat (K-3): (1) CI tidak menjalankan seluruh tes SQL (`--daftar` + subset mutasi) sehingga regresi tabel non-0012 bisa luput; (2) klaim #2 tentang guard buku-uji tidak akurat (guard lebih longgar dari yang diklaim). Tidak ada temuan K-1/K-2. Oleh karena itu verdict **BERSIH-DENGAN-CATATAN** — layak merge setelah dua catatan K-3 ditindaklanjuti (terutama PR-01).