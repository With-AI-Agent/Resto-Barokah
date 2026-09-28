# Panduan Printer Struk — untuk Lee

> Ditulis 2026-09-23, menjawab pertanyaan Lee: _"kalau misalnya ada yang pakai printer
> lain selain yang disebutin ini, gimana? Bisa tetep berjalan ga?"_

## Jawaban singkat

**Bisa.** Printer merek apa pun bisa dipakai, asal jenisnya printer struk termal
biasa. Lee **tidak perlu** membeli merek tertentu, dan pegawai **tidak perlu**
memanggil siapa pun kalau suatu hari printernya diganti merek lain.

## Kenapa bisa begitu

Hampir semua printer struk di pasaran "berbicara" dengan bahasa perintah yang
sama, namanya **ESC/POS**. Anggap saja seperti colokan listrik: mereknya
bermacam-macam, tetapi bentuk colokannya sama, jadi semuanya bisa masuk.

Kelima printer yang Lee sebutkan semuanya memakai bahasa itu:

| Printer | Lebar kertas | Sambungan | Catatan |
|---|---|---|---|
| Goojprt PT-210 | 58 mm (kecil) | Bluetooth / USB | Printer saku, kertas disobek tangan |
| Kassen BT-P290 | 58 mm (kecil) | Bluetooth / USB | Printer saku |
| Blueprint Lite-58 | 58 mm (kecil) | Bluetooth / USB | Umum di Indonesia |
| Xprinter XP-N160II | 80 mm (besar) | USB / Bluetooth | Printer meja, ada pisau otomatis + colokan laci kas |
| Epson TM-T82X | 80 mm (besar) | USB | Printer meja, ada pisau otomatis + colokan laci kas |

Kelimanya sudah dimasukkan ke aplikasi supaya **langsung terpasang sekali pilih**.

## Kalau printernya merek lain

Di layar **Pengaturan → Pasang printer**, ada pilihan bernama
**"Printer ESC/POS umum"**. Pilih itu, lalu tentukan lebar kertasnya:

- **58 mm** — kertas kecil, lebarnya kira-kira **5 cm**
- **80 mm** — kertas besar, lebarnya kira-kira **8 cm**

Cara tahunya gampang: lihat saja gulungan kertasnya, atau ukur dengan penggaris.
Tidak perlu tahu istilah teknis apa pun.

Setelah itu tekan **"Uji cetak"**. Akan keluar selembar kertas contoh berisi
garis panjang. **Kalau garisnya pas selebar kertas, berarti pengaturannya sudah
benar.** Kalau garisnya terlipat ke bawah atau kependekan, tinggal ganti pilihan
lebarnya lalu uji cetak lagi.

## Yang sudah dipastikan lewat pengujian otomatis

Supaya janji ini tidak berhenti di ucapan, saya membuat pengujian yang **sengaja
merusak** kode untuk membuktikan penjaganya bekerja:

1. Kalau ada yang mengubah aplikasi sehingga **printer di luar daftar ditolak** →
   pengujian langsung gagal (merah).
2. Kalau **penelusuran otomatis untuk printer tak dikenal dicabut** → gagal.
3. Kalau **lebar kertas bawaan diam-diam diubah** → gagal.

Artinya, jaminan "merek lain tetap jalan" tidak bisa hilang diam-diam di
kemudian hari tanpa ketahuan.

## Yang MASIH perlu Lee lakukan

Semua di atas diuji dengan printer **tiruan** di dalam komputer. Itu membuktikan
logikanya benar, tetapi **belum membuktikan kertasnya benar-benar keluar**.

👉 **Uji cetak di printer sungguhan masih wajib** (tugas T6-08). Nanti caranya:

1. Buka aplikasi di HP Android atau komputer (Chrome/Edge).
2. Masuk **Pengaturan → Pasang printer**, pilih merek atau "umum", atur lebar.
3. Tekan **Uji cetak**, pilih printernya saat diminta.
4. Periksa hasil kertasnya: garis pas selebar kertas, huruf tidak terpotong.
5. Lalu coba cetak **satu struk asli** dan **satu tiket dapur**.

Kalau ada yang aneh, catat merek printernya dan apa yang terjadi — dari situ
saya bisa perbaiki.

## Catatan penting soal iPhone

**iPhone dan iPad tidak bisa menyambung ke printer Bluetooth lewat peramban.**
Itu batasan dari Apple, bukan kekurangan aplikasi ini, dan tidak bisa diakali.

Kalau kasir memakai iPhone, aplikasi akan menampilkan pesan yang menjelaskan hal
itu **beserta jalan keluarnya**: kirim struk digital ke pelanggan. Untuk cetak
kertas, pakai **Android atau komputer**.
