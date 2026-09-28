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
