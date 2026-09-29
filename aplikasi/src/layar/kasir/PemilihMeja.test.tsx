// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { PemilihMeja, type PemilihMejaProps } from './PemilihMeja'
import { PenyediaBahasa } from '../../bahasa'
import { MEJA_KASIR_UJI } from '../../test/fixtures/mejaKasir'

function PemilihMejaDenganDataUji(props: PemilihMejaProps) {
  return <PemilihMeja daftarMeja={MEJA_KASIR_UJI} mejaTerpilihId="meja-01" {...props} />
}

describe('PemilihMeja (T3-03 & T3-06)', () => {
  afterEach(() => {
    cleanup()
  })

  it('tidak menampilkan meja contoh saat daftar cabang belum tersedia', () => {
    render(
      <PenyediaBahasa>
        <PemilihMeja onPilihTipe={vi.fn()} onPilihMeja={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.queryByText('Meja 01')).toBeNull()
    expect(screen.queryByText('Meja 02')).toBeNull()
  })

  it('merender pilihan jenis pesanan: Dine In, Takeaway, Ojol', () => {
    const onPilihTipeMock = vi.fn()

    render(
      <PenyediaBahasa>
        <PemilihMeja onPilihTipe={onPilihTipeMock} onPilihMeja={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText(/Makan di Tempat \(Dine In\)/i)).toBeDefined()
    expect(screen.getByText(/Bawa Pulang \(Takeaway\)/i)).toBeDefined()
    expect(screen.getByText(/Ojek Online/i)).toBeDefined()

    fireEvent.click(screen.getByText(/Bawa Pulang \(Takeaway\)/i))
    expect(onPilihTipeMock).toHaveBeenCalledWith('takeaway')
  })

  it('menampilkan status meja dan memilih meja resto', () => {
    const onPilihMejaMock = vi.fn()

    render(
      <PenyediaBahasa>
        <PemilihMejaDenganDataUji onPilihTipe={vi.fn()} onPilihMeja={onPilihMejaMock} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Meja 01')).toBeDefined()
    expect(screen.getByText('Meja 02')).toBeDefined()

    // Klik Meja 02
    fireEvent.click(screen.getByText('Meja 02'))
    expect(onPilihMejaMock).toHaveBeenCalled()
    expect(onPilihMejaMock.mock.calls[0][0].nama).toBe('Meja 02')
  })

  it('menjalankan alur pindah meja saat tombol pindah meja aktif (T3-06)', async () => {
    const onPindahMock = vi.fn().mockResolvedValue({ sukses: true })
    const onPilihMejaMock = vi.fn()

    render(
      <PenyediaBahasa>
        <PemilihMejaDenganDataUji
          mejaTerpilihId="meja-01"
          onPilihTipe={vi.fn()}
          onPilihMeja={onPilihMejaMock}
          onPindahMeja={onPindahMock}
        />
      </PenyediaBahasa>,
    )

    // Klik tombol Pindah Meja
    fireEvent.click(screen.getByText(/⇄ Pindah Meja/i))

    // Klik Meja 04 sebagai meja tujuan
    fireEvent.click(screen.getByText('Meja 04'))

    await waitFor(() => {
      expect(onPindahMock).toHaveBeenCalledWith('meja-01', 'meja-04')
      expect(onPilihMejaMock).toHaveBeenCalledWith(MEJA_KASIR_UJI[3])
      expect(screen.getByText(/Pesanan berhasil dipindahkan ke meja baru/i)).toBeDefined()
    })
  })

  it('menambahkan catatan cepat ke dalam isian catatan pesanan (T3-03)', () => {
    const onSimpanCatatanMock = vi.fn()

    render(
      <PenyediaBahasa>
        <PemilihMeja
          onPilihTipe={vi.fn()}
          onPilihMeja={vi.fn()}
          onSimpanCatatanPesanan={onSimpanCatatanMock}
        />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByText('+ Tanpa Es'))
    expect(onSimpanCatatanMock).toHaveBeenCalledWith('Tanpa Es')
  })
})
