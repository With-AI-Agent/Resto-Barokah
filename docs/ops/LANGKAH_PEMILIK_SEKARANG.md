# LANGKAH PEMILIK SEKARANG — 3 rahasia di GitHub (±5 menit)

> Ditulis 2026-09-19 untuk Lee. Bahasa awam, **tanpa perintah yang perlu kamu ketik**.
> Kalau ragu di langkah mana pun: **berhenti dan tanya agent** — jangan menebak.

## ⚠️ LANGKAH PALING PENTING SEKARANG (2026-09-20) — GitHub berhenti menjalankan pemeriksaan otomatis

**Apa yang terjadi:** semua pemeriksaan otomatis (CI) di repo ini **tidak bisa mulai** sejak sekitar
pukul 12:00 (WIB) hari ini. Pesan dari GitHub apa adanya:

> *"The job was not started because recent account payments have failed or your spending limit needs to be increased.
> Please check the 'Billing & plans' section in your settings."*

Artinya: **tagihan/pembayaran akun GitHub-mu bermasalah, atau batas belanja (spending limit) untuk
GitHub Actions sudah tersentuh** — jadi runner tidak dijalankan sama sekali. Ini **BUKAN** cacat kode:
semua pemeriksaan yang sama sudah kujalankan ulang di komputer (klon bersih) dan **semuanya LOLOS**.

**Kenapa penting bagimu:** selama ini belum diperbaiki, (a) robot pemeriksa tidak jalan, sehingga
pekerjaan baru tidak punya cap "hijau" dari GitHub; (b) alur **"Sebar skema"** (menyebar tabel ke database
nyata) juga TIDAK akan jalan — jadi langkah pemilik yang sudah kusiapkan itu pun akan buntu.

**Yang kamu lakukan (urut):**
1. Buka <https://github.com/settings/billing> (masuk sebagai **fatrizmubarok**, pemilik repo).
2. Periksa bagian **Billing & plans** → kalau ada pembayaran gagal: perbaiki metode pembayarannya.
3. Kalau tidak ada masalah pembayaran: periksa **budget / spending limit** untuk GitHub Actions —
   naikkan sedikit (atau pastikan kuota gratis bulan ini belum habis).
4. Setelah beres, bilang saja ke aku: **"GitHub sudah beres"** — aku langsung memicu pemeriksaan lagi dan
   memastikan hijaunya.

> Catatan jujur: repo ini privat, jadi menit GitHub Actions memakai kuota akunmu. Kalau kamu ingin **tanpa biaya**,
> cukup pastikan kuota gratis bulanan tidak habis (Actions gratis ~2.000 menit/bulan untuk repo privat).

## Kenapa ini perlu

Aku tidak boleh — dan tidak mau — melihat kunci rahasiamu. Kunci itu disimpan di **kotak rahasia GitHub**
(*repository secrets*) dan hanya **dipakai** mesin saat menjalankan alur otomatis (menyebar tabel database,
menaikkan halaman ke internet).

**Jujur soal batasnya (koreksi 2026-09-20, audit I F-11):** "terenkripsi" BUKAN berarti "tidak mungkin
terbaca". GitHub menyimpan secrets agar tidak tampil di layar dan menyamarkan nilainya di log, tetapi
**siapa pun yang boleh mengubah alur kerja (workflow) di repo ini secara teknis bisa membuat alur yang
membaca secrets itu** (mis. mengirimnya ke tempat lain), dan penyamaran log tidak dijamin untuk semua
bentuk keluaran. Karena itu:

- beri **hanya** repo ini (jangan pakai token pribadi yang dipakai di tempat lain);
- pakai token dengan **izin sesempit mungkin** dan **masa berlaku** (TTL) yang wajar, bukan selamanya;
- jangan menambah penulis/kontributor yang tidak kamu percaya ke repo ini — merekalah yang bisa mengubah alur;
- kalau nanti ada fitur *environment protection* di GitHub (butuh review sebelum rahasia dipakai), itu
  menambah lapisan; tidak wajib sekarang.

Yang **tidak** aku lakukan: mengambil, menyalin, atau menampilkan nilai rahasianya. Aku juga tidak pernah
memintamu menempelkan nilainya di chat.

## Kabar terbaru (2026-09-19) — Langkah A SUDAH SELESAI

- **Langkah A (2 rahasia Supabase) SUDAH SELESAI & terbukti**: 14 berkas tabel sudah disebar ke proyek
  Supabase-mu; pemeriksaan otomatis berhasil **membaca tabel katalog** dari proyek nyata. Tidak perlu diulang.
- **Langkah B (1 rahasia Cloudflare) SUDAH SELESAI & terbukti**: setelah kamu menulis "Boleh naik", halaman
  sudah naik ke internet di **<https://resto-barokah.fatrizmubarok.workers.dev>** dan pemeriksaan otomatis menjawab **HTTP 200**.
- **Fase 0 tuntas** (akun, kunci, halaman, sebar tabel pertama) — **tetapi sekarang ada SATU langkah baru yang menunggu kamu**
  (dikoreksi 2026-09-20 setelah temuan audit H F-03, karena kalimat lama menjanjikan terlalu banyak):
  **menyebar berkas tabel yang lebih baru ke database nyata**. Saat Langkah A selesai, yang tersebar baru
  **0001–0014**; semua perbaikan sesudahnya (penutup celah putaran ke-16) masih **hanya ada di GitHub**,
  belum masuk database nyata. Hanya kamu yang bisa memicunya (rahasia ada di tanganmu).

  **Kapan?** Tunggu aku bilang **"batch selesai, silakan sebar"** — jangan sekarang. Alasannya: berkas `0015`
  masih terus ditambah selama maraton perbaikan temuan, dan berkas migrasi yang sudah masuk database tidak
  boleh diubah lagi. Begitu batch selesai, aku akan bilang, lalu kamu jalankan alur sebar skema dari GitHub
  (Actions → **Sebar skema** → Run workflow). Kalau ragu, tanya dulu — jangan menekan tombol ini sendiri.

## Langkah A — 2 rahasia Supabase ✅ SUDAH SELESAI (tidak perlu diulang)

1. Buka **https://supabase.com/dashboard/account/tokens** → tekan **Generate new token** →
   nama: `github-resto-barokah` → **Generate token** → tekan **Copy** (token mulai dengan `sbp_`).
2. Buka repo di GitHub → tab **Settings** → menu kiri **Secrets and variables** → **Actions** →
   tekan **New repository secret**:
   - **Name:** `SUPABASE_ACCESS_TOKEN`
   - **Secret:** tempel token tadi
   - tekan **Add secret**.
3. Ambil **kata sandi database**: Supabase → **Project Settings** → **Database** → bagian
   *Database password* (kalau lupa, tekan **Reset database password** lalu simpan yang baru).
4. Di halaman GitHub yang sama (masih **Actions** secrets) → **New repository secret**:
   - **Name:** `SUPABASE_DB_PASSWORD`
   - **Secret:** kata sandi tadi
   - tekan **Add secret**.

## Langkah B — 1 rahasia Cloudflare (untuk menaikkan halaman ke internet) ✅ SUDAH SELESAI 2026-09-19

1. Buka **https://dash.cloudflare.com/profile/api-tokens**.
2. Tekan tombol **Create Token** (biru, di halaman daftar token) — **jangan** menekan
   **Create Custom Token**; jalan itu lebih rumit dan mudah salah.
3. Di bagian **Token templates**, cari baris bernama **Edit Cloudflare Workers** → tekan
   **Use template**.
4. Di halaman ringkasan, **biarkan apa adanya** (Account Resources: *Include → All accounts*) →
   tekan **Continue to summary** → **Create Token** → tekan **Copy**.

   *Kalau kamu sudah terlanjur membuka **Create Custom Token*** dan ingin melanjutkan di situ:
   pada baris **Permissions** pilih **Account** → **Workers Scripts** → **Edit**
   (tekan **+ Add more** kalau barisnya belum ada), biarkan **Client IP Address Filtering** dan
   **TTL** kosong, lalu **Continue to summary** → **Create Token** → **Copy**.

5. GitHub → repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
   - **Name:** `CLOUDFLARE_API_TOKEN`
   - **Secret:** tempel token tadi
   - tekan **Add secret**.

> Belum ingin halaman tampil di internet? **Tidak apa-apa** — Langkah A sudah selesai dan tabel sudah
> disebar. Halaman publik menunggu sampai kamu memang mau; cukup bilang **"Boleh naik"** kalau sudah siap.

## Langkah C — bilang ke aku

Tulis **satu kalimat** di chat:

> **Rahasia sudah dipasang.**

Setelah itu aku yang menjalankan sisanya, dan kamu akan menerima laporan:

1. ~~Sebar tabel~~ — **SUDAH SELESAI 2026-09-19**: 14 berkas tabel sudah ada di proyek Supabase-mu,
   dan pemeriksaan otomatis sudah membuktikannya (membaca tabel katalog dengan kunci publik).
2. ~~Naikkan halaman~~ — **SUDAH SELESAI 2026-09-19**: alamat publiknya <https://resto-barokah.fatrizmubarok.workers.dev> (HTTP 200),
   catatan lengkap di `docs/ops/ALAMAT_PUBLIK.md` (termasuk cara memperbarui & cara mematikannya).

## Aturan penting (demi keamanan uang & data)

- **Jangan pernah** menempel token/kata sandi di chat, di dokumen, atau di commit. Kotak rahasia GitHub
  adalah tempat yang benar.
- Kalau **terlanjur** tertempel di chat atau terlihat orang lain: buka situsnya → **hapus token itu** →
  buat token baru → ganti di GitHub. (Alasannya: token yang sudah terlihat harus dianggap bocor.)
- Kalau kamu merasa ragu, cukup bilang *"Tolong pandu aku langkah demi langkah"* — agent akan menemani
  satu langkah sekali.
