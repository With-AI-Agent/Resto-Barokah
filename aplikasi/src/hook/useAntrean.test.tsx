/**
 * useAntrean.test.tsx — Pengujian hook useAntrean (T10-01).
 */
// @vitest-environment jsdom
import { describe, expect, it, beforeEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useAntrean } from './useAntrean'
import { kosongkanSemuaAntrean } from '../lib/antrean-offline'

describe('useAntrean (T10-01 / ART-8)', () => {
  beforeEach(async () => {
    await kosongkanSemuaAntrean()
    vi.restoreAllMocks()
  })

  it('menyediakan status awal yang benar saat daring dan kosong', async () => {
    const { result } = renderHook(() => useAntrean())

    // Tunggu efek awal selesai
    await act(async () => {
      await result.current.muatUlang()
    })

    expect(result.current.apakahDaring).toBe(true)
    expect(result.current.jumlahMenunggu).toBe(0)
    expect(result.current.pesanStatus).toContain('semua pesanan terkirim')
  })

  it('menampilkan status "menunggu dikirim 2" saat ada 2 pesanan di antrean (DoD)', async () => {
    const { result } = renderHook(() => useAntrean())

    await act(async () => {
      await result.current.tambahAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-1',
        muatan: { total: 10000 },
      })
      await result.current.tambahAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-2',
        muatan: { total: 20000 },
      })
    })

    expect(result.current.jumlahMenunggu).toBe(2)
    // DoD T10-01: status terlihat jelas ("menunggu dikirim 2")
    expect(result.current.pesanStatus).toBe('menunggu dikirim 2')
  })

  it('merespons perubahan status jaringan (offline & online)', async () => {
    const { result } = renderHook(() => useAntrean())

    await act(async () => {
      await result.current.tambahAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-1',
        muatan: { total: 10000 },
      })
    })

    // Simulasikan jaringan terputus
    act(() => {
      window.dispatchEvent(new Event('offline'))
    })

    expect(result.current.apakahDaring).toBe(false)
    expect(result.current.pesanStatus).toBe('menunggu dikirim 1')

    // Mock sinkronkanAntrean saat kembali online
    const sinkronSpy = vi.spyOn(result.current, 'sinkronkanAntrean')

    act(() => {
      window.dispatchEvent(new Event('online'))
    })

    expect(result.current.apakahDaring).toBe(true)
    void sinkronSpy
  })

  it('bisa memproses sinkronisasi manual dengan penangan kustom', async () => {
    const { result } = renderHook(() => useAntrean())

    await act(async () => {
      await result.current.tambahAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-sync',
        muatan: { total: 50000 },
      })
    })

    expect(result.current.jumlahMenunggu).toBe(1)

    let penanganDipanggil = false
    await act(async () => {
      await result.current.sinkronkanAntrean(async (item) => {
        penanganDipanggil = true
        expect(item.kunciIdempoten).toBe('kunci-sync')
        return { sukses: true }
      })
    })

    expect(penanganDipanggil).toBe(true)
    expect(result.current.jumlahMenunggu).toBe(0)
    expect(result.current.pesanStatus).toContain('semua pesanan terkirim')
  })

  it('bisa menghapus item dari antrean', async () => {
    const { result } = renderHook(() => useAntrean())

    let idItem = ''
    await act(async () => {
      const item = await result.current.tambahAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-hapus',
        muatan: { total: 30000 },
      })
      idItem = item.id
    })

    expect(result.current.jumlahMenunggu).toBe(1)

    await act(async () => {
      await result.current.hapusAntrean(idItem)
    })

    expect(result.current.jumlahMenunggu).toBe(0)
  })
})
