# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-17

- **Auditor:** Arena.ai Agent Mode — sesi baru, terpisah dari sesi pembangun (model tidak diungkapkan oleh platform; dicatat sebagai keterbatasan di bagian 6)
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `442913e4b7ae6d09ed060fe17dd90fa499d449b3`
- **Alasan commit berbeda:** HEAD klon kerja saya adalah `253d1297a3b81433d7f5809afd257d8a1b40958f` (klon dangkal depth-1 dengan refspec hanya `refs/heads/main`, sehingga commit target tidak ikut terbawa). Commit target **ada di origin** (dibuktikan `gh api repos/With-AI-Agent/Resto-Barokah/commits/442913e4…` → SHA + pesan "Prompt pembuka: langkah 2b baca REKAM_PESAN_PEMILIK"). Saya mengambilnya hanya-baca dengan `git fetch --depth=1 origin 442913e4…` lalu `git worktree add --detach /home/user/audit-target 442913e4…`, jadi seluruh audit dijalankan di atas commit target tanpa memindahkan HEAD cabang sesi. `git -C /home/user/audit-target status --short` → kosong.
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-17.md` (versi SIAP-TEMPEL yang ditempel pemilik; lihat temuan F-09 soal selisih commit dengan salinan yang ter-commit)
- **Mode cakupan:** menyeluruh
- **Verdict:** TIDAK-BERSIH

> **Kenapa TIDAK-BERSIH:** ada 2 temuan **K-1** dan 7 temuan **K-2** berstatus TERVERIFIKASI (bagian 4).
> Sesuai `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §6, verdict tidak boleh lebih tinggi.

---

## 1. Cakupan

Cakupan menyeluruh: 334 dari 334 berkas

Cara membaca kolom "Diperiksa": **dalam** = dibaca baris demi baris dan/atau ditembak dengan serangan SQL/uji mutasi;
**struktur+rujukan** = dibaca isinya (judul, tabel, rujukan berkas, angka klaim) lewat sapuan seluruh berkas teks di grup itu
(226 berkas teks, 40.418 baris) + 107 berkas biner diverifikasi ada/ukurannya lewat pemeriksa yang menutupinya
(`aplikasi/alat/uji-kontras.py` memeriksa 13 keluarga/19 berkas woff2; `prototipe/alat/periksa-halaman.py` memeriksa 5 halaman).
Denominator 334 direproduksi dengan `git ls-tree -r --name-only HEAD | grep -v '^skills/' | grep -v '^_salinan-meta/' | grep -v '^_Notes.md' | wc -l` → `334`.
Catatan jujur: 17 grup pada tabel paket hanya menutup **333** berkas — berkas ke-334, `supabase/README.md`, tidak masuk grup mana pun
(saya buktikan dengan memetakan setiap berkas ke predikat grupnya: `TIDAK TERTUTUP: ['supabase/README.md']`). Berkas itu tetap saya periksa dan saya taruh di baris 18 → temuan F-16.

| # | Grup (nama persis paket) | Berkas | Diperiksa | Bukti (perintah → hasil nyata) |
|---|---|---|---|---|
| 1 | aplikasi/src | 67 | dalam (kode) + struktur+rujukan (19 font biner) | `cd aplikasi && npm test` → `Test Files 7 passed (7) · Tests 51 passed (51)`; `npm run typecheck` → bersih; `find aplikasi/src -type f` → 67 berkas; `python3 aplikasi/alat/uji-kontras.py` → `RINGKASAN: 166 lolos, 0 gagal - 10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain` |
| 2 | aplikasi/alat | 6 | dalam | `python3 aplikasi/alat/periksa-struktur.py` → `27 OK · 7 INFO · 0 GAGAL / KEPUTUSAN: LOLOS`; `periksa-komponen-env.py` → `10 OK · 0 GAGAL`; `periksa-uji.py` → `6 OK · 1 INFO · 0 GAGAL`; `uji-kontras.py` → `166 lolos, 0 gagal` |
| 3 | aplikasi (konfigurasi) | 16 | dalam | `npm run lint` → bersih; `npm run format:check` → `All matched files use Prettier code style!`; `cat aplikasi/.env.example` → 2 variabel publik aktif, 7 rahasia dikomentari tanpa awalan `VITE_`; `cat .github/workflows/ci.yml` dibaca penuh |
| 4 | supabase/migrations | 11 | dalam (dibaca penuh + ditembak 24 serangan) | `node alat/uji-sql.mjs` → `Menerapkan 10 migrasi: OK … 0010_pembayaran.sql`; `grep -in "security definer"` → 39 fungsi, semuanya ber-`set search_path = public, pg_temp` (probe katalog `pg_proc` di bagian 3) |
| 5 | supabase/tes | 11 | dalam | `node alat/uji-sql.mjs` → `uji: 10 LULUS · 0 GAGAL / HASIL: LOLOS`; `cat supabase/tes/rls_semua_tabel.sql` dibaca penuh → temuan F-14 |
| 6 | supabase/functions | 2 | dalam | `python3 alat/periksa-fungsi-pin.py` → `RINGKASAN: 9 lolos, 0 gagal`; `grep -n "console\." supabase/functions/verifikasi_pin/index.ts` → hanya 2 baris komentar, bukan panggilan |
| 7 | alat | 24 | dalam | `python3 alat/periksa-roadmap.py` → `Tugas: 187 … HASIL: LOLOS`; `alat/periksa-fondasi-independen.py` → `HASIL: BERSIH`; `alat/audit-independen.py --uji-diri` → `HASIL: LOLOS`; `alat/review-pr.py --uji-diri` → `HASIL: LOLOS`; `alat/periksa-panduan.py` → `647 baris · 12 alur · 4 blok prompt · 18 perintah · 11 mekanisme · 66 rujukan … LOLOS` + 4 uji mutasi (F-12) |
| 8 | _sistem | 15 | struktur+rujukan | `python3 _sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`; `git ls-tree -r --name-only HEAD \| grep -c '^_sistem/'` → **15** (paket menulis 16 — selisih 1, lihat bagian 6) |
| 9 | docs (fondasi) | 11 | dalam untuk PRD/KEAMANAN/SPESIFIKASI_UI/ROADMAP/TECH_SPEC §6; struktur+rujukan sisanya | `grep -n "PIN atasan" docs/PRD.md` → baris 98, 135, 266; `grep -n -i pin docs/KEAMANAN.md` → §6 butir 3, 5, 6; `sed -n '261,267p' docs/TECH_SPEC.md` → 7 baris tabel variabel lingkungan |
| 10 | docs/uji | 26 | dalam untuk PROTOKOL/PROMPT/paket/kalibrasi; struktur+rujukan sisanya | `wc -l docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` → 277; `ls docs/uji/audit/` → **kosong** (hanya `.gitkeep`); `ls docs/uji/kalibrasi/bahan-2026-09-17/` → 5 berkas (bagian 5) |
| 11 | docs/teknis | 6 | dalam | `sed -n '125,152p' docs/teknis/BUKU_INSIDEN.md` → temuan F-08; `ls docs/teknis/PEMULIHAN.md` → tidak ada (tetapi itu berkas keluaran yang memang belum ditulis, bukan rujukan mati) |
| 12 | docs/ops | 1 | dalam | `ls docs/ops/` → hanya `SIAP_AKUN_PEMILIK.md`; 4 berkas `docs/ops/*` lain di daftar artefak paket belum ada (rencana) |
| 13 | docs/desain | 59 | struktur+rujukan (4 berkas teks dibaca, 55 gambar/biner diverifikasi lewat pemeriksa) | `python3 prototipe/alat/periksa-halaman.py` → `Periksa halaman: 183/183 lolos` (papan bukti digambar dari token yang sama) |
| 14 | prototipe | 58 | struktur+rujukan (26 teks dibaca, 32 biner) | `python3 prototipe/uji-kontras.py` → `RINGKASAN: 166 lolos, 0 gagal`; `find prototipe -name '*.woff2' \| wc -l` → 19 |
| 15 | _log-sesi | 3 | struktur+rujukan | `wc -l _log-sesi/*` → `76 LOG_SESI_2026-09-15.md · 596 LOG_SESI_2026-09-16.md · 171 LOG_SESI_2026-09-17.md · 843 total`; ketiganya dibaca penuh — klaim yang bisa diuji di dalamnya (`19 berkas woff2`, `166 lolos`, `51 uji`) saya cocokkan dengan keluaran pemeriksa nyata dan cocok |
| 16 | berkas pengguna di akar | 16 | dalam | `git ls-files \| grep -v '/' \| wc -l` → **17** (16 berkas lingkup + `_Notes.md` yang dikecualikan); 6 di antaranya diperiksa dengan 4 uji mutasi + penjaga mesin — rinci di sub-bagian **1a** di bawah; `python3 alat/periksa-panduan.py` → `647 baris · 12 alur · 4 blok prompt · 18 perintah · 11 mekanisme · 66 rujukan berkas … LOLOS` |
| 17 | .github/workflows | 1 | dalam | `cat .github/workflows/ci.yml` → 13 langkah; tidak ada `peta-ui.py` (F-15); ada `audit-independen.py --uji-diri` dan `review-pr.py --uji-diri` tetapi **tidak ada** uji-diri untuk `periksa-panduan.py` (F-12) |
| 18 | `supabase/README.md` (berkas ke-334 — **tidak tercakup 17 grup paket**, lihat F-16) | 1 | dalam | `cat supabase/README.md` (40 baris) dibaca penuh; keempat klaim yang bisa diuji saya jalankan: `node alat/uji-sql.mjs` → `10 LULUS · 0 GAGAL`; `node alat/uji-sql.mjs --daftar` → 23 tabel tercetak; `UJI_SQL_RINCI=1 node alat/uji-sql.mjs /tmp/serang/rinci.sql` → benar menampilkan `RINCI: {"hint":…,"pos":"66","query":…}`; `grep -n periksa-fungsi-pin .github/workflows/ci.yml` → baris 65 (klaim "ikut berjalan di CI" benar). `seed.sql` belum ada tetapi ditandai "(menyusul di Fase 1)" → bukan rujukan mati |

**Berkas yang dikecualikan — saya SETUJU, dengan alasan:**
`skills/` (1.802 berkas) = kumpulan skill pihak ketiga yang di-vendor; dipakai sebagai acuan, bukan kode proyek —
memasukkannya ke lingkup hanya akan menenggelamkan sinyal. `_salinan-meta/` (2 berkas) = arsip provenance sistem.
`_Notes.md` = catatan pribadi pemilik. Ketiganya tetap saya pakai: 6 skill dimuat nyata (bagian 3 baris S-0) dan
`skills/supabase/SKILL.md` menjadi sumber daftar periksa RLS/SECURITY DEFINER.

### 1a. Berkas untuk pengguna

Diperiksa **dengan cara pengguna** (bukan dengan cara programmer): apakah langkahnya bisa diikuti orang non-teknis,
apakah prompt bisa disalin apa adanya, apakah ada langkah yang menunjuk berkas/perintah yang tidak ada.

| # | Berkas untuk pengguna | Diperiksa | Bukti (perintah → hasil nyata) |
|---|---|---|---|
| 1 | `PANDUAN_PENGGUNA.md` (buku induk) | ya — dalam + 4 uji mutasi | `python3 alat/periksa-panduan.py` → `647 baris · 12 alur · 4 blok prompt · 18 perintah · 11 mekanisme · 66 rujukan berkas … LOLOS`. Uji mutasi di salinan: rujukan dipalsukan → **MERAH**; blok prompt C1 diubah → **MERAH** (`blok Prompt Pembuka … TIDAK identik`); buku dipotong 100 baris → **MERAH**; **satu alur (AL-9 insiden) dihapus → tetap HIJAU** = temuan F-12. Catatan pemakaian: urutan Bagian C adalah C1, C2, C3, C4, C5, **C7, C6** (`grep -nE '^### C[0-9]' PANDUAN_PENGGUNA.md` → baris 404 = C7, baris 418 = C6) — membingungkan pengguna yang disuruh "buka Bagian C4/C6", tetapi tidak menghalangi (K-4, tidak dihitung sebagai temuan) |
| 2 | `PROMPT_ENTRI_UNIVERSAL.md` + blok C1 di buku induk | ya — dalam | identitas keduanya dijaga mesin dan saya buktikan penjaganya bisa MERAH (mutasi M3: `STATUS.md` → `STATUS.md_DIUBAH` di blok C1 → `GAGAL — 1 temuan`). Prompt **bisa disalin apa adanya**: saya menerimanya apa adanya di awal sesi ini dan seluruh langkahnya (baca ROADMAP/STATUS/PROJECT_STATE/TERTANGGUH/REKAM_PESAN_PEMILIK) menunjuk berkas yang benar-benar ada di commit ini |
| 3 | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` (bagian B) | ya — dalam | identik dengan blok C4 buku induk (dijaga `periksa-panduan.py`; mutasi membuktikan penjaganya hidup). Kalimat pembuka yang saya terima cocok dengan isinya. Satu-satunya jalan buntu: langkah 1 menyuruh membaca paket audit, dan **paket yang ter-commit menunjuk commit yang berbeda** dari paket yang ditempel pemilik → temuan F-09 |
| 4 | `START_DI_SINI.md`, `PROFIL_PENGGUNA.md`, `STATUS.md`, `PROJECT_STATE.md`, `AGENT_SYSTEM.md`, `10_LOG_SESI.md`, `PANDUAN_PEMAKAIAN.md`, `SYSTEM_MANIFEST.md` | ya — struktur+rujukan, semua rujukan hidup diverifikasi | sapuan rujukan ber-backtick pada 14 berkas pengguna: 698 rujukan diperiksa; setelah menyaring nama relatif (`ROADMAP.md` = `docs/ROADMAP.md`), notasi `/docs`, dan contoh ilustratif (`supabase/migrations/001_users.sql` di `AGENT_SYSTEM.md:328` adalah contoh format tugas), **satu** rujukan mati nyata pada langkah pengguna: `alat/denyut.py` di `docs/teknis/BUKU_INSIDEN.md:131` → temuan F-08 |
| 5 | `docs/PANDUAN_PEMILIK.md` | ya — dalam | `periksa-panduan.py` memeriksa arah tunjuk baliknya dan LOLOS; isinya merujuk `PANDUAN_PENGGUNA.md` Bagian C4/C5 yang benar-benar ada |
| 6 | `docs/teknis/BUKU_INSIDEN.md` | ya — dalam | 12 bab ada. **Langkah 4 bab 8 (proyek Supabase tidur) tidak bisa dijalankan apa adanya**: "Nyalakan kembali 'denyut harian' (pg_cron) … (alat: `alat/denyut.py`)" — `ls alat/denyut.py` → tidak ada → temuan F-08 |
| 7 | `docs/ops/*` | ya — dalam | hanya `SIAP_AKUN_PEMILIK.md` yang ada. Empat berkas operasional lain yang disebut daftar artefak paket (`PEMULIHAN_PERANGKAT.md`, `DEPLOY.md`, `PANDUAN_PEGAWAI.md`, `SERAH_TERIMA_G1.md`) belum ada — konsisten dengan tugasnya yang masih `[ ]`, jadi bukan temuan |
| 8 | Paket audit + mekanisme audit dari sisi pengguna | ya — dalam | `python3 alat/audit-independen.py --verifikasi-lingkup` → `Commit target : d9de6ebf… / Commit lokal : 442913e4… / HASIL: TARGET TIDAK ADA di repo ini setelah fetch. JANGAN mengaudit commit lain.` Padahal commit yang diperintahkan paket tempel pemilik **adalah** commit lokal → temuan F-09 |

**Jawaban atas empat pertanyaan wajib §2b.2:** (a) langkah bisa diikuti non-teknis — ya, kecuali F-08;
(b) prompt bisa disalin apa adanya dan bekerja — ya, dibuktikan pada sesi ini;
(c) ada langkah yang menyebut berkas/perintah tidak ada — ya, satu (F-08);
(d) buku induk lengkap — ya: 12 alur, 4 blok prompt, 18 perintah, 11 mekanisme terdaftar, semua rujukan hidup,
tetapi penjaganya menyisakan ruang untuk menghapus 2 alur tanpa ketahuan (F-12).

---

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T0-01: "`npm run dev` melayani halaman (HTTP 200), `main.tsx`, `tema.css`, dan berkas huruf" | `npm run dev -- --host 0.0.0.0 --port 5199` lalu `curl -w "%{http_code}"` pada 6 URL | **TERBUKTI.** `/`=200 · `/src/main.tsx`=200 · `/src/gaya/token/tema.css`=200 · `/src/gaya/aset/font/outfit-reguler.woff2`=200 · `/favicon.svg`=200 · `/robots.txt`=200 |
| 2 | T0-01: "**31 berkas huruf pindah**" | `find aplikasi -name '*.woff2' \| wc -l` dan `find . -name '*.woff2' -not -path './skills/*' \| wc -l` | **DIBANTAH.** aplikasi = **19**, seluruh repo (di luar `skills/`) = **38** (19 aplikasi + 19 prototipe). Angka 31 tidak cocok dengan hitungan mana pun, dan `STATUS.md` sendiri menulis "13 keluarga, **19 berkas**" → temuan F-13 |
| 3 | T0-04: "uji kontras aplikasi **166 lolos · 0 gagal** (130 warna + 36 aturan desain, termasuk tinggi sentuh ≥44 px)" | `python3 aplikasi/alat/uji-kontras.py` | **TERBUKTI** persis: `RINGKASAN: 166 lolos, 0 gagal - 10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain`; `.btn/.input/.tab` ≥44 px, `.pay` 48 px, `.nav-bawah a` 46 px |
| 4 | T0-10: "**51 uji hijau dalam 7 berkas**" | `cd aplikasi && npm test` | **TERBUKTI** persis: `Test Files 7 passed (7) · Tests 51 passed (51)` |
| 5 | T0-05: "`.env.example` memuat **semua 8 nama variabel** TECH_SPEC §6; hanya 2 yang aktif; rahasia tanpa awalan `VITE_`" | `cat aplikasi/.env.example` + `sed -n '261,267p' docs/TECH_SPEC.md` + `python3 aplikasi/alat/periksa-komponen-env.py` | **TERBUKTI.** 2 variabel `VITE_` aktif; 7 baris rahasia dikomentari tanpa `VITE_`; pemeriksa → `OK: .env.example memuat semua 8 nama variabel TECH_SPEC §6` dan `OK: hanya 2 variabel publik yang aktif` |
| 6 | T0-07: "CI menyala di setiap push & pull request; gerbangnya benar-benar bekerja (run 35121292973 merah di ESLint)" | `cat .github/workflows/ci.yml` + `gh run view <id> --json conclusion,jobs` | **TERBUKTI, dan lebih kuat dari yang saya duga.** `on: push / pull_request` benar; 13 langkah benar dan semua saya jalankan lokal (hijau). Ketiga nomor run yang diklaim **nyata ada**: 35121292973 → `conclusion: failure`, langkah gagal = **"Aturan kode (ESLint)"** (judul run: "UJI SENGAJA (T0-07): kode dengan variabel tidak terpakai"); 35120922393 → failure di "Pemeriksa fondasi, roadmap, struktur & kontras"; 35121062046 → failure. **Tetapi** lihat F-17: commit yang saya audit tidak punya satu pun run |
| 7 | T1-06: "PIN disimpan **hanya sebagai hash** … database menolak sendiri nilai yang bukan hash" | `node alat/uji-sql.mjs supabase/tes/pin.sql` + serangan S08b/S08c | **TERBUKTI untuk penyimpanannya** (`pin.sql` LULUS; `update … set pin_hash='123456'` ditolak). **TETAPI** hash-nya tetap **bisa dibaca klien** lewat `SELECT` biasa: kasir membaca `pin_hash` dirinya = `$tiruan$10$08f0a2219…`, owner membaca hash pegawainya → temuan F-10 |
| 8 | T1-10: "total pembayaran **tidak boleh melebihi total pesanan** (50.000 + 20.000 > 62.100 → ditolak)" | serangan S11b: kasir membuat pesanan (total=0 karena penjaga uang), lalu mencatat pembayaran 99.999.999 | **DIBANTAH.** `S11b_total_pesanan=0 ; nilai_item=12000 ; UANG_TERCATAT_MASUK=99999999`. Pemeriksaan dilewati whenever `total = 0`, dan **semua** pesanan buatan klien bertotal 0 → temuan F-03 |
| 9 | T1-10: "pembatalan **setelah dapur mulai wajib disetujui** pengguna berizin" + PRD Aturan Bisnis 7 "**PIN atasan**" | serangan S10 + S10b | **DIBANTAH secara substantif.** Kasir membaca UUID admin dari `pengguna_cabang` (`S10_langkah1_… = 90000000-…0003, …0004, …0005`), lalu menyisipkan `pembatalan(tahap='sesudah_dapur', disetujui_oleh=<UUID admin>)` → **diterima**, `kerugian=54000`, `jumlah_percobaan_pin_yang_tercatat=0`. Yang diperiksa hanya *izin* nama yang ditulis klien, bukan PIN-nya → temuan F-02 |
| 10 | T1-09: "pesanan **tidak bisa dihapus** (hanya dibatalkan)" | serangan S22 (`delete from public.pesanan`) | **TERBUKTI untuk DELETE** (`DITOLAK: permission denied for table pesanan`). **TETAPI** "dibatalkan" bisa dilakukan tanpa jejak: `kasir_batalkan_TANPA_pembatalan -> baris=1` → bagian dari temuan F-01 |
| 11 | T1-05: "batas diskon (kasir 25.000/5 persen · admin 50.000/10 persen) ditegakkan **gerbang**, bukan layar" | serangan S12 + S23 | **SEBAGIAN DIBANTAH.** Batas **nominal** ditegakkan (`kasir_diskon_30000_batas25000 -> DITOLAK: Diskon ini melebihi batas izin Anda`). Batas **persen** dilewati dengan mengosongkan kolom `persen`: `S12_diskon_kasir_persen_NULL_berhasil: nilai=25000 ; subtotal_pesanan=54000` = 46% dengan batas 5% → temuan F-06 |
| 12 | T1-04: uji katalog "membaca katalog PostgreSQL, tidak menyebut nama tabel satu per satu — jadi tabel baru otomatis diperiksa … plus pemindaian pembocoran" | `cat supabase/tes/rls_semua_tabel.sql` | **SEBAGIAN DIBANTAH.** Sapuan pembocoran hanya mengulang tabel yang **punya kolom `penyewa_id`** (`where … column_name = 'penyewa_id'`), jadi `pesanan_item`, `pembayaran`, `diskon_transaksi`, `pembatalan`, `meja`, `menu_varian`, `izin`, `percobaan_pin` **tidak ikut tersapu** — persis tabel tempat uang berada → temuan F-14 |
| 13 | T1-06: "batas percobaan **dua lapis** (5 salah/akun & 12 salah/perangkat per 15 menit)" | serangan S14b: 15 percobaan salah untuk korban yang sama, nama perangkat diganti tiap kali | **SEBAGIAN DIBANTAH.** Lapis akun **bekerja** (`masih_dilayani="PIN salah."=5`, sisanya `terkunci=10`). Lapis perangkat **tidak berarti** karena `p_perangkat` adalah teks kiriman klien → temuan F-11 |
| 14 | T0-11/T0-14 + PROTOKOL §2b: "`alat/periksa-panduan.py` … memastikan buku induk tetap lengkap — bagian A–H ada, topik wajib ada, ≥10 mekanisme terdaftar … dan semua rujukan berkas ber-backtick benar-benar ada" | 4 uji mutasi pada salinan buku induk | **SEBAGIAN DIBANTAH.** Rujukan mati → MERAH ✓; prompt tidak identik → MERAH ✓; buku menyusut → MERAH ✓; **satu alur utuh (AL-9 "Masalah mendesak (insiden)", 983 huruf) dihapus → tetap LOLOS** karena `MIN_ALUR = 10` sementara buku punya 12 → temuan F-12 |
| 15 | KEAMANAN §6 butir 6: "Ganti PIN sendiri **wajib PIN lama**" | serangan S13c | **DIBANTAH.** `ganti_pin('9999','2222')` tanpa PIN lama memang ditolak, tetapi `simpan_pin('2222', null, '<UUID diri sendiri>', 'hp-penyerang')` **diterima**: `pin_lama_1111_berlaku=false ; pin_baru_2222_berlaku=true` → temuan F-07 |
| 16 | STATUS.md: "Fase 1 dijeda dengan sadar di T1-10; T1-01…T1-10 sudah `[x]`" | `grep -cE "\[x\]" docs/ROADMAP.md` + `ls supabase/migrations/` | **TERBUKTI.** 22 tugas bertanda `[x]` = T0-01…T0-07, T0-10, T0-11, T0-13, T0-14, T1-01…T1-10 (+7 baris checklist jejak). Migrasi yang ada persis 0001–0010. Saya sempat menduga STATUS.md mengklaim Fase 1B/1C selesai; setelah dibaca ulang, kalimatnya menyebut **penyisipan tugas**, bukan penyelesaian, dan T1-39 memang masih `[ ]` — dugaan saya **tidak** dijadikan temuan |

| 17 | `supabase/README.md`: "PostgreSQL asli dijalankan di dalam Node … sehingga migrasi dan kebijakan RLS bisa benar-benar diuji di komputer mana pun"; "Pemeriksa itu (`periksa-fungsi-pin.py`) ikut berjalan di CI"; "`UJI_SQL_RINCI=1` menampilkan letak galat dari PostgreSQL" | jalankan keempat perintahnya apa adanya di commit ini | **TERBUKTI.** `cd alat && npm ci` lalu `node alat/uji-sql.mjs` → `10 LULUS · 0 GAGAL / LOLOS`; `--daftar` → 23 tabel + RLS + jumlah policy tercetak; `UJI_SQL_RINCI=1` → benar menampilkan `RINCI: {"hint":…,"pos":"66","query":…}`; `grep -n periksa-fungsi-pin .github/workflows/ci.yml` → baris 65. Satu-satunya berkas yang tidak masuk tabel lingkup paket (F-16) justru dokumen paling penting untuk menjalankan gerbang |

---

## 3. Serangan yang dijalankan (kill attempts)

Semua serangan dijalankan terhadap PostgreSQL asli di dalam Node (PGlite) dengan migrasi repo apa adanya, memakai
runner repo sendiri (`node alat/uji-sql.mjs <jalur absolut>` menerima jalur di luar repo — `jalurUji()` baris 173),
sehingga **tidak satu pun berkas repo berubah**. Pelaku memakai akun data uji: Rina=kasir Pusat, Dedi=pelayan 2 cabang,
Sari=dapur Cabang Dua, Bu Oasis=owner, Ujang=kasir resto lain.

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| S-0 | Muat 6 skill wajib + 1 penemuan skill | `head`/`grep` pada `skills/{security-review,verification-before-completion,systematic-debugging,verification-loop,test-driven-development,prd-taskmaster,supabase,supabase-postgres-best-practices,ui-ux-pro-max,find-skills}/SKILL.md` | 10/10 berkas ada dan dibaca. Daftar periksa `skills/supabase/SKILL.md` baris 45–67 (view menembus RLS · UPDATE butuh policy SELECT · `SECURITY DEFINER` di `public` bisa dipanggil semua peran) dipakai sebagai daftar tembak |
| S-1 | Bedah katalog: fungsi mana SECURITY DEFINER, `search_path` terkunci?, siapa boleh EXECUTE? | probe `pg_proc`/`proacl`/`proconfig` (berkas serangan `p1_katalog_fungsi.sql`) | 39 fungsi. **Semua** `security definer` ber-`set search_path = public, pg_temp` ✓. 24 fungsi di-`revoke … from public` + `grant` eksplisit ✓. Yang ber-`acl=DEFAULT(PUBLIC!)` hanya fungsi pemicu (`picu_*`) — tidak bisa dipanggil langsung, dan `crypt`/`gen_salt` = tiruan alat uji. **Tetapi** `harga_berlaku` & `menu_habis` juga di-grant ke `anon` (lihat S-7) dan `total_dibayar`/`izin_efektif_untuk`/`boleh_untuk` tanpa cek penyewa (S-5, S-6) |
| S-2 | Anon membaca 16 tabel sensitif + memanggil fungsi istimewa | `s01b_anon.sql` | **GAGAL SERANGAN.** 0 baris di 16 tabel; `percobaan_pin`/`diskon_transaksi`/`pembatalan` → `permission denied`; `verifikasi_pin`/`boleh` → `permission denied for function` |
| S-3 | Kasir resto B membaca & menulis data resto A | `s02b_pecah.sql`, `s02c_tajam.sql` | **GAGAL SERANGAN.** Yang terlihat hanya datanya sendiri (`penyewa=Warung Bandung`, `menu_item=Mie Ayam`); 0 baris pesanan/item/menu_cabang/pengaturan/izin_peran/pengguna/meja/stok resto A; 4 percobaan tulis ditolak. *Catatan kejujuran: versi pertama serangan ini (`s02_lintas_resto.sql`) menyalak "BOCOR" — ternyata asersi saya sendiri salah (saya menuntut `izin_peran=0` padahal 50 baris miliknya sendiri memang boleh terlihat). Setelah dipecah per tabel, klaim bocor itu saya tarik* |
| S-4 | Kasir mengarang angka uang pesanan | `s03_uang_palsu.sql` | **GAGAL SERANGAN.** `insert … total=1` dan `update … set total=1` dua-duanya ditolak pemicu `picu_pesanan_jaga_uang` |
| S-5 | Bocor angka uang lintas resto lewat fungsi SECURITY DEFINER | `s16_total_dibayar_lintas.sql` | **SERANGAN BERHASIL → F-04.** `kasir_restoB -> total_dibayar(pesanan_restoA)=62100` padahal `baris_pembayaran_terlihat_lewat_select=0` dan `pesanan_restoA_terlihat=0` |
| S-6 | Bocor izin & batas diskon lintas resto | `s06_boleh_untuk.sql` | **SERANGAN BERHASIL → F-05.** `boleh_untuk(owner_restoA,'atur_pengaturan')=true ; batas_diskon_kasir_restoA=25000 ; pengguna_restoA_tak_terlihat=0` |
| S-7 | Anon mengintip harga/stok resto mana pun lewat `harga_berlaku`/`menu_habis` | `s07b_anon_harga.sql` | **GAGAL SERANGAN** (hipotesis saya gugur): `harga_berlaku(...)=NULL`, `menu_habis(...)=false`, `baris_menu_item_terlihat_anon=0` — kedua fungsi memfilter `penyewa_saya()`. Grant EXECUTE ke `anon` jadi tidak berguna hari ini, bukan lubang |
| S-8 | Baca hash PIN lewat SELECT biasa | `s08b_pin_hash.sql`, `s08c_pin_hash_owner.sql` | **SERANGAN BERHASIL → F-10.** `pin_hash_diri_sendiri=$tiruan$10$08f0a2219…`; owner: `jumlah_pegawai_yang_pin_hash_nya_terbaca_owner=1 ; contoh_hash=$tiruan$10$cc51436a8…` |
| S-9 | Tebak PIN dengan memutar nama perangkat | `s14b_perangkat_palsu.sql` | **SEBAGIAN BERHASIL → F-11.** Lapis akun menahan di 5 (`masih_dilayani=5`, `terkunci=10`), tetapi lapis 12×/perangkat tidak berlaku sama sekali karena `p_perangkat` kiriman klien |
| S-10 | Kasir mencari UUID atasan | `s10_void_palsu.sql` | **SERANGAN BERHASIL (langkah 1 F-02).** `pengguna_cabang` cabang sendiri membocorkan `90000000-…0003, …0004, …0005` — termasuk UUID admin cabang |
| S-11 | Void sesudah dapur dengan penyetuju karangan (tanpa PIN) | `s10b_void_palsu.sql` | **SERANGAN BERHASIL → F-02.** `baris pembatalan=1 ; kerugian=54000 ; penyetuju_tercatat=90000000-…0003 ; jumlah_percobaan_pin_yang_tercatat=0` |
| S-12 | Catat uang masuk jauh melampaui nilai pesanan | `s11b_bayar_lebih.sql` | **SERANGAN BERHASIL → F-03.** `total_pesanan=0 ; nilai_item=12000 ; UANG_TERCATAT_MASUK=99999999` |
| S-13 | Diskon melewati batas persen dengan mengosongkan `persen` | `s12_diskon_tanpa_persen.sql` | **SERANGAN BERHASIL → F-06.** `nilai=25000 ; subtotal_pesanan=54000` (46% dari subtotal, batas izin 5%) |
| S-14 | Ganti PIN sendiri tanpa PIN lama | `s13c_pin_tanpa_lama.sql` | **SERANGAN BERHASIL → F-07.** `ganti_pin` tanpa PIN lama ditolak ✓, tetapi `simpan_pin(…, p_pengguna_id:=diri sendiri)` → `pin_lama_1111_berlaku=false ; pin_baru_2222_berlaku=true` |
| S-15 | Kasir/pelayan memindahkan status pesanan seenaknya | `s15b_lunas.sql`, `t5.sql`, `s22_jumlah_baris.sql` | **SERANGAN BERHASIL → F-01.** `S15b_kasir_menandai_LUNAS_baris=1 \|\| pembayaran_tercatat=0`; `T5_sebagai_kasir_ubah_status_batal_baris=1`; `pelayan_tandai_lunas -> baris=1` |
| S-16 | 15 percobaan eskalasi hak (izin, peran, pajak, cabang, harga, buku besar stok, hapus riwayat) | `s22_jumlah_baris.sql` (setiap perintah diukur dengan `GET DIAGNOSTICS row_count`, bukan sekadar "tidak error") | **GAGAL SERANGAN (13/15).** `kasir_ubah_izin_peran -> baris=0` · `kasir_ubah/tambah_izin -> permission denied` · `kasir_ubah_pajak -> 0` · `kasir_ubah/hapus_metode_bayar -> 0` · `kasir_ubah_cabang -> 0` · `kasir_tambah_cabang -> violates RLS` · `kasir_ubah_harga_menu -> 0` · `kasir_nonaktifkan_pengguna/naikkan_peran -> permission denied` · `kasir_ubah_buku_besar_stok -> permission denied` · `kasir_hapus_pesanan -> permission denied` · `dapur_ubah_harga_menu -> 0` · `dapur_ubah_status_pesanan -> 0`. **Yang lolos hanya 2:** `kasir_tandai_lunas_TANPA_bayar -> baris=1`, `pelayan_tandai_lunas -> baris=1` |
| S-17 | Pembayaran dobel saat koneksi putus (kunci idempoten sama) | `s20_dobel_bayar.sql` | **GAGAL SERANGAN.** `duplicate key value violates unique constraint "pesanan_cabang_id_kunci_idempote…"`; jumlah baris tetap 1 |
| S-18 | Diskon tanpa alasan / void tanpa penyetuju / void dengan penyetuju diri sendiri | `s23_sisa.sql` | **GAGAL SERANGAN.** `violates check constraint diskon_transaksi…` · `Pembatalan setelah dapur mulai wajib disetujui pengguna berizin (PIN)` · `Penyetuju itu tidak berizin menyetujui pembatalan setelah dapur mulai` (kasir memang tidak punya `void_sesudah_dapur` — yang berbahaya justru penyetuju **orang lain**, lihat S-11) |
| S-19 | Ubah/hapus buku besar stok & riwayat uang/keamanan | `s18_stok_saldo.sql`, `s19_hapus_riwayat.sql` | **GAGAL SERANGAN.** 3 + 6 percobaan (`update stok_bahan.jumlah`, `update/delete stok_pergerakan`, `delete pesanan/pembayaran/pembatalan/percobaan_pin`, `update pembayaran.jumlah`, `update percobaan_pin.berhasil`) semuanya ditolak |
| S-20 | Baca lintas cabang (kasir Pusat → Cabang Dua) | `s24_lintas_cabang_baca.sql`, `t3_isolasi_item2.sql` | **GAGAL SERANGAN.** 0 baris pesanan/item/meja/menu_cabang Cabang Dua; `insert` item ke pesanan Cabang Dua → `new row violates row-level security policy for table "pesanan_item"`. *Hipotesis awal saya (policy `pesanan_item` hanya per-penyewa) **gugur** setelah menelusuri pemanggilnya: `pesanan_sepenyewa()` ternyata memuat `cabang_pantau_saya(p.cabang_id)` — persis alasan protokol §3.6 mewajibkan uji ulang* |
| S-21 | Uji mutasi penjaga buku induk (4 mutasi) | salinan buku induk + `alat/periksa-panduan.py` di farm `/tmp/mp` (semua entri di-symlink, `periksa-panduan.py` disalin nyata supaya `AKAR` tidak ikut `resolve()` ke repo asli) | **3 MERAH, 1 HIJAU.** rujukan dipalsukan → `GAGAL — 1 temuan`; blok prompt C1 diubah → `GAGAL`; buku dipotong 100 baris → `GAGAL`; **hapus AL-9 (983 huruf) → `HASIL: LOLOS`** → F-12. *Catatan kejujuran: percobaan farm pertama saya cacat (`.resolve()` mengikuti symlink sehingga checker membaca berkas asli dan keempat mutasi "lolos"); farm diperbaiki dan hasilnya di atas adalah yang sah* |
| S-22 | Sapuan rahasia & log | `grep -rInE "sk-[A-Za-z0-9]{16,}\|eyJhbGciOi\|service_role…\|SUPABASE_SERVICE_ROLE_KEY=…"` (di luar `skills/`), `find . -name .env`, `grep -n "console\." supabase/functions/verifikasi_pin/index.ts` | **GAGAL SERANGAN.** 0 kecocokan rahasia; tidak ada berkas `.env` nyata; `console.*` hanya muncul di 2 baris komentar penjelas |
| S-23 | Gerbang aplikasi hidup & melayani aset | `npm run dev` + 6 `curl` | **TERBUKTI HIJAU** (lihat bagian 2 klaim #1) — sekaligus membuktikan tidak ada regresi build/lint/tipe/uji setelah seluruh serangan |
| S-24 | Seluruh gerbang repo dijalankan ulang sesudah serangan | `node alat/uji-sql.mjs`, 6 pemeriksa Python, `npm test/typecheck/lint/format:check` | **SEMUA HIJAU** — yaitu: tidak satu pun dari 8 lubang di bagian 4 membuat gerbang yang ada menjadi MERAH. Itu sendiri bukti bahwa gerbang belum menutup jalur-jalur ini |

---

## 4. Temuan

### [F-01] Status pesanan bisa dipindahkan bebas oleh kasir **dan pelayan** — "lunas" tanpa pembayaran, "batal" tanpa jejak
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0009_pesanan.sql:213-224` (policy `pesanan_ubah`) — tidak ada pemicu penjaga transisi status pada tabel `pesanan`
- **Klaim yang dilanggar:** PRD M6/Aturan Bisnis 7 ("tidak ada pembatalan yang tidak terlihat"; "sebelum dapur = kasir boleh + wajib alasan; setelah dapur = PIN atasan + tercatat sebagai kerugian") dan doktrin proyek sendiri di `supabase/migrations/0010_pembayaran.sql:5-8` ("semua … dijaga database — bukan hanya oleh layar"). Juga melemahkan klaim T1-09 "pesanan tidak bisa dihapus (hanya dibatalkan)"
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s15b_lunas.sql` → `S15b_kasir_menandai_LUNAS_baris=1 || pembayaran_tercatat=0`; `node alat/uji-sql.mjs /tmp/serang/s22_jumlah_baris.sql` → `kasir_tandai_lunas_TANPA_bayar -> baris=1`, `kasir_batalkan_TANPA_pembatalan -> baris=1`, `pelayan_tandai_lunas -> baris=1` (padahal 13 percobaan tulis ilegal lain di berkas yang sama `baris=0`/`permission denied`)
- **Skenario gagal:** Pelayan di jam ramai membuka pesanan teman → tekan satu tombol yang mengirim `update pesanan set status='lunas'` → pesanan tampak terbayar, tidak ada satu baris `pembayaran`, tidak ada selisih kas yang terlihat di laporan. Jalur kedua: kasir mengirim `status='batal'` → pesanan hilang dari daftar **tanpa** baris `pembatalan`, tanpa alasan, tanpa nilai kerugian — persis "pembatalan yang tidak terlihat" yang PRD janjikan tidak ada. Keduanya tidak bisa dipulihkan: tidak ada jejak yang bisa diaudit afterwards
- **Dugaan penyebab:** `pesanan_ubah` hanya memeriksa penyewa + cabang + peran (`in ('owner_pusat','admin_cabang','kasir','pelayan')`), tanpa `boleh(...)` dan tanpa penjaga transisi status. Penjaga uang (`picu_pesanan_jaga_uang`) melindungi **kolom angka**, bukan **kolom status**, dan RPC `simpan_pesanan`/`bayar_pesanan`/`batal_pesanan` (T1-15, T3-05, T5-02…) memang belum ada — sehingga hari ini satu-satunya pintu ke `status` adalah UPDATE langsung dari klien
- **Cara membuktikan perbaikan:** tambahkan pemicu `before update of status on public.pesanan` yang menolak `lunas` bila `total_dibayar(id) < total`, menolak `batal` bila tidak ada baris `pembatalan` yang cocok, dan menolak peran `pelayan` mengubah status; lalu perintah ini harus MERAH→HIJAU: `node alat/uji-sql.mjs /tmp/serang/s15b_lunas.sql` dan `…/s22_jumlah_baris.sql` (baris `kasir_tandai_lunas_TANPA_bayar`, `kasir_batalkan_TANPA_pembatalan`, `pelayan_tandai_lunas` harus berubah jadi `DITOLAK`)
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Pembatalan sesudah dapur mulai lolos dengan penyetuju karangan — PIN atasan tidak pernah diverifikasi
- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:414-420` (`picu_pembatalan_sah`: `if not public.boleh_untuk(new.disetujui_oleh, 'void_sesudah_dapur')`); jalur pembocoran UUID di `supabase/migrations/0004_pola_rls.sql:60-61` (`pengguna_cabang_pilih`)
- **Klaim yang dilanggar:** PRD §M6 & Aturan Bisnis 7 ("setelah dapur mulai = **PIN atasan**"), `docs/KEAMANAN.md` §6 butir 5 ("PIN benar belum cukup untuk aksi") dan §9 ("Laporan 'siapa menyetujui apa' … mencegah PIN atasan dipakai berulang tanpa terasa")
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s10_void_palsu.sql` → `S10_langkah1_uuid_yang_terlihat_di_pengguna_cabang_cabang_saya=90000000-0000-0000-0000-000000000003,90000000-0000-0000-0000-000000000004,90000000-0000-0000-0000-000000000005`; lalu `node alat/uji-sql.mjs /tmp/serang/s10b_void_palsu.sql` → `S10b_VOID_SESUDAH_DAPUR_LOLOS_TANPA_PIN: baris pembatalan=1 ; kerugian=54000 ; penyetuju_tercatat=90000000-0000-0000-0000-000000000003 ; jumlah_percobaan_pin_yang_tercatat=0`
- **Skenario gagal:** Kasir membaca daftar `pengguna_cabang` cabangnya (dibolehkan policy) → mendapat UUID admin cabang → menyisipkan `pembatalan(tahap='sesudah_dapur', disetujui_oleh=<UUID admin>, alasan='pelanggan batal')`. Makanan yang sudah dimasak dicatat sebagai kerugian Rp54.000 **atas nama admin yang tidak pernah dimintai persetujuan**, dan `percobaan_pin` tetap 0 baris sehingga laporan "siapa menyetujui apa" tidak akan pernah menunjukkan kejanggalan. Tabel `pembatalan` bersifat hanya-tambah, jadi jejak palsu itu tidak bisa dikoreksi
- **Dugaan penyebab:** `disetujui_oleh` diperlakukan sebagai *fakta yang dipercaya* dari klien. Tidak ada kaitan antara baris `pembatalan` dan satu baris `percobaan_pin` yang `berhasil=true` untuk pengguna itu dalam jendela waktu tertentu (mis. kolom `disetujui_percobaan_pin_id` + pemeriksaan di pemicu)
- **Cara membuktikan perbaikan:** wajibkan pemicu menemukan `percobaan_pin` `berhasil=true` milik `disetujui_oleh` dalam N menit terakhir (atau lewat token persetujuan sekali pakai dari `verifikasi_pin`); bukti: `node alat/uji-sql.mjs /tmp/serang/s10b_void_palsu.sql` harus berubah dari `baris pembatalan=1` menjadi `DITOLAK`
- **Status verifikasi:** TERVERIFIKASI

### [F-03] Pembayaran boleh melampaui total pesanan selama `total` masih 0 — dan semua pesanan buatan klien bertotal 0
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:292-298` (`if coalesce(v_pesanan.total, 0) > 0 then … pemeriksaan …`)
- **Klaim yang dilanggar:** ROADMAP T1-10 Bukti: "total pembayaran **tidak boleh melebihi total pesanan** (50.000 + 20.000 > 62.100 → ditolak)"; komentar kepala 0010 butir 2
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s11b_bayar_lebih.sql` → `S11b_total_pesanan=0 ; nilai_item=12000 ; UANG_TERCATAT_MASUK=99999999`. Total pesanan **tidak bisa** diisi klien (F-04 klaim #4 di bagian 2: penjaga uang bekerja), jadi keadaan `total = 0` adalah keadaan **bawaan** setiap pesanan yang dibuat dari perangkat sampai `hitung_total()` (T1-15) ada
- **Skenario gagal:** Kasir membuat pesanan 1 kopi (12.000) → mencatat pembayaran tunai 99.999.999 → `pembayaran` bersifat hanya-tambah dan tidak bisa dihapus/diubah (S-19), jadi angka itu permanen di buku uang masuk. Laporan kas harian (T7-07…) akan menjumlahkannya sebagai uang masuk
- **Dugaan penyebab:** pengecualian "supaya pencatatan tidak macet" ditulis sebelum `hitung_total()` ada, dan tidak ada jaring pengaman kedua (mis. membandingkan dengan `sum(pesanan_item.subtotal)` bila `total = 0`)
- **Cara membuktikan perbaikan:** bila `total = 0`, pakai `sum(pesanan_item.subtotal)` sebagai pembanding (atau tolak pembayaran sebelum total dihitung); bukti: `node alat/uji-sql.mjs /tmp/serang/s11b_bayar_lebih.sql` harus `DITOLAK`
- **Status verifikasi:** TERVERIFIKASI

### [F-04] `total_dibayar(uuid)` SECURITY DEFINER tanpa pemeriksaan penyewa → angka uang bocor lintas resto
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:153-165` + `:503-504` (`grant execute … to authenticated, service_role`)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §7 butir 3 ("Fungsi `SECURITY DEFINER` … tidak boleh menjadi jalan pintas menyelesaikan masalah izin"); lensa L1 ("ada jalur membaca data penyewa lain?"); TECH_SPEC §9 ART-1
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s16_total_dibayar_lintas.sql` → `S16_kasir_restoB -> total_dibayar(pesanan_restoA)=62100 | baris_pembayaran_terlihat_lewat_select=0 | pesanan_restoA_terlihat=0`. Fungsi ini membaca `pembayaran` sebagai pemilik tabel sehingga RLS tidak berlaku, dan badannya tidak menyebut `penyewa_saya()` sama sekali
- **Skenario gagal:** Pegawai resto B yang memperoleh satu UUID pesanan resto A (dari log, tangkapan layar, atau kebocoran lain) bisa memanggil RPC ini berulang kali dan membaca nilai uang masuk resto lain, tanpa satu baris pun terlihat lewat SELECT biasa. Eksploitabilitas praktis rendah (UUIDv4 sulit ditebak) tetapi jalurnya nyata dan murah ditutup
- **Dugaan penyebab:** fungsi dibuat sebagai pembantu internal pemicu, lalu hak `execute` diberikan ke `authenticated` tanpa menambah saringan penyewa
- **Cara membuktikan perbaikan:** tambahkan `and public.pesanan_sepenyewa(p_pesanan_id)` (atau `penyewa_saya()`) di badan fungsi, atau cabut `execute` dari `authenticated`; bukti: serangan S-16 harus mengembalikan `0`/`NULL`
- **Status verifikasi:** TERVERIFIKASI

### [F-05] `izin_efektif_untuk` / `boleh_untuk` SECURITY DEFINER tanpa pemeriksaan penyewa → izin & batas diskon resto lain bocor
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0006_pin.sql:82-176` (badan `izin_efektif_untuk`) + `:181-184` (`grant execute … to authenticated`)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §7 butir 3; TECH_SPEC §9 ART-1 (isolasi penyewa)
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s06_boleh_untuk.sql` → `S06_kasir_restoB_boleh_untuk(owner_restoA, atur_pengaturan)=true ; batas_diskon_kasir_restoA=25000 ; pengguna_restoA_tak_terlihat=0`. Fungsi hanya menolak `pemilik_platform` dan akun nonaktif; tidak ada pembandingan `v_penyewa` dengan `penyewa_saya()`
- **Skenario gagal:** Pegawai resto B yang memegang UUID pegawai resto A dapat memetakan kebijakan izin resto saingan (siapa boleh apa, berapa batas diskon per peran) — informasi yang oleh `izin_pilih` sengaja disembunyikan (`pengguna_restoA_tak_terlihat=0` membuktikan SELECT biasa menutupnya)
- **Dugaan penyebab:** fungsi ini memang perlu menilai "pegawai lain" untuk jalur PIN atasan, tetapi penyaringnya berhenti di tingkat *aktif/peran*, tidak sampai tingkat *penyewa pemanggil*
- **Cara membuktikan perbaikan:** tambahkan `if v_penyewa <> public.penyewa_saya() then return query select false, null, null; return; end if;`; bukti: serangan S-06 harus mengembalikan `false`/`null`
- **Status verifikasi:** TERVERIFIKASI

### [F-06] Batas **persen** diskon dilewati dengan mengosongkan kolom `persen`
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:330-333` (`public.boleh('beri_diskon', new.nilai, coalesce(new.persen, 0))`) + `supabase/migrations/0005_izin_berjenjang.sql:268-275`
- **Klaim yang dilanggar:** ROADMAP T1-05 Bukti ("batas diskon kasir 25.000/**5 persen** … ditegakkan gerbang, bukan layar") dan T1-10 Bukti ("melebihi batas izin kasir (25.000 / 5%) ditolak")
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s12_diskon_tanpa_persen.sql` → `S12_diskon_kasir_persen_NULL_berhasil: nilai=25000 ; subtotal_pesanan=54000 ; batas_izin_kasir=25000/5persen` — 25.000 dari 54.000 = **46%**, padahal `batas_persen = 5`. Pembandingnya (`s23_sisa.sql`) membuktikan batas nominal tetap bekerja: `kasir_diskon_30000_batas25000 -> DITOLAK`
- **Skenario gagal:** Karena `coalesce(new.persen, 0)`, klien cukup tidak mengirim `persen` dan seluruh batas persentase lenyap; yang tersisa hanya batas rupiah. Kasir bisa memberi diskon 25.000 pada transaksi 30.000 (83%) selama masih di bawah 25.000 rupiah
- **Dugaan penyebab:** `boleh(aksi, nominal, persen)` dirancang untuk dipanggil RPC yang menghitung persen lebih dulu; saat dipanggil langsung dari pemicu INSERT, persen adalah nilai mentah kiriman klien
- **Cara membuktikan perbaikan:** hitung persen di dalam pemicu (`round(100.0 * new.nilai / nullif(v_pesanan.subtotal,0), 2)`) dan pakai itu sebagai argumen, jangan `new.persen`; bukti: serangan S-12 harus `DITOLAK`
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Ganti PIN sendiri tanpa PIN lama, lewat `p_pengguna_id` yang diisi UUID diri sendiri
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0006_pin.sql:224-233` (`if v_target = v_saya and p_pengguna_id is null then … verifikasi PIN lama`)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §6 butir 6 ("Ganti PIN sendiri **wajib PIN lama**"); komentar fungsi `simpan_pin` di berkas yang sama baris 244
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s13c_pin_tanpa_lama.sql` → `ganti_pin('9999','2222','hp-lain')` → `HARAPAN TIDAK TERPENUHI: perintah tidak ditolak` **tidak** muncul (jadi memang ditolak ✓), lalu `S13c_PIN_DIGANTI_TANPA_PIN_LAMA: pin_lama_1111_berlaku=false ; pin_baru_2222_berlaku=true`
- **Skenario gagal:** Tablet kasir yang terbuka sebentar (atau sesi yang dibajak) cukup memanggil `simpan_pin(<PIN baru>, null, <UUID sendiri>)` — tanpa tahu PIN lama — dan pegawai asli terkunci keluar dari PIN-nya sendiri, sementara jejaknya tampak seperti penggantian PIN yang sah
- **Dugaan penyebab:** syarat verifikasi PIN lama digantungkan pada `p_pengguna_id is null` (niatnya: "jalur admin mengisi UUID orang lain"), sehingga mengisi UUID diri sendiri secara eksplisit dianggap jalur admin dan lolos dari syarat PIN lama — padahal cabang `kelola_pegawai` juga dilewati karena `v_target = v_saya`
- **Cara membuktikan perbaikan:** ganti syarat menjadi `if v_target = v_saya then …` (verifikasi PIN lama kapan pun targetnya diri sendiri, kecuali `pin_hash is null`); bukti: serangan S-13c harus menghasilkan `pin_baru_2222_berlaku=false`
- **Status verifikasi:** TERVERIFIKASI

### [F-08] Buku Insiden menyuruh memakai alat yang tidak ada, tepat di jalur pemulihan proyek Supabase yang tidur
- **Tingkat:** K-2
- **Artefak:** `docs/teknis/BUKU_INSIDEN.md:131`
- **Klaim yang dilanggar:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b butir 5 ("setiap langkah pengguna yang **tidak bisa dijalankan apa adanya** (salah rujukan, perintah tidak ada …) diperlakukan minimal **K-2**. Buku pedoman yang basi = temuan, bukan kerapian")
- **Bukti:** `sed -n '125,132p' docs/teknis/BUKU_INSIDEN.md` → "4. Nyalakan kembali 'denyut harian' (pg_cron) supaya proyek tidak tidur lagi (alat: `alat/denyut.py`)." · `ls alat/denyut.py` → `No such file or directory` · `git ls-files alat/` → 24 berkas, `denyut.py` tidak ada di antaranya
- **Skenario gagal:** Proyek Supabase gratis tidur setelah 7 hari tanpa aktivitas (risiko yang diakui `docs/KEAMANAN.md`). Pemilik non-teknis membuka Buku Insiden bab 8, mengikuti langkah 4, dan menemui alat yang tidak ada — tepat pada langkah yang mencegah kejadian terulang. Ini satu-satunya berkas di `docs/ops`/`docs/teknis` yang menjadi pegangan saat insiden
- **Dugaan penyebab:** `alat/denyut.py` adalah keluaran T10-xx yang belum dikerjakan (`docs/uji/PROTOKOL…`/paket audit mencantumkannya sebagai artefak #315), tetapi Buku Insiden sudah menulisnya sebagai alat yang tersedia, tanpa penanda `(rencana)`
- **Cara membuktikan perbaikan:** tandai `(rencana — belum ada, menyusul di T10-…)` atau tulis langkah manualnya (SQL `select cron.schedule(…)`); bukti: `python3 -c "import pathlib;print(pathlib.Path('alat/denyut.py').exists())"` selaras dengan teksnya, dan sapuan rujukan berkas pengguna (bagian 1a baris 4) menghasilkan 0 rujukan mati
- **Status verifikasi:** TERVERIFIKASI

### [F-09] Paket audit yang ter-commit menunjuk commit lain, sehingga `--verifikasi-lingkup` menyuruh auditor berhenti padahal commit-nya benar
- **Tingkat:** K-2
- **Artefak:** `docs/uji/paket-audit/AUD-3-2026-09-17.md:14` dan `…-SIAP-TEMPEL.md:50,574` (semuanya `d9de6ebf8f54e14d511ad24e61f05c589d3762b9`); alat: `alat/audit-independen.py` mode `--verifikasi-lingkup`
- **Klaim yang dilanggar:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §5b butir 2 ("**Target tidak ada** → … auditor **berhenti dan melaporkan** — bukan mengaudit commit lain") dan LANGKAH 0 paket
- **Bukti:** paket yang ditempel pemilik menargetkan `442913e4…`; `grep -n "Commit yang diaudit" docs/uji/paket-audit/AUD-3-2026-09-17*.md` → **semua** menuliskan `d9de6ebf…`; `python3 alat/audit-independen.py --verifikasi-lingkup` di commit `442913e4` → `Commit target : d9de6ebf… / Commit lokal : 442913e4… / HASIL: TARGET TIDAK ADA di repo ini setelah fetch. JANGAN mengaudit commit lain.` · `gh api …/compare/442913e4…d9de6ebf` → `{"ahead_by":0,"behind_by":2,"status":"behind"}` (jadi `442913e4` **2 commit lebih baru** daripada target paket ter-commit)
- **Skenario gagal:** Auditor yang taat protokol menjalankan LANGKAH 0, melihat "JANGAN mengaudit commit lain", dan menghentikan audit — atau mengaudit `d9de6ebf` yang lebih tua. Keduanya menghasilkan audit yang tidak sesuai keadaan terkini, dan mekanisme "independen terhadap base branch" yang justru dibuat untuk memudahkan Lee malah menutup pintu
- **Dugaan penyebab:** paket di-generate saat HEAD = `d9de6ebf`, lalu di-commit pada commit berikutnya **tanpa di-generate ulang**; salinan yang ditempel pemilik adalah hasil generate yang lebih baru dan tidak pernah di-commit
- **Cara membuktikan perbaikan:** generate ulang paket pada commit yang akan diaudit dan commit berkasnya dalam commit yang sama; atau terima SHA target sebagai argumen (`--verifikasi-lingkup <sha>`). Bukti: `python3 alat/audit-independen.py --verifikasi-lingkup` di commit target → `COCOK`
- **Status verifikasi:** TERVERIFIKASI

### [F-10] `pin_hash` bisa dibaca klien lewat SELECT biasa (diri sendiri, dan seluruh pegawai oleh owner/admin cabang)
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql:24` (kolom `pin_hash` di tabel `pengguna`) + `supabase/migrations/0004_pola_rls.sql:45-58` (policy `pengguna_pilih`, tanpa pembatasan kolom)
- **Klaim yang dilanggar:** semangat `docs/KEAMANAN.md` §6 butir 3 ("Tidak ada fungsi yang mengembalikan hash") dan butir 1–2 (PIN tidak pernah meninggalkan database dalam bentuk apa pun)
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s08b_pin_hash.sql` → `S08b_pin_hash_diri_sendiri=$tiruan$10$08f0a2219…`; `node alat/uji-sql.mjs /tmp/serang/s08c_pin_hash_owner.sql` → `S08c_jumlah_pegawai_yang_pin_hash_nya_terbaca_owner=1 ; contoh_hash=$tiruan$10$cc51436a8…`
- **Skenario gagal:** Setiap `select * from pengguna` yang dikirim PostgREST ke layar "Kelola Pegawai" membawa hash PIN semua pegawai ke perangkat. PIN staf 4–6 angka (regex `^\d{4,6}$` di `0006_pin.sql:208`) bisa dipecahkan offline dalam hitungan detik. Dampak terbatas karena owner/admin memang bisa mereset PIN lewat `kelola_pegawai`, tetapi hash tidak perlu pernah keluar dari database
- **Dugaan penyebab:** hash ditaruh di tabel yang sama dengan data profil pegawai, tanpa view penutup atau `revoke select (pin_hash)`
- **Cara membuktikan perbaikan:** pisahkan ke tabel `pengguna_pin` (RLS: tidak ada policy SELECT untuk `authenticated`) atau buat view tanpa kolom itu untuk klien; bukti: `select pin_hash from public.pengguna` sebagai `authenticated` → `permission denied`
- **Status verifikasi:** TERVERIFIKASI

### [F-11] Lapis kedua pembatasan PIN (12×/perangkat) tidak berlaku karena nama perangkat kiriman klien
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0006_pin.sql:277-282` (`p_perangkat text default 'tidak-diketahui'` dipakai apa adanya sebagai kunci penghitung)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §4 ("PIN ditebak (batas 5×/15 menit per akun & **12×/15 menit per perangkat**)") dan ROADMAP T1-06 Bukti ("**dua lapis** … supaya menebak PIN dari satu HP tidak bisa jalan")
- **Bukti:** `node alat/uji-sql.mjs /tmp/serang/s14b_perangkat_palsu.sql` → `S14b_15_percobaan_salah_perangkat_selalu_baru: terkunci=10 / masih_dilayani="PIN salah."=5`. Yang menahan adalah lapis **akun** (5), bukan lapis perangkat
- **Skenario gagal:** Penyerang yang mengontrol klien mengganti `p_perangkat` setiap percobaan sehingga lapis per-perangkat tidak pernah terkumpul. Sisa pertahanannya 5 percobaan/15 menit per akun = ±480/hari; untuk PIN 6 angka masih aman, untuk PIN 4 angka (yang diizinkan regex) ±21 hari kerja tanpa alarm. Kejujuran: lapis akun **bekerja**, jadi ini kelemahan lapis kedua, bukan pintu terbuka
- **Dugaan penyebab:** identitas perangkat dipercaya dari klien; tidak ada penanda perangkat yang ditandatangani/tidak bisa dipalsukan (T1-24 `perangkat` belum dikerjakan)
- **Cara membuktikan perbaikan:** ambil identitas perangkat dari `perangkat_id` yang terverifikasi (Fase 1B) dan tolak percobaan tanpa perangkat terdaftar; bukti: serangan S-14b harus `terkunci=15`
- **Status verifikasi:** TERVERIFIKASI

### [F-12] Penjaga buku induk membiarkan dua alur dihapus tanpa ketahuan, dan tidak punya uji-diri
- **Tingkat:** K-3
- **Artefak:** `alat/periksa-panduan.py:38` (`MIN_ALUR = 10`) dengan isi nyata 12 alur; `.github/workflows/ci.yml` (tidak ada langkah uji-diri untuk pemeriksa ini, berbeda dari `audit-independen.py --uji-diri` dan `review-pr.py --uji-diri`)
- **Klaim yang dilanggar:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b ("Penjaga mekanisme ini: `alat/periksa-panduan.py` … memastikan buku induk tetap lengkap") dan §8 ("Pemeriksa ini **sendiri diuji** … kalau pemeriksa tidak bisa MERAH, mekanismenya dianggap belum terpasang")
- **Bukti:** farm salinan di `/tmp/mp` (baseline `HASIL: LOLOS`) → mutasi hapus `### AL-9 — Masalah mendesak (insiden)` (983 huruf) → `PERIKSA … 636 baris · **11 alur** … HASIL: LOLOS`. Tiga mutasi lain (rujukan mati, prompt C1 diubah, buku dipotong 100 baris) **MERAH** → pemeriksa tidak tumpul total, hanya ambangnya longgar
- **Skenario gagal:** Alur insiden (AL-9) — persis alur yang dipakai saat ada masalah — bisa terhapus saat merapikan dokumen dan CI tetap hijau. Karena tidak ada `--uji-diri`, kelonggaran ini tidak pernah terdeteksi
- **Dugaan penyebab:** ambang ditulis di bawah jumlah nyata sebagai "ruang tumbuh" dan tidak pernah dikunci ke jumlah sebenarnya
- **Cara membuktikan perbaikan:** naikkan `MIN_ALUR` ke jumlah nyata (12) dan/atau wajibkan daftar ID alur yang diharuskan ada; tambahkan `--uji-diri` ke CI. Bukti: mutasi hapus satu alur → `GAGAL`
- **Status verifikasi:** TERVERIFIKASI

### [F-13] Klaim Bukti T0-01 "31 berkas huruf pindah" tidak bisa direproduksi
- **Tingkat:** K-3
- **Artefak:** `docs/ROADMAP.md:62` (baris **Bukti 2026-09-16** T0-01)
- **Klaim yang dilanggar:** lensa L3 ("Setiap klaim 'Bukti' di ROADMAP bisa direproduksi hari ini?"); catatan ROADMAP sendiri baris 1818 ("jumlah … **tidak boleh** ditulis dari ingatan — ambil dari hasil pemeriksa")
- **Bukti:** `find aplikasi -name '*.woff2' \| wc -l` → **19**; `find . -name '*.woff2' -not -path './skills/*' \| wc -l` → **38** (19 aplikasi + 19 prototipe); `python3 aplikasi/alat/uji-kontras.py` → `Semua huruf tema tersedia tanpa internet [13 keluarga huruf tersimpan (woff2)]`; `STATUS.md` menulis "13 keluarga, **19 berkas**, 504 KB"
- **Skenario gagal:** Angka pada kolom Bukti adalah bahan yang dipakai auditor berikutnya dan pemilik untuk percaya tanpa memeriksa. Satu angka yang salah di sana melatih semua orang untuk tidak memeriksa angka lain
- **Dugaan penyebab:** angka ditulis dari ingatan saat tugas ditutup (31 mungkin gabungan woff2 + lisensi pada keadaan folder sementara)
- **Cara membuktikan perbaikan:** ganti dengan keluaran pemeriksa (`19 berkas woff2 / 13 keluarga`); bukti: `find aplikasi -name '*.woff2' \| wc -l` sama dengan angka di ROADMAP
- **Status verifikasi:** TERVERIFIKASI

### [F-14] Sapuan anti-bocor lintas resto hanya mencakup tabel ber-`penyewa_id`, dan pemeriksaan policy memakai pencocokan teks
- **Tingkat:** K-3
- **Artefak:** `supabase/tes/rls_semua_tabel.sql:79-92` (blok `for r in … and exists (… column_name = 'penyewa_id')`) dan `:48-56` (`pg_get_expr(...) like '%penyewa_saya%'`)
- **Klaim yang dilanggar:** ROADMAP T1-04 Bukti ("uji ini membaca katalog PostgreSQL … plus **pemindaian pembocoran**") — pemindaian itu tidak menjangkau tabel uang
- **Bukti:** `cat supabase/tes/rls_semua_tabel.sql` → syarat sapuan pembocoran adalah `where … column_name = 'penyewa_id'`. Daftar katalog repo sendiri (`node alat/uji-sql.mjs --daftar`, keluaran apa adanya) menunjukkan **12 dari 23 tabel** tidak punya kolom itu dan karena itu **tidak ikut tersapu**: `diskon_transaksi`, `izin`, `izin_kode`, `meja`, `menu_cabang`, `menu_varian`, `pembatalan`, `pembayaran`, `pengguna_cabang`, `penyewa`, `percobaan_pin`, `pesanan_item` (semuanya tercetak `penyewa_id=tidak`). Yang tersapu hanya 11: `cabang`, `izin_peran`, `kategori_menu`, `menu_item`, `menu_tambahan`, `metode_bayar`, `pengaturan`, `pengguna`, `pesanan`, `stok_bahan`, `stok_pergerakan`
- **Skenario gagal:** Kebijakan `pesanan_item`/`pembayaran` bergantung pada fungsi perantara (`pesanan_sepenyewa`). Kalau suatu hari fungsi itu kehilangan saringan cabang/penyewa, tidak ada satu pun uji menyeluruh yang menyalak — hanya uji per-fitur yang kebetulan menutup jalur itu. (Catatan kejujuran: hari ini jalurnya **tertutup**, dibuktikan serangan S-20; yang lemah adalah jaringnya, bukan pagarnya.) Bagian `like '%penyewa_saya%'` juga puas dengan penyebutan di cabang `OR` mana pun
- **Dugaan penyebab:** sapuan ditulis untuk tabel ber-`penyewa_id` karena itulah pola termudah dibaca dari katalog
- **Cara membuktikan perbaikan:** perluas sapuan ke tabel tanpa `penyewa_id` dengan mengikuti kunci asing induknya, dan ganti pencocokan teks dengan pemeriksaan bahwa `penyewa_saya()` muncul di **setiap** policy yang relevan; bukti: mutasi sementara menghapus `cabang_pantau_saya` dari `pesanan_sepenyewa` → `supabase/tes/rls_semua_tabel.sql` harus GAGAL
- **Status verifikasi:** TERVERIFIKASI

### [F-15] `docs/SPESIFIKASI_UI.md` menyebut pemeriksa `alat/peta-ui.py` di CI sebagai penutup akar masalah, padahal berkas & langkah CI-nya belum ada
- **Tingkat:** K-3
- **Artefak:** `docs/SPESIFIKASI_UI.md:22` ("| 6 | Dokumen & kode bisa saling tinggal (drift) | **Pemeriksa `alat/peta-ui.py`** di CI (§5) |"), `:79`, `:97`
- **Klaim yang dilanggar:** kejujuran dokumen berstatus "BERLAKU sejak 2026-09-17"; lensa L3 (janji punya kode **dan** uji)
- **Bukti:** `ls alat/peta-ui.py` → tidak ada (`git ls-files alat/` → 24 berkas, tanpa `peta-ui.py`); `grep -n "peta-ui" .github/workflows/ci.yml` → **tidak ada kecocokan**; `python3 alat/periksa-panduan.py` → `[catatan] rujukan berkas yang belum ada (ditandai rencana): alat/peta-ui.py`; `docs/PETA_UI.md` juga belum ada. Baris `:181` memang menulis "(Fase 1C)", tetapi baris `:22` (tabel akar masalah) menyajikannya sebagai penutup yang sudah ada
- **Skenario gagal:** Pembaca (termasuk agent sesi berikutnya) menyimpulkan drift UI sudah dijaga CI, sehingga menunda pekerjaan T1-39 dengan rasa aman yang palsu — persis keluhan Lee yang dokumen ini dibuat untuk menutupnya ("fungsi yang katanya ada tapi ga bisa dipake")
- **Dugaan penyebab:** dokumen spesifikasi ditulis lebih dulu dari implementasinya (sengaja), tanpa penanda `(rencana)` yang konsisten di semua penyebutan
- **Cara membuktikan perbaikan:** tandai `(rencana — T1-39)` di baris 22/79/97, atau hadirkan berkasnya + langkah CI; bukti: `python3 alat/peta-ui.py` ada dan `grep -c peta-ui .github/workflows/ci.yml` ≥ 1
- **Status verifikasi:** TERVERIFIKASI

### [F-16] Tabel lingkup paket audit tidak menutup seluruh berkasnya sendiri (333 dari 334), dan angka satu grupnya meleset
- **Tingkat:** K-4
- **Artefak:** `docs/uji/paket-audit/AUD-3-2026-09-17.md:69` (baris `_sistem` … **16**) dan tabel lingkup 17 grup di bagian 1 paket
- **Klaim yang dilanggar:** tujuan tabel lingkup itu sendiri — menjadi daftar periksa cakupan auditor ("setiap grup wajib punya baris bukti"); lensa L4 (gerbang yang tidak menutup kasus nyata)
- **Bukti:** `git ls-tree -r --name-only HEAD | grep -v '^skills/' | grep -v '^_salinan-meta/' | grep -v '^_Notes.md' | wc -l` → `334`; pemetaan setiap berkas ke 17 predikat grup → `tertutup grup : 333`, `TIDAK TERTUTUP: ['supabase/README.md']`. Secara terpisah, `git ls-tree -r --name-only HEAD | grep -c '^_sistem/'` → **15**, padahal paket baris 69 menulis **16**
- **Skenario gagal:** Auditor menyeluruh yang patuh menulis satu baris bukti per grup (seperti yang dituntut pemeriksa laporan) akan memeriksa 333 berkas dan melaporkan 333/334 = 99,7% — di bawah ambang 90%? tidak, tetapi ia kehilangan `supabase/README.md`: satu-satunya dokumen yang menjelaskan cara menjalankan seluruh gerbang SQL. Saya sendiri baru menemukannya saat memverifikasi ulang laporan ini
- **Dugaan penyebab:** tabel lingkup di-generate dengan daftar pola folder yang tidak menyertakan berkas lepas di akar `supabase/`, dan angka per-grup tidak dihitung ulang dari pohon git saat paket di-commit
- **Cara membuktikan perbaikan:** generate tabel lingkup dari `git ls-files` nyata dan tambahkan asersi `sum(per-grup) == total`; bukti: pemetaan ulang harus menghasilkan `TIDAK TERTUTUP: []`
- **Status verifikasi:** TERVERIFIKASI

### [F-17] Commit yang diaudit tidak pernah dilewatkan CI — tidak ada satu pun run untuknya
- **Tingkat:** K-3
- **Artefak:** `.github/workflows/ci.yml` (pemicu `push`/`pull_request`) + riwayat Actions repo
- **Klaim yang dilanggar:** makna "CI hijau" sebagai bukti; lensa L4 ("setiap gerbang benar-benar dijalankan pada keadaan yang diserahkan"); T0-07 ("CI menyala di setiap push & pull request")
- **Bukti:** `gh run list --repo With-AI-Agent/Resto-Barokah --limit 200 --json databaseId,conclusion,headSha,headBranch` → **67 run, semuanya di cabang `arena/01a0a8a2-resto-barokah`** (`Counter({'success': 51, 'cancelled': 8, 'failure': 8})`; `Counter({'arena/01a0a8a2-resto-barokah': 67})`). Penyaringan `headSha`: commit yang saya audit `442913e4…` → **0 run**; target paket ter-commit `d9de6ebf…` → **0 run**
- **Skenario gagal:** Paket audit menyerahkan commit yang tidak pernah diperiksa CI. Semua bukti "gerbang hijau" yang bisa dirujuk hanya berlaku untuk commit lain di cabang lain; kalau commit ini di-merge lalu rusak, tidak ada riwayat yang menunjukkan kapan rusaknya. Ini juga yang membuat F-09 berbahaya: auditor diarahkan ke `d9de6ebf` yang sama-sama tanpa bukti CI
- **Dugaan penyebab:** workflow terpicu pada cabang kerja saja (push/PR dari cabang itu), dan commit paket/kalibrasi dibuat di jalur yang tidak memicu run — atau riwayat run untuk commit itu sudah di luar jendela yang bisa diambil. Saya tidak bisa membedakan keduanya dari data yang tersedia
- **Cara membuktikan perbaikan:** pastikan paket audit di-commit pada commit yang punya run CI hijau, dan cantumkan `run_id` di kepala paket; bukti: `gh run list --json headSha | grep 442913e4` menghasilkan satu run ber-`conclusion: success`
- **Status verifikasi:** TERVERIFIKASI

---

## 5. Kalibrasi cacat tanaman

Bahan: `docs/uji/kalibrasi/bahan-2026-09-17/` (5 berkas). Saya tidak diberi tahu jumlah, lokasi, atau kelasnya.
Kunci jawaban **tidak saya cari** — saya hanya membaca 5 berkas bahan itu, membandingkannya dengan kode/dokumen nyata
di repo, dan menjalankan pemeriksanya. Tidak ada berkas di luar repo yang saya buka untuk keperluan ini.

**Ditemukan: 14 dari 14** (Y = 14 adalah jumlah cacat yang **saya yakini ada** setelah membaca ulang; angka ini penilaian saya, bukan kunci)

| # | Berkas | Kelas | Cacat & bukti |
|---|---|---|---|
| 1 | `01_gerbang_izin.sql` | K-1 | **`revoke all … from public` tidak pernah dijalankan**, padahal komentarnya sendiri menulis "hak execute dicabut dari public". Berkas hanya memuat `grant execute … to authenticated`. Fungsi SECURITY DEFINER di skema `public` dengan hak default PUBLIC = bisa dipanggil `anon` — persis jebakan yang disebut `skills/supabase/SKILL.md:67` dan dilarang `docs/KEAMANAN.md` §7 butir 3 |
| 2 | `01_gerbang_izin.sql` | K-2 | Gerbangnya **tidak bisa jalan**: `public.izin_efektif(p.id, p_aksi, p_cabang)` dipanggil dengan 3 argumen `(uuid, text, uuid)`, padahal tanda tangan nyata `izin_efektif(p_aksi text, p_cabang_id uuid)` (`0005_izin_berjenjang.sql:151`); yang ber-3-argumen adalah `izin_efektif_untuk`. Hasilnya juga `TABLE(boleh, batas_nominal, batas_persen)`, dipakai sebagai boolean di `and …` |
| 3 | `01_gerbang_izin.sql` | K-3 | `set search_path = public` — **tanpa `pg_temp`**. Seluruh 39 fungsi SECURITY DEFINER repo nyata memakai `public, pg_temp` (probe katalog S-1); tanpa `pg_temp` objek skema sementara bisa membayangi |
| 4 | `01_gerbang_izin.sql` | K-3 | Gerbang kehilangan pemeriksaan batas: `boleh(aksi, nominal[, persen])` di repo nyata memeriksa `batas_nominal`/`batas_persen`; versi bahan hanya `exists(…)` tanpa batas |
| 5 | `02_policy_pengaturan.sql` | K-1 | `create policy pengaturan_pilih … using (penyewa_id is not null)` → **setiap** pengguna yang masuk membaca pengaturan **semua** resto (pajak, service, header struk). Versi nyata `0004_pola_rls.sql:76-78`: `using (penyewa_id = public.penyewa_saya())` |
| 6 | `02_policy_pengaturan.sql` | K-2 | `pengaturan_ubah` **kehilangan syarat peran** `public.peran_saya() = 'owner_pusat'` pada `using` → kasir/pelayan bisa mengubah pajak & service charge restonya. Versi nyata `0004_pola_rls.sql:80-84` memuat syarat itu |
| 7 | `03_fungsi_terima_bayar.sql` | K-1 | Penjaga lebih-bayar membandingkan besaran yang salah: `if v_sebelum > v_pesanan.total` — seharusnya `v_sebelum + p_jumlah > v_pesanan.total`. Satu panggilan bisa melewati total berapa pun. Kontras dengan `0010_pembayaran.sql:294` (`v_sebelum := total_dibayar(...) + new.jumlah; if v_sebelum > v_pesanan.total`) |
| 8 | `03_fungsi_terima_bayar.sql` | K-2 | SECURITY DEFINER tanpa pemeriksaan penyewa/cabang maupun `boleh(...)`: `p_pesanan` UUID bebas, lalu `insert into pembayaran` + `update pesanan set status='lunas'` sebagai pemilik tabel — lintas resto dan tanpa izin |
| 9 | `03_fungsi_terima_bayar.sql` | K-3 | `set search_path = public` tanpa `pg_temp` (sama seperti #3) |
| 10 | `03_fungsi_terima_bayar.sql` | K-3 | Tidak cocok skema nyata: kolom `metode`/`dibuat_oleh` tidak ada di `pembayaran` (yang ada `metode_nama_saat_itu`, `jenis_saat_itu`, `kasir_id`, `kunci_idempoten` NOT NULL) — `insert`-nya pasti gagal; `p_jumlah bigint` vs kolom `jumlah integer` |
| 11 | `04_panduan_singkat.md` | K-2 | **Perintah tidak bisa dijalankan apa adanya:** `bash aplikasi/pratinjau.sh` — berkasnya `aplikasi/alat/pratinjau.sh` (`find . -name pratinjau.sh` → `./aplikasi/alat/pratinjau.sh`). Protokol §2b butir 5 menetapkan langkah pengguna yang tidak bisa dijalankan = minimal K-2 |
| 12 | `04_panduan_singkat.md` | K-2 | `python3 alat/periksa-struktur.py` — berkasnya `aplikasi/alat/periksa-struktur.py`. Dan rujukan mati: "Kebijakan lengkap ada di `docs/PANDUAN_KEAMANAN.md` §4" — `ls docs/PANDUAN_KEAMANAN.md` → tidak ada; yang ada `docs/KEAMANAN.md` |
| 13 | `04_panduan_singkat.md` | K-2 | Angka kebijakan keamanan salah di dokumen pengguna: "Salah PIN **10 kali** … terkunci 15 menit" — kode nyata `BATAS_AKUN := 5` dan `BATAS_PERANGKAT := 12` (`0006_pin.sql:268-270`), `docs/KEAMANAN.md` §4 menulis "5×/15 menit per akun & 12×/15 menit per perangkat". Ditambah "PIN wajib 6 angka" padahal regex-nya `^\d{4,6}$` |
| 14 | `05_pemeriksa_ambang.py` | K-2 | **Pemeriksa tumpul (selalu hijau), tiga sebab bertumpuk:** (a) `MIN_LAYAR_DIPERIKSA = 5  # ambang nyata proyek: 20` — komentar mengakui ambang sesungguhnya 20, sehingga di bawah 5 layar pemeriksa `return 0` tanpa memeriksa apa pun; (b) `glob("*.tsx")` **tidak rekursif** padahal layar nyata berada di subfolder (`aplikasi/src/layar/contoh/LayarContoh.tsx`; `ls aplikasi/src/layar/*.tsx` → tidak ada), jadi `len(layar) = 0` → selalu SKIP; (c) `kurang` dihitung sebelum pemeriksaan ambang lalu dibuang, dan pencocokannya (`f'"{keadaan}"' not in teks`) puas dengan kata berperisai apa pun di berkas |

**Temuan palsu: 0.** Tiga hal yang sempat saya curigai sebagai cacat tanaman **tidak** saya laporkan setelah diuji:
(i) `02_policy_pengaturan.sql` mengulang `alter table … enable row level security` — idempoten, bukan cacat;
(ii) `03_fungsi_terima_bayar.sql` memakai `>= v_pesanan.total` untuk menandai `lunas` — itu justru benar (pembayaran pas);
(iii) `04_panduan_singkat.md` menulis `http://localhost:5173` — memang port bawaan Vite 6 (`npm run dev` saya jalankan di 5199 hanya karena saya memindahkannya), jadi bukan cacat.

---

## 6. Yang tidak bisa saya verifikasi

- **Model yang saya pakai.** Platform tidak mengungkapkan identitas model kepada saya, jadi syarat "model berbeda" (§3 butir 2) tidak bisa saya buktikan. Yang bisa saya buktikan: sesi ini terpisah dari sesi pembangun, dan saya tidak punya konteks apa pun selain repo + paket yang ditempel.
- **Riwayat GitHub Actions — SUDAH TERTUTUP, bukan lagi keterbatasan.** Saya sempat menulis ini sebagai tidak bisa diverifikasi; ternyata `gh` punya akses. Hasilnya: 67 run, semuanya di cabang `arena/01a0a8a2-resto-barokah` (51 success · 8 cancelled · 8 failure); ketiga run yang diklaim T0-07 nyata ada dan **benar** merahnya (35121292973 gagal di langkah "Aturan kode (ESLint)"). Yang muncul dari penutupan celah ini justru temuan baru: commit yang diaudit **tidak punya run sama sekali** → F-17.
- **Deno dan peramban benar-benar tidak ada di ruang kerja ini** (saya periksa, bukan menduga): `command -v deno` → kosong; `chromium`/`chromium-browser`/`google-chrome` → tidak ada; `aplikasi/node_modules` tidak memuat `playwright`/`puppeteer`. Jadi dua butir keterbatasan di bawah bersifat mutlak, bukan karena saya melewatkannya.
- **Perilaku Supabase/Cloudflare nyata.** Seluruh pengujian SQL berjalan di PGlite (PostgreSQL WASM) dengan `crypt`/`gen_salt` **tiruan** yang dipasang `alat/uji-sql.mjs` (`$tiruan$…`, SHA-256 berulang — berkasnya sendiri menyatakan "BUKAN pengganti produksi"). Jadi: kekuatan bcrypt asli, `auth.uid()`/`auth.jwt()` yang diterbitkan Supabase sungguhan, default privileges & Data API PostgREST, serta `pg_cron` **tidak** teruji di sini. Kesimpulan saya tentang RLS/`SECURITY DEFINER`/`search_path` bersandar pada `skills/supabase/SKILL.md` baris 45–67 (https://supabase.com/docs/guides/api/securing-your-api.md dan https://supabase.com/docs/guides/database/postgres/row-level-security) dan `skills/supabase-postgres-best-practices/SKILL.md` kategori `security-`, bukan pada pengujian di proyek Supabase hidup.
- **Runtime Edge Function (Deno).** `verifikasi_pin` hanya diuji **statis** (`alat/periksa-fungsi-pin.py`, 9 lolos). Tidak ada Deno di ruang kerja ini, jadi perilaku `Deno.serve`, penerusan header `Authorization`, dan jawaban 405 tidak saya jalankan. Ini memang sudah dicatat terbuka oleh pembangun di ROADMAP/DECISIONS_LOG.
- **Tampilan di peramban sungguhan.** Saya membuktikan server dev melayani `/`, `main.tsx`, `tema.css`, woff2, favicon (semua HTTP 200) dan 166 pemeriksaan kontras/aturan desain lolos, tetapi saya **tidak** merender halaman di peramban: tidak ada penilaian visual, tidak ada pengukuran nyata target sentuh, tidak ada uji pembaca layar, tidak ada uji 7 keadaan pada layar nyata (layar aplikasi memang baru `LayarContoh`).
- **Printer, offline queue, voucher, laporan.** Seluruh artefak itu (daftar artefak paket #226–#346) belum ada di commit ini (`aplikasi/src/lib/supabase.ts`, `alat/peta-ui.py`, `supabase/seed.sql`, `docs/uji/audit/LAPORAN_*`, `docs/ops/{DEPLOY,PANDUAN_PEGAWAI,…}.md` → tidak ada). Tidak ada yang bisa diuji; saya tidak menyimpulkan apa pun tentangnya.
- **Selisih 1 berkas pada tabel lingkup paket — SUDAH DITETAPKAN, jadi temuan F-16.** Berkas ke-334 adalah `supabase/README.md`, yang tidak masuk grup mana pun pada tabel paket (dibuktikan `TIDAK TERTUTUP: ['supabase/README.md']`). Berkas itu sudah saya periksa penuh (baris 18 tabel cakupan); keempat klaim yang bisa diuji terbukti benar.
- **Kerentanan rantai pasok (`npm audit`) — saya laporkan datanya, tetapi TIDAK saya hitung sebagai temuan.** `npm audit --json` di `aplikasi/` → `{'moderate': 3, 'high': 1, 'critical': 1, 'total': 5}`, yaitu `vitest@2.1.9` (critical), `vite@6.4.3` (high), `@vitest/mocker@2.1.9`, `esbuild@0.25.12`, `vite-node@2.1.9` (moderate). Dua alasan tidak menjadikannya temuan: (1) `package-lock.json` menandai kelimanya `dev=True`, dan `dependencies` proyek hanya `react`/`react-dom` — jadi tidak ada yang ikut terkirim ke pengguna; (2) versi terpasang `vite` (6.4.3) dan `esbuild` (0.25.12) sudah **di atas** rentang advisori yang npm cetak (`<=6.4.2`, `<=0.24.2`), jadi laporan itu didorong rantai `vitest` 2.x, bukan oleh versi yang benar-benar rentan di pohon ini. Perbaikannya pun pemutusan versi (`npm audit fix --force` → `vitest@5.0.1`), yaitu keputusan pembangun, bukan cacat.
- **Sisa yang benar-benar tidak bisa saya jalankan di sini:** perilaku Supabase/Cloudflare nyata (bcrypt asli, JWT sungguhan, PostgREST, `pg_cron`), runtime Deno untuk Edge Function, dan perenderan di peramban — perinciannya di butir-butir di bawah.
- **Jumlah cacat tanaman (Y).** "14 dari 14" memakai Y = penilaian saya sendiri. Bila kunci di luar repo menyebut lebih banyak, tingkat deteksi saya lebih rendah dari yang saya klaim — itu harus dinilai pembangun, bukan saya.
- **Pemasangan pustaka.** Untuk menjalankan gerbang saya memasang dependensi yang memang dinyatakan repo: `npm ci` di `aplikasi/` (282 paket) dan `npm ci --prefix alat` (1 paket, `@electric-sql/pglite`) — persis langkah CI. Keduanya hanya membuat `node_modules/` yang di-`.gitignore`; tidak ada berkas terlacak yang berubah (`git status --short` kosong). Paket audit menyarankan auditor tidak memasang apa pun; saya memilih memasang karena tanpa itu uji SQL dan vitest tidak bisa dijalankan sama sekali, dan saya laporkan di sini.

---

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan **tidak mengubah** berkas apa pun di repo yang diaudit: tidak ada berkas terlacak yang disunting,
ditambah, dihapus, atau dipindahkan; tidak ada commit, tidak ada push, tidak ada perpindahan cabang.
Seluruh berkas serangan saya tulis di luar repo (`/tmp/serang/*.sql`, `/tmp/mp/`, `/tmp/cakupan.txt`) dan dijalankan
lewat runner repo yang memang menerima jalur absolut, sehingga repo tetap bersih.

Bukti:

```
$ git -C /home/user/audit-target rev-parse HEAD
442913e4b7ae6d09ed060fe17dd90fa499d449b3
$ git -C /home/user/audit-target status --short
(kosong)
```

Satu-satunya berkas baru adalah **laporan ini**, yang memang keluaran wajib audit (§6). Karena itu laporan divalidasi
lebih dulu dari lokasi di luar repo (`python3 alat/audit-independen.py --periksa-laporan /tmp/…/LAPORAN_….md`)
pada saat `git status --short` masih benar-benar kosong, baru kemudian disalin ke `docs/uji/audit/` untuk diserahkan.