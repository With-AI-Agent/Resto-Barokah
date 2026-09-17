# AUDIT_RIWAYAT.md — Riwayat Audit Independen & Kalibrasi

> Angka paling penting di berkas ini bukan "berapa temuan", melainkan **berapa cacat yang lolos ke produksi**
> (escaped defects) dan **berapa tingkat deteksi auditor** pada kalibrasi. Keduanya diukur, bukan diklaim.

## 1. Riwayat audit

| # | Tanggal | Tingkat | Lingkup | Auditor | Commit | Temuan K-1 | K-2 | K-3 | K-4 | Tingkat deteksi kalibrasi | Verdict | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A | 2026-09-17 | AUD-3 | menyeluruh (334/334 berkas) | sesi `arena/01a0aeb0` (Arena.ai Agent Mode, sesi terpisah) | `442913e` | 1 | 6 | 3 | 0 | 5/5 (100%), 0 temuan palsu | TIDAK-BERSIH | 10 temuan (F-01…F-10). Laporan **LOLOS KONTRAK**. |
| B | 2026-09-17 | AUD-3 | menyeluruh (334/334 berkas) | sesi `arena/01a0aeb4` (Arena.ai Agent Mode, sesi terpisah) | `442913e` | 2 | 7 | 8 | 0 | 5/5 (100%), 0 temuan palsu | TIDAK-BERSIH | 17 temuan (F-01…F-17). Laporan **LOLOS KONTRAK**. |
| C | 2026-09-17 | AUD-3 | 23 dari 334 berkas (7%) | sesi `arena/01a0aeb0` (versi tertimpa, diselamatkan dari commit `9e9dbb6`) | `253d129` (repo basi) | 0 | 3 | 4 | 0 | 0/0 (bahan kalibrasi tidak ada di sesinya) | TIDAK-BERSIH | **DITOLAK** — sesinya tidak menerima paket & commit target (repo yang terbuka masih template), jadi laporan ini **tidak sah untuk putusan**; tetap diarsipkan sebagai bukti (versi tertimpa). |
| — | 2026-09-17 | — | (mekanisme dipasang; belum ada sesi auditor independen) | mesin + pembangun | `5ecd10b` | 0 | 0 | 0 | 0 | belum dijalankan | — | Paket AUD-2 (T1-01…T1-10) & paket **AUD-3 menyeluruh** (`docs/uji/paket-audit/AUD-3-2026-09-17.md`, seluruh berkas proyek) sudah disiapkan dan **menunggu sesi auditor**; mekanisme diperluas ke lingkup menyeluruh + penjaga buku induk (DECISIONS_LOG 2026-09-17 «Mekanisme audit diperluas…») |


### 1a. Catatan ronde AUD-3 (2026-09-17) — apa yang sesi kerja lakukan dengan laporan itu

1. **Ditarik, bukan diyakini.** `python3 alat/audit-independen.py --ambil-laporan` menarik laporan dari cabang sesi auditor.
2. **Diperiksa kontraknya**: kedua laporan **LOLOS KONTRAK** (catatan: bagian 8 tidak ada, karena kontrak §8 belum berlaku di commit `442913e` yang diaudit — dinilai dengan kontrak lama, bukan pelanggaran).
3. **Dikalibrasi**: kedua auditor **TERKALIBRASI** — 5/5 cacat bahan ditemukan (K-1 2/2, K-2 2/2, K-3 1/1), **0 temuan palsu**. Kunci jawaban jalur auditor dibuat ulang dari bahan (kunci lama di `/tmp` hilang saat reset platform) — lihat cacat mekanisme #11.
4. **Diuji ulang sendiri oleh sesi kerja** (tidak mempercayai laporan): 9 pemeriksaan dijalankan lewat `node alat/uji-sql.mjs docs/uji/audit/bukti-verifikasi-2026-09-17.sql` → **1 LULUS · 0 GAGAL**, artinya seluruh cacat yang diklaim (termasuk kedua K-1) benar-benar ada pada commit `417b658`.
5. **Lingkup commit**: audit menunjuk `442913e`; sesudahnya tidak ada berkas `aplikasi/`, `supabase/`, atau `prototipe/` yang berubah (dibuktikan `git diff --name-only 442913e 417b658 -- aplikasi supabase prototipe` → kosong), jadi temuan tetap berlaku untuk tip.
6. **Anomali tiga sesi yang dilaporkan Lee (2026-09-17) — terkonfirmasi, dan tidak ada laporan yang hilang.**
   Tiga sesi dibuka **berbarengan**; ternyata **dua di antaranya bekerja di cabang yang SAMA** (`arena/01a0aeb0`) dan
   menulis laporan dengan **nama berkas yang sama** — jadi laporan pertama **tertimpa** dan hanya hidup di **riwayat commit**
   (`9e9dbb6`, 10:52) di bawah versi yang bertahan (`b4b3e78`, 10:54). Versi tertimpa itu **diselamatkan**
   (`…menyeluruh.dari-01a0aeb0-9e9dbb61.md`) dan **dinyatakan tidak sah untuk putusan** — sesinya tidak menerima paket/commit
   target (repo yang terbuka masih template `253d129`), cakupan hanya 23/334 dan tanpa kalibrasi. Jadi: **laporan ketiga itu sudah masuk dan diarsipkan sebagai bukti**, sedangkan dua laporan yang **sah** (A & B)
   sudah diperiksa penuh dan dipakai untuk bertindak. Atas temuan Lee ini, penarik laporan
   sekarang menelusuri **seluruh riwayat** cabang, bukan hanya ujungnya (cacat mekanisme #12).

### 1b. Status penutupan temuan AUD-3 (diperbarui setiap batch perbaikan)

| Temuan | Tingkat | Status | Bukti penutup |
|---|---|---|---|
| Uang lebih bayar diterima saat total pesanan masih 0 (laporan A F-04 · B F-04 · F-10) | K-1 | **DITUTUP 2026-09-17** | `supabase/tes/gerbang_uang.sql` (merah sebelum, hijau sesudah) · `docs/uji/audit/bukti-verifikasi-2026-09-17.sql` bagian A |
| `total_dibayar(uuid)` bocor lintas resto (laporan B F-04) | K-1 | **DITUTUP 2026-09-17** | `supabase/tes/isolasi_lintas_penyewa.sql` (dulu mengembalikan 777.000 kepada kasir resto lain, kini 0) |
| `izin_efektif_untuk()` / `boleh_untuk()` bocor lintas resto (laporan B F-05) | K-1 | **DITUTUP 2026-09-17** | pintu ditutup untuk klien (hak `authenticated` dicabut) + saringan penyewa di dalam fungsi — diuji di `supabase/tes/isolasi_lintas_penyewa.sql` |
| PIN sendiri bisa diganti tanpa PIN lama (A F-01) | K-2 | **DITUTUP 2026-09-17** | `supabase/tes/kredensial_pin.sql` — penggantian PIN sendiri wajib PIN lama, termasuk saat uuid diri sendiri disebutkan |
| `pin_hash` bisa dibaca pegawai lain (A F-02, B F-10) | K-2 | **DITUTUP 2026-09-17** | rahasia pindah ke tabel `kredensial_pin` (hak klien dicabut, policy menolak semua): `supabase/tes/kredensial_pin.sql` + `pin.sql` |
| Jejak pelaku bisa dipalsukan (A F-05) | K-2 | **DITUTUP 2026-09-17** | pelaku diisi sistem (`auth.uid()`), nilai lain DITOLAK — `supabase/tes/jejak_pelaku.sql` (pembayaran, diskon, pembatalan, catatan stok) |
| Batas persen diskon dilewati saat kolom persen kosong (B F-06) | K-2 | **DITUTUP 2026-09-17** | persen efektif dihitung dari uang — `supabase/tes/diskon_persen.sql`; uji lama `pembayaran.sql` juga diperbaiki (dulu lulus karena sebab yang salah: 20.000 = 37 % dianggap "dalam batas") |
| Void sesudah dapur dengan penyetuju karangan (A F-03) | K-2 | **DITUTUP 2026-09-17** | persetujuan wajib TERBUKTI: PIN benar untuk aksi itu & baru saja (jendela 5 menit), dicatat di `percobaan_pin` — `supabase/tes/persetujuan_void.sql` |
| Status pesanan bisa dipindah klien (lunas tanpa uang) (A F-03/B F-02) | K-2 | **DITUTUP 2026-09-17** | penjaga perpindahan status per peran; `lunas`/`batal` hanya peladen; tanda kirim ke dapur tak bisa dihapus — `supabase/tes/status_pesanan.sql` |
| Penjaga stok dilewati dengan peubah sesi klien (A F-06) | K-2 | **DITUTUP 2026-09-17** | penjaga memakai bukti peladen yang tak bisa dipalsukan klien (`peran_peladen()`), penanda sesi dibuang — `supabase/tes/penjaga_stok.sql` |
| Lapis kedua pembatasan PIN memakai nama perangkat kiriman klien (B F-11) | K-3 | **TERBUKA (dipagari)** | **Tingkat dikoreksi K-2 → K-3** (mengikuti laporan B §F-11; lapis akun terbukti bekerja). Yang bisa dikerjakan sekarang sudah: batas akun dikunci uji regresi `supabase/tes/percobaan_pin_perangkat.sql` (2 uji mutasi memerah: batas akun dimatikan · lapis perangkat dihapus). Perbaikan sebenarnya butuh `perangkat_id` terverifikasi → T1-24 (Fase 1B) yang **wajib** memperketat uji itu (tertulis di DoD/Verifikasi T1-24) dan menutup baris ini dengan bukti ujinya. Catatan: butir ini **sengaja TIDAK** masuk `docs/TERTANGGUH.md` — TERTANGGUH untuk hal yang menunggu jawaban/keputusan, sedangkan ini pekerjaan terjadwal (siapa pun bisa menutupnya dengan bukti) |
| Kontrol wajib `docs/KEAMANAN.md` belum ada di kode (A F-07) | K-2 | **TERBUKA (sebagian mendarat)** | Fase 1B. **Kemajuan 2026-09-17:** T1-23 selesai — satu akun satu peran (migrasi 0011, `pengguna_cabang.peran` dibongkar) + PIN 6 angka, bukan pola lemah, **unik** antar pegawai, dengan pembatas anti-oracle; sisa kontrol (perangkat terdaftar, sesi, TOTP, matriks izin, percobaan masuk) masih T1-24…T1-30 |
| Kertas kerja K-3/K-4 (rujukan mati, `npm audit`, uji batas, dll.) | K-3/K-4 | **TERBUKA** | dikelola lewat `docs/TERTANGGUH.md` pada batch K-2 |

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
| 9 | **Dua sesi auditor memakai nama berkas yang sama → laporan pertama tertimpa.** Bukti: `--ambil-laporan` menyimpan laporan sesi `01a0aeb0` sebagai `…menyeluruh.sebelumnya.md` lalu menimpa nama utamanya dengan laporan sesi `01a0aeb4` | Ditemukan sendiri saat menarik laporan ronde AUD-3 (dua laporan berbeda isi, nama sama) | Nama bentrok kini disimpan **terpisah** menjadi `<nama>.dari-<cabang>.md` (tidak pernah menimpa); `--uji-diri` menguji kasus dua sesi bernama sama; prompt meminta penanda sesi di nama berkas |
| 10 | **Pemeriksa menolak laporan yang SAH**: (a) mewajibkan bagian 8 padahal kontrak §8 belum ada di commit yang diaudit; (b) memakai `git status` meja kerja sesi kerja — sehingga draf kerja sesi itu sendiri (atau berkas laporan yang baru ditarik) membuat laporan auditor ditolak | Kedua laporan ronde AUD-3 ditolak palsu pada percobaan pertama | (a) syarat §8 kini **sadar-versi** (dicek dari commit target) → jadi CATATAN bila kontrak lama; (b) cek kebersihan kini memakai **bukti dari cabang auditor** (hanya menambah berkas laporan) yang tidak bisa dikotori sesi kerja; fallback `git status` mengabaikan folder saluran laporan |
| 12 | **Dua sesi bisa berbagi SATU cabang `arena/*` dan memakai nama berkas yang sama → laporan pertama hanya hidup di riwayat commit** (versi kedua menimpa nama berkasnya). Bukti: cabang `arena/01a0aeb0` punya dua commit laporan (`9e9dbb6` lalu `b4b3e78`) dengan isi berbeda | Ditemukan dari laporan pemilik bahwa 3 sesi dibuka berbarengan sementara hanya 2 cabang muncul; ditelusuri `git log --name-only` di cabang itu | `--ambil-laporan` (kedua alat) kini menelusuri **seluruh riwayat** berkas laporan di tiap cabang dan menyelamatkan versi tertimpa sebagai `<nama>.dari-<cabang>-<commit8>.md`; tarik ulang tetap idempoten; `--uji-diri` menguji kasus ini (3 laporan dari 2 cabang) |
| 11 | **Kunci jawaban kalibrasi jalur auditor hidup di `/tmp`** → hilang saat ruang kerja direset, sehingga kalibrasi ronde berikutnya tidak bisa dinilai dengan kunci aslinya | Reset platform 2026-09-17 (kunci `/tmp/KUNCI-KALIBRASI-bahan-*.md` tidak ada lagi) | Kunci dibangun ulang **dari bahan itu sendiri** (bukan dari laporan auditor), disimpan di luar repo, dan risikonya dicatat jujur di riwayat ini. Aturan tetap: kunci tidak boleh masuk repo selama ronde berjalan |
| 8 | **Bahan kalibrasi review PR membocorkan dirinya sendiri**: diff bahan ikut membawa komentar penanda `-- SENGAJA (kalibrasi)` pada baris yang diubah, sehingga peninjau cukup mencari kata "SENGAJA" untuk menemukan semua cacat → kalibrasi tidak berarti | Ditemukan sendiri saat memeriksa isi diff sebelum diserahkan (grep "SENGAJA" di bahan) | `alat/review-pr.py --kalibrasi-pr-siapkan` kini **membuang** penanda & komentar pembocor dari diff (dan menghapus baris yang isinya hanya penanda); diuji ulang: 0 kemunculan "SENGAJA" di bahan |




## 5. Uji-diri mekanisme (wajib hijau sebelum mekanisme dianggap terpasang)

Perintah: `python3 alat/audit-independen.py --uji-diri`

- `laporan-bagus.md` → **LOLOS** (7 artefak, 5 klaim, 5 serangan, 1 temuan K-3)
- `laporan-malas.md` → **DITOLAK** (12 alasan: kepala/bagian hilang, bukti kosong, cakupan & serangan kurang, bagian 6 kosong)
- `laporan-palsu-bersih.md` → **DITOLAK** (verdict BERSIH padahal ada temuan K-1 TERVERIFIKASI)
- `laporan-tanpa-kalibrasi.md` → **DITOLAK** (AUD-3 tanpa angka kalibrasi)
- `kalibrasi-penuh.md` → **TERKALIBRASI** · `kalibrasi-sebagian.md` → **BELUM TERKALIBRASI** (67% < 70%)
