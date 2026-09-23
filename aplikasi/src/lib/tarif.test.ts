/**
 * Uji T-027 — perkiraan keranjang mengikuti tarif resto.
 *
 * Yang paling dijaga: hasilnya harus SAMA dengan rumus peladen
 * (`hitung_total`, migrasi 0025). Kalau layar dan peladen berbeda cara
 * menghitung, selisihnya baru ketahuan di depan tamu — saat kasir sudah
 * terlanjur menyebut angka.
 */
import { describe, expect, it } from 'vitest'
import { TARIF_BAWAAN, hitungPerkiraan, type TarifResto } from './tarif'

const TANPA_BULAT: TarifResto = { pajakPersen: 10, servicePersen: 5, pembulatan: 'none' }

describe('hitungPerkiraan — tarif resto, bukan angka keras-kode', () => {
  it('memakai tarif bawaan bila pengaturan belum termuat', () => {
    const r = hitungPerkiraan(100000, 0)
    expect(r.pajak).toBe(10000)
    expect(r.service).toBe(5000)
    expect(r.total).toBe(115000)
  })

  it('mengikuti tarif resto yang berbeda dari bawaan (inti T-027)', () => {
    const r = hitungPerkiraan(100000, 0, {
      pajakPersen: 11,
      servicePersen: 0,
      pembulatan: 'none',
    })
    expect(r.pajak).toBe(11000)
    expect(r.service).toBe(0)
    expect(r.total).toBe(111000)
  })

  it('kedai tanpa pajak dan tanpa service tetap dapat total yang benar', () => {
    const r = hitungPerkiraan(50000, 0, { pajakPersen: 0, servicePersen: 0, pembulatan: 'none' })
    expect(r.total).toBe(50000)
  })

  it('pajak dihitung dari dasar SESUDAH diskon, sama seperti peladen', () => {
    // dasar = 100000 - 20000 = 80000 → pajak 8000, service 4000
    const r = hitungPerkiraan(100000, 20000, TANPA_BULAT)
    expect(r.pajak).toBe(8000)
    expect(r.service).toBe(4000)
    expect(r.total).toBe(92000)
  })

  it('diskon lebih besar dari subtotal tidak membuat angka negatif', () => {
    const r = hitungPerkiraan(30000, 50000, TANPA_BULAT)
    expect(r.pajak).toBe(0)
    expect(r.service).toBe(0)
    expect(r.total).toBe(0)
  })

  it('pembulatan mengikuti peladen: TURUN ke kelipatan, bukan naik', () => {
    // dasar 33333 → pajak 3333, service 1667 → kasar 38333 → bulat 500 → 38000
    const r = hitungPerkiraan(33333, 0, { pajakPersen: 10, servicePersen: 5, pembulatan: '500' })
    expect(r.total).toBe(38000)
    expect(r.total).toBeLessThanOrEqual(r.subtotal + r.pajak + r.service)
  })

  it('pembulatan 1000 bekerja', () => {
    const r = hitungPerkiraan(100000, 0, { pajakPersen: 10, servicePersen: 5, pembulatan: '1000' })
    expect(r.total).toBe(115000)
  })

  it('tarif tidak masuk akal jadi 0, bukan NaN — kasir tidak bisa menebak "RpNaN"', () => {
    const r = hitungPerkiraan(100000, 0, {
      pajakPersen: Number.NaN,
      servicePersen: -5,
      pembulatan: 'none',
    })
    expect(r.pajak).toBe(0)
    expect(r.service).toBe(0)
    expect(r.total).toBe(100000)
  })

  it('tarif bawaan sama dengan nilai bawaan kolom pengaturan (10 % / 5 % / tanpa pembulatan)', () => {
    expect(TARIF_BAWAAN).toEqual({ pajakPersen: 10, servicePersen: 5, pembulatan: 'none' })
  })

  it('subtotal & diskon diteruskan apa adanya untuk ditampilkan', () => {
    const r = hitungPerkiraan(75000, 5000, TANPA_BULAT)
    expect(r.subtotal).toBe(75000)
    expect(r.totalDiskon).toBe(5000)
  })
})
