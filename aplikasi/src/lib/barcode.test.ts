import { describe, it, expect } from 'vitest'
import { apakahFormatVoucherAcak, buatPolaGaris } from './barcode'

describe('Helper Barcode & Pola Garis 1D (lib/barcode.ts — T8-08)', () => {
  it('apakahFormatVoucherAcak memvalidasi format RB-XXXX-XXXX non-ambigu', () => {
    expect(apakahFormatVoucherAcak('RB-7X9K-2M4P')).toBe(true)
    expect(apakahFormatVoucherAcak('rb-7x9k-2m4p')).toBe(true)

    // Karakter ambigu (0, O, 1, I, L) ditolak
    expect(apakahFormatVoucherAcak('RB-0123-4567')).toBe(false)
    expect(apakahFormatVoucherAcak('RB-OIL1-2345')).toBe(false)

    // Format di luar RB-XXXX-XXXX ditolak
    expect(apakahFormatVoucherAcak('BRK-123456')).toBe(false)
    expect(apakahFormatVoucherAcak('')).toBe(false)
    expect(apakahFormatVoucherAcak('   ')).toBe(false)
  })

  it('buatPolaGaris menghasilkan representasi bit biner valid dan deterministik', () => {
    const pola1 = buatPolaGaris('RB-7X9K-2M4P')
    const pola2 = buatPolaGaris('RB-7X9K-2M4P')

    expect(pola1).toBe(pola2)
    expect(pola1.length).toBeGreaterThan(50)
    expect(pola1.startsWith('11010010000')).toBe(true)
    expect(pola1.endsWith('1100011101011')).toBe(true)
    expect(/^[01]+$/.test(pola1)).toBe(true)
  })
})
