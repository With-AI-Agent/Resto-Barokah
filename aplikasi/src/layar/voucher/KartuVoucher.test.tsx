// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { KartuVoucher, type VoucherDetail } from './KartuVoucher'
import { buatPolaGaris } from '../../lib/barcode'

const CONTOH_VOUCHER: VoucherDetail = {
  kode: 'RB-7X9K-2M4P',
  nama_pelanggan: 'Kartika Dewi',
  nama_kampanye: 'Diskon Sambut Pelanggan',
  nama_resto: 'Kedai Barokah Utama',
  nilai: 25,
  jenis: 'persen',
  min_belanja: 50000,
  maks_potongan: 20000,
  berlaku_sampai: '20 Oktober 2026',
  status: 'aktif',
}

describe('Komponen KartuVoucher (T8-08 — Kode Voucher Acak & Barcode)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
  })

  afterEach(() => {
    cleanup()
  })

  it('fungsi helper buatPolaGaris menghasilkan representasi bit biner barcode 1D', () => {
    const pola = buatPolaGaris('RB-7X9K-2M4P')
    expect(typeof pola).toBe('string')
    expect(pola.length).toBeGreaterThan(50)
    expect(pola.startsWith('11010010000')).toBe(true)
    expect(pola.endsWith('1100011101011')).toBe(true)
    expect(/^[01]+$/.test(pola)).toBe(true)
  })

  it('merender detail voucher lengkap: nama resto, kampanye, diskon, dan syarat', () => {
    render(<KartuVoucher voucher={CONTOH_VOUCHER} />)

    expect(screen.getByText('Kedai Barokah Utama')).toBeDefined()
    expect(screen.getByText('Diskon Sambut Pelanggan')).toBeDefined()
    expect(screen.getByText(/Kartika Dewi/)).toBeDefined()
    expect(screen.getByTestId('nilai-diskon-voucher').textContent).toContain('Diskon 25%')
    expect(screen.getByText(/Min. Belanja: Rp50.000/)).toBeDefined()
    expect(screen.getByText(/Maks. Potongan: Rp20.000/)).toBeDefined()
    expect(screen.getByTestId('masa-berlaku-voucher').textContent).toContain('20 Oktober 2026')
  })

  it('merender kode voucher acak monospaced dan barcode 1D serta QR Code 2D', () => {
    render(<KartuVoucher voucher={CONTOH_VOUCHER} />)

    // Kode teks monospaced
    const kodeEl = screen.getByTestId('kode-voucher-teks')
    expect(kodeEl).toBeDefined()
    expect(kodeEl.textContent).toContain('RB-7X9K-2M4P')

    // Barcode visual 1D
    const barcodeWadah = screen.getByTestId('wadah-barcode-1d')
    expect(barcodeWadah).toBeDefined()
    expect(barcodeWadah.querySelector('svg')).toBeDefined()

    // Barcode 2D / QR Code
    expect(screen.getByTestId('komponen-qr')).toBeDefined()
  })

  it('menampilkan status badge yang sesuai (aktif, terpakai, kedaluwarsa)', () => {
    const { rerender } = render(<KartuVoucher voucher={CONTOH_VOUCHER} />)
    expect(screen.getByText('Siap Digunakan')).toBeDefined()

    rerender(<KartuVoucher voucher={{ ...CONTOH_VOUCHER, status: 'terpakai' }} />)
    expect(screen.getByText('Sudah Terpakai')).toBeDefined()

    rerender(<KartuVoucher voucher={{ ...CONTOH_VOUCHER, status: 'kedaluwarsa' }} />)
    expect(screen.getByText('Kedaluwarsa')).toBeDefined()
  })

  it('dapat menyalin kode voucher ke papan klip dengan umpan balik visual', async () => {
    const onSalin = vi.fn()
    render(<KartuVoucher voucher={CONTOH_VOUCHER} onSalin={onSalin} />)

    const tombolSalin = screen.getByRole('button', { name: /salin kode voucher/i })
    fireEvent.click(tombolSalin)

    await waitFor(() => {
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith('RB-7X9K-2M4P')
      expect(onSalin).toHaveBeenCalledWith('RB-7X9K-2M4P')
      expect(screen.getByText(/✓ Kode Tersalin ke Papan Klip!/i)).toBeDefined()
    })
  })

  it('dapat memanggil fungsi cetak tiket', () => {
    const onCetak = vi.fn()
    render(<KartuVoucher voucher={CONTOH_VOUCHER} onCetak={onCetak} />)

    const tombolCetak = screen.getByRole('button', { name: /cetak atau simpan tiket voucher/i })
    fireEvent.click(tombolCetak)

    expect(onCetak).toHaveBeenCalledTimes(1)
  })

  it('merender voucher dengan jenis nominal rupiah potongan tetap', () => {
    const voucherNominal: VoucherDetail = {
      ...CONTOH_VOUCHER,
      kode: 'RB-3B2C-9P8T',
      jenis: 'nominal',
      nilai: 15000,
      maks_potongan: undefined,
    }

    render(<KartuVoucher voucher={voucherNominal} />)
    expect(screen.getByTestId('nilai-diskon-voucher').textContent).toContain('Potongan Rp15.000')
    expect(screen.getByTestId('kode-voucher-teks').textContent).toContain('RB-3B2C-9P8T')
  })
})
