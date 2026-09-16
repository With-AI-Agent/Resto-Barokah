# Penilaian Referensi Desain — kiriman pemilik (2026-09-16)

> **Status berkas:** gambar kiriman pemilik **SUDAH TERSIMPAN** di repo (34 gambar unik, `docs/desain/referensi/pemilik/`,
> kode `P01`–`P34`, semuanya sudah diverifikasi tidak ada yang rusak). Jalur masuknya: pemilik mengunggah `Referensi.zip`
> (35 berkas) ke GitHub → agent membongkar, memeriksa, memberi nama, membuat papan perbandingan, lalu menghapus zip
> (isinya sudah lengkap; zip asli tetap ada di riwayat commit `fc05f17`).
> Daftar lengkap per gambar ada di `docs/desain/referensi/pemilik/README.md`; papan visualnya `docs/desain/papan-referensi-pemilik.jpg`.

## 1. Jawaban singkat: bagus tidak?

**Bagus — dan jauh lebih banyak daripada yang aku kira (34 gambar, bukan 10).** Kualitasnya satu tingkat di atas
gambar hasil pencarianku sendiri: sistemnya konsisten (jarak, bentuk sudut, ukuran huruf, gaya foto, palet) sehingga
terasa karya perancang profesional.

**Yang paling berharga:** pemilik mengirim **tiga layar kasir POS asli** (P04 terang, P17 gelap, P32 tablet) dan
**dua layar laporan/dashboard** (P26 terang, P31 gelap). Ini persis "layar kerja" yang aku khawatirkan tidak ada —
ternyata ada. Ditambah **P12 yang menampilkan satu aplikasi dalam mode terang dan gelap berdampingan**: ini bukti
langsung bahwa permintaan "beberapa tema tinggal dipilih" memang wajar dan bisa dikerjakan.

**Catatan jujur yang tetap berlaku:** mayoritas (sekitar 25 dari 34) tetap **layar menghadap pelanggan** — katalog,
promo, pemesanan. Untuk layar kerja pegawai kita tetap ambil sikap: **pakai bahasa visualnya, tapi tahan diri**
(tanpa foto besar, banner promo, dan animasi dekoratif di kasir/dapur).

## 2. Enam temuan terpenting dari kiriman pemilik

| # | Temuan | Bukti | Akibatnya pada desain kita |
|---|---|---|---|
| 1 | **Layar kasir POS itu inti, dan bentuknya sudah jelas** | P04, P17, P32 | Layar kasir = menu di tengah + **keranjang menempel di kanan** + tombol bayar besar. Pada tablet: tab kategori besar (P32); pada desktop: tab kategori ramping (P17) |
| 2 | **Satu susunan bisa tampil terang atau gelap** | P12 (Light vs Dark berdampingan), P25 & P27 (katalog kopi dua nuansa) | Tema memang bisa diganti tanpa membongkar susunan → **sistem token warna** wajib sejak awal |
| 3 | **Papan pesanan + laporan butuh chip status berwarna** | P31 (Order Reports: Paid / On Progress / Unpaid, hijau-kuning-merah) | Status pesanan & status bayar ditampilkan sebagai label berwarna, bukan kalimat |
| 4 | **Keranjang selalu punya kolom kode promo + ringkasan pajak** | P02, P05, P23, P31 | Voucher undang-teman kita punya tempat alami di layar kasir; pajak/service ditampilkan sebagai baris tersendiri |
| 5 | **Pasar Indonesia: harga Rupiah & menu lokal** | P21 (Rp 70.000), P30 (Mie Ayam, Nasi Uduk, Ayam Geprek, Nasi Goreng Special) | Format harga & contoh menu kita pakai asumsi lokal (Rp 12.000–30.000), nama menu lazim Indonesia |
| 6 | **Varian ukuran itu kebutuhan nyata, bukan hiasan** | P22 (berat 1–4 kg), P23 & P25 (Small/Medium/Large), P28 (perkiraan waktu siap) | Di MVP: opsi **panas/es** dan **ukuran/porsi** (sudah masuk PRD) + "perkiraan waktu siap" (usulan, murah) |

## 3. Pola yang diadopsi (dan sudah masuk `RENCANA_DESAIN_UI.md`)

1. **Kartu menu**: foto + nama + deskripsi singkat + harga + tombol tambah melingkar besar (P02, P08, P14, P15, P16, P18).
2. **Label/merek di kartu**: "Best Seller / Chef's Pick / Populer" (P03, P16) → di aplikasi kita: **menu unggulan / promo / habis**.
3. **Kategori ikon bulat** mendatar (P03, P14, P15, P24) — mudah dijangkau jempol di HP.
4. **Bilah bawah** dengan **tombol tengah menonjol** (P03, P14, P16, P21) — aksi utama selalu terlihat di HP.
5. **Keranjang menempel di kanan + ringkasan bertingkat** (P02, P04, P17, P23, P31, P32) — pola utama layar kasir.
6. **Kolom kode promo di keranjang** (P02, P05, P23, P31) → pintu masuk voucher.
7. **Chip status berwarna** (P31) → status pesanan & status bayar.
8. **Kartu statistik + tabel/grafik sederhana** (P26, P31) → laporan harian & dashboard pemilik.
9. **Pilihan varian (ukuran/porsi/berat)** (P22, P23, P25) → pola detail menu.
10. **Perkiraan waktu siap** (P28) → ditambah sebagai usulan murah di detail/daftar pesanan.
11. **Tab kategori besar di POS tablet** (P32) vs **tab ramping di desktop** (P17) → dasar dua tingkat kepadatan.
12. **Layar sambutan ramah + foto asli** (P22, P33) → untuk halaman pelanggan & pembukaan aplikasi (bukan layar kerja).

## 4. Yang SENGAJA TIDAK ditiru

| Tidak ditiru | Bukti | Alasan |
|---|---|---|
| Foto besar / hero image di **layar kerja** (kasir, dapur, laporan) | P03, P15, P16, P33 | Memakan ruang & memperlambat kasir saat antre; hero hanya untuk katalog pelanggan & papan menu |
| Banner promo di setiap layar | P03, P16 | Mengalihkan perhatian pegawai dari pekerjaan |
| Poster/infografis dicampur sebagai "desain layar" | P06, P07, P09 | Bukan antarmuka yang bisa dipakai; berguna hanya untuk warna/identitas |
| Animasi dekoratif & ilustrasi besar di dalam aplikasi kerja | P24, P34 | Boros kuota & baterai; aturan kita: gerak hanya bila memberi arti |
| Sudut sangat membulat di semua tempat | P18, P22 | Kesan aplikasi pesan makanan; untuk alat kerja dipakai sudut sedang agar lebih padat informasi |
| Teks kecil kontras rendah pada tema gelap | beberapa contoh gelap | Melanggar aturan wajib: kontras ≥4,5:1, huruf dasar 16 px (layar dapur dilihat dari 1–2 m) |
| Tema gelap oranye menyala sebagai bawaan | P20, P29 | Indah untuk iklan, melelahkan untuk shift 8 jam; tetap tersedia sebagai pilihan |

## 5. Keputusan desain usulan agent (diperkuat oleh kiriman pemilik)

1. **Bahasa visual**: kartu bersih, foto produk berkualitas, label status berwarna, tombol besar, angka harga tegas.
2. **Empat tema bawaan** — rujukan gambar nyata dari kiriman pemilik sendiri:
   - **Terang Bersih** ← P16 Grill & Co. / P08 katalog terang *(usulan bawaan)*
   - **Hangat Kedai** ← P15 Brew & Bliss / P25 katalog kopi *(paling dekat Kedai Oasis bila pemilik suka)*
   - **Gelap Dapur** ← P17 Jaegar Resto / P03 Burger gelap
   - **Kontras Tinggi** ← versi paling tegas untuk keterbacaan maksimum
3. **Dua tingkat kepadatan** (dipilih per perangkat, tanpa koding):
   - **Mode Kasir** (padat, cepat, tanpa foto besar) ← P04, P17, P32
   - **Mode Katalog** (kartu besar berfoto) ← P02, P08, P14, P15, P16
4. **Prioritas pola layar kasir** (hasil kiriman pemilik): kiri = pencarian + tab kategori + grid menu; kanan = keranjang
   (item + qty), lalu Sub Total → Pajak → Diskon → **Total**, tombol bayar besar. Di bawah: tombol Simpan/Pesan.
5. **Uji wajib sebelum dirilis:** kontras ≥4,5:1 · area sentuh ≥44 px · huruf dasar 16 px — di **setiap** tema/kepadatan.

## 6. Usulan langkah berikutnya
1. Buat **3 contoh tampilan** memakai pola di atas: **laporan/pemantauan**, **kasir**, **katalog pelanggan** — dalam tema pilihan pemilik.
2. Susun jadi **prototipe bisa diklik** (HP, tablet, laptop) agar pemilik bisa merasakan sendiri.
3. Setelah disetujui → **Tahap 3 (Tech Spec)** memakai desain ini sebagai acuan.
