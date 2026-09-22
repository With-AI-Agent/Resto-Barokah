import { describe, it, expect } from 'vitest'
import { REGISTRI_AKSI, type EntriAksi } from './aksi'
import { DAFTAR_LAYAR } from './layar'

describe('Registri Aksi Aplikasi (aksi.ts)', () => {
  it('memuat registri aksi dengan pemetaan layar yang valid', () => {
    const daftarLayarValid = Object.keys(DAFTAR_LAYAR)
    const entriAksi = Object.values(REGISTRI_AKSI) as EntriAksi[]

    expect(entriAksi.length).toBeGreaterThan(20)

    for (const aksi of entriAksi) {
      expect(aksi.id).toContain('.')
      expect(daftarLayarValid).toContain(aksi.layar)
      expect(aksi.label.length).toBeGreaterThan(0)
      expect(aksi.peran.length).toBeGreaterThan(0)
      expect(['baca', 'tulis', 'navigasi']).toContain(aksi.jenis)
    }
  })

  it('seluruh aksi jenis tulis wajib memiliki daftar uji pembuktian', () => {
    const entriAksi = Object.values(REGISTRI_AKSI) as EntriAksi[]
    const aksiTulis = entriAksi.filter((a) => a.jenis === 'tulis')

    expect(aksiTulis.length).toBeGreaterThan(10)
    for (const aksi of aksiTulis) {
      expect(aksi.uji.length).toBeGreaterThan(0)
    }
  })

  it('aksi yang menyangkut pembatalan atau perubahan penting wajib memiliki konfirmasi', () => {
    const aksiBatal = REGISTRI_AKSI['kasir.batal_item']
    expect(aksiBatal.konfirmasi).not.toBeNull()
    expect(aksiBatal.audit).toBe(true)

    const aksiShift = REGISTRI_AKSI['kasir.tutup_shift']
    expect(aksiShift.konfirmasi).not.toBeNull()
    expect(aksiShift.audit).toBe(true)
  })
})
