// @vitest-environment jsdom
import { act, renderHook } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import type { PenggunaSesi } from '../lib/auth'
import { useCabang } from './useCabang'

describe('useCabang hook (T2-07)', () => {
  it('menginisialisasi null ketika tidak ada sesi aktif', () => {
    const { result } = renderHook(() => useCabang(null))
    expect(result.current.cabangAktifId).toBeNull()
    expect(result.current.bisaPindahCabang).toBe(false)
  })

  it('mengunci admin cabang tunggal sehingga tidak bisa pindah cabang asing', () => {
    const sesiAdmin: PenggunaSesi = {
      id: 'usr-admin',
      nama: 'Admin Cabang 1',
      email: 'admin1@resto.test',
      peran: 'admin_cabang',
      penyewaId: 'resto-1',
      cabangIds: ['cab-1'],
      cabangAktifId: 'cab-1',
    }

    const { result } = renderHook(() => useCabang(sesiAdmin))
    expect(result.current.cabangAktifId).toBe('cab-1')
    expect(result.current.bisaPindahCabang).toBe(false)

    act(() => {
      const berhasil = result.current.gantiCabang('cab-2')
      expect(berhasil).toBe(false)
    })

    expect(result.current.cabangAktifId).toBe('cab-1')
  })

  it('mengizinkan owner pusat berpindah cabang bebas', () => {
    const sesiOwner: PenggunaSesi = {
      id: 'usr-owner',
      nama: 'Bu Oasis',
      email: 'owner@resto.test',
      peran: 'owner_pusat',
      penyewaId: 'resto-1',
      cabangIds: ['cab-1', 'cab-2', 'cab-3'],
      cabangAktifId: 'cab-1',
    }

    const { result } = renderHook(() => useCabang(sesiOwner))
    expect(result.current.bisaPindahCabang).toBe(true)

    act(() => {
      const berhasil = result.current.gantiCabang('cab-2')
      expect(berhasil).toBe(true)
    })

    expect(result.current.cabangAktifId).toBe('cab-2')
  })
})
