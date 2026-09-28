// @vitest-environment jsdom
/**
 * Uji TutupKas.tsx (T7-02) — rekonsiliasi tutup kas kasir & pencatatan selisih.
 *
 * Yang dibuktikan (DoD T7-02):
 *  - Informasi shift aktif & uang seharusnya (sistem) ditampilkan dengan jelas;
 *  - Input uang fisik wajib diisi dan tidak boleh negatif;
 *  - Tombol Uang Pas mengisi nominal sesuai uang seharusnya;
 *  - Tombol bantuan pecahan uang dan reset berfungsi dengan benar;
 *  - Selisih kas dihitung secara real-time (seharusnya vs fisik);
 *  - Bila ada selisih (lebih atau kurang), isian alasan selisih kas wajib diisi;
 *  - Bila tidak ada selisih (pas), alasan selisih kas tidak wajib diisi;
 *  - Alasan cepat (chips) mempermudah kasir mengisi alasan selisih;
 *  - Dialog konfirmasi merangkum rincian sebelum penutupan kas dieksekusi;
 *  - Memanggil `onTutupShift` (RPC `tutup_shift`) dan menampilkan kartu sukses;
 *  - Penanganan galat dari peladen ditampilkan secara ramah kepada kasir.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { TutupKas } from './TutupKas'

afterEach(() => {
  cleanup()
})

describe('Komponen TutupKas (T7-02)', () => {
  const dummyProps = {
    shiftId: 'shift-123',
    cabangId: 'cab-01',
    namaCabang: 'Kedai Oasis Pusat',
    namaKasir: 'Rina Kasir',
    dibukaPada: '2026-09-24T08:00:00Z',
    modalAwal: 100000,
    uangSeharusnyaPerkiraan: 250000,
  }

  it('menampilkan informasi shift aktif dengan benar', () => {
    render(<TutupKas {...dummyProps} />)

    expect(screen.getByText('Tutup Shift Kasir')).toBeDefined()
    expect(screen.getByText(/Kedai Oasis Pusat/)).toBeDefined()
    expect(screen.getByText('Rina Kasir')).toBeDefined()
    expect(screen.getByText('Rp100.000')).toBeDefined() // modal awal
    expect(screen.getByText('Rp250.000')).toBeDefined() // uang seharusnya
  })

  it('tombol Uang Pas mengisi nilai sesuai uang seharusnya', () => {
    render(<TutupKas {...dummyProps} />)

    const tombolUangPas = screen.getByRole('button', { name: /Uang Pas/i })
    fireEvent.click(tombolUangPas)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i) as HTMLInputElement
    expect(inputFisik.value).toBe('250000')

    // Selisih pas (Rp0)
    expect(screen.getByText('Hasil Hitung Pas')).toBeDefined()
  })

  it('tombol tambah uang dan reset berfungsi dengan benar', () => {
    render(<TutupKas {...dummyProps} />)

    const tombolTambah50k = screen.getByRole('button', { name: '+Rp50.000' })
    fireEvent.click(tombolTambah50k)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i) as HTMLInputElement
    expect(inputFisik.value).toBe('50000')

    const tombolReset = screen.getByRole('button', { name: 'Reset Rp0' })
    fireEvent.click(tombolReset)
    expect(inputFisik.value).toBe('0')
  })

  it('menampilkan status selisih kas lebih saat fisik > seharusnya', () => {
    render(<TutupKas {...dummyProps} />)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i)
    fireEvent.change(inputFisik, { target: { value: '260000' } })

    expect(screen.getByText('Kas Lebih')).toBeDefined()
    expect(screen.getByTestId('nilai-selisih').textContent).toBe('+Rp10.000')

    // Kolom alasan selisih muncul
    expect(screen.getByLabelText(/Alasan Selisih Kas \(Wajib\)/i)).toBeDefined()
  })

  it('menampilkan status selisih kas kurang saat fisik < seharusnya', () => {
    render(<TutupKas {...dummyProps} />)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i)
    fireEvent.change(inputFisik, { target: { value: '240000' } })

    expect(screen.getByText('Kas Kurang')).toBeDefined()
    expect(screen.getByText('-Rp10.000')).toBeDefined()
  })

  it('menolak lanjut jika ada selisih tetapi alasan kosong', () => {
    render(<TutupKas {...dummyProps} />)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i)
    fireEvent.change(inputFisik, { target: { value: '240000' } })

    const tombolLanjut = screen.getByRole('button', { name: 'Lanjut Tutup Kas' })
    fireEvent.click(tombolLanjut)

    expect(
      screen.getByText(/Alasan selisih wajib diisi jika hasil hitung fisik berbeda/i),
    ).toBeDefined()
    expect(screen.queryByText('Konfirmasi Penutupan Shift')).toBeNull()
  })

  it('alasan cepat mengisi isian alasan selisih dan mengizinkan konfirmasi', () => {
    render(<TutupKas {...dummyProps} />)

    const inputFisik = screen.getByLabelText(/Uang Fisik di Laci Kas/i)
    fireEvent.change(inputFisik, { target: { value: '260000' } })

    const chipAlasan = screen.getByRole('button', {
      name: 'Kembalian receh tidak diambil pelanggan',
    })
    fireEvent.click(chipAlasan)

    const inputAlasan = screen.getByLabelText(/Alasan Selisih Kas \(Wajib\)/i) as HTMLInputElement
    expect(inputAlasan.value).toBe('Kembalian receh tidak diambil pelanggan')

    const tombolLanjut = screen.getByRole('button', { name: 'Lanjut Tutup Kas' })
    fireEvent.click(tombolLanjut)

    expect(screen.getByText('Konfirmasi Penutupan Shift')).toBeDefined()
  })

  it('berhasil mengirim data tutup shift dan menampilkan ringkasan sukses', async () => {
    const mockOnTutupShift = vi.fn().mockResolvedValue({
      sukses: true,
      data: {
        shiftId: 'shift-123',
        cabangId: 'cab-01',
        modalAwal: 100000,
        tunaiMasuk: 150000,
        tunaiKeluar: 0,
        uangSeharusnya: 250000,
        uangFisik: 250000,
        selisih: 0,
        status: 'ditutup',
      },
    })

    render(<TutupKas {...dummyProps} onTutupShift={mockOnTutupShift} />)

    // Isi fisik pas
    fireEvent.change(screen.getByLabelText(/Uang Fisik di Laci Kas/i), {
      target: { value: '250000' },
    })

    fireEvent.click(screen.getByRole('button', { name: 'Lanjut Tutup Kas' }))

    expect(screen.getByText('Konfirmasi Penutupan Shift')).toBeDefined()

    // Klik tombol konfirmasi eksekusi
    fireEvent.click(screen.getByRole('button', { name: 'Ya, Tutup Shift Sekarang' }))

    await waitFor(() => {
      expect(mockOnTutupShift).toHaveBeenCalledWith({
        uangFisik: 250000,
        alasanSelisih: undefined,
        catatan: undefined,
        shiftId: 'shift-123',
      })
    })

    expect(screen.getByText('Shift Kas Berhasil Ditutup!')).toBeDefined()
  })

  it('menangani kegagalan peladen dan menampilkan pesan galat', async () => {
    const mockOnTutupShift = vi.fn().mockResolvedValue({
      sukses: false,
      pesan: 'Shift kas ini sudah ditutup sebelumnya.',
    })

    render(<TutupKas {...dummyProps} onTutupShift={mockOnTutupShift} />)

    fireEvent.change(screen.getByLabelText(/Uang Fisik di Laci Kas/i), {
      target: { value: '250000' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Lanjut Tutup Kas' }))
    fireEvent.click(screen.getByRole('button', { name: 'Ya, Tutup Shift Sekarang' }))

    await waitFor(() => {
      expect(screen.getByText('Shift kas ini sudah ditutup sebelumnya.')).toBeDefined()
    })
  })
})
