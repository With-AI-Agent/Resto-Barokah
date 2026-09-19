# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran8 — 2026-09-17

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md`
- **Commit yang direview:** `7e8c0b952744fd4b604743022acfb1b643c94a9a`
- **Tingkat risiko:** Merah
- **Verdict:** TIDAK-BERSIH

## 1. Cakupan diff

Cakupan nyata diukur sendiri: `git diff origin/main...7e8c0b9 --stat` → **338 berkas · +41655 / −132** (cocok dengan paket). Jalur Merah (supabase/migrations, fungsi Edge, CI, pemeriksa) dibuka satu per satu di bawah lensa **L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji)**; Kuning/Hijau diverifikasi lewat pemeriksa otomatis + sampel berkas dokumen fondasi. Tidak ada berkas yang dinyatakan "diperiksa" tanpa bukti perintah.

| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `supabase/migrations/*.sql` (11 migrasi, 0001–0011) | Merah | ya | `node alat/uji-sql.mjs` → 11 migrasi OK; `git show 7e8c0b9 --stat` |
| 2 | `supabase/functions/verifikasi_pin/index.ts` | Merah | ya | `cat` + `python3 alat/periksa-fungsi-pin.py` → 9 LOLOS (tanpa console.*, tanpa service_role, hanya POST) |
| 3 | `.github/workflows/ci.yml` | Merah | ya | `git show 7e8c0b9 -- .github/workflows/ci.yml` → hanya TAMBAH langkah (npm audit + 3 pemeriksa baru), tidak ada yang dihapus/dilonggarkan |
| 4 | `alat/periksa-rujukan.py`, `alat/periksa-temuan-audit.py`, `alat/periksa-buku-uji.py`, `alat/bantu_uji_diri.py` | Merah | ya | `python3 alat/<nama>.py --uji-diri` → masing-masing LOLOS (mutasi MENOLAK/utuh MENERIMA) |
| 5 | `alat/periksa-panduan.py` (MIN_ALUR 10→12) | Merah | ya | `python3 alat/periksa-panduan.py` → 12 alur, LOLOS; `--uji-diri` → 4 kasus OK |
| 6 | `_sistem/validate_system.py` | Merah | ya | `python3 _sistem/validate_system.py` → `VALIDATOR: PASS` |
| 7 | `aplikasi/package.json` (vitest ↑5.0.1) + `package-lock.json` | Merah | ya | `cd aplikasi && npm audit --audit-level=low` → `found 0 vulnerabilities`; lock teresolve ke 5.0.1 |
| 8 | `docs/uji/BUKU_UJI_PEMILIK.md` (baru) | Kuning | ya | `python3 alat/periksa-buku-uji.py` → 2 lakukan + 5 coba, LOLOS |
| 9 | `docs/ROADMAP.md` (189→192 tugas), `docs/KEAMANAN.md`, `docs/SPESIFIKASI_UI.md`, `PANDUAN_PENGGUNA.md` | Kuning | ya | `python3 alat/periksa-roadmap.py` → 192 tugas LOLOS; periksa-panduan LOLOS; rujukan `alat/peta-ui.py` ditandai rencana T1-33 |
| 10 | Sisa berkas Hijau (catatan sesi, riwayat, prototipe, aset) | Hijau | ya | `git diff origin/main...7e8c0b9 --name-only` dikelompokkan per jalur; dibaca lewat pemeriksa dokumen di gerbang |

## 2. Klaim yang dibantah

| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | (butir 1 paket **kosong**) paket memuat klaim lengkap yang bisa dibantah | `sed -n '/## 3. Klaim/,/## 4./p' docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md` | Butir 1 kosong; 7 butir pertama kosong seluruhnya; klaim non-kosong pertama barulah butir 8. Klaim ENGGAK lengkap — lihat temuan [PR-05] |
| 2 | "Paket baru docs/…/PKT-…pr-01-**putaran7**-SIAP-TEMPEL.md" | `grep -n putaran8 docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md` dan bandingkan `cat docs/uji/REVIEW_PR_RIWAYAT.md` | SALAH/KUNO: paket berlaku hari ini adalah `putaran8` (baris riwayat 4). Klaim butir 2 menunjuk paket putaran7 (commit 183a3c1) — klaim basi |
| 3 | "REVIEW_PR_RIWAYAT baris 3 (paket berlaku) + baris 2 ditandai digantikan" | `cat docs/uji/REVIEW_PR_RIWAYAT.md` | SALAH/KUNO: kenyataannya **baris 4 = paket berlaku** (`7e8c0b9`) dan **baris 3 = digantikan**. Butir 3 menyalin pernyataan putaran7, bukan keadaan putaran8 |
| 4 | Uji otomatis membuktikan perilaku baru / bebas regresi pada commit ini | `bash aplikasi/alat/periksa-semua.sh`; `node alat/uji-sql.mjs`; 3 uji mutasi jalur Merah | LOLOS untuk hal yang DIUJI (21 LULUS · 0 GAGAL; 51 unit; 166 kontras). TAPI ada celah terverifikasi: cacat kelas K-2 "akun nonaktif" pada `cabang_saya()` **lolos 21/21 uji** (temuan [PR-01]) — jadi klaim "membuktikan" tidak 100% benar |
| 5 | Tidak ada gerbang keamanan/CI yang dilemahkan | `git show 7e8c0b9 -- .github/workflows/ci.yml aplikasi/alat/periksa-semua.sh` + `git show 7e8c0b9 -- alat/periksa-panduan.py` | BENAR: CI hanya menambah langkah (npm audit, 3 pemeriksa baru + `--uji-diri`); ambang `MIN_ALUR` justru **dinaikkan** 10→12; tidak ada uji dimatikan / revoke dihapus dari kode |
| 6 | Perubahan jalur uang/keamanan/data tidak bisa dilewati lewat pemanggilan langsung (RPC/API) | Mutasi `git` `sed` di salinan /tmp lalu `node alat/uji-sql.mjs` | TERBUKTI sebagian besar: lepas revoke `kredensial_pin` → `kredensial_pin.sql` MERAH; hapus revoke `boleh(text,uuid)` → `izin.sql` MERAH; longgarkan `pengaturan_pilih` lintas resto → `rls_semua_tabel.sql` MERAH; matikan pagar lebih-bayar → `gerbang_uang.sql` MERAH. Sisa risiko: lihat temuan [PR-01] (pintu `cabang_saya()` tidak dijaga uji) |
| 7 | Dokumen yang menyatakan perilaku ikut diperbarui — tidak ada klaim basi | `git show 7e8c0b9 -- docs/ROADMAP.md`; `find aplikasi -name '*.woff2' | wc -l`; `grep -n putaran7 docs/uji/BUKU_UJI_PEMILIK.md` | SALAH sebagian: ROADMAP T0-01 menulis "57 berkas .woff2" sementara perintah yang dikutip menghasilkan **38** (temuan [PR-02]); Buku Uji Pemilik U-04 menyuruh menyalin paket **putaran7** yang basi (temuan [PR-03]) |
| 8 | Setiap berkas baru benar-benar dipakai (tidak ada berkas mati / rujukan menggantung) | `python3 alat/periksa-rujukan.py`; `grep -n "bantu_uji_diri" alat/*.py`; `grep -n "periksa-buku-uji\|periksa-temuan-audit\|periksa-rujukan" aplikasi/alat/periksa-semua.sh .github/workflows/ci.yml` | BENAR: 148 rujukan diperiksa LOLOS; keempat berkas baru dipakai (3 pemanggil, semua mengimpor helper `bantu_uji_diri.py`); semua masuk CI + periksa-semua.sh |

## 3. Pemeriksaan gerbang

| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | `SEMUA PEMERIKSAAN LOLOS.` · unit Vitest `51 passed (51)` · uji-kontras `RINGKASAN: 166 lolos, 0 gagal` · `uji: 21 LULUS · 0 GAGAL` · exit 0 |
| 2 | `node alat/uji-sql.mjs` | 11 migrasi OK · `uji: 21 LULUS · 0 GAGAL` · `HASIL: LOLOS` |
| 3 | `node alat/uji-sql.mjs --daftar` | 24 tabel + kredensial_pin + percobaan_simpan_pin; RLS=ya pada semua; jalur uji tetap 21 LULUS |
| 4 | Pemeriksa dokumen: `python3 _sistem/validate_system.py` → `PASS`; `python3 alat/periksa-roadmap.py` → 192 tugas `HASIL: LOLOS`; `python3 alat/periksa-panduan.py` → 12 alur `HASIL: LOLOS` | semua exit 0 |
| 5 | `python3 alat/audit-independen.py --uji-diri` | `HASIL: LOLOS` (penilai kalibrasi + jalur pulang berperilaku benar) |
| 6 | `python3 alat/review-pr.py --uji-diri` | `HASIL: LOLOS` (3 contoh: bagus diterima, 2 buruk ditolak) |
| 7 | 4 pemeriksa baru `--uji-diri` | `periksa-panduan` 4 kasus OK; `periksa-rujukan` 3 kasus OK; `periksa-temuan-audit` 4 kasus OK; `periksa-buku-uji` 4 kasus OK |
| 8 | Uji mutasi jalur Merah (rusak → MERAH → pulihkan → LOLOS) — **L1/L2** | (a) pagar uang: `sed 's/if v_sebelum > v_pesanan.total then/if false then/'` → `gerbang_uang.sql` `0 LULUS · 1 GAGAL` (ditolak) → pulih → hijau. (b) RLS/izin: lepas revoke `kredensial_pin` → `kredensial_pin.sql` GAGAL (`dapat t, harap f`); hapus revoke `boleh(text,uuid)` → `izin.sql` GAGAL (`anon tidak boleh memanggil boleh()`); `pengaturan_pilih` → `penyewa_id is not null` → `rls_semua_tabel.sql` GAGAL (`membocorkan 1 baris`). (c) kontrol positif semua kembali LOLOS setelah dipulihkan |
| 9 | `git diff origin/main...origin/arena/01a0a8a2-resto-barokah` dibaca penuh | 338 berkas; didapati hal yang TIDAK ada di deskripsi: klaim basi (PR-02/03/05), bahan kalibrasi korup (PR-04), celah uji nonaktif (PR-01) — semuanya dilaporkan di bagian 4 |
| 10 | `cd aplikasi && npm audit --audit-level=low` | `found 0 vulnerabilities` (claim npm audit 0 di deskripsi TRUE) |

**Rencana pemulihan (jalur Merah, bahasa sederhana).** Bila perubahan di PR ini ternyata salah, yang harus dilakukan: (1) **jangan merge** PR; (2) kembalikan ambang/uji ke keadaan sebelum commit — karena commit ini hanya menambah penjaga dan menaikkan `MIN_ALUR`, pemulihannya murah: hapus langkah `npm audit` + 3 pemeriksa baru dari `ci.yml` dan `periksa-semua.sh`, kembalikan `MIN_ALUR=10`, dan kembali ke `vitest` versi sebelumnya; (3) untuk temuan yang menyentuh isi (angka .woff2, paket basi, bahan kalibrasi, celah uji), perbaikan dilakukan di sesi kerja — tidak ada data/uang yang ikut berubah karena migrasi produksi tidak diubah oleh commit ini (commit hanya menyentuh alat + dokumen + `package.json`), jadi **tidak ada risiko kehilangan data pelanggan** dan rollback-nya = checkout commit sebelumnya.
**Sisa risiko (bahasa sederhana).** (a) Uji SQL berjalan di tiruan PGlite + tiruan `pgcrypto`, bukan Supabase asli, sehingga perilaku `bcrypt` sejati & mekanisme akses API nyata belum teruji — itu memang menunggu akun Supabase Lee (butir tunggu T-018). (b) Lapis ke-2 pembatas PIN (per perangkat) masih memakai nama perangkat kiriman klien (temuan B F-11, dipagari uji, belum ditutup sampai T1-24) — diakui di `docs/KEAMANAN.md`. (c) Pertahanan "akun nonaktif = cabut seketika" pada `cabang_saya()` tidak ada ujinya (temuan [PR-01]).

## 4. Temuan

### [PR-01] Celah uji: pertahanan "akun nonaktif kehilangan akses" di `cabang_saya()` tidak dijaga — cacat kelas K-2 lolos seluruh 21 uji + semua pemeriksa
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0003_helper_identitas.sql:66` (join `p.aktif`), `supabase/tes/helper.sql:87-95` (uji nonaktif tidak menyentuh `cabang_saya()`), `alat/kalibrasi-cacat.json` (P4 `harapan_mesin: "ya"`)
- **Klaim yang dilanggar:** klaim #4 (uji otomatis membuktikan perilaku bebas regresi) dan klaim #6 (perubahan keamanan tidak bisa dilewati) — khususnya pertahanan berlapis **"akun nonaktif = cabut seketika"** yang dinyatakan di `docs/KEAMANAN.md` §"Sepuluh ancaman" (mantan pegawai).
- **Bukti:** cacat P4 bahan kalibrasi (hapus `and p.aktif` dari `cabang_saya()` = "pegawai nonaktif masih mendapat cabang") diterapkan di salinan /tmp:
  - `sed -i 's/join public.pengguna p on p.id = pc.pengguna_id and p.aktif/join public.pengguna p on p.id = pc.pengguna_id/' /tmp/rb-d1/supabase/migrations/0003_helper_identitas.sql && node alat/uji-sql.mjs` → `uji: 21 LULUS · 0 GAGAL · HASIL: LOLOS` (cacat **TIDAK tertangkap**).
  - Probe dampak nyata (`verifikasi_pin`/`cabang_saya` untuk pegawai nonaktif + klaim cabang sah): pada salinan rusak `cabang_saya()` = `a1a1a1a1-…-0002` (bukan NULL) → probe GAGAL; pada repo bersih probe LULUS. Jadi `pengguna_pilih` RLS (admin_cabang lewat `cabang_saya()`) ikut terpengaruh.
  - `python3 -c "import json;d=json.load(open('alat/kalibrasi-cacat.json'));print(d['cacat'][3]['harapan_mesin'])"` → `"ya (helper.sql …)"` — padahal tidak ada uji yang menangkapnya (uji helper hanya uji `penyewa_saya()/peran_saya()/cabang_ids_saya()`, baris 87–95).
- **Skenario gagal:** pegawai di-nonaktifkan, tapi kakinya di cabang tidak sepenuhnya tertutup — `cabang_saya()` tetap mengembalikan cabang untuk token lama sampai token kedaluwarsa; pemanggil RLS yang bergantung pada `cabang_saya()` (mis. admin_cabang menyeleksi pegawai) membaca data yang seharusnya sudah tertutup. Regresi yang memperkenalkan ini akan **memerah-kan nol uji** dan lolos CI.
- **Dugaan penyebab:** uji nonaktif (helper.sql §8) hanya menutup tiga fungsi identitas, tidak `cabang_saya()`; katalog kalibrasi menulis `harapan_mesin: "ya"` tanpa pernah menjalankan mutasinya (klaim katalog, bukan bukti).
- **Cara membuktikan perbaikan:** tambahkan kasus nonaktif untuk `cabang_saya()` di `supabase/tes/helper.sql` (contoh: `select uji.sama(public.cabang_saya(), null::uuid, 'pegawai nonaktif tidak punya cabang aktif')` setelah `update pengguna set aktif=false`); lalu mutasi P4 di salinan harus membuat `node alat/uji-sql.mjs supabase/tes/helper.sql` **GAGAL**, dan repo bersih harus **LULUS**. Perbaiki juga `harapan_mesin` P4 di `alat/kalibrasi-cacat.json`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] Klaim bukti yang "dikoreksi" tetap salah: angka huruf 57 berkas `.woff2` tidak terproduksi oleh perintah yang dikutip
- **Tingkat:** K-3
- **Artefak:** `docs/ROADMAP.md:61` (bukti T0-01, baris diubah oleh commit ini)
- **Klaim yang dilanggar:** klaim #7 (dokumen fondasi diperbarui tanpa klaim basi) dan butir 3 pesan commit ("klaim bukti T0-01 … dicabut, diganti **angka terhitung + perintah hitungnya**").
- **Bukti:**
  - `git show 7e8c0b9 -- docs/ROADMAP.md | grep -n woff2` → `+… berkas huruf **57 berkas** .woff2 (dihitung ulang 2026-09-17: find aplikasi -name '*.woff2' | wc -l) …`
  - `find aplikasi -name '*.woff2' | wc -l` → `38` (perintah yang dikutip).
  - `find . -name '*.woff2' | wc -l` → `57` (angka 57 hanya benar bila dihitung dari **akar repo**, termasuk `prototipe/`).
- **Skenario gagal:** Lee (atau auditor berikutnya) menyalin perintah bukti yang tertulis di ROADMAP dan mendapat 38, bukan 57 — angka bukti yang baru saja "dikoreksi" tetap tidak bisa direproduksi; kredibilitas "verifikasi menyeluruh" (inti commit ini) rontok pada butir yang justru sedang diperbaiki.
- **Dugaan penyebab:** angka 57 dihitung ulang dengan `find .` (seluruh repo) lalu dikutip bersama perintah `find aplikasi …` (hanya aplikasi) — dua lingkup yang berbeda.
- **Cara membuktikan perbaikan:** `find aplikasi -name '*.woff2' | wc -l` harus sama dengan angka di ROADMAP, atau tulis perintah `find . -name '*.woff2' | wc -l` bila maksudnya seluruh repo.
- **Status verifikasi:** TERVERIFIKASI

### [PR-03] Buku Uji Pemilik U-04 menyuruh Lee menyalin paket review BASI (putaran7), bukan paket berlaku (putaran8)
- **Tingkat:** K-2
- **Artefak:** `docs/uji/BUKU_UJI_PEMILIK.md:41` (baris U-04)
- **Klaim yang dilanggar:** klaim #7 (dokumen = sumber kebenaran, tidak basi) dan aturan paket §0b (peninjau harus menilai paket/commit yang berlaku).
- **Bukti:**
  - `grep -n putaran7-SIAP-TEMPEL docs/uji/BUKU_UJI_PEMILIK.md` → `41:| U-04 | … 2) Salin SELURUH isi `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran7-SIAP-TEMPEL.md` …`
  - `cat docs/uji/REVIEW_PR_RIWAYAT.md` → baris 4: `**Paket berlaku: `…pr-01-putaran8-SIAP-TEMPEL.md`**`.
- **Skenario gagal:** Lee mengikuti buku ujinya sendiri (satu-satunya cara dia "mencoba" review PR) → menyalin paket putaran7 yang menunjuk commit `183a3c1` (putaran sebelumnya) → review independen berjalan atas commit yang salah, hasilnya tidak sah untuk keputusan merge putaran8.
- **Dugaan penyebab:** putaran8 dibuat setelah buku uji ditulis; baris U-04 tidak ikut diperbarui saat paket disegarkan (tidak ada pemeriksa yang mencocokkan isi Buku Uji ke paket berlaku).
- **Cara membuktikan perbaikan:** baris U-04 menyebut `PKT-2026-09-17-pr-01-putaran8-SIAP-TEMPEL.md`, dan (Lebih baik) `alat/periksa-buku-uji.py` atau `periksa-rujukan.py` menolak bila baris U-04 menunjuk paket `-SIAP-TEMPEL` yang bukan yang terbaru di `REVIEW_PR_RIWAYAT`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-04] Bahan kalibrasi review PR korup (`git apply` gagal) dan pembuatnya (`--kalibrasi-pr-siapkan`) gagal karena katalog basi
- **Tingkat:** K-2
- **Artefak:** `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` (hunk 0005, baris 39) · `alat/kalibrasi-cacat.json` (P3) · `alat/review-pr.py` (`kalibrasi_pr_siapkan`)
- **Klaim yang dilanggar:** RV-3 (§2 protokol: kalibrasi review PR sebelum pilot) — mekanisme yang diminta paket §5 "periksa bahan itu secara terpisah" harus bisa diterapkan.
- **Bukti:**
  - Di salinan repo (tidak menyentuh repo asli): `git apply --check docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` → `error: corrupt patch at line 39`.
  - Sebab: hunk `0005_izin_berjenjang.sql` di bahan memuat **5 pasang +/-** (`-revoke boleh(text,uuid) …` dan 4 baris konteks) padahal berkas sumber hanya mencocokkan 4 → git menolak hunk berikutnya.
  - `python3 alat/review-pr.py --kalibrasi-pr-siapkan` → `GAGAL menyiapkan kalibrasi PR: - P3: pola tidak ditemukan (katalog basi!)` — karena katalog P3 `cari` = `"    if v_sebelum > v_pesanan.total then"` (4 spasi), sedangkan berkas sekarang `"  if v_sebelum > v_pesanan.total then"` (2 spasi, berubah sejak `b936ddd`).
- **Skenario gagal:** peninjau mana pun yang mengikuti paket §5 secara harfiah berhenti di `git apply`; dan agent yang menyegarkan bahan kalibrasi di putaran berikut mendapat GAGAL (katalog basi) — kalibrasi review PR praktis tidak berjalan untuk PR ini.
- **Dugaan penyebab:** (a) katalog P3 memakai indentasi lama yang kedaluwarsa; (b) generator membuang "penanda SENGAJA" dengan `re.sub` yang dapat mengubah jumlah baris hunk tanpa menyesuaikan hitungan baris `@@` dif.
- **Cara membuktikan perbaikan:** (1) `git apply --check docs/uji/kalibrasi/pr-bahan-*.diff` → exit 0; (2) `python3 alat/review-pr.py --kalibrasi-pr-siapkan` → membuat berkas `pr-bahan-*.diff` baru yang lolos `git apply --check`, dari katalog yang polanya cocok dengan berkas terkini.
- **Status verifikasi:** TERVERIFIKASI

### [PR-05] Daftar klaim di paket review rusak: 7 butir kosong + butir 2/3 basi (akar penyebab di `alat/review-pr.py::klaim_dari_commit`)
- **Tingkat:** K-3
- **Artefak:** `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md` (bagian "## 3. Klaim") · `alat/review-pr.py:104-119`
- **Klaim yang dilanggar:** kontrak paket "klaim yang wajib kamu bantah" harus memuat klaim commit yang direview; perintah paket §6 (laporan memuat minimal 5 klaim yang masih benar).
- **Bukti:**
  - `sed -n '/## 3. Klaim/,/## 4./p' docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md` → butir 1–7 **kosong**; butir 2 = `Paket baru docs/…/putaran7-SIAP-TEMPEL.md`; butir 3 = `REVIEW_PR_RIWAYAT baris 3 (paket berlaku) + baris 2 digantikan` — keduanya fakta putaran7.
  - Reproduksi akar penyebab (logika persis `klaim_dari_commit`): `git log --no-merges --format='%s%n%b%n---' origin/main..HEAD` → 8 klaim pertama yang terbentuk = `['', '', '', '', '', '', '', 'Paket baru …putaran7…']`.
  - `sed -n '104,119p' alat/review-pr.py` → kondisional `if not b or b.startswith("- ") and len(b) > 12:` membuat **setiap baris kosong** menjadi klaim kosong (lewati `not b`), sehingga 7 slot pertama terpakai baris kosong dan klaim sungguhan pertama jatuh pada bullet commit lama (putaran7), bukan commit yang direview.
- **Skenario gagal:** peninjau yang kurang teliti merebut klaim butir 2/3 untuk memeriksa paket putaran7 / baris riwayat 3+2 (basi) alih-alih putaran8; sekaligus 7 dari 8 slot klaim paket tidak berguna — kontrak "minimal 5 klaim dibantah" secara efektif terpenuhi oleh klaim bawaan saja.
- **Dugaan penyebab:** bug kondisional di `klaim_dari_commit` (baris kosong lolos filter) + urutan `git log` terbalik mengambil bullet `- ` dari pesan commit paling baru yang kebetulan bukan commit target.
- **Cara membuktikan perbaikan:** `python3 alat/review-pr.py --siapkan --dasar origin/main --kepala <sha-target>` menghasilkan bagian "## 3. Klaim" tanpa butir kosong dan dengan butir yang menyebut fakta commit target (mis. "Putaran verifikasi + Buku Uji Pemilik"). Tambah uji-diri: paket tidak boleh berisi baris klaim kosong dan klaim pertama harus berasal dari commit kepala.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Ditemukan: 4 dari 4 · temuan palsu: 0 · (catatan: bahan itu sendiri KORUP — lihat temuan [PR-04])

Prosedur: bahan `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` diperiksa **terpisah** dari repo (salinan `/tmp/rb-*`). Karena `git apply` gagal ("corrupt patch at line 39"), keempat cacat diterapkan manual satu per satu ke salinan bersih dan diuji. Daftar cacat yang saya temukan:

| ID (katalog) | Tingkat | Kelas | Berkas | Saya menemukan? | Bukti tertangkap gerbang |
|---|---|---|---|---|---|
| P1 | K-1 | hak-istimewa-fungsi (hak `boleh(text,uuid)` tidak dicabut) | `0005_izin_berjenjang.sql` | ya | `node alat/uji-sql.mjs supabase/tes/izin.sql` → GAGAL `anon tidak boleh memanggil boleh()` |
| P2 | K-1 | isolasi-penyewa (`pengaturan_pilih` lintas resto) | `0004_pola_rls.sql` | ya | `node alat/uji-sql.mjs supabase/tes/rls_semua_tabel.sql` → GAGAL `membocorkan 1 baris` |
| P3 | K-2 | uang-lebih-bayar (+100.000) | `0010_pembayaran.sql` | ya | `node alat/uji-sql.mjs supabase/tes/pembayaran.sql` DAN `gerbang_uang.sql` → GAGAL `perintah tidak ditolak` |
| P4 | K-2 | akun-nonaktif (`cabang_saya()` tanpa `p.aktif`) | `0003_helper_identitas.sql` | ya | **21 LULUS · 0 GAGAL — lolos semua uji**, sehingga tidak tertangkap mesin (bertentangan dengan `harapan_mesin: "ya"` di katalog). Dampak nyata dibuktikan dengan probe: `cabang_saya()` mengembalikan cabang untuk pegawai nonaktif |

Kesimpulan kalibrasi: skor deteksi 4/4 (100%) · 0 temuan palsu, tetapi kelas K-2 "akun-nonaktif" lolos dari mesin — persis cacat yang seharusnya dideteksi kalibrasi, dan bahan/katalognya sendiri rusak (temuan [PR-04]).

## 6. Yang tidak bisa saya verifikasi

- Perilaku nyata di **Supabase di-hosting** (bcrypt `pgcrypto` asli, mekanisme kunci `anon`/`service_role`, Data API) — uji SQL memakai PGlite + tiruan pgcrypto; akun Supabase belum ada (butir tunggu T-018).
- Pratinjau desain (baris U-01 Buku Uji) di peramban nyata — tidak ada peramban pada sesi ini; hanya `npm run build` (lolos) yang saya jalankan.
- Isi detail *run* GitHub Actions untuk commit `7e8c0b9` — API melaporkan `success` untuk `7e8c0b9` dan `f59debd` (PR #1 head), tetapi saya tidak membuka log langkah per langkahnya; gerbang yang sama saya jalankan ulang lokal dan semuanya hijau.
- Apakah kunci kalibrasi di luar repo (`/tmp/KUNCI-KALIBRASI-PR-*.md`) ada di lingkungan sesi kerja — dilarang dicari; hasil saya di bagian 5 murni dari bahan yang diberikan.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah. Bukti: `git status --short` menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
| — | tidak ada | Temuan yang saya kumpulkan semuanya berasal dari berkas dalam diff PR ini (atau mekanisme yang diubahnya) dan sudah dilaporkan di bagian 4 dan 5 | `git diff origin/main...7e8c0b9 --name-only` = 338 berkas; setiap temuan dirujuk ke berkas di dalamnya | — |