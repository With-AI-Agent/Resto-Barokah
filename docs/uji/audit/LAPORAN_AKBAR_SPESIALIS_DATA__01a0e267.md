# LAPORAN AKBAR — SPESIALIS BASIS DATA & KEUANGAN
## Pemeriksaan Akbar Menyeluruh Fase 0 s/d Fase 10 · Resto Barokah

| | |
|---|---|
| **Peran** | Spesialis Basis Data & Keuangan (Pemeriksa Horizontal #2) |
| **Mandat** | `docs/uji/PROMPT_AKBAR_SPESIALIS_DATA.md` + `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` |
| **Protokol** | Audit independen **HANYA-BACA** — tidak ada satu pun berkas migrasi/kode yang diubah |
| **Cabang / SHA** | `arena/01a0e267-resto-barokah` @ `0fc63c7e8d4007007380b8fcfc3b74a0d8010963` |
| **Tanggal** | 2026-09-27 |
| **Mesin uji** | Node v22.22.3 (PGlite) + Python 3.11.2 + PostgreSQL 16.2 nyata (pgserver, sementara di sandbox) |

> **Catatan penamaan:** laporan ini terbit **berdampingan** dengan
> `LAPORAN_AKBAR_SPESIALIS_DATA.md` (putaran auditor lain, commit `5b76a8c`) yang lebih dulu
> menempati jalur kanonik. Keduanya audit independen atas SHA `0fc63c7` dan vonisnya **selaras**:
> SIAP Fase 11, 0 K-1, 0 K-2. Akhiran `__01a0e267` = id sesi Arena penulis laporan ini
> (mengikuti konvensi berkas laporan multi-agen di folder ini).

---

## 1. Ringkasan Eksekutif (Bahasa Manusia)

Lee, saya sudah membongkar dan menguji ulang seluruh lapisan data Resto Barokah dari nol:
semua berkas migrasi, kunci keamanan 47 tabel, mesin hitung uang, dan perlindungan terhadap
transaksi dobel. Hasilnya: **sangat sehat**.

- **Semua gerbang uji mesin hijau.** 132 berkas uji SQL lulus tanpa satu pun kegagalan;
  pemeriksa keamanan SQL, pemeriksa idempoten, uji konkurensi dua koneksi nyata, dan uji
  mutasi 0080/0083/0084 semuanya LOLOS — termasuk uji-diri yang membuktikan alat-alat itu
  *peka* (bisa merah kalau proteksinya dilepas), bukan hijau karena longgar.
- **Tidak ada celah bocor antar resto.** Saya uji sendiri di PostgreSQL nyata: kasir
  "Warung Bandung" benar-benar buta total atas data "Kedai Oasis" (0 baris terlihat).
- **Rahasia PIN dan kunci perangkat terkunci rapat.** Bahkan peran `service_role` pun
  tidak diberi hak tulis langsung ke tabel hash PIN — hanya fungsi peladen resmi yang
  bisa menyentuhnya. Klien (anon/authenticated) ditolak mentah-mentah.
- **Jejak audit tidak bisa dipalsukan.** UPDATE, DELETE, bahkan TRUNCATE pada
  `catatan_audit` ditolak trigger **meskipun dilakukan oleh pemilik tabel**.
- **Uang dihitung peladen sampai rupiah terkecil, tanpa pecahan.** Kasus tersulit
  (dasar ganjil 12.345 × PB1 10% = 1.234,5) dibulatkan naik menjadi tepat Rp1.235 —
  tidak ada setengah rupiah yang nyangkut; pembulatan struk selalu KE BAWAH
  (keuntungan pelanggan).
- **Kirim dobel tidak menghasilkan uang dobel.** RPC `simpan_pesanan` yang dikirim dua
  kali dengan kunci sama menghasilkan tepat 1 pesanan dengan balasan "IDEMPOTEN";
  kelebihan bayar ditolak pagar BY-301 di peladen.

**Temuan: 0 Kritis (K-1), 0 Tinggi (K-2), 1 Sedang (K-3), 3 Saran (K-4)** — semuanya
berkadar dokumentasi/desain, tidak satu pun menghentikan langkah ke Fase 11.

---

## 2. Tabel Bukti Pengujian Mesin (perintah wajib §3 prompt)

Semua perintah dijalankan apa adanya di terminal, pada SHA di atas:

| # | Perintah | Hasil | Kesimpulan |
|---|---|---|---|
| 1 | `node alat/uji-sql.mjs` | `uji: 132 LULUS · 0 GAGAL` → `HASIL: LOLOS` (exit 0); 82 migrasi diterapkan berurutan tanpa galat | ✅ LOLOS |
| 2a | `python3 alat/periksa-keamanan-sql.py` | `HASIL: LOLOS` — lingkup: search_path + ACL efektif + trigger-only + sapuan RLS + optimasi InitPlan | ✅ LOLOS |
| 2b | `python3 alat/periksa-keamanan-sql.py --uji-diri` | `13 mutasi, kontrol awal/akhir, kalibrasi rusak; 0 tidak sesuai` → LOLOS | ✅ LOLOS |
| 3 | `python3 alat/periksa-idempoten.py` | `8/8 RPC (100.0%)` punya kunci idempoten (RPC & Skema) → LOLOS | ✅ LOLOS |
| 4a | `python3 alat/uji-konkuren.py` | F-13 (nomor pesanan), T4-09 (riwayat status), F-12 (cap diskon) terserialisasi di 2 koneksi nyata; tiap uji terbukti peka → LOLOS | ✅ LOLOS |
| 4b | `python3 alat/uji-konkuren.py --uji-diri` | `9 kasus klasifikasi, 0 tidak sesuai` → LOLOS | ✅ LOLOS |
| 5a | `python3 alat/uji-mutasi-0080.py` | 5/5 mutasi (idempoten dilepas per RPC) TERBUKTI MERAH → LOLOS | ✅ LOLOS |
| 5b | `python3 alat/uji-mutasi-0083.py` | Baseline hijau; `4/4 MUTAN MATI` — proteksi konkurensi fail-closed | ✅ LOLOS |
| 5c | `python3 alat/uji-mutasi-0084.py` | `4/4 mutan terbunuh — 100% FAIL-CLOSED TERBUKTI` | ✅ LOLOS |
| 6 | `python3 alat/periksa-migrasi-beku.py` (cakupan §2.1) | 16 migrasi beku (0001–0016) utuh → LOLOS | ✅ LOLOS |
| 7 | `python3 alat/periksa-sisir-rls.py` (cakupan §2.2) | **47/47 tabel RLS aktif · 47/47 ber-policy · 0 tabel terbuka** → LOLOS | ✅ LOLOS |
| 8 | `python3 alat/periksa-sisir-rls.py --uji-diri` | semua mutasi kebocoran RLS (tabel tanpa RLS / tanpa policy / tanpa jangkar / policy terbuka) tertangkap → LOLOS | ✅ LOLOS |

**Catatan lingkungan (jujur dicatat):** saat audit dimulai, dependensi uji belum terpasang
(`alat/node_modules` kosong; `pgserver`+`psycopg` tidak ada). Saya pasang keduanya di
sandbox: `cd alat && npm ci` (masuk `.gitignore` via `node_modules`) dan venv Python lokal
`.venv` yang **saya hapus lagi setelah semua uji tercatat** sehingga jejak git audit ini
tetap nol di luar berkas laporan. **Tidak ada berkas repo yang diubah** — lihat K-4-2 untuk sarannya.

---

## 3. Bukti Probe Independen (bukan sekadar percaya alat repo)

Saya menulis probe sendiri (skrip di `/tmp`, di luar repo — protokol hanya-baca terjaga),
menjalankan **PostgreSQL 16.2 nyata** dengan **seluruh 82 migrasi + data uji**, lalu
menyerang skema langsung. Hasil: **20/20 bukti sesuai harapan**.

| # | Skenario serangan | Hasil nyata di server |
|---|---|---|
| P1a | `authenticated` membaca `kredensial_pin` (sengaja diisi 1 hash) | ❌ DITOLAK `permission denied for table kredensial_pin` |
| P1b | `authenticated` membaca `kredensial_perangkat` | ❌ DITOLAK `permission denied` |
| P1c | `authenticated` membaca `kredensial_pemulihan` (sengaja diisi 1 kode) | ❌ DITOLAK `permission denied` |
| P1d–f | `anon` membaca ketiga tabel kredensial | ❌ DITOLAK semua |
| P1g | `service_role` MENULIS ke `kredensial_pin` | ❌ DITOLAK — tidak ada grant tabel sama sekali; tulis hanya lewat fungsi SECURITY DEFINER resmi |
| P2a | Pemilik tabel melakukan `UPDATE catatan_audit` | ❌ DITOLAK trigger: *"Catatan audit bersifat permanen dan tidak dapat diubah atau dihapus."* |
| P2b | Pemilik tabel melakukan `DELETE catatan_audit` | ❌ DITOLAK trigger (pesan sama) |
| P2c | Pemilik tabel melakukan `TRUNCATE catatan_audit` | ❌ DITOLAK: *"Pemotongan tabel catatan_audit dilarang"* (0057) |
| P2d | Jumlah baris audit sesudah serangan | utuh (1 → 1) |
| P3a | `simpan_pesanan` kirim #1 (kunci `probe-art8-kunci`) | `kode=SUKSES`, total Rp62.100 (2×27.000 + PB1 10% + service 5%) |
| P3b | kirim #2 kunci sama | `kode=IDEMPOTEN` — rekaman lama dikembalikan, bukan pesanan baru |
| P3c | Jumlah pesanan di tabel | tepat **1 baris** — uang tidak berlipat |
| P4 | Kasir resto B (Warung Bandung) `SELECT` seluruh `pesanan` | **0 baris terlihat** — data Kedai Oasis tak tersentuh RLS |
| P5a | PB1 10% atas dasar ganjil 12.345 (kasus .5) | pajak = **1.235** (naik, tanpa pecahan rupiah) |
| P5b | Total pesanan | 12.345 + 1.235 = **13.580** persis |
| P5c | Pembulatan struk 500 | total → **13.500 (KE BAWAH)**; baris pajak tetap 1.235 (struk jujur, selisih terhitung) |
| P6 | `simpan_menu` dengan versi usang (0083) | ❌ DITOLAK: *"Data menu sudah diubah oleh pengguna lain. Silakan muat ulang halaman."* |

---

## 4. Evaluasi Keamanan RLS & Multi-Tenant (ART-1)

**Klaim: 47 tabel publik, semua RLS. TERBUKTI.**

- `periksa-sisir-rls.py` (katalog PostgreSQL asli, bukan regex): **47/47 `relrowsecurity=true`,
  47/47 punya policy terdaftar, 0 tabel terbuka**. Setiap tabel ber-`penyewa_id` terikat
  isolasi `penyewa_saya()`; tabel tanpa `penyewa_id` wajib terdaftar dengan jangkar resmi
  (`pesanan_sepenyewa`, `cabang_pantau_saya`, `TOLAK-SEMUA`, dst.) — tabel baru yang
  muncul tanpa jangkar langsung membuat uji GAGAL (terbukti di uji-diri).
- `supabase/tes/rls_semua_tabel.sql` (B F-14, 2026-09-21): **SETIAP** policy pada tabel
  tanpa `penyewa_id` wajib menyebut jangkarnya atau menolak-semua — LULUS.
- **Tabel kredensial:** pola "tolak semua" tiga lapis — (1) `REVOKE ALL … FROM public, anon,
  authenticated` (0006:47, 0028:47), (2) policy `using (false)` (0006:52, 0028:55),
  (3) tanpa grant tabel ke `service_role` untuk `kredensial_pin`/`kredensial_perangkat`
  (probe P1g: tulis pun ditolak). PIN disimpan hanya sebagai hash (CHECK
  `pin_hash ~ '^\$[a-z0-9]+\$'` menolak nilai bukan-hash).
- **Isolasi lintas penyewa terbukti hidup** (probe P4 + `supabase/tes/isolasi_lintas_penyewa.sql` LULUS):
  kasir resto lawan melihat 0 baris.
- Kebijakan InitPlan `(SELECT penyewa_saya())` konsisten — pemeriksa T130 memastikan tidak
  ada pemanggilan helper telanjang yang mengorbankan performa/keamanan; uji-dirinya
  membuktikan 13 pola perusakan semuanya tertangkap.
- Fungsi istimewa: `search_path` terkunci `public, pg_temp` di semua SECURITY DEFINER,
  EXECUTE PUBLIC dicabut efektif (bukan sekadar komentar REVOKE), fungsi trigger tak
  terpanggil sebagai RPC — semuanya diverifikasi dari **katalog efektif** setelah 82 migrasi.

## 5. Evaluasi Logika Finansial & Idempotensi (ART-8)

### 5.1 Presisi rupiah & PB1
- Seluruh kolom uang bertipe `integer`/`bigint` rupiah penuh — **tidak ada satu pun kolom
  `float`/`double precision` di 82 migrasi** (grep bersih). Persentase memakai `numeric(5,2)`.
- Satu-satunya mesin hitung: `public.hitung_total` (versi efektif 0076) — SECURITY DEFINER,
  search_path terkunci, mengunci baris `FOR UPDATE` (anti saling-menimpa), menghitung
  `dasar = subtotal − diskon`, `pajak = round(dasar × PB1/100)`, `service = round(dasar ×
  service/100)`, pembulatan langkah **ke bawah** (keuntungan pelanggan), tip ditambahkan
  terakhir. `round()` PostgreSQL atas `numeric` = half-up — kasus .5 terbukti naik tepat
  (probe P5a: 1.234,5 → **1.235**, tanpa selisih 1 rupiah; juga dijaga
  `supabase/tes/pajak_service.sql` butir 8).
- Tarif PB1 bawaan 10% (`0002:88`, CHECK 0–100) — resto bisa mengatur sendiri; validasi
  RPC pengaturan menolak di luar 0–100 (0072:118).
- Klien **tidak pernah** bisa menulis angka uang: pesanan lahir bertotal 0; UPDATE angka
  uang ditolak trigger kecuali dari `hitung_total` (uji `uang_peladen.sql` LULUS); kembalian
  dihitung peladen (100.000 − 62.100 = 37.900 terbukti).

### 5.2 Idempotensi ART-8 (8 RPC penulisan)
- `periksa-idempoten.py`: **8/8** RPC (`simpan_pesanan`, `bayar_pesanan`, `pakai_voucher`,
  `buka_shift`, `tutup_shift`, `kas_pergerakan`, `set_stok`, `opname_stok`) punya parameter
  kunci idempoten **dan** skema penyimpan kunci (indeks unik parsial, mis.
  `shift_kas_kunci_idempoten_unik`, `stok_pergerakan_kunci_idempoten_unik` di 0080).
- Uji mutasi 0080: menghapus pengecekan idempoten pada 5 RPC → **semuanya tertangkap merah**
  (uji SQL peka, bukan hiasan).
- Probe hidup P3: kirim ganda → balasan `IDEMPOTEN`, 1 baris, uang tidak berlipat.
- Lapis kedua anti-dobel uang: BY-301 di `bayar_pesanan` (`0060:134`) menolak total dibayar
  melebihi total pesanan — jadi kalaupun klien mengirim kunci berbeda untuk pembayaran yang
  sama (lihat K-3-1), **uang dobel tetap mustahil**.
- Konkurensi nyata (2 koneksi, PostgreSQL 16.2): nomor pesanan terserialisasi (advisory lock),
  cap diskon tidak jebol, riwayat status item tepat 1 baris — masing-masing dengan kalibrasi
  mutasi yang membuktikan ujinya peka.

### 5.3 Konkurensi optimistik (0083) & kekekalan audit (0029/0057)
- `uji-mutasi-0083`: 4/4 mutan mati — pengecekan versi usang di `simpan_menu`,
  `simpan_kategori_menu`, `simpan_meja` + jejak audit konflik semuanya terpasang dan teruji.
  Probe P6 membuktikan langsung penolakan versi usang.
- `catatan_audit`: append-only absolut — trigger `cegah_ubah_hapus_audit` (0029) menolak
  UPDATE/DELETE **bahkan oleh pemilik tabel** (probe P2a–b), TRUNCATE ditolak (0057, probe
  P2c), rantai hash + urutan menjaga integritas (0040; `supabase/tes/urutan_rantai_audit.sql` LULUS).

### 5.4 Integritas skema & migrasi
- **82 berkas** migrasi ada di `supabase/migrations/`, bernomor 0001–0085 dengan tiga celah
  (0034, 0044, 0055) — lihat K-4-1. Seluruhnya diterapkan bersih di dua mesin berbeda
  (PGlite dan PostgreSQL 16.2 nyata).
- 16 migrasi beku (0001–0016) cocok byte-per-byte dengan database nyata
  (`periksa-migrasi-beku.py` LOLOS).
- 132 berkas uji SQL — jumlah klaim sesuai kenyataan, semuanya LULUS.

---

## 6. Daftar Temuan

### K-1 (Kritis) — **TIDAK ADA**
Tidak ditemukan kebocoran antar-penyewa, salah hitung uang, atau celah idempotensi.

### K-2 (Tinggi) — **TIDAK ADA**

### K-3 (Sedang) — 1 temuan
**[K-3-1] Kunci idempoten pembayaran dibuat di sisi klien** *(berlanjut dari temuan F-04 audit sebelumnya)*
- **Artefak:** `aplikasi/src/hook/useBayar.ts:178` — `p_kunci_idempoten: kunciIdempoten(pesananId, urutanBayar.current + 1)`
- **Bukti:** grep di SHA audit; peladen menerima kunci apa pun dari parameter.
- **Skenario gagal:** klien yang rusak/dikompromikan dapat mengirim kunci berbeda untuk
  pembayaran yang sama secara logika → percobaan ganda lolos dari deteksi kunci.
- **Peredam yang SUDAH TERBUKTI:** BY-301 (`0060:134`) menolak total dibayar > total pesanan,
  sehingga dampak terburuk = percobaan gagal, **bukan uang dobel** (probe P3 + uji `bayar_pesanan`).
- **Saran perbaikan:** turunkan kunci dari peladen (mis. nomor antrean per pesanan yang
  diterbitkan RPC), atau jadikan `(pesanan_id, jumlah, metode)` unik bersyarat di peladen.

### K-4 (Saran) — 3 temuan
**[K-4-1] Celah penomoran migrasi 0034/0044/0055 & klaim "85 migrasi" tidak sesuai isi folder** *(pengulangan F-01 audit sebelumnya — rekomendasi lama belum dijalankan)*
- **Bukti:** `ls supabase/migrations | wc -l` → **82** berkas; nomor melompat 0033→0035,
  0043→0045, 0054→0056. Dokumen masih menulis "85 migrasi SQL"
  (`docs/teknis/REKAM_PESAN_PEMILIK.md:548`, `PAKET_PEMERIKSAAN_AKBAR_F0_F10.md`, prompt spesialis).
- **Dampak:** tidak fungsional (urutan tetap aman), tapi membingungkan auditor/pengembang baru
  dan membuat angka klaim tidak presisi.
- **Saran:** catat alasan tiga kekosongan itu di `supabase/README.md` (satu paragraf), dan
  selaraskan angka klaim menjadi "82 berkas migrasi (penomoran s/d 0085)".

**[K-4-2] Dependensi alat uji Python tidak tercatat di berkas requirements**
- **Bukti:** `alat/uji-konkuren.py` + `alat/uji-mutasi-0080/0083/0084.py` butuh `pgserver`
  & `psycopg[binary]`; petunjuk pasang hanya muncul sebagai pesan galat saat runtime
  (`GAGAL: pustaka pgserver belum terpasang`). Tidak ada `requirements.txt`/`pyproject` di `alat/`.
- **Dampak:** auditor/CI baru tersandung dua kali (sisi Node sudah rapi lewat `alat/package.json`).
- **Saran:** tambah `alat/requirements-dev.txt` berisi `pgserver` + `psycopg[binary]` dan rujuk di `supabase/README.md`.

**[K-4-3] Tiruan pgcrypto pada mesin uji lokal memakai hash murah (bukan bcrypt produksi)**
- **Bukti:** `alat/uji-konkuren.py:92–97` — komentar sendiri menyatakan "Algoritma SENGAJA
  murah (SHA-256 ber-ulang), BUKAN bcrypt produksi"; hal sama di mock PGlite.
- **Dampak:** tidak ada di produksi (sudah didokumentasikan sebagai mock uji lokal); disebut
  di sini murni agar pembaca laporan tidak salah sangka bahwa kekuatan hash teruji di uji lokal.
- **Saran:** tidak perlu tindakan; pertahankan komentar penjaga itu di kedua mock.

---

## 7. Kesimpulan & Rekomendasi

**Dari kacamata Basis Data & Keuangan, sistem dinyatakan: ✅ SIAP melangkah ke Fase 11
(Uji Lapangan & Pilot Kedai Nyata).**

- Kriteria kelulusan paket untuk dimensi data terpenuhi: **0 temuan K-1, 0 temuan K-2**;
  seluruh mesin uji hijau (132/132 uji SQL; sapuan RLS 47/47; 8/8 RPC idempoten;
  seluruh uji-diri & uji mutasi membuktikan pagar-pagarnya PEKA dan fail-closed).
- Satu K-3 (kunci idempoten sisi klien) sudah punya peredam peladen yang terbukti hidup,
  sehingga tidak menghalangi pilot — layak dijadwalkan sebagai perbaikan kecil Fase 11.
- Tiga K-4 bersifat dokumentasi/kerapian — cukup dikerjakan sebagai tugas sampingan,
  tidak menahan apa pun.

Keputusan akhir kesiapan holistik tetap di tangan Auditor Utama dan Lee.

---

## 8. Penutup

**Posisi Sekarang:** Audit independen hanya-baca Spesialis Data selesai di cabang
`arena/01a0e267-resto-barokah` (SHA `0fc63c7`); semua perintah wajib §3 dijalankan dan
direkam di §2, ditambah 20 bukti probe independen di §3; laporan ini satu-satunya berkas
yang saya tulis (repo selain itu tidak tersentuh).

**Rencana Selanjutnya:** Menyerahkan tongkat ke Auditor Utama (holistik) dan dua spesialis
lain (Frontend, Infrastruktur) untuk melengkapi matriks silang; bila Lee setuju, K-3-1 dan
K-4-1/K-4-2 dijadwalkan sebagai tugas kecil Fase 11.

**Langkah Lee:** Baca ringkasan laporan ini; putuskan apakah (a) lanjut menunggu tiga
laporan spesialis lain sebelum vonis akhir Fase 11, dan (b) K-3-1 + K-4-1/K-4-2 mau
dijadikan tugas maraton sekarang atau dititip ke backlog Fase 11.
