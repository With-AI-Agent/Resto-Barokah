# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang yang dilanjutkan:** `arena/01a0b7d1-resto-barokah`
- **Dasar pilihan cabang:** pilihan Lee yang tersimpan di handoff sebelumnya
- **Ditulis oleh sesi:** `arena/01a0b7d1-resto-barokah`
- **Commit keadaan kerja:** `8bb0c3b699e3ab292290b51f3ab55eeeb63f3c95`
- **PR:** PR #2 (base main)
PR #1 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** success (run 35441490803, commit 8bb0c3b6)
- **Ditulis:** 2026-09-19 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)
- **Berkas yang Lee salin ke chat baru:** `PROMPT_SESI_BARU.md` (STATIS — mesin memeriksanya, bukan
  menulisnya ulang tiap batch; Lee hanya mengisi baris pertama `SESI YANG AKU LANJUT`)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **6** — T-002, T-003, T-010, T-011, T-015, T-016
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)
- **Paket peninjau terbaru:** audit `AUD-3-2026-09-19.md` → `93a50bac` (36 commit di bawah HEAD saat ini) · review `PKT-2026-09-19-pr-01-putaran16.md` → `93a50bac` (36 commit di bawah HEAD saat ini) — segarkan paket SEBELUM meminta peninjau bekerja bila
  jaraknya jauh: `python3 alat/audit-independen.py --paket AUD-3 --semua` ·
  `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN`
- **Ruang kerja baru:** `aplikasi/node_modules` & `alat/node_modules` TIDAK ikut tersimpan di snapshot.
  Sebelum pratinjau/uji aplikasi: `bash aplikasi/alat/pratinjau.sh` (±1–2 menit). Uji SQL & pemeriksa
  Python tetap berjalan tanpa pemasangan itu.

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0b7d1-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Cabang `arena/01a0b7d1-resto-barokah` di atas adalah **pilihan Lee** (bukan tebakan mesin). Lee juga bebas memilih sesi
LAIN: saat membuka chat baru, ia menulis pilihannya di baris pertama `PROMPT_SESI_BARU.md` — dan baris
itu yang **MENANG** bila berbeda dengan handoff ini. Laporkan bedanya, lalu rapikan catatan handoff
dengan `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>`. Sesi yang belum pernah di-push
tidak bisa dilanjutkan; sesi yang sengaja ditinggalkan ada di `docs/ops/SESI_DITINGGALKAN.md`.

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 2c. Fakta cabang sesi baru: PR #1 TIDAK otomatis memuat pekerjaanmu

Kamu bekerja di cabang sesi barumu sendiri (dibuat platform; hanya ke cabang itu kamu boleh push).
PR #1 menunjuk cabang sesi SEBELUMNYA, jadi commit barumu tidak muncul di PR itu.
Bila Lee ingin meninjau lewat PR: buka PR BARU dari cabangmu (base `main`) dan laporkan tautannya.
JANGAN merge apa pun tanpa keputusan Lee.

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18g (2026-09-19) — MARATON T1-45: K-2a + K-2b DITUTUP.**

Dua temuan K-2 tuntas, keduanya di **bagian 2–3** `supabase/migrations/0015_penutup_celah_putaran16.sql`:

* **PR-02 — void satu item tidak lagi membatalkan seluruh pesanan.** Pemicu resmi
  `picu_pembatalan_jejak` sekarang menutup pesanan (`status = 'batal'`) **hanya** bila tidak ada item hidup
  tersisa atau pembatalannya memang tingkat pesanan; pesanan yang ditutup menandai **seluruh** itemnya batal
  (tidak ada lagi keadaan setengah jalan). Akibatnya pembayaran sisa tidak lagi buntu — uji
  `supabase/tes/void_satu_item.sql` (termasuk membayar item yang masih hidup, dan pesanan yang memang batal).
* **Audit D F-01 — diskon tidak bisa lagi ditanam sesudah uang tercatat.** Pemicu baru `diskon_awal_pesanan`
  menolak tambah/ubah/hapus baris diskon pada pesanan `lunas`/`batal`; jalur sahnya pembatalan/void resmi. Nama
  pemicu sengaja berjalan **sebelum** pemicu nilai `diskon_batas` (abjad nama) supaya penolakan berbunyi tentang
  status, dan urutan itu ikut dikunci mutasi — uji `supabase/tes/diskon_sesudah_lunas.sql`.

**Bukti mesin:** suite SQL **44 berkas LULUS · 0 GAGAL** (`node alat/uji-sql.mjs`); `python3 alat/uji-mutasi-0015.py`
**11 kasus — 10 mutasi wajib MERAH semuanya terbukti merah**, 1 kasus memang diharapkan hijau; keputusan dikunci di
`docs/DECISIONS_LOG.md` `[Uang/2026-09-19]`. Sisa temuan **18** (16 `T1-45`, 2 `T1-44`).

**Langkah berikutnya (urut) — lanjut maraton, sisa `T1-45`:**
1. **K-2 (sisa 2):** kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03, sekaligus tabrakan nomor
   antar-kasir) · oracle PIN kembar (PR-04).
2. **K-3 (7):** PR-05 pra-dapur tanpa izin/jejak · PR-06 jejak hierarki ikut rollback · PR-07 kupon tanpa ikatan
   pesanan (jalur Edge buntu) · PR-08 saldo awal stok tanpa baris buku · PR-09 PIN warisan 4 angka buntu ·
   PR-13 `KEAMANAN.md` menunjuk tabel hantu · PR-14 hak `service_role`/`peringkat_peran`.
3. **K-4 (5):** PR-15 hapus meja memutus riwayat · D F-04 & PR-11 + sisa temuan audit ringan (pemilik `T1-44`).
4. Fase 1B: `T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+.

**PUTARAN 18f (2026-09-19) — MARATON T1-45: K-1 (PR-01) DITUTUP.**

Temuan **paling berbahaya** tuntas. Sebelumnya kasir bisa memalsukan penanda transaksi
(`set_config('resto.pembatalan_pesanan', …)`) lalu membatalkan item sesudah dapur **tanpa PIN atasan & tanpa satu pun
baris jejak**. Perbaikan ada di **migrasi baru** `supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 1**:
penanda transaksi tidak lagi diakui di mana pun; pembatalan item setelah dapur hanya sah lewat baris `pembatalan`
resmi (0013: tahap + PIN + kupon sekali pakai), dan pemicu resmi berhenti menulis penanda itu.

**Bukti:** uji regresi `supabase/tes/pembatalan_penanda_palsu.sql` (4 serangan dari kursi kasir, semuanya ditolak;
keadaan data tidak berubah) + `alat/uji-mutasi-0015.py` — **6 mutasi**, termasuk "kembalikan versi lama yang bocor",
"lepas pemicunya", "beri pengecualian diam-diam untuk peran kasir" → semuanya **MERAH** (terbukti), kontrol hijau.
Masuk CI sebagai **gerbang ke-52** (uji + bukti mutasi). Suite SQL kini **42 berkas LULUS · 0 GAGAL**. Keputusan
dikunci di `DECISIONS_LOG.md` `[Keamanan uang/2026-09-19]`.

**Langkah berikutnya (urut) — lanjut maraton:**
1. **K-2 (sisa 4)** — diskon pada pesanan `lunas`/`batal` (audit D F-01) · void satu item ikut membatalkan seluruh
   pesanan (PR-02) · kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03) · oracle PIN kembar (PR-04).
   Ditulis sebagai **bagian 2…5 dalam `0015_penutup_celah_putaran16.sql`** + uji regresi + mutasi baru di
   `alat/uji-mutasi-0015.py`.
2. K-3/K-4 (16 temuan tersisa), lalu Fase 1B (`T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+).
 (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18e (2026-09-19) — FASE 0 TUNTAS: HALAMAN PUBLIK NAIK; MARATON T1-45 DIMULAI.**

Lee menulis **"Boleh naik"** (izin publik — Stop Condition, jadi wajib menunggu). Agent memicu penanda
`aplikasi/SEBAR-HALAMAN`: run `35440300274` hijau (unggahan pertama), lalu `35440432817` hijau (unggahan ulang +
**pencatatan alamat otomatis**). Alamat publik: **https://resto-barokah.fatrizmubarok.workers.dev** — **HTTP 200**.
Bukti dibaca dari **anotasi** (`ALAMAT-PUBLIK`) karena log job GitHub tidak bisa dibaca dari lingkungan agent;
alat baru `aplikasi/alat/catat-alamat.mjs` (+`--uji-diri` 6 kasus) menjadi **gerbang CI ke-51** dan membuat
"hijau" berarti halaman benar-benar menjawab. Alamat & cara mundur dicatat di `docs/ops/ALAMAT_PUBLIK.md`;
`T0-09` DITUTUP, `T-021` SELESAI (terbuka kini **6**).

**Penjaga batas mode bimbingan diperkuat (permintaan Lee):** `alat/periksa-panduan.py` kini memeriksa blok
AL-14 **dan** §14 `AGENT_OPERATING_GUIDE.md`; mutasi yang menghapus batas (2 kasus baru) WAJIB ditolak.

**Langkah berikutnya (urut) — MARATON:**
1. **T1-45 K-1** (paling berbahaya): penanda `resto.pembatalan_*` bisa dipalsukan kasir → void sesudah dapur tanpa
   PIN & tanpa jejak. Ditulis sebagai migrasi BARU `supabase/migrations/0015_penutup_celah_putaran16.sql`
   (+ uji regresi di `supabase/tes/`, + `alat/uji-mutasi-0015.py` semua mutasi WAJIB MERAH).
2. Lanjut K-2 (diskon pada lunas/batal · void satu item · kebocoran nomor lintas resto · oracle PIN) → K-3/K-4.
3. Setelah T1-45: Fase 1B (T1-24/25/26) memakai nomor migrasi `0015`+ sesuai catatan; lalu T1-37 (B.4–B.9).
 (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18d (2026-09-19) — PEMERIKSAAN PRA-MARATON (permintaan Lee) SELESAI.**

Diperiksa ulang semua yang bisa terlupakan: butir tunggu (**7 terbuka**), daftar temuan (audit §1b + review PR),
rencana pekerjaan ulang (`docs/uji/DAFTAR_PEKERJAAN_ULANG.md`), dan angka-angka di dokumen. Hasil:

1. **PR-12 DITUTUP** — label `12/12` basi di `aplikasi/alat/periksa-semua.sh` diganti label tanpa angka (angka benar
   selalu datang dari ringkasan alat).
2. **Angka sisa temuan dibetulkan: 23 → 21 terbuka** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`). Sebelumnya
   dokumen menulis 23 padahal F-05/F-07/PR-10 sudah ditutup lebih dulu — kelas cacat F-14.
3. **Bentrok penomoran ditemukan & dibereskan:** `T1-24`/`T1-25`/`T1-26` masih merencanakan migrasi `0012`–`0014`
   yang kini terpakai & **beku** → diberi catatan wajib memakai nomor baru `0015`–`0017`.
4. **Tidak ada temuan tanpa pemilik** dan tidak ada pekerjaan setengah jalan yang tersembunyi.

**Langkah berikutnya (urut):**
1. **`T-021` halaman publik** — tinggal izin Lee (`Boleh naik`); rahasia Cloudflare sudah dipasang.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`) — mulai K-1, ditulis sebagai migrasi BARU `0015_…` dst.
3. **Fase 1B (T1-24/25/26)** — setelah temuan tuntas, memakai nomor migrasi `0015`+ sesuai catatan baru.
 (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (lanjutan) — MODE BIMBINGAN DITANAM + LANGKAH B LEE SELESAI.**

Lee menyelesaikan **Langkah B** (rahasia `CLOUDFLARE_API_TOKEN` dipasang) dan meminta dua hal: (a) bimbingan singkat
saat ia memegang layar, (b) mekanismenya **ditanam** di sistem. Hasilnya: alur **AL-14** (`PANDUAN_PENGGUNA.md`,
8 bidang lengkap) + **§14** (`docs/AGENT_OPERATING_GUIDE.md`) + baris `PROFIL_PENGGUNA.md` + rekam pesan §16.
Pemicu: `Tolong bimbing.` · `Mode bimbingan.` · `Beri arahan step by step.` · `Aku bingung, pandu aku.`
Penutup: `Sudah beres, lanjut normal.` Penjaga `alat/periksa-panduan.py`: **MIN_ALUR 13 → 14** + topik wajib
"mode bimbingan". **Batas yang disampaikan ke Lee:** mode ini hanya memendekkan cara bicara — Stop Conditions §12
(biaya, keamanan/uang/data, keputusan terkunci, deploy publik) dan klaim "selesai" tetap butuh bukti diperiksa dulu.

**Langkah berikutnya (urut):**
1. **`T-021` (halaman publik)** — tinggal **izin publik** dari Lee (`Boleh naik`). Begitu dikatakan: buat penanda
   `aplikasi/SEBAR-HALAMAN` → alur mengunggah → catat alamat `*.workers.dev` + pemeriksaan HTTPS → hapus penanda.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`) — K-1…K-4 dalam bentuk migrasi **BARU** `0015_penutup_celah_putaran16.sql`
   (berkas `0001`–`0014` beku; penjaga `alat/periksa-migrasi-beku.py`), tiap perbaikan + uji regresi + mutasi wajib MERAH.
 (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (2026-09-19) — SKEMA HIDUP DI PROYEK NYATA: `T0-08` DITUTUP, `T-020` SELESAI.**

Lee menyelesaikan **Langkah A** (2 rahasia Supabase di kotak rahasia GitHub); agent memicu berkas penanda
supabase/SEBAR-SKEMA → run `35435248540` **hijau berurutan** (`link` → `db push --dry-run` → `db push` →
`migration list`), jadi 14 migrasi kini ADA di proyek `bdvjirmbuqelmduztryj`. Bukti baca data (setara `select 1`):
gerbang CI ke-50 membaca tabel katalog dengan kunci publik → **HTTP 200** (run `35435414653`).

**Aturan baru yang mengikat (dikunci di `DECISIONS_LOG.md`):** berkas migrasi `0001`–`0014` **DIBEKUKAN** — semua
perubahan skema, termasuk seluruh perbaikan temuan audit K-1…K-4, WAJIB ditulis sebagai berkas BARU `0015`+ dan
dijaga `alat/periksa-migrasi-beku.py` (ikut berjalan di CI, punya `--uji-diri`, plus mutasi "penjaga dihapus"
di `alat/periksa-gerbang-ci.py --uji-diri`).

**Langkah berikutnya (urut):**
1. **T1-45 sisa 21 temuan** (PR-12 sudah ditutup 2026-09-19) — mulai **K-1**, tetapi kini dalam bentuk **`supabase/migrations/0015_penutup_celah_putaran16.sql`**
   (berkas lama tidak boleh disunting), lengkap dengan uji regresi + semua mutasi wajib MERAH.
2. **`T-021` (halaman publik)** — menunggu DUA hal dari Lee: rahasia `CLOUDFLARE_API_TOKEN` (panduan
   `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, pakai templat **Edit Cloudflare Workers**, bukan *Create Custom Token*)
   dan izin **"Boleh naik"** karena deploy publik = tindakan tak bisa dibatalkan.
3. **Uji ulang berkas uji `supabase/tes/` di proyek nyata** (bcrypt asli pgcrypto) — bukti bahwa perilaku di proyek
   Lee sama dengan PostgreSQL lokal; dicatat di `supabase/README.md`, belum dijadwalkan sebagai tugas.
 (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18b (2026-09-19) — FASE 0 DIBERESKAN (akun pemilik aktif). RENCANA BERIKUTNYA: K-1.**

Keadaan sekarang: `T0-00` + butir tunggu `T-018` **DITUTUP** — Lee membuat akun **Supabase + Resend + Cloudflare** dan
mengisi nilai non-rahasia di `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`; kunci rahasia tidak pernah
masuk repo/obrolan). Selesai hari ini: klien Supabase aman `aplikasi/src/lib/supabase.ts` (+10 uji) · alat uji sambung
`aplikasi/alat/cek-supabase.mjs` (+`--uji-diri` 5 kasus) · **gerbang CI ke-50** `npm run cek:supabase` (bukti live: run
`35432334878` hijau, langkah ke-11 = success) · jalur rilis `aplikasi/wrangler.toml` + `npm run deploy`.

**Dua hal menunggu Lee — jangan dikerjakan tanpa jawaban:** `T-020` menyebar 14 migrasi ke proyek Supabase nyata (butuh
kredensial pemilik; sesudahnya DoD `select 1` T0-08 bisa dituntaskan) · `T-021` deploy publik halaman kosong ke Cloudflare
(tindakan publik & tak bisa dibatalkan).

**Bukti jalur (2026-09-19, sudah dijalankan):** penanda terpasang → kedua alur **menyala lalu berhenti aman** di gerbang rahasia tanpa menyentuh proyek (run `35433200326` skema, `35433200375` halaman; semua langkah penyebaran `skipped`) · penanda dihapus → kedua alur **hijau tanpa kerja** (run `35433237658`, `35433237656`) — jadi tidak ada penyebaran tak sengaja di kiriman berikutnya. Penjaga gerbang kini memeriksa **urutan** perintah (pratinjau wajib benar-benar mendahului penyebaran) dan menolak 9 mutasi alur.

**Jalurnya sudah disiapkan mesin (2026-09-19):** Lee tinggal menempel **3 rahasia** ke kotak rahasia GitHub
(`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `CLOUDFLARE_API_TOKEN`) — panduan langkah bernomor tanpa perintah:
`docs/ops/LANGKAH_PEMILIK_SEKARANG.md` (baris `BUKU_UJI_PEMILIK` P-04/P-05). Setelah Lee bilang "Rahasia sudah dipasang",
agent: (1) buat berkas penanda supabase/SEBAR-SKEMA → alur menjalankan **dry-run lebih dulu** lalu menyebar → hapus
penanda; (2) catat bukti tabel ada; (3) bila Lee setuju, buat penanda aplikasi/SEBAR-HALAMAN → alur menaikkan halaman
→ catat alamat publik + hapus penanda. Kedua alur diawasi `alat/periksa-gerbang-ci.py` (dua arah, 8 + 5 perintah, **urutan diperiksa**).

**Langkah berikutnya (urut):**
1. **T1-45, sisa 21 temuan** — mulai **K-1** (penanda `resto.pembatalan_*` dipalsukan → void sesudah dapur tanpa PIN
   & tanpa jejak), lalu **K-2** (diskon pada `lunas`/`batal` · void satu item jangan menutup pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar), lalu K-3/K-4 (jejak berjenjang, kupon↔pesanan Edge
   `p_pesanan_id`, buku besar stok, PIN warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu
   `percobaan_masuk`, label `12/12` basi, generator paket audit, pesan diskon F-10).
   Target: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/uji-mutasi-0015.py`.
2. Setiap perbaikan wajib: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi MERAH) + suite penuh hijau +
   `DECISIONS_LOG.md` bila menyentuh cara membuktikan izin/uang.
3. Butir tertangguh terbuka **8** (batas 12) → di akhir batch, tawarkan jawaban agent untuk semuanya.
4. Kalau Lee menjawab `T-020`/`T-021`, kerjakan itu lebih dulu: Fase 0 tuntas adalah syarat sebelum pekerjaan Fase 1
   berlanjut (dan penyebaran skema membuka uji RLS di layanan nyata — nilai besar untuk penutupan T1-45).

**Jangan merge PR #2** selama K-1/K-2 masih terbuka. PR #1 tetap tidak disentuh.

**PUTARAN 18 (2026-09-19) — 25 TEMUAN PENINJAU DIBANTAH-BALIK (25/25 NYATA); 2 SUDAH DITUTUP, SISA 23.**

Dua laporan diterima (sesi peninjau `arena/01a0b85b`): AUD-3 menyeluruh (10 temuan, **laporan DITOLAK MESIN** karena
kelengkapan format — label grup cakupan diparafrase + cabang memuat 2 laporan; isinya tetap dipakai setelah
diverifikasi ulang) dan review PR putaran16 (15 temuan, **LOLOS KONTRAK**, verdict TIDAK-BERSIH). Semua temuan
**dibantah-balik sendiri dengan probe** dan semuanya NYATA (0 palsu). DITUTUP: **D F-05** (kunci kalibrasi keluar
dari repo + daftar pensiun + bahan review PR hidup di luar repo) dan **PR-10** (gerbang CI gagal-terbuka: penjaga
kini dua arah — 49 perintah CI diawasi, `if:` dilarang — dibuktikan menolak di salinan `/tmp/gc2`).

**Langkah berikutnya yang wajib (urut):**
1. **Lanjutkan `T1-45`** — sisa **21 temuan**. Urutan nilai:
   **(a) K-1** penanda `resto.pembatalan_*` jangan dipercaya (kasir bisa memasang penanda transaksi sendiri →
   void sesudah dapur tanpa PIN & tanpa jejak; bukti probe peninjau sudah direproduksi);
   **(b) K-2** diskon pada pesanan `lunas`/`batal` · void satu item jangan menutup seluruh pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar;
   **(c)** K-3/K-4: jejak penolakan berjenjang, kupon ↔ pesanan (Edge `p_pesanan_id`), buku besar stok, PIN
   warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu `percobaan_masuk`, label `12/12` basi,
   generator paket audit (baris "TIDAK ADA" palsu), pesan diskon F-10.
   Target berkas: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/*`.
2. Setiap perbaikan: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi WAJIB MERAH) + suite penuh hijau
   + `DECISIONS_LOG.md` bila menyentuh cara membuktikan persetujuan/keamanan uang.
3. **Satu hal masih menunggu Lee:** auditor diminta memperbaiki **format** laporannya (label grup cakupan sama
   seperti paket + satu laporan per cabang) lalu mengirim ulang agar auditnya sah formal.
4. Selagi menunggu: butir tertangguh terbuka **7** (batas 12) — tawarkan jawaban agent untuk masing-masing.

**Jangan merge PR #2** (temuan K-1/K-2 masih terbuka di commit yang direview). PR #1 tetap tidak disentuh.


**PUTARAN 17 SEDANG BERJALAN (2026-09-19) — putaran verifikasi, MENUNGGU LEE.** Paket peninjau
**sudah terbit & ter-push** (target `93a50ba`): audit
`docs/uji/paket-audit/AUD-3-2026-09-19-SIAP-TEMPEL.md` dan review PR
`docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran16-SIAP-TEMPEL.md` (PR **#2**; jalur risiko Merah).
Tugas Lee: **buka 2 chat baru** (idealnya model berbeda) dan **salin satu berkas `-SIAP-TEMPEL` ke
tiap chat**; setelah selesai bilang **"Laporan audit/review sudah masuk, periksa."** Keadaan
menunggu ini **normal dan tidak menghambat**: sambil menunggu, agent boleh menutup cacat lain yang
ditemukan sendiri (aturan: cacat yang sudah diketahui ditutup dulu supaya peninjau tidak membuang
anggaran). Saat laporan masuk: ambil (`--ambil-laporan`), **bantah-balik setiap temuan dengan probe
sendiri**, tutup yang nyata, catat yang palsu.

**Catatan pilihan cabang (penting untuk sesi baru):** handoff ini menunjuk
`arena/01a0b7d1-resto-barokah` — dipilih **supaya pekerjaan terbaru tidak hilang**: cabang sesi
sebelumnya (`arena/01a0a8a2-resto-barokah`) berhenti di `0af1cf9` dan **tidak memuat** paket peninjau
2026-09-19 + perbaikan putaran ini. Mesin kini **menolak** handoff yang menunjuk cabang tanpa keadaan
kerja terbaru (`alat/lanjut-sesi.py`, uji-diri 39 kasus) — jadi kalau Lee ingin melanjutkan dari
cabang lain, itu tetap haknya, tapi harus lewat `--lanjut-dari` atau `--paksa` (tercatat).

**Sesi ditutup (putaran 16, 2026-09-18)** atas perintah Lee: *"Siapkan pindah sesi dan tutup sesi ini dengan baik."*
Sebelum menutup, pertanyaan kepercayaan Lee diperiksa jujur dan **4 celah nyata ditutup** (rantai "kalimat perintah
sederhana Lee → alur" sekarang dijaga mesin): Prompt Pembuka item **2d** menunjuk `PANDUAN_PENGGUNA.md`; **KARTU SESI**
mencetak penunjuk buku; kalimat gabungan & sinonim ("dengan baik" = "dengan benar") masuk AL-3/AL-13 + tabel C3;
rujukan berkas pensiun dibetulkan. Jadi: kalau Lee menulis kalimat pendek, **cari di buku (Bagian C3/B/E)** —
jangan mengarang langkah. Sesi yang sengaja ditinggalkan Lee tetap `arena/01a0b4c3-resto-barokah`.

**Putaran 15 (2026-09-18):** permintaan Lee — berkas prompt pindah sesi dijadikan
**STATIS** (`PROMPT_SESI_BARU.md`, satu baris `SESI YANG AKU LANJUT:` diisi Lee) dan sesi yang **sengaja
ditinggalkan** dicatat di `docs/ops/SESI_DITINGGALKAN.md` (mesin menolak handoff ke arah sana).
`docs/ops/SIAP-TEMPEL-SESI-BARU.md` dipensiunkan menjadi penunjuk. Jadi: **untuk pindah sesi, Lee cukup
menyalin `PROMPT_SESI_BARU.md` — tidak perlu minta apa pun ke agent.**

Keadaan keputusan Lee (2026-09-18, sesi ditutup karena berat): arah berikutnya **belum dipilih**.
Urutan yang disarankan agent, dan alasannya:

1. **Putaran verifikasi (disarankan lebih dulu, kecil).** Commit yang ditunjuk paket peninjau
   TIDAK diklaim tangan di sini — bacalah baris **"Paket peninjau terbaru"** di §2 (ditulis mesin
   dari berkas paketnya sendiri). Sebelum dua peninjau mulai bekerja, segarkan paket ke commit
   terkini: `python3 alat/audit-independen.py --paket AUD-3 --semua` dan
   `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN` (pakai NN berikutnya —
   jangan menimpa nama lama, laporan peninjau pernah tertimpa karena ini). Lee tinggal menyalin
   **satu berkas `-SIAP-TEMPEL` per chat baru** (dua chat). Setelah laporan masuk:
   bantah-balik setiap temuan dengan probe sendiri (aturan tetap), tutup yang nyata, catat yang palsu.
   Bukti dari laporan putaran sebelumnya: dua putaran berturut-turut menemukan cacat nyata, dan dua
   cacat terakhir justru tertangkap CI — jadi verifikasi ini bukan formalitas.
2. **Lanjut kerja T1-24** (perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat) — menutup
   akar beberapa kelemahan (batas PIN per perangkat masih memakai nama perangkat kiriman klien).
   **PENTING (temuan baru):** ROADMAP T1-24 menyebut "Migrasi 0012", padahal 0012 **sudah terpakai**
   (penutup celah review) dan migrasi sudah mencapai `0014`. T1-24..T1-28 wajib memakai nomor
   berikutnya (0015 dst.) — perbarui ROADMAP + catat di `DECISIONS_LOG.md` saat dikerjakan.
3. **Lihat pratinjau** (10 tema, mode Nyaman/Padat) kalau Lee ingin menilai tampilan langsung.

Kalau Lee hanya menulis "lanjut" tanpa memilih: kerjakan **(1) penyiapan putaran verifikasi** sampai
tuntas (paket + arahan siap tempel), lalu tanyakan **satu** pertanyaan singkat: "verifikasi (jalankan
2 chat) atau langsung T1-24?" — jangan menebak di antara dua jalur besar yang tidak bisa dibatalkan.
