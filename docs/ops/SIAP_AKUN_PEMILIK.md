# SIAP AKUN — Panduan Pemilik (±30 menit, gratis, tanpa coding)

Tujuan: menyiapkan **dua akun gratis** supaya agent bisa menyambungkan aplikasi. Kamu tidak perlu paham istilah teknis — cukup ikuti langkah bernomor. Kalau bingung di langkah mana pun: **berhenti dan tanya agent**, jangan menebak.

**Yang perlu disiapkan dulu:** satu alamat email yang kamu kuasai (boleh Gmail) dan HP untuk menerima kode verifikasi.

---

## Bagian 1 — Akun Supabase (tempat data kedai disimpan)

1. Buka `supabase.com`, tekan **Start your project**.
2. Daftar memakai email tadi (boleh juga masuk dengan Google).
3. Buka email, tekan tautan verifikasi.
4. Tekan **New project**, isi:
   - Nama: misalnya `kedai-oasis`
   - Database password: tekan **Generate a password**, lalu **SIMPAN** di catatan aman (jangan ditempel ke chat).
   - Region: pilih **Southeast Asia (Singapore)** — paling dekat, paling cepat.
   - Plan: pilih **Free** (jangan masukkan kartu kredit).
5. Tunggu 1–2 menit sampai proyek siap (tanda hijau).
6. Buka **Settings → API**. Salin **dua nilai** ini dan kirimkan ke agent:
   - **Project URL** (bentuknya `https://xxxx.supabase.co`)
   - **anon public** key (kunci panjang pada baris `anon`)
   ⚠️ **Jangan kirim** kunci `service_role` ke chat. Kalau agent perlu, ia akan memandumu menaruhnya langsung di tempat rahasia.
7. Kalau nanti proyek tertulis **Paused** (tertidur karena lama tidak dipakai), tekan **Restore** — data tetap ada.

## Bagian 2 — Akun Cloudflare (tempat aplikasi online)

1. Buka `dash.cloudflare.com`, tekan **Sign up**, daftar dengan email yang sama, lalu verifikasi lewat email.
2. Buka **Workers & Pages → Create → Workers**, ikuti sampai halaman contoh muncul (nama boleh `sajian`).
3. Beri tahu agent: **"akun Cloudflare sudah jadi"**. Agent yang akan memasang koneksinya (kamu tidak perlu mengetik perintah).

## Setelah selesai

Katakan ke agent: **"akun Supabase & Cloudflare sudah siap"**, lalu berikan **Project URL** dan **anon key** saja. Agent mencatatnya di berkas rahasia lokal (tidak masuk Git), menyambungkan aplikasi ke Supabase, lalu memasang aplikasi supaya bisa dibuka publik.

**Posisi sekarang (2026-09-16):** persiapan aplikasi (T0-01 sampai T0-07, termasuk T0-10) **sudah selesai** — repo, aturan kode, tema, komponen, berkas rahasia, README, dan CI hijau. Sisa Fase 0 hanya **T0-08** (menyambung Supabase) dan **T0-09** (memasang aplikasi ke alamat publik), dan keduanya **baru bisa dikerjakan setelah dua akun di atas jadi**. Jadi panduan ini adalah langkah berikutnya yang ditunggu.

## Kalau macet

- Email verifikasi tidak datang → periksa folder spam atau kirim ulang.
- Salah hapus proyek Supabase → tidak masalah, buat proyek baru; belum ada data kedai.
- Ragu di langkah mana pun → berhenti dan tanya agent. Jangan pernah menempelkan password database atau kunci `service_role` ke chat.
