# LAPORAN AUD-2 — 2026-09-21 — Batch-5 (terarah)

- **Auditor:** Agen independen di Arena.ai, sesi `arena/01a0c39d-resto-barokah`; bukan sesi pembangun Batch-5.
- **Tanggal:** 2026-09-21 (UTC).
- **Tingkat audit:** AUD-2.
- **Commit yang diaudit:** `09bcb89fc139b3be32ab874e7a004f0a3b0480ee`
- **Paket audit:** `docs/uji/paket-audit/AUD-2-2026-09-21.md`, melalui salinan paket dalam permintaan pemilik. Paket dibuat sesudah commit target; tidak menganggap ketiadaannya dalam target sebagai cacat.
- **Mode cakupan:** terarah; T1-30 dan T1-45, terutama diff `73bd831c4226ad0d69926484ec65d2f35d30249d..09bcb89fc139b3be32ab874e7a004f0a3b0480ee`.
- **Verdict:** BERSIH-DENGAN-CATATAN

> **Catatan rekonsiliasi untuk agen sesi lain:** cabang GitHub sebelumnya sudah memuat versi berbeda dari laporan ini pada commit `5529eae99fbd6f369b41ef599919418a3719adee`, dengan verdict **TIDAK-BERSIH**. Hasil audit lokal yang disampaikan dalam percakapan tetap menjadi isi utama di bawah. Versi remote dipertahankan **utuh** pada lampiran arsip di akhir berkas dan dalam riwayat merge; tidak ditimpa dengan force-push. Klaim pengujian/temuan versi remote **belum diverifikasi ulang atau direkonsiliasi secara substantif**. Jangan menafsirkan verdict utama sebagai pembatalan klaim K-2 pada arsip atau izin penutupan gerbang. Permintaan lanjutan pemilik adalah memastikan hasil tersedia di GitHub, bukan menjalankan audit ulang.

**Makna verdict, bukan izin sebar:** ditemukan **10 temuan K-3 terverifikasi**, terutama kelemahan pembuktian/gerbang dan ketidakselarasan dokumen. Tidak ada cacat K-1/K-2 yang berhasil saya verifikasi pada implementasi uang target. Itu **bukan bukti tidak ada cacat uang**: SQL lokal, konkurensi database nyata, dan suite aplikasi lengkap tidak dapat diulang di lingkungan ini. Dugaan berisiko uang dipisahkan di §6. **Jangan menutup I F-17/T1-45, menyatakan seluruh DoD T1-30 terpenuhi, atau melakukan deploy berdasarkan laporan ini saja.** Reproduksi database yang belum terlaksana tetap diperlukan. Kelemahan uji tidak saya naikkan menjadi K-2 hanya untuk memperoleh verdict negatif.

Independensi sesi terbukti dari cabang kerja berbeda; **identitas model pembangun dibanding auditor tidak tersedia untuk saya buktikan**. Dengan demikian, persyaratan “sesi & model berbeda” tidak seluruhnya dapat disahkan oleh laporan ini.

## 1. Cakupan

### Identitas bahan dan cara baca

Saya tetap di cabang sesi; tidak checkout, cherry-pick, memperbaiki migrasi, atau membuat salinan kerja target. Semua pembacaan sumber memakai objek Git target, bukan berkas pada HEAD kerangka. Komit HEAD sesi sebelum laporan adalah `253d1297a3b81433d7f5809afd257d8a1b40958f`. Target berhasil diperoleh lewat fetch cabang pembangun; pemeriksaan objek berikut berhasil:

```bash
cd /home/user/Resto-Barokah
git fetch origin arena/01a0c2c1-resto-barokah
git cat-file -t 09bcb89fc139b3be32ab874e7a004f0a3b0480ee
git rev-parse 73bd831 09bcb89 HEAD
git diff --stat 73bd831..09bcb89
git log --oneline -20 09bcb89
git symbolic-ref --short HEAD
git status --porcelain=v1
```

Hasil: target bertipe `commit`; ketiga SHA sesuai yang ditulis di atas; diff **28 berkas, 960 penambahan, 63 penghapusan**; cabang `arena/01a0c39d-resto-barokah`; status awal kosong. Tidak memakai kegagalan membuka berkas di checkout kerangka sebagai bukti bahwa berkas target hilang.

**Notasi bukti dalam tabel:**

- **C1** = perintah identitas/diff di atas.
- **C2(path)** = `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:path | nl -ba`, dengan rentang terarah bila dicantumkan. Pembacaan diff memakai `git diff 73bd831..09bcb89 -- path`. Ini pemeriksaan sumber, **bukan eksekusi SQL**.
- **C3** = metadata CI GitHub, perintah dan batasnya di §3.2.
- **R0–R8 / N1** = probe yang sumbernya disertakan di §3.3; tidak menulis fixture ke disk.
- **RB** = pemeriksa asli target, dengan pembaca objek Git di memori. Bukan menjalankan CLI di pohon checkout kerangka. Hasilnya di §3.2; pembungkusnya R0+RB.

Tabel mencatat kedalaman yang benar-benar dilakukan. Pemindaian otomatis semua berkas **tidak** berarti saya mengulas semua baris secara manual. Pembacaan historis hanya dipakai untuk provenance dan penelusuran penutup, bukan sebagai bukti cacat target masih hidup.

| # | Artefak | Diperiksa | Bukti |
|---|---|---|---|
| 1 | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` | Tingkat, format, empat lensa, ambang, pemisahan dugaan/verifikasi, pengiriman | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`; C2, dibaca sebelum audit |
| 2 | Paket AUD-2 dalam prompt pemilik | Target, tujuh klaim, batas baca-saja, daftar bahan dan probe prioritas | `git cat-file -e 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/paket-audit/AUD-2-2026-09-21.md`; Sumber prompt; bukan paket pada commit lain; hasil pengecekan keberadaan = tidak ada pada target, sesuai paket pascatarget |
| 3 | `supabase/migrations/0022_beku_setelah_bayar.sql` | Seluruh 118 baris; kunci OLD/NEW, BY-201, header, skip AFTER | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0022_beku_setelah_bayar.sql`; C2; R2; §6 |
| 4 | `supabase/migrations/0023_acl_fungsi_pemicu.sql` | Seluruh 53 baris; dua daftar identik 20 fungsi, tanpa perubahan body/policy | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0023_acl_fungsi_pemicu.sql`; C2 |
| 5 | `supabase/tes/beku_setelah_bayar.sql` | Rp1, header, parent, null-auth, pembayaran lanjutan, dapur, void sebelum bayar | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/beku_setelah_bayar.sql`; C2; R2 |
| 6 | `supabase/tes/keamanan_fungsi.sql` | Sapuan public SECURITY DEFINER, ACL default/efektif, path, trigger-only | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/keamanan_fungsi.sql`; C2; R1 |
| 7 | `alat/uji-mutasi-0022.py` | Sembilan mutasi, kontrol, klasifikasi dan substitusi yang menyentuh dua lokasi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-mutasi-0022.py`; C2; R2 |
| 8 | `alat/periksa-keamanan-sql.py` | Dua tes efektif, sembilan mutasi, token tambahan, caller klasifikasi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-keamanan-sql.py`; C2; R1 |
| 9 | `alat/uji-konkuren-0022.py` | Lima kontrol, dua mutasi, bukti blocking, SQLSTATE dan efek tersimpan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-konkuren-0022.py`; C2; percobaan CLI §3.2 |
| 10 | `alat/uji-konkuren.py` | Preamble, loader, kedua uji dan cabang kalibrasi main | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-konkuren.py`; C2:1–155,210–446; R3 |
| 11 | `alat/klasifikasi_mutasi.py` | Seluruh fungsi asli; keluaran campuran runtime/asersi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/klasifikasi_mutasi.py`; C2; R1 |
| 12 | `alat/uji-sql.mjs` | Preamble auth/crypto tiruan, helper asersi, transaksi per berkas, keluaran dan exit | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-sql.mjs`; C2:1–354; percobaan Node §3.2 |
| 13 | `alat/uji-mutasi-0015.py` | Kontrol suite penuh vs tes per mutasi; pemakaian classifier | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-mutasi-0015.py`; C2:1–160; bukan run mutasi SQL |
| 14 | `.github/workflows/ci.yml` | Penambahan Batch-5, perintah yang dijalankan, pembatas kegagalan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:.github/workflows/ci.yml`; C2/diff; C3; R4 |
| 15 | `alat/periksa-gerbang-ci.py` | Daftar wajib, pembaca perintah, regex pelemahan, caller | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-gerbang-ci.py`; C2; RB; R4 |
| 16 | `aplikasi/alat/periksa-semua.sh` | Seluruh 115 baris; pemasangan otomatis dan kesetaraan dengan CI | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/alat/periksa-semua.sh`; C2; R4 |
| 17 | `supabase/tes/jejak_pelaku.sql` | Atribusi palsu ditolak; atribusi otomatis diuji sebelum pembayaran | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/jejak_pelaku.sql`; C2/diff |
| 18 | `supabase/tes/pembayaran.sql` | Fixture pesanan terpisah; cap/izin/alasan/PIN/idempoten; sebab penolakan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/pembayaran.sql`; C2/diff, termasuk 174–256 dan 261–413 |
| 19 | `supabase/tes/uang_peladen.sql` | Total 62.100, kembalian 37.900, void berbayar vs belum bayar, isolasi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/uang_peladen.sql`; C2/diff |
| 20 | `supabase/tes/void_satu_item.sql` | Item hidup, pembayaran sebagian, void terakhir pada pesanan lain tanpa bayar | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/void_satu_item.sql`; C2/diff |
| 21 | `docs/uji/BUKTI_T025_BEKU_SETELAH_BAYAR.md` | Klaim hasil, batas READ COMMITTED/crypto tiruan/AUD-2/deploy | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/BUKTI_T025_BEKU_SETELAH_BAYAR.md`; C2, seluruh dokumen |
| 22 | `docs/uji/BUKTI_T130_KEAMANAN_SQL.md` | Klaim 53 definer/20 trigger, 9 mutasi, sisa AST/initplan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/BUKTI_T130_KEAMANAN_SQL.md`; C2, seluruh dokumen |
| 23 | `docs/PRD.md` | M6, M10, alur voucher dan aturan pembatalan setelah uang pertama | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/PRD.md`; C2/diff; RB |
| 24 | `docs/TECH_SPEC.md` | §2, §4.4, §5, ART uang/perangkat; PIN pelanggan vs pegawai | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/TECH_SPEC.md`; C2/diff; RB |
| 25 | `docs/ROADMAP.md` | T1-30/T1-45 tetap terbuka; T1-24/25 dan sisa implementasi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/ROADMAP.md`; C2/diff; RB |
| 26 | `docs/DECISIONS_LOG.md` | T-023/T-025, pelaksanaan 0022/0023 dan batasnya | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/DECISIONS_LOG.md`; C2/diff |
| 27 | `docs/TERTANGGUH.md` | Keputusan selesai bukan implementasi selesai; 0 terbuka/25 selesai | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/TERTANGGUH.md`; C2/diff; RB |
| 28 | `docs/uji/AUDIT_RIWAYAT.md` | I F-17, F F-12/F-13, B F-11/K F-03, D F-08 dan bukti penutup | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/AUDIT_RIWAYAT.md`; C2/diff; RB; R8 |
| 29 | `docs/ops/SIAP-LANJUT.md` | Header dan prioritas Batch-5; catatan lama berlabel sejarah | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/ops/SIAP-LANJUT.md`; C2:1–86 dan rujukan terkait; RB mode isi |
| 30 | `PROJECT_STATE.md` | Posisi terbaru Batch-5 dan batas “bagian lebih lama = riwayat” | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:PROJECT_STATE.md`; C2/diff |
| 31 | `STATUS.md` | Header/status, klaim uji dan perubahan Batch-5 | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:STATUS.md`; C2/diff |
| 32 | `PANDUAN_PENGGUNA.md` | Perubahan angka/gerbang, rujukan; fixture pemindai rahasia | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:PANDUAN_PENGGUNA.md`; C2/diff; RB; R6 |
| 33 | `_log-sesi/LOG_SESI_2026-09-21_2.md` | Diff narasi Batch-5 vs artefak dan metadata CI | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:_log-sesi/LOG_SESI_2026-09-21_2.md`; C2/diff, bukan bukti eksekusi auditor |
| 34 | `supabase/migrations/0009_pesanan.sql` | `picu_item_salinan_beku`, immutabilitas identitas/parent item | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0009_pesanan.sql`; C2:224–242; telusur semua definisi ulang/drop |
| 35 | `supabase/migrations/0010_pembayaran.sql` | Privilege tabel, pembayar, diskon, pembatalan; append-only klien | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0010_pembayaran.sql`; C2:484–561; §6 |
| 36 | `supabase/migrations/0014_penutup_celah_putaran13.sql` | Pemicu AFTER item/diskon; pemicu metode pembayaran | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0014_penutup_celah_putaran13.sql`; C2:125–161, definisi terkait |
| 37 | `supabase/migrations/0015_penutup_celah_putaran16.sql` | Final hitung_total/pembayaran/item, caller void; null-auth lama | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0015_penutup_celah_putaran16.sql`; C2:144–203,455–677,909–1001 |
| 38 | `supabase/migrations/0017_pesanan_tertutup_beku.sql` | Pagar header sebelumnya, interaksi status lama | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0017_pesanan_tertutup_beku.sql`; C2 |
| 39 | `supabase/migrations/0021_kunci_diskon.sql` | Pagar serialisasi yang ditelusuri melalui harness/definisi target | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0021_kunci_diskon.sql`; C2:1–65; caller 0022 dan harness lama |
| 40 | `supabase/migrations/0018_perangkat_terdaftar.sql` | Identitas perangkat terverifikasi dan jalur verifikasi PIN, bukan sesi lengkap | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/migrations/0018_perangkat_terdaftar.sql`; C2 bagian terkait; tes perangkat; R8 |
| 41 | `supabase/tes/rls_semua_tabel.sql` | Dipanggil scanner T1-30; kontrak registri/policy/transitif dan lokasi asersi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/rls_semua_tabel.sql`; C2 terarah; R1 (injeksi keluaran, bukan SQL) |
| 42 | `supabase/tes/rls_pengguna.sql` | Kasir/owner/admin-cabang/tenant lain; izin dan pengaturan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/rls_pengguna.sql`; C2 |
| 43 | `supabase/tes/pin_batas_pasang.sql` | 20/15 menit, percobaan ke-21, jejak dan privilege | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/pin_batas_pasang.sql`; C2 |
| 44 | `supabase/tes/kredensial_pin.sql` | ACL, PIN lama, format 6 digit, penolakan/pencatatan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/kredensial_pin.sql`; C2 |
| 45 | `supabase/tes/percobaan_pin_perangkat.sql` | Delapan perangkat asing: 0 dilayani; pencabutan/kunci salah/12+1 | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/percobaan_pin_perangkat.sql`; C2 |
| 46 | `supabase/tes/hak_fungsi.sql` | Grant service_role, pembatas helper klien, kontrol positif | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/tes/hak_fungsi.sql`; C2 |
| 47 | `supabase/functions/verifikasi_pin/index.ts` | Handler asli, POST, auth forwarding, body, balasan, PIN tidak dikembalikan baseline | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:supabase/functions/verifikasi_pin/index.ts`; C2; R5; N1 |
| 48 | `alat/periksa-fungsi-pin.py` | Pembaca berbasis baris dan sepuluh self-test | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-fungsi-pin.py`; C2; RB; R5 |
| 49 | `alat/uji-edge-pin.mjs` | VM handler asli, E11 seluruh body, tidak mengawasi sink log | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/uji-edge-pin.mjs`; C2; N1 |
| 50 | `alat/periksa-rahasia.py` | Enam pola, indeks Git, file rahasia, cakupan bukan history | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-rahasia.py`; C2; RB; R6 |
| 51 | `alat/ci_target.py` | Query run per SHA dan pemilihan success tanpa workflow | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/ci_target.py`; C2:1–96; R7 |
| 52 | `alat/periksa-paket.py` | Aturan 5: SHA di baris CI vs SHA paket; aturan pohon/artefak | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-paket.py`; C2:349–493; R7 |
| 53 | `alat/artefak.py` | Pemisahan file/perintah/glob dan jalur relatif | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/artefak.py`; C2:1–92; RB lewat pemakai |
| 54 | `alat/lanjut-sesi.py` | Isi handoff vs kesegaran Git; cabang pilihan; mode --di-ci | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/lanjut-sesi.py`; C2:397–620; RB mode isi saja |
| 55 | `alat/periksa-temuan-audit.py` | Keberadaan bukti, status parsial, daftar luar cakupan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-temuan-audit.py`; C2:96–238; RB |
| 56 | `alat/periksa-rujukan.py` | Pola rujukan, pengecualian sejarah/rencana, daftar pensiun | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-rujukan.py`; C2:31–180; RB |
| 57 | `alat/review-pr.py` | Caller status_ci dan penolakan tanpa izin pemilik; tidak menyiapkan paket | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/review-pr.py`; C2:204–292; R7 |
| 58 | `alat/periksa-kunci-kalibrasi.py` | Kode pengaman/provenance saja; tidak menjalankan pencarian katalog luar | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-kunci-kalibrasi.py`; C2:50–228; tidak membuka kunci/bahan |
| 59 | `docs/uji/BERKAS_PENSIUN.md` | Keputusan mengeluarkan katalog; pengecualian rujukan sejarah | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/BERKAS_PENSIUN.md`; C2; R8 |
| 60 | `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md` | L-03/L-06 dan hubungan dengan daftar penutup | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md`; C2; RB; R8 |
| 61 | `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` | Petunjuk token vs paragraf least-privilege/TTL dan batas riwayat; calon ditarik | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/ops/LANGKAH_PEMILIK_SEKARANG.md`; C2:1–12,40–50,90–103; R8; caller SIAP_AKUN:52 |
| 62 | `docs/KEAMANAN.md` | §1/2/5/6/8/9/10/16: uang, PIN, status perangkat dan audit | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:docs/KEAMANAN.md`; C2 terarah; R8 |
| 63 | `_sistem/validate_system.py` | Eksekusi terhadap pohon target virtual; sumber pemeriksa umum | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:_sistem/validate_system.py`; RB |
| 64 | `alat/periksa-roadmap.py` | Sumber/eksekusi aturan 193 tugas dan self-test | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-roadmap.py`; RB |
| 65 | `alat/periksa-fondasi-independen.py` | Silang dokumen/entitas/RPC dan keputusan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:alat/periksa-fondasi-independen.py`; RB |
| 66 | `aplikasi/alat/periksa-uji.py` | Kerangka uji, pasangan logika/uji dan interaksi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/alat/periksa-uji.py`; RB; ini pemeriksaan statis, bukan Vitest |
| 67 | `aplikasi/alat/periksa-node.py` | Kebutuhan dari lockfile vs versi iklan/lingkungan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/alat/periksa-node.py`; RB |
| 68 | `aplikasi/package.json` | Skrip, batas Node, dependensi yang dideklarasikan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/package.json`; C2; RB |
| 69 | `aplikasi/package-lock.json` | Dibaca pemeriksa Node; bukan audit kerentanan daring baru | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/package-lock.json`; RB |
| 70 | `aplikasi/src/lib/env.ts` | Dua variabel klien, perilaku env kosong | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/lib/env.ts`; C2 |
| 71 | `aplikasi/src/lib/supabase.ts` | URL dibatasi, timeout, auth DAN data harus 200 | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/lib/supabase.ts`; C2:1–163 |
| 72 | `aplikasi/src/lib/tema.ts` | Validasi kode tema; getItem/setItem terlindungi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/lib/tema.ts`; C2:1–176 |
| 73 | `aplikasi/src/hook/useTema.ts` | Effect penyimpanan dan pemanggilan helper | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/hook/useTema.ts`; C2 |
| 74 | `aplikasi/src/hook/useJam.ts` | Interval dan cleanup | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/hook/useJam.ts`; C2 |
| 75 | `aplikasi/src/komponen/Lapis.tsx` | Fokus/Tab/Esc/cleanup dan caller callback | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/komponen/Lapis.tsx`; C2:1–104; tidak diuji peramban |
| 76 | `aplikasi/src/komponen/PemilihRingkas.tsx` | Penutupan, fokus, pointer luar, handler pilihan | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/komponen/PemilihRingkas.tsx`; C2:1–112 |
| 77 | `aplikasi/src/komponen/komponen.test.tsx` | Perbedaan SSR vs interaksi nyata; perubahan fokus dan KolomIsian | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/komponen/komponen.test.tsx`; C2:1–225; bukan runtime React |
| 78 | `aplikasi/src/komponen/PemilihRingkas.test.tsx` | Kontrol Esc/pointer/fokus/aksi | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/komponen/PemilihRingkas.test.tsx`; C2:1–110 |
| 79 | `aplikasi/src/komponen/Kartu.tsx`, `aplikasi/src/komponen/KeadaanGagal.tsx`, `aplikasi/src/komponen/KeadaanKosong.tsx`, `aplikasi/src/komponen/KeadaanMemuat.tsx`, `aplikasi/src/komponen/KolomIsian.tsx`, `aplikasi/src/komponen/Lencana.tsx`, `aplikasi/src/komponen/Tabel.tsx`, `aplikasi/src/komponen/Toast.tsx`, `aplikasi/src/komponen/Tombol.tsx` | Sembilan berkas dibaca: penerusan callback, a11y dan kondisi kosong | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/komponen/Kartu.tsx`; C2 per berkas; RB |
| 80 | `aplikasi/src/lib/env.test.ts`, `aplikasi/src/lib/supabase.test.ts`, `aplikasi/src/lib/tema.test.ts`, `aplikasi/src/hook/useTema.test.tsx`, `aplikasi/src/hook/useJam.test.tsx` | Daftar kasus dan ikatan dengan kode; bukan klaim eksekusi seluruh kasus | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:aplikasi/src/lib/env.test.ts`; C2 terarah; RB |
| 81 | Skill wajib | security-review, verification-before-completion, systematic-debugging, verification-loop, test-driven-development, prd-taskmaster, supabase, supabase-postgres-best-practices; ui-ux-pro-max untuk pembacaan komponen | `git show 09bcb89fc139b3be32ab874e7a004f0a3b0480ee:skills/security-review/SKILL.md`; Dibaca dari objek target sebelum penilaian; tanpa pemasangan pustaka |
Nama migrasi pada inventar disilang dengan `git ls-tree -r --name-only 09bcb89 -- supabase/migrations`, bukan nama rencana ROADMAP. Pemeriksa laporan `alat/audit-independen.py` hanya akan dieksekusi untuk validasi akhir; kode penilaiannya tidak dibaca untuk mengatur temuan/verdict.

### Empat lensa wajib

#### L1 Ancaman & Akses

- **Diperiksa:** Null-auth/definer, tenant/cabang, ACL 20 trigger, katalog, PIN Edge, rahasia
- **Perintah:** C2 migrasi/caller; R5/N1; R6; RB
- **Keluaran nyata / batas:** Baseline PIN 14/14; mutant log juga 14/14. Handler mutant mencatat PIN, suite Edge tetap 19/19 dengan penghapus tipe native. Baseline pemindai 2.367 berkas exit 0, secret-key dummy tidak ditolak. ACL runtime/53 fungsi belum diulang.

#### L2 Uang & Jejak

- **Diperiksa:** Pagar setelah Rp1, progres dapur/tarif, parent lama/baru, fixture lama, urutan lock/rollback
- **Perintah:** C2 0022/0009/0010/0014/0015/0021 dan empat fixture; R2; lima percobaan CLI wajib
- **Keluaran nyata / batas:** Substitusi mutasi progres mengubah **dua** baris (36 dan 108). CLI konkuren target di memori berhenti karena `pgserver`/`psycopg` tidak tersedia; tidak ada dua koneksi nyata. Risiko tambahan di §6 bukan uang salah yang sudah teramati.

#### L3 Kesepakatan Dokumen

- **Diperiksa:** T-023/T-025, kotak tugas, status penutup dan petunjuk pemilik
- **Perintah:** C2/diff; RB roadmap/fondasi/rujukan/temuan; R8
- **Keluaran nyata / batas:** 193 tugas; 38 entitas/45 RPC; 0 tertangguh terbuka, 25 selesai; 58 dokumen/2.278 rujukan lolos. T1-30/T1-45 tetap terbuka. Status di beberapa dokumen lain masih berlawanan (F-10).

#### L4 Mutu Uji

- **Diperiksa:** Sebab MERAH, kalibrasi, isolasi mutasi, gerbang workflow, kesetaraan lokal
- **Perintah:** R1–R4; R7; C3
- **Keluaran nyata / batas:** Classifier menerima keluaran campuran; main concurrency menerima galat sebagai kalibrasi; shell `cat {0}`/ekspresi continue-on-error lolos penjaga. CI target historis success, bukan eksekusi lokal auditor.

## 2. Klaim pembangun yang saya coba falsifikasi

“Tidak berhasil dibantah” di sini tidak sama dengan “sudah terbukti benar di database”. Klaim tambahan berasal dari sumber alat/dokumen aktual yang dipakai sebagai bukti Batch-5, bukan klaim buatan auditor.

| # | Klaim | Cara mencoba membantah | Hasil dan batas |
|---|---|---|---|
| K01 | 0022 membekukan rincian/header setelah pembayaran pertama termasuk Rp1, null-auth dan peladen | Telusuri semua trigger/caller, pembayaran yang sudah ada vs grant DELETE pembayaran; coba runner wajib | Pagar langsung tampak di sumber; **belum terverifikasi runtime**. Hipotesis menghapus pembayaran lewat service_role ada di §6, bukan temuan uang terverifikasi. |
| K02 | Parent lama/baru memakai kunci yang sama dengan pembayaran; aman dua arah READ COMMITTED | Bandingkan kunci 0022/0015/0021, per-row vs multi-row, skenario harness dan rollback | Lima kontrol/dua mutasi terdefinisi; pembayar di harness commit, bukan rollback. Tidak menjalankan transaksi nyata. Tidak mengesahkan generalisasi multi-parent/rollback. |
| K03 | Progres masak murni tidak menerapkan ulang tarif dan tidak membuka izin/status lama | Baca BEFORE+AFTER dan final guard item 0015; evaluasi mutasi progres | Skip AFTER dan guard lama ada. **Bukti mutasi spesifiknya tidak terisolasi** (F-03); bukan bukti baseline menerapkan tarif salah. |
| K04 | Empat fixture lama tetap menjaga izin, cap, PIN, atribusi dan void terakhir sebelum bayar | Bandingkan diff dan ikuti fixture baru sampai asersi sebab/efek | Asersi tersebut masih ada; contoh dapur diberi keanggotaan agar yang diuji izin, bukan isolasi. Eksekusi SQL independen tidak tersedia; tidak mengklaim fixture lulus lokal. |
| K05 | 0023 hanya mempersempit 20 ACL trigger; operasi lama hidup; 53 public definer dipindai | Periksa dua daftar ACL/body, SQL katalog, pemakai trigger | Daftar ACL eksplisit 20 sesuai; tidak mengubah body/policy. Angka **53 efektif dan kelangsungan operasi belum diukur ulang** di DB oleh auditor. |
| K06 | 65 SQL/101 aplikasi, periksa-semua, CI hijau; mutasi merah karena pagar, bukan setup | C3, percobaan runtime, R1–R3 | Ada 65 berkas SQL dalam tree dan CI target success. Angka 65 lulus/101 lulus lokal belum terbukti. Klaim classifier/kalibrasi murni pagar **terbantah secara unit/injeksi** (F-01/F-02/F-03). |
| K07 | PIN pelanggan dihapus, PIN pegawai/persetujuan tetap; AST/initplan, AUD-2, deploy tetap terbuka | Diff PRD/TECH_SPEC/ROADMAP/DECISIONS/TERTANGGUH | Tidak ditemukan penghapusan PIN pegawai/persetujuan dalam diff; dokumen terbaru memang mengakui sisa. Tidak menuduh fitur yang sengaja belum selesai sebagai regresi Batch-5. |
| K08 | Penjaga CI menolak pelemahan gerbang walau perintahnya tetap | Sisipkan literal if/continue-on-error sebagai kontrol, lalu ekspresi dan shell pencetak | Literal ditolak; ekspresi dan `shell: cat {0}` **lolos**. F-04. |
| K09 | periksa-semua menjalankan semua pemeriksaan yang sama dengan CI | Selisihkan perintah CI hasil parser asli dengan seluruh skrip lokal | Delapan perbedaan tekstual; setelah menelusuri mode/caller, enam panggilan benar-benar tidak terdaftar lokal, termasuk pemeriksa migrasi beku. Mode lanjut-sesi lokal bukan gap; cek Supabase memang CI-only. **Terbantah pada inventaris terarah**, bukan run lokal sukses. F-05. |
| K10 | Penjaga PIN memastikan PIN tidak masuk balasan/log; uji Edge memperkuatnya | Mutant inline response/raw body/computed console, handler asli dan suite asli dengan penghapus tipe native | Checker teks 14/14; log sungguh menerima PIN dummy; suite log-mutant 19/19. E11 justru menangkap mutant response. F-06. |
| K11 | Hasil LOLOS pemindai rahasia cukup mencakup kunci layanan yang digunakan | Tambah JWT dummy sebagai kontrol dan `sb_secret_` dummy dalam dokumen terlacak virtual | JWT ditolak, `sb_secret_` **lolos**. Bukan temuan kunci nyata bocor. F-07. |
| K12 | “CI target success” mengikat workflow pemeriksaan dan commit target paket | Respons API tiruan: CI failure + deploy success; lalu beda SHA baris CI | Kedua bentuk bukti salah diterima oleh fungsi asli. Target audit ini sendiri tetap punya CI yang benar-benar success. F-08/F-09. |
| K13 | Dokumen status/operasional merupakan petunjuk konsisten | Silang KEAMANAN, ledger L-03/L-06, pensiun, penutup B F-11/K F-03, dan langkah token | Ketidaksesuaian status ada (F-10), di luar diff utama Batch-5. Calon tentang TTL/scope ditarik: halaman langkah pemilik menyatakan bagian bawah sebagai riwayat, dan caller SIAP_AKUN juga menyatakan bukan daftar tugas aktif. |

## 3. Serangan yang dijalankan (kill attempts)

Semua mutant/injeksi berikut hanya di string/objek memori, **bukan perubahan sumber**. “Berhasil” berarti klaim penjaga dapat dipatahkan dalam batas probe, bukan eksploit database/produksi.

| # | Serangan dan kontrol | Perintah | Hasil aktual |
|---|---|---|---|
| A01 | Campur satu asersi dengan runtime `function ... does not exist`, dua urutan | R0+R1 | Keduanya `MERAH-PAGAR`; runtime saja `RUSAK`. |
| A02 | Kirim keluaran campuran ke **uji_diri T1-30 asli**, kasus RLS tanpa token tambahan | R0+R1 | `OK RLS tabel dilepas`, `HASIL: LOLOS ... 0 tidak sesuai`, return 0. SQL diganti keluaran sintetis, bukan dieksekusi. |
| A03 | Evaluasi daftar mutasi 0022 asli, bukan mengetik ulang substitusinya | R0+R2 | Sembilan mutasi; mutasi terakhir mengubah BEFORE baris 36 **dan** AFTER baris 108. |
| A04 | Hasil mutasi concurrency = koneksi hilang; kontrol utuh tetap True | R0+R3 | Main asli menyebut kalibrasi peka dan return 0. Bukan koneksi DB nyata yang diputus. |
| A05 | Hasil mutasi concurrency = utas menggantung/deadlock | R0+R3 | Main asli tetap LOLOS/return 0. |
| A06 | Hasil mutasi concurrency = ambang waktu gagal (0,99 < 1 detik) | R0+R3 | Main asli tetap LOLOS/return 0. |
| A07 | Tambah `if: false` dan literal `continue-on-error: true` pada step keamanan SQL | R0+R4 | Keduanya ditolak, exit 1; kontrol positif bagi probe penjaga. |
| A08 | Ganti pelemahan menjadi `continue-on-error: ${{ true }}` | R0+R4 | Exit 0, daftar masalah kosong; job-level varian juga pernah menghasilkan 0. |
| A09 | Biarkan perintah security check utuh tetapi pakai `shell: cat {0}` di step | R0+R4 | Exit 0, daftar masalah kosong. Varian `defaults.run.shell` yang dicoba sebelumnya ditolak; tidak dihitung sebagai bypass. |
| A10 | Cari gerbang CI yang tak dilaksanakan periksa-semua | R0+R4 | Delapan perbedaan literal, kemudian dipilah: enam panggilan hilang, satu beda mode yang bukan gap dan satu cek daring CI-only (F-05). Bukan run shell hijau. |
| A11 | Inline return PIN/raw request body/body["pin"]/pengecekan typeof | R0+R5 | Seluruh contoh dan baseline **14/14 LOLOS** oleh pemeriksa teks. |
| A12 | Log body melalui `globalThis["con"+"sole"]["log"]` | R0+R5; N1 | Static 14/14; handler asli yang dimutasi mencatat PIN dummy, baseline tidak. |
| A13 | Jalankan suite Edge dengan mutant response sebagai kontrol dan mutant log sebagai serangan | N1 | Utuh 19/19, response-mutant 18/19 (E11 gagal), log-mutant 19/19. Transpiler diganti `stripTypeScriptTypes`; bukan command esbuild/CI asli. |
| A14 | Sisipkan token JWT dummy vs secret-key Supabase dummy pada dokumen virtual | R0+R6 | Utuh exit 0, JWT exit 1, `sb_secret_` exit 0. Tidak memakai/menguji kredensial nyata. |
| A15 | API fixture menyatakan CI gagal, workflow deploy sukses pada SHA sama | R0+R7 | `status_ci`: `hijau=True`, `baris_paket`: success. CI gagal saja ditolak. |
| A16 | SHA target paket gagal pada fixture; baris CI diberi SHA berbeda yang sukses | R0+R7 | Aturan 5 tidak memberi masalah; fixture dengan SHA CI yang sama dengan target gagal ditolak. History/keberadaan objek diisolasi dengan stub. |
| A17 | Silang status perangkat/katalog dan instruksi token dengan dokumen aktual | R0+R8; C2 | Perangkat sudah dicatat ditutup, ledger masih DITUNDA; katalog dipensiunkan tetapi ledger masih menunggu keputusan. Kontradiksi TTL pada halaman historis tidak dihitung sebagai temuan aktif setelah penelusuran caller. |

Percobaan SQL/konkurensi yang **terhalang** tercantum terpisah berikut; tidak saya hitung sebagai serangan database yang selesai. Probe multi-row, pembayar rollback, lintas tenant/cabang dinamis dan pindah parent bersamaan belum terlaksana.

### 3.1 Lingkungan dan percobaan wajib

Lingkungan: Node **22.22.3**, npm **10.9.8**, Python **3.11.2**. `psql`/`postgres` tidak ada di PATH; `pgserver`, `psycopg`, PGlite dan esbuild tidak tersedia. Tidak ada pemasangan pustaka. Direktori aplikasi/alat/supabase tidak dimaterialisasi di checkout kerangka; sumbernya ada pada target Git.

| Perintah yang dicoba | Keluaran aktual | Arti |
|---|---|---|
| `python3 alat/uji-mutasi-0022.py` | `can't open file ... [Errno 2] No such file or directory`, exit 2 | CLI tidak dapat dibuka dari checkout sesi; **bukan** file target hilang. Sumber target/mutasi diuji di R2, SQL tidak jalan. |
| `python3 alat/periksa-keamanan-sql.py` | Kesalahan file sama, exit 2 | Tidak mengesahkan katalog efektif. |
| `python3 alat/periksa-keamanan-sql.py --uji-diri` | Kesalahan file sama, exit 2 | R1 memeriksa keputusan self-test dengan injeksi, bukan sembilan run SQL. |
| `python3 alat/uji-konkuren.py` | Kesalahan file sama, exit 2 | Program **target** juga dicoba lewat `exec(compile(git show ...))`: mencetak `GAGAL: pustaka pgserver belum terpasang`, SystemExit 2. |
| `python3 alat/uji-konkuren-0022.py` | Kesalahan file sama, exit 2 | Program target lewat memori berhenti dengan `ModuleNotFoundError: No module named 'psycopg'`. |
| Program target `alat/uji-sql.mjs --daftar` lewat `git show ... | node --input-type=module - --daftar` | `ERR_MODULE_NOT_FOUND: Cannot find package '@electric-sql/pglite'` | Tidak menjalankan SQL; bukan daftar katalog berhasil. |
| `(cd aplikasi && npm test)`, `(cd aplikasi && npm run typecheck)`, `(cd aplikasi && npm run lint)` | `cd: aplikasi: No such file or directory`, masing-masing exit 1 | Suite aplikasi tidak dijalankan auditor. |
| `bash aplikasi/alat/periksa-semua.sh` | **Tidak dieksekusi**; inspeksi baris 15–25 menunjukkan npm ci/pip install otomatis | Sengaja tidak melanggar larangan memasang pustaka/menulis salinan. |

Pembacaan sumber target dan pemeriksa murni diteruskan melalui pembaca objek Git. Percobaan awal pembungkus pathlib sempat jatuh ke checkout fisik dan memberi hasil tidak sah; **hasil itu dibuang**, lalu pembungkus diperbaiki dan diberi kontrol `type(G(ROOT)) is G` serta kesamaan byte ROADMAP dengan `git show`. Hasil berikut hanya berasal dari pengulangan yang benar. Larangan membaca bahan/kunci kalibrasi tidak dilonggarkan; panduan umum kalibrasi boleh dibaca validator, katalog/kunci/bahan jawaban tetap tidak dibaca.

### 3.2 Verifikasi yang dapat diselesaikan

**CI historis, bukan run auditor:**

```bash
gh run view 35574069120 --repo With-AI-Agent/Resto-Barokah \
  --json headSha,status,conclusion,createdAt,updatedAt,jobs
```

Keluaran: SHA **persis target**, `completed/success`, mulai `2026-09-21T07:40:24Z`, selesai `2026-09-21T07:49:21Z`; job `106251883660` dan langkah terkait lint/typecheck/Vitest, SQL penuh, mutasi 0022, concurrency, keamanan SQL dan Edge semuanya `success`. [Run GitHub](https://github.com/With-AI-Agent/Resto-Barokah/actions/runs/35574069120).

`gh api repos/With-AI-Agent/Resto-Barokah/actions/jobs/106251883660/logs` dicoba untuk memeriksa keluaran rinci; unduhan blob berhenti dengan **EOF**, body 0 byte. URL sementara bertanda tangan tidak disalin ke laporan. Jadi **angka 65 SQL lulus/101 aplikasi lulus dan alasan tiap mutasi di run historis belum diperiksa dari log**. `git ls-tree -r --name-only TARGET -- supabase/tes` memang berisi **65 file SQL**, tetapi jumlah file bukan jumlah yang terbukti lulus.

**Pemeriksa target melalui RB (eksekusi kode asli dengan filesystem virtual baca-saja):**

| Pemeriksaan | Keluaran teramati |
|---|---|
| `_sistem/validate_system.py` | `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`, exit 0 |
| `alat/periksa-roadmap.py` | LOLOS; 193 tugas, atribut lengkap, 38 tabel, 45 RPC, 0 rujukan tertangguh aktif |
| `alat/periksa-roadmap.py --uji-diri` | 9 kasus OK, termasuk kontrol utuh dan penolakan penanda hilang/basi |
| `alat/periksa-fondasi-independen.py` | BERSIH; 193 tugas; 0 atribut/pengisi/rujukan mati; 0 terbuka, 25 selesai |
| `alat/periksa-fungsi-pin.py` | 14 lolos, 0 gagal |
| `alat/periksa-fungsi-pin.py --uji-diri` | Sumber utuh diterima, 10 contoh cacat bawaan ditolak |
| `alat/periksa-gerbang-ci.py` | 74 gerbang wajib; dua workflow sebar ikut diperiksa; LOLOS |
| `aplikasi/alat/periksa-uji.py` | 7 OK, 1 INFO, 0 GAGAL; 6 berkas logika punya uji; 97 deklarasi uji terbaca statis |
| `aplikasi/alat/periksa-node.py` | 6 pemeriksaan LOLOS; minimum dari lock >=22.12.0; lingkungan 22.22.3 |
| `alat/periksa-temuan-audit.py` | 102 temuan terlacak, 96 baris penutup, 20 temuan luar cakupan; LOLOS |
| `alat/periksa-rujukan.py` | 58 dokumen, 2.278 rujukan, 2 berkas pensiun; LOLOS |
| `alat/periksa-rahasia.py` | 2.367 berkas, 6 pola; LOLOS; binary dilewati sebagaimana perilaku aslinya |
| `alat/lanjut-sesi.py`, fungsi `periksa(..., penuh=False)` | `[]`; hanya isi, tidak menguji kesegaran HEAD/push cabang pembangun |
| Parsing AST Python alat/aplikasi/validator, tanpa import/eksekusi | 43 file valid sintaks; checker laporan audit sengaja tidak diinspeksi |

“97 terbaca statis” bukan pembantahan terhadap klaim 101 runtime: kasus berparameter/loop dapat menghasilkan jumlah berbeda. Kata “terpasang” yang dicetak pemeriksa kerangka uji berarti dependensi tercantum di package, **bukan** konfirmasi node_modules auditor ada.

### 3.3 Perintah reproduksi read-only

Blok berikut merupakan bagian laporan, bukan berkas alat baru. Seluruh sumber dibaca dari SHA target. Untuk menjalankan salah satu probe Python dari laporan **tanpa membuat file lain**:

```bash
cd /home/user/Resto-Barokah
LAPORAN=docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md
PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R1 <<'PY'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
scope = {'__name__': 'audit_readonly'}
for ident in ['R0', *sys.argv[2:]]:
    match = re.search(r'<!-- PROBE ' + re.escape(ident) + r' -->\s*```python\n(.*?)\n```', text, re.S)
    if not match:
        raise RuntimeError('blok tidak ditemukan: ' + ident)
    exec(compile(match.group(1), '<laporan:' + ident + '>', 'exec'), scope)
PY
```

Ganti `R1` dengan `R2`, `R3`, `R4`, `R5`, `R6`, `R7`, `R8`, atau `RB`. R0 mengarahkan pembacaan Path/glob ke pohon target dan menolak penulisan. Pada RB, enumerasi `git ls-files` dua pemeriksa diganti daftar `git ls-tree TARGET`, agar tidak memindai HEAD kerangka. Uji injeksi secara eksplisit mengganti **batas I/O atau hasil tes**, bukan logika keputusan yang sedang dinilai.

<details>
<summary>R0 — pembaca sumber target, modul, dan filesystem virtual</summary>

<!-- PROBE R0 -->
```python
import ast, contextlib, glob, importlib.abc, importlib.util, io, os
import pathlib, subprocess, sys, types
from functools import lru_cache
sys.dont_write_bytecode = True
S = '09bcb89fc139b3be32ab874e7a004f0a3b0480ee'
ROOT = os.getcwd()
REPORT = 'docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md'
O = pathlib.PosixPath
files = set(subprocess.check_output(
    ['git', 'ls-tree', '-r', '--name-only', S], text=True).splitlines())
dirs = {'.'}
for f in files:
    dirs.update(str(p) for p in pathlib.PurePosixPath(f).parents)
@lru_cache(None)
def source(f):
    name = pathlib.PurePosixPath(f).name
    if f.endswith('kalibrasi-cacat.json') or (
        '/kalibrasi/' in f and ('KUNCI' in f or name.startswith('pr-bahan-'))
    ):
        raise PermissionError('kunci/bahan kalibrasi tidak dibaca')
    return subprocess.check_output(['git', 'show', S + ':' + f])
def read(f):
    return source(f).decode('utf8')
def rel(p):
    a = os.path.abspath(str(p))
    return os.path.relpath(a, ROOT) if a == ROOT or a.startswith(ROOT + '/') else None
class G(O):
    def __new__(cls, *args, **kw):
        return cls._from_parts(args)
    def resolve(self, strict=False):
        return G(os.path.abspath(self))
    def read_bytes(self):
        r = rel(self)
        if r is None or r == REPORT:
            return O(self).read_bytes()
        if r not in files:
            raise FileNotFoundError(str(self))
        return source(r)
    def read_text(self, encoding=None, errors=None):
        return self.read_bytes().decode(encoding or 'utf8', errors or 'strict')
    def is_file(self):
        r = rel(self)
        return r in files if r is not None and r != REPORT else O(self).is_file()
    def is_dir(self):
        r = rel(self)
        return r in dirs if r is not None else O(self).is_dir()
    def exists(self):
        return self.is_file() or self.is_dir()
    def glob(self, pattern):
        r = rel(self)
        if r is None:
            yield from (G(p) for p in O(self).glob(pattern))
            return
        prefix = '' if r == '.' else r + '/'
        for f in sorted(files | dirs):
            if not f.startswith(prefix) or f == r:
                continue
            q = f[len(prefix):]
            pats = [pattern] + ([pattern[3:]] if pattern.startswith('**/') else [])
            if any(pathlib.PurePosixPath(q).match(p) and
                   ('**' in pattern or q.count('/') == p.count('/')) for p in pats):
                yield G(ROOT) / f
    def rglob(self, pattern):
        return self.glob('**/' + pattern)
    def iterdir(self):
        return self.glob('*')
pathlib.Path = G
old_glob = glob.glob
def gitglob(p, **kw):
    r = rel(p)
    return [str(x) for x in G(ROOT).glob(r)] if r is not None else old_glob(p, **kw)
glob.glob = gitglob
class Loader(importlib.abc.Loader):
    def __init__(self, f):
        self.f = f
    def create_module(self, spec):
        return None
    def exec_module(self, m):
        m.__file__ = ROOT + '/' + self.f
        exec(compile(source(self.f), m.__file__, 'exec'), m.__dict__)
class Finder(importlib.abc.MetaPathFinder):
    def find_spec(self, name, path=None, target=None):
        for f in ['alat/' + name.replace('.', '/') + '.py',
                  '_sistem/' + name.replace('.', '/') + '.py']:
            if f in files:
                return importlib.util.spec_from_loader(name, Loader(f))
sys.meta_path.insert(0, Finder())
def load(f, name=None):
    name = name or 'audit_' + pathlib.PurePosixPath(f).stem.replace('-', '_')
    m = types.ModuleType(name)
    sys.modules[name] = m
    Loader(f).exec_module(m)
    return m
def run_main(f, args=()):
    sys.argv = [f, *args]
    try:
        exec(compile(source(f), ROOT + '/' + f, 'exec'),
             {'__name__': '__main__', '__file__': ROOT + '/' + f})
    except SystemExit as e:
        return e.code
    return 0
def readonly(event, args):
    if event == 'open' and isinstance(args[2], int) and args[2] & (
        os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC
    ):
        raise PermissionError('audit read-only: ' + str(args[0]))
    if event in {'os.mkdir', 'os.remove', 'os.rename', 'os.rmdir', 'os.symlink', 'os.link'}:
        raise PermissionError('audit read-only: ' + event)
sys.addaudithook(readonly)
assert type(G(ROOT)) is G
assert (G(ROOT) / 'docs/ROADMAP.md').read_bytes() == source('docs/ROADMAP.md')
print('R0: target tepat; pembacaan objek Git; penulisan dilarang')
```

</details>

<details>
<summary>R1 — classifier dan caller self-test keamanan SQL</summary>

<!-- PROBE R1 -->
```python
k = load('alat/klasifikasi_mutasi.py', 'klasifikasi_mutasi')
def output(errors):
    return ''.join('  GAGAL supabase/tes/' + f + '\n' + why + '\n'
                   for f, why in errors) + f'uji: 0 LULUS · {len(errors)} GAGAL\n'
a = ('a.sql', 'HARAPAN TIDAK TERPENUHI: pagar')
b = ('b.sql', 'function public.hilang() does not exist')
for label, errs in [('asersi', [a]), ('runtime', [b]),
                    ('asersi lalu runtime', [a, b]), ('runtime lalu asersi', [b, a])]:
    print(label, '=>', k.klasifikasi(1, output(errs)))
print('tanpa ringkasan =>', k.klasifikasi(1, 'syntax error at or near "X"'))
print('exit0, nol tes =>', k.klasifikasi(0, 'uji: 0 LULUS · 0 GAGAL'))
# Eksekusi uji_diri asli; seluruh filesystem temporer dan keluaran SQL disimulasikan.
m = load('alat/periksa-keamanan-sql.py')
base = read(m.MIG)
data = {m.MIG: base}
class P(pathlib.PurePosixPath):
    def read_text(self, *a, **kw):
        return data[str(self).removeprefix('/__audit_memory_only/')]
    def write_text(self, text, *a, **kw):
        data[str(self).removeprefix('/__audit_memory_only/')] = text
    def symlink_to(self, *a, **kw):
        pass
@contextlib.contextmanager
def temp(**kw):
    yield '/__audit_memory_only'
m.Path = P
m.tempfile = types.SimpleNamespace(TemporaryDirectory=temp)
m.shutil = types.SimpleNamespace(copytree=lambda *a: None, copy2=lambda *a: None)
fn = next(n for n in ast.parse(read('alat/periksa-keamanan-sql.py')).body
          if isinstance(n, ast.FunctionDef) and n.name == 'uji_diri')
assignment = next(n for n in fn.body if isinstance(n, ast.Assign)
                  and any(isinstance(t, ast.Name) and t.id == 'mutasi' for t in n.targets))
cases = eval(compile(ast.Expression(assignment.value), '<mutasi asli>', 'eval'))
expected = {sql: token for _, sql, token in cases}
def run(root):
    tail = data[m.MIG][len(base):].strip()
    if not tail:
        return subprocess.CompletedProcess([], 0, 'uji: 2 LULUS · 0 GAGAL\n', '')
    if tail == 'BUKAN SQL;':
        return subprocess.CompletedProcess([], 1, 'migrasi tidak bisa diterapkan', '')
    if tail == 'alter table public.pesanan disable row level security;':
        out = output([
            ('keamanan_fungsi.sql', 'function public.hilang() does not exist'),
            ('rls_semua_tabel.sql', 'HARAPAN TIDAK TERPENUHI: RLS tabel dilepas')])
    else:
        out = ('  GAGAL supabase/tes/keamanan_fungsi.sql\n'
               'HARAPAN TIDAK TERPENUHI: ' + expected[tail] + '\nuji: 1 LULUS · 1 GAGAL\n')
    return subprocess.CompletedProcess([], 1, out, '')
m.jalankan = run
print('INJEKSI KELUARAN, BUKAN SQL; uji_diri return:', m.uji_diri())
```

</details>

<details>
<summary>R2 — mutasi progres mengubah BEFORE dan AFTER</summary>

<!-- PROBE R2 -->
```python
path = 'supabase/migrations/0022_beku_setelah_bayar.sql'
asli = read(path)
fn = next(n for n in ast.parse(read('alat/uji-mutasi-0022.py')).body
          if isinstance(n, ast.FunctionDef) and n.name == 'main')
assignment = next(n for n in fn.body if isinstance(n, ast.Assign)
                  and any(isinstance(t, ast.Name) and t.id == 'mutasi' for t in n.targets))
mutasi = eval(compile(ast.Expression(assignment.value), '<daftar asli>', 'eval'), {'asli': asli})
label, mutant = mutasi[-1]
print('jumlah mutasi:', len(mutasi), '; label terakhir:', label)
for n, (before, after) in enumerate(zip(asli.splitlines(), mutant.splitlines()), 1):
    if before != after:
        print(path + ':' + str(n), '\n-', before, '\n+', after)
```

</details>

<details>
<summary>R3 — keputusan kalibrasi concurrency lama</summary>

<!-- PROBE R3 -->
```python
main_ast = next(n for n in ast.parse(read('alat/uji-konkuren.py')).body
                if isinstance(n, ast.FunctionDef) and n.name == 'main')
code = compile(ast.Module(body=[main_ast], type_ignores=[]), '<main asli>', 'exec')
for reason in ['galat koneksi: connection lost', 'utas menggantung (deadlock?)',
               'pemanggil-2 tidak tertahan cukup lama: 0.99 < 1.0']:
    state = {'mutasi': False}
    class Server:
        def get_uri(self): return 'INJEKSI-TANPA-DATABASE'
        def cleanup(self): pass
    def server_baru(name):
        state['mutasi'] = 'mutasi' in name
        return Server()
    def result(uri):
        return (False, reason) if state['mutasi'] else (True, 'kontrol hasil simulasi')
    env = dict(server_baru=server_baru, muat_skema=lambda *a: None,
               pasang_tiruan_pgcrypto=lambda: None, uji_f13=result, uji_f12=result,
               MUTASI_F13_TANPA_KUNCI='stub', MUTASI_F12_TANPA_KUNCI='stub')
    exec(code, env)
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = env['main']()
    print('INJEKSI:', reason, '; RETURN', rc)
    print('\n'.join(x for x in buf.getvalue().splitlines()
                    if 'kalibrasi:' in x or 'HASIL:' in x))
```

</details>

<details>
<summary>R4 — workflow dan kesetaraan gerbang lokal</summary>

<!-- PROBE R4 -->
```python
m = load('alat/periksa-gerbang-ci.py')
data = {p: read(p) for p in ['.github/workflows/ci.yml',
        '.github/workflows/sebar-skema.yml', '.github/workflows/sebar-halaman.yml']}
class Mem(pathlib.PurePosixPath):
    def is_file(self): return str(self) in data
    def read_text(self, **kw): return data[str(self)]
base = data['.github/workflows/ci.yml']
line = next(l for l in base.splitlines() if 'name: Keamanan SQL efektif' in l)
for name, extra in [
    ('utuh', ''), ('if false', '        if: false'),
    ('continue literal', '        continue-on-error: true'),
    ('continue ekspresi', '        continue-on-error: ${{ true }}'),
    ('shell pencetak', '        shell: cat {0}')]:
    data['.github/workflows/ci.yml'] = base.replace(line, line + '\n' + extra, 1) if extra else base
    print(name, '=>', m.periksa(Mem('.')))
local = read('aplikasi/alat/periksa-semua.sh')
print('Perintah CI yang tidak tercantum dalam skrip lokal:')
for cmd in m.perintah_ci(base):
    if cmd not in local:
        print(cmd)
```

</details>

<details>
<summary>R5 — false negative pemeriksa PIN</summary>

<!-- PROBE R5 -->
```python
m = load('alat/periksa-fungsi-pin.py')
s = read('supabase/functions/verifikasi_pin/index.ts')
mutants = [
    ('utuh', ''),
    ('inline PIN', '  return balasan({ pin: pin }, 200, kepala)\n'),
    ('typeof PIN', '  if (typeof pin === "string") return balasan({ pin }, 200, kepala)\n'),
    ('badan mentah', '  return balasan(badan, 200, kepala)\n'),
    ('index pin', '  return balasan({ nilai: badan["pin"] }, 200, kepala)\n'),
    ('computed console', '  globalThis["con" + "sole"]["log"](badan)\n')]
for name, add in mutants:
    text = s.replace('  const aksi =', add + '  const aksi =', 1) if add else s
    assert not add or text != s
    result = m.periksa_isi(text)
    print(name, sum(row[1] for row in result), '/', len(result), 'LOLOS')
```

</details>

<details>
<summary>R6 — secret key format tidak dikenali</summary>

<!-- PROBE R6 -->
```python
m = load('alat/periksa-rahasia.py')
data = {p: read(p) for p in ['.gitignore',
        'docs/ops/DAFTAR_KUNCI_PEMILIK.template.md', 'PANDUAN_PENGGUNA.md']}
class Mem(pathlib.PurePosixPath):
    def is_file(self): return str(self) in data
    def read_text(self, **kw): return data[str(self)]
m.berkas_terlacak = lambda akar: list(data)
original = data['PANDUAN_PENGGUNA.md']
for name, key in [('utuh', ''),
                  ('JWT dummy', 'eyJ' + 'hbGciOiJIUzI1NiJ9' + '.' + 'abcdefghijklmnop' + '.qrstuvwxyz'),
                  ('Supabase secret dummy', 'sb_secret_' + 'A' * 40)]:
    data['PANDUAN_PENGGUNA.md'] = original + '\n' + key
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = m.periksa(Mem('.'))
    print(name, '=>', rc)
    print('\n'.join(x for x in buf.getvalue().splitlines() if 'HASIL:' in x))
```

</details>

<details>
<summary>R7 — provenance workflow dan commit dalam bukti CI</summary>

<!-- PROBE R7 -->
```python
from unittest.mock import patch
m = load('alat/ci_target.py', 'ci_target')
m.nama_repo = lambda akar: 'With-AI-Agent/Resto-Barokah'
for name, runs in [
    ('CI gagal', [{'path': '.github/workflows/ci.yml', 'head_sha': S,
                   'conclusion': 'failure', 'id': 1}]),
    ('CI gagal + deploy success', [
        {'path': '.github/workflows/sebar-halaman.yml', 'head_sha': S,
         'conclusion': 'success', 'id': 2},
        {'path': '.github/workflows/ci.yml', 'head_sha': S,
         'conclusion': 'failure', 'id': 1}])]:
    import json
    def stub(cmd, **kw):
        return subprocess.CompletedProcess(cmd, 0, json.dumps({'workflow_runs': runs}), '')
    with patch.object(m.subprocess, 'run', stub):
        print('API TIRUAN', name, '=>', m.status_ci(S, G(ROOT)))
        print(m.baris_paket(S, G(ROOT)))
# Hanya aturan 5 yang dinilai; history dan keberadaan objek ditahan konstan.
p = load('alat/periksa-paket.py')
T, OTHER = 'a' * 40, 'b' * 40
p._induk_commit = lambda *a, **kw: ('fixture-writer', T)
p.paket_ditulis_sah = lambda *a: True
p.jalankan = lambda *a: (0, '')
ci = types.ModuleType('ci_target')
seen = []
def status(sha, akar):
    seen.append(sha)
    return {'bisa': True, 'hijau': sha == OTHER,
            'rincian': 'success' if sha == OTHER else 'failure'}
ci.status_ci = status
sys.modules['ci_target'] = ci
for label, sha in [('SHA target gagal', T), ('baris CI SHA lain sukses', OTHER)]:
    seen.clear()
    text = (f'- **Commit yang direview:** `{T}`\n'
            f'- **CI commit target:** success (run 2) — diperiksa mesin terhadap commit `{sha}`\n')
    errs, notes = p.periksa_paket('HEAD', 'docs/uji/review-pr/PKT-2026-09-21-probe.md', text)
    print('FIXTURE', label, '=> masalah', errs, '; SHA dicek', seen)
```

</details>

<details>
<summary>R8 — bukti silang dokumen, tanpa membuka kunci kalibrasi</summary>

<!-- PROBE R8 -->
```python
selections = {
    'docs/KEAMANAN.md': [(38, 40), (95, 100), (138, 140)],
    'docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md': [(18, 18), (21, 21)],
    'docs/uji/BERKAS_PENSIUN.md': [(16, 16)],
    'docs/uji/AUDIT_RIWAYAT.md': [(119, 119), (150, 151), (182, 182), (196, 196)],
    'docs/ops/LANGKAH_PEMILIK_SEKARANG.md': [(1, 12), (40, 50), (90, 103)],
}
for path, ranges in selections.items():
    print('\n===', path, '===')
    for n, line in enumerate(read(path).splitlines(), 1):
        if any(lo <= n <= hi for lo, hi in ranges):
            print(n, line)
```

</details>

<details>
<summary>RB — baseline pemeriksa murni terhadap pohon target</summary>

<!-- PROBE RB -->
```python
for path, args in [
    ('_sistem/validate_system.py', []), ('alat/periksa-roadmap.py', []),
    ('alat/periksa-roadmap.py', ['--uji-diri']),
    ('alat/periksa-fondasi-independen.py', []), ('alat/periksa-fungsi-pin.py', []),
    ('alat/periksa-fungsi-pin.py', ['--uji-diri']), ('alat/periksa-gerbang-ci.py', []),
    ('aplikasi/alat/periksa-uji.py', []), ('aplikasi/alat/periksa-node.py', [])]:
    print('\n=== TARGET', path, args, '===')
    print('EXIT', run_main(path, args))
for path in ['alat/periksa-temuan-audit.py', 'alat/periksa-rujukan.py',
             'alat/periksa-rahasia.py', 'alat/lanjut-sesi.py']:
    m = load(path)
    if path.endswith('periksa-rujukan.py'):
        m.daftar_md = lambda akar: [p for p in sorted(files)
            if p.endswith('.md') and not p.startswith(m.FOLDER_DIKECUALIKAN)]
    if path.endswith('periksa-rahasia.py'):
        m.berkas_terlacak = lambda akar: sorted(files)
    print('\n=== TARGET', path, '===')
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        rc = m.periksa(G(ROOT), penuh=False) if path.endswith('lanjut-sesi.py') else m.periksa(G(ROOT))
    lines = buf.getvalue().splitlines()
    print('\n'.join(lines if len(lines) < 18 else lines[:2] + ['[catatan diringkas]'] + lines[-6:]))
    print('RETURN', rc)
```

</details>

**N1 dijalankan dengan Node**, bukan melalui wrapper Python R0. Ekstrak blok JavaScript dari laporan dan alirkan langsung:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 - \
  docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md <<'PY' | \
  node --experimental-vm-modules --input-type=module -
import pathlib, re, sys
s = pathlib.Path(sys.argv[1]).read_text()
print(re.search(r'<!-- PROBE N1 -->\s*```javascript\n(.*?)\n```', s, re.S).group(1))
PY
```

<details>
<summary>N1 — handler dan suite Edge, jaringan tiruan, native type stripping</summary>

<!-- PROBE N1 -->
```javascript
import { execFileSync } from 'node:child_process';
import { stripTypeScriptTypes } from 'node:module';
import * as paths from 'node:path';
import * as urls from 'node:url';
import vm from 'node:vm';
const S = '09bcb89fc139b3be32ab874e7a004f0a3b0480ee';
const ROOT = process.cwd() + '/';
const get = f => execFileSync('git', ['show', S + ':' + f], { encoding: 'utf8' });
const edge = get('supabase/functions/verifikasi_pin/index.ts');
const logged = edge.replace('  const aksi =',
  '  globalThis["con" + "sole"]["log"](badan)\n  const aksi =');
const body = {
  pengguna_id: 'e2000000-0000-4000-8000-000000000003', pin: '654321',
  perangkat_id: 'de000000-0000-0000-0000-000000000003',
  perangkat_kunci: 'kunci-uji-hp-kasir-0123456789'
};
for (const [name, source] of [['utuh', edge], ['log-mutant', logged]]) {
  let handler;
  const logs = [];
  const context = vm.createContext({
    Deno: { serve: f => handler = f, env: { get: k => ({
      SUPABASE_URL: 'https://uji.invalid', SUPABASE_ANON_KEY: 'sb_publishable_uji'
    })[k] } }, Request, Response, console: { log: x => logs.push(x) },
    fetch: async () => Response.json([{ berhasil: true, sisa_percobaan: 5, pesan: 'ok' }])
  });
  vm.runInContext(stripTypeScriptTypes(source), context);
  const r = await handler(new Request('https://fungsi.invalid/verifikasi_pin', {
    method: 'POST', headers: { Authorization: 'Bearer token-uji', 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }));
  console.log('HANDLER', name, JSON.stringify({ status: r.status,
    loggedPIN: logs.some(x => JSON.stringify(x).includes(body.pin)) }));
}
const runner = get('alat/uji-edge-pin.mjs');
const responseLeak = edge.replace('    {\n      berhasil: hasil?.berhasil === true,',
  '    { pin: pin,\n      berhasil: hasil?.berhasil === true,');
if (logged === edge || responseLeak === edge) throw Error('mutasi tidak diterapkan');
for (const [name, text] of [['utuh', edge], ['response-mutant', responseLeak], ['log-mutant', logged]]) {
  const output = [];
  let exit;
  const context = vm.createContext({
    console: { log: (...x) => output.push(x.join(' ')) },
    process: { exit: c => { exit = c; } }, Response, Request, URL
  });
  const mods = {
    'node:fs': { readFileSync: p => {
      if (p !== ROOT + 'supabase/functions/verifikasi_pin/index.ts') throw Error('outside Edge: ' + p);
      return text;
    } },
    'node:path': paths, 'node:url': urls, 'node:vm': { default: vm },
    'node:module': { createRequire: () => name => {
      if (name !== 'esbuild') throw Error(name);
      return { transformSync: s => ({ code: stripTypeScriptTypes(s) }) };
    } }
  };
  const m = new vm.SourceTextModule(runner, {
    context, identifier: ROOT + 'alat/uji-edge-pin.mjs',
    initializeImportMeta(meta) { meta.url = urls.pathToFileURL(ROOT + 'alat/uji-edge-pin.mjs').href; }
  });
  await m.link(name => {
    const val = mods[name];
    if (!val) throw Error(name);
    return new vm.SyntheticModule(Object.keys(val), function () {
      for (const [k, v] of Object.entries(val)) this.setExport(k, v);
    }, { context });
  });
  await m.evaluate();
  console.log('SUITE ASLI + NATIVE TYPE STRIPPING', name);
  console.log(output.filter(x => x.includes('GAGAL') || x.includes('E11') || x.includes('RINGKASAN')).join('\n'));
  console.log('EXIT', exit);
}
```

</details>

## 4. Temuan

### [F-01] Classifier menerima merah campuran runtime/asersi; caller T1-30 dapat ikut meloloskannya

- **Tingkat:** K-3 — kelemahan alat pembuktian, bukan bukti kebocoran data/uang target.
- **Artefak:** `alat/klasifikasi_mutasi.py:53–84`; `alat/periksa-keamanan-sql.py:24,67–74`; keluaran runner `alat/uji-sql.mjs:304–348`.
- **Klaim yang dilanggar:** merah karena function/sintaks/runtime bukan bukti pagar; self-test menolak salinan rusak.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R1` dengan heredoc pembaca R0 di §3.3. perintah R0+R1. Dua berkas gagal, satu `function public.hilang() does not exist` dan satu `HARAPAN TIDAK TERPENUHI`, menghasilkan `MERAH-PAGAR` dalam kedua urutan. Dalam injeksi ke `uji_diri()` asli, runtime pada `keamanan_fungsi.sql` diikuti asersi RLS pada `rls_semua_tabel.sql` tetap menghasilkan `OK RLS tabel dilepas` dan return 0. Kontrol runtime saja menghasilkan `RUSAK`.
- **Skenario gagal:** satu tes tidak pernah mencapai asersinya karena runtime rusak, tes kedua gagal oleh pagar; self-test keseluruhan masih menyatakan 9 mutasi sesuai. Ini membantah pemisahan sebab, **tidak menyatakan keluaran campuran tersebut terjadi di CI historis**.
- **Dugaan penyebab:** baris 81 memakai `any` asersi dari seluruh sebab; baris 84 memilih sebab berkas terakhir. Tambahan syarat HARAPAN/token di caller hanya membantu sebagian urutan/kasus. Dua mutasi RLS tidak mempunyai token spesifik tambahan.
- **Cara membuktikan perbaikan:** R1 harus mengklasifikasikan kedua urutan campuran sebagai RUSAK dan self-test menolaknya; asersi murni tetap MERAH-PAGAR. Tambahkan kontrol runtime-before/assertion-after serta kebalikannya pada caller dua-berkas. Ulangi run SQL nyata sesudah lingkungan tersedia.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada fungsi asli dan keputusan caller dengan injeksi keluaran; bukan run SQL. Caller 0015/0022 yang memilih satu berkas tidak otomatis terkena skenario dua-berkas ini.

### [F-02] Kalibrasi concurrency lama menerima semua `False`, termasuk koneksi/deadlock/timing

- **Tingkat:** K-3 — bukti kepekaan uji dapat hijau palsu.
- **Artefak:** `alat/uji-konkuren.py:250–255,373–385,405–412,427–433`; caller CI dan periksa-semua; penutup F F-12/F F-13 di `docs/uji/AUDIT_RIWAYAT.md:150–151`.
- **Klaim yang dilanggar:** run tanpa kunci harus gagal **karena bug tereproduksi**, sehingga kalibrasi membuktikan pagar peka.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R3` dengan heredoc pembaca R0 di §3.3. R0+R3 menjalankan AST `main()` asli dengan kontrol True dan hasil mutasi False. Tiga alasan berbeda—koneksi hilang, utas menggantung/deadlock, waktu 0,99 detik—semuanya mencetak kalibrasi OK/peka dan `HASIL: LOLOS`, return 0.
- **Skenario gagal:** kontrol utuh sukses, tetapi DB mutasi kehilangan koneksi atau tidak memenuhi timing sebelum membuktikan tabrakan/cap tersimpan. CI masih dapat menerima kalibrasi itu. Tidak membuktikan laporan historis tentang 60 ribu/dua nomor salah, sebab saya tidak mendapat log lengkapnya.
- **Dugaan penyebab:** keputusan `kalibrasi = not lulus` membuang perbedaan pelanggaran invariant dan kerusakan/ketidakpastian harness.
- **Cara membuktikan perbaikan:** hanya tabrakan nomor atau pelanggaran cap yang dibuktikan dengan hasil tersimpan boleh dihitung sebagai kalibrasi; fault injection R3 harus membuat exit bukan nol. Jalankan dua koneksi nyata dengan kontrol pulih, SQLSTATE, timeout dan stored effects yang tegas.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada logika main dengan stub terisolasi; bukan galat koneksi/deadlock nyata. `uji-konkuren-0022.py` sudah memeriksa SQLSTATE/efek lebih ketat; saya tidak menyamakan kedua harness.

### [F-03] Mutasi progres 0022 merusak dua pagar sehingga tidak mengisolasi skip AFTER

- **Tingkat:** K-3 — sebab kegagalan mutasi tidak diagnostik terhadap klaim tarif.
- **Artefak:** `alat/uji-mutasi-0022.py:30`; `supabase/migrations/0022_beku_setelah_bayar.sql:35–41,106–113`; `supabase/tes/beku_setelah_bayar.sql` kasus progres.
- **Klaim yang dilanggar:** mutasi bernama “progres masak menghitung ulang tarif baru” membuktikan kepekaan terhadap penghitungan ulang AFTER.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R2` dengan heredoc pembaca R0 di §3.3. R0+R2 mengevaluasi assignment mutasi asli dan membandingkan teksnya. Hasil tepat **dua perubahan**, pada baris 36 dan 108: kondisi masing-masing ditambah `and false`.
- **Skenario gagal:** untuk item yang sudah dibayar, pengecualian progres di BEFORE menjadi mustahil; kegagalan dapat terjadi sebelum AFTER yang ingin diuji. Mutant gabungan merah tidak membuktikan mutant **AFTER-saja** akan tertangkap dengan alasan tarif/header yang dimaksud.
- **Dugaan penyebab:** `str.replace` global terhadap fragmen yang sengaja identik di dua fungsi, tanpa pembatas lokasi/jumlah perubahan.
- **Cara membuktikan perbaikan:** mutasikan hanya `picu_item_hitung_total`, kontrol bahwa tepat satu lokasi berubah; jalankan kasus tarif lama vs tarif baru, sebelum dan sesudah pembayaran, sambil membuktikan progres melewati BEFORE. Mutasi BEFORE terpisah boleh tetap ada.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** untuk cacat isolasi mutasi melalui AST/sumber; tidak mengaku mengamati urutan error SQL lokal atau baseline salah menghitung uang.

### [F-04] Penjaga CI melewatkan ekspresi continue-on-error dan shell yang tidak menjalankan tes

- **Tingkat:** K-3 — penjaga regresi konfigurasi tidak lengkap; workflow target tidak berisi mutant ini.
- **Artefak:** `alat/periksa-gerbang-ci.py:203–214,251–357`; `.github/workflows/ci.yml` langkah keamanan SQL.
- **Klaim yang dilanggar:** semua gerbang wajib ada **tanpa pelemahan**, tidak cukup baris perintahnya hadir.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R4` dengan heredoc pembaca R0 di §3.3. R0+R4 memakai ketiga workflow target. Baseline exit 0; `if: false` dan literal `continue-on-error: true` exit 1. Step dengan `continue-on-error: ${{ true }}` atau `shell: cat {0}` menghasilkan exit 0/`[]`. Penyisipan setelah baris nama step lengkap menjaga bentuk YAML, bukan potongan YAML rusak.
- **Skenario gagal:** perintah keamanan masih tertulis sehingga scanner puas, tetapi error diabaikan atau isi skrip hanya dicetak. GitHub mendukung expression pada continue-on-error serta template custom shell `{0}`; custom command menggantikan shell pengeksekusi. [1](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- **Dugaan penyebab:** regex hanya menangkap literal `true`; daftar teks perintah tidak memvalidasi executable shell per step.
- **Cara membuktikan perbaikan:** kedua mutant R4 harus ditolak; kontrol workflow utuh tetap diterima. Uji job dan step, expression, inherited shell dan custom shell. Jangan menghapus kontrol positif literal yang sekarang bekerja.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada penjaga asli. Tidak mengubah workflow atau memicu workflow GitHub untuk menjalankan serangan.

### [F-05] Klaim pemeriksaan lokal sama dengan CI tidak sesuai daftar pemanggilannya

- **Tingkat:** K-3 — perbedaan bukti/gerbang, bukan klaim perintah shell lokal sudah sukses.
- **Artefak:** `aplikasi/alat/periksa-semua.sh:2,15–25` dan sisa skrip; `.github/workflows/ci.yml`.
- **Klaim yang dilanggar:** komentar pembuka “Jalankan SEMUA pemeriksaan yang sama dengan CI” dan pemakaian hasil lokal sebagai padanan CI.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R4` dengan heredoc pembaca R0 di §3.3. R0+R4 menggunakan `perintah_ci()` asli lalu membandingkan seluruh teks skrip. Delapan **string perintah persis** CI tidak terdapat di skrip: `npm run cek:supabase`; `python3 alat/periksa-maraton.py`; `python3 alat/lanjut-sesi.py --di-ci`; `python3 alat/mulai-sesi.py --uji-diri`; `python3 alat/periksa-migrasi-beku.py`; `python3 alat/periksa-migrasi-beku.py --uji-diri`; `node aplikasi/alat/catat-alamat.mjs --uji-diri`; `python3 aplikasi/alat/periksa-komponen-env.py --uji-diri`.
- **Skenario gagal:** regresi yang hanya ditahan pemeriksa migrasi beku atau guard maraton tidak mendapat pemanggilan guard tersebut di skrip lokal, walau langkah lain hijau. **Bantah-balik daftar tekstual:** `lanjut-sesi.py` justru dipanggil tanpa `--di-ci` pada baris 80 (mode penuh meliputi pemeriksaan isi), sehingga ini **bukan** gap. `cek:supabase` memang didokumentasikan CI-only karena batas jaringan agent (ROADMAP T0-08), sehingga tidak dihitung sebagai kehilangan kontrol lokal wajib. Enam pemanggilan sisanya tetap tidak terdaftar, khususnya baseline dan self-test pemeriksa migrasi beku. Tidak menuduh semua delapan perbedaan literal sebagai cacat yang sama.
- **Dugaan penyebab:** daftar lokal/CI dirawat terpisah; penjaga CI tidak menyilang daftar lokal.
- **Cara membuktikan perbaikan:** inventaris bersama atau perbedaan eksplisit yang terdokumentasi dan dijaga; mutasi gerbang lokal/CI harus memerahkan pemeriksa kesetaraan. Jalankan ulang skrip di lingkungan yang sudah punya dependensi tanpa memaksa pemasangan dalam audit ini.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** secara inventaris sumber/pemanggilan; tidak menjalankan periksa-semua (ia memasang pustaka).

### [F-06] Penjaga PIN meloloskan log kebocoran; suite Edge tidak mengamati log

- **Tingkat:** K-3 — kontrol regresi PIN kurang; bukan kebocoran PIN pada baseline.
- **Artefak:** `alat/periksa-fungsi-pin.py:55–56,97–115,184–198`; `supabase/functions/verifikasi_pin/index.ts`; `alat/uji-edge-pin.mjs:366–373` dan konteks VM.
- **Klaim yang dilanggar:** KEAMANAN §6.3 menyebut PIN tidak masuk log dijaga pemeriksa statis; hasil pemeriksa menyatakan tidak ada pemakaian PIN di balasan/pesan/log/penyimpanan.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R5` dengan heredoc pembaca R0 di §3.3. R0+R5: baseline dan lima mutant, masing-masing 14/14. N1: handler log-mutant memanggil console dengan body berisi PIN dummy (`loggedPIN=true`), baseline false. Suite asli, dengan esbuild **hanya diganti native penghapus tipe**, memperoleh utuh 19/19, response-mutant 18/19 (E11 menangkap 4 body bocor), log-mutant 19/19.
- **Skenario gagal:** debug logging tubuh permintaan dengan akses computed global lolos dua lapis yang diperiksa, meskipun PIN dan kunci perangkat masuk log. Mutant balasan inline memang lolos checker statis tetapi **bukan** bukti seluruh suite lolos, karena E11 menyediakan kontrol balasan yang efektif pada probe ini.
- **Dugaan penyebab:** whitelist baris pembacaan `{ pin`/body-read terlalu lebar; pemakaian body/alias tidak dianalisis; regex nama `console` dapat dipisah menjadi ekspresi; VM test hanya memeriksa response, bukan sink keluaran.
- **Cara membuktikan perbaikan:** spy console/stdout/stderr dalam harness, periksa seluruh permintaan/galat/jalur balasan dengan PIN sentinel; tambah mutant body/alias/computed property. Jalankan lagi **runner esbuild asli** ketika tersedia; tetap buktikan baseline tidak memicu detektor.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada pemeriksa, handler dan harness yang diadaptasi tanpa jaringan. Bukan eksekusi CI lengkap, bukan kebocoran dari handler target yang tidak dimutasi. Di luar diff utama Batch-5; dicatat lagi §8.

### [F-07] Pemindai rahasia tidak mengenali format secret key Supabase

- **Tingkat:** K-3 — cakupan detektor kurang, tidak ditemukan kunci nyata.
- **Artefak:** `alat/periksa-rahasia.py:30–37,78–104`; jalur CI dan periksa-semua yang memanggilnya.
- **Klaim yang dilanggar:** LOLOS pemindai dipakai sebagai bukti tidak ada kunci rahasia pada berkas terlacak.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R6` dengan heredoc pembaca R0 di §3.3. R0+R6 memakai tiga file target dalam filesystem virtual. Kontrol utuh exit 0; JWT dummy ditolak exit 1; dokumen yang ditambah `'sb_secret_' + 'A'*40` tetap exit 0. Baseline scan seluruh target juga exit 0, tetapi tidak menutup false negative ini.
- **Skenario gagal:** kunci layanan format baru tertempel pada dokumen/kode bernama biasa, bukan file .env; semua enam regex tidak mengenalinya. Dokumentasi [API keys Supabase](https://supabase.com/docs/guides/getting-started/api-keys) membedakan `sb_secret_...` dari JWT/service_role lama dan menyatakan secret key berhak tinggi/bypass RLS.
- **Dugaan penyebab:** daftar pola mencakup JWT dan personal access token `sbp_`, bukan format secret key aplikasi `sb_secret_`.
- **Cara membuktikan perbaikan:** fixture dummy sesuai format secret yang didukung penyedia harus ditolak tanpa akses jaringan/kredensial nyata; publishable key yang memang publik harus tetap diterima. Tambahkan self-test agar whitelist tidak terlalu luas.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada pola/eksekusi pemindai. Tidak melakukan autentikasi dengan token dummy dan tidak menyimpulkan ada kunci produksi bocor. Di luar diff Batch-5.

### [F-08] “CI target hijau” dapat berasal dari workflow bukan CI

- **Tingkat:** K-3 — salah atribusi bukti proses.
- **Artefak:** `alat/ci_target.py:58–78,86–90`; caller `alat/review-pr.py:277–292`; `alat/periksa-paket.py:434–446`.
- **Klaim yang dilanggar:** paket hanya menargetkan commit yang lolos **gerbang CI** atau diberi pengecualian pemilik.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R7` dengan heredoc pembaca R0 di §3.3. R0+R7 memanggil fungsi asli dengan respons API tiruan: `ci.yml=failure`, `sebar-halaman.yml=success` pada SHA yang sama → `hijau=True`, run 2; `baris_paket` menulis success. Fixture CI failure saja memberi `hijau=False`.
- **Skenario gagal:** deploy/dokumentasi workflow sukses menutupi workflow pemeriksaan yang gagal; caller paket melanjutkan tanpa meminta pengecualian non-hijau. **Run audit target yang nyata tidak mengalami kasus ini**: C3 memverifikasi workflow pemeriksaannya sukses.
- **Dugaan penyebab:** endpoint semua workflow run disaring hanya berdasarkan SHA dan `conclusion == success`, bukan workflow_id/path/nama pemeriksaan wajib.
- **Cara membuktikan perbaikan:** filter identitas workflow wajib; fixture campuran R7 harus non-hijau, CI success yang benar tetap hijau; offline tetap tidak dianggap hijau.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** dengan injeksi respons API, bukan mengubah run GitHub. Di luar diff Batch-5.

### [F-09] Pemeriksa paket mempercayai SHA pada baris CI yang berbeda dari target

- **Tingkat:** K-3 — integritas provenance paket tidak lengkap.
- **Artefak:** `alat/periksa-paket.py:427–438`; `sha_diklaim` dan `ci_target.status_ci` sebagai pemakai.
- **Klaim yang dilanggar:** bukti CI yang divalidasi adalah CI **commit target paket**, bukan commit lain.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R7` dengan heredoc pembaca R0 di §3.3. bagian kedua R0+R7 mengisolasi aturan 5. Fixture target A gagal; bila baris CI menyebut A, masalah dilaporkan. Bila hanya SHA pada baris CI diganti B yang sukses, masalah menjadi `[]` dan SHA yang diperiksa B. Pemeriksaan history/keberadaan objek ditahan konstan; ini bukan paket nyata yang diam-diam diubah.
- **Skenario gagal:** menyalin baris CI hijau dari paket lain dapat mengesahkan bukti yang tidak terkait target, walaupun target/title/history paket sendiri sah.
- **Dugaan penyebab:** `sha_dicek = m_sha_baris.group(1) if m_sha_baris else sha` tidak disertai kewajiban `sha_dicek == sha`.
- **Cara membuktikan perbaikan:** tolak perbedaan SHA sebelum menghubungi GitHub; kontrol paket dengan satu target/CI SHA tetap lolos. Tambahkan kasus huruf/format dan full SHA, tanpa mengubah target hanya demi memuaskan checker.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** pada aturan asli dengan fixture terisolasi. Tidak menuduh paket AUD-2 yang diberikan memakai SHA berbeda. Di luar diff utama Batch-5.

### [F-10] Status penutup tidak konsisten di dokumen keamanan/ledger aktif

- **Tingkat:** K-3 — dokumen/status basi, bukan regresi perangkat yang sudah dibuktikan hidup.
- **Artefak:** `docs/KEAMANAN.md:40,99`; `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md:18,21`; `docs/uji/BERKAS_PENSIUN.md:16`; `docs/uji/AUDIT_RIWAYAT.md:119,150–151,182,196`.
- **Klaim yang dilanggar:** sumber status aktif menunjukkan pemilik/penutup yang sama; sisa bukan pekerjaan yang sudah tercatat selesai di sumber kanonik.
- **Bukti:** Perintah `PYTHONDONTWRITEBYTECODE=1 python3 - "$LAPORAN" R8` dengan heredoc pembaca R0 di §3.3. R0+R8 dan C2. K F-03/B F-11 tercatat DITUTUP 2026-09-21 dengan 0018+tes perangkat; L-06 masih DITUNDA dan KEAMANAN masih menyebut nama perangkat kiriman klien. L-03 masih “sisa memindahkan katalog, menunggu keputusan Lee”, sedangkan daftar pensiun mencatat keputusan Lee dan perpindahan pada 2026-09-20. D F-08 menyebut F F-13 masih terbuka meskipun baris F F-13 sendiri ditutup. RB pemeriksa temuan/rujukan tetap LOLOS karena ia memeriksa status yang dikenal/rujukan hidup, bukan kesetaraan semantik ini.
- **Skenario gagal:** penerus mengulang permintaan keputusan yang sudah diputuskan atau salah membaca risiko perangkat yang masih terbuka. Ini tidak membenarkan penutupan **seluruh T1-24**: sisa sesi/UI/kode pendaftaran memang masih terbuka.
- **Dugaan penyebab:** status duplikat tidak diperbarui saat penutup kanonik berubah; parser status/rujukan tidak memetakan duplikat.
- **Cara membuktikan perbaikan:** bedakan catatan historis dari status sekarang, tautkan duplikat ke penutup kanonik; R8 harus menunjukkan status/batas implementasi yang konsisten. Jangan menghapus riwayat atau membuka katalog kalibrasi untuk memperbaiki teks.
- **Status verifikasi:** TERVERIFIKASI
- **Batas verifikasi:** sebagai ketidaksesuaian dokumen target. Bagian lama PROJECT_STATE/SIAP-LANJUT yang sudah diberi label sejarah **tidak** dihitung sebagai temuan ini. Di luar perubahan utama Batch-5.

## 5. Kalibrasi cacat tanaman

**Tidak berlaku: ini AUD-2, bukan AUD-3.** Tidak mencari/membuka katalog atau kunci jawaban kalibrasi di dalam/luar repo, tidak membuat bahan kalibrasi dan tidak menulis skor “ditemukan X dari Y”. Probe R1–R7 adalah uji adversarial terhadap alat yang dipakai proyek, bukan pembacaan jawaban cacat tanaman.

## 6. Yang tidak bisa saya verifikasi

- **Runtime uang dan katalog:** tidak ada run SQL lokal yang selesai. Tidak mengonfirmasi 65 lulus, 53 definer efektif, efek REVOKE pada operasi normal, crypto bcrypt nyata, atau keluaran transaksi aktual. Kegagalan lingkungan tidak dihitung sebagai cacat produk. Semua pengujian lanjutan harus di database sementara, **bukan produksi**.
- **READ COMMITTED dua arah dan rollback:** harness baru menggunakan blocking evidence dan memeriksa SQLSTATE/efek, tetapi belum dijalankan auditor. Snapshot ketika menunggu lock, rollback pembayar, transaksi multi-row/multi-parent, pindah parent bersamaan, tenant/cabang negatif dan timeout tetap perlu dibuktikan. Dokumentasi [PostgreSQL 16 READ COMMITTED](https://www.postgresql.org/docs/16/transaction-iso.html#XACT-READ-COMMITTED) menjelaskan snapshot tiap statement serta wait/commit/rollback; ini alasan menyusun probe, bukan pengganti hasil proyek.
- **Suite aplikasi/CI lengkap:** npm test/typecheck/lint/periksa-semua belum diulang. Metadata CI success tidak menyediakan isi log yang gagal diunduh. N1 memakai native type stripping eksperimental Node, bukan esbuild terpasang; penerjemahan tipe dan VM dinyatakan secara terbuka.
- **Supabase/Cloudflare produksi/deploy:** tidak disentuh, tidak mengambil secrets, tidak menjalankan SQL/provider check dengan kredensial. Tidak mengesahkan 0017–0023 sudah deployed. Dokumen terbaru mengakui deploy/AUD-2 masih terbuka.
- **Sisa T1-30:** scanner efektif bukan AST umum; initplan/helper policy dan angka minimal 38/55 policy berasal dari dokumen pembangun, belum saya ukur ulang lewat katalog/parser. Tidak ada dasar mencentang T1-30 dari bagian ACL saja.
- **Independensi model:** hanya independensi sesi/branch yang dapat dibuktikan, bukan model berbeda.
- **Kalibrasi formal:** tidak dilakukan dan tidak diperlukan untuk tingkat ini. Pemeriksa pengaman kalibrasi dibaca sebagai kode, tidak dijalankan untuk mencari bahan luar.

### Dugaan yang wajib ditindaklanjuti, belum menjadi temuan terverifikasi

Tidak mengubah tingkat/verdict berdasarkan hipotesis di bawah. Setiap calon ditelusuri terhadap sumber target dan caller; hasil database **belum tersedia**.

| ID | Status / hipotesis | Bukti sumber dan perintah yang sudah dijalankan | Pembuktian berikutnya / kontrol penyangkal |
|---|---|---|---|
| D-01 | **DUGAAN:** penghapusan/pemindahan pembayaran oleh service_role dapat menghilangkan penanda beku. Dampak potensial uang/jejak, bukan serangan authenticated biasa. | `git show TARGET:supabase/migrations/0010_pembayaran.sql` baris 552–553 memberi UPDATE/DELETE pembayaran ke service_role; pencarian semua migrasi tidak menemukan penjaga DELETE pembayaran. 0022:32/73 hanya mengecek pembayaran yang **masih ada**. KEAMANAN §9.1 menyebut pembayaran tak boleh diubah/dihapus. Tes pembayaran:109–110 hanya mencoba sebagai authenticated. | Pada DB sementara, bayar Rp1 dengan service_role/null-auth, coba DELETE/UPDATE parent pembayaran, lalu ubah qty dan periksa total/jejak. Kontrol tanpa DELETE harus BY-201. Pastikan FK/trigger/privilege efektif benar-benar mengizinkan rangkaian sebelum menaikkan ke temuan uang. Perjelas apakah janji “peladen tunduk” mencakup jalur ini. |
| D-02 | **DUGAAN:** urutan parent per-row bukan urutan global semua lock; update item versus void atau multi-row antar parent mungkin deadlock. Tidak menyimpulkan korupsi uang. | C2 0022:25–31; 0015:159–188 (void mengubah item); `git grep -n ... TARGET -- supabase/migrations`. New harness hanya lima kasus satu parent dan pembayar commit. | Dua koneksi sementara: A menahan item, B void menahan parent lalu menunggu item, A meminta parent; ukur `pg_blocking_pids`, SQLSTATE, rollback/retry dan hasil akhir. Ulangi multi-row parent dengan urutan berlawanan, bukan sekadar UUID OLD/NEW satu baris. |
| D-03 | **DUGAAN, di luar perubahan utama:** pindah parent **diskon pra-bayar** oleh peladen dapat meninggalkan total parent lama. Parent item tidak boleh disamakan. | C2 0014:146–161 memanggil hitung_total hanya `coalesce(new.pesanan_id, old.pesanan_id)`; 0010:552–553 memberi UPDATE diskon pada service_role; 0022 memeriksa kedua parent tanpa menghitung ulang keduanya. Telusur `salinan_beku` membuktikan item memiliki guard lama 0009 yang masih terpasang—dugaan perpindahan item tidak saya angkat menjadi bug. | Pindahkan diskon antara dua pesanan belum bayar dengan service_role di DB sementara; pastikan semua guard efektif dan bandingkan total kedua parent dengan rincian. Kontrol authenticated UPDATE harus tetap ditolak, dan salah satu parent berbayar harus BY-201. |

Contoh payload untuk **D-01 — BELUM DIJALANKAN**, setelah skema/data-uji target dimuat di database sementara:

```sql
begin;
select uji.klaim(null);
set local role service_role;
insert into public.pembayaran
  (pesanan_id, kasir_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010',
       '90000000-0000-0000-0000-000000000004', m.id, 1, 1, 'aud2-delete-payment'
from public.metode_bayar m
where m.penyewa_id='11111111-1111-1111-1111-111111111111' and m.nama='Tunai';
-- Kontrol terpisah: perubahan qty SEBELUM delete harus BY-201.
delete from public.pembayaran where kunci_idempoten='aud2-delete-payment';
update public.pesanan_item set qty=qty+1
where pesanan_id='eeee0000-0000-0000-0000-000000000010';
select total, (select count(*) from public.pembayaran pb where pb.pesanan_id=p.id)
from public.pesanan p where id='eeee0000-0000-0000-0000-000000000010';
rollback;
```

Dokumentasi [PostgreSQL row locks/deadlocks](https://www.postgresql.org/docs/16/explicit-locking.html#LOCKING-DEADLOCKS) menekankan urutan lock yang konsisten **untuk semua objek**, dan bahwa deadlock membatalkan salah satu transaksi. Tidak memakai dokumentasi itu untuk mengklaim D-02 sudah tereproduksi. [CREATE TRIGGER](https://www.postgresql.org/docs/16/sql-createtrigger.html) menjelaskan kebutuhan TRIGGER/EXECUTE pada pembuatan trigger dan urutan pemicuan; ini mendukung pembacaan desain, bukan pengganti uji regresi setelah 0023.

## 7. Pernyataan tidak mengubah apa pun

Saya tidak mengubah apa pun selain berkas laporan audit ini.

**Tidak ada kode, migrasi, fixture, konfigurasi, status proyek, ledger, paket, pustaka, atau data produksi yang saya ubah. Satu-satunya berkas yang dibuat/diubah adalah laporan ini:**

`docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md`

Tidak ada file probe/salinan sementara, instalasi npm/pip, server baru, atau kalibrasi formal. Perubahan memori tidak ditulis kembali. Fetch, commit dan push laporan menggunakan metadata Git sebagaimana diminta; bukan perubahan sumber aplikasi.

Status sebelum penulisan laporan diperiksa dengan `git status --porcelain=v1` dan kosong. Sesudah laporan dibuat, `git status --porcelain=v1 --untracked-files=all` menghasilkan hanya `?? docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md`; `git diff --name-only` kosong (tidak ada perubahan pada berkas terlacak sebelumnya). Cabang tetap sesuai. Sebelum commit akan diperiksa ulang bahwa daftar staged hanya laporan dan `git symbolic-ref --short HEAD` menghasilkan **`arena/01a0c39d-resto-barokah`**. Setelah commit, keluaran status dan SHA pengiriman dicantumkan dalam jawaban pengiriman, bukan mengaku push sudah berhasil sebelum perintah dijalankan.

**Validasi format — hasil aktual, bukan klaim lulus:** program asli target **sudah dijalankan SATU KALI** dengan argumen `--periksa-laporan` melalui R0, exit **1**, `HASIL: DITOLAK (100 alasan)`. Kelompok diagnostiknya: label `Commit yang diaudit`/SHA dan nilai Verdict; sel bukti cakupan memakai alias C2/RB tanpa perintah literal; nilai status verifikasi diberi markup/penjelasan; bagian batas memakai daftar bernomor; pernyataan baca-saja perlu frasa literal; status Git default merangkum laporan untracked sebagai `docs/uji/`.

Format kemudian dilengkapi dari diagnostik tersebut: label/nilai literal, perintah Git konkret pada setiap baris cakupan, lensa dipisah dari tabel artefak, status dipisah dari batas pembuktian, butir batas dan pernyataan baca-saja eksplisit. Jumlah/tingkat/verdict temuan **tidak** diubah untuk memuaskan mesin. Header §8 diperjelas agar tidak menyebut pilihan tabel kosong padahal ada temuan. **Tidak mengulang validator**, sesuai instruksi satu kali; versi setelah kelengkapan format **belum dinyatakan LOLOS mesin**. Kode penilaian tidak dibaca. `git status --porcelain=v1 --untracked-files=all` membuktikan entri direktori yang dianggap kotor itu hanya laporan, bukan perubahan aplikasi.

Angka yang dicetak validator pada draf ialah artefak 86, klaim 13, serangan 41, temuan 10, luar cakupan 0. Angka parser itu tidak saya adopsi sebagai klaim audit: tabel auditor berisi 81 entri cakupan (termasuk grup), 17 kill attempts, serta enam entri lintas fokus (lima temuan terverifikasi dan satu dugaan). Ada beberapa tabel lain dalam bagian yang sama pada draf; pembaca harus memakai daftar/bukti aktual, bukan angka parser. Penolakan format ini **tidak** membuktikan atau membantah cacat uang, dan menjadi alasan tambahan untuk tidak memperlakukan laporan sebagai gerbang penutupan yang sudah sah.

Perintah pengiriman yang diminta, sesudah validasi dan pemeriksaan diff:

```bash
git symbolic-ref --short HEAD
git add -- docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md
git diff --cached --name-only
git diff --cached --check
git commit -m "docs(audit): laporan AUD-2 Batch-5 2026-09-21"
git symbolic-ref --short HEAD
git push origin HEAD:refs/heads/arena/01a0c39d-resto-barokah
git status --porcelain=v1
git ls-remote origin refs/heads/arena/01a0c39d-resto-barokah
```

**Riwayat pengiriman pertama — saat itu belum ter-push.** Laporan pertama sudah di-commit lokal sebagai `b8290b3d125df3971dcaab974c96586c11f0976a` (satu file, 994 baris penambahan). Perintah push eksplisit di atas dicoba dan ditolak: `[rejected] ... (fetch first)` / non-fast-forward. Ini **bukan galat autentikasi**. `git ls-remote origin refs/heads/arena/01a0c39d-resto-barokah` kemudian menunjukkan remote berada pada `5529eae99fbd6f369b41ef599919418a3719adee`, berbeda dari HEAD lokal tersebut.

Pada penyerahan pertama, tidak dilakukan force-push atau merge/rebase; penolakan dicatat dalam commit lokal `7ad811211d1ff1b4cf0f0a4ca4c1da8b84e07f06`. **Tindak lanjut atas permintaan pemilik agar hasil tersedia di GitHub:** riwayat remote `5529eae99fbd6f369b41ef599919418a3719adee` digabung pada cabang sesi yang sama. Konflik hanya pada berkas laporan ini; versi remote disimpan utuh di lampiran arsip. Tidak mengubah kode/migrasi/konfigurasi atau menulis ulang riwayat. Tidak meminta kata sandi/token/kode autentikasi pemilik.

**Status pengiriman susulan: SUDAH TER-PUSH ke GitHub.** Push normal commit merge `b68490ed7cdbe52175e546c2df0bd0454418bb13` berhasil ke `arena/01a0c39d-resto-barokah` (tanpa force-push). `git ls-remote` mengonfirmasi SHA cabang sama; GitHub Contents API berhasil membaca laporan 137.685 byte pada commit tersebut dan blob `a3d4b70553da6cd215ceac355fa2b271a149cd7f` cocok dengan berkas lokal. [Laporan yang telah diverifikasi di GitHub](https://github.com/With-AI-Agent/Resto-Barokah/blob/b68490ed7cdbe52175e546c2df0bd0454418bb13/docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md). Catatan status ini ditambahkan sesudah bukti pengiriman tersebut; SHA penutup terbaru disampaikan di chat. Hanya berkas laporan berubah, dan versi remote asal tetap tersimpan utuh. Validator audit tidak dijalankan ulang dalam tindak lanjut pengiriman ini.

## 8. Temuan di luar cakupan (WAJIB)

“Di luar” di tabel ini berarti di luar **diff/fokus utama Batch-5**, bukan alasan mengabaikan artefak pendukung yang memang tercantum dalam paket. Semua temuan terverifikasi tetap dijelaskan lengkap di §4. Tidak menyunting daftar penutup/ledger karena hanya laporan yang boleh diubah.

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | F-06, K-3 TERVERIFIKASI — PIN log-mutant lolos checker dan harness teradaptasi | Edge dan penjaganya bukan perubahan Batch-5 | R5/N1; §4 | Pemilik T1-30/T1-45 tambahkan sink log, jalankan esbuild asli dan mutant yang sama; baseline tetap bersih |
| 2 | F-07, K-3 TERVERIFIKASI — secret-key format tidak dikenali | Pemindai rahasia lama tidak disentuh diff | R6; dokumentasi Supabase | Uji dummy format penyedia dan whitelist publishable; jangan memakai token nyata |
| 3 | F-08, K-3 TERVERIFIKASI — workflow lain mengesahkan CI target | Mekanisme paket/provenance lama | R7, ci_target/review-pr | Identitas workflow wajib diikat; fixture CI gagal/deploy sukses wajib ditolak |
| 4 | F-09, K-3 TERVERIFIKASI — beda SHA baris CI diterima | Aturan paket lama, bukan paket target yang diberikan | R7, periksa-paket aturan 5 | Kesamaan full SHA wajib; kasus paket sah tetap diterima |
| 5 | F-10, K-3 TERVERIFIKASI — status perangkat/katalog/duplikat basi | Di luar sapuan penanda ❓ ROADMAP; tidak menuduh sejarah berlabel sebagai status kini | R8; ledger/KEAMANAN/pensiun | Rekonsiliasi status kanonik tanpa menghapus sejarah/katalog jawaban; tutup hanya cakupan implementasi yang benar |
| 6 | D-03, **DUGAAN** — total parent lama pada perpindahan diskon pra-bayar | AFTER diskon lama, bukan perubahan aturan berbayar | C2 0014:146–161; §6 | Reproduksi DB sementara dan kontrol izin/guard efektif sebelum menentukan tingkat/verdict |

**Calon yang ditarik setelah bantah-balik:** petunjuk token pada `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` memuat teks scope/TTL yang berbeda antara paragraf dan langkah. Namun baris 11 menyebut bagian bawah disimpan sebagai riwayat, langkah B berlabel SUDAH SELESAI, dan `docs/ops/SIAP_AKUN_PEMILIK.md:52` menegaskan bukan daftar tugas aktif. Perintah `git grep -n LANGKAH_PEMILIK_SEKARANG TARGET -- PANDUAN_PENGGUNA.md docs/ops docs/PANDUAN_PEMILIK.md docs/ROADMAP.md docs/KEAMANAN.md` menelusuri caller. Tidak ada bukti instruksi itu dipakai untuk penerbitan token baru sekarang; **tidak dihitung sebagai temuan aktif/risiko token aktual**. Tidak perlu membuka token untuk menyimpulkan batas ini.

**Urutan tindak lanjut:** perbaiki keandalan pembuktian F-01/F-02/F-03 lebih dahulu; ulangi SQL dan concurrency target termasuk D-01/rollback/multi-row; evaluasi F-04/F-05 dan temuan lintas fokus. Jangan menggunakan keluaran penjaga yang saya patahkan sebagai satu-satunya alasan menutup temuan. Tidak ada implementasi perbaikan yang dilakukan dalam audit ini.

---

### Lampiran arsip — versi laporan yang sebelumnya berada di GitHub

- **Sumber:** commit `5529eae99fbd6f369b41ef599919418a3719adee`, berkas yang sama; [tautan versi asal](https://github.com/With-AI-Agent/Resto-Barokah/blob/5529eae99fbd6f369b41ef599919418a3719adee/docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md).
- **SHA-256 isi asal UTF-8:** `25d7abe4d467ded1ee9295bcbd9ad1a2f8c8e8025ceb1e736b01f9a58bef1f0c`.
- **Kedudukan:** arsip apa adanya untuk mempertahankan pekerjaan remote saat konflik add/add. Nomor F-xx, tingkat, verdict dan klaim perintah pada arsip adalah milik **versi asal**, bukan tambahan temuan yang telah saya verifikasi pada isi utama. Perbedaan hasil kedua versi belum diselesaikan secara substantif.
- **Batas kepercayaan:** klaim versi asal tentang pemasangan pustaka, salinan `/tmp`, pengujian SQL, dan hasil runtime bukan kegiatan yang dilakukan atau dibuktikan ulang pada audit lokal di atas. Pembaca perlu meminta bukti yang dapat direproduksi sebelum menerima atau menolak klaim tersebut.

<details>
<summary>Buka salinan lengkap versi remote 5529eae (232 baris; verdict TIDAK-BERSIH)</summary>

````markdown
# LAPORAN AUDIT INDEPENDEN — AUD-2 — 2026-09-21

- **Auditor:** sesi Arena `arena/01a0c39d-resto-barokah` (model berbeda dari sesi kerja `arena/01a0c2c1-resto-barokah`; identitas model tidak diungkapkan platform — dicatat sebagai keterbatasan di bagian 6)
- **Tanggal:** 2026-09-21
- **Tingkat audit:** AUD-2
- **Commit yang diaudit:** `09bcb89fc139b3be32ab874e7a004f0a3b0480ee` — `git rev-parse HEAD` di ruang kerja auditor mencetak SHA ini setelah `git fetch origin arena/01a0c2c1-resto-barokah` + `git checkout --detach 09bcb89…`
- **Paket audit:** `docs/uji/paket-audit/AUD-2-2026-09-21.md` (TIDAK ada di pohon commit yang diaudit — sesuai catatan paket, berkas paket di-commit sesudah commit target; sumber saya adalah isi paket yang ditempel pemilik)
- **Mode cakupan:** terarah
- **Alasan commit berbeda:** cabang sesi auditor `arena/01a0c39d-resto-barokah` bercabang dari `main` (`253d1297a3b81433d7f5809afd257d8a1b40958f`) yang hanya memuat kerangka; paket menargetkan `09bcb89f…`. Saya `git fetch origin arena/01a0c2c1-resto-barokah` lalu `git checkout --detach 09bcb89fc139b3be32ab874e7a004f0a3b0480ee` **hanya untuk membaca**, dan sudah kembali ke `arena/01a0c39d-resto-barokah` sebelum menyerahkan laporan (protokol §5c butir 2).
- **Verdict:** TIDAK-BERSIH

Alasan verdict: ada 2 temuan **K-2 berstatus TERVERIFIKASI** (F-01, F-02). Protokol §6: "Ada temuan K-1/K-2 berstatus TERVERIFIKASI → verdict wajib TIDAK-BERSIH".

Lensa yang dijalankan: **L1 Ancaman & Akses · L2 Uang & Jejak · L3 Kesepakatan Dokumen · L4 Mutu Uji** (semua lensa wajib paket).

Cara kerja: repo asli di `/home/user/Resto-Barokah` dipakai **hanya-baca** pada commit target. Semua perintah yang memasang pustaka atau mengubah skema dijalankan pada salinan `git archive HEAD` di `/tmp/aud` (di luar repo) + PostgreSQL 16.2 nyata via `pgserver` di `/tmp/venv-aud`, supaya tidak satu pun berkas repo tersentuh. Probe ditulis di `/tmp/probe-aud`.

---

## 1. Cakupan

| # | Artefak | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|
| 1 | `supabase/migrations/0022_beku_setelah_bayar.sql` | YA | `cat -n` 118 baris; dua pemicu BEFORE (`aaa_*` pada item/diskon/pembatalan, `zzz_*` pada pesanan) + `picu_item_hitung_total` di-`create or replace` |
| 2 | `supabase/migrations/0023_acl_fungsi_pemicu.sql` | YA | `cat -n` 53 baris; 20 fungsi trigger di-`revoke … from public, anon, authenticated` + `grant … to service_role` |
| 3 | `supabase/tes/beku_setelah_bayar.sql` | YA | `cat -n` 118 baris; 18 perintah dalam array `T025-peladen` + kontrol sebelum bayar |
| 4 | `supabase/tes/keamanan_fungsi.sql` | YA | `cat -n` 34 baris; 4 asersi katalog (`T130-setup/path/public/trigger`) |
| 5 | `supabase/migrations/0015_penutup_celah_putaran16.sql` | YA | `sed -n '560,700p'` → `picu_pembayaran_jujur` mengunci baris pesanan `for update` (baris 41–45), cek metode aktif, cek `total>0`, cek lebih-bayar |
| 6 | `supabase/migrations/0014_penutup_celah_putaran13.sql` | YA | `sed -n '430,500p'` → `picu_pesanan_jejak_jujur` menolak ubah `kasir_id`/`tanggal`/`nomor` |
| 7 | `supabase/migrations/0017_pesanan_tertutup_beku.sql` | YA | `supabase/migrations/0017_pesanan_tertutup_beku.sql:10` — "Kolom jejak lain (catatan, tipe, shift_id, meja_id, pelayan_id, …) masih bisa [diubah]" |
| 8 | `supabase/migrations/0009_pesanan.sql` | YA | `sed -n '1,60p'` → kolom `pesanan` (subtotal/pajak/service/total_diskon/total/dibayar_pada/shift_id/meja_id/pelayan_id/tipe/catatan) |
| 9 | `supabase/migrations/0010_pembayaran.sql` | YA | `grep -n` → `peran_peladen()` (baris 161–174), `total_dibayar()` (baris 190–200), `picu_pesanan_jaga_uang` (baris 207+), `grant select, insert on pembayaran … to authenticated` (baris 550) |
| 10 | `alat/periksa-keamanan-sql.py` | YA | `python3 alat/periksa-keamanan-sql.py` → "2 LULUS · 0 GAGAL / HASIL: LOLOS"; `--uji-diri` → "9 mutasi … 0 tidak sesuai" |
| 11 | `alat/uji-mutasi-0022.py` | YA | `python3 alat/uji-mutasi-0022.py` → "LOLOS — 9 mutasi, kontrol+penutup, kalibrasi salinan rusak; 0 tidak sesuai" |
| 12 | `alat/uji-konkuren-0022.py` | YA | `python3 alat/uji-konkuren-0022.py` → "LOLOS — 5 kontrol dua arah + 2 mutasi pelanggaran nyata; 0 tidak sesuai" (PostgreSQL 16.2 pgserver, 2 koneksi) |
| 13 | `alat/uji-konkuren.py` | YA | dimuat sebagai loader skema oleh probe auditor; dijalankan pembangun di CI (langkah `uji-konkuren.py` di `.github/workflows/ci.yml`) |
| 14 | `alat/klasifikasi_mutasi.py` | YA | `cat -n` 84 baris; `HIJAU/MERAH-PAGAR/RUSAK`, menolak `ERR_MODULE_NOT_FOUND`/`SyntaxError`/"tidak bisa diterapkan" |
| 15 | `alat/periksa-rahasia.py` | YA | `python3 alat/periksa-rahasia.py` di repo asli → "2367 berkas terlacak … LOLOS" |
| 16 | `alat/periksa-gerbang-ci.py` | YA | `python3 alat/periksa-gerbang-ci.py` → "74 gerbang wajib … LOLOS"; `--uji-diri` → semua mutasi ditolak |
| 17 | `.github/workflows/ci.yml` | YA | `git diff 73bd831..09bcb89` → +3 langkah: `uji-mutasi-0022.py`, `uji-konkuren-0022.py`, `periksa-keamanan-sql.py` + `--uji-diri` |
| 18 | `alat/uji-sql.mjs` | YA | `node alat/uji-sql.mjs` → "uji: 65 LULUS · 0 GAGAL / HASIL: LOLOS"; runner juga dipakai menjalankan probe auditor |
| 19 | `supabase/tes/pembayaran.sql`, `uang_peladen.sql`, `void_satu_item.sql`, `jejak_pelaku.sql` | YA | `git diff 73bd831..09bcb89 -- supabase/tes/…` (4 fixture dipindah ke pesanan belum berbayar + kontrol positif ditambah) |
| 20 | `docs/uji/BUKTI_T025_BEKU_SETELAH_BAYAR.md` | YA | `cat` 70 baris; tabel bukti + 4 gerbang lanjut |
| 21 | `docs/uji/BUKTI_T130_KEAMANAN_SQL.md` | YA | `sed -n '1,90p'` 55 baris; klaim "65/65 hijau", "9 mutasi", "inventaris awal 55 policy / minimal 38" |
| 22 | `docs/uji/AUDIT_RIWAYAT.md` | YA | `grep -n "SQL 64/64"` → baris 84 (baris I F-17) |
| 23 | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` | YA | `cat` 373 baris (aturan main, §5c jalur pulang laporan, §6 kontrak laporan) |
| 24 | `docs/ROADMAP.md` | YA | `grep -n "T1-30\|T1-45"` → baris 473 `- [ ] T1-30 … ⚠️`, baris 622 `- [ ] T1-45 … ⚠️` (keduanya BELUM dicentang) |
| 25 | `docs/PRD.md`, `docs/TECH_SPEC.md` | YA | `git diff 73bd831..09bcb89 -- docs/PRD.md docs/TECH_SPEC.md` (M6/aturan 7 + §2 butir 6 + §4.4/§5 tanpa PIN pelanggan) |
| 26 | `docs/ops/SIAP-LANJUT.md` | YA | `grep -n "CI terakhir\|PERHATIAN"` → baris 17–18 |
| 27 | `alat/periksa-angka-bukti.py` | YA | `python3 alat/periksa-angka-bukti.py` → LOLOS; `sed -n '1,70p'` → `POLA_ANGKA = r"\b\d+\s+(uji|tabel)\b"` |
| 28 | `alat/periksa-roadmap.py`, `alat/periksa-rujukan.py`, `alat/periksa-fungsi-pin.py`, `alat/periksa-kunci-kalibrasi.py`, `alat/periksa-temuan-audit.py`, `alat/periksa-paket.py` | YA | `python3 alat/periksa-roadmap.py` → LOLOS · `python3 alat/periksa-rujukan.py` → LOLOS · `python3 alat/periksa-fungsi-pin.py` → 14 lolos · `python3 alat/periksa-kunci-kalibrasi.py --uji-diri` → LOLOS · `python3 alat/periksa-temuan-audit.py --uji-diri` → LOLOS · `python3 alat/periksa-paket.py --uji-diri` → LEWAT (lihat §6) |
| 29 | `alat/uji-edge-pin.mjs` + `supabase/functions/verifikasi_pin/index.ts` | YA | `node alat/uji-edge-pin.mjs` → "19 lolos, 0 gagal"; `grep -n "Access-Control"` → asal dibatasi daftar, bukan `*` |
| 30 | `aplikasi/` (uji unit/komponen, typecheck, lint) | YA | `npm test` → "Test Files 11 passed · Tests 101 passed"; `npm run typecheck` exit 0; `npm run lint` exit 0 |
| 31 | `aplikasi/alat/periksa-semua.sh` | SEBAGIAN | `git diff` dibaca; komponennya saya jalankan sendiri (mutasi 0015/0022, keamanan-sql, konkuren) — skrip utuh tidak saya jalankan (lihat §6) |
| 32 | Katalog PostgreSQL efektif sesudah 23 migrasi | YA | probe5: 53 fungsi SECURITY DEFINER di public, 0 ber-EXECUTE PUBLIC, 0 tanpa `search_path=public, pg_temp`, 23 di antaranya `returns trigger`, 55 policy, 29 tabel, 0 tabel tanpa RLS |

---

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | "0022 menolak perubahan setelah pembayaran Rp1, termasuk lewat jalur peladen/null-auth; belum ada refund baru" (`docs/uji/BUKTI_T025…`, paket §2 no.1) | Probe perubahan isi/nominal lewat 6 jalur (item/diskon/void/header/parent/tarif) dalam **satu pernyataan** dan **dua pernyataan**; `node alat/uji-sql.mjs /tmp/probe-aud/f01.sql` | **SEBAGIAN TERBANTAHKAN.** Perubahan nominal (qty, harga, diskon, void, total, `status='batal'`, delete) **memang** ditolak BY-201 di semua jalur yang saya coba, termasuk `auth.uid()` null dan pemilik tabel. Tetapi perubahan **jejak non-nominal** (`pesanan.catatan`, `tipe`, `meja_id`, `pelayan_id`, `shift_id`, `pesanan_item.catatan`) **DITERIMA** bila INSERT pembayaran dan UPDATE digabung dalam satu pernyataan (CTE data-modifying) → **F-01**. "Belum ada refund baru" TERBUKTI: tidak ada fungsi/tabel refund di `grep -rn "refund\|pengembalian_dana" supabase/migrations` = 0 |
| 2 | "Parent lama dan tujuan diperiksa dengan kunci sama seperti pembayaran; default READ COMMITTED teruji dua arah" (0022 baris 4–5, 25; paket §2 no.2) | `python3 alat/uji-konkuren-0022.py` (7 kasus); probe sendiri dua-koneksi dengan urutan commit dibalik; probe deadlock dua parent | **KUNCI: TERBUKTI.** `picu_pembayaran_jujur` (0015:41–45) dan 0022 (`perform … for update`) mengunci baris `pesanan` yang sama. Hipotesis saya sendiri — bahwa `exists(select 1 from pembayaran)` memakai snapshot basi READ COMMITTED sehingga bayar→edit lolos — **GAGAL**: 5/5 kontrol dua arah menolak BY-201, termasuk `bayar→catatan/qty/void`. **URUTAN KUNCI: klaim berlebihan** — komentar 0022:25 "Urutan UUID tetap menghindari kunci silang" hanya berlaku untuk dua parent **di dalam satu baris**; deadlock nyata tercapai antar-transaksi (`DeadlockDetected`) → **F-04** |
| 3 | "Progres masak murni tidak menerapkan ulang tarif pajak baru; tidak membuka izin klien/status yang sebelumnya dilarang" (0022 baris 96–98; paket §2 no.3) | probe3-K: bayar Rp1 → `pajak_pb1_persen` 10→20 → `status` `baru→dimasak→siap`, baca ulang subtotal/pajak/service/total; plus mutasi 9 `uji-mutasi-0022.py` | **TERBUKTI.** `sebelum: [(54000, 5400, 2700, 62100)]` → `sesudah: [(54000, 5400, 2700, 62100)] [('siap',)]` — total tidak dihitung ulang. Mutasi "progres masak menghitung ulang tarif baru" → MERAH-PAGAR. Tidak ada izin baru: `update … set status='batal'` tetap ditolak `picu_item_jaga` ("Pembatalan item WAJIB lewat baris pembatalan resmi") |
| 4 | "Empat fixture lama masih membuktikan izin, cap, PIN, atribusi dan void item terakhir sebelum bayar; bukan hanya mengganti pesan yang diharapkan" (paket §2 no.4) | `git diff 73bd831..09bcb89 -- supabase/tes/jejak_pelaku.sql supabase/tes/pembayaran.sql supabase/tes/uang_peladen.sql supabase/tes/void_satu_item.sql`; `node alat/uji-sql.mjs` | **TERBUKTI.** `pembayaran.sql`: pesanan baru `eeee…0023` (belum berbayar) dipakai untuk batas diskon/PIN/void, dan keanggotaan cabang dapur ditambahkan supaya sebab penolakan pasti IZIN; `void_satu_item.sql` menambah pesanan `d1…0003` untuk membuktikan "item terakhir sebelum bayar menutup pesanan"; `uang_peladen.sql` menambah `f002` untuk void-sebelum-bayar. Semua asersi memakai `harap_gagal_sebab` (sebab dipatok). 65/65 hijau |
| 5 | "0023 hanya mempersempit EXECUTE 20 pemicu; operasi trigger lama tetap bekerja; 53 definer public dipindai dari katalog efektif" (paket §2 no.5) | probe5 (katalog sesudah 23 migrasi); `python3 alat/periksa-keamanan-sql.py`; `node alat/uji-sql.mjs` (65/65 = operasi staf lama tetap diuji) | **TERBUKTI untuk definer.** Katalog: **53** fungsi SECURITY DEFINER di `public`, **0** dengan EXECUTE PUBLIC efektif, **0** tanpa `search_path` terkunci, **23** `returns trigger`, 55 policy, 29 tabel semuanya ber-RLS. Trigger lama tetap bekerja (65/65 + `uji-mutasi-0015` 17 kasus hijau). **CATATAN:** ada **11 fungsi trigger non-definer** (`picu_item_jaga`, `picu_pesanan_jaga_uang`, `picu_pesanan_jejak_jujur`, …) yang masih memegang EXECUTE PUBLIC/anon/authenticated dan **di luar jangkauan** asersi `T130-trigger` (yang menyaring `p.prosecdef`) → **F-06** |
| 6 | "65/65 SQL, 101 uji aplikasi, seluruh periksa-semua lokal hijau; CI 35574069120 success. Mutasi 0022 (9), T1-30 (9), concurrency (5+2) bukan merah karena setup rusak" (paket §2 no.6) | `node alat/uji-sql.mjs`; `cd aplikasi && npm test`; `npm run typecheck`; `npm run lint`; `python3 alat/uji-mutasi-0022.py`; `periksa-keamanan-sql.py --uji-diri`; `uji-konkuren-0022.py`; `gh run view 35574069120` | **TERBUKTI (dengan satu catatan).** `uji: 65 LULUS · 0 GAGAL` · `Tests 101 passed (101)` · typecheck exit 0 · lint exit 0 · mutasi 0022 "9 mutasi … 0 tidak sesuai" · keamanan-sql `--uji-diri` "9 mutasi … 0 tidak sesuai" · konkuren-0022 "5 kontrol + 2 mutasi … 0 tidak sesuai" · `gh run view 35574069120` → `{"conclusion":"success","headSha":"09bcb89f…"}`. Klasifikasi `RUSAK` vs `MERAH-PAGAR` nyata (`klasifikasi_mutasi.py` menolak `ERR_MODULE_NOT_FOUND`/`SyntaxError`/"tidak bisa diterapkan", dan kasus "salinan SQL rusak bukan bukti" → `RUSAK`). Catatan: `periksa-semua.sh` utuh tidak saya jalankan; komponennya saya jalankan sendiri (§6) |
| 7 | "PRD/TECH_SPEC tanpa PIN pelanggan tetapi PIN pegawai/persetujuan tetap; T1-30 AST/initplan, AUD-2, dan deploy masih gerbang terbuka, bukan selesai terselubung" (paket §2 no.7) | `git diff 73bd831..09bcb89 -- docs/PRD.md docs/TECH_SPEC.md`; `grep -n "T1-30\|T1-45" docs/ROADMAP.md`; `python3 alat/periksa-fungsi-pin.py`; `node alat/uji-edge-pin.mjs` | **TERBUKTI.** PRD M10/alur 17 dan TECH_SPEC §4.4/§5 menghapus PIN pelanggan; PIN pegawai utuh (14 pemeriksaan `periksa-fungsi-pin.py` LOLOS, 19 pemeriksaan Edge Function LOLOS). `docs/ROADMAP.md:473` `- [ ] T1-30 … ⚠️` dan `:622` `- [ ] T1-45 … ⚠️` — keduanya **belum** dicentang |

---

## 3. Serangan yang dijalankan (kill attempts)

Semua serangan dijalankan pada skema 23 migrasi + `alat/sql/data-uji.sql`, PostgreSQL 16.2 (`pgserver`) atau runner proyek (`node alat/uji-sql.mjs`), sebagai `set local role authenticated` dengan `uji.klaim(<uuid>)` — model ancaman yang sama dengan yang dipakai suite uji proyek sendiri.

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| S-01 | Bayar penuh + turunkan `qty` dalam SATU pernyataan (CTE data-modifying) | `with bayar as (insert into pembayaran … returning id) update pesanan_item set qty=1 …` | **GAGAL diserang** — `BY-201: Pembayaran sudah tercatat. Isi dan nominal pesanan terkunci` (datang dari `zzz_pesanan_beku_setelah_bayar` lewat `hitung_total`; baris CTE belum terlihat pemicu `aaa_`, tapi sabuk header menangkapnya) |
| S-02 | Bayar penuh + void seluruh pesanan dalam SATU pernyataan | `with bayar as (…) insert into pembatalan(pesanan_id,tahap,alasan) …` | **GAGAL diserang** — BY-201 (sabuk header, `new.status='batal'`) |
| S-03 | Bayar penuh + diskon dalam SATU pernyataan | `with bayar as (…) insert into diskon_transaksi … 1000` | **GAGAL diserang** — BY-201 |
| S-04 | **Bayar penuh + ubah `pesanan_item.catatan`** (total tidak berubah) | `node alat/uji-sql.mjs /tmp/probe-aud/f01.sql` varian D | **BERHASIL MENEMBUS** — `DITERIMA (tanpa BY-201)`; sesudah: `catatan='sudah diubah sesudah bayar'`, `bayar=[(62100,)]` → **F-01** |
| S-05 | **Bayar penuh + ubah `pesanan.catatan`** | probe3-I | **BERHASIL MENEMBUS** — `sesudah: [(62100, 'draf', 'catatan diubah sesudah bayar')] bayar= [(62100,)]` → **F-01** |
| S-06 | **Bayar penuh + ubah `pesanan.tipe` `dinein`→`takeaway`** | probe3-J | **BERHASIL MENEMBUS** — `sesudah: [('takeaway', 62100, 'draf')] bayar= [(62100,)]` → **F-01** |
| S-07 | **Bayar penuh + pindah `pesanan.shift_id` ke shift lain / kosongkan `meja_id` / isi `pelayan_id`** | probe4 (CTE + `update pesanan set …`) | **BERHASIL MENEMBUS** ketiganya — `shift_id sekarang=[(UUID('…beef'))] baris_pembayaran=[(1,)]` · `meja_id=[(None,)]` · `pelayan_id=[(UUID('9000…0005'))]` → **F-01** |
| S-08 | Bayar penuh + mundurkan `tanggal` 3 hari / ganti `nomor` / karang `dibayar_pada` / paksa `status='lunas'` | probe4 | **GAGAL diserang** — ditolak penjaga lama: "Tanggal pesanan tidak boleh diubah" · "Nomor pesanan tidak boleh diubah" · "Stempel pembayaran (dibayar_pada) hanya diisi jalur peladen" · "Perpindahan status pesanan draf → lunas tidak diizinkan dari perangkat" |
| S-09 | Bayar penuh + tukar `qty`/`harga_saat_itu` supaya subtotal tetap (kasir, lalu admin ber-`ubah_harga`) | probe2-E, probe3-L | **GAGAL diserang** — "Harga menu ini Rp27000 — mencatat harga lain (Rp54000) perlu izin ubah harga" (kasir); "Nama & harga yang sudah tercatat tidak boleh diubah" (admin) |
| S-10 | Bayar penuh + tukar `menu_item_id` ke item lain | probe3-M | **GAGAL diserang** — "Harga menu ini Rp8000 — mencatat harga lain (Rp27000) perlu izin ubah harga" |
| S-11 | Bayar penuh + `update pesanan_item set status='batal'` (void tanpa baris `pembatalan`) | probe2-H | **GAGAL diserang** — "Pembatalan item WAJIB lewat baris pembatalan resmi" |
| S-12 | Urutan terbalik: kecilkan `qty` di CTE, catat bayar 62.100 di pernyataan utama | probe2-G | **GAGAL diserang** — BY-201; `dibayar=[(0,)]` (tidak ada uang tersimpan) |
| S-13 | Balapan dua koneksi bayar↔edit/void, kedua urutan commit | `python3 alat/uji-konkuren-0022.py` | **GAGAL diserang** — 5 kontrol: `bayar→catatan/qty/void` ditolak BY-201 dengan `terkunci=True` (`pg_blocking_pids`), `qty→bayar` ditolak "melebihi total pesanan (31050)", `void→bayar` ditolak "sudah dibatalkan"; 2 mutasi menyimpan pelanggaran nyata |
| S-14 | **Sesi `authenticated` TANPA klaim `sub` membaca uang pesanan resto lain** lewat RPC definer | `node alat/uji-sql.mjs /tmp/probe-aud/f02.sql` | **BERHASIL MENEMBUS** — kontrol kasir resto B dengan identitas = `0`; tanpa klaim `sub` = **`12345`** (angka nyata) → **F-02** |
| S-15 | **Sesi `authenticated` TANPA klaim `sub` memanggil `hitung_total()` pesanan resto lain** (tulis lintas penyewa, RLS dilewati definer) | probe7-a2 | **BERHASIL MENEMBUS** — `select public.hitung_total(<pesanan resto A>)` → `[(62100,)]` (tidak ditolak); dengan identitas kasir resto B → ditolak "Pesanan itu bukan milik resto Anda" → **F-02** |
| S-16 | Sesi `authenticated` tanpa klaim `sub` menulis kolom uang `pesanan.total` langsung | probe6 (`update public.pesanan set total=1 …`) | **GAGAL diserang** — `baris terpengaruh: 0` (RLS menahan walau `picu_pesanan_jaga_uang` melompat karena `auth.uid() is null`); `select count(*) from pesanan` = 0 |
| S-17 | **Deadlock**: T1 kunci parent X lalu Y, T2 kunci Y lalu X (masukan multi-baris/dua pernyataan) | probe7-b + probe8 (diulang dengan pemicu 0022 DIBUANG) | **TERCAPAI** — `t1 -> DeadlockDetected: deadlock detected`, `t2 -> commit`; **sama** dengan 0022 dibuang → bukan regresi Batch-5, tapi klaim urutan kunci 0022 tidak menutupnya → **F-04** |
| S-18 | Tarif pajak dinaikkan sesudah bayar lalu dapur menekan "siap" | probe3-K | **GAGAL diserang** — total tetap `(54000, 5400, 2700, 62100)` |
| S-19 | Naik peran lewat peubah sesi yang bisa di-`SET` klien (`peran_peladen()`) | `grep -n "function public.peran_peladen" -A 20 supabase/migrations/0010_pembayaran.sql` | **GAGAL diserang** — `peran_peladen()` membaca `current_user` + `pg_has_role(…,'service_role','member')`, bukan GUC yang bisa di-`SET` klien |
| S-20 | Panggil fungsi trigger sebagai RPC dari klien (`select picu_…()`) | probe5 (daftar EXECUTE) | **Sebagian terbuka** — 11 fungsi trigger non-definer masih bisa dipanggil `anon`/`authenticated`; pemanggilan langsung tidak menimbulkan efek (NEW/OLD NULL) dan bukan `security definer`, jadi **tidak ada eksploit yang bisa saya buktikan** → **F-06** (higiene, K-4) |
| S-21 | Ubah `kasir_id` pesanan sesudah bayar (pemalsuan atribusi tingkat pesanan) | probe4 + `sed -n '455,470p' supabase/migrations/0014…` | **GAGAL diserang** — `picu_pesanan_jejak_jujur` menolak "Jejak kasir pesanan tidak boleh diubah" (independen dari pembayaran) |
| S-22 | Hapus/ubah baris `pembayaran` (refund gelap) | `grep -n "on public.pembayaran" supabase/migrations/*.sql` | **GAGAL diserang** — hanya `grant select, insert … to authenticated` (0010:550); tidak ada grant UPDATE/DELETE, tidak ada trigger yang perlu |

---

## 4. Temuan

### [F-01] Pembekuan sesudah pembayaran pertama (0022) bisa dilewati satu pernyataan SQL: jejak pesanan tetap bisa diubah setelah uang tercatat
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0022_beku_setelah_bayar.sql:31-32` (`perform … for update` lalu `exists(select 1 from pembayaran …)`) dan `:73` (`if exists(select 1 from pembayaran pb where pb.pesanan_id = old.id)`); kolom terdampak di `supabase/migrations/0009_pesanan.sql:17-42`
- **Klaim yang dilanggar:** PRD M6 + Aturan Bisnis 7 ("**Sesudah pembayaran pertama, termasuk sebagian: isi/nominal, diskon, dan void dikunci** — T-025(a)"); TECH_SPEC §2 butir 6 ("**Setelah pembayaran pertama (termasuk sebagian), isi/nominal, diskon, dan void terkunci**"); komentar 0022:41 `BY-201: … Isi, diskon, dan pembatalan pesanan terkunci`; klaim pembangun paket §2 no.1
- **Bukti:** `node alat/uji-sql.mjs /tmp/probe-aud/f01.sql` (runner proyek sendiri, probe auditor di luar repo) →
  `node alat/uji-sql.mjs /tmp/probe-aud/f01.sql` →
  `GAGAL /tmp/probe-aud/f01.sql` / `HARAPAN TIDAK TERPENUHI: F-01: catatan pesanan TIDAK boleh berubah sesudah pembayaran pertama (dapat catatan diubah SESUDAH uang tercatat, harap <NULL>)` / `uji: 0 LULUS · 1 GAGAL`.
  Asersi pertama pada berkas yang sama (`count(*) from pembayaran = 1`) **LULUS**, jadi baris uang Rp62.100 benar-benar tersimpan.
  Pernyataan penyerangnya satu kalimat:
  `with bayar as (insert into public.pembayaran(pesanan_id,metode_id,jumlah,diterima,kunci_idempoten) select '<pesanan>', id, 62100, 62100, 'k' from public.metode_bayar where penyewa_id='<penyewa>' and nama='Tunai' returning id) update public.pesanan set catatan='…', tipe='takeaway', pelayan_id='<pegawai>' where id='<pesanan>';`
  Keluaran probe PostgreSQL 16.2 (dua koneksi tidak diperlukan):
  `I: bayar penuh + ubah catatan header → DITERIMA (tanpa BY-201); sesudah: [(62100,'draf','catatan diubah sesudah bayar')] bayar= [(62100,)]` ·
  `J: … ubah tipe → DITERIMA; sesudah: [('takeaway',62100,'draf')]` ·
  `shift_id dipindah ke shift lain → DITERIMA; shift_id=[(UUID('00000000-0000-0000-0000-00000000beef'))] baris_pembayaran=[(1,)]` ·
  `meja_id dikosongkan → DITERIMA` · `pelayan_id diisi pegawai cabang itu → DITERIMA` ·
  `D: … ubah catatan item → DITERIMA; sesudah: catatan=[('sudah diubah sesudah bayar')] bayar=[(62100,)]`.
  **Kontrol** (perubahan yang sama sebagai pernyataan kedua, sesudah pembayaran di-commit) **ditolak** BY-201 — jadi yang bocor khusus jalur satu-pernyataan.
- **Skenario gagal:** (1) kasir/penyerang dengan kemampuan menjalankan SQL sebagai `authenticated` menutup meja: satu pernyataan mencatat pembayaran tunai Rp62.100 **dan** menulis ulang jejak pesanan (`catatan`, `tipe`, `meja_id`, `pelayan_id`, `shift_id`, `pesanan_item.catatan`); (2) karena `pembayaran` append-only dan tidak ada jejak audit untuk kolom-kolom itu, isi struk/atribusi/shift yang tercetak dan yang tersimpan berbeda permanen; (3) T-025(a) justru dibuat untuk menutup kelas "ubah setelah uang masuk" ini — `zzz_pesanan_beku_setelah_bayar` sengaja membandingkan **semua** kolom kecuali `status`/`dikirim_ke_dapur_pada`/`dibayar_pada`, dan perbandingan itu tidak pernah melihat baris uang yang lahir di perintah yang sama. **Batas jujur:** `total`/`subtotal`/`pajak`/`service`/`total_diskon` **tidak** berubah (setiap varian yang mengubahnya tertangkap sabuk header lewat `hitung_total`), dan `shift_id` saat ini belum punya FK/tabel `shift` (`grep -rn "shift_id" supabase/migrations` = 3 baris deklarasi/komentar saja) sehingga dampak `shift_id` masih laten sampai M7 dibangun. Karena itu ini saya nilai K-2 (kontrol wajib/janji PRD bisa dilewati), **bukan** K-1.
- **Dugaan penyebab:** baris yang disisipkan CTE data-modifying berbagi *command id* dengan pernyataan utama, sehingga `HeapTupleSatisfiesMVCC` membuatnya tak terlihat bagi `exists(select 1 from pembayaran …)` di pemicu `aaa_*`/`zzz_*` pada perintah yang sama. Pemicu mengandalkan "sudah ada baris uang **yang terlihat**", bukan "perintah ini sedang mencatat uang". Sabuk kedua (`zzz_`) kebetulan menutup varian ber-dampak-nominal karena `hitung_total` menaikkan *command counter* sebelum `UPDATE pesanan`, tetapi tidak menutup varian yang totalnya tetap.
- **Cara membuktikan perbaikan:** probe di atas dijadikan berkas uji tetap, mis. `supabase/tes/beku_satu_pernyataan.sql`, berisi minimal 3 asersi `uji.sama(… , null::text, …)`/`harap_gagal_sebab(…, 'BY-201', …)` untuk (a) `pesanan.catatan/tipe/meja_id/pelayan_id/shift_id`, (b) `pesanan_item.catatan`, (c) kontrol dua-pernyataan tetap BY-201; lalu `node alat/uji-sql.mjs supabase/tes/beku_satu_pernyataan.sql` **LULUS** dan `python3 alat/uji-mutasi-0022.py` ditambah mutasi "pagar satu-pernyataan dilepas" yang **wajib MERAH-PAGAR**.
- **Status verifikasi:** TERVERIFIKASI

### [F-02] Pola `auth.uid() is null or …` membuat RPC SECURITY DEFINER melewati isolasi penyewa untuk sesi `authenticated` tanpa klaim `sub`
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0010_pembayaran.sql:190-200` (`total_dibayar`, `security definer`, `and (auth.uid() is null or public.pesanan_sepenyewa(pb.pesanan_id))`, `grant execute … to authenticated` di baris 559); pola sama di 14 tempat — `grep -rn "auth.uid() is null or" supabase/migrations/*.sql` = 14 baris (0009:151, 0010:200, 0013:272, 0014:183/359/434/503/546, 0015:62/819/921, 0016:440, 0017:35)
- **Klaim yang dilanggar:** PRD Aturan Bisnis 9 ("**Isolasi data**: antar-penyewa dan antar-cabang"); komentar 0010:180-189 sendiri ("ISOLASI LINTAS RESTO … fungsi SECURITY DEFINER melewati RLS, jadi tanpa pemeriksaan di sini siapa pun yang masuk bisa membaca angka uang pesanan resto LAIN hanya dengan menebak UUID"); klaim 0022:6-7 ("Tidak ada bypass auth.uid() null")
- **Bukti:** `node alat/uji-sql.mjs /tmp/probe-aud/f02.sql` →
  `HARAPAN TIDAK TERPENUHI: F-02: tanpa klaim sub, angka uang resto lain TIDAK boleh bocor (dapat 12345, harap 0)` / `uji: 0 LULUS · 1 GAGAL`.
  Pada berkas yang sama asersi kontrol **LULUS**: `public.total_dibayar(<pesanan resto A>)` sebagai kasir resto B (identitas jelas) = `0`.
  Jalur tulis lintas penyewa juga terbuka — probe7:
  `hitung_total pesanan resto A dipanggil kasir resto B → DITOLAK: Pesanan itu bukan milik resto Anda.` vs
  `hitung_total pesanan resto A dipanggil TANPA identitas → [(62100,)]` (fungsi definer benar-benar menghitung ulang dan menulis pesanan penyewa lain, RLS dilewati).
- **Skenario gagal:** sesi Postgres dengan peran `authenticated` tetapi tanpa `sub` (mis. kode peladen/Edge Function yang memakai `set local role authenticated` tanpa menyetel `request.jwt.claims` — pola yang didokumentasikan Supabase sendiri untuk koneksi langsung, lihat tautan di bawah; atau siapa pun yang punya kredensial DB lalu `SET ROLE authenticated`) dapat (a) **membaca** total uang yang sudah masuk untuk pesanan resto lain hanya dengan menebak UUID, dan (b) **menulis ulang** angka uang pesanan resto lain lewat `hitung_total()`. RLS masih menahan `select`/`update` langsung pada tabel (probe6: `baris terpengaruh: 0`, `count(*) from pesanan` = 0), jadi kebocoran terbatas pada permukaan RPC definer — tetapi permukaan itu persis yang dulu dinilai K-1 pada audit AUD-3 2026-09-17 dan ditutup dengan penjaga ini.
  **Batas jujur (tidak saya naikkan menjadi fakta):** saya **tidak** bisa membuktikan jalur yang bisa dicapai dari peramban/PostgREST — PostgREST selalu mengisi klaim dari JWT yang sudah diverifikasi. Yang TERVERIFIKASI adalah perilakunya di SQL; yang **DUGAAN** adalah keterjangkauannya dari klien tanpa kredensial DB.
- **Dugaan penyebab:** "tanpa identitas = jalur peladen yang tepercaya" dipakai sebagai proxy untuk "bukan klien". Di Postgres, peran `authenticated` dan ada/tidaknya klaim `sub` adalah dua hal yang berbeda; sesi bisa berada di peran `authenticated` tanpa klaim.
- **Cara membuktikan perbaikan:** ganti cabang null dengan pembeda yang tidak bisa dipalsukan dari sesi klien — mis. `public.peran_peladen()` di luar fungsi definer, atau `auth.uid() is null and current_user <> 'authenticated'` — pada 14 titik, ditambah berkas uji `supabase/tes/isolasi_null_identitas.sql` yang mengaserasikan `total_dibayar(<pesanan penyewa lain>) = 0` dan `hitung_total(<pesanan penyewa lain>)` **ditolak** saat `uji.klaim(null)` + `set local role authenticated`; perintah yang harus hijau: `node alat/uji-sql.mjs supabase/tes/isolasi_null_identitas.sql`, dan `python3 alat/uji-mutasi-0015.py` + mutasi baru "cabang null-identitas dibuka" wajib MERAH.
- **Status verifikasi:** TERVERIFIKASI (perilaku di SQL); keterjangkauan dari klien = DUGAAN (lihat Batas jujur)

### [F-03] Tidak ada satu pun uji/mutasi yang menutup jalur "uang dan perubahan dalam SATU pernyataan"
- **Tingkat:** K-3
- **Artefak:** `supabase/tes/beku_setelah_bayar.sql` (118 baris, tanpa satu pun `with … as (`), `alat/uji-mutasi-0022.py:22-40` (9 mutasi, semuanya `drop trigger`/pelemahan syarat), `alat/uji-konkuren-0022.py:145-152` (7 kasus, semuanya dua pernyataan/dua koneksi)
- **Klaim yang dilanggar:** paket §0d "Probe prioritas tambahan: … transaksi pembayar gagal/rollback; urutan kunci …"; protokol §4 L4 ("Ada uji yang lulus karena sebab yang salah? … Gerbang yang belum pernah dibuktikan bisa MERAH?")
- **Bukti:** `grep -c "with " supabase/tes/beku_setelah_bayar.sql` → `0` (tidak ada CTE data-modifying di uji pembekuan); `grep -n "mutasi = \[" -A 12 alat/uji-mutasi-0022.py` → 9 mutasi semuanya `drop trigger`/penggantian syarat, tidak ada yang menguji visibilitas baris dalam perintah yang sama. Akibatnya F-01 lolos dari 65/65 SQL + 9 mutasi + 7 kasus concurrency yang semuanya hijau.
- **Skenario gagal:** harness hijau penuh memberi keyakinan "pembekuan tertutup", padahal kelas serangan satu-pernyataan belum pernah dicoba; temuan uang baru akan terus lolos sampai ada asersi yang menanyakannya.
- **Dugaan penyebab:** model uji dibangun dari skenario aplikasi (satu pernyataan = satu aksi kasir), bukan dari model ancaman SQL yang justru dipakai suite uji ini di semua tempat lain (`set local role authenticated` + SQL bebas).
- **Cara membuktikan perbaikan:** tambahkan berkas uji satu-pernyataan (lihat F-01) **dan** mutasi padanannya; `python3 alat/uji-mutasi-0022.py` harus mencetak ≥10 mutasi dengan kasus baru berklasifikasi `MERAH-PAGAR`.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Deadlock nyata tercapai di jalur penyuntingan item; komentar urutan kunci 0022 menjanjikan lebih daripada yang diberikan
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0022_beku_setelah_bayar.sql:25-27` ("Urutan UUID tetap menghindari kunci silang pada pemindahan antar-pesanan" + `order by x`); pembanding pra-0022 `supabase/migrations/0014_penutup_celah_putaran13.sql:142` (`item_hitung_total` → `hitung_total` → `UPDATE pesanan`)
- **Klaim yang dilanggar:** 0022:25 (klaim urutan kunci); paket §0d "urutan kunci dan timeout/deadlock"
- **Bukti:** `/tmp/venv-aud/bin/python /tmp/probe-aud/probe7_kunci.py` (dua koneksi, PostgreSQL 16.2, T1 mengunci parent X lalu Y, T2 mengunci Y lalu X):
  `t1 -> DeadlockDetected: deadlock detected` / `t2 -> commit`.
  probe8 mengulang skenario identik dengan keempat pemicu 0022 DIBUANG di database uji:
  `skema : {'t1': 'DeadlockDetected', 't2': 'commit'}` · `0022 D: {'t1': 'DeadlockDetected', 't2': 'commit'}`
  → deadlock **bukan** regresi Batch-5 (sudah ada dari `hitung_total` yang meng-`UPDATE` parent), tetapi pengurutan UUID di 0022 **tidak** mencegahnya.
- **Skenario gagal:** dua perangkat kasir/dapur menyunting item dari dua pesanan yang sama secara bersilangan (mis. sinkronisasi ulang saat koneksi pulih, atau pemindahan item antar-pesanan berbarengan) → salah satu transaksi dibatalkan PostgreSQL dengan `40P01 deadlock detected`. Kasir melihat galat internal, bukan pesan bisnis; bila klien tidak mengulang, perubahan itu hilang diam-diam.
- **Dugaan penyebab:** `order by x` hanya mengurutkan dua parent **di dalam satu pemanggilan pemicu (satu baris)**. Urutan penguncian antar-baris dalam satu pernyataan multi-baris, dan antar-pernyataan dalam satu transaksi, tetap mengikuti urutan pemindaian/urutan perintah — bukan urutan UUID.
- **Cara membuktikan perbaikan:** kunci parent dengan urutan global yang stabil sebelum menyentuh rincian (mis. `pg_advisory_xact_lock(hashtext(pesanan_id))` di awal `hitung_total`/pemicu, seperti pola 0021), atau dokumentasikan bahwa deadlock mungkin dan klien wajib mengulang; buktinya: probe dua-koneksi di atas dijadikan `alat/uji-konkuren-0022.py` kasus ke-8 yang menuntut **tidak ada** `DeadlockDetected` pada skema utuh dan **ada** pada mutasi tanpa pengurutan global.
- **Status verifikasi:** TERVERIFIKASI (deadlock tercapai; asal-usul pra-0022 juga terverifikasi)

### [F-05] Angka bukti di dokumen pengikat basi pada commit yang diaudit, dan pemeriksa angka tidak bisa menangkapnya
- **Tingkat:** K-4
- **Artefak:** `docs/uji/AUDIT_RIWAYAT.md:84` (baris I F-17: "Batch-5: penegak 0022 + **SQL 64/64** …", baris ini disentuh di commit `09bcb89`), `docs/ROADMAP.md:623` ("**SQL 64/64**, mutasi 9/9 …"), `docs/ops/SIAP-LANJUT.md:17-18` ("**CI terakhir:** in_progress (run 35573632489, commit c5dbc983)" + "**PERHATIAN:** CI terakhir BUKAN success"), penjaga `alat/periksa-angka-bukti.py:44` (`POLA_ANGKA = re.compile(r"\b\d+\s+(uji|tabel)\b")`)
- **Klaim yang dilanggar:** protokol §4 L3 ("Setiap klaim 'Bukti' di ROADMAP **bisa direproduksi hari ini**?"); `docs/ops/SIAP-LANJUT.md` adalah berkas handoff yang dibaca sesi berikutnya sebagai keadaan sekarang
- **Bukti:** `node alat/uji-sql.mjs` pada commit ini → `uji: 65 LULUS · 0 GAGAL` (bukan 64). `gh run view 35574069120 --json status,conclusion,headSha` → `{"conclusion":"success","headSha":"09bcb89fc139b3be32ab874e7a004f0a3b0480ee"}` — jadi baris "CI terakhir BUKAN success" sudah tidak benar di commit yang sama. `python3 alat/periksa-angka-bukti.py` → `HASIL: LOLOS` (bentuk `64/64` tidak cocok polanya, jadi tidak pernah diperiksa). Pembanding: `docs/uji/BUKTI_T130_KEAMANAN_SQL.md:23` dan `docs/ops/SIAP-LANJUT.md:73` menulis **65/65** — benar.
- **Skenario gagal:** sesi berikutnya membaca `SIAP-LANJUT.md` baris 18 dan menyimpulkan CI merah (menahan pekerjaan yang seharusnya jalan), atau membaca `AUDIT_RIWAYAT.md`/`ROADMAP` dan mereproduksi "64/64" lalu mengira suite kehilangan satu berkas uji.
- **Dugaan penyebab:** `AUDIT_RIWAYAT.md:84` disalin dari `BUKTI_T025…` (yang benar 64 pada commit `2d181a2`, sebelum `keamanan_fungsi.sql` menambah berkas ke-65) dan tidak disegarkan saat 0023 mendarat di commit yang sama; penjaga angka hanya mengenal pola "N uji"/"N tabel".
- **Cara membuktikan perbaikan:** samakan menjadi 65/65 di `AUDIT_RIWAYAT.md:84` dan `ROADMAP.md:623`, segarkan baris CI `SIAP-LANJUT.md:17-18` ke `success (run 35574069120, commit 09bcb89)`; perluas `POLA_ANGKA` agar menangkap bentuk `N/M` di klaim Bukti, lalu `python3 alat/periksa-angka-bukti.py --uji-diri` memuat kasus baru "angka N/M basi → ditolak".
- **Status verifikasi:** TERVERIFIKASI

### [F-06] 11 fungsi trigger non-definer masih memegang EXECUTE PUBLIC/anon/authenticated; asersi `T130-trigger` tidak menjangkaunya
- **Tingkat:** K-4
- **Artefak:** `supabase/tes/keamanan_fungsi.sql:27-34` (syarat `where … p.prosecdef and p.prorettype='trigger'::regtype`), `supabase/migrations/0023_acl_fungsi_pemicu.sql:9-30` (20 nama eksplisit)
- **Klaim yang dilanggar:** `docs/uji/BUKTI_T130_KEAMANAN_SQL.md` ("daftar eksplisit 20 pemicu dicabut hak PUBLIC/anon/authenticated-nya … fungsi trigger tidak dapat dipanggil sebagai RPC biasa") — benar untuk yang definer, tidak untuk 11 sisanya
- **Bukti:** `/tmp/venv-aud/bin/python /tmp/probe-aud/probe5_katalog.py` (katalog PostgreSQL efektif sesudah 23 migrasi) — `fungsi SECURITY DEFINER di public : [(53,)]`, `… returns trigger: [(23,)]`, dan daftar fungsi **biasa** yang masih boleh dipanggil `anon`+`authenticated` memuat 11 fungsi trigger: `picu_item_jaga`, `picu_item_salinan_beku`, `picu_item_varian_berharga`, `picu_jaga_jumlah_stok`, `picu_meja_jaga`, `picu_pembayaran_metode_wajib`, `picu_pesanan_jaga_status`, `picu_pesanan_jaga_uang`, `picu_pesanan_jejak_jujur`, `picu_pesanan_status_awal`, `picu_pesanan_tertutup_beku`. Jadi 23 dari 34 fungsi trigger tercakup DoD, 11 tidak.
- **Skenario gagal:** permukaan panggilan yang tidak perlu tetap terbuka untuk `anon`; bila salah satu fungsi itu suatu saat dijadikan `security definer` (pola yang dipakai di 0012–0022), hak PUBLIC yang sudah ada akan langsung menjadi RPC istimewa tanpa ada pemeriksa yang merah. **Saya tidak berhasil membuktikan eksploit hari ini:** pemanggilan langsung mengembalikan NULL karena `NEW`/`OLD` kosong dan fungsi-fungsi itu bukan definer.
- **Dugaan penyebab:** 0023 memakai daftar eksplisit (sengaja, agar objek penyedia tidak tersapu) yang diambil dari inventaris **definer**; asersi penjaganya memakai penyaring yang sama, sehingga keduanya buta pada fungsi trigger non-definer.
- **Cara membuktikan perbaikan:** tambah satu asersi di `supabase/tes/keamanan_fungsi.sql` untuk `p.prorettype='trigger'::regtype` **tanpa** syarat `prosecdef` (atau perluas daftar 0023 ke 31 nama), lalu `python3 alat/periksa-keamanan-sql.py` LOLOS dan `--uji-diri` memuat mutasi "trigger non-definer dibuka ke anon" yang wajib MERAH-PAGAR.
- **Status verifikasi:** TERVERIFIKASI (fakta katalog); dampak keamanan = tidak terbukti (lihat Skenario gagal)

---

## 5. Kalibrasi cacat tanaman

Tidak berlaku untuk tingkat AUD-2. Protokol §7 menetapkan kalibrasi cacat tanaman **wajib untuk AUD-3**; paket AUD-2 ini tidak menunjuk folder bahan (`docs/uji/kalibrasi/bahan-*`) dan tidak memberi kunci. Saya tidak mencari kunci jawaban di dalam maupun di luar repo. Konsekuensi jujur: ketajaman auditor pada audit ini **tidak terukur**; verdict TIDAK-BERSIH di atas berdiri di atas bukti probe, bukan di atas skor kalibrasi.

---

## 6. Yang tidak bisa saya verifikasi

- **Supabase produksi.** Tidak ada proyek/kredensial Supabase. Semua hasil SQL berasal dari PostgreSQL 16.2 `pgserver` (dengan tiruan `pgcrypto` yang algoritmanya sengaja murah) dan PGlite di `node alat/uji-sql.mjs`. Perilaku `auth.uid()`/`auth.jwt()`, `pgcrypto` asli, penyedia Supabase, dan penerapan migrasi di proyek nyata **tidak teruji** — persis peringatan `docs/uji/BUKTI_T025…` butir 2.
- **Keterjangkauan F-02 dari klien.** Saya tidak bisa membuktikan bahwa penyerang tanpa kredensial DB dapat memperoleh sesi `authenticated` tanpa klaim `sub`. PostgREST mengisi klaim dari JWT terverifikasi; jalur yang saya ketahui (koneksi langsung sebagai `postgres` lalu `SET ROLE authenticated`, atau kode peladen yang memakai pola `set local role authenticated` + `set_config('request.jwt.claims', …)`) semuanya membutuhkan rahasia proyek. Rujukan pola koneksi langsung: <https://supabase.com/docs/reference/server/middleware-withpostgresclientconfig> dan <https://github.com/orgs/supabase/discussions/30124>.
- **`bash aplikasi/alat/periksa-semua.sh` utuh.** Tidak saya jalankan (durasi). Saya menjalankan komponennya sendiri dan semuanya hijau: `uji-mutasi-0015`, `uji-mutasi-0022`, `periksa-keamanan-sql.py` (+`--uji-diri`), `uji-konkuren-0022.py`, `uji-edge-pin.mjs`, `npm test`, `typecheck`, `lint`. Klaim "seluruh periksa-semua lokal hijau" karena itu **tidak** saya sahkan secara utuh.
- **`alat/periksa-paket.py --uji-diri`** mencetak `LEWAT: commit sejarah d1f11d7 tidak ada di repo ini (klon dangkal?)` di salinan kerja saya — itu artefak salinan `git archive` (tanpa riwayat), bukan cacat repo. Perilaku penuhnya pada klon berriwayat tidak saya uji.
- **`alat/audit-independen.py --verifikasi-lingkup`** menunjuk paket lain (`docs/uji/paket-audit/AUD-3-2026-09-20.md` → `cbba4010`), bukan paket AUD-2 yang saya kerjakan, karena berkas paket AUD-2 belum ada di commit target (sudah dijelaskan paket §6). Saya tidak memakainya sebagai sumber lingkup.
- **Lensa L5 (lapangan/UI) dan L6 (privasi/kepatuhan)** tidak wajib untuk AUD-2 dan tidak saya kerjakan sebagai lensa. Berkas UI (`aplikasi/src/lib/tema.ts`, `aplikasi/src/komponen/*.tsx`, `aplikasi/README.md`) hanya saya sentuh lewat `npm test`/`lint`/`typecheck`; tidak ada penilaian 7-keadaan/tombol.
- **Identitas model.** Platform tidak membuka model yang dipakai sesi ini, jadi "model berbeda dari sesi kerja" tidak bisa saya buktikan; dicatat sebagai keterbatasan sesuai protokol §3 butir 2 dan §14 butir 2.
- **`alat/uji-mutasi-0009/0012/0014/0016/0017/0018/0021.py`** dan `alat/uji-konkuren.py` penuh tidak saya jalankan ulang (di luar lingkup Batch-5); hanya `0015` yang saya jalankan sebagai pembanding.

---

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan **tidak mengubah** berkas proyek apa pun. SATU-SATUNYA berkas yang saya buat adalah laporan ini (`docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md`); tidak ada berkas lain yang saya buat, ubah, atau hapus di repo. Semua pemasangan pustaka, salinan skema, mutasi kalibrasi, dan probe dijalankan di **luar** repo (`/tmp/aud` = salinan `git archive HEAD`, `/tmp/venv-aud` = virtualenv, `/tmp/probe-aud` = probe), jadi pohon kerja commit target tetap bersih.

Bukti — `git symbolic-ref --short HEAD` → `arena/01a0c39d-resto-barokah`, lalu `git status --short`:

```
?? docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md
```

Satu baris, yaitu laporan ini. (Sebelum menulis laporan, `git status --short` pada checkout `--detach 09bcb89` mencetak kosong.)

---

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | **Deadlock pra-0022 di jalur uang** (akar masalah F-04 ada di `item_hitung_total` → `hitung_total` → `UPDATE pesanan`, bukan di 0022) | Lingkup paket adalah Batch-5 (`73bd831..09bcb89`); cacat ini sudah ada sebelum Batch-5 | `probe8`: `skema : {'t1': 'DeadlockDetected', 't2': 'commit'}` · `0022 D: {'t1': 'DeadlockDetected', 't2': 'commit'}` — identik dengan dan tanpa 0022 | Masukkan ke AUD-3 menyeluruh sebagai temuan konkuren jalur uang; butuh keputusan apakah `hitung_total` mengambil kunci global (`pg_advisory_xact_lock`) seperti pola 0021, plus kasus ke-8 di `uji-konkuren-0022.py` |
| 2 | **14 titik `auth.uid() is null or …` di luar `total_dibayar`** (0009:151, 0013:272, 0014:183/359/434/503/546, 0015:62/819/921, 0016:440, 0017:35) — semuanya pemicu, jadi dilindungi RLS pada tabel, tetapi pola yang sama | F-02 saya buktikan hanya pada permukaan RPC definer yang bisa dipanggil klien; pemicu-pemicu ini tidak bisa dipanggil langsung | `grep -rn "auth.uid() is null or" supabase/migrations/*.sql` → 14 baris; `probe6`: `update total pesanan (uang) → baris terpengaruh: 0` (RLS menahan) | AUD-3 L1: petakan tiap titik — mana yang bisa dicapai tanpa RLS (dipanggil dari dalam fungsi definer lain), mana yang tidak; jadikan satu aturan penulisan, bukan 14 pengecualian |
| 3 | **`peran_peladen()` dipakai di dalam pemicu non-definer** (`picu_pesanan_jaga_uang`, `picu_pesanan_jejak_jujur`, …) sehingga `current_user` = pemanggil, bukan pemilik fungsi | Di luar lingkup Batch-5 (definisi ada di 0010/0014 yang beku) | `sed -n '161,174p' supabase/migrations/0010_pembayaran.sql` (baca `current_user` + `pg_has_role`); `probe5` menunjukkan fungsi-fungsi itu **bukan** `prosecdef` | AUD-3 L1: pastikan semantiknya memang dimaksud (pemicu non-definer → `current_user` = klien → penjaga aktif), dan tidak ada tempat yang mengira sedang berada di dalam definer |
| 4 | **Runner `uji-sql.mjs` mendefinisikan `auth.uid()` hanya dari `request.jwt.claim.sub`** (`alat/uji-sql.mjs:60-63`) sementara Supabase membaca `request.jwt.claims->>'sub'` juga | Di luar lingkup Batch-5, tetapi menentukan kesetiaan seluruh 65 uji | `sed -n '55,70p' alat/uji-sql.mjs`; pola Supabase: <https://supabase.com/docs/reference/server/middleware-withpostgresclientconfig> (`select set_config('request.jwt.claims', $claims, true); set local role "authenticated";`) | AUD-3 L4: samakan tiruan `auth.uid()`/`auth.jwt()` dengan definisi Supabase sekarang, supaya uji "tanpa identitas" dan "dengan identitas" menguji cabang yang sama seperti produksi |
| 5 | **`klasifikasi_mutasi.py:81` memakai `any(...)`** — cukup SATU berkas gagal berasersi pengaman untuk melabeli seluruh keluaran `MERAH-PAGAR` | Di luar lingkup Batch-5 (berkas tidak berubah di Batch-5) | `sed -n '81,84p' alat/klasifikasi_mutasi.py`; pembanding: `alat/periksa-keamanan-sql.py:72-73` menambahkan syarat `'HARAPAN TIDAK TERPENUHI' in sebab` sehingga lebih ketat | AUD-3 L4: buktikan dengan dua-berkas-gagal (satu asersi, satu setup rusak) apakah labelnya masih `MERAH-PAGAR`; kalau ya, perketat menjadi `all(...)` |
| 6 | **`docs/uji/audit/` berisi banyak berkas `.dari-<cabang>-<sha>.md` hasil tabrakan nama laporan** (mis. 4 varian `LAPORAN_AUD-3_2026-09-18_menyeluruh__01a0b1f4…`) | Di luar lingkup Batch-5; mekanisme `--ambil-laporan` bekerja sesuai protokol §5c butir 3b | `ls docs/uji/audit/` | Tidak perlu audit; cukup pastikan penanda sesi selalu dipakai (laporan ini memakai `__01a0c39d`) |
````

</details>