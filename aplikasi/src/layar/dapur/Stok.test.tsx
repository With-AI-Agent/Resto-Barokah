/**
 * Uji Stok.tsx (T4-06): daftar bahan, penyesuaian delta dengan alasan wajib,
 * riwayat perubahan tampil.
 */
// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Stok, type BarisBahan, type BarisPergerakan } from './Stok'

afterEach(() => {
  cleanup()
})

const BAHAN: BarisBahan[] = [
  { id: 'b1', nama: 'Beras Uji-36', satuan: 'kg', jumlah: 10, minimum: 2, dipantau: true },
  { id: 'b2', nama: 'Gula Uji-36', satuan: 'kg', jumlah: 1, minimum: 3, dipantau: true },
]

const RIWAYAT: BarisPergerakan[] = [
  {
    id: 'p1',
    bahanId: 'b1',
    namaBahan: 'Beras Uji-36',
    jenis: 'masuk',
    jumlah: 5,
    alasan: 'Belanja pagi',
    oleh: 'Pak Dapur',
    waktu: '2026-09-22 10:00',
  },
]

describe('Stok (T4-06)', () => {
  it('menampilkan daftar bahan + penanda di bawah minimum', () => {
    render(<Stok bahan={BAHAN} riwayat={RIWAYAT} />)
    expect(screen.getAllByText('Beras Uji-36').length).toBeGreaterThan(0)
    expect(screen.getByText('Di bawah minimum')).toBeTruthy()
  })

  it('penyesuaian memakai delta dengan alasan wajib', () => {
    const onSimpan = vi.fn()
    render(<Stok bahan={BAHAN} riwayat={RIWAYAT} onSimpan={onSimpan} />)
    fireEvent.click(screen.getByTestId('tambah-b1'))
    fireEvent.click(screen.getByTestId('simpan-perubahan'))
    expect(onSimpan).not.toHaveBeenCalled()
    fireEvent.change(screen.getByLabelText(/Jumlah/), { target: { value: '5' } })
    fireEvent.change(screen.getByLabelText(/Alasan/), { target: { value: 'Belanja sore' } })
    fireEvent.click(screen.getByTestId('simpan-perubahan'))
    expect(onSimpan).toHaveBeenCalledWith('b1', 5, 'Belanja sore')
  })

  it('pengurangan mengirim delta negatif', () => {
    const onSimpan = vi.fn()
    render(<Stok bahan={BAHAN} riwayat={RIWAYAT} onSimpan={onSimpan} />)
    fireEvent.click(screen.getByTestId('kurang-b1'))
    fireEvent.change(screen.getByLabelText(/Jumlah/), { target: { value: '3' } })
    fireEvent.change(screen.getByLabelText(/Alasan/), { target: { value: 'Pemakaian dapur' } })
    fireEvent.click(screen.getByTestId('simpan-perubahan'))
    expect(onSimpan).toHaveBeenCalledWith('b1', -3, 'Pemakaian dapur')
  })

  it('riwayat perubahan tampil (siapa, kapan, berapa, alasannya)', () => {
    render(<Stok bahan={BAHAN} riwayat={RIWAYAT} />)
    expect(screen.getByText('Belanja pagi')).toBeTruthy()
    expect(screen.getByText('Pak Dapur')).toBeTruthy()
  })

  it('keadaan kosong ramah + jalan pintas ke opname', () => {
    const onKeOpname = vi.fn()
    render(<Stok bahan={[]} riwayat={[]} onKeOpname={onKeOpname} />)
    expect(screen.getByText('Belum ada bahan yang dicatat.')).toBeTruthy()
    fireEvent.click(screen.getByTestId('ke-opname'))
    expect(onKeOpname).toHaveBeenCalled()
  })
})
