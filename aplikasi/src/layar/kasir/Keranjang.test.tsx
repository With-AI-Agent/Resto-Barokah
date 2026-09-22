// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Keranjang, type ItemKeranjang } from './Keranjang'
import { PenyediaBahasa } from '../../bahasa'

describe('Keranjang Kasir (T3-02)', () => {
  afterEach(() => {
    cleanup()
  })

  const itemContoh: ItemKeranjang = {
    id: 'it-1',
    menuItem: {
      id: 'm-1',
      kategoriId: 'kat-1',
      nama: 'Nasi Goreng Spesial',
      harga: 28000,
      jenis: 'makanan',
      aktif: true,
    },
    qty: 2,
    subtotal: 56000,
  }

  it('merender keadaan kosong dengan ramah saat keranjang belum terisi', () => {
    render(
      <PenyediaBahasa>
        <Keranjang
          daftarItem={[]}
          onTambahQty={vi.fn()}
          onKurangQty={vi.fn()}
          onHapusItem={vi.fn()}
          onUbahCatatan={vi.fn()}
        />
      </PenyediaBahasa>,
    )

    expect(screen.getByText(/Keranjang Masih Kosong/i)).toBeDefined()
  })

  it('menampilkan daftar item, kuantitas, dan rincian keuangan dari peladen', () => {
    render(
      <PenyediaBahasa>
        <Keranjang
          daftarItem={[itemContoh]}
          ringkasan={{
            subtotal: 56000,
            totalDiskon: 5000,
            pajak: 5100,
            service: 2550,
            total: 58650,
          }}
          onTambahQty={vi.fn()}
          onKurangQty={vi.fn()}
          onHapusItem={vi.fn()}
          onUbahCatatan={vi.fn()}
        />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Nasi Goreng Spesial')).toBeDefined()
    expect(screen.getAllByText('Rp56.000').length).toBe(2)
    expect(screen.getByText('-Rp5.000')).toBeDefined()
    expect(screen.getByText('Rp58.650')).toBeDefined()
  })

  it('memungkinkan penambahan catatan khusus per item pesanan (T3-03)', () => {
    const onUbahCatatanMock = vi.fn()

    render(
      <PenyediaBahasa>
        <Keranjang
          daftarItem={[itemContoh]}
          onTambahQty={vi.fn()}
          onKurangQty={vi.fn()}
          onHapusItem={vi.fn()}
          onUbahCatatan={onUbahCatatanMock}
        />
      </PenyediaBahasa>,
    )

    // Buka modal catatan
    fireEvent.click(screen.getByText('+ Tambah Catatan'))

    // Ketik catatan khusus
    const input = screen.getByLabelText(/Catatan Khusus untuk Dapur/i)
    fireEvent.change(input, { target: { value: 'Pedas sedang, telur setengah matang' } })

    // Simpan
    fireEvent.click(screen.getByRole('button', { name: /Simpan Catatan/i }))

    expect(onUbahCatatanMock).toHaveBeenCalledWith('it-1', 'Pedas sedang, telur setengah matang')
  })
})
