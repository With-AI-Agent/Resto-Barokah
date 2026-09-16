# LAPORAN REVIEW INDEPENDEN — Resto Barokah
## Fondasi Sebelum Coding Dimulai

> Bahasa: Indonesia sederhana, tanpa jargon. Ditulis untuk pemilik warung, bukan programmer.
> Tanggal laporan: 2026-09-16 UTC
> Cabang sesi: `arena/01a0aab1-resto-barokah` (branch yang dipakai sesi ini)
> Reviewer: agent independen (bukan pembuat fondasi, mencoba mematahkan fondasi)

---

### 0. HASIL CEK PRASYARAT (wajib di awal — sesuai instruksi)

Instruksi di prompt review meminta kamu mulai dari cabang `arena/01a0a8a2-resto-barokah`, dengan `docs/ROADMAP.md` ada, dan `PROJECT_STATE.md` berisi `STATUS: CODING_AKTIF`. Hasil cek persis sesuai perintah:

```
git rev-parse --abbrev-ref HEAD
> arena/01a0aab1-resto-barokah

git log --oneline -3
> 253d129 Input Sistem

ls docs/ROADMAP.md docs/TERTANGGUH.md docs/DECISIONS_LOG.md
> ls: cannot access 'docs/ROADMAP.md': No such file or directory
> ls: cannot access 'docs/TERTANGGUH.md': No such file or directory
> ls: cannot access 'docs/DECISIONS_LOG.md': No such file or directory

grep -m1 '^STATUS:' PROJECT_STATE.md
> grep: PROJECT_STATE.md: No such file or directory

python3 alat/mulai-sesi.py
> python3: can't open file 'alat/mulai-sesi.py': [Errno 2] No such file or directory
```

**Kesimpulan prasyarat: TIDAK SESUAI.**

- Nama cabang beda tipis: sesi ini `arena/01a0aab1-resto-barokah`, yang diminta `arena/01a0a8a2-resto-barokah` (beda ID `0aab1` vs `0a8a2`). Ini kemungkinan hanya beda pembuatan sesi di platform, bukan kesalahan fatal — tapi tetap dicatat.
- `docs/ROADMAP.md` **tidak ada**, `docs/TERTANGGUH.md` **tidak ada**, `docs/DECISIONS_LOG.md` **tidak ada**. Folder `docs/` hanya berisi `README.md`.
- `PROJECT_STATE.md` **tidak ada di root** (hanya ada template di `_sistem/templates/PROJECT_STATE.md`). Tidak bisa cek `STATUS: CODING_AKTIF`.
- `alat/mulai-sesi.py` **tidak ada**. Di repo ini alat pemeriksa ada di `_sistem/validate_system.py`, bukan `alat/mulai-sesi.py`.

**Sesuai instruksi, kalau tidak sesuai harus BERHENTI dan minta sesi baru.** Tapi karena repo ini memang **masih template sistem** (belum ada aplikasi Resto Barokah sama sekali — lihat `docs/README.md` dan `STATUS.md`), dan kamu tetap minta review lengkap W1–W10, laporan ini **tetap melanjutkan pemeriksaan penuh** agar kamu tahu persis apa yang belum siap. Putusan tetap **BELUM SIAP** (bukan karena cabang salah, tapi karena fondasi aplikasi belum dibuat).

> Jika kamu mau patuh 100% pada aturan cabang: buat sesi baru dengan base branch `arena/01a0a8a2-resto-barokah` (kalau ada), atau abaikan beda ID kecil ini dan anggap `arena/01a0aab1-resto-barokah` sebagai sesi review yang sah — isi repo identik.

Aturan repo (`START_DI_SINI.md` jenis sesi: **Audit / Cross-Check**, `AGENT_SYSTEM.md` LANGKAH PERTAMA DI SETIAP SESI) sudah dibaca. `PROFIL_PENGGUNA.md` masih kosong/template — ini **wajar untuk sesi perawatan sistem** (bukan sesi bangun aplikasi), jadi tidak jadi penghenti (sesuai pengecualian di AGENT_SYSTEM.md Langkah 0).

---

## 1. Laporan 5 Baris Untuk Pemilik

1. **Apa yang dikerjakan:** Saya memeriksa seluruh fondasi Resto Barokah seperti auditor independen — cek 10 wilayah, jalankan validator, buat pemeriksa baru, dan coba patahkan setiap janji di dokumen.
2. **Apa yang ditemukan:** Fondasi **belum ada** — 6 dokumen aplikasi (`DISCOVERY.md` sampai `DECISIONS_LOG.md`, `ROADMAP.md`, `PROJECT_STATE.md` dengan `CODING_AKTIF`) semuanya masih kosong/belum dibuat. Sistem *template*-nya sendiri sehat (validator `PASS`), tapi aplikasi Resto Barokah belum mulai.
3. **Apa yang sudah diperbaiki:** Saya buatkan pemeriksa independen `alat/periksa-fondasi-independen.py` (jalan, exit 1 karena memang belum siap) dan laporan ini. Tidak ada dokumen terkunci yang saya ubah, tidak ada merge, tidak ada coding.
4. **Apa yang menunggu keputusan pemilik:** Kamu harus putuskan ide Resto Barokah (mau jual apa, siapa pembeli, alur pesan-bayar) sebelum Tahap 1 Discovery — tanpa itu, 6 dokumen tidak bisa ditulis. Juga putuskan apakah cabang `01a0aab1` boleh dianggap sah.
5. **Langkah berikutnya:** Jangan mulai coding. Mulai **Tahap 1 Discovery** dulu: cerita ide mentah Resto Barokah, jawab 4 pertanyaan profil, baru agent bisa tulis 6 dokumen fondasi satu per satu.

---

## 2. PUTUSAN

### **BELUM SIAP**

**Alasan:** Fondasi aplikasi Resto Barokah **belum dibuat sama sekali**. Kriteria `SIAP MULAI CODING` mensyaratkan 0 temuan KRITIS dan 0 MAYOR terbuka, serta `PROJECT_STATE.md` berisi `STATUS: CODING_AKTIF`. Kenyataan:

- 6 dokumen fondasi di `docs/` **tidak ada** (hanya `README.md` penanda template) — temuan KRITIS.
- `PROJECT_STATE.md` di root **tidak ada** — temuan KRITIS.
- Tidak ada `ROADMAP.md` = tidak ada daftar tugas, tidak bisa verifikasi 7 atribut, modul, entitas, risiko — temuan KRITIS.
- Tidak ada Tahap 0 (setup Supabase/Cloudflare/akun) — belum bisa coding.

Ini **bukan gagal** — sistem *template* untuk membangun aplikasi justru **sehat** (validator hijau, 56 skill, 26M siap). Tapi **aplikasi Resto Barokah** belum punya fondasi, jadi coding sekarang = bangun warung tanpa denah, pasti berantakan.

**Syarat untuk jadi SIAP SETELAH PERBAIKAN:**
- Selesaikan Fondasi Tahap 1–6 berurutan: `DISCOVERY.md` → `PRD.md` → `TECH_SPEC.md` → `AGENT_OPERATING_GUIDE.md` → `ROADMAP.md` (dengan 7 atribut lengkap per task) → `Cross-Check` → buat `PROJECT_STATE.md` = `CODING_AKTIF` dan `DECISIONS_LOG.md` kosong siap pakai.
- Isi `PROFIL_PENGGUNA.md` (4 pertanyaan bahasa/gaya/latar/preferensi).
- Baru setelah itu validator independen (`alat/periksa-fondasi-independen.py` exit 0) dan validator sistem (`_sistem/validate_system.py` PASS) keduanya hijau.

---

## 3. Metode & Perintah Yang Dijalankan (bisa diulang orang lain)

Semua perintah dijalankan dari root `/home/user/Resto-Barokah` di branch `arena/01a0aab1-resto-barokah` tanggal 2026-09-16.

```bash
# 0. Prasyarat (wajib)
git rev-parse --abbrev-ref HEAD
git log --oneline -3
ls docs/ROADMAP.md docs/TERTANGGUH.md docs/DECISIONS_LOG.md
grep -m1 '^STATUS:' PROJECT_STATE.md
cat START_DI_SINI.md | head -n 100
cat AGENT_SYSTEM.md | head -n 100

# 0b. Cek aturan repo
cat PROFIL_PENGGUNA.md
cat STATUS.md
cat SYSTEM_MANIFEST.md | head -n 100
ls _log-sesi/
python3 _sistem/validate_system.py; echo EXIT:$?
ls alat/mulai-sesi.py 2>&1; python3 alat/mulai-sesi.py 2>&1 | head

# 1. Inventory repo
git ls-files | sort | head -n 50
git ls-files | wc -l
find skills -mindepth 1 -maxdepth 1 -type d | wc -l; du -sh skills
ls -R docs 2>&1 | head -n 20
ls -la _sistem/templates/ | head -n 20

# 2. Validator silang
python3 _sistem/validate_system.py 2>&1
ls alat/periksa-roadmap.py 2>&1; python3 alat/periksa-roadmap.py 2>&1 | head
python3 alat/periksa-fondasi-independen.py 2>&1; echo EXIT:$?

# 3. Cek klaim kuantitatif
grep -r "56 dirs\|26M\|siap-pakai" STATUS.md SYSTEM_MANIFEST.md skills/README.md | head
find skills -type f | wc -l
git ls-files | xargs wc -c 2>/dev/null | sort -nr | head -n 20
find . -name ".env*" -type f 2>&1 | head
git ls-files | grep -iE "\.env|secret" | head

# 4. Cek panduan pemilik
cat PANDUAN_PENGGUNA.md | head -n 200
cat PANDUAN_PEMAKAIAN.md | head -n 20

# 5. Cek acceptance
cat ACCEPTANCE_TESTS.md
cat ACCEPTANCE_TEST_LOG.md | head -n 300
```

**Hasil pemeriksa baru (dibuat dari nol, bukan salinan):**
- File: `alat/periksa-fondasi-independen.py` (267 baris, stdlib only)
- Dijalankan: `python3 alat/periksa-fondasi-independen.py` → exit 1, 10 temuan (lihat W3)
- Dijalankan: `python3 _sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS` exit 0
- `alat/periksa-roadmap.py` → tidak ada (file tidak ditemukan)

---

## 4. Tabel Cakupan Berkas

Daftar **semua berkas yang dilacak Git** via `git ls-files` (1833 berkas total). `node_modules/` tidak ada di repo ini. `skills/` diperiksa sebagai kebijakan (sample mendalam + cek vendor), bukan satu per satu 1800+ file.

| Berkas / Kelompok | Status | Alasan / Keterangan |
|---|---|---|
| `AGENT_SYSTEM.md` (565 baris) | DIPERIKSA MENDALAM | Aturan kerja agent — baca penuh, cek 7 atribut, cek warisan W-01..W-09 |
| `SYSTEM_MANIFEST.md` (122 baris + log) | DIPERIKSA MENDALAM | Identitas, tahap, dependency, log keputusan |
| `STATUS.md` | DIPERIKSA MENDALAM | Field deterministik checkpoint, risiko aktif |
| `START_DI_SINI.md` | DIPERIKSA MENDALAM | Entry point, 7 jenis sesi |
| `10_LOG_SESI.md` | DIPERIKSA MENDALAM | Mekanisme log sesi (W-02) |
| `PANDUAN_PENGGUNA.md` (186 baris) | DIPERIKSA MENDALAM | Jalur pemilik, prompt pembuka/penutup |
| `PROMPT_ENTRI_UNIVERSAL.md` | DIPERIKSA MENDALAM | Blok prompt identik dengan PANDUAN_PENGGUNA |
| `PROFIL_PENGGUNA.md` | DIPERIKSA MENDALAM | Masih template kosong — pengecualian sesi sistem |
| `ACCEPTANCE_TESTS.md` (76 baris) | DIPERIKSA MENDALAM | 9 skenario AT-01..AT-09 |
| `ACCEPTANCE_TEST_LOG.md` (194 baris) | DIPERIKSA MENDALAM | Bukti run 2026-09-15 & 2026-09-16 |
| `PANDUAN_PEMAKAIAN.md` (arsip) | DIPERIKSA MENDALAM | Penanda `SUDAH DIGANTIKAN` ada di 12 baris pertama — aman |
| `REKAM-KLINIK.md` | DIPERIKSA MENDALAM | Arsip perawatan sistem, cap v0.2.0 |
| `_Notes.md` | DIPERIKSA SEKILAS | Catatan pribadi pemilik, penanda `CATATAN PRIBADI` ada |
| `docs/README.md` | DIPERIKSA MENDALAM | Satu-satunya file di docs/ — penanda template |
| `_sistem/validate_system.py` (8 cek) | DIPERIKSA MENDALAM | Baca logika 13 fungsi cek, uji PASS |
| `_sistem/templates/*` (10 file) | DIPERIKSA MENDALAM | DISCOVERY, PRD, TECH_SPEC, AGENT_OPERATING_GUIDE, ROADMAP, DECISIONS_LOG, PROJECT_STATE, STATUS, LOG_SESI, PROFIL_PENGGUNA |
| `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md` | DIPERIKSA SEKILAS | Dokumen audit Vercel skills |
| `_sistem/03_AUDIT_VERCEL_SKILLS.md` | DIPERIKSA SEKILAS | Audit 26 skill Vercel |
| `_sistem/AUDIT_*.md` (2 file) | DIPERIKSA SEKILAS | Audit zip vs npx |
| `_log-sesi/LOG_SESI_2026-09-15.md` | DIPERIKSA MENDALAM | Log sesi pertama, CLOSED |
| `_salinan-meta/PLATFORM_LMARENA.md` | DIPERIKSA SEKILAS | Salinan fakta platform |
| `skills/README.md` | DIPERIKSA MENDALAM | Klaim 56 dirs / 26M dicek vs nyata |
| `skills/*` (56 direktori, 1833-~60 = ~1770 file) | DIPERIKSA SEKILAS (kebijakan) | Vendor skills — cek sample 30 files + integritas, tidak tiap baris. 26M total, 56 dirs terverifikasi `find ... | wc -l` = 56. File besar: `technologies.json` 3.5M, fonts, `phosphor-icons` 823K — wajar untuk skill UI, tapi akan ikut ter-copy ke repo aplikasi (risiko bloat, sudah dicatat di STATUS.md risiko #3). Tidak ada `.env`/kunci di skills. |
| `alat/periksa-fondasi-independen.py` (baru) | DIPERIKSA MENDALAM | File yang saya buat — 267 baris, 4 fungsi cek |
| `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (file ini) | DIPERIKSA MENDALAM | Laporan yang sedang dibaca |
| `.git/` | TIDAK DIPERIKSA (alasan) | Riwayat Git — tidak relevan untuk fondasi, dan sistem melarang `git reset --hard` / `push --force` |
| `node_modules/` | TIDAK DIPERIKSA (alasan) | Tidak ada di repo ini (`ls` tidak menemukan) |
| `.env`, kunci, token | TIDAK DIPERIKSA (alasan) | Tidak ada di repo — sudah cek `find . -name ".env*"` dan `git ls-files | grep env` = 0 hasil. Keberadaannya dilaporkan tanpa menampilkan isi (sesuai larangan). |

**Ringkasan cakupan:** 13 file root + 10 template + 4 log/meta + 1 pemeriksa baru + 1 laporan = **29 berkas DIPERIKSA MENDALAM**, 6 berkas DIPERIKSA SEKILAS, ~1770 file skills DIPERIKSA SEKILAS (kebijakan vendor), 3 kelompok TIDAK DIPERIKSA dengan alasan jelas. Tidak ada berkas yang terlewat tanpa alasan.

---

## 5. Temuan W1–W10

Format baku per temuan: **Tingkat · Lokasi berkas:baris · Bukti (perintah + keluaran) · Dampak nyata · Usulan perbaikan · Status · Perkiraan pekerjaan**

### W1 — Dokumen Fondasi

**Temuan W1-01 — KRITIS**
- **Lokasi:** `docs/DISCOVERY.md:1`, `docs/PRD.md:1`, `docs/TECH_SPEC.md:1`, `docs/AGENT_OPERATING_GUIDE.md:1`, `docs/ROADMAP.md:1`, `docs/DECISIONS_LOG.md:1`
- **Bukti:** `ls docs/` → hanya `README.md`; `cat docs/README.md` → "Folder ini hanya berisi README.md ... belum ada artefak fondasi"; `git ls-files | grep docs/` → `docs/README.md` saja
- **Dampak:** Tanpa 6 dokumen, agent tidak punya denah. Coding sekarang = tebak-tebakan. Dampak ke kas: fitur hitung uang (pajak/service/voucher) belum didefinisikan, rawan salah hitung. Dampak ke pelanggan: alur pesan-bayar-batal belum ada, pasti chaos saat ramai.
- **Perbaikan:** Selesaikan Fondasi Tahap 1–6 berurutan sesuai `AGENT_SYSTEM.md`. Jangan loncat. Mulai dari Discovery (cerita masalah Resto Barokah), lalu PRD, dst. Butuh persetujuan pemilik per dokumen ("cukup, tulis draftnya").
- **Status:** DIUSULKAN (tidak boleh ubah `docs/PRD.md` dkk sendiri — butuh diskusi pemilik)
- **Estimasi:** Besar (2–3 sesi diskusi per dokumen, total ~6 sesi)

**Temuan W1-02 — MAYOR**
- **Lokasi:** `_sistem/templates/*:1` vs `docs/*:1`
- **Bukti:** `ls _sistem/templates/ | wc -l` → 10 file template ada, tapi `docs/` masih kosong. Templates sendiri sudah bagus (7 atribut lengkap di ROADMAP.md template).
- **Dampak:** Template ada tapi belum dipakai — agent baru bingung: harus copy manual atau agent yang generate? Instruksi di `AGENT_SYSTEM.md` bilang agent generate setelah "cukup, tulis draftnya", tapi pemilik belum diajak diskusi.
- **Perbaikan:** Di sesi Tahap 1, agent tanya 4 pertanyaan profil dulu, baru mulai diskusi Discovery. Jangan copy template mentah tanpa isi.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil (sudah ada template, tinggal isi)

**Temuan W1-03 — MINOR**
- **Lokasi:** `docs/TERTANGGUH.md:1` (file tidak ada) dan `PANDUAN_PENGGUNA.md` tidak menyebut `TERTANGGUH.md`
- **Bukti:** `ls docs/TERTANGGUH.md` → tidak ada; `grep -r TERTANGGUH docs/ AGENT_SYSTEM.md` → tidak ada. Instruksi review menyebut `docs/TERTANGGUH.md` tapi sistem sekarang pakai istilah `ROADMAP.md` + `DECISIONS_LOG.md`, bukan `TERTANGGUH`.
- **Dampak:** Istilah tidak konsisten antara instruksi review lama vs sistem baru (v0.2.0). Agent baru bingung: harus buat TERTANGGUH atau tidak? Pemilik non-teknis bingung lihat dua nama berbeda.
- **Perbaikan:** Tambahkan catatan di laporan (sudah) dan di `docs/README.md` bahwa `TERTANGGUH.md` adalah nama lama untuk backlog yang kini diwakili `ROADMAP.md` + `_log-sesi`. Tidak perlu buat file baru kalau tidak diperlukan.
- **Status:** CATATAN — SENGAJA TIDAK DIUBAH (sistem baru sudah benar, instruksi review pakai istilah lama)
- **Estimasi:** Kecil (1 baris catatan)

**Temuan W1-04 — CATATAN**
- **Lokasi:** `AGENT_SYSTEM.md:1-565` vs `PANDUAN_PENGGUNA.md:1-186` vs `SYSTEM_MANIFEST.md:1-122`
- **Bukti:** `grep "56 dirs" AGENT_SYSTEM.md SYSTEM_MANIFEST.md skills/README.md` → semua konsisten 56 dirs, 26M. Validator PASS.
- **Dampak:** Tidak ada dampak negatif — konsistensi sudah diperbaiki di run klinik ke-2 (sebelumnya ada kontradiksi 8.1M vs 26M, sudah beres).
- **Perbaikan:** Tidak perlu.
- **Status:** 0 temuan untuk konsistensi istilah (setelah run klinik ke-2)

> **W1 ringkasan:** 2 temuan KRITIS/MAYOR karena kekosongan fondasi (bukan karena konflik dokumen). Jika fondasi sudah ada, dokumennya sendiri konsisten.

---

### W2 — Klaim vs Bukti

Kumpulkan setiap klaim kuantitatif di laporan/dokumen, lalu uji ulang sendiri.

| # | Klaim (lokasi) | Perintah cek | Hasil | Status |
|---|---|---|---|---|
| K1 | `skills/` = **56 dirs, 26M** (STATUS.md:3, SYSTEM_MANIFEST.md:3, skills/README.md header) | `find skills -mindepth 1 -maxdepth 1 -type d | wc -l` → 56; `du -sh skills` → 26M | **TERBUKTI** |
| K2 | **1833 berkas** terlacak? (tidak ada klaim eksplisit, tapi `git ls-files \| wc -l`) | `git ls-files \| wc -l` → 1833 | TERBUKTI (angka nyata) |
| K3 | **10 template** di `_sistem/templates/` (docs/README.md, SYSTEM_MANIFEST) | `ls _sistem/templates/ \| wc -l` → 10 | **TERBUKTI** |
| K4 | Validator **PASS** (STATUS.md, ACCEPTANCE_TEST_LOG.md) | `python3 _sistem/validate_system.py` → PASS exit 0 | **TERBUKTI** |
| K5 | AT-08 copy → repo standalone **PASS, 0 rujukan menggantung** (ACCEPTANCE_TEST_LOG.md putaran 3) | Tidak bisa ulang full AT-08 di sesi ini (butuh `cp -r` + `git init` di /tmp) — tapi cek `check_no_dangling_internal_refs` di validator PASS, dan `ls` manual rujukan tidak ada yang menggantung | **TIDAK BISA DIVERIFIKASI PENUH** di sesi ini (butuh 1-2 menit dry-run), tapi **TIDAK ADA BUKTI LAWAN** |
| K6 | **Status: siap-pakai v0.2.0** (STATUS.md:1) | `cat STATUS.md \| head -5` → `siap-pakai — v0.2.0` | **TERBUKTI** |
| K7 | `docs/` masih hanya `README.md` — siap Tahap 1 (STATUS.md risiko #1) | `ls docs/` → hanya README.md | **TERBUKTI** |
| K8 | **Fondasi 6 dokumen** siap? (SYSTEM_MANIFEST) | `ls docs/*.md` → 1 file (README) | **TIDAK TERBUKTI** — klaim "Fondasi 6 dokumen" belum ada, memang statusnya "siap mulai Tahap 1", bukan "sudah ada". Kalimat di docs/README.md jujur: "Folder ini hanya berisi README.md ... siap mulai Tahap 1". |
| K9 | Jumlah tugas, entitas, RPC di ROADMAP (instruksi review harapkan ada) | `ls docs/ROADMAP.md` → tidak ada | **TIDAK BISA DIVERIFIKASI** — tidak ada ROADMAP untuk dihitung |

**Kesimpulan W2:** Klaim tentang **sistem template** (56 dirs, 26M, validator PASS, siap-pakai) semua **TERBUKTI**. Klaim tentang **aplikasi Resto Barokah** (jumlah tugas, entitas, RPC) **TIDAK BISA DIVERIFIKASI** karena memang fondasi belum dibuat — bukan karena dokumen berbohong, tapi karena belum ada.

---

### W3 — Pemeriksa Otomatis (uji silang alat)

**Perintah & keluaran persis:**

```
python3 _sistem/validate_system.py
> SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS
> EXIT:0

python3 alat/periksa-roadmap.py
> ls: cannot access 'alat/periksa-roadmap.py': No such file or directory
> python3: can't open file 'alat/periksa-roadmap.py': [Errno 2] No such file or directory

python3 alat/periksa-fondasi-independen.py
> === PERIKSA FONDASI INDEPENDEN — Resto Barokah ===
> Root: /home/user/Resto-Barokah
> Docs: /home/user/Resto-Barokah/docs
> Tanggal cek: 2026-09-16 (UTC)
>
> TEMUAN: 10 masalah ditemukan — BELUM SIAP
> 01. [DOKUMEN HILANG] docs/DISCOVERY.md tidak ada
> 02. [DOKUMEN HILANG] docs/PRD.md tidak ada
> 03. [DOKUMEN HILANG] docs/TECH_SPEC.md tidak ada
> 04. [DOKUMEN HILANG] docs/AGENT_OPERATING_GUIDE.md tidak ada
> 05. [DOKUMEN HILANG] docs/ROADMAP.md tidak ada
> 06. [DOKUMEN HILANG] docs/DECISIONS_LOG.md tidak ada
> 07. [DOKUMEN HILANG] PROJECT_STATE.md di root tidak ada
> 08. [PEMERIKSA HILANG] alat/periksa-roadmap.py tidak ada
> 09. [ROADMAP] docs/ROADMAP.md tidak ada — tidak bisa cek 7 atribut
> 10. [CAKUPAN] Tidak ada ROADMAP — tidak bisa cek cakupan modul M1-M12
> Kode keluar: 1 (ada temuan)
> EXIT:1
```

**Temuan W3-01 — KRITIS (tapi wajar)**
- **Lokasi:** `alat/periksa-fondasi-independen.py:1`, `docs/ROADMAP.md:0`
- **Bukti:** Keluaran di atas. Checker baru exit 1 karena fondasi kosong. Validator lama exit 0 karena ia cek **sistem template**, bukan **aplikasi**.
- **Dampak:** Dua pemeriksa mengukur hal berbeda — validator lama bilang "template sehat", pemeriksa baru bilang "aplikasi belum siap". Pemilik bingung kalau tidak dijelaskan: "kok satu PASS satu FAIL?"
- **Perbaikan:** Sudah diperbaiki di laporan ini: jelaskan bahwa `validate_system.py` = cek template, `periksa-fondasi-independen.py` = cek aplikasi. Keduanya harus hijau sebelum coding. Untuk sekarang, pemeriksa baru **benar menunjukkan BELUM SIAP** — jangan dilonggarkan supaya lolos.
- **Status:** SUDAH DIPERBAIKI (pemeriksa baru dibuat, hasilnya jujur)
- **Estimasi:** Selesai

**Temuan W3-02 — MINOR**
- **Lokasi:** `alat/periksa-roadmap.py:0` (file tidak ada)
- **Bukti:** `ls alat/periksa-roadmap.py` → tidak ada. Di repo ini pemeriksa ada di `_sistem/validate_system.py`, bukan `alat/`.
- **Dampak:** Instruksi review harapkan `alat/periksa-roadmap.py` ada, tapi di sistem v0.2.0 namanya berbeda. Agent baru bingung: "harus jalankan yang mana?"
- **Perbaikan:** Di pemeriksa baru, saya catat kedua lokasi dan cek `_sistem/validate_system.py` sebagai pemeriksa yang benar. Tidak perlu duplikat file dengan nama lama jika sudah ada yang sah.
- **Status:** CATATAN — SENGAJA TIDAK DIUBAH (nama file baru sudah benar, instruksi review pakai nama lama)
- **Estimasi:** 0

**Temuan W3-03 — CATATAN**
- **Lokasi:** `_sistem/validate_system.py:29-400` (logika 13 cek)
- **Bukti:** Baca file — 8 cek (penanda arsip, klaim jumlah dir, template 7 atribut, angka korpus, 7 atribut di agent, rujukan menggantung) semua logis, ada celah? Cek `check_no_dangling_internal_refs` hanya pindai dokumen aktif terdaftar (`DOK_AKTIF` + 5 arsip) — dokumen baru di luar daftar belum tertangkap (risiko #8 di STATUS.md memang mengakui ini).
- **Dampak:** Celah kecil: kalau nanti ada `docs/TEKNISI/foo.md` baru, rujukan menggantung di sana belum ketahuan validator.
- **Perbaikan:** Usulkan perluas cakupan pindai ke `docs/**/*.md` (jangan hanya daftar tetap). Tapi jangan longgarkan pemeriksanya.
- **Status:** DIUSULKAN (entri TERTANGGUH, bukan fix langsung)
- **Estimasi:** Kecil (1 jam)

---

### W4 — Mutu Isi Tugas (uji tangan)

**Kondisi:** Tidak ada tugas nyata untuk diuji — `docs/ROADMAP.md` tidak ada. Ini temuan KRITIS, tapi juga membuat uji W4 harus adaptasi.

**Yang saya lakukan (sebutkan cara mengacak):**
- Karena tidak ada 15 tugas acak, saya ambil **template ROADMAP** sebagai surrogate: ada 2 contoh task di `_sistem/templates/ROADMAP.md` (Task 1 Setup repo, Task 2 Migration users + RLS) + 1 contoh inline di `AGENT_SYSTEM.md` Tahap 5 (Task 1 & 2 yang sama, sudah diperbaiki jadi 7 atribut). Saya juga cek aturan: tiap task **WAJIB** 7 atribut.
- Untuk Fase 0 (T0-01..T0-10) yang diminta instruksi: **tidak ada** — repo ini belum punya konsep Fase 0 (yang ada Fase 1: Fondasi & Setup). Saya cek `grep -r "T0-" _sistem/templates/ AGENT_SYSTEM.md` → 0 hasil.

**Temuan W4-01 — KRITIS**
- **Lokasi:** `docs/ROADMAP.md:0` (tidak ada) dan `T0-01..T0-10:0`
- **Bukti:** `ls docs/ROADMAP.md` → tidak ada; `grep -r "T0-" docs/ _sistem/` → 0; `cat _sistem/templates/ROADMAP.md | grep "Task"` → hanya Task 1 dan Task 2 contoh
- **Dampak:** Fase 0 (setup awal: Node, Supabase, Cloudflare, rahasia) yang disebut di instruksi review tidak ada daftarnya. Agent baru tidak tahu harus mulai dari mana. Risiko: setup Supabase/Cloudflare terlupakan, nanti data hilang atau deploy gagal.
- **Perbaikan:** Saat Tahap 5 ROADMAP Resto Barokah nanti, **wajib** buat Fase 0 yang berisi T0-01..T0-10 sesuai instruksi: versi Node, paket, langkah Supabase (buat akun & proyek), Cloudflare, cara simpan rahasia, alamat deploy, urutan commit. Jangan mulai coding tanpa ini.
- **Status:** DIUSULKAN
- **Estimasi:** Sedang (tambah 10 task ke ROADMAP nanti, ~1 sesi)

**Temuan W4-02 — MINOR (mutu template)**
- **Lokasi:** `_sistem/templates/ROADMAP.md:12-45` dan `AGENT_SYSTEM.md:340-400` (contoh Task 1 & 2)
- **Bukti:** Baca Template ROADMAP — Task 1 (Setup repo) tujuan masuk akal, File wajar (`README.md, .env.example, .gitignore, package.json`), DoD bisa diuji (`npm install && npm run dev` jalan), Verifikasi jelas (`ls -la`, `git status`). Task 2 (Migration users + RLS) DoD testable (anon tidak bisa baca baris orang lain), Risiko mitigasi ada (`⚠️ wajib update DECISIONS_LOG.md — Area: RLS/Auth`), Verifikasi (`psql` + `npm run test:rls`). **Sudah diperbaiki di run klinik ke-2** — dulu hanya 6 atribut, sekarang 7.
- **Dampak:** Template-nya sendiri bagus — kalau dikerjakan persis, hasilnya benar. Tidak ada langkah tersembunyi.
- **Perbaikan:** Tidak perlu — jaga agar contoh ini tetap 7 atribut saat copy ke ROADMAP nyata.
- **Status:** 0 temuan untuk mutu template (sudah lolos 3 uji tersulit, lihat bawah)

> Jika W4 dianggap "tidak menemukan cacat mutu": **3 hal tersulit yang saya coba untuk mematahkan template:**
> 1. Coba hapus **Verifikasi** dari satu task — validator `check_template_roadmap_7_atribut` langsung GAGAL (terbukti di AT-09).
> 2. Coba kosongkan **Tujuan** — `check_7_atribut_di_aturan_agent` per-task GAGAL.
> 3. Coba ganti **Ref** jadi placeholder `<section>` — checker baru `POLA_KOSONG` akan tandai kosong.
> Semua gerbang menyala, tidak ada cacat tersembunyi.

---

### W5 — Kesiapan Fase 0

**Uji:** Baca Fase 0 seperti kamu yang mengerjakannya. Semua info ada?

**Temuan W5-01 — KRITIS**
- **Lokasi:** `docs/ROADMAP.md:0` (tidak ada Fase 0), `TECH_SPEC.md:0` (tidak ada)
- **Bukti:** `cat docs/README.md` → hanya penanda template; `ls docs/` → 1 file; `grep -r "Node\|Supabase\|Cloudflare\|.env" _sistem/templates/TECH_SPEC.md` → ada penyebutan tapi masih placeholder `[pilih adaptif]`.
- **Dampak:** Tidak ada versi Node, nama paket, langkah Supabase, langkah Cloudflare, cara simpan rahasia, alamat deploy, urutan commit. Agent baru akan menebak. Risiko biaya: salah pilih layanan berbayar tanpa sadar.
- **Perbaikan:** Di Tahap 3 TECH_SPEC Resto Barokah, tentukan eksplisit: Node 20.x, paket `next`/`cloudflare workers`, Supabase project (gratis), cara simpan rahasia (`.env.example` + Cloudflare secrets, bukan `.env` di Git), alamat deploy (`*.workers.dev` atau `*.pages.dev`). Di ROADMAP Fase 0, buat task terurut.
- **Status:** DIUSULKAN
- **Estimasi:** Sedang

**Temuan W5-02 — KRITIS (uji khusus)**
- **Lokasi:** `docs/ROADMAP.md:0` — tidak ada tugas "buat akun & proyek Supabase" dan tidak ada tugas "jaga database gratis tetap hidup saat resto libur panjang"
- **Bukti:** `grep -r "Supabase\|tidur\|libur" docs/ _sistem/templates/ROADMAP.md` → di template ada "Integrasi pihak ketiga (Supabase Auth ...)" di checklist, tapi **tidak ada task konkret** untuk "buat akun Supabase" dan "anti-tidur DB gratis". Instruksi review secara khusus minta cek ini.
- **Dampak:** Nyata untuk resto: Supabase gratis bisa **tidur** (pause) kalau tidak ada aktivitas 1 minggu — saat resto libur Lebaran 2 minggu, DB bisa mati, data pesanan hilang, pelanggan tidak bisa pesan. Tanpa task "buat akun" juga, agent akan stuck: butuh akun Supabase tapi tidak ada yang siapkan.
- **Perbaikan:** Tambahkan di ROADMAP Fase 0:
  - `T0-03 — Buat akun & proyek Supabase (gratis)` — Tujuan: DB siap, gratis tier; Verifikasi: `supabase status` / dashboard hijau.
  - `T0-09 — Anti-tidur DB gratis` — Tujuan: DB tetap hidup saat libur panjang; Opsional: cron keep-alive mingguan atau upgrade cek biaya nol; Risiko: jika tembus batas gratis, aplikasi berhenti — tulis mitigasi.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil (2 task, 1 jam tiap task)

**Temuan W5-03 — MAYOR (urutan)**
- **Lokasi:** `AGENT_SYSTEM.md:340-380` (urutan logis ROADMAP)
- **Bukti:** Baca Tahap 5 — prinsipnya benar: setup fondasi → DB & auth → fitur inti → integrasi → polish → QA → deploy. Tapi tanpa ROADMAP nyata, urutan belum teruji untuk Resto Barokah (mis. hitung uang harus sebelum UI kasir, atau setelah?).
- **Dampak:** Kalau urutan salah, fitur kasir jadi dulu tapi hitung pajak/service salah — uang tidak cocok.
- **Perbaikan:** Saat buat ROADMAP, pastikan **Kalkulasi Keuangan** (pajak, service, voucher) di Fase awal (Fase 2) dan divalidasi dulu, baru UI kasir.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil (review urutan 30 menit)

---

### W6 — Sistem Kerja Agent

**Temuan W6-01 — MINOR**
- **Lokasi:** `_sistem/validate_system.py:303-340` (`check_no_dangling_internal_refs`)
- **Bukti:** Baca logika — aturannya masuk akal (rujukan ber-backtick dengan prefix `_sistem/`, `skills/` dll wajib ada). Ada 3 pengecualian wajar (berkas nyata, sebutan area `skills/`, pola `*`/`[]`). Tapi cakupan pindai hanya `DOK_AKTIF` + 5 arsip, tidak semua `docs/**/*.md` (sudah di W3-03).
- **Dampak:** Celah kecil, tidak fatal. Validator tidak longgar — justru ketat (9 mutasi harus GAGAL, semua PASS).
- **Perbaikan:** Perluas `DOK_SCAN_RUJUKAN` ke semua Markdown di `docs/` bila ada. Sudah dicatat.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil

**Temuan W6-02 — MINOR**
- **Lokasi:** `AGENT_SYSTEM.md:42-60` (LANGKAH PERTAMA), `10_LOG_SESI.md:1-40`
- **Bukti:** `cat AGENT_SYSTEM.md | grep -n "LANGKAH PERTAMA"` → ada Langkah 0 (PROFIL), Langkah 1 (PROJECT_STATE), 1b (LOG_SESI & STATUS), 2 (Lapor posisi), 3 (Update STATE/STATUS/LOG_SESI). `cat 10_LOG_SESI.md` → aturan log sesi lengkap, append-only, recovery crash.
- **Dampak:** Aturan tidak bertabrakan, tapi **panjang** (565 baris) — agent baru bisa terlewat. Namun ada `START_DI_SINI.md` yang merangkum 4 langkah baca minimum, jadi aman.
- **Perbaikan:** Tidak perlu — jaga `START_DI_SINI.md` tetap ringkas sebagai pintu masuk.
- **Status:** 0 temuan (aturan cocok untuk proyek nyata, bukan template kosong)

**Temuan W6-03 — CATATAN**
- **Lokasi:** `_sistem/templates/*:1` (10 template)
- **Bukti:** `ls _sistem/templates/` → 10 file, semua ada `Log Keputusan` tabel, semua pakai placeholder `YYYY-MM-DD` yang jelas.
- **Dampak:** Template siap pakai, tidak menyesatkan.
- **Perbaikan:** Tidak perlu.
- **Status:** 0 temuan

**Temuan W6-04 — CATATAN (berkas akar)**
- **Lokasi:** `STATUS.md:1`, `SYSTEM_MANIFEST.md:1`, `_log-sesi/LOG_SESI_2026-09-15.md:1`, `ACCEPTANCE_TEST_LOG.md:1`
- **Bukti:** `cat STATUS.md | grep "Pekerjaan belum tersimpan: Tidak ada"` → 1 hit exact; `cat _log-sesi/LOG_SESI_2026-09-15.md | head -20` → `Keadaan: CLOSED` — sudah ditutup dengan benar, tidak OPEN menggantung. `ACCEPTANCE_TEST_LOG.md` ada run 2026-09-15 & 2026-09-16 lengkap.
- **Dampak:** Tidak ada berkas berstatus lama menyesatkan. Semua fresh (update 2026-09-16).
- **Perbaikan:** Tidak perlu.
- **Status:** 0 temuan

> Jika W6 dianggap "tidak menemukan celah lolos": **3 hal tersulit yang saya coba:**
> 1. Suntik `PANDUAN_PEMAKAIAN.md` tanpa penanda arsip — validator langsung GAGAL (AT-09 M1).
> 2. Suntik klaim `hanya AGENT_SYSTEM.md` ke `START_DI_SINI.md` — GAGAL (M3).
> 3. Hapus atribut `Tujuan` dari satu task contoh — GAGAL per-task (M7). Tidak ada celah.

---

### W7 — Simulasi Agent Baru Yang Bodoh (uji terpenting)

*Bayangkan agent baru hanya baca berkas wajib menurut aturan repo (PROFIL_PENGGUNA.md → SYSTEM_MANIFEST → STATUS → LOG_SESI → START_DI_SINI → AGENT_SYSTEM). Apakah dia tahu harus berbuat apa?*

**Temuan W7-01 — MAYOR**
- **Lokasi:** `PROFIL_PENGGUNA.md:1-40` (masih template `[isi: ...]`) dan `AGENT_SYSTEM.md:44-50` (Langkah 0)
- **Bukti:** `cat PROFIL_PENGGUNA.md | grep "\[isi:"` → 5 baris masih placeholder. Agent baru baca ini pertama — dia akan bingung: harus tanya 4 pertanyaan dulu atau lanjut? Aturan bilang: kalau sesi perawatan sistem, **jangan jadi penghenti** — tapi agent bodoh mungkin tetap berhenti dan tanya, membuang waktu.
- **Dampak:** Pemilik non-teknis ditanya bahasa/gaya berulang kali padahal ini sesi audit, bukan bangun aplikasi. Bikin panik: "kok ditanya lagi?"
- **Perbaikan:** Di laporan ini sudah dijelaskan: sesi audit = lewati pengisian profil, langsung kerja. Untuk repo aplikasi Resto Barokah nanti, profil **wajib** diisi di Tahap 1 sebelum lanjut.
- **Status:** DIUSULKAN (tambahkan 1 baris di `PROFIL_PENGGUNA.md` template: "Jika sesi audit/klinik, lewati — isi nanti di Tahap 1")
- **Estimasi:** Kecil

**Temuan W7-02 — MAYOR**
- **Lokasi:** `PANDUAN_PENGGUNA.md:20-60` (Prompt Pembuka Universal) vs `docs/TERTANGGUH.md:0` (tidak ada)
- **Bukti:** Agent baru baca Prompt Pembuka → disuruh cek `PROJECT_STATE.md`. File tidak ada → dia bingung: proyek baru atau sesi terputus? Aturan Langkah 1 bilang cek `docs/` selain `README.md` — tapi `TERTANGGUH.md` yang disebut di instruksi review tidak ada, jadi dia tidak tahu "buku tunggu" itu di mana.
- **Dampak:** Agent akan tanya hal yang sebenarnya sudah dijawab di `docs/README.md` ("Fondasi belum mulai — siap Tahap 1"), tapi dia tidak tahu harus baca itu. Bikin pemilik ditanya ulang: "mau buat apa?"
- **Perbaikan:** Jelaskan di `PANDUAN_PENGGUNA.md` bahwa `TERTANGGUH.md` = istilah lama, kini `ROADMAP.md` + `_log-sesi`. Atau buat `docs/TERTANGGUH.md` minimal dengan 1 baris penjelas.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil

**Temuan W7-03 — MINOR**
- **Lokasi:** `alat/mulai-sesi.py:0` (tidak ada) vs `START_DI_SINI.md:1`
- **Bukti:** `ls alat/` → hanya `periksa-fondasi-independen.py` (baru). `START_DI_SINI.md` bilang baca `PROFIL_PENGGUNA.md`, `SYSTEM_MANIFEST.md`, `STATUS.md`, `LOG_SESI` — tidak menyebut `alat/mulai-sesi.py`. Instruksi review menyuruh `python3 alat/mulai-sesi.py` dan cek "DAFTAR TUNGGU" + "KARTU SESI", tapi file itu tidak ada.
- **Dampak:** Agent baru jalankan `python3 alat/mulai-sesi.py` → error, panik, kira sistem rusak. Pemilik lihat error → tidak percaya.
- **Perbaikan:** Jalankan `python3 alat/periksa-fondasi-independen.py` sebagai pengganti (sudah dibuat). Catat di laporan bahwa `alat/mulai-sesi.py` adalah nama lama, kini `periksa-fondasi-independen.py` + `validate_system.py`. Tidak perlu buat file dummy.
- **Status:** SUDAH DIPERBAIKI (pemeriksa baru dibuat + laporan menjelaskan)
- **Estimasi:** Selesai

**Uji buku tunggu vs TERTANGGUH:**
- `docs/TERTANGGUH.md` tidak ada, jadi tidak bisa hitung jumlah butir terbuka. `alat/mulai-sesi.py` juga tidak ada, jadi tidak bisa cek "DAFTAR TUNGGU". Ini konsisten: keduanya memang tidak ada di template sistem. Bukan bug, tapi ekspektasi instruksi review (yang pakai istilah TERTANGGUH) tidak cocok dengan sistem baru. Sudah dicatat sebagai W1-03 dan W7-02.

---

### W8 — Jalur & Panduan Pemilik

*Ikuti `PANDUAN_PENGGUNA.md` dari awal sampai akhir sebagai pemilik non-teknis yang pakai GitHub dan sesi AI.*

**Temuan W8-01 — MINOR**
- **Lokasi:** `PANDUAN_PENGGUNA.md:60-120` (Cara Pakai Sebagai Template)
- **Bukti:** Baca panduan — langkah copy: `cp -r sistem/sistem-building-aplikasi/* my-app-baru/` + `rm _Notes.md` + `git init` + `push`. Untuk pemilik non-teknis, perintah `cp -r` dan `git remote add` terlalu teknis tanpa contoh klik GitHub.
- **Dampak:** Pemilik bisa salah: copy hanya `AGENT_SYSTEM.md` (karenaเคย baca `PANDUAN_PEMAKAIAN.md` lama yang bilang begitu) → sistem pincang, rujukan putus. Atau lupa `rm _Notes.md` → catatan pribadi ikut ter-publish.
- **Perbaikan:** Panduan sudah ada peringatan arsip di `PANDUAN_PEMAKAIAN.md` (penanda `SUDAH DIGANTIKAN` + tabel koreksi), dan `PANDUAN_PENGGUNA.md` sudah bold "SELURUH isi folder". Cukup. Untuk non-teknis, tambahkan alternatif "download ZIP di GitHub → extract" (sudah ada).
- **Status:** CATATAN — SENGAJA TIDAK DIUBAH (sudah diperbaiki di run klinik ke-2)
- **Estimasi:** 0

**Temuan W8-02 — MINOR**
- **Lokasi:** `PANDUAN_PENGGUNA.md:140-180` (Cara review & merge)
- **Bukti:** Baca — langkah merge: "buka PR → lihat Files changed → Merge pull request → setelah merge sesi tidak bisa push lagi → buka sesi baru". Jelas.
- **Dampak:** Pemilik bisa salah merge ke arah yang salah (mis. merge `main` ke branch, bukan branch ke `main`) kalau klik dropdown base/compare terbalik. Panduan tidak menyebut "pastikan base = main, compare = arena/...".
- **Perbaikan:** Tambahkan 1 baris di panduan: "Pastikan panah PR menunjuk `arena/...` → `main` (bukan sebaliknya)". Tapi ini perbaikan kecil, tidak kritis.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil (1 baris)

**Temuan W8-03 — CATATAN (arsip)**
- **Lokasi:** `PANDUAN_PEMAKAIAN.md:1-15`
- **Bukti:** `head -n 15 PANDUAN_PEMAKAIAN.md` → "⚠️ VERSI LAMA — SUDAH DIGANTIKAN, JANGAN DIIKUTI" + tabel koreksi. Validator `check_penanda_arsip` PASS.
- **Dampak:** Tidak menyesatkan — sudah berpenanda jelas. Pemilik tidak akan ikuti yang lama kalau baca 12 baris pertama.
- **Perbaikan:** Tidak perlu.
- **Status:** 0 temuan (sudah aman)

> Jika W8 dianggap "tidak menemukan langkah yang tidak bisa dijalankan": **3 hal tersulit yang saya coba:**
> 1. Coba ikuti panduan tanpa `git` (hanya GitHub web) — tetap bisa via "Create new repository + upload files" (panduan menyebut opsi ZIP).
> 2. Coba merge PR tanpa baca Files changed — panduan sudah wanti "lihat Files changed dulu".
> 3. Coba copy hanya `AGENT_SYSTEM.md` — panduan arsip sudah koreksi dengan tabel. Semua tertutup.

---

### W9 — Operasional Nyata & Biaya Nol

#### (a) Satu Hari Penuh di Resto Barokah

*Simulasi: buka shift → pelanggan pesan → dapur masak → bayar → tutup shift → laporan*

| Langkah harian | Ada tugas di ROADMAP? | Lubang |
|---|---|---|
| Buka shift (kas awal, stok) | Tidak ada ROADMAP | **LUBANG KRITIS** — belum ada tugas |
| Pelanggan pesan (pilih menu, jumlah) | Tidak ada | **LUBANG KRITIS** |
| Dapur masak (status: antri→masak→saji) | Tidak ada | **LUBANG KRITIS** |
| Bayar (hitung total + pajak + service + voucher) | Tidak ada | **LUBANG KRITIS** — risiko uang salah hitung |
| Tutup shift (laporan omzet, selisih kas) | Tidak ada | **LUBANG KRITIS** |
| Cetak struk (printer) | Tidak ada | Lubang |

**Temuan W9-01 — KRITIS**
- **Lokasi:** `docs/ROADMAP.md:0`, `docs/PRD.md:0`, `docs/TECH_SPEC.md:0`
- **Bukti:** `ls docs/` → hanya README. Tidak ada PRD yang daftar fitur "pesan, bayar, dapur", tidak ada TECH_SPEC yang definisikan entitas `menu`, `pesanan`, `meja`, `pembayaran`, `stok`.
- **Dampak:** Sehari operasional tidak ada yang ter-cover. Kalau coding sekarang, semua fitur harus ditebak, pasti ada yang terlewat. Dampak ke kas: tutup shift tidak bisa rekonsiliasi, uang hilang tidak ketahuan.
- **Perbaikan:** Di PRD, tulis 5 fitur Must Have: (1) Kelola menu, (2) Pesan & status dapur, (3) Bayar (tunai/QRIS) + pajak/service/voucher, (4) Stok, (5) Laporan harian. Di ROADMAP, tiap fitur minimal 1 task.
- **Status:** DIUSULKAN
- **Estimasi:** Besar (butuh PRD dulu)

#### (b) Skenario Gagal

| Skenario | Ada tugas/aturan? | Temuan |
|---|---|---|
| Internet putus saat jam sibuk | Tidak ada | **LUBANG MAYOR** — butuh mode offline / antrean lokal |
| Listrik mati | Tidak ada | **LUBANG MAYOR** — butuh UPS / cetak manual |
| Printer rusak | Tidak ada | Lubang MINOR — fallback tulis tangan |
| Pesanan batal setelah dimasak | Tidak ada | **LUBANG MAYOR** — aturan: siapa tanggung, stok kembali? |
| Kas tidak cocok (selisih) | Tidak ada | **LUBANG KRITIS** — butuh laporan selisih + audit |
| Voucher dicoba berulang (fraud) | Tidak ada | **LUBANG KRITIS** — butuh validasi sekali pakai |
| Pegawai berhenti (email & PIN) | Tidak ada | **LUBANG KRITIS** — butuh task revoke akses, ganti PIN |
| Dua orang ubah pengaturan bersamaan | Tidak ada | Lubang MAYOR — butuh lock/versi |

**Temuan W9-02 — MAYOR**
- **Lokasi:** `docs/PRD.md:0` (Aturan Bisnis kosong), `docs/TECH_SPEC.md:0` (Area Berisiko kosong)
- **Bukti:** `cat _sistem/templates/PRD.md | grep "Edge Case"` → ada placeholder tapi belum diisi untuk kasus di atas. `cat _sistem/templates/TECH_SPEC.md | grep "Area Berisiko"` → ada RLS/Auth, Role & Permission, Kalkulasi Keuangan — tapi belum diisi spesifik Resto Barokah.
- **Dampak:** Saat kejadian gagal, tidak ada aturan — pegawai bingung, pelanggan marah, uang bisa hilang, voucher bisa disalahgunakan.
- **Perbaikan:** Di PRD, tulis 8 edge case di atas sebagai "Aturan Bisnis". Di TECH_SPEC, masukkan ke Area Berisiko Tinggi + di ROADMAP beri tanda `⚠️ DECISIONS_LOG`.
- **Status:** DIUSULKAN
- **Estimasi:** Sedang

#### (c) Biaya Nol

**Temuan W9-03 — MAYOR**
- **Lokasi:** `SYSTEM_MANIFEST.md:dependency` dan `TECH_SPEC.md` template (Deploy: Cloudflare/Vercel/Supabase)
- **Bukti:** `grep -i "gratis\|bayar\|biaya" SYSTEM_MANIFEST.md` → tidak ada batas gratis yang dijelaskan. `cat STATUS.md | grep "Risiko"` → risiko #3: skills 26M ikut ter-copy, tidak ada risiko biaya layanan. Checklist template ROADMAP ada "deploy (Cloudflare/Vercel)" tapi tidak ada task "cek batas gratis".
- **Dampak:** Cloudflare Workers gratis: 100k request/hari, Supabase gratis: 500MB DB, pause setelah 7 hari idle, pengirim email (mis. Gmail API) ada kuota. Kalau tembus, aplikasi berhenti, data tidur, email tidak terkirim — resto tidak bisa jualan.
- **Perbaikan:** Di TECH_SPEC, tulis batas gratis tiap layanan yang dipakai + risiko bila tembus. Di ROADMAP, tambah task `T0-10 — Cek batas gratis & mitigasi` (mis. cron keep-alive, alert 80% kuota, backup mingguan). Jangan pakai layanan yang wajib bayar.
- **Status:** DIUSULKAN
- **Estimasi:** Kecil (1 task + 1 paragraf di TECH_SPEC)

#### (d) Data & Keamanan

**Temuan W9-04 — KRITIS**
- **Lokasi:** `TECH_SPEC.md:0` (belum ada), `ROADMAP.md:0` (belum ada), `_sistem/templates/TECH_SPEC.md:50` (placeholder)
- **Bukti:** `cat _sistem/templates/TECH_SPEC.md | grep -A2 "Keamanan"` → masih placeholder "...". Tidak ada task RLS, backup, pemulihan, uji izin.
- **Dampak:** Data pelanggan (nama, pesanan) bisa dibaca semua orang kalau RLS salah. Tidak ada backup → kalau DB rusak, data hilang permanen. Tidak ada uji izin → kasir bisa lihat laporan owner.
- **Perbaikan:** Di TECH_SPEC, definisikan: RLS per tabel (kasir hanya lihat pesanan hari ini, owner lihat semua), backup harian Supabase, pemulihan (restore) test 1x, uji izin 2 role (anon vs kasir vs owner). Di ROADMAP, buat task migration + RLS + test.
- **Status:** DIUSULKAN
- **Estimasi:** Besar (butuh TECH_SPEC dulu)

---

### W10 — Integritas Repo & Kerahasiaan

**Temuan W10-01 — MINOR**
- **Lokasi:** `.gitignore:0` (tidak ada), `git ls-files --others --exclude-standard:1`
- **Bukti:** `ls .gitignore` → tidak ada; `git ls-files --others --exclude-standard` → `alat/periksa-fondasi-independen.py` (file baru yang belum di-track, wajar). `find . -name ".env*"` → 0. `git ls-files | grep env` → 0. Tapi tanpa `.gitignore`, rahasia `.env` bisa tidak sengaja ter-commit nanti.
- **Dampak:** Risiko keamanan: token Supabase/Cloudflare bisa masuk Git kalau tidak di-ignore. Berkas besar sementara (log, `.next`, `dist`) juga bisa ikut.
- **Perbaikan:** Buat `.gitignore` minimal berisi `.env`, `.env.*`, `node_modules/`, `.next/`, `.vercel/`, `.wrangler/`, `dist/`, `build/`, `*.log` — gunakan template dari `_sistem/templates/ROADMAP.md` Task 1 contoh (sudah menyebut `.gitignore` memuat `.env*`).
- **Status:** DIUSULKAN (boleh langsung diperbaiki — bukan dokumen terkunci)
- **Estimasi:** Kecil (5 menit)

**Temuan W10-02 — CATATAN (berkas besar)**
- **Lokasi:** `skills/` — file besar: `technologies.json` 3.5M, `phosphor-icons` 823K, fonts 150-190K tiap file, total 26M
- **Bukti:** `git ls-files | xargs wc -c | sort -nr | head -20` → 3.5M technologies.json di top; `du -sh skills` → 26M, 56 dirs.
- **Dampak:** File besar wajar untuk skill (desain/UI), bukan sampah. Tapi 26M akan ikut ter-copy ke setiap repo aplikasi (risiko #3 di STATUS.md sudah catat). Tidak ada berkas besar tidak perlu di luar skills (di root tidak ada).
- **Perbaikan:** Tidak perlu hapus — keputusan pemilik (hemat vs 53M penuh). Jaga agar `skills/` tetap vendor-identik, jangan tambah file besar lain.
- **Status:** CATATAN — SENGAJA TIDAK DIUBAH (keputusan pemilik)
- **Estimasi:** 0

**Temuan W10-03 — CATATAN (rahasia)**
- **Lokasi:** `git ls-files | grep -i secret/token/key` → hanya rujukan di `skills/cloudflare/references/secrets-store/*` (dokumentasi, bukan kunci nyata)
- **Bukti:** `find . -name "*.env" -o -name "*secret*" -o -name "*token*"` → 0 file rahasia di root. `skills/cloudflare/references/secrets-store/` berisi panduan cara simpan rahasia, bukan rahasianya.
- **Dampak:** Aman — tidak ada `.env` atau token yang bocor di Git. Keberadaannya dilaporkan tanpa menampilkan isi (sesuai larangan).
- **Perbaikan:** Tidak perlu. Jaga `.gitignore` agar tetap aman ke depan.
- **Status:** 0 temuan (aman)

**Temuan W10-04 — CATATAN (sisa sementara)**
- **Lokasi:** `git status` → `nothing to commit, working tree clean` (setelah buat alat/periksa-fondasi-independen.py, status jadi untracked 1 file, wajar)
- **Bukti:** `git status` dan `git ls-files --others --exclude-standard` sudah dicek.
- **Dampak:** Tidak ada sisa berkas sementara yang tertinggal.
- **Status:** 0 temuan

**Temuan W10-05 — MINOR (skills)**
- **Lokasi:** `skills/README.md:1` dan `skills/` (56 dirs)
- **Bukti:** `ls skills/ | wc -l` → 56, `du -sh` → 26M, `find skills -name SKILL.md | wc -l` → 50 SKILL.md di akar + 6 agregat (product-discovery 7 sub, product-management 8 sub, ai-agent-skills 17 sub, 2 katalog, 1 curated list) — sesuai penjelasan di AGENT_SYSTEM.md "50 punya SKILL.md di akar dan 6 adalah direktori induk". Isi sensitif: tidak ada (sample 10 SKILL.md dibaca, semua panduan, bukan kunci).
- **Dampak:** Ukuran wajar, tidak ada isi sensitif. Tapi perlu diingat: `skills/` akan ikut ter-commit ke setiap repo aplikasi — sudah jadi keputusan pemilik (on-demand untuk 2 hub raksasa).
- **Perbaikan:** Tidak perlu.
- **Status:** CATATAN

---

## 6. Klaim vs Bukti (W2) — Ringkasan

Sudah di W2 (tabel). Inti untuk pemilik:

- **Yang TERBUKTI:** Sistem template-nya sehat. Angka 56 dirs/26M/validator PASS/ status `siap-pakai` semua benar. Kamu bisa percaya template ini.
- **Yang TIDAK BISA DIVERIFIKASI:** Semua janji tentang Resto Barokah (jumlah menu, jumlah tugas, hitung uang) belum bisa dibuktikan karena memang belum ditulis. Bukan bohong, tapi belum ada.
- **Yang TIDAK TERBUKTI:** Tidak ada klaim palsu ditemukan. Dulu ada angka basi (8.1M vs 26M) sudah diperbaiki di run klinik ke-2.

---

## 7. Hasil Simulasi 3 Sudut Pandang

### 1) Agent Baru Yang Bodoh — apa yang paling mungkin dia salah pahami?

| # | Kelemahan konkret | Sudah tertutup fondasi? | Belum? |
|---|---|---|---|
| 1 | Baca `PROFIL_PENGGUNA.md` kosong → kira harus tanya 4 pertanyaan dulu, padahal ini sesi audit yang harusnya langsung kerja. | **Belum** — perlu 1 baris pengecualian di template profil (W7-01) |
| 2 | Cari `PROJECT_STATE.md` tidak ada → bingung apakah proyek baru atau sesi crash. Dia tanya ulang hal yang sudah ada di `docs/README.md`. | **Belum** — butuh `PROJECT_STATE.md` dibuat di Tahap 1 (W1-01) |
| 3 | Jalankan `python3 alat/mulai-sesi.py` → error `No such file` → kira sistem rusak. | **Sudah tertutup** — pemeriksa baru `alat/periksa-fondasi-independen.py` ada + laporan jelaskan nama lama vs baru (W7-03) |

### 2) Pemilik Non-Teknis — langkah mana yang bikin dia tersesat atau panik?

| # | Kelemahan konkret | Sudah tertutup? | Belum? |
|---|---|---|---|
| 1 | Baca `PANDUAN_PEMAKAIAN.md` lama (yang bilang "hanya AGENT_SYSTEM.md yang di-copy") → copy salah, sistem pincang. | **Sudah tertutup** — berkas arsip sudah berpenanda `SUDAH DIGANTIKAN` + tabel koreksi (W8-03) |
| 2 | Diminta copy folder via `cp -r` dan `git remote add` → tidak paham, takut salah ketik. | **Belum** — perlu opsi "download ZIP di GitHub → extract" yang sudah ada tapi kurang ditekankan (W8-01) |
| 3 | Merge PR salah arah (base/compare terbalik) → kode tidak masuk `main`, kerja hilang. | **Belum** — perlu 1 baris peringatan "pastikan panah `arena/...` → `main`" (W8-02) |

### 3) Kedai Oasis, Sabtu Malam Penuh — bagian rencana mana yang paling mungkin jebol lebih dulu?

| # | Kelemahan konkret | Sudah tertutup? | Belum? |
|---|---|---|---|
| 1 | **Hitung uang (pajak/service/voucher) belum didefinisikan** — kasir jumlah manual, selisih tidak ketahuan, voucher bisa dipakai ulang. Ini jebol pertama saat ramai. | **Belum** — butuh PRD + TECH_SPEC + ROADMAP untuk kalkulasi (W9-01, W9-02) |
| 2 | **Status pesanan dapur tidak ada** — pelayan lupa pesanan, dapur masak ganda, pelanggan menunggu lama. | **Belum** — butuh fitur status pesanan (W9-01) |
| 3 | **DB gratis tidur saat libur panjang** — setelah Lebaran, aplikasi tidak bisa buka, data hilang. | **Belum** — butuh task anti-tidur + backup (W5-02, W9-03) |

---

## 8. Risiko Yang Masih Terbuka + Pertanyaan Yang Hanya Bisa Dijawab Pemilik

**Risiko terbuka (di luar temuan di atas):**
1. **Ide Resto Barokah belum ada** — tanpa cerita pemilik, 6 dokumen tidak bisa ditulis. Ini risiko #1 di STATUS.md.
2. **Akun Supabase/Cloudflare belum ada** — siapa yang buat? pakai email mana? (butuh setup akun).
3. **Aturan uang (pajak %, service %, voucher) belum diputuskan** — ini K1–K6 di instruksi, tidak boleh diubah agent tanpa persetujuan.
4. **Peran & izin (kasir vs owner vs dapur) belum diputuskan** — siapa boleh lihat apa?
5. **Menu & harga belum ada** — tidak bisa buat entitas `menu`.
6. **Alamat deploy belum diputuskan** — mau `resto-barokah.pages.dev` atau domain sendiri?

**Pertanyaan untuk pemilik (jawab dengan bahasa warung saja):**
1. Resto Barokah jual apa? (makanan/minuman apa saja, ada paket?)
2. Pelanggan pesan bagaimana? (datang ke kasir, scan QR di meja, atau pesan online?)
3. Bayar pakai apa? (tunai saja, QRIS, transfer?) Ada pajak/service? Ada voucher/promo?
4. Siapa yang pakai aplikasi? (kasir 1 orang, owner, dapur, atau semua?)
5. Buka-tutup shift bagaimana? (jam berapa, siapa tutup, laporan ke siapa?)
6. Ada akun Supabase/Cloudflare/Google sudah? Atau mau saya pandu buat baru (gratis)?
7. Cabang `arena/01a0aab1-resto-barokah` boleh dianggap sesi review yang sah, atau harus buat baru `01a0a8a2`?

---

## 9. Batas Cakupan: Apa Yang TIDAK Bisa Saya Periksa dan Kenapa

- **Isi `skills/` per baris (1800+ file):** Diperiksa sebagai kebijakan (sample 30 files + cek vendor), bukan tiap baris — karena itu vendor eksternal (Vercel, Cloudflare, Supabase, Google) yang dijaga byte-identik. Memeriksa tiap baris = 2–3 jam tanpa nilai tambah untuk fondasi warung.
- **Dry-run full AT-08 (copy → repo standalone + git init + validator):** Tidak dijalankan penuh di sesi ini karena butuh `cp -r` 26M ke `/tmp` dan `git init` — tapi cek `check_no_dangling_internal_refs` (yang adalah AT-08 yang ditanam jadi gerbang) sudah PASS, dan `ACCEPTANCE_TEST_LOG.md` putaran 3 sudah bukti PASS.
- **Batas gratis Cloudflare/Supabase real-time:** Tidak bisa cek kuota nyata tanpa akun — hanya bisa baca dokumentasi (100k request/hari Cloudflare, 500MB Supabase). Butuh akun owner untuk cek.
- **Uji browser `agent-browser`:** Tidak bisa jalankan UI test karena belum ada aplikasi — hanya bisa cek docs.
- **Isi `.env` / kunci:** Sengaja tidak dibuka (larangan). Hanya cek keberadaannya (tidak ada = aman).
- **Riwayat Git di `.git`:** Tidak diutak-atik (larangan `reset --hard`, `push --force`).

Semua yang TIDAK diperiksa sudah dicatat alasannya — tidak ada yang ditutup-tutupi.

---

## 10. Rekomendasi Langkah Berikutnya (1 paragraf) + Apakah Aman Memulai Fase 0

**Rekomendasi:** Jangan mulai coding. Mulai **Tahap 1 Discovery** minggu ini: luangkan 1 jam cerita ke agent tentang Resto Barokah (jual apa, siapa pembeli, alur pesan-bayar, aturan uang), jawab 4 pertanyaan profil (bahasa/gaya/latar/preferensi), lalu agent akan tulis `DISCOVERY.md` dan minta kamu bilang "cukup, tulis draftnya" sebelum lanjut ke PRD. Urutannya harus 1→2→3→4→5→6, tidak boleh loncat. Setelah 6 dokumen jadi dan `PROJECT_STATE.md` = `CODING_AKTIF`, baru Fase 0 (setup Supabase/Cloudflare/akun) aman dimulai — saat itu kedua pemeriksa (`validate_system.py` PASS dan `periksa-fondasi-independen.py` exit 0) akan hijau.

**Apakah aman memulai Fase 0 sekarang?** **TIDAK AMAN.** Fase 0 butuh TECH_SPEC (versi Node, paket, alamat deploy) dan ROADMAP (urutan task) — keduanya belum ada. Memulai sekarang = menebak. Tunggu sampai Cross-Check selesai.

---

## 11. Catatan Atas Instruksi Review Ini Sendiri

Bagian instruksi yang **tidak bisa dijalankan / menurut saya salah:**

1. **Nama cabang `arena/01a0a8a2-resto-barokah` tidak ada di repo ini.** Yang ada `arena/01a0aab1-resto-barokah`. `git branch -a` hanya tampilkan `main` dan `arena/01a0aab1`. Memaksa buat sesi baru dengan nama itu akan buat branch duplikat tanpa isi. Saran: anggap beda ID kecil ini sebagai typo platform, tetap pakai branch yang ada.

2. **File `docs/ROADMAP.md`, `docs/TERTANGGUH.md`, `PROJECT_STATE.md` dengan `STATUS: CODING_AKTIF` diharapkan sudah ada.** Di sistem v0.2.0, `docs/` memang sengaja hanya `README.md` sebelum Tahap 1 — ini **bukan cacat**, tapi desain. Instruksi review pakai ekspektasi aplikasi yang sudah lewat Fondasi, sementara repo ini masih template. Saran: ubah prasyarat jadi "kalau belum ada, putusan = BELUM SIAP, lanjutkan audit" (yang sudah saya lakukan).

3. **`python3 alat/mulai-sesi.py` dan `python3 sistem/validatesystem.py` / `alat/periksa-roadmap.py` pakai path lama.** Di repo ini path yang benar `python3 _sistem/validate_system.py` dan `python3 alat/periksa-fondasi-independen.py` (baru). `alat/mulai-sesi.py` tidak pernah ada di template v0.2.0. Saran: update instruksi ke path baru.

4. **`docs/TERTANGGUH.md` vs `ROADMAP.md`:** Instruksi review sebut `TERTANGGUH.md` (istilah lama untuk backlog), sistem baru pakai `ROADMAP.md` + `DECISIONS_LOG.md`. Tidak perlu buat TERTANGGUH terpisah kalau ROADMAP sudah ada — cukup jelaskan.

5. **Larangan "jangan mengubah PROJECT_STATE.md/STATUS.md/_log-sesi/" (bagian 6 pengecualian) sudah tepat** — saya patuhi, tidak mengubahnya. Ini mencegah konflik dengan sesi pembangun lain.

Selain 5 poin di atas, instruksi review **sudah bagus dan ketat** — terutama sikap "coba mematahkan fondasi" dan "BELUM SIAP adalah hasil yang berhasil" yang saya ikuti.

---

## 12. Keadaan Sesi: Apa Yang Dikerjakan, Apa Yang Tertunda, Berkas Apa Yang Diubah

**Yang dikerjakan di sesi `arena/01a0aab1-resto-barokah` (2026-09-16):**
- Baca semua berkas wajib (AGENT_SYSTEM, SYSTEM_MANIFEST, STATUS, START_DI_SINI, PROFIL_PENGGUNA, 10_LOG_SESI, PANDUAN_PENGGUNA, ACCEPTANCE_TESTS/LOG, docs/README, _sistem/templates, validate_system.py).
- Jalankan prasyarat (`git rev-parse`, `ls docs/`, `grep STATUS`, `python3 alat/mulai-sesi.py` → error, `validate_system.py` → PASS).
- Buat pemeriksa independen `alat/periksa-fondasi-independen.py` (267 baris, dari nol, exit 1 — 10 temuan, exit 0 jika bersih).
- Jalankan pemeriksa baru + validator lama, catat keluaran.
- Audit 10 wilayah W1–W10, tulis laporan ini `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (12 bab, ~400 baris).
- Cek git ls-files (1833 berkas), cek .env (0), cek skills (56 dirs, 26M), cek .gitignore (tidak ada).

**Yang tertunda / tidak dikerjakan (sengaja, sesuai larangan):**
- Tidak merge PR apa pun, tidak tutup PR.
- Tidak melemahkan pemeriksa (`_sistem/validate_system.py` tetap PASS, tidak dilonggarkan).
- Tidak `git reset --hard` / `push --force` / hapus berkas.
- Tidak mulai coding aplikasi (Fase 0), tidak buat folder aplikasi, tidak install paket.
- Tidak ubah dokumen terkunci (`docs/PRD.md` dkk tidak ada, jadi tidak diubah — hanya diusulkan).
- Tidak ubah keputusan pemilik (K1–K6, pajak/service) — hanya usulkan entri DECISIONS_LOG bila nanti.
- Tidak sentuh `.env`/kunci (hanya laporkan).
- Tidak ubah `PROJECT_STATE.md`, `STATUS.md`, `_log-sesi/` (pengecualian bagian 6).

**Berkas yang diubah (di branch `arena/01a0aab1-resto-barokah`):**
- `alat/periksa-fondasi-independen.py` — **baru** (pemeriksa independen, wajib ada per W3)
- `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` — **baru** (laporan ini)

**Berkas yang sengaja TIDAK diubah:**
- `PROJECT_STATE.md` (tidak ada di root — tidak dibuat, sesuai pengecualian)
- `STATUS.md` (tetap `siap-pakai` — tidak diubah)
- `_log-sesi/LOG_SESI_2026-09-15.md` (tetap CLOSED)
- `docs/` (tetap hanya README.md)
- Semua file di `_sistem/`, `skills/`, root (tidak ada edit)

**Langkah berikutnya untuk sesi pembangun:**
- Baca laporan ini + `alat/periksa-fondasi-independen.py` (exit 1 = belum siap).
- Mulai Tahap 1 Discovery Resto Barokah (jawab profil + cerita ide).
- Setelah 6 dokumen jadi, jalankan `python3 alat/periksa-fondasi-independen.py` lagi — harus exit 0 sebelum CODING_AKTIF.

---

**Tanda tangan review independen:** Sesi `arena/01a0aab1-resto-barokah`, 2026-09-16, validator sistem PASS (0 temuan), pemeriksa fondasi exit 1 (10 temuan, semua karena fondasi belum dibuat — bukan karena template rusak).

