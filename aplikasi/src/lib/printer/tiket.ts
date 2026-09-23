/**
 * tiket.ts (T6-05) — susun tiket dapur menjadi byte ESC/POS.
 *
 * Tiket dapur bukan struk kecil. Bedanya mendasar, dan salah memperlakukannya
 * menimbulkan masalah nyata di dapur:
 *
 *  1. **Tidak ada satu pun angka uang.** Dapur tidak perlu tahu harga, dan
 *     mencetaknya hanya menambah baris yang harus dibaca cepat di tengah
 *     kesibukan. Aturan ini dijaga uji, bukan sekadar niat.
 *
 *  2. **Catatan khusus harus MENCOLOK.** "Tanpa kacang" yang terlewat bukan
 *     soal selera — bisa berarti alergi. Karena itu catatan dicetak dengan
 *     huruf tebal dan diberi awalan `>>`, bukan sekadar teks kecil di bawah.
 *
 *  3. **Nomor pesanan dicetak besar.** Tiket dibaca sambil lalu, sering dari
 *     jarak satu meter di atas meja panas; nomor kecil membuat pelayan salah
 *     ambil pesanan.
 *
 *  4. **Makanan & minuman bisa dipisah** (DoD T6-05) karena biasanya dikerjakan
 *     dua stasiun berbeda. `susunTiketTerpisah` menghasilkan dua tiket, dan
 *     stasiun yang tidak punya item tidak menghasilkan tiket sama sekali —
 *     tiket kosong hanya membuang kertas dan membingungkan.
 *
 *  5. **Cetakan kedua ditandai "SALINAN"** (sejalan dengan T5-10) supaya dapur
 *     tidak memasak dua kali untuk satu pesanan.
 */
import { jamLokal } from '../format'
import { LEBAR_58MM, PenyusunEscPos, bungkusTeks } from './expos'

export type StasiunTiket = 'makanan' | 'minuman'

export interface ItemTiket {
  nama: string
  qty: number
  catatan?: string
  /** Stasiun pengerjaan; dipakai `susunTiketTerpisah`. */
  stasiun?: StasiunTiket
}

export interface DataTiket {
  nomor: number
  /** ISO dari peladen — jam kirim ke dapur, bukan jam perangkat. */
  dikirimPada: string
  /** "Meja 4", atau keterangan bawa pulang. */
  namaMeja?: string | null
  /** "dinein" | "takeaway" | "online" — dicetak sebagai jenis pesanan. */
  tipe?: string
  item: ItemTiket[]
}

export interface OpsiTiket {
  lebar?: number
  /** Tandai cetakan kedua supaya dapur tidak memasak dua kali. */
  salinan?: boolean
  /** Judul stasiun, mis. "MAKANAN" — dipakai saat tiket dipisah. */
  judulStasiun?: string
}

/** Susun satu tiket dapur. */
export function susunTiket(data: DataTiket, opsi: OpsiTiket = {}): Uint8Array {
  const lebar = opsi.lebar ?? LEBAR_58MM
  const p = new PenyusunEscPos(lebar)

  p.awal().pilihCp437().rata('tengah')

  if (opsi.salinan) {
    p.tebal(true).baris('SALINAN - CETAK ULANG').tebal(false)
  }

  // Nomor pesanan besar: dibaca sambil lalu di dapur.
  p.hurufBesar(true).tebal(true).baris(`#${data.nomor}`).tebal(false).hurufBesar(false)

  if (opsi.judulStasiun) p.tebal(true).baris(opsi.judulStasiun).tebal(false)

  p.rata('kiri').garis()

  if (data.namaMeja) p.baris(data.namaMeja)
  if (data.tipe) p.baris(`Jenis: ${data.tipe}`)
  p.baris(`Jam: ${jamLokal(new Date(data.dikirimPada))}`)
  p.garis()

  for (const item of data.item) {
    // Jumlah di depan nama: mata dapur mencari "berapa" lebih dulu.
    for (const baris of bungkusTeks(`${item.qty}x ${item.nama}`, lebar)) p.baris(baris)
    if (item.catatan) {
      p.tebal(true)
      for (const baris of bungkusTeks(`>> ${item.catatan}`, lebar)) p.baris(baris)
      p.tebal(false)
    }
  }

  p.potongKertas()
  return p.selesai()
}

/**
 * Pisahkan tiket per stasiun (makanan / minuman).
 *
 * Item tanpa `stasiun` dianggap makanan — asumsi yang paling aman karena
 * dapur panas adalah stasiun bawaan di kedai kecil. Stasiun tanpa item tidak
 * menghasilkan tiket (tidak ada kertas terbuang, tidak ada tiket kosong yang
 * membingungkan).
 */
export function susunTiketTerpisah(
  data: DataTiket,
  opsi: OpsiTiket = {},
): { stasiun: StasiunTiket; byte: Uint8Array }[] {
  const makanan = data.item.filter((i) => (i.stasiun ?? 'makanan') === 'makanan')
  const minuman = data.item.filter((i) => i.stasiun === 'minuman')

  const hasil: { stasiun: StasiunTiket; byte: Uint8Array }[] = []
  if (makanan.length > 0) {
    hasil.push({
      stasiun: 'makanan',
      byte: susunTiket({ ...data, item: makanan }, { ...opsi, judulStasiun: 'MAKANAN' }),
    })
  }
  if (minuman.length > 0) {
    hasil.push({
      stasiun: 'minuman',
      byte: susunTiket({ ...data, item: minuman }, { ...opsi, judulStasiun: 'MINUMAN' }),
    })
  }
  return hasil
}
