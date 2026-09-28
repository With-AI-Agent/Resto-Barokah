// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { TagihanTerbuka } from './TagihanTerbuka'
import { PenyediaBahasa } from '../../bahasa'

describe('TagihanTerbuka (T3-04)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender daftar open bill transaksi berjalan', () => {
    render(
      <PenyediaBahasa>
        <TagihanTerbuka onPilihTagihan={vi.fn()} onBuatPesananBaru={vi.fn()} />
      </PenyediaBahasa>,
    )

    // Bentuk tampilan nomor tagihan: "No. 101" (hindari pola pagar-plus-angka
    // yang terbaca warna mentah oleh gerbang periksa-struktur).
    expect(screen.getByText('No. 101')).toBeDefined()
    expect(screen.getByText('Meja 02')).toBeDefined()
    expect(screen.getByText('No. 102')).toBeDefined()
    expect(screen.getByText('Rp62.000')).toBeDefined()
  })

  it('memilih tagihan terbuka untuk melanjutkan pesanan', () => {
    const onPilihMock = vi.fn()

    render(
      <PenyediaBahasa>
        <TagihanTerbuka onPilihTagihan={onPilihMock} onBuatPesananBaru={vi.fn()} />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByText('No. 101'))
    expect(onPilihMock).toHaveBeenCalled()
    expect(onPilihMock.mock.calls[0][0].nomor).toBe(101)
  })
})
