/**
 * Uji TombolHabis (T4-05): konfirmasi dua langkah + konfirmasi salah tidak menandai.
 */
// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { TombolHabis } from './TombolHabis'

afterEach(() => {
  cleanup()
})

describe('TombolHabis (T4-05)', () => {
  it('meminta konfirmasi sebelum menandai menu habis', () => {
    const onTandai = vi.fn()
    render(<TombolHabis namaMenu="Nasi Goreng" onTandai={onTandai} />)
    fireEvent.click(screen.getByTestId('tombol-habis'))
    expect(onTandai).not.toHaveBeenCalled()
    fireEvent.click(screen.getByTestId('tombol-habis-ya'))
    expect(onTandai).toHaveBeenCalledTimes(1)
  })

  it('batal membatalkan tanpa menandai apa pun', () => {
    const onTandai = vi.fn()
    render(<TombolHabis namaMenu="Es Teh" onTandai={onTandai} />)
    fireEvent.click(screen.getByTestId('tombol-habis'))
    fireEvent.click(screen.getByText('Batal'))
    expect(onTandai).not.toHaveBeenCalled()
    expect(screen.getByTestId('tombol-habis')).toBeTruthy()
  })
})
