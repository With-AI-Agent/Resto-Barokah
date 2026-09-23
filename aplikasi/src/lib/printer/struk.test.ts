/**
 * Uji T6-04 — struk termal.
 *
 * Fokus uji ini bukan "apakah tercetak", melainkan **apakah isinya sama dengan
 * yang dilihat tamu di layar dan sama dengan yang tercatat di kas**. Struk
 * adalah bukti bayar; salah satu angka saja berarti sengketa di depan kasir.
 */
import { describe, expect, it } from 'vitest'
import { susunStruk } from './struk'
import { LEBAR_58MM, LEBAR_80MM } from './expos'
import type { DataStruk } from '../../komponen/Struk'

/**
 * Ubah byte jadi teks yang bisa dibaca manusia.
 *
 * Perintah ESC/POS dibuang BESERTA parameternya. Ini penting: `ESC E 1`
 * (tebal) dan `ESC a 1` (rata tengah) membawa parameter yang kebetulan berada
 * di rentang ASCII ('E', 'a'), jadi kalau hanya byte kendali yang dibuang,
 * huruf sisanya ikut terbaca sebagai isi struk dan panjang baris jadi salah
 * hitung. Versi pertama uji ini melakukan justru kesalahan itu.
 */
function bacaTeks(byte: Uint8Array): string {
  const a = Array.from(byte)
  let keluar = ''
  for (let i = 0; i < a.length; i += 1) {
    const b = a[i]
    if (b === 0x1b) {
      const perintah = a[i + 1]
      // ESC @ tidak berparameter; ESC p (laci) punya tiga; sisanya satu.
      if (perintah === 0x40) i += 1
      else if (perintah === 0x70) i += 4
      else i += 2
      continue
    }
    if (b === 0x1d) {
      i += 2 // GS ! n / GS V n
      continue
    }
    if (b === 0x0a) {
      keluar += '\n'
      continue
    }
    if (b >= 0x20 && b <= 0x7e) keluar += String.fromCharCode(b)
  }
  return keluar
}

const DASAR: DataStruk = {
  nomor: 12,
  tanggal: '2026-09-23T04:30:00.000Z',
  namaResto: 'Kedai Oasis',
  header: 'Jl. Merdeka 10, Bandung',
  footer: 'Terima kasih, sampai jumpa lagi',
  namaMeja: 'Meja 4',
  item: [
    { nama: 'Nasi Goreng', qty: 2, hargaSatuan: 27500, subtotal: 55000 },
    { nama: 'Es Teh', qty: 1, hargaSatuan: 5000, subtotal: 5000 },
  ],
  subtotal: 60000,
  totalDiskon: 0,
  pajak: 6000,
  service: 3000,
  total: 69000,
}

describe('susunStruk — isi wajib (DoD T6-04)', () => {
  const teks = bacaTeks(susunStruk(DASAR, { namaKasir: 'Dedi' }))

  it('memuat identitas resto dari pengaturan, bukan keras-kode', () => {
    expect(teks).toContain('Kedai Oasis')
    expect(teks).toContain('Jl. Merdeka 10, Bandung')
  })

  it('memuat nomor, tanggal, meja, dan kasir', () => {
    expect(teks).toContain('No. 12')
    expect(teks).toContain('23 Sep 2026')
    expect(teks).toContain('Meja 4')
    expect(teks).toContain('Kasir: Dedi')
  })

  it('memuat tiap item beserta qty dan harga satuan', () => {
    expect(teks).toContain('Nasi Goreng')
    expect(teks).toContain('2 x Rp27.500')
    expect(teks).toContain('Rp55.000')
    expect(teks).toContain('Es Teh')
  })

  it('memuat subtotal, pajak, service, dan total', () => {
    expect(teks).toContain('Subtotal')
    expect(teks).toContain('PB1 (pajak)')
    expect(teks).toContain('Rp6.000')
    expect(teks).toContain('Service')
    expect(teks).toContain('Rp3.000')
    expect(teks).toContain('TOTAL')
    expect(teks).toContain('Rp69.000')
  })

  it('memuat ucapan penutup dari pengaturan', () => {
    expect(teks).toContain('Terima kasih')
  })
})

describe('susunStruk — aturan yang sama dengan layar (T5-03)', () => {
  it('pajak & service TETAP dicetak walau 0 persen', () => {
    const nol: DataStruk = { ...DASAR, pajak: 0, service: 0, total: 60000 }
    const teks = bacaTeks(susunStruk(nol))
    expect(teks).toContain('PB1 (pajak)')
    expect(teks).toContain('Service')
  })

  it('diskon hanya dicetak bila memang ada', () => {
    expect(bacaTeks(susunStruk(DASAR))).not.toContain('Diskon')
    const diskon: DataStruk = { ...DASAR, totalDiskon: 5000, total: 64000 }
    expect(bacaTeks(susunStruk(diskon))).toContain('Diskon')
  })

  it('pembulatan dicetak sebagai SELISIH bertanda, supaya rincian menjumlah ke total', () => {
    // subtotal 60.000 + pajak 6.000 + service 3.000 = 69.000; total dibulatkan 68.500.
    const bulat: DataStruk = { ...DASAR, total: 68500 }
    const teks = bacaTeks(susunStruk(bulat))
    expect(teks).toContain('Pembulatan')
    expect(teks).toContain('-Rp500')
  })

  it('tanpa pembulatan, barisnya tidak muncul', () => {
    expect(bacaTeks(susunStruk(DASAR))).not.toContain('Pembulatan')
  })
})

describe('susunStruk — pembayaran & sisa', () => {
  it('lunas bila pembayaran menutup total', () => {
    const teks = bacaTeks(
      susunStruk(DASAR, {
        pembayaran: [{ metode: 'Tunai', jumlah: 69000 }],
        kembalian: 1000,
      }),
    )
    expect(teks).toContain('Tunai')
    expect(teks).toContain('Kembalian')
    expect(teks).toContain('LUNAS')
  })

  it('sisa tagihan WAJIB tercetak bila belum lunas (jangan diam)', () => {
    const teks = bacaTeks(susunStruk(DASAR, { pembayaran: [{ metode: 'Tunai', jumlah: 20000 }] }))
    expect(teks).not.toContain('LUNAS')
    expect(teks).toContain('Sisa tagihan')
    expect(teks).toContain('Rp49.000')
  })

  it('beberapa metode tercetak sebagai baris terpisah (kas per metode bisa dicocokkan)', () => {
    const teks = bacaTeks(
      susunStruk(DASAR, {
        pembayaran: [
          { metode: 'Tunai', jumlah: 20000 },
          { metode: 'QRIS', jumlah: 49000, referensi: 'QR-77' },
        ],
      }),
    )
    expect(teks).toContain('Tunai')
    expect(teks).toContain('QRIS (QR-77)')
    expect(teks).toContain('LUNAS')
  })

  it('tanpa pembayaran, blok bayar tidak dicetak sama sekali', () => {
    const teks = bacaTeks(susunStruk(DASAR))
    expect(teks).not.toContain('Kembalian')
    expect(teks).not.toContain('LUNAS')
  })
})

describe('susunStruk — perilaku printer', () => {
  it('selalu diawali ESC @ dan diakhiri perintah potong kertas', () => {
    const byte = susunStruk(DASAR)
    expect(Array.from(byte.slice(0, 2))).toEqual([0x1b, 0x40])
    expect(Array.from(byte.slice(-3))).toEqual([0x1d, 0x56, 0x00])
  })

  it('laci kas hanya terbuka bila diminta (kartu/QRIS tidak membuka laci)', () => {
    const tanpa = Array.from(susunStruk(DASAR))
    const dengan = Array.from(susunStruk(DASAR, { bukaLaci: true }))
    const escP = (a: number[]) => a.some((_, i) => a[i] === 0x1b && a[i + 1] === 0x70)
    expect(escP(tanpa)).toBe(false)
    expect(escP(dengan)).toBe(true)
  })

  it('tanda SALINAN tercetak saat cetak ulang, dan tidak saat cetak pertama', () => {
    expect(bacaTeks(susunStruk(DASAR))).not.toContain('SALINAN')
    expect(bacaTeks(susunStruk(DASAR, { salinan: true }))).toContain('SALINAN - CETAK ULANG')
  })

  it('tanda SALINAN tidak mengubah satu pun angka', () => {
    const biasa = bacaTeks(susunStruk(DASAR))
    const salinan = bacaTeks(susunStruk(DASAR, { salinan: true }))
    expect(salinan.replace('SALINAN - CETAK ULANG\n', '')).toBe(biasa)
  })

  it('tidak ada baris yang melebihi lebar kertas 58 mm', () => {
    const teks = bacaTeks(susunStruk(DASAR, { namaKasir: 'Dedi' }))
    for (const baris of teks.split('\n')) {
      expect(baris.length).toBeLessThanOrEqual(LEBAR_58MM)
    }
  })

  it('tidak ada baris yang melebihi lebar kertas 80 mm', () => {
    const teks = bacaTeks(susunStruk(DASAR, { lebar: LEBAR_80MM }))
    for (const baris of teks.split('\n')) {
      expect(baris.length).toBeLessThanOrEqual(LEBAR_80MM)
    }
  })

  it('nama menu panjang tidak menggeser angka rupiah', () => {
    const panjang: DataStruk = {
      ...DASAR,
      item: [
        {
          nama: 'Nasi Goreng Spesial Kampung Pedas Level Lima Porsi Besar',
          qty: 1,
          hargaSatuan: 127500,
          subtotal: 127500,
        },
      ],
    }
    const teks = bacaTeks(susunStruk(panjang))
    expect(teks).toContain('Rp127.500')
    for (const baris of teks.split('\n')) {
      expect(baris.length).toBeLessThanOrEqual(LEBAR_58MM)
    }
  })

  it('catatan item ikut tercetak (dapur & tamu melihat hal yang sama)', () => {
    const berCatatan: DataStruk = {
      ...DASAR,
      item: [
        {
          nama: 'Nasi Goreng',
          qty: 1,
          hargaSatuan: 27500,
          subtotal: 27500,
          catatan: 'tanpa sambal, pedas sedikit saja',
        },
      ],
    }
    const teks = bacaTeks(susunStruk(berCatatan))
    expect(teks).toContain('tanpa sambal')
  })

  it('tanggal diambil dari ISO peladen, bukan jam perangkat', () => {
    const lain: DataStruk = { ...DASAR, tanggal: '2026-01-05T02:00:00.000Z' }
    expect(bacaTeks(susunStruk(lain))).toContain('5 Jan 2026')
  })
})
