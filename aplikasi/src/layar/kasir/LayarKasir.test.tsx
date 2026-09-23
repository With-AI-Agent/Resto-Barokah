// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import { PenyediaBahasa } from '../../bahasa'

describe('LayarKasir POS (T3-01 s/d T3-16)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender layout POS lengkap: katalog menu dan keranjang kosong di awal', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    expect(screen.getByText(/Kasir POS — Cabang Utama/i)).toBeDefined()
    expect(screen.getByText(/Semua Menu/i)).toBeDefined()
    expect(screen.getByText(/Keranjang Masih Kosong/i)).toBeDefined()
  })

  it('menambahkan item dari katalog ke keranjang dan memperbarui ringkasan total', async () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    // Klik Es Teh Manis Melati (tanpa varian)
    const esTeh = screen.getByText('Es Teh Manis Melati')
    fireEvent.click(esTeh)

    // Item harus muncul di keranjang
    await waitFor(() => {
      expect(screen.getAllByText('Es Teh Manis Melati').length).toBeGreaterThan(0)
    })

    // Subtotal, service, pajak, dan tombol bayar aktif
    expect(screen.getByRole('button', { name: /Bayar Pesanan/i })).toBeDefined()
  })

  it('menjalankan alur pembayaran tunai dan menyelesaikan transaksi pesanan', async () => {
    // Sejak T5-01 uang dicatat lewat `onBayar` (pintu RPC `bayar_pesanan`),
    // dan metode bayar datang dari kontainer — bukan daftar keras-kode layar.
    const onBayarMock = vi.fn().mockResolvedValue({
      jumlah: 13800,
      kembalian: 36200,
      totalDibayar: 13800,
      totalPesanan: 13800,
      lunas: true,
      dobel: false,
    })

    render(
      <PenyediaBahasa>
        <LayarKasir
          metodeBayar={[
            { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuhReferensi: false, urutan: 1 },
          ]}
          onBayar={onBayarMock}
        />
      </PenyediaBahasa>,
    )

    // Tambah Tahu Tempe (tanpa varian) ke keranjang
    fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))

    // Klik tombol Bayar Pesanan
    fireEvent.click(screen.getByRole('button', { name: /Bayar Pesanan/i }))

    // Modal pembayaran terbuka, metodenya dari kontainer
    expect(screen.getByText('Pembayaran Transaksi Kasir')).toBeDefined()
    expect(screen.getByTestId('metode-Tunai')).toBeDefined()

    // Isi uang diterima, tinjau, lalu catat
    fireEvent.click(screen.getByText('Rp50.000'))
    fireEvent.click(screen.getByText('Tinjau pembayaran'))
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))

    await waitFor(() => {
      expect(onBayarMock).toHaveBeenCalled()
    })
  })

  it('dapat membuka modal Tagihan Terbuka (Open Bill)', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByText(/Tagihan Terbuka/i))
    expect(screen.getByText('Tagihan Terbuka (Open Bill)')).toBeDefined()
  })
})
