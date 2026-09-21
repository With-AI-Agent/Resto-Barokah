# LAPORAN TUGAS MARATON T-03 — DRAF kontrak privasi pelanggan

- **Tugas:** T-03 (papan `docs/ops/PAPAN_TUGAS.md`, alur AL-16, gelombang 2 — 2026-09-21)
- **Pekerja:** pekerja-3
- **Cabang sesi (dilaporkan untuk papan):** `arena/01a0c1d7-resto-barokah`
  (dibuka dari `main` commit `253d129`, lalu dikejar fast-forward ke ujung cabang
  integrator `origin/kerja-terakhir` = `c25d2dc` — `git merge --ff-only` sukses,
  `ANCESTOR-OK` diverifikasi sebelum merge). Riwayat cabang: basis `c25d2dc`, di atasnya
  dua cabang kembar — `d4c0e2d` (kerja T-02, ter-push sesi pekerja-2 ke remote) dan
  `61e739b` (kerja T-03, commitku) — disatukan merge `b7fa385` (keduanya jadi induk
  merge; rincian di §3), lalu commit laporan pembaruan ini di atasnya.
- **Tanggal:** 2026-09-21
- **Status: SELESAI** — artifact + laporan di-push ke cabang sesi ini

---

## 1. Yang dikerjakan

1. **Orientasi (PRO.md, MODE PEKERJA):** cek keadaan (mulai dari `main` yang belum memuat
   papan) → `git fetch origin arena/01a0c1d1-resto-barokah:refs/remotes/origin/kerja-terakhir`
   + `git merge --ff-only` → baca `PRO.md` (MODE PEKERJA MARATON), alur **AL-16** di
   `PANDUAN_PENGGUNA.md`, baris T-03 di papan, lalu bahan sumber: `docs/PRD.md`,
   `docs/DISCOVERY.md`, `docs/TECH_SPEC.md` (§4.4, ART-10, ART-14, §12), `docs/KEAMANAN.md`
   §1/§2/§11, `docs/DECISIONS_LOG.md` (2026-09-16 & 2026-09-17), `docs/TERTANGGUH.md`
   (T-011, T-012, T-014), `docs/ROADMAP.md` (Fase 8: T8-01…T8-15), `docs/uji/AUDIT_RIWAYAT.md`
   §1c (F F-09), `docs/teknis/BUKU_INSIDEN.md` §6, `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md`
   §B8, `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (L6), dan skema `supabase/migrations/`
   (0001–0019).
2. **Artifact utama: `docs/PRIVASI_PELANGGAN.md` (BARU, status DRAF)** — kontrak privasi
   pelanggan dalam bahasa Indonesia sederhana untuk Lee, memuat persis isi DoD:
   - §0 keadaan jujur: fitur pelanggan belum dibangun, **belum ada data pelanggan tersimpan**
     (tidak ada tabel pelanggan di migrasi 0001–0019); cakupan dokumen dibatasi data pelanggan
     (data pegawai/usaha di luar);
   - §1 data apa yang dikumpulkan/diproses (skema rencana `pelanggan`/`voucher`/`voucher_percobaan`
     dari `TECH_SPEC.md` §4.4; jalur pendaftaran PRD M10; verifikasi Google utama + email
     kedua dari DISCOVERY; yang TIDAK disimpan: tanpa NIK/lokasi/biometrik/pelacakan);
   - §2 dasar & tujuan (UU PDP + persetujuan eksplisit; tujuan sempit = voucher & pemulihan;
     transfer ke Singapore);
   - §3 masa simpan (catatan keuangan tak dihapus permanen — Aturan Bisnis 11; cadangan 90
     hari; masa simpan data pribadi = TODO);
   - §4 hak pelanggan akses/koreksi/penghapusan (akses + hapus-anonimisasi sudah didesain,
     tanggap 3×24 jam; koreksi = TODO; kanal permintaan = TODO);
   - §5 anonimisasi/pseudonimisasi (anonimisasi sudah dirancang di T8-15; pseudonimisasi =
     TODO);
   - §6 kebocoran (notifikasi tertulis ≤3×24 jam, template BUKU_INSIDEN §6);
   - §7 jalur implementasi per fase (Fase 1B sudah mendarat → gerbang tinjauan Lee (T-011) →
     Fase 8 T8-01…T8-15 → audit L6 setelahnya) + catatan jujur soal nomor migrasi T8-15;
   - §8 ringkasan 6 bagian `TODO(keputusan Lee)`; §9 daftar sumber per bagian.
   Setiap bagian berbaris **Sumber** dengan rujukan berkas repo; tidak ada mekanisme yang
   dikarang; yang belum diputuskan ditandai `TODO(keputusan Lee)` — tidak ada keputusan
   diambil pekerja.
3. **Laporan ini** (`docs/ops/maraton/LAPORAN-T-03.md`).

## 2. Bukti (perintah + hasil)

| # | Perintah | Hasil |
|---|---|---|
| 1 | `git fetch origin arena/01a0c1d1-resto-barokah:refs/remotes/origin/kerja-terakhir` | `c25d2dc` (AL-16 gelombang 2) terambil |
| 2 | `git merge --ff-only origin/kerja-terakhir` | `Updating 253d129..c25d2dc` — fast-forward bersih |
| 3 | `python3 alat/periksa-rujukan.py` | **LOLOS** — semua rujukan di dokumen pengikat hidup |
| 4 | `python3 alat/periksa-rahasia.py` | **LOLOS** — tidak ada kunci rahasia di berkas terlacak |
| 5 | `python3 alat/periksa-maraton.py` | **LOLOS** — papan tugas maraton sehat (papan tidak kusentuh) |
| 6 | `python3 alat/periksa-panduan.py` | **LOLOS** — buku induk lengkap, rujukan hidup |
| 7 | `python3 alat/periksa-angka-bukti.py` | **LOLOS** — semua angka di klaim Bukti bisa direproduksi |
| 8 | `node alat/uji-sql.mjs` (suite penuh) | **uji: 60 LULUS · 0 GAGAL — HASIL: LOLOS** (harness butuh `npm ci` di `alat/` — lokal saja, `node_modules` diabaikan Git; `git status --short` hanya menunjukkan berkas baru) |
| 9 | `python3 alat/periksa-bersih.py` | **LOLOS** — semua pemeriksa dokumen hijau di pohon bersih |

Catatan: perintah #3–#7, #9 dijalankan **setelah** `docs/PRIVASI_PELANGGAN.md` ada di
working tree, sehingga hasil itu mencakup artifact-nya.

### Bukti tambahan — kejadian cabang bersama (lihat §3 butir 1)

| # | Perintah | Hasil |
|---|---|---|
| 10 | `git push origin HEAD:refs/heads/arena/01a0c1d7-resto-barokah` (push pertama) | **ditolak** (non-fast-forward) — remote cabang itu sudah memuat commit `d4c0e2d` milik **sesi pekerja-2** (berkas T-02), karena sesi pekerja-2 memakai nama cabang yang SAMA dengan sesiku |
| 11 | `git merge FETCH_HEAD` (merge commit `d4c0e2d` ke cabangku, **bukan** force-push — kerja pekerja-2 harus tetap hidup) | merge bersih, tanpa konflik (empat berkas berbeda) |
| 12 | `git push origin HEAD:refs/heads/arena/01a0c1d7-resto-barokah` (ulang) | sukses — `d4c0e2d..b7fa385` |
| 13 | `node alat/uji-sql.mjs` (ulang, setelah merge) | **uji: 60 LULUS · 1 GAGAL** — GAGAL-nya = `supabase/tes/perangkat_registrasi_tepi.sql`, yaitu **reproduksi sengaja GAGAL** milik pekerja-2 yang membuktikan hambatan DoD(d) T-02 (laporan mereka: status **MACET**). Bukan akibat kerja T-03 (T-03 tidak menyentuh SQL). |

### Daftar sumber per bagian (bukti DoD T-03)

| Bagian `docs/PRIVASI_PELANGGAN.md` | Sumber di repo |
|---|---|
| §0 keadaan jujur | `supabase/migrations/` 0001–0019 (tak ada tabel pelanggan — diverifikasi `grep -n "^create table" supabase/migrations/*.sql`) · `docs/TECH_SPEC.md` §4.4 · `docs/ROADMAP.md` Fase 8 · `docs/uji/AUDIT_RIWAYAT.md` §1c (F F-09, TERBUKA → T8-01) · `docs/TERTANGGUH.md` T-011 |
| §1 data dikumpulkan/diproses | `docs/TECH_SPEC.md` §4.4 (kolom `pelanggan`/`voucher`/`voucher_percobaan`), ART-10, ART-14, §12 (Singapore) · `docs/PRD.md` M10 (alur pendaftaran, kasus tepi kasir) + §8 Aturan Bisnis 3 (HP opsional) · `docs/DISCOVERY.md` butir 98 & keputusan 12 (Google utama, email kedua, tanpa SMS) · `docs/KEAMANAN.md` §11 (tanpa NIK/lokasi/biometrik/pelacakan) · `docs/DECISIONS_LOG.md` 2026-09-17 |
| §2 dasar & tujuan | `docs/KEAMANAN.md` §11 (persetujuan eksplisit) · `docs/DECISIONS_LOG.md` 2026-09-17 (isi kalimat persetujuan: apa/untuk apa/berapa lama/cara hapus) · `docs/PRD.md` §9 risiko #10 (UU PDP, denda 2% + pidana) + §10.7 + M10 kasus tepi (pemulihan PIN via email) · `docs/TECH_SPEC.md` ART-10 + §12 · `docs/TERTANGGUH.md` T-014 (dasar transfer = persetujuan + pengamanan penyedia) |
| §3 masa simpan | `docs/PRD.md` §8 Aturan Bisnis 11 (tak ada penghapusan permanen) · `docs/TECH_SPEC.md` §4.3 (pola hanya-tambah) · `docs/DECISIONS_LOG.md` 2026-09-16 + `docs/TERTANGGUH.md` T-012 (cadangan terenkripsi, masa simpan 90 hari) · verbatim "belum ada data siapa pun": `docs/TERTANGGUH.md` T-011 |
| §4 hak pelanggan | `docs/KEAMANAN.md` §11 ("akses & hapus", "Tanggap 3×24 jam") · `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` §B8 ("minta salinan/hapus") · `docs/TECH_SPEC.md` ART-14 · `docs/PRD.md` §8 Aturan Bisnis 18 · koreksi/kanal: tidak ditemukan di mana pun (verifikasi `grep -rn -i "koreksi data\|ubah data pelanggan\|perbaiki data" docs/` = 0 hasil) → TODO |
| §5 anonimisasi/pseudonimisasi | `docs/ROADMAP.md` T8-15 (DoD: kolom persetujuan + versi kebijakan; fungsi anonimisasi; uji) · `docs/TECH_SPEC.md` ART-14 (uji wajib) · `docs/KEAMANAN.md` §1 butir 6, §2, §11 · `docs/PRD.md` §8 Aturan Bisnis 9 (isolasi) · pseudonimisasi: tidak ada di repo (verifikasi `grep -rn -i "pseudonim" docs/` = 0 hasil) → TODO |
| §6 kebocoran | `docs/KEAMANAN.md` §11 (≤3×24 jam, Pasal 46) · `docs/DECISIONS_LOG.md` 2026-09-17 · `docs/TECH_SPEC.md` ART-14 · `docs/teknis/BUKU_INSIDEN.md` §6 (template) |
| §7 jalur per fase | `docs/ROADMAP.md` Fase 8 (T8-01…T8-15, semua `[ ]`) + catatan T8-07 (pagar T-011) · `docs/TERTANGGUH.md` T-011 ("sebelum F8 — draf ditinjau pemilik") · `docs/ops/PAPAN_TUGAS.md` (cadangan 0020) · `docs/uji/AUDIT_RIWAYAT.md` §1c · `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` L6 |

## 3. Keterbatasan jujur

- **Cabang sesi ini ternyata dipakai BERSAMA oleh sesi pekerja-2** (laporan mereka,
  `docs/ops/maraton/LAPORAN-T-02.md` baris "Cabang sesi", menulis `arena/01a0c1d7-resto-barokah`
  — nama yang sama dengan sesiku; kemungkinan bentukan nama cabang platform berbenturan).
  Commit mereka `d4c0e2d` ("T-02: laporkan hambatan daftar ulang perangkat…", status MACET)
  terlanjur ter-push ke cabang ini sebelum push pertamaku. Aku **merge** commit itu (tanpa
  konflik) supaya kerja mereka tidak hilang — **bukan** force-push. Konsekuensinya:
  1. Cabang ini kini memuat kerja **dua** pekerja (T-02 MACET + T-03 selesai); integrator
     perlu memilahnya saat panen (laporan masing-masing ada di `docs/ops/maraton/`).
  2. `node alat/uji-sql.mjs` di ujung cabang ini = **60 LULUS · 1 GAGAL** — GAGAL-nya sengaja
     (reproduksi hambatan T-02 di atas migrasi beku 0018, menunggu keputusan integrator).
     Cabang ini **tidak boleh dipanen sebagai hijau** sebelum hambatan T-02 ditangani; kerja
     T-03 di dalamnya sendiri tidak menyentuh satu pun berkas SQL.
- **Uji yang tidak dijalankan (di luar lingkup):** baterai mutasi
  (`alat/uji-mutasi-*.py`), uji Edge PIN (`node alat/uji-edge-pin.mjs`), dan uji aplikasi
  (vitest) tidak dijalankan — perubahanku hanya **satu berkas markdown baru**, tidak
  menyentuh kode/migrasi apa pun; gerbang yang relevan (pemeriksa dokumen + suite SQL penuh)
  sudah hijau. CI akan menjalankan semuanya saat integrator memanen.
- **Tidak ada keputusan yang kuambil.** Enam bagian yang belum punya dasar di repo
  (masa simpan data pribadi, jalur koreksi, kanal permintaan, kalimat persetujuan,
  pseudonimisasi, frekuensi pembaruan kebijakan) kutandai `TODO(keputusan Lee)` — sengaja
  terbuka.
- **Dokumen menggambarkan rancangan yang belum dibangun.** Semua klaim "yang akan terjadi"
  bersumber dari `docs/TECH_SPEC.md` §4.4 & `docs/ROADMAP.md` Fase 8 yang masih terbuka;
  bila Lee mengubah rancangan, DRAF ini ikut disegarkan saat tinjauan.
- **Dua pengamatan untuk integrator (bukan pekerja memutuskan):**
  1. Baris T-03 di papan masih berstatus `DIBATALKAN (gelombang 1 …)` padahal kolom "Kolam
     tugas" + commit integrator `c25d2dc` ("T-01/T-02/T-03 DIBERIKAN") + prompt Lee
     menerbitkannya untuk gelombang 2 — aku memaknainya **DIBERIKAN** (gelombang 2).
     Kolom status baris T-01/T-03 mungkin perlu disegarkan integrator saat panen.
  2. Judul tugas `T8-15` menyebut "Migrasi 0017" padahal 0017–0019 sudah terpakai (0020
     sudah dicadangkan untuk T-01). Sudah kutuliskan sebagai catatan jujur di §7 DRAF-nya;
     pekerja tidak memilih nomor migrasi (aturan AL-16).

## 4. Berkas yang disentuh (daftar lengkap)

| Berkas | Aksi | Catatan |
|---|---|---|
| `docs/PRIVASI_PELANGGAN.md` | **baru (dibuat pekerja T-03)** | artifact DRAF kontrak privasi (lingkup eksklusif T-03) |
| `docs/ops/maraton/LAPORAN-T-03.md` | **baru (dibuat pekerja T-03)** | laporan ini |
| `docs/ops/maraton/LAPORAN-T-02.md` + `supabase/tes/perangkat_registrasi_tepi.sql` | masuk via **merge commit `d4c0e2d`** | **BUKAN kerja T-03** — milik sesi pekerja-2 yang berbagi nama cabang; tidak kusunting |

Tidak disentuh: papan tugas, handoff (`SIAP-LANJUT.md`/`PROJECT_STATE.md`/`STATUS.md`),
`alat/…` (pemeriksa/pagar), `.github/…`, migrasi beku (≤0019) maupun migrasi apa pun,
`supabase/tes/…`, lockfile, `main`, atau cabang lain. `npm ci` di `alat/` hanya
penginstalan dependensi lokal untuk menjalankan harness (berkas `node_modules/` diabaikan
Git — diverifikasi `git status --short` bersih selain dua berkas baru).

## 5. Pernyataan kepatuhan lingkup

Bekerja hanya di cabang `arena/01a0c1d7-resto-barokah`; commit + push hanya ke cabang itu;
tidak merge ke cabang apa pun; tidak mengubah papan; tidak mengambil keputusan
uang/keamanan/privasi — yang belum diputuskan ditandai untuk Lee.
