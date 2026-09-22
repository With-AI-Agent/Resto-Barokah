# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-19

- **Auditor:** Arena Agent Mode — sesi auditor `arena/01a0b85b-resto-barokah` (sesi baru, hanya-baca)
- **Tanggal:** 2026-09-19
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `93a50baccffc23ca0f41a9f636fed03b447ae391` ("Tutup 2 cacat nyata yang ditemukan saat menyiapkan putaran verifikasi") — sesi auditor ini dinyalakan dari `main` (`253d129…`, pohon template, shallow); sesuai LANGKAH 0 paket, saya `git fetch origin '+refs/heads/*:refs/remotes/origin/*'` lalu `git checkout --detach 93a50baccffc23ca0f41a9f636fed03b447ae391`. SEMUA perintah di laporan ini dijalankan pada commit itu.
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-19.md` (ditempel ke sesi; berkas paket itu sendiri belum ada di commit `93a50ba` — di commit itu paket terbaru yang tersimpan adalah `AUD-3-2026-09-18.md`, lihat bagian 6)
- **Mode cakupan:** menyeluruh
- **Verdict:** TIDAK-BERSIH

## 1. Cakupan

Cakupan menyeluruh: 436 dari 436 berkas — setiap grup di bawah mendapat minimal satu sapuan otomatis penuh-pohon yang saya jalankan sendiri (`python3 alat/periksa-rahasia.py` dan `python3 alat/periksa-bersih.py` memindai seluruh 2242 berkas terlacak termasuk semua grup proyek; `python3 _sistem/validate_system.py`, `python3 alat/periksa-rujukan.py`, `python3 alat/periksa-panduan.py` memindai seluruh dokumen; `python3 prototipe/uji-kontras.py` & `python3 aplikasi/alat/uji-kontras.py` mem-parsing seluruh CSS/HTML prototipe+aplikasi; `python3 aplikasi/alat/periksa-antarmuka.py` & `periksa-kerapatan.py` mem-parsing gaya) **ditambah** bacaan langsung/terarah pada berkas inti per grup seperti tabel berikut. Saya tidak mengklaim membaca mendalam 436 berkas satu per satu — kedalaman bacaan saya: semua migrasi SQL (14 berkas, utuh), Edge Function (utuh), perkakas pemeriksa (dijalankan + sebagian dibaca), dokumen pengguna (utuh atau bagian yang diklaim), sisanya lewat sapuan mesin.

| # | Artefak | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|
| 1 | **GRUP supabase/migrations (15 berkas)** — 0001–0014 dibaca UTUH | Ya | `cat supabase/migrations/000{1..14}*.sql`; `wc -l` = 4857 baris SQL |
| 2 | **GRUP supabase/tes (42 berkas)** | Ya | `ls supabase/tes \| wc -l` → 41 + `.gitkeep`; jumlah asersi: 30 `uji.harap` · 150 `uji.harap_gagal` · 400 `uji.sama`; `supabase/tes/diskon_setuju.sql` dibaca utuh |
| 3 | **GRUP supabase/functions (2 berkas)** | Ya | `supabase/functions/verifikasi_pin/index.ts` dibaca utuh; `python3 alat/periksa-fungsi-pin.py` → "9 lolos, 0 gagal" |
| 4 | **GRUP supabase (akar, 1)** | Ya | `head supabase/README.md` (tabel isi folder) |
| 5 | **GRUP alat (40 berkas)** | Ya | 15 pemeriksa dijalankan (semua LOLOS, keluaran di bawah); `alat/audit-independen.py:219-227` & `alat/uji-sql.mjs:140-185` dibaca (dipakai sebagai bukti F-03 & lensa L4) |
| 6 | **GRUP aplikasi/src (71 berkas)** | Ya | `App.tsx`, `lib/env.ts`, `lib/tema.ts`, `lib/format.ts`, `hook/useTema.ts` dibaca; `find aplikasi/src -name '*.test.ts*' \| wc -l` → 10; `grep -rE "^\s*(it\|test)\(" ...` → 76 asersi; 19 `.woff2` terhitung |
| 7 | **GRUP aplikasi/alat (8 berkas)** | Ya | `periksa-struktur` (29 OK·0 GAGAL), `periksa-komponen-env` (10 OK·0 GAGAL), `periksa-uji` (6 OK·0 GAGAL), `periksa-kerapatan` (LOLOS), `periksa-antarmuka` (LOLOS), `uji-kontras` (166 lolos·0 gagal) — semuanya dijalankan |
| 8 | **GRUP aplikasi konfigurasi (16 berkas)** | Ya | `.env.example` dibaca utuh; `git check-ignore -v aplikasi/.env` → `aplikasi/.gitignore:4`; `grep strict\|noUnused aplikasi/tsconfig.app.json` → ketiganya `true` |
| 9 | **GRUP _sistem (15 berkas)** | Ya | `python3 _sistem/validate_system.py` → "SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS"; daftar isi diperiksa |
| 10 | **GRUP docs fondasi (11 berkas)** | Ya | ROADMAP status T0/T1 dibaca; `sed -n "$(grep -n '^## 6' docs/TECH_SPEC.md \| head -1 \| cut -d: -f1),+14p" docs/TECH_SPEC.md` (§6 utuh); `docs/KEAMANAN.md:160-180` (§11–12); `docs/TERTANGGUH.md` utuh; `docs/DECISIONS_LOG.md:1-8`, `docs/SPESIFIKASI_UI.md:1-6`, `docs/AGENT_OPERATING_GUIDE.md:1-6`, `docs/PANDUAN_PEMILIK.md:1-8` |
| 11 | **GRUP docs/uji (65 berkas)** | Ya | PROTOKOL_AUDIT_INDEPENDEN (utuh), AUDIT_RIWAYAT & DAFTAR_PEKERJAAN_ULANG (baris temuan terbuka), PROMPT_AUDIT_INDEPENDEN (kepala), BUKU_UJI_PEMILIK (kepala; `alat/periksa-buku-uji.py` LOLOS), kalibrasi `bahan-2026-09-17` (5 berkas dibaca utuh) |
| 12 | **GRUP docs/teknis (6 berkas)** | Ya | BUKU_INSIDEN (kepala, 12 bab), REKAM_PESAN_PEMILIK (rujukan dicek `periksa-rujukan`) |
| 13 | **GRUP docs/ops (5 berkas)** | Ya | `docs/ops/SIAP_AKUN_PEMILIK.md` dibaca utuh; `docs/ops/SIAP-LANJUT.md:8-16` (dasar F-07); `ls docs/ops/` → 5 berkas semuanya teridentifikasi |
| 14 | **GRUP docs/desain (59 berkas)** | Ya | `ls docs/desain \| head -5` (PENILAIAN_REFERENSI.md, RENCANA_DESAIN_UI.md, mockup/, palet-tema.png, papan-referensi-pemilik.jpg); kepala dua berkas utama dibaca |
| 15 | **GRUP prototipe (58 berkas)** | Ya | README (kepala), `python3 prototipe/uji-kontras.py` → "166 lolos, 0 gagal" |
| 16 | **GRUP _log-sesi (4 berkas)** | Ya | `ls _log-sesi/` → 4 berkas (2026-09-15/16/17/18); `_log-sesi/LOG_SESI_2026-09-18.md:1-8` (CLOSED, putaran 14–16) dibaca |
| 17 | **GRUP berkas pengguna akar (17 berkas)** | Ya | lihat §1a (`PROMPT_ENTRI_UNIVERSAL.md` utuh; `START_DI_SINI.md:1-30`; `STATUS.md:1-20`; `PROJECT_STATE.md:1-12`; `PROFIL_PENGGUNA.md:1-6`; `AGENT_SYSTEM.md:1-5`; `SYSTEM_MANIFEST.md:1-6`; `PROMPT_SESI_BARU.md:1-6`; `PANDUAN_PEMAKAIAN.md:1-5`; `10_LOG_SESI.md:1-4`; `REKAM-KLINIK.md:1-4`; `ACCEPTANCE_TESTS.md:1-4`) |
| 18 | **GRUP .github/workflows (1 berkas)** | Ya | `ci.yml` dibaca utuh (gerbang lint/tipe/uji/uji-SQL/mutasi/pemeriksa, `fetch-depth: 0`) |
| 19 | GRUP "belum berggrup" | n/a | 0 berkas — `git ls-files \| wc -l` = 2242 = 436 cakupan + 1803 `skills/` + 2 `_salinan-meta/` + 1 `_Notes.md` (cocok dengan tabel grup paket) |
| 20 | pengecualian paket: `skills/` (1803), `_salinan-meta/` (2), `_Notes.md` (1) | Setuju | Bukan kode proyek: skill pihak ketiga (vendored, dipakai `mulai-sesi.py`), arsip provenance, catatan pribadi. `skills/` tetap ikut sapuan `periksa-rahasia.py` (LOLOS). 2242 − 1803 − 2 − 1 = 436 ✓ |

### 1a. Berkas untuk pengguna

| Berkas untuk pengguna | Cara diperiksa (cara pengguna) | Hasil (bukti: `perintah` / `berkas:baris`) |
|---|---|---|
| `PROMPT_ENTRI_UNIVERSAL.md` (utuh) + rujukannya | `[ -e alat/mulai-sesi.py ] && [ -e alat/lanjut-sesi.py ] && [ -e docs/ops/SIAP-LANJUT.md ] && [ -e PROMPT_SESI_BARU.md ] && [ -e aplikasi/alat/pratinjau.sh ] && [ -e alat/pulihkan-git.sh ]` — semua ADA; blok prompt disalin-baca apa adanya | Prompt bisa disalin & bekerja; satu-satunya jalan buntu yang mengikuti alurnya adalah ISI handoff `SIAP-LANJUT.md` yang basi (F-07) dan keadaan cabang remote (§8-01), bukan promptnya |
| `docs/ops/SIAP_AKUN_PEMILIK.md` (utuh) | dibaca sebagai pemilik non-teknis: 2 bagian bernomor, hanya meminta `Project URL` + `anon`, melarang `service_role` masuk chat | Langkah bisa diikuti orang awam, konsisten dengan `docs/TECH_SPEC.md:§6` & T-018; tidak ada rujukan berkas mati |
| `PANDUAN_PENGGUNA.md` (buku induk, 725 baris) | `python3 alat/periksa-panduan.py` → "LOLOS — 725 baris · 13 alur · 4 blok prompt · 30 perintah · 13 mekanisme · 83 rujukan berkas"; struktur A–H dicek manual (`grep -n "^## Bagian" PANDUAN_PENGGUNA.md` → A,B,C,D,E,F,G,H) | Lengkap; 2 rujukan `rencana` ditandai jelas |
| `START_DI_SINI.md`, `STATUS.md`, `PROJECT_STATE.md`, `PROFIL_PENGGUNA.md`, `AGENT_SYSTEM.md`, `SYSTEM_MANIFEST.md` | `head -20..30` tiap berkas; silang-referensi antar berkas | Konsisten satu sama lain; catatan: klaim "CI HIJAU" di `STATUS.md`/`PROJECT_STATE.md` benar untuk commit penutup sesi (0af1cf9) tetapi TIDAK untuk commit audit 93a50ba (F-04) |
| `10_LOG_SESI.md`, `REKAM-KLINIK.md`, `ACCEPTANCE_TESTS.md`, `ACCEPTANCE_TEST_LOG.md`, `PANDUAN_PEMAKAIAN.md`, `PROMPT_SESI_BARU.md`, `_log-sesi/LOG_SESI_2026-09-18.md`, `docs/teknis/BUKU_INSIDEN.md`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, `docs/PANDUAN_PEMILIK.md` | `head` tiap berkas; `python3 alat/periksa-buku-uji.py` → LOLOS (3 baris lakukan · 8 baris coba) | `PANDUAN_PEMAKAIAN.md` berlabel jelas "VERSI LAMA — JANGAN DIIKUTI" (arsip, aman); `PROMPT_SESI_BARU.md` statis dengan baris pilihan kosong menunggu Lee; sisanya hidup & konsisten |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T0-01: "19 berkas `.woff2` di aplikasi" | `find aplikasi/src/gaya/aset -name '*.woff2' \| wc -l` | **19** — klaim BERHASIL DIBANTAH namun BERTAHAN (benar) |
| 2 | T0-03: "`tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css`" | `diff -q aplikasi/src/gaya/token/tema.css prototipe/css/tokens.css` | Tidak ada selisih — identik; klaim bertahan |
| 3 | T0-04/T0-08/T0-10: "76 uji hijau dalam 10 berkas" | `find aplikasi/src -name '*.test.ts*' \| wc -l` → 10; hitung `it(`/`test(` → 76 | Jumlah berkas & asersi COCOK. **Tetapi** `npm test` tidak bisa saya jalankan (node_modules absen; paket melarang memasang) → "hijau" tidak bisa direproduksi di sini (bagian 6) |
| 4 | T0-02: TS ketat `strict`, `noUnusedLocals`, `noUnusedParameters` | `grep` tsconfig.app.json | Ketiganya `true` — bertahan; `tsc`/`eslint` tak bisa dijalankan lokal (bagian 6) |
| 5 | T0-05: `.env.example` memuat semua 8 nama variabel TECH_SPEC §6, hanya 2 `VITE_` aktif | baca `.env.example` + TECH_SPEC §6 | 2 aktif + 7 rahasia dikomentari (RESEND & BREVO dua-duanya ada) → semua slot §6 terwakili; `git ls-files \| grep -i .env` hanya `.env.example`; `git check-ignore aplikasi/.env` → diabaikan. Klaim bertahan |
| 6 | T0-07: CI bisa MERAH — run 35121292973, 35120922393, 35121062046 | `gh api repos/…/actions/runs/<id>` | Ketiganya `conclusion: failure` — klaim bertahan (bukti merah nyata); `ci.yml` menyala di semua push & PR |
| 7 | T1-09: salinan beku `nama_saat_itu`/`harga_saat_itu` tidak boleh berubah | baca trigger `picu_item_salinan_beku` (0009:226-240) + `supabase/tes/harga_item.sql` ada | Trigger menolak perubahan nama/harga/menu/pesanan pada UPDATE — klaim bertahan (statis) |
| 8 | T1-23: peran tunggal, kolom `pengguna_cabang.peran` dihapus | baca `0011_peran_tunggal.sql:27` (`alter table … drop column if exists peran`) + `izin_efektif` versi 0011 membaca `pengguna.peran` | Klaim bertahan |
| 9 | 0010 PENJAGA 1: "angka uang hanya dari peladen" | baca `picu_pesanan_jaga_uang` + `peran_peladen()` (bukan security definer, cek `current_user` pemilik tabel / keanggotaan service_role) | Penjaga nyata dan tidak bisa dipalsukan klien — klaim bertahan. Implementasinya mendarat lewat 0014 `hitung_total` padahal T1-15 masih `[ ]` → F-06 |
| 10 | Paket §1b: "sudah [x] — berkasnya TIDAK ADA: laporkan!" untuk `alat/periksa-roadmap.py`, `alat/periksa-panduan.py`, `_sistem/validate_system.py`, `alat/uji-mutasi-0012.py`, `node alat/uji-sql.mjs`, `aplikasi/src/lib/tema.ts` | `[ -e ]` untuk tiap jalur | **SEMUA ADA** di commit audit → klaim paket SALAH; kalau dipatuhi, auditor akan membuat temuan palsu. Akar: `alat/audit-independen.py:219` menyerap string perintah backtick dari blok tugas sebagai "jalur berkas" → F-03 |
| 11 | PROJECT_STATE/STATUS: "CI HIJAU" sebagai keadaan terkini | `gh api …/commits/93a50ba…/check-runs` | 2 check-run, keduanya `cancelled` — commit audit TIDAK pernah lolos CI → F-04 (temuan B F-17 yang terbuka, berulang) |
| 12 | PROTOKOL §7: "kunci jawaban kalibrasi ada di luar repo, dilarang dicari" | penelusuran folder kalibrasi (tanpa mencari kunci) | **DIBANTAH**: docs/uji/kalibrasi/pr-bahan-2026-09-17.diff DI DALAM repo memuat diff migrasi-nyata→versi-cacat (= kunci) → F-05 |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | Sapuan RLS menyeluruh: ada tabel tanpa RLS/policy, atau tabel ber-`penyewa_id` yang policy-nya tidak menyebut `penyewa_saya()` | parser Python inline atas 14 migrasi (meniru logika `rls_semua_tabel.sql`): 26 tabel diekstrak, dicocokkan dgn `enable row level security`, `create policy`, dan `penyewa_saya` | **0 temuan**: semua tabel RLS+policy; tabel ber-`penyewa_id` lewat `penyewa_saya()` atau helper `pesanan_sepenyewa()`; tidak ada VIEW sama sekali (jadi tak ada jalur `security_invoker`) |
| 2 | Baca data resto lain lewat fungsi SECURITY DEFINER (`izin_efektif_untuk`, `boleh_untuk`, `total_dibayar`, `hitung_total`, `harga_berlaku`, `menu_habis`) | baca isi tiap fungsi: cari pemeriksaan `auth.uid() is not null and … <> penyewa_saya()` | Semua berpemeriksaan penyewa (0010: total_dibayar & hitung_total menolak bila `pesanan_sepenyewa` gagal; 0006/0012 `izin_efektif_untuk` menolak lintas penyewa; 0007 `harga_berlaku`/`menu_habis` menyaring `penyewa_saya()` — untuk anon hasil selalu kosong). GAGAL ditembus |
| 3 | Karang angka uang dari klien: `UPDATE pesanan SET total=1` | telusuri policy `pesanan_ubah` (mengizinkan kasir/pelayan) × trigger `pesanan_jaga_uang` (0010) | Trigger (bukan definer) menolak perubahan kelima kolom uang dari pemanggil ber-identitas; hanya `hitung_total()` (definer) boleh menulis. GAGAL |
| 4 | Pesanan lahir `lunas`/`batal` via INSERT langsung | telusuri `picu_pesanan_status_awal` (0013, sengaja bukan definer) | INSERT klien wajib `draf`, tanpa tanda kirim/bayar/batal. GAGAL |
| 5 | Dobel pembayaran / lebih bayar / bayar pesanan batal | telusuri `picu_pembayaran_jujur` (versi 0012): `for update` pada baris pesanan, tolak `status='batal'`, tolak `total<=0`, `total_dibayar+jumlah > total` → tolak, `kunci_idempoten` unik per pesanan | Semua jalur tertutup; dua pembayaran bersamaan diserialisasi kunci baris. GAGAL |
| 6 | Diskon di atas batas / jenis liar | telusuri `picu_diskon_batas` versi 0013: `manual` = `boleh('beri_diskon', nilai, persen-efektif)`; `promo` & `voucher` = DITOLAK gagal-aman (mesinnya belum ada); jenis tak dikenal ditolak | Per-baris + kumulatif ≤ subtotal + cap resto (persen & nominal) diperiksa. GAGAL (tapi lihat F-01: tidak ada cek STATUS pesanan) |
| 7 | Tanam diskon saat subtotal masih 0 (menempel selamanya, baris append-only) | 0013: `if coalesce(subtotal,0) <= 0 then raise` | Ditolak. GAGAL |
| 8 | Void sesudah dapur tanpa PIN, atau satu PIN untuk banyak pesanan | telusuri `picu_pembatalan_sah` (0013): kupon = baris `percobaan_pin` berhasil+aksi+**pesanan_id cocok**+`dipakai_pada is null`+≤5 menit, `for update`, lalu ditandai dipakai | Tanpa kupon tertolak; kupon sekali pakai. GAGAL — TAPI konsekuensinya F-02: kupon tak bisa DIHASILKAN lewat Edge Function |
| 9 | Batalkan item / kecilkan qty setelah dapur mulai tanpa jejak | telusuri `picu_item_jaga` (0014): batal/qty turun sesudah dapur wajib konfigurasi transaksi `resto.pembatalan_pesanan` yang hanya diset trigger `pembatalan_jejak` (transaction-local `set_config(..., true)`) | Ditolak kecuali dalam transaksi pembatalan resmi yang sama. GAGAL |
| 10 | Rampok PIN atasan (admin ganti PIN owner lalu menyetujui void atas namanya) | telusuri `simpan_pin` versi 0014: `peran_lebih_tinggi(pemanggil, target)` wajib lebih tinggi; kegagalan dicatat di `percobaan_simpan_pin` (kolom `target_id`, korban boleh melihat) | Ditolak untuk bawahan→atasan. GAGAL |
| 11 | Baca hash PIN / catatan pemasangan PIN dari klien | cek grant & policy: `kredensial_pin` (revoke all + policy `using (false)`), `percobaan_simpan_pin` (revoke + policy deny, korban hanya melihat baris `target_id = auth.uid()`), `percobaan_pin` hanya select terbatas, insert hanya lewat fungsi definer | Tidak ada jalur baca/tulis langsung. GAGAL |
| 12 | Naik peran / pilih cabang sembarangan lewat klaim token atau metadata | 0011 `izin_efektif` membaca `pengguna.peran` (tabel, bukan JWT metadata); `cabang_saya()` versi 0012 membaca `sesi_cabang` (policy deny-all) yang hanya diisi `pilih_cabang(uuid)` setelah verifikasi keanggotaan; trigger `pengguna_cabang_jaga_keanggotaan` menolak keanggotaan lintas-resto & pemilik platform | GAGAL |
| 13 | Menebak PIN kolega (oracle & brute force) | `verifikasi_pin` versi 0012: 6 digit tepat, 5 gagal/pencoba-akun & 12/perangkat per 15 menit dihitung per PEMCOBA (`pemanggil_id`), jawaban seragam utk target tak dikenal, `simpan_pin` anti-oracle keunikan 20/15 menit | Laju tebak ≈ maks 480/hari/akun → 6 digit tidak praktis. GAGAL |
| 14 | Dapur/kasir melompati status (`dimasak`→`lunas`), hapus tanda kirim dapur | `picu_pesanan_jaga_status` (0009, bukan definer): satu-satunya perpindahan klien = draf→dikirim (dgn waktu kirim) & dapur maju; sisanya ditolak; `dikirim_ke_dapur_pada` tak bisa diubah/hapus | GAGAL |
| 15 | Karang jejak: `kasir_id` orang lain, tanggal mundur, nomor pilihan sendiri | `picu_pesanan_jejak_jujur` (0014): kasir_id & tanggal & nomor diisi sistem, UPDATE menolak perubahan ketiganya; pelayan wajib anggota cabang | GAGAL |
| 16 | Hapus meja yang sedang dipakai / kasir mengubah nama meja | `picu_meja_jaga` (0014): DELETE ditolak bila ada pesanan aktif; non-admin hanya boleh menyentuh status | GAGAL |
| 17 | Stok arah karangan (`jenis='keluar', jumlah=+7`) atau tulis saldo langsung | `picu_stok_arah_jujur` (0014) menormalkan tanda per jenis; `picu_jaga_jumlah_stok` (bukan definer) menolak perubahan `stok_bahan.jumlah` di luar buku besar; policy insert buku besar wajib `boleh('ubah_stok')` | GAGAL |
| 18 | Serang mesin auditnya sendiri: paket & CI | `python3 alat/audit-independen.py --verifikasi-lingkup` (menunjuk paket lama AUD-3-2026-09-18 → target 52e22fc — CATATAN, bukan penghalang); `gh api check-runs` untuk commit audit; `[ -e ]` untuk tiap jalur §1b paket | Commit target ADA & saya periksa; CI commit audit = cancelled (F-04); 7 jalur §1b "TIDAK ADA" ternyata ADA (F-03) — mesin auditnya sendiri kena |

## 4. Temuan

### [F-01] Diskon masih bisa dicatat pada pesanan `lunas`/`batal` — total pesanan berubah SETELAH uang tercatat
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0013_penutup_celah_putaran11.sql:24-118` (`picu_diskon_batas` — tanpa satu pun pemeriksaan status pesanan) · `supabase/migrations/0014_penutup_celah_putaran13.sql:117-152` (`hitung_total` — menghitung ulang tanpa memeriksa status) · `supabase/migrations/0010_pembayaran.sql` policy `diskon_transaksi_tambah` (tanpa syarat status)
- **Klaim yang dilanggar:** 0010 PENJAGA-1 & komentar `pesanan`: "riwayat tidak bisa berubah artinya"; ART-3 (riwayat beku); `item_jaga` 2b sendiri menyatakan "Pesanan yang sudah lunas/batal TIDAK boleh diubah lagi" — tetapi hanya untuk ITEM, tidak untuk DISKON.
- **Bukti:** `awk '/create or replace function public.picu_diskon_batas/,/^end;/' supabase/migrations/0013_penutup_celah_putaran11.sql | grep -n status` → tidak ada pemeriksaan status di badan fungsi; `awk '/create or replace function public.hitung_total/,/^\$\$;/' supabase/migrations/0014_penutup_celah_putaran13.sql | grep status` → hanya `pi.status <> 'batal'` untuk item (bukan status pesanan); `grep 'grant select, insert on … diskon_transaksi' 0010` → append-only (diskon tak bisa dihapus klien, jadi kerusakan menempel permanen).
- **Skenario gagal:** pesanan berstatus `lunas` (sudah dibayar penuh, mis. total 100.000) → kasir (batas sah 25.000/5%, atau bertumpuk bila owner menyalakannya) menyisipkan `diskon_transaksi` untuk pesanan itu → pemicu menyetujui (semua syaratnya lolos: jenis manual dalam batas, subtotal > 0, cap terhormat) → `diskon_hitung_total` memanggil `hitung_total` → `pesanan.total` MENGURANG padahal pembayaran 100.000 sudah tercatat append-only. Laporan penjualan (T7) akan menunjukkan total ≠ uang masuk untuk transaksi tertutup, dan selisihnya tak bisa dipulihkan lewat jalur mana pun.
- **Dugaan penyebab:** perbaikan berlapis (0012→0013→0014) berfokus pada batas nominal/persen dan tahap dapur; syarat "pesanan masih terbuka" tertangani untuk item (`item_jaga` 2b) dan pembayaran (`picu_pembayaran_jujur` hanya menolak `batal`) tetapi terlewat untuk diskon.
- **Cara membuktikan perbaikan:** migrasi baru yang menolak `diskon_transaksi` (dan idealnya membekukan `hitung_total`) ketika `pesanan.status in ('lunas','batal')`, lalu uji negatif dengan sebab-tertentu: `uji.harap_gagal_sebab($$insert into diskon_transaksi … pesanan lunas …$$, 'lunas|batal|tertutup', …)` hijau di `node alat/uji-sql.mjs`.
- **Status verifikasi:** TERVERIFIKASI (jalur kode lengkap dan tertutup secara statis; pelaksanaan dinamis tidak mungkin di sesi ini — lihat bagian 6)

### [F-02] Edge Function `verifikasi_pin` tidak bisa meneruskan `p_pesanan_id` — kupon persetujuan (void sesudah dapur & diskon berstempel) mustahil dihasilkan lewat satu-satunya gerbang PIN di repo
- **Tingkat:** K-3
- **Artefak:** `supabase/functions/verifikasi_pin/index.ts:52-58,74-79` vs `supabase/migrations/0012_penutup_celah_review.sql:243-249` (signature 5-argumen; versi 4-argumen di-drop) & `0013:…` (`pp.pesanan_id = new.pesanan_id` wajib)
- **Klaim yang dilanggar:** header Edge Function "Tugasnya … meneruskan ke fungsi database"; kontrak kupon 0012/0013 ("bukti persetujuan harus TERIKAT pesanan ini").
- **Bukti:** isi fungsi hanya mengekstrak `pengguna_id, pin, aksi, perangkat` dari body dan mengirim `JSON.stringify({p_pengguna_id, p_pin, p_aksi, p_perangkat})` — tidak ada field `pesanan_id`; padahal `picu_pembatalan_sah` (0013) & `picu_diskon_setuju_jujur` (0014) menuntut `percobaan_pin.pesanan_id = <pesanan>`.
- **Skenario gagal:** atasan memasukkan PIN utk menyetujui void lewat Edge Function → baris `percobaan_pin` lahir dengan `pesanan_id = null` → `pembatalan_sah` tidak menemukan kupon → "Persetujuan belum terbukti untuk pesanan ini" SELALU, untuk pesanan mana pun. Fitur void-sesudah-dapur buntu lewat jalur resmi; tekanan fungsional untuk melemahkan penjaga kupon di masa depan.
- **Dugaan penyebab:** signature DB ditambah `p_pesanan_id` di 0012 tetapi Edge Function (T1-06) tidak ikut direvisi; tidak ada uji yang menyambungkan Edge Function ↔ kupon (uji SQL memanggil RPC langsung dengan `p_pesanan_id`).
- **Cara membuktikan perbaikan:** Edge Function menerima & meneruskan `pesanan_id` (uji `alat/periksa-fungsi-pin.py --uji-diri` diperluas), plus satu uji end-to-end di `supabase/tes/` yang mensimulasikan payload Edge Function dan menghasilkan kupon yang lulus `pembatalan_sah`.
- **Status verifikasi:** TERVERIFIKASI

### [F-03] Generator paket audit menghasilkan baris "berkasnya TIDAK ADA: laporkan!" yang PALSU — memancing temuan palsu
- **Tingkat:** K-3
- **Artefak:** `alat/audit-independen.py:219-227` (regex backtick menyerap string perintah dari blok tugas, lalu diuji sebagai jalur berkas); paket `AUD-3-2026-09-19.md` bagian 1b
- **Klaim yang dilanggar:** catatan mesin paket: "daftar di atas SUDAH disaring… Kalau kamu menemukan jalur di bagian 1 yang tidak ada, laporkan sebagai temuan mesin" — premisnya adalah 1b memuat hanya jalur yang benar-benar belum ada.
- **Bukti:** `[ -e … ]` pada commit `93a50ba`: `alat/periksa-roadmap.py`, `alat/periksa-panduan.py`, `_sistem/validate_system.py`, `alat/uji-mutasi-0012.py`, `alat/uji-sql.mjs`, `aplikasi/src/lib/tema.ts` — SEMUANYA ADA, tetapi paket menandainya "(sudah [x] — berkasnya TIDAK ADA: laporkan!)". Akar terbaca di kode: baris 219 `re.findall(r"`([^`]+\.(?:sql|ts|tsx|py|mjs|yml|json|md))`", isi)` juga menangkap perintah di **Verifikasi/Bukti**, mis. `python3 alat/periksa-roadmap.py` (ROADMAP baris 11 & 143), yang jelas bukan jalur.
- **Skenario gagal:** auditor patuh mengikuti 1b → melaporkan 6+ "tugas sudah [x] tapi berkasnya tidak ada" yang semuanya salah → riwayat audit tercemar temuan palsu dan pembangun membuang waktu menutupnya.
- **Dugaan penyebab:** deteksi "belum ada" dijalankan pada SEMUA string berekstensi dalam blok tugas, tanpa memisahkan perintah verifikasi dari rujukan berkas.
- **Cara membuktikan perbaikan:** `python3 alat/audit-independen.py --paket AUD-3 --semua` pada commit yang sama tidak lagi menandai jalur-jalur itu; uji-dirinya (`--uji-diri`) diberi kasus perintah-berbacktick.
- **Status verifikasi:** TERVERIFIKASI

### [F-04] Commit yang diaudit (`93a50ba`) tidak pernah lolos CI — kedua check-run-nya `cancelled`
- **Tingkat:** K-3
- **Artefak:** commit `93a50baccffc23ca0f41a9f636fed03b447ae391`; klaim keadaan di `PROJECT_STATE.md`/`STATUS.md` ("CI HIJAU")
- **Klaim yang dilanggar:** temuan audit sebelumnya B F-17 (status TERBUKA, ditujukan T1-44): "Commit yang diaudit tidak pernah dilewatkan CI" — pola yang sama berulang untuk putaran ini.
- **Bukti:** `gh api repos/With-AI-Agent/Resto-Barokah/commits/93a50baccffc23ca0f41a9f636fed03b447ae391/check-runs` → 2 check-run "Periksa (lint · tipe · uji · pemeriksa Python)", keduanya `conclusion: cancelled` (run 35424252489 push, 35424254943 pull_request). CI hijau terdekat adalah commit LAIN (bdf8a86 dst.) yang isinya sudah berbeda.
- **Skenario gagal:** paket audit dibuat dari commit yang belum pernah dibuktikan hijau; kalau suite di commit itu sebenarnya MERAH, auditor adalah orang pertama yang menangkapnya — tanpa jaring CI.
- **Dugaan penyebab:** `concurrency: cancel-in-progress` membatalkan run push ketika run PR menyusul, dan paket tetap dibuat tanpa menunggu run selesai (aturan T1-44 belum diterapkan).
- **Cara membuktikan perbaikan:** `gh api …/commits/<sha-paket>/check-runs` menampilkan minimal satu `success` sebelum `--paket` diizinkan (T1-44).
- **Status verifikasi:** TERVERIFIKASI

### [F-05] Kunci jawaban kalibrasi cacat tanaman tertanam DI DALAM repo
- **Tingkat:** K-2
- **Artefak:** docs/uji/kalibrasi/pr-bahan-2026-09-17.diff (ikut ter-commit)
- **Klaim yang dilanggar:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 & paket §0b: "kunci jawabannya disimpan di luar repo dan tidak boleh kamu cari".
- **Bukti:** `cat docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` → diff dari migrasi NYATA ke versi CACAT, mis. `0004_pola_rls.sql`: `- using (penyewa_id = public.penyewa_saya());` `+ using (penyewa_id is not null);` — persis cacat bahan-02; juga injeksi `0003` (buang `p.aktif`), `0005` (buang `revoke … boleh(text,uuid)`), `0012` (`raise exception` promo → `null`).
- **Skenario gagal:** auditor (atau mesin apa pun yang bisa baca repo) membuka diff → tahu semua lokasi & kelas cacat → skor "Ditemukan: X dari Y" bisa dipalsukan sempurna; ambang kalibrasi ("verdict BERSIH-mu boleh dipercaya") kehilangan makna.
- **Dugaan penyebab:** berkas diff dibuat untuk keperluan menanam bahan lalu ikut ter-commit (jalur mesin kalibrasi seharusnya menyimpan kunci di `/tmp` di luar repo, sesuai §7).
- **Cara membuktikan perbaikan:** `git rm docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` pada batch berikutnya + aturan `periksa-bersih.py`/baru yang menolak berkas `pr-bahan-*.diff` di dalam repo.
- **Status verifikasi:** TERVERIFIKASI (saya menemukan semua cacat bahan SEBELUM membuka diff ini; penemuan dicatat apa adanya di bagian 5)

### [F-06] Jejak syarat→tugas→uji kacau: `hitung_total` & penomoran sudah mendarat di migrasi 0014, tetapi T1-15/T1-17 masih `[ ]` dengan rujukan berkas yang tidak ada
- **Tingkat:** K-3
- **Artefak:** `docs/ROADMAP.md:312` (`- [ ] T1-15 — Fungsi hitung_total() + 12 uji uang`), `:330` (`- [ ] T1-17 — Penomoran pesanan…`) vs `supabase/migrations/0014_penutup_celah_putaran13.sql` (`hitung_total`, `nomor_pesanan_berikutnya`, pemicu hitung ulang)
- **Klaim yang dilanggar:** lensa L3 & `alat/periksa-roadmap.py` ("semua klaim Bukti bisa direproduksi"): tugas menyimpan janji (`0022_hitung_total.sql`, `supabase/tes/uang.sql`, `0024_penomoran.sql`, `supabase/tes/penomoran.sql`, "12 uji uang") yang TIDAK ADA, sementara fungsinya sudah hidup di berkas lain tanpa tugas & tanpa suite uji yang dijanjikan.
- **Bukti:** `[ -e supabase/migrations/0022_hitung_total.sql ]` → tidak ada; `[ -e supabase/tes/uang.sql ]` → tidak ada; `grep -n "hitung_total" supabase/migrations/0014…` → ada (baris 27-100); ROADMAP T1-15/T1-17 masih `[ ]`.
- **Skenario gagal:** sesi berikutnya membaca ROADMAP, menyimpulkan uang belum bisa dihitung → menulis `hitung_total` KEDUA (dua rumus = pelanggaran "satu rumus, tidak diduplikasi"), atau menandai T1-15 selesai dengan bukti yang sebenarnya milik 0014 tanpa 12 uji uang yang dijanjikan.
- **Dugaan penyebab:** penutupan celah audit 2026-09-18 (F-01 lama: "ALUR UANG BUNTU") menanam versi minimal `hitung_total` langsung di migrasi penutup, sementara tugas induknya (dengan DoD penuh + uji) sengaja dibiarkan terbuka — tanpa catatan silang di ROADMAP.
- **Cara membuktikan perbaikan:** ROADMAP T1-15/T1-17 diberi catatan "sebagian mendarat di 0014 (fungsinya X, uji penuh Y tetap wajib)" atau tugas ditutup dengan bukti `node alat/uji-sql.mjs` yang memuat 12 uji uang.
- **Status verifikasi:** TERVERIFIKASI

### [F-07] Handoff mesin `docs/ops/SIAP-LANJUT.md` basi dua commit dan menunjuk cabang lain
- **Tingkat:** K-3
- **Artefak:** `docs/ops/SIAP-LANJUT.md:8-16` (di commit `93a50ba`)
- **Klaim yang dilanggar:** aturan berkas itu sendiri: "berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch"; PROMPT_ENTRI langkah 2c menyuruh sesi baru mengikuti isi berkas ini.
- **Bukti:** `git log --oneline -1 -- docs/ops/SIAP-LANJUT.md` → terakhir ditulis di `0af1cf9`; isi berkas: "Cabang yang dilanjutkan: `arena/01a0a8a2-resto-barokah`", "Commit keadaan kerja: `e8b7919`", "CI terakhir: (run 35418874877) … BUKAN success". Padahal berkas ini dibawa oleh `0af1cf9` dan `93a50ba` yang lahir di cabang `arena/01a0b7d1` (93a50ba = 2 commit di atas e8b7919), dan run yang dirujuk (35418874877) berstatus `cancelled` menurut `gh api`.
- **Skenario gagal:** sesi baru membuka repo dari `main`, mengikuti 2c → melanjutkan `arena/01a0a8a2` (ujungnya `0af1cf9`) → pekerjaan `93a50ba` (penutupan 2 cacat) tidak terlihat dan bisa tertimpa. (Kelas cacat yang sama sudah ditutup pembangun di commit SETELAH audit: `bdf8a86` "Cacat keempat: handoff bisa menunjuk cabang TERTINGGAL" — pada commit yang saya audit, cacatnya masih hidup.)
- **Dugaan penyebab:** `alat/lanjut-sesi.py --di-ci` sengaja hanya memeriksa ISI berkas (baris 271 & 1009: "pemeriksaan kesegaran" tidak dijalankan di CI), sehingga dua commit terakhir lewat tanpa penyegaran handoff.
- **Cara membuktikan perbaikan:** `python3 alat/lanjut-sesi.py` (mode penuh) dijalankan pada commit terakhir tiap batch dan CI menolak handoff yang menunjuk commit/cabang yang bukan leluhur langsung dari HEAD.
- **Status verifikasi:** TERVERIFIKASI

### [F-08] `nomor_pesanan_berikutnya` = `max(nomor)+1` tanpa penguncian — dua pesanan bersamaan bertabrakan
- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:436-447` (`nomor_pesanan_berikutnya`) dipanggil dari `picu_pesanan_jejak_jujur`
- **Klaim yang dilanggar:** komentar sendiri mengakui risikonya ("dua kasir bisa mendapat nomor yang sama dan pesanan gagal karena kunci unik — kegagalan yang membingungkan") tetapi solusinya (definer) hanya menangani RLS, bukan balapan.
- **Bukti:** baca badan fungsi — `select coalesce(max(p.nomor),0)+1 …` tanpa `for update`/advisory lock pada pasangan (cabang, tanggal).
- **Skenario gagal:** dua kasir menyimpan pesanan hampir bersamaan di cabang yang sama → keduanya membaca `max` yang sama → satu INSERT gagal dengan pelanggaran `unique (cabang_id, tanggal, nomor)` — di jam sibuk, kasir melihat galat aneh dan harus mengulang.
- **Dugaan penyebab:** penyederhanaan yang disengaja untuk fondasi; belum ada RPC simpan-pesanan yang bisa menjadi titik penguncian.
- **Cara membuktikan perbaikan:** uji konkurensi (dua transaksi paralel) atau `pg_advisory_xact_lock(hashtext(cabang_id::text || tanggal::text))` di fungsi penomoran, dengan uji yang membuktikan keduanya bernomor beda.
- **Status verifikasi:** TERVERIFIKASI (statis; tabrakan sendiri tidak bisa direproduksi tanpa DB)

### [F-09] Uji negatif dominan memakai bentuk lemah: 150 `uji.harap_gagal` (menolak sebab apa pun) vs 10 `uji.harap_gagal_sebab` (spesifik sebab)
- **Tingkat:** K-4
- **Artefak:** `supabase/tes/*.sql` (150 vs 10); helper di `alat/uji-sql.mjs:148-185`
- **Klaim yang dilanggar:** lensa L4 (negatif-test yang bisa ditolak banyak sebab) — bentuk kuat sendiri lahir dari temuan A-17/F-06 tetapi adopsinya belum menjangkau mayoritas asersi.
- **Bukti:** `grep -rh 'uji\.harap_gagal(' supabase/tes/ | wc -l` → 150; `grep -rh 'harap_gagal_sebab' supabase/tes/ | wc -l` → 10 (hanya `kredensial_pin.sql`, `pembayaran.sql`, `pesanan.sql`).
- **Skenario gagal:** penjaga baru yang salah (mis. menolak karena kunci idempoten alih-alih aturan uang) membuat ratusan asersi negatif tetap hijau — persis kelas cacat yang dulu nyata (T1-10).
- **Dugaan penyebab:** migrasi asersi ke bentuk kuat baru menjangkau berkas yang diperbaiki saat audit, belum menyisuruh berkas lama.
- **Cara membuktikan perbaikan:** `grep -rc harap_gagal_sebab supabase/tes/` menyusul untuk asersi yang menjaga uang/jejak; pemeriksa (`aplikasi/alat/periksa-uji.py` atau baru) menandai `harap_gagal` pada berkas uang sebagai CATATAN.
- **Status verifikasi:** TERVERIFIKASI

### [F-10] Pesan penolakan diskon menunjuk alur yang tidak ada: "Minta persetujuan atasan (PIN)"
- **Tingkat:** K-4
- **Artefak:** `supabase/migrations/0013_penutup_celah_putaran11.sql:47` (`raise exception 'Diskon ini melebihi batas izin Anda. Minta persetujuan atasan (PIN).'`)
- **Klaim yang dilanggar:** konsistensi alur (L5/L3): kupon PIN atasan (`diskon_setuju_jujur`) tidak menaikkan batas pemanggil — `picu_diskon_batas` selalu menilai `boleh()` si PEMANGGIL, jadi kasir yang melewati batasnya ditolak walau kupon owner sah sudah ada.
- **Bukti:** baca `picu_diskon_batas` (0013) vs `picu_diskon_setuju_jujur` (0014) vs `supabase/tes/diskon_setuju.sql` (jalur sah yang teruji hanyalah ATASAN yang mencatat sendiri diskonnya).
- **Skenario gagal:** pembuat layar kasir (Fase 5) mengikuti pesan galat → membangun alat "kasir minta PIN atasan → kasir simpan diskon" → SELALU ditolak; ditemukan lagi sebagai bug baru di fase berikutnya.
- **Dugaan penyebab:** pesan ditulis sebelum mekanisme kupon selesai dirancang.
- **Cara membuktikan perbaikan:** ubah pesan menjadi "atasan harus mencatat diskon ini dari sesinya" ATAU ubah `picu_diskon_batas` menilai izin disetujui_oleh bila kupon valid ada — salah satu, dibuktikan uji `supabase/tes/diskon_setuju.sql` diperluas.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

**Ditemukan: 11 dari 11** cacat yang saya yakini sengaja ditanam, di 5 berkas bahan. **Temuan palsu: 0.** Semua temuan di bawah saya buat HANYA dari membaca bahan sebagai kode sungguhan (kelas & alasan ditulis sendiri); berkas `pr-bahan-2026-09-17.diff` baru saya buka SETELAH daftar ini final — dan justru isinya membuktikan kunci jawaban bocor di dalam repo (F-05).

1. `01_gerbang_izin.sql` — **search_path SECURITY DEFINER tanpa `pg_temp`** (`set search_path = public`): objek temp milik pemanggil bisa membayangi tabel `pengguna` di dalam fungsi definer (kelas K-1/K-2; proyek nyata selalu menulis `public, pg_temp`). K-2.
2. `01_gerbang_izin.sql` — **komentar menuntut "execute dicabut dari public" tetapi TIDAK ada `revoke`**: SECURITY DEFINER di `public` otomatis dapat EXECUTE oleh PUBLIC (K-2/K-3; mencocokkan injeksi `0005` di diff).
3. `01_gerbang_izin.sql` — **pemanggilan `izin_efektif(p.id, p_aksi, p_cabang)` sebagai boolean**: tanda tangan salah (skema nyata: `(text, uuid)`; versi 3-argumen namanya `izin_efektif_untuk` dan mengembalikan tabel, tidak sah sebagai kondisi boolean) — fungsi ini tidak bisa berjalan apa adanya. K-3.
4. `02_policy_pengaturan.sql` — **`pengaturan_pilih … using (penyewa_id is not null)`**: seluruh pengaturan SEMUA resto terbaca setiap pengguna masuk — kebocoran lintas penyewa. K-1.
5. `03_fungsi_terima_bayar.sql` — **pemeriksa lebih-bayar memakai saldo LAMA** (`if v_sebelum > v_pesanan.total` sebelum pembayaran baru dijumlahkan): pembayaran melebihi total diterima. K-1 (uang).
6. `03_fungsi_terima_bayar.sql` — **SECURITY DEFINER tanpa cek penyewa/izin**: RLS dilewati total; siapa pun yang masuk bisa membayar & melunasinya pesanan resto lain dengan menebak UUID. K-1.
7. `04_panduan_singkat.md` — **`bash aplikasi/pratinjau.sh` tidak ada** (yang ada `aplikasi/alat/pratinjau.sh`) → langkah pengguna buntu. K-2 (aturan §2b: langkah pengguna yang mati = K-2).
8. `04_panduan_singkat.md` — **`python3 alat/periksa-struktur.py` salah jalur** (nyata: `aplikasi/alat/periksa-struktur.py`). K-3.
9. `04_panduan_singkat.md` — **`docs/PANDUAN_KEAMANAN.md` tidak ada** (nyata: `docs/KEAMANAN.md`). K-3.
10. `04_panduan_singkat.md` — **"Salah PIN 10 kali → terkunci 15 menit"** bertentangan dengan kebijakan terpasang (5 gagal per pencoba-akun, 12 per perangkat, per 15 menit — 0011/0012): dokumen keamanan berbohong. K-2.
11. `05_pemeriksa_ambang.py` — **gerbang yang tumpul**: di bawah ambang ia `return 0` (SKIP = hijau), dan `AKAR = parent.parent` dari lokasi berkasnya menunjuk `kalibrasi/` (bukan akar repo) sehingga glob tidak pernah menemukan layar apa pun → SELALU hijau; plus glob non-rekursif melewatkan layar di subfolder. K-2/K-3.

Catatan kecil (tidak dihitung sebagai cacat tanaman karena bisa jadi sekadar penyederhanaan realisme bahan): `03` tidak menangani pesanan tidak ditemukan (`v_pesanan` null) dan menyebut kolom `pembayaran.metode`/`dibuat_oleh` yang tidak ada di skema nyata.

Bukti pemeriksaan bahan dilakukan seperti kode sungguhan: `[ -e aplikasi/pratinjau.sh ]` → tidak ada; `[ -e alat/periksa-struktur.py ]` → tidak ada / `[ -e aplikasi/alat/periksa-struktur.py ]` → ada; `[ -e docs/PANDUAN_KEAMANAN.md ]` → tidak ada; `grep -n "BATAS_AKUN\|BATAS_PERANGKAT" supabase/migrations/0012_penutup_celah_review.sql` → 5/12 (bukan 10); jalankan `python3 docs/uji/kalibrasi/bahan-2026-09-17/05_pemeriksa_ambang.py` → `SKIP: layar baru 0 — di bawah ambang 5`, exit 0 (hijau tanpa memeriksa apa pun).

## 6. Yang tidak bisa saya verifikasi

- **`cd aplikasi && npm test`, `npm run lint`, `npm run typecheck`, `npm run build`** — `aplikasi/node_modules` tidak ada di sesi ini dan paket melarang memasang apa pun ("kamu hanya-baca"). Angka "76 uji hijau" saya verifikasi secara STATIS (10 berkas, 76 asersi ada) tetapi tidak bisa dijalankan.
- **`node alat/uji-sql.mjs` (seluruh 41 berkas uji SQL), `python3 alat/uji-mutasi-0012.py`, `python3 alat/uji-mutasi-0014.py`** — butuh `@electric-sql/pglite` (`npm ci --prefix alat`); tidak terpasang, pemasangan dilarang. Karena itu SEMUA temuan SQL saya berstatus TERVERIFIKASI secara STATIS (kode lengkap & tertutup), bukan dinamis; `uji-mutasi-0012/0014` sendiri mencetak "GAGAL: salinan uji tidak punya pustaka uji (pglite)".
- **Perilaku Supabase produksi nyata** — tidak ada proyek Supabase aktif (T-018 terbuka, menunggu akun pemilik): konfigurasi Data API, penerbitan klaim JWT, perilaku `auth.jwt()` nyata, dan migrasi pada Postgres terkelola tidak bisa diuji dari sini.
- **Peramban/tablet nyata (L5 lapangan)** — aplikasi masih kerangka Fase 0 (satu layar contoh); alur kasir sesungguhnya belum ada untuk diuji; printer/offline belum dibangun (T6/T10 direncanakan).
- **Riwayat CI untuk commit audit hanya berupa metadata** (`cancelled`) — tidak ada log langkah untuk menilai sampai mana suite berjalan sebelum dibatalkan.
- **`--verifikasi-lingkup` alat membaca paket LAIN** yang tersimpan di commit ini (`AUD-3-2026-09-18.md`, target `52e22fc`), bukan paket tempel saya (`AUD-3-2026-09-19`, target `93a50ba`) — saya menyelesaikan target secara manual sesuai LANGKAH 0 (commit ada & diperiksa: `git cat-file -e 93a50ba…` ✓ setelah fetch semua cabang).
- **Verdict saya memakai model yang sama dengan ekosistem sesi lain** — independensi model penuh tidak bisa saya jamin dari dalam sesi (dicatat sesuai PROTOKOL §14 butir 2/5).

## 7. Pernyataan tidak mengubah apa pun

Saya tidak mengubah apa pun. Saya hanya-baca. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain yang saya ubah atau buat. Satu-satunya perpindahan posisi Git yang saya lakukan adalah `git fetch` (ambil objek) dan `git checkout --detach 93a50ba…` (hanya-baca, sesuai LANGKAH 0 paket); tidak ada commit/perbaikan kode dari saya. Bukti: perintah `git status --short` yang saya jalankan menampilkan hanya berkas laporan ini (`?? docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0b85b.md`).

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 8-01 | **Cabang remote `arena/01a0b7d1-resto-barokah` menunjuk commit auditor 2026-09-17 (pohon template + 1 laporan), bukan ujung kerja** — ujung kerja `bdf8a86` ("Cacat keempat…") hanya hidup di `refs/pull/2/head`; commit audit `93a50ba` tidak lagi dicapai cabang mana pun di remote. `338f9b4` (author "Arena Audit", 2026-09-17) ber-induk `253d129` = template. Pola insiden yang didokumentasikan sendiri (dua sesi satu cabang) — kali ini yang tertimpa adalah ujung KERJA, bukan laporan | Keadaan remote SETELAH commit audit (bukan isi commit) | `git ls-remote origin` → `338f9b4… refs/heads/arena/01a0b7d1-resto-barokah`; `git cat-file -p 338f9b4` → `parent 253d129…`; `git merge-base --is-ancestor 93a50ba bdf8a86` → YA (kerja selamat di PR #2) | Sesi kerja menarik ulang kerja dari `refs/pull/2/head` (atau `origin/arena/01a0b4c3`/cabang sesi yang benar), mendorong ulang ujung kerja, dan mekanisme `--ambil-laporan`/platform disikat agar sesi auditor berbasis template TIDAK pernah mendorong ke cabang kerja bersama |
| 8-02 | `EXECUTE harga_berlaku/menu_habis` diberikan ke `anon` (0007:497-498) — untuk anon hasil selalu kosong (`penyewa_saya()` null), jadi tidak bocor; hak berlebih saja | Fungsi publik katalog untuk T8 (belum dibangun) | `grep "grant execute on function public.harga_berlaku" supabase/migrations/0007_katalog.sql` | Tarik grant `anon` bila T8 tidak melulu memakainya; uji anon Tetap-0-baris |
| 8-03 | `peran_lebih_tinggi(uuid, uuid)` bisa dipanggil `authenticated` untuk membandingkan peran dua UUID sembarang (0014) — UUID tidak ditebak dan informasinya minim, tapi ini intip kecil lintas resto secara teori | Fungsi pendukung hierarki PIN (Fase 1B/2) | `grant execute on function public.peran_lebih_tinggi… to authenticated` | Batasi ke pemanggil ber-identitas di penyewa yang sama (seperti pola `izin_efektif_untuk`) |
| 8-04 | Edge Function PIN memakai `Access-Control-Allow-Origin: *` dan tidak memverifikasi kesesuaian token↔`pengguna_id` (menyerahkan ke DB — DB membatasi per penyewa & per pencoba, jadi bukan lubang hari ini) | Konfigurasi gerbang jaringan | header CORS di `supabase/functions/verifikasi_pin/index.ts` | Pertimbangkan allowlist origin saat domain produksi (T0-09) tetap; dokumentasikan keputusan |

---
### Referensi eksternal yang dipakai untuk menilai perilaku sistem luar
- Supabase — RLS, security definer & perangkap keamanan: https://supabase.com/docs/guides/database/row-level-security dan https://supabase.com/docs/guides/api/securing-your-api (dilokalkan dalam skill repo `skills/supabase/SKILL.md` — daftar periksa yang sama: view bypass RLS, `WITH CHECK`, EXECUTE→PUBLIC untuk fungsi definer, metadata JWT tidak untuk otorisasi)
- PostgreSQL — `search_path` & skema `pg_temp` pada fungsi SECURITY DEFINER: https://www.postgresql.org/docs/current/sql-createfunction.html#SQL-CREATEFUNCTION-SECURITY (paragraf "Because `pg_temp` is searched first… safe schema usage")
- PostgreSQL — RLS `USING` vs `WITH CHECK`: https://www.postgresql.org/docs/current/sql-createpolicy.html
- OWASP — A01 Broken Access Control / A04 Insecure Design (kerangka penilaian K-1/K-2): https://owasp.org/Top10/A01_2021-Broken_Access_Control/