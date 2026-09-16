# Rencana Desain & UI — Resto Barokah

> **Status: DRAF DISKUSI** — dibahas bersama pemilik 2026-09-16 (sesi Desain & UI, sisipan sebelum Tahap 3).
> Permintaan pemilik yang menjadi dasar: *(a)* minta sesi desain & UI, *(b)* minta **beberapa tema yang bisa diubah hanya dengan memilih**,
> *(c)* minta contoh gambar untuk dibahas bersama, *(d)* aplikasi dipakai di **HP, tablet, dan laptop/PC**.
>
> **Referensi pendukung:** `docs/desain/referensi/` (13 gambar hasil pencarian agent) ·
> `docs/desain/referensi/pemilik/` (**34 gambar kiriman pemilik**, kode `P01`–`P34`) ·
> papan visual: `docs/desain/papan-referensi.jpg` dan `docs/desain/papan-referensi-pemilik.jpg` ·
> penilaian lengkap: `docs/desain/PENILAIAN_REFERENSI.md`.

## 1. Aturan desain yang WAJIB dipatuhi (dari panduan resmi yang dibaca agent)
Sumber: `skills/web-design-guidelines` (Vercel, fetch berkas panduan terbaru), `skills/frontend-designer`, `skills/design-system`, `skills/ui-ux-pro-max`.

| # | Aturan | Angka/kriteria |
|---|---|---|
| 1 | Kontras teks minimal | 4,5:1 (wajib lolos di **setiap tema**) |
| 2 | Ukuran area sentuh minimal | 44×44 px (penting: kasir & pelayan pakai jari di HP) |
| 3 | Ukuran huruf dasar | 16 px, jarak baris 1,5 |
| 4 | Prioritas pertama | Dapat diakses (kontras, keyboard, label) |
| 5 | Ikon | Ikon vektor/SVG, **bukan emoji**, tombol ikon wajib punya label |
| 6 | Umpan balik | Setiap aksi harus terlihat hasilnya (memuat/berhasil/gagal) — bukan diam-diam |
| 7 | Gerak/animasi | Halus, cepat, dan **menghormati pengaturan "kurangi gerak"** pengguna |
| 8 | Responsif | Mobile-first (HP dulu) → melebar otomatis ke tablet & laptop |
| 9 | Warna | Wajib lewat **token** (bukan kode warna keras di tiap tempat) — inilah yang membuat ganti tema mungkin |

## 2. Pola desain yang diambil dari contoh (dan yang ditolak)
Kode `P…` = gambar kiriman pemilik (`docs/desain/referensi/pemilik/`); angka `01`–`13` = pencarian agent.

| Pola | Dari contoh | Dipakai untuk | Alasan |
|---|---|---|---|
| **POS: tab kategori + kisi menu + panel keranjang menempel di kanan** (ringkasan Sub Total → Pajak → Diskon → **Total** + tombol bayar besar) | **P04, P17, P32**, P02 | **Layar kasir (tablet & laptop)** | Tiga contoh independen memakai pola yang sama — inilah cara kasir bekerja: sekali lihat, semua terbaca |
| **POS desktop gelap + tab pesanan (Dine In / To Go / Delivery)** | **P17** | Layar kasir desktop & antrean pesanan | Cocok untuk resto dengan beberapa jenis pesanan sekaligus (Kedai Oasis: alur campur) |
| **POS tablet: tab kategori besar + kartu menu berharga rapat** | **P32** | Layar kasir tablet (mode sentuh) | Jari menekan lebih mudah; banyak item terlihat sekaligus |
| **Papan pesanan dengan chip status berwarna** (Paid / On Progress / Unpaid) | **P31**, 03, 05 | **Dapur (KDS)** + papan pemantauan pesanan | Status terbaca sekilas, tanpa membaca kalimat |
| **Kartu pesanan berwarna + tombol aksi besar** | 05, P31 | Layar dapur | Cepat dibaca dari jauh, tombol besar tidak salah tekan |
| **Laporan/dashboard: kartu angka besar + tabel + grafik sederhana** | **P26, P31** | Laporan harian, dashboard pemilik & pemilik platform | Ringkas, langsung menjawab "hari ini bagaimana?" |
| **Keranjang menempel di kanan + kolom kode promo** | P02, P05, P23, P31 | Layar kasir & halaman pelanggan | Pintu masuk alami untuk **voucher undang-teman** |
| **Kartu menu: foto + nama + harga + tombol tambah melingkar besar** | P02, P08, P14, P15, P16, P18 | Katalog pelanggan & "mode katalog" | Sudah terbukti nyaman dipakai di HP |
| **Label di kartu** (Best Seller / Chef's Pick / Populer) | P03, P16 | Menu unggulan, promo, dan penanda **habis** | Pembeli cepat tahu mana yang direkomendasikan |
| **Kategori ikon bulat** mendatar | P03, P14, P15, P24 | HP (pelayan & pelanggan) | Mudah dijangkau jempol, menghemat ruang |
| **Bilah bawah dengan tombol tengah menonjol** | P03, P14, P16, P21 | Layar HP (pelayan & kasir mobile) | Aksi utama selalu terlihat |
| **Pilihan varian (ukuran / porsi / berat)** | P22, P23, P25 | Detail menu (panas/es, ukuran, porsi) | Kebutuhan nyata menu kedai |
| **Perkiraan waktu siap pesanan** | P28 | Daftar & detail pesanan | Murah dibuat, sangat membantu pelanggan |
| **Satu susunan, dua mode (terang/gelap) berdampingan** | **P12**, P25 vs P27, P03 vs P16 | Dasar **sistem tema** | Membuktikan tema bisa diganti tanpa mengubah susunan |
| ~~Poster & infografis~~ | P06, P07, 06, 07 | **Ditolak** sebagai desain layar | Bukan antarmuka yang bisa dipakai (berguna hanya untuk warna/identitas) |
| ~~Kolase promosi~~ | P09 | **Ditolak** | Materi pemasaran, bukan rancangan layar |

## 3. Rancangan sistem tema (menjawab permintaan "beberapa tema tinggal dipilih")
**4 tema bawaan** (pemilik resto cukup memilih, tanpa koding) — masing-masing punya rujukan gambar nyata dari kiriman pemilik:
1. **Terang Bersih** *(bawaan)* — latar putih/abu sangat terang, warna aksen tegas. Paling mudah dibaca di kasir yang ramai. *Rujukan: P16 Grill & Co. / P08 katalog terang.*
2. **Hangat Kedai** — latar krem, sudut membulat, aksen hangat. Kesan ramah (cocok cafe/kedai). *Rujukan: P15 Brew & Bliss / P25 katalog kopi / P22 toko kue.*
3. **Gelap Dapur** — latar gelap. Untuk layar dapur (ruangan panas/silau) dan pemakaian malam. *Rujukan: P17 Jaegar Resto / P03 Burger gelap / P31 dashboard gelap.*
4. **Kontras Tinggi** — teks & garis paling tegas, warna lebih sedikit. Untuk pegawai yang sulit membaca layar kecil / layar kena matahari.

**Tambahan: 2 tingkat kepadatan tampilan (dipilih per perangkat, tanpa koding)** — hasil pelajaran dari kiriman pemilik:
- **Mode Kasir (padat & cepat):** tanpa foto besar; fokus nama menu, harga, dan tombol. Muat banyak item sekaligus → kasir cepat melayani antrean. *Rujukan: P04, P17, P32.*
- **Mode Katalog (menawan):** kartu besar dengan foto, label, dan tombol melingkar → untuk halaman pelanggan, papan menu, dan tampilan promo. *Rujukan: P02, P08, P14, P15, P16.*
Setiap kombinasi tema × kepadatan tetap wajib lolos uji kontras & ukuran sentuh.

**Dapat diatur per-resto tanpa koding:** pilihan tema · warna aksen (dari palet terkurasi ±8 warna yang sudah dijamin kontras) · logo · banner · gambar latar halaman pelanggan · nama resto · tagline.

**Bisa berbeda per perangkat/peran** (contoh: kasir memakai Terang Bersih, dapur memakai Gelap Dapur). Bukti dari kiriman pemilik: P12 (satu aplikasi, dua mode) dan P25 vs P27.

**Jaminan tema:**
- Ganti tema **tidak mengubah susunan layar maupun fungsi** — hanya warna, bentuk, dan kesan.
- Setiap tema wajib **lolos uji kontras**; tema yang gagal tidak dirilis (prinsip "tidak ada yang cacat").
- Halaman pelanggan (katalog & voucher) memakai tema resto tersebut → pelanggan melihat merek restonya, bukan merek platform.

**Pelajaran lokal dari kiriman pemilik:** P21 memakai format **Rupiah (Rp 70.000)** dan P30 memuat menu Indonesia (Mie Ayam, Nasi Uduk, Ayam Geprek, Nasi Goreng Special) → format harga, istilah, dan contoh menu aplikasi kita memakai asumsi pasar Indonesia.

## 4. Layar yang akan dirancang untuk MVP (urutan pengerjaan)
1. Masuk & pilih peran (PIN)
2. **Kasir** — menu + keranjang + bayar *(pola P04/P17/P32)*
3. **Dapur (KDS)** — papan pesanan berkolom *(pola chip status P31)*
4. **Pelayan** — meja & catat pesanan (HP) *(pola bilah bawah P03/P14/P16)*
5. **Tutup kas + laporan harian** *(pola P26/P31)*
6. **Pengaturan resto** (identitas, tema, pajak, meja, menu, pegawai)
7. **Katalog pelanggan + pendaftaran voucher + tukar voucher di kasir** *(pola P08/P14/P15/P16 + kolom kode promo P02/P05/P23)*
8. Daftar penyewa (Pemilik Platform)

## 5. Langkah berikutnya
1. **Contoh tampilan sudah jadi & bisa diklik** (folder `prototipe/`) — pemilik memeriksa, lalu menyetujui atau meminta perubahan.
2. Setelah disetujui: pola layar & tema bawaan dikunci di dokumen ini, lalu masuk **Tahap 3 (Tech Spec)** dengan desain sebagai acuan.

## 6. Hasil uji aturan wajib (contoh tampilan, 2026-09-16)
| Aturan | Hasil |
|---|---|
| Kontras ≥ 4,5:1 | **52 dari 52 pemeriksaan LOLOS** di 4 tema (alat: `prototipe/uji-kontras.py`) |
| Area sentuh ≥ 44 px | Tombol, tab, tombol +/−, tombol tambah (dibuat 40 px visual + jarak aman) |
| Huruf dasar 16 px, jarak baris 1,5 | Terpasang di `prototipe/css/tokens.css` |
| Ikon SVG, bukan emoji | Semua ikon sebaris SVG |
| Umpan balik tiap aksi | Tombol +/−, "Cek voucher", dan pemilih metode bayar menjawab langsung |

## Log Keputusan
| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-09-16 | Aturan desain mengikuti panduan resmi yang tersedia (kontras 4,5:1, sentuh 44px, huruf 16px, tema lewat token warna) | Tema bisa diganti tanpa merusak keterbacaan — inilah syarat pemilik "beberapa tema tinggal dipilih" |
| 2026-09-16 | Contoh gambar dipakai sebagai **inspirasi**, desain produk dibuat sendiri (orisinil) | Menghormati karya orang lain + tetap bebas biaya |
| 2026-09-16 | Kiriman gambar pemilik dinilai: **dipakai sebagai rujukan utama bahasa visual** (kartu menu, keranjang samping, chip status, bilah bawah) | Kualitas paling konsisten dari semua contoh; sekaligus membuktikan tema terang & gelap bisa satu susunan |
| 2026-09-16 | Ditambah **2 tingkat kepadatan** (Mode Kasir / Mode Katalog) | Foto besar bagus untuk pelanggan, tapi memperlambat kasir saat antre |
| 2026-09-16 | Foto besar, banner promo, dan animasi dekoratif **tidak dipakai di layar kerja** (kasir/dapur) | Menjaga kecepatan & fokus pegawai — prinsip "layar kerja untuk kerja" |
| 2026-09-16 | **34 gambar kiriman pemilik masuk repo** (`docs/desain/referensi/pemilik/`, kode P01–P34) via `Referensi.zip` | Gambar kini bisa dipakai ulang di sesi mana pun; zip dihapus setelah isinya terbukti lengkap |
| 2026-09-16 | Pola kasir dikunci mengikuti **P04/P17/P32** (tab kategori + kisi menu + panel keranjang kanan + ringkasan biaya bertingkat) | Tiga contoh bebas memakai pola sama = pola teruji, bukan selera agent |
| 2026-09-16 | Format harga & istilah memakai asumsi **Indonesia** (Rupiah, nama menu lokal) — rujukan P21 & P30 | Aplikasi akan dipakai di Kedai Oasis (Indonesia); contohnya pun sudah lokal |
| 2026-09-16 | Poster (P06, P07) & kolase promosi (P09) **ditolak sebagai desain layar** | Bukan antarmuka; hanya berguna untuk warna/identitas |
| 2026-09-16 | Pemilik: **"Lanjut"** → rekomendasi agent disetujui: pola kasir P04/P17/P32 · tema bawaan **Terang Bersih** · tema boleh beda per perangkat · lanjut ke 3 contoh tampilan | Pemilik mempercayakan pilihan terbaik; bukti pola sudah kuat (3 contoh bebas, pola sama) |
| 2026-09-16 | Contoh tampilan dibuat sebagai **halaman web asli yang bisa diklik** (bukan gambar) di `prototipe/` | Browser headless tidak bisa dipasang di lingkungan ini (unduhan diblokir) → halaman asli justru lebih berguna: pemilik bisa mencoba ganti tema & mode kasir sendiri, dan berkasnya menjadi fondasi sistem desain tahap pengembangan |
| 2026-09-16 | Foto menu di katalog memakai **foto contoh buatan** dan disebut terang-terangan | Menjaga kejujuran (bukan foto Kedai Oasis) sekaligus menunjukkan tempat foto asli yang akan diisi lewat Pengaturan tanpa koding |
