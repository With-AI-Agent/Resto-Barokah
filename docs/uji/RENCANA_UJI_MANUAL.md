# RENCANA UJI MANUAL — daftar periksa Lee (yang HARUS dicoba mata & tangan manusia)

> **Dibuat 2026-09-23** atas permintaan Lee, sebagai syarat menunda uji peramban otomatis
> (butir **T-026**) ke Fase 11. Kesepakatannya: boleh ditunda, **asal semua yang perlu dicek
> tercatat rapi, dijelaskan, dan bisa dicentang**.

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
| M-12 | **Cetak ke printer sungguhan** | Semua uji di atas percuma kalau kertasnya tidak keluar | 1) Sambungkan printer termal 2) Selesaikan pembayaran 3) Tekan cetak | Kertas keluar, tulisan tidak terpotong di kanan, angka terbaca | Terpotong, huruf aneh, atau tidak keluar | 🔴 BUTUH ALAT (printer Kedai Oasis — butir **T-002**) | |

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

## Bagian G — Riwayat hasil

Diisi saya setiap kali Lee melaporkan hasil.

| Tanggal | ID | Hasil | Catatan |
|---|---|---|---|
| — | — | — | Belum ada laporan; daftar baru dibuat 2026-09-23 |
