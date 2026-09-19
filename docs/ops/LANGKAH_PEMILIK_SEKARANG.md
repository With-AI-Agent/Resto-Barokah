# LANGKAH PEMILIK SEKARANG — 3 rahasia di GitHub (±5 menit)

> Ditulis 2026-09-19 untuk Lee. Bahasa awam, **tanpa perintah yang perlu kamu ketik**.
> Kalau ragu di langkah mana pun: **berhenti dan tanya agent** — jangan menebak.

## Kenapa ini perlu

Aku tidak boleh — dan tidak mau — melihat kunci rahasiamu. GitHub punya **kotak rahasia terenkripsi**
untuk itu: kunci yang kamu simpan di sana bisa **dipakai** mesin (untuk menyebar tabel database dan
menaikkan halaman ke internet) **tanpa pernah terlihat** oleh siapa pun, termasuk aku.

Sampai kotak itu terisi, dua pekerjaan terakhir Fase 0 tidak bisa dijalankan mesin (karena itu
statusnya masih "menunggu", bukan "selesai").

## Sudah beres — bagian ini tidak perlu kamu apa-apakan

- Akun **Supabase + Resend + Cloudflare** sudah dibuat → tugas `T0-00` & catatan tunggu `T-018` ditutup.
- **Sambungan aplikasi ke proyek Supabase-mu sudah terbukti** (uji otomatis hijau di GitHub — lihat tab
  **Actions**, langkah "Cek sambungan Supabase").
- **Jalur sebar tabel** dan **jalur naikkan halaman** sudah siap dan diawasi penjaga otomatis;
  keduanya hanya butuh kunci di bawah.

---

## Langkah A — 2 rahasia Supabase (untuk menyebar 14 berkas tabel)

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

## Langkah B — 1 rahasia Cloudflare (untuk menaikkan halaman ke internet)

1. Buka **https://dash.cloudflare.com/profile/api-tokens** → **Create Token** →
   pilih templat **Edit Cloudflare Workers** → **Continue to summary** → **Create Token** → **Copy**.
2. GitHub → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
   - **Name:** `CLOUDFLARE_API_TOKEN`
   - **Secret:** tempel token tadi
   - tekan **Add secret**.

> Belum ingin halaman tampil di internet? **Tidak apa-apa** — cukup Langkah A yang dikerjakan.
> Halaman publik menunggu sampai kamu memang mau.

## Langkah C — bilang ke aku

Tulis **satu kalimat** di chat:

> **Rahasia sudah dipasang.**

Setelah itu aku yang menjalankan sisanya, dan kamu akan menerima laporan:

1. **Sebar tabel** — mesin menjalankan **pratinjau lebih dulu** (apa yang akan berubah), baru menyebar;
   lalu aku laporkan bukti "tabel sudah ada" (`select 1` yang selama ini belum bisa dijalankan).
2. **Naikkan halaman** (kalau Langkah B dikerjakan) — aku laporkan **alamat publiknya** + hasil
   pemeriksaan HTTPS.

## Aturan penting (demi keamanan uang & data)

- **Jangan pernah** menempel token/kata sandi di chat, di dokumen, atau di commit. Kotak rahasia GitHub
  adalah tempat yang benar.
- Kalau **terlanjur** tertempel di chat atau terlihat orang lain: buka situsnya → **hapus token itu** →
  buat token baru → ganti di GitHub. (Alasannya: token yang sudah terlihat harus dianggap bocor.)
- Kalau kamu merasa ragu, cukup bilang *"Tolong pandu aku langkah demi langkah"* — agent akan menemani
  satu langkah sekali.
