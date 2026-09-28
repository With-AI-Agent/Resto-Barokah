// @vitest-environment jsdom
/**
 * Uji Unit Layar Kasir: VoucherKasir (T8-09).
 *
 * Target DoD:
 *   1. Tombol Cek tidak mengubah apa pun (baca saja, dibuktikan uji).
 *   2. Pakai wajib PIN kasir/atasan berizin.
 *   3. Hasil jelas (berhasil + rincian potongan / gagal + sebab spesifik).
 *   4. Potongan dihitung dari aturan kampanye.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { VoucherKasir, type HasilCekVoucher, type HasilPakaiVoucher } from './VoucherKasir'

afterEach(() => {
  cleanup()
})

const DATA_CEK_SUKSES: HasilCekVoucher = {
  berhasil: true,
  kode: 'SUKSES',
  pesan: 'Voucher sah dan siap digunakan.',
  data: {
    voucher_id: 'vcr-001',
    kode_voucher: 'VC-HEMAT20',
    status: 'aktif',
    nama_kampanye: 'Promo Makan Hemat 20%',
    jenis: 'persen',
    nilai: 20,
    min_belanja: 50000,
    maks_potongan: 20000,
    estimasi_potongan: 16000,
    nama_pelanggan: 'Budi Santoso',
    berlaku_sampai: '2026-12-31T23:59:59Z',
  },
}

describe('VoucherKasir (T8-09)', () => {
  it('menampilkan subtotal pesanan saat ini', () => {
    render(<VoucherKasir subtotal={80000} onCek={vi.fn()} onPakai={vi.fn()} />)
    expect(screen.getByTestId('voucher-subtotal').textContent).toContain('80.000')
  })

  it('menolak cek jika kode voucher kosong', async () => {
    const onCek = vi.fn()
    render(<VoucherKasir subtotal={80000} onCek={onCek} onPakai={vi.fn()} />)

    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))
    expect(onCek).not.toHaveBeenCalled()
    expect(screen.getByTestId('voucher-pesan-pakai').textContent).toContain('Masukkan kode voucher')
  })

  it('tombol Cek bersifat BACA SAJA dan menampilkan rincian promo kampanye', async () => {
    const onCek = vi.fn().mockResolvedValue(DATA_CEK_SUKSES)
    const onPakai = vi.fn()

    render(
      <VoucherKasir
        subtotal={80000}
        pesananId="ord-001"
        cabangId="cabang-001"
        onCek={onCek}
        onPakai={onPakai}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'vc-hemat20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))

    await waitFor(() => {
      expect(onCek).toHaveBeenCalledWith({
        kode: 'VC-HEMAT20',
        subtotal: 80000,
        cabangId: 'cabang-001',
      })
    })

    // Membuktikan bahwa Cek Voucher TIDAK memanggil onPakai (hanya membaca)
    expect(onPakai).not.toHaveBeenCalled()

    // Menampilkan rincian promo hasil cek
    await waitFor(() => {
      expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy()
      expect(screen.getByText('Voucher Sah')).toBeTruthy()
      expect(screen.getByTestId('voucher-nama-kampanye').textContent).toContain(
        'Promo Makan Hemat 20%',
      )
      expect(screen.getByTestId('voucher-rincian-diskon').textContent).toContain('Diskon 20%')
      expect(screen.getByTestId('voucher-estimasi-potongan').textContent).toContain('16.000')
      expect(screen.getByTestId('voucher-pelanggan').textContent).toContain('Budi Santoso')
    })
  })

  it('menampilkan sebab spesifik saat cek voucher gagal', async () => {
    const onCek = vi.fn().mockResolvedValue({
      berhasil: false,
      kode: 'SUBTOTAL_KURANG',
      pesan: 'Total belanja belum memenuhi syarat minimum Rp 50.000.',
    })

    render(<VoucherKasir subtotal={30000} onCek={onCek} onPakai={vi.fn()} />)

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))

    await waitFor(() => {
      expect(screen.getByTestId('voucher-hasil-cek-gagal')).toBeTruthy()
      expect(screen.getByText('Tidak Sah')).toBeTruthy()
      expect(screen.getByTestId('voucher-pesan-gagal').textContent).toContain(
        'Total belanja belum memenuhi syarat minimum',
      )
    })

    // Tombol pakai voucher tidak dapat diklik
    expect(screen.queryByRole('button', { name: /Pakai voucher/i })).toBeNull()
  })

  it('tombol Pakai Voucher dinonaktifkan sebelum PIN kasir diisi', async () => {
    const onCek = vi.fn().mockResolvedValue(DATA_CEK_SUKSES)
    render(<VoucherKasir subtotal={80000} onCek={onCek} onPakai={vi.fn()} />)

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))

    await waitFor(() => expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy())

    const tombolPakai = screen.getByRole('button', {
      name: /Pakai voucher/i,
    }) as HTMLButtonElement
    expect(tombolPakai.disabled).toBe(true)

    // Isi PIN Kasir -> tombol aktif
    fireEvent.change(screen.getByLabelText(/PIN Kasir/i), {
      target: { value: '1234' },
    })
    expect(tombolPakai.disabled).toBe(false)
  })

  it('menampilkan galat dan menghapus PIN saat verifikasi peladen gagal', async () => {
    const onCek = vi.fn().mockResolvedValue(DATA_CEK_SUKSES)
    const onPakai = vi.fn().mockResolvedValue({
      berhasil: false,
      kode: 'PIN_SALAH',
      pesan: 'PIN kasir tidak sah. Mohon periksa kembali PIN Anda.',
    })

    render(<VoucherKasir subtotal={80000} pesananId="ord-001" onCek={onCek} onPakai={onPakai} />)

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))
    await waitFor(() => expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy())

    fireEvent.change(screen.getByLabelText(/PIN Kasir/i), {
      target: { value: '9999' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Pakai voucher/i }))

    await waitFor(() => {
      expect(onPakai).toHaveBeenCalledWith({
        kode: 'VC-HEMAT20',
        pinKasir: '9999',
        pesananId: 'ord-001',
      })
    })

    // Galat spesifik tampil
    await waitFor(() => {
      expect(screen.getByTestId('voucher-pesan-pakai').textContent).toContain('PIN kasir tidak sah')
    })

    // Kolom PIN dikosongkan demi keamanan
    expect((screen.getByLabelText(/PIN Kasir/i) as HTMLInputElement).value).toBe('')
  })

  it('berhasil memakai voucher atomik dan memanggil onSelesai', async () => {
    const onCek = vi.fn().mockResolvedValue(DATA_CEK_SUKSES)
    const dataSuksesPakai: HasilPakaiVoucher = {
      berhasil: true,
      kode: 'SUKSES',
      pesan: 'Voucher berhasil digunakan.',
      data: {
        voucher_id: 'vcr-001',
        kode_voucher: 'VC-HEMAT20',
        nilai_potongan: 16000,
        nama_kampanye: 'Promo Makan Hemat 20%',
        nama_pelanggan: 'Budi Santoso',
      },
    }
    const onPakai = vi.fn().mockResolvedValue(dataSuksesPakai)
    const onSelesai = vi.fn()

    render(
      <VoucherKasir
        subtotal={80000}
        pesananId="ord-001"
        onCek={onCek}
        onPakai={onPakai}
        onSelesai={onSelesai}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))
    await waitFor(() => expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy())

    fireEvent.change(screen.getByLabelText(/PIN Kasir/i), {
      target: { value: '1234' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Pakai voucher/i }))

    await waitFor(() => {
      expect(onPakai).toHaveBeenCalledWith({
        kode: 'VC-HEMAT20',
        pinKasir: '1234',
        pesananId: 'ord-001',
      })
      expect(onSelesai).toHaveBeenCalledWith(dataSuksesPakai.data)
      expect(screen.getByTestId('voucher-sukses-pakai')).toBeTruthy()
    })
  })

  it('tombol batal memanggil onBatal', () => {
    const onBatal = vi.fn()
    render(<VoucherKasir subtotal={80000} onCek={vi.fn()} onPakai={vi.fn()} onBatal={onBatal} />)

    fireEvent.click(screen.getByRole('button', { name: /Batal/i }))
    expect(onBatal).toHaveBeenCalled()
  })
})
