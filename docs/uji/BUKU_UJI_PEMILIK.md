# BUKU UJI PEMILIK — lembar kerja Lee (ditulis BERTAHAP mengikuti jalannya proyek)

> **Apa ini:** satu berkas untuk Lee. Isinya dua hal: **(1) yang harus Lee lakukan** (mis. membuat akun
> Supabase, memutuskan sesuatu) dan **(2) yang harus Lee coba** (sesuatu yang sudah jadi dan bisa dinilai mata).
> Ditulis **bertahap**: setiap kali sebuah pekerjaan selesai dan hasilnya bisa dilihat/dijalankan manusia,
> barisnya **langsung ditambahkan** di sini — bukan ditulis semua di akhir. Setiap baris baru juga **ditampilkan
> di chat** pada batch yang sama, supaya Lee tidak perlu mencari berkas.
>
> **Lee tidak perlu membuka terminal.** Untuk apa pun yang berbentuk "jalankan perintah",
cukup bilang ke agent (mis. **`Uji semuanya.`**) — agent yang menjalankan dan **wajib menempelkan
hasilnya di chat**. Buku ini ditulis supaya kamu tidak perlu menghafal perintah.

**Cara pakai (3 langkah):**
> 1. Kerjakan/coba satu baris pada satu waktu. Jangan kerjakan semua sekaligus.
> 2. Isi kolom **Hasil** dengan `OK` atau `GAGAL`, dan tulis apa yang terjadi di kolom **Catatan** (kalau ada).
> 3. Bilang ke agent di chat: `Buku uji baris <ID>: OK` (atau `GAGAL — <apa yang terjadi>`). Agent mencatatnya di sini.
>
> **Batas yang disepakati (jangan dilanggar):**
> - **Uji mesin tetap di CI.** Buku ini **bukan** pengganti uji otomatis; ia hanya untuk hal yang butuh **mata manusia**
>   (tampilan, alur, rasa pakai, keputusan). Baris yang bisa dijawab mesin tidak dimasukkan ke sini.
> - **Satu baris = satu hal**, maksimal **5 langkah**. Kalau butuh lebih dari 5 langkah, baris itu harus dipecah.
> - **Dokumen ini sumber kebenaran**; ringkasan di chat hanyalah pengingat.
> - Kolom **Yang seharusnya terjadi** wajib ada. Tanpa itu, "sudah saya coba" tidak bisa dinilai.
>
> **Dijaga mesin:** `alat/periksa-buku-uji.py` (dijalankan di CI). Baris tanpa langkah/harapan, id kembar,
> urutan langkah melompat, atau tugas yang tidak ada di ROADMAP → **CI GAGAL**.

## 1. Yang harus Lee LAKUKAN (tugas yang hanya bisa dikerjakan Lee)

| ID | Yang harus dilakukan | Langkah | Yang seharusnya terjadi | Hasil (isi: OK/GAGAL) | Catatan |
|---|---|---|---|---|---|
| P-06 | **Membuka audit independen Batch-5** (T1-30/T1-45), setelah waktu belajar selesai | 1) Buka sesi baru dengan base branch `arena/01a0c2c1-resto-barokah` (pilih model berbeda bila tersedia) 2) Tempel seluruh isi `docs/uji/paket-audit/AUD-2-2026-09-21-SIAP-TEMPEL.md` 3) Setelah laporan dikirim, kembali dan bilang `Laporan audit sudah masuk, periksa.` | Auditor memeriksa commit `09bcb89` dan mengirim laporan; agent memvalidasi serta menindaklanjuti, bukan langsung mengizinkan merge/deploy |  | Menunggu sejak 2026-09-21; tidak perlu dilakukan saat exam. Paket siap, audit BELUM dijalankan. |
| P-03 | **Mengisi lembar kunci & akun** — tempat kamu menuliskan hal yang harus dikumpulkan (alamat proyek, kunci, akun layanan) | 1) Buka formulir `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` 2) Salin formulir itu menjadi berkas kerja bernama DAFTAR_KUNCI_PEMILIK.local.md di folder yang sama 3) Isi kolom "Nilai" di berkas kerja itu 4) **Jangan tempel nilai rahasia di chat** | Berkas kerja terisi rapi dan tetap tidak ikut Git; formulir contoh tetap kosong |  |  |
| P-01 | Membuat akun & proyek **Supabase** (+ akun Cloudflare), lalu menyerahkan **URL proyek** dan kunci `anon` ke agent (tugas `T0-00`) | 1) Buka `docs/ops/SIAP_AKUN_PEMILIK.md` 2) Ikuti langkah 1–6 (region **Singapore**) 3) Tempel URL + kunci `anon` ke chat | Agent bisa menjalankan pengecekan di Supabase nyata (tugas `T0-08`); tidak ada kunci rahasia yang masuk repo | **OK** (2026-09-19) | Nilai non-rahasia masuk `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md`; sambungan diuji otomatis di CI (gerbang ke-50); sebar skema masih menunggu Lee (`T-020`) |
| P-04 | **Menitipkan 2 rahasia Supabase** ke kotak rahasia GitHub supaya tabel database bisa disebar mesin (tugas `T0-08`) | 1) Buka `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, ikuti **Langkah A** (4 langkah) 2) **Jangan** menempel token/kata sandi di chat 3) Bilang `Rahasia sudah dipasang.` | Alur "Sebar Skema ke Supabase" berjalan: pratinjau dry-run lalu 14 migrasi disebar; tabel ada di proyek nyata | **OK** (2026-09-19) | Lee menyelesaikan Langkah A → agent memicu berkas penanda → run `35435248540` hijau (`link` → pratinjau → sebar → daftar migrasi); gerbang CI ke-50 lalu membaca tabel katalog (HTTP 200, run `35435414653`) |
| P-05 | **Menitipkan 1 rahasia Cloudflare** supaya halaman bisa naik ke internet (tugas `T0-09`, hanya bila Lee mau) | 1) Ikuti **Langkah B** di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` 2) Bilang `Rahasia sudah dipasang.` | Alur "Naikkan Halaman ke Cloudflare" berjalan; alamat publik `*.workers.dev` muncul di laporan agent | **OK** (2026-09-19) | Lee menulis "Boleh naik" → agent memicu penanda → run `35440300274` & `35440432817` hijau; alamat publik <https://resto-barokah.fatrizmubarok.workers.dev> **HTTP 200** (pemeriksaan otomatis di dalam alur) |
| P-02 | **Menjawab "butir tunggu"** — daftar hal kecil yang ditunda supaya pekerjaan jalan terus; isinya menunggu keputusanmu (mis. merek printer, daftar perangkat, tablet Android, pelatihan pegawai, kebijakan privasi) | 1) Bilang di chat: `Tampilkan butir tunggu.` (agent menampilkan daftarnya lengkap dengan jawaban usulan) 2) Balas `setuju semua` — atau pilih yang mau kamu putuskan sendiri 3) Tidak perlu buka berkas apa pun | Semua butir tertutup dengan jawabanmu; agent mencatatnya di `docs/TERTANGGUH.md` lalu melanjutkan |  |  |

**Catatan jujur:** baris P-01 tidak memblokir pekerjaan agent (database diuji di PostgreSQL nyata di mesin ini),
tetapi **memblokir** dua tugas yang butuh layanan sungguhan: `T0-08` dan `T0-09`.

## 2. Yang harus Lee COBA (yang sudah jadi & bisa dinilai manusia)

| ID | Yang dicoba | Langkah | Yang seharusnya terjadi | Hasil (isi: OK/GAGAL) | Catatan |
|---|---|---|---|---|---|
| U-01 | Pratinjau **desain** (5 halaman contoh + 10 tema) | 1) Minta agent: `Nyalakan pratinjau.` 2) Buka alamat yang muncul 3) Coba ganti tema & perkecil lebar jendela (ukuran HP) | Halaman terbuka tanpa error; teks tidak bertumpuk; tombol bisa ditekan; tema berganti |  |  |
| U-02 | Melihat **seluruh pemeriksaan otomatis** berjalan (tanpa mengetik perintah) | 1) Bilang di chat: `Uji semuanya.` 2) Tunggu agent selesai 3) Baca hasil yang agent tempel | Baris terakhir berbunyi `SEMUA PEMERIKSAAN LOLOS.` — kalau ada yang GAGAL, nama pemeriksanya disebut |  |  |
| U-03 | Melihat **uji database** berjalan (tanpa mengetik perintah) | 1) Bilang di chat: `Uji database.` 2) Tunggu agent selesai 3) Baca hasil yang agent tempel | Tertulis `uji: <jumlah> LULUS · 0 GAGAL` dan `HASIL: LOLOS` |  |  |
| U-04 | Menjalankan **sesi review PR independen** (satu-satunya cara Lee menilai kode tanpa membaca diff) | 1) Buka chat BARU (idealnya model berbeda) 2) Bilang `Siapkan review PR.` — agent menyebutkan nama berkas **paling baru** (berkas SIAP-TEMPEL di folder docs/uji/review-pr/); salin SELURUH isi berkas itu 3) Kirim pesan: `Laporan review sudah masuk, periksa.` | Chat peninjau menghasilkan laporan berisi temuan berlevel + skor kalibrasi; lalu agent memvalidasi laporan itu dengan `alat/review-pr.py --periksa-laporan` |  |  |
| U-05 | **Buku induk** benar-benar bisa dipakai tanpa bertanya | 1) Buka `PANDUAN_PENGGUNA.md` 2) Cari 3 hal: cara minta audit, cara review PR, cara mengulang pekerjaan lama 3) Lakukan tanpa bertanya ke agent | Ketiga hal ditemukan lengkap dengan langkah & kalimat yang bisa langsung dipakai |  |  |

| U-06 | **Tombol Nyaman/Padat & daftar 10 tema** (cacat yang kamu laporkan 2026-09-17: cuma terlihat 5 tema & kerapatan tidak berefek) | 1) Buka pratinjau, muat ulang halaman 2) Buka tombol `Ganti tema` → hitung sendiri jumlah pilihannya (harus 10) 3) Pilih 2–3 tema berbeda → warna berubah 4) Tekan `Padat` lalu `Nyaman` → jarak kartu & baris contoh berubah | Daftar tema memuat **10** pilihan; tiap tema mengubah warna; `Padat` merapatkan jarak, `Nyaman` melegakan kembali |  |  |

| U-07 | **Panel tema tidak lagi terpotong & mode Padat lebih rapi** (dua laporan kamu 2026-09-17) | 1) Buka pratinjau, muat ulang halaman 2) Tekan `Ganti tema (10)` di dekat bawah halaman — panelnya terbuka utuh, tidak terpotong tepi layar 3) Geser daftar di dalam panel bila perlu 4) Tekan `Padat`, lalu bandingkan dengan `Nyaman` | Panel tema muncul **utuh** (bisa digeser di dalam kotak, tidak keluar layar); mode `Padat` merapatkan **ukuran blok** (kartu, tombol, isian, baris tabel) — bukan cuma jaraknya — dan **ukuran huruf tetap sama** |  |  |
| 2026-09-17 | U-02 & U-03: janji "SEMUA PEMERIKSAAN LOLOS" dijaga — kedua perintah uji memasang pustakanya sendiri, jadi bisa dijalankan apa adanya di salinan baru (temuan review PR-07). U-04 disegarkan ke paket berlaku **putaran10** (temuan PR-03/PR-07/PR-10) dan penjaga `alat/periksa-buku-uji.py` menolak paket basi (urutan putaran dibandingkan sebagai angka) |
| 2026-09-17 | U-04 tidak lagi menyebut nama paket tetap — cukup "berkas SIAP-TEMPEL paling baru di `docs/uji/review-pr/`" (agent menyebut namanya di chat). Alasannya: tiap tip bergerak, paket berganti, dan buku ini sempat 3× menyuruh Lee memakai paket basi; penjaga mesin tetap aktif untuk kasus nama paket ditulis tetap |
| U-08 | **Panel tema: cara menutup + ujung daftar** (dua keluhan kamu 2026-09-17) | 1) Buka pratinjau, muat ulang 2) Tekan `Ganti tema` lalu tekan **Esc** — panel menutup dan kursor kembali ke tombolnya 3) Buka lagi, lalu klik/ketuk **di luar panel** — panel menutup 4) Geser daftar tema ke bawah — isinya **memudar halus** di ujung, bukan terpotong mentah | Esc menutup · klik di luar menutup · ujung daftar memudar mengikuti geseran |  |  |

## 3. Log buku ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Baris **U-06** (tema & kerapatan) ditambahkan setelah Lee melaporkan tombol kerapatan tampak mati; langkah U-02/U-03 diubah ke jalur chat (Lee tidak perlu terminal); **P-03** (lembar kunci pemilik) ditambahkan | Laporan Lee 2026-09-17 + permintaan lembar kunci |
| 2026-09-17 | Berkas dibuat + 7 baris pertama (2 "lakukan" · 5 "coba") + penjaga `alat/periksa-buku-uji.py` | Permintaan Lee 2026-09-17: buku uji bertahap berisi apa yang harus dicoba, lengkap dengan panduan bahasa sederhana & tempat mengisi hasilnya; ditampilkan juga di chat. Tugas ROADMAP `T1-43`. |
| 2026-09-17 | Baris **U-08** (cara menutup panel tema + jejak pudar ujung daftar) ditambahkan | Keluhan Lee 2026-09-17: panel hanya bisa ditutup lewat tombolnya, dan ujung daftar "nabrak" |
