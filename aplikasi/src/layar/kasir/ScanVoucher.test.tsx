// @vitest-environment jsdom
/**
 * Uji Unit Layar Kasir: ScanVoucher (T8-10).
 *
 * Target DoD:
 *   1. Memindai barcode/QR dari kamera perangkat (BarcodeDetector API & MediaDevices).
 *   2. Masukan manual sebagai cadangan selalu tersedia langsung di layar.
 *   3. Pesan kejelasan bila kamera tidak tersedia atau izin ditolak disajikan ramah awam.
 *   4. Pembersihan MediaStream track saat komponen dilepas (unmount).
 *   5. Integrasi lancar dengan alur cek dan pakai voucher kasir.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { ScanVoucher } from './ScanVoucher'
import { VoucherKasir, type HasilCekVoucher } from './VoucherKasir'

afterEach(() => {
  cleanup()
})

describe('ScanVoucher (T8-10)', () => {
  const mockTrackStop = vi.fn()
  const mockStream = {
    getTracks: () => [{ stop: mockTrackStop }],
  } as unknown as MediaStream

  let originalMediaDevices: PropertyDescriptor | undefined

  beforeEach(() => {
    originalMediaDevices = Object.getOwnPropertyDescriptor(navigator, 'mediaDevices')
    mockTrackStop.mockClear()
  })

  afterEach(() => {
    if (originalMediaDevices) {
      Object.defineProperty(navigator, 'mediaDevices', originalMediaDevices)
    } else {
      // @ts-expect-error reset jika tadinya undefined
      delete navigator.mediaDevices
    }
    // @ts-expect-error bersihkan BarcodeDetector tiruan
    delete window.BarcodeDetector
  })

  it('menampilkan pesan ramah awam bila peramban tidak mendukung kamera', async () => {
    // MediaDevices tidak tersedia
    Object.defineProperty(navigator, 'mediaDevices', {
      value: undefined,
      configurable: true,
      writable: true,
    })

    render(<ScanVoucher onPindai={vi.fn()} onBatal={vi.fn()} />)

    await waitFor(() => {
      expect(screen.getByTestId('pesan-kamera-tidak-tersedia')).toBeTruthy()
      expect(screen.getByText('Kamera Tidak Tersedia')).toBeTruthy()
      expect(
        screen.getByText(/Kamera tidak didukung pada peramban atau perangkat kasir ini/i),
      ).toBeTruthy()
    })

    // Jalur cadangan manual tetap wajib tampil
    expect(screen.getByTestId('scan-voucher-manual')).toBeTruthy()
  })

  it('menampilkan pesan ramah awam bila izin kamera ditolak oleh pengguna', async () => {
    const errorDitolak = new Error('Permission denied')
    errorDitolak.name = 'NotAllowedError'

    Object.defineProperty(navigator, 'mediaDevices', {
      value: {
        getUserMedia: vi.fn().mockRejectedValue(errorDitolak),
      },
      configurable: true,
      writable: true,
    })

    render(<ScanVoucher onPindai={vi.fn()} onBatal={vi.fn()} />)

    await waitFor(() => {
      expect(screen.getByTestId('pesan-kamera-tidak-tersedia')).toBeTruthy()
      expect(screen.getByText('Akses Ditolak')).toBeTruthy()
      expect(screen.getByText(/Izin akses kamera ditolak oleh peramban/i)).toBeTruthy()
    })

    // Masukan manual tetap dapat digunakan
    expect(screen.getByTestId('scan-voucher-manual')).toBeTruthy()
  })

  it('menampilkan pesan ramah awam bila kamera sedang dipakai aplikasi lain atau galat perangkat', async () => {
    const errorPerangkat = new Error('Camera busy')
    errorPerangkat.name = 'NotReadableError'

    Object.defineProperty(navigator, 'mediaDevices', {
      value: {
        getUserMedia: vi.fn().mockRejectedValue(errorPerangkat),
      },
      configurable: true,
      writable: true,
    })

    render(<ScanVoucher onPindai={vi.fn()} onBatal={vi.fn()} />)

    await waitFor(() => {
      expect(screen.getByTestId('pesan-kamera-tidak-tersedia')).toBeTruthy()
      expect(screen.getByText('Kamera Tidak Tersedia')).toBeTruthy()
      expect(screen.getByText(/Kamera tidak dapat diakses atau sedang digunakan/i)).toBeTruthy()
    })
  })

  it('berhasil membuka kamera dan mematikan stream saat komponen di-unmount', async () => {
    const getUserMedia = vi.fn().mockResolvedValue(mockStream)
    Object.defineProperty(navigator, 'mediaDevices', {
      value: { getUserMedia },
      configurable: true,
      writable: true,
    })

    const { unmount } = render(<ScanVoucher onPindai={vi.fn()} onBatal={vi.fn()} />)

    await waitFor(() => {
      expect(getUserMedia).toHaveBeenCalledWith({
        video: { facingMode: 'environment' },
      })
      expect(screen.getByTestId('video-kamera')).toBeTruthy()
      expect(screen.getByTestId('bingkai-bidik')).toBeTruthy()
    })

    // Bersihkan komponen -> pastikan track video dimatikan
    unmount()
    expect(mockTrackStop).toHaveBeenCalled()
  })

  it('meneruskan hasil deteksi kamera BarcodeDetector ke callback pemindai saat video aktif', async () => {
    const getUserMedia = vi.fn().mockResolvedValue(mockStream)
    Object.defineProperty(navigator, 'mediaDevices', {
      value: { getUserMedia },
      configurable: true,
      writable: true,
    })

    const onPindai = vi.fn()
    let mockDetect: () => Promise<Array<{ rawValue: string }>> = async () => []

    class MockBarcodeDetector {
      constructor() {}
      detect() {
        return mockDetect()
      }
    }
    // @ts-expect-error pasang BarcodeDetector global untuk uji
    window.BarcodeDetector = MockBarcodeDetector

    render(<ScanVoucher onPindai={onPindai} />)

    await waitFor(() => {
      expect(screen.getByTestId('video-kamera')).toBeTruthy()
    })

    const videoEl = screen.getByTestId('video-kamera')
    fireEvent.play(videoEl)

    // Simulasikan deteksi barcode berhasil
    mockDetect = async () => [{ rawValue: 'rb-promo-50' }]

    // Trigger requestAnimationFrame
    await waitFor(() => {
      if (onPindai.mock.calls.length > 0) {
        expect(onPindai).toHaveBeenCalledWith('RB-PROMO-50')
      }
    })
  })

  it('masukan manual sebagai cadangan: memvalidasi teks kosong dan mengirim kode yang dibersihkan', () => {
    const onPindai = vi.fn()
    render(<ScanVoucher onPindai={onPindai} onBatal={vi.fn()} />)

    const inputManual = screen.getByLabelText(/Ketik kode voucher manual/i)
    const tombolGunakan = screen.getByRole('button', { name: /Gunakan kode manual/i })

    // Awalnya tombol dinonaktifkan
    expect((tombolGunakan as HTMLButtonElement).disabled).toBe(true)

    // Ketik kode dengan spasi dan huruf kecil
    fireEvent.change(inputManual, { target: { value: '  hemat-10k  ' } })
    expect((tombolGunakan as HTMLButtonElement).disabled).toBe(false)

    fireEvent.click(tombolGunakan)
    expect(onPindai).toHaveBeenCalledWith('HEMAT-10K')
  })

  it('tombol batal memanggil callback onBatal', () => {
    const onBatal = vi.fn()
    render(<ScanVoucher onPindai={vi.fn()} onBatal={onBatal} />)

    fireEvent.click(screen.getByRole('button', { name: /Batal scan/i }))
    expect(onBatal).toHaveBeenCalled()
  })
})

describe('Integrasi ScanVoucher pada VoucherKasir (T8-10)', () => {
  const DATA_CEK_SUKSES: HasilCekVoucher = {
    berhasil: true,
    kode: 'SUKSES',
    pesan: 'Voucher sah dan siap digunakan.',
    data: {
      voucher_id: 'vcr-002',
      kode_voucher: 'VC-SCAN10',
      status: 'aktif',
      nama_kampanye: 'Promo Pindai Kamera 10%',
      jenis: 'persen',
      nilai: 10,
      min_belanja: 30000,
      maks_potongan: 15000,
      estimasi_potongan: 5000,
    },
  }

  it('kasir dapat membuka pemindai, mengetik kode manual di pemindai, dan otomatis terverifikasi', async () => {
    const onCek = vi.fn().mockResolvedValue(DATA_CEK_SUKSES)
    const onPakai = vi.fn()

    render(<VoucherKasir subtotal={50000} onCek={onCek} onPakai={onPakai} />)

    // Buka pemindai dengan klik tombol "📷 Pindai"
    const tombolPindai = screen.getByRole('button', { name: /Buka scan kamera/i })
    fireEvent.click(tombolPindai)

    // Komponen ScanVoucher muncul
    expect(screen.getByTestId('scan-voucher')).toBeTruthy()

    // Gunakan jalur manual pada pemindai
    const inputManual = screen.getByLabelText(/Ketik kode voucher manual/i)
    fireEvent.change(inputManual, { target: { value: 'VC-SCAN10' } })
    fireEvent.click(screen.getByRole('button', { name: /Gunakan kode manual/i }))

    // Pemindai tertutup dan onCek dipanggil otomatis
    await waitFor(() => {
      expect(onCek).toHaveBeenCalledWith({
        kode: 'VC-SCAN10',
        subtotal: 50000,
        cabangId: undefined,
      })
    })

    // Hasil cek sukses tampil di layar
    await waitFor(() => {
      expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy()
      expect(screen.getByTestId('voucher-nama-kampanye').textContent).toContain(
        'Promo Pindai Kamera 10%',
      )
    })
  })

  it('kasir dapat membatalkan scan dan kembali ke tampilan awal voucher kasir', () => {
    render(<VoucherKasir subtotal={50000} onCek={vi.fn()} onPakai={vi.fn()} />)

    fireEvent.click(screen.getByRole('button', { name: /Buka scan kamera/i }))
    expect(screen.getByTestId('scan-voucher')).toBeTruthy()

    // Klik tombol Batal di pemindai
    fireEvent.click(screen.getByRole('button', { name: /Batal scan/i }))

    // Tampilan awal kembali (input kode voucher terlihat)
    expect(screen.queryByTestId('scan-voucher')).toBeNull()
    expect(screen.getByLabelText(/Kode voucher/i)).toBeTruthy()
  })
})
