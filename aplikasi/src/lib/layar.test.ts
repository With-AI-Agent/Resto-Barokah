import { describe, it, expect } from 'vitest'
import { DAFTAR_LAYAR, type KontrakLayar } from './layar'

describe('Registri dan Kontrak Layar (layar.ts)', () => {
  it('memuat 8 layar G1 yang sah dan terdaftar', () => {
    const keys = Object.keys(DAFTAR_LAYAR)
    expect(keys.length).toBe(8)
    expect(keys).toContain('masuk')
    expect(keys).toContain('kasir')
    expect(keys).toContain('dapur')
    expect(keys).toContain('laporan')
    expect(keys).toContain('pengaturan')
    expect(keys).toContain('voucher')
    expect(keys).toContain('pelanggan-publik')
    expect(keys).toContain('contoh')
  })

  it('setiap layar memiliki atribut kontrak yang lengkap dan valid', () => {
    for (const [id, layar] of Object.entries(DAFTAR_LAYAR) as [string, KontrakLayar][]) {
      expect(layar.id).toBe(id)
      expect(layar.judul.length).toBeGreaterThan(0)
      expect(layar.tujuan.length).toBeGreaterThan(0)
      expect(layar.rute.startsWith('/')).toBe(true)
      expect(layar.peran.length).toBeGreaterThan(0)
      expect(layar.masukDari.length).toBeGreaterThan(0)
      expect(layar.komponen.startsWith('src/layar/')).toBe(true)
      expect(layar.berkasUji.endsWith('.test.tsx')).toBe(true)
      expect(layar.naskahJalan.startsWith('W-')).toBe(true)
      expect(layar.aturanTampilan.length).toBeGreaterThan(0)
    }
  })

  it('setiap layar mendefinisikan 7 keadaan wajib', () => {
    for (const [, layar] of Object.entries(DAFTAR_LAYAR) as [string, KontrakLayar][]) {
      const k = layar.keadaan
      expect(k.kosong.length).toBeGreaterThan(0)
      expect(k.memuat.length).toBeGreaterThan(0)
      expect(k.gagal.length).toBeGreaterThan(0)
      expect(k.menunggu.length).toBeGreaterThan(0)
      expect(k.tidakPunyaAkses.length).toBeGreaterThan(0)
      expect(k.dataSebagian.length).toBeGreaterThan(0)
      expect(k.berhasil.length).toBeGreaterThan(0)
    }
  })
})
