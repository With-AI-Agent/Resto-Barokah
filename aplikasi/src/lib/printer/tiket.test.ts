/**
 * Uji T6-05 — tiket dapur.
 *
 * Yang paling dijaga: catatan khusus tidak boleh hilang atau tenggelam.
 * "Tanpa kacang" yang terlewat bisa berarti alergi, bukan sekadar selera.
 */
import { describe, expect, it } from 'vitest'
import { susunTiket, susunTiketTerpisah, type DataTiket } from './tiket'
import { LEBAR_58MM } from './expos'

/** Buang perintah ESC/POS beserta parameternya (lihat catatan di struk.test.ts). */
function bacaTeks(byte: Uint8Array): string {
  const a = Array.from(byte)
  let keluar = ''
  for (let i = 0; i < a.length; i += 1) {
    const b = a[i]
    if (b === 0x1b) {
      const perintah = a[i + 1]
      if (perintah === 0x40) i += 1
      else if (perintah === 0x70) i += 4
      else i += 2
      continue
    }
    if (b === 0x1d) {
      i += 2
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

const DASAR: DataTiket = {
  nomor: 45,
  dikirimPada: '2026-09-23T07:15:00.000Z',
  namaMeja: 'Meja 4',
  tipe: 'dinein',
  item: [
    { nama: 'Nasi Goreng', qty: 2 },
    { nama: 'Ayam Bakar', qty: 1, catatan: 'tanpa kacang, alergi' },
  ],
}

describe('susunTiket — isi wajib (DoD T6-05)', () => {
  const teks = bacaTeks(susunTiket(DASAR))

  it('memuat nomor pesanan', () => {
    expect(teks).toContain('#45')
  })

  it('memuat meja dan jenis pesanan', () => {
    expect(teks).toContain('Meja 4')
    expect(teks).toContain('dinein')
  })

  it('memuat jam kirim dari peladen', () => {
    expect(teks).toContain('Jam:')
  })

  it('memuat tiap item beserta jumlahnya, jumlah di depan', () => {
    expect(teks).toContain('2x Nasi Goreng')
    expect(teks).toContain('1x Ayam Bakar')
  })

  it('memuat catatan khusus', () => {
    expect(teks).toContain('tanpa kacang, alergi')
  })
})

describe('susunTiket — catatan khusus harus MENCOLOK', () => {
  it('catatan diberi awalan >> supaya tidak terbaca sebagai nama menu', () => {
    expect(bacaTeks(susunTiket(DASAR))).toContain('>> tanpa kacang')
  })

  it('catatan dicetak tebal (ESC E 1 muncul sebelum teks catatan)', () => {
    const byte = Array.from(susunTiket(DASAR))
    // Cari posisi byte '>' pertama; sebelum itu harus ada ESC E 1.
    const posisi = byte.findIndex((b, i) => b === 0x3e && byte[i + 1] === 0x3e)
    expect(posisi).toBeGreaterThan(0)
    const sebelum = byte.slice(0, posisi)
    const adaTebal = sebelum.some(
      (b, i) => b === 0x1b && sebelum[i + 1] === 0x45 && sebelum[i + 2] === 0x01,
    )
    expect(adaTebal).toBe(true)
  })

  it('item tanpa catatan tidak memunculkan penanda catatan', () => {
    const polos: DataTiket = { ...DASAR, item: [{ nama: 'Es Teh', qty: 1 }] }
    expect(bacaTeks(susunTiket(polos))).not.toContain('>>')
  })
})

describe('susunTiket — tiket dapur TIDAK memuat uang', () => {
  it('tidak ada satu pun angka rupiah di tiket', () => {
    const teks = bacaTeks(susunTiket(DASAR))
    expect(teks).not.toContain('Rp')
    expect(teks).not.toContain('Total')
    expect(teks).not.toContain('TOTAL')
  })
})

describe('susunTiket — perilaku printer', () => {
  it('nomor pesanan dicetak dengan huruf besar (GS ! 0x11)', () => {
    const byte = Array.from(susunTiket(DASAR))
    const adaBesar = byte.some((b, i) => b === 0x1d && byte[i + 1] === 0x21 && byte[i + 2] === 0x11)
    expect(adaBesar).toBe(true)
  })

  it('diawali ESC @ dan diakhiri potong kertas', () => {
    const byte = susunTiket(DASAR)
    expect(Array.from(byte.slice(0, 2))).toEqual([0x1b, 0x40])
    expect(Array.from(byte.slice(-3))).toEqual([0x1d, 0x56, 0x00])
  })

  it('tidak pernah membuka laci kas (itu urusan kasir, bukan dapur)', () => {
    const byte = Array.from(susunTiket(DASAR))
    const adaLaci = byte.some((b, i) => b === 0x1b && byte[i + 1] === 0x70)
    expect(adaLaci).toBe(false)
  })

  it('tidak ada baris melebihi lebar kertas, termasuk nama & catatan panjang', () => {
    const panjang: DataTiket = {
      ...DASAR,
      item: [
        {
          nama: 'Nasi Goreng Spesial Kampung Pedas Level Lima Porsi Besar',
          qty: 3,
          catatan: 'tanpa sambal tanpa kacang tanpa bawang goreng sama sekali ya',
        },
      ],
    }
    for (const baris of bacaTeks(susunTiket(panjang)).split('\n')) {
      expect(baris.length).toBeLessThanOrEqual(LEBAR_58MM)
    }
  })

  it('tanda SALINAN muncul hanya saat cetak ulang', () => {
    expect(bacaTeks(susunTiket(DASAR))).not.toContain('SALINAN')
    expect(bacaTeks(susunTiket(DASAR, { salinan: true }))).toContain('SALINAN - CETAK ULANG')
  })
})

describe('susunTiketTerpisah — makanan & minuman dikerjakan stasiun berbeda', () => {
  const campur: DataTiket = {
    ...DASAR,
    item: [
      { nama: 'Nasi Goreng', qty: 2, stasiun: 'makanan' },
      { nama: 'Es Teh', qty: 3, stasiun: 'minuman' },
    ],
  }

  it('menghasilkan dua tiket dengan judul stasiun masing-masing', () => {
    const hasil = susunTiketTerpisah(campur)
    expect(hasil).toHaveLength(2)
    expect(hasil[0].stasiun).toBe('makanan')
    expect(hasil[1].stasiun).toBe('minuman')
    expect(bacaTeks(hasil[0].byte)).toContain('MAKANAN')
    expect(bacaTeks(hasil[1].byte)).toContain('MINUMAN')
  })

  it('tiket makanan TIDAK memuat item minuman, dan sebaliknya', () => {
    const hasil = susunTiketTerpisah(campur)
    const makanan = bacaTeks(hasil[0].byte)
    const minuman = bacaTeks(hasil[1].byte)
    expect(makanan).toContain('Nasi Goreng')
    expect(makanan).not.toContain('Es Teh')
    expect(minuman).toContain('Es Teh')
    expect(minuman).not.toContain('Nasi Goreng')
  })

  it('stasiun tanpa item tidak menghasilkan tiket kosong', () => {
    const hanyaMinum: DataTiket = {
      ...DASAR,
      item: [{ nama: 'Es Teh', qty: 1, stasiun: 'minuman' }],
    }
    const hasil = susunTiketTerpisah(hanyaMinum)
    expect(hasil).toHaveLength(1)
    expect(hasil[0].stasiun).toBe('minuman')
  })

  it('item tanpa stasiun dianggap makanan (asumsi paling aman)', () => {
    const hasil = susunTiketTerpisah({ ...DASAR, item: [{ nama: 'Ayam Bakar', qty: 1 }] })
    expect(hasil).toHaveLength(1)
    expect(hasil[0].stasiun).toBe('makanan')
  })

  it('nomor pesanan yang sama muncul di kedua tiket (agar bisa disatukan lagi)', () => {
    const hasil = susunTiketTerpisah(campur)
    expect(bacaTeks(hasil[0].byte)).toContain('#45')
    expect(bacaTeks(hasil[1].byte)).toContain('#45')
  })

  it('tanda salinan diteruskan ke semua tiket stasiun', () => {
    const hasil = susunTiketTerpisah(campur, { salinan: true })
    for (const t of hasil) expect(bacaTeks(t.byte)).toContain('SALINAN')
  })
})
