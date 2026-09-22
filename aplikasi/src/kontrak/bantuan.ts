/**
 * Kontrak Bantuan Kontekstual Aplikasi Resto Barokah (T1-42, docs/SPESIFIKASI_UI.md §11)
 * Satu sumber kebenaran bantuan untuk setiap layar kerja pegawai & pelanggan.
 */

import type { PeranPengguna } from '../lib/layar'

export interface BantuanLayar {
  idLayar: string
  judul: string
  ringkasan: string
  langkah: string[]
  kalauMacet: string
  peranBoleh: PeranPengguna[]
  aksiTerkait: string[]
}

export const DAFTAR_BANTUAN: Record<string, BantuanLayar> = {
  masuk: {
    idLayar: 'masuk',
    judul: 'Panduan Masuk Bertugas',
    ringkasan:
      'Masuk bertugas menggunakan akun nama pegawai dan 6 digit PIN pada perangkat terdaftar.',
    langkah: [
      'Pilih nama pegawai Anda dari daftar yang tersedia.',
      'Ketik 6 digit PIN rahasia Anda pada papan tombol.',
      'Tekan tombol Masuk untuk memulai sesi kerja.',
    ],
    kalauMacet:
      'Bila PIN salah lebih dari 5 kali atau perangkat tidak terdaftar, hubungi Admin Cabang atau Pemilik.',
    peranBoleh: ['pemilik_platform', 'owner_pusat', 'admin_cabang', 'kasir', 'pelayan', 'dapur'],
    aksiTerkait: ['masuk.verifikasi_pin', 'masuk.ganti_pengguna', 'masuk.batal'],
  },
  kasir: {
    idLayar: 'kasir',
    judul: 'Panduan Transaksi Kasir',
    ringkasan:
      'Mencatat pesanan menu pelanggan, mengirim tiket ke dapur, dan memproses pembayaran.',
    langkah: [
      'Buka shift kasir bila baru memulai hari dengan mengisi modal awal.',
      'Pilih nomor meja pelanggan atau jenis pesanan bawa pulang.',
      'Pilih item menu dari katalog dan sesuaikan jumlahnya.',
      'Tekan Kirim ke Dapur agar pesanan mulai dimasak.',
      'Tekan Bayar Pesanan saat pelanggan ingin menyelesaikan tagihan.',
    ],
    kalauMacet:
      'Jika koneksi offline, pesanan tersimpan di antrean perangkat dan dikirim otomatis saat tersambung.',
    peranBoleh: ['owner_pusat', 'admin_cabang', 'kasir'],
    aksiTerkait: [
      'kasir.tambah_item',
      'kasir.kurang_item',
      'kasir.batal_item',
      'kasir.kirim_dapur',
      'kasir.beri_diskon',
      'kasir.proses_bayar',
      'kasir.buka_shift',
      'kasir.tutup_shift',
    ],
  },
  dapur: {
    idLayar: 'dapur',
    judul: 'Panduan Layar Dapur & Bar',
    ringkasan:
      'Melihat antrean pesanan makanan/minuman berurutan (FIFO) dan memperbarui status hidangan.',
    langkah: [
      'Lihat tiket pesanan urut dari yang paling lama masuk (kiri ke kanan).',
      'Tekan Mulai Masak saat pesanan mulai disiapkan di wajan/bar.',
      'Tekan Siap Saji saat hidangan selesai dan siap diantar ke meja.',
      'Tekan Tandai Habis jika bahan menu tertentu telah habis terjual.',
    ],
    kalauMacet:
      'Bila pesanan tidak muncul, periksa status jaringan kasir atau segarkan layar dapur.',
    peranBoleh: ['owner_pusat', 'admin_cabang', 'kasir', 'dapur'],
    aksiTerkait: ['dapur.mulai_masak', 'dapur.selesai_masak', 'dapur.tandai_habis'],
  },
  laporan: {
    idLayar: 'laporan',
    judul: 'Panduan Laporan & Rekap Kas',
    ringkasan:
      'Memantau ringkasan omset penjualan, kas per shift, menu terlaris, dan rincian pembatalan.',
    langkah: [
      'Tentukan rentang tanggal transaksi yang ingin diperiksa.',
      'Pilih cabang spesifik atau seluruh cabang (bagi Owner).',
      'Periksa rincian omset tunai vs non-tunai dan selisih kas fisik.',
      'Tekan Cetak Laporan atau Ekspor Ringkasan untuk pembukuan.',
    ],
    kalauMacet:
      'Jika ada selisih kas fisik, tinjau catatan alasan selisih pada penutupan shift kasir.',
    peranBoleh: ['owner_pusat', 'admin_cabang'],
    aksiTerkait: [
      'laporan.filter_tanggal',
      'laporan.pilih_cabang',
      'laporan.cetak_laporan',
      'laporan.ekspor_data',
    ],
  },
  pengaturan: {
    idLayar: 'pengaturan',
    judul: 'Panduan Pengaturan Resto',
    ringkasan:
      'Mengelola tata letak meja, pegawai, pajak, service charge, serta tema tampilan merek.',
    langkah: [
      'Atur persentase PB1 dan service charge sesuai regulasi daerah.',
      'Daftarkan nomor meja dan area tata letak ruang makan.',
      'Tambahkan pegawai baru dan tentukan peran serta hak izinnya.',
      'Pilih palet warna tema desain yang mewakili identitas resto.',
    ],
    kalauMacet:
      'Perubahan tarif pajak dan izin peran dicatat di riwayat audit dan tidak mengubah transaksi lama.',
    peranBoleh: ['owner_pusat', 'admin_cabang'],
    aksiTerkait: [
      'pengaturan.simpan_pajak',
      'pengaturan.simpan_tema',
      'pengaturan.tambah_meja',
      'pengaturan.hapus_meja',
      'pengaturan.tambah_pegawai',
      'pengaturan.ubah_izin',
    ],
  },
  voucher: {
    idLayar: 'voucher',
    judul: 'Panduan Voucher & Diskon',
    ringkasan:
      'Memeriksa kupon diskon pelanggan secara aman dan menerapkan potongan harga pada transaksi.',
    langkah: [
      'Pindai kode batang/QR pelanggan dengan kamera atau ketik manual.',
      'Tekan Periksa Voucher untuk memvalidasi masa berlaku dan syaratnya.',
      'Tekan Terapkan Voucher untuk memasang potongan ke tagihan meja.',
    ],
    kalauMacet:
      'Voucher yang telah kedaluwarsa atau dipakai di transaksi lain akan ditolak sistem secara aman.',
    peranBoleh: ['owner_pusat', 'admin_cabang', 'kasir'],
    aksiTerkait: ['voucher.cek_kode', 'voucher.klaim_diskon', 'voucher.batal'],
  },
  'pelanggan-publik': {
    idLayar: 'pelanggan-publik',
    judul: 'Panduan Menu Pelanggan Digital',
    ringkasan:
      'Melihat seluruh daftar menu, foto makanan, harga resmi, dan ketersediaan dari meja makan.',
    langkah: [
      'Pindai kode QR pada meja Anda untuk membuka menu.',
      'Pilih kategori makanan atau minuman di bagian atas.',
      'Gunakan kolom pencarian untuk menemukan menu favorit.',
    ],
    kalauMacet: 'Pemberitahuan habis akan muncul jika stok hidangan sudah tidak tersedia di dapur.',
    peranBoleh: [
      'pelanggan',
      'kasir',
      'pelayan',
      'admin_cabang',
      'owner_pusat',
      'pemilik_platform',
    ],
    aksiTerkait: ['pelanggan.cari_menu', 'pelanggan.filter_kategori'],
  },
  contoh: {
    idLayar: 'contoh',
    judul: 'Panduan Contoh Komponen & Tema',
    ringkasan:
      'Pratinjau elemen interaktif, 10 tema warna, kerapatan, serta uji coba responsivitas desain.',
    langkah: [
      'Uji coba pergantian 10 tema warna dan mode kerapatan Nyaman vs Padat.',
      'Coba tombol aksi berbagai ragam warna dan ukuran sentuh ≥44px.',
      'Periksa komponen dialog lapis mengambang, toast, dan tabel data.',
    ],
    kalauMacet: 'Layar ini adalah lingkungan peragaan dan pengujian kontrol tampilan.',
    peranBoleh: [
      'owner_pusat',
      'admin_cabang',
      'kasir',
      'pelayan',
      'dapur',
      'pemilik_platform',
      'pelanggan',
    ],
    aksiTerkait: ['contoh.ganti_tema', 'contoh.ganti_kerapatan', 'contoh.picu_toast'],
  },
}
