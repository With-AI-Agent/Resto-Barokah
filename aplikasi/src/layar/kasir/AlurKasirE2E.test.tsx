// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import { PenyediaBahasa } from '../../bahasa'

describe('Uji Alur Kasir Ujung-ke-Ujung (T3-14)', () => {
  afterEach(() => {
    cleanup()
  })

  it('menjalankan skenario lengkap: pilih menu -> catatan -> kirim dapur -> bayar lunas', async () => {
    const onSimpanPesananMock = vi.fn().mockResolvedValue({
      sukses: true,
      pesananId: 'ord-e2e-001',
    })
    const onKirimKeDapurMock = vi.fn().mockResolvedValue({
      sukses: true,
    })
    // T5-01: uang lewat `onBayar` (RPC `bayar_pesanan`), balasannya angka peladen.
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
          cabangId="cab-01"
          namaCabang="Cabang Barokah Utama"
          onSimpanPesanan={onSimpanPesananMock}
          onKirimKeDapur={onKirimKeDapurMock}
          metodeBayar={[
            { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuhReferensi: false, urutan: 1 },
          ]}
          onBayar={onBayarMock}
        />
      </PenyediaBahasa>,
    )

    // 1. Verifikasi header kasir tampil
    expect(screen.getByText(/Cabang Barokah Utama/i)).toBeDefined()

    // 2. Tambahkan Tahu Tempe Goreng Lengkuas (Rp12.000)
    fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))

    // 3. Verifikasi item masuk keranjang
    await waitFor(() => {
      expect(screen.getAllByText('Tahu Tempe Goreng Lengkuas').length).toBeGreaterThan(1)
    })

    // 4. Tambahkan catatan khusus per item
    const tombolCatatan = screen.getByRole('button', { name: /\+ Tambah Catatan/i })
    fireEvent.click(tombolCatatan)

    const inputCatatan = screen.getByPlaceholderText(/Es dipisah/i)
    fireEvent.change(inputCatatan, { target: { value: 'Goreng garing pedas' } })

    const tombolSimpanCatatan = screen.getByRole('button', { name: /Simpan Catatan/i })
    fireEvent.click(tombolSimpanCatatan)

    // Catatan tampil
    expect(screen.getByText(/Goreng garing pedas/i)).toBeDefined()

    // 5. Kirim pesanan ke dapur
    const tombolKirimDapur = screen.getByRole('button', { name: /Kirim ke Dapur/i })
    fireEvent.click(tombolKirimDapur)

    await waitFor(() => {
      expect(onSimpanPesananMock).toHaveBeenCalled()
      expect(onKirimKeDapurMock).toHaveBeenCalledWith('ord-e2e-001')
    })

    // 6. Buka modal pembayaran
    const tombolBayar = screen.getByRole('button', { name: /Bayar Pesanan/i })
    fireEvent.click(tombolBayar)

    expect(screen.getByText('Pembayaran Transaksi Kasir')).toBeDefined()

    // 7. Eksekusi bayar tunai: uang diterima → tinjau → catat
    fireEvent.click(screen.getByText('Rp50.000'))
    fireEvent.click(screen.getByText('Tinjau pembayaran'))
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))

    await waitFor(() => {
      expect(onBayarMock).toHaveBeenCalled()
    })
    // Uang yang dicatat = total tagihan menurut kasir, bukan uang yang diterima.
    expect(onBayarMock.mock.calls[0][0]).toMatchObject({
      metodeId: 'm-tunai',
      jumlah: 13800,
      diterima: 50000,
    })
  })
})
