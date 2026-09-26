# RENCANA UJI MANUAL — daftar periksa Lee (yang HARUS dicoba mata & tangan manusia)

> **Dibuat 2026-09-23** atas permintaan Lee, sebagai syarat menunda uji peramban otomatis
> (butir **T-026**) ke Fase 11. Kesepakatannya: boleh ditunda, **asal semua yang perlu dicek
> tercatat rapi, dijelaskan, dan bisa dicentang**.

---

## 🖨️ YANG MENUNGGU LEE SEKARANG — UJI PRINTER (5 baris)

> Ditambahkan 2026-09-23 atas permintaan Lee: _"Untuk printer aku ceknya nanti.
> Masukin aja dulu ke daftar yang harus aku uji."_

Printer sudah **selesai dikerjakan dan lulus uji otomatis**, tetapi uji otomatis
memakai printer **tiruan** di dalam komputer. Itu membuktikan logikanya benar,
**bukan** bahwa kertasnya benar-benar keluar. Lima baris di bawah ini hanya bisa
dibuktikan Lee dengan printer sungguhan:

| ID | Yang dicek | Perlu apa |
|---|---|---|
| **M-12** | Cetak struk ke printer sungguhan | Printer mana pun |
| **M-22** | Uji cetak halaman contoh & lebar kertas benar | Printer mana pun |
| **M-23** | **Printer merek LAIN tetap jalan** | Printer di luar 5 merek Lee |
| **M-24** | Tiket dapur: nomor besar, catatan mencolok, tanpa harga | Printer mana pun |
| **M-25** | Pesan jelas saat printer mati di tengah cetak | Printer mana pun |

**Mulai dari M-22** — itu yang paling cepat (tidak perlu transaksi, cukup tekan
"Uji cetak" di Pengaturan). Kalau M-22 sudah benar, empat sisanya lebih mudah.

Langkah rincinya ada di **`docs/uji/PANDUAN_PRINTER.md`** (bahasa sehari-hari,
ada tabel kelima printer Lee). Rincian tiap baris ada di **Bagian C** di bawah.

> ⚠️ **Tugas `T6-08` di ROADMAP tidak boleh dicentang** sampai lima baris ini
> punya hasil nyata. Agent tidak boleh mencentangnya sendiri.

---

## Bagian A — Baca ini dulu (3 menit)

### A1. Kenapa berkas ini ada

Aplikasi ini dijaga **dua lapis pengujian**:

| Lapis | Siapa yang menjalankan | Sudah ada? |
|---|---|---|
| **Uji mesin** — memeriksa logika, angka, aturan database | Komputer, otomatis tiap kali kode berubah | ✅ Ya: 400-an uji aplikasi + 86 uji database |
| **Uji manusia** — memeriksa hal yang hanya bisa dinilai mata & tangan | **Lee** (atau pegawai) | 📋 **Berkas inilah daftarnya** |

Mesin bisa membuktikan "total tagihan = 62.100". Mesin **tidak bisa** membuktikan "tulisan di
struk terbaca jelas", "tombol tidak kekecilan untuk jempol", atau "printer benar-benar
mengeluarkan kertas". Itu bagian Lee.

### A2. Cara memakai daftar ini

1. **Kerjakan satu baris pada satu waktu.** Jangan diborong.
2. Baca kolom **Langkah**, lakukan persis urutannya.
3. Bandingkan yang Lee lihat dengan kolom **✅ Tanda berhasil** dan **❌ Tanda gagal**.
4. Isi kolom **Status** dengan `OK` atau `GAGAL`.
5. Bilang ke saya di chat: **`Uji manual M-05: OK`** atau **`Uji manual M-05: GAGAL — tulisannya kepotong`**.
   Saya yang mencatat ke berkas ini. **Lee tidak perlu mengedit berkas apa pun.**

> **Kalau ragu, tulis GAGAL.** Uji yang dipaksakan "OK" lebih berbahaya daripada uji yang gagal,
> karena masalahnya akan muncul lagi nanti saat kedai sedang ramai.

### A3. Arti tanda

| Tanda | Arti |
|---|---|
| 🟢 **SIAP** | Fiturnya sudah jadi — Lee bisa mencoba **sekarang** |
| 🟡 **MENUNGGU FITUR** | Belum bisa dicoba; menunggu tugas tertentu selesai |
| 🔴 **BUTUH ALAT** | Perlu barang fisik (printer, HP kedua, dsb.) yang belum ada |

### A4. Cara menyalakan aplikasi untuk mencoba

Lee **tidak perlu mengetik perintah apa pun**. Cukup bilang di chat:

> **`Nyalakan pratinjau.`**

Saya akan menyalakan aplikasinya dan memberi Lee satu alamat web untuk dibuka. Kalau alamatnya
mati atau kosong, bilang saja — itu urusan saya, bukan kesalahan Lee.

---

## Bagian B — Daftar periksa: UANG (paling penting)

> Kenapa bagian ini didahulukan: kesalahan tampilan bikin malu, kesalahan uang bikin rugi.

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-01 | **Angka keranjang sama dengan angka yang ditagih** | Kasir menyebut angka ke tamu dari layar keranjang. Kalau berbeda dengan layar bayar, tamu merasa ditipu | 1) Buka pratinjau, masuk layar Kasir 2) Tambah 3 menu berbeda 3) **Catat di kertas** angka "Total Tagihan" di keranjang 4) Tekan Bayar 5) Bandingkan dengan total di layar bayar | Kedua angka **sama persis** | Beda walau Rp1 | 🟢 SIAP | |
| M-02 | **Kembalian dihitung benar** | Uang kembali yang salah langsung jadi selisih laci kas | 1) Susun pesanan apa saja 2) Tekan Bayar → pilih Tunai 3) Masukkan uang lebih besar dari tagihan (mis. tagihan 62.100, bayar 100.000) 4) Lihat angka kembalian | Kembalian = uang diterima − tagihan (37.900) | Angka lain, atau kolom kosong | 🟢 SIAP | |
| M-03 | **Uang kurang ditolak** | Pesanan tidak boleh tercatat lunas kalau uangnya belum cukup | 1) Susun pesanan 2) Bayar Tunai dengan uang **lebih kecil** dari tagihan 3) Coba lanjutkan | Ditolak dengan pesan yang jelas | Diterima, atau pesan error membingungkan | 🟢 SIAP | |
| M-04 | **Tombol bayar tidak bisa ditekan dua kali** | Tekan dua kali karena panik = uang tercatat dobel | 1) Susun pesanan 2) Masuk layar bayar, isi uang 3) Tekan tombol catat pembayaran **dua kali cepat** | Hanya **satu** pembayaran tercatat | Muncul dua catatan pembayaran | 🟢 SIAP | |
| M-05 | **Pembayaran sebagian & tagihan ditinggal** | Meja yang belum lunas harus terlihat, bukan hanya diingat kasir | 1) Susun pesanan 2) Bayar **sebagian** (mis. tagihan 62.100, bayar 30.000) 3) Lihat daftar tagihan | Tagihan masih muncul; **sisa** tertulis jelas; ada penanda berapa lama menggantung | Tagihan hilang, atau tertulis lunas | 🟡 MENUNGGU FITUR (perlu T5-11 disambung ke layar utama) | |
| M-06 | **Diskon di atas batas minta izin atasan** | Tanpa ini, kasir bisa memberi diskon sesukanya | 1) Susun pesanan besar 2) Beri diskon melebihi batas kasir (mis. Rp50.000) 3) Coba terapkan | Diminta PIN atasan; tanpa PIN, diskon **tidak** masuk | Diskon langsung masuk tanpa izin | 🟢 SIAP | |
| M-07 | **Pembatalan item wajib beralasan** | Tanpa alasan tertulis, kerugian tidak bisa ditelusuri | 1) Susun pesanan, kirim ke dapur 2) Coba batalkan satu item 3) Kosongkan kolom alasan, coba lanjut | Ditolak sampai alasan diisi | Item hilang tanpa alasan | 🟢 SIAP | |

---

## Bagian C — Daftar periksa: STRUK & CETAK

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-08 | **Isi struk lengkap & terbaca** | Struk adalah bukti sah untuk tamu | 1) Selesaikan satu pembayaran 2) Lihat struk yang muncul 3) Periksa satu per satu | Ada: nama kedai · nomor struk · tanggal & jam · daftar item + jumlah · subtotal · diskon · **pajak** · **service** · total · metode bayar · kembalian | Ada yang hilang, tertukar, atau tertimpa | 🟢 SIAP | |
| M-09 | **Pajak & service tertulis TERPISAH** | Tamu dan petugas pajak berhak tahu rinciannya | 1) Lihat struk dari M-08 2) Cari baris pajak dan baris service | Dua baris **berbeda**, masing-masing bernilai | Digabung jadi satu baris "biaya lain" | 🟢 SIAP | |
| M-10 | **Struk cetak ulang bertanda SALINAN** | Struk kedua yang mirip aslinya bisa dipakai menagih dua kali | 1) Buka daftar transaksi 2) Cari transaksi lama 3) Cetak ulang strukanya | Ada tulisan **"SALINAN — CETAK ULANG"** yang jelas di atas | Terlihat sama persis dengan struk asli | 🟡 MENUNGGU FITUR (perlu T5-10 disambung ke layar utama) | |
| M-11 | **Struk digital bisa dibagikan** | Cadangan saat printer mati | 1) Selesaikan pembayaran 2) Tekan tombol bagikan / simpan PDF | Struk bisa dibagikan atau tersimpan; **angkanya sama** dengan struk kertas | Angkanya berbeda dari struk kertas | 🟢 SIAP | |
| M-12 | **Cetak ke printer sungguhan** | Semua uji di atas percuma kalau kertasnya tidak keluar | 1) Sambungkan printer termal 2) Selesaikan pembayaran 3) Tekan cetak | Kertas keluar, tulisan tidak terpotong di kanan, angka terbaca | Terpotong, huruf aneh, atau tidak keluar | 🟡 SIAP DICOBA (merek sudah didukung sejak T6-02/T6-03; **butir T-002 sudah dijawab Lee**) | |
| M-22 | **Uji cetak halaman contoh & lebar kertas** | Lebar kertas salah = angka rupiah hilang di sisi kanan | 1) Pengaturan → Pasang printer 2) Pilih merek (atau "Printer ESC/POS umum") 3) Pilih lebar 58 mm / 80 mm 4) Tekan **Uji cetak** | Garis panjang di kertas **pas selebar kertas**, tidak terlipat & tidak kependekan | Garis terlipat ke baris bawah, atau jauh lebih pendek dari kertas | 🟡 SIAP DICOBA (butuh printer) | |
| M-23 | **Printer merek LAIN tetap jalan** | Janji ke Lee: tidak terkunci pada 5 merek tertentu | 1) Pakai printer termal merek apa pun di luar daftar 2) Pilih **"Printer ESC/POS umum"** 3) Atur lebar kertasnya 4) Uji cetak | Kertas tetap keluar dan terbaca rapi | Printer tidak bisa dipilih, atau hasilnya kacau | 🟡 SIAP DICOBA (butuh printer selain 5 merek itu) | |
| M-24 | **Tiket dapur tercetak & catatan mencolok** | "Tanpa kacang" yang terlewat bisa berarti alergi | 1) Buat pesanan dengan catatan khusus 2) Kirim ke dapur 3) Cetak tiket | Nomor pesanan **besar**; catatan khusus **tebal** berawalan `>>`; **tidak ada harga** di tiket | Catatan kecil/hilang, atau tiket memuat harga | 🟡 SIAP DICOBA (butuh printer) | |
| M-25 | **Pesan jelas saat printer mati/putus** | Kegagalan cetak tidak boleh menghilangkan transaksi | 1) Matikan printer di tengah proses 2) Coba cetak struk | Muncul pesan yang bisa dimengerti + tawaran struk digital; **transaksi tetap tersimpan** | Aplikasi diam saja, atau transaksi hilang | 🟡 SIAP DICOBA (butuh printer) | |

---

## Bagian D — Daftar periksa: ALUR KERJA HARIAN

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-13 | **Satu putaran penuh: pesan → dapur → bayar → struk** | Inilah pekerjaan kedai sehari-hari | 1) Susun pesanan 2) Kirim ke dapur 3) Buka layar Dapur, tandai selesai 4) Kembali ke Kasir, bayar 5) Lihat struk | Lancar dari awal sampai akhir tanpa layar macet | Macet di salah satu langkah | 🟢 SIAP | |
| M-14 | **Pesanan muncul di layar dapur** | Dapur tidak boleh menunggu kasir berteriak | 1) Buka dua tab: Kasir & Dapur 2) Kirim pesanan dari Kasir 3) Lihat tab Dapur | Tiket muncul lengkap dengan catatan khusus | Tidak muncul, atau catatan hilang | 🟢 SIAP | |
| M-15 | **Dua perangkat tidak saling menimpa** | Kasir dan pelayan sering bekerja bersamaan | 1) Buka aplikasi di **dua perangkat** 2) Ubah pesanan yang sama dari keduanya 3) Perhatikan hasilnya | Perubahan tidak saling menghapus; ada pesan bila bentrok | Data satu perangkat hilang diam-diam | 🔴 BUTUH ALAT (HP/tablet kedua — butir **T-003**) | |
| M-16 | **Jaringan putus tidak bikin kacau** | Internet kedai sering mati sebentar | 1) Buka aplikasi 2) Matikan WiFi perangkat 3) Coba pakai beberapa layar | Muncul pesan jelas "tidak ada jaringan"; aplikasi **tidak** membeku atau layar putih | Layar putih, atau pura-pura berhasil padahal tidak tersimpan | 🟢 SIAP | |
| M-17 | **Lima metode pembayaran** | Tamu bayar dengan cara berbeda-beda | 1) Selesaikan 5 transaksi 2) Tiap transaksi pakai metode berbeda (tunai, QRIS, debit, kredit, transfer) | Semua tercatat; non-tunai minta nomor referensi | Ada metode yang gagal atau tercatat salah | 🟢 SIAP | |

---

## Bagian E — Daftar periksa: TAMPILAN & KENYAMANAN

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-18 | **Tombol cukup besar untuk jempol** | Kasir memakai layar sentuh sambil berdiri & buru-buru | 1) Buka pratinjau di **HP**, bukan komputer 2) Coba susun pesanan hanya dengan jempol | Tidak pernah salah tekan karena tombol berdempetan | Sering salah tekan | 🟢 SIAP | |
| M-19 | **Teks terbaca di bawah lampu terang** | Kasir sering menghadap jendela | 1) Buka di HP 2) Bawa ke tempat terang / dekat jendela 3) Baca angka total | Angka tetap terbaca | Pudar, harus menyipitkan mata | 🟢 SIAP | |
| M-20 | **Layar sempit tetap rapi** | Tidak semua perangkat kedai berlayar besar | 1) Buka di komputer 2) Perkecil lebar jendela sampai selebar HP 3) Telusuri tiap layar | Tidak ada teks bertumpuk atau tombol keluar layar | Tulisan bertabrakan | 🟢 SIAP | |
| M-21 | **Pesan error bisa dimengerti pegawai** | Pesan teknis membuat pegawai menyerah dan menelepon Lee | 1) Sengaja buat kesalahan (bayar kurang, alasan kosong) 2) Baca pesannya | Bahasa Indonesia biasa, menyebut **apa yang harus dilakukan** | Muncul istilah teknis/kode error mentah | 🟢 SIAP | |

---

## Bagian F — Yang menunggu Fase 11 (uji peramban otomatis, T-026)

Ini **bukan** tugas Lee — ini catatan supaya tidak ada yang lupa bahwa uji otomatisnya ditunda,
bukan dibatalkan.

| Alur yang wajib diotomatiskan nanti | Dikerjakan di tugas |
|---|---|
| Buka shift kas | T11-01 / T11-11 |
| Susun pesanan → kirim ke dapur | T11-01 / T11-11 |
| Dapur menandai selesai | T11-01 / T11-11 |
| Bayar → cetak struk digital | T11-01 / T11-11 |
| Pembatalan berjenjang (sebelum & sesudah dapur mulai) | T11-01 / T11-11 |
| Tutup kas | T11-01 / T11-11 |
| Voucher | T11-01 / T11-11 |
| Katalog publik (halaman tamu) | T11-01 / T11-11 |
| Cetak ulang struk bertanda SALINAN | T11-11 |

**Kenapa ditunda:** peramban Chrome-nya tidak bisa diunduh di ruang kerja agent (sudah dicoba
2026-09-17 dan 2026-09-23). Artinya saya bisa **menulis** ujinya tetapi tidak bisa
**menjalankannya** untuk membuktikan ujinya sendiri benar — dan menaruh uji yang tak pernah
dicoba ke dalam pemeriksaan otomatis pernah membuat CI merah berjam-jam.

**Jaminan tidak terlupa:** butir **T-026** berstatus terbuka di `docs/TERTANGGUH.md`, dan tugas
**T11-01** serta **T11-11** di `docs/ROADMAP.md` ditandai `❓ T-026`. Penjaga mesin
`alat/periksa-roadmap.py` **menolak** (CI merah) bila butir terbuka kehilangan tandanya.

---

## Bagian G — Daftar periksa: KASIR, SHIFT KAS, & LAPORAN (Fase 7: T7-01 s/d T7-12)

> Menguji alur buka kas shift, pencatatan kas masuk/keluar, koreksi modal, tutup kas fisik, dan rekonsiliasi laporan.

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-26 | **Buka Kas Shift Kasir** | Uang modal awal wajib tercatat sebelum kasir bisa melayani transaksi | 1) Buka pratinjau, masuk sebagai kasir 2) Tekan tombol Buka Kas 3) Masukkan nominal modal (mis. Rp100.000) 4) Konfirmasi buka kas | Kas terbuka; kasir siap melayani; modal tercatat di sistem | Buka kas tanpa modal berhasil, atau kasir bisa transaksi sebelum buka kas | 🟢 SIAP | |
| M-27 | **Kas Masuk & Kas Keluar** | Pengeluaran kecil kedai (es batu, galon, dll) wajib tercatat di laci kas | 1) Di layar kasir, tekan menu Kas Keluar / Masuk 2) Pilih Kas Keluar 3) Isi nominal Rp25.000 dan alasan "Beli es batu" 4) Simpan | Saldo kas berkurang Rp25.000; alasan tercatat di laporan kas | Uang keluar tanpa alasan lolos, atau saldo kas tidak terpotong | 🟢 SIAP | |
| M-28 | **Koreksi Modal Awal Shift** | Kasir salah hitung uang modal di awal tidak boleh membuat laporan kacau | 1) Di menu kasir, pilih Koreksi Modal 2) Masukkan selisih koreksi (+Rp20.000) dan alasan "Uang receh terselip" 3) Simpan | Modal awal terbarui; alasan koreksi tercatat di riwayat | Modal berubah tanpa alasan atau tanpa jejak | 🟢 SIAP | |
| M-29 | **Tutup Kas Shift & Selisih Uang** | Uang di laci wajib dihitung fisik saat ganti shift | 1) Di akhir shift, tekan Tutup Kas 2) Masukkan uang fisik hasil hitung 3) Bila ada selisih, sistem meminta alasan wajib 4) Konfirmasi tutup kas | Shift ditutup; ringkasan uang masuk/keluar tampil rapi; selisih tercatat | Kas ditutup tanpa hitung fisik, atau selisih lolos tanpa alasan | 🟢 SIAP | |
| M-30 | **Laporan Penjualan & Omzet Harian** | Owner wajib tahu pendapatan bersih, pajak, dan metode bayar | 1) Masuk sebagai Owner → menu Laporan 2) Buka Laporan Penjualan 3) Periksa omzet kotor, diskon, pajak PB1, service charge, dan omzet bersih | Rincian per metode bayar (tunai, QRIS, kartu) cocok dengan transaksi nyata | Angka omzet tidak cocok dengan total transaksi | 🟢 SIAP | |
| M-31 | **Laporan Menu Terlaris** | Mengetahui menu favorit tamu untuk belanja bahan baku | 1) Masuk menu Laporan → Laporan Menu 2) Periksa daftar menu terlaris dan porsi terjual | Menu berperingkat dari yang paling laku; jumlah porsi dan kontribusi omzet jelas | Data porsi salah atau menu teracak | 🟢 SIAP | |
| M-32 | **Laporan Pembatalan / Void & Kerugian** | Mengawasi kecurangan kasir atau pemborosan bahan dapur | 1) Buka Laporan Pembatalan 2) Periksa daftar pesanan/item yang pernah dibatalkan | Menampilkan siapa yang membatalkan, alasan pembatalan, dan estimasi kerugian bahan | Pembatalan hilang dari laporan | 🟢 SIAP | |

---

## Bagian H — Daftar periksa: KATALOG PELANGGAN, VOUCHER, & PRIVASI (Fase 8: T8-01 s/d T8-15)

> Menguji halaman katalog mandiri pelanggan, sistem voucher promo undang-teman, scan barcode kasir, dan privasi UU PDP.

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-33 | **Katalog Menu Publik Tanpa Login** | Tamu bisa melihat daftar menu dari HP sendiri lewat internet | 1) Buka tautan katalog publik (tanpa login) 2) Periksa nama resto, logo, banner, jam buka, dan kategori menu | Katalog tampil bersih dan cepat; harga cabang akurat; data rahasia staf tidak bocor | Halaman meminta login staf, atau data sensitif terlihat | 🟢 SIAP | |
| M-34 | **Penanda Menu Habis di Katalog & Kasir** | Tamu tidak memesan menu yang bahannya sudah habis di dapur | 1) Di layar dapur, tandai salah satu menu "Habis" 2) Buka katalog pelanggan dan layar kasir | Menu tersebut bertanda abu-abu "HABIS" dan tombol pesannya terkunci | Menu habis masih bisa dipesan | 🟢 SIAP | |
| M-35 | **Tautan & Stand QR Meja Akrilik** | Tamu di meja tinggal scan QR untuk membuka menu kedai | 1) Masuk sebagai Owner → Pengaturan → Tautan & QR Meja 2) Pilih Meja 01 3) Tekan Unduh / Pratinjau Stand Akrilik | Gambar kode QR tajam siap cetak ukuran stand meja; saat di-scan membuka menu meja tersebut | Kode QR rusak atau salah membuka nomor meja | 🟢 SIAP | |
| M-36 | **Pendaftaran & Klaim Voucher Promo** | Menarik pelanggan baru lewat promo undang teman | 1) Buka tautan kampanye voucher 2) Masukkan nama & email 3) Beri centang persetujuan privasi UU PDP 4) Tekan Klaim Voucher | Tiket voucher terbit dengan kode unik resmi (contoh: RB-XXXX-XXXX) dan barcode | Pendaftaran tanpa persetujuan privasi lolos, atau kode voucher kembar | 🟢 SIAP | |
| M-37 | **Cek Voucher di Kasir (Hanya Baca)** | Kasir memeriksa keabsahan voucher tanpa menghanguskannya | 1) Di layar kasir, masukkan kode voucher tamu 2) Tekan Cek Voucher | Menampilkan nominal potongan dan syarat tanpa mengubah status voucher di database | Voucher langsung hangus sebelum pesanan dibayar | 🟢 SIAP | |
| M-38 | **Pakai Voucher di Kasir (Sekali Pakai)** | Satu voucher tidak boleh dipakai dua kali oleh orang berbeda | 1) Terapkan voucher sah pada pesanan 2) Selesaikan pembayaran 3) Coba gunakan kode voucher yang sama pada transaksi kedua | Transaksi pertama sukses terpotong; percobaan kedua ditolak "VOUCHER SUDAH TERPAKAI" | Voucher bisa dipakai berulang kali | 🟢 SIAP | |
| M-39 | **Scan Kamera Barcode Voucher** | Kasir cukup mengarahkan barcode voucher ke kamera tanpa mengetik | 1) Di modal voucher kasir, tekan "📷 Pindai Kamera" 2) Arahkan barcode voucher ke kamera (atau gunakan masukan manual jika tanpa kamera) | Kode voucher langsung terdeteksi otomatis dan diperiksa | Kamera macet tanpa tombol alternatif ketik manual | 🟢 SIAP | |
| M-40 | **Kelola Aturan Kampanye Voucher oleh Owner** | Owner mengatur kuota, batas belanja, dan diskon sendiri | 1) Masuk sebagai Owner → Pengaturan → Kampanye Voucher 2) Buat kampanye baru (misal: diskon 20%, maks Rp15.000, min belanja Rp30.000) 3) Simpan | Kampanye baru aktif; aturan pratinjau bahasa manusia terbaca jelas | Aturan mustahil (diskon > 100%) lolos | 🟢 SIAP | |
| M-41 | **Laporan Voucher & Deteksi Anomali** | Mencegah kasir atau pihak luar berbuat curang dengan voucher | 1) Buka menu Laporan → Laporan Voucher 2) Periksa ringkasan serapan kuota, total diskon, dan kotak Peringatan Anomali | Menampilkan bila ada kode dicoba berkali-kali secara mencurigakan (brute force) | Percobaan mencurigakan tidak terdeteksi | 🟢 SIAP | |
| M-42 | **Transparansi Kebijakan Privasi (UU PDP)** | Hak pelanggan terlindungi dan kepatuhan hukum aman | 1) Buka tautan Kebijakan Privasi di bagian bawah halaman 2) Baca transparansi hak subjek data dan alur penghapusan/anonimisasi data | Menjelaskan bahasa sederhana data apa yang disimpan dan cara meminta penghapusan | Dokumen hukum membingungkan atau tidak ada | 🟢 SIAP | |

---

## Bagian I — Daftar periksa: PENGATURAN RESTO TANPA KODING (Fase 9: T9-01 s/d T9-03)

> Menguji pengaturan identitas resto, 10 tema warna visual siap pakai, dan pengaturan operasional keuangan.

| ID | Yang dicek | Kenapa penting | Langkah | ✅ Tanda berhasil | ❌ Tanda gagal | Kesiapan | Status |
|---|---|---|---|---|---|---|---|
| M-43 | **Ubah Identitas Resto (Nama, Tagline, Logo)** | Owner bisa meremajakan merek resto sendiri kapan saja | 1) Masuk sebagai Owner → Pengaturan Resto → Tab Identitas 2) Ubah nama resto dan tagline 3) Unggah logo baru 4) Simpan 5) Buka katalog publik | Nama dan logo langsung terbarui di katalog pelanggan dan kop struk kasir | Logo pecah, nama tidak berubah, atau file > 2 MB lolos | 🟢 SIAP | |
| M-44 | **Ganti Tema Warna & Kerapatan Tampilan** | Menyesuaikan suasana kedai (misal: Hangat, Vintage, Bara) | 1) Masuk Pengaturan Resto → Tab Tema & Tampilan 2) Pilih tema "Hangat Kedai" atau "Etnik Nusantara" 3) Coba kerapatan "Padat" 4) Simpan | Warna tombol, kartu, dan latar berubah serasi; kontras teks tetap tajam terbaca (lulus WCAG) | Teks tidak terbaca karena warna bertabrakan | 🟢 SIAP | |
| M-45 | **Pengaturan Pajak PB1 & Service Charge** | Menyesuaikan tarif pajak daerah dan biaya layanan kedai | 1) Masuk Pengaturan Resto → Tab Operasional & Kasir 2) Ubah Pajak PB1 ke 11% dan Service ke 6% 3) Perhatikan struk simulasi di sebelah kanan | Total di struk simulasi langsung terhitung ulang akurat seketika | Angka persentase tidak dihitung atau simulasi macet | 🟢 SIAP | |
| M-46 | **Aturan Pembulatan & Pesan Struk Kasir** | Struk kasir mencetak ucapan terima kasih dan pembulatan pas | 1) Di Tab Operasional & Kasir, pilih pembulatan "Ke Rp 500" 2) Ketik ucapan header dan footer struk 3) Simpan | Struk kasir membulatkan tagihan ke kelipatan 500 dan mencetak ucapan yang diketik | Pembulatan salah hitung atau ucapan tidak tercetak | 🟢 SIAP | |
| M-47 | **Transaksi Lama Kebal Perubahan Pajak (ART-3)** | Mengubah pajak hari ini tidak boleh mengubah laporan penjualan bulan lalu | 1) Catat transaksi lunas kemarin 2) Ubah tarif PB1 kedai dari 10% ke 12% 3) Buka kembali transaksi lama di riwayat kasir / laporan | Nominal pajak dan total transaksi lama **TETAP SAMA PERSIS** seperti saat dibuat | Angka transaksi lama ikut berubah sendiri | 🟢 SIAP | |
| M-48 | **Unggah Logo > 2 MB / Format Tak Valid Ditolak (T9-01)** | Mencegah kuota jebol dan browser melambat akibat berkas raksasa | 1) Masuk Pengaturan Resto → Tab Identitas 2) Coba unggah file gambar > 2 MB atau file non-gambar (mis. PDF) 3) Perhatikan respons sistem | Muncul pesan peringatan ramah "Ukuran logo maksimal 2 MB" dan berkas tidak tersimpan | Berkas raksasa tersimpan atau aplikasi macet | 🟢 SIAP | |
| M-49 | **Tarif Pajak & Service Negatif atau > 100% Ditolak (T9-03)** | Integritas pembukuan: tidak boleh ada persentase aneh yang merusak laporan | 1) Masuk Pengaturan Resto → Tab Operasional 2) Ketik angka -5 atau 120 pada kolom tarif pajak PB1 3) Tekan Simpan Pengaturan | Tombol simpan tidak aktif atau muncul validasi kesalahan 0–100% | Angka negatif atau > 100% lolos tersimpan | 🟢 SIAP | |
| M-50 | **Bentrok Perubahan Bersamaan / Versi Ketinggalan (T9-01/T9-03)** | Mencegah perubahan admin satu menimpa admin lain yang sedang bekerja bersamaan | 1) Buka layar Pengaturan di dua jendela browser 2) Di jendela A ubah nama kedai lalu simpan 3) Di jendela B tanpa refresh ubah pesan struk lalu simpan | Jendela B menampilkan pesan ramah bahwa data telah diperbarui pengguna lain dan meminta muat ulang | Jendela B menimpa perubahan jendela A diam-diam | 🟢 SIAP | |
| M-51 | **Penolakan Email Sekali Pakai / Disposable (T8-07)** | Mencegah bot atau klaim voucher berulang dengan alamat email palsu | 1) Buka tautan klaim voucher promo 2) Masukkan email dengan domain penyedia email sementara (misal: mailinator / tempmail) 3) Tekan Klaim | Ditolak dengan pesan meminta alamat email pribadi/resmi yang sah | Email palsu sekali pakai lolos menerima voucher | 🟢 SIAP | |
| M-52 | **Kunci Brute Force Kode Voucher di Kasir (T8-12)** | Mencegah pihak nakal menebak-nebak kode voucher acak berulang kali | 1) Di modal voucher kasir, masukkan kode sembarangan 5 kali berturut-turut 2) Perhatikan respons sistem | Sistem mengunci percobaan pengecekan kode voucher selama 15 menit dengan pesan ramah | Kode acak bisa dicoba terus-menerus tanpa batas | 🟢 SIAP | |
| M-53 | **Isolasi Data Antar Cabang Kedai (T2-01 s/d T2-04)** | Data penjualan dan meja Cabang A tidak boleh bercampur ke Cabang B | 1) Masuk kasir dan pilih Cabang A 2) Periksa daftar pesanan 3) Ganti lokasi ke Cabang B 4) Periksa daftar pesanan | Pesanan dan meja terisolasi rapi sesuai cabang masing-masing | Transaksi cabang lain bercampur atau bocor | 🟢 SIAP | |
| M-54 | **Hak Akses Menu Pengaturan Terkunci untuk Kasir (T2-05)** | Kasir hanya melayani transaksi dan tidak boleh mengubah setting kedai | 1) Masuk aplikasi menggunakan Akun Kasir 2) Perhatikan menu navigasi utama | Tab/menu "Pengaturan Resto" tidak tampil untuk peran kasir | Kasir bisa membuka formulir pengaturan operasional | 🟢 SIAP | |
| M-55 | **Pemisahan Tiket Dapur Makanan & Bar Minuman (T4-01 s/d T4-03)** | Koki fokus pada makanan dan barista fokus pada minuman tanpa bercampur | 1) Buat pesanan berisi makanan dan minuman 2) Buka layar Dapur Makanan 3) Buka layar Bar Minuman | Makanan muncul di dapur; minuman muncul di bar | Semua item menumpuk di dapur tanpa filter stasiun | 🟢 SIAP | |

---

## Bagian J — Yang menunggu Fase 11 (uji peramban otomatis, T-026)

Ini **bukan** tugas Lee — ini catatan supaya tidak ada yang lupa bahwa uji otomatisnya ditunda,
bukan dibatalkan.

| Alur yang wajib diotomatiskan nanti | Dikerjakan di tugas |
|---|---|
| Buka shift kas | T11-01 / T11-11 |
| Susun pesanan → kirim ke dapur | T11-01 / T11-11 |
| Dapur menandai selesai | T11-01 / T11-11 |
| Bayar → cetak struk digital | T11-01 / T11-11 |
| Pembatalan berjenjang (sebelum & sesudah dapur mulai) | T11-01 / T11-11 |
| Tutup kas | T11-01 / T11-11 |
| Voucher | T11-01 / T11-11 |
| Katalog publik (halaman tamu) | T11-01 / T11-11 |
| Cetak ulang struk bertanda SALINAN | T11-11 |

**Kenapa ditunda:** peramban Chrome-nya tidak bisa diunduh di ruang kerja agent (sudah dicoba
2026-09-17 dan 2026-09-23). Artinya saya bisa **menulis** ujinya tetapi tidak bisa
**menjalankannya** untuk membuktikan ujinya sendiri benar — dan menaruh uji yang tak pernah
dicoba ke dalam pemeriksaan otomatis pernah membuat CI merah berjam-jam.

**Jaminan tidak terlupa:** butir **T-026** berstatus terbuka di `docs/TERTANGGUH.md`, dan tugas
**T11-01** serta **T11-11** di `docs/ROADMAP.md` ditandai `❓ T-026`. Penjaga mesin
`alat/periksa-roadmap.py` **menolak** (CI merah) bila butir terbuka kehilangan tandanya.

---

## Bagian K — Riwayat hasil

Diisi saya setiap kali Lee melaporkan hasil.

| Tanggal | ID | Hasil | Catatan |
|---|---|---|---|
| — | — | — | Belum ada laporan; daftar baru dibuat 2026-09-23, diperluas Fase 7–9 pada 2026-09-26 |
