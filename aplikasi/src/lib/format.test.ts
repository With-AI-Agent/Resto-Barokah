import { describe, expect, it } from 'vitest'
import { rupiah, jamLokal, tanggalLokal } from './format'

describe('rupiah', () => {
  it('memberi pemisah ribuan', () => {
    expect(rupiah(27500)).toBe('Rp27.500')
    expect(rupiah(1000000)).toBe('Rp1.000.000')
  })

  it('membulatkan desimal ke rupiah utuh', () => {
    expect(rupiah(1000.4)).toBe('Rp1.000')
    expect(rupiah(1000.5)).toBe('Rp1.001')
  })

  it('mendukung nol dan nilai negatif (koreksi)', () => {
    expect(rupiah(0)).toBe('Rp0')
    expect(rupiah(-2500)).toBe('-Rp2.500')
  })

  it('menolak nilai bukan angka', () => {
    expect(() => rupiah(Number.NaN)).toThrow()
    expect(() => rupiah(Number.POSITIVE_INFINITY)).toThrow()
  })
})

describe('jamLokal', () => {
  it('memakai dua angka', () => {
    expect(jamLokal(new Date(2026, 8, 16, 9, 5))).toBe('09:05')
    expect(jamLokal(new Date(2026, 8, 16, 14, 30))).toBe('14:30')
  })
})

describe('tanggalLokal', () => {
  it('menulis bulan singkat bahasa Indonesia', () => {
    expect(tanggalLokal(new Date(2026, 8, 16, 10, 0))).toBe('16 Sep 2026')
    expect(tanggalLokal(new Date(2026, 0, 1, 0, 0))).toBe('1 Jan 2026')
  })
})
