import { describe, it, expect } from 'vitest'
import { DAFTAR_LAYAR, type KontrakLayar } from './layar'

describe('Registri dan Kontrak Layar (layar.ts)', () => {
  // KONTRAK DIREVISI 2026-09-23 atas keputusan Lee ("semuanya dikerjakan, urutan
  // ikut agent"): delapan layar G1 di bawah TETAP wajib ada — tidak boleh hilang
  // atau berganti id. Yang dilonggarkan hanya jumlah total: layar Fase 4
  // (bar/stok/opname) kini terdaftar resmi di sini, bukan lagi hidup lewat
  // App.tsx tanpa entri registri.
  const LAYAR_G1_WAJIB = [
    'masuk',
    'kasir',
    'dapur',
    'laporan',
    'pengaturan',
    'voucher',
    'pelanggan-publik',
    'contoh',
  ] as const

  const LAYAR_FASE4 = ['bar', 'stok', 'opname'] as const
  const LAYAR_PLATFORM = ['platform_penyewa'] as const

  it('delapan layar G1 tetap terdaftar (tidak boleh hilang)', () => {
    const keys = Object.keys(DAFTAR_LAYAR)
    for (const id of LAYAR_G1_WAJIB) expect(keys).toContain(id)
  })

  it('layar Fase 4 terdaftar resmi: bar, stok, opname', () => {
    const keys = Object.keys(DAFTAR_LAYAR)
    for (const id of LAYAR_FASE4) expect(keys).toContain(id)
  })

  it('layar Platform terdaftar resmi: platform_penyewa (T9-10 / PRD M1)', () => {
    const keys = Object.keys(DAFTAR_LAYAR)
    for (const id of LAYAR_PLATFORM) expect(keys).toContain(id)
  })

  it('tidak ada layar tak dikenal yang menyelinap ke registri', () => {
    const sah: string[] = [...LAYAR_G1_WAJIB, ...LAYAR_FASE4, ...LAYAR_PLATFORM]
    for (const id of Object.keys(DAFTAR_LAYAR)) expect(sah).toContain(id)
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
