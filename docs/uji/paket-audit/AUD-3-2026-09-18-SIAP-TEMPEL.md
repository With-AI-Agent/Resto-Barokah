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
7. Laporkan SEMUA yang kamu temukan — termasuk yang di luar cakupan/lensa yang diminta (isi bagian 8 laporan).
   Ambang minimum di paket adalah LANTAI, bukan target: jangan berhenti setelah mencapai angka minimum, dan jangan
   menambah baris demi memenuhi syarat. Jangan menyusun laporan supaya lolos pemeriksa — formatnya sudah lengkap di paket.
8. Tulis laporan dengan format PERSIS seperti di paket (bagian "6. Format laporan") ke
   `docs/uji/audit/LAPORAN_<TINGKAT>_<tanggal>_<lingkup>__<penanda-sesi>.md`, dengan `<penanda-sesi>`
   = potongan nama cabangmu (mis. `01a0aeb4`) supaya tidak bertabrakan dengan sesi auditor lain.
   Berkas ini SATU-SATUNYA yang boleh kamu buat/ubah.
9. Jalankan `python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/<berkas-laporan>.md` (sekali di akhir).
   Bila ditolak: perbaiki KELENGKAPAN FORMAT-nya, bukan menambah temuan yang tidak kamu yakini.
10. Supaya hasilmu sampai ke sesi kerja, commit + push HANYA berkas laporan itu ke cabang sesi ini. Contoh:
    `git add docs/uji/audit/ && git commit -m "laporan audit <tingkat> <lingkup>" && git push -u origin HEAD`
    (jangan mengubah/meng-commit berkas lain; bila push tidak bisa, tulis "belum ter-push" di laporan dan beri tahu saya).
11. Laporkan verdict + ringkasan temuan ke saya di chat.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas selain laporan,
mempercayai klaim tanpa membuktikannya, menaikkan verdict di atas bukti, dan menyusun laporan demi memenuhi ambang /
kelulusan pemeriksa — itu teater, bukan audit.

Paket audit:
<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>

===== SAMBUNGAN: PAKET AUDIT =====

# PAKET AUDIT INDEPENDEN — AUD-3 — 2026-09-18

> Dibuat mesin oleh `alat/audit-independen.py`. Berkas ini **untuk auditor** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`.

> **CARA PAKAI — untuk pemilik (3 langkah, mudah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas ini** ke chat baru itu.
> 3. Susulkan **kalimat pembuka auditor** dari buku induk `PANDUAN_PENGGUNA.md` **Bagian C4** (sama persis dengan
>    `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B) — satu blok, apa adanya, tidak perlu diubah.
> Setelah auditor selesai, kembali ke sesi kerja dan bilang: **"Laporan audit sudah masuk, periksa."**

- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `cdd80b6724845663103cde132273919a4636e2d4` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Tugas dalam lingkup:** T0-00, T0-01, T0-02, T0-03, T0-04, T0-05, T0-06, T0-07, T0-08, T0-09, T0-10, T0-11, T0-12, T0-13, T0-14, T1-01, T1-02, T1-03, T1-04, T1-05, T1-06, T1-07, T1-08, T1-09, T1-10, T1-11, T1-12, T1-13, T1-14, T1-15, T1-16, T1-17, T1-18, T1-19, T1-20, T1-21, T1-22, T1-23, T1-24, T1-25, T1-26, T1-27, T1-28, T1-29, T1-30, T1-31, T1-32, T1-33, T1-34, T1-35, T1-36, T1-37, T1-38, T1-39, T1-40, T1-41, T1-42, T1-43, T1-44, T2-01, T2-02, T2-03, T2-04, T2-05, T2-06, T2-07, T2-08, T2-09, T2-10, T2-11, T2-12, T2-13, T2-14, T2-15, T2-16, T2-17, T2-18, T2-19, T3-01, T3-02, T3-03, T3-04, T3-05, T3-06, T3-07, T3-08, T3-09, T3-10, T3-11, T3-12, T3-13, T3-14, T3-15, T3-16, T4-01, T4-02, T4-03, T4-04, T4-05, T4-06, T4-07, T4-08, T4-09, T4-10, T5-01, T5-02, T5-03, T5-04, T5-05, T5-06, T5-07, T5-08, T5-09, T5-10, T5-11, T5-12, T6-01, T6-02, T6-03, T6-04, T6-05, T6-06, T6-07, T6-08, T7-01, T7-02, T7-03, T7-04, T7-05, T7-06, T7-07, T7-08, T7-09, T7-10, T7-11, T7-12, T8-01, T8-02, T8-03, T8-04, T8-05, T8-06, T8-07, T8-08, T8-09, T8-10, T8-11, T8-12, T8-13, T8-14, T8-15, T9-01, T9-02, T9-03, T9-04, T9-05, T9-06, T9-07, T9-08, T9-09, T9-10, T9-11, T9-12, T10-01, T10-02, T10-03, T10-04, T10-05, T10-06, T10-07, T10-08, T10-09, T10-10, T10-11, T10-12, T10-13, T10-14, T10-15, T10-16, T11-01, T11-02, T11-03, T11-04, T11-05, T11-06, T11-07, T11-08, T11-09, T11-10, T11-11, T11-12, T11-13
- **Lensa wajib:** L1, L2, L3, L4, L5, L6
- **Mode cakupan:** menyeluruh
- **Minimum laporan:** ≥19 artefak diperiksa · ≥5 klaim dibantah · ≥12 serangan dijalankan · masing-masing temuan punya perintah bukti
- **Perintah validasi laporan (wajib hijau):** periksa dengan alat `alat/audit-independen.py --periksa-laporan` (berkas laporan ditulis di folder docs/uji/audit/). Bila repo yang kamu pakai adalah klon dangkal, alat akan memberi CATATAN (bukan menolak) untuk SHA yang riwayatnya tidak ada.

## 0a. LANGKAH 0 (WAJIB) — pastikan kamu memeriksa commit yang benar

Paket ini menargetkan commit **`cdd80b6724845663103cde132273919a4636e2d4`**. **Cabang/base apa pun yang Lee pilih tidak masalah** — yang menentukan adalah commit-nya.

```
# (a) di repo ini, satu perintah memeriksa semuanya:
python3 alat/audit-independen.py --verifikasi-lingkup

# (b) atau manual:
git rev-parse HEAD                 # commit yang sedang kamu lihat
git cat-file -e cdd80b6724845663103cde132273919a4636e2d4            # apakah commit target ada di repo ini?
```

- **Sama** (`HEAD` = `cdd80b6724845663103cde132273919a4636e2d4`) → langsung lanjut.
- **Berbeda tetapi commit target ada** → pindah hanya-baca lalu lanjut (aman, tidak mengubah apa pun):
  `git fetch origin && git checkout --detach cdd80b6724845663103cde132273919a4636e2d4`
- **Commit target tidak ada** → coba `git fetch origin` sekali lagi. Kalau tetap tidak ada, **JANGAN mengaudit commit lain**:
  tulis di bagian "Yang tidak bisa saya verifikasi" dan hentikan (minta Lee membuka sesi dari sumber yang benar).
- Tulis di kepala laporan: `- **Commit yang diaudit:** <commit yang benar-benar kamu periksa>`.

## 0c. Setelah laporan selesai — kirim ke sesi kerja (wajib)

Beri nama berkas dengan **penanda sesimu** di belakang supaya dua sesi auditor tidak bertabrakan
(kejadian nyata 2026-09-17: dua sesi memilih nama yang sama sehingga laporan pertama nyaris tertimpa):

```
docs/uji/audit/LAPORAN_AUD-3_2026-09-18_menyeluruh__<penanda-sesi>.md
```
`<penanda-sesi>` = potongan nama cabang sesimu, mis. `01a0aeb4` (lihat `git branch --show-current`).

Laporan harus menjadi **berkas di Git**, bukan hanya teks di chat:

```
git add docs/uji/audit/ && git commit -m "laporan audit AUD-3 <lingkup>" && git push -u origin HEAD
```

Hanya berkas laporan yang di-commit. Bila push tidak bisa, tulis "belum ter-push" di laporan + beri tahu Lee di chat.

## ATURAN INDEPENDENSI (tidak bisa ditawar)

1. Kamu **hanya-baca**: SATU-SATUNYA berkas yang boleh kamu buat adalah laporan (§6 format laporan). Selain berkas itu,
   jangan mengubah/memperbaiki apa pun (temuan ditulis, bukan dibetulkan).
2. Tugasmu **membantah** klaim pembangun di bawah — bukan mempercayainya.
3. Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan.
4. Setiap calon temuan wajib kamu **uji ulang** di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah).
   Tidak bisa dibuktikan → tandai **DUGAAN**, bukan TERVERIFIKASI.
5. Istilah tingkat: **K-1** = uang salah/data bocor/tak bisa dipulihkan; **K-2** = janji PRD/ART/KEAMANAN dilanggar atau kontrol wajib hilang;
   **K-3** = tidak konsisten / uji kurang / dokumen basi; **K-4** = kerapian, tidak menghambat.
6. Verdict: `BERSIH` / `BERSIH-DENGAN-CATATAN` / `TIDAK-BERSIH`. **Ada K-1/K-2 TERVERIFIKASI → verdict wajib TIDAK-BERSIH.**


## 0. LINGKUP MENYELURUH (wajib — audit ini memeriksa SEMUA berkas proyek)

- **Jumlah berkas dalam lingkup:** 426
- **Mode cakupan yang wajib kamu tulis di laporan:** `menyeluruh`

**Grup berkas yang wajib kamu sentuh (minimal satu baris bukti per grup):**

| Grup | Isi | Jumlah berkas | Contoh |
|---|---|---|---|
| aplikasi/src | kode aplikasi (layar, komponen, lib, uji) | 71 | `aplikasi/src/App.tsx`, `aplikasi/src/gaya/aset/font/LISENSI-ArsenalSC.txt` … |
| aplikasi/alat | perkakas pemeriksa aplikasi | 8 | `aplikasi/alat/periksa-antarmuka.py`, `aplikasi/alat/periksa-kerapatan.py` … |
| aplikasi (konfigurasi) | package.json, tsconfig, vite, index.html | 16 | `aplikasi/.env.example`, `aplikasi/.gitignore` … |
| supabase/migrations | migrasi database | 15 | `supabase/migrations/.gitkeep`, `supabase/migrations/0001_penyewa_cabang.sql` … |
| supabase/tes | uji SQL | 42 | `supabase/tes/.gitkeep`, `supabase/tes/cabang_sesi.sql` … |
| supabase/functions | Edge Functions | 2 | `supabase/functions/.gitkeep`, `supabase/functions/verifikasi_pin/index.ts` |
| supabase (akar) | berkas di akar supabase/ (README cara memasang migrasi) | 1 | `supabase/README.md` |
| alat | perkakas repo (uji SQL, pemeriksa, mekanisme audit) | 39 | `alat/audit-independen.py`, `alat/bantu_uji_diri.py` … |
| _sistem | mesin kerja agent (validator, template) | 15 | `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md`, `_sistem/03_AUDIT_VERCEL_SKILLS.md` … |
| docs (fondasi) | PRD, TECH_SPEC, ROADMAP, KEAMANAN, SPESIFIKASI_UI, dll | 11 | `docs/AGENT_OPERATING_GUIDE.md`, `docs/DECISIONS_LOG.md` … |
| docs/uji | protokol & laporan uji/audit | 61 | `docs/uji/AUDIT_RIWAYAT.md`, `docs/uji/BUKU_UJI_PEMILIK.md` … |
| docs/teknis | catatan teknis & Buku Insiden | 6 | `docs/teknis/BUKU_INSIDEN.md`, `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md` … |
| docs/ops | panduan operasional | 2 | `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md`, `docs/ops/SIAP_AKUN_PEMILIK.md` |
| docs/desain | catatan desain | 59 | `docs/desain/PENILAIAN_REFERENSI.md`, `docs/desain/RENCANA_DESAIN_UI.md` … |
| prototipe | prototipe desain (acuan visual) | 58 | `prototipe/01-laporan.html`, `prototipe/02-kasir.html` … |
| _log-sesi | log sesi kerja | 3 | `_log-sesi/LOG_SESI_2026-09-15.md`, `_log-sesi/LOG_SESI_2026-09-16.md` … |
| berkas pengguna di akar | PANDUAN_*, PROMPT_*, START_DI_SINI, PROFIL_PENGGUNA, AGENT_SYSTEM, STATUS, PROJECT_STATE, dll | 16 | `.gitignore`, `10_LOG_SESI.md` … |
| .github/workflows | alur CI | 1 | `.github/workflows/ci.yml` |
| belum berggrup | BERKAS YANG TIDAK COCOK GRUP MANA PUN — paket TIDAK dibuat selama ada isinya | 0 |  |

**Dikecualikan dari lingkup (dan wajib kamu setujui/tolak dengan alasan):**

- `skills/` (1803 berkas) — kumpulan skill pihak ketiga (vendored) — bukan kode proyek; dipakai, tidak diubah
- `_salinan-meta/` (2 berkas) — arsip provenance sistem
- `_Notes.md` (1 berkas) — catatan pribadi pemilik (tidak ikut template)

**Kewajiban khusus mode menyeluruh (divalidasi mesin):**
1. Tulis di kepala laporan: `- **Mode cakupan:** menyeluruh`.
2. Tulis ringkasan: `Cakupan menyeluruh: X dari 426 berkas` (X = berkas yang benar-benar kamu periksa; angka ini diperiksa mesin).
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
| 1 | `docs/ops/SIAP_AKUN_PEMILIK.md` |
| 2 | `aplikasi/package.json` |
| 3 | `aplikasi/vite.config.ts` |
| 4 | `aplikasi/tsconfig.json` |
| 5 | `aplikasi/tsconfig.app.json` |
| 6 | `aplikasi/tsconfig.node.json` |
| 7 | `aplikasi/src/layar/contoh/LayarContoh.tsx` |
| 8 | `aplikasi/alat/periksa-struktur.py` |
| 9 | `aplikasi/.prettierrc.json` |
| 10 | `aplikasi/vitest.config.ts` |
| 11 | `aplikasi/src/lib/tema.ts` |
| 12 | `aplikasi/src/hook/useTema.ts` |
| 13 | `prototipe/uji-kontras.py` |
| 14 | `aplikasi/alat/uji-kontras.py` |
| 15 | `aplikasi/alat/periksa-komponen-env.py` |
| 16 | `aplikasi/src/lib/env.ts` |
| 17 | `aplikasi/README.md` |
| 18 | `.github/workflows/ci.yml` |
| 19 | `aplikasi/src/lib/format.test.ts` |
| 20 | `aplikasi/src/lib/tema.test.ts` |
| 21 | `aplikasi/src/lib/env.test.ts` |
| 22 | `aplikasi/src/hook/useJam.test.tsx` |
| 23 | `aplikasi/src/hook/useTema.test.tsx` |
| 24 | `aplikasi/src/komponen/komponen.test.tsx` |
| 25 | `aplikasi/alat/periksa-uji.py` |
| 26 | `alat/periksa-roadmap.py` |
| 27 | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` |
| 28 | `alat/periksa-panduan.py` |
| 29 | `docs/PANDUAN_PEMILIK.md` |
| 30 | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` |
| 31 | `docs/ROADMAP.md` |
| 32 | `docs/uji/AUDIT_RIWAYAT.md` |
| 33 | `docs/TERTANGGUH.md` |
| 34 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` |
| 35 | `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` |
| 36 | `alat/review-pr.py` |
| 37 | `docs/uji/REVIEW_PR_RIWAYAT.md` |
| 38 | `docs/teknis/REKAM_PESAN_PEMILIK.md` |
| 39 | `supabase/migrations/0001_penyewa_cabang.sql` |
| 40 | `supabase/tes/rls_penyewa.sql` |
| 41 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql` |
| 42 | `supabase/tes/rls_pengguna.sql` |
| 43 | `supabase/migrations/0003_helper_identitas.sql` |
| 44 | `supabase/tes/helper.sql` |
| 45 | `supabase/migrations/0004_pola_rls.sql` |
| 46 | `supabase/tes/rls_semua_tabel.sql` |
| 47 | `supabase/migrations/0005_izin_berjenjang.sql` |
| 48 | `supabase/tes/izin.sql` |
| 49 | `supabase/migrations/0006_pin.sql` |
| 50 | `supabase/functions/verifikasi_pin/index.ts` |
| 51 | `supabase/tes/pin.sql` |
| 52 | `supabase/tes/percobaan_pin_perangkat.sql` |
| 53 | `alat/periksa-fungsi-pin.py` |
| 54 | `supabase/migrations/0007_katalog.sql` |
| 55 | `supabase/tes/katalog.sql` |
| 56 | `supabase/migrations/0008_meja.sql` |
| 57 | `supabase/tes/meja.sql` |
| 58 | `supabase/migrations/0009_pesanan.sql` |
| 59 | `supabase/tes/pesanan.sql` |
| 60 | `supabase/migrations/0010_pembayaran.sql` |
| 61 | `supabase/tes/pembayaran.sql` |
| 62 | `supabase/tes/gerbang_uang.sql` |
| 63 | `supabase/tes/diskon_voucher.sql` |
| 64 | `docs/KEAMANAN.md` |
| 65 | `docs/DECISIONS_LOG.md` |
| 66 | `supabase/migrations/0011_peran_tunggal.sql` |
| 67 | `supabase/tes/peran_tunggal.sql` |
| 68 | `supabase/tes/kredensial_pin.sql` |
| 69 | `supabase/tes/pin_batas_pasang.sql` |
| 70 | `alat/periksa-rahasia.py` |
| 71 | `docs/SPESIFIKASI_UI.md` |
| 72 | `docs/AGENT_OPERATING_GUIDE.md` |
| 73 | `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` |
| 74 | `alat/sql/data-uji.sql` |
| 75 | `docs/uji/BUKU_UJI_PEMILIK.md` |
| 76 | `alat/periksa-buku-uji.py` |
| 77 | `alat/audit-independen.py` |
| 78 | `aplikasi/src/App.tsx` |
| 79 | `prototipe/README.md` |
| 80 | `docs/teknis/BUKU_INSIDEN.md` |
| 81 | `supabase/tes/cabang_sesi.sql` |
| 82 | `supabase/tes/diskon_cap.sql` |
| 83 | `supabase/tes/diskon_cap_bawaan.sql` |
| 84 | `supabase/tes/diskon_persen.sql` |
| 85 | `supabase/tes/diskon_setuju.sql` |
| 86 | `supabase/tes/harga_item.sql` |
| 87 | `supabase/tes/isolasi_lintas_penyewa.sql` |
| 88 | `supabase/tes/item_penjaga.sql` |
| 89 | `supabase/tes/izin_efektif_untuk.sql` |
| 90 | `supabase/tes/jejak_pelaku.sql` |
| 91 | `supabase/tes/jejak_pengaturan.sql` |
| 92 | `supabase/tes/jejak_pesanan.sql` |
| 93 | `supabase/tes/meja_penjaga.sql` |
| 94 | `supabase/tes/nilai_kerugian.sql` |
| 95 | `supabase/tes/pembayaran_metode.sql` |
| 96 | `supabase/tes/penjaga_stok.sql` |
| 97 | `supabase/tes/persetujuan_void.sql` |
| 98 | `supabase/tes/pesanan_status_awal.sql` |
| 99 | `supabase/tes/pin_hierarki.sql` |
| 100 | `supabase/tes/pin_kunci_silang.sql` |
| 101 | `supabase/tes/status_pesanan.sql` |
| 102 | `supabase/tes/stok_arah.sql` |
| 103 | `supabase/tes/stok_insert_langsung.sql` |
| 104 | `supabase/tes/uang_peladen.sql` |
| 105 | `supabase/tes/varian_gagal_aman.sql` |
| 106 | `alat/bantu_uji_diri.py` |
| 107 | `alat/lanjut-sesi.py` |
| 108 | `alat/mulai-sesi.py` |
| 109 | `alat/periksa-angka-bukti.py` |
| 110 | `alat/periksa-bersih.py` |
| 111 | `alat/periksa-fondasi-independen.py` |
| 112 | `alat/periksa-gerbang-ci.py` |
| 113 | `alat/periksa-paket.py` |
| 114 | `alat/periksa-rujukan.py` |
| 115 | `alat/periksa-temuan-audit.py` |
| 116 | `alat/uji-mutasi-0012.py` |
| 117 | `alat/uji-mutasi-0014.py` |


> **Catatan mesin (F-12 audit 2026-09-18):** daftar di atas SUDAH disaring — hanya berkas
> yang **benar-benar ada** di commit ini. Jalur yang baru *direncanakan* ada di bagian 1b.
> Kalau kamu menemukan jalur di bagian 1 yang tidak ada, laporkan sebagai temuan mesin.

## 1b. Direncanakan — berkas yang BELUM ADA (JANGAN diperiksa sebagai bukti)

| Jalur yang dirujuk dokumen | Tugas |
|---|---|
| `src/lib/tema.ts` | T0-03 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `aplikasi/src/komponen/*.tsx` | T0-04 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 aplikasi/alat/uji-kontras.py` | T0-04 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 aplikasi/alat/periksa-komponen-env.py` | T0-05 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `aplikasi/src/lib/supabase.ts` | T0-08 |
| `python3 alat/periksa-roadmap.py` | T0-10 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 alat/periksa-roadmap.py` | T0-10 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 alat/periksa-panduan.py` | T0-11 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 _sistem/validate_system.py` | T0-11 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `docs/uji/paket-audit/AUD-3-<tanggal>.md` | T0-12 |
| `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_menyeluruh.md` | T0-12 |
| `python3 alat/periksa-panduan.py` | T0-14 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `python3 alat/uji-mutasi-0012.py` | T1-05 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `supabase/migrations/0018_kas_shift.sql` | T1-11 |
| `supabase/migrations/0019_voucher.sql` | T1-12 |
| `supabase/migrations/0020_catatan_audit.sql` | T1-13 |
| `supabase/tes/audit.sql` | T1-13 |
| `supabase/migrations/0021_antrean_kesalahan.sql` | T1-14 |
| `supabase/migrations/0022_hitung_total.sql` | T1-15 |
| `supabase/tes/uang.sql` | T1-15 |
| `supabase/migrations/0023_urutan_pembulatan.sql` | T1-16 |
| `supabase/tes/urutan.sql` | T1-16 |
| `supabase/migrations/0024_penomoran.sql` | T1-17 |
| `supabase/tes/penomoran.sql` | T1-17 |
| `supabase/migrations/0025_state_machine.sql` | T1-18 |
| `supabase/tes/status.sql` | T1-18 |
| `supabase/migrations/0026_cek_voucher.sql` | T1-19 |
| `supabase/tes/cek_voucher.sql` | T1-19 |
| `supabase/migrations/0027_pakai_voucher.sql` | T1-20 |
| `supabase/tes/pakai_voucher.sql` | T1-20 |
| `supabase/seed.sql` | T1-21 |
| `supabase/seed_uji.sql` | T1-21 |
| `supabase/tes/sisir_rls.sql` | T1-22 |
| `node alat/uji-sql.mjs` | T1-23 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `supabase/migrations/0012_perangkat.sql` | T1-24 |
| `supabase/tes/perangkat.sql` | T1-24 |
| `supabase/migrations/0013_sesi_perangkat.sql` | T1-25 |
| `supabase/tes/sesi_perangkat.sql` | T1-25 |
| `supabase/migrations/0014_percobaan_masuk.sql` | T1-26 |
| `supabase/tes/percobaan_masuk.sql` | T1-26 |
| `supabase/migrations/0015_audit.sql` | T1-27 |
| `supabase/tes/audit.sql` | T1-27 |
| `alat/periksa-audit.py` | T1-27 |
| `supabase/migrations/0016_mode_dukungan.sql` | T1-28 |
| `supabase/tes/mode_dukungan.sql` | T1-28 |
| `supabase/tes/matriks_izin.sql` | T1-29 |
| `supabase/tes/matriks_staf.sql` | T1-29 |
| `alat/periksa-keamanan-sql.py` | T1-30 |
| `aplikasi/src/lib/layar.ts` | T1-31 |
| `docs/PETA_UI.md` | T1-31 |
| `alat/peta-ui.py` | T1-31 |
| `aplikasi/src/lib/aksi.ts` | T1-32 |
| `aplikasi/src/komponen/TombolAksi.tsx` | T1-32 |
| `aplikasi/src/komponen/TombolAksi.test.tsx` | T1-32 |
| `alat/peta-ui.py` | T1-33 |
| `docs/PETA_UI.md` | T1-33 |
| `aplikasi/src/uji/harness.tsx` | T1-34 |
| `aplikasi/src/uji/harness.test.tsx` | T1-34 |
| `docs/uji/NASKAH_JALAN.md` | T1-35 |
| `supabase/migrations/0016b_pemulihan_perangkat.sql` | T1-36 |
| `supabase/tes/pemulihan.sql` | T1-36 |
| `docs/ops/PEMULIHAN_PERANGKAT.md` | T1-36 |
| `tes/izin.sql` | T1-37 |
| `node alat/uji-sql.mjs` | T1-37 |
| `python3 alat/periksa-roadmap.py` | T1-37 |
| `docs/uji/paket-audit/AUD-2-<tanggal>.md` | T1-38 |
| `docs/uji/audit/LAPORAN_AUD-2_<tanggal>_keamanan.md` | T1-38 |
| `docs/PETA_UI.md` | T1-38 |
| `docs/PETA_UI.md` | T1-39 |
| `aplikasi/src/lib/layar.ts` | T1-39 |
| `aplikasi/src/lib/aksi.ts` | T1-39 |
| `alat/peta-ui.py` | T1-39 |
| `python3 alat/peta-ui.py` | T1-39 |
| `aplikasi/src/bahasa/id.ts` | T1-40 |
| `aplikasi/src/bahasa/index.ts` | T1-40 |
| `docs/PETA_UI.md` | T1-40 |
| `aplikasi/alat/periksa-bahasa.py` | T1-40 |
| `python3 aplikasi/alat/periksa-bahasa.py` | T1-40 |
| `aplikasi/alat/periksa-arah.py` | T1-41 |
| `aplikasi/src/kontrak/bantuan.ts` | T1-42 |
| `aplikasi/src/komponen/LembarBantuan.tsx` | T1-42 |
| `alat/periksa-bantuan.py` | T1-42 |
| `alat/tambah-uji.py` | T1-43 |
| `aplikasi/src/lib/auth.ts` | T2-01 |
| `aplikasi/src/hook/useSesi.ts` | T2-01 |
| `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx` | T2-02 |
| `supabase/tes/masuk_pegawai.sql` | T2-02 |
| `aplikasi/src/layar/pengaturan/KelolaPegawai.tsx` | T2-03 |
| `supabase/functions/undang_pegawai/index.ts` | T2-03 |
| `aplikasi/src/layar/masuk/LayarMasukPelanggan.tsx` | T2-04 |
| `aplikasi/src/lib/google.ts` | T2-04 |
| `supabase/functions/pemulihan_pelanggan/index.ts` | T2-05 |
| `aplikasi/src/layar/masuk/LupaAkses.tsx` | T2-05 |
| `aplikasi/src/komponen/Rangka.tsx` | T2-06 |
| `aplikasi/src/komponen/Navigasi.tsx` | T2-06 |
| `aplikasi/src/hook/useCabang.ts` | T2-07 |
| `aplikasi/src/komponen/PemilihCabang.tsx` | T2-07 |
| `aplikasi/src/layar/TidakPunyaAkses.tsx` | T2-08 |
| `aplikasi/src/lib/pesan.ts` | T2-08 |
| `aplikasi/src/hook/useKunciSesi.ts` | T2-09 |
| `supabase/functions/pembatas_masuk/index.ts` | T2-10 |
| `supabase/tes/pembatas.sql` | T2-10 |
| `aplikasi/src/layar/masuk/*.test.ts` | T2-12 |
| `supabase/tes/peran_masuk.sql` | T2-12 |
| `aplikasi/src/layar/masuk/Totp.tsx` | T2-13 |
| `supabase/functions/atur_ulang_mfa/index.ts` | T2-13 |
| `alat/periksa-fungsi-mfa.py` | T2-13 |
| `supabase/tes/mfa.sql` | T2-13 |
| `aplikasi/src/layar/masuk/MasukStaf.tsx` | T2-14 |
| `aplikasi/src/lib/sesi.ts` | T2-14 |
| `aplikasi/src/layar/pengaturan/Perangkat.tsx` | T2-15 |
| `supabase/functions/kode_perangkat/index.ts` | T2-15 |
| `aplikasi/src/hook/useKunciOtomatis.ts` | T2-16 |
| `aplikasi/src/komponen/KunciSekarang.tsx` | T2-16 |
| `aplikasi/src/hook/useKunciOtomatis.test.tsx` | T2-16 |
| `aplikasi/src/layar/pengaturan/DaftarPerangkat.tsx` | T2-17 |
| `docs/uji/NASKAH_JALAN.md` | T2-17 |
| `aplikasi/src/layar/masuk/MasukPengelola.tsx` | T2-18 |
| `supabase/tes/masuk_perangkat.sql` | T2-19 |
| `aplikasi/src/layar/masuk/masuk.test.tsx` | T2-19 |
| `aplikasi/src/layar/kasir/LayarKasir.tsx` | T3-01 |
| `aplikasi/src/layar/kasir/Katalog.tsx` | T3-01 |
| `aplikasi/src/layar/kasir/Keranjang.tsx` | T3-02 |
| `aplikasi/src/lib/uang.ts` | T3-02 |
| `aplikasi/src/layar/kasir/PemilihMeja.tsx` | T3-03 |
| `aplikasi/src/komponen/CatatanItem.tsx` | T3-03 |
| `aplikasi/src/layar/kasir/DaftarTagihan.tsx` | T3-04 |
| `supabase/migrations/0028_simpan_pesanan.sql` | T3-05 |
| `supabase/tes/simpan_pesanan.sql` | T3-05 |
| `aplikasi/src/layar/kasir/PindahMeja.tsx` | T3-06 |
| `supabase/migrations/0029_pindah_meja.sql` | T3-06 |
| `aplikasi/src/layar/kasir/Katalog.tsx` | T3-07 |
| `supabase/migrations/0030_menu_habis.sql` | T3-07 |
| `aplikasi/src/layar/kasir/KirimDapur.tsx` | T3-08 |
| `supabase/migrations/0031_kirim_dapur.sql` | T3-08 |
| `aplikasi/src/layar/kasir/PeringatanMeja.tsx` | T3-09 |
| `supabase/tes/konflik_meja.sql` | T3-09 |
| `aplikasi/src/hook/usePintasan.ts` | T3-10 |
| `aplikasi/src/layar/pelayan/LayarPelayan.tsx` | T3-11 |
| `aplikasi/src/layar/kasir/DaftarPesanan.tsx` | T3-12 |
| `aplikasi/src/layar/kasir/BatalPesanan.tsx` | T3-13 |
| `supabase/migrations/0032_batal_pra_dapur.sql` | T3-13 |
| `aplikasi/uji/e2e/kasir.spec.ts` | T3-14 |
| `aplikasi/src/layar/kasir/*.tsx` | T3-15 |
| `aplikasi/src/komponen/Keadaan*.tsx` | T3-15 |
| `aplikasi/uji/beban/kasir.test.ts` | T3-16 |
| `aplikasi/src/layar/dapur/LayarDapur.tsx` | T4-01 |
| `aplikasi/src/layar/dapur/LayarBar.tsx` | T4-02 |
| `supabase/migrations/0033_tujuan_item.sql` | T4-02 |
| `aplikasi/src/layar/dapur/KartuPesanan.tsx` | T4-03 |
| `supabase/migrations/0034_status_item.sql` | T4-04 |
| `supabase/tes/status_item.sql` | T4-04 |
| `aplikasi/src/layar/dapur/TombolHabis.tsx` | T4-05 |
| `supabase/migrations/0035_menu_habis_sumber.sql` | T4-05 |
| `aplikasi/src/layar/dapur/Stok.tsx` | T4-06 |
| `supabase/migrations/0036_stok.sql` | T4-06 |
| `aplikasi/src/layar/dapur/Opname.tsx` | T4-07 |
| `supabase/migrations/0037_opname.sql` | T4-07 |
| `aplikasi/src/layar/dapur/KartuPesanan.tsx` | T4-08 |
| `aplikasi/uji/e2e/dapur.spec.ts` | T4-09 |
| `supabase/tes/anti_dobel.sql` | T4-09 |
| `aplikasi/src/layar/dapur/*.tsx` | T4-10 |
| `aplikasi/src/layar/kasir/Bayar.tsx` | T5-01 |
| `supabase/migrations/0038_bayar_pesanan.sql` | T5-02 |
| `supabase/tes/bayar.sql` | T5-02 |
| `aplikasi/src/komponen/Struk.tsx` | T5-03 |
| `supabase/tes/pajak_service.sql` | T5-03 |
| `supabase/migrations/0039_diskon.sql` | T5-04 |
| `supabase/tes/diskon.sql` | T5-04 |
| `aplikasi/src/layar/kasir/DiskonManual.tsx` | T5-05 |
| `supabase/migrations/0040_diskon_izin.sql` | T5-05 |
| `supabase/migrations/0041_void_pra.sql` | T5-06 |
| `supabase/tes/void_pra.sql` | T5-06 |
| `supabase/migrations/0042_void_pasca.sql` | T5-07 |
| `aplikasi/src/layar/kasir/VoidPasca.tsx` | T5-07 |
| `aplikasi/src/layar/kasir/DataPelanggan.tsx` | T5-08 |
| `aplikasi/src/komponen/StrukDigital.tsx` | T5-09 |
| `aplikasi/src/layar/kasir/DaftarTransaksi.tsx` | T5-10 |
| `supabase/tes/pembayaran_sebagian.sql` | T5-11 |
| `aplikasi/src/layar/kasir/DaftarTagihan.tsx` | T5-11 |
| `supabase/migrations/0043_laporan_pembatalan.sql` | T5-12 |
| `aplikasi/src/layar/laporan/DaftarPembatalan.tsx` | T5-12 |
| `aplikasi/src/lib/printer/expos.ts` | T6-01 |
| `aplikasi/src/lib/printer/expos.test.ts` | T6-01 |
| `aplikasi/src/lib/printer/bluetooth.ts` | T6-02 |
| `aplikasi/src/layar/pengaturan/PasangPrinter.tsx` | T6-02 |
| `aplikasi/src/lib/printer/usb.ts` | T6-03 |
| `aplikasi/src/lib/printer/struk.ts` | T6-04 |
| `aplikasi/src/lib/printer/tiket.ts` | T6-05 |
| `aplikasi/src/lib/printer/antrean.ts` | T6-06 |
| `aplikasi/src/komponen/StatusPrinter.tsx` | T6-06 |
| `supabase/migrations/0044_printer.sql` | T6-07 |
| `aplikasi/src/layar/pengaturan/PengaturanPrinter.tsx` | T6-07 |
| `docs/uji/UJI_CETAK_KEDAI_OASIS.md` | T6-08 |
| `supabase/migrations/0045_buka_shift.sql` | T7-01 |
| `aplikasi/src/layar/kasir/BukaKas.tsx` | T7-01 |
| `supabase/migrations/0046_tutup_shift.sql` | T7-02 |
| `aplikasi/src/layar/kasir/TutupKas.tsx` | T7-02 |
| `supabase/migrations/0047_kas_pergerakan.sql` | T7-03 |
| `aplikasi/src/layar/kasir/KasKeluarMasuk.tsx` | T7-03 |
| `supabase/migrations/0048_wajib_shift.sql` | T7-04 |
| `supabase/tes/wajib_shift.sql` | T7-04 |
| `aplikasi/src/komponen/PengingatShift.tsx` | T7-05 |
| `supabase/migrations/0049_pengingat_shift.sql` | T7-05 |
| `supabase/migrations/0050_koreksi_modal.sql` | T7-06 |
| `supabase/migrations/0051_laporan_kas.sql` | T7-07 |
| `aplikasi/src/layar/laporan/LaporanKas.tsx` | T7-07 |
| `supabase/migrations/0052_laporan_penjualan.sql` | T7-08 |
| `aplikasi/src/layar/laporan/LaporanPenjualan.tsx` | T7-08 |
| `supabase/migrations/0053_laporan_menu.sql` | T7-09 |
| `aplikasi/src/layar/laporan/LaporanMenu.tsx` | T7-09 |
| `aplikasi/src/layar/laporan/FormatLaporan.tsx` | T7-10 |
| `supabase/tes/tengah_malam.sql` | T7-11 |
| `supabase/tes/golden_laporan.sql` | T7-12 |
| `supabase/migrations/0054_katalog_publik.sql` | T8-01 |
| `supabase/tes/katalog_publik.sql` | T8-01 |
| `aplikasi/src/layar/pelanggan-publik/Katalog.tsx` | T8-02 |
| `aplikasi/src/layar/pelanggan-publik/Menu.tsx` | T8-03 |
| `aplikasi/src/layar/pelanggan-publik/Menu.tsx` | T8-04 |
| `aplikasi/src/layar/pengaturan/TautanKatalog.tsx` | T8-05 |
| `aplikasi/src/layar/voucher/Kampanye.tsx` | T8-06 |
| `aplikasi/src/layar/voucher/Daftar.tsx` | T8-06 |
| `supabase/functions/verifikasi_pelanggan/index.ts` | T8-07 |
| `aplikasi/src/lib/emailNormalisasi.ts` | T8-07 |
| `supabase/tes/anti_email_palsu.sql` | T8-07 |
| `supabase/migrations/0055_voucher_terbit.sql` | T8-08 |
| `aplikasi/src/layar/voucher/KartuVoucher.tsx` | T8-08 |
| `aplikasi/src/layar/kasir/Voucher.tsx` | T8-09 |
| `aplikasi/src/layar/kasir/ScanVoucher.tsx` | T8-10 |
| `aplikasi/src/layar/pengaturan/Kampanye.tsx` | T8-11 |
| `supabase/migrations/0056_kampanye_aturan.sql` | T8-11 |
| `supabase/migrations/0057_pengaman_voucher.sql` | T8-12 |
| `supabase/tes/pengaman_voucher.sql` | T8-12 |
| `supabase/migrations/0058_laporan_voucher.sql` | T8-13 |
| `aplikasi/src/layar/laporan/LaporanVoucher.tsx` | T8-13 |
| `supabase/tes/voucher_lengkap.sql` | T8-14 |
| `aplikasi/uji/e2e/voucher.spec.ts` | T8-14 |
| `supabase/migrations/0017_privasi_pelanggan.sql` | T8-15 |
| `supabase/tes/privasi.sql` | T8-15 |
| `aplikasi/src/layar/pelanggan-publik/KebijakanPrivasi.tsx` | T8-15 |
| `aplikasi/src/layar/pengaturan/Identitas.tsx` | T9-01 |
| `supabase/migrations/0059_unggah_gambar.sql` | T9-01 |
| `aplikasi/src/layar/pengaturan/Tampilan.tsx` | T9-02 |
| `aplikasi/src/layar/pengaturan/Operasional.tsx` | T9-03 |
| `supabase/migrations/0060_pengaturan_operasional.sql` | T9-03 |
| `aplikasi/src/layar/pengaturan/Meja.tsx` | T9-04 |
| `aplikasi/src/layar/pengaturan/Menu.tsx` | T9-05 |
| `supabase/migrations/0061_urut_menu.sql` | T9-05 |
| `aplikasi/src/layar/pengaturan/MenuCabang.tsx` | T9-06 |
| `aplikasi/src/layar/pengaturan/MetodeBayar.tsx` | T9-07 |
| `aplikasi/src/layar/pengaturan/Izin.tsx` | T9-08 |
| `supabase/migrations/0062_kelola_izin.sql` | T9-08 |
| `aplikasi/src/layar/pengaturan/Cabang.tsx` | T9-09 |
| `supabase/migrations/0063_kelola_cabang.sql` | T9-09 |
| `aplikasi/src/layar/platform/Penyewa.tsx` | T9-10 |
| `supabase/functions/daftar_penyewa/index.ts` | T9-10 |
| `supabase/tes/daftar_penyewa.sql` | T9-10 |
| `aplikasi/src/layar/pengaturan/Pratinjau.tsx` | T9-11 |
| `supabase/tes/riwayat_tidak_berubah.sql` | T9-11 |
| `docs/uji/UJI_TERIMA_PENGATURAN.md` | T9-12 |
| `aplikasi/src/lib/antrean-offline.ts` | T10-01 |
| `aplikasi/src/hook/useAntrean.ts` | T10-01 |
| `supabase/migrations/0064_idempoten.sql` | T10-02 |
| `supabase/tes/idempoten.sql` | T10-02 |
| `aplikasi/src/komponen/StatusAntrean.tsx` | T10-03 |
| `aplikasi/uji/e2e/luring.spec.ts` | T10-04 |
| `supabase/tes/sisir_rls_akhir.sql` | T10-05 |
| `aplikasi/src/layar/pengaturan/SesiAktif.tsx` | T10-06 |
| `supabase/functions/akhiri_sesi/index.ts` | T10-06 |
| `docs/uji/AUDIT_KEAMANAN.md` | T10-07 |
| `supabase/migrations/0065_pg_cron.sql` | T10-08 |
| `alat/denyut.py` | T10-08 |
| `aplikasi/src/lib/pemulihan-sesi.ts` | T10-09 |
| `aplikasi/uji/e2e/mati-mendadak.spec.ts` | T10-09 |
| `docs/ops/PEMULIHAN_LISTRIK.md` | T10-09 |
| `docs/teknis/PEMULIHAN.md` | T10-10 |
| `.github/workflows/cadangan.yml` | T10-10 |
| `supabase/migrations/0066_versi_pengaturan.sql` | T10-11 |
| `supabase/tes/pengaturan_bersamaan.sql` | T10-11 |
| `aplikasi/src/layar/pengaturan/CabutAkses.tsx` | T10-12 |
| `supabase/tes/cabut_akses.sql` | T10-12 |
| `supabase/functions/ringkasan_harian/index.ts` | T10-13 |
| `supabase/migrations/0066_ringkasan_harian.sql` | T10-13 |
| `aplikasi/src/layar/laporan/Peringatan.tsx` | T10-13 |
| `supabase/tes/ringkasan.sql` | T10-13 |
| `docs/teknis/PEMULIHAN.md` | T10-15 |
| `docs/teknis/TINJAUAN_KEAMANAN_F10.md` | T10-16 |
| `supabase/tes/mfa.sql` | T10-16 |
| `aplikasi/uji/e2e/*.spec.ts` | T11-01 |
| `docs/uji/UJI_TERIMA_G1.md` | T11-02 |
| `docs/uji/UJI_CETAK_KEDAI_OASIS.md` | T11-03 |
| `docs/uji/UJI_PERANGKAT.md` | T11-04 |
| `docs/uji/AUDIT_TAMPILAN.md` | T11-05 |
| `alat/pantau_batas.py` | T11-06 |
| `docs/uji/KINERJA_DAN_BATAS.md` | T11-06 |
| `docs/ops/DEPLOY.md` | T11-07 |
| `aplikasi/src/layar/pengaturan/StatusPemakaian.tsx` | T11-08 |
| `supabase/functions/peringatan_batas/index.ts` | T11-08 |
| `docs/ops/PANDUAN_PEGAWAI.md` | T11-09 |
| `docs/ops/SERAH_TERIMA_G1.md` | T11-10 |
| `docs/teknis/PEMULIHAN.md` | T11-10 |
| `.github/workflows/e2e.yml` | T11-11 |
| `uji-e2e/*.spec.ts` | T11-11 |
| `docs/uji/NASKAH_JALAN.md` | T11-12 |
| `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` | T11-12 |
| `docs/uji/paket-audit/AUD-3-<tanggal>.md` | T11-13 |
| `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_pilot.md` | T11-13 |
| `docs/uji/NASKAH_JALAN.md` | T11-13 |
| `python3 alat/periksa-roadmap.py` | T11-13 |

Jangan menghabiskan anggaran mencari berkas di tabel ini; pakai daftarnya hanya untuk menilai
apakah dokumen menjanjikan sesuatu yang belum ada.

## 2. Klaim pembangun yang harus kamu coba bantah

| # | Tugas | Klaim "Bukti" |
|---|---|---|
| 1 | T0-01 | `npm run dev` melayani halaman (HTTP 200), `main.tsx`, `tema.css`, dan berkas huruf (font/woff2); 7 folder layar + `supabase/{migrations,functions,tes}` ada; berkas huruf **19 berkas** `.woff2` di aplikasi (angka terhitung 2026-09-17; perintah yang bisa diulang: `find aplikasi/src/gaya/aset -name '*.woff2' | wc -l` (hu |
| 2 | T0-02 | ESLint 9.39 (typescript-eslint 8.70) + Prettier 3.9 + TypeScript 5.7 ketat (`strict`, `noUnusedLocals`, `noUnusedParameters`); gerbang dibuktikan menyala lewat uji mutasi — berkas dengan `any` ditolak lint, berkas dengan salah tipe ditolak `tsc -b --noEmit`, berkas belum diformat ditolak `format:check`; sesudah dibersi |
| 3 | T0-03 | `tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css` (diperiksa otomatis), 19 berkas huruf tersalin dan semua rujukan `url()` di dalamnya ada di disk; 10 kode tema di `src/lib/tema.ts` sama persis dengan kode tema di token (diperiksa otomatis); warna `theme-color` peramban diambil dari token `--accent`, b |
| 4 | T0-04 | `uji-kontras.py` versi aplikasi **166 lolos · 0 gagal** (130 pemeriksaan warna 10 tema + 36 aturan desain, termasuk tinggi sentuh ≥44 px); 10 komponen ada dan diperiksa `aplikasi/alat/periksa-komponen-env.py`; **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah yang bisa diulang: `cd aplikasi && npm t |
| 5 | T0-05 | `.env.example` memuat **semua 8 nama variabel** dari TECH_SPEC §6 (diperiksa otomatis dari dokumen, bukan dari daftar manual), hanya `VITE_SUPABASE_URL` & `VITE_SUPABASE_ANON_KEY` yang aktif (dua-duanya aman publik), variabel rahasia sengaja tidak berawalan `VITE_` dan hanya dikomentari; `git check-ignore` membuktikan  |
| 6 | T0-06 | folder `aplikasi/` disalin ke tempat bersih (tanpa `node_modules`/`dist`), lalu `npm ci` → Prettier → ESLint → TypeScript → **76 uji** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`) → build: **semuanya hijau** mengikuti langkah di README; README memuat prasyarat, cara menjalankan, peta folder, daftar  |
| 7 | T0-07 | CI menyala di setiap push & pull request; gerbangnya benar-benar bekerja — (a) run 35121292973 **MERAH di langkah ESLint** saat sengaja dipasang variabel tidak terpakai (kode ujinya lalu dihapus), (b) run 35120922393 merah karena folder layar kosong tidak ikut Git, (c) run 35121062046 merah karena satu berkas Markdown  |
| 8 | T0-10 | **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`; jumlah berkas uji bertambah bersama fase berikutnya) (uang/tanggal/jam · tema & kerapatan · pembacaan pengaturan · jam berdenyut · pemilih tema dengan jsdom · 17 uji komponen · layar contoh); kerangka siap untuk kode uang/ |
| 9 | T1-01 | migrasi `0001` diterapkan pada PostgreSQL asli lalu diuji `supabase/tes/rls_penyewa.sql` — pengunjung belum masuk melihat **0 baris** penyewa & cabang, kasir resto A hanya melihat **1 penyewa & 2 cabangnya**, kasir resto B **tidak melihat satu baris pun** milik resto A; perintah ubah cabang dari resto lain **tidak meng |
| 10 | T1-02 | `supabase/tes/rls_pengguna.sql` — kasir hanya melihat **baris dirinya sendiri**, admin cabang Pusat melihat **3 pegawai** cabangnya (bukan yang hanya bertugas di Cabang Dua), owner pusat melihat **seluruh pegawai restonya** dan **0 pegawai resto lain**; izin hanya terlihat oleh yang berhak (kasir **2 baris miliknya**,  |
| 11 | T1-03 | `supabase/migrations/0003_helper_identitas.sql` + `supabase/tes/helper.sql` — diuji untuk **7 akun** (pemilik platform, owner pusat, admin cabang, kasir, pelayan merangkap dua cabang, dapur, kasir resto lain): pemilik platform tidak punya penyewa/cabang, owner pusat punya penyewa tanpa cabang, pelayan mengembalikan **2 |
| 12 | T1-04 | `supabase/migrations/0004_pola_rls.sql` + `supabase/tes/rls_semua_tabel.sql`. Uji ini **membaca katalog PostgreSQL**, tidak menyebut nama tabel satu per satu — jadi tabel baru di fase mana pun otomatis diperiksa (RLS aktif · punya policy · yang punya `penyewa_id` wajib menyebut `penyewa_saya()`), plus pemindaian pemboc |
| 13 | T1-05 | `supabase/migrations/0005_izin_berjenjang.sql` + `supabase/tes/izin.sql`. Kamus resmi **10 kode izin** (`izin_kode`) dan **izin bawaan per peran** (`izin_peran`, 50 baris per resto, dipasang otomatis untuk resto baru lewat pemicu). Gerbang tunggal **`boleh(aksi)` / `boleh(aksi, nominal)` / `boleh(aksi, nominal, persen) |
| 14 | T1-06 | `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`. PIN disimpan **hanya sebagai hash** (`crypt(pin, gen_salt('bf', 10))`) dan database **menolak sendiri** nilai yang bukan berbentuk hash lewat batas (CHECK) — dibuktikan uji: perintah m |
| 15 | T1-07 | `supabase/migrations/0007_katalog.sql` + `supabase/tes/katalog.sql` + data uji katalog/stok. Tujuh tabel baru (`kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`) — seluruhnya RLS aktif + berpolicy (**16 tabel** saat itu; hari ini **26 tabel** — perintah: `selec |
| 16 | T1-08 | `supabase/migrations/0008_meja.sql` + `supabase/tes/meja.sql` + data uji meja di 3 cabang. Meja terpisah per cabang dan **nama meja unik per cabang** — dibuktikan langsung: nama “Meja 5” berhasil dipakai di **dua cabang berbeda**, sedangkan nama yang sama **ditolak** di cabang yang sama; uji mutasi “nama meja dijadikan |
| 17 | T1-09 | `supabase/migrations/0009_pesanan.sql` + `supabase/tes/pesanan.sql`. Tabel `pesanan` + `pesanan_item` dengan **salinan beku** `nama_saat_itu` & `harga_saat_itu` (WAJIB/NOT NULL). **Inti ART-3 dibuktikan langsung:** harga Nasi Goreng dinaikkan 25.000 → 31.000 (dan harga cabang 27.000 → 33.000) **setelah** pesanan dibuat |
| 18 | T1-10 | `supabase/migrations/0010_pembayaran.sql` + `supabase/tes/pembayaran.sql` + data uji pesanan berisi uang. Empat tabel baru: `pembayaran` (banyak baris per pesanan = pembayaran terbagi), `metode_bayar` (per resto, **4 metode bawaan dipasang otomatis** untuk resto baru), `diskon_transaksi`, `pembatalan` — total **23 tabe |
| 19 | T1-23 | `supabase/migrations/0011_peran_tunggal.sql` (migrasi BARU; 0002/0005 dibekukan) · uji `supabase/tes/peran_tunggal.sql` (baru), `supabase/tes/kredensial_pin.sql` §5, `supabase/tes/pin_batas_pasang.sql` (baru), `supabase/tes/izin.sql` §8 diganti. **Peran tunggal:** kolom `pengguna_cabang.peran` dihapus (peran kedua must |

## 3. Lensa wajib (jalankan semua, satu bagian per lensa)

- **L1 Ancaman & Akses** — Bisakah orang tanpa hak masuk/naik peran? Sesi/perangkat yang dicabut masih bisa dipakai? Ada fungsi istimewa (security definer) yang bisa dipanggil siapa saja? Ada jalur membaca data penyewa lain?
- **L2 Uang & Jejak** — Bisakah angka uang dibuat/ubah/hapus dari klien? Pembayaran dobel? Void tanpa jejak? Diskon lewat batas? Kas tanpa shift? Apakah jejak audit benar-benar tak bisa diubah dan bisa mendeteksi penghapusan?
- **L3 Kesepakatan Dokumen** — Setiap janji PRD/TECH_SPEC punya kode DAN uji? Setiap klaim 'Bukti' di ROADMAP bisa direproduksi hari ini? Ada syarat tanpa uji (orphan requirement) atau uji tanpa syarat (orphan test)?
- **L4 Mutu Uji** — Ada uji yang lulus karena sebab yang salah? Negatif-test yang bisa ditolak banyak sebab? Uji tanpa pemeriksaan? Gerbang yang belum pernah dibuktikan bisa MERAH? Ada pemeriksa yang tumpul (selalu hijau)?
- **L5 Lapangan & UI** — Alur nyata di tablet kasir bisa selesai? Tujuh keadaan tertangani? Ada tombol tanpa fungsi atau aksi tanpa tombol? Pesan galat bahasa manusia + kode? Target sentuh & kontras? Printer/offline?
- **L6 Privasi & Kepatuhan** — Data pelanggan seminimal mungkin? Persetujuan sebelum simpan? Anonimisasi tanpa menghapus catatan keuangan? Jalur kebocoran 3×24 jam siap? Rahasia tidak pernah masuk repo/log?

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
# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-18

- **Auditor:** <nama sesi/model yang benar-benar dipakai>
- **Tanggal:** 2026-09-18
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `cdd80b6724845663103cde132273919a4636e2d4` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-18.md`
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
Saya hanya-baca. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah.
Bukti: perintah `git status --short` yang saya jalankan menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")
| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
```

**Aturan penulisan laporan (ditegakkan, bukan imbauan):**
- **Ambang minimum adalah LANTAI, bukan target.** Jangan berhenti setelah mencapai angka minimum, dan jangan
  menambah baris demi memenuhi syarat. Kalau kamu menemukan 30 hal, tulis 30.
- **Semua temuan wajib dilaporkan — termasuk yang di luar cakupan/lingkup tugas.** Cakupan menentukan sedalam apa
  sesuatu **wajib** diperiksa, bukan apa yang **boleh** kamu laporkan. Temuan yang tidak masuk lensa/cakupan tetap
  masuk **bagian 8** dengan buktinya, supaya tidak hilang.
- **Jangan menyusun laporan agar lolos pemeriksa.** Format sudah lengkap di paket ini; kamu tidak perlu membaca
  kode alat pemeriksa (`alat/audit-independen.py`) untuk menyesuaikannya. Jalankan pemeriksa **sekali di akhir**;
  bila ditolak, perbaiki **kelengkapan format**, bukan menambah temuan yang tidak kamu yakini.

## 7. Kalibrasi cacat tanaman (khusus AUD-3)

Bahan kalibrasi ada **di dalam repo ini** (folder yang disebut §0b di atas) dan berisi **cacat yang sengaja ditanam**;
kunci jawabannya disimpan **di luar repo** dan tidak boleh kamu cari. Isi `## 5. Kalibrasi cacat tanaman` dengan daftar
cacat yang kamu temukan (`berkas` + kelas + bukti), `Ditemukan: X dari Y`, dan jumlah temuan palsu.
**Kalibrasi ini menentukan apakah verdict BERSIH-mu boleh dipercaya.** Cacat di folder bahan **tidak** dihitung sebagai temuan proyek.
