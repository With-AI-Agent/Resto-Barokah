# AUDIT_RIWAYAT.md — Riwayat Audit Independen & Kalibrasi

> Angka paling penting di berkas ini bukan "berapa temuan", melainkan **berapa cacat yang lolos ke produksi**
> (escaped defects) dan **berapa tingkat deteksi auditor** pada kalibrasi. Keduanya diukur, bukan diklaim.

## 1. Riwayat audit

| # | Tanggal | Tingkat | Lingkup | Auditor | Commit | Temuan K-1 | K-2 | K-3 | K-4 | Tingkat deteksi kalibrasi | Verdict | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| — | 2026-09-17 | — | (mekanisme dipasang; belum ada sesi auditor independen) | mesin + pembangun | `5ecd10b` | 0 | 0 | 0 | 0 | belum dijalankan | — | Paket AUD-2 (T1-01…T1-10) & paket **AUD-3 menyeluruh** (`docs/uji/paket-audit/AUD-3-2026-09-17.md`, seluruh berkas proyek) sudah disiapkan dan **menunggu sesi auditor**; mekanisme diperluas ke lingkup menyeluruh + penjaga buku induk (DECISIONS_LOG 2026-09-17 «Mekanisme audit diperluas…») |

**Cara mengisi:** satu baris per audit. `Tingkat deteksi kalibrasi` = `X/Y` dari `--kalibrasi-nilai`.
Kolom `Auditor` wajib menyebut model/keluarga model yang dipakai (atau "tidak bisa dipilih" bila platform hanya menyediakan satu).

## 2. Cacat yang lolos ke produksi (escaped defects) — angka kejujuran

| # | Tanggal ditemukan | Lolos dari | Ditemukan oleh | Dampak | Sudah jadi butir kalibrasi? |
|---|---|---|---|---|---|
| — | (belum ada — proyek belum dipakai di kedai) | — | — | — | — |

**Aturan:** setiap cacat yang **lolos** ke produksi atau ke pemilik wajib ditambahkan sebagai **butir kalibrasi baru**
ke `alat/kalibrasi-cacat.json`, supaya auditor berikutnya diuji dengan kelas cacat yang sama (praktik *defects → inspection scenarios*).

## 3. Kalibrasi bawaan (baseline 2026-09-17)

Perintah: `python3 alat/audit-independen.py --kalibrasi-siapkan` → 6 cacat ditanam; kunci jawaban di luar repo.

| Butir | Tingkat | Kelas | Ketangkap mesin? (bukti) |
|---|---|---|---|
| P1 | K-1 | hak istimewa fungsi (revoke hilang) | **ya** — `supabase/tes/izin.sql` GAGAL |
| P2 | K-1 | isolasi penyewa (policy dibuka) | **ya** — `supabase/tes/rls_semua_tabel.sql` GAGAL |
| P3 | K-2 | uang (batas lebih bayar dilonggarkan) | **ya** — `supabase/tes/pembayaran.sql` GAGAL |
| P4 | K-2 | akun nonaktif (pemeriksaan `aktif` hilang) | **ya** — `supabase/tes/rls_pengguna.sql` GAGAL |
| P5 | K-3 | dokumen vs kode (5× vs 10×) | **tidak** — hanya ketangkap auditor yang membandingkan dokumen dengan kode |
| P6 | K-3 | pemeriksa tumpul (ambang `periksa-roadmap.py` dilonggarkan 20 → 5) | **tidak** — tidak ada pemeriksa yang memeriksa dirinya sendiri |

**Kesimpulan baseline (jujur):** 4 dari 6 cacat ketangkap **mesin**, 2 hanya bisa ketangkap **penalaran auditor** —
itulah alasan mekanisme ini memakai keduanya, bukan salah satu. Hasil perintah mesin diuji langsung di salinan
kalibrasi: `uji: 6 LULUS · 4 GAGAL`.

## 4. Cacat pada mekanisme ini sendiri (ditemukan saat pemasangan, 2026-09-17)

> Semua cacat di bawah ditemukan **oleh mekanisme/uji sendiri**, bukan oleh pemilik — itulah gunanya.

| # | Cacat | Bagaimana ketahuan | Perbaikan |
|---|---|---|---|
| 1 | Salinan kalibrasi tidak membawa `node_modules` → auditor **tidak bisa menjalankan uji SQL** (alat bukti utama hilang) | Dijalankan sendiri sebelum diserahkan (`node alat/uji-sql.mjs` → `ERR_MODULE_NOT_FOUND`) | `--kalibrasi-siapkan` menautkan `alat/node_modules` & `aplikasi/node_modules`; paket audit kini mencantumkan **kesiapan mesin** |
| 2 | Penghitung **temuan palsu** melewatkan baris yang tidak diberi awalan `P` | Uji-diri dengan contoh laporan berisi temuan palsu (`X1`) — tidak terhitung | Perbaikan logika + uji-diri kini menguji penilai kalibrasi juga (bukan hanya pemeriksa laporan) |
| 3 | Pustaka uji SQL **hilang** dari ruang kerja (sisa restart) → semua klaim "uji LULUS" menjadi tak bisa direproduksi | Pre-flight paket audit & percobaan menjalankan uji | `npm ci --prefix alat` dijalankan; pre-flight sekarang memperingatkan bila alat bukti tidak siap |
| 4 | Pemeriksa laporan **menolak laporan yang sah di klon dangkal** (CI memakai `fetch-depth: 1`, sehingga SHA historis pada contoh laporan tidak ada) → CI MERAH | CI kiriman `7f3974f` gagal di langkah pemeriksa; diagnosis: `git cat-file -e <sha-lama>` gagal di klon dangkal (dibuktikan dengan klon dangkal sungguhan) | Pemeriksa memberi **CATATAN** (bukan penolakan) bila `.git/shallow` ada; `--uji-diri` memakai `cek_sha=False` untuk contoh historis. Diuji ulang di klon dangkal nyata: semua pemeriksa OK |
| 5 | **Rujukan berkas basi di berkas untuk pengguna**: `PROMPT_ENTRI_UNIVERSAL.md` & buku induk menyuruh membaca `` `ROADMAP.md` `` padahal berkas itu ada di `docs/ROADMAP.md` (bagian dari kelas cacat "panduan menunjuk jalan buntu") | Penjaga buku baru (`alat/periksa-panduan.py`) menolak karena rujukan ber-`backtick` tidak hidup | Rujukan diperbaiki **di sumber kanoniknya** (`PROMPT_ENTRI_UNIVERSAL.md`) lalu buku induk dibangun ulang dari sumber itu — bukan disunting terpisah. Rujukan serupa di `AGENT_SYSTEM.md`/`STATUS.md`/`SYSTEM_MANIFEST.md`/`AGENT_OPERATING_GUIDE.md` **diserahkan ke audit menyeluruh** (tidak diubah diam-diam oleh sesi pembangun) |
| 6 | `docs/PANDUAN_PEMILIK.md` & `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` **tidak menunjuk balik** ke buku induk → pengguna bisa tersesat di antara pedoman | Penjaga buku (aturan "berkas pengguna wajib menunjuk ke induk") | Pointer ditambahkan; aturan ini kini diperiksa mesin di CI |
| 7 | **Kalibrasi auditor tidak bisa dijalankan lintas sesi**: `--kalibrasi-siapkan` menaruh salinan di `/tmp` (di luar repo) — sedangkan sesi auditor berjalan di ruang kerja **baru**, sehingga bahan itu tidak ikut berpindah dan AUD-3 praktis **tidak bisa dikalibrasi** | Ditemukan saat menyiapkan AUD-3: menelusuri apakah auditor sesi baru bisa mencapai bahan | Ditambah **jalur kalibrasi auditor**: bahan cacat disengaja di-commit di `docs/uji/kalibrasi/bahan-<tanggal>/` (kunci tetap di luar repo), dijelaskan di `docs/uji/kalibrasi/CARA-PAKAI.md`, diwajibkan di PROTOKOL §7, dan dimasukkan ke paket AUD-3 oleh mesin; `validate_system` diberi **pengecualian sempit** (hanya folder `docs/uji/kalibrasi/bahan-*/`) karena rujukan menggantung di sana memang disengaja |



## 5. Uji-diri mekanisme (wajib hijau sebelum mekanisme dianggap terpasang)

Perintah: `python3 alat/audit-independen.py --uji-diri`

- `laporan-bagus.md` → **LOLOS** (7 artefak, 5 klaim, 5 serangan, 1 temuan K-3)
- `laporan-malas.md` → **DITOLAK** (12 alasan: kepala/bagian hilang, bukti kosong, cakupan & serangan kurang, bagian 6 kosong)
- `laporan-palsu-bersih.md` → **DITOLAK** (verdict BERSIH padahal ada temuan K-1 TERVERIFIKASI)
- `laporan-tanpa-kalibrasi.md` → **DITOLAK** (AUD-3 tanpa angka kalibrasi)
- `kalibrasi-penuh.md` → **TERKALIBRASI** · `kalibrasi-sebagian.md` → **BELUM TERKALIBRASI** (67% < 70%)
