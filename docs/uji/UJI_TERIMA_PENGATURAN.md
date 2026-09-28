# UJI_TERIMA_PENGATURAN.md — Daftar Uji Terima Pengaturan Resto (Bahasa Manusia)

> **Status:** AKTIF (Tugas T9-12 / Gelombang 1)  
> **Sasaran Pengguna:** Lee (Owner / Pemilik Resto) dan Penguji Non-Teknis  
> **Rujukan:** `docs/ROADMAP.md` (T9-12), `docs/AGENT_OPERATING_GUIDE.md` §5 butir 6, `docs/PRD.md` M2/M11  
> **Prinsip Utama:** Ditulis dari sudut pandang pemilik kedai dalam bahasa Indonesia yang sederhana tanpa istilah teknis yang rumit. Pemilik dapat menguji sendiri bahwa seluruh fitur kendali restoran bekerja sempurna langsung dari layar tanpa perlu mengetik perintah komputer.

---

## Panduan Singkat untuk Lee

Halo Lee, berkas ini adalah **lembar uji terima mandiri** untuk memastikan seluruh fitur pengaturan restoran di Resto Barokah bekerja sesuai kebutuhan operasional kedai sehari-hari.

### Cara Menggunakan Dokumen Ini:
1. **Tidak perlu buka terminal:** Cukup buka aplikasi di peramban (browser) laptop atau ponsel.
2. **Masuk sebagai Pemilik (Owner):** Gunakan akun Owner untuk membuka menu **Pengaturan Resto**.
3. **Ikuti 12 Skenario Berurutan:** Setiap skenario memiliki maksimal 5 langkah mudah.
4. **Periksa Hasilnya:** Cocokkan apa yang tampil di layar dengan kolom **Hasil yang Seharusnya Terjadi**.
5. **Beri Tanda:** Centang kotak `[x]` pada tabel ringkasan di bagian akhir dokumen ini bila hasilnya cocok.

---

## Daftar 12 Skenario Uji Terima Pengaturan

---

### Skenario 01: Mengubah Nama Kedai & Slogan (Identitas Resto)
*Menguji kemudahan pemilik memperbarui nama merek kedai kapan saja.*

- **Mengapa ini penting:** Pemilik bebas meremajakan nama kedai, slogan promosi, atau nomor telepon resmi tanpa perlu bantuan teknisi.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Masuk ke aplikasi, lalu buka menu **Pengaturan Resto** → pilih tab **Identitas**.
  2. Ubah kolom **Nama Restoran** (misalnya menjadi `Kedai Barokah Kopi & Grill`) dan isi **Slogan/Tagline** (misalnya `Hangat, Gurih, Penuh Berkah`).
  3. Tekan tombol **Simpan Identitas Resto**.
  4. Buka halaman **Katalog Publik Pelanggan** (tanpa login atau di tab baru).
  5. Buka layar kasir atau cetak contoh struk belanja.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Pesan hijau *"Pengaturan identitas berhasil disimpan"* muncul di layar.
  - Halaman katalog publik pelanggan langsung memuat nama dan slogan baru tersebut.
  - Kop bagian paling atas pada struk kasir otomatis menampilkan nama resto yang baru.
- **Tanda Masalah (❌ Gagal):**
  - Nama resto kembali ke nama lama setelah halaman dimuat ulang.
  - Muncul pesan kesalahan bahasa Inggris atau kode teknis yang tidak jelas.

---

### Skenario 02: Memasang Foto Logo & Banner Resto
*Menguji pemasangan foto merek kedai dan perlindungan ukuran berkas foto.*

- **Mengapa ini penting:** Tampilan kedai terlihat profesional dengan foto logo asli, sekaligus melindungi kuota dan memori HP agar tidak lemot akibat foto raksasa.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Pada menu **Pengaturan Resto** → tab **Identitas**, cari bagian **Logo Restoran**.
  2. Tekan tombol **Pilih Foto Logo**, pilih berkas gambar berformat JPG, PNG, atau WebP ukuran wajar (di bawah 2 MB).
  3. Perhatikan kotak pratinjau gambar di layar, lalu tekan **Simpan Identitas Resto**.
  4. Coba pilih berkas gambar yang sengaja berukuran sangat besar (di atas 2 MB) atau berkas non-gambar (misal berkas dokumen PDF).
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Foto logo wajar berhasil terunggah dan tampil proporsional tanpa pecah di pratinjau katalog publik.
  - Saat mencoba mengunggah foto > 2 MB, sistem menolak ramah dengan peringatan *"Ukuran berkas logo maksimal 2 MB agar aplikasi kasir tetap ringan"*.
- **Tanda Masalah (❌ Gagal):**
  - Gambar tidak tampil atau kotak logo menjadi kosong.
  - Berkas dokumen PDF atau berkas raksasa lolos tersimpan sehingga aplikasi menjadi berat.

---

### Skenario 03: Mengganti Tema Suasana Kedai & Kerapatan Tampilan
*Menguji penyesuaian 10 tema warna visual merek kedai dan pilihan tata letak nyaman/padat.*

- **Mengapa ini penting:** Suasana visual kasir dan katalog publik dapat disesuaikan dengan konsep kedai (kedai kopi hangat, resto panggangan bara, kedai santai alam, atau kafe vintage klasik).
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Tema & Tampilan**.
  2. Pilih salah satu dari 10 tema visual yang disediakan (misalnya tema `Bara Panggang` atau `Hangat Kedai`).
  3. Coba pilih kerapatan tampilan antara mode **Nyaman** (ruang tombol lega) dan mode **Padat** (muat lebih banyak menu di layar tablet kasir).
  4. Tekan tombol **Simpan Pilihan Tema**.
  5. Buka layar kasir dan periksa warna tombol serta keterbacaan teks.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Seluruh warna aksen tombol, kartu menu, dan latar belakang berganti serasi seketika tanpa perlu muat ulang browser.
  - Teks tetap hitam/putih tajam dengan kontras yang nyaman di mata (memenuhi standar keterbacaan WCAG).
  - Mode padat merapatkan susunan daftar tanpa membuat jari salah memencet tombol.
- **Tanda Masalah (❌ Gagal):**
  - Warna tulisan bertabrakan dengan warna latar sehingga tulisan susah dibaca.
  - Pilihan tema kembali ke setelan awal setelah berpindah menu.

---

### Skenario 04: Mengubah Tarif Pajak Resto (PB1) & Biaya Layanan
*Menguji perhitungan otomatis pajak daerah dan biaya servis pada transaksi baru.*

- **Mengapa ini penting:** Menyesuaikan aturan perpajakan daerah kedai (PB1 10% atau 11%) dan biaya layanan kedai secara transparan tanpa salah hitung.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Operasional**.
  2. Pada kolom **Pajak PB1**, masukkan angka persentase (misalnya `11%`).
  3. Pada kolom **Service Charge**, masukkan angka (misalnya `5%`).
  4. Perhatikan **Simulasi Struk Kasir** di samping formulir; periksa apakah angka pajak dan servis terhitung otomatis.
  5. Tekan **Simpan Pengaturan Operasional**, lalu buat satu pesanan baru di layar kasir.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Simulasi struk di layar pengaturan dan pesanan baru di kasir otomatis menghitung PB1 11% dan Service 5% dari subtotal belanja.
  - Transaksi lama yang sudah lunas kemarin **tetap utuh** dan tidak terpengaruh tarif baru ini (bebas dari risiko kekacauan pembukuan).
- **Tanda Masalah (❌ Gagal):**
  - Angka pajak tidak muncul di struk baru.
  - Persentase negatif (misal -5%) atau di atas 100% bisa tersimpan tanpa ditegur sistem.

---

### Skenario 05: Mengatur Pembulatan Kembalian & Ucapan Kaki Struk
*Menguji pembulatan nominal tagihan kasir dan pencetakan pesan ramah pelanggan.*

- **Mengapa ini penting:** Kasir tidak perlu pusing mencari uang koin receh Rp 50/Rp 100 saat transaksi tunai, dan struk bisa memuat doa berkah atau akun media sosial kedai.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → tab **Operasional**.
  2. Pada pilihan **Aturan Pembulatan Tagihan**, pilih opsi `Ke Rp 500 terdekat` (atau `Ke Rp 1.000`).
  3. Pada kolom **Pesan Kaki Struk (Footer)**, ketik: `Terima kasih atas kunjungannya. Semoga berkah selalu! IG: @kedaibarokah`.
  4. Tekan tombol **Simpan Pengaturan Operasional**.
  5. Masuk ke layar Kasir, pilih menu dengan total ganjil (misalnya Rp 23.350), lalu cetak/lihat struk.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Total tagihan di kasir otomatis dibulatkan sesuai aturan (misal Rp 23.350 menjadi Rp 23.500) dengan baris keterangan pembulatan yang jelas.
  - Kalimat ucapan dan akun Instagram tercetak rapi di bagian paling bawah struk kasir.
- **Tanda Masalah (❌ Gagal):**
  - Pembulatan salah hitung atau total akhir tidak mencerminkan pembulatan.
  - Ucapan kaki struk terpotong atau tidak tercetak.

---

### Skenario 06: Menambah Kategori & Menu Baru Lengkap Varian
*Menguji penambahan hidangan baru kedai beserta varian rasa/porsi dan foto makanan.*

- **Mengapa ini penting:** Pemilik dapat meluncurkan menu baru atau promo musiman seketika agar kasir bisa langsung menjualnya hari itu juga.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Menu & Kategori**.
  2. Tekan tombol **Tambah Kategori**, beri nama `Cemilan Sore` dan simpan.
  3. Tekan tombol **Tambah Menu Baru**, isi nama `Roti Bakar Barokah`, pilih kategori `Cemilan Sore`, dan tentukan harga Rp 15.000.
  4. Tambahkan pilihan varian: `Cokelat Keju` (+Rp 3.000) dan `Original` (+Rp 0).
  5. Tekan **Simpan Menu**, kemudian buka layar **Kasir**.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Kategori `Cemilan Sore` dan menu `Roti Bakar Barokah` langsung muncul di katalog layar kasir.
  - Saat kasir mengetuk menu tersebut, jendela pilihan varian muncul dan total harga bertambah otomatis saat opsi Cokelat Keju dipilih.
- **Tanda Masalah (❌ Gagal):**
  - Menu baru tidak muncul di kasir meski sudah disimpan.
  - Kasir tidak bisa memilih varian atau harga tambahan varian tidak terhitung.

---

### Skenario 07: Menyembunyikan Menu di Cabang Tertentu
*Menguji pengaturan ketersediaan hidangan yang berbeda antar cabang kedai.*

- **Mengapa ini penting:** Jika Cabang A kehabisan bahan khusus atau tidak memiliki oven panggangan, menu tersebut bisa disembunyikan di Cabang A saja tanpa mengganggu Cabang B.
- **Peran:** `Owner / Admin Cabang`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Menu Per Cabang**.
  2. Pilih lokasi **Cabang A (Pusat)**. Cari menu `Ikan Gurame Bakar`.
  3. Geser sakelar visibilitas menjadi **Sembunyikan di Cabang Ini**, lalu simpan.
  4. Buka layar kasir dengan lokasi terpilih **Cabang A**; cari menu `Ikan Gurame Bakar`.
  5. Ganti lokasi kasir ke **Cabang B**; cari menu yang sama.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Di Cabang A: menu `Ikan Gurame Bakar` tidak muncul di katalog kasir dan tidak bisa dipesan.
  - Di Cabang B: menu tetap muncul normal dan bisa dijual seperti biasa.
- **Tanda Masalah (❌ Gagal):**
  - Menu malah ikut tersembunyi di seluruh cabang kedai.
  - Menu yang disembunyikan masih bisa dicari atau dimasukkan ke keranjang kasir di Cabang A.

---

### Skenario 08: Menentukan Harga Menu Berbeda Antar Cabang
*Menguji fleksibilitas harga hidangan untuk cabang mall vs cabang pinggir jalan.*

- **Mengapa ini penting:** Biaya sewa tempat di mall lebih tinggi daripada ruko, sehingga pemilik dapat menaikkan harga khusus di cabang mall tanpa mengubah harga pusat.
- **Peran:** `Owner / Admin Cabang`
- **Langkah Pengujian:**
  1. Masuk ke tab **Menu Per Cabang**.
  2. Pilih **Cabang Mall**, cari menu `Ayam Goreng Spesial` (harga pusat Rp 25.000).
  3. Masukkan harga khusus cabang: `Rp 28.000`, lalu tekan **Simpan Perubahan Cabang**.
  4. Buka kasir dengan lokasi **Cabang Mall**, masukkan `Ayam Goreng Spesial` ke pesanan.
  5. Buka kasir dengan lokasi **Cabang Ruko**, masukkan menu yang sama ke pesanan.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Kasir di Cabang Mall mencatat harga Rp 28.000 dan struk tercetak Rp 28.000.
  - Kasir di Cabang Ruko tetap mencatat harga Rp 25.000.
  - Pada layar pengaturan cabang, indikator selisih `(+Rp 3.000)` tampak jelas memberi tahu pemilik.
- **Tanda Masalah (❌ Gagal):**
  - Harga di Cabang Ruko ikut berubah menjadi Rp 28.000.
  - Kasir di Cabang Mall tetap menagih harga lama Rp 25.000.

---

### Skenario 09: Mengatur Tata Letak Meja, Area, & Unduh Kode QR
*Menguji penataan denah meja kedai dan pencetakan stand akrilik QR untuk pelanggan.*

- **Mengapa ini penting:** Meja tertata rapi sesuai area (Indoor AC, Lantai 2, Outdoor Santai), dan pemilik bisa langsung mencetak stand nomor meja dengan kode QR siap pakai.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Meja & Area**.
  2. Tekan tombol **Tambah Meja**, ketik nama meja `Meja 12` dan pilih area `Outdoor Lantai 2`.
  3. Tekan tombol **Simpan Meja**.
  4. Pada baris Meja 12, tekan tombol **Lihat / Unduh Kode QR**.
  5. Buka layar kasir, lalu periksa daftar tombol pemilih meja saat menyusun pesanan baru.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Jendela pratinjau stand akrilik meja terbuka rapi menampilkan nomor Meja 12 dan kode QR yang bisa disalin atau dicetak.
  - Di layar kasir, Meja 12 langsung tersedia di bawah kelompok area `Outdoor Lantai 2`.
  - Meja yang sedang dipakai tamu makan tidak bisa dinonaktifkan sembarangan.
- **Tanda Masalah (❌ Gagal):**
  - Gambar kode QR tidak muncul atau nomor meja salah.
  - Meja baru tidak ditemukan oleh kasir saat memilih meja.

---

### Skenario 10: Menambah Pegawai, Batas Diskon Kasir, & Reset PIN
*Menguji keamanan akun staf, pembatasan wewenang diskon kasir, dan reset PIN cepat.*

- **Mengapa ini penting:** Staf baru bisa langsung didaftarkan dengan hak akses aman; kasir hanya boleh memberi diskon wajar tanpa bisa membobol pembukuan kedai; atasan bisa mereset PIN staf yang lupa tanpa ribet.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Kelola Pegawai**.
  2. Tekan **Tambah Pegawai Baru**, isi nama staf `Budi Santoso`, peran `Kasir`, cabang tugas, dan PIN awal 6 digit `147258`.
  3. Pada menu **Atur Izin**, beri centang izin `Beri Diskon`, namun pasang batas maksimal: `Rp 20.000` (atau 10%).
  4. Keluar dari akun Owner, lalu masuk kembali menggunakan PIN kasir baru `147258`.
  5. Coba berikan diskon Rp 15.000 (di bawah batas) lalu coba diskon Rp 30.000 (melebihi batas wewenang).
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Kasir Budi berhasil masuk dengan PIN 6 digit barunya.
  - Diskon Rp 15.000 langsung diterima sistem.
  - Diskon Rp 30.000 meminta otorisasi/PIN atasan dan menolak kasir melanjutkan tanpa persetujuan.
  - Pemilik sewaktu-waktu bisa menekan tombol **Reset PIN** untuk staf tersebut tanpa perlu tahu PIN lamanya.
- **Tanda Masalah (❌ Gagal):**
  - Kasir bisa memberi diskon Rp 50.000 tanpa izin atasan.
  - Kasir baru bisa membuka menu Pengaturan Resto pemilik.

---

### Skenario 11: Mengaktifkan Metode Bayar & Aturan Tip Pelanggan
*Menguji pilihan cara bayar yang diterima kasir serta fasilitas tip sukarela.*

- **Mengapa ini penting:** Kedai bisa memilih hanya menerima metode bayar yang siap (misal QRIS dan Tunai saja), dan pelanggan yang puas bisa memberikan tip sukarela bagi staf.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka menu **Pengaturan Resto** → pilih tab **Metode Pembayaran**.
  2. Pastikan metode `Tunai` dan `QRIS Barokah` berstatus aktif, matikan metode yang belum dipakai (misal `Kartu Debit`).
  3. Pada bagian **Aturan Tip Sukarela**, geser sakelar ke posisi **Izinkan Tip**, dan pilih model nominal cepat (misal `Rp 2.000`, `Rp 5.000`, `Rp 10.000`).
  4. Tekan **Simpan Pengaturan Pembayaran**.
  5. Buka layar kasir, susun pesanan dan tekan tombol **Bayar**.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Di layar pembayaran kasir, hanya muncul tombol `Tunai` dan `QRIS`; tombol metode nonaktif tidak muncul.
  - Kotak pilihan tip sukarela muncul di kasir; jika dipilih, tip ditambahkan ke total akhir dan tercatat transparan di struk kasir.
  - Sistem menolak jika pemilik tidak sengaja mematikan seluruh metode bayar (minimal 1 cara bayar wajib tetap aktif).
- **Tanda Masalah (❌ Gagal):**
  - Metode bayar yang sudah dinonaktifkan masih muncul di kasir.
  - Semua metode bayar bisa dinonaktifkan sekaligus sehingga kasir tidak bisa melayani pembayaran.

---

### Skenario 12: Pratinjau Perubahan & Pengaman Riwayat Masa Lalu (Kekal)
*Menguji peninjauan perbedaan pengaturan sebelum disimpan dan jaminan pembukuan lama kebal manipulasi.*

- **Mengapa ini penting:** Pemilik dapat melihat simulasi dampak perubahan sebelum memutuskan menyimpan ke sistem, dan memiliki jaminan pasti bahwa laporan keuntungan serta struk belanja bulan lalu tidak akan berubah sepeser pun.
- **Peran:** `Owner / Pengelola`
- **Langkah Pengujian:**
  1. Buka laporan penjualan atau riwayat struk lunas kemarin, catat salah satu transaksi (misalnya: Total `Rp 44.000`, Pajak PB1 `Rp 4.000`).
  2. Buka **Pengaturan Resto**, lakukan perubahan besar: ganti nama kedai, ganti tema warna, naikkan pajak PB1 menjadi `12%`, dan naikkan harga menu.
  3. Buka tab **Pratinjau Perubahan (Diff Viewer)**: periksa tabel perbandingan nilai lama vs nilai usulan baru, serta bandingkan dua lembar struk simulasi (Sebelum vs Sesudah).
  4. Tekan tombol **Simpan & Terapkan Pengaturan**.
  5. Buka kembali riwayat pesanan kemarin dan Laporan Penjualan kemarin.
- **Hasil yang Seharusnya Terjadi (✅ Berhasil):**
  - Tab Pratinjau menyajikan perbedaan dengan jelas lengkap dengan selisih tagihan pelanggan (misal: `+Rp 4.500 (+10,2%)`).
  - Setelah perubahan disimpan, nota belanja kemarin dan laporan keuntungan kemarin **TETAP SAMA PERSIS** (Total tetap Rp 44.000, Pajak tetap Rp 4.000; selisih perubahan = Rp 0).
  - Pesanan baru berikutnya yang dibuat kasir otomatis mengikuti nama, warna, dan tarif baru.
- **Tanda Masalah (❌ Gagal):**
  - Angka laporan penjualan kemarin ikut berubah atau nominal struk kemarin berubah sendiri.
  - Tab pratinjau tidak menampilkan perbandingan sebelum vs sesudah.

---

## Lembar Ceklis Uji Terima Pemilik (Lee)

Gunakan tabel ini untuk mencatat hasil pengujian yang telah dicoba:

| No | Skenario Pengaturan | Cara Singkat | Hasil Uji (LULUS / GAGAL) | Catatan Pemilik |
|:--:|---|---|:---:|---|
| 01 | **Identitas Resto** | Ubah nama kedai → Cek katalog publik & kop struk kasir | `[ ] LULUS` | |
| 02 | **Logo & Banner** | Pasang logo < 2 MB & coba cegah berkas raksasa > 2 MB | `[ ] LULUS` | |
| 03 | **Tema & Kerapatan** | Pilih 1 dari 10 tema visual & coba mode padat/nyaman | `[ ] LULUS` | |
| 04 | **Pajak PB1 & Service** | Atur tarif persentase → Periksa struk pesanan baru kasir | `[ ] LULUS` | |
| 05 | **Pembulatan & Ucapan** | Pilih pembulatan Rp 500 & isi footer struk berkah | `[ ] LULUS` | |
| 06 | **Menu & Varian Baru** | Buat menu lengkap varian porsi/rasa → Coba di kasir | `[ ] LULUS` | |
| 07 | **Sembunyikan Menu** | Nonaktifkan menu di Cabang A → Pastikan Cabang B tetap ada | `[ ] LULUS` | |
| 08 | **Harga Cabang Khusus** | Pasang harga mall lebih tinggi → Kasir ruko tetap harga pusat | `[ ] LULUS` | |
| 09 | **Meja & Kode QR** | Tambah meja di area lantai 2 → Unduh stand akrilik QR | `[ ] LULUS` | |
| 10 | **Pegawai, Izin, & PIN** | Tambah kasir baru, batasi diskon, & uji coba login PIN | `[ ] LULUS` | |
| 11 | **Metode Bayar & Tip** | Aktifkan QRIS/Tunai & aktifkan kotak tip sukarela di kasir | `[ ] LULUS` | |
| 12 | **Pratinjau & Pengaman** | Cek simulator diff sebelum simpan & buktikan riwayat lama utuh | `[ ] LULUS` | |

---

## Apa yang Harus Dilakukan Bila Ada Hal yang Tidak Sesuai?

Jika saat menguji ada langkah yang tidak sesuai atau membingungkan:
1. **Tidak perlu panik:** Sistem dilengkapi pengaman otomatis sehingga data transaksi dan riwayat kedai Anda tidak akan rusak.
2. **Kirim pesan ke Agent di chat:** Cukup salin kalimat sederhana berikut:
   > *"Lee: Saya mencoba Skenario [Nomor], hasilnya [jelaskan apa yang terjadi di layar]. Tolong dicek."*
3. Agent akan langsung menindaklanjuti, memperbaiki kode yang bermasalah, dan memastikan pengujian lulus 100%.

---
*Dokumen ini merupakan bagian dari sistem jaminan kualitas Resto Barokah. Dibuat agar pemilik kedai memiliki kendali penuh dan rasa tenang dalam menjalankan usahanya.*
