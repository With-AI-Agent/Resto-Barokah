# FORMULIR DAFTAR KUNCI & AKUN PEMILIK — salinan contoh (AMAN, ikut Git)

> **Berkas ini TERISI — tetapi hanya bagian NON-RAHASIA** (alamat layanan, kunci publik `anon`/publishable,
> nama akun). Sengaja ikut Git supaya sesi kerja mana pun tahu alamat & kunci publik mana yang dipakai.
> Nilai **RAHASIA** (service_role, Resend, Cloudflare token, dst.) **TIDAK PERNAH** ditulis di sini — tempatnya
> berkas kerja `DAFTAR_KUNCI_PEMILIK.local.md` yang diabaikan Git (`*.local.md`), bukan chat.
>
> **Cara pakai:**
> 1. Salin berkas formulir `DAFTAR_KUNCI_PEMILIK.template.md` menjadi berkas kerja bernama `DAFTAR_KUNCI_PEMILIK.local.md` di folder `docs/ops/`.
> 2. Isi kolom **"Nilai (isi di sini)"** di **berkas kerja itu** — bukan di chat, bukan di berkas contoh ini.
> 3. Berkas kerja berpola `*.local.md` **diabaikan Git** (lihat `.gitignore`) dan dijaga `alat/periksa-rahasia.py`,
>    jadi nilainya tidak akan ikut ter-commit. Berkas contoh ini sebaliknya **tidak boleh** diisi.
> 4. Aturan tetap: **nilai rahasia tidak pernah lewat chat**. Sebelum rilis sungguhan, semua kunci di-rotate.

Kolom **"Rahasia?"** menentukan perlakuan: **YA** = jangan pernah masuk repo, jangan disebut di chat.
**TIDAK** = aman muncul di aplikasi/peramban (mis. kunci `anon`), tetapi tetap jangan disebar.

## 1. Akun & alamat layanan

| #    | Yang perlu dikumpulkan                        | Di mana mendapatkannya                                     | Rahasia? | Sudah | Nilai (isi di sini)                                                                               |
| ---- | --------------------------------------------- | ---------------------------------------------------------- | -------- | ----- | ------------------------------------------------------------------------------------------------- |
| A-01 | Alamat proyek Supabase (URL)                  | Panel Supabase → Project Settings → Data API → Project URL | TIDAK    |       | https://bdvjirmbuqelmduztryj.supabase.co                                                          |
| A-02 | Kunci publik Supabase (`anon` / publishable)  | Panel Supabase → Project Settings → API Keys               | TIDAK    | Ya    | sb_publishable_b1TMUnIFZAJjmA59X8_WFA_z7SyMXwM                                                    |
| A-03 | Nama proyek & region Supabase                 | Panel Supabase → Project Settings → General                | TIDAK    |       | Project name: Resto-Barokah<br>Project region: ap-southeast-1<br>Project ID: bdvjirmbuqelmduztryj |
| A-04 | Akun Cloudflare (email yang dipakai)          | cloudflare.com → My Profile                                | TIDAK    |       | fatrizmubarok@gmail.com                                                                           |
| A-05 | Nama akun Cloudflare (Account ID)             | Cloudflare → Workers & Pages → Account ID                  | TIDAK    |       | 2b55bd03207235e421de6ec18837b654                                                                  |
| A-06 | Akun email pengirim (Google) untuk notifikasi | console.cloud.google.com                                   | TIDAK    |       | fatrizmubarok@gmail.com                                                                           |

