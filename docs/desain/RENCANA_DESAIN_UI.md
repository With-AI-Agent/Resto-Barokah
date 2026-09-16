# Rencana Desain & UI — Resto Barokah

> **Status: DRAF DISKUSI** — dibahas bersama pemilik 2026-09-16 (sesi Desain & UI, sisipan sebelum Tahap 3).
> Permintaan pemilik yang menjadi dasar: *(a)* minta sesi desain & UI, *(b)* minta **beberapa tema yang bisa diubah hanya dengan memilih**,
> *(c)* minta contoh gambar untuk dibahas bersama, *(d)* aplikasi dipakai di **HP, tablet, dan laptop/PC**.

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
| Pola | Dari contoh | Dipakai untuk | Alasan |
|---|---|---|---|
| **Papan pesanan berkolom status** (Baru → Diproses → Siap → Selesai) | 03, 05 | **Layar dapur (KDS)** & papan pemantauan pesanan | Koki langsung tahu mana yang paling lama menunggu |
| **Panel menu + keranjang di samping** | 02 | **Layar kasir (tablet/laptop)** | Sekali lihat: menu, isi pesanan, total, tombol bayar |
| **Kartu pesanan berwarna + tombol aksi besar** | 05 | Layar dapur | Cepat dibaca dari jauh, tombol besar tidak salah tekan |
| **Mobile-first: kategori ikon + kisi menu + keranjang bawah** | 04, 08 | **Layar pelayan (HP)** | Dipakai sambil berdiri di samping meja pelanggan |
| **Warna aksen kuat sebagai identitas** | 09, 10 | Pembuktian bahwa tema bisa diganti | Menunjukkan pengaruh besar warna terhadap kesan keseluruhan |
| **Kartu menu: foto + nama + harga + tombol tambah melingkar besar** | kiriman pemilik (Grill & Co., Burger House, Brew & Bliss) | Katalog pelanggan & "mode katalog" | Sudah terbukti nyaman dipakai di HP |
| **Keranjang menempel di kanan + ringkasan bertingkat (subtotal → pajak → diskon → total) + kolom kode promo** | kiriman pemilik (Burger District) | **Layar kasir tablet/laptop** | Paling dekat dengan cara kasir bekerja; kolom kode promo jadi pintu masuk voucher kita |
| **Chip/label status berwarna** | kiriman pemilik (download.jfif) | Papan pesanan & daftar transaksi | Status terbaca sekilas, tanpa membaca kalimat |
| **Bilah bawah dengan tombol tengah menonjol** | kiriman pemilik (Grill & Co.) | Layar HP (pelayan & kasir mobile) | Terjangkau jempol; aksi utama selalu terlihat |
| **Pilihan varian ukuran (S/M/L) & label menu unggulan** | kiriman pemilik (coffee shop, Grill & Co.) | Detail menu (panas/es, ukuran, porsi) | Kebutuhan nyata menu kedai |
| ~~Slide presentasi~~ | 06, 07 | **Ditolak** | Bukan desain layar aplikasi (hanya materi presentasi) |

## 3. Rancangan sistem tema (menjawab permintaan "beberapa tema tinggal dipilih")
**4 tema bawaan** (pemilik resto cukup memilih, tanpa koding) — masing-masing sudah punya contoh nyata dari kiriman pemilik:
1. **Terang Bersih** *(bawaan)* — latar putih/abu sangat terang, warna aksen tegas. Paling mudah dibaca di kasir yang ramai. *Rujukan: Grill & Co. versi terang.*
2. **Hangat Kedai** — latar krem, sudut membulat, aksen hangat. Kesan ramah (cocok cafe/kedai). *Rujukan: Brew & Bliss / bakery coklat-krem.*
3. **Gelap Dapur** — latar gelap. Untuk layar dapur (ruangan panas/silau) dan pemakaian malam. *Rujukan: Burger House versi gelap.*
4. **Kontras Tinggi** — teks & garis paling tegas, warna lebih sedikit. Untuk pegawai yang sulit membaca layar kecil / layar kena matahari.

**Tambahan: 2 tingkat kepadatan tampilan (dipilih per perangkat, tanpa koding)** — hasil pelajaran dari kiriman pemilik:
- **Mode Kasir (padat & cepat):** tanpa foto besar; fokus nama menu, harga, dan tombol. Muat banyak item sekaligus → kasir cepat melayani antrean.
- **Mode Katalog (menawan):** kartu besar dengan foto, label, dan tombol melingkar seperti kiriman pemilik → untuk halaman pelanggan, papan menu, dan tampilan promo.
Setiap kombinasi tema × kepadatan tetap wajib lolos uji kontras & ukuran sentuh.

**Dapat diatur per-resto tanpa koding:** pilihan tema · warna aksen (dari palet terkurasi ±8 warna yang sudah dijamin kontras) · logo · banner · gambar latar halaman pelanggan · nama resto · tagline.

**Bisa berbeda per perangkat/peran** (contoh: kasir memakai Terang Bersih, dapur memakai Gelap Dapur).

**Jaminan tema:**
- Ganti tema **tidak mengubah susunan layar maupun fungsi** — hanya warna, bentuk, dan kesan.
- Setiap tema wajib **lolos uji kontras**; tema yang gagal tidak dirilis (prinsip "tidak ada yang cacat").
- Halaman pelanggan (katalog & voucher) memakai tema resto tersebut → pelanggan melihat merek restonya, bukan merek platform.

## 4. Layar yang akan dirancang untuk MVP (urutan pengerjaan)
1. Masuk & pilih peran (PIN)
2. **Kasir** — menu + keranjang + bayar
3. **Dapur (KDS)** — papan pesanan berkolom
4. **Pelayan** — meja & catat pesanan (HP)
5. **Tutup kas + laporan harian**
6. **Pengaturan resto** (identitas, tema, pajak, meja, menu, pegawai)
7. **Katalog pelanggan + pendaftaran voucher + tukar voucher di kasir**
8. Daftar penyewa (Pemilik Platform)

## 5. Langkah berikutnya
1. **Pemilihan arah** (sedang dibahas bersama pemilik) — pola layar kasir, tema bawaan, dan tema per-peran.
2. **Aku buat 3 contoh tampilan (mockup)** dalam arah yang dipilih — supaya pemilik bisa membandingkan gambar, bukan penjelasan.
3. **Prototipe bisa diklik** di layar (HP/tablet/laptop) untuk dirasakan sendiri.
4. Setelah disetujui → masuk **Tahap 3 (Tech Spec)** dengan desain sebagai acuan.

## Log Keputusan
| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-09-16 | Aturan desain mengikuti panduan resmi yang tersedia (kontras 4,5:1, sentuh 44px, huruf 16px, tema lewat token warna) | Tema bisa diganti tanpa merusak keterbacaan — inilah syarat pemilik "beberapa tema tinggal dipilih" |
| 2026-09-16 | Contoh gambar dipakai sebagai **inspirasi**, desain produk dibuat sendiri (orisinil) | Menghormati karya orang lain + tetap bebas biaya |
| 2026-09-16 | Kiriman 10 gambar pemilik dinilai: **dipakai sebagai rujukan utama bahasa visual** (kartu menu, keranjang samping, chip status, bilah bawah) | Kualitas paling konsisten dari semua contoh; sekaligus membuktikan tema terang & gelap bisa satu susunan |
| 2026-09-16 | Ditambah **2 tingkat kepadatan** (Mode Kasir / Mode Katalog) | Foto besar bagus untuk pelanggan, tapi memperlambat kasir saat antre |
| 2026-09-16 | Foto besar, banner promo, dan animasi dekoratif **tidak dipakai di layar kerja** (kasir/dapur) | Menjaga kecepatan & fokus pegawai — prinsip "layar kerja untuk kerja" |

> **Catatan kejujuran penyimpanan:** 10 gambar kiriman pemilik **tidak bisa disimpan** ke repo (berkasnya tidak sampai ke
> ruang kerja — hanya terlihat di percakapan). Isi & penilaiannya dicatat lengkap di `docs/desain/PENILAIAN_REFERENSI.md`
> supaya tidak hilang. Gambar asli dari pencarian agent tersimpan di `docs/desain/referensi/`.
