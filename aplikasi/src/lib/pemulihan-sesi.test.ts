/**
 * Uji pemulihan-sesi.ts (T10-09).
 */
import { describe, expect, it } from 'vitest'
import { apakahShiftMasihBerjalan } from './pemulihan-sesi'

describe('pemulihan-sesi (T10-09)', () => {
  it('mengenali shift aktif pada hari yang sama sebelum jam tutup wajar', () => {
    const sekarang = new Date('2026-09-27T14:30:00Z')
    const shift = {
      id: 'shift-01',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: '2026-09-27T08:00:00Z',
    }

    const masihBerjalan = apakahShiftMasihBerjalan(shift, '22:00', sekarang)
    expect(masihBerjalan).toBe(true)
  })

  it('menolak shift dari hari kemarin (tidak boleh dilanjutkan, wajib buka shift baru)', () => {
    const sekarang = new Date('2026-09-27T08:30:00Z')
    const shiftKemarin = {
      id: 'shift-kemarin',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: '2026-09-26T08:00:00Z',
    }

    const masihBerjalan = apakahShiftMasihBerjalan(shiftKemarin, '22:00', sekarang)
    expect(masihBerjalan).toBe(false)
  })

  it('menolak shift yang sudah melewati toleransi jam tutup kedai (+2 jam)', () => {
    // Jam tutup 22:00 + toleransi 2 jam = 00:00 (tengah malam)
    const waktuTengahMalam = new Date('2026-09-27T23:59:00')
    const waktuLewatTengahMalam = new Date('2026-09-28T01:00:00')

    const shift = {
      id: 'shift-02',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: '2026-09-27T10:00:00',
    }

    expect(apakahShiftMasihBerjalan(shift, '22:00', waktuTengahMalam)).toBe(true)
    expect(apakahShiftMasihBerjalan(shift, '22:00', waktuLewatTengahMalam)).toBe(false)
  })

  it('mengembalikan false bila data shift kosong atau tanggal tidak sah', () => {
    expect(apakahShiftMasihBerjalan(null)).toBe(false)
    expect(apakahShiftMasihBerjalan(undefined)).toBe(false)
    expect(
      apakahShiftMasihBerjalan({
        id: '',
        cabangId: 'cab-01',
        modalAwal: 0,
        dibukaPada: 'invalid-date',
      }),
    ).toBe(false)
  })
})
