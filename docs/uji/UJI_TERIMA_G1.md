# LEMBAR UJI TERIMA RESMI GELOMBANG 1 (G1)
# Resto Barokah — Sistem Operasional Restoran & Kasir Pintar Multi-Tenant

> **Dokumen Resmi Uji Terima (T11-02 — PRD §3 / AGENT_OPERATING_GUIDE §5)**  
> Disusun untuk diuji langsung oleh Pemilik Platform / Pemilik Kedai (**Lee**) bersama tim sebelum sistem resmi digunakan harian di kedai nyata (Gelombang 1 / Kedai Oasis).

---

## 1. Identitas Pengujian

| Informasi | Keterangan |
|---|---|
| **Nama Penguji / Pemilik** | Lee (Pemilik Platform Resto Barokah) |
| **Nama Kedai / Cabang** | Kedai Oasis (Cabang Percontohan G1) |
| **Tanggal Pengujian** | ............................................................ |
| **Perangkat yang Digunakan** | [ ] Tablet Kasir &nbsp;&nbsp; [ ] Laptop / PC &nbsp;&nbsp; [ ] HP / Ponsel |
| **Versi Rilis Aplikasi** | Gelombang 1 (G1 — Penutup Fase 0 s/d 11) |
| **Hasil Akhir Evaluasi** | [ ] **LULUS PENUH (SIAP PAKAI)** &nbsp;&nbsp; [ ] **LULUS BERSYARAT** &nbsp;&nbsp; [ ] **PERLU PERBAIKAN** |

---

## 2. Petunjuk Penggunaan Lembar Uji

1. **Bahasa Manusia Sederhana:** Seluruh langkah ditulis seperti instruksi kerja harian bagi staf kedai baru, tanpa istilah komputer rumit.
2. **Uji Nyata Satu Demi Satu:** Lakukan pengujian berurutan dari Bagian 1 sampai Bagian 7. Jangan melompati langkah agar alur kas terhubung dengan benar.
3. **Format Pengisian:**
   - Beri tanda centang `[v]` pada kolom **Status** jika hasil di layar sesuai dengan kolom **Tanda Berhasil**.
   - Beri tanda silang `[x]` jika yang muncul adalah **Tanda Gagal**.
4. **Catat Masalah Langsung:** Jika ditemukan tampilan janggal, tombol macet, atau angka salah, tuliskan nomor ID dan kendalanya pada **Tabel Catatan Masalah (Bagian 8)** di lembar penutup.

---

## 3. Bagian 1: Kasir & Alur Pelayanan Transaksi

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 1 | **UT-01** | **Membuka Menu & Memilih Meja** | 1. Masuk ke aplikasi kasir.<br>2. Pilih Meja (misal: Meja 01).<br>3. Pilih 3 menu makanan/minuman berbeda. | Menu masuk ke keranjang pesanan sebelah kanan; nomor meja tertulis jelas. | Meja tidak bisa dipilih atau menu tidak masuk keranjang. | [ ] |
| 2 | **UT-02** | **Menambah Catatan Khusus Item** | 1. Klik menu di keranjang (misal: Nasi Goreng).<br>2. Tambahkan catatan: *"Pedas sedang, tanpa timun"*.<br>3. Simpan. | Catatan khusus muncul tepat di bawah nama menu dengan tulisan jelas. | Catatan tidak tersimpan atau terpotong. | [ ] |
| 3 | **UT-03** | **Kesesuaian Angka Keranjang & Bayar** | 1. Catat angka Total Tagihan di keranjang kasir.<br>2. Tekan tombol **Bayar**.<br>3. Bandingkan angka di layar pembayaran. | Angka total di layar bayar **sama persis** dengan yang tertera di keranjang kasir. | Angka total berbeda walau hanya Rp 1. | [ ] |
| 4 | **UT-04** | **Perhitungan Kembalian Tunai Pas** | 1. Di layar bayar, pilih metode **Tunai**.<br>2. Masukkan nominal uang yang lebih besar (misal tagihan Rp 65.000, bayar Rp 100.000). | Angka kembalian otomatis muncul pas: **Rp 35.000**. | Kembalian salah hitung atau kolom tetap kosong. | [ ] |
| 5 | **UT-05** | **Penolakan Pembayaran Kurang** | 1. Di metode Tunai, masukkan uang lebih kecil dari tagihan (misal Rp 50.000 dari tagihan Rp 65.000).<br>2. Tekan tombol Catat Pembayaran. | Tombol tidak dapat diproses dan muncul peringatan jelas: *"Nominal pembayaran kurang"*. | Pembayaran kurang berhasil disimpan sebagai lunas. | [ ] |
| 6 | **UT-06** | **Pencegahan Tombol Bayar Dobel** | 1. Masukkan uang pas/lebih.<br>2. Tekan tombol konfirmasi bayar dua kali secara cepat karena buru-buru. | Sistem hanya mencatat **tepat 1 pembayaran**; tombol langsung terkunci saat proses. | Transaksi tersimpan dobel (muncul dua kali di riwayat). | [ ] |
| 7 | **UT-07** | **Pilihan 5 Metode Pembayaran Lengkap** | 1. Coba selesaikan transaksi dengan masing-masing metode: Tunai, QRIS, Debit, Kartu Kredit, dan Transfer Bank. | Semua metode dapat dipilih; metode non-tunai menyediakan kolom nomor referensi/struk bank. | Ada metode yang macet atau tidak dapat dipilih. | [ ] |
| 8 | **UT-08** | **Tampilan Struk Belanja Lengkap** | 1. Selesaikan pembayaran.<br>2. Periksa struk yang muncul di layar (atau dicetak). | Ada: Nama kedai, nomor struk, tanggal & jam, daftar menu, subtotal, baris pajak PB1, baris service, total akhir, metode bayar, dan kembalian. | Ada bagian struk yang hilang, tulisan tumpang tindih, atau pajak & service digabung. | [ ] |
| 9 | **UT-09** | **Bagikan Struk Digital (PDF / WhatsApp)** | 1. Pada struk yang selesai dibayar, tekan tombol **Bagikan Struk** atau simpan digital. | File struk digital dapat diunduh/dibuka dengan tampilan rapi; angka identik dengan layar. | Tombol tidak merespons atau file rusak. | [ ] |

---

## 4. Bagian 2: Layar Dapur & Bar Minuman

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 10 | **UT-10** | **Kirim Pesanan ke Dapur Real-Time** | 1. Dari layar kasir, susun pesanan lalu tekan **Kirim ke Dapur**.<br>2. Buka layar Dapur di tab/perangkat lain. | Tiket pesanan langsung muncul di layar dapur lengkap dengan nomor meja dan waktu kirim. | Pesanan tidak muncul di dapur atau kasir harus memuat ulang layar. | [ ] |
| 11 | **UT-11** | **Pemisahan Otomatis Dapur & Bar** | 1. Buat pesanan berisi makanan (Ayam Bakar) dan minuman (Es Teh Manis).<br>2. Buka layar Dapur Makanan.<br>3. Buka layar Bar Minuman. | Layar dapur **hanya menampilkan Ayam Bakar**; layar bar **hanya menampilkan Es Teh Manis**. | Makanan dan minuman bercampur di layar dapur tanpa filter stasiun. | [ ] |
| 12 | **UT-12** | **Penandaan Status Masak & Selesai** | 1. Di layar dapur, tekan tombol **Mulai Masak**.<br>2. Setelah matang, tekan tombol **Selesai / Siap Saji**. | Warna kartu berubah sesuai status; kasir dan pelayan dapat melihat bahwa pesanan sudah selesai. | Status tidak berubah atau tombol macet. | [ ] |
| 13 | **UT-13** | **Pembatalan Item Wajib Beralasan** | 1. Pada pesanan yang sudah masuk dapur, coba batalkan salah satu item.<br>2. Kosongkan kolom alasan lalu coba simpan.<br>3. Isi alasan *"Bahan habis"* lalu simpan. | Ditolak saat alasan kosong; sukses dibatalkan saat alasan diisi; alasan tercatat di jejak audit. | Item dapat dibatalkan tanpa menulis alasan apapun. | [ ] |

---

## 5. Bagian 3: Kasir, Shift, & Keamanan Kas Fisik

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 14 | **UT-14** | **Buka Kas Shift Kasir Baru** | 1. Masuk aplikasi dengan akun kasir di awal hari.<br>2. Tekan tombol **Buka Kas**.<br>3. Masukkan uang modal awal (misal Rp 100.000).<br>4. Konfirmasi. | Kas terbuka; nama kasir, jam buka, dan modal awal tercatat resmi di sistem. | Kasir dapat melayani pesanan sebelum modal awal diisi. | [ ] |
| 15 | **UT-15** | **Pencatatan Kas Masuk & Kas Keluar** | 1. Di menu kasir, pilih **Kas Keluar**.<br>2. Masukkan nominal Rp 20.000 dan alasan *"Beli es batu warung"*.<br>3. Simpan. | Saldo laci kas berkurang tepat Rp 20.000; alasan tercatat di riwayat mutasi kas harian. | Uang kas keluar tanpa alasan lolos, atau saldo laci tidak berkurang. | [ ] |
| 16 | **UT-16** | **Koreksi Modal Awal Shift Kasir** | 1. Jika kasir salah hitung modal di awal, buka menu **Koreksi Modal**.<br>2. Masukkan penyesuaian (+Rp 10.000) dan alasan *"Uang receh ketinggalan di brankas"*.<br>3. Simpan. | Modal awal shift terbarui; catatan koreksi dan alasannya tersimpan kekal untuk audit pemilik. | Modal berubah diam-diam tanpa ada jejak catatan audit. | [ ] |
| 17 | **UT-17** | **Tutup Kas & Perhitungan Fisik Laci** | 1. Di akhir shift kasir, tekan menu **Tutup Kas**.<br>2. Sistem menghitung uang seharusnya (modal + penjualan tunai − kas keluar).<br>3. Kasir menghitung uang fisik di laci dan memasukkan angkanya. | Jika uang fisik cocok: shift tertutup rapi.<br>Jika ada selisih: sistem **wajib meminta alasan selisih kas**. | Shift kasir ditutup tanpa input hitungan fisik, atau selisih kas lolos tanpa alasan. | [ ] |
| 18 | **UT-18** | **Pemberian Diskon di Atas Batas Kasir** | 1. Berikan diskon manual bernilai besar (melebihi batas izin kasir, misal Rp 50.000).<br>2. Coba terapkan diskon. | Layar meminta otorisasi PIN Atasan (Supervisor/Owner); tanpa PIN atasan diskon ditolak. | Kasir biasa bisa memberi diskon bebas tanpa persetujuan atasan. | [ ] |

---

## 6. Bagian 4: Katalog Menu Pelanggan & Voucher Promo

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 19 | **UT-19** | **Katalog Publik Pelanggan Tanpa Login** | 1. Buka tautan katalog kedai di peramban HP (mode penyamaran / tanpa login).<br>2. Periksa tampilan menu dan harga. | Tampil rapi dan cepat; menampilkan nama resto, logo, banner, dan harga menu sah; data staf aman terlindungi. | Halaman meminta login atau menampilkan data rahasia kedai. | [ ] |
| 20 | **UT-20** | **Tanda Menu Habis Terkunci Otomatis** | 1. Di dapur/kasir, tandai salah satu menu *"Habis"*.<br>2. Buka katalog pelanggan dan layar kasir. | Menu langsung berubah abu-abu bertanda **HABIS** dan tombol pesan otomatis terkunci. | Menu habis masih bisa dipesan oleh pelanggan atau kasir. | [ ] |
| 21 | **UT-21** | **Stand Kode QR Meja Akrilik Siap Cetak** | 1. Masuk menu Pengaturan → Tautan & QR Meja.<br>2. Pilih Meja 01 lalu buka Pratinjau Stand Meja. | Tampil kartu QR meja tajam berbingkai cantik ukuran cetak akrilik; saat di-scan HP langsung membuka menu Meja 01. | Gambar QR buram, nomor meja salah, atau tautan tidak dapat dibuka. | [ ] |
| 22 | **UT-22** | **Klaim Voucher Promo & Persetujuan Privasi** | 1. Buka tautan pendaftaran voucher promo.<br>2. Isi nama, email, dan beri centang persetujuan kebijakan privasi (UU PDP).<br>3. Tekan Klaim Voucher. | Voucher resmi terbit menampilkan kode unik acak (RB-XXXX-XXXX), barcode, dan masa berlaku. | Form lolos tanpa centang privasi atau kode voucher berurutan mudah ditebak. | [ ] |
| 23 | **UT-23** | **Cek Voucher Kasir (Hanya Membaca)** | 1. Di kasir, ketik kode voucher pelanggan.<br>2. Tekan tombol **Cek Voucher**. | Menampilkan nominal diskon dan syarat minimal belanja **tanpa menghanguskan voucher**. | Voucher langsung hangus/terpakai padahal transaksi belum dibayar. | [ ] |
| 24 | **UT-24** | **Pencairan Voucher Kasir (Sekali Pakai)** | 1. Terapkan voucher yang valid ke pesanan.<br>2. Selesaikan pembayaran hingga lunas.<br>3. Coba pakai kode voucher yang sama pada transaksi lain. | Transaksi pertama mendapat diskon;<br>Percobaan kedua **ditolak tegas**: *"Voucher sudah pernah digunakan"*. | Satu voucher bisa dipakai berulang kali di transaksi berbeda. | [ ] |
| 25 | **UT-25** | **Pencegahan Tebak Kode Voucher Acak** | 1. Di layar kasir, masukkan kode voucher ngawur 5 kali berturut-turut. | Sistem mengunci pengecekan voucher selama 15 menit untuk mencegah tebakan liar. | Kode acak bisa dicoba ribuan kali tanpa ada pengaman. | [ ] |

---

## 7. Bagian 5: Laporan Bisnis & Rekapitulasi Pemilik

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 26 | **UT-26** | **Rekapitulasi Omzet Penjualan Harian** | 1. Masuk sebagai Pemilik / Owner → menu Laporan Penjualan.<br>2. Periksa omzet kotor, total diskon, pajak PB1, service charge, dan omzet bersih. | Angka total cocok persis dengan penjumlahan transaksi kasir hari itu; rincian per metode bayar rapi. | Angka omzet tidak sesuai atau transaksi tunai/QRIS hilang dari rekap. | [ ] |
| 27 | **UT-27** | **Laporan Peringkat Menu Terlaris** | 1. Buka menu Laporan Menu.<br>2. Periksa daftar menu terlaris hari ini / bulan ini. | Menu berurutan dari porsi paling banyak terjual lengkap dengan kontribusi rupiah omzet. | Porsi menu salah hitung atau urutan acak. | [ ] |
| 28 | **UT-28** | **Laporan Pembatalan (Void) & Kerugian** | 1. Buka menu Laporan Pembatalan.<br>2. Periksa baris pembatalan yang terjadi. | Menampilkan nama kasir yang membatalkan, jam transaksi, nama menu, alasan batal, dan nilai kerugian bahan. | Pembatalan kasir tidak terekam dalam laporan pengawasan. | [ ] |
| 29 | **UT-29** | **Laporan Kinerja Voucher Promo** | 1. Buka menu Laporan Voucher.<br>2. Periksa total voucher terbit vs voucher yang terpakai di kasir. | Grafik serapan kuota, total potongan rupiah diskon, dan peringatan anomali klaim tampil jelas. | Angka pemakaian voucher tidak sesuai transaksi nyata. | [ ] |
| 30 | **UT-30** | **Laporan Kas & Rekonsiliasi Shift** | 1. Buka menu Laporan Kas.<br>2. Periksa shift kasir yang sudah ditutup. | Menampilkan modal awal, uang tunai masuk, pengeluaran kasir, uang fisik di laci, dan selisih beserta alasannya. | Laporan kas tidak mencatat selisih atau catatan kasir hilang. | [ ] |

---

## 8. Bagian 6: Pengaturan Resto & Manajemen Kedai

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 31 | **UT-31** | **Ubah Identitas Resto (Nama, Logo, Tagline)** | 1. Masuk Pengaturan Resto → Tab Identitas.<br>2. Ubah nama resto, slogan/tagline, dan unggah logo baru.<br>3. Simpan. | Nama, slogan, dan logo baru seketika terpasang di katalog pelanggan publik dan kop struk kasir. | Logo tidak muncul, nama tidak berubah, atau logo di atas 2 MB lolos tanpa validasi. | [ ] |
| 32 | **UT-32** | **Ganti Tema Visual 10 Preset Warna & Kerapatan** | 1. Masuk Pengaturan Resto → Tab Tema & Tampilan.<br>2. Coba pilih tema (misal: "Hangat Kedai", "Bara Panggang", atau "Etnik Nusantara").<br>3. Pilih mode kerapatan "Padat".<br>4. Simpan. | Warna aplikasi berubah serasi; tulisan tetap tajam terbaca (memenuhi kontras WCAG AA ≥ 4.5:1); tata letak padat rapi di tablet. | Teks sulit dibaca karena warna tabrakan, atau tata letak berantakan. | [ ] |
| 33 | **UT-33** | **Atur Pajak PB1, Service Charge, & Pembulatan** | 1. Masuk Pengaturan Resto → Tab Operasional & Kasir.<br>2. Setel tarif PB1 (misal 11%), Service (misal 5%), dan pembulatan ke Rp 500.<br>3. Perhatikan simulasi struk interaktif di sebelah kanan. | Struk simulasi langsung menghitung ulang nominal sesuai urutan resmi: Pajak dihitung dari dasar sesudah diskon. | Pajak dihitung sebelum diskon, atau simulasi macet tidak bereaksi. | [ ] |
| 34 | **UT-34** | **Transaksi Lama Tetap Kebal Perubahan Pajak** | 1. Catat transaksi kemarin saat pajak 10%.<br>2. Naikkan tarif pajak resto menjadi 12% hari ini.<br>3. Buka riwayat transaksi kemarin di laporan kasir. | Transaksi kemarin **TETAP 10% dan total rupiah tidak berubah sama sekali** (integritas ART-3 terjaga). | Transaksi lama ikut berubah angkanya mengikuti tarif hari ini. | [ ] |
| 35 | **UT-35** | **Kelola Pegawai, Pembatasan Izin, & Reset PIN** | 1. Masuk Pengaturan Resto → Tab Kelola Pegawai.<br>2. Tambah pegawai baru peran Kasir.<br>3. Atur centang izin dan batas diskon maksimal Rp 20.000.<br>4. Lakukan reset PIN pegawai oleh atasan. | Pegawai baru terdaftar; PIN berhasil diganti tanpa perlu tahu PIN lama staf; kasir terkunci sesuai batas izinnya. | Kasir baru bisa mengakses menu owner tanpa izin, atau reset PIN gagal. | [ ] |
| 36 | **UT-36** | **Pencegahan Tabrakan Simpan Pengaturan Bersamaan** | 1. Buka menu pengaturan di dua tab browser (Tab A dan Tab B).<br>2. Di Tab A, ubah pesan footer struk lalu simpan.<br>3. Di Tab B (tanpa memuat ulang), coba ubah nama kedai lalu simpan. | Tab B menolak simpan dengan pesan ramah: *"Data sudah diubah oleh pengguna lain. Silakan muat ulang halaman."* Masukan di Tab B tidak hilang. | Tab B menimpa perubahan Tab A secara diam-diam tanpa peringatan. | [ ] |

---

## 9. Bagian 7: Ketahanan Lapangan & Kasus Tepi

| No | ID | Skenario yang Diuji | Langkah Pengujian | Tanda Berhasil (Harapan) | Tanda Gagal | Status |
|---|---|---|---|---|---|---|
| 37 | **UT-37** | **Antrean Offline saat Internet Putus Total** | 1. Masuk layar Kasir.<br>2. Matikan koneksi internet (WiFi/data seluler).<br>3. Buat pesanan baru dan kirim. | Muncul indikator ramah: *"Pesanan tersimpan di antrean luring (menunggu dikirim 1)"*; aplikasi tidak macet atau layar putih. | Aplikasi macet, layar membeku, atau pesanan hilang tanpa jejak. | [ ] |
| 38 | **UT-38** | **Sinkronisasi Otomatis Tanpa Data Dobel** | 1. Sambungkan kembali koneksi internet.<br>2. Perhatikan indikator antrean kasir. | Pesanan di antrean otomatis terkirim ke peladen; status berubah menjadi terkirim; pesanan di database **tepat 1 (tidak dobel)**. | Pesanan tercatat dua kali di peladen atau kasir harus input ulang manual. | [ ] |
| 39 | **UT-39** | **Pemulihan Otomatis Kasir Mati Mendadak** | 1. Susun pesanan 4 menu di keranjang kasir.<br>2. Tutup paksa browser / muat ulang halaman tiba-tiba.<br>3. Buka kembali aplikasi kasir. | Keranjang belanja kasir otomatis pulih seperti semula tanpa kasir harus memilih ulang menu dari awal. | Keranjang belanja kosong melompong dan kasir harus input dari nol. | [ ] |
| 40 | **UT-40** | **Ergonomi Pengetikan Keyboard Fisik PIN** | 1. Di layar masuk staf, ketik 6 angka PIN menggunakan keyboard fisik.<br>2. Coba tombol `Backspace` (hapus angka terakhir).<br>3. Coba tombol `Escape` (reset 0 digit).<br>4. Coba tombol `Enter` atau `Spasi` untuk konfirmasi masuk. | Seluruh tombol keyboard fisik berfungsi mulus dan responsif; keypad layar sentuh tetap aktif. | Angka tidak masuk, tombol Backspace macet, atau harus klik mouse/layar. | [ ] |
| 41 | **UT-41** | **Pelindung Intipan Mata (Anti Shoulder-Surfing)** | 1. Perhatikan indikator digit saat PIN diketik via keyboard atau layar sentuh. | Angka PIN **selalu disamarkan sebagai bulatan hitam (●)**; tidak pernah menampilkan angka asli di layar kasir. | Angka PIN asli terlihat jelas oleh orang di belakang kasir. | [ ] |
| 42 | **UT-42** | **Pencabutan Akses Cepat Pegawai Berhenti** | 1. Masuk menu Kelola Pegawai.<br>2. Pilih pegawai yang berhenti, tekan **Cabut Akses Pegawai**.<br>3. Ketik konfirmasi kata "CABUT". | Akun pegawai seketika dinonaktifkan, PIN dihapus, seluruh sesi aktif di perangkat dicabut, dan shift yang menggantung dialihkan ke atasan. | Pegawai yang berhenti masih bisa login di perangkat kedai. | [ ] |

---

## 10. Bagian 8: Lembar Catatan Masalah & Evaluasi Lapangan

Gunakan tabel ini untuk mencatat setiap kendala atau hal yang dirasa kurang nyaman selama pengujian berlangsung:

| No | ID Uji | Layar / Bagian | Kendala / Masalah yang Ditemukan | Saran Perbaikan / Tindak Lanjut | Tingkat (Kritis / Sedang / Kecil) |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |

---

## 11. Lembar Persetujuan Akhir Gelombang 1 (G1)

Berdasarkan pengujian langsung yang telah dijalankan di atas:

- **Total Skenario Diuji:** 42 Skenario (Kasir, Dapur, Kas/Shift, Voucher/Katalog, Laporan, Pengaturan, & Ketahanan Lapangan).
- **Hasil Skenario Lolos:** .......... dari 42 Skenario.
- **Hasil Skenario Bermasalah:** .......... Skenario (tercatat di Bagian 8).

### Pernyataan Persetujuan Pemilik Platform:

> *"Dengan ini saya menyatakan bahwa aplikasi Resto Barokah Gelombang 1 (G1) telah diuji coba secara langsung. Seluruh alur utama operasional, ketepatan uang, keamanan kas, dan ketahanan sistem telah diverifikasi dengan hasil yang tercantum pada lembar ini."*

**Kota / Tanggal:** Bandung, .................................................... 2026

**Penguji / Pemilik Platform (SaaS Vendor):**

<br><br><br>
**( LEE )**  
*Pemilik Platform Resto Barokah*
