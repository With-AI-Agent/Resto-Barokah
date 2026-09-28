/**
 * profil.ts (T6-02/T6-03 penunjang) — daftar printer yang dikenal + jalur umum.
 *
 * ================== JAWABAN ATAS PERTANYAAN PEMILIK (2026-09-23) ==================
 * Lee bertanya: "kalau ada yang pakai printer lain selain yang disebutkan, bisa
 * tetap berjalan tidak?" Jawabannya HARUS "ya", dan berkas ini yang memastikannya.
 *
 * Kuncinya: **ESC/POS adalah bahasa bersama**, bukan milik satu merek. Kelima
 * printer yang disebut Lee (Goojprt PT-210, Kassen BT-P290, Blueprint Lite-58,
 * Xprinter XP-N160II, Epson TM-T82X) semuanya menyatakan diri "ESC/POS
 * compatible", sama seperti hampir semua printer struk termal yang dijual di
 * Indonesia. Jadi perintah yang sudah kita susun di `expos.ts` berlaku umum.
 *
 * Yang benar-benar berbeda antar merek hanya DUA hal, dan keduanya ditangani
 * tanpa perlu tahu mereknya:
 *
 *   1. **Lebar kertas** — 58 mm (32 kolom) atau 80 mm (48 kolom). Kalau merek
 *      tidak dikenal, pengguna tinggal MEMILIH lebar kertasnya di pengaturan.
 *      Itu satu pertanyaan sederhana yang bisa dijawab siapa pun sambil melihat
 *      kertasnya, bukan hal teknis.
 *
 *   2. **Cara menyambung** — Bluetooth (BLE) atau kabel USB. Untuk BLE, alamat
 *      layanan (UUID) berbeda-beda antar pabrik; karena itu `UUID_LAYANAN_UMUM`
 *      berisi daftar yang dicoba BERURUTAN, ditambah penelusuran otomatis
 *      "pakai karakteristik apa pun yang bisa ditulisi". Untuk USB, printer
 *      struk hampir selalu memakai kelas USB 7 (Printer) dengan satu jalur
 *      keluar (bulk OUT) — itu bisa ditemukan tanpa tahu merek sama sekali.
 *
 * **Aturan yang dikunci:** daftar merek di bawah hanyalah JALAN PINTAS supaya
 * printer yang sudah dikenal langsung terpasang dengan lebar kertas yang benar.
 * Daftar ini TIDAK PERNAH boleh menjadi syarat. Printer di luar daftar wajib
 * tetap bisa dipakai lewat `PROFIL_UMUM`. Ada uji khusus yang membuktikan
 * printer karangan ("merek antah berantah") tetap dapat profil yang bisa
 * dipakai — supaya aturan ini tidak bisa dilanggar diam-diam di kemudian hari.
 * ==================================================================================
 */
import { LEBAR_58MM, LEBAR_80MM } from './expos'

export type CaraSambung = 'bluetooth' | 'usb'

export interface ProfilPrinter {
  /** Kode tetap untuk disimpan di pengaturan. */
  id: string
  /** Nama yang dibaca manusia. */
  nama: string
  /** Lebar kertas dalam karakter (32 atau 48). */
  lebar: number
  /** Cara sambung yang didukung. */
  sambung: CaraSambung[]
  /** Apakah printer punya pisau pemotong otomatis. */
  pemotong: boolean
  /** Apakah printer punya colokan laci kas. */
  laci: boolean
  /**
   * Kata kunci nama perangkat untuk pencocokan otomatis (huruf kecil).
   * Kosong untuk profil umum.
   */
  petunjukNama: string[]
  catatan?: string
}

/**
 * Profil umum — **inilah jaring pengaman untuk merek yang tidak dikenal.**
 *
 * Sengaja memakai anggapan paling aman:
 *  - lebar 58 mm, karena itu ukuran paling umum di kedai kecil dan struk yang
 *    terlalu sempit masih terbaca, sedangkan struk yang terlalu lebar TERPOTONG
 *    (kehilangan angka di kanan). Kalau harus salah, salahlah ke arah yang aman.
 *  - dianggap TIDAK punya pisau & laci, karena mengirim perintah ke perangkat
 *    yang tidak punya fiturnya hanya diabaikan, sedangkan menganggap punya
 *    membuat kasir menunggu pisau yang tak pernah datang.
 */
export const PROFIL_UMUM: ProfilPrinter = {
  id: 'umum-58',
  nama: 'Printer ESC/POS umum (58 mm)',
  lebar: LEBAR_58MM,
  sambung: ['bluetooth', 'usb'],
  pemotong: false,
  laci: false,
  petunjukNama: [],
  catatan:
    'Dipakai bila merek printer tidak ada di daftar. Lebar kertas bisa diubah di pengaturan.',
}

/** Pasangan profil umum untuk kertas lebar. */
export const PROFIL_UMUM_80: ProfilPrinter = {
  id: 'umum-80',
  nama: 'Printer ESC/POS umum (80 mm)',
  lebar: LEBAR_80MM,
  sambung: ['bluetooth', 'usb'],
  pemotong: true,
  laci: true,
  petunjukNama: [],
  catatan: 'Pilih ini bila kertas struknya selebar 8 cm.',
}

/**
 * Printer yang sudah dipastikan pemilik (2026-09-23).
 *
 * Gunanya hanya mempercepat pemasangan — bukan pembatas.
 */
export const PROFIL_DIKENAL: ProfilPrinter[] = [
  {
    id: 'goojprt-pt210',
    nama: 'Goojprt PT-210',
    lebar: LEBAR_58MM,
    sambung: ['bluetooth', 'usb'],
    pemotong: false,
    laci: false,
    petunjukNama: ['pt-210', 'pt210', 'goojprt'],
    catatan: 'Printer saku 58 mm, kertas disobek tangan (tidak ada pisau otomatis).',
  },
  {
    id: 'kassen-btp290',
    nama: 'Kassen BT-P290',
    lebar: LEBAR_58MM,
    sambung: ['bluetooth', 'usb'],
    pemotong: false,
    laci: false,
    petunjukNama: ['bt-p290', 'btp290', 'kassen'],
    catatan: 'Printer saku 58 mm.',
  },
  {
    id: 'blueprint-lite58',
    nama: 'Blueprint Lite-58',
    lebar: LEBAR_58MM,
    sambung: ['bluetooth', 'usb'],
    pemotong: false,
    laci: false,
    petunjukNama: ['lite-58', 'lite58', 'blueprint'],
    catatan: 'Printer 58 mm yang umum dipakai di Indonesia.',
  },
  {
    id: 'xprinter-xpn160ii',
    nama: 'Xprinter XP-N160II',
    lebar: LEBAR_80MM,
    sambung: ['usb', 'bluetooth'],
    pemotong: true,
    laci: true,
    petunjukNama: ['xp-n160', 'xpn160', 'xprinter'],
    catatan: 'Printer meja 80 mm, ada pisau otomatis dan colokan laci kas.',
  },
  {
    id: 'epson-tmt82x',
    nama: 'Epson TM-T82X',
    lebar: LEBAR_80MM,
    sambung: ['usb'],
    pemotong: true,
    laci: true,
    petunjukNama: ['tm-t82', 'tmt82', 'epson'],
    catatan:
      'Printer meja 80 mm. Sambungan USB/Serial/Ethernet — di aplikasi ini dipakai lewat kabel USB.',
  },
]

/** Semua pilihan yang ditampilkan di layar pemasangan. */
export const SEMUA_PROFIL: ProfilPrinter[] = [...PROFIL_DIKENAL, PROFIL_UMUM, PROFIL_UMUM_80]

/**
 * Tebak profil dari nama perangkat yang dilaporkan Bluetooth/USB.
 *
 * **Selalu mengembalikan profil yang bisa dipakai** — tidak pernah `null`.
 * Nama yang tidak dikenal jatuh ke `PROFIL_UMUM`, bukan ditolak. Ini inti
 * jaminan "printer merek lain tetap berjalan".
 */
export function tebakProfil(namaPerangkat: string | null | undefined): ProfilPrinter {
  const nama = (namaPerangkat ?? '').toLowerCase()
  if (nama !== '') {
    for (const profil of PROFIL_DIKENAL) {
      if (profil.petunjukNama.some((petunjuk) => nama.includes(petunjuk))) return profil
    }
  }
  return PROFIL_UMUM
}

/** Cari profil dari kode yang tersimpan di pengaturan. */
export function profilDariId(id: string | null | undefined): ProfilPrinter {
  return SEMUA_PROFIL.find((p) => p.id === id) ?? PROFIL_UMUM
}

/**
 * Alamat layanan BLE yang dipakai printer struk, dicoba BERURUTAN.
 *
 * Tidak ada satu standar pun untuk ini — tiap pabrik memakai alamatnya
 * sendiri. Daftar ini mengumpulkan yang paling umum; kalau semuanya meleset,
 * jalur sambungan masih boleh mencari "karakteristik apa pun yang bisa
 * ditulisi". Karena itu printer yang belum pernah kita lihat pun tetap
 * berpeluang besar bekerja.
 */
export const UUID_LAYANAN_UMUM: string[] = [
  '000018f0-0000-1000-8000-00805f9b34fb',
  '0000ff00-0000-1000-8000-00805f9b34fb',
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  '0000fff0-0000-1000-8000-00805f9b34fb',
  '49535343-fe7d-4ae5-8fa9-9fafd205e455',
  'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
]

/**
 * Besar potongan kiriman BLE.
 *
 * BLE hanya menjamin 20 byte per kiriman sebelum MTU dinaikkan, dan banyak
 * printer murah benar-benar hanya menerima sebanyak itu. Struk dikirim
 * potong demi potong; kalau dikirim sekaligus, printer mencetak setengah lalu
 * berhenti — cacat yang sulit ditebak sebabnya di lapangan.
 */
export const POTONGAN_BLE = 20
