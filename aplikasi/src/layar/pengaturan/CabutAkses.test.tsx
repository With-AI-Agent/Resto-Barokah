// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { CabutAkses } from './CabutAkses'
import type { PegawaiResto } from './KelolaPegawai'

describe('CabutAkses (T10-12 / PRD M3 & M12 / ART-2)', () => {
  afterEach(() => {
    cleanup()
  })

  const pegawaiUji: PegawaiResto = {
    id: 'usr-kasir-01',
    nama: 'Doni Pratama',
    email: 'doni@barokah.test',
    peran: 'kasir',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama',
    aktif: true,
    dibuatPada: '2026-09-01',
  }

  it('tidak merender apapun saat buka bernilai false', () => {
    const { container } = render(
      <CabutAkses buka={false} pegawai={pegawaiUji} onTutup={vi.fn()} onKonfirmasi={vi.fn()} />,
    )
    expect(container.firstChild).toBeNull()
  })

  it('merender dialog serah terima dan peringatan pengamanan saat buka true', () => {
    render(<CabutAkses buka={true} pegawai={pegawaiUji} onTutup={vi.fn()} onKonfirmasi={vi.fn()} />)

    expect(screen.getByText(/Cabut Akses: Doni Pratama/i)).toBeDefined()
    expect(screen.getByText('KASIR')).toBeDefined()
    expect(screen.getByText(/Akun seketika dinonaktifkan/i)).toBeDefined()
    expect(screen.getByText(/Sesi perangkat diakhiri/i)).toBeDefined()
    expect(screen.getByText(/Kredensial PIN dihapus/i)).toBeDefined()
    expect(screen.getByText(/Shift kasir ditandai/i)).toBeDefined()
    expect(screen.getByText(/Jaminan Laporan Masa Lalu/i)).toBeDefined()
  })

  it('memvalidasi kata konfirmasi CABUT sebelum mengirimkan serah terima', async () => {
    const onKonfirmasiMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <CabutAkses
        buka={true}
        pegawai={pegawaiUji}
        onTutup={vi.fn()}
        onKonfirmasi={onKonfirmasiMock}
      />,
    )

    // Tombol nonaktif jika belum diketik CABUT
    const tombolSubmit = screen.getByRole('button', { name: /Cabut Akses Sekarang/i })
    expect(tombolSubmit.hasAttribute('disabled')).toBe(true)

    // Ketik kata konfirmasi yang benar
    const inputKonfirmasi = screen.getByLabelText(/Ketik kata 'CABUT' untuk konfirmasi/i)
    fireEvent.change(inputKonfirmasi, { target: { value: 'CABUT' } })

    expect(tombolSubmit.hasAttribute('disabled')).toBe(false)
  })

  it('mengirimkan alasan dan catatan serah terima saat disubmit', async () => {
    const onKonfirmasiMock = vi.fn().mockResolvedValue({ sukses: true })
    const onTutupMock = vi.fn()

    render(
      <CabutAkses
        buka={true}
        pegawai={pegawaiUji}
        onTutup={onTutupMock}
        onKonfirmasi={onKonfirmasiMock}
      />,
    )

    // Ubah alasan dan catatan serah terima
    const inputAlasan = screen.getByLabelText(/Alasan Berhenti \/ Pencabutan Akses/i)
    fireEvent.change(inputAlasan, { target: { value: 'Karyawan resign pindah domisili' } })

    const inputCatatan = screen.getByPlaceholderText(
      /Contoh: Kunci laci kas fisik telah diserahkan/i,
    )
    fireEvent.change(inputCatatan, {
      target: { value: 'Kunci laci kas diserahkan ke Admin. Laci kas berisi Rp 100.000.' },
    })

    // Ketik CABUT
    const inputKonfirmasi = screen.getByLabelText(/Ketik kata 'CABUT' untuk konfirmasi/i)
    fireEvent.change(inputKonfirmasi, { target: { value: 'CABUT' } })

    // Klik tombol submit
    const tombolSubmit = screen.getByRole('button', { name: /Cabut Akses Sekarang/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onKonfirmasiMock).toHaveBeenCalledWith({
        pegawaiId: 'usr-kasir-01',
        alasan: 'Karyawan resign pindah domisili',
        catatanSerahTerima: 'Kunci laci kas diserahkan ke Admin. Laci kas berisi Rp 100.000.',
      })
      expect(onTutupMock).toHaveBeenCalled()
    })
  })
})
