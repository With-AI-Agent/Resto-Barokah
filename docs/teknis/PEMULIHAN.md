# Panduan Operasional Pemulihan Bencana Basis Data (SOP)
## Resto Barokah — Ketahanan & Keamanan Lanjutan (T10-10 / TECH_SPEC §8 & §10)

Dokumen ini adalah Prosedur Operasi Standar (SOP) resmi pemulihan bencana (*Disaster Recovery*) untuk basis data Resto Barokah jika terjadi kehilangan data total, server Supabase rusak permanen, atau serangan siber.

---

## 1. Parameter Utama Pemulihan (RTO & RPO)

| Parameter | Target Kebijakan | Penjelasan |
| :--- | :--- | :--- |
| **RPO (*Recovery Point Objective*)** | **< 24 Jam** (Harian Denyut) / **7 Hari** (Mingguan Penuh) | Batas maksimal rentang data yang hilang bila terjadi bencana fatal. Ditopang denyut harian (`T10-08`) dan cadangan mingguan otomatis (`T10-10`). |
| **RTO (*Recovery Time Objective*)** | **< 30 Menit** | Waktu maksimal dari bencana diumumkan hingga sistem kasir dan dapur kembali aktif menerima transaksi. |
| **Enkripsi Cadangan** | **AES-256-CBC (PBKDF2)** | Enkripsi simetris standar militer dengan 100.000 iterasi hashing kunci (`-pbkdf2 -iter 100000`). |
| **Integritas Berkas** | **SHA-256 Checksum** | Setiap berkas cadangan terenkripsi wajib memiliki berkas `.sha256` pendamping sebelum proses dekripsi. |

---

## 2. Lokasi Artefak Cadangan

1. **Penyimpanan Utama CI/CD (GitHub Actions Artifacts):**
   - Jalur: Tab **Actions** → Alur kerja **"Cadangan Mingguan & Uji Pemulihan Bencana"** → Bagian **Artifacts**.
   - Berkas: `cadangan-resto-barokah-YYYYMMDD_HHMMSS.sql.gz.enc`.
   - Masa Retensi: 90 hari.
2. **Kunci Rahasia Dekripsi:**
   - Nama Rahasia: `KUNCI_ENKRIPSI_CADANGAN`.
   - Disimpan di: GitHub Repository Secrets (`Settings` → `Secrets and variables` → `Actions`).
   - Panjang Kunci: Minimal 16 karakter.
   - Hak Akses: Hanya Pemilik Platform (Lee) dan DevOps berwenang.

---

## 3. Prosedur Pemulihan Langkah Demi Langkah (7 Tahap)

> **PRINSIP:** Jangan panik. Jalankan langkah sesuai urutan nomor tanpa melompati tahap verifikasi.

### Tahap 1: Unduh Berkas Cadangan Terakhir
1. Buka repositori GitHub Resto Barokah.
2. Masuk ke tab **Actions** → pilih alur **Cadangan Mingguan & Uji Pemulihan Bencana**.
3. Pilih eksekusi alur terakhir yang berstatus hijau (sukses).
4. Unduh arsip artefak `cadangan-resto-barokah.zip` ke komputer pemulihan.
5. Ekstrak arsip zip tersebut hingga menghasilkan dua berkas:
   - `cadangan-resto-barokah-*.sql.gz.enc` (data terenkripsi).
   - `cadangan-resto-barokah-*.sql.gz.enc.sha256` (checksum).

### Tahap 2: Verifikasi Integritas Berkas Terenkripsi (Anti-Tamper)
Sebelum membuka enkripsi, buktikan berkas tidak rusak atau diubah di perjalanan:
```bash
sha256sum -c cadangan-resto-barokah-*.sql.gz.enc.sha256
```
**Syarat Lolos:** Harus mencetak output `OK`. Jika tidak cocok, **JANGAN LANJUTKAN** — berkas rusak, unduh cadangan dari minggu sebelumnya.

### Tahap 3: Dekripsi Berkas Cadangan (AES-256-CBC)
Setel kunci rahasia ke variabel lingkungan:
```bash
export KUNCI_ENKRIPSI_CADANGAN="<kunci-rahasia-dari-github-secret>"
```
Jalankan dekripsi menggunakan skrip resmi:
```bash
bash alat/cadangan.sh dekripsi cadangan-resto-barokah-*.sql.gz.enc cadangan_bersih.sql.gz
```
*Atau menggunakan perintah OpenSSL langsung:*
```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 \
  -in cadangan-resto-barokah-*.sql.gz.enc \
  -out cadangan_bersih.sql.gz \
  -pass "pass:$KUNCI_ENKRIPSI_CADANGAN"
```
Verifikasi integritas dekompresi gzip:
```bash
gzip -t cadangan_bersih.sql.gz
```

### Tahap 4: Dekompresi Berkas SQL
Ekstrak berkas SQL plaintext ke direktori aman:
```bash
gunzip -k cadangan_bersih.sql.gz
# Menghasilkan berkas: cadangan_bersih.sql
```

### Tahap 5: Persiapan Basis Data Target (Clean Slate)
1. Jika memulihkan ke instans Supabase baru:
   - Buat proyek baru di dashboard Supabase.
   - Dapatkan `SUPABASE_DB_URL` (format: `postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres`).
2. Pastikan basis data target dalam kondisi bersih (*clean slate*).

### Tahap 6: Eksekusi Pemulihan
Jalankan pemulihan skema dan data menggunakan skrip pemulihan:
```bash
# Melalui skrip bantu Resto Barokah:
bash alat/cadangan.sh pulihkan cadangan_bersih.sql

# ATAU langsung ke instans PostgreSQL/Supabase target:
psql "$TARGET_DB_URL" -f cadangan_bersih.sql
```

### Tahap 7: Verifikasi Paritas Data & Validasi Keamanan RLS
Jalankan verifikasi otomatis untuk memastikan seluruh data pulih sempurna:
```bash
node alat/eksekusi-cadangan.mjs --uji-pemulihan
# Atau melalui skrip eksekutif latihan bencana & buku insiden:
bash alat/pulihkan-cadangan.sh
```
Kriteria keberhasilan pemulihan (*Definition of Done*):
- [x] Seluruh 47 tabel publik terisi data tanpa tabel yang terlewat.
- [x] Seluruh 47 tabel publik memiliki status **RLS aktif** (*Row-Level Security* mengunci akses publik).
- [x] Kunci asing (*foreign key*) antar-tabel konsisten (`integritasRelasi = true`).
- [x] Data penyewa, cabang, menu, pegawai, dan riwayat audit utuh.

### Pembersihan Pasca-Pemulihan:
Demi kepatuhan privasi data pelanggan (TECH_SPEC §9 ART-10):
```bash
# Hapus berkas plaintext dari komputer pemulihan setelah database aktif
rm -f cadangan_bersih.sql cadangan_bersih.sql.gz
unset KUNCI_ENKRIPSI_CADANGAN
```

---

## 4. Penanganan Masalah (*Troubleshooting*)

| Gejala | Penyebab Umum | Solusi Tindakan |
| :--- | :--- | :--- |
| **`bad decrypt` / galat OpenSSL** | Kunci rahasia salah ketik atau berbeda dari kunci pembuat cadangan. | Periksa `KUNCI_ENKRIPSI_CADANGAN` di GitHub Secrets. Pastikan tidak ada spasi di awal/akhir kunci. |
| **`not in gzip format` saat dekompresi** | Berkas terpotong saat pengunduhan atau kunci salah sehingga output dekripsi acak. | Periksa checksum SHA-256 berkas `.enc` terlebih dahulu (Tahap 2). |
| **`role service_role does not exist`** | Target PostgreSQL polos di luar Supabase belum memiliki peran bawaan. | Berkas dump otomatis menyertakan definisi DDL pembuatan peran tiruan bila belum ada. |
| **`foreign key constraint violation`** | Urutan pemulihan data tidak menghormati pohon relasi dependensi. | Skrip `alat/eksekusi-cadangan.mjs` telah mengurutkan 47 tabel sesuai topologi dependensi foreign key. |

---

## 5. Simulasi Bencana Berkala

Sistem Resto Barokah menjalankan simulasi otomatis uji pemulihan setiap minggu melalui GitHub Actions. Uji mandiri juga dapat dijalankan secara lokal kapan saja dengan satu perintah:
```bash
bash alat/cadangan.sh uji-pemulihan
```
Perintah ini membuktikan siklus lengkap:
`Database Hidup` → `Dump SQL` → `Kompres Gzip` → `Enkripsi AES-256` → `Dekripsi` → `Ekstrak` → `Pulihkan ke Database Bersih` → `Verifikasi Paritas 47 Tabel & RLS 100%`.

---

## 6. Laporan Resmi Latihan Pemulihan Bencana & Uji Buku Insiden (T10-15)

Latihan pemulihan bencana menyeluruh dan simulasi Buku Insiden dijalankan secara deterministik menggunakan skrip `alat/pulihkan-cadangan.sh`:

- **Tanggal Pelaksanaan:** 2026-09-27
- **Waktu Eksekusi Pemulihan:** ~4,3 detik (jauh di bawah batas target RTO 30 menit).
- **Basis Data Target:** Bersih (*clean slate*) PostgreSQL/PGlite tanpa data awal.
- **Jumlah Tabel Terpulihkan:** 47 dari 47 tabel publik (100% paritas lengkap).
- **Jumlah Baris Terpulihkan:** 192 baris sumber cocok 100% dengan target (selisih = 0 baris).
- **Status Keamanan RLS:** 100% aktif (seluruh 47 tabel publik terverifikasi memiliki `relrowsecurity = true`).
- **Dril Insiden §2 (Perangkat Hilang):**
  - Perangkat kasir berhasil ditandai `status = 'hilang'` dan dinonaktifkan (`aktif = false`).
  - Sesi aktif perangkat seketika dicabut (`status = 'dicabut'`).
  - PIN kasir berhasil direset ke PIN baru yang kuat.
  - Jejak audit `tandai_perangkat_hilang` dan `reset_pin_pegawai` tercatat permanen di `public.catatan_audit`.
- **Dril Insiden §4 (Akun Diduga Bocor):**
  - Akun pegawai seketika dinonaktifkan (`aktif = false`) via `public.set_status_pengguna`.
  - Seluruh sesi perangkat aktif dicabut via `public.keluar_semua_perangkat`.
  - Kredensial PIN diganti via `public.reset_pin_pegawai`.
  - Jejak audit tercatat lengkap di `public.catatan_audit`.
- **Dril Insiden §5 (Pegawai Berhenti / Offboarding Cepat T10-12):**
  - Akun dinonaktifkan, PIN dihapus, shift terbuka ditandai `perlu_tutup_atasan = true`.
  - Riwayat transaksi masa lalu dan laporan penjualan tetap utuh (Aturan Bisnis 11).
- **Dril Insiden §15 (Rekonsiliasi Harian & Privasi UU PDP):**
  - RPC `public.hasilkan_ringkasan_harian` berhasil mendeteksi pergantian perangkat dan memvalidasi keutuhan rantai audit kriptografis (0 putus).
  - Privasi data pelanggan terlindungi penuh tanpa nomor kontak/data pribadi (ART-14).
- **Uji-Diri Fail-Closed:**
  - 5 mutasi kegagalan (selisih baris sumber, kehilangan baris target, RLS mati, gagal cabut perangkat, gagal nonaktifkan akun) terbukti 100% tertolak merah (`bash alat/pulihkan-cadangan.sh --uji-diri`).
- **Kesimpulan:** SOP Pemulihan Bencana dan Buku Insiden terbukti siap operasional (*production-ready*).
