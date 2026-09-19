# LANGKAH PEMILIK SEKARANG — 3 rahasia di GitHub (±5 menit)

> Ditulis 2026-09-19 untuk Lee. Bahasa awam, **tanpa perintah yang perlu kamu ketik**.
> Kalau ragu di langkah mana pun: **berhenti dan tanya agent** — jangan menebak.

## Kenapa ini perlu

Aku tidak boleh — dan tidak mau — melihat kunci rahasiamu. GitHub punya **kotak rahasia terenkripsi**
untuk itu: kunci yang kamu simpan di sana bisa **dipakai** mesin (untuk menyebar tabel database dan
menaikkan halaman ke internet) **tanpa pernah terlihat** oleh siapa pun, termasuk aku.

## Kabar terbaru (2026-09-19) — Langkah A SUDAH SELESAI

- **Langkah A (2 rahasia Supabase) SUDAH SELESAI & terbukti**: 14 berkas tabel sudah disebar ke proyek
  Supabase-mu; pemeriksaan otomatis berhasil **membaca tabel katalog** dari proyek nyata. Tidak perlu diulang.
- **Langkah B (1 rahasia Cloudflare) SUDAH SELESAI & terbukti**: setelah kamu menulis "Boleh naik", halaman
  sudah naik ke internet di **<https://resto-barokah.fatrizmubarok.workers.dev>** dan pemeriksaan otomatis menjawab **HTTP 200**.
- **Fase 0 tuntas.** Tidak ada lagi langkah yang menunggu kamu di daftar ini.

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
