/**
 * Uji Opname.tsx (T4-07): jumlah nyata → selisih tampil terbuka; selisih nol
 * tidak dicatat (mengikuti penjaga buku besar).
 */
// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Opname } from './Opname'
import type { BarisBahan } from './Stok'

afterEach(() => {
  cleanup()
})

const BAHAN: BarisBahan[] = [
  { id: 'b1', nama: 'Minyak Uji-37', satuan: 'liter', jumlah: 10, minimum: 1, dipantau: true },
]

describe('Opname (T4-07)', () => {
  it('selisih tampil terbuka saat jumlah fisik diisi', () => {
    render(<Opname bahan={BAHAN} />)
    fireEvent.click(screen.getByTestId('hitung-b1'))
    fireEvent.change(screen.getByLabelText(/fisik/), { target: { value: '7' } })
    expect(screen.getByTestId('pratinjau-selisih').textContent).toContain('-3')
  })

  it('simpan opname mengirim jumlah fisik + alasan', () => {
    const onSimpan = vi.fn()
    render(<Opname bahan={BAHAN} onSimpan={onSimpan} />)
    fireEvent.click(screen.getByTestId('hitung-b1'))
    fireEvent.change(screen.getByLabelText(/fisik/), { target: { value: '7' } })
    fireEvent.change(screen.getByLabelText(/[Aa]lasan/), {
      target: { value: 'Hitung fisik gudang' },
    })
    fireEvent.click(screen.getByTestId('simpan-opname'))
    expect(onSimpan).toHaveBeenCalledWith('b1', 7, 'Hitung fisik gudang')
  })

  it('selisih nol dinonaktifkan (tidak dicatat — aturan buku besar)', () => {
    const onSimpan = vi.fn()
    render(<Opname bahan={BAHAN} onSimpan={onSimpan} />)
    fireEvent.click(screen.getByTestId('hitung-b1'))
    fireEvent.change(screen.getByLabelText(/fisik/), { target: { value: '10' } })
    fireEvent.change(screen.getByLabelText(/[Aa]lasan/), { target: { value: 'Cocok' } })
    expect((screen.getByTestId('simpan-opname') as HTMLElement).closest('button')).toHaveProperty(
      'disabled',
      true,
    )
    fireEvent.click(screen.getByTestId('simpan-opname'))
    expect(onSimpan).not.toHaveBeenCalled()
  })

  it('keadaan gagal tampil tegas (bukan daftar kosong yang menipu) + bisa dicoba lagi', () => {
    const onCoba = vi.fn()
    render(<Opname bahan={[]} keadaan="gagal" onCoba={onCoba} />)
    expect(screen.getByText('Gagal memuat daftar bahan')).toBeTruthy()
    expect(screen.queryByText('Belum ada bahan untuk diopname.')).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: /coba lagi/i }))
    expect(onCoba).toHaveBeenCalled()
  })

  it('keadaan kosong ramah + kembali ke stok', () => {
    const onKembali = vi.fn()
    render(<Opname bahan={[]} onKembali={onKembali} />)
    expect(screen.getByText('Belum ada bahan untuk diopname.')).toBeTruthy()
    fireEvent.click(screen.getByTestId('kembali-stok'))
    expect(onKembali).toHaveBeenCalled()
  })
})
