# NASKAH_JALAN.md — Naskah Jalan Pemilik (Uji Coba Langkah demi Langkah)

> **Status: AKTIF (Fase 1C — T1-35)**  
> **Rujukan:** `docs/SPESIFIKASI_UI.md` §7, `docs/PRD.md`, `docs/PETA_UI.md`  
> **Tujuan:** Menjadi panduan pengujian manusia (Lee / pemilik) yang dapat dijalankan langsung di pratinjau aplikasi. Setiap fitur dan tombol memiliki skenario langkah demi langkah yang jelas, apa yang harus muncul, dan apa yang dilarang keras terjadi.

---

## 1. Aturan Penulisan & Pelaksanaan

1. **Penomoran:** Menggunakan pola `W-<fase>-<nomor>` (misalnya `W-3-04` untuk alur pembayaran kasir pada Fase 3).
2. **Data Uji:** Seluruh naskah dijalankan dengan data awal terstandarisasi (`DATA_CONTOH` / seed uji).
3. **Penyelesaian Tugas:** Tugas antarmuka di `docs/ROADMAP.md` hanya boleh ditandai selesai `[x]` setelah naskah terkait dibuktikan berhasil dijalankan.
4. **Prinsip Kejujuran:** Jika ada langkah yang tidak sesuai antara naskah dan tampilan di layar, hal tersebut merupakan **cacat** yang wajib diperbaiki, bukan naskahnya yang dihilangkan.

---

## 2. Daftar Naskah Jalan Antarmuka (G1)

---

### `W-0-01` · Layar Bukti Contoh: Tema, Kerapatan, dan Komponen
- **Layar:** `contoh` (`/contoh`)
- **Peran:** Semua peran (`owner_pusat`, `kasir`, dll.)
- **Prasyarat:** Membuka aplikasi pratinjau di peramban.
- **Langkah-langkah:**
  1. Buka rute `/contoh`.
  2. Buka pemilih tema, pilih tema "Bara" atau "Hijau Daun". Perhatikan palet warna berubah seketika tanpa memuat ulang halaman.
  3. Tekan pemilih kerapatan "Padat". Perhatikan jarak baris dan komponen merapat dengan rapi namun target sentuh tetap nyaman (≥44 px).
  4. Tekan tombol "Tutup pemberitahuan" pada Toast di bagian atas.
- **Hasil yang HARUS muncul:**
  - Tema dan kerapatan berubah seketika.
  - Toast menghilang saat tombol tutup ditekan, dan muncul kembali saat tombol "Tampilkan pemberitahuan lagi" ditekan.
- **Harus TIDAK terjadi:**
  - Halaman berkedip atau memuat ulang secara penuh (*full page reload*).
  - Teks terpotong atau huruf mengecil di bawah batas nyaman baca (14 px).

---

### `W-1-01` · Layar Masuk: Verifikasi PIN & Masuk Bertugas
- **Layar:** `masuk` (`/masuk`)
- **Peran:** Semua staf resto (`owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur`)
- **Prasyarat:** Perangkat sudah terdaftar di cabang.
- **Langkah-langkah:**
  1. Buka layar masuk `/masuk`.
  2. Pilih profil kasir "Budi (Kasir)".
  3. Masukkan 6 digit PIN kasir yang sah pada papan angka.
  4. Tekan tombol `TombolAksi` "Masuk".
- **Hasil yang HARUS muncul:**
  - Tombol menampilkan status "Memproses..." sesaat.
  - Muncul pesan sukses "Selamat bertugas! Sesi masuk aktif."
  - Aplikasi otomatis berpindah ke layar utama kasir `/kasir`.
- **Harus TIDAK terjadi:**
  - PIN ditampilkan dalam bentuk teks biasa (wajib bertopeng titik/bintang).
  - Bisa masuk tanpa verifikasi PIN atau menggunakan PIN kosong.

---

### `W-1-02` · Layar Masuk: Penolakan PIN Salah & Batas Percobaan
- **Layar:** `masuk` (`/masuk`)
- **Peran:** Semua staf
- **Prasyarat:** Layar masuk aktif.
- **Langkah-langkah:**
  1. Pilih nama pegawai.
  2. Masukkan PIN yang salah (misalnya `999999`).
  3. Tekan "Masuk".
- **Hasil yang HARUS muncul:**
  - Tombol kembali aktif.
  - Muncul pesan kesalahan "PIN salah atau perangkat belum terdaftar (AU-101)."
  - Kolom isian PIN otomatis dikosongkan untuk percobaan berikutnya.
- **Harus TIDAK terjadi:**
  - Sesi masuk terbuka meski PIN salah.
  - Aplikasi macet atau layar putih (*crash*).

---

### `W-3-01` · Kasir: Buka Shift Kasir & Saldo Awal Kas
- **Layar:** `kasir` (`/kasir`)
- **Peran:** `kasir`, `admin_cabang`, `owner_pusat`
- **Prasyarat:** Sesi kasir baru masuk, belum ada shift aktif.
- **Langkah-langkah:**
  1. Masuk ke layar kasir `/kasir`.
  2. Muncul dialog buka shift: isi saldo awal modal laci kasir (mis. Rp 200.000).
  3. Tekan `TombolAksi` "Buka Shift".
- **Hasil yang HARUS muncul:**
  - Muncul pesan "Shift kasir dibuka."
  - Laci kasir siap transaksi dan daftar katalog menu aktif.
- **Harus TIDAK terjadi:**
  - Bisa membuka transaksi kasir tanpa mengisi saldo modal awal.

---

### `W-3-02` · Kasir: Pencatatan Pesanan, Keranjang, dan Void Pra-Dapur
- **Layar:** `kasir` (`/kasir`)
- **Peran:** `kasir`, `admin_cabang`, `owner_pusat`
- **Prasyarat:** Shift kasir telah dibuka.
- **Langkah-langkah:**
  1. Pilih nomor meja (mis. "Meja 02").
  2. Tekan item "Nasi Goreng Kampung" -> masuk ke daftar keranjang belanja.
  3. Tekan tombol "+" ("Tambah Item") untuk menambah porsi menjadi 2.
  4. Tekan tombol "-" ("Kurangi Item") untuk mengurangi porsi kembali ke 1.
  5. Tekan tombol "Batalkan Item" pada salah satu baris pesanan.
  6. Muncul konfirmasi "Batalkan item pesanan ini?", pilih "OK".
- **Hasil yang HARUS muncul:**
  - Subtotal dan total dihitung otomatis oleh peladen.
  - Item pesanan yang dibatalkan terhapus dari daftar aktif dengan catatan audit.
- **Harus TIDAK terjadi:**
  - Item terhapus tanpa ada dialog konfirmasi.
  - Total transaksi dihitung salah atau berbeda dengan tarif katalog.

---

### `W-3-03` · Kasir: Pemberian Diskon Transaksi & Pembatasan Izin
- **Layar:** `kasir` (`/kasir`)
- **Peran:** `kasir` (memiliki izin `beri_diskon`)
- **Prasyarat:** Keranjang pesanan terisi minimal 1 item.
- **Langkah-langkah:**
  1. Tekan tombol "Beri Diskon".
  2. Pilih jenis diskon (nominal atau persen, mis. 10%).
  3. Konfirmasi penerapan diskon.
- **Hasil yang HARUS muncul:**
  - Baris potongan diskon muncul di bawah subtotal.
  - Pajak PB1 dan service dihitung ulang berdasarkan subtotal setelah diskon.
  - Total tagihan berkurang sesuai aturan uang.
- **Harus TIDAK terjadi:**
  - Kasir tanpa izin `beri_diskon` dapat menekan tombol diskon (tombol wajib nonaktif / terkunci).
  - Pajak dihitung dari nilai kotor sebelum diskon (melanggar aturan PB1).

---

### `W-3-04` · Kasir: Pembayaran Tunai & Cetak Struk Pelanggan
- **Layar:** `kasir` (`/kasir`)
- **Peran:** `kasir`, `admin_cabang`, `owner_pusat`
- **Prasyarat:** Pesanan terisi dengan total tagihan mis. Rp 57.000.
- **Langkah-langkah:**
  1. Tekan tombol "Bayar Pesanan".
  2. Pilih metode "Tunai", masukkan nominal uang diterima Rp 100.000.
  3. Perhatikan kolom kembalian menampilkan Rp 43.000.
  4. Tekan "Selesaikan Pembayaran".
- **Hasil yang HARUS muncul:**
  - Status pesanan berubah menjadi `lunas`.
  - Muncul pesan "Pembayaran diterima dan pesanan ditutup lunas."
  - Dialog cetak struk muncul secara otomatis.
- **Harus TIDAK terjadi:**
  - Uang kembalian bernilai negatif atau salah hitung.
  - Pesanan yang sudah `lunas` dapat diubah atau ditambah item lagi (status pesanan wajib beku).

---

### `W-3-05` · Kasir: Tutup Shift Kasir & Rekonsiliasi Kas Harian
- **Layar:** `kasir` (`/kasir`)
- **Peran:** `kasir` (dengan izin `tutup_kas`), `admin_cabang`, `owner_pusat`
- **Prasyarat:** Seluruh transaksi meja aktif sudah diselesaikan/ditutup.
- **Langkah-langkah:**
  1. Tekan tombol "Tutup Shift" di pojok atas layar kasir.
  2. Masukkan jumlah uang tunai fisik yang ada di laci kasir.
  3. Tekan konfirmasi penutupan shift.
- **Hasil yang HARUS muncul:**
  - Muncul ringkasan rekonsiliasi kas (saldo awal, total penjualan tunai, selisih fisik).
  - Muncul pesan "Shift kasir berhasil ditutup."
  - Layar terkunci dan kembali ke layar masuk.
- **Harus TIDAK terjadi:**
  - Shift ditutup oleh staf yang tidak memiliki izin `tutup_kas`.

---

### `W-4-01` · Layar Dapur: Penerimaan Tiket & Mulai Memasak
- **Layar:** `dapur` (`/dapur`)
- **Peran:** `dapur`, `kasir`, `admin_cabang`, `owner_pusat`
- **Prasyarat:** Kasir telah mengirim pesanan baru ke dapur.
- **Langkah-langkah:**
  1. Buka layar `/dapur`.
  2. Terlihat kartu pesanan tiket masuk dengan status "Baru".
  3. Tekan `TombolAksi` "Mulai Masak" pada kartu pesanan tersebut.
- **Hasil yang HARUS muncul:**
  - Kartu pesanan berpindah ke kolom "Sedang Dimasak" dengan penanda waktu berjalan.
  - Pesanan di layar kasir ikut terbarui statusnya secara *real-time*.
- **Harus TIDAK terjadi:**
  - Kartu pesanan hilang dari layar dapur sebelum diselesaikan.

---

### `W-4-02` · Layar Dapur: Siap Saji & Penanda Menu Habis
- **Layar:** `dapur` (`/dapur`)
- **Peran:** `dapur` (dengan izin `ubah_stok`), `admin_cabang`, `owner_pusat`
- **Prasyarat:** Pesanan selesai dimasak.
- **Langkah-langkah:**
  1. Tekan tombol "Siap Saji" pada kartu pesanan yang sudah selesai.
  2. Buka panel cepat ketersediaan menu di bilah samping dapur.
  3. Tekan tombol "Tandai Habis" pada item "Jus Alpukat".
- **Hasil yang HARUS muncul:**
  - Pesanan berpindah ke status siap saji untuk diantar pelayan.
  - Menu "Jus Alpukat" langsung berstatus habis di layar kasir dan menu digital publik.
- **Harus TIDAK terjadi:**
  - Staf dapur tanpa izin `ubah_stok` dapat mengubah ketersediaan menu.

---

### `W-5-01` · Layar Laporan: Filter Penjualan & Ekspor Ringkasan
- **Layar:** `laporan` (`/laporan`)
- **Peran:** `owner_pusat`, `admin_cabang` (dengan izin `lihat_laporan`)
- **Prasyarat:** Telah ada riwayat transaksi penjualan lunas.
- **Langkah-langkah:**
  1. Buka rute `/laporan`.
  2. Pilih rentang tanggal transaksi (mis. "Hari Ini" atau "7 Hari Terakhir").
  3. Tekan tombol "Filter Tanggal".
  4. Tekan tombol "Ekspor Ringkasan".
- **Hasil yang HARUS muncul:**
  - Tabel ringkasan menampilkan total omset, jumlah transaksi, rincian metode bayar (Tunai, QRIS, Kartu), pajak PB1, dan service.
  - Berkas ringkasan berhasil diunduh.
- **Harus TIDAK terjadi:**
  - Peran `kasir` atau `pelayan` dapat mengakses layar ini (wajib ditolak dengan keadaan tanpa akses).

---

### `W-6-01` · Pengaturan Resto: Tarif Pajak PB1, Service, dan Penambahan Meja
- **Layar:** `pengaturan` (`/pengaturan`)
- **Peran:** `owner_pusat` (dengan izin `atur_pengaturan`)
- **Prasyarat:** Sesi pemilik pusat aktif.
- **Langkah-langkah:**
  1. Buka rute `/pengaturan`.
  2. Masuk ke tab "Keuangan & Pajak".
  3. Ubah tarif pajak PB1 menjadi 10% dan service charge menjadi 5%.
  4. Tekan "Simpan Pajak & Service".
  5. Masuk ke tab "Tata Letak Meja", tekan "Tambah Meja", isi nomor "Meja 10", lalu simpan.
- **Hasil yang HARUS muncul:**
  - Muncul dialog konfirmasi perubahan tarif.
  - Pengaturan tersimpan dan tercatat di rantai `catatan_audit`.
  - Meja 10 langsung muncul di daftar meja kasir.
- **Harus TIDAK terjadi:**
  - Perubahan disimpan tanpa dialog konfirmasi atau tanpa izin pemilik pusat.

---

### `W-8-01` · Voucher: Pengecekan Kode & Klaim Diskon Transaksi
- **Layar:** `voucher` (`/voucher`)
- **Peran:** `kasir`, `admin_cabang`, `owner_pusat`
- **Prasyarat:** Transaksi kasir sedang aktif.
- **Langkah-langkah:**
  1. Buka panel voucher dari layar kasir.
  2. Masukkan kode voucher pelanggan (mis. `DISKONHEMAT20`).
  3. Tekan "Periksa Voucher".
  4. Setelah voucher terbukti valid, tekan `TombolAksi` "Terapkan Voucher".
- **Hasil yang HARUS muncul:**
  - Muncul keterangan nominal diskon voucher.
  - Diskon diterapkan ke tagihan dan voucher ditandai telah terpakai.
- **Harus TIDAK terjadi:**
  - Voucher yang sudah terpakai (*redeemed*) dapat diklaim ulang kedua kalinya.

---

### `W-10-01` · Layar Menu Digital Pelanggan (Publik)
- **Layar:** `pelanggan-publik` (`/menu`)
- **Peran:** Publik / Pelanggan (`pelanggan`)
- **Prasyarat:** Pelanggan memindai QR meja di ponsel mereka.
- **Langkah-langkah:**
  1. Buka tautan `/menu` di peramban ponsel.
  2. Pilih kategori "Makanan" -> katalog menyaring hanya menampilkan makanan.
  3. Ketik "Ayam" pada kolom pencarian -> menampilkan menu "Ayam Bakar Madu".
  4. Menu yang bertanda "Habis" menampilkan lencana nonaktif dan tidak bisa dipesan.
- **Hasil yang HARUS muncul:**
  - Katalog tampil cepat, bersih, ramah layar sentuh ponsel.
  - Tidak ada tombol staf (tidak ada tombol kasir, pengaturan, atau laporan).
- **Harus TIDAK terjadi:**
  - Pelanggan diminta PIN atau dapat mengakses data keuangan resto.
