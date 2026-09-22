import { describe, expect, it } from 'vitest'
import { formatPesanError, KAMUS_PESAN } from './pesan'

describe('formatPesanError & KAMUS_PESAN (T2-08)', () => {
  it('menerjemahkan kode FORBIDDEN menjadi AK-403 dengan judul dan tindakan jelas', () => {
    const hasil = formatPesanError('FORBIDDEN')
    expect(hasil.kode).toBe('AK-403')
    expect(hasil.judul).toBe('Akses Tidak Diizinkan')
    expect(hasil.tindakan).toContain('Owner atau Admin')
  })

  it('menerjemahkan PIN_SALAH dan PIN_TERKUNCI secara tepat', () => {
    const salah = formatPesanError('PIN_SALAH')
    expect(salah.kode).toBe('PIN-401')

    const terkunci = formatPesanError('PIN_TERKUNCI')
    expect(terkunci.kode).toBe('PIN-429')
    expect(terkunci.pesan).toContain('Terlalu banyak')
  })

  it('menerjemahkan error dari instance Error yang memuat kata kunci', () => {
    const err = new Error('Operasi ditolak: PERANGKAT_BELUM_TERDAFTAR di cabang 1')
    const hasil = formatPesanError(err)
    expect(hasil.kode).toBe('PRG-404')
    expect(hasil.judul).toBe('Perangkat Belum Terdaftar')
  })

  it('menerjemahkan objek response RPC dengan field kode', () => {
    const res = { berhasil: false, kode: 'SESI_HABIS', pesan: 'Sesi berakhir' }
    const hasil = formatPesanError(res)
    expect(hasil.kode).toBe('SESI-401')
    expect(hasil.judul).toBe('Sesi Selesai')
  })

  it('menggunakan fallback ketika pesan tidak dikenal atau null', () => {
    const hasilNull = formatPesanError(null)
    expect(hasilNull.kode).toBe('AK-601')
    expect(hasilNull.judul).toBe('Terjadi Kendala')

    const hasilCustom = formatPesanError(null, 'CUSTOM-001')
    expect(hasilCustom.kode).toBe('CUSTOM-001')
  })

  it('memastikan setiap entri KAMUS_PESAN memiliki atribut lengkap', () => {
    for (const item of Object.values(KAMUS_PESAN)) {
      expect(item.kode).toBeTruthy()
      expect(item.judul).toBeTruthy()
      expect(item.pesan).toBeTruthy()
      expect(item.tindakan).toBeTruthy()
    }
  })
})
