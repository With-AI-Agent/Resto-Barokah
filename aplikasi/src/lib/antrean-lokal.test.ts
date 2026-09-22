/**
 * Uji penyimpanan antrean cadangan per perangkat (T4-10).
 */
// @vitest-environment jsdom
import { describe, expect, it, beforeEach } from 'vitest'
import {
  simpanAntreanTerakhir,
  muatAntreanTerakhir,
  hapusAntreanTerakhir,
} from './antrean-lokal'

describe('antrean-lokal (T4-10)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('menyimpan lalu memuat kembali tiket antrean', () => {
    const tiket = [{ id: 't1', nomor: 7 }, { id: 't2', nomor: 8 }]
    simpanAntreanTerakhir('dapur', tiket)
    expect(muatAntreanTerakhir<{ id: string }>('dapur')).toEqual(tiket)
  })

  it('antrean dapur dan bar disimpan terpisah', () => {
    simpanAntreanTerakhir('dapur', [{ id: 'dapur-1' }])
    simpanAntreanTerakhir('bar', [{ id: 'bar-1' }])
    expect(muatAntreanTerakhir<{ id: string }>('dapur')).toEqual([{ id: 'dapur-1' }])
    expect(muatAntreanTerakhir<{ id: string }>('bar')).toEqual([{ id: 'bar-1' }])
  })

  it('muatan kosong / JSON rusak menghasilkan null, bukan meledak', () => {
    expect(muatAntreanTerakhir('dapur')).toBeNull()
    localStorage.setItem('resto.antrean-terakhir.dapur', 'bukan-json')
    expect(muatAntreanTerakhir('dapur')).toBeNull()
    localStorage.setItem('resto.antrean-terakhir.dapur', JSON.stringify({ versi: 99 }))
    expect(muatAntreanTerakhir('dapur')).toBeNull()
  })

  it('bisa dihapus (mis. setelah daring kembali)', () => {
    simpanAntreanTerakhir('dapur', [{ id: 't1' }])
    hapusAntreanTerakhir('dapur')
    expect(muatAntreanTerakhir('dapur')).toBeNull()
  })
})
