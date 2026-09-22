// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarPelayan } from './LayarPelayan'
import { PenyediaBahasa } from '../../bahasa'

describe('LayarPelayan POS Mobile (T3-11)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender antarmuka pelayan HP dengan nama pelayan dan input meja', () => {
    render(
      <PenyediaBahasa>
        <LayarPelayan namaPelayan="Pelayan Rian" nomorMejaAwal="Meja 05" />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Pelayan Rian')).toBeDefined()
    expect(screen.getByDisplayValue('Meja 05')).toBeDefined()
    expect(screen.getByText('Nasi Goreng Spesial Barokah')).toBeDefined()
  })

  it('dapat menambahkan item menu ke keranjang dan mengubah kuantitas', async () => {
    render(
      <PenyediaBahasa>
        <LayarPelayan />
      </PenyediaBahasa>,
    )

    // Klik menu Es Teh Manis Melati
    fireEvent.click(screen.getByText('Es Teh Manis Melati'))

    // Keranjang muncul
    expect(screen.getByText(/Pesanan \(1 item\)/i)).toBeDefined()

    // Tambah kuantitas dengan tombol +
    const tombolPlus = screen.getByRole('button', { name: '+' })
    fireEvent.click(tombolPlus)

    expect(screen.getByText(/Pesanan \(2 item\)/i)).toBeDefined()
  })

  it('mengirim pesanan ke dapur saat tombol kirim ditekan', async () => {
    const onKirimMock = vi.fn().mockResolvedValue(true)

    render(
      <PenyediaBahasa>
        <LayarPelayan onKirimPesanan={onKirimMock} />
      </PenyediaBahasa>,
    )

    // Tambah menu
    fireEvent.click(screen.getByText('Nasi Goreng Spesial Barokah'))

    // Klik tombol Kirim ke Dapur
    const tombolKirim = screen.getByRole('button', { name: /Kirim ke Dapur/i })
    fireEvent.click(tombolKirim)

    await waitFor(() => {
      expect(onKirimMock).toHaveBeenCalled()
      expect(screen.getByText(/Pesanan berhasil dikirim ke dapur!/i)).toBeDefined()
    })
  })
})
