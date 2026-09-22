// @vitest-environment jsdom
import { act, cleanup, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { useJam } from './useJam'

/**
 * Uji jam berdenyut (T0-10).
 * Dipakai layar dapur & header; penting supaya jam tidak "beku" tanpa ketahuan.
 */

function PenunjukJam() {
  const sekarang = useJam(1000)
  return <span data-testid="jam">{sekarang.getSeconds()}</span>
}

afterEach(() => {
  cleanup()
  vi.useRealTimers()
})

describe('useJam', () => {
  it('memberi jam sekarang sejak render pertama', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 8, 16, 10, 0, 5))
    render(<PenunjukJam />)
    expect(screen.getByTestId('jam').textContent).toBe('5')
  })

  it('ikut berjalan setiap detik', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 8, 16, 10, 0, 5))
    render(<PenunjukJam />)
    act(() => {
      vi.advanceTimersByTime(3000)
    })
    expect(screen.getByTestId('jam').textContent).toBe('8')
  })
})
