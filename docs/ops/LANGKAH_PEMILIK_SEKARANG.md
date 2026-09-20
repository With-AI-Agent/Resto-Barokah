# LANGKAH PEMILIK SEKARANG — 3 rahasia di GitHub (±5 menit)

> Ditulis 2026-09-19 untuk Lee. Bahasa awam, **tanpa perintah yang perlu kamu ketik**.
> Kalau ragu di langkah mana pun: **berhenti dan tanya agent** — jangan menebak.

## ⚠️ Update 2026-09-20 (setelah melihat screenshot billing Lee) — penyebab KETEMU: menit gratis habis; **tidak perlu bayar apa pun**

Screenshot halaman tagihan organisasi (With-AI-Agent) yang dikirim Lee menunjukkan kebenarannya:

1. Langganan = **GitHub Free ($0 per bulan)**; tagihan bulan ini **$0** → **tidak perlu kartu / pembayaran apa pun**.
2. **Menit Actions: 2.000 / 2.000 terpakai** (bar merah penuh). Itulah kenapa GitHub menghentikan semua robot —
   paket gratis memang menghentikan robot kalau jatahnya habis.
3. Jatahnya **dipakai bersama seluruh organisasi**: bulan ini repo **Oasis-Pro** (±setengah) dan **Resto-Barokah**
   (±setengah) berbagi 2.000 menit itu.
4. **Reset otomatis dalam 11 hari** (±1 Oktober) — robot hidup lagi sendiri tanpa kita berbuat apa-apa.

**Sementara menunggu:** maraton lanjut terus; semua pemeriksaan dijalankan di komputer lokal (sudah dibuktikan
identik dengan CI). Supaya setelah reset jatahnya tidak habis lagi di tengah bulan, disiapkan **mode hemat**:
robot tidak lagi jalan dua kali per kiriman (push + permintaan-tarik) melainkan sekali — menunggu persetujuan Lee.

**Opsi gratis kalau tidak mau menunggu (keputusan Lee):** (1) **jadikan repo publik** → menit robot tak terbatas,
tapi kode & dokumen terlihat siapa pun; (2) **transfer repo ke akun pribadi teman** (atau organisasi baru) →
jatah 2.000 menit segar, tapi kunci rahasia (Supabase/Cloudflare) harus diisikan ulang di repo baru.

(Langkah lama "perbaiki pembayaran" sudah **tidak diperlukan** — penyebabnya jatah menit, bukan pembayaran gagal.)

## Kenapa ini perlu

Aku tidak boleh — dan tidak mau — melihat kunci rahasiamu. Kunci itu disimpan di **kotak rahasia GitHub**
(_repository secrets_) dan hanya **dipakai** mesin saat menjalankan alur otomatis (menyebar tabel database,
menaikkan halaman ke internet).

**Jujur soal batasnya (koreksi 2026-09-20, audit I F-11):** "terenkripsi" BUKAN berarti "tidak mungkin
terbaca". GitHub menyimpan secrets agar tidak tampil di layar dan menyamarkan nilainya di log, tetapi
**siapa pun yang boleh mengubah alur kerja (workflow) di repo ini secara teknis bisa membuat alur yang
membaca secrets itu** (mis. mengirimnya ke tempat lain), dan penyamaran log tidak dijamin untuk semua
bentuk keluaran. Karena itu:

- beri **hanya** repo ini (jangan pakai token pribadi yang dipakai di tempat lain);
- pakai token dengan **izin sesempit mungkin** dan **masa berlaku** (TTL) yang wajar, bukan selamanya;
- jangan menambah penulis/kontributor yang tidak kamu percaya ke repo ini — merekalah yang bisa mengubah alur;
- kalau nanti ada fitur _environment protection_ di GitHub (butuh review sebelum rahasia dipakai), itu
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
   _Database password_ (kalau lupa, tekan **Reset database password** lalu simpan yang baru).
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
4. Di halaman ringkasan, **biarkan apa adanya** (Account Resources: _Include → All accounts_) →
   tekan **Continue to summary** → **Create Token** → tekan **Copy**.

   _Kalau kamu sudah terlanjur membuka **Create Custom Token**_ dan ingin melanjutkan di situ:
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
- Kalau kamu merasa ragu, cukup bilang _"Tolong pandu aku langkah demi langkah"_ — agent akan menemani
  satu langkah sekali.
