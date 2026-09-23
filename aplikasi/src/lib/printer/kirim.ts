/**
 * kirim.ts (T6-02 & T6-03) — mengantar byte ESC/POS ke printer lewat
 * Web Bluetooth atau WebUSB.
 *
 * Pembagian tugas yang dijaga ketat: `expos.ts`/`struk.ts`/`tiket.ts` memutuskan
 * APA yang dicetak, berkas ini hanya soal BAGAIMANA mengantarnya. Karena itu
 * berkas ini tidak pernah menyentuh angka uang, dan tidak tahu bedanya struk
 * dengan tiket dapur.
 *
 * ===================== KENAPA MEREK LAIN TETAP BISA JALAN =====================
 * (jawaban langsung atas pertanyaan pemilik, 2026-09-23)
 *
 * **Bluetooth:** tidak ada satu alamat layanan (UUID) baku untuk printer struk —
 * tiap pabrik memakai alamatnya sendiri. Jadi penyambungan dilakukan bertingkat:
 *   1. coba alamat-alamat yang sudah dikenal (`UUID_LAYANAN_UMUM`), lalu
 *   2. kalau semuanya meleset, **telusuri semua layanan** dan pakai
 *      karakteristik apa pun yang bisa ditulisi.
 * Langkah 2 itulah yang membuat printer yang belum pernah kita lihat pun
 * berpeluang besar langsung bekerja.
 *
 * **USB:** printer struk hampir selalu mengaku sebagai kelas USB 7 (Printer)
 * dan menyediakan satu jalur keluar (bulk OUT). Itu bisa ditemukan tanpa tahu
 * merek sama sekali. Kalau kelas 7 tidak ketemu, dicari jalur keluar apa pun.
 *
 * **Data dikirim potong demi potong (20 byte).** BLE hanya menjamin sebanyak
 * itu per kiriman, dan banyak printer murah benar-benar hanya menerima segitu.
 * Kalau struk dikirim sekaligus, printer mencetak setengah lalu berhenti —
 * cacat yang sangat sulit ditebak sebabnya di lapangan.
 * ==============================================================================
 *
 * Semua kegagalan dilaporkan sebagai `GagalCetak` dengan pesan berbahasa
 * manusia, karena ART-7 mewajibkan: kegagalan cetak tidak boleh menghilangkan
 * transaksi, dan kasir harus tahu apa yang terjadi supaya bisa memilih jalur
 * cadangan digital.
 */
import { POTONGAN_BLE, UUID_LAYANAN_UMUM } from './profil'

/** Kegagalan cetak dengan pesan yang bisa dibaca kasir. */
export class GagalCetak extends Error {
  constructor(
    message: string,
    readonly sebab: 'tak-didukung' | 'dibatalkan' | 'sambungan' | 'kirim',
  ) {
    super(message)
    this.name = 'GagalCetak'
  }
}

/** Apakah peramban ini mendukung Web Bluetooth? */
export function dukungBluetooth(): boolean {
  return typeof navigator !== 'undefined' && 'bluetooth' in navigator
}

/** Apakah peramban ini mendukung WebUSB? */
export function dukungUsb(): boolean {
  return typeof navigator !== 'undefined' && 'usb' in navigator
}

/**
 * Pesan jelas saat perangkat tidak mendukung — DoD T6-02 menuntut ini.
 *
 * iPhone/iPad memang tidak akan pernah mendukung Web Bluetooth di Safari, jadi
 * pesan harus menyebut jalan keluarnya (cadangan digital), bukan sekadar
 * "tidak didukung" yang membuat kasir buntu.
 */
export function pesanTakDidukung(cara: 'bluetooth' | 'usb'): string {
  if (cara === 'bluetooth') {
    return (
      'Perangkat ini tidak bisa menyambung ke printer Bluetooth dari peramban. ' +
      'iPhone dan iPad memang belum mendukungnya. Pakai Android atau komputer, ' +
      'atau kirim struk digital sebagai gantinya.'
    )
  }
  return (
    'Perangkat ini tidak bisa menyambung ke printer USB dari peramban. ' +
    'Coba peramban Chrome/Edge di komputer, atau kirim struk digital sebagai gantinya.'
  )
}

/** Potong data menjadi bagian kecil agar printer tidak kewalahan. */
export function potongData(data: Uint8Array, besar: number = POTONGAN_BLE): Uint8Array[] {
  if (besar <= 0) throw new Error('Besar potongan harus lebih dari 0')
  const hasil: Uint8Array[] = []
  for (let i = 0; i < data.length; i += besar) {
    hasil.push(data.slice(i, i + besar))
  }
  return hasil
}

// ---------------------------------------------------------------- Bluetooth

/** Bentuk minimal yang kita perlukan dari Web Bluetooth (memudahkan pengujian). */
export interface KarakteristikBle {
  properties?: { write?: boolean; writeWithoutResponse?: boolean }
  writeValue?(data: BufferSource): Promise<void>
  writeValueWithoutResponse?(data: BufferSource): Promise<void>
}
export interface LayananBle {
  uuid?: string
  getCharacteristics(): Promise<KarakteristikBle[]>
}
export interface PeladenGattBle {
  connect?(): Promise<PeladenGattBle>
  getPrimaryService?(uuid: string): Promise<LayananBle>
  getPrimaryServices?(): Promise<LayananBle[]>
}
export interface PerangkatBle {
  name?: string | null
  gatt?: PeladenGattBle
}

/** Apakah karakteristik ini bisa ditulisi? */
function bisaDitulis(k: KarakteristikBle): boolean {
  const p = k.properties
  if (p && (p.write || p.writeWithoutResponse)) return true
  // Sebagian peramban/implementasi tidak melaporkan properties; kalau ada
  // fungsi tulisnya, anggap bisa — lebih baik dicoba daripada langsung menyerah.
  return typeof k.writeValue === 'function' || typeof k.writeValueWithoutResponse === 'function'
}

/**
 * Cari karakteristik yang bisa dipakai menulis ke printer.
 *
 * Bertingkat: alamat yang dikenal dulu, baru penelusuran menyeluruh. Inilah
 * yang membuat printer merek asing tetap punya peluang bekerja.
 */
export async function cariKarakteristikTulis(peladen: PeladenGattBle): Promise<KarakteristikBle> {
  // Tahap 1 — alamat layanan yang sudah dikenal.
  if (typeof peladen.getPrimaryService === 'function') {
    for (const uuid of UUID_LAYANAN_UMUM) {
      try {
        const layanan = await peladen.getPrimaryService(uuid)
        const daftar = await layanan.getCharacteristics()
        const cocok = daftar.find(bisaDitulis)
        if (cocok) return cocok
      } catch {
        // Layanan ini tidak ada di printer tersebut — wajar, lanjut ke berikutnya.
        continue
      }
    }
  }

  // Tahap 2 — telusuri semua layanan; pakai apa pun yang bisa ditulisi.
  if (typeof peladen.getPrimaryServices === 'function') {
    try {
      const semua = await peladen.getPrimaryServices()
      for (const layanan of semua) {
        try {
          const daftar = await layanan.getCharacteristics()
          const cocok = daftar.find(bisaDitulis)
          if (cocok) return cocok
        } catch {
          continue
        }
      }
    } catch {
      // jatuh ke galat di bawah
    }
  }

  throw new GagalCetak(
    'Printer tersambung, tetapi jalur untuk mengirim data tidak ditemukan. ' +
      'Coba matikan lalu hidupkan kembali printernya, atau pakai printer lain.',
    'sambungan',
  )
}

/** Kirim byte ke karakteristik BLE, potong demi potong. */
export async function kirimKeKarakteristik(
  k: KarakteristikBle,
  data: Uint8Array,
  besarPotongan: number = POTONGAN_BLE,
): Promise<number> {
  const potongan = potongData(data, besarPotongan)
  const tulis = k.writeValue ?? k.writeValueWithoutResponse
  if (typeof tulis !== 'function') {
    throw new GagalCetak('Printer tidak menerima kiriman data.', 'kirim')
  }
  for (const bagian of potongan) {
    await tulis.call(k, bagian)
  }
  return potongan.length
}

/** Cetak lewat perangkat Bluetooth yang sudah dipilih pengguna. */
export async function cetakBluetooth(perangkat: PerangkatBle, data: Uint8Array): Promise<void> {
  const gatt = perangkat.gatt
  if (!gatt) {
    throw new GagalCetak('Printer Bluetooth tidak bisa dihubungi.', 'sambungan')
  }
  let peladen: PeladenGattBle = gatt
  if (typeof gatt.connect === 'function') {
    try {
      peladen = await gatt.connect()
    } catch {
      throw new GagalCetak(
        'Gagal menyambung ke printer. Pastikan printer menyala dan berada di dekat perangkat.',
        'sambungan',
      )
    }
  }
  const karakteristik = await cariKarakteristikTulis(peladen)
  try {
    await kirimKeKarakteristik(karakteristik, data)
  } catch (galat) {
    if (galat instanceof GagalCetak) throw galat
    throw new GagalCetak(
      'Pengiriman ke printer terputus di tengah jalan. Periksa kertas dan daya printer.',
      'kirim',
    )
  }
}

// --------------------------------------------------------------------- USB

/** Bentuk minimal WebUSB yang kita perlukan. */
export interface UjungUsb {
  direction: string
  endpointNumber: number
}
export interface AlternatifUsb {
  interfaceClass?: number
  endpoints: UjungUsb[]
}
export interface AntarmukaUsb {
  interfaceNumber: number
  alternate?: AlternatifUsb
  alternates?: AlternatifUsb[]
}
export interface KonfigurasiUsb {
  configurationValue?: number
  interfaces: AntarmukaUsb[]
}
export interface PerangkatUsb {
  configuration?: KonfigurasiUsb | null
  configurations?: KonfigurasiUsb[]
  open(): Promise<void>
  close(): Promise<void>
  selectConfiguration(nilai: number): Promise<void>
  claimInterface(nomor: number): Promise<void>
  releaseInterface?(nomor: number): Promise<void>
  transferOut(ujung: number, data: BufferSource): Promise<unknown>
}

/** Kelas USB 7 = Printer. Dipakai hampir semua printer struk. */
const KELAS_USB_PRINTER = 7

/**
 * Cari antarmuka & jalur keluar pada printer USB.
 *
 * Mengutamakan kelas 7 (Printer); kalau tidak ada, memakai jalur keluar apa pun
 * yang tersedia — supaya printer yang tidak mengaku kelas 7 tetap bisa dipakai.
 */
export function cariJalurUsb(konfigurasi: KonfigurasiUsb): { antarmuka: number; ujung: number } {
  const alternatifDari = (a: AntarmukaUsb): AlternatifUsb[] =>
    a.alternate ? [a.alternate] : (a.alternates ?? [])

  // Tahap 1 — antarmuka yang menyatakan diri sebagai printer.
  for (const antarmuka of konfigurasi.interfaces) {
    for (const alt of alternatifDari(antarmuka)) {
      if (alt.interfaceClass !== KELAS_USB_PRINTER) continue
      const keluar = alt.endpoints.find((e) => e.direction === 'out')
      if (keluar) {
        return { antarmuka: antarmuka.interfaceNumber, ujung: keluar.endpointNumber }
      }
    }
  }

  // Tahap 2 — jalur keluar apa pun.
  for (const antarmuka of konfigurasi.interfaces) {
    for (const alt of alternatifDari(antarmuka)) {
      const keluar = alt.endpoints.find((e) => e.direction === 'out')
      if (keluar) {
        return { antarmuka: antarmuka.interfaceNumber, ujung: keluar.endpointNumber }
      }
    }
  }

  throw new GagalCetak(
    'Printer USB terpasang, tetapi jalur untuk mengirim data tidak ditemukan. ' +
      'Coba cabut dan pasang kembali kabelnya.',
    'sambungan',
  )
}

/** Cetak lewat printer USB yang sudah dipilih pengguna. */
export async function cetakUsb(perangkat: PerangkatUsb, data: Uint8Array): Promise<void> {
  try {
    await perangkat.open()
  } catch {
    throw new GagalCetak(
      'Printer USB tidak bisa dibuka. Pastikan tidak sedang dipakai program lain.',
      'sambungan',
    )
  }

  let nomorAntarmuka: number | null = null
  try {
    let konfigurasi = perangkat.configuration ?? null
    if (!konfigurasi) {
      const pertama = perangkat.configurations?.[0]
      await perangkat.selectConfiguration(pertama?.configurationValue ?? 1)
      konfigurasi = perangkat.configuration ?? pertama ?? null
    }
    if (!konfigurasi) {
      throw new GagalCetak('Printer USB tidak melaporkan pengaturannya.', 'sambungan')
    }

    const jalur = cariJalurUsb(konfigurasi)
    nomorAntarmuka = jalur.antarmuka
    await perangkat.claimInterface(jalur.antarmuka)
    await perangkat.transferOut(jalur.ujung, data)
  } catch (galat) {
    if (galat instanceof GagalCetak) throw galat
    throw new GagalCetak(
      'Pengiriman ke printer USB gagal. Periksa kertas, daya, dan kabelnya.',
      'kirim',
    )
  } finally {
    // Selalu dilepas: antarmuka yang tetap dipegang membuat cetak BERIKUTNYA
    // gagal dengan pesan membingungkan ("sedang dipakai program lain").
    try {
      if (nomorAntarmuka !== null && perangkat.releaseInterface) {
        await perangkat.releaseInterface(nomorAntarmuka)
      }
      await perangkat.close()
    } catch {
      // Menutup adalah usaha terbaik; kegagalannya tidak boleh menutupi
      // keberhasilan/kegagalan cetak yang sebenarnya.
    }
  }
}
