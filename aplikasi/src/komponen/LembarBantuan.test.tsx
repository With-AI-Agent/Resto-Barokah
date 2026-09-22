// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { LembarBantuan } from './LembarBantuan'
import { PenyediaBahasa } from '../bahasa'

describe('Komponen Lembar Bantuan Kontekstual (T1-42)', () => {
  afterEach(() => {
    cleanup()
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('merender tombol tanda tanya dan membuka panduan saat diklik', () => {
    render(
      <PenyediaBahasa>
        <LembarBantuan idLayar="kasir" />
      </PenyediaBahasa>,
    )

    const tombol = screen.getByTestId('tombol-bantuan-kasir')
    expect(tombol).toBeTruthy()
    expect(tombol.textContent).toContain('?')

    // Buka modal
    fireEvent.click(tombol)

    const dialog = screen.getByTestId('dialog-bantuan-kasir')
    expect(dialog).toBeTruthy()
    expect(screen.getByText('Panduan Transaksi Kasir')).toBeTruthy()
    expect(screen.getByText(/Mencatat pesanan menu pelanggan/i)).toBeTruthy()
    expect(screen.getByText(/Bila Terjadi Kendala \/ Macet:/i)).toBeTruthy()
  })

  it('dapat menutup lembar bantuan dan menyimpan preferensi', () => {
    render(
      <PenyediaBahasa>
        <LembarBantuan idLayar="dapur" />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByTestId('tombol-bantuan-dapur'))
    expect(screen.getByTestId('dialog-bantuan-dapur')).toBeTruthy()

    // Centang jangan tampil lagi
    const checkbox = screen.getByLabelText(/jangan tampilkan panduan ini secara otomatis/i)
    fireEvent.click(checkbox)

    // Tutup
    const tombolTutup = screen.getByRole('button', { name: 'Tutup Bantuan' })
    fireEvent.click(tombolTutup)

    expect(screen.queryByTestId('dialog-bantuan-dapur')).toBeNull()
    expect(localStorage.getItem('resto_barokah_bantuan_dilihat_dapur')).toBe('true')
  })

  it('memanggil window.print saat tombol cetak ditekan', () => {
    const cetakSpy = vi.spyOn(window, 'print').mockImplementation(() => {})

    render(
      <PenyediaBahasa>
        <LembarBantuan idLayar="laporan" />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByTestId('tombol-bantuan-laporan'))
    fireEvent.click(screen.getByRole('button', { name: /cetak lembar panduan/i }))

    expect(cetakSpy).toHaveBeenCalled()
  })
})
