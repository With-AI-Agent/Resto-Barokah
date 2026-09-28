# FORMULIR DAFTAR KUNCI & AKUN PEMILIK — salinan contoh (AMAN, ikut Git)

> **Ini berkas CONTOH/formulir — bukan tempat mengisi.** Ikut Git, jadi isinya harus tetap kosong.
>
> **Cara pakai:**
> 1. Salin berkas ini menjadi berkas kerja bernama `DAFTAR_KUNCI_PEMILIK.local.md` di folder `docs/ops/`.
> 2. Isi kolom **"Nilai (isi di sini)"** di **berkas kerja itu** — bukan di chat, bukan di berkas contoh ini.
> 3. Berkas kerja berpola `*.local.md` **diabaikan Git** (lihat `.gitignore`) dan dijaga `alat/periksa-rahasia.py`,
>    jadi nilainya tidak akan ikut ter-commit. Berkas contoh ini sebaliknya **tidak boleh** diisi.
> 4. Aturan tetap: **nilai rahasia tidak pernah lewat chat**. Sebelum rilis sungguhan, semua kunci di-rotate.

Kolom **"Rahasia?"** menentukan perlakuan: **YA** = jangan pernah masuk repo, jangan disebut di chat.
**TIDAK** = aman muncul di aplikasi/peramban (mis. kunci `anon`), tetapi tetap jangan disebar.

## 1. Akun & alamat layanan

| # | Yang perlu dikumpulkan | Di mana mendapatkannya | Rahasia? | Sudah | Nilai (isi di sini) |
|---|---|---|---|---|---|
| A-01 | Alamat proyek Supabase (URL) | Panel Supabase → Project Settings → Data API → Project URL | TIDAK |  |  |
| A-02 | Kunci publik Supabase (`anon` / publishable) | Panel Supabase → Project Settings → API Keys | TIDAK |  |  |
| A-03 | Nama proyek & region Supabase | Panel Supabase → Project Settings → General | TIDAK |  |  |
| A-04 | Akun Cloudflare (email yang dipakai) | cloudflare.com → My Profile | TIDAK |  |  |
| A-05 | Nama akun Cloudflare (Account ID) | Cloudflare → Workers & Pages → Account ID | TIDAK |  |  |
| A-06 | Akun email pengirim (Google) untuk notifikasi | console.cloud.google.com | TIDAK |  |  |
| A-07 | Kunci API Resend (email harian) | resend.com → API Keys | **YA** |  |  |

## 2. Kunci rahasia (JANGAN pernah masuk repo / chat)

| # | Yang perlu dikumpulkan | Di mana mendapatkannya | Rahasia? | Sudah | Nilai (isi di sini) |
|---|---|---|---|---|---|
| R-01 | Kunci `service_role` Supabase | Panel Supabase → Project Settings → API Keys | **YA** |  |  |
| R-02 | Kata sandi database Supabase | Panel Supabase → Project Settings → Database → Reset password | **YA** |  |  |
| R-03 | Kunci rahasia GitHub Actions (kalau dipakai) | GitHub → Settings → Secrets and variables → Actions | **YA** |  |  |
| R-04 | Kode/rahasia Cloudflare API token (untuk penyebaran) | Cloudflare → My Profile → API Tokens | **YA** |  |  |
| R-05 | Rahasia OAuth Google (client secret) | console.cloud.google.com → Credentials | **YA** |  |  |
| R-06 | Kata sandi akun email pengirim | Google → keamanan akun | **YA** |  |  |

## 3. Hal lain yang harus Lee siapkan (bukan kunci)

| # | Yang perlu disiapkan | Kenapa | Sudah | Catatan |
|---|---|---|---|---|
| S-01 | Nomor HP pemilik platform & langkah pemulihan (latihan sekali) | Jalan pemulihan kalau perangkat hilang (T1-36) |  |  |
| S-02 | Kode pemulihan dicetak & disimpan (2 amplop tersegel) | Pemulihan akun tanpa bergantung pada orang |  |  |
| S-03 | Nama & email admin cabang + daftar pegawai Kedai Oasis | Penyiapan akun pegawai (T2-03) |  |  |
| S-04 | Merek & tipe printer kedai + cara menyambungnya | Fase cetak (T-002) |  |  |
| S-05 | Daftar perangkat yang dipakai (Android/iPhone/komputer) | Uji perangkat (T-003) |  |  |
| S-06 | Tablet/HP Android yang akan dipakai mode terkunci | Penyiapan perangkat (T-015) |  |  |

## 4. Log berkas ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Berkas contoh dibuat | Keperluan Lee: formulir tetap ada di Git, sedangkan berkas terisi tidak ikut Git |
