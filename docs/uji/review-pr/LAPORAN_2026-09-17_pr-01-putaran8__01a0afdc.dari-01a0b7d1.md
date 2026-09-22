# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran8 — 2026-09-17

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran8.md`
- **Commit yang direview:** `7e8c0b952744fd4b604743022acfb1b643c94a9a`
- **Tingkat risiko:** Merah
- **Verdict:** TIDAK-BERSIH

Lensa yang diwajibkan paket (Jalur Merah): **L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji)** — ketiganya dijalankan. Diff `origin/main...7e8c0b952744fd4b604743022acfb1b643c94a9a` = **338 berkas · +41655 / −132**. 55 berkas jalur Merah diperiksa (migrasi, RLS, tes SQL, CI, pemeriksa). 110 kuning dan 173 hijau **tidak** ditelusuri baris-demi-baris; sampel kuning = alat/gerbang + `aplikasi/src` (env, tanpa layar kasir); sampel hijau = dokumen pengikat (KEAMANAN, ROADMAP T1-23, BUKU_UJI, REVIEW_PR_RIWAYAT). PR ini mencampur migrasi uang, CI, dan ratusan dokumen — kedalaman L1/L2 tidak mungkin merata ke 338 berkas (lihat PR-06).

## 1. Cakupan diff

| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `supabase/migrations/0001_penyewa_cabang.sql` | Merah | ya | baca penuh; RLS enable + grant anon/authenticated |
| 2 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql` | Merah | ya | baca penuh; grant update pengaturan ke anon:120 |
| 3 | `supabase/migrations/0003_helper_identitas.sql` | Merah | ya | `penyewa_saya`/`cabang_saya` (jwt `cabang_id`:69); uji `helper.sql` LULUS |
| 4 | `supabase/migrations/0004_pola_rls.sql` | Merah | ya | policy pengaturan_pilih:80; **uji mutasi** longgarkan → MERAH → pulihkan → LOLOS |
| 5 | `supabase/migrations/0005_izin_berjenjang.sql` | Merah | ya | `boleh()` + revoke; komentar "tidak ada rumus izin kedua":10 |
| 6 | `supabase/migrations/0006_pin.sql` | Merah | ya | `izin_efektif_untuk` masih `select pc.peran` :135; bukti error `column pc.peran does not exist` |
| 7 | `supabase/migrations/0007_katalog.sql` | Merah | ya | `catat_stok` insert delta mentah :393; bukti stok keluar +5 → 20 menjadi 25 |
| 8 | `supabase/migrations/0008_meja.sql` | Merah | ya | RLS + grant; `node alat/uji-sql.mjs supabase/tes/meja.sql` (berkas lulus dalam 21/21) |
| 9 | `supabase/migrations/0009_pesanan.sql` | Merah | ya | penjaga status :166 vs policy `pesanan_ubah` tanpa dapur :259 |
| 10 | `supabase/migrations/0010_pembayaran.sql` | Merah | ya | diskon subtotal :387; void PIN tanpa `pesanan_id` :460-466; **uji mutasi** lebih bayar |
| 11 | `supabase/migrations/0011_peran_tunggal.sql` | Merah | ya | `drop column peran` :14; menulis ulang `izin_efektif` tapi **bukan** `izin_efektif_untuk` |
| 12 | `supabase/functions/verifikasi_pin/index.ts` | Merah | ya | POST + anon key; CORS `*`; `periksa-fungsi-pin.py` 9 lolos 0 gagal |
| 13 | `supabase/tes/rls_semua_tabel.sql` | Merah | ya | LULUS di commit; GAGAL saat policy pengaturan dilonggarkan |
| 14 | `supabase/tes/pembayaran.sql` | Merah | ya | LULUS di commit; GAGAL saat `v_sebelum > total + 100000` |
| 15 | `supabase/tes/gerbang_uang.sql` | Merah | ya | sama; mutasi lebih bayar → GAGAL |
| 16 | `supabase/tes/persetujuan_void.sql` | Merah | ya | menguji kedaluwarsa, **tidak** menguji replay lintas pesanan |
| 17 | `supabase/tes/peran_tunggal.sql` | Merah | ya | LULUS; hanya `boleh()`/`izin_efektif`, bukan `izin_efektif_untuk` |
| 18 | `supabase/tes/penjaga_stok.sql` | Merah | ya | hanya `catat_stok(..., 'masuk', +5)` — tidak menguji tanda `keluar` |
| 19 | `supabase/tes/izin.sql` | Merah | ya | LULUS; §8 diganti peran tunggal |
| 20 | `supabase/tes/isolasi_lintas_penyewa.sql` | Merah | ya | LULUS; `izin_efektif_untuk` dicabut dari klien |
| 21 | `supabase/tes/helper.sql` | Merah | ya | LULUS; tidak memanggil `cabang_saya()` untuk akun nonaktif + JWT |
| 22 | `.github/workflows/ci.yml` | Merah | ya | `npm audit --audit-level=low`; `node alat/uji-sql.mjs --daftar` (flag itu **tetap menjalankan** seluruh tes) |
| 23 | `aplikasi/alat/periksa-semua.sh` | Merah | ya | `bash aplikasi/alat/periksa-semua.sh` → `SEMUA PEMERIKSAAN LOLOS.` |
| 24 | `alat/uji-sql.mjs` | Merah | ya | 21 LULUS · 0 GAGAL pada commit ini |
| 25 | `alat/review-pr.py` | Merah | ya | `--uji-diri` LOLOS (3 contoh) |
| 26 | `alat/audit-independen.py` | Merah | ya | `--uji-diri` LOLOS |
| 27 | `alat/periksa-rujukan.py` | Merah | ya | 147 rujukan; `--uji-diri` ikut di periksa-semua |
| 28 | `alat/periksa-buku-uji.py` | Merah | ya | ikut CI / periksa-semua |
| 29 | `alat/periksa-temuan-audit.py` | Merah | ya | ikut CI / periksa-semua |
| 30 | `alat/periksa-fungsi-pin.py` | Merah | ya | 9 lolos 0 gagal |
| 31 | `_sistem/validate_system.py` | Merah | ya | `PASS` |
| 32 | `docs/KEAMANAN.md` | Merah | ya | :24 klaim `hitung_total()` "sudah berlaku sejak T1-10" — fungsi tidak ada |
| 33 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` | Merah | ya | §3 campur-risiko; §6 kontrak laporan |
| 34 | `docs/uji/BUKU_UJI_PEMILIK.md` | Kuning | ya | U-04 masih menunjuk paket **putaran7** @ 183a3c1 |
| 35 | `docs/uji/REVIEW_PR_RIWAYAT.md` | Hijau | ya | baris 3 paket berlaku = putaran7 / `183a3c1`, bukan 7e8c0b9 |
| 36 | `docs/ROADMAP.md` | Kuning | ya | T1-23 `[x]`; T1-15 `hitung_total` masih `[ ]` :311 |
| 37 | `aplikasi/src/lib/env.ts` | Kuning | ya | hanya `VITE_SUPABASE_URL` / `ANON_KEY` |
| 38 | `alat/sql/data-uji.sql` | Kuning | ya | fixture tanpa perangkat terdaftar (B.9 masih WAJIB) |
| 39 | 300 berkas lain (kuning/hijau: prototipe, font, paket putaran5/6, layar `.gitkeep`, dll.) | Kuning/Hijau | tidak (bukan baris-demi-baris) | `git diff --name-only origin/main...7e8c0b9 \| wc -l` → 338 |

## 2. Klaim yang dibantah

| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | *(kosong di paket — baris klaim #1 tidak berisi teks)* | Baca paket yang ditempel Lee; bandingkan generator `klaim_dari_commit()` | Klaim #1 paket kosong. Tidak ada yang bisa dibuktikan. |
| 2 | Paket baru `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran7-SIAP-TEMPEL.md` | `ls` + `grep 'Commit yang direview' docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran7.md` di tree `7e8c0b9` | Berkas **ada**. Isi menunjuk commit `183a3c11aa24f865d6e3140820e64574aea15ff6`, **bukan** `7e8c0b9`. Paket itu tidak mereview commit ini. |
| 3 | REVIEW_PR_RIWAYAT baris 3 (paket berlaku) + baris 2 ditandai digantikan | `sed -n '10,14p' docs/uji/REVIEW_PR_RIWAYAT.md` pada `7e8c0b9` | Baris 2 bertuliskan **digantikan**. Baris 3: paket berlaku = **putaran7 @ `183a3c1`**. Commit yang diminta paket putaran8 (`7e8c0b9`, +22 berkas termasuk CI `npm audit` + 3 penjaga) **tidak** tercatat sebagai paket berlaku. |
| 4 | Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini (bukan commit sebelumnya) | `node alat/uji-sql.mjs` dan `bash aplikasi/alat/periksa-semua.sh` di worktree `7e8c0b9` | Gerbang **hijau pada commit ini**: `uji: 21 LULUS · 0 GAGAL` / `SEMUA PEMERIKSAAN LOLOS.` / vitest 51/51. **Tetapi** tes tidak menyentuh celah yang saya buktikan (diskon subtotal 0, replay void, tanda stok `keluar`, `izin_efektif_untuk`+cabang). Hijau ≠ lengkap. |
| 5 | Tidak ada gerbang keamanan/CI yang dilemahkan | Baca `.github/workflows/ci.yml`; bandingkan `periksa-semua.sh`; uji mutasi gerbang | CI **menambah** `npm audit --audit-level=low` (0 vulnerabilities). `uji-sql.mjs --daftar` tetap menjalankan seluruh tes (bukan hanya daftar). Mutasi RLS/uang membuat gerbang **MERAH** lalu pulih **LOLOS** — gerbang tidak tumpul. Klaim ini **tidak tertolak** untuk pelemahan ambang. |
| 6 | Perubahan jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API) | Sisipan SQL langsung sebagai `authenticated` (bukan UI) | **Ditolak.** Tiga jalan langsung berhasil: (a) `INSERT diskon_transaksi` 25.000 pada pesanan subtotal 0; (b) satu `verifikasi_pin` void memakai dua `INSERT pembatalan`; (c) `catat_stok('keluar', +5)` menambah stok. Keluaran: ketiga berkas bukti `LULUS` (artinya celah ada). |
| 7 | Dokumen perilaku sudah ikut diperbarui — tidak ada klaim basi | `grep hitung_total docs/KEAMANAN.md`; `grep T1-15 docs/ROADMAP.md`; U-04 BUKU_UJI | **Ditolak.** `docs/KEAMANAN.md:24` menulis `hitung_total()` "sudah berlaku sejak T1-10". `docs/ROADMAP.md` T1-15 masih `[ ]` dan `grep -n hitung_total supabase/migrations` tidak menemukan fungsi. BUKU_UJI U-04 menunjuk paket putaran7. |
| 8 | Setiap berkas baru benar-benar dipakai (tidak ada berkas mati / rujukan menggantung) | `python3 alat/periksa-rujukan.py`; `ls prototipe docs/uji/review-pr` | Pemeriksa rujukan **LOLOS** (rujukan mati ditandai rencana). Tetap ada artefak yang tidak dipakai runtime: `prototipe/*.html`, paket putaran5/6 (disimpan sebagai riwayat — disengaja), layar `aplikasi/src/layar/*/.gitkeep`. Bukan rujukan menggantung, tapi bukan "setiap berkas baru dipakai". |

## 3. Pemeriksaan gerbang

| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` (worktree `/tmp/pr-work` @ `7e8c0b9`) | Akhir: `SEMUA PEMERIKSAAN LOLOS.` Vitest `7 passed (7)` / `51 passed (51)`. `npm audit`: `found 0 vulnerabilities`. SQL: `uji: 21 LULUS · 0 GAGAL` / `HASIL: LOLOS`. `validate_system.py`: `PASS`. `review-pr.py --uji-diri`: LOLOS. `audit-independen.py --uji-diri`: LOLOS. |
| 2 | `node alat/uji-sql.mjs` | `Menerapkan 11 migrasi` OK. `Menjalankan 21 berkas uji` semua `LULUS`. `uji: 21 LULUS · 0 GAGAL` / `HASIL: LOLOS`. |
| 3 | `git diff origin/main...7e8c0b952744fd4b604743022acfb1b643c94a9a` | `338 files changed, 41655 insertions(+), 132 deletions(-)`. Bukan hanya "T1-23 + buku uji": seluruh skema 0001–0011, CI, prototipe, font, paket review lama. |
| 4 | `python3 _sistem/validate_system.py` + `python3 alat/periksa-roadmap.py` + `python3 alat/periksa-panduan.py` | `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`. Roadmap: `HASIL: LOLOS` (192 tugas). Panduan: `HASIL: LOLOS` (catatan rujukan rencana: `alat/peta-ui.py`, `supabase/functions/ringkasan_harian/index.ts`). |
| 5 | `python3 alat/audit-independen.py --uji-diri` + `python3 alat/review-pr.py --uji-diri` | Keduanya `HASIL: LOLOS` — pemeriksa menolak contoh buruk dan menerima contoh baik. |
| 6 | **Uji mutasi RLS (Jalur Merah / L1):** di `/tmp/pr-mutasi` ganti `pengaturan_pilih` menjadi `using (penyewa_id is not null)` lalu `node alat/uji-sql.mjs supabase/tes/rls_semua_tabel.sql` | **MERAH:** `GAGAL supabase/tes/rls_semua_tabel.sql` / `Tabel public.pengaturan membocorkan 1 baris milik resto lain`. Pulihkan ke `penyewa_saya()` → `LULUS` / `HASIL: LOLOS`. |
| 7 | **Uji mutasi uang (L2/L4):** `if v_sebelum > v_pesanan.total then` → `+ 100000` di 0010, lalu `node alat/uji-sql.mjs supabase/tes/pembayaran.sql supabase/tes/gerbang_uang.sql` | **MERAH:** kedua tes GAGAL `perintah tidak ditolak (total pembayaran tidak boleh melebihi total pesanan)`. Commit utuh (tanpa mutasi) 21/21 LULUS. |
| 8 | `gh pr checks 1` | `Periksa (lint · tipe · uji · pemeriksa Python) pass 41s` pada PR #1 (kepala GitHub = `f59debd`, satu commit setelah target). |

## 4. Temuan

### [PR-01] Penjaga diskon dilewati saat subtotal masih 0 — baris diskon tidak bisa dihapus klien
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:387`
- **Klaim yang dilanggar:** 6 (jalur uang tidak bisa dilewati pemanggilan langsung)
- **Bukti:** perintah → hasil nyata
  ```
  $ node alat/uji-sql.mjs /tmp/bukti-diskon-subtotal-nol.sql
  Menjalankan 1 berkas uji:
    LULUS /tmp/bukti-diskon-subtotal-nol.sql
  uji: 1 LULUS · 0 GAGAL
  ```
  Kasir (`9000…0004`, batas 25.000/5%) `INSERT` diskon manual 25.000 ke pesanan draf subtotal 0. Pemicu melewati `if coalesce(v_pesanan.subtotal, 0) > 0 and v_sudah + new.nilai > v_pesanan.subtotal`. `DELETE` dari klien ditolak (hanya policy INSERT). `hitung_total()` belum ada (T1-15 `[ ]`), jadi baris ini akan ikut terhitung nanti dan tidak bisa dibatalkan klien.
- **Skenario gagal:** Kasir membuka pesanan kosong, menanam diskon 25.000 (masih dalam batas izin), lalu mengisi item murah. Setelah T1-15, total terpotong 25.000 tanpa bisa dihapus.
- **Dugaan penyebab:** Penjaga "diskon ≤ subtotal" sengaja di-skip saat subtotal 0 (karena T1-15 belum ada), tanpa menolak diskon pada pesanan yang belum dihitung.
- **Cara membuktikan perbaikan:** perintah yang harus hijau — tes yang sekarang LULUS (celah) harus **GAGAL** (insert ditolak), misalnya `node alat/uji-sql.mjs supabase/tes/diskon_persen.sql` plus kasus subtotal 0; `INSERT` kasir pada pesanan draf harus raise.
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] Bukti PIN void tidak terikat pesanan — satu PIN membatalkan banyak pesanan dalam 5 menit
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:460-466`
- **Klaim yang dilanggar:** 6 (uang/pembatalan lewat pemanggilan langsung)
- **Bukti:** perintah → hasil nyata
  ```
  $ node alat/uji-sql.mjs /tmp/bukti-void-replay.sql
  Menjalankan 1 berkas uji:
    LULUS /tmp/bukti-void-replay.sql
  uji: 1 LULUS · 0 GAGAL
  ```
  Satu `verifikasi_pin(owner, PIN, 'void_sesudah_dapur')` lalu dua `INSERT pembatalan` untuk dua pesanan berbeda — keduanya diterima. EXISTS hanya menyaring `pengguna_id` + `berhasil` + `aksi` + jendela 5 menit; **tidak ada `pesanan_id`**. `supabase/tes/persetujuan_void.sql` menguji "tanpa PIN" dan "kedaluwarsa", tidak menguji replay lintas pesanan.
- **Skenario gagal:** Owner memasukkan PIN sekali untuk satu void. Kasir (atau siapa pun yang bisa INSERT pembatalan) membatalkan seluruh antrian dapur selama 5 menit dengan nama owner yang sama, tanpa PIN baru. Nilai kerugian tercatat dari salinan harga.
- **Dugaan penyebab:** Perbaikan AUD-3 K-2 (bukti PIN) mengikat aksi, bukan transaksi.
- **Cara membuktikan perbaikan:** perintah yang harus hijau — sisipan pembatalan pesanan kedua tanpa `verifikasi_pin` baru harus ditolak; tes replay di `persetujuan_void.sql` LULUS hanya jika insert kedua GAGAL.
- **Status verifikasi:** TERVERIFIKASI

### [PR-03] `catat_stok('keluar', +N)` menambah stok, bukan mengurangi
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0007_katalog.sql:389-393` (pemicu jumlahkan: `jumlah = jumlah + new.jumlah`)
- **Klaim yang dilanggar:** 6 (jalur stok/uang lewat RPC langsung)
- **Bukti:** perintah → hasil nyata
  ```
  $ node alat/uji-sql.mjs /tmp/bukti-stok-keluar.sql
  Menjalankan 1 berkas uji:
    LULUS /tmp/bukti-stok-keluar.sql
  uji: 1 LULUS · 0 GAGAL
  ```
  Dapur (`9000…0006`, izin `ubah_stok`) memanggil `catat_stok(beras, 'keluar', 5, …)` → saldo **20 → 25**. Fungsi tidak membalik tanda berdasarkan `jenis`. `penjaga_stok.sql` hanya menguji `'masuk', +5`.
- **Skenario gagal:** Pegawai berizin stok mencatat "keluar" dengan angka positif. Buku besar bilang keluar, saldo justru naik — selisih opname bisa ditutup tanpa jejak yang jujur.
- **Dugaan penyebab:** Kontrak "jumlah selalu delta (keluar negatif)" tidak ditegakkan di `catat_stok`; pemicu menjumlah buta.
- **Cara membuktikan perbaikan:** perintah yang harus hijau — `catat_stok(..., 'keluar', 5)` harus menghasilkan 15 (atau ditolak jika tanda salah); tes `penjaga_stok.sql` kasus keluar harus LULUS dengan saldo turun.
- **Status verifikasi:** TERVERIFIKASI

### [PR-04] `izin_efektif_untuk` masih membaca `pengguna_cabang.peran` yang sudah di-DROP
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0006_pin.sql:135` vs `0011_peran_tunggal.sql:14`
- **Klaim yang dilanggar:** 4 (uji tidak membuktikan rumus izin tunggal) dan komentar 0005:10 "Tidak ada rumus izin kedua"
- **Bukti:** perintah → hasil nyata
  ```
  $ node alat/uji-sql.mjs /tmp/bukti-izin-pesan.sql
  GAGAL /tmp/bukti-izin-pesan.sql
        PESAN_ERROR: column pc.peran does not exist
  ```
  `0011` menulis ulang `izin_efektif()` tetapi membiarkan `izin_efektif_untuk` / `boleh_untuk` (dipakai `verifikasi_pin` dan pemicu void). Tanpa `p_cabang_id` masih jalan (membaca `pengguna.peran`); dengan cabang → meledak. `peran_tunggal.sql` tidak memanggil fungsi ini.
- **Skenario gagal:** RPC/pemicu masa depan yang menilai izin orang lain di cabang tertentu (void/diskon per cabang) error di produksi. Dua rumus izin hidup berdampingan.
- **Dugaan penyebab:** 0011 hanya mengganti bungkus `izin_efektif`, bukan fungsi umum yang ditulis 0006.
- **Cara membuktikan perbaikan:** perintah yang harus hijau — `select * from izin_efektif_untuk(kasir, 'tutup_kas', cabang_pusat)` mengembalikan baris (bukan error) dan sama dengan `izin_efektif` peran tunggal; tes peran_tunggal mencakup jalur ini.
- **Status verifikasi:** TERVERIFIKASI

### [PR-05] Dokumen pengikat KEAMANAN mengklaim `hitung_total()` sudah berlaku sejak T1-10
- **Tingkat:** K-3
- **Artefak:** `docs/KEAMANAN.md:24`; `docs/ROADMAP.md` T1-15 `[ ]`
- **Klaim yang dilanggar:** 7 (klaim basi)
- **Bukti:** perintah → hasil nyata
  ```
  $ grep -n 'hitung_total' docs/KEAMANAN.md
  24:5. **Tidak ada angka uang dari perangkat.** Semua nominal dihitung di peladen (`hitung_total()`), klien hanya menampilkan (sudah berlaku sejak T1-10).
  $ grep -n 'T1-15' docs/ROADMAP.md | head -3
  311:- [ ] T1-15 — Fungsi hitung_total() + 12 uji uang
  $ grep -n 'create or replace function public.hitung_total' supabase/migrations/*.sql
  (kosong)
  ```
- **Skenario gagal:** Pembaca dokumen pengikat (Lee / sesi berikutnya) mengira angka uang sudah dihitung peladen. Yang ada hanya penjaga "klien tidak boleh menulis total" + tolak bayar jika total ≤ 0. Tidak ada fungsi pengisi total.
- **Dugaan penyebab:** Kalimat "sudah berlaku sejak T1-10" menyalin niat T1-10 (penjaga) seolah T1-15 (perhitungan) sudah mendarat.
- **Cara membuktikan perbaikan:** perintah yang harus hijau — `grep hitung_total docs/KEAMANAN.md` tidak lagi menyatakan "sudah berlaku" sampai `create function public.hitung_total` ada dan T1-15 `[x]`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-06] PR 338 berkas mencampur jalur Merah+Kuning+Hijau — tidak bisa dinilai merata
- **Tingkat:** K-3
- **Artefak:** `git diff --shortstat origin/main...7e8c0b9` → `338 files changed, 41655 insertions(+), 132 deletions(-)`; protokol `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` §3 aturan pemisahan
- **Klaim yang dilanggar:** kelayakan review (protokol: PR campur-risiko wajib dipecah atau beralasan kuat)
- **Bukti:** perintah → hasil nyata — paket mesin sendiri mengklasifikasi 55 Merah / 110 Kuning / 173 Hijau. Tidak ada alasan pemisahan di paket. Saya memeriksa 55 merah + sampel; 300 berkas lain tidak baris-demi-baris.
- **Skenario gagal:** Temuan uang di atas lolos dari "review PR" karena reviewer wajib juga menelan prototipe, font, dan 6 paket review lama dalam satu putaran.
- **Dugaan penyebab:** PR #1 = seluruh pekerjaan dari `main` dokumen-saja. Tidak dipecah per tujuan (skema uang vs dokumen vs CI).
- **Cara membuktikan perbaikan:** perintah yang harus hijau — PR berikutnya `git diff --shortstat` tidak mencampur `supabase/migrations` + ratusan dokumen non-fondasi tanpa alasan di paket; atau pecah PR.
- **Status verifikasi:** TERVERIFIKASI

### [PR-07] Buku uji pemilik & riwayat review masih mengikat Lee ke paket putaran7 (commit `183a3c1`)
- **Tingkat:** K-3
- **Artefak:** `docs/uji/BUKU_UJI_PEMILIK.md` baris U-04; `docs/uji/REVIEW_PR_RIWAYAT.md` baris 3
- **Klaim yang dilanggar:** 2, 3, 7
- **Bukti:** perintah → hasil nyata — U-04: salin `PKT-2026-09-17-pr-01-putaran7-SIAP-TEMPEL.md`. Riwayat baris 3: commit direview `183a3c1`. Commit ini `7e8c0b9` menambah 22 berkas (CI audit, 3 penjaga, buku uji) yang **tidak** masuk cakupan putaran7.
- **Skenario gagal:** Lee mengikuti buku uji / riwayat → peninjau menilai `183a3c1`, bukan kode yang akan di-merge.
- **Dugaan penyebab:** 7e8c0b9 tidak menyegarkan riwayat/buku uji; paket putaran8 baru ditulis di commit berikutnya (`f59debd`).
- **Cara membuktikan perbaikan:** perintah yang harus hijau — U-04 dan baris riwayat "paket berlaku" menunjuk paket yang `Commit yang direview` = `7e8c0b9` (atau kepala PR yang sama).
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Ditemukan: 4 dari 4 · temuan palsu: 0 · daftar cacat yang saya temukan:

Bahan: docs/uji/kalibrasi/pr-bahan-2026-09-17.diff. `git apply` di salinan `/tmp/pr-kalibrasi` gagal (`error: corrupt patch at line 39`) — tidak mencari kunci jawaban; hunk dibaca dari bahan itu sendiri lalu diterapkan.

1. **`0003_helper_identitas.sql` — `cabang_saya()` membuang `p.aktif`.** Akun nonaktif tetap dapat cabang jika JWT membawa `cabang_id`. `helper.sql` tetap LULUS setelah hunk ini (tes nonaktif memakai `cabang_ids_saya()`, bukan `cabang_saya()`+JWT) — gerbang uji **tidak** menangkap cacat ini.
2. **`0004_pola_rls.sql` — `pengaturan_pilih` jadi `penyewa_id is not null`.** Isolasi resto runtuh. Uji: `rls_semua_tabel.sql` GAGAL `Tabel public.pengaturan membocorkan 1 baris milik resto lain`.
3. **`0005_izin_berjenjang.sql` — `revoke all on function public.boleh(text, uuid) from public` dihapus.** Anon bisa memanggil gerbang izin. Uji: `izin.sql` GAGAL `anon tidak boleh memanggil boleh()`.
4. **`0010_pembayaran.sql` — batas lebih bayar `total + 100000`.** Hunk yang sama sebagai uji mutasi di `/tmp/pr-mutasi`: `pembayaran.sql` dan `gerbang_uang.sql` GAGAL `perintah tidak ditolak (total pembayaran tidak boleh melebihi total pesanan)`.

Tidak ada temuan palsu (saya tidak menandai hunk selain keempat perubahan di bahan).

## 6. Yang tidak bisa saya verifikasi

- **Supabase nyata / RLS produksi.** Semua uji SQL memakai PGlite + tiruan `crypt`/`gen_salt` (bukan bcrypt pgcrypto). T0-00/T0-08 belum ada proyek. Perilaku JWT `cabang_id`, `auth.jwt()`, dan FORCE RLS di hosted tidak saya ulangi.
- **`git apply` bahan kalibrasi** gagal (patch corrupt); saya terapkan hunk dari isi bahan. Jika ada cacat ke-5 yang hanya muncul lewat apply utuh, saya tidak melihatnya.
- **CI GitHub pada SHA `7e8c0b9` secara terpisah.** `gh pr checks 1` hijau di kepala PR `f59debd` (paket putaran8), bukan di SHA target. Saya menjalankan gerbang lokal di `7e8c0b9`.
- **110 berkas kuning + sebagian besar 173 hijau** tidak dibaca penuh (lihat §1).
- **Apakah replay void 5 menit disengaja sebagai UX "satu PIN untuk beberapa item".** Perilaku lintas *pesanan* terbukti; niat produk tidak bisa saya tanya ke penulis.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah. Bukti: `git status --short` menampilkan hanya berkas laporan ini. Worktree/salinan uji ada di `/tmp/pr-work`, `/tmp/pr-mutasi`, `/tmp/pr-kalibrasi` — di luar repo sesi.

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
| 1 | Klaim JWT `cabang_id` tidak pernah diterbitkan di repo ini, padahal `cabang_saya()` memerlukannya | Tidak ada kode login/hook di commit ini (layar masuk = `.gitkeep`); ini utang T1-24/T1-25, bukan regresi 7e8c0b9 | `grep -rn cabang_id supabase/migrations/0003_helper_identitas.sql` (baca klaim token) vs tidak ada hook Auth | Jangan mengandalkan `cabang_saya()` di policy admin sebelum hook/sesi ada; T1-24 harus memasang penerbit klaim atau mengganti sumber cabang aktif |
| 2 | Batas PIN per perangkat (12×/15 menit) masih dari nama kiriman klien — sudah diakui AUD-3 F-11, masih terbuka | Bukan cacat baru 7e8c0b9; sudah tertulis di `docs/KEAMANAN.md` §2 dan T1-24 belum `[x]` | `docs/KEAMANAN.md` catatan F-11; `verifikasi_pin(..., p_perangkat)` | Jangan tutup F-11 sebelum `perangkat_id` terverifikasi |
| 3 | Hash PIN di uji lokal = tiruan SHA, bukan bcrypt | Alat uji, bukan diff perilaku produksi yang diklaim "sudah bcrypt" | komentar `alat/uji-sql.mjs` blok pgcrypto tiruan | Jangan mengklaim kekuatan KDF dari 21 tes PGlite |

---

**Rencana pemulihan (Jalur Merah, bahasa sederhana):** Jangan merge. Kalau perubahan ini salah masuk: (1) jangan pakai di resto nyata; (2) tutup INSERT diskon pada pesanan yang total/subtotal-nya 0; (3) ikat bukti PIN void ke satu pesanan (atau habiskan bukti setelah dipakai); (4) `catat_stok('keluar')` wajib mengurangi; (5) tulis ulang `izin_efektif_untuk` tanpa kolom yang sudah dihapus; (6) coret kalimat KEAMANAN yang bilang `hitung_total` sudah jalan. Rollback = tidak deploy migrasi ke proyek Supabase (belum ada T0-00) + jangan merge ke `main`.

**Sisa risiko:** Perangkat belum terdaftar, PIN 6 angka tetap lemah jika hash bocor, tidak ada proyek Supabase nyata, perhitungan uang (`hitung_total`) belum ada jadi jalur bayar gagal-tertutup untuk pesanan baru (total 0 ditolak) — itu pelindung sementara, bukan fitur selesai. Review ini memakai L1/L2/L4 pada 55 berkas merah; sisanya bisa menyimpan cacat yang tidak saya lihat.