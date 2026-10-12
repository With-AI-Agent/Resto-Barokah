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

  it('menerjemahkan PERANGKAT_BELUM_DISETUJUI (PMB1-F-082) dengan ajakan minta persetujuan', () => {
    const hasil = formatPesanError('PERANGKAT_BELUM_DISETUJUI')
    expect(hasil.kode).toBe('PRG-405')
    expect(hasil.judul).toBe('Perangkat Belum Disetujui')
    expect(hasil.tindakan).toContain('menyetujui')
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

  it('menerjemahkan KREDENSIAL_TIDAK_VALID dan PERANGKAT_WAJIB dengan tepat', () => {
    const kredensial = formatPesanError('KREDENSIAL_TIDAK_VALID')
    expect(kredensial.kode).toBe('PIN-401')
    expect(kredensial.judul).toBe('Kredensial Tidak Sesuai')

    const prgWajib = formatPesanError({ kode: 'PERANGKAT_WAJIB', pesan: 'Wajib perangkat' })
    expect(prgWajib.kode).toBe('PRG-400')
    expect(prgWajib.judul).toBe('Perangkat Belum Diinisialisasi')
  })

  it('menggunakan pesan eksplisit dari server bila kode tidak ada di kamus', () => {
    const resTeknis = { code: '42703', message: 'column "created_at" does not exist' }
    const hasil = formatPesanError(resTeknis)
    expect(hasil.judul).toBe('Kendala Sistem')
    expect(hasil.pesan).toBe('column "created_at" does not exist')
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
