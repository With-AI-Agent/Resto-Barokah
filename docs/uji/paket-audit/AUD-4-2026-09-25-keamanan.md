# PAKET AUDIT INDEPENDEN — AUD-4 — 2026-09-25

> Dibuat mesin oleh `alat/audit-independen.py`. Berkas ini **untuk auditor** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`.

> **CARA PAKAI — untuk pemilik (3 langkah, mudah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas ini** ke chat baru itu.
> 3. Susulkan **kalimat pembuka auditor** dari buku induk `PANDUAN_PENGGUNA.md` **Bagian C4** (sama persis dengan
>    `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B) — satu blok, apa adanya, tidak perlu diubah.
> Setelah auditor selesai, kembali ke sesi kerja dan bilang: **"Laporan audit sudah masuk, periksa."**

- **Tingkat audit:** AUD-4
- **Commit yang diaudit:** `804ed86f3464490d5bc6c466b7e268d138b78e5e` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **CI commit target:** BELUM-HIJAU (BELUM HIJAU — 1 run CI pada commit itu: failure)
- **Izin pemilik untuk commit non-hijau:** fase 7 tuntas, 13 temuan AUD-3 ditutup, persiapan audit putaran kedua Agent A Keamanan
- **Tugas dalam lingkup:** T0-00, T0-01, T0-02, T0-03, T0-04, T0-05, T0-06, T0-07, T0-08, T0-09, T0-10, T0-11, T0-12, T0-13, T0-14, T1-01, T1-02, T1-03, T1-04, T1-05, T1-06, T1-07, T1-08, T1-09, T1-10, T1-11, T1-12, T1-13, T1-14, T1-15, T1-16, T1-17, T1-18, T1-19, T1-20, T1-21, T1-22, T1-23, T1-24, T1-25, T1-26, T1-27, T1-28, T1-29, T1-30, T1-31, T1-32, T1-33, T1-34, T1-35, T1-36, T1-37, T1-38, T1-39, T1-40, T1-41, T1-42, T1-43, T1-44, T1-45, T2-01, T2-02, T2-03, T2-04, T2-05, T2-06, T2-07, T2-08, T2-09, T2-10, T2-11, T2-12, T2-13, T2-14, T2-15, T2-16, T2-17, T2-18, T2-19, T3-01, T3-02, T3-03, T3-04, T3-05, T3-06, T3-07, T3-08, T3-09, T3-10, T3-11, T3-12, T3-13, T3-14, T3-15, T3-16, T4-01, T4-02, T4-03, T4-04, T4-05, T4-06, T4-07, T4-08, T4-09, T4-10, T5-01, T5-02, T5-03, T5-04, T5-05, T5-06, T5-07, T5-08, T5-09, T5-10, T5-11, T5-12, T6-01, T6-02, T6-03, T6-04, T6-05, T6-06, T6-07, T6-08, T7-01, T7-02, T7-03, T7-04, T7-05, T7-06, T7-07, T7-08, T7-09, T7-10, T7-11, T7-12, T8-01, T8-02, T8-03, T8-04, T8-05, T8-06, T8-07, T8-08, T8-09, T8-10, T8-11, T8-12, T8-13, T8-14, T8-15, T9-01, T9-02, T9-03, T9-04, T9-05, T9-06, T9-07, T9-08, T9-09, T9-10, T9-11, T9-12, T10-01, T10-02, T10-03, T10-04, T10-05, T10-06, T10-07, T10-08, T10-09, T10-10, T10-11, T10-12, T10-13, T10-14, T10-15, T10-16, T11-01, T11-02, T11-03, T11-04, T11-05, T11-06, T11-07, T11-08, T11-09, T11-10, T11-11, T11-12, T11-13
- **Lensa wajib:** L1, L2, L3, L4, L5, L6
- **Mode cakupan:** bidang-keamanan
- **Minimum laporan:** ≥8 artefak diperiksa · ≥5 klaim dibantah · ≥15 serangan dijalankan · masing-masing temuan punya perintah bukti
- **Perintah validasi laporan (wajib hijau):** periksa dengan alat `alat/audit-independen.py --periksa-laporan` (berkas laporan ditulis di folder docs/uji/audit/). Bila repo yang kamu pakai adalah klon dangkal, alat akan memberi CATATAN (bukan menolak) untuk SHA yang riwayatnya tidak ada.

## 0a. LANGKAH 0 (WAJIB) — ambil bahannya dulu, lalu pastikan kamu memeriksa commit yang benar

Paket ini menargetkan commit **`804ed86f3464490d5bc6c466b7e268d138b78e5e`** pada cabang **`arena/01a0d09b-resto-barokah`**. **Cabang/base apa pun yang Lee pilih tidak masalah** —
yang menentukan adalah commit-nya.

Baca objek target tanpa pindah cabang. Bila perlu pohon berkas untuk pengujian,
buat salinan sementara unik; JANGAN checkout/detach pada working tree bersama:

```sh
git fetch --no-write-fetch-head origin 804ed86f3464490d5bc6c466b7e268d138b78e5e
TARGET="$(mktemp -d)"
git archive 804ed86f3464490d5bc6c466b7e268d138b78e5e | tar -x -C "$TARGET"
```

Jalankan pemeriksaan target di salinan tersebut; catat SHA objek sumbernya, bukan
HEAD checkout lain. Metadata Git/perintah yang membutuhkan riwayat harus memakai
repositori terisolasi dari target (tanpa mengganti cabang sesi). Kalau akses gagal,
berhenti dan laporkan — jangan mengaudit commit lain atau mengklaim lengkap.

- Tulis di kepala laporan: `- **Commit yang diaudit:** <commit yang benar-benar kamu periksa>`.

## 0c. Setelah laporan selesai — kirim ke sesi kerja (wajib)

Tanpa meminta Lee lagi, buat, validasi, **commit dan push otomatis** SATU laporan,
lalu **verifikasi remote**. Chat/lokal saja bukan selesai. Dua sesi bisa berbagi
cabang DAN working tree; nama cabang bukan ID unik. Jangan checkout, git add folder,
merge, rebase, reset, force-push, menimpa laporan, atau menyatukan verdict.

Akses paket privat melalui git/gh terautentikasi: identitas repo + cabang sumber +
SHA paket penuh + path pada prompt pendek. SHA paket BUKAN SHA target audit.
Baca paket SELURUHNYA; URL hanya tambahan (web tool tidak mewarisi autentikasi git/gh).
Jika akses/sasaran gagal, berhenti dan laporkan keterbatasan, jangan menebak/minta token.

Ambil alat pengirim dari **SHA paket pada prompt pendek**, bukan target audit yang
lebih tua. Tetap jalankan dari checkout cabang SESIMU SENDIRI, bukan salinan target:

```sh
SHA_PAKET=<SHA-paket-penuh-dari-prompt-pendek>
git fetch --no-write-fetch-head origin "$SHA_PAKET"
RUNNER="$(mktemp -d)"
git show "$SHA_PAKET:alat/kirim_laporan.py" > "$RUNNER/kirim_laporan.py"
git show "$SHA_PAKET:alat/kirim-laporan.py" > "$RUNNER/kirim-laporan.py"
python3 "$RUNNER/kirim-laporan.py" --jenis audit --sumber arena/01a0d09b-resto-barokah --siapkan
```

`--siapkan` mengalokasikan draf `LAPORAN_*_<UUID>.md` secara eksklusif di
`.laporan-lokal/` (diabaikan Git). Catat path keluaran sebagai LAPORAN; isi hanya
laporanmu, jangan mengedit milik penulis lain. Validasi format dengan pemeriksa
paket pada salinan terisolasi; perubahan orang lain di checkout bersama bukan
alasan untuk membersihkannya. Draf/cadangan dan salinan uji boleh dibuat, kode proyek
asli tidak boleh diubah. Setelah validasi, langsung kirim tanpa menunggu Lee:

```sh
python3 "$RUNNER/kirim-laporan.py" --jenis audit --sumber arena/01a0d09b-resto-barokah --laporan "$LAPORAN"
```

Pengirim menyimpan snapshot sebelum jaringan; membuat commit **satu tambahan**
laporan bernama hash isi, dalam Git/index sementara; normal push fast-forward saja.
Jika didahului penulis lain, ambil tip remote lalu buat kandidat BELUM TERBIT lagi
(maksimal 5 upaya, bukan rebase/merge); jangan menyentuh HEAD/index/berkas bersama.
Jika cabang belum ada, dasar lokal harus sudah bisa diambil dari origin. Bila
riwayat mundur, path berbeda isi/mode, akses/izin hilang, atau upaya habis: **TERBLOKIR,
pengiriman BELUM TERVERIFIKASI**. Pertahankan snapshot dan berikan path/hambatan/jalur
pemulihan kepada integrator; jangan klaim selesai, jangan meminta sandi/token.
Pemulihan oleh integrator hanya untuk hambatan nyata, bukan antrean wajib normal.

Bukti akhir WAJIB: **repo, cabang tujuan, path laporan, commit SHA, remote_tip,
SHA-256 dan hasil verifikasi remote** dari pengirim. Pemeriksaan membaca ulang ref
langsung dan membandingkan blob/byte di GitHub; exit push saja bukan bukti.
HEAD lokal sengaja tetap: jangan pull/commit ulang, sinkronisasi kelak fast-forward
hanya jika working tree aman. Transport terverifikasi bukan pengesahan isi/verdict.


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


## 0. LINGKUP BIDANG: KEAMANAN (audit menyeluruh yang DIPERSEMPIT ke berkas bidang ini)

- **Jumlah berkas dalam lingkup:** 205
- **Mode cakupan yang wajib kamu tulis di laporan:** `bidang-keamanan`
- **Sumber angka:** pohon commit `804ed86f3464490d5bc6c466b7e268d138b78e5e` (`git ls-tree -r --name-only`), BUKAN meja kerja — berkas yang belum di-commit TIDAK masuk hitungan (B F-16).
- **Berkas paket ini:** `docs/uji/paket-audit/AUD-4-2026-09-25-keamanan.md` dibuat SETELAH angka di atas dihitung — ia TIDAK masuk hitungan; kalau dihitung pun ia masuk grup `docs/uji`.

**Prefiks berkas bidang keamanan (definisi mesin):**
- `supabase/`
- `.github/workflows/`
- `docs/KEAMANAN.md`
- `alat/periksa-rahasia.py`
- `alat/periksa-kunci-kalibrasi.py`
- `alat/uji-edge-pin.mjs`
- `aplikasi/src/lib/`

Lingkup menentukan berkas yang **wajib** diperiksa sedalam-dalamnya. Temuan di LUAR lingkup
**tetap wajib dilaporkan** (bagian 8) — lingkup bukan izin untuk diam.

**Grup berkas yang wajib kamu sentuh (minimal satu baris bukti per grup):**

| Grup | Isi | Jumlah berkas | Contoh |
|---|---|---|---|
| aplikasi/src | kode aplikasi (layar, komponen, lib, uji) | 30 | `aplikasi/src/lib/aksi.test.ts`, `aplikasi/src/lib/aksi.ts` … |
| supabase/migrations | migrasi database | 59 | `supabase/migrations/.gitkeep`, `supabase/migrations/0001_penyewa_cabang.sql` … |
| supabase/tes | uji SQL | 105 | `supabase/tes/.gitkeep`, `supabase/tes/anti_dobel.sql` … |
| supabase/functions | Edge Functions | 2 | `supabase/functions/.gitkeep`, `supabase/functions/verifikasi_pin/index.ts` |
| supabase (akar) | berkas di akar supabase/ (README cara memasang migrasi) | 2 | `supabase/README.md`, `supabase/config.toml` |
| alat | perkakas repo (uji SQL, pemeriksa, mekanisme audit) | 3 | `alat/periksa-kunci-kalibrasi.py`, `alat/periksa-rahasia.py` … |
| docs (fondasi) | PRD, TECH_SPEC, ROADMAP, KEAMANAN, SPESIFIKASI_UI, dll | 1 | `docs/KEAMANAN.md` |
| .github/workflows | alur CI | 3 | `.github/workflows/ci.yml`, `.github/workflows/sebar-halaman.yml` … |

**Dikecualikan dari lingkup (dan wajib kamu setujui/tolak dengan alasan):**

- `skills/` (1803 berkas) — kumpulan skill pihak ketiga (vendored) — bukan kode proyek; dipakai, tidak diubah
- `_salinan-meta/` (2 berkas) — arsip provenance sistem
- `_Notes.md` (1 berkas) — catatan pribadi pemilik (tidak ikut template)

**Kewajiban khusus mode menyeluruh (divalidasi mesin):**
1. Tulis di kepala laporan: `- **Mode cakupan:** menyeluruh`.
2. Tulis ringkasan: `Cakupan bidang-keamanan: X dari 205 berkas` (X = berkas yang benar-benar kamu periksa).
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
| 1 | `aplikasi/src/lib/tema.ts` |
| 2 | `aplikasi/src/lib/env.ts` |
| 3 | `.github/workflows/ci.yml` |
| 4 | `aplikasi/src/lib/supabase.ts` |
| 5 | `aplikasi/src/lib/supabase.test.ts` |
| 6 | `.github/workflows/sebar-skema.yml` |
| 7 | `.github/workflows/sebar-halaman.yml` |
| 8 | `aplikasi/src/lib/format.test.ts` |
| 9 | `aplikasi/src/lib/tema.test.ts` |
| 10 | `aplikasi/src/lib/env.test.ts` |
| 11 | `supabase/migrations/0001_penyewa_cabang.sql` |
| 12 | `supabase/tes/rls_penyewa.sql` |
| 13 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql` |
| 14 | `supabase/tes/rls_pengguna.sql` |
| 15 | `supabase/migrations/0003_helper_identitas.sql` |
| 16 | `supabase/tes/helper.sql` |
| 17 | `supabase/migrations/0004_pola_rls.sql` |
| 18 | `supabase/tes/rls_semua_tabel.sql` |
| 19 | `supabase/migrations/0005_izin_berjenjang.sql` |
| 20 | `supabase/tes/izin.sql` |
| 21 | `supabase/migrations/0006_pin.sql` |
| 22 | `supabase/functions/verifikasi_pin/index.ts` |
| 23 | `supabase/tes/pin.sql` |
| 24 | `supabase/tes/percobaan_pin_perangkat.sql` |
| 25 | `supabase/migrations/0007_katalog.sql` |
| 26 | `supabase/tes/katalog.sql` |
| 27 | `supabase/migrations/0008_meja.sql` |
| 28 | `supabase/tes/meja.sql` |
| 29 | `supabase/migrations/0009_pesanan.sql` |
| 30 | `supabase/tes/pesanan.sql` |
| 31 | `supabase/migrations/0010_pembayaran.sql` |
| 32 | `supabase/tes/pembayaran.sql` |
| 33 | `supabase/migrations/0020_catatan_audit.sql` |
| 34 | `supabase/migrations/0029_audit_kekal_rantai.sql` |
| 35 | `supabase/tes/catatan_audit.sql` |
| 36 | `supabase/tes/audit_rantai.sql` |
| 37 | `supabase/migrations/0014_penutup_celah_putaran13.sql` |
| 38 | `supabase/tes/urutan_uang.sql` |
| 39 | `supabase/tes/gerbang_uang.sql` |
| 40 | `supabase/tes/diskon_voucher.sql` |
| 41 | `docs/KEAMANAN.md` |
| 42 | `supabase/migrations/0011_peran_tunggal.sql` |
| 43 | `supabase/tes/peran_tunggal.sql` |
| 44 | `supabase/tes/kredensial_pin.sql` |
| 45 | `supabase/tes/pin_batas_pasang.sql` |
| 46 | `supabase/migrations/0018_perangkat_terdaftar.sql` |
| 47 | `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql` |
| 48 | `supabase/tes/perangkat_registrasi.sql` |
| 49 | `supabase/tes/sesi_dan_perangkat.sql` |
| 50 | `supabase/migrations/0031_mode_dukungan_platform.sql` |
| 51 | `supabase/tes/mode_dukungan.sql` |
| 52 | `supabase/tes/matriks_izin_6_peran.sql` |
| 53 | `alat/periksa-rahasia.py` |
| 54 | `supabase/tes/keamanan_fungsi.sql` |
| 55 | `supabase/migrations/0023_acl_fungsi_pemicu.sql` |
| 56 | `supabase/migrations/0027_initplan_policy_rls.sql` |
| 57 | `aplikasi/src/lib/layar.ts` |
| 58 | `aplikasi/src/lib/aksi.ts` |
| 59 | `supabase/migrations/0028_pemulihan_perangkat.sql` |
| 60 | `supabase/tes/pemulihan.sql` |
| 61 | `supabase/migrations/0022_beku_setelah_bayar.sql` |
| 62 | `supabase/migrations/0015_penutup_celah_putaran16.sql` |
| 63 | `alat/uji-edge-pin.mjs` |
| 64 | `alat/periksa-kunci-kalibrasi.py` |
| 65 | `supabase/tes/pin_helper_pribadi.sql` |
| 66 | `supabase/tes/nomor_pesanan_kunci.sql` |
| 67 | `supabase/tes/status_item_transisi.sql` |
| 68 | `supabase/tes/uang_peladen.sql` |
| 69 | `supabase/tes/metode_bayar_nonaktif.sql` |
| 70 | `supabase/tes/pembatalan_sekali.sql` |
| 71 | `supabase/tes/lifecycle_pesanan.sql` |
| 72 | `supabase/tes/nomor_pesanan_isolasi.sql` |
| 73 | `supabase/tes/pin_bukan_oracle.sql` |
| 74 | `supabase/tes/diskon_sesudah_lunas.sql` |
| 75 | `supabase/tes/void_satu_item.sql` |
| 76 | `supabase/tes/pembatalan_penanda_palsu.sql` |
| 77 | `aplikasi/src/lib/auth.ts` |
| 78 | `aplikasi/src/lib/auth.test.ts` |
| 79 | `aplikasi/src/lib/pesan.ts` |
| 80 | `aplikasi/src/lib/pesan.test.ts` |
| 81 | `aplikasi/src/lib/format.ts` |
| 82 | `supabase/migrations/0035_menu_habis_sumber.sql` |
| 83 | `supabase/migrations/0032_status_item_dapur.sql` |
| 84 | `supabase/migrations/0033_tujuan_item.sql` |
| 85 | `supabase/tes/status_item.sql` |
| 86 | `supabase/tes/menu_habis_sumber.sql` |
| 87 | `supabase/migrations/0036_stok.sql` |
| 88 | `supabase/migrations/0037_opname.sql` |
| 89 | `supabase/tes/anti_dobel.sql` |
| 90 | `supabase/migrations/0039_bayar_pesanan.sql` |
| 91 | `supabase/tes/bayar_pesanan.sql` |
| 92 | `supabase/tes/pajak_service.sql` |
| 93 | `supabase/migrations/0019_pesan_diskon_jujur.sql` |
| 94 | `supabase/tes/diskon_tumpuk.sql` |
| 95 | `supabase/migrations/0041_diskon_pin_atasan.sql` |
| 96 | `supabase/tes/diskon_pin_atasan.sql` |
| 97 | `supabase/migrations/0042_bahan_terbuang_jujur.sql` |
| 98 | `supabase/tes/bahan_terbuang.sql` |
| 99 | `supabase/tes/pembayaran_sebagian.sql` |
| 100 | `supabase/migrations/0043_laporan_pembatalan.sql` |
| 101 | `aplikasi/src/lib/printer/expos.ts` |
| 102 | `aplikasi/src/lib/printer/expos.test.ts` |
| 103 | `aplikasi/src/lib/printer/kirim.ts` |
| 104 | `aplikasi/src/lib/printer/profil.ts` |
| 105 | `aplikasi/src/lib/printer/struk.ts` |
| 106 | `aplikasi/src/lib/printer/tiket.ts` |
| 107 | `supabase/migrations/0045_buka_shift.sql` |
| 108 | `supabase/migrations/0046_tutup_shift.sql` |
| 109 | `supabase/migrations/0047_kas_pergerakan.sql` |
| 110 | `supabase/migrations/0048_wajib_shift.sql` |
| 111 | `supabase/tes/wajib_shift.sql` |
| 112 | `supabase/migrations/0049_pengingat_shift.sql` |
| 113 | `supabase/migrations/0050_koreksi_modal.sql` |
| 114 | `supabase/migrations/0051_laporan_kas.sql` |
| 115 | `supabase/migrations/0052_laporan_penjualan.sql` |
| 116 | `supabase/migrations/0053_laporan_menu.sql` |
| 117 | `supabase/tes/tengah_malam.sql` |
| 118 | `supabase/tes/golden_laporan.sql` |
| 119 | `supabase/tes/beku_satu_pernyataan.sql` |
| 120 | `supabase/tes/beku_setelah_bayar.sql` |
| 121 | `supabase/tes/buka_shift.sql` |
| 122 | `supabase/tes/cabang_aktif_saya.sql` |
| 123 | `supabase/tes/cabang_sesi.sql` |
| 124 | `supabase/tes/diskon_cap.sql` |
| 125 | `supabase/tes/diskon_cap_bawaan.sql` |
| 126 | `supabase/tes/diskon_persen.sql` |
| 127 | `supabase/tes/diskon_setuju.sql` |
| 128 | `supabase/tes/hak_fungsi.sql` |
| 129 | `supabase/tes/harga_item.sql` |
| 130 | `supabase/tes/isolasi_lintas_penyewa.sql` |
| 131 | `supabase/tes/isolasi_null_identitas.sql` |
| 132 | `supabase/tes/item_penjaga.sql` |
| 133 | `supabase/tes/izin_efektif_untuk.sql` |
| 134 | `supabase/tes/jejak_pelaku.sql` |
| 135 | `supabase/tes/jejak_pengaturan.sql` |
| 136 | `supabase/tes/jejak_pesanan.sql` |
| 137 | `supabase/tes/kas_pergerakan.sql` |
| 138 | `supabase/tes/koreksi_modal.sql` |
| 139 | `supabase/tes/kupon_wajib_pesanan.sql` |
| 140 | `supabase/tes/laporan_kas.sql` |
| 141 | `supabase/tes/laporan_menu.sql` |
| 142 | `supabase/tes/laporan_pembatalan.sql` |
| 143 | `supabase/tes/laporan_penjualan.sql` |
| 144 | `supabase/tes/meja_penjaga.sql` |
| 145 | `supabase/tes/meja_riwayat.sql` |
| 146 | `supabase/tes/nilai_kerugian.sql` |
| 147 | `supabase/tes/opname_stok.sql` |
| 148 | `supabase/tes/pembayaran_audit.sql` |
| 149 | `supabase/tes/pembayaran_metode.sql` |
| 150 | `supabase/tes/pengingat_shift.sql` |
| 151 | `supabase/tes/penjaga_stok.sql` |
| 152 | `supabase/tes/perangkat_registrasi_tepi.sql` |
| 153 | `supabase/tes/percobaan_masuk_tenant.sql` |
| 154 | `supabase/tes/persetujuan_void.sql` |
| 155 | `supabase/tes/pesanan_status_awal.sql` |
| 156 | `supabase/tes/pesanan_tertutup_beku.sql` |
| 157 | `supabase/tes/pin_hierarki.sql` |
| 158 | `supabase/tes/pin_kunci_silang.sql` |
| 159 | `supabase/tes/pin_warisan.sql` |
| 160 | `supabase/tes/saldo_awal_stok.sql` |
| 161 | `supabase/tes/sesi_kedaluwarsa.sql` |
| 162 | `supabase/tes/set_stok.sql` |
| 163 | `supabase/tes/status_pesanan.sql` |
| 164 | `supabase/tes/stok_arah.sql` |
| 165 | `supabase/tes/stok_insert_langsung.sql` |
| 166 | `supabase/tes/truncate_audit_ditolak.sql` |
| 167 | `supabase/tes/tujuan_item.sql` |
| 168 | `supabase/tes/tutup_shift.sql` |
| 169 | `supabase/tes/uang_kunci.sql` |
| 170 | `supabase/tes/urutan_rantai_audit.sql` |
| 171 | `supabase/tes/varian_gagal_aman.sql` |
| 172 | `supabase/tes/verifikasi_pin_perangkat.sql` |
| 173 | `supabase/tes/waktu_peladen.sql` |


## 1a. Perintah bukti yang disebut tugas (JALANKAN bila perlu — ini BUKAN berkas hilang)

| # | Perintah (dari dokumen tugas) |
|---|---|
| 1 | `python3 aplikasi/alat/uji-kontras.py  →  aplikasi/alat/uji-kontras.py` |
| 2 | `python3 aplikasi/alat/periksa-komponen-env.py  →  aplikasi/alat/periksa-komponen-env.py` |
| 3 | `node
    aplikasi/alat/catat-alamat.mjs  →  aplikasi/alat/catat-alamat.mjs` |
| 4 | `python3 alat/periksa-roadmap.py  →  alat/periksa-roadmap.py` |
| 5 | `python3 alat/periksa-panduan.py  →  alat/periksa-panduan.py` |
| 6 | `python3 _sistem/validate_system.py  →  _sistem/validate_system.py` |
| 7 | `python3 alat/uji-mutasi-0012.py  →  alat/uji-mutasi-0012.py` |
| 8 | `node alat/uji-sql.mjs  →  alat/uji-sql.mjs` |
| 9 | `python3 alat/peta-ui.py  →  alat/peta-ui.py` |
| 10 | `python3 aplikasi/alat/periksa-bahasa.py  →  aplikasi/alat/periksa-bahasa.py` |
| 11 | `python3 alat/uji-mutasi-0015.py  →  alat/uji-mutasi-0015.py` |


> **Catatan mesin (F-12 audit 2026-09-18):** daftar di atas SUDAH disaring — hanya berkas
> yang **benar-benar ada** di commit ini. Jalur yang baru *direncanakan* ada di bagian 1b.
> Kalau kamu menemukan jalur di bagian 1 yang tidak ada, laporkan sebagai temuan mesin.

## 1b. Direncanakan — berkas yang BELUM ADA (JANGAN diperiksa sebagai bukti)

| Jalur yang dirujuk dokumen | Tugas |
|---|---|
| `docs/uji/paket-audit/AUD-3-<tanggal>.md` | T0-12 |
| `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_menyeluruh.md` | T0-12 |
| `supabase/migrations/0018_kas_shift.sql` | T1-11 |
| `supabase/migrations/0019_voucher.sql` | T1-12 |
| `supabase/migrations/0021_antrean_kesalahan.sql` | T1-14 |
| `supabase/migrations/0022_hitung_total.sql` | T1-15 |
| `supabase/tes/uang.sql` | T1-15 |
| `supabase/migrations/0023_urutan_pembulatan.sql` | T1-16 |
| `supabase/tes/urutan.sql` | T1-16 |
| `supabase/tes/penomoran.sql` | T1-17 |
| `supabase/migrations/0024_penomoran.sql` | T1-17 |
| `supabase/migrations/0025_state_machine.sql` | T1-18 |
| `supabase/tes/status.sql` | T1-18 |
| `supabase/migrations/0026_cek_voucher.sql` | T1-19 |
| `supabase/tes/cek_voucher.sql` | T1-19 |
| `supabase/migrations/0027_pakai_voucher.sql` | T1-20 |
| `supabase/tes/pakai_voucher.sql` | T1-20 |
| `supabase/seed.sql` | T1-21 |
| `supabase/seed_uji.sql` | T1-21 |
| `docs/uji/paket-audit/AUD-2-<tanggal>.md` | T1-38 |
| `docs/uji/audit/LAPORAN_AUD-2_<tanggal>_keamanan.md` | T1-38 |
| `alat/kalibrasi-cacat.json` | T1-45 |
| `/home/user/.kalibrasi/kalibrasi-cacat.json` | T1-45 |
| `aplikasi/src/lib/google.ts` | T2-04 (sudah [x] — berkasnya TIDAK ADA: laporkan!) |
| `supabase/migrations/0028_simpan_pesanan.sql` | T3-05 |
| `supabase/tes/simpan_pesanan.sql` | T3-05 |
| `aplikasi/src/layar/kasir/PeringatanMeja.tsx` | T3-09 |
| `supabase/tes/konflik_meja.sql` | T3-09 |
| `aplikasi/src/layar/kasir/BatalPesanan.tsx` | T3-13 |
| `supabase/migrations/0032_batal_pra_dapur.sql` | T3-13 |
| `supabase/migrations/0034_status_item.sql` | T4-04 |
| `aplikasi/uji/e2e/dapur.spec.ts` | T4-09 |
| `aplikasi/src/lib/printer/antrean.ts` | T6-06 |
| `aplikasi/src/komponen/StatusPrinter.tsx` | T6-06 |
| `supabase/migrations/0044_printer.sql` | T6-07 |
| `aplikasi/src/layar/pengaturan/PengaturanPrinter.tsx` | T6-07 |
| `docs/uji/UJI_CETAK_KEDAI_OASIS.md` | T6-08 |
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
| `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` | T11-12 |
| `docs/uji/paket-audit/AUD-3-<tanggal>.md` | T11-13 |
| `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_pilot.md` | T11-13 |

Jangan menghabiskan anggaran mencari berkas di tabel ini; pakai daftarnya hanya untuk menilai
apakah dokumen menjanjikan sesuatu yang belum ada.

## 2. Klaim pembangun yang harus kamu coba bantah

| # | Tugas | Klaim "Bukti" |
|---|---|---|
| 1 | T0-00 | pemilik (Lee) membuat akun **Supabase + Resend + Cloudflare**; nilai non-rahasia (URL proyek, kunci publik, id proyek, region **Singapore**, id akun Cloudflare) diserahkan lewat berkas `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`); kunci `service_role` tidak pernah masuk repo maupun obrolan; butir tun |
| 2 | T0-01 | `npm run dev` melayani halaman (HTTP 200), `main.tsx`, `tema.css`, dan berkas huruf (font/woff2); 7 folder layar + `supabase/{migrations,functions,tes}` ada; berkas huruf **19 berkas** `.woff2` di aplikasi (angka terhitung 2026-09-17; perintah yang bisa diulang: `find aplikasi/src/gaya/aset -name '*.woff2' | wc -l` (hu |
| 3 | T0-02 | ESLint 9.39 (typescript-eslint 8.70) + Prettier 3.9 + TypeScript 5.7 ketat (`strict`, `noUnusedLocals`, `noUnusedParameters`); gerbang dibuktikan menyala lewat uji mutasi — berkas dengan `any` ditolak lint, berkas dengan salah tipe ditolak `tsc -b --noEmit`, berkas belum diformat ditolak `format:check`; sesudah dibersi |
| 4 | T0-03 | `tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css` (diperiksa otomatis), 19 berkas huruf tersalin dan semua rujukan `url()` di dalamnya ada di disk; 10 kode tema di `aplikasi/src/lib/tema.ts` sama persis dengan kode tema di token (diperiksa otomatis); warna `theme-color` peramban diambil dari token `--a |
| 5 | T0-04 | `uji-kontras.py` versi aplikasi **166 lolos · 0 gagal** (130 pemeriksaan warna 10 tema + 36 aturan desain, termasuk tinggi sentuh ≥44 px); 10 komponen ada dan diperiksa `aplikasi/alat/periksa-komponen-env.py`; **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah yang bisa diulang: `cd aplikasi && npm t |
| 6 | T0-05 | `.env.example` memuat **semua 8 nama variabel** dari TECH_SPEC §6 (diperiksa otomatis dari dokumen, bukan dari daftar manual), hanya `VITE_SUPABASE_URL` & `VITE_SUPABASE_ANON_KEY` yang aktif (dua-duanya aman publik), variabel rahasia sengaja tidak berawalan `VITE_` dan hanya dikomentari; `git check-ignore` membuktikan  |
| 7 | T0-06 | folder `aplikasi/` disalin ke tempat bersih (tanpa `node_modules`/`dist`), lalu `npm ci` → Prettier → ESLint → TypeScript → **76 uji** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`) → build: **semuanya hijau** mengikuti langkah di README; README memuat prasyarat, cara menjalankan, peta folder, daftar  |
| 8 | T0-07 | CI menyala di setiap push & pull request; gerbangnya benar-benar bekerja — (a) run 35121292973 **MERAH di langkah ESLint** saat sengaja dipasang variabel tidak terpakai (kode ujinya lalu dihapus), (b) run 35120922393 merah karena folder layar kosong tidak ikut Git, (c) run 35121062046 merah karena satu berkas Markdown  |
| 9 | T0-08 | penanda terpasang → alur menyala lalu berhenti di gerbang rahasia (run `35433200326`); penanda dihapus → hijau tanpa kerja (run `35433237658`). **Bukti live 2026-09-19:** langkah itu benar-benar **hijau** di CI — run `35432334878` (langkah ke-11 "Cek sambungan Supabase (kunci publik saja — tugas T0-08)" = success; pran |
| 10 | T0-09 | penanda terpasang → alur menyala lalu berhenti di gerbang rahasia (run `35433200375`); penanda dihapus → hijau tanpa kerja (run `35433237656`). |
| 11 | T0-10 | **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`; jumlah berkas uji bertambah bersama fase berikutnya) (uang/tanggal/jam · tema & kerapatan · pembacaan pengaturan · jam berdenyut · pemilih tema dengan jsdom · 17 uji komponen · layar contoh); kerangka siap untuk kode uang/ |
| 12 | T1-01 | migrasi `0001` diterapkan pada PostgreSQL asli lalu diuji `supabase/tes/rls_penyewa.sql` — pengunjung belum masuk melihat **0 baris** penyewa & cabang, kasir resto A hanya melihat **1 penyewa & 2 cabangnya**, kasir resto B **tidak melihat satu baris pun** milik resto A; perintah ubah cabang dari resto lain **tidak meng |
| 13 | T1-02 | `supabase/tes/rls_pengguna.sql` — kasir hanya melihat **baris dirinya sendiri**, admin cabang Pusat melihat **3 pegawai** cabangnya (bukan yang hanya bertugas di Cabang Dua), owner pusat melihat **seluruh pegawai restonya** dan **0 pegawai resto lain**; izin hanya terlihat oleh yang berhak (kasir **2 baris miliknya**,  |
| 14 | T1-03 | `supabase/migrations/0003_helper_identitas.sql` + `supabase/tes/helper.sql` — diuji untuk **7 akun** (pemilik platform, owner pusat, admin cabang, kasir, pelayan merangkap dua cabang, dapur, kasir resto lain): pemilik platform tidak punya penyewa/cabang, owner pusat punya penyewa tanpa cabang, pelayan mengembalikan **2 |
| 15 | T1-04 | `supabase/migrations/0004_pola_rls.sql` + `supabase/tes/rls_semua_tabel.sql`. Uji ini **membaca katalog PostgreSQL**, tidak menyebut nama tabel satu per satu — jadi tabel baru di fase mana pun otomatis diperiksa (RLS aktif · punya policy · yang punya `penyewa_id` wajib menyebut `penyewa_saya()`), plus pemindaian pemboc |
| 16 | T1-05 | `supabase/migrations/0005_izin_berjenjang.sql` + `supabase/tes/izin.sql`. Kamus resmi **10 kode izin** (`izin_kode`) dan **izin bawaan per peran** (`izin_peran`, 50 baris per resto, dipasang otomatis untuk resto baru lewat pemicu). Gerbang tunggal **`boleh(aksi)` / `boleh(aksi, nominal)` / `boleh(aksi, nominal, persen) |
| 17 | T1-06 | `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`. PIN disimpan **hanya sebagai hash** (`crypt(pin, gen_salt('bf', 10))`) dan database **menolak sendiri** nilai yang bukan berbentuk hash lewat batas (CHECK) — dibuktikan uji: perintah m |
| 18 | T1-07 | `supabase/migrations/0007_katalog.sql` + `supabase/tes/katalog.sql` + data uji katalog/stok. Tujuh tabel baru (`kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`) — seluruhnya RLS aktif + berpolicy (**16 tabel** saat itu; hari ini **26 tabel** — perintah: `selec |
| 19 | T1-08 | `supabase/migrations/0008_meja.sql` + `supabase/tes/meja.sql` + data uji meja di 3 cabang. Meja terpisah per cabang dan **nama meja unik per cabang** — dibuktikan langsung: nama “Meja 5” berhasil dipakai di **dua cabang berbeda**, sedangkan nama yang sama **ditolak** di cabang yang sama; uji mutasi “nama meja dijadikan |
| 20 | T1-09 | `supabase/migrations/0009_pesanan.sql` + `supabase/tes/pesanan.sql`. Tabel `pesanan` + `pesanan_item` dengan **salinan beku** `nama_saat_itu` & `harga_saat_itu` (WAJIB/NOT NULL). **Inti ART-3 dibuktikan langsung:** harga Nasi Goreng dinaikkan 25.000 → 31.000 (dan harga cabang 27.000 → 33.000) **setelah** pesanan dibuat |
| 21 | T1-10 | `supabase/migrations/0010_pembayaran.sql` + `supabase/tes/pembayaran.sql` + data uji pesanan berisi uang. Empat tabel baru: `pembayaran` (banyak baris per pesanan = pembayaran terbagi), `metode_bayar` (per resto, **4 metode bawaan dipasang otomatis** untuk resto baru), `diskon_transaksi`, `pembatalan` — total **23 tabe |
| 22 | T1-13 | `supabase/migrations/0029_audit_kekal_rantai.sql` memasang trigger `catatan_audit_cegah_ubah_hapus` yang menolak mutlak segala UPDATE/DELETE; dibuktikan di `supabase/tes/audit_rantai.sql` & `alat/uji-mutasi-0029.py`. |
| 23 | T1-22 | sapuan = `supabase/tes/rls_semua_tabel.sql` (blok 1 RLS-wajib · blok 2 policy-wajib · blok 3 SETIAP-policy · blok 4 registri beralasan · blok 6 rantai transitif wajib); CI menjalankan suite penuh tiap push (langkah "uji SQL penuh", terkunci gerbang dua-arah); Verifikasi TERPENUHI dua arah — CI hijau + `alat/uji-mutasi- |
| 24 | T1-23 | `supabase/migrations/0011_peran_tunggal.sql` (migrasi BARU; 0002/0005 dibekukan) · uji `supabase/tes/peran_tunggal.sql` (baru), `supabase/tes/kredensial_pin.sql` §5, `supabase/tes/pin_batas_pasang.sql` (baru), `supabase/tes/izin.sql` §8 diganti. **Peran tunggal:** kolom `pengguna_cabang.peran` dihapus (peran kedua must |
| 25 | T1-24 | `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql` melengkapi seluruh DoD: `kode_pendaftaran_perangkat` (15 menit), `persetujuan_perangkat`, `buat_kode_perangkat()`, `daftarkan_perangkat_dengan_kode()`, `setujui_perangkat_pegawai()`, `cabut_perangkat()`; dibuktikan di `supabase/tes/sesi_dan_perangkat.sql` &  |
| 26 | T1-25 | `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql` mengimplementasikan tabel `sesi_perangkat`, RPC `ikat_sesi_perangkat()` (umur 12 jam staf, 30 hari admin, 8 jam owner), `keluar_semua_perangkat()`, dan pemutusan seketika saat perangkat dicabut; dibuktikan di `supabase/tes/sesi_dan_perangkat.sql` & `alat/uji |
| 27 | T1-26 | `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql` mengimplementasikan tabel `percobaan_masuk`, RPC `catat_percobaan_masuk()`, dan fungsi `periksa_kunci_masuk()`; dibuktikan di `supabase/tes/sesi_dan_perangkat.sql` & `alat/uji-mutasi-0030.py`. |
| 28 | T1-27 | `supabase/migrations/0029_audit_kekal_rantai.sql` mengimplementasikan rantai hash sha256 atomik per resto & RPC `verifikasi_rantai_audit()`; dibuktikan di `supabase/tes/audit_rantai.sql`, `alat/periksa-audit.py`, dan `alat/uji-mutasi-0029.py`. |
| 29 | T1-28 | `supabase/migrations/0031_mode_dukungan_platform.sql`, `supabase/tes/mode_dukungan.sql`, `alat/uji-mutasi-0031.py`. |
| 30 | T1-29 | `supabase/tes/matriks_izin_6_peran.sql`, `alat/periksa-matriks-izin.py`. |
| 31 | T1-31 | `aplikasi/src/lib/layar.ts` mendefinisikan kontrak 8 layar G1 lengkap dengan 7 keadaan, rute, peran, data, aksi, dan naskah jalan; diperiksa oleh `alat/peta-ui.py` (LOLOS). · **Bukti 2026-09-23 (registri diperluas):** 8 layar G1 tetap utuh + 3 layar Fase 4 (`bar`, `stok`, `opname`) kini terdaftar resmi — total **11 lay |
| 32 | T1-32 | `aplikasi/src/lib/aksi.ts` memuat 32 registri aksi; komponen `TombolAksi.tsx` menegakkan izin, konfirmasi dialog, dan penolakan ID tidak terdaftar; 7 uji unit (angka saat itu, perintah: `npm test`) di `TombolAksi.test.tsx` lulus 100%. |
| 33 | T1-33 | `alat/peta-ui.py` dibuat dan dipasang di CI (gerbang ke-85); `--periksa` LOLOS dan `--uji-diri` membuktikan 6 mutasi tertangkap pagar (RPC salah, izin salah, aksi tulis tanpa uji, layar tanpa peran, drift dokumen, tombol liar). |
| 34 | T1-34 | `harness.tsx` & `harness.test.tsx` menyediakan konteks peran/izin, data seed, dan perekam RPC tiruan; 3 uji unit lulus di Vitest; DoD UI ditegakkan di `docs/AGENT_OPERATING_GUIDE.md`. |
| 35 | T1-35 | `docs/uji/NASKAH_JALAN.md` mendefinisikan 15 naskah jalan pemilik untuk seluruh 8 layar G1 (`W-0-01` s/d `W-10-01`). --- |
| 36 | T1-36 | `supabase/migrations/0028_pemulihan_perangkat.sql`, `supabase/tes/pemulihan.sql` (13 skenario lolos), `alat/uji-mutasi-0028.py` (4 mutasi wajib MERAH terbukti), dan panduan operasional `docs/ops/PEMULIHAN_PERANGKAT.md`. |
| 37 | T1-39 | `docs/PETA_UI.md` berisi pemetaan 8 layar dan 32 aksi terverifikasi; matriks fitur PRD M1–M12 terhubung penuh. · **Bukti 2026-09-23:** `docs/PETA_UI.md` disegarkan menjadi **11 layar & 38 aksi** (6 aksi baru: `bar.mulai_buat`, `bar.selesai_buat`, `stok.catat_perubahan`, `stok.ke_opname`, `opname.catat_fisik`, `opname.k |
| 38 | T1-40 | 4 kamus bahasa (`id.ts`, `en.ts`, `zh.ts`, `ar.ts`) 100% paritas 102 kunci; context & hook `useBahasa()` + helper `t()` aktif; pemeriksa `periksa-bahasa.py` terpasang di CI; uji unit Vitest lulus. |
| 39 | T1-41 | `aplikasi/src/gaya/arah.css` mendefinisikan aturan logis LTR/RTL, selektor `[dir='rtl']`, dan variabel font Mandarin/Arab; `periksa-arah.py` membuktikan total ukuran font 461 KB (< 650 KB ambang batas) dan aturan arah lengkap. |
| 40 | T1-42 | `aplikasi/src/kontrak/bantuan.ts` mendefinisikan panduan kontekstual untuk seluruh 8 layar G1; komponen `LembarBantuan.tsx` terintegrasi; diperiksa otomatis oleh `alat/periksa-bantuan.py` di CI. · **Bukti 2026-09-23:** bantuan kontekstual ditambah untuk `bar`, `stok`, `opname` — `periksa-bantuan.py` melaporkan **11/11  |
| 41 | T1-43 | `docs/uji/BUKU_UJI_PEMILIK.md` berisi 18 butir (6 lakukan, 12 coba), skrip pembantu `alat/tambah-uji.py` (+ `--uji-diri`), dan validator `alat/periksa-buku-uji.py` aktif di CI. |
| 42 | T2-01 | `aplikasi/src/lib/auth.ts`, `aplikasi/src/hook/useSesi.ts`, `aplikasi/src/lib/auth.test.ts`, `aplikasi/src/hook/useSesi.test.tsx`. |
| 43 | T2-02 | `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`, `aplikasi/src/layar/masuk/LayarMasukPegawai.test.tsx`. |
| 44 | T2-03 | `aplikasi/src/layar/pengaturan/KelolaPegawai.tsx`, `aplikasi/src/layar/pengaturan/KelolaPegawai.test.tsx` (3 tes lulus). |
| 45 | T2-04 | `aplikasi/src/layar/masuk/LayarMasukPelanggan.tsx`, `aplikasi/src/layar/masuk/LayarMasukPelanggan.test.tsx` (3 tes lulus). |
| 46 | T2-05 | `aplikasi/src/layar/masuk/LupaAkses.tsx`, `aplikasi/src/layar/masuk/LupaAkses.test.tsx` (2 tes lulus). |
| 47 | T2-06 | `aplikasi/src/App.tsx`, `aplikasi/src/komponen/Rangka.tsx`, `aplikasi/src/komponen/Navigasi.tsx`, `aplikasi/src/komponen/Rangka.test.tsx`, `aplikasi/src/komponen/Navigasi.test.tsx`. |
| 48 | T2-07 | `aplikasi/src/hook/useCabang.ts`, `aplikasi/src/komponen/PemilihCabang.tsx`, `aplikasi/src/hook/useCabang.test.tsx`, `aplikasi/src/komponen/PemilihCabang.test.tsx`. |
| 49 | T2-08 | `aplikasi/src/layar/TidakPunyaAkses.tsx`, `aplikasi/src/lib/pesan.ts`, `aplikasi/src/layar/TidakPunyaAkses.test.tsx`, `aplikasi/src/lib/pesan.test.ts`. |
| 50 | T2-09 | `aplikasi/src/hook/useKunciOtomatis.ts`, `aplikasi/src/hook/useKunciOtomatis.test.tsx` (4 tes lulus). |
| 51 | T2-10 | `supabase/migrations/0028_pemulihan_perangkat.sql`, `supabase/tes/percobaan_pin_perangkat.sql` (lulus). |
| 52 | T2-11 | `aplikasi/public/manifest.webmanifest`, `aplikasi/public/sw.js`, `aplikasi/index.html`, `aplikasi/src/main.tsx`. |
| 53 | T2-12 | `aplikasi/src/layar/masuk/SkenarioMasukPeran.test.tsx` (8 tes lulus), `supabase/tes/matriks_izin_6_peran.sql`. |
| 54 | T2-13 | `aplikasi/src/layar/masuk/MasukPengelola.tsx`, `aplikasi/src/layar/masuk/MasukPengelola.test.tsx` (3 tes lulus). |
| 55 | T2-14 | `aplikasi/src/layar/masuk/MasukStaf.tsx`, `aplikasi/src/layar/masuk/MasukStaf.test.tsx` (4 tes lulus). |
| 56 | T2-15 | `aplikasi/src/layar/pengaturan/Perangkat.tsx`, `aplikasi/src/layar/pengaturan/Perangkat.test.tsx` (3 tes lulus). |
| 57 | T2-16 | `aplikasi/src/hook/useKunciOtomatis.ts`, `aplikasi/src/komponen/KunciSekarang.tsx`, `aplikasi/src/hook/useKunciOtomatis.test.tsx`, `aplikasi/src/komponen/KunciSekarang.test.tsx` (6 tes lulus). |
| 58 | T2-17 | `aplikasi/src/layar/pengaturan/DaftarPerangkat.tsx`, `aplikasi/src/layar/pengaturan/DaftarPerangkat.test.tsx` (2 tes lulus). |
| 59 | T2-18 | `aplikasi/src/layar/masuk/MasukPengelola.tsx`, `aplikasi/src/layar/masuk/MasukPengelola.test.tsx` (3 tes lulus). |
| 60 | T2-19 | `aplikasi/src/layar/masuk/SkenarioMasukPeran.test.tsx`, `supabase/tes/sesi_dan_perangkat.sql`, `supabase/tes/matriks_izin_6_peran.sql`. |
| 61 | T3-14 | `aplikasi/src/layar/kasir/AlurKasirE2E.test.tsx` (uji alur menu -> catatan -> kirim dapur -> bayar tunai lunas lulus). |
| 62 | T3-16 | `aplikasi/src/layar/kasir/BebanKasir.test.ts` (2 tes beban performa lulus di Vitest). |
| 63 | T5-06 | VoidItem 8 tes + LayarKasirVoid 7 tes LULUS · aplikasi 62 berkas / 368 tes LULUS · `uji-mutasi-app.mjs` 24/24 MERAH (4 mutasi baru T5-06: alasan tidak wajib, penolakan disulap berhasil, hapus tanpa alasan, item lenyap walau ditolak) · suite SQL 84 LULUS · tsc bersih. |
| 64 | T5-07 | suite SQL **85 LULUS · 0 GAGAL** · `uji-mutasi-0042.py` **4/4 MERAH** · `uji-mutasi-0012.py` **16/16** (M6 dipindah ke `0042` — lihat catatan jebakan) · gerbang & paritas CI LOLOS setelah perintah baru didaftarkan. |
| 65 | T5-08 | `DataPelanggan.test.tsx` **9 tes LULUS** (nomor tidak terkirim tanpa persetujuan; persetujuan tanpa nomor juga tidak cukup; persetujuan ikut sebagai data `setuju: true`; tombol Lewati selalu hidup; melewati tidak mengirim apa pun) · `uji-mutasi-app.mjs` **26/26 MERAH** (2 mutasi baru: kirim tanpa persetujuan, Lewati di |
| 66 | T5-09 | `StrukDigital.test.tsx` **15 tes LULUS** · aplikasi **64 berkas / 392 tes LULUS** · `uji-mutasi-app.mjs` **28/28 MERAH** (2 mutasi baru: tombol Bagikan tampil walau tak didukung, ringkasan mengaku LUNAS padahal belum dibayar) · `tsc` bersih · lint 0 error · format bersih. |
| 67 | T5-10 | `DaftarTransaksi.test.tsx` **13 tes LULUS** · `Struk.test.tsx` **16 tes** tetap hijau · `uji-mutasi-app.mjs` **31/31 MERAH** (3 mutasi baru: tanda SALINAN tidak pernah tampil, pratinjau tanpa tanda salinan, tombol cetak ulang hidup tanpa memilih transaksi). |
| 68 | T5-11 | SQL **86 LULUS · 0 GAGAL** · `DaftarTagihan.test.tsx` **17 tes LULUS** · aplikasi **66 berkas / 422 tes LULUS** · `uji-mutasi-app.mjs` **34/34 MERAH** (3 mutasi baru: umur selalu "baru", sisa mengabaikan uang masuk, umur ditulis menit mentah). |
| 69 | T5-12 | SQL **87 LULUS · 0 GAGAL** · `alat/uji-mutasi-0043.py` **4/4 MERAH** · `DaftarPembatalan.test.tsx` **16 tes LULUS** · aplikasi **68 berkas / 450 tes LULUS** · `uji-mutasi-app.mjs` **42/42 MERAH** · `periksa-gerbang-ci.py` + `periksa-paritas-ci.py` LOLOS. --- ## Fase 6 — Cetak termal ESC/POS (⚠️ ART-7) T-002 |
| 70 | T6-01 | `expos.test.ts` **29 tes LULUS** · `uji-mutasi-app.mjs` **47/47 MERAH** (5 mutasi ESC/POS baru) · aplikasi **69 berkas / 479 tes LULUS** · tsc bersih · lint 0 error. |
| 71 | T6-02 | `profil.test.ts` **20 tes** · `kirim.test.ts` **23 tes** · `PasangPrinter.test.tsx` **14 tes** · 6 mutasi T6-02/T6-03 MERAH. |
| 72 | T6-04 | `struk.test.ts` **22 tes LULUS** · 6 mutasi T6-04 semuanya MERAH. |
| 73 | T6-05 | `tiket.test.ts` **20 tes LULUS** · 6 mutasi T6-05 semuanya MERAH. |
| 74 | T7-12 | Berkas uji SQL `supabase/tes/golden_laporan.sql` membuktikan seluruh angka laporan operasional (`laporan_penjualan`, `laporan_menu`, `laporan_harian`, `laporan_shift`, `laporan_pembatalan`, `laporan_koreksi_modal`) sama persis (|selisih| = 0) dengan hasil hitung langsung dari tabel data mentah transaksi (`pesanan`, `pe |

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

Kamu juga **wajib**: (a) memakai `skills/find-skills` atau `skills/agent-skills-hub/CATALOG.md` bila butuh skill lain;
(b) mencari referensi internet bila menyimpulkan perilaku sistem luar (Supabase/PostgreSQL/OWASP) dan **mencantumkan tautannya**.

## 6. Format laporan (salin apa adanya, isi bagiannya)

```markdown
# LAPORAN AUDIT INDEPENDEN — AUD-4 — 2026-09-25

- **Auditor:** <nama sesi/model yang benar-benar dipakai>
- **Tanggal:** 2026-09-25
- **Tingkat audit:** AUD-4
- **Commit yang diaudit:** `804ed86f3464490d5bc6c466b7e268d138b78e5e` (commit tepat sebelum berkas paket ini dibuat; auditor boleh mencatat commit yang benar-benar ia periksa — tulis apa adanya, jangan dibulatkan ke commit lain)
- **Paket audit:** `docs/uji/paket-audit/AUD-4-2026-09-25-keamanan.md` (CATATAN: berkas paket ini di-commit SETELAH commit target — ia TIDAK ADA di pohon commit yang kamu audit; jangan mencarinya di sana. Sumber sahmu: repo + cabang sumber + SHA paket + path pada prompt pendek. Temuan audit J F-06)
- **Mode cakupan:** bidang-keamanan
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
