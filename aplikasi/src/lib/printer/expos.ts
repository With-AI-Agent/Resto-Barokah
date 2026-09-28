/**
 * expos.ts (T6-01) — penyusun perintah ESC/POS untuk printer termal.
 *
 * Berkas ini adalah "satu berkas perintah cetak" yang diwajibkan TECH_SPEC
 * §9 ART-7. Isinya SENGAJA murni: tidak menyentuh Bluetooth, USB, jaringan,
 * maupun jam perangkat. Semua fungsi di sini hanya mengubah data menjadi
 * deretan byte. Itu yang membuatnya bisa diuji tanpa printer sungguhan —
 * dan uji tanpa printer adalah satu-satunya cara memastikan tata letak struk
 * tidak diam-diam berubah di antara dua uji lapangan.
 *
 * Yang HARUS dipahami sebelum menyunting:
 *
 *  1. **Printer termal tidak mengerti UTF-8.** Ia bekerja dengan satu byte per
 *     huruf memakai "code page". Kalau teks UTF-8 dikirim mentah-mentah, huruf
 *     beraksen (é, ñ) berubah jadi dua huruf sampah dan BARIS MELESET —
 *     angka rupiah di kanan ikut bergeser. Karena itu teks diterjemahkan dulu
 *     ke CP437 (`keCp437`), dan huruf yang tak ada padanannya diganti huruf
 *     terdekat tanpa aksen ("é" → "e"), bukan dibuang. Bahasa Indonesia sendiri
 *     tidak memakai aksen, tetapi nama menu dan nama resto bisa saja memakainya.
 *
 *  2. **Lebar kertas dihitung dalam KARAKTER, bukan milimeter.** Printer 58 mm
 *     memuat 32 karakter, printer 80 mm memuat 48 karakter. Semua perataan
 *     memakai angka itu; salah lebar = struk berantakan.
 *
 *  3. **Nama panjang dipotong, angka TIDAK PERNAH dipotong.** Pada
 *     `barisKiriKanan`, kalau ruang tidak cukup, yang dikorbankan adalah nama
 *     menu — angka uangnya dipertahankan utuh. Struk yang kehilangan digit
 *     rupiah jauh lebih berbahaya daripada nama menu yang terpotong.
 *
 *  4. **Fungsi ini tidak menghitung uang.** Sama seperti `Struk.tsx`: semua
 *     angka datang dari peladen. Di sini hanya soal menaruhnya di kertas.
 */

/** Lebar kertas termal yang didukung, dinyatakan dalam jumlah karakter. */
export const LEBAR_58MM = 32
export const LEBAR_80MM = 48

/** Byte kendali ESC/POS yang dipakai. Diberi nama supaya tidak ada angka misterius. */
const ESC = 0x1b
const GS = 0x1d
const LF = 0x0a

/**
 * Peta huruf beraksen → huruf polos terdekat.
 *
 * Dipakai sebagai jaring pengaman: lebih baik tamu membaca "Creme Brulee"
 * daripada "Cr??me Br??l??e". Sengaja hanya memuat huruf yang masuk akal
 * muncul di nama menu Indonesia/Barat.
 */
const PADANAN_POLOS: Record<string, string> = {
  à: 'a',
  á: 'a',
  â: 'a',
  ã: 'a',
  ä: 'a',
  å: 'a',
  è: 'e',
  é: 'e',
  ê: 'e',
  ë: 'e',
  ì: 'i',
  í: 'i',
  î: 'i',
  ï: 'i',
  ò: 'o',
  ó: 'o',
  ô: 'o',
  õ: 'o',
  ö: 'o',
  ù: 'u',
  ú: 'u',
  û: 'u',
  ü: 'u',
  ý: 'y',
  ÿ: 'y',
  ñ: 'n',
  ç: 'c',
  À: 'A',
  Á: 'A',
  Â: 'A',
  Ã: 'A',
  Ä: 'A',
  Å: 'A',
  È: 'E',
  É: 'E',
  Ê: 'E',
  Ë: 'E',
  Ì: 'I',
  Í: 'I',
  Î: 'I',
  Ï: 'I',
  Ò: 'O',
  Ó: 'O',
  Ô: 'O',
  Õ: 'O',
  Ö: 'O',
  Ù: 'U',
  Ú: 'U',
  Û: 'U',
  Ü: 'U',
  Ý: 'Y',
  Ñ: 'N',
  Ç: 'C',
  '–': '-',
  '—': '-',
  '‘': "'",
  '’': "'",
  '“': '"',
  '”': '"',
  '…': '...',
  '₂': '2',
  '°': ' ',
}

/**
 * Ubah teks menjadi byte CP437 (satu byte per huruf).
 *
 * Huruf yang tidak ada di CP437 diganti padanan polosnya; kalau tetap tidak
 * dikenal, dipakai '?' — TIDAK dibuang, supaya panjang baris tetap terduga
 * dan kolom angka tidak bergeser.
 */
export function keCp437(teks: string): number[] {
  const keluar: number[] = []
  for (const huruf of teks) {
    const kode = huruf.codePointAt(0) ?? 63
    if (kode >= 0x20 && kode <= 0x7e) {
      keluar.push(kode) // ASCII — sama persis di CP437
      continue
    }
    if (huruf === '\n') {
      keluar.push(LF)
      continue
    }
    const polos = PADANAN_POLOS[huruf]
    if (polos !== undefined) {
      for (const p of polos) keluar.push(p.codePointAt(0) ?? 63)
      continue
    }
    keluar.push(0x3f) // '?'
  }
  return keluar
}

/**
 * Panjang teks SETELAH diterjemahkan ke CP437.
 *
 * Dipakai untuk perataan. `"…".length` di JavaScript bisa berbeda dari jumlah
 * byte yang benar-benar dicetak (mis. '…' jadi tiga titik), dan perbedaan
 * satu karakter saja sudah cukup membuat kolom kanan meleset.
 */
export function lebarCetak(teks: string): number {
  return keCp437(teks).length
}

/** Potong teks agar tidak melebihi `maks` karakter cetak. */
export function potong(teks: string, maks: number): string {
  if (maks <= 0) return ''
  let hasil = ''
  for (const huruf of teks) {
    if (lebarCetak(hasil + huruf) > maks) break
    hasil += huruf
  }
  return hasil
}

/**
 * Satu baris "nama di kiri, angka di kanan" — tulang punggung struk.
 *
 * Kalau ruang tidak cukup, NAMA yang dipotong, bukan angkanya (lihat catatan
 * 3 di kepala berkas). Bila angkanya sendiri sudah lebih lebar dari kertas,
 * angka tetap dikembalikan utuh: lebih baik satu baris berantakan daripada
 * struk menyebut nilai uang yang salah.
 */
export function barisKiriKanan(kiri: string, kanan: string, lebar: number): string {
  const lebarKanan = lebarCetak(kanan)
  if (lebarKanan >= lebar) return kanan
  const ruangKiri = lebar - lebarKanan - 1 // minimal satu spasi pemisah
  const kiriPotong = potong(kiri, Math.max(ruangKiri, 0))
  const spasi = lebar - lebarCetak(kiriPotong) - lebarKanan
  return kiriPotong + ' '.repeat(Math.max(spasi, 0)) + kanan
}

/** Teks di tengah baris. Sisa ganjil dibiarkan di kanan. */
export function barisTengah(teks: string, lebar: number): string {
  const isi = potong(teks, lebar)
  const kosong = lebar - lebarCetak(isi)
  return ' '.repeat(Math.floor(kosong / 2)) + isi
}

/** Garis pemisah selebar kertas, mis. "--------". */
export function garis(lebar: number, huruf = '-'): string {
  return huruf.repeat(Math.max(lebar, 0))
}

/**
 * Pemecah teks panjang menjadi beberapa baris tanpa memotong kata di tengah.
 *
 * Dipakai untuk catatan pesanan ("tanpa sambal, pedas sedikit") yang kalau
 * terpotong bisa berubah arti — "tanpa sambal" terpotong jadi "tanpa" masih
 * aman, tetapi "pedas" terpotong jadi "peda" membingungkan dapur.
 */
export function bungkusTeks(teks: string, lebar: number): string[] {
  if (lebar <= 0) return []
  const kata = teks.split(/\s+/).filter((k) => k.length > 0)
  const baris: string[] = []
  let kini = ''
  for (const k of kata) {
    const calon = kini === '' ? k : `${kini} ${k}`
    if (lebarCetak(calon) <= lebar) {
      kini = calon
      continue
    }
    if (kini !== '') baris.push(kini)
    // Kata tunggal yang lebih panjang dari kertas dipenggal paksa.
    let sisa = k
    while (lebarCetak(sisa) > lebar) {
      const bagian = potong(sisa, lebar)
      baris.push(bagian)
      sisa = sisa.slice(bagian.length)
    }
    kini = sisa
  }
  if (kini !== '') baris.push(kini)
  return baris
}

/**
 * Penyusun byte ESC/POS.
 *
 * Dibuat sebagai kelas kecil supaya perintah bisa dirangkai berurutan dan
 * hasil akhirnya satu `Uint8Array` yang siap dikirim ke Bluetooth/USB (T6-02 &
 * T6-03 yang akan memakainya — berkas ini sengaja tidak tahu caranya).
 */
export class PenyusunEscPos {
  private bagian: number[] = []

  constructor(readonly lebar: number = LEBAR_58MM) {}

  /** ESC @ — kembalikan printer ke keadaan awal. Selalu dipakai di awal. */
  awal(): this {
    this.bagian.push(ESC, 0x40)
    return this
  }

  /** ESC t n — pilih code page. 0 = CP437, sepadan dengan `keCp437`. */
  pilihCp437(): this {
    this.bagian.push(ESC, 0x74, 0x00)
    return this
  }

  /** ESC E n — tebal hidup/mati. */
  tebal(hidup: boolean): this {
    this.bagian.push(ESC, 0x45, hidup ? 1 : 0)
    return this
  }

  /** ESC a n — perataan: 0 kiri, 1 tengah, 2 kanan. */
  rata(posisi: 'kiri' | 'tengah' | 'kanan'): this {
    const n = posisi === 'kiri' ? 0 : posisi === 'tengah' ? 1 : 2
    this.bagian.push(ESC, 0x61, n)
    return this
  }

  /** GS ! n — ukuran huruf ganda (dipakai untuk nomor pesanan di tiket dapur). */
  hurufBesar(hidup: boolean): this {
    this.bagian.push(GS, 0x21, hidup ? 0x11 : 0x00)
    return this
  }

  /** Tulis teks apa adanya (tanpa pindah baris). */
  teks(isi: string): this {
    this.bagian.push(...keCp437(isi))
    return this
  }

  /** Tulis teks lalu pindah baris. */
  baris(isi = ''): this {
    return this.teks(isi).lf()
  }

  /** Pindah baris. */
  lf(): this {
    this.bagian.push(LF)
    return this
  }

  /** Baris "kiri ... kanan" selebar kertas. */
  kiriKanan(kiri: string, kanan: string): this {
    return this.baris(barisKiriKanan(kiri, kanan, this.lebar))
  }

  /** Garis pemisah selebar kertas. */
  garis(huruf = '-'): this {
    return this.baris(garis(this.lebar, huruf))
  }

  /**
   * GS V — potong kertas.
   *
   * Didahului beberapa baris kosong dengan sengaja: pisau printer berada
   * beberapa milimeter di atas kepala cetak, jadi tanpa umpan kertas ini
   * baris terakhir struk ikut terpotong.
   */
  potongKertas(): this {
    this.lf().lf().lf()
    this.bagian.push(GS, 0x56, 0x00)
    return this
  }

  /**
   * ESC p — buka laci kas.
   *
   * Tidak semua printer punya colokan laci; kalau tidak ada, perintah ini
   * diabaikan printer tanpa efek samping. Karena itu aman selalu dikirim
   * pada pembayaran tunai.
   */
  bukaLaci(): this {
    this.bagian.push(ESC, 0x70, 0x00, 0x19, 0xfa)
    return this
  }

  /** Hasil akhir: byte siap kirim. */
  selesai(): Uint8Array {
    return Uint8Array.from(this.bagian)
  }
}
