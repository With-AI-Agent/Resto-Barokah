// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useKunciOtomatis, BATAS_MENGANGGUR_MS } from './useKunciOtomatis'

describe('useKunciOtomatis (T2-09 & T2-16)', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('memiliki batas waktu menganggur yang sesuai per peran', () => {
    expect(BATAS_MENGANGGUR_MS.kasir).toBe(15 * 60 * 1000)
    expect(BATAS_MENGANGGUR_MS.pelayan).toBe(15 * 60 * 1000)
    expect(BATAS_MENGANGGUR_MS.dapur).toBe(15 * 60 * 1000)
    expect(BATAS_MENGANGGUR_MS.admin_cabang).toBe(30 * 60 * 1000)
    expect(BATAS_MENGANGGUR_MS.owner_pusat).toBe(60 * 60 * 1000)
  })

  it('bisa mengunci langsung saat fungsi kunci() dipanggil (Kunci Sekarang)', () => {
    const onKunci = vi.fn()
    const { result } = renderHook(() => useKunciOtomatis({ onKunci }))

    expect(result.current.terkunci).toBe(false)

    act(() => {
      result.current.kunci()
    })

    expect(result.current.terkunci).toBe(true)
    expect(onKunci).toHaveBeenCalledTimes(1)

    act(() => {
      result.current.bukaKunci()
    })

    expect(result.current.terkunci).toBe(false)
  })

  it('memberikan peringatan 60 detik sebelum batas waktu tercapai', () => {
    const onPeringatan = vi.fn()
    const onKunci = vi.fn()
    const { result } = renderHook(() =>
      useKunciOtomatis({
        peran: 'kasir',
        detikTenggangPeringatan: 60,
        onPeringatan,
        onKunci,
      })
    )

    // Majukan waktu ke 13 menit 50 detik (830 detik) -> belum peringatan
    act(() => {
      vi.advanceTimersByTime(830 * 1000)
    })
    expect(result.current.dalamPeringatan).toBe(false)

    // Majukan ke 14 menit 10 detik (850 detik) -> masuk zona peringatan
    act(() => {
      vi.advanceTimersByTime(20 * 1000)
    })
    expect(result.current.dalamPeringatan).toBe(true)
    expect(result.current.sisaDetik).toBeLessThanOrEqual(60)
    expect(onPeringatan).toHaveBeenCalled()

    // Majukan sampai 15 menit penuh -> terkunci
    act(() => {
      vi.advanceTimersByTime(60 * 1000)
    })
    expect(result.current.terkunci).toBe(true)
    expect(onKunci).toHaveBeenCalled()
  })

  it('mereset timer saat ada aktivitas interaksi', () => {
    const { result } = renderHook(() => useKunciOtomatis({ peran: 'kasir' }))

    // Majukan 14 menit
    act(() => {
      vi.advanceTimersByTime(14 * 60 * 1000)
    })

    // Pengguna berinteraksi
    act(() => {
      window.dispatchEvent(new Event('pointerdown'))
    })

    // Majukan lagi 2 menit (total 16 menit dari awal, tapi baru 2 menit setelah klik)
    act(() => {
      vi.advanceTimersByTime(2 * 60 * 1000)
    })

    expect(result.current.terkunci).toBe(false)
    expect(result.current.dalamPeringatan).toBe(false)
  })
})
