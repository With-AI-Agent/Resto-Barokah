import { describe, it, expect } from 'vitest'

interface ItemBeban {
  id: string
  nama: string
  harga: number
  qty: number
}

function hitungRingkasanBeban(items: ItemBeban[]) {
  const mulai = performance.now()
  const subtotal = items.reduce((acc, item) => acc + item.harga * item.qty, 0)
  const serviceCharge = Math.round(subtotal * 0.05)
  const pajakPb1 = Math.round((subtotal + serviceCharge) * 0.1)
  const totalAkhir = subtotal + serviceCharge + pajakPb1
  const selesai = performance.now()
  return {
    subtotal,
    serviceCharge,
    pajakPb1,
    totalAkhir,
    durasiMs: selesai - mulai,
  }
}

describe('Uji Beban Ringan Kasir (T3-16)', () => {
  it('mampu memproses kalkulasi 50 item pesanan sekaligus dalam < 10ms', () => {
    const items: ItemBeban[] = Array.from({ length: 50 }, (_, i) => ({
      id: `item-${i + 1}`,
      nama: `Menu Beban Uji Ke-${i + 1}`,
      harga: 15000 + (i % 10) * 2500,
      qty: (i % 4) + 1,
    }))

    const hasil = hitungRingkasanBeban(items)

    expect(items.length).toBe(50)
    expect(hasil.totalAkhir).toBeGreaterThan(0)
    expect(hasil.durasiMs).toBeLessThan(10) // Sangat cepat di bawah 10ms
  })

  it('mampu menyimulasikan akumulasi 300 transaksi per hari dalam hitungan milidetik', () => {
    const mulai = performance.now()
    let grandTotalOmset = 0

    for (let t = 1; t <= 300; t++) {
      const items: ItemBeban[] = Array.from({ length: 5 }, (_, i) => ({
        id: `t-${t}-item-${i}`,
        nama: `Menu ${i}`,
        harga: 25000,
        qty: 2,
      }))
      const res = hitungRingkasanBeban(items)
      grandTotalOmset += res.totalAkhir
    }

    const selesai = performance.now()
    const durasiTotal = selesai - mulai

    expect(grandTotalOmset).toBeGreaterThan(0)
    expect(durasiTotal).toBeLessThan(100) // 300 transaksi di bawah 100ms
  })
})
