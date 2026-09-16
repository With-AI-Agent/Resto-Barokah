# Contoh Tampilan (Mockup) — Resto Barokah

> **Status:** contoh tampilan berbentuk **halaman web asli yang bisa diklik** + **papan bukti gambar**.
> Dibuat 2026-09-16 · diperhalus pada ronde 3 (standar kehalusan 8 aspek, lihat `docs/desain/RENCANA_DESAIN_UI.md` §7).
> Halaman ini **bukan aplikasi jadi** — angkanya data contoh, dan tidak ada data yang disimpan.

## Apa isinya

| Berkas | Isi |
|---|---|
| `index.html` | Halaman awal: 4 pintu masuk + ringkasan apa yang diperhalus di ronde 3 |
| `01-laporan.html` | Laporan & pemantauan pemilik/admin: kartu angka, grafik omzet per jam (tumbuh saat dibuka), papan pesanan, tabel transaksi, tombol Tutup Kas (jendela mengambang) |
| `02-kasir.html` | Layar kasir (POS): rel menu kiri, kisi menu, keranjang menempel kanan (PB1 10% + Service 5% + diskon voucher), pilihan cara bayar, tombol bayar → jendela mengambang + pesan berhasil |
| `03-katalog.html` | Katalog pelanggan (2 layar HP): beranda (hero promo, kategori bulat, kartu menu, bilah keranjang kaca, navigasi bawah) dan detail menu (level pedas, tambahan, catatan, jumlah) |
| `04-tema.html` | Galeri **10 tema** berdampingan — susunan sama, suasana berbeda |
| `css/tokens.css` | Sistem desain: token 3 lapis (dasar → arti → komponen), 10 tema, 13 `@font-face` lokal, seluruh komponen |
| `js/ui.js` | Tanpa pustaka luar: pemilih 10 tema, kerapatan (Mode Kasir / Mode Katalog), keranjang +/−, jendela mengambang, pesan berhasil, animasi masuk, contoh "Cek Voucher" |
| `aset/` | 7 foto menu **contoh buatan** + `aset/font/` 13 huruf woff2 (lisensi OFL, ada berkas lisensinya) |
| `uji-kontras.py` | Uji kontras otomatis semua tema → **130/130 lolos** |
| `buat-palet.py` | Menggambar `docs/desain/palet-tema.png` langsung dari `tokens.css` |
| `alat/gambar.js` | Alat gambar papan bukti (membaca warna & huruf yang sama dengan `tokens.css`) |
| `alat/mockup.js` | Membuat **5 papan bukti** di `docs/desain/mockup/` |
| `alat/periksa-halaman.py` | Periksa halaman: aset ada, id jendela mengambang cocok, tag seimbang, token terdefinisi → **135/135 lolos** |

## Cara melihat

```bash
# dari folder prototipe/
python3 -m http.server 8080
# lalu buka http://localhost:8080
```

Klik **Tema** di kanan atas untuk mencoba 10 tema; pilihanmu diingat di perangkat ini saja
(`localStorage` kunci `rb-tema`, `rb-kerapatan`). Halaman juga menyediakan pengaturan "kurangi gerak":
bila perangkat memintanya, semua animasi & transisi mati otomatis.

## Cara memeriksa sendiri (tanpa perlu jeli)

```bash
python3 prototipe/uji-kontras.py            # 130/130 lolos · 10 tema
python3 prototipe/alat/periksa-halaman.py   # 135/135 lolos · aset & kaitan halaman
python3 prototipe/buat-palet.py             # gambar palet dari kode

# papan bukti gambar (perlu Node + @napi-rs/canvas terpasang di luar repo):
node prototipe/alat/mockup.js               # semua papan -> docs/desain/mockup/
node prototipe/alat/mockup.js bara          # satu papan saja
```

Papan bukti digambar dari **nilai tema yang sama** (`tokens.css`), memakai **foto & huruf asli** yang dipakai halaman.
Jadi gambar bukti tidak bisa berbeda dari halaman — kalau kode berubah, papannya ikut berubah.

## Aturan yang dijaga di setiap tema

- Kontras teks ≥ 4,5:1 · elemen ≥ 3:1 → **130/130 lolos** (`uji-kontras.py`)
- Area sentuh ≥ 44 px · huruf dasar 16 px jarak baris 1,5
- Ikon SVG (bukan emoji) · tombol ikon selalu punya label
- Setiap aksi memberi umpan balik (tombol berubah, pesan berhasil, atau jendela konfirmasi)
- Bila peramban belum mendukung `color-mix`/`backdrop-filter`, tersedia warna cadangan → halaman tetap terbaca
- Animasi mati bila pengguna memilih "kurangi gerak"

## Yang belum ada (jujur)

Masuk/PIN, pengiriman ke dapur, cetak struk, penyimpanan data, dan pengaturan pemilik.
Itu pekerjaan **Tahap 3 (Tech Spec)** setelah pemilik menyetujui tampilan ini.

Aturan desain lengkap: `docs/desain/RENCANA_DESAIN_UI.md` · papan bukti: `docs/desain/mockup/` ·
palet: `docs/desain/palet-tema.png`
