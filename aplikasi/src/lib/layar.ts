/**
 * Registri dan Kontrak Layar Aplikasi (T1-31, T1-39, docs/SPESIFIKASI_UI.md §3-§4)
 * Satu sumber kebenaran untuk seluruh layar G1 di aplikasi Resto Barokah.
 */

export type PeranPengguna =
  'pemilik_platform' | 'owner_pusat' | 'admin_cabang' | 'kasir' | 'pelayan' | 'dapur' | 'pelanggan'

export interface SumberDataLayar {
  nama: string
  sumber: string
}

export interface KeadaanLayar {
  kosong: string
  memuat: string
  gagal: string
  menunggu: string
  tidakPunyaAkses: string
  dataSebagian: string
  berhasil: string
  konflik?: string
}

export interface KontrakLayar {
  id: string
  rute: string
  judul: string
  tujuan: string
  peran: PeranPengguna[]
  masukDari: string[]
  komponen: string
  data: SumberDataLayar[]
  aksi: string[]
  keadaan: KeadaanLayar
  aturanTampilan: string[]
  berkasUji: string
  naskahJalan: string
}

export const DAFTAR_LAYAR: Record<string, KontrakLayar> = {
  masuk: {
    id: 'masuk',
    rute: '/masuk',
    judul: 'Masuk Pegawai',
    tujuan: 'Otentikasi staf dan admin resto berbasis PIN dan kredensial perangkat terdaftar.',
    peran: ['pemilik_platform', 'owner_pusat', 'admin_cabang', 'kasir', 'pelayan', 'dapur'],
    masukDari: ['Awal aplikasi', 'Keluar sesi', 'Kunci otomatis'],
    komponen: 'src/layar/masuk/LayarMasuk.tsx',
    data: [
      { nama: 'Daftar Pegawai Cabang', sumber: 'public.pengguna' },
      { nama: 'Status Perangkat', sumber: 'public.perangkat' },
    ],
    aksi: ['masuk.verifikasi_pin', 'masuk.ganti_pengguna', 'masuk.batal'],
    keadaan: {
      kosong: 'Belum ada pegawai terdaftar di cabang ini.',
      memuat: 'Memeriksa kredensial perangkat dan akun...',
      gagal: 'PIN salah atau perangkat tidak terdaftar.',
      menunggu: 'Menghubungkan ke layanan otentikasi...',
      tidakPunyaAkses: 'Perangkat ini belum disetujui untuk mengakses cabang.',
      dataSebagian: 'Daftar pegawai offline dimuat sebagian.',
      berhasil: 'Masuk berhasil. Mengalihkan ke layar kerja...',
    },
    aturanTampilan: [
      'Papan tombol angka besar dan ramah sentuh (≥44px)',
      'PIN disamarkan saat pengetikan',
      'Pemberitahuan percobaan gagal ditampilkan jelas',
    ],
    berkasUji: 'src/layar/masuk/LayarMasuk.test.tsx',
    naskahJalan: 'W-2-01',
  },
  kasir: {
    id: 'kasir',
    rute: '/kasir',
    judul: 'Kasir & Transaksi',
    tujuan: 'Kasir memilih meja, mencatat pesanan menu, dan memproses pembayaran pelanggan.',
    peran: ['owner_pusat', 'admin_cabang', 'kasir'],
    masukDari: ['Bilah navigasi bawah Kasir', 'Setelah buka shift'],
    komponen: 'src/layar/kasir/LayarKasir.tsx',
    data: [
      { nama: 'Katalog Menu Aktif', sumber: 'public.menu_item & public.menu_cabang' },
      { nama: 'Daftar Meja', sumber: 'public.meja' },
      { nama: 'Pesanan Berjalan', sumber: 'public.pesanan & public.pesanan_item' },
      { nama: 'Metode Pembayaran', sumber: 'public.metode_bayar' },
    ],
    aksi: [
      'kasir.tambah_item',
      'kasir.kurang_item',
      'kasir.batal_item',
      'kasir.kirim_dapur',
      'kasir.beri_diskon',
      'kasir.proses_bayar',
      'kasir.buka_shift',
      'kasir.tutup_shift',
    ],
    keadaan: {
      kosong: 'Keranjang pesanan masih kosong. Pilih menu untuk memulai.',
      memuat: 'Memuat katalog menu dan meja...',
      gagal: 'Gagal memperbarui transaksi. Silakan coba lagi.',
      menunggu: 'Memproses pesanan ke peladen...',
      tidakPunyaAkses: 'Hanya peran Kasir dan Pengelola yang dapat mengakses transaksi.',
      dataSebagian: 'Katalog lokal aktif; pembaruan harga terbaru belum sinkron.',
      berhasil: 'Pesanan berhasil disimpan dan dicatat.',
    },
    aturanTampilan: [
      'Semua kalkulasi uang dan pajak dihitung oleh peladen',
      'Tombol aksi kasir cepat minimal 48px',
      'Status pesanan dan item terlihat kontras',
    ],
    berkasUji: 'src/layar/kasir/LayarKasir.test.tsx',
    naskahJalan: 'W-3-01',
  },
  dapur: {
    id: 'dapur',
    rute: '/dapur',
    judul: 'Pesanan Dapur & Bar',
    tujuan:
      'Petugas dapur melihat antrean pesanan masuk dan mengubah status pengerjaan makanan/minuman.',
    peran: ['owner_pusat', 'admin_cabang', 'kasir', 'dapur'],
    masukDari: ['Bilah navigasi Dapur', 'Menu Utama'],
    komponen: 'src/layar/dapur/LayarDapur.tsx',
    data: [{ nama: 'Item Pesanan Dapur', sumber: 'public.pesanan_item & public.pesanan' }],
    aksi: ['dapur.mulai_masak', 'dapur.selesai_masak', 'dapur.tandai_habis'],
    keadaan: {
      kosong: 'Tidak ada antrean pesanan yang perlu dimasak.',
      memuat: 'Memuat antrean pesanan dapur...',
      gagal: 'Gagal memperbarui status masakan.',
      menunggu: 'Menyinkronkan status ke kasir...',
      tidakPunyaAkses: 'Halaman khusus petugas dapur dan pengelola resto.',
      dataSebagian: 'Menampilkan antrean lokal yang tersimpan.',
      berhasil: 'Status pesanan berhasil diperbarui.',
    },
    aturanTampilan: [
      'Kartu pesanan berbasis FIFO (pertama masuk di kiri/atas)',
      'Penanda waktu tunggu berwarna tegas bila pesanan melebihi batas waktu',
      'Dukungan tampilan layar sentuh dapur skala besar',
    ],
    berkasUji: 'src/layar/dapur/LayarDapur.test.tsx',
    naskahJalan: 'W-4-01',
  },
  bar: {
    idLayar: 'bar',
    rute: '/bar',
    judul: 'Pesanan Bar',
    peran: ['owner_pusat', 'admin_cabang', 'kasir', 'dapur'],
    tujuan:
      'menampilkan pesanan minuman untuk bartender — otomatis terpisah dari pesanan makanan berdasarkan tujuan kategori menu',
    masukDari: ['dapur'],
    keluarKe: ['dapur'],
    dataDitampilkan: ['antrean minuman tertua di atas', 'jenis pesanan', 'catatan khusus', 'status tiap minuman'],
    aksiTerkait: ['dapur.mulai_masak', 'dapur.selesai_masak'],
    keadaan: {
      kosong: 'Belum ada pesanan minuman.',
      memuat: 'Memuat antrean pesanan bar...',
      dataSebagian: 'Menampilkan antrean lokal yang tersimpan.',
      gagal: 'Gagal memuat antrean — periksa sambungan',
    },
    aturanTampilan: [
      'Menyamai layar dapur: FIFO, penanda waktu tegas, sentuhan skala besar',
      'Sumber kebenaran pemisahan = peladen (pesanan_item.tujuan)',
    ],
    berkasUji: 'src/layar/dapur/LayarBar.test.tsx',
    naskahJalan: 'W-4-02',
  },
  laporan: {
    id: 'laporan',
    rute: '/laporan',
    judul: 'Laporan Penjualan & Kas',
    tujuan:
      'Pimpinan resto memantau pendapatan harian, kas per shift, item terlaris, dan pembatalan.',
    peran: ['owner_pusat', 'admin_cabang'],
    masukDari: ['Bilah navigasi Laporan', 'Menu Pengelola'],
    komponen: 'src/layar/laporan/LayarLaporan.tsx',
    data: [
      { nama: 'Ringkasan Kas Harian', sumber: 'public.pembayaran & public.pesanan' },
      { nama: 'Catatan Audit', sumber: 'public.catatan_audit' },
    ],
    aksi: [
      'laporan.filter_tanggal',
      'laporan.pilih_cabang',
      'laporan.cetak_laporan',
      'laporan.ekspor_data',
    ],
    keadaan: {
      kosong: 'Belum ada transaksi tercatat pada rentang tanggal ini.',
      memuat: 'Menghitung rekapan penjualan dan kas...',
      gagal: 'Gagal mengambil data laporan dari peladen.',
      menunggu: 'Menghitung agregasi data...',
      tidakPunyaAkses: 'Laporan keuangan hanya dapat dibuka oleh Admin Cabang dan Pemilik.',
      dataSebagian: 'Laporan parsial ditampilkan dari kas lokal.',
      berhasil: 'Laporan berhasil diperbarui.',
    },
    aturanTampilan: [
      'Format angka moneter konsisten (Rp)',
      'Tabel ringkasan kas per shift mudah dibaca dan diekspor',
    ],
    berkasUji: 'src/layar/laporan/LayarLaporan.test.tsx',
    naskahJalan: 'W-7-01',
  },
  pengaturan: {
    id: 'pengaturan',
    rute: '/pengaturan',
    judul: 'Pengaturan Resto',
    tujuan: 'Mengatur identitas kedai, tarif pajak, service charge, pembulatan, meja, dan tema.',
    peran: ['owner_pusat', 'admin_cabang'],
    masukDari: ['Bilah navigasi Pengaturan', 'Menu Utama'],
    komponen: 'src/layar/pengaturan/LayarPengaturan.tsx',
    data: [
      { nama: 'Pengaturan Resto', sumber: 'public.pengaturan' },
      { nama: 'Data Cabang & Meja', sumber: 'public.cabang & public.meja' },
      { nama: 'Daftar Pegawai', sumber: 'public.pengguna & public.izin' },
    ],
    aksi: [
      'pengaturan.simpan_pajak',
      'pengaturan.simpan_tema',
      'pengaturan.tambah_meja',
      'pengaturan.hapus_meja',
      'pengaturan.tambah_pegawai',
      'pengaturan.ubah_izin',
    ],
    keadaan: {
      kosong: 'Belum ada data konfigurasi tambahan.',
      memuat: 'Memuat konfigurasi resto...',
      gagal: 'Gagal menyimpan perubahan pengaturan.',
      menunggu: 'Menyimpan konfigurasi ke peladen...',
      tidakPunyaAkses: 'Akses terbatas untuk Pengelola dan Pemilik resto.',
      dataSebagian: 'Konfigurasi bawaan ditampilkan.',
      berhasil: 'Pengaturan berhasil disimpan.',
    },
    aturanTampilan: [
      'Ubah tema langsung diterapkan seketika',
      'Konfirmasi sebelum mengubah parameter pajak dan pembulatan',
    ],
    berkasUji: 'src/layar/pengaturan/LayarPengaturan.test.tsx',
    naskahJalan: 'W-9-01',
  },
  voucher: {
    id: 'voucher',
    rute: '/voucher',
    judul: 'Voucher & Diskon',
    tujuan: 'Kasir memeriksa keabsahan kode voucher pelanggan dan mencairkan diskon pada pesanan.',
    peran: ['owner_pusat', 'admin_cabang', 'kasir'],
    masukDari: ['Panel Pembayaran Kasir', 'Menu Voucher'],
    komponen: 'src/layar/voucher/LayarVoucher.tsx',
    data: [{ nama: 'Data Voucher', sumber: 'public.diskon_transaksi' }],
    aksi: ['voucher.cek_kode', 'voucher.klaim_diskon', 'voucher.batal'],
    keadaan: {
      kosong: 'Masukkan kode voucher pelanggan untuk memeriksa.',
      memuat: 'Memeriksa status voucher...',
      gagal: 'Kode voucher tidak valid atau sudah kedaluwarsa.',
      menunggu: 'Memverifikasi keabsahan kupon...',
      tidakPunyaAkses: 'Hanya staf berizin yang dapat memverifikasi voucher.',
      dataSebagian: 'Data kampanye lokal dimuat.',
      berhasil: 'Voucher sah dan diskon berhasil diterapkan.',
    },
    aturanTampilan: [
      'Mendukung pemindaian kamera QR dan input manual',
      'Menampilkan rincian potongan dengan jelas sebelum disetujui',
    ],
    berkasUji: 'src/layar/voucher/LayarVoucher.test.tsx',
    naskahJalan: 'W-8-01',
  },
  'pelanggan-publik': {
    id: 'pelanggan-publik',
    rute: '/menu',
    judul: 'Katalog Menu Publik',
    tujuan: 'Pelanggan melihat daftar menu, harga, foto, dan ketersediaan tanpa perlu login.',
    peran: ['pelanggan', 'kasir', 'pelayan', 'admin_cabang', 'owner_pusat', 'pemilik_platform'],
    masukDari: ['Tautan publik / QR Meja', 'Peramban pelanggan'],
    komponen: 'src/layar/pelanggan-publik/LayarPelangganPublik.tsx',
    data: [{ nama: 'Katalog Publik', sumber: 'public.menu_item & public.kategori_menu' }],
    aksi: ['pelanggan.cari_menu', 'pelanggan.filter_kategori'],
    keadaan: {
      kosong: 'Belum ada menu yang tersedia untuk cabang ini.',
      memuat: 'Memuat katalog menu lezat...',
      gagal: 'Gagal memuat katalog menu. Silakan muat ulang.',
      menunggu: 'Menyaring daftar menu...',
      tidakPunyaAkses: 'Halaman ini terbuka untuk umum.',
      dataSebagian: 'Menampilkan menu yang tersimpan.',
      berhasil: 'Menu siap dilihat.',
    },
    aturanTampilan: [
      'Desain responsif sempurna untuk ponsel pelanggan',
      'Indikator menu habis jelas terlihat',
      'Tema mengikuti identitas merek resto',
    ],
    berkasUji: 'src/layar/pelanggan-publik/LayarPelangganPublik.test.tsx',
    naskahJalan: 'W-8-02',
  },
  contoh: {
    id: 'contoh',
    rute: '/contoh',
    judul: 'Contoh Komponen & Tema',
    tujuan: 'Layar pratinjau komponen dasar, 10 tema desain, dan pengujian interaktivitas UI.',
    peran: [
      'owner_pusat',
      'admin_cabang',
      'kasir',
      'pelayan',
      'dapur',
      'pemilik_platform',
      'pelanggan',
    ],
    masukDari: ['Pengembang / Penguji', 'Bilah tema'],
    komponen: 'src/layar/contoh/LayarContoh.tsx',
    data: [],
    aksi: ['contoh.ganti_tema', 'contoh.ganti_kerapatan', 'contoh.picu_toast'],
    keadaan: {
      kosong: 'Contoh keadaan kosong.',
      memuat: 'Contoh keadaan memuat komponen...',
      gagal: 'Contoh penanganan galat komponen.',
      menunggu: 'Contoh proses latar belakang...',
      tidakPunyaAkses: 'Contoh pembatasan akses peran.',
      dataSebagian: 'Contoh data sebagian.',
      berhasil: 'Contoh aksi berhasil dipicu.',
    },
    aturanTampilan: [
      'Memperagakan 10 palet tema warna dan 2 mode kerapatan',
      'Memvalidasi standar keterbacaan kontras token',
    ],
    berkasUji: 'src/layar/contoh/LayarContoh.test.tsx',
    naskahJalan: 'W-0-01',
  },
}
