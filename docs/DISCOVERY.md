# DISCOVERY — Resto Barokah

> **Status dokumen: DISETUJUI** — ditulis 2026-09-16 dan **dikunci atas persetujuan pemilik pada 2026-09-16**
> (pemilik: *"Setuju — kunci draf DISCOVERY"*). Proyek lanjut ke **Tahap 2 (PRD)**.
> Dokumen ini **tetap dokumen hidup** — ide/koreksi baru boleh masuk kapan saja; setiap perubahan
> wajib dicatat di **Log Pembaruan Dokumen (bagian 8)** dan di catatan sesi, bukan ditulis diam-diam.
>
> Dokumen ini adalah **catatan mentah yang lengkap** — semua ide dikumpulkan tanpa dipangkas, termasuk
> yang belum akan dikerjakan. Pemilahan prioritas resmi (MoSCoW) baru dilakukan di Tahap 2.
> Kolom "perkiraan tahap" di bawah bersifat **catatan sementara**, bukan keputusan akhir.
>
> Sumber: diskusi Tahap 1 Discovery (6 ronde, 2026-09-16) + 3 riset internet atas permintaan pemilik.

---

## 1. Problem Statement

**Pemilik UKM kuliner di Indonesia (warung, kedai, cafe, rumah makan) menjalankan operasional harian
tanpa pencatatan yang rapi** — pesanan dicatat di kertas, uang dihitung di kepala, dan pemilik tidak
punya cara cepat untuk tahu performa usahanya. Sementara itu aplikasi kasir yang ada di pasaran
mayoritas berharga Rp55.000–Rp999.000 per outlet per bulan, dengan fitur penting (multi-cabang,
layar dapur, loyalitas pelanggan) yang biasanya baru terbuka di paket mahal. Akibatnya banyak usaha
kecil tetap manual, rawan salah hitung, rawan kecurangan internal, dan sulit berkembang ke cabang kedua.

**Peluang yang ditemukan (fakta riset):**
- Indonesia memiliki **±5,28 juta usaha penyediaan makanan & minuman** (2024), termasuk **±2,51 juta restoran/warung makan**.
- **Jawa Barat provinsi terbanyak** (±1,23 juta usaha) — lokasi pemilik.
- Hanya **±18,8% UMKM** yang sudah terhubung digital (Kemenkop UKM) → mayoritas masih manual.
- Rentang harga pasar: **Rp20.000–150.000/outlet/bulan** untuk segmen UMKM; aplikasi gratis biasanya
  dipangkas (riwayat 30 hari, struk berwatermark, fitur multi-cabang dikunci).

**Yang akan dibangun:** satu platform kasir & operasional F&B yang **dapat dipakai banyak usaha
(penyewa) sekaligus**, di mana **setiap usaha punya merek, pengaturan, dan datanya sendiri**, dan
operasional intinya **gratis dijalankan** (tanpa biaya berlangganan layanan pihak ketiga).

---

## 2. Persona

### Persona 1 — "Pemilik Platform" (pemilik proyek: kamu)
- **Peran:** pemilik produk; bukan programmer (nol coding — sesuai profil pengguna).
- **Yang dia butuhkan:** platform yang bisa ia tawarkan ke banyak resto tanpa harus paham teknis;
  cara mendaftarkan/ mengaktifkan penyewa baru; gambaran kesehatan platform (siapa yang aktif, fitur apa dipakai);
  biaya operasional nol selama belum menghasilkan; hasil yang "tanpa cacat" karena reputasinya taruhannya.
- **Keberhasilan bagi dia:** resto teman (Kedai Oasis) berjalan lancar dengan platform ini, lalu penyewa kedua dan ketiga bergabung.

### Persona 2 — "Pemilik / Admin Resto" (penyewa)
- **Peran:** pemilik warung/cafe/resto; sering ikut bekerja di lapangan (jaga kasir pada jam sibuk).
- **Yang dia butuhkan:** tahu pemasukan hari ini dalam sekali lihat; laporan tutup kasir yang cocok dengan
  uang di laci; **merasa aman dari kecurangan** staf (siapa void, siapa kasih diskon, siapa buka laci);
  mengatur menu & harga sendiri tanpa minta tolong orang teknis; tampilan yang bisa diwarnai & dilogokan
  sesuai mereknya; harga yang terjangkau.
- **Kebutuhannya yang tersembunyi:** ia takut ditinggalkan teknologi, tapi lebih takut **ribet**.

### Persona 3 — "Kasir, Pelayan, dan Dapur" (satu tim, kebutuhan berbeda)
- **Kasir:** kecepatan (antrean panjang saat jam makan), keakuratan (takut selisih kas = dituduh mencuri),
  alur buka/tutup kas yang jelas, hak akses yang mencegahnya melakukan hal sensitif sendirian.
- **Pelayan:** mencatat pesanan di samping meja pelanggan tanpa kertas, mengirim ke dapur seketika,
  tahu meja mana masih kosong/terisi/siap disajikan, bisa pindah meja bila tamu pindah.
- **Dapur/bar:** daftar pesanan yang jelas urutannya, instruksi khusus terlihat mencolok
  (tanpa jeroan, level 5, alergi kacang), bisa menandai menu habis, dan tidak salah antar hidangan.

### Aktor pendukung (perlu dicatat, prioritas menyusul)
Pelanggan (lihat menu, kumpulkan poin, tukar voucher) · Calon pelanggan (terima undangan & voucher dari tautan) ·
Admin cabang (mengelola satu outlet) · Akuntan/konsultan pajak resto (butuh ekspor data — bukan pengguna langsung aplikasi) ·
Staf kebersihan (penanda meja selesai dibersihkan — peran ringan, menyusul).

---

## 3. Analisis Kompetitor / Solusi yang Ada (ringkas)

Harga dari halaman publik pesaing, Juli 2026 (sumber perbandingan pihak ketiga; angka dapat berubah):

| Aplikasi | Harga per outlet/bulan | Catatan |
|---|---|---|
| Moka POS | Rp299rb (Pro Rp499rb, Enterprise Rp799rb) | Manajemen meja & QR order di paket atas |
| Majoo | Rp249rb ke atas | Sejak Mei 2026 paket gratis dihapus; add-on dijual terpisah |
| Pawoon | Gratis terbatas, Basic Rp149rb, Pro Rp299rb | Gratis dibatasi jumlah transaksi harian |
| Olsera | ±Rp107rb–224rb (tahunan) | Ritel & F&B, KDS, multi-outlet |
| Qasir | Gratis (riwayat 30 hari) · Pro ±Rp58rb | Segmen mikro |
| Kasir Pintar | Gratis (struk berwatermark) · Pro Rp55,5rb | Segmen mikro |
| Kasirnesia | Rp0 / Rp49rb / Rp99rb / Rp149rb | Bertingkat per jumlah cabang |
| diKasirin | mulai Rp20rb | Menjual mode offline + laporan via WhatsApp |
| iReap POS | Rp42rb–99rb | Kuat di mode offline |
| Kaspoint | Sekali bayar Rp349rb (Lite) | Berjalan 100% offline |

**Fitur yang hampir semua pesaing jual** (menjadi standar pasar, bukan pembeda):
kasir + cetak struk · manajemen menu · laporan penjualan · stok · multi-outlet (biasanya paket atas) ·
mode offline · Kitchen Display System (biasanya paket atas) · QR menu & self-order · poin loyalitas ·
promo & voucher · shift karyawan · multi-pembayaran (tunai/QRIS/e-wallet) · laporan via WhatsApp.

**Kesimpulan yang diambil (analisis pemilik + agent):** celah pembeda yang paling masuk akal untuk
proyek ini adalah **multi-cabang + layar dapur + loyalitas/voucher di harga segmen UMKM**, ditambah dua
pembeda yang jarang ada di pasar ini: **(a) setiap resto bisa mengubah tampilan & pengaturan sendiri
tanpa koding**, dan **(b) pemisahan "Cek Voucher" (baca saja) dan "Pakai Voucher" (sekali pakai, ber-PIN)**.

**Nama yang sudah dipakai pihak lain (dicek saat mempertimbangkan nama produk):** "Kasirin"/"KasirinAja",
"Restoku". Nama produk platform **belum diputuskan** (usulan: Langgan, Baraka, Sajian, Rame, Nota).

---

## 4. Daftar Mentah Semua Ide Fitur (belum diprioritaskan)

Kolom **"Catatan tahap"** = perkiraan sementara (G1 dikerjakan lebih dulu untuk cafe pilot; G2 setelah
pilot terbukti; G3 setelah ada pemasukan; **Tidak diambil** = sengaja dikeluarkan). Prioritas resminya dibahas di Tahap 2.

### 4.1 Fondasi platform (khusus pemilik platform)
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 1 | Pendaftaran & pengaktifan penyewa (resto) baru oleh pemilik platform | G1 |
| 2 | Pemisahan data antar-penyewa (data Resto A tidak bisa dilihat Resto B) | G1 (wajib) |
| 3 | Pemisahan data antar-cabang di dalam satu penyewa | G1 (wajib) |
| 4 | Pengaturan identitas & tampilan per-penyewa (nama, logo, warna, banner, gambar latar, tagline) | G1 |
| 5 | Tombol hidup/mati fitur per-penyewa (on/off modul) | G1 (sebagian) |
| 6 | Dashboard pemilik platform: penyewa aktif, pemakaian fitur, kesehatan platform | G2 |
| 7 | Penagihan langganan penyewa (paket & tagihan) | G3 |
| 8 | Pendaftaran penyewa mandiri (self-service) | G3 (5–10 penyewa pertama dibantu manual) |

### 4.2 Pesanan, meja, dan alur pelayanan
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 9 | Pilih meja / nomor meja saat mencatat pesanan | G1 |
| 10 | Tanda jenis pesanan: makan di tempat / bawa pulang / antar (ojol) | G1 |
| 11 | Catatan khusus pesanan (tanpa es, kurang pedas, tanpa jeroan) | G1 |
| 12 | Simpan tagihan (open bill) — pelanggan menambah pesanan sebelum bayar | G1 |
| 13 | Pindah meja & gabung meja | G2 (pindah meja dasar bisa G1) |
| 14 | Split bill (pisah tagihan antar pelanggan satu meja) | G2 |
| 15 | Reservasi meja (nama, jam datang, kunci meja) | G2 |
| 16 | Daftar tunggu (waitlist) + estimasi waktu | G2 (notifikasi di aplikasi, bukan SMS) |
| 17 | Status meja real-time (kosong / terisi / siap disajikan / kotor) | G1 (dasar) |
| 18 | Notifikasi meja kotor → bersih untuk staf kebersihan | G2 |
| 19 | Panggil pelayan digital (tombol dari meja pelanggan) | G3 |
| 20 | QR menu (lihat menu tanpa pesan) | G1 |
| 21 | QR pesan sendiri (self-order) | G2 |
| 22 | Pesan-antar sendiri + bayar di meja (pay at table) | G3 |

### 4.3 Transaksi & pembayaran
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 23 | Catat metode pembayaran (tunai, QRIS, transfer, e-wallet, kartu) — **pencatatan, bukan integrasi** | G1 |
| 24 | Diskon (persen/nominal) + voucher | G1 |
| 25 | Pajak restoran (PB1) & service charge otomatis | G1 |
| 26 | Aturan pembulatan & tip | G1 |
| 27 | Buka/tutup kas + rekonsiliasi selisih uang laci per shift | G1 |
| 28 | Integrasi pembayaran otomatis (QRIS dinamis / e-wallet) | G3 (berbiaya/potongan) |
| 29 | Integrasi resmi pesanan ojol (GoFood/GrabFood/ShopeeFood) | G3 (kerja sama merchant + komisi) — **input manual dulu di G1** |
| 30 | Retur / refund | G2 |

### 4.4 Dapur (KDS & printer)
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 31 | Kirim pesanan ke dapur otomatis (layar KDS) | G1 |
| 32 | Cetak tiket dapur otomatis | G1 |
| 33 | Pemisahan otomatis makanan → dapur, minuman → bar | G1 |
| 34 | Urutan antrean FIFO (paling lama menunggu di atas) | G1 |
| 35 | Tanda jenis pesanan (dine-in/takeaway/ojol) di layar dapur | G1 |
| 36 | Ubah status hidangan (sedang dimasak → siap diantar) | G1 |
| 37 | Instruksi khusus ditampilkan mencolok (mis. huruf merah) | G1 |
| 38 | Gabung item sama dari meja berbeda (Total Nasi Goreng: 5 porsi) | G2 |
| 39 | Timer peringatan (hijau → kuning → merah bila lewat target waktu) | G2 |
| 40 | Notifikasi ke pelayan saat hidangan siap (di aplikasi; jam pintar tidak sekarang) | G2 |
| 41 | Tombol "menu habis" dari layar dapur (mengunci menu di kasir & QR) | G1 |
| 42 | Validasi menu antar (mencegah salah antar hidangan) | G2 |
| 43 | Cetak struk pelanggan — printer termal | G1 |
| 44 | Dukungan printer Bluetooth / USB / LAN | G1 (uji di cafe pilot — **risiko teknis utama**) |
| 45 | Struk digital via email | G2 (WhatsApp berbayar → G3) |

### 4.5 Manajemen & pengaturan oleh pemilik resto
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 46 | Kelola menu: kategori, item, varian (panas/es, ukuran), tambahan/topping, foto, harga, urutan, item unggulan | G1 |
| 47 | Harga khusus per cabang & penanda menu habis manual | G1 |
| 48 | Pengaturan jam buka, pajak, service charge, header/footer struk | G1 |
| 49 | Kelola cabang (tambah cabang, menu/harga khusus cabang) | G1 (dasar) → G3 (lengkap) |
| 50 | Kelola pegawai: tambah pegawai, peran, PIN kasir, izin void/diskon | G1 |
| 51 | Jejak audit: siapa melakukan void, diskon manual, buka laci, ubah harga | G1 |
| 52 | Persetujuan khusus (PIN/kode) untuk tindakan di luar wewenang | G1 |
| 53 | Pantau laporan sesuai peran (pemilik = semua cabang; admin cabang = cabangnya) | G1 |
| 54 | Laporan harian per shift (omzet, transaksi, metode bayar, menu terlaris, kas, selisih, void/diskon) | **G1 (dipilih pemilik: laporan A)** |
| 55 | Laba-rugi sederhana (butuh pencatatan pengeluaran: belanja, gaji, listrik, sewa) | G3 (laporan B) |
| 56 | Pembukuan lengkap (jurnal, neraca, arus kas, PPh, faktur pajak, penyusutan) | **Tidak diambil** — jembatannya ekspor Excel untuk akuntan |
| 57 | Ekspor laporan ke Excel/CSV | G2 |
| 58 | Mode offline (tetap jalan saat internet mati, sinkron otomatis) | G3 (pilot internetnya lancar) |
| 59 | Aplikasi jalan di perangkat apa pun (HP/tablet/laptop) — berbasis browser | G1 |
| 60 | Dapat dipasang ke layar HP seperti aplikasi (tanpa toko aplikasi) | G2 |
| 61 | Aplikasi Android/iOS dari toko aplikasi (ada biaya pendaftaran) | G3 (menunggu pemasukan) |

### 4.6 Stok & bahan baku
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 62 | Penanda menu habis manual (kasir/dapur) | G1 |
| 63 | Catat stok sederhana + opname berkala | G1 |
| 64 | Resep sederhana: 1 menu = beberapa bahan → stok berkurang otomatis | G2 (dipilih pemilik) |
| 65 | Resep lengkap + konversi satuan (kg→gram) + susut/terbuang | G3 |
| 66 | HPP / harga pokok per menu otomatis | G3 |
| 67 | Transfer stok antar cabang, gudang pusat, penerimaan barang (PO), kedaluwarsa (FIFO) | G3 |
| 68 | Menu engineering (simulasi harga & HPP sebelum rilis menu) | G3 |

### 4.7 Pelanggan, loyalitas, & kampanye
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 69 | Halaman katalog publik per resto (foto, harga, jam buka, lokasi, tombol WhatsApp) | G2 |
| 70 | Keanggotaan digital pelanggan (tanpa kartu fisik) | G1 (dasar) / G2 (lengkap) |
| 71 | Poin loyalitas (kumpulkan & tukarkan: diskon, menu gratis) | G2 |
| 72 | Undang teman / referensi (kode & tautan unik) | G1 (via kampanye voucher) |
| 73 | Voucher: tautan undangan → pendaftaran → barcode → tukar di kedai | **G1** |
| 74 | **Cek Voucher (baca saja, tidak menghanguskan)** & **Pakai Voucher (sekali pakai + PIN)** — dipisah | **G1** |
| 75 | Aturan voucher dapat diatur admin (persen/nominal, minimum belanja, batas maksimal diskon, masa berlaku, kuota, anggaran kampanye) | G1 |
| 76 | Voucher otomatis via tautan kampanye; teman dapat hadiah, pengundang dapat hadiah/poin | G1 (dasar) |
| 77 | Promo terjadwal + segmentasi pelanggan (sering datang vs lama tidak datang) | G2 |
| 78 | Blast promo massal via WhatsApp/email | G3 via WhatsApp (berbayar); email gratis di G2 |
| 79 | Tingkatan loyalitas (silver/gold/platinum) | G3 |
| 80 | Ukur hasil kampanye (KOL/kode promo terpakai berapa kali) | G3 |
| 81 | Info alergen/kalori pada menu | G2 |
| 82 | Pelanggan melacak status pesanan sendiri | G2 |
| 83 | Ulasan/rating setelah makan (tautan dari struk digital) | G2 |

### 4.8 Pegawai (HR) — versi ringan
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 84 | Absensi sederhana (tombol masuk/pulang + PIN) | G3 |
| 85 | Jadwal shift & tukar shift | G3 |
| 86 | Rekap jam kerja & dasar hitung gaji (pemilik menghitung manual) | G3 |
| 87 | Penggajian otomatis penuh, kasbon, lembur, slip gaji | **Tidak diambil** (aturan pajak/BPJS → risiko salah) |
| 88 | Absensi pengenalan wajah & pelacakan lokasi (GPS) | **Tidak diambil** (data pribadi sensitif / UU PDP, tidak sebanding manfaat) |
| 89 | KPI pegawai, pelacakan kesalahan, manajemen cuti | **Tidak diambil** (bukan kebutuhan penyewa sasaran) |

### 4.9 Kurir internal, gudang, teknisi (peran pendukung)
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 90 | Catat pengantaran internal + setoran uang COD | G3 |
| 91 | Bukti pengantaran digital (foto/tanda tangan) | G3 |
| 92 | Pelacakan kurir langsung + navigasi peta | **Tidak diambil** (butuh akun penagihan peta = berbiaya) |
| 93 | Tiket kerusakan alat, jadwal servis, inventaris aset | **Tidak diambil** (beban perawatan tanpa nilai bagi sasaran) |

### 4.10 Keamanan & anti-kecurangan (lintas fitur — permintaan penting pemilik)
| # | Ide fitur | Catatan tahap |
|---|---|---|
| 94 | Pemisahan data antar-penyewa & antar-cabang (isolasi penuh) | G1 |
| 95 | Hak akses per peran (pemilik, admin cabang, kasir, pelayan, dapur) | G1 |
| 96 | Jejak audit tindakan sensitif + siapa pelakunya | G1 |
| 97 | PIN untuk void/diskon/pakai voucher/ubah pengaturan | G1 |
| 98 | Verifikasi pelanggan: **"Daftar dengan Google" (utama)** + email terverifikasi (jalur kedua), tanpa SMS | G1 |
| 99 | Anti akun palsu: satu voucher per identitas/kampanye, batas per perangkat, tolak email sekali-pakai, normalisasi alamat Gmail (titik & tanda +) | G1 |
| 100 | Voucher sekali pakai + kode acak (tidak bisa ditebak/diurutkan) + batas scan per kasir | G1 |
| 101 | Log semua percobaan cek/scan voucher (mendeteksi penebakan kode) | G1 |
| 102 | Laporan anomali klaim (lonjakan, jam tidak wajar, kasir tertentu) | G2 |
| 103 | Kata sandi/PIN pegawai, sesi otomatis berakhir, pemisahan hak antara kasir & pemilik | G1 |

---

## 5. Batasan & Konteks Proyek

| Aspek | Kondisi (fakta dari diskusi) |
|---|---|
| **Biaya** | **Nol rupiah dulu** sampai menghasilkan. Yang sengaja dihindari karena berbiaya: payment gateway (potongan per transaksi), WhatsApp API (per pesan), SMS (per pesan), toko aplikasi (biaya pendaftaran), domain (tahunan), peta/navigasi (butuh akun penagihan) |
| **Waktu** | **Tidak ada target** — prinsip pemilik: *"yang penting bener dulu"* |
| **Tim** | Pemilik bekerja sendiri; semua pekerjaan teknis dikerjakan AI agent. Pendampingan penyewa (resto teman/calon penyewa lain) dilakukan pemilik |
| **Kemampuan teknis** | Pemilik: nol coding — semua istilah harus dijelaskan tanpa jargon; pemilik tidak akan mengedit kode/dokumen teknis |
| **Perangkat** | Aplikasi harus jalan di perangkat apa pun (HP Android, tablet, laptop/komputer kasir) — dipilih: aplikasi berbasis browser |
| **Pilot pertama** | **Kedai Oasis** — cafe milik teman pemilik, dipinjamkan **gratis**. Kondisi: **ada printer struk & internet lancar** (karena itu mode offline tidak mendesak untuk pilot) |
| **Pasar sasaran** | Cafe/toko/warung/resto mana pun di Indonesia; fokus awal Jawa Barat (provinsi dengan usaha F&B terbanyak) |
| **Merek** | Setiap penyewa memakai nama, logo, dan warna sendiri. Nama produk platform belum diputuskan |
| **Model bisnis (rencana)** | Gratis untuk beberapa penyewa pertama → langganan per cabang di harga bawah pasar (usulan: Rp39rb–99rb/bulan). Fitur penagihan belum dibangun di versi pertama (pengaktifan manual) |
| **Bahasa & mata uang** | Bahasa Indonesia, Rupiah |
| **Fitur yang diminta pemilik secara khusus** | Semua alur pesanan disediakan & bisa dipilih pengguna · penyesuaian tampilan/fitur tanpa koding · mode "Cek Voucher" terpisah dari "Pakai Voucher" · keamanan anti-kecurangan voucher · sesi desain & UI |
| **Urutan pengerjaan yang disepakati** | Bergelombang: **G1** (operasional inti untuk cafe pilot) → **G2** (loyalitas & layanan pelanggan) → **G3** (naik kelas, butuh pemasukan). Gelombang berikutnya tidak dimulai sebelum gelombang sebelumnya lulus uji — menjaga prinsip **"tidak ada yang cacat"** |

---

## 6. Keputusan Awal yang Sudah Disepakati (2026-09-16)

1. **Bentuk produk:** platform multi-penyewa (banyak resto memakai satu sistem, datanya terpisah), bukan aplikasi satu resto.
2. **Multi-cabang:** disiapkan sejak awal (struktur data mengenal cabang di dalam penyewa).
3. **Perangkat:** aplikasi berbasis browser (HP/tablet/laptop), tanpa biaya toko aplikasi.
4. **Semua alur pesanan** (dilayani ke meja / ambil di kasir / dua-duanya) disediakan dan dipilih per-resto.
5. **Penyesuaian tanpa koding** (nama, logo, warna, banner, menu, pajak, metode bayar, poin/voucher, pegawai, cabang) — cakupannya diperluas atas permintaan pemilik, dengan aturan "hanya pengaturan yang sudah teruji yang ditampilkan".
6. **Merek per-penyewa** (nama & logo sendiri), pemilik platform tetap punya dashboard pusat.
7. **Pesanan ojol:** dicatat manual oleh kasir (dengan penanda saluran) pada tahap awal; integrasi resmi menyusul di G3.
8. **Pembayaran:** hanya dicatat (tunai/QRIS/e-wallet) tanpa integrasi otomatis pada tahap awal.
9. **Pesanan pelanggan:** input oleh pegawai dulu (G1); QR pesan sendiri menyusul (G2); jalur QR pesan sendiri tetap menjadi rencana karena pemilik ingin semua alur tersedia.
10. **Laporan G1:** Laporan Harian/Kas per Shift (versi A) — laba-rugi (B) menyusul, pembukuan lengkap (C) tidak diambil.
11. **Stok bertahap:** G1 penanda habis + opname → G2 resep sederhana → G3 resep lengkap + HPP + belanja supplier.
12. **Verifikasi pelanggan:** "Daftar dengan Google" sebagai jalur utama (gratis, email terverifikasi, tanpa kuota email), email terverifikasi sebagai jalur kedua (lewat penyedia gratis Resend/Mailjet/Brevo, **bukan** email bawaan Supabase yang hanya 2 email/jam), SMS menyusul bila sudah menghasilkan.
13. **Voucher undang-teman** menjadi fitur G1 dengan aturan yang diatur admin + 10 lapis pengaman anti-kecurangan (daftar lengkap di bagian 4.10).

---

## 7. Pertanyaan Terbuka (untuk dibahas di tahap berikutnya)

1. **Nama & logo produk platform** — belum diputuskan (kandidat: Langgan, Baraka, Sajian, Rame, Nota). Tiap penyewa pakai merek sendiri, tapi halaman masuk & dashboard pusat butuh satu nama.
2. **Arah desain & UI** — **permintaan pemilik; dijadwalkan sebagai sesi tersendiri setelah PRD** (hasilnya mockup yang bisa dilihat & dinilai pemilik, bukan penjelasan teknis).
3. **Target metrik keberhasilan** (mis. berapa penyewa aktif dalam 6 bulan, berapa transaksi/hari di pilot) — dibahas di Tahap 2.
4. **Harga langganan final** per cabang & isi paketnya — dibahas setelah pilot berjalan (belum perlu di versi pertama).
5. **Mode offline**: apakah wajib untuk penyewa selain Kedai Oasis, dan pada tahap mana.
6. **Integrasi resmi ojol**: apakah benar-benar memungkinkan tanpa biaya; perlu riset kerja sama merchant sebelum dijanjikan.
7. **Batasan pasti layanan gratis** (kapasitas penyimpanan, jumlah permintaan per bulan, jumlah penyewa yang bisa dilayani) — akan disampaikan terbuka di Tahap 3 beserta pilihan bila sudah mentok.
8. **Siapa yang mendampingi penyewa baru** (pemilik sendiri?) dan berapa lama waktu yang realistis per penyewa.
9. **Alih kepemilikan/pengelolaan domain & email pengirim** saat nanti ada pemasukan — perlu disiapkan agar tidak putus di tengah jalan.
10. **Kebijakan privasi & persetujuan data pelanggan** (data pelanggan yang tersimpan: nama, email, riwayat transaksi) — dibahas di Tahap 3/4 sebagai syarat kepercayaan, terutama untuk penyewa yang menanyakan legalitas.
11. **Detail fitur tambahan yang pemilik janjikan akan disampaikan menyusul** — akan dicatat sebagai pembaruan dokumen ini.

---

## 8. Log Pembaruan Dokumen

| Tanggal | Pembaruan | Oleh |
|---|---|---|
| 2026-09-16 | Dokumen dibuat (DRAF) dari 6 ronde diskusi Discovery + 3 riset internet (pesaing & harga, loyalitas/referral, keamanan verifikasi) + saringan fitur 4 keranjang | Agent |
| 2026-09-16 | **Dokumen DISETUJUI & dikunci oleh pemilik** (7 ronde diskusi selesai) → proyek lanjut ke Tahap 2 (PRD). Setelah dikunci: saringan fitur disetujui, verifikasi pelanggan = "Daftar dengan Google" utama + email kedua, "Kedai Oasis" terkonfirmasi sebagai cafe pilot | Pemilik + Agent |
