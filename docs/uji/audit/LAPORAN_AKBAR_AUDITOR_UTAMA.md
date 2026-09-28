# LAPORAN AKBAR AUDITOR UTAMA (HOLISTIK & SAAS MULTI-TENANT)
# Resto Barokah — Pemeriksaan Akbar Fase 0 s/d Fase 10 (Gerbang Sebelum Fase 11)

- **Auditor:** Auditor Utama (Holistik) — sesi audit independen, hanya-baca
- **Tanggal:** 2026-09-27
- **Tingkat audit:** Pemeriksaan Akbar Menyeluruh (setara AUD-3, kacamata Pemilik Platform SaaS)
- **Cabang kerja:** `arena/01a0e267-resto-barokah`
- **Commit yang diaudit:** `0fc63c7e8d4007007380b8fcfc3b74a0d8010963` (HEAD sesi saat pemeriksaan, dulu `git rev-parse HEAD` — cocok)
- **Paket audit:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` + `docs/uji/PROMPT_AKBAR_AUDITOR_UTAMA.md`
- **Verdict:** **MEMERLUKAN PERBAIKAN sebelum Fase 11** — 0 temuan K-1, **1 temuan K-2**, 3 temuan K-3, 2 temuan K-4

> **Aturan protokol yang saya patuhi:** hanya-baca (tidak mengubah kode sumber, migrasi, atau alur sistem —
> laporan ini satu-satunya berkas yang saya buat di dalam repo; berkas uji serangan saya taruh di luar repo
> `/home/user/serangan-auditor-utama.sql`), setiap temuan berbasis perintah nyata + nomor baris + skenario
> kegagalan, klaim pembangun saya **bantah** (bukan saya telan), dan saya tidak "merapikan" apa pun.
> Keterbatasan independensi: saya adalah model AI pada sesi terpisah dari sesi pembangun; "model berbeda"
> tidak bisa saya pastikan dari dalam — dicatat sebagai keterbatasan, bukan kekuatan.

---

## 1. Ringkasan Eksekutif (Bahasa Manusia)

Lee, saya sudah memeriksa sistem ini dari ujung ke ujung dengan kacamata pemilik platform SaaS yang
menyewakan aplikasi ke banyak resto: mulai dari cara Lee mendaftarkan resto baru, pemisahan data antar
resto, alur kerja kasir–dapur–pembayaran–struk–tutup kas, sampai kesesuaian dengan janji di PRD dan
TECH_SPEC.

**Kabar baiknya sungguh nyata, bukan sekadar klaim:**

1. **Resto A benar-benar tidak bisa melihat Resto B.** Seluruh 47 tabel milik penyewa terkunci rapat
   (RLS aktif + kebijakan di 47/47 tabel, 0 tabel terbuka). Saya juga melancarkan 13 serangan nyata
   (lompat tenant, naik peran, bocorkan uang tetangga, palsukan uang & jejak audit, bayar tanpa aturan)
   — **semuanya dipukul mundur**, dan mesin uji bahkan menolak serangan saya ketika saya salah menebak
   *alasan* penolakannya (artinya penjaganya memeriksa sebab, bukan asal gagal).
2. **Uang tidak bisa dimainkan dari tablet kasir.** Semua angka uang (total, pajak PB1, service charge,
   kembalian) dihitung peladen; klien tidak bisa mengubah total, menulis pembayaran kelebihan, mengedit
   riwayat pembayaran, atau membatalkan pesanan yang sudah berbayar.
3. **Mesin pengujian hijau semua, dan terbukti bisa merah:** 132/132 berkas uji SQL LULUS,
   123 berkas uji frontend (1.013 tes) LULUS, 126 gerbang CI utuh (uji-diri mutasinya menolak yang
   rusak), penyisir RLS dan peta UI sama-sama lulus uji-diri mutasi.

**Tapi ada satu temuan TINGGI (K-2) yang menahan gerbang Fase 11** — dan tepat di titik yang paling akan
terasa saat pilot kedai nyata:

- **K-2 (A-05): fitur antrean luring (offline queue) tidak bekerja pada kegagalan jaringan yang paling
  umum di lapangan** — "WiFi tersambung ke router tetapi internet mati". Dalam kondisi itu pesanan
  **tidak masuk antrean** sama sekali (hanya muncul pesan galat), dan pesanan yang sedang terkirim saat
  aplikasi/tablet mati **terkunci selamanya** di status `mengirim` (tidak pernah dicoba ulang). Janji
  T10-01/ART-8 ("tersimpan persisten, tersinkron otomatis saat online") belum benar-benar terpenuhi.

Selain itu ada 3 temuan K-3 dan 2 temuan K-4, termasuk "janji dokumen yang basi": aturan shift
(PRD M7 vs perilaku bawaan), celah uji email ganda untuk pendaftaran dua resto, dan janji kontras
WCAG **AAA** yang dijanjikan ke Lee tetapi alatnya hanya menegakkan **AA**.

**Kesimpulan singkat: inti sistem (isolasi tenant, uang, kasir–dapur–kas) SEHAT dan siap; tetapi sesuai
kriteria paket ("0 Temuan Mayor") verdict saya adalah MEMERLUKAN PERBAIKAN dulu** — perbaikan A-05
relatif kecil dan terukur (pemetaan galat jaringan ke antrean + pemulihan item `mengirim`), dan begitu
itu hijau, sistem layak masuk Fase 11.

---

## 2. Hasil Uji Isolasi Multi-Tenant

### 2a. Bukti "matematis" (struktur & mesin)

Pemisahan dibangun di atas **satu sumber kebenaran identitas**: `penyewa_saya()` mengambil penyewa dari
tabel `pengguna` lewat `auth.uid()` — bukan dari metadata yang bisa diubah klien
(`supabase/migrations/0003_helper_identitas.sql:20-31`), diperketat cek sesi hidup
(`0058_sesi_masih_aktif.sql:116-141`) dan hanya bisa "melompat" ke penyewa lain lewat mode dukungan yang
hanya bisa dibuka pemilik platform dengan alasan ≥10 karakter + masa berlaku
(`0031_mode_dukungan_platform.sql:114-145`; uji `supabase/tes/mode_dukungan.sql` membuktikan pintu ini
menolak kasir/owner dan tetap **hanya-baca** walau untuk pemilik platform).

| Pemeriksaan struktur | Perintah | Hasil |
|---|---|---|
| Penyisiran RLS seluruh tabel | `python3 alat/periksa-sisir-rls.py` | **LOLOS** — 47 tabel publik, RLS aktif **47/47**, policy terpasang **47/47**, 0 tabel terbuka/tanpa policy, "fail-closed" |
| Ketajaman penyisir (bisa merah?) | `python3 alat/periksa-sisir-rls.py --uji-diri` | **LOLOS** — 4/4 mutasi kebocoran (tabel tanpa RLS, RLS tanpa policy, tanpa penyewa_id, policy terbuka tanpa `penyewa_saya()`) TERTANGKAP |
| Uji SQL sisir akhir | `node alat/uji-sql.mjs supabase/tes/sisir_rls_akhir.sql` | **LOLOS** (82 migrasi diterapkan utuh sebelum uji) |
| Isolasi pintu fungsi (bukan hanya tabel) | `node alat/uji-sql.mjs supabase/tes/isolasi_lintas_penyewa.sql` (ikut suite penuh) | **LULUS** — fungsi `total_dibayar`, `izin_efektif_untuk`, `boleh_untuk`, `peran_lebih_tinggi` tidak membocorkan data resto lain (celah AUD-3 lama sudah tertutup + ada uji regresinya) |
| Uji pendaftaran & isolasi dua/tiga resto | `node alat/uji-sql.mjs supabase/tes/daftar_penyewa.sql` | **LOLOS** — anon/kasir/owner ditolak memanggil `buat_penyewa`; data Resto A vs B vs C terbukti tak saling terlihat (penyewa, cabang, pengaturan, pengguna, pesanan, meja, catatan_audit) |

### 2b. Bukti "perilaku" — 13 serangan yang saya lancarkan sendiri

Saya menulis skrip serangan di **luar repo** (`/home/user/serangan-auditor-utama.sql`) dan menjalankannya
terhadap migrasi sungguhan: `node alat/uji-sql.mjs /home/user/serangan-auditor-utama.sql` → **1 LULUS · 0 GAGAL**
(artinya: setiap serangan berhasil **ditolak dengan sebab yang benar** — aturan uji di repo ini bahkan
memaksa saya memakai `uji.harap_gagal_sebab`; serangan saya sempat ditolak mesinnya karena saya salah
menebak sebab penolakan S11, bukan karena serangannya berhasil).

| # | Serangan (skenario gagal yang saya incar) | Pelaku | Hasil |
|---|---|---|---|
| S1 | Lompat tenant: ubah `penyewa_id` diri sendiri ke Resto B | kasir Resto A | DITOLAK — `permission denied for table pengguna` (klien hanya dapat SELECT) |
| S2 | Eskalasi peran: ubah `peran` sendiri jadi `owner_pusat` | kasir Resto A | DITOLAK — sebab sama |
| S3 | Baca pesanan & pembayaran Resto B langsung | kasir Resto A | 0 baris terlihat (RLS) |
| S4 | Catat pembayaran Rp999.999 untuk pesanan ber-total Rp62.100 (bypass `bayar_pesanan`) | kasir Resto A | DITOLAK — "Total pembayaran … melebihi total pesanan" (`0010_pembayaran.sql:319`) |
| S5 | Ubah `total` pesanan jadi Rp1 | kasir Resto A | DITOLAK — "Angka uang pesanan hanya boleh diubah oleh fungsi perhitungan peladen (`hitung_total`)" (`0010_pembayaran.sql:225-233`) |
| S6 | Daftarkan penyewa baru lewat `buat_penyewa` | owner Resto A | DITOLAK — "Hanya pemilik_platform…" (`0079_daftar_penyewa_m1.sql:129-131`) |
| S7 | Edit baris `pembayaran` yang sudah tercatat | kasir Resto A | DITOLAK — `permission denied for table pembayaran` (jejak uang tak bisa diedit/dihapus klien) |
| S8 | Masuk mode dukungan ke Resto B | owner Resto A | DITOLAK — hasil `FORBIDDEN` (`0031_mode_dukungan_platform.sql:132-134`) |
| S9 | Tulis sendiri baris `mode_dukungan` | owner Resto A | DITOLAK — `permission denied for table mode_dukungan` (INSERT di-revoke, `0031:45`) |
| S10 | Tulis jejak audit atas nama penyewa lain | kasir Resto A | DITOLAK — `permission denied for table catatan_audit` (klien tak punya hak tulis, `0020_catatan_audit.sql:37-44`) |
| S11 | Batalkan pesanan yang sudah ber-jejak pembayaran | kasir Resto A | DITOLAK — "Perpindahan status … hanya boleh ditetapkan peladen" (pembekuan T-025(a) bekerja berlapis) |
| S12 | Panggil pintu uang `bayar_pesanan` | anonim | DITOLAK — `permission denied for function bayar_pesanan` (grant hanya `authenticated`, `0060:206-207`) |
| S13 | Daftar resto baru dengan **email owner yang sudah dipakai resto lain** | pemilik platform | **DITERIMA lokal** (`PENYEWA_DIBUAT`) → inilah dasar temuan K-3 A-01 di bawah |

### 2c. Pendaftaran penyewa baru (`buat_penyewa`) — telaah hulu

RPC `buat_penyewa` (`0079_daftar_penyewa_m1.sql:81-377`) sudah benar polanya: hanya `pemilik_platform`
aktif yang boleh memanggil (dicek di badan fungsi + hak eksekusinya dicabut dari publik/anon),
validasi nama/slug unik/zona waktu/mata uang/email/PIN 6 digit anti-pola-lemah, membuat paket awal
lengkap (penyewa + pengaturan bawaan PB1 10% / service 5% + cabang pertama + akun owner + hash PIN
bcrypt + penugasan cabang + jejak audit), dan penolakan hard-delete penyewa ber-riwayat
(`picu_penyewa_cegah_hapus`, `0079:53-80`) sehingga menonaktifkan ≠ menghapus data — persis PRD M1.
Satu-satunya celah ada pada kasus tepi "satu orang dua resto dengan email sama" (temuan K-3 A-01).

---

## 3. Hasil Uji Alur Bisnis E2E (kasir → dapur → bayar → struk → tutup shift)

Rantai bisnis saya telusuri dari kode, uji, dan serangan — bukan dari janji dokumen:

| Tahap | Kode & bukti | Hasil |
|---|---|---|
| Buka shift (modal awal) | `0045_buka_shift.sql` (RPC `buka_shift`), layar `BukaKas.tsx` + uji `buka_shift.sql`, `BukaKas.test.tsx` | Sehat — satu shift terbuka per kasir per cabang dijaga indeks unik + RPC |
| Pesan meja/bungkus, catatan item, simpan tagihan | `0009_pesanan.sql`, trigger `picu_pesanan_jaga_uang` (`0010:206-241`) — angka uang hanya boleh diisi `hitung_total` peladen | Sehat — harga saat pesanan disalin (`harga_saat_itu`), uang tidak bisa dikirim perangkat |
| Kirim ke KDS dapur/bar | `0033_tujuan_item.sql` — pemisahan dapur/bar otomatis dari kategori, salinan kekal per item; layar `LayarDapur.tsx` / `LayarBar.tsx` + uji `tujuan_item.sql`, `status_item_transisi.sql` | Sehat — item salah tujuan tidak akan nyasar (bawaan 'dapur' saat kategori ragu), status per item tidak dobel |
| Bayar (tunai/QRIS/voucher) | Pintu tunggal `bayar_pesanan` (`0060:21-203`): kunci baris `for update` (anti balap dua kasir), kembalian dihitung peladen, idempoten per kunci (klik dobel → `BY-200, dobel: true`, tidak dobel catat), tolak kelebihan bayar (`BY-301`), tolak pesanan batal/total belum dihitung; non-tunai wajib referensi; voucher punya pintu `cek_voucher` (baca-saja) + `pakai_voucher` + log percobaan (`kasir_voucher.sql`, `pengaman_voucher.sql`) | Sehat — serangan S4/S7/S12 semua patah |
| Pembekuan setelah bayar (T-025(a)) | `0017_pesanan_tertutup_beku.sql`, `0022_beku_setelah_bayar.sql`, `0024_beku_satu_pernyataan.sql` + serangan S11 | Sehat — sesudah pembayaran pertama, isi/nominal/diskon/void terkunci berlapis (PIN atasan pun tidak menembus) |
| Struk | Komponen `StrukDigital.tsx` (cetak via `window.print`, cetak ulang dari `DaftarPesanan.tsx:221-224` — printer mati tidak menghapus transaksi) | Sehat untuk MVP cetak-peramban; uji fisik printer thermal di lapangan belum mungkin dari audit ini |
| Tutup shift | `0046_tutup_shift.sql` + `0049`/`0047` perkembangan: sistem menghitung uang seharusnya (modal + tunai masuk − keluar), kasir isi hitungan fisik, **selisih ≠ 0 wajib alasan** (RPC `SH-422` + constraint tabel `shift_kas_selisih_alasan`, `0046:21-30`) | Sehat — dua lapis (RPC + skema) |
| Uji E2E layar kasir | `cd aplikasi && npm test -- src/layar/platform/Penyewa.test.tsx src/layar/kasir/AlurKasirE2E.test.tsx --run` | **LULUS** (2 berkas, 7 tes). Skenario penuh: pilih menu → catatan → kirim dapur → bayar lunas; uang yang dicatat = total tagihan (Rp13.800), bukan uang diterima (Rp50.000) |
| Ketahanan luring (antrean offline) | `aplikasi/uji/e2e/luring.spec.ts` & `mati-mendadak.spec.ts` (vitest, ikut suite penuh) + telaah kode `antrean-offline.ts`/`App.tsx` | **BERMASALAH** — suite lulus, tetapi jalur antrean punya lubang nyata pada mode gagal yang paling umum; rincian di temuan **A-05 (K-2)** |

### Tabel Bukti Pengujian (seluruh perintah wajib + tambahan)

| No | Perintah (dijalankan apa adanya di `0fc63c7`) | Hasil |
|---|---|---|
| 1 | `python3 alat/periksa-sisir-rls.py` | LOLOS — 47/47 tabel terisolasi 100% fail-closed |
| 2 | `python3 alat/periksa-sisir-rls.py --uji-diri` | LOLOS — 4/4 mutasi kebocoran tertangkap |
| 3 | `python3 alat/peta-ui.py` | HIJAU — Layar, Aksi, RPC, Izin, Uji, PRD M1–M12, bebas tombol liar |
| 4 | `python3 alat/peta-ui.py --uji-diri` | LULUS — 6/6 mutasi (RPC fiktif, izin fiktif, aksi tanpa uji, layar tanpa peran, drift dokumen, tombol mentah) tertangkap |
| 5 | `node alat/uji-sql.mjs supabase/tes/daftar_penyewa.sql` | LOLOS — 82 migrasi OK, 1/1 LULUS |
| 6 | `node alat/uji-sql.mjs supabase/tes/sisir_rls_akhir.sql` | LOLOS — 1/1 LULUS |
| 7 | `cd aplikasi && npm test -- src/layar/platform/Penyewa.test.tsx src/layar/kasir/AlurKasirE2E.test.tsx --run` | LULUS — 2 berkas, 7 tes (6 tes Penyewa + 1 E2E kasir) |
| 8 | `node alat/uji-sql.mjs` (suite penuh — di luar daftar wajib, demi klaim "100% mesin hijau") | **132 LULUS · 0 GAGAL** |
| 9 | `cd aplikasi && npm test` (suite penuh) | **123 berkas · 1.013 tes · 0 gagal** (±126 detik) |
| 10 | `python3 alat/periksa-gerbang-ci.py` + `--uji-diri` | LOLOS — 126 gerbang CI utuh (ci.yml + sebar-skema + sebar-halaman + cadangan + denyut), mutasi terbukti bisa MENOLAK |
| 11 | `node alat/uji-sql.mjs /home/user/serangan-auditor-utama.sql` (13 serangan auditor) | LULUS — semua serangan ditolak dengan sebab benar (kecuali S13 yang sengaja membuktikan celah uji) |

### Catatan keterbatasan verifikasi (jujur)

- Saya **tidak** punya akun Supabase/Cloudflare sungguhan di sesi ini: perilaku `auth.users` produksi
  (kunci unik email), deploy, dan denyut cron 02:00 WIB **tidak** bisa dijalankan betulan — diperiksa lewat
  kode, uji, dan definisi alur CI-nya saja.
- Uji fisik tablet/printer thermal/sentuh di kedai nyata belum mungkin dilakukan dari lingkungan audit ini
  (Fase 11 memang untuk itu).
- Uji konkurensi dua koneksi nyata tetap jujur belum ada di PGlite (satu koneksi) — sifat kunci
  `for update` yang diuji `uang_kunci.sql` adalah bukti terbaik yang tersedia hari ini.
- **Catatan lintas-periksa:** di cabang yang sama sudah ada laporan pememeriksa lain
  (`docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md`, commit `961f50b`) dengan temuan tambahan dan
  verdict-nya sendiri. Sesuai protokol, verdict tidak saya gabung. Yang saya lakukan: dua temuan paling
  menentukan di laporan itu **saya verifikasi sendiri ulang dari kode/pustaka terpasang** sebelum saya
  angkat ke laporan ini sebagai A-05 dan A-06 (bukti verifikasi mandiri saya cantumkan). Temuan lain di
  laporan itu tidak saya ulangi klaimnya di sini.

---

## 4. Daftar Temuan

### K-1 (Kritis) — 0 temuan
(tidak ada kebocoran antar penyewa, tidak ada salah hitung uang, tidak ada kunci rahasia di repo —
`periksa-rahasia.py` ikut CI dan repo bersih `.env`)

### K-2 (Tinggi) — 1 temuan

**[A-05] Antrean luring tidak terpicu pada "WiFi nyala, internet mati" — dan item `mengirim` bisa terkunci selamanya**
- **Tingkat:** K-2 (Tinggi)
- **Artefak:** `aplikasi/src/App.tsx:81-100` (hanya `!navigator.onLine` yang memaksa jalur antrean; `App.tsx:96-98` mengembalikan `sukses:false` saat `errPesanan` terisi — **tanpa** `tambahKeAntrean`), `aplikasi/src/lib/antrean-offline.ts:293-297` (`ambilAntreanMenunggu` hanya `menunggu`/`gagal` — status `mengirim` tidak pernah dipulihkan), `antrean-offline.ts:508` (status diubah ke `mengirim` sebelum kirim), `aplikasi/node_modules/@supabase/postgrest-js/dist/index.mjs:416` (secara bawaan kegagalan `fetch` diubah menjadi balasan `{error}`, **bukan** lemparan — dan aplikasi tidak memakai `throwOnError`)
- **Klaim yang dilanggar:** janji T10-01/ART-8 ("transaksi yang dicatat saat koneksi internet mati tersimpan persisten di IndexedDB… tersinkronisasi otomatis saat online kembali") dan kasus tepi PRD M4 ("internet terputus saat menekan kirim — pesan gagal harus terlihat jelas, **bukan diam-diam hilang**").
- **Bukti (verifikasi mandiri saya):**
  1. `grep -n "shouldThrowOnError\|throwOnError" aplikasi/src` → tidak ada (konversi galat pustaka berlaku bawaan).
  2. Baca `@supabase/postgrest-js` terpasang (`dist/index.mjs:416`): `if (!this.shouldThrowOnError) res = res.catch((fetchError) => … { error: … })` → kegagalan jaringan menghasilkan **balasan `error`**, bukan exception.
  3. `App.tsx:96-98`: `if (errPesanan) { return { sukses: false, pesan: errPesanan.message } }` — kembali sebelum `tambahKeAntrean` (baris 127). Karena `navigator.onLine === true` saat "internet mati", lemparan buatan di baris 81-83 juga tidak terjadi.
  4. `antrean-offline.ts:293-297` + `496-499`: `prosesAntrean()` hanya mengambil `menunggu`/`gagal`; item yang tersisa `mengirim` (mis. aplikasi/tablet mati di tengah kirim) **tidak pernah** masuk daftar kirim-ulang, dan tidak ada pemulihan saat mulai.
- **Skenario gagal (dua sub-cacat):**
  - *5a (paling umum):* modem kedai mati 10 menit, WiFi tablet tetap tersambung router. Kasir tekan "Kirim ke Dapur" → muncul galat, pesanan **tidak masuk antrean** — kasir harus mengulang manual; janji "offline-ready" tidak hidup di kondisi yang justru paling sering terjadi di lapangan.
  - *5b (senyap):* tablet kehabisan baterai tepat saat antrean sedang dikirim → satu pesanan terkunci di status `mengirim` di IndexedDB **selamanya**, tidak dicoba ulang dan tidak terlihat di hitungan "menunggu" — bentuk "diam-diam hilang" yang dilarang PRD M4.
- **Dugaan penyebab:** deteksi gangguan jaringan hanya mengandalkan `navigator.onLine` + lemparan; galat bertipe "balasan `{error}`" tidak dipetakan ke jalur antrean; dan antrean tidak punya aturan "reset `mengirim` yang menganggur" saat inisialisasi.
- **Cara membuktikan perbaikan:** (1) galat berindikasi jaringan (`Failed to fetch`, `fetch failed`, `network`, timeout) dari `insert`/`rpc` dipetakan ke `tambahKeAntrean` (kunci idempoten tetap `pos-<id>`), diuji dengan klien tiruan yang mengembalikan `{ error: new TypeError('Failed to fetch') }` dan berharap ada item antrean, bukan `sukses:false`; (2) item `mengirim` dengan `terakhirDicoba` lebih tua dari ambang (mis. 60 detik) direset ke `menunggu` saat modul dimuat → uji "mati-mendadak" berharap `diproses: 1`; (3) `npm test` tetap hijau.
- **Status verifikasi:** TERVERIFIKASI (kode + perilaku pustaka terpasang saya baca sendiri; eksekusi di peramban nyata dengan jaringan putus sungguhan belum bisa dilakukan dari audit ini — dicatat jujur).

### K-3 (Sedang) — 3 temuan

**[A-01] Email sama untuk dua resto lolos di uji lokal, diperkirakan gagal di Supabase produksi (celah uji + janji PRD M1 tak teruji)**
- **Tingkat:** K-3
- **Artefak:** `alat/uji-sql.mjs:56-59` (tiruan `auth.users (id uuid, email text)` tanpa unik), `supabase/migrations/0079_daftar_penyewa_m1.sql:193` (hanya menolak email `pemilik_platform`), `0079:286` (`insert into auth.users (id, email) values (v_owner_id, …)` dengan id baru), `supabase/migrations/0002_pengguna_izin_pengaturan.sql:38-45` (unik email per penyewa — sengaja mengizinkan email sama antar penyewa), `docs/PRD.md:71` (kasus tepi M1: "satu orang memiliki dua resto (boleh, dengan akun berbeda)")
- **Klaim yang dilanggar:** PRD M1 kasus tepi + komentar skema "beda penyewa boleh sama" — kemampuan ini tidak punya uji yang jujur terhadap perilaku produksi.
- **Bukti:** serangan **S13** — `buat_penyewa('Resto Kembar', …, owner_email => 'owner.a@contoh.test', …)` sebagai pemilik platform **diterima** (`PENYEWA_DIBUAT`) di mesin uji lokal, karena tiruan `auth.users` tidak punya kunci unik email. Pada Supabase produksi, `auth.users` memiliki kunci unik email — `insert` kedua untuk email yang sama akan melempar `duplicate key … users_email_key` (galat database mentah, bukan pesan ramah) dan seluruh transaksi RPC batal. **Status:** TERVERIFIKASI (celah tiruan-uji + diterimanya skenario di lokal) · DUGAAN (galat persis di Supabase produksi — tidak bisa dibuktikan tanpa akun).
- **Skenario gagal:** Lee mendaftarkan resto kedua milik orang yang sama dengan email yang sama (wajar terjadi saat penjualan) → pendaftaran gagal dengan pesan teknis; atau (bila suatu saat tiruan berubah) akun ganda membingungkan alur masuk.
- **Cara membuktikan perbaikan:** (1) tambah batas unik email di tiruan `auth.users` uji (atau ubah `buat_penyewa` agar berperilaku eksplisit: terima/tolak dengan pesan ramah "email sudah terdaftar — pakai email lain untuk akun kedua"), (2) tambah kasus uji `daftar_penyewa.sql` untuk email duplikat, (3) uji ulang di Supabase staging dengan dua resto satu email.

**[A-02] Janji PRD M7 & TECH_SPEC ART-6 (transaksi wajib dalam shift terbuka) tidak berlaku pada perilaku bawaan sistem**
- **Tingkat:** K-3
- **Artefak:** `docs/PRD.md:145` ("Transaksi hanya bisa dilakukan dalam shift yang sudah dibuka."), `docs/TECH_SPEC.md:356-357` (ART-6: "Transaksi **hanya** boleh terjadi bila ada shift terbuka…"), `supabase/migrations/0048_wajib_shift.sql:28` (`wajib_shift boolean not null default false`), `0079_daftar_penyewa_m1.sql` (insert pengaturan baru tanpa kolom `wajib_shift` → ikut default `false`), `supabase/tes/wajib_shift.sql:29-33` (menguji "Mode fleksibel: pesanan dan pembayaran tetap dapat dibuat tanpa shift")
- **Klaim yang dilanggar:** kriteria selesai PRD M7 & ART-6 yang berbunyi mutlak. Keputusan fleksibilitas memang tercatat di `docs/DECISIONS_LOG.md:2518-2555` (disengaja, ada audit perubahan setelan), **tetapi** PRD & TECH_SPEC tidak diperbarui — dan penamaan di DECISIONS_LOG pun basa: disebut `picu_pesanan_validasi_shift_terbuka`/`picu_pembayaran_validasi_shift_terbuka` (`docs/DECISIONS_LOG.md:2535,2538`) sementara kodenya `picu_pesanan_wajib_shift`/`picu_pembayaran_wajib_shift` (`0048_wajib_shift.sql:36,111`).
- **Bukti:** `grep -n "Transaksi hanya bisa dilakukan dalam shift" docs/PRD.md` → baris 145; `sed -n 28p supabase/migrations/0048_wajib_shift.sql` → `default false`; uji `wajib_shift.sql` bagian 1 lulus justru karena transaksi tanpa shift **diizinkan** saat bawaan. **Status:** TERVERIFIKASI.
- **Skenario gagal:** Lee/pemilik resto membaca PRD lalu percaya "tidak ada penjualan di luar kas" — padahal penyewa baru bawaannya *bisa* menerima pesanan & pembayaran tanpa shift terbuka (penjualan bayangan tidak terikat kas shift, persis risiko yang ingin ditutup T7-04). Penjaga baru bekerja bila pemilik mengaktifkan `wajib_shift`.
- **Cara membuktikan perbaikan:** selaraskan dokumen (ubah PRD M7 & ART-6 menjadi "wajib shift — bisa dilonggarkan lewat setelan `wajib_shift` (bawaan: …)" beserta keputusannya), **atau** ubah bawaan jadi `true` + perbarui uji; sekalian samakan nama pemicu di DECISIONS_LOG dengan kode. Uji: `node alat/uji-sql.mjs supabase/tes/wajib_shift.sql` + `python3 alat/peta-ui.py` tetap hijau setelah dokumen diselaraskan.

**[A-06] Janji kontras WCAG AAA ke Lee tidak terpenuhi — alat uji hanya menegakkan AA**
- **Tingkat:** K-3 (penilaian saya; rekan spesialis frontend memberi K-2 — verdict tidak digabung)
- **Artefak:** janji di `docs/teknis/REKAM_PESAN_PEMILIK.md:549` ("aksesibilitas kontras WCAG AAA") & `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md:18`; penegak di `aplikasi/alat/uji-kontras.py:193-207` (pasangan warna dengan ambang **4.5**/**3.0** = AA; AAA butuh **7.0**/**4.5**); konfirmasi AA yang tertulis di `docs/DECISIONS_LOG.md` baris tema 2026-09-26 ("validasi otomatis kontras warna aksen heksa WCAG AA (≥ 4.5:1)")
- **Klaim yang dilanggar:** pesan pemilik yang menetapkan standar AAA untuk 10 tema — janji ke pemilik yang tidak diukur dan tidak dipenuhi alatnya.
- **Bukti:** `python3 aplikasi/alat/uji-kontras.py` → "166 lolos, 0 gagal" **pada ambang AA** (perintah & angka dikonfirmasi di dokumen bukti yang sama); mengukur ulang dengan ambang AAA akan gagal puluhan pasangan (laporan rekan memuat rincian 50 pasangan di 4,5–7:1 — bagian itu saya rujuk, bukan hitung ulang). **Status:** TERVERIFIKASI (selisih ambang klaim vs alat).
- **Skenario gagal:** kasir berpenglihatan rendah membaca teks redup di tema terang pada tablet di bawah cahaya terang — rasio ~5,4–6,4:1 memenuhi AA tetapi di bawah janji AAA (7:1).
- **Dugaan penyebab:** ambang alat dibuat untuk AA dan tidak pernah dinaikkan ketika dokumen mulai menjanjikan AAA.
- **Cara membuktikan perbaikan:** **keputusan Lee dulu** — (a) terima AA dan ubah seluruh dokumen janji dari "AAA" menjadi "AA (4.5:1)" secara eksplisit, atau (b) naikkan ambang `PASANGAN` ke 7.0/4.5 lalu perbaiki tema sampai `python3 aplikasi/alat/uji-kontras.py` hijau lagi.

### K-4 (Saran) — 2 temuan

**[A-03] Notifikasi kasir memakai `alert()` yang memblokir — tanpa kode galat**
- **Tingkat:** K-4 · **Artefak:** `aplikasi/src/layar/kasir/LayarKasir.tsx:439-450,739` (juga `DaftarPerangkat.tsx`, `KelolaPegawai.tsx`, `Perangkat.tsx`)
- **Bukti:** uji mandiri perintah 7 memunculkan `Error: Not implemented: window.alert … at tanganiKirimKeDapur (LayarKasir.tsx:445)` — sukses "kirim ke dapur" selalu memunculkan alert modal; kegagalan hanya berupa teks tanpa kode (kontras dengan pintu uang yang sudah ber-kode `BY-200/BY-301/SH-400`). **Status:** TERVERIFIKASI.
- **Skenario gagal:** kasir ramai melayani harus menutup dialog setiap kirim pesanan; galat "Gagal mengirim pesanan ke dapur." tanpa kode menyulitkan bantuan jarak jauh. (M4 "pesan gagal harus terlihat jelas" tetap terpenuhi — ini soal kenyamanan, bukan kehilangan data.)
- **Cara membuktikan perbaikan:** ganti dengan komponen notifikasi/toast yang sudah dipakai layar lain + sematkan kode galat; `npm test` tidak lagi memunculkan peringatan jsdom `window.alert`.

**[A-04] Angka klaim "85 migrasi SQL" tidak cocok dengan kenyataan (82 berkas)**
- **Tingkat:** K-4 · **Artefak:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` (baris Spesialis Basis Data: "85 migrasi SQL", mengikuti frasa yang sama di `docs/teknis/REKAM_PESAN_PEMILIK.md:548`) vs `ls supabase/migrations/*.sql | wc -l` → **82** (penomoran memang sampai 0085, tetapi nomor **0034, 0044, 0055** tidak ada — kemungkinan konsolidasi/penggabungan).
- **Bukti:** perintah `ls supabase/migrations/ | sed 's/_.*//' | awk …` menemukan tiga nomor hilang; 132 berkas uji SQL & 123 berkas uji frontend justru **cocok** dengan klaim paket (divalidasi vitest: "123 passed"). **Status:** TERVERIFIKASI.
- **Skenario gagal:** laporan/rapat memakai angka "85" yang tidak bisa ditelusuri orang baru; audit berikutnya membuang waktu mencari 3 migrasi yang tidak pernah ada.
- **Cara membuktikan perbaikan:** perbaiki angka menjadi "82 berkas (penomoran s/d 0085)" atau catat di `BERKAS_PENSIUN.md`/ROADMAP ke mana nomor 0034/0044/0055 pergi.

---

## 5. Kesimpulan

**Sistem dinyatakan MEMERLUKAN PERBAIKAN dulu sebelum Fase 11 (Uji Lapangan & Pilot Kedai Nyata).**

Dasarnya:

1. **K-1 = 0** — inti yang paling berbahaya (isolasi antar penyewa, kebenaran uang, kerahasiaan) terbukti
   sehat oleh mesin **dan** 13 serangan independen. Ini kabar besar: fondasi SaaS multi-tenant layak
   dipercaya untuk dibawa ke lapangan.
2. **K-2 = 1 (A-05)** — sesuai kriteria kelulusan paket ("0 Temuan Mayor"), gerbang **belum** boleh
   dibuka: fitur antrean luring tidak hidup pada mode kegagalan jaringan yang paling umum di kedai nyata,
   dan item `mengirim` bisa lenyap senyap. Perbaikannya kecil dan terukur (pemetaan galat jaringan →
   antrean + pemulihan item `mengirim`), lengkap dengan resep uji yang saya tulis di temuannya.
3. **100% mesin pengujian hijau tetap benar** (5/5 perintah wajib LOLOS; 132/132 uji SQL; 123/123 berkas
   uji frontend / 1.013 tes; 126 gerbang CI terbukti bisa merah) — tetapi A-05 menunjukkan *apa yang belum
   dijangkau mesin*: uji antrean berjalan di fallback memori/lingkungan tiruan, bukan pada dua mode
   kegagalan jaringan di atas. Hijau ≠ selesai.
4. **K-3 (A-01, A-02, A-06) & K-4 (A-03, A-04)** masuk daftar perbaikan fase: sesuaikan janji dokumen
   dengan keputusan nyata (shift, WCAG), tutup celah uji email ganda, rapikan notifikasi & angka klaim.
   Setelah A-05 hijau, halangan sisa untuk Fase 11 adalah keputusan produk Lee (A-02 & A-06), bukan kerja
   coding besar.

---

## 6. Penutup Chat

**Posisi Sekarang:**
Audit Akbar holistik Fase 0–10 selesai dijalankan pada commit `0fc63c7` (cabang `arena/01a0e267-resto-barokah`),
mode hanya-baca. Verdict saya: **MEMERLUKAN PERBAIKAN sebelum Fase 11** — 0 K-1, 1 K-2, 3 K-3, 2 K-4.
Laporan lengkap tersimpan di `docs/uji/audit/LAPORAN_AKBAR_AUDITOR_UTAMA.md` — satu-satunya berkas yang
saya buat (repo tetap bersih di luar itu). Kabar terpenting: inti uang & isolasi tenant terbukti sehat;
satu-satunya penahan gerbang (A-05) ada di ketahanan antrean luring dan perbaikannya kecil.

**Rencana Selanjutnya:**
Tim pembangun menangani A-05 lebih dulu (pemetaan galat jaringan ke antrean + pemulihan item `mengirim`,
dengan uji seperti yang saya tulis di temuan), lalu A-01/A-02/A-06 menyesuaikan janji dokumen & celah uji;
setelah semua hijau, sistem layak dibuka ke Fase 11. Saya tidak mengubah kode apa pun sesuai protokol
audit independen.

**Langkah Lee:**
1. **Putuskan target perbaikan A-05** (K-2 penahan gerbang): setujui perbaikan kecil di `App.tsx` +
   `antrean-offline.ts` sebelum pilot — ini tepat yang akan kamu dengar dari kedai pertama bila internet
   mereka tidak stabil.
2. **Dua keputusan produk:** A-02 — apakah aturan "wajib shift" di PRD/TECH_SPEC disesuaikan dengan
   keputusan `wajib_shift` (default-fleksibel), atau bawaannya diperketat jadi wajib? A-06 — terima AA
   dan ubah janjinya, atau naikkan standar kontras ke AAA sesuai pesanmu sebelumnya?
3. Setelah A-05 hijau dan kedua keputusan itu tercatat, perintahkan sesi berikutnya membuka **Fase 11
   (Uji Lapangan & Pilot Kedai Nyata)** sesuai `PANDUAN_PENGGUNA.md`.
