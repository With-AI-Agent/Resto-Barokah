// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { DaftarPesanan } from './DaftarPesanan'
import { PenyediaBahasa } from '../../bahasa'

describe('DaftarPesanan POS (T3-12)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender daftar riwayat pesanan dengan nomor pesanan, meja, dan total harga', () => {
    render(
      <PenyediaBahasa>
        <DaftarPesanan />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Riwayat Pesanan Hari Ini')).toBeDefined()
    expect(screen.getByText('ORD-20260922-001')).toBeDefined()
    expect(screen.getByText('Meja 01')).toBeDefined()
    expect(screen.getByText('Rp62.000')).toBeDefined()
  })

  it('dapat memfilter pesanan berdasarkan tipe pesanan atau kata kunci', () => {
    render(
      <PenyediaBahasa>
        <DaftarPesanan />
      </PenyediaBahasa>,
    )

    // Filter Takeaway
    const tombolTakeaway = screen.getByRole('button', { name: 'TAKEAWAY' })
    fireEvent.click(tombolTakeaway)

    expect(screen.getByText('ORD-20260922-003')).toBeDefined()
    expect(screen.queryByText('ORD-20260922-001')).toBeNull()
  })

  it('dapat memanggil callback saat tombol buka atau cetak struk ditekan', () => {
    const onPilihMock = vi.fn()
    const onCetakMock = vi.fn()

    render(
      <PenyediaBahasa>
        <DaftarPesanan onPilihPesanan={onPilihMock} onCetakUlang={onCetakMock} />
      </PenyediaBahasa>,
    )

    const tombolBuka = screen.getAllByRole('button', { name: 'Buka' })
    fireEvent.click(tombolBuka[0])
    expect(onPilihMock).toHaveBeenCalledWith('ord-101')

    const tombolCetak = screen.getAllByRole('button', { name: /Struk/i })
    fireEvent.click(tombolCetak[0])
    expect(onCetakMock).toHaveBeenCalledWith('ord-101')
  })
})
