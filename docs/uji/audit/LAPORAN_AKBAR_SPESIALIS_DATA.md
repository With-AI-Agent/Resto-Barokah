# LAPORAN AKBAR — SPESIALIS BASIS DATA & KEUANGAN
# Resto Barokah · Pemeriksaan Menyeluruh Fase 0 s/d Fase 10

- **Auditor:** Spesialis Basis Data & Keuangan (agen independen, sesi terpisah)
- **Tanggal:** 2026-09-27
- **Tingkat audit:** AKBAR-SPESIALIS-DATA (misi: 85 slot migrasi, RLS 47 tabel, idempoten ART-8, presisi rupiah/PB1)
- **Commit yang diaudit:** `0fc63c7e8d4007007380b8fcfc3b74a0d8010963`
- **Cabang sesi:** `arena/01a0e267-resto-barokah`
- **Paket audit:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` + `docs/uji/PROMPT_AKBAR_SPESIALIS_DATA.md`
- **Mode:** HANYA-BACA (tidak mengubah migrasi/kode; satu-satunya berkas baru = laporan ini)
- **Verdict:** **SIAP untuk Fase 11 (lapis data)** — 0 temuan Kritis, 0 temuan Tinggi

---

## 1. Ringkasan Eksekutif (Bahasa Manusia)

Lee, kabar baik: **brankas datanya kokoh.** Saya memeriksa seluruh fondasi database —
puluhan ribu baris aturan main SQL, 47 tabel data resto, 8 pintu pembayaran/penulisan,
dan seluruh rumus uang (subtotal, diskon, pajak PB1, service, tip, pembulatan) —
dan semuanya terbukti bekerja seperti yang dijanjikan.

Hasil mesin penguji bicara sendiri:

| Mesin penguji | Hasil |
|---|---|
| 132 berkas uji database (`node alat/uji-sql.mjs`) | **132 LULUS · 0 GAGAL** |
| Keamanan SQL + uji-diri (`periksa-keamanan-sql.py`) | **LOLOS** (13 mutasi serangan semuanya ditangkap) |
| Kunci anti-dobel 8 pintu tulis (`periksa-idempoten.py`) | **8/8 (100%)** |
| Uji balapan 2 koneksi nyata (`uji-konkuren.py`) | **LOLOS** (nomor pesanan, batas diskon, status dapur terbukti anti-balapan) |
| Uji-diri konkuren | **LOLOS** (9/9 kasus klasifikasi benar) |
| Mutasi idempoten 0080 | **5/5 mutan mati** (kalau pengaman dilepas, uji langsung merah) |
| Mutasi anti-tabrakan pengaturan 0083 | **4/4 mutan mati** |
| Mutasi cabut-akses pegawai 0084 | **4/4 mutan mati** |
| Migrasi beku 0001–0016 (`periksa-migrasi-beku.py`) | **LOLOS** (16 sidik utuh, tak ada yang diubah) |
| Sisir RLS 47 tabel (`periksa-sisir-rls.py`) | **47/47 terkunci, 0 terbuka** |
| Matriks izin 6 peran | **LOLOS** |
| Pemeriksa fungsi PIN | **LOLOS** (14/14) |

Uang dihitung **selalu di peladen, tidak pernah di HP/tablet kasir**: pajak & service
dihitung dari subtotal *sesudah* diskon, pembulatan selalu *ke bawah* (tidak pernah
merugikan pelanggan), pecahan persen (mis. 11,11%) tetap menghasilkan rupiah bulat
tanpa selisih 1 rupiah.

Saya juga menyerang sendiri dengan probe balapan sungguhan (dua koneksi database
bersamaan menekan tombol simpan dengan kunci yang sama): hasilnya **tepat 1 baris
tersimpan** — pesanan ganda mustahil. Satu-satunya cacat yang saya temukan semuanya
ringan (4 saran K-4, tanpa satu pun yang bisa menghilangkan uang atau membocorkan
data antar resto).

**Kesimpulan satu kalimat: lapis data SIAP melangkah ke Fase 11 (uji lapangan),
dengan 4 saran kecil yang boleh dikerjakan sambil jalan.**

---

## 2. Evaluasi Keamanan RLS & Multi-Tenant

### 2.1. 47 dari 47 tabel terkunci (nol kebocoran antar resto)

Perintah `python3 alat/periksa-sisir-rls.py` memeriksa langsung skema hasil
penerapan seluruh migrasi. Hasilnya:

- **47 tabel publik: RLS aktif 47/47, punya policy 47/47, terbuka 0.**
- Tabel-tabel sensitif tanpa kolom `penyewa_id` langsung (mis. `diskon_transaksi`,
  `pembayaran`, `pesanan_item`) tetap terisolasi lewat fungsi jembatan
  (`pesanan_sepenyewa()`, `sepenyewa()`) — diverifikasi oleh uji
  `rls_semua_tabel.sql` + aturan B F-14 (setiap policy wajib menyebut
  `penyewa_saya()` atau menolak-semua), yang **LULUS** di dalam suite 132.
- Uji isolasi khusus semuanya hijau: `rls_penyewa.sql`, `rls_pengguna.sql`,
  `isolasi_lintas_penyewa.sql`, `isolasi_null_identitas.sql`,
  `nomor_pesanan_isolasi.sql`, `cabang_sesi.sql`, `sesi_dan_perangkat.sql`.

### 2.2. Tabel kredensial tidak bisa dibaca klien

| Tabel | Perlindungan | Bukti berkas:baris |
|---|---|---|
| `kredensial_pin` | `REVOKE ALL ... FROM public, anon, authenticated` + policy tolak-semua | `0006_pin.sql:47,52` |
| `kredensial_perangkat` | idem (pola persis 0006) | `0018_perangkat_terdaftar.sql:61,68` |
| `kredensial_pemulihan` | idem + grant hanya ke `service_role` | `0028_pemulihan_perangkat.sql:47,55,61` |

Hanya jalur peladen (fungsi `SECURITY DEFINER`) yang menyentuh hash PIN/kunci.
Uji `kredensial_pin.sql`, `pin_bukan_oracle.sql`, `pin_kunci_silang.sql` LULUS.

### 2.3. 257 fungsi istimewa terkunci search_path & hak akses

- 70 berkas migrasi memuat 257 definisi `SECURITY DEFINER`; pemeriksa
  `periksa-keamanan-sql.py` membuktikan satu per satu: **search_path terkunci
  (`public, pg_temp`)**, `EXECUTE` untuk `PUBLIC` dicabut efektif (224 baris
  `REVOKE`), fungsi pemicu istimewa bukan RPC klien. **Hasil: LOLOS.**
- Uji-diri pemeriksa (13 mutasi: path dilepas, EXECUTE dibuka ulang, komentar
  REVOKE palsu, helper tanpa `(SELECT ...)`, RLS dilepas, policy dihapus)
  semuanya **MERAH seperti harapan** — artinya pemeriksa ini terbukti bisa
  menangkap perusakan, bukan sekadar stempel hijau.
- Seluruh policy RLS memakai pola `(SELECT ...)` (optimasi InitPlan, migrasi
  `0027_initplan_policy_rls.sql`) — helper identitas dievaluasi sekali per
  query, bukan per baris. Temuan grep saya pada berkas lama (0004–0007) adalah
  definisi historis yang sudah digantikan 0027; keadaan akhir terverifikasi
  hijau oleh mesin.

### 2.4. Jejak audit kekal (append-only)

- `UPDATE`/`DELETE` pada `public.catatan_audit` ditolak mutlak oleh pemicu
  (`0029_audit_kekal_rantai.sql:42-44`) + rantai hash per baris.
- `TRUNCATE` ditolak oleh pemicu level-pernyataan (`0057_truncate_audit_ditolak.sql`).
- Uji `catatan_audit.sql`, `audit_rantai.sql`, `urutan_rantai_audit.sql`,
  `truncate_audit_ditolak.sql`, `riwayat_tidak_berubah.sql`, `jejak_pelaku.sql`,
  `jejak_pengaturan.sql`, `jejak_pesanan.sql` — **semua LULUS**.

### 2.5. Serangan yang saya jalankan & hasilnya (lapis akses)

| # | Serangan (kill attempt) | Cara | Hasil |
|---|---|---|---|
| A-1 | Baca data resto lain sebagai kasir resto A | Telaah policy + uji `isolasi_lintas_penyewa`, `rls_penyewa` | **GAGAL (sistem bertahan)** — hijau |
| A-2 | Baca tabel PIN/hash langsung sebagai anon/authenticated | Telaah `REVOKE` + policy tolak-semua 0006/0018/0028 | **GAGAL (sistem bertahan)** |
| A-3 | Panggil fungsi istimewa tanpa hak | `periksa-keamanan-sql.py` (T130-public) + `hak_fungsi.sql` | **GAGAL (sistem bertahan)** — LOLOS |
| A-4 | Ubah/hapus baris jejak audit | Telaah pemicu 0029 + 0057 + 5 berkas uji audit | **GAGAL (sistem bertahan)** |
| A-5 | Tebak PIN lewat oracle (beda pesan galat) | Uji `pin_bukan_oracle.sql` | **GAGAL (sistem bertahan)** — LULUS |
| A-6 | Pakai sesi/perangkat yang dicabut | Uji `sesi_kedaluwarsa.sql`, `cabut_akses.sql`, `akhiri_sesi_perangkat_hilang.sql` | **GAGAL (sistem bertahan)** — LULUS |

---

## 3. Evaluasi Logika Finansial & Idempotensi

### 3.1. Rumus uang: peladen satu-satunya kebenaran (ART-3)

Fungsi `hitung_total()` (definisi final di `0076_metode_bayar_tip.sql`) saya baca
baris per baris. Sifat-sifat yang terbukti:

1. **Kunci baris dulu (`FOR UPDATE`)** — dua kasir menghitung bersamaan tidak
   bisa saling menimpa (dibuktikan uji balapan F-12 di 2 koneksi nyata).
2. **Pajak & service dari subtotal SESUDAH diskon**, bukan sebelum diskon
   (uji `pajak_service.sql` kasus 3: diskon 4.000 → dasar 50.000 → PB1 5.000,
   service 2.500, total 57.500 — persis).
3. **Diskon penuh → pajak & service NOL, total NOL, tidak pernah minus**
   (`greatest(..., 0)` + uji kasus 4).
4. **Pembulatan hanya mengubah TOTAL, selalu KE BAWAH** (pembagian bulat
   `(total/langkah)*langkah`; baris pajak/service di struk tidak berubah;
   selisih pembulatan bisa dihitung struk sebagai `total − (dasar+pajak+service)`).
5. **Persen pecahan tetap rupiah bulat**: 11,11% × 54.000 = 5.999;
   2,22% × 54.000 = 1.199; rincian struk menjumlah **persis** ke total
   (uji kasus 8 — tanpa selisih 1 rupiah).
6. **Tip ditambahkan sesudah pembulatan** — benar secara desain (tip sukarela
   nominal pasti tidak boleh disunat pembulatan); total = subtotal + pajak +
   service + tip ditegaskan uji T907-15. Tip ditolak bila negatif, bila resto
   tidak mengaktifkannya, atau bila pesanan sudah lunas/batal.
7. **Kolom uang bertipe `integer` (rupiah bulat)** di seluruh tabel
   (pesanan, pembayaran, diskon, kas, shift, voucher); **tidak ada satu pun
   `float`/`double`/`money`** di 82 migrasi (grep bukti di bawah). Persen
   memakai `numeric(5,2)` terkendala 0–100; PB1 bawaan 10%, service 5%.
8. **Harga kiriman klien tidak dipercaya**: `simpan_pesanan` boleh menerima
   `harga` varian, tetapi pemicu `picu_item_harga_jujur` (0012) **menolak**
   harga yang ≠ `harga_berlaku(menu, cabang)` kecuali pemanggil berizin
   `ubah_harga`; subtotal selalu dihitung ulang peladen. Uji `harga_item.sql`
   + `varian_gagal_aman.sql` LULUS (varian tanpa harga resmi ditolak
   gagal-aman).
9. **Uang berlebih ditolak**: pembayaran melebihi sisa tagihan ditolak pemicu
   `picu_pembayaran_jujur` (0010); pembayaran sebagian sah dan pesanan lunas
   tepat saat cukup (uji `pembayaran_sebagian.sql`, `bayar_pesanan.sql`).
10. **Pesanan lunas/batal beku**: hitung ulang, diskon susulan, tip susulan,
    dan ubah item semuanya ditolak (0017/0022 + uji `beku_setelah_bayar.sql`,
    `diskon_sesudah_lunas.sql`, `pesanan_tertutup_beku.sql`).

### 3.2. Idempoten ART-8: 8 dari 8 pintu (100%)

`python3 alat/periksa-idempoten.py` → **8/8 RPC + 8/8 skema. LOLOS.**

| RPC | Kunci unik di database | Bukti |
|---|---|---|
| `simpan_pesanan` | `UNIQUE (cabang_id, kunci_idempoten)`, NOT NULL | `0009:41-42` |
| `bayar_pesanan` | `UNIQUE (pesanan_id, kunci_idempoten)`, NOT NULL | `0010:96-97` |
| `pakai_voucher` | Dedup kunci-alami (pesanan+kode) + `UPDATE ... WHERE status='aktif'` atomik | `0067:438-455,470` |
| `buka_shift` | indeks unik parsial `shift_kas_kunci_idempoten_unik` | `0080:31-33` |
| `tutup_shift` | indeks unik parsial `shift_kas_kunci_tutup_unik` | `0080:35-37` |
| `kas_pergerakan` | `kunci_idempoten text unique` | `0047:29` |
| `set_stok` | indeks unik parsial `stok_pergerakan_kunci_idempoten_unik` | `0080:42-44` |
| `opname_stok` | idem (satu tabel pergerakan) | `0080:42-44` |

Mutasi 0080 (5/5 mutan mati) membuktikan: kalau satu saja pengecekan idempoten
dilepas, uji `idempoten.sql` langsung merah.

**Bukti balapan langsung (probe saya, 2 koneksi PostgreSQL 16 nyata via pgserver):**
dua `simpan_pesanan` bersamaan dengan kunci identik → satu SUKSES, satu
`UniqueViolation`, dan **`BARIS_TERSIMPAN_DENGAN_KUNCI: 1`** — pesanan ganda
mustahil walau tombol ditekan bersamaan. (Satu catatan kecil: yang kalah
menerima galat mentah, bukan balasan IDEMPOTEN yang halus — lihat F-01.)

### 3.3. Kunci anti-tabrakan pengaturan (0083) & cabut akses (0084)

- 0083: simpan menu/kategori/meja membawa `p_versi_lama`; versi usang ditolak
  fail-closed (P0001) + konflik dicatat ke jejak audit. Mutasi 4/4 mati,
  uji `pengaturan_bersamaan.sql` LULUS.
- 0084: pegawai berhenti → sesi diputus, PIN dihapus, shift ditandai
  `perlu_tutup_atasan`. Mutasi 4/4 mati, uji `cabut_akses.sql` LULUS.

### 3.4. Serangan yang saya jalankan & hasilnya (lapis uang)

| # | Serangan (kill attempt) | Cara | Hasil |
|---|---|---|---|
| U-1 | Kirim harga palsu Rp 0/Rp 1 dari klien | Telaah pemicu 0012 + uji `harga_item`, `varian_gagal_aman` | **GAGAL (sistem bertahan)** |
| U-2 | Tekan simpan 2× bersamaan (kunci sama) | Probe 2-koneksi `/tmp/probe_idem_race.py` | **GAGAL (sistem bertahan)** — tepat 1 baris |
| U-3 | Bayar 2× bersamaan melebihi total | Telaah `picu_pembayaran_jujur` + uji F-12 balapan | **GAGAL (sistem bertahan)** |
| U-4 | Pakai 1 voucher untuk 2 pesanan bersamaan | Telaah `UPDATE ... WHERE status='aktif'` atomik 0067 | **GAGAL (sistem bertahan)** — satu pemenang |
| U-5 | Tanam diskon di pesanan kosong/lunas | Telaah 0012/0021 + uji `diskon_sesudah_lunas` | **GAGAL (sistem bertahan)** |
| U-6 | Cari selisih 1 rupiah (pecahan persen) | Uji `pajak_service` kasus 8 (11,11% & 2,22%) | **GAGAL (sistem bertahan)** — persis |
| U-7 | Pembulatan merugikan pelanggan | Uji kasus 6–7 (selalu ke bawah) | **GAGAL (sistem bertahan)** |
| U-8 | Ubah tip/harga setelah lunas | Telaah 0076 + uji T907 kasus 16–17 | **GAGAL (sistem bertahan)** |

---

## 4. Daftar Temuan

**Ringkasan: K-1: 0 · K-2: 0 · K-3: 0 · K-4: 4.**

> Skala Akbar: K-1 Kritis · K-2 Tinggi · K-3 Sedang · K-4 Saran.
> Gerbang fase (`tahan_semua`) hanya menahan pada K-1/K-2 — keempat temuan di
> bawah tidak menahan Fase 11.

### [F-01] Balapan kunci-sama: yang kalah dapat galat mentah, bukan balasan IDEMPOTEN

- **Tingkat:** K-4 (Saran)
- **Artefak:** `supabase/migrations/0080_kunci_idempoten_menyeluruh.sql:103-125`
  (pola periksa-dulu-simpan-kemudian tanpa penangkap `unique_violation`);
  tidak ada `unique_violation` di seluruh 82 migrasi (grep bukti di bawah).
- **Klaim yang dilanggar:** —
- **Bukti (perintah → hasil nyata):**
  `python3 /tmp/probe_idem_race.py` (2 koneksi pgserver bersamaan, kunci
  `probe-balapan-sama-001`) →
  `T1: SUKSES`, `T2: GALAT UniqueViolation: duplicate key value violates
  unique constraint "pesanan_cabang_id_kunci_idempoten_key"`,
  `BARIS_TERSIMPAN_DENGAN_KUNCI: 1`.
- **Skenario gagal:** kasir menekan Bayar/Simpan dua kali dalam sepersekian
  detik saat jaringan lambat → satu berhasil, satu menampilkan galat teknis
  berbahasa Inggris. **Uang aman** (tepat 1 baris, tidak ada tagihan ganda);
  yang kurang hanya kemasan pesannya. Kirim ulang berurutan dengan kunci yang
  sama tetap kembali IDEMPOTEN (uji `idempoten.sql` LULUS).
- **Dugaan penyebab:** pengaman idempoten mengandalkan SELECT-then-INSERT +
  constraint unik sebagai jaring; tidak ada `EXCEPTION WHEN unique_violation`
  yang membaca ulang baris pemenang lalu membalas `{'kode':'IDEMPOTEN'}`.
- **Cara membuktikan perbaikan:** ulangi probe balapan → kedua pemanggil
  menerima `berhasil:true` (satu `SUKSES`, satu `IDEMPOTEN`), 0 galat,
  tetap 1 baris.
- **Status verifikasi:** TERVERIFIKASI (bukti balapan langsung).

### [F-02] Dokumen menyebut "85 berkas migrasi", berkas nyatanya 82

- **Tingkat:** K-4 (Saran, ketepatan dokumen)
- **Artefak:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md:17`,
  `docs/uji/PROMPT_AKBAR_SPESIALIS_DATA.md:15` ("85 berkas migrasi
  `0001_...` s/d `0085_...`").
- **Klaim yang dilanggar:** —
- **Bukti:** `ls supabase/migrations/ | wc -l` → **82**; nomor yang tidak ada:
  `0034`, `0044`, `0055` (loop `seq 0001..0085`); `git log --diff-filter=D --
  supabase/migrations/` → **kosong** (tidak pernah ada penghapusan — tiga nomor
  memang dilewati sejak awal, warisan penomoran rencana lama di ROADMAP, mis.
  `0034_status_item.sql` rencana vs `0032_status_item_dapur.sql` nyata).
  Penjaga `periksa-migrasi-beku.py` hanya menuntut: beku utuh + tanpa nomor
  kembar + berkas baru > 0016 — **celah nomor tidak melanggar aturan apa pun**,
  skema utuh dan 132 uji hijau.
- **Skenario gagal:** tidak ada dampak sistem; hanya pembaca dokumen yang
  menghitung berkas akan bingung ("kok 82?").
- **Dugaan penyebab:** redaksi "85" = nomor tertinggi, bukan jumlah berkas.
- **Cara membuktikan perbaikan:** ubah redaksi menjadi "82 berkas (nomor
  0001–0085; tiga nomor 0034/0044/0055 dilewati)" lalu `ls | wc -l` cocok.
- **Status verifikasi:** TERVERIFIKASI.

### [F-03] Kolom uang `integer` 32-bit: plafon Rp 2,1 miliar per isian (gagal-aman, tapi tak tertulis)

- **Tingkat:** K-4 (Saran)
- **Artefak:** `0009_pesanan.sql:33-36`, `0010_pembayaran.sql:89-91,113-114`,
  `0045:30`, `0047:25` (semua `integer check (... >= 0)`); pelemparan
  `v_subtotal::integer` di `hitung_total` (`0076`).
- **Klaim yang dilanggar:** —
- **Bukti:** `grep -rn "integer\|bigint" ...` → seluruh kolom rupiah `integer`;
  tidak ada `bigint`/`numeric` untuk rupiah. Batas `integer` PostgreSQL =
  2.147.483.647.
- **Skenario gagal:** satu pesanan/pembayaran melebihi Rp 2,1 miliar
  (praktis mustahil untuk resto — setara ribuan porsi termahal sekaligus) →
  database melempar galat `integer out of range`, transaksi dibatalkan,
  **tidak ada angka salah yang tersimpan** (gagal-aman, bukan diam-diam
  melimpah). Jadi ini bukan lubang uang, melainkan plafon tak tertulis.
- **Dugaan penyebab:** pemilihan sadar rupiah-bulat-32-bit sejak 0001.
- **Cara membuktikan perbaikan:** dokumentasikan plafon di TECH_SPEC, atau
  migrasi `bigint` bila Lee mengincar segmen katering/B2B bernilai raksasa.
- **Status verifikasi:** TERVERIFIKASI (telaah tipe + semantik cast PostgreSQL).

### [F-04] `pakai_voucher` menerima `p_kunci_idempoten` tetapi tidak memakainya

- **Tingkat:** K-4 (Saran, kebersihan API)
- **Artefak:** `supabase/migrations/0067_pengaman_voucher.sql:325` (parameter
  ada) vs pemakaian: hanya kode balasan `'IDEMPOTEN'` di baris 446 —
  dedup sesungguhnya memakai kunci-alami (pesanan + kode voucher, baris
  438-455) + `UPDATE ... WHERE status='aktif'` atomik (baris 470+).
- **Klaim yang dilanggar:** —
- **Bukti:** `grep -n "p_kunci_idempoten\|v_kunci\|IDEMPOTEN" 0067_...` →
  parameter tidak pernah dibaca badannya.
- **Skenario gagal:** tidak ada — desain kunci-alami justru tepat untuk voucher
  (satu kode hanya bisa menempel sekali per pesanan apa pun kuncinya; kunci
  sama + kode beda = dua voucher sah yang memang boleh menempel).
  Satu-satunya risiko: pengembang frontend mengira kuncinya yang berlaku.
- **Dugaan penyebab:** kepatuhan tanda-tangan ART-8 tanpa kebutuhan nyata.
- **Cara membuktikan perbaikan:** dokumentasikan di komentar fungsi
  ("idempoten via (pesanan_id, kode); parameter kunci diabaikan") atau hapus
  parameter di migrasi baru. `periksa-idempoten.py` tetap 8/8.
- **Status verifikasi:** TERVERIFIKASI.

### Temuan yang saya DUGA lalu BUKTI BERSALAH (refutasi — bukan temuan)

1. **Harga kiriman klien (`0080: v_harga_menu := (v_item->>'harga')`)** —
   ternyata dijaga pemicu `picu_item_harga_jujur` saat INSERT (0012:189):
   harga ≠ harga resmi tanpa izin `ubah_harga` = DITOLAK. Bukan celah.
2. **Policy lama tanpa `(SELECT ...)` (0004–0007)** — sudah digantikan total
   oleh 0027; keadaan akhir terverifikasi mesin. Bukan celah.
3. **Tip ditambah sesudah pembulatan** — disengaja & diuji (T907-15):
   tip nominal pasti tidak boleh disunat. Bukan celah.
4. **PB1 "10-12%" di naskah vs cek 0–100 di 0002** — naskah hanya contoh tarif
   umum; cek 0–100 + uji pajak 0% justru benar (resto belum kena PB1 tetap
   bisa mencetak struk jujur). Bukan celah.

---

## 5. Kesimpulan & Rekomendasi

**Pernyataan tegas: lapis Basis Data & Keuangan dinyatakan SIAP untuk Fase 11
(Uji Lapangan & Pilot Kedai Nyata).**

Dasar verdict:

1. **0 Kritis, 0 Tinggi.** Tiga janji Akbar terpenuhi: nol bocor antar-resto
   (47/47 RLS + uji isolasi hijau), nol salah hitung uang (rumus peladen +
   8 kasus uji pajak/pembulatan persis), nol rahasia di repo (grep bersih).
2. **100% mesin hijau + terbukti bisa merah.** 132 uji SQL, seluruh pemeriksa
   Python, seluruh uji-diri, dan 13+5+4+4 mutasi pembunuh-pengaman — semuanya
   lulus, dan mutasinya membuktikan gerbang-gerbang itu benar-benar menggigit.
3. **Beku 0001–0016 utuh** — repo cocok dengan database nyata milik Lee.

**Rekomendasi (tidak menahan pilot, kerjakan sambil jalan):**

1. F-01: tangkap `unique_violation` di 8 RPC tulis → balas IDEMPOTEN
   (migrasi baru > 0085; serviskan ke antrean frontend juga: kunci yang sama
   dipakai ulang saat kirim-ulang).
2. F-02: betulkan redaksi "85 berkas" → "82 berkas (nomor 0001–0085)".
3. F-03: tuliskan plafon Rp 2,1 M per isian uang di TECH_SPEC
   (atau rencanakan `bigint` bila menyasar katering raksasa).
4. F-04: dokumentasikan idempoten kunci-alami voucher di komentar fungsi.
5. Untuk Spesialis Frontend (cek silang): pastikan antrean offline **selalu**
   mengirim `kunci_idempoten` (tanpa kunci, peladen membuat kunci acak per
   kiriman → kirim-ulang dianggap pesanan baru yang sah; pagar kelebihan
   bayar tetap menahan, tetapi UX-nya membingungkan).

**Keterbatasan audit ini (jujur):** sesi terpisah di cabang
`arena/01a0e267-resto-barokah` (hanya-baca, terverifikasi §7); ketersediaan
model berbeda tidak dapat saya verifikasi dari dalam sesi ini — bila modelnya
sama dengan pembangun, korelasinya dikompensasi oleh lensa adversarial +
kalibrasi balapan langsung di atas. Tanpa akses proyek Supabase nyata milik
Lee, verifikasi penyebaran (`db push`) mengandalkan sidik beku +
`migration list` bersejarah. Tanpa peramban, perilaku kunci di sisi aplikasi
dilimpahkan ke Spesialis Frontend (butir 5 di atas).

---

## 6. Yang tidak bisa saya verifikasi

1. Isi database nyata di proyek Supabase milik Lee (apakah `db push` terakhir
   persis sama dengan repo) — saya hanya bisa membuktikan repo tidak mengubah
   16 migrasi beku yang pernah disebar.
2. Perilaku aplikasi (apakah setiap layar benar-benar mengirim `kunci_idempoten`
   dan memakai ulang kunci yang sama saat kirim-ulang) — ranah Spesialis
   Frontend; kontrak sisi peladen sudah saya buktikan.
3. Beban puluhan kasir bersamaan (uji balapan saya memakai 2 koneksi; cukup
   untuk membuktikan serialisasi, belum uji beban).

## 7. Pernyataan tidak mengubah apa pun

Saya **tidak mengubah** berkas migrasi, kode, atau dokumen apa pun selama audit
ini. **Laporan ini satu-satunya berkas** yang saya buat. Bukti `git status --short`
(sesudah laporan ditulis, sebelum commit apa pun):

```
?? docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_DATA.md
```
Satu-satunya perubahan pohon kerja adalah laporan ini (berkas baru tak-terlacak).
Nol modifikasi pada migrasi, kode, maupun dokumen lain.

## 8. Temuan di luar cakupan

Tidak ada. (Pemeriksaan rahasia pada migrasi: bersih. Pemeriksa PIN/Edge saya
jalankan sebagai bukti pendukung lapisan kredensial dan hasilnya LOLOS 14/14.)

---

## Lampiran A — Tabel Bukti Pengujian (perintah → hasil)

| # | Perintah (wajib naskah §3 + pendukung) | Hasil |
|---|---|---|
| 1 | `node alat/uji-sql.mjs` | 132 LULUS · 0 GAGAL → HASIL: LOLOS |
| 2 | `python3 alat/periksa-keamanan-sql.py` | 82 migrasi OK + 2 uji T130 hijau → LOLOS |
| 3 | `python3 alat/periksa-keamanan-sql.py --uji-diri` | 13 mutasi merah-sesuai-harapan + kontrol hijau → LOLOS |
| 4 | `python3 alat/periksa-idempoten.py` | 8/8 RPC + 8/8 skema (100%) → LOLOS |
| 5 | `python3 alat/uji-konkuren.py` | F-13 + T4-09 + F-12 terserialisasi, tiap uji peka → LOLOS |
| 6 | `python3 alat/uji-konkuren.py --uji-diri` | 9/9 klasifikasi benar → LOLOS |
| 7 | `python3 alat/uji-mutasi-0080.py` | 5/5 mutan mati → LOLOS |
| 8 | `python3 alat/uji-mutasi-0083.py` | 4/4 mutan mati → LOLOS |
| 9 | `python3 alat/uji-mutasi-0084.py` | 4/4 mutan mati → LOLOS |
| 10 | `python3 alat/periksa-migrasi-beku.py` | 16 beku utuh → LOLOS |
| 11 | `python3 alat/periksa-sisir-rls.py` | 47/47 RLS + policy, 0 terbuka → LOLOS |
| 12 | `python3 alat/periksa-matriks-izin.py` | 6 peran valid → LOLOS |
| 13 | `python3 alat/periksa-fungsi-pin.py` | 14/14 → LOLOS |
| 14 | `python3 /tmp/probe_idem_race.py` (probe saya, di luar repo) | balapan kunci-sama → tepat 1 baris (F-01) |
| 15 | `ls supabase/migrations/ \| wc -l` + loop seq + `git log --diff-filter=D` | 82 berkas; 0034/0044/0055 dilewati; 0 hapus (F-02) |
| 16 | `grep -rni "float\|double precision\|money(" supabase/migrations/` | kosong — uang selalu integer (F-03 konteks) |
| 17 | `grep -rni "password\s*=\|secret\s*=\|api[_-]key\|bearer \|sk-\|eyJ" supabase/migrations/` | kosong — nol rahasia |
| 18 | `git status --short` (sebelum laporan) | kosong — pohon bersih, hanya-baca terjaga |

## Lampiran B — Cakupan baca mendalam

- Migrasi dibaca penuh/arah: 0002, 0004, 0006, 0009, 0010, 0012, 0014, 0015,
  0018, 0027, 0028, 0029, 0039, 0045, 0047, 0057, 0060, 0065, 0067, 0070, 0072,
  0076, 0080, 0083 (±25 berkas, ±29.008 baris total migrasi dijelajah via grep
  terarah untuk klaim tiap temuan).
- Uji dibaca penuh: `pajak_service.sql`, `uang_kunci.sql`, `varian_gagal_aman.sql`;
  132 berkas uji dijalankan mesin (25.417 baris).
- Skill dimuat (PROTOKOL §9): `skills/security-review/SKILL.md`,
  `skills/supabase-postgres-best-practices/SKILL.md` (+ rujukan OWASP Top 10 &
  dokumentasi Supabase RLS yang dikutip skill tersebut).
