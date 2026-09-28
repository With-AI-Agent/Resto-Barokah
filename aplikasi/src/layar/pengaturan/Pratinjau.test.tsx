// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { Pratinjau, hitungTagihanStruk } from './Pratinjau'

describe('Pratinjau (Pratinjau Perubahan & Pengaman Riwayat — T9-11 / PRD M2)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('fungsi hitungTagihanStruk menghitung subtotal, diskon, PB1, service, dan pembulatan secara presisi', () => {
    // Skenario 1: Subtotal 50.000, PB1 10%, Service 5%, Tanpa Pembulatan
    const res1 = hitungTagihanStruk(
      [{ nama: 'Nasi Goreng', qty: 2, harga: 25000 }],
      0,
      10,
      5,
      'none',
    )
    expect(res1.subtotal).toBe(50000)
    expect(res1.diskon).toBe(0)
    expect(res1.dasar).toBe(50000)
    expect(res1.pajak).toBe(5000)
    expect(res1.service).toBe(2500)
    expect(res1.selisihBulat).toBe(0)
    expect(res1.total).toBe(57500)

    // Skenario 2: Subtotal 50.000, Diskon 10.000 (Dasar 40.000), PB1 10% (4.000), Service 5% (2.000), Pembulatan ke 500
    // Total kotor = 40.000 + 4.000 + 2.000 = 46.000 (sudah kelipatan 500)
    const res2 = hitungTagihanStruk(
      [{ nama: 'Nasi Goreng', qty: 2, harga: 25000 }],
      10000,
      10,
      5,
      '500',
    )
    expect(res2.subtotal).toBe(50000)
    expect(res2.diskon).toBe(10000)
    expect(res2.dasar).toBe(40000)
    expect(res2.pajak).toBe(4000)
    expect(res2.service).toBe(2000)
    expect(res2.total).toBe(46000)
    expect(res2.selisihBulat).toBe(0)

    // Skenario 3: Pembulatan ke bawah dengan selisih
    // 33.000 + 10% (3.300) + 5% (1.650) = 37.950 -> dibulatkan ke 500 = 37.500 (selisih -450)
    const res3 = hitungTagihanStruk([{ nama: 'Menu Uji', qty: 1, harga: 33000 }], 0, 10, 5, '500')
    expect(res3.total).toBe(37500)
    expect(res3.selisihBulat).toBe(-450)
  })

  it('merender judul, tabel diff, live struk simulator, dan jaminan pengaman riwayat', () => {
    render(
      <Pratinjau
        dataIdentitasSaatIni={{ namaResto: 'Kedai Oasis Barokah' }}
        dataIdentitasDraf={{ namaResto: 'Kedai Oasis Baru Berkah' }}
        dataOperasionalSaatIni={{ pajak_pb1_persen: 10, service_persen: 5 }}
        dataOperasionalDraf={{ pajak_pb1_persen: 12, service_persen: 10 }}
      />,
    )

    expect(screen.getByTestId('pratinjau-pengaturan')).toBeDefined()
    expect(screen.getByText(/Pratinjau Perubahan & Pengaman Riwayat/i)).toBeDefined()
    expect(screen.getByTestId('jaminan-pengaman-riwayat')).toBeDefined()
    expect(screen.getByTestId('tabel-diff-pengaturan')).toBeDefined()
    expect(screen.getByTestId('struk-lama')).toBeDefined()
    expect(screen.getByTestId('struk-baru')).toBeDefined()
    expect(screen.getByTestId('ringkasan-selisih-tagihan')).toBeDefined()

    // Indikator perubahan terdeteksi
    expect(screen.getByText(/3 Pengaturan Diubah/i)).toBeDefined()
  })

  it('menampilkan status selaras jika tidak ada perubahan draf', () => {
    render(
      <Pratinjau
        dataIdentitasSaatIni={{ namaResto: 'Kedai Oasis' }}
        dataIdentitasDraf={{ namaResto: 'Kedai Oasis' }}
      />,
    )

    expect(screen.getByText(/Semua Pengaturan Selaras/i)).toBeDefined()
  })

  it('dapat mengganti skenario transaksi uji untuk simulasi struk kasir', () => {
    render(<Pratinjau />)

    // Awalnya skenario Makan Siang Standar
    expect(screen.getAllByText(/Makan Siang Standar/i).length).toBeGreaterThan(0)

    // Beralih ke skenario Kopi & Kudapan
    const tombolKopi = screen.getByRole('button', { name: /pilih skenario pesanan santai/i })
    fireEvent.click(tombolKopi)

    expect(screen.getAllByText(/Kopi Barokah/i).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Pisang Goreng Crispy/i).length).toBeGreaterThan(0)
  })

  it('dapat mengganti format lebar kertas termal 58mm dan 80mm', () => {
    render(<Pratinjau />)

    const tombol80 = screen.getByRole('button', { name: /gunakan lebar kertas 80/i })
    fireEvent.click(tombol80)

    const strukBaru = screen.getByTestId('struk-baru')
    expect(strukBaru.style.width).toBe('360px')

    const tombol58 = screen.getByRole('button', { name: /gunakan lebar kertas 58/i })
    fireEvent.click(tombol58)

    expect(strukBaru.style.width).toBe('280px')
  })

  it('membuka dialog konfirmasi dan memanggil onSimpanSemua saat disetujui', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true, pesan: 'Tersimpan sukses' })
    render(
      <Pratinjau
        dataIdentitasSaatIni={{ namaResto: 'Lama' }}
        dataIdentitasDraf={{ namaResto: 'Baru' }}
        onSimpanSemua={mockSimpan}
      />,
    )

    const tombolTerapkan = screen.getByRole('button', {
      name: /terapkan dan simpan semua perubahan pengaturan/i,
    })
    fireEvent.click(tombolTerapkan)

    // Dialog konfirmasi muncul
    expect(screen.getByTestId('dialog-konfirmasi-simpan')).toBeDefined()
    expect(screen.getByText(/Konfirmasi Terapkan Perubahan Pengaturan/i)).toBeDefined()

    // Klik Ya, Terapkan Sekarang
    const tombolYa = screen.getByRole('button', { name: /konfirmasi simpan seluruh pengaturan/i })
    fireEvent.click(tombolYa)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledTimes(1)
    })
  })

  it('memanggil onResetDraf saat tombol Reset Draf ditekan', () => {
    const mockReset = vi.fn()
    render(
      <Pratinjau
        dataIdentitasSaatIni={{ namaResto: 'Lama' }}
        dataIdentitasDraf={{ namaResto: 'Baru' }}
        onResetDraf={mockReset}
      />,
    )

    const tombolReset = screen.getByRole('button', {
      name: /reset seluruh draf perubahan kembali ke nilai aktif/i,
    })
    fireEvent.click(tombolReset)

    expect(mockReset).toHaveBeenCalledTimes(1)
  })

  it('memanggil onCetakSimulasi saat tombol Cetak Uji ditekan', () => {
    const mockCetak = vi.fn()
    render(<Pratinjau onCetakSimulasi={mockCetak} />)

    const tombolCetak = screen.getByRole('button', { name: /cetak lembar simulasi ini/i })
    fireEvent.click(tombolCetak)

    expect(mockCetak).toHaveBeenCalledTimes(1)
  })
})
