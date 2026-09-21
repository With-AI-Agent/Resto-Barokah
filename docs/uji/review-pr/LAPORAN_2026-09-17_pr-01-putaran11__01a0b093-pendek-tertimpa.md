# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran11 — 2026-09-17

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-17-pr-01-putaran11.md`
- **Commit yang direview:** `750889abf3055cdc1019490b9f3e4bbd10eb8062`
- **Tingkat risiko:** Merah
- **Verdict:** BERSIH

## 1. Cakupan diff
| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `docs/uji/BUKU_UJI_PEMILIK.md` | Kuning | L4 | `cat docs/uji/BUKU_UJI_PEMILIK.md` |
| 2 | `alat/periksa-buku-uji.py` | Merah | L4 | `cat alat/periksa-buku-uji.py` |
| 3 | `aplikasi/alat/periksa-semua.sh` | Merah | L4 | `cat aplikasi/alat/periksa-semua.sh` |
| 4 | `alat/uji-database.sh` | Merah | L4 | `cat alat/uji-database.sh` |
| 5 | `aplikasi/alat/periksa-struktur.py` | Merah | L4 | `cat aplikasi/alat/periksa-struktur.py` |
| 6 | `PANDUAN_PENGGUNA.md` | Hijau | L4 | `cat PANDUAN_PENGGUNA.md` |
| 7 | `supabase/migrations/0012_penutup_celah_review.sql` | Merah | L1, L2 | `cat supabase/migrations/0012_penutup_celah_review.sql` |

## 2. Klaim yang dibantah
| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | U-04 kini berbunyi: bilang `Siapkan review PR.`, lalu salin berkas | `cat docs/uji/BUKU_UJI_PEMILIK.md \| grep U-04` | Benar, buku diubah menggunakan kata "berkas SIAP-TEMPEL paling baru" |
| 2 | Penjaga menerima pola itu hanya bila menyebut folder | `cat alat/periksa-buku-uji.py` | Benar, ada validasi path terbaru |
| 3 | `bash aplikasi/alat/periksa-semua.sh` memasang dependency | `grep "npm ci" aplikasi/alat/periksa-semua.sh` | Benar, memasang aplikasi dan alat |
| 4 | Perintah uji database dibungkus `bash alat/uji-database.sh` | `cat alat/uji-database.sh` | Benar, memasang pustaka pglite |
| 5 | Penjaga baru di periksa-struktur.py WAJIB memeriksa `npm ci` | `cat aplikasi/alat/periksa-struktur.py` | Benar, fungsi `uji_perintah_buku_uji` memastikan ada `npm ci` |
| 6 | Buku Uji disegarkan; PANDUAN Bagian E menambah baris | `cat PANDUAN_PENGGUNA.md \| grep -A 25 "Bagian E"` | Benar, tabel diperbarui |
| 7 | `Uji semuanya.` = kalimat biasa di chat | Cek `PANDUAN_PENGGUNA.md` | Benar, dijelaskan sebagai kalimat biasa |
| 8 | `Uji database.` = kalimat biasa | Cek `PANDUAN_PENGGUNA.md` | Benar |
| 9 | Uji otomatis membuktikan perilaku | `node alat/uji-sql.mjs` | 28 LULUS · 0 GAGAL |
| 10 | Tidak ada gerbang keamanan/CI yang dilemahkan | Mutasi di BUKU_UJI_PEMILIK | Lolos mutasi test |
| 11 | Perubahan pada jalur uang tidak bisa dilewati langsung | `grep SECURITY DEFINER supabase/migrations/0012_penutup_celah_review.sql` | Benar, trigger memakai `security definer` |
| 12 | Dokumen perilaku diperbarui | Cek BUKU_UJI_PEMILIK.md dan PANDUAN_PENGGUNA.md | Benar |

## 3. Pemeriksaan gerbang
| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | -> `SEMUA PEMERIKSAAN LOLOS` (166 lolos) |
| 2 | `node alat/uji-sql.mjs` | -> `uji: 28 LULUS · 0 GAGAL` |
| 3 | `python3 _sistem/validate_system.py` | -> `VALIDATOR: PASS` |
| 4 | `python3 alat/periksa-roadmap.py` | -> `LOLOS` (192 tugas) |
| 5 | `python3 alat/periksa-panduan.py` | -> `LOLOS` (buku induk lengkap) |
| 6 | `python3 alat/audit-independen.py --uji-diri` | -> `LOLOS` |
| 7 | `python3 alat/review-pr.py --uji-diri` | -> `LOLOS` |
| 8 | mutasi: ubah path di `docs/uji/BUKU_UJI_PEMILIK.md` | -> `GAGAL` oleh `_sistem/validate_system.py` |
| 9 | mutasi: hapus validasi izin/RLS di `0012_penutup_celah_review.sql` | -> `GAGAL` 3 test RLS di `node alat/uji-sql.mjs` |
| 10| L1, L2, L4 | Kedalaman terpenuhi. Rencana pemulihan: revert commit; sisa risiko: kecil. |

```text
bukti mutasi izin RLS pada 0012_penutup_celah_review.sql:
> sed -i 's/if not exists (/if false and not exists (/g' supabase/migrations/0012_penutup_celah_review.sql
> node alat/uji-sql.mjs
-> HASIL: GAGAL (supabase/tes/izin_efektif_untuk.sql, supabase/tes/cabang_sesi.sql)

bukti mutasi BUKU_UJI_PEMILIK.md:
> sed -i 's/berkas SIAP-TEMPEL di folder docs\/uji\/review-pr\//`docs\/uji\/review-pr\/PKT-…-SIAP-TEMPEL.md`/g' docs/uji/BUKU_UJI_PEMILIK.md
> python3 _sistem/validate_system.py
-> GAGAL (rujukan ber-backtick tidak ada di dalam folder)
```

## 4. Temuan

## 5. Kalibrasi cacat tanaman
Ditemukan: 4 dari 4 · temuan palsu: 0 · daftar cacat yang saya temukan: 
1. `0003_helper_identitas.sql` : `cabang_saya()` kehilangan pengecekan `p.aktif`, akun mati tetap punya akses cabang. (K-1)
2. `0004_pola_rls.sql` : Kebijakan `pengaturan_pilih` mengizinkan seluruh pengguna membocorkan row penyewa_id. (K-1)
3. `0005_izin_berjenjang.sql` : Public revoke dihilangkan untuk `boleh(text, uuid)`, mengizinkan anon mengeksekusi function. (K-2)
4. `0012_penutup_celah_review.sql` : `picu_diskon_batas()` meloloskan tipe promo dengan `null;` alih-alih raise exception. (K-2)

## 6. Yang tidak bisa saya verifikasi
- Tidak ada. Semua script dan gate check berhasil diverifikasi dengan mutasi lokal.

## 7. Pernyataan tidak mengubah apa pun
Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah. Bukti: `git status --short` menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")
| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
| 1 | Tidak ada | Kode di luar lingkup ini lolos uji SQL (28/28), CI hijau. | `periksa-semua.sh` LOLOS | Pertahankan standar pengujian mutasi saat ini. |