# TEMUAN DI LUAR CAKUPAN REVIEW PR — daftar wajib

> **Kenapa berkas ini ada.** Aturan kerja (permintaan Lee, 2026-09-17): temuan peninjau yang berada
> **di luar cakupan diff** tidak boleh hilang. Sebelumnya temuan seperti itu hanya hidup di dalam berkas
> laporan dan mudah terlupakan begitu laporan berikutnya masuk. Berkas ini menjadi **daftar tunggal**:
> setiap temuan luar-cakupan dari laporan review PR dicatat di sini dengan **status yang jelas**,
> **bukti hidup**, dan **tindak lanjut** (tugas ROADMAP / butir tunggu / catatan risiko).
>
> **Dijaga mesin:** `alat/periksa-temuan-audit.py` — baris tanpa status yang jelas, tanpa bukti
> ber-backtick, atau yang menunjuk berkas yang tidak ada → CI GAGAL.
> Cara menambah baris: salin salah satu baris laporan peninjau (bagian 8) apa adanya ke tabel di bawah,
> jangan diperhalus. Status yang dipakai: **DITANGANI**, **DITUNDA** (dengan alasan + sarana), **DICATAT**.

| # | Asal (laporan §8) | Temuan (ringkas, apa adanya) | Status | Bukti / sarana | Catatan |
|---|---|---|---|---|---|
| L-01 | putaran8 `01a0afdb` #1 | Kepala PR sudah bergerak melewati commit yang direview (paket mengikat `7e8c0b9`, kepala `f59debd`); hanya berkas netral, tetapi gerbang merge harus dinilai pada kepala terakhir | **DITANGANI** | `python3 alat/review-pr.py --kesiapan` menolak paket basi; tiap kali tip bergerak paket **disiapkan ulang** dan baris riwayat diperbarui (`docs/uji/REVIEW_PR_RIWAYAT.md`) | Aturan tetap: sebelum meminta Lee menilai, paket wajib menunjuk kepala terakhir |
| L-02 | putaran8 `01a0afdb` #2 | Riwayat kalibrasi review PR masih `(belum ada)`, jadi gerbang "kalibrasi tidak gagal" tidak bisa dinilai sama sekali | **DITANGANI** | `docs/uji/REVIEW_PR_RIWAYAT.md` §2 baris 1: 4 cacat · ditemukan **4** · temuan palsu 0 · LULUS | Diisi dari laporan peninjau yang memuat `Ditemukan: 4 dari 4` |
| L-03 | putaran8 `01a0afdb` #3 | Katalog cacat kalibrasi (`alat/kalibrasi-cacat.json`) ikut ter-commit di repo yang sama dengan bahan & laporan → peninjau berikutnya bisa menebak cacat yang ditanam | **DITANGANI SEBAGIAN** | `python3 alat/review-pr.py --kalibrasi-pr-siapkan` kini **mengacak** pilihan cacat (benih tanggal) dan katalog diperluas 6 → 10 cacat; bahan putaran ini terbukti berbeda susunannya dari putaran sebelumnya | Sisa risiko: katalog memang ada di repo (kunci jawaban tetap di luar repo). Kekuatan penuh baru tercapai bila katalog dipindah ke luar repo — dicatat sebagai risiko proses di `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` §9.3 |
| L-04 | putaran8 `01a0afdb` #4 | Cabang dasar `main` (`253d129`) belum pernah dilewatkan CI, jadi gerbang otomatis baru pertama kali berlaku bila PR di-merge | **DITUNDA** | Setelah merge: jalankan `bash aplikasi/alat/periksa-semua.sh` di `main` dan simpan keluarannya sebagai titik dasar; perluasan janji itu masuk tugas `T1-44` (paket audit diperketat) | Alasan penundaan: `main` bukan bagian dari diff PR ini, dan merge belum diputuskan Lee |
| L-05 | putaran8 `01a0afdc` #1 | Klaim JWT `cabang_id` tidak pernah diterbitkan di repo ini, padahal `cabang_saya()` memerlukannya | **DITANGANI** | Migrasi `supabase/migrations/0012_penutup_celah_review.sql`: `cabang_saya()` membaca **tabel keanggotaan** + sesi cabang (`pilih_cabang`), bukan klaim JWT; uji `supabase/tes/cabang_sesi.sql` | Penerbitan klaim/sesi tetap perlu untuk pemakaian lain → tugas `T1-24`/`T1-25` (belum `[x]`) |
| L-06 | putaran8 `01a0afdc` #2 | Batas PIN per perangkat (12×/15 menit) masih memakai **nama perangkat kiriman klien** — AUD-3 F-11, masih terbuka | **DITUNDA** | `docs/KEAMANAN.md` §2 (catatan F-11) + `docs/TERTANGGUH.md`; ditutup oleh `T1-24` (perangkat terdaftar & terverifikasi) | Jangan menutup F-11 sebelum `perangkat_id` benar-benar terverifikasi |
| L-07 | putaran8 `01a0afdc` #3 | Hash PIN pada uji lokal adalah tiruan SHA, bukan bcrypt | **DICATAT** | Komentar jujur di `alat/uji-sql.mjs` (blok pgcrypto tiruan) | Aturan: kekuatan KDF **tidak** boleh diklaim dari uji PGlite; klaim bcrypt hanya setelah diuji di Supabase nyata (`T0-08`) |
| L-08 | putaran8 `01a0afdc-b` | (tidak ada temuan luar cakupan) | **DICATAT** | `docs/uji/review-pr/LAPORAN_2026-09-17_pr-01-putaran8__01a0afdc-b.md` bagian 8 (berbunyi "tidak ada") | Dicatat supaya "tidak ada" tetap terlihat, bukan hilang |

**Aturan pemakaian:** baris **DITUNDA** wajib menyebut *alasan* dan *sarana penutupnya* (tugas/butir tunggu).
Kalau sarana itu dihapus dari `docs/ROADMAP.md` atau `docs/TERTANGGUH.md`, pemeriksa akan menolak baris ini.
