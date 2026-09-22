// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Katalog } from './Katalog'
import { PenyediaBahasa } from '../../bahasa'

describe('Katalog Kasir (T3-01 & T3-07)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender daftar kategori dan item menu yang aktif', () => {
    render(
      <PenyediaBahasa>
        <Katalog onTambahKeKeranjang={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Semua Menu')).toBeDefined()
    expect(screen.getByText('Nasi Goreng Spesial Barokah')).toBeDefined()
    expect(screen.getByText('Es Teh Manis Melati')).toBeDefined()
  })

  it('mengunci menu yang berstatus habis (T3-07) sehingga tidak dapat ditambahkan ke keranjang', () => {
    const onTambahMock = vi.fn()

    render(
      <PenyediaBahasa>
        <Katalog onTambahKeKeranjang={onTambahMock} />
      </PenyediaBahasa>,
    )

    // Kopi Susu Gula Aren Barokah berstatus habis
    expect(screen.getByText('Habis')).toBeDefined()
    const kartuKopi = screen.getByText('Kopi Susu Gula Aren Barokah').closest('.kartu-menu')
    expect(kartuKopi).toBeDefined()

    if (kartuKopi) {
      fireEvent.click(kartuKopi)
    }

    // Tidak boleh memicu onTambahKeKeranjang
    expect(onTambahMock).not.toHaveBeenCalled()
  })

  it('membuka dialog varian & tambahan saat item memiliki varian, lalu menambahkan ke keranjang', () => {
    const onTambahMock = vi.fn()

    render(
      <PenyediaBahasa>
        <Katalog onTambahKeKeranjang={onTambahMock} />
      </PenyediaBahasa>,
    )

    // Klik Nasi Goreng (memiliki varian porsi sedang & jumbo, serta tambahan)
    const nasiGoreng = screen.getByText('Nasi Goreng Spesial Barokah')
    fireEvent.click(nasiGoreng)

    // Dialog terbuka
    expect(screen.getByText(/Pilih Opsi: Nasi Goreng Spesial Barokah/i)).toBeDefined()
    expect(screen.getByText('Porsi Jumbo')).toBeDefined()
    expect(screen.getByText(/Tambah Telur Dadar/i)).toBeDefined()

    // Pilih Porsi Jumbo
    fireEvent.click(screen.getByText('Porsi Jumbo'))

    // Pilih Tambahan Telur Dadar
    fireEvent.click(screen.getByText(/Tambah Telur Dadar/i))

    // Klik Tambahkan ke Pesanan
    fireEvent.click(screen.getByRole('button', { name: /Tambahkan ke Pesanan/i }))

    expect(onTambahMock).toHaveBeenCalledTimes(1)
    const panggilan = onTambahMock.mock.calls[0]
    expect(panggilan[0].nama).toBe('Nasi Goreng Spesial Barokah')
    expect(panggilan[1].nama).toBe('Porsi Jumbo')
    expect(panggilan[2][0].nama).toBe('Tambah Telur Dadar')
  })
})
