# Cuplikan PRD — usulan revisi bagian M6 & M7 (bahan kalibrasi; lihat README.md)

### M6. Pembayaran, struk, & pembatalan
- **Cerita:** Sebagai **Kasir**, saya ingin menerima pembayaran dengan berbagai cara dan mencetak struk yang benar, supaya pelanggan selesai cepat dan uang tercatat akurat.
- **Kriteria selesai:**
  - Metode tercatat: tunai (dengan hitung kembalian), QRIS, transfer, e-wallet, kartu — **pencatatan, bukan integrasi otomatis**.
  - Pajak PB1 & service charge dihitung otomatis sesuai pengaturan resto; **terlihat terpisah di struk**.
  - Diskon: **bawaan sampai tiga diskon per transaksi** tanpa batas total; pengaturan bisa membatasi menjadi satu diskon bila owner menghendaki.
  - Struk cetak memuat: nama resto, alamat, tanggal/jam, nomor transaksi, daftar item, subtotal, pajak, service, diskon, total, metode bayar, nama kasir, ucapan terima kasih (header/footer bisa diatur).
  - Nomor HP pelanggan **opsional** (ditawarkan bila pelanggan mau poin/voucher).
  - **Aturan pembatalan bertingkat SEBELUM pembayaran pertama** (dikunci pemilik):
    - Dapur **belum** mulai → kasir boleh membatalkan, **wajib pilih alasan** (pelanggan batal / salah input), tercatat di laporan.
    - Dapur **sudah** menandai sedang dimasak → **wajib PIN atasan/owner** + alasan wajib → dicatat sebagai **bahan terbuang/kerugian** dengan nilai rupiahnya dan muncul di laporan harian.
    - **Sesudah pembayaran pertama, termasuk sebagian: isi/nominal dan diskon dikunci; void masih diperbolehkan dengan PIN owner + alasan** supaya kesalahan kasir tetap bisa dikoreksi hari itu juga. Refund resmi tetap fase 2.
- **Kasus tepi:** pembayaran sebagian (split bill = fase 2; di MVP dicatat sebagai dua transaksi terpisah) · printer mati (struk bisa dicetak ulang, transaksi tidak boleh hilang) · pembulatan (aturan di pengaturan) · tagihan terbuka ditinggal pelanggan (ditandai & tetap muncul di daftar).

### M7. Kas & shift (buka/tutup kasir)
- **Cerita:** Sebagai **Kasir**, saya ingin membuka dan menutup kas dengan jelas, supaya saya tidak pernah dituduh selisih.
- **Kriteria selesai:**
  - Buka kas: masukkan **modal awal**.
  - Tutup kas: sistem menghitung uang **seharusnya** (modal + penerimaan tunai − pengeluaran tunai) lalu kasir memasukkan **hasil hitung fisik**.
  - Bila ada selisih → **wajib mengisi alasan**; nilainya tercatat di laporan untuk owner.
  - Aturan shift & transaksi: sistem mendukung penegakan transaksi hanya dalam shift kasir terbuka (melalui setelan `wajib_shift` di pengaturan cabang; bawaan `false`/fleksibel untuk kemudahan adopsi kedai pemula, dan dapat diwajibkan penuh oleh owner resto sesuai SOP kedai via pemicu database).
- **Kasus tepi:** dua kasir dalam satu shift (satu kas, dicatat siapa yang membuka/menutup) · shift tidak ditutup sampai besok (sistem mengingatkan) · kasir lupa modal awal (bisa dikoreksi dengan izin atasan, tercatat).
