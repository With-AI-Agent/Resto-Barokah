/**
 * Penangan dan kamus pesan kesalahan ramah berkode (T2-08, AGENT_OPERATING_GUIDE §6).
 *
 * Mengubah kode kesalahan teknis / RPC menjadi pesan ramah pengguna:
 * - Masalah apa yang terjadi (dalam bahasa sederhana tanpa jargon)
 * - Tindakan apa yang perlu dilakukan pengguna
 * - Kode rujukan ramah (mis. AK-601, PIN-401, SESI-403)
 */

export interface PesanRamah {
  kode: string
  judul: string
  pesan: string
  tindakan: string
}

export const KAMUS_PESAN: Record<string, PesanRamah> = {
  // Akses & Peran
  FORBIDDEN: {
    kode: 'AK-403',
    judul: 'Akses Tidak Diizinkan',
    pesan: 'Akun Anda tidak memiliki izin untuk membuka halaman atau melakukan tindakan ini.',
    tindakan: 'Silakan hubungi Owner atau Admin Cabang jika Anda membutuhkan akses ini.',
  },
  AKSES_TERLARANG: {
    kode: 'AK-601',
    judul: 'Halaman Dibatasi',
    pesan: 'Halaman ini khusus untuk peran yang berbeda.',
    tindakan: 'Silakan kembali ke menu utama peran Anda.',
  },
  AKUN_NONAKTIF: {
    kode: 'AK-401',
    judul: 'Akun Dinonaktifkan',
    pesan: 'Akun pegawai ini sedang dalam status tidak aktif.',
    tindakan: 'Hubungi pengelola resto untuk mengaktifkan kembali akun Anda.',
  },

  // PIN & Percobaan Masuk
  PIN_SALAH: {
    kode: 'PIN-401',
    judul: 'PIN Tidak Cocok',
    pesan: 'PIN yang Anda masukkan salah. Mohon periksa kembali 6 angka PIN Anda.',
    tindakan:
      'Coba masukkan kembali dengan teliti. Hindari kesalahan berulang agar akun tidak terkunci.',
  },
  KREDENSIAL_TIDAK_VALID: {
    kode: 'PIN-401',
    judul: 'Kredensial Tidak Sesuai',
    pesan: 'Email atau 6 angka PIN yang dimasukkan tidak cocok.',
    tindakan: 'Periksa kembali penulisan email dan 6 angka PIN Anda.',
  },
  FORMAT_PIN_SALAH: {
    kode: 'PIN-400',
    judul: 'Format PIN Salah',
    pesan: 'PIN harus berupa tepat 6 digit angka.',
    tindakan: 'Masukkan 6 angka PIN Anda dengan benar.',
  },
  INPUT_TIDAK_LENGKAP: {
    kode: 'INP-400',
    judul: 'Data Tidak Lengkap',
    pesan: 'Email dan PIN wajib diisi untuk masuk ke sistem.',
    tindakan: 'Lengkapi seluruh kolom isian yang diminta.',
  },
  AKUN_TERKUNCI: {
    kode: 'PIN-429',
    judul: 'Akun Terkunci Sementara',
    pesan:
      'Terlalu banyak percobaan PIN salah. Sistem mengunci akses selama 15 menit demi keamanan.',
    tindakan: 'Tunggu 15 menit sebelum mencoba kembali, atau hubungi Owner untuk bantuan.',
  },
  PIN_TERKUNCI: {
    kode: 'PIN-429',
    judul: 'Akses Terkunci Sementara',
    pesan: 'Terlalu banyak percobaan PIN yang salah demi keamanan akun Anda.',
    tindakan: 'Tunggu 15 menit sebelum mencoba lagi, atau hubungi atasan Anda untuk bantuan.',
  },
  PIN_LEMAH: {
    kode: 'PIN-400',
    judul: 'PIN Kurang Kuat',
    pesan:
      'PIN harus 6 angka dan tidak boleh berurutan (mis. 123456) atau angka kembar (mis. 111111).',
    tindakan: 'Gunakan kombinasi 6 angka unik yang mudah diingat.',
  },

  // Perangkat & Sesi
  PERANGKAT_WAJIB: {
    kode: 'PRG-400',
    judul: 'Perangkat Belum Diinisialisasi',
    pesan: 'Pengenal perangkat belum tersedia di peramban ini.',
    tindakan: 'Muat ulang halaman agar sistem menyiapkan identitas perangkat kasir Anda.',
  },
  PERANGKAT_BELUM_TERDAFTAR: {
    kode: 'PRG-404',
    judul: 'Perangkat Belum Terdaftar',
    pesan: 'HP atau tablet ini belum didaftarkan sebagai perangkat resmi kasir/resto.',
    tindakan: 'Minta kode pendaftaran perangkat dari Owner/Admin resto Anda.',
  },
  PERANGKAT_TIDAK_SAH: {
    kode: 'PRG-403',
    judul: 'Akses Perangkat Dicabut',
    pesan: 'Perangkat ini tidak terdaftar atau telah dinonaktifkan oleh pemilik restoran.',
    tindakan: 'Hubungi pengelola resto untuk mengaktifkan kembali perangkat ini.',
  },
  PERAN_TIDAK_DIIZINKAN: {
    kode: 'AK-403',
    judul: 'Peran Tidak Diizinkan',
    pesan: 'Peran akun Anda tidak diizinkan masuk dari perangkat ini.',
    tindakan: 'Gunakan perangkat yang sesuai dengan peran Anda atau hubungi Owner.',
  },
  RESTO_TIDAK_COCOK: {
    kode: 'AK-403',
    judul: 'Restoran Tidak Sesuai',
    pesan: 'Perangkat ini tidak terdaftar pada restoran akun Anda.',
    tindakan: 'Pastikan Anda mengakses tautan resto yang benar.',
  },
  PERANGKAT_DICABUT: {
    kode: 'PRG-403',
    judul: 'Izin Perangkat Dicabut',
    pesan: 'Pendaftaran perangkat ini telah dinonaktifkan oleh pengelola resto.',
    tindakan: 'Daftarkan ulang perangkat ini dengan persetujuan Owner.',
  },
  SESI_HABIS: {
    kode: 'SESI-401',
    judul: 'Sesi Selesai',
    pesan: 'Batas waktu masuk Anda telah berakhir demi keamanan data resto.',
    tindakan: 'Silakan masuk kembali untuk melanjutkan pekerjaan.',
  },

  // Mode Dukungan & Sistem
  MODE_DUKUNGAN_AKTIF: {
    kode: 'SYS-200',
    judul: 'Mode Dukungan Aktif',
    pesan: 'Sesi bantuan teknis aktif dalam mode hanya-baca (read-only).',
    tindakan: 'Segala aktivitas tercatat di buku jejak audit resto.',
  },
  JARINGAN_TERPUTUS: {
    kode: 'NET-500',
    judul: 'Koneksi Terganggu',
    pesan: 'Tidak dapat terhubung ke peladen. Mohon periksa jaringan internet atau Wi-Fi resto.',
    tindakan: 'Periksa koneksi Anda dan coba beberapa saat lagi.',
  },
}

/**
 * Menerjemahkan kode atau objek error menjadi PesanRamah terstruktur.
 */
export function formatPesanError(error: unknown, fallbackKode = 'AK-601'): PesanRamah {
  if (!error) {
    return {
      kode: fallbackKode,
      judul: 'Terjadi Kendala',
      pesan: 'Terjadi kesalahan yang tidak diketahui.',
      tindakan: 'Silakan muat ulang halaman atau hubungi pengelola resto.',
    }
  }

  // Jika string kode langsung
  if (typeof error === 'string') {
    const terdaftar = KAMUS_PESAN[error]
    if (terdaftar) return terdaftar
    return {
      kode: fallbackKode,
      judul: 'Pemberitahuan',
      pesan: error,
      tindakan: 'Silakan periksa kembali tindakan Anda.',
    }
  }

  // Jika objek Error
  if (error instanceof Error) {
    const pesanStr = error.message
    for (const [key, ramah] of Object.entries(KAMUS_PESAN)) {
      if (pesanStr.includes(key)) return ramah
    }
    return {
      kode: fallbackKode,
      judul: 'Kendala Sistem',
      pesan: 'Sistem mengalami kendala saat memproses permintaan Anda.',
      tindakan: 'Silakan coba kembali beberapa saat lagi.',
    }
  }

  // Jika objek dengan properti kode / message
  if (typeof error === 'object' && error !== null) {
    const obj = error as Record<string, unknown>
    const kodeKey = String(obj.kode || obj.code || '')
    if (KAMUS_PESAN[kodeKey]) return KAMUS_PESAN[kodeKey]
    const pesanObj = String(obj.pesan || obj.message || '')
    for (const [key, ramah] of Object.entries(KAMUS_PESAN)) {
      if (pesanObj.includes(key)) return ramah
    }
    if (pesanObj && pesanObj !== '[object Object]') {
      return {
        kode: kodeKey || fallbackKode,
        judul: 'Kendala Sistem',
        pesan: pesanObj,
        tindakan: 'Silakan coba kembali atau hubungi bantuan teknis jika kendala berlanjut.',
      }
    }
  }

  return {
    kode: fallbackKode,
    judul: 'Kendala Tidak Dikenal',
    pesan: 'Terjadi kendala dalam memproses operasi.',
    tindakan: 'Silakan hubungi bantuan teknis jika kendala berlanjut.',
  }
}
