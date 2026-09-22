// @vitest-environment jsdom
import { act, renderHook } from '@testing-library/react'
import { beforeEach, describe, expect, it } from 'vitest'
import type { PenggunaSesi } from '../lib/auth'
import { simpanSesiLokal } from '../lib/auth'
import { useSesi } from './useSesi'

describe('useSesi hook (T2-01)', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
  })

  it('menginisialisasi keadaan kosong saat belum ada sesi', () => {
    const { result } = renderHook(() => useSesi())
    expect(result.current.sedangMasuk).toBe(false)
    expect(result.current.sesi).toBeNull()
    expect(result.current.peran).toBeNull()
  })

  it('membaca sesi tersimpan saat dipasang', () => {
    const mockSesi: PenggunaSesi = {
      id: 'usr-001',
      nama: 'Siti Kasir',
      email: 'siti@resto.test',
      peran: 'kasir',
      penyewaId: 'resto-01',
      cabangIds: ['cab-1'],
      cabangAktifId: 'cab-1',
    }
    simpanSesiLokal(mockSesi)

    const { result } = renderHook(() => useSesi())
    expect(result.current.sedangMasuk).toBe(true)
    expect(result.current.sesi?.nama).toBe('Siti Kasir')
    expect(result.current.peran).toBe('kasir')
  })

  it('melakukan proses masuk dan memperbarui state sesi', async () => {
    const { result } = renderHook(() => useSesi())

    await act(async () => {
      const res = await result.current.masuk('kasir@resto.test', '123456')
      expect(res.berhasil).toBe(true)
    })

    expect(result.current.sedangMasuk).toBe(true)
    expect(result.current.peran).toBe('kasir')
  })

  it('melakukan proses keluar dan mengosongkan state sesi', async () => {
    const mockSesi: PenggunaSesi = {
      id: 'usr-001',
      nama: 'Siti Kasir',
      email: 'siti@resto.test',
      peran: 'kasir',
      penyewaId: 'resto-01',
      cabangIds: ['cab-1'],
      cabangAktifId: 'cab-1',
    }
    simpanSesiLokal(mockSesi)

    const { result } = renderHook(() => useSesi())
    expect(result.current.sedangMasuk).toBe(true)

    await act(async () => {
      await result.current.keluar()
    })

    expect(result.current.sedangMasuk).toBe(false)
    expect(result.current.sesi).toBeNull()
    expect(result.current.peran).toBeNull()
  })
})
