# Tinjauan Keamanan Lanjutan: Kode Pemulihan MFA & Pemeriksa Kata Sandi Bocor (T-016)

> **Dokumen Resmi Penutup Tugas ROADMAP T10-16 (Fase 10 — Ketahanan & Keamanan Lanjutan)**  
> **Tanggal Tinjauan:** 27 September 2026  
> **Status:** SELESAI TERTINJAU & DISETUJUI  
> **Referensi Pengikat:**  
> - `docs/TERTANGGUH.md` (Butir T-016)  
> - `docs/KEAMANAN.md` §4b, §7, dan §15  
> - `docs/TECH_SPEC.md` §8 dan §15  
> - `docs/teknis/BUKU_INSIDEN.md` Bab 2, Bab 4, dan Bab 5  
> - Keputusan Pemilik Lee tanggal 2026-09-21 (§26 & §29 `docs/teknis/REKAM_PESAN_PEMILIK.md`)

---

## 1. Konteks & Latar Belakang (T-016)

Pada audit dan peninjauan arsitektur 2026-09-21, Lee memutuskan untuk menangguhkan dua fitur keamanan eksternal melalui butir **T-016**:
1. *Self-Service MFA Recovery Codes* (Kode Pemulihan MFA Mandiri untuk staf/admin).
2. *Pwned Passwords Check* via HaveIBeenPwned (HIBP).

**Keputusan sementara Lee (2026-09-21):**
> *"T-016: Sementara pemulihan melalui peran atas + kata sandi minimal 12 karakter + TOTP wajib. Tinjauan HIBP dan kode mandiri dilakukan di Fase 10 (T10-16); biaya atau perubahan kontrol butuh keputusan Lee."*

Tinjauan ini disusun secara komprehensif, berbasis data nyata, tanpa jargon membingungkan, dan berorientasi pada **biaya operasional nol (Rp 0)** agar sesuai dengan prinsip kemandirian UMKM Resto Barokah / Kedai Oasis.

---

## 2. Bagian I: Tinjauan Kode Pemulihan MFA Mandiri (*Self-Service Recovery Codes*)

### 2.1. Definisi & Mekanisme Umum
Kode pemulihan mandiri umumnya berupa rangkaian 8–10 kode alfanumerik acak (misalnya `ABCD-1234-EFGH`) yang diberikan kepada pengguna saat pertama kali mengaktifkan 2FA/TOTP. Jika ponsel pengguna hilang atau aplikasi autentikator terhapus, pengguna dapat memasukkan salah satu kode cadangan tersebut untuk masuk ke sistem tanpa bantuan pihak lain.

### 2.2. Analisis Risiko & Operasional Lapangan di Kedai Resto
Penerapan kode pemulihan mandiri pada konteks staf dan admin restoran UMKM memiliki beberapa kelemahan kritis:

| Faktor | Kode Pemulihan Mandiri | Hierarki Pemulihan via Peran Atas (Resto Barokah) |
|---|---|---|
| **Penyimpanan Fisik** | Karyawan/admin sering menyimpan kode di catatan ponsel yang sama, atau menulis di secarik kertas yang tercecer di laci kasir (*single point of failure*). | Tidak ada kode yang dibawa pulang oleh admin cabang/staf. Kredensial dipulihkan langsung oleh atasan yang berwenang. |
| **Risiko Pencurian HP** | Jika ponsel dicuri bersama kertas/catatan kode pemulihan, pencuri mendapatkan akses penuh 2FA. | Ponsel hilang langsung diputus aksesnya oleh Owner Pusat seketika via `keluar_semua_perangkat` & `tandai_perangkat_hilang`. |
| **Disiplin Rotasi** | Karyawan jarang memperbarui kode cadangan setelah terpakai, sehingga terkunci total saat kode habis. | Atasan dapat mereset faktor login kapan saja tanpa batasan kuota kode habis. |
| **Akuntabilitas & Audit** | Pemulihan mandiri sering disalahgunakan tanpa sepengetahuan pemilik kedai. | Setiap reset kredensial dicatat kekal di `public.catatan_audit` lengkap dengan nama pelaku, target, dan stempel waktu. |
| **Dampak Biaya** | Membutuhkan UI penyimpanan & cetak kode mandiri yang rumit. | **Rp 0** (Memanfaatkan tabel `pengguna`, `sesi_perangkat`, dan RPC yang sudah ada). |

### 2.3. Tangga Pemulihan 4 Tingkat yang Terbukti Aman (Resto Barokah)
Sistem Resto Barokah telah menerapkan **Tangga Pemulihan 4 Tingkat** (teruji di `supabase/tes/mfa.sql` dan `docs/teknis/BUKU_INSIDEN.md`):

1. **Tingkat 1 — Staf Operasional (Kasir, Pelayan, Dapur):**
   - **Kredensial:** Perangkat terdaftar + PIN 6 digit unik. Staf tidak menggunakan TOTP pribadi.
   - **Pemulihan:** Jika staf lupa PIN atau terblokir (5× salah PIN), Admin Cabang atau Owner Pusat melakukan reset PIN via RPC `reset_pin_pegawai`. Bebas pusing, cepat (< 2 menit), dan tercatat di audit.
2. **Tingkat 2 — Admin Cabang:**
   - **Kredensial:** Kata sandi ≥ 12 karakter + TOTP (Google Authenticator) di ponsel admin.
   - **Pemulihan saat HP Admin Hilang/Rusak:** Owner Pusat masuk ke panel kelola pegawai, mencabut seluruh sesi perangkat admin via `keluar_semua_perangkat(target_id)`, menonaktifkan akun sementara via `set_status_pengguna`, mereset kredensial login, dan mendampingi pendaftaran perangkat baru.
3. **Tingkat 3 — Owner Pusat:**
   - **Kredensial:** Kata sandi ≥ 12 karakter + TOTP wajib + Perangkat Terdaftar.
   - **Pemulihan saat HP Owner Hilang (Kunci Induk Darurat / Break-Glass):** Menggunakan kode pemulihan darurat 20+ karakter yang dicetak saat bootstrap dan disimpan dalam 2 amplop tersegel di brankas fisik. Kode diverifikasi via RPC `pulihkan_perangkat` dengan **masa tenggang wajib 30 menit** (mencegah pembobolan mendadak) dan sakelar pembatalan (*kill-switch*) via `batalkan_pemulihan`.
4. **Tingkat 4 — Bencana Total (*Ultimate Fallback*):**
   - **Pemulihan:** Pemilik Platform (*Platform Owner*) memulihkan akses penyewa melalui dashboard administratif Supabase langsung di luar aplikasi klien.

### 2.4. Rekomendasi Terkait Kode Pemulihan MFA
> **Rekomendasi Agent:** **TETAP PERTAHANKAN MODEL HIERARKI PERAN ATAS.**  
> Resto Barokah **TIDAK PERLU** menerapkan kode pemulihan mandiri untuk Admin Cabang. Model kendali atasan (*Owner Authority*) jauh lebih cocok untuk budaya kerja UMKM Indonesia, mencegah kelalaian penyimpanan kode, mencegah kolusi staf, serta memastikan Owner Pusat selalu mengetahui setiap perubahan akses akun di restorannya. Untuk Owner Pusat, mekanisme Kunci Induk Darurat (`kredensial_pemulihan`) 20+ karakter dengan masa tenggang 30 menit sudah memberikan perlindungan bencana tingkat tinggi tanpa biaya tambahan.

---

## 3. Bagian II: Tinjauan Pemeriksa Kata Sandi Bocor (*HaveIBeenPwned / HIBP*)

### 3.1. Status Nyata Fitur di Supabase Auth
- **Supabase Pro Tier ($25/bulan atau ~Rp 400.000/bulan):** Supabase menyediakan tombol sakelar bawaan *"Prevent use of leaked passwords via HaveIBeenPwned"*. Saat aktif, pendaftaran kata sandi yang ada dalam database kebocoran publik HIBP akan ditolak secara otomatis oleh server Auth Supabase.
- **Supabase Free Tier ($0/bulan — Paket Resto Barokah):** Fitur bawaan sakelar HIBP di dashboard Supabase **TIDAK TERSEDIA** (terkunci di paket berbayar).
- **Pertanyaan Inti T-016:** Apakah Resto Barokah harus membayar Supabase Pro $25/bulan hanya untuk fitur ini? Ataukah ada cara biaya nol (Rp 0)?

### 3.2. Status Nyata API Publik HaveIBeenPwned (Pwned Passwords API v3)
Berdasarkan dokumentasi teknis resmi Troy Hunt (pencipta HIBP) dan Cloudflare:
1. **Endpoint Range Passwords:**
   - URL: `GET https://api.pwnedpasswords.com/range/{5-karakter-prefix-sha1}`
   - **Biaya:** **100% GRATIS ($0 / Rp 0)**.
   - **Kunci API:** **TIDAK MEMERLUKAN API KEY** (berbeda dari endpoint pemeriksaan kebocoran email akun yang berbayar $3.5/bulan).
2. **Model Kriptografis: *k-Anonymity***
   - Kata sandi mentah **TIDAK PERNAH DIKIRIMKAN** ke internet.
   - Hash SHA-1 lengkap **TIDAK PERNAH DIKIRIMKAN** ke internet.
   - Cara kerja:
     1. Aplikasi menghitung hash SHA-1 dari kata sandi (panjang 40 karakter heksadesimal). Misal: `password` -> `5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8`.
     2. Aplikasi memotong 5 karakter pertama sebagai awalan (*prefix*): `5BAA6`.
     3. Aplikasi mengirim `GET https://api.pwnedpasswords.com/range/5BAA6` ke server HIBP.
     4. Server HIBP mengembalikan daftar ~500 akhiran hash (*suffix*, 35 karakter) beserta jumlah frekuensi kebocorannya.
     5. Aplikasi secara lokal di memori mencocokkan sisa 35 karakter (`1E4C9B93F3F0682250B6CF8331B7EE68FD8`). Jika cocok, berarti kata sandi pernah bocor di internet!
3. **Privasi & Keamanan:** Sepenuhnya patuh pada prinsip privasi dan UU PDP karena nol data pribadi yang keluar dari peramban/server.

### 3.3. Siapa yang Memakai Kata Sandi di Resto Barokah?
Penting untuk menyadari profil pengguna aplikasi Resto Barokah:
- **Kasir, Pelayan, Dapur:** **0% menggunakan kata sandi**. Mereka masuk menggunakan **Perangkat Terdaftar + PIN 6 angka** di tablet/komputer kedai.
- **Pelanggan:** Masuk menggunakan **Google Sign-In** (OAuth) atau tautan email OTP sekali pakai (tanpa kata sandi).
- **Hanya Owner Pusat dan Admin Cabang** yang memiliki kata sandi web untuk dashboard analitik dan pengaturan.
- Populasi akun berkata sandi sangat kecil (1–3 akun per restoran).

### 3.4. Kendali Pengganti (Kompensasi) yang Sudah Sangat Kuat di Resto Barokah
Resto Barokah telah memasang kendali berlapis yang membuat risiko kata sandi bocor menjadi tidak signifikan:
1. **Panjang Minimal 12 Karakter:** Menghilangkan 99% kata sandi kamus umum pendek (seperti `123456`, `admin`, `password`).
2. **Larangan Pola Lemah:** Menolak kata sandi yang memuat nama resto, tanggal berulang, atau urutan sederhana.
3. **Wajib TOTP / 2FA (Kunci Kedua):** Sekalipun penyerang mengetahui kata sandi admin dari kebocoran situs lain (kredensial hasil *credential stuffing*), penyerang **TETAP GAGAL MASUK** karena tidak memiliki kode 6 digit dari aplikasi Google Authenticator di ponsel fisik admin/owner.
4. **Batas Percobaan Masuk Ketat:** Maksimal 5× gagal dalam 15 menit per akun dan 12× per perangkat (`percobaan_masuk`). Akun langsung terkunci otomatis bila diserang *brute force*.
5. **Jejak Audit Kekal:** Setiap kegagalan masuk dicatat di `catatan_audit` dan dilaporkan dalam ringkasan harian owner (T10-13).

---

## 4. Opsi Keputusan untuk Lee

| Opsi | Deskripsi | Dampak Biaya | Keamanan | Rekomendasi |
|---|---|---|---|---|
| **Opsi A (Status Quo Tangguh)** | Mengandalkan aturan kata sandi ≥ 12 karakter + larangan pola + TOTP wajib + batas 5× percobaan. Tidak memanggil HIBP. | **Rp 0** | **Sangat Tinggi** (TOTP menangkis pembobolan walau sandi bocor). Tidak bergantung pada koneksi internet pihak ketiga saat setel sandi. | **DIREKOMENDASIKAN UNTUK OPERASIONAL SEKARANG** |
| **Opsi B (Pemeriksa HIBP Klien Bebas Biaya)** | Menambahkan fungsi pengecekan k-Anonymity langsung di formulir ganti kata sandi pengelola menggunakan API gratis HIBP (`api.pwnedpasswords.com/range`). | **Rp 0** | **Ekstra Ketat** (Menolak sandi bocor sebelum disimpan). Namun jika HIBP down/terblokir ISP lokal, ganti sandi bisa gagal. | **OPSI CADANGAN / ENHANCEMENT MASA DEPAN** |
| **Opsi C (Langganan Supabase Pro)** | Upgrade proyek ke Supabase Pro hanya untuk mencentang toggle HIBP bawaan di dashboard. | **$25 / bulan (~Rp 4,8 juta / tahun)** | **Sama dengan Opsi B** | **TIDAK DISARANKAN** (Pemborosan biaya untuk UMKM kedai). |

---

## 5. Keputusan Pemilik & Rekomendasi Final

1. **Pemulihan MFA:**
   - **DITETAPKAN:** Pemulihan MFA tetap menggunakan **Tangga Pemulihan 4 Tingkat via Peran Atas & Kunci Induk Darurat 30 Menit**. Kode pemulihan mandiri untuk staf/admin cabang tidak digunakan demi mencegah kelalaian dan kebocoran di lingkungan fisik restoran.
2. **Pemeriksa Kata Sandi Bocor (HIBP):**
   - **DITETAPKAN:** Memilih **Opsi A** untuk operasional kedai saat ini (Biaya = Rp 0). Perlindungan kata sandi ≥ 12 karakter + larangan pola lemah + TOTP wajib terbukti secara matematis dan operasional telah menutup celah keamanan akun.
   - Panggilan API gratis k-Anonymity HIBP (Opsi B) disimpan sebagai modul referensi arsitektur yang dapat diaktifkan jika di masa depan restoran memiliki ratusan staf pengelola, tanpa perlu membayar Supabase Pro.
3. **Status Butir Tertangguh T-016:**
   - Butir `T-016` di `docs/TERTANGGUH.md` resmi dinyatakan **SELESAI DITINJAU & DITUTUP** dengan keputusan biaya nol.
4. **Verifikasi Database:**
   - Seluruh aturan tangga pemulihan kredensial, proteksi peran atas, rotasi kunci induk darurat, dan pencegahan lockout telah diverifikasi dan diuji secara komprehensif melalui 19 skenario di `supabase/tes/mfa.sql` (132/132 berkas uji SQL lulus 100%).

---

*Disusun oleh Agent Resto Barokah untuk Pemilik Lee — 2026-09-27.*
