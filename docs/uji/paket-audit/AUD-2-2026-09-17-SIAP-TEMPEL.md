> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat/percakapan BARU (idealnya model berbeda).
> Dibuat mesin oleh `alat/audit-independen.py`; kalimat pembuka diambil apa adanya dari sumber kanonik.

===== MULAI SALIN DARI SINI =====

Kamu adalah AUDITOR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis kode ini dan kamu
TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu menemukan masalah,
bukan menyenangkan pembuatnya.

Kerjakan berurutan:
1. Baca `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (aturan main), lalu paket audit yang saya tempel di bawah.
2. Muat skill yang disebut paket: `skills/security-review/SKILL.md`, `skills/verification-before-completion/SKILL.md`,
   `skills/systematic-debugging/SKILL.md`, `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`,
   `skills/prd-taskmaster/SKILL.md`, `skills/supabase/SKILL.md`, `skills/supabase-postgres-best-practices/SKILL.md`,
   dan `skills/ui-ux-pro-max/SKILL.md` bila menyentuh tampilan. Bila butuh skill lain, gunakan `skills/find-skills`
   atau `skills/agent-skills-hub`.
3. Kerjakan SEMUA lensa yang diminta paket. Untuk tiap lensa tulis: apa yang kamu periksa, perintah yang kamu jalankan,
   dan HASIL NYATA (tempel keluaran penting, bukan ringkasan keyakinan).
4. Bantah klaim pembangun di paket — jangan mempercayainya. Kalau perintah bukti tidak bisa dijalankan
   (mis. pustaka belum dipasang), tulis di bagian "Yang tidak bisa saya verifikasi", jangan menebak.
5. Setiap calon temuan: uji ulang di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah). Tidak bisa
   dibuktikan → tandai DUGAAN. Bisa dibuktikan → TERVERIFIKASI + sertakan perintahnya.
6. Kamu boleh (dan dianjurkan) mencari referensi internet untuk perilaku Supabase/PostgreSQL/OWASP; cantumkan tautannya.
7. Tulis laporan dengan format PERSIS seperti di paket (bagian "6. Format laporan") ke
   `docs/uji/audit/LAPORAN_<TINGKAT>_<tanggal>_<lingkup>.md`.
8. Jalankan `python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/<berkas-laporan>.md` sampai LOLOS,
   lalu laporkan verdict + ringkasan temuan ke saya.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas,
mempercayai klaim tanpa membuktikannya, dan menaikkan verdict di atas bukti yang kamu punya.

Paket audit:
<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>

===== SAMBUNGAN: PAKET AUDIT =====

# PAKET AUDIT INDEPENDEN — AUD-2 — 2026-09-17

> Dibuat mesin oleh `alat/audit-independen.py`. Berkas ini **untuk auditor** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`.

> **CARA PAKAI — untuk pemilik (3 langkah, mudah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas ini** ke chat baru itu.
> 3. Susulkan **kalimat pembuka auditor** dari buku induk `PANDUAN_PENGGUNA.md` **Bagian D1** (sama persis dengan
>    `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B) — satu blok, apa adanya, tidak perlu diubah.
> Setelah auditor selesai, kembali ke sesi kerja dan bilang: **"Laporan audit sudah masuk, periksa."**

- **Tingkat audit:** AUD-2
- **Commit yang diaudit:** `8d0f72410098080b4833193605f15db70f7d0dfd` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Tugas dalam lingkup:** T1-01, T1-02, T1-03, T1-04, T1-05, T1-06, T1-07, T1-08, T1-09, T1-10
- **Lensa wajib:** L1, L3, L4
- **Mode cakupan:** menyeluruh
- **Minimum laporan:** ≥17 artefak diperiksa · ≥5 klaim dibantah · ≥5 serangan dijalankan · masing-masing temuan punya perintah bukti
- **Perintah validasi laporan (wajib hijau):** periksa dengan alat `alat/audit-independen.py --periksa-laporan` (berkas laporan ditulis di folder docs/uji/audit/). Bila repo yang kamu pakai adalah klon dangkal, alat akan memberi CATATAN (bukan menolak) untuk SHA yang riwayatnya tidak ada.

## ATURAN INDEPENDENSI (tidak bisa ditawar)

1. Kamu **hanya-baca**: dilarang mengubah/memperbaiki berkas apa pun (temuan ditulis, bukan dibetulkan).
2. Tugasmu **membantah** klaim pembangun di bawah — bukan mempercayainya.
3. Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan.
4. Setiap calon temuan wajib kamu **uji ulang** di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah).
   Tidak bisa dibuktikan → tandai **DUGAAN**, bukan TERVERIFIKASI.
5. Istilah tingkat: **K-1** = uang salah/data bocor/tak bisa dipulihkan; **K-2** = janji PRD/ART/KEAMANAN dilanggar atau kontrol wajib hilang;
   **K-3** = tidak konsisten / uji kurang / dokumen basi; **K-4** = kerapian, tidak menghambat.
6. Verdict: `BERSIH` / `BERSIH-DENGAN-CATATAN` / `TIDAK-BERSIH`. **Ada K-1/K-2 TERVERIFIKASI → verdict wajib TIDAK-BERSIH.**


## 0. LINGKUP MENYELURUH (wajib — audit ini memeriksa SEMUA berkas proyek)

- **Jumlah berkas dalam lingkup:** 320
- **Mode cakupan yang wajib kamu tulis di laporan:** `menyeluruh`

**Grup berkas yang wajib kamu sentuh (minimal satu baris bukti per grup):**

| Grup | Isi | Jumlah berkas | Contoh |
|---|---|---|---|
| aplikasi/src | kode aplikasi (layar, komponen, lib, uji) | 67 | `aplikasi/src/App.tsx`, `aplikasi/src/gaya/aset/font/LISENSI-ArsenalSC.txt` … |
| aplikasi/alat | perkakas pemeriksa aplikasi | 6 | `aplikasi/alat/periksa-komponen-env.py`, `aplikasi/alat/periksa-semua.sh` … |
| aplikasi (konfigurasi) | package.json, tsconfig, vite, index.html | 16 | `aplikasi/.env.example`, `aplikasi/.gitignore` … |
| supabase/migrations | migrasi database | 11 | `supabase/migrations/.gitkeep`, `supabase/migrations/0001_penyewa_cabang.sql` … |
| supabase/tes | uji SQL | 11 | `supabase/tes/.gitkeep`, `supabase/tes/helper.sql` … |
| supabase/functions | Edge Functions | 2 | `supabase/functions/.gitkeep`, `supabase/functions/verifikasi_pin/index.ts` |
| alat | perkakas repo (uji SQL, pemeriksa, mekanisme audit) | 19 | `alat/audit-independen.py`, `alat/contoh-laporan/kalibrasi-penuh.md` … |
| _sistem | mesin kerja agent (validator, template) | 16 | `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md`, `_sistem/03_AUDIT_VERCEL_SKILLS.md` … |
| docs (fondasi) | PRD, TECH_SPEC, ROADMAP, KEAMANAN, SPESIFIKASI_UI, dll | 11 | `docs/AGENT_OPERATING_GUIDE.md`, `docs/DECISIONS_LOG.md` … |
| docs/uji | protokol & laporan uji/audit | 18 | `docs/uji/AUDIT_RIWAYAT.md`, `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md` … |
| docs/teknis | catatan teknis & Buku Insiden | 5 | `docs/teknis/BUKU_INSIDEN.md`, `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md` … |
| docs/ops | panduan operasional | 1 | `docs/ops/SIAP_AKUN_PEMILIK.md` |
| docs/desain | catatan desain | 59 | `docs/desain/PENILAIAN_REFERENSI.md`, `docs/desain/RENCANA_DESAIN_UI.md` … |
| prototipe | prototipe desain (acuan visual) | 58 | `prototipe/01-laporan.html`, `prototipe/02-kasir.html` … |
| _log-sesi | log sesi kerja | 3 | `_log-sesi/LOG_SESI_2026-09-15.md`, `_log-sesi/LOG_SESI_2026-09-16.md` … |
| berkas pengguna di akar | PANDUAN_*, PROMPT_*, START_DI_SINI, PROFIL_PENGGUNA, AGENT_SYSTEM, STATUS, PROJECT_STATE, dll | 16 | `.gitignore`, `10_LOG_SESI.md` … |
| .github/workflows | alur CI | 1 | `.github/workflows/ci.yml` |

**Dikecualikan dari lingkup (dan wajib kamu setujui/tolak dengan alasan):**

- `skills/` (1802 berkas) — kumpulan skill pihak ketiga (vendored) — bukan kode proyek; dipakai, tidak diubah
- `_salinan-meta/` (2 berkas) — arsip provenance sistem
- `_Notes.md` (1 berkas) — catatan pribadi pemilik (tidak ikut template)

**Kewajiban khusus mode menyeluruh (divalidasi mesin):**
1. Tulis di kepala laporan: `- **Mode cakupan:** menyeluruh`.
2. Tulis ringkasan: `Cakupan menyeluruh: X dari 320 berkas` (X = berkas yang benar-benar kamu periksa; angka ini diperiksa mesin).
3. Bagian 1 harus memuat **setiap grup** di atas minimal satu baris (dengan bukti perintah/baris).
4. Tambahkan sub-bagian `### 1a. Berkas untuk pengguna` (minimal 3 baris): berkas pengguna di akar (PANDUAN_*, PROMPT_*, START_DI_SINI, PROFIL_PENGGUNA, AGENT_SYSTEM, STATUS, PROJECT_STATE), `docs/PANDUAN_PEMILIK.md`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`,
   `docs/teknis/BUKU_INSIDEN.md`, `docs/ops/*`, dan `PANDUAN_PENGGUNA.md` → **periksa dengan cara pengguna**: apakah langkahnya bisa diikuti orang non-teknis, apakah prompt bisa disalin apa adanya dan bekerja, apakah ada langkah yang menyebut berkas/perintah yang tidak ada, apakah isi buku induk lengkap (semua mekanisme & semua prompt ada).
5. Auditor yang **tidak** memeriksa berkas untuk pengguna dianggap **belum menyeluruh** dan laporannya ditolak.

## 0b. Kalibrasi cacat tanaman (wajib untuk AUD-3 — jangan dilewati)

Folder bahan kalibrasi **berisi cacat yang disengaja** (defect injection). Tugasmu: temukan cacat itu.

- `docs/uji/kalibrasi/bahan-2026-09-17/` (5 berkas)

Aturan main (dikutip dari `docs/uji/kalibrasi/CARA-PAKAI.md`):
1. Kamu **tidak** diberi tahu berapa jumlah cacatnya, di berkas mana, atau kelasnya. Periksa seperti kode/dokumen sungguhan.
2. Cacat di folder `bahan-*/` **tidak dihitung** sebagai temuan proyek — tulis hasilnya terpisah di `## 5. Kalibrasi cacat tanaman`.
3. Format bagian 5: `Ditemukan: X dari Y` (Y = jumlah cacat yang kamu yakini ada), daftar cacat temuanmu (berkas + kelas + bukti), dan jumlah **temuan palsu** (yang kamu klaim cacat padahal bukan).
4. **Dilarang mencari kunci jawaban** (ada di luar repo). Menemukan/memakai kunci = kalibrasi batal dan wajib kamu laporkan.

Ambang lulus (dinilai pembangun setelah laporan masuk): semua cacat K-1/K-2 tertanam ditemukan + ≥70% total + 0 temuan palsu.

## 1. Artefak yang harus diperiksa (minimal)

| # | Berkas |
|---|---|
| 1 | `supabase/migrations/0001_penyewa_cabang.sql` |
| 2 | `supabase/tes/rls_penyewa.sql` |
| 3 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql` |
| 4 | `supabase/tes/rls_pengguna.sql` |
| 5 | `supabase/migrations/0003_helper_identitas.sql` |
| 6 | `supabase/tes/helper.sql` |
| 7 | `supabase/migrations/0004_pola_rls.sql` |
| 8 | `supabase/tes/rls_semua_tabel.sql` |
| 9 | `supabase/migrations/0005_izin_berjenjang.sql` |
| 10 | `supabase/tes/izin.sql` |
| 11 | `supabase/migrations/0006_pin.sql` |
| 12 | `supabase/functions/verifikasi_pin/index.ts` |
| 13 | `supabase/tes/pin.sql` |
| 14 | `alat/periksa-fungsi-pin.py` |
| 15 | `supabase/migrations/0007_katalog.sql` |
| 16 | `supabase/tes/katalog.sql` |
| 17 | `supabase/migrations/0008_meja.sql` |
| 18 | `supabase/tes/meja.sql` |
| 19 | `supabase/migrations/0009_pesanan.sql` |
| 20 | `supabase/tes/pesanan.sql` |
| 21 | `supabase/migrations/0010_pembayaran.sql` |
| 22 | `supabase/tes/pembayaran.sql` |

## 2. Klaim pembangun yang harus kamu coba bantah

| # | Tugas | Klaim "Bukti" |
|---|---|---|
| 1 | T1-01 | migrasi `0001` diterapkan pada PostgreSQL asli lalu diuji `supabase/tes/rls_penyewa.sql` — pengunjung belum masuk melihat **0 baris** penyewa & cabang, kasir resto A hanya melihat **1 penyewa & 2 cabangnya**, kasir resto B **tidak melihat satu baris pun** milik resto A; perintah ubah cabang dari resto lain **tidak meng |
| 2 | T1-02 | `supabase/tes/rls_pengguna.sql` — kasir hanya melihat **baris dirinya sendiri**, admin cabang Pusat melihat **3 pegawai** cabangnya (bukan yang hanya bertugas di Cabang Dua), owner pusat melihat **seluruh pegawai restonya** dan **0 pegawai resto lain**; izin hanya terlihat oleh yang berhak (kasir **2 baris miliknya**,  |
| 3 | T1-03 | `supabase/migrations/0003_helper_identitas.sql` + `supabase/tes/helper.sql` — diuji untuk **7 akun** (pemilik platform, owner pusat, admin cabang, kasir, pelayan merangkap dua cabang, dapur, kasir resto lain): pemilik platform tidak punya penyewa/cabang, owner pusat punya penyewa tanpa cabang, pelayan mengembalikan **2 |
| 4 | T1-04 | `supabase/migrations/0004_pola_rls.sql` + `supabase/tes/rls_semua_tabel.sql`. Uji ini **membaca katalog PostgreSQL**, tidak menyebut nama tabel satu per satu — jadi tabel baru di fase mana pun otomatis diperiksa (RLS aktif · punya policy · yang punya `penyewa_id` wajib menyebut `penyewa_saya()`), plus pemindaian pemboc |
| 5 | T1-05 | `supabase/migrations/0005_izin_berjenjang.sql` + `supabase/tes/izin.sql`. Kamus resmi **10 kode izin** (`izin_kode`) dan **izin bawaan per peran** (`izin_peran`, 50 baris per resto, dipasang otomatis untuk resto baru lewat pemicu). Gerbang tunggal **`boleh(aksi)` / `boleh(aksi, nominal)` / `boleh(aksi, nominal, persen) |
| 6 | T1-06 | `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`. PIN disimpan **hanya sebagai hash** (`crypt(pin, gen_salt('bf', 10))`) dan database **menolak sendiri** nilai yang bukan berbentuk hash lewat batas (CHECK) — dibuktikan uji: perintah m |
| 7 | T1-07 | `supabase/migrations/0007_katalog.sql` + `supabase/tes/katalog.sql` + data uji katalog/stok. Tujuh tabel baru (`kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`) — seluruhnya RLS aktif + berpolicy (**16 tabel** diperiksa uji katalog). **Harga per cabang terbukt |
| 8 | T1-08 | `supabase/migrations/0008_meja.sql` + `supabase/tes/meja.sql` + data uji meja di 3 cabang. Meja terpisah per cabang dan **nama meja unik per cabang** — dibuktikan langsung: nama “Meja 5” berhasil dipakai di **dua cabang berbeda**, sedangkan nama yang sama **ditolak** di cabang yang sama; uji mutasi “nama meja dijadikan |
| 9 | T1-09 | `supabase/migrations/0009_pesanan.sql` + `supabase/tes/pesanan.sql`. Tabel `pesanan` + `pesanan_item` dengan **salinan beku** `nama_saat_itu` & `harga_saat_itu` (WAJIB/NOT NULL). **Inti ART-3 dibuktikan langsung:** harga Nasi Goreng dinaikkan 25.000 → 31.000 (dan harga cabang 27.000 → 33.000) **setelah** pesanan dibuat |
| 10 | T1-10 | `supabase/migrations/0010_pembayaran.sql` + `supabase/tes/pembayaran.sql` + data uji pesanan berisi uang. Empat tabel baru: `pembayaran` (banyak baris per pesanan = pembayaran terbagi), `metode_bayar` (per resto, **4 metode bawaan dipasang otomatis** untuk resto baru), `diskon_transaksi`, `pembatalan` — total **23 tabe |

## 3. Lensa wajib (jalankan semua, satu bagian per lensa)

- **L1 Ancaman & Akses** — Bisakah orang tanpa hak masuk/naik peran? Sesi/perangkat yang dicabut masih bisa dipakai? Ada fungsi istimewa (security definer) yang bisa dipanggil siapa saja? Ada jalur membaca data penyewa lain?
- **L3 Kesepakatan Dokumen** — Setiap janji PRD/TECH_SPEC punya kode DAN uji? Setiap klaim 'Bukti' di ROADMAP bisa direproduksi hari ini? Ada syarat tanpa uji (orphan requirement) atau uji tanpa syarat (orphan test)?
- **L4 Mutu Uji** — Ada uji yang lulus karena sebab yang salah? Negatif-test yang bisa ditolak banyak sebab? Uji tanpa pemeriksaan? Gerbang yang belum pernah dibuktikan bisa MERAH? Ada pemeriksa yang tumpul (selalu hijau)?

## 4. Perintah bukti yang disarankan

```
node alat/uji-sql.mjs --daftar        # uji SQL (RLS, uang, PIN, katalog…) + daftar tabel & policy
python3 _sistem/validate_system.py    # struktur & rujukan dokumen
python3 alat/periksa-roadmap.py       # kelengkapan ROADMAP (7 atribut, entitas §4, RPC §5)
python3 alat/periksa-fondasi-independen.py   # pemeriksa kedua (tulisan terpisah)
python3 alat/periksa-fungsi-pin.py    # PIN tidak pernah disimpan/dilog
cd aplikasi && npm test               # uji unit & komponen (vitest)
cd aplikasi && npm run typecheck && npm run lint
git log --oneline -20 && git status --short
```

**Kesiapan mesin saat paket ini dibuat (dicek otomatis):**

- UJI SQL (PGlite) — `node alat/uji-sql.mjs`
- uji unit/komponen — `cd aplikasi && npm test`
- pemeriksa Python — selalu siap

Bila ada yang bertanda ⚠️, **laporkan sebagai keterbatasan** (bagian 6 laporan) dan jangan menyimpulkan sesuatu
yang tidak bisa kamu uji. Jangan memasang apa pun (kamu hanya-baca) — cukup laporkan.

## 5. Skill yang wajib kamu muat lebih dulu

| Berkas | Kegunaan |
|---|---|
| `skills/security-review/SKILL.md` | L1 · L6 — daftar periksa keamanan |
| `skills/systematic-debugging/SKILL.md` | L4 — akar masalah, bukan gejala |
| `skills/verification-before-completion/SKILL.md` | semua klaim wajib bukti segar |
| `skills/verification-loop/SKILL.md` | urutan periksa: bangun → tipe → uji |
| `skills/test-driven-development/SKILL.md` | L4 — mutu uji |
| `skills/prd-taskmaster/SKILL.md` | L3 — jejak syarat → tugas → uji |
| `skills/supabase/SKILL.md` | L1 · L2 — jebakan Supabase (RLS, Auth, paket gratis) |
| `skills/supabase-postgres-best-practices/SKILL.md` | L1 · L2 — RLS, fungsi, indeks |
| `skills/ui-ux-pro-max/SKILL.md` | L5 — layar, tombol, 7 keadaan |

Kamu juga **wajib**: (a) memakai `skills/find-skills` atau `skills/agent-skills-hub` bila butuh skill lain;
(b) mencari referensi internet bila menyimpulkan perilaku sistem luar (Supabase/PostgreSQL/OWASP) dan **mencantumkan tautannya**.

## 6. Format laporan (salin apa adanya, isi bagiannya)

```markdown
# LAPORAN AUDIT INDEPENDEN — AUD-2 — 2026-09-17

- **Auditor:** <nama sesi/model yang benar-benar dipakai>
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-2
- **Commit yang diaudit:** `8d0f72410098080b4833193605f15db70f7d0dfd` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Paket audit:** `docs/uji/paket-audit/AUD-2-2026-09-17.md`
- **Mode cakupan:** menyeluruh
- **Verdict:** BERSIH | BERSIH-DENGAN-CATATAN | TIDAK-BERSIH

## 1. Cakupan
Cakupan menyeluruh: X dari Y berkas (ganti angka sesuai kenyataan) — WAJIB untuk mode menyeluruh
| # | Artefak | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|

## 2. Klaim pembangun yang saya coba falsifikasi
| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|

## 3. Serangan yang dijalankan (kill attempts)
| # | Skenario | Cara | Hasil |
|---|---|---|---|

## 4. Temuan
### [F-01] <judul singkat>
- **Tingkat:** K-2
- **Artefak:** `berkas:baris`
- **Klaim yang dilanggar:** …
- **Bukti:** `perintah` → hasil nyata
- **Skenario gagal:** langkah → dampak
- **Dugaan penyebab:** …
- **Cara membuktikan perbaikan:** `perintah yang harus hijau`
- **Status verifikasi:** TERVERIFIKASI

(atau tulis: (tidak ada temuan))

## 5. Kalibrasi cacat tanaman
(wajib untuk AUD-3 — lihat instruksi terpisah dari pembangun)

## 6. Yang tidak bisa saya verifikasi
- …

## 7. Pernyataan tidak mengubah apa pun
Saya hanya-baca dan tidak mengubah berkas apa pun. Bukti: `git status --short` kosong.
```

## 7. Kalibrasi cacat tanaman (khusus AUD-3)

Bahan kalibrasi ada **di dalam repo ini** (folder yang disebut §0b di atas) dan berisi **cacat yang sengaja ditanam**;
kunci jawabannya disimpan **di luar repo** dan tidak boleh kamu cari. Isi `## 5. Kalibrasi cacat tanaman` dengan daftar
cacat yang kamu temukan (`berkas` + kelas + bukti), `Ditemukan: X dari Y`, dan jumlah temuan palsu.
**Kalibrasi ini menentukan apakah verdict BERSIH-mu boleh dipercaya.** Cacat di folder bahan **tidak** dihitung sebagai temuan proyek.
