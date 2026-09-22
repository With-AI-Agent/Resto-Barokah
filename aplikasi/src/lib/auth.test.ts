// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest'
import type { PenggunaSesi } from './auth'
import {
  ambilPerangkatLokal,
  bacaSesiLokal,
  hapusSesiLokal,
  masukDenganPin,
  simpanPerangkatLokal,
  simpanSesiLokal,
} from './auth'

describe('Auth & Manajemen Sesi (T2-01, T2-02)', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
  })

  it('menyimpan dan membaca identitas perangkat lokal dengan benar', () => {
    simpanPerangkatLokal('dev-123', 'Tablet Kasir 1')
    const dev = ambilPerangkatLokal()
    expect(dev.id).toBe('dev-123')
    expect(dev.nama).toBe('Tablet Kasir 1')
  })

  it('membangkitkan id perangkat baru jika belum ada di penyimpanan', () => {
    const dev = ambilPerangkatLokal()
    expect(dev.id).toBeTruthy()
    expect(dev.nama).toBe('Perangkat Browser')
  })

  it('menyimpan dan membaca sesi lokal ke sessionStorage', () => {
    const mockSesi: PenggunaSesi = {
      id: 'usr-1',
      nama: 'Budi Kasir',
      email: 'budi@resto.test',
      peran: 'kasir',
      penyewaId: 'resto-1',
      cabangIds: ['cab-1'],
      cabangAktifId: 'cab-1',
      perangkatId: 'dev-123',
    }
    simpanSesiLokal(mockSesi)
    expect(bacaSesiLokal()).toEqual(mockSesi)

    hapusSesiLokal()
    expect(bacaSesiLokal()).toBeNull()
  })

  it('menolak format email yang tidak valid saat masuk dengan PIN', async () => {
    const hasil = await masukDenganPin('invalid-email', '123456')
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('EMAIL_TIDAK_VALID')
  })

  it('menolak PIN yang bukan 6 digit angka', async () => {
    const hasil1 = await masukDenganPin('kasir@resto.test', '12345')
    expect(hasil1.berhasil).toBe(false)
    expect(hasil1.kode).toBe('PIN_TIDAK_VALID')

    const hasil2 = await masukDenganPin('kasir@resto.test', '12345a')
    expect(hasil2.berhasil).toBe(false)
    expect(hasil2.kode).toBe('PIN_TIDAK_VALID')
  })

  it('berhasil masuk dengan format valid dalam mode simulasi / offline', async () => {
    const hasil = await masukDenganPin('kasir@resto.test', '123456')
    expect(hasil.berhasil).toBe(true)
    expect(hasil.sesi?.peran).toBe('kasir')
    expect(hasil.sesi?.email).toBe('kasir@resto.test')
    expect(bacaSesiLokal()).toEqual(hasil.sesi)
  })
})
