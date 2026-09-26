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
| U-09 | **Penggantian multi-bahasa instan** (tugas `T1-40`) | 1) Buka pratinjau aplikasi 2) Klik pemilih bahasa di bilah navigasi 3) Pilih English, 中文, atau العربية 4) Perhatikan teks antarmuka dan format nominal harga | Seluruh teks antarmuka berganti bahasa seketika tanpa reload halaman; teks tombol dan status berubah; format nominal rupiah tetap konsisten Rp (id-ID) |  |  |
| U-10 | **Tata letak dua arah RTL & isolasi nominal harga** (tugas `T1-41`) | 1) Buka pratinjau aplikasi 2) Ganti bahasa ke Bahasa Arab (العربية) 3) Perhatikan arah navigasi dan tombol 4) Ganti kembali ke Bahasa Indonesia | Tata letak bergeser ke kanan-ke-kiri (RTL) rapi; font Arab/Mandarin tampil proporsional; angka nominal uang tetap terbaca LTR dari kiri ke kanan |  |  |
| U-11 | **Bantuan kontekstual '?' di setiap layar** (tugas `T1-42`) | 1) Buka pratinjau aplikasi 2) Tekan tombol tanda tanya (?) di pojok kanan atas layar 3) Baca isi panduan terstruktur 4) Tekan tombol tutup atau tekan Esc | Lembar bantuan terbuka menampilkan ringkasan, maksimal 5 langkah pengoperasian, dan petunjuk kalau macet; lembar bantuan menutup bersih |  |  |
| U-12 | **Naskah jalan pemilik alur contoh layar** (tugas `T1-35`) | 1) Buka naskah jalan di `docs/uji/NASKAH_JALAN.md` 2) Buka skenario W-0-01 3) Ikuti 4 langkah di pratinjau aplikasi 4) Periksa kesesuaian hasil | Seluruh langkah naskah jalan W-0-01 terlaksana mulus tanpa galat, tombol aksi menaati dialog konfirmasi dan izin |  |  |

| U-13 | Buka & Tutup Kas Shift Kasir (tugas `T7-01`) | 1) Masuk sebagai Kasir 2) Tekan Buka Kas dan isi modal awal 3) Lakukan transaksi 4) Tekan Tutup Kas dan isi uang fisik 5) Konfirmasi selisih kas | Kasir berhasil buka kas dengan modal, status aktif, dan tutup kas mencatat selisih fisik secara akurat |  | Fase 7 Shift Kas |

| U-14 | Laporan Penjualan & Kas Harian (tugas `T7-05`) | 1) Masuk sebagai Owner 2) Buka menu Laporan 3) Pilih Laporan Penjualan 4) Periksa rincian omzet, diskon, dan metode bayar 5) Cocokkan total kas | Laporan penjualan harian menyajikan omzet kotor, potongan diskon, pajak PB1, dan metode bayar cocok dengan transaksi kasir |  | Fase 7 Laporan |

| U-15 | Katalog Menu Publik Pelanggan (tugas `T8-02`) | 1) Buka rute publik katalog resto tanpa login 2) Periksa nama resto, logo, dan jam operasional 3) Telusuri daftar menu dan varian harga 4) Periksa penanda menu habis | Katalog publik memuat profil kedai, harga cabang akurat, foto menu rapi, dan menu habis terkunci tanpa membocorkan data staf |  | Fase 8 Katalog Publik |

| U-16 | Klaim & Pakai Voucher Diskon di Kasir (tugas `T8-09`) | 1) Buka tautan kampanye voucher dan klaim voucher 2) Masuk layar Kasir dan susun pesanan 3) Masukkan kode voucher atau scan kamera 4) Bayar pesanan dan periksa potongan di struk 5) Coba pakai lagi kode voucher yang sama | Voucher memotong tagihan sesuai aturan, struk mencatat diskon, dan percobaan pemakaian kedua langsung ditolak karena sudah hangus |  | Fase 8 Voucher |

| U-17 | Transparansi Privasi UU PDP & Hak Hapus Data (tugas `T8-15`) | 1) Buka tautan Kebijakan Privasi di kaki halaman 2) Baca ringkasan hak subjek data 3) Periksa bagian alur permintaan penghapusan data 4) Coba pendaftaran pelanggan baru | Halaman privasi transparan sesuai UU PDP, dan formulir pendaftaran mewajibkan centang persetujuan sebelum data disimpan |  | Fase 8 Privasi |

| U-18 | Pengaturan Identitas Resto & Logo (tugas `T9-01`) | 1) Masuk sebagai Owner 2) Buka menu Pengaturan Resto → Tab Identitas 3) Ubah nama kedai dan tagline 4) Unggah logo kedai 5) Simpan perubahan dan buka katalog publik | Identitas dan logo resto berhasil tersimpan, langsung muncul di katalog publik dan kop struk kasir tanpa koding |  | Fase 9 Identitas |

| U-19 | Tema Merek 10 Pilihan Visual & Kerapatan (tugas `T9-02`) | 1) Masuk sebagai Owner → Pengaturan Resto → Tab Tema 2) Pilih tema visual yang berbeda (mis. Hangat Kedai atau Bara) 3) Beralih antara mode Nyaman dan Padat 4) Simpan pilihan tema 5) Periksa keterbacaan teks | Tema visual berganti seketika dengan kontras teks tajam (lulus WCAG), dan mode kerapatan padat/nyaman merapikan tata letak |  | Fase 9 Tema Merek |

| U-20 | Pengaturan Operasional PB1, Service, & Struk (tugas `T9-03`) | 1) Masuk sebagai Owner → Pengaturan Resto → Tab Operasional 2) Ubah persentase PB1 dan service charge 3) Pilih aturan pembulatan dan ubah teks ucapan struk 4) Periksa kalkulasi struk simulasi langsung 5) Tekan Simpan Pengaturan | Pengaturan tersimpan rapi, simulasi struk live kasir akurat, dan kalkulasi transaksi masa lalu tetap utuh kebal perubahan |  | Fase 9 Operasional |

| U-21 | Daftar Uji Terima Pengaturan Mandiri Pemilik (tugas `T9-12`) | 1) Buka berkas panduan `docs/uji/UJI_TERIMA_PENGATURAN.md` 2) Masuk sebagai Owner ke Pengaturan Resto 3) Jalankan 12 skenario pengujian ramah manusia 4) Cocokkan hasil dengan lembar ceklis 5) Tandai status pengujian | Seluruh 12 skenario pengaturan resto terbukti berjalan mulus dari sudut pandang pemilik kedai tanpa kendala teknis |  | Fase 9 Uji Terima |

| U-22 | Antrean Pesanan Luring saat Internet Putus (tugas `T10-01`) | 1) Masuk ke layar Kasir 2) Putuskan koneksi internet perangkat 3) Susun pesanan di keranjang dan tekan Kirim ke Dapur 4) Periksa banner status "menunggu dikirim 1" 5) Sambungkan kembali internet dan amati sinkronisasi | Pesanan tersimpan aman di IndexedDB lokal tanpa data sensitif, status antrean jelas jujur, dan otomatis terkirim sekali saat daring kembali (ART-8) |  | Fase 10 Ketahanan |

## 3. Log buku ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-26 | Baris **U-22** ditambahkan (Antrean pesanan luring saat internet putus T10-01) | Panduan uji mandiri pemilik saat kasir offline, pembuktian status jelas "menunggu dikirim X", dan sinkronisasi otomatis ART-8 |
| 2026-09-26 | Baris **U-21** ditambahkan (Daftar uji terima pengaturan mandiri pemilik bahasa manusia T9-12) | Melengkapi panduan uji mandiri pemilik untuk seluruh fitur Pengaturan Resto & Multi-Cabang Fase 9 (`docs/uji/UJI_TERIMA_PENGATURAN.md`) |
| 2026-09-26 | Baris **U-13** s/d **U-20** ditambahkan (Fase 7 Shift & Laporan, Fase 8 Katalog & Voucher & Privasi, Fase 9 Pengaturan Resto T9-01 s/d T9-03) | Permintaan Lee memastikan seluruh hal yang perlu diuji mata/tangan manusia dari Fase 1 sampai 9 tercatat lengkap dengan cara, tujuan, dan indikator |
| 2026-09-22 | Baris **U-09** s/d **U-12** ditambahkan (multi-bahasa T1-40, RTL T1-41, bantuan kontekstual T1-42, naskah jalan T1-35) + skrip penambah baris `alat/tambah-uji.py` | Selesainya fondasi kelengkapan UI Fase 1C yang siap dinilai pemilik di pratinjau |
| 2026-09-17 | Baris **U-06** (tema & kerapatan) ditambahkan setelah Lee melaporkan tombol kerapatan tampak mati; langkah U-02/U-03 diubah ke jalur chat (Lee tidak perlu terminal); **P-03** (lembar kunci pemilik) ditambahkan | Laporan Lee 2026-09-17 + permintaan lembar kunci |
| 2026-09-17 | Berkas dibuat + 7 baris pertama (2 "lakukan" · 5 "coba") + penjaga `alat/periksa-buku-uji.py` | Permintaan Lee 2026-09-17: buku uji bertahap berisi apa yang harus dicoba, lengkap dengan panduan bahasa sederhana & tempat mengisi hasilnya; ditampilkan juga di chat. Tugas ROADMAP `T1-43`. |
| 2026-09-17 | Baris **U-08** (cara menutup panel tema + jejak pudar ujung daftar) ditambahkan | Keluhan Lee 2026-09-17: panel hanya bisa ditutup lewat tombolnya, dan ujung daftar "nabrak" |
