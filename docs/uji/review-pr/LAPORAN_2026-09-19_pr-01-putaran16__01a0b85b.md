# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran16 — 2026-09-19

- **Commit yang direview:** `93a50baccffc23ca0f41a9f636fed03b447ae391`
- **Tingkat risiko:** Merah
- **Verdict:** TIDAK-BERSIH

Catatan paket: tidak ada berkas `PKT-*-putaran16.md` di repo — paket review ditempel langsung di chat
pembuka sesi ini. 12 klaim di §2 dikutip apa adanya dari paket tempelan itu (bagian yang terpotong di
ujung baris saya tandai). Nomor klaim 1–8 berasal dari butir pesan commit dalam rentang
`origin/main...93a50ba` (terverifikasi ulang lewat `klaim_dari_commit()` di bawah); klaim 9–12 adalah
klaim bawaan pemeriksa. Tree yang diuji adalah worktree snapshot commit 93a50ba di `/tmp/rb-p16`
(detached HEAD, diverifikasi `git rev-parse`), bukan tip cabang dan bukan deskripsi PR.
Saya menjalankan lensa L1 (ancaman & akses), L2 (uang & jejak), dan L4 (mutu uji).
Satu temuan K-1 TERVERIFIKASI membuat rekomendasi **JANGAN MERGE DULU**.

## 1. Cakupan diff

Perbandingan independen `git diff --shortstat origin/main...93a50ba` menghasilkan
**420 berkas berubah, +60.192/−145 baris** (`git diff --name-status`: 409 tambah, 11 ubah).
Klasifikasi risiko per berkas (pola: migrasi/SQL/CI/pemeriksa/Edge/fondasi = Merah;
alat bantu + aplikasi = Kuning; dokumen biasa = Hijau): **Merah 85 · Kuning 121 · Hijau 214**.

Saya tidak membaca 420 berkas baris demi baris. Saya mengeksekusi seluruh suite uji SQL (41 berkas),
kedua suite mutasi, gerbang penuh, dan seluruh pemeriksa Python; membaca penuh kode gerbang/CI/RPC
yang relevan dengan klaim; dan menulis 14 probe SQL sendiri (P0–P12 + bisect) yang semuanya
dieksekusi di snapshot commit yang direview. Baris yang tidak saya baca satu per satu saya
nyatakan apa adanya di kolom Diperiksa.

| # | Kelompok berkas | Jumlah di diff | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---:|---|---|---|
| 1 | `supabase/migrations/0001–0014` (khusus 0009–0014: pesanan, bayar, PIN, penutup celah) | 14 migrasi | Merah | Ya, fungsi/pemicu/policy yang disentuh temuan dibaca + diprobe | `node alat/uji-sql.mjs /tmp/pb-p*.sql` → 13/13 LULUS (P0–P12); bukti per temuan di §4 |
| 2 | `supabase/tes/*.sql` | 41 uji | Merah | Ya, seluruhnya dieksekusi | `node alat/uji-sql.mjs` → `uji: 41 LULUS · 0 GAGAL`, exit 0 |
| 3 | `supabase/functions/verifikasi_pin/index.ts` (Edge) | 1 | Merah | Ya, dibaca penuh | tidak meneruskan `p_pesanan_id` → PR-07; tanpa pemanggil aplikasi (grep) |
| 4 | `.github/workflows/ci.yml`, `aplikasi/alat/periksa-semua.sh` | 2 | Merah | Ya, dibaca + dijalankan | `bash aplikasi/alat/periksa-semua.sh` → GAGAL handoff, exit 1; `gh api …/check-runs` → cancelled |
| 5 | `alat/uji-mutasi-0012.py`, `alat/uji-mutasi-0014.py` | 2 | Merah | Ya, dijalankan penuh | `16/16` dan `17/17 mutasi WAJIB terbukti MERAH`, exit 0 keduanya |
| 6 | `alat/periksa-gerbang-ci.py`, `alat/periksa-angka-bukti.py`, `alat/periksa-paket.py`, `alat/lanjut-sesi.py`, `alat/review-pr.py`, `alat/periksa-fungsi-pin.py`, pemeriksa lain | ~20 | Merah/Kuning | Ya, dijalankan (+ `--uji-diri`); gerbang-ci & angka-bukti dibaca penuh | `--uji-diri` 13/13, 5/5, LOLOS; batch sisa 166 lolos/0 gagal; mutasi G1/G2 → PR-10 |
| 7 | `alat/audit-independen.py`, `_sistem/validate_system.py`, `alat/mulai-sesi.py`, `alat/bantu_uji_diri.py` | 4+ | Kuning | Dijalankan; bantu_uji_diri dibaca sekilas | audit `--uji-diri` TERKALIBRASI; validate LOLOS; mulai-sesi `--uji-diri` LOLOS |
| 8 | `aplikasi/src/**`, `aplikasi/alat/*` (React/TS + pemeriksa UI) | ±100 | Kuning | Sebagian: seluruh pemeriksa UI dijalankan; kode dibaca sekilas + pindai rahasia | vitest/eslint/typecheck/build LOLOS (via gerbang); grep rahasia nihil; tidak ada audit visual manual tiap komponen |
| 9 | `docs/KEAMANAN.md`, `docs/ROADMAP.md`, `STATUS.md`, `PROJECT_STATE.md`, protokol/paket | ±30 | Merah/Hijau | Ya untuk klaim perilaku & angka | hitung tugas 192 + per fase cocok; §6.4 KEAMANAN → PR-13; echo 12/12 → PR-12 |
| 10 | Dokumen lain, skill, log sesi, riwayat, aset | ±200 | Hijau | Tidak baris-per-baris; rujukan silang diperiksa via `periksa-rujukan.py` LOLOS | sampling + pemeriksa rujukan; bukan verifikasi isi tiap dokumen |

## 2. Klaim yang dibantah

Perintah dijalankan di `/tmp/rb-p16` (snapshot 93a50ba) kecuali dinyatakan lain.
Klaim 1–8 dikutip dari paket; klaim yang terpotong di ujung baris commit saya lengkapi dari pesan
commit 93a50ba (saya tandai [lengkap]).

| # | Klaim | Cara membantah | Hasil nyata |
|---:|---|---|---|
| 1 | Angka disegarkan ke 192 (rincian per fase diukur ulang: cocok semua). | `python3 -c` hitung `^- \[[ x]\] T\d+-\d+` per fase di `docs/ROADMAP.md` + baca 3 baris keadaan-sekarang | **DITERIMA**: total 192 persis; per fase T0 15·T1 44·T2 19·T3 16·T4 10·T5 12·T6 8·T7 12·T8 15·T9 12·T10 16·T11 13 = cocok semua. (Hitungan kasar saya 199 di tengah jalan adalah salah ukur saya sendiri — pola longgar ikut menghitung centang non-tugas; pola ID-tugas memberi 192.) |
| 2 | `alat/periksa-angka-bukti.py` diberi **Aturan 2**: angka jumlah tugas [keadaan-sekarang di 3 baris wajib sama dengan jumlah baris tugas nyata; riwayat tidak disasar] | Baca `jumlah_tugas_nyata()` + `ATURAN_JML_TUGAS`; jalankan pemeriksa | **DITERIMA**: Aturan 2 ada dan tepat menyasar `**Jumlah tugas:**` ROADMAP, `- **Status:**` STATUS.md, `DETAIL:` PROJECT_STATE.md; `python3 alat/periksa-angka-bukti.py` → LOLOS, exit 0 |
| 3 | Uji-diri penjaga ini 3 → 5 kasus; dua mutasi baru (STATUS & PROJECT_STATE [dibiarkan basi) terbukti DITOLAK] | `python3 alat/periksa-angka-bukti.py --uji-diri` | **DITERIMA**: 5/5 OK — `salinan utuh → 0`, `perintah dihapus → ditolak`, `penanda jujur dihapus → ditolak`, `jumlah basi di STATUS.md → ditolak`, `jumlah basi di PROJECT_STATE.md → ditolak`; exit 0 |
| 4 | CI: `python3 alat/periksa-paket.py` + `python3 alat/periksa-angka-bukti.py` [dijalankan; checkout `fetch-depth: 0`] | `grep -n` ci.yml + `python3 alat/periksa-gerbang-ci.py` | **DITERIMA**: ci.yml baris 110/111 & 115/116 menjalankan keduanya (+ `--uji-diri`); `fetch-depth: 0` ada; pemeriksa gerbang → LOLOS 22 gerbang, exit 0 |
| 5 | `aplikasi/alat/periksa-semua.sh` ikut menjalankan keduanya (+ uji-dirinya) [supaya sama dengan CI] | `grep -n` skrip + eksekusi penuh | **DITERIMA sebagian**: baris 61–64 menjalankan keempat perintah dan semuanya LOLOS saat eksekusi — tetapi skrip secara keseluruhan GAGAL (exit 1) pada pemeriksa handoff, dan label echonya basi ("12/12", nyata 16/16 → PR-12). "Sama dengan CI" pun tidak tepat: CI memakai `--di-ci` yang justru melewati pemeriksaan handoff (→ PR-11) |
| 6 | `alat/periksa-gerbang-ci.py`: 19 → **22 gerbang wajib** (termasuk pola [`fetch-depth: 0`) + 3 mutasi baru; semuanya terbukti DITOLAK saat dirusak] | Hitung `GERBANG_WAJIB`; `--uji-diri`; 2 mutasi peninjau (G1/G2) di salinan `/tmp/gc-test` | **DITERIMA sebagian**: 22 pola terjangkar `$` terverifikasi; `--uji-diri` 13/13 exit 0. **DITOLAK** untuk kekuatannya: menghapus langkah `periksa-rahasia.py` dari salinan ci.yml → tetap LOLOS (G1, exit 0); memberi `if: false` pada langkah Uji SQL → tetap LOLOS (G2, exit 0). Pemeriksa hanya mengunci keberadaan 22 dari ±40 langkah dan buta terhadap penonaktifan bersyarat → PR-10 |
| 7 | `python3 alat/lanjut-sesi.py --daftar-sesi` — menampilkan SEMUA sesi di GitHub: nama cabang, [tanggal, jarak, ketersediaan alat] | `--daftar-sesi` vs `git ls-remote origin 'refs/heads/arena/*'` (12 cabang) | **DITERIMA**: 12/12 cabang tampil setelah pembacaan benar (pembacaan pertama saya hanya 6 karena pipa `head -20` saya sendiri memotong keluaran — kesalahan ukur saya, bukan cacat alat). Tanpa batas/paginasi di kode |
| 8 | `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>` — pilihan Lee. [Ditulis ke handoff] | `--siapkan --lanjut-dari arena/01a0b7d1-resto-barokah` + kontrol negatif cabang palsu, di worktree kalibrasi `/tmp/rb-kal` | **DITERIMA**: handoff menulis `Cabang yang dilanjutkan: arena/01a0b7d1-resto-barokah`, exit 0; cabang palsu ditolak dengan pesan jelas. Catatan kecil: penolakan keluar dengan exit 0 walau mencetak GAGAL (berkas tidak ditulis — aman secara perilaku; → §8) |
| 9 | Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini (bukan commit sebelumnya). | `node alat/uji-sql.mjs` + kedua suite mutasi + 14 probe peninjau + status CI commit ini | **DITOLAK sebagian**: regresi lama terbukti (41/41; mutasi 16/16 & 17/17; probe P0 R1–R7 semua bertahan). Tetapi "perilaku baru" 0014 menyimpan 8 celah TERVERIFIKASI yang tidak ditangkap uji (PR-01–PR-09, PR-14–PR-15), dan commit ini sendiri tidak pernah mendapat verdict CI hijau (check-runs: cancelled; → PR-11). Suite membuktikan masa lalu, bukan kebaruan |
| 10 | Tidak ada gerbang keamanan/CI yang dilemahkan (ambang diturunkan, uji dimatikan, revoke/hak dicabut dihapus). | Baca ci.yml + `periksa-gerbang-ci.py` + mutasi G1/G2 + probe hak P8 | **DITERIMA untuk isi CI** (22 gerbang hadir, tanpa `continue-on-error`/`\|\| true`) **tetapi DITOLAK untuk penjaganya**: pemeriksa gerbang gagal-terbuka (G1/G2 → PR-10), dan 0014 mengubah pola hak (`+service_role` hilang di 3 fungsi; `peringkat_peran` masih PUBLIC → PR-14). Jaring pengaman klaim ini berlubang |
| 11 | Perubahan pada jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API). | Probe P1–P12: pemanggilan SQL langsung sebagai peran terbatas | **DITOLAK KUAT**: 6 pelanggaran TERVERIFIKASI lewat pemanggilan langsung — penanda `resto.pembatalan_*` dipalsu kasir → void tanpa PIN/jejak (PR-01 K-1); `nomor_pesanan_berikutnya` lintas resto (PR-03 K-2); oracle PIN via pesan kembar (PR-04 K-2); void pra-dapur tanpa izin (PR-05 K-3); kupon tanpa pesanan (PR-07 K-3); void item membunuh pesanan (PR-02 K-2) |
| 12 | Dokumen yang menyatakan perilaku (fondasi, buku induk, panduan Lee) sudah ikut diperbarui — tidak ada klaim basi. | Pindai angka/nama di keluaran gerbang + `docs/KEAMANAN.md` + pesan commit | **DITOLAK**: 3 klaim basi/salah di artefak kini — echo gerbang "12/12 WAJIB MERAH" padahal 16/16 (PR-12); `docs/KEAMANAN.md` §6.4 menyebut tabel `percobaan_masuk` yang tidak ada di migrasi mana pun (PR-13); pesan commit 93a50ba menyalahkan "pohon belum di-commit" padahal pohon ter-commit pun tetap merah (PR-11) |

Regenerasi klaim terverifikasi: `klaim_dari_commit("origin/main", "93a50ba")` menghasilkan 12 klaim
yang sama dengan paket tempelan (8 dari butir commit + 4 bawaan: uji-otomatis, gerbang, RPC, dokumen).

## 3. Pemeriksaan gerbang

| # | Permintaan | Perintah (di `/tmp/rb-p16` kecuali dinyatakan lain) | Hasil nyata |
|---:|---|---|---|
| 1 | Gerbang penuh | `bash aplikasi/alat/periksa-semua.sh` | **GAGAL, exit 1** — seluruh langkah teknis LOLOS (SQL 41/41, mutasi, checkers, vitest, build) kecuali 2 masalah handoff: `[X] commit terakhir TIDAK memperbarui docs/ops/SIAP-LANJUT.md — handoff basi satu batch` dan `[X] handoff menulis commit keadaan e8b7919f, padahal induk commit terakhir 0af1cf9f`. → PR-11 |
| 2 | Suite SQL penuh | `node alat/uji-sql.mjs` | **LOLOS, exit 0** — `uji: 41 LULUS · 0 GAGAL` (14 migrasi diterapkan). Satu-satunya penutup celah putaran16 (Aturan 2 dkk.) tidak menambah uji SQL — semua 41 mengunci perilaku lama |
| 3 | Mutasi pagar 0012 | `python3 alat/uji-mutasi-0012.py` | **LOLOS, exit 0** — `RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH (+ 4 mutasi tunggal pada penjaga bertumpuk: hijau = sesuai dugaan…)` ±74 dtk |
| 4 | Mutasi pagar 0014 | `python3 alat/uji-mutasi-0014.py` | **LOLOS, exit 0** — `RINGKASAN: 17/17 mutasi WAJIB terbukti MERAH` |
| 5 | Mutasi + pelonggaran RLS/hak milik peninjau | Tambah `supabase/migrations/9999_mutasi_peninjau.sql` (grant kembali 2 pintu izin + policy `using (true)` di `penyewa`), jalankan 2 uji, hapus berkasnya | **MERAH sesuai harapan lalu pulih**: `uji: 0 LULUS · 2 GAGAL` (`klien tidak lagi bisa memanggil izin_efektif_untuk`; `anon tidak melihat satu baris penyewa pun (dapat 2, harap 0)`), exit 1; setelah berkas dihapus: `2 LULUS · 0 GAGAL`, exit 0. Worktree kembali bersih (`git status` kosong) |
| 6 | Pemeriksa gerbang CI + uji-diri | `python3 alat/periksa-gerbang-ci.py` dan `--uji-diri` | LOLOS `22 gerbang wajib ada` + `--uji-diri` 13/13, exit 0. **Tetapi** mutasi peninjau G1 (hapus langkah rahasia) & G2 (`if: false` di langkah SQL) pada salinan ci.yml → keduanya tetap LOLOS exit 0 → PR-10 |
| 7 | Pemeriksa paket + angka-bukti | `python3 alat/periksa-paket.py`; `python3 alat/periksa-angka-bukti.py` (+ `--uji-diri`) | `PERIKSA PAKET — 26 paket terlacak` LOLOS; angka-bukti LOLOS; `--uji-diri` 5/5 (kasus: utuh, perintah dihapus, penanda jujur dihapus, basi di STATUS, basi di PROJECT_STATE) |
| 8 | Pemeriksa laporan & audit + uji-diri | `python3 alat/review-pr.py --uji-diri`; `python3 alat/audit-independen.py --uji-diri` (via gerbang) | Keduanya LOLOS (`MENOLAK yang buruk dan MENERIMA yang baik`; `TERKALIBRASI`). Catatan: baris `BELUM TERKALIBRASI` di log gerbang adalah kasus uji negatif yang lulus ([OK]), bukan kegagalan |
| 9 | Sisa pemeriksa Python (rujukan, temuan-audit, buku-uji, bersih, kerapatan, antarmuka+uji-diri, struktur, komponen-env+uji-diri, uji, kontras+uji-diri, rahasia+uji-diri, gerbang-ci uji-diri, mulai-sesi uji-diri, panduan+uji-diri, fungsi-pin, roadmap, validate_system) | Rantai `&&` satu perintah | **166 lolos / 0 gagal, exit 0** (`periksa-rahasia.py` LOLOS; tidak ada `.env`; pindai rahasia manual nihil selain positif-palsu `mask-image` CSS) |
| 10 | CI GitHub pada commit & cabang | `gh api …/commits/93a50bac…/check-runs`; `gh run list --branch arena/01a0b7d1-resto-barokah` | Pada 93a50ba: 2 check-run **cancelled** (tidak pernah ada verdict hijau untuk commit yang direview). Di tip cabang: 5 run terakhir success; PR #2 OPEN. → PR-11 |

## 4. Temuan

### [PR-01] Penanda transaksi `resto.pembatalan_*` bisa dipalsu kasir → void sesudah-dapur tanpa PIN dan tanpa jejak

- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (pemicu pesanan_item + `resto.pembatalan_pesanan`/`resto.pembatalan_item`); `supabase/migrations/0009_pesanan.sql` (aturan void sesudah-dapur)
- **Klaim yang dilanggar:** klaim 11 (jalur uang tak bisa dilewati pemanggilan langsung); `docs/KEAMANAN.md` §1.7 (tindakan sensitif meninggalkan jejak), §9 (void sesudah-dapur wajib persetujuan)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p1-penanda.sql` → LULUS (probe LULUS = celah ada):

```sql
select uji.harap_gagal($$update public.pesanan_item set status='batal' where id='…a101'$$,
  'kontrol: batal item sesudah dapur tanpa jejak resmi DITOLAK');   -- kontrol: DITOLAK ✓
select set_config('resto.pembatalan_pesanan', '…a001', true);        -- kasir memasang penanda sendiri
update public.pesanan_item set status='batal' where id='…a101';      -- DITERIMA ✗
-- uji.sama(status,'batal'), uji.sama(count(pembatalan),0), uji.sama(subtotal,27000) — semua LULUS
```

```text
uji: 1 LULUS · 0 GAGAL — item sesudah dapur berhasil dibatalkan TANPA baris pembatalan & TANPA PIN;
tidak ada satu pun baris pembatalan; tagihan turun (satu baris 27000 tidak ditagih) tanpa jejak
```

- **Skenario gagal:** kasir menjalankan dua pernyataan SQL (atau satu RPC yang membungkusnya) dari
  perangkatnya: pasang penanda → batalkan item yang sudah dimasak. Tagihan berkurang Rp27.000+ tanpa
  persetujuan atasan, tanpa baris `pembatalan`, tanpa PIN — tidak terlihat di laporan "siapa
  menyetujui apa". Uang tunai selisihnya bisa dikantongi; jejak audit nol.
- **Dugaan penyebab:** pemicu mempercayai GUC `resto.pembatalan_*` yang bisa ditulis sesi mana pun
  (`set_config`) sebagai "bukti" pemicu peladen; tidak ada penanda yang hanya-bisa-ditulis-pemicu
  (mis. tabel tempel sekali-pakai per transaksi, atau pemeriksaan `pg_trigger_depth()`).
- **Cara membuktikan perbaikan:** probe di atas harus GAGAL pada baris `update` (ditolak walau penanda
  dipasang manual), kontrol tetap DITOLAK, dan jalur sah (INSERT `pembatalan` sesudah-dapur dengan
  persetujuan → update item) tetap LULUS; jadikan `supabase/tes/resto_penanda_bukan_bukti.sql`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] Void satu item ikut membatalkan seluruh pesanan + pembayaran sisa ditolak

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (pemicu penutup pesanan setelah pembatalan item)
- **Klaim yang dilanggar:** klaim 11; Aturan Bisnis 7 (pembatalan berjejak, pesanan hidup)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p2-void-item.sql` → LULUS:

```sql
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan) values ('…b001','…b101','sebelum_dapur','satu item dibatalkan');
-- uji.sama(status pesanan,'batal') LULUS  ✗  (seharusnya tetap hidup — masih ada 1 item)
-- uji.sama(item hidup,1) LULUS — pesanan berisi item hidup tetapi berstatus batal
-- uji.harap_gagal(insert pembayaran sisa…) LULUS ✗ — pembayaran SAH ditolak karena status batal
```

```text
uji: 1 LULUS · 0 GAGAL — void satu item ikut MEMBATALKAN seluruh pesanan; pembayaran sah untuk sisa item DITOLAK
```

- **Skenario gagal:** pelanggan membatalkan 1 dari 2 menu → kasir mencatat pembatalan resmi → seluruh
  nota mati → pelanggan tidak bisa membayar menu yang dimakannya; kasir terpaksa membuat nota baru
  (nomor & jejak ganda) atau menerima tunai di luar sistem. Gangguan operasional + catatan berantakan.
- **Dugaan penyebab:** pemicu pasca-`pembatalan` menutup pesanan tanpa memeriksa sisa item hidup
  (`not exists (… status <> 'batal')`).
- **Cara membuktikan perbaikan:** probe di atas harus menunjukkan status tetap `draf`/`aktif` setelah
  void 1 dari 2 item, pembayaran sisa DITERIMA, dan pesanan baru menjadi `batal` setelah item
  TERAKHIR dibatalkan; jadikan uji regresi.
- **Status verifikasi:** TERVERIFIKASI

### [PR-03] `nomor_pesanan_berikutnya()` membocorkan hitungan pesanan ke resto lain

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (`public.nomor_pesanan_berikutnya`)
- **Klaim yang dilanggar:** klaim 11; `docs/KEAMANAN.md` §2 (isolasi antar penyewa = janji utama platform)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p3-nomor.sql` → LULUS:

```sql
select uji.klaim('90000000-0000-0000-0000-000000000007');  -- kasir RESTO B
set local role authenticated;
select uji.sama(public.nomor_pesanan_berikutnya('a1a1a1a1-…', current_date), 11,
  'kasir resto B berhasil membaca hitungan pesanan cabang resto A (bocor)');  -- LULUS ✗
select uji.sama(public.total_dibayar('eeee0000-…0010'), 0,
  'kontrol: total_dibayar menolak membocorkan angka resto lain');              -- kontrol benar ✓
```

- **Skenario gagal:** pegawai resto B memanggil fungsi untuk cabang resto A dan membaca volume
  transaksi harian kompetitor (nomor urut = omzet tak langsung). Pelanggaran isolasi penyewa +
  potensi sengketa UU PDP (data usaha bocor lintas tenant).
- **Dugaan penyebab:** fungsi 0014 tidak memeriksa `penyewa_saya()`/keanggotaan cabang sebelum
  menghitung; pola penjaga `total_dibayar` (kembalikan 0 untuk resto lain) tidak diterapkan.
- **Cara membuktikan perbaikan:** probe harus menunjukkan fungsi mengembalikan 0/null/ditolak untuk
  cabang resto lain, angka benar untuk cabang sendiri, dan `service_role` tetap bisa (bila
  dibutuhkan peladen); jadikan `supabase/tes/nomor_bocor_lintas_resto.sql`.
- **Status verifikasi:** TERVERIFIKASI

### [PR-04] Pesan "PIN sudah dipakai pegawai lain" memastikan PIN aktif kolega (oracle kredensial)

- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (`public.simpan_pin`, cabang kembar)
- **Klaim yang dilanggar:** klaim 11; `docs/KEAMANAN.md` §1.6 ("PIN tidak boleh masuk … pesan error")
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p6-kembar.sql` → LULUS:

```sql
select uji.sama(public.simpan_pin('482619','957031'),
  'PIN itu sudah dipakai pegawai lain di resto ini — pilih angka lain.',
  'ORACLE: jawaban kembar memastikan 482619 adalah PIN aktif kolega satu resto');  -- LULUS ✗
select uji.sama(public.simpan_pin('739284','957031'), 'PIN tersimpan.',
  'kontrol: angka yang belum dipakai dijawab tersimpan (bukan kembar)');           -- dua arah ✓
```

- **Skenario gagal:** orang dalam (atau penyerang dengan satu akun curian) menguji PIN dugannya lewat
  `simpan_pin`: jawaban "kembar" = PIN itu AKTIF milik kolega. PIN atasan yang diintip sekilas bisa
  dipastikan dalam sekali coba, lalu dipakai menyetujui void/diskon. Setiap tebakan memang
  menimpa PIN penyerang sendiri (akun sekali-pakai mengatasi itu).
- **Dugaan penyebab:** pemeriksaan keunikan mengembalikan pesan berbeda untuk "kembar" vs "tersimpan";
  tidak ada jawaban seragam ("bila angka bisa dipakai, PIN-mu sudah diganti") atau keunikan
  ditegakkan tanpa membocorkan (hash + respons generik).
- **Cara membuktikan perbaikan:** probe harus menunjukkan jawaban IDENTIK untuk angka-terpakai dan
  angka-bebas (tanpa mengubah PIN pada kasus kembar), dengan uji positif (ganti ke angka bebas
  tetap berhasil) tetap hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-05] Pembatalan pra-dapur tanpa izin void dan tanpa satu pun baris jejak

- **Tingkat:** K-3
- **Artefak:** pemicu `pesanan_item` pra-dapur (`0009_pesanan.sql` + 0014); tidak ada pemeriksaan `boleh('void_sebelum_dapur')`
- **Klaim yang dilanggar:** klaim 11; `docs/KEAMANAN.md` §8.2 (pemeriksaan izin pertama), §1.7 (jejak)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p10-prakitchen.sql` → LULUS:

```sql
select uji.sama(public.boleh('void_sebelum_dapur'), false, 'kontrol: pelayan TIDAK berizin void');  -- ✓
update public.pesanan_item set status='batal' where id='…d101';                                     -- DITERIMA ✗
-- uji.sama(status,'batal') + uji.sama(count(pembatalan),0) — keduanya LULUS
```

- **Skenario gagal:** pelayan (atau akun yang izin void-nya dicabut) membatalkan item draf langsung
  via UPDATE — tanpa izin, tanpa baris `pembatalan`, tanpa alasan. Pesanan pelanggan berubah diam-diam.
- **Dugaan penyebab:** jalur UPDATE langsung hanya dijaga pemicu tahap; tidak ada pemicu yang
  mewajibkan izin `void_*` + baris `pembatalan` untuk SETIAP perubahan status ke `batal`.
- **Cara membuktikan perbaikan:** UPDATE tanpa izin harus DITOLAK; UPDATE berizin pra-dapur wajib
  menulis baris `pembatalan` (atau ditolak bila tidak lewat INSERT `pembatalan`); uji matriks peran.
- **Status verifikasi:** TERVERIFIKASI

### [PR-06] Penolakan hierarki PIN tidak meninggalkan jejak (catatan ikut batal bersama transaksi)

- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (`public.simpan_pin`, cabang hierarki)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §1.7, §10 (perubahan pegawai/PIN wajib dicatat); klaim 12 (§6.4 "semua percobaan" tercatat)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p4-hierarki.sql` → LULUS:

```sql
select uji.harap_gagal_sebab($$select public.simpan_pin('739284',null,'…0002','alat-admin')$$,
  'tidak lebih tinggi', 'kontrol: admin merebut PIN owner DITOLAK');   -- penolakan benar ✓
-- uji.sama(count(*) from percobaan_simpan_pin where alasan='hierarki peran', 0) LULUS ✗
```

- **Skenario gagal:** admin nakal berulang kali mencoba merebut/mengganti PIN owner — setiap upaya
  DITOLAK tetapi TIDAK TERCATAT di mana pun, sehingga tidak ada peringatan, tidak ada bahan
  investigasi, dan pola serangan orang-dalam tidak terlihat.
- **Dugaan penyebab:** baris jejak ditulis dalam transaksi yang sama lalu ikut di-rollback oleh
  `raise exception`; pola "kembalikan PESAN bukan error" (dipakai untuk kasus kembar/batas) tidak
  diterapkan pada cabang hierarki/izin.
- **Cara membuktikan perbaikan:** upaya perebutan harus meninggalkan 1 baris `percobaan_simpan_pin`
  beralasan hierarki (via dblink/oker mandiri, atau pesan-bukan-error), penolakan tetap terjadi.
- **Status verifikasi:** TERVERIFIKASI

### [PR-07] Kupon persetujuan tanpa ikatan pesanan: berhasil dibuat, mustahil dipakai (jalur Edge buntu)

- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (`verifikasi_pin` membolehkan `p_pesanan_id` NULL);
  `supabase/functions/verifikasi_pin/index.ts` (tidak meneruskan `p_pesanan_id`); pemicu `pembatalan` (menuntut bukti per pesanan)
- **Klaim yang dilanggar:** klaim 11 (jalur persetujuan utuh ujung-ke-ujung)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p12-kupon.sql` → LULUS:

```sql
select uji.sama((public.verifikasi_pin('…0002','482619','void_sesudah_dapur','alat-kasir',null)).berhasil,
  true, 'kupon tanpa pesanan berhasil dibuat (seperti via Edge Function)');   -- dibuat ✓✗
select uji.harap_gagal_sebab($$insert into public.pembatalan …$$, 'Persetujuan belum terbukti',
  'kupon tanpa ikatan pesanan DITOLAK saat dipakai (jalur Edge Function buntu)');  -- buntu ✗
```

  Edge dibaca penuh: hanya meneruskan PIN/aksi/perangkat — tidak ada `p_pesanan_id`.
  `periksa-fungsi-pin.py` tidak memeriksa kelengkapan parameter (6 cek: bentuk/POST/log/kunci/pola).
- **Skenario gagal:** (kini) setiap pengguna terautentikasi bisa mencetak baris `persetujuan_pin`
  sampah yang tak terpakai (polusi jejak audit); (nanti) saat T1-19/T1-20 membangun mesin voucher
  di atas Edge Function, seluruh persetujuan dari aplikasi DITOLAK pemicu — fitur mati saat lahir.
- **Dugaan penyebab:** kontrak longgar di ujung tulis (NULL diterima) + kontrak ketat di ujung pakai
  (bukti per pesanan) + Edge tidak tahu ada parameter pesanan.
- **Cara membuktikan perbaikan:** salah satu — tolak NULL di `verifikasi_pin` untuk aksi berpesanan,
  ATAU terima bukti-tanpa-pesanan di pemicu (dengan batas waktu + sekali pakai), DAN Edge
  meneruskan `pesanan_id`; uji ujung-ke-ujung tulis→pakai.
- **Status verifikasi:** TERVERIFIKASI

### [PR-08] Saldo awal stok tercatat tanpa satu pun baris buku besar (saldo tanpa asal-usul)

- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0007_katalog.sql` (`stok_bahan.jumlah` bisa diisi langsung; `stok_pergerakan` tak wajib)
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §1.7 (jejak tak bisa dikarang); prinsip buku besar (ART-6 koreksi = baris baru)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p11-saldoawal.sql` → LULUS:

```sql
-- insert stok_bahan (…, 'Bahan Siluman','kg', 500) DITERIMA
-- uji.sama(jumlah,500) + uji.sama(sum(pergerakan),0) — keduanya LULUS ✗
```

- **Skenario gagal:** 500 kg "Bahan Siluman" muncul dari ketiadaan — tanpa pembelian, tanpa penyesuaian
  beralasan, tanpa jejak siapa mencatat. Selisih stok/opname tidak bisa diaudit; penyusutan bisa
  ditutup dengan saldo karangan.
- **Dugaan penyebab:** tidak ada pemicu `stok_bahan` yang mewajibkan baris `stok_pergerakan`
  pengimbang (saldo-awal/pembelian/penyesuaian) dalam transaksi yang sama.
- **Cara membuktikan perbaikan:** INSERT/UPDATE `jumlah` tanpa baris pergerakan pengimbang DITOLAK;
  jalur sah (saldo awal beralasan) tetap LULUS; uji paritas saldo-vs-buku-besar.
- **Status verifikasi:** TERVERIFIKASI

### [PR-09] PIN warisan 4 angka buntu total: tak bisa diverifikasi, tak bisa naik kelas swadaya

- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0011_peran_tunggal.sql` (menaikkan 4–6 → tepat 6 TANPA migrasi data);
  `0014_…` (`verifikasi_pin` menolak non-6; `simpan_pin` butuh PIN lama yang lolos verifikasi)
- **Klaim yang dilanggar:** klaim 12 (perilaku migrasi tuntas); kelengkapan jalan pemulihan
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p7-pinlama.sql` → LULUS; `grep` 0011 nihil
  (`update/delete kredensial_pin`, invalidasi, atau penanda wajib-ganti — tidak ada):

```sql
select uji.harap_gagal_sebab($$select public.simpan_pin('482619','1234')$$, 'PIN lama salah',
  'naik kelas 4->6 angka dengan PIN lama yang benar DITOLAK (buntu swadaya)');        -- LULUS ✗
select uji.sama((public.verifikasi_pin('…0004','1234')).pesan, 'PIN harus tepat 6 angka.',
  'PIN warisan 4 angka tidak bisa diverifikasi sama sekali');                         -- LULUS ✗
```

- **Skenario gagal:** pegawai dengan PIN 4 angka (sah di masa 0002/0005) terkunci dari semua aksi
  ber-PIN setelah 0011: masuk gagal, ganti-sendiri gagal ("PIN lama salah" walau benar). Satu-satunya
  jalan keluar adalah reset oleh admin berizin (`kelola_pegawai`) — bila adminnya pun bernasib sama,
  eskalasi ke owner.
- **Dugaan penyebab:** kombinasi tiga aturan yang masing-masing benar tetapi buntu bersama:
  verifikasi menolak non-6 → PIN lama warisan tak pernah lolos → ganti-sendiri mustahil;
  tanpa skrip migrasi/penanda kedaluwarsa saat 0011 mendarat.
- **Cara membuktikan perbaikan:** akun warisan mendapat SATU jalan: verifikasi warisan sekali-pakai
  → wajib ganti ke 6 angka; atau 0011 susulan menandai + memaksa ganti saat masuk pertama; uji
  warisan hijau, uji 6-angka tetap hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-10] Pemeriksa gerbang CI gagal-terbuka: langkah tak-terkunci bisa dihapus; `if: false` tak terlihat

- **Tingkat:** K-3
- **Artefak:** `alat/periksa-gerbang-ci.py` (`GERBANG_WAJIB` 22 pola + `PELEMAHAN` 3 pola); `.github/workflows/ci.yml` (±40 langkah)
- **Klaim yang dilanggar:** klaim 6 (22 gerbang = pengunci), klaim 10 (tak ada pelemahan — jaringnya berlubang)
- **Bukti:** mutasi peninjau pada salinan `/tmp/gc-test` (kode pemeriksa + ci.yml disalin, lalu dirusak):

```text
$ python3 alat/periksa-gerbang-ci.py   # salinan utuh
PERIKSA GERBANG CI — 22 gerbang wajib ada … HASIL: LOLOS   INTACT_EXIT=0
$ # G1: hapus baris langkah periksa-rahasia.py (non-uji-diri) dari salinan ci.yml
PERIKSA GERBANG CI — 22 gerbang wajib ada … HASIL: LOLOS — gerbang CI utuh   G1_EXIT=0 ✗
$ # G2: beri 'if: false' pada langkah Uji SQL (GitHub akan MELEWATINYA) — pola run tetap cocok
PERIKSA GERBANG CI — 22 gerbang wajib ada … HASIL: LOLOS — gerbang CI utuh   G2_EXIT=0 ✗
```

- **Skenario gagal:** PR jahat/ceroboh menghapus pemindai rahasia (atau build/uji-unit/roadmap —
  tak satu pun dikunci) dari ci.yml, atau menonaktifkan langkah SQL dengan `if: false`: CI tetap
  hijau DAN pemeriksa gerbang ikut memberi stempel "gerbang CI utuh" — peninjau yang memverifikasi
  klaim 10 lewat alat ini akan disesatkan tepat saat jaring dibutuhkan.
- **Dugaan penyebab:** penguncian berbasis keberadaan-teks (regex per baris `run:`) atas subset
  langkah; tidak ada pemeriksaan kondisi langkah (`if:`), cakupan langkah keamanan lain, atau
  konsistensi dengan `periksa-semua.sh`.
- **Cara membuktikan perbaikan:** G1 dan G2 harus MERAH (pemeriksa menolak penghapusan langkah
  keamanan + menolak `if:` pada langkah wajib), salinan utuh tetap LOLOS, `--uji-diri` bertambah
  2 kasus; jadikan kasus uji-diri permanen.
- **Status verifikasi:** TERVERIFIKASI

### [PR-11] Commit yang direview tidak pernah hijau: gerbang penuh merah, CI cancelled, pesan commit salah menuduh

- **Tingkat:** K-3
- **Artefak:** commit `93a50ba` (tree + pesannya); `alat/lanjut-sesi.py` (aturan kesegaran); `.github/workflows/ci.yml` (`--di-ci`)
- **Klaim yang dilanggar:** klaim 5 ("seluruh langkah hijau"), klaim 9 (bukti pada commit ini), klaim 10
- **Bukti:** tiga perintah, tiga keluaran mentah:

```text
$ bash aplikasi/alat/periksa-semua.sh   # di /tmp/rb-p16, HEAD = 93a50ba, pohon BERSIH
  [X] commit terakhir TIDAK memperbarui docs/ops/SIAP-LANJUT.md — handoff basi satu batch …
  [X] handoff menulis commit keadaan e8b7919f, padahal induk commit terakhir 0af1cf9f …
HASIL: GAGAL — 2 masalah pada handoff lanjut-sesi   (exit 1)
$ gh api repos/With-AI-Agent/Resto-Barokah/commits/93a50bac…/check-runs --jq '…'
Periksa (lint · tipe · uji · pemeriksa Python) | cancelled   (×2 — tanpa verdict hijau)
$ git show -s --format=%B 93a50ba | grep Bukti -A3
Bukti: `bash aplikasi/alat/periksa-semua.sh` (seluruh langkah hijau; satu-satunya GAGAL adalah
pemeriksa handoff karena pohon memang belum di-commit saat itu) · …
```

  Aturan kesegaran (`lanjut-sesi.py:38-40` + periksa baris 405+): handoff wajib disegarkan di
  commit terakhir tiap batch; CI memakai `--di-ci` yang SENGAJA melewati pemeriksaan ini
  (baris 271) — sehingga CI tidak akan pernah menangkap kebasian ini.
- **Skenario gagal:** commit acuan review dinyatakan "seluruh langkah hijau" padahal gerbang penuhnya
  merah di pohon bersih; alasan yang ditulis ("pohon belum di-commit") tidak menjelaskan keadaan
  ter-commit (penyebab nyata: `--siapkan` tidak dijalankan ulang setelah 2 commit terakhir).
  Peninjau/auditor berikutnya yang memakai commit ini sebagai dasar bekerja di atas fondasi merah.
- **Dugaan penyebab:** alur tulis-handoff → commit tidak dijalankan sebagai satu batch atomik;
  tidak ada pengait pra-commit yang menolak commit tanpa handoff segar.
- **Cara membuktikan perbaikan:** pada commit perbaikan, `periksa-semua.sh` exit 0 di pohon bersih
  DENGAN `git stash list` kosong dan HEAD ter-push; pesan commit berikutnya wajib mencantumkan
  keluaran pasca-commit (bukan pra-commit).
- **Status verifikasi:** TERVERIFIKASI

### [PR-12] Label gerbang basi: echo "12/12 WAJIB MERAH" padahal ringkasan nyata 16/16

- **Tingkat:** K-4
- **Artefak:** `aplikasi/alat/periksa-semua.sh:38`
- **Klaim yang dilanggar:** klaim 12 (tidak ada klaim basi); preseden putaran13 PR-07/PR-05 (kelas "angka basi di gerbang")
- **Bukti:**

```text
$ grep -n "12/12" aplikasi/alat/periksa-semua.sh
38:echo "== bukti mutasi pagar migrasi 0012 (kontrol hijau + 12/12 WAJIB MERAH) =="
$ python3 alat/uji-mutasi-0012.py 2>&1 | tail -1
RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH (+ 4 mutasi tunggal …)   ✗ label ≠ nyata
```

  CI sudah dibersihkan dari angka-baku-nama-langkah (pelajaran PR-07) tetapi gema skrip ini luput.
- **Skenario gagal:** pembaca keluaran gerbang (termasuk Lee via ringkasan) melihat "12/12" lalu
  "16/16" dan harus menebak mana yang benar; kepercayaan pada angka gerbang terkikis tepat di
  proyek yang menjadikan angka-terukur sebagai fondasi.
- **Dugaan penyebab:** jumlah mutasi bertambah 12 → 16 tanpa memperbarui teks gema (angka ditulis
  tangan, bukan dihitung).
- **Cara membuktikan perbaikan:** gema dihitung dari keluaran aktual (atau tanpa angka); uji-diri/
  pemeriksa menolak angka baku yang menyimpang; contoh kemenangan: label putaran13 yang sudah benar.
- **Status verifikasi:** TERVERIFIKASI

### [PR-13] `docs/KEAMANAN.md` §6.4 menuntut pencatatan ke tabel hantu `percobaan_masuk`

- **Tingkat:** K-4
- **Artefak:** `docs/KEAMANAN.md:113` vs `supabase/migrations/*.sql` (kebenaran kode)
- **Klaim yang dilanggar:** klaim 12 (dokumen perilaku mutakhir)
- **Bukti:**

```text
$ grep -n "percobaan_masuk" docs/KEAMANAN.md supabase/ alat -r
docs/KEAMANAN.md:113: … semua percobaan masuk `percobaan_masuk`.     ← satu-satunya rujukan di repo
$ grep -rn "create table.*percobaan" supabase/migrations/
0006_pin.sql:58: create table … public.percobaan_pin (
0011_peran_tunggal.sql:134: create table … public.percobaan_simpan_pin (
```

  Tabel `percobaan_masuk` tidak dibuat di migrasi mana pun; tabel nyatanya `percobaan_pin` (+
  `percobaan_simpan_pin`). Dokumen pengikat menuntut pencatatan ke tempat yang tidak ada —
  berkaitan dengan PR-06 (jejak hierarki yang memang hilang).
- **Skenario gagal:** implementer/auditor mencari tabel yang tidak ada; lebih buruk: keyakinan
  "semua percobaan tercatat" (klaim §6.4) menutupi kenyataan PR-06 bahwa sebagian penolakan
  tidak tercatat di mana pun.
- **Dugaan penyebab:** nama tabel rencana Fase 1B tertulis sebagai fakta kini tanpa penanda
  "rencana" (pola penanda-jujur §2 tidak dipakai di §6).
- **Cara membuktikan perbaikan:** §6.4 menyebut tabel nyata per jenis percobaan (atau ditandai
  rencana bila memang 1B); `periksa-rujukan.py` diperluas ke nama-tabel-vs-migrasi.
- **Status verifikasi:** TERVERIFIKASI

### [PR-14] Kerapian hak 0014: `service_role` ditolak 3 fungsi; `peringkat_peran` bisa dipanggil anon

- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql` (grant `authenticated` saja);
  `supabase/migrations/0005_izin_berjenjang.sql` (pola `+service_role` 0005–0013)
- **Klaim yang dilanggar:** klaim 10 (pola revoke/hak tidak berubah); `docs/KEAMANAN.md` §16.5
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p8-hak.sql` → LULUS:

```sql
set local role service_role;
select uji.harap_gagal_sebab($$select public.hitung_total('eeee0000-…0010')$$, 'permission denied',
  'service_role DITOLAK memanggil hitung_total (hak kurang)');            -- LULUS ✗ (+2 fungsi sama)
select uji.harap_gagal_sebab($$select public.nomor_pesanan_berikutnya(…)$$, 'permission denied', …);
select uji.harap_gagal_sebab($$select public.peran_lebih_tinggi(…)$$, 'permission denied', …);
set local role anon;
select uji.sama(public.peringkat_peran('kasir'), 30,
  'anon bisa memanggil peringkat_peran (hak PUBLIC tersisa)');            -- LULUS ✗
```

- **Skenario gagal:** (a) alur peladen (Edge/cron dengan kunci service) yang kelak memanggil tiga
  fungsi 0014 langsung gagal `permission denied` — pola lama selalu memberi `+service_role`;
  (b) siapa pun tanpa masuk bisa memetakan angka peringkat peran internal (info bocor kecil,
  higiene buruk).
- **Dugaan penyebab:** blok grant 0014 ditulis tanpa `service_role`; `peringkat_peran` luput dari
  `revoke … from public` + penguncian `search_path`.
- **Cara membuktikan perbaikan:** probe P8 dibalik (service_role DITERIMA ketiganya; anon DITOLAK
  `peringkat_peran`); uji matriks hak per fungsi seperti T1-29.
- **Status verifikasi:** TERVERIFIKASI

### [PR-15] Hapus meja memutus tautan pesanan lunas (riwayat kehilangan "meja mana")

- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0008_meja.sql` / `0009_pesanan.sql` (FK `pesanan.meja_id` ON DELETE SET NULL)
- **Klaim yang dilanggar:** kelengkapan jejak (Aturan Bisnis 7; `docs/KEAMANAN.md` §1.7)
- **Bukti:** `node alat/uji-sql.mjs /tmp/pb-p9-meja.sql` → LULUS:

```sql
-- pesanan …c001 lunas di meja M-3; hapus meja M-3 (boleh: tak ada lagi pesanan AKTIF di sana)
select uji.sama((select meja_id from public.pesanan where id='…c001'), null::uuid,
  'pesanan lunas kehilangan tautan mejanya (SET NULL) setelah meja dihapus');   -- LULUS ✗
```

- **Skenario gagal:** sengketa "kami duduk di meja mana?" / audit tata-letak vs omzet: nota lunas
  yang mejanya sudah dihapus (renovasi, ganti nomor) kehilangan tautannya selamanya. Uang tidak
  berubah; kesaksian berubah.
- **Dugaan penyebab:** `ON DELETE SET NULL` tanpa pengecualian pesanan non-draf; tidak ada
  salinan "nama meja saat itu" (pola `*_saat_itu` dipakai di pembayaran tetapi tidak di sini).
- **Cara membuktikan perbaikan:** hapus meja dengan pesanan non-draf DITOLAK (atau mewariskan
  `meja_nama_saat_itu`); uji: buat → lunasi → hapus meja → tautan/nama tetap terbaca.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Bahan: `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` + `docs/uji/kalibrasi/bahan-2026-09-17/`
(dari tree yang direview). Diff diterapkan dengan `git apply --check` BERSIH lalu `git apply` di
worktree terpisah `/tmp/rb-kal` (HEAD 93a50ba, node_modules dipinjam via symlink) — repo kerja
tidak tersentuh. Ditemukan: 4 dari 4 hunk pr-bahan (seluruhnya) + 11 kandidat di bahan-2026-09-17
(9 pasti + 2 dugaan-kuat; total ditanam tak diketahui — tanpa kunci jawaban); temuan palsu: 0.

| # | Tanaman (pr-bahan) | Ditemukan | Verifikasi eksekusi |
|---|---|---|---|
| K-1 | `0004_pola_rls.sql`: policy pengaturan `penyewa_saya()` → `is not null` (bocor lintas resto) | Ya | Suite kalibrasi MERAH: `rls_pengguna.sql` (owner melihat 2 resto, harap 1) + `rls_semua_tabel.sql` (membocorkan 1 baris) |
| K-2 | `0012_…`: penolak promo `raise` → `null;` (diskon 100% tanpa mesin) | Ya (baca) | **INERT di 93a50ba**: 0013 menulis ulang `picu_diskon_batas()` lengkap dengan penolak promo — tanaman mati tertimpa migrasi (suite tidak merah OLEH hunk ini; benar) |
| K-1 | `0003_…`: `and p.aktif` dihapus (akun nonaktif retains akses) | Ya (baca) | **INERT di 93a50ba**: `cabang_saya()` hidup didefinisi ulang di 0012 (via `sesi_cabang`) dengan `p.aktif` utuh (baris 682–700) |
| K-3 | `0005_…`: `revoke … boleh(text,uuid) from public` dihapus | Ya | Suite MERAH: `izin.sql` (`anon tidak boleh memanggil boleh()`) |

Hasil suite di tree bertanam: `uji: 38 LULUS · 3 GAGAL` (exit 1) — tepat 2 tanaman HIDUP yang
ditangkap 3 berkas uji, 2 tanaman mati yang terbukti mati. Skor: 4/4 hunk ditemukan, 0 klaim palsu
(satu kandidat saya TARIK: `search_path = public` tanpa `pg_temp` di bahan-01 — setelah diperiksa,
tanpa pg_temp justru tak bisa dibayangi tabel-temp, jadi bukan cacat; tidak saya klaim).

Bahan-2026-09-17 (5 berkas, 105 baris): 01 — revoke hilang + aritas `izin_efektif` salah
(`(uuid,text,uuid)` vs nyata `(text,uuid)`, terverifikasi); 02 — policy `is not null` lintas resto;
03 — cek lebih-bayar mengabaikan `p_jumlah` + tanpa cek penyewa/izin (+ dugaan race jumlah);
04 — "10 kali" salah (nyata 5×/12×) + rujukan mati `docs/PANDUAN_KEAMANAN.md` + jalur salah
`aplikasi/pratinjau.sh` (nyata `aplikasi/alat/pratinjau.sh`), ketiganya terverifikasi;
05 — ambang 20→5 (+ dugaan gagal-terbuka SKIP). Semua klaim "pasti" diverifikasi ke kebenaran repo.

Catatan mekanisme (→ §8): 2/4 tanaman pr-bahan sudah mati tertimpa migrasi 0012/0013 — bahan
kalibrasi menua; peninjau berikutnya butuh bahan segar agar "suite hanya menangkap 2/4" tidak
dibaca sebagai suite yang lemah.

## 6. Yang tidak bisa saya verifikasi

- Perilaku di PostgreSQL/Supabase nyata (RLS, GUC `resto.*`, `auth.uid()`, trigger): seluruh bukti
  SQL saya berjalan di pg-mem dalam Node. Khusus PR-01, GUC kustom di Supabase nyata mungkin
  berperilaku berbeda (tidak bisa `set_config` dari klien?) — tetapi pemicu yang mempercayai GUC
  tetap cacat secara desain; butuh rehearsal T0-08.
- Edge Function live: tidak ada akun Supabase (T0-08/T0-00 terbuka); jalur HTTP, header bukti
  perangkat, dan batasan GUC tidak teruji. PR-07 sisi-DB terbukti; sisi-Edge dinilai dari baca kode.
- Data produksi: tidak ada — dampak PR-09 (berapa akun warisan) dan PR-15 (berapa nota) tak terukur.
- Isi 200-an berkas Hijau tidak saya baca baris-per-baris (sampling + `periksa-rujukan.py`).
- Alasan `cancelled` pada check-run 93a50ba (diduga push susulan; API hanya memberi status).
- Klaim 7–8 berasal dari pesan commit leluhur dalam rentang (bukan pesan 93a50ba) — perilaku yang
  diklaim terverifikasi pada tree 93a50ba; niat aslinya saya tafsir dari teks butir.

## 7. Pernyataan tidak mengubah apa pun

Saya tidak mengubah satu baris pun kode/dokumen proyek: seluruh pengujian destruktif (mutasi
9999, `--siapkan`, terapan diff kalibrasi) saya jalankan di worktree sekali-pakai `/tmp/rb-p16`
dan `/tmp/rb-kal` (terverifikasi kembali bersih/dibuang), dan probe saya tinggal di `/tmp`
(di luar repo). Saya bukan sesi penulis PR (sesi peninjau independen `arena/01a0b85b`).
Laporan ini satu-satunya berkas yang saya buat.

## 8. Temuan di luar cakupan diff

| # | Temuan | Tindak lanjut yang disarankan |
|---|---|---|
| L-1 | Re-ukur F-11 (TERBUKA, dipagari): probe P5a/P5b membuktikan ulang batas per-perangkat lolos via rotasi nama (16 PIN-salah tanpa kunci vs kontrol terkunci di #13) — sesuai catatan-jujur `docs/KEAMANAN.md` §2. Bukan temuan baru; pagarnya terverifikasi (`percobaan_pin_perangkat.sql` LOLOS dalam 41; baris AUDIT_RIWAYAT §1b masih TERBUKA→T1-24) | Biarkan terpagar; tutup via T1-24 sesuai rencana; jangan hitung sebagai temuan PR ini |
| L-2 | `lanjut-sesi.py --siapkan` keluar exit 0 walau mencetak GAGAL (cabang tujuan tak ada) — perilaku aman (berkas tak ditulis) tetapi menyesatkan otomasi `&&` | Kembalikan exit ≠ 0 pada jalur GAGAL; tambah kasus uji-diri |
| L-3 | `PROJECT_STATE.md` DETAIL memuat "21 berkas uji SQL, 21 LULUS" (konteks T1-23, kini 41) tanpa penanda tanggal — pembaca sekilas melihat dua angka kini yang bertentangan dengan STATUS.md "41/41" | Beri penanda tanggal "(saat T1-23, 2026-09-16)" atau pindahkan ke riwayat |
| L-4 | `docs/KEAMANAN.md` §5 ("Tanpa perangkat terdaftar, PIN tidak menghasilkan sesi") dibaca sebagai fakta kini padahal penegakan perangkat = T1-24 (belum ada) — pola penanda-jujur §2 tidak dipakai di §5 | Tambah penanda "berlaku sejak T1-24" seperti §2 |
| L-5 | Bahan kalibrasi menua: 2/4 tanaman pr-bahan mati tertimpa migrasi (bukti §5) | Terbitkan bahan segar tiap N putaran; arsipkan yang lama (jangan hapus — riwayat) |
| L-6 | `menu_habis()` hanya dipanggil dari berkas uji — tidak ada penegakan DB bahwa item habis tak bisa dipesan (dicek via grep; tanpa klaim yang dilanggar sehingga bukan temuan, hanya dicatat) | Putuskan di T1-07/T1-12: jadikan pemicu atau tandai helper-uji |