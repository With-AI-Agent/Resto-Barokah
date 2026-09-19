# AUDIT_RIWAYAT.md — Riwayat Audit Independen & Kalibrasi

> Angka paling penting di berkas ini bukan "berapa temuan", melainkan **berapa cacat yang lolos ke produksi**
> (escaped defects) dan **berapa tingkat deteksi auditor** pada kalibrasi. Keduanya diukur, bukan diklaim.

## 1. Riwayat audit

| # | Tanggal | Tingkat | Lingkup | Auditor | Commit | Temuan K-1 | K-2 | K-3 | K-4 | Tingkat deteksi kalibrasi | Verdict | Catatan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A | 2026-09-17 | AUD-3 | menyeluruh (334/334 berkas) | sesi `arena/01a0aeb0` (Arena.ai Agent Mode, sesi terpisah) | `442913e` | 1 | 6 | 3 | 0 | 5/5 (100%), 0 temuan palsu | TIDAK-BERSIH | 10 temuan (F-01…F-10). Laporan **LOLOS KONTRAK**. |
| B | 2026-09-17 | AUD-3 | menyeluruh (334/334 berkas) | sesi `arena/01a0aeb4` (Arena.ai Agent Mode, sesi terpisah) | `442913e` | 2 | 7 | 8 | 0 | 5/5 (100%), 0 temuan palsu | TIDAK-BERSIH | 17 temuan (F-01…F-17). Laporan **LOLOS KONTRAK**. |
| C | 2026-09-17 | AUD-3 | 23 dari 334 berkas (7%) | sesi `arena/01a0aeb0` (versi tertimpa, diselamatkan dari commit `9e9dbb6`) | `253d129` (repo basi) | 0 | 3 | 4 | 0 | 0/0 (bahan kalibrasi tidak ada di sesinya) | TIDAK-BERSIH | **DITOLAK** — sesinya tidak menerima paket & commit target (repo yang terbuka masih template), jadi laporan ini **tidak sah untuk putusan**; tetap diarsipkan sebagai bukti (versi tertimpa). |
| D | 2026-09-19 | AUD-3 | menyeluruh (436/436 berkas) | sesi `arena/01a0b85b` (Arena.ai Agent Mode, sesi terpisah) | `93a50ba` | 0 | 2 | 5 | 3 | 11/11 (100%), 0 temuan palsu | TIDAK-BERSIH | 10 temuan (F-01…F-10) + 4 luar cakupan. **DITOLAK MESIN** karena kelengkapan format (4 label grup cakupan diparafrase dari paket + cabang laporan memuat 2 laporan); isinya tetap dipakai setelah **10/10 temuan dibantah-balik = NYATA** oleh sesi kerja (probe sendiri). |
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

> **Aturan (dijaga mesin oleh `alat/periksa-temuan-audit.py`):** laporan A punya 10 temuan, laporan B punya 17.
> **Setiap** temuan wajib punya baris sendiri di sini. Baris `DITUTUP` wajib menunjuk bukti yang benar-benar ada
> di repo; baris `TERBUKA` wajib menunjuk tugas ROADMAP yang benar-benar ada — temuan tanpa bukti/pemilik
> adalah temuan yang akan terlupakan. Dulu tabel ini memakai satu baris gelondongan ("kertas kerja K-3/K-4")
> dan beberapa temuan tidak punya status; itu cacat ketertelusuran yang diperbaiki 2026-09-17.

| Laporan | Tingkat | Temuan (ringkas) | Status | Bukti penutup / pemilik penyelesaian |
|---|---|---|---|---|
| A F-04 · B F-03 · A F-10 | K-1/K-2 | Uang lebih bayar diterima saat total pesanan masih 0 (uji batas lama hanya untuk total > 0) | **DITUTUP 2026-09-17** | `supabase/tes/gerbang_uang.sql` (merah sebelum, hijau sesudah) · `docs/uji/audit/bukti-verifikasi-2026-09-17.sql` |
| B F-04 | K-1 | `total_dibayar(uuid)` bocor lintas resto | **DITUTUP 2026-09-17** | `supabase/tes/isolasi_lintas_penyewa.sql` (dulu mengembalikan 777.000 ke kasir resto lain, kini 0) |
| B F-05 | K-1 | `izin_efektif_untuk()` / `boleh_untuk()` bocor lintas resto | **DITUTUP 2026-09-17** | pintu klien ditutup + saringan penyewa di dalam fungsi — `supabase/tes/isolasi_lintas_penyewa.sql` |
| B F-01 | K-1 | Status pesanan bisa dipindah klien: "lunas" tanpa uang, "batal" tanpa jejak | **DITUTUP 2026-09-17** | penjaga perpindahan status per peran; `lunas`/`batal` hanya peladen — `supabase/tes/status_pesanan.sql` |
| B F-02 · A F-03 | K-1/K-2 | Void sesudah dapur lolos dengan penyetuju karangan (PIN tidak pernah diverifikasi) | **DITUTUP 2026-09-17** | persetujuan wajib TERBUKTI (PIN benar untuk aksi itu, jendela 5 menit, tercatat) — `supabase/tes/persetujuan_void.sql` |
| A F-01 · B F-07 | K-2 | PIN sendiri bisa diganti tanpa PIN lama → persetujuan bisa dipalsukan | **DITUTUP 2026-09-17** | `supabase/tes/kredensial_pin.sql` — penggantian PIN sendiri wajib PIN lama, termasuk saat uuid diri sendiri disebut |
| A F-02 · B F-10 | K-2/K-3 | `pin_hash` bisa dibaca klien (diri sendiri & seluruh pegawai oleh admin/owner) | **DITUTUP 2026-09-17** | rahasia pindah ke `kredensial_pin` (hak klien dicabut, policy menolak semua) — `supabase/tes/kredensial_pin.sql` · `supabase/tes/rls_semua_tabel.sql` |
| A F-05 | K-2 | Identitas pelaku/penyetuju di tiga tabel bisa dipalsukan klien | **DITUTUP 2026-09-17** | pelaku diisi sistem (`auth.uid()`) — `supabase/tes/jejak_pelaku.sql` |
| B F-06 | K-2 | Batas **persen** diskon dilewati dengan mengosongkan kolom `persen` | **DITUTUP 2026-09-17** | persen efektif dihitung dari uang — `supabase/tes/diskon_persen.sql` |
| A F-06 | K-2 | Penjaga stok bisa dilewati dengan peubah sesi klien | **DITUTUP 2026-09-17** | bukti peladen `peran_peladen()` — `supabase/tes/penjaga_stok.sql` |
| A F-07 | K-2 | Kontrol wajib `docs/KEAMANAN.md` belum ada di kode | **TERBUKA (sebagian mendarat)** | T1-23 mendarat 2026-09-17 (`supabase/migrations/0011_peran_tunggal.sql`); sisa kontrol dijadwalkan `T1-24`, `T1-25`, `T1-26`, `T1-27`, `T1-28`, `T1-29`, `T1-30` |
| A F-08 · B F-08 | K-2/K-3 | Rujukan mati di dokumen pengikat — Buku Insiden menyuruh memakai alat yang tidak ada | **DITUTUP 2026-09-17** | 3 rujukan mati diperbaiki di dokumen pengikat (Buku Insiden: alat denyut & berkas catatan pemulihan; KEAMANAN: pemeriksa rantai audit) — kini ditandai rencana + tugasnya, dan dijaga penjaga baru `alat/periksa-rujukan.py` (mode `--uji-diri`) |
| A F-09 | K-3 | 5 kerentanan dependency dev & CI tidak memeriksanya | **DITUTUP 2026-09-17** | `aplikasi/package.json` (vitest 5) + langkah `npm audit` di `.github/workflows/ci.yml` · `npm audit` → 0 kerentanan |
| B F-09 | K-2 | Paket audit ter-commit menunjuk commit lain → `--verifikasi-lingkup` menyuruh auditor berhenti padahal commit-nya benar | **TERBUKA** | perketat mekanisme paket (lingkup dari commit target + CI wajib hijau) → `T1-44` |
| B F-11 | K-3 | Lapis kedua pembatasan PIN memakai nama perangkat kiriman klien | **TERBUKA (dipagari)** | dipagari `supabase/tes/percobaan_pin_perangkat.sql`; perbaikan asli butuh perangkat terdaftar → `T1-24` |
| B F-12 | K-3 | Penjaga buku induk: ambang longgar (10 dari 12 alur) & tidak punya uji-diri | **DITUTUP 2026-09-17** | `alat/periksa-panduan.py` (`MIN_ALUR = 12` + mode `--uji-diri` 3 mutasi) + langkah di `.github/workflows/ci.yml` |
| B F-13 | K-3 | Klaim bukti T0-01 "31 berkas huruf pindah" tidak bisa direproduksi | **DITUTUP 2026-09-17** | klaim dicabut & diganti angka terhitung + perintah hitungnya di `docs/ROADMAP.md`. **Tindak lanjut (review RV-2 putaran8, temuan PR-08/PR-02):** penggantinya (angka 57) ternyata **juga tidak cocok** dengan perintah yang dikutip → dikoreksi lagi jadi **19** (perintah hitungnya ditulis di `docs/ROADMAP.md`) dan sekarang **dijaga otomatis** oleh `aplikasi/alat/periksa-struktur.py`, supaya kelas cacat "angka bukti basi" tidak terulang |
| B F-14 | K-3 | Sapuan isolasi lintas resto hanya tabel ber-`penyewa_id` + pencocokan teks policy | **TERBUKA** | perkuat sapuan di `T1-22` (dasar: `supabase/tes/rls_semua_tabel.sql`) |
| B F-15 | K-3 | `docs/SPESIFIKASI_UI.md` menyebut pemeriksa `alat/peta-ui.py` di CI padahal berkas & langkah CI belum ada | **DITUTUP (klaim dikoreksi) 2026-09-17** | `docs/SPESIFIKASI_UI.md` §5 kini menandai alat itu sebagai rencana Fase 1C (`T1-33`); pembuatan alatnya sendiri tetap tugas `T1-33` |
| B F-16 | K-4 | Tabel lingkup paket audit tidak menutup berkasnya sendiri (333/334) & satu grup angkanya meleset | **TERBUKA** | perketat mekanisme paket (hitungan mesin + berkas paket sendiri) → `T1-44` |
| B F-17 | K-3 | Commit yang diaudit tidak pernah dilewatkan CI — tidak ada satu pun run untuknya | **TERBUKA** | wajibkan & periksa CI hijau sebelum paket audit dibuat → `T1-44` |
| D F-01 | K-2 | Diskon masih bisa dicatat pada pesanan `lunas`/`batal` → total pesanan berubah SETELAH uang tercatat | **TERBUKA** | pemicu diskon wajib memeriksa status pesanan → `T1-45` |
| D F-02 | K-3 | Edge Function `verifikasi_pin` tidak bisa meneruskan `p_pesanan_id` → kupon persetujuan mustahil dipakai lewat jalur Edge (jalur void buntu) | **TERBUKA** | Edge meneruskan `pesanan_id` + uji ujung-ke-ujung → `T1-45` |
| D F-03 | K-3 | Generator paket audit menghasilkan baris "berkasnya TIDAK ADA: laporkan!" yang PALSU (perintah backtick dianggap jalur) → memancing temuan palsu | **TERBUKA** | saring perintah dari jalur + uji-diri kasus perintah → `T1-45` |
| D F-04 | K-3 | Commit yang diaudit (`93a50ba`) tidak pernah lolos CI — kedua check-run `cancelled` | **TERBUKA** | paket hanya boleh menargetkan commit ber-CI hijau → `T1-44` |
| D F-05 | K-2 | Kunci jawaban kalibrasi cacat tanaman tertanam DI DALAM repo (`docs/uji/kalibrasi/pr-bahan-2026-09-17.diff`) | **TERBUKA** | keluarkan kunci dari repo + aturan bahan segar → `T1-45` |
| D F-06 | K-3 | `hitung_total` & penomoran sudah hidup di 0014 tetapi T1-15/T1-17 masih `[ ]` tanpa catatan silang → risiko rumus kedua | **TERBUKA** | catatan silang di ROADMAP + berkas yang dijanjikan → `T1-45` |
| D F-07 | K-3 | Handoff `docs/ops/SIAP-LANJUT.md` basi & menunjuk cabang lain pada commit audit | **DITUTUP 2026-09-19** | penjaga baru `alat/lanjut-sesi.py` (menolak handoff yang cabangnya tidak memuat keadaan kerja) + handoff disegarkan — `docs/ops/SIAP-LANJUT.md` |
| D F-08 | K-4 | `nomor_pesanan_berikutnya` = `max(nomor)+1` tanpa penguncian → dua kasir bisa bertabrakan | **TERBUKA** | advisory lock per (cabang, tanggal) + uji → `T1-45` |
| D F-09 | K-4 | Uji negatif dominan bentuk lemah: 150 `uji.harap_gagal` vs 10 `uji.harap_gagal_sebab` | **TERBUKA** | pemeriksa menandai berkas uang + migrasi bertahap → `T1-45` |
| D F-10 | K-4 | Pesan penolakan diskon menunjuk alur yang tidak ada ("Minta persetujuan atasan (PIN)" padahal kupon tidak menaikkan batas pemanggil) | **TERBUKA** | pesan diperbaiki / jalur disambungkan → `T1-45` |

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

## 2026-09-19 — putaran verifikasi: 25 temuan NYATA dari 2 peninjau, 0 palsu

| # | Peristiwa | Bukti |
|---|---|---|
| 1 | Lee menjalankan **2 sesi peninjau** (satu chat, cabang `arena/01a0b85b`): AUD-3 menyeluruh + review PR putaran16. Kedua laporan diambil mesin: `python3 alat/audit-independen.py --ambil-laporan` & `python3 alat/review-pr.py --ambil-laporan`. | `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0b85b.md` · `docs/uji/review-pr/LAPORAN_2026-09-19_pr-01-putaran16__01a0b85b.md` |
| 2 | **Laporan review LOLOS KONTRAK** (verdict TIDAK-BERSIH · K-1 1 · K-2 3 · K-3 7 · luar cakupan 6 · kalibrasi 4/4 hunk + 11 kandidat, 0 palsu). **Laporan audit DITOLAK MESIN** karena kelengkapan format (4 label grup cakupan diparafrase dari paket + cabang memuat 2 laporan) — isinya tetap dipakai setelah diverifikasi ulang manual, dan auditor diminta memperbaiki format pada sesi yang sama. | `python3 alat/review-pr.py --periksa-laporan …` → LOLOS · `python3 alat/audit-independen.py --periksa-laporan …` → DITOLAK (5 alasan) |
| 3 | **Setiap temuan dibantah-balik dengan probe sendiri** (aturan tetap): 10 temuan audit + 15 temuan review = **25/25 NYATA, 0 palsu**. Probe ditulis ulang dari nol di `/tmp/probe-*.sql` (bukan menyalin probe laporan) dan dijalankan dengan `node alat/uji-sql.mjs <berkas>` di pohon kerja. | probe `docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql` … `docs/uji/audit/probe-2026-09-19/audit-f01-diskon-sesudah-lunas.sql` (12 berkas) — semuanya LULUS sesuai dugaan temuan |
| 4 | Temuan terberat **K-1** (review PR-01): penanda transaksi `resto.pembatalan_*` bisa dipalsukan kasir (`set_config`) → item SESUDAH dapur dibatalkan **tanpa PIN & tanpa baris jejak**; kontrol (tanpa penanda) tetap DITOLAK. Dibuktikan di PostgreSQL asli dalam Node. | probe `docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql` → LULUS |
| 5 | Temuan uang K-2 lain juga terbukti: diskon pada pesanan `lunas` mengubah total (`docs/uji/audit/probe-2026-09-19/audit-f01-diskon-sesudah-lunas.sql`) · void SATU item membatalkan SELURUH pesanan & pembayaran sisa ditolak (`docs/uji/audit/probe-2026-09-19/pr02-void-satu-item.sql`) · kasir resto B membaca hitungan pesanan resto A (`docs/uji/audit/probe-2026-09-19/pr03-bocor-nomor.sql`) · jawaban kembar `simpan_pin` memastikan PIN aktif kolega (`docs/uji/audit/probe-2026-09-19/pr04-oracle-pin.sql`). | keempat probe LULUS |
| 6 | Cacat mekanisme yang tertangkap: **gerbang CI gagal-terbuka** (langkah keamanan boleh dihapus & `if: false` tak terlihat oleh `alat/periksa-gerbang-ci.py` — direproduksi sendiri di salinan `/tmp/gc`), **kunci kalibrasi di dalam repo**, **generator paket audit memancing temuan palsu** (paket 2026-09-19 memuat 10 baris "TIDAK ADA: laporkan!" palsu), **label gema `12/12` padahal nyata `16/16``, dan **1 klaim luar-cakupan tidak dapat direproduksi** (`--siapkan` exit 0 saat GAGAL → diuji ulang: exit **1**, berkas tidak ditulis). | `/tmp/gc` · `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` · `docs/uji/paket-audit/AUD-3-2026-09-19.md` (baris 260–293) · `aplikasi/alat/periksa-semua.sh:38` · uji ulang `--lanjut-dari arena/cabang-hantu` → EXIT=1 |
| 7 | Seluruh temuan NYATA dimiliki satu tugas penutup **T1-45** (migrasi `0015` + penjaga alat); yang sudah tertutup lebih dulu (D F-07) dicatat DITUTUP dengan bukti hidup. | `docs/ROADMAP.md` (T1-45) · `docs/uji/REVIEW_PR_RIWAYAT.md` §1b |

## 2026-09-18 — AUD-3 putaran ini: 15 temuan NYATA, ditutup `0014`

| # | Peristiwa | Bukti |
|---|---|---|
| 1 | 4 sesi independen dijalankan Lee (2 review PR + 2 audit AUD-3). Laporan yang tertimpa **diselamatkan** lebih dulu lewat `python3 alat/audit-independen.py --ambil-laporan` — dan memang ada yang tertimpa (satu laporan sesi lain hidup hanya di riwayat commit). | 7 berkas laporan di `docs/uji/audit/` & `docs/uji/review-pr/`, semuanya ter-commit |
| 2 | Setiap temuan **dibantah-balik lebih dulu dengan probe sendiri** (bukan dipercaya dari kalimat laporan): 12 temuan review + 15 temuan audit dinyatakan NYATA; sisanya dijelaskan. | probe `/tmp/probe2/*.sql` (uang, dapur/item, batal, PIN, jejak, baris tersentuh) |
| 3 | Seluruh temuan ditutup migrasi `supabase/migrations/0014_penutup_celah_putaran13.sql` + 10 berkas uji baru; 6 berkas uji lama diselaraskan (nomor pesanan kini selalu dari sistem, dsb.). | `node alat/uji-sql.mjs` → 41 LULUS · 0 GAGAL |
| 4 | Bukti pagar: 17 mutasi khusus 0014 + 16 mutasi pagar lama, semuanya WAJIB MERAH; penjaga berlapis dibuktikan lewat mutasi GABUNGAN (M3k/M5k/M8k). | `python3 alat/uji-mutasi-0014.py` → 17/17 · `python3 alat/uji-mutasi-0012.py` → 16/16 |
| 5 | Dua cacat **alat audit itu sendiri** yang ditemukan di putaran ini ditutup: paket bisa menargetkan commit yang bukan induknya (F-11) dan bagian 1 paket memuat jalur berkas yang belum ada (F-12/F-13). Penjaganya: `alat/periksa-paket.py` (ikut CI, punya `--uji-diri`). | `python3 alat/periksa-paket.py --uji-diri` LOLOS; paket lama dikecualikan eksplisit (T-019) |
| 6 | Dua cacat akibat suntingan dokumen tertangkap **CI, bukan gerbang lokal** (field wajib `STATUS.md` berubah; T-019 tidak ditandai dari ROADMAP). Keduanya diperbaiki, lalu CI hijau pada push & PR. | run push `35325266036` SUCCESS · PR `35325269977` SUCCESS |
| 7 | Langkah uji SQL di CI kini menulis ringkasan hasil ke halaman Summary job. | sebabnya nyata: pada satu percobaan, langkah itu merah **dan log mentah GitHub tidak bisa dibaca** dari lingkungan kerja; ringkasan bisa dibaca lewat API |
