// @vitest-environment jsdom
/**
 * Meja.test.tsx — Uji Unit Pengaturan Meja & Area (T9-04 / PRD M2 & M4).
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { Meja, type ItemMeja } from './Meja'

const DATA_UJI: ItemMeja[] = [
  {
    id: 'm-1',
    cabang_id: 'cab-1',
    nama: 'Meja 01',
    area: 'Utama',
    status: 'kosong',
    aktif: true,
  },
  {
    id: 'm-2',
    cabang_id: 'cab-1',
    nama: 'Meja 02',
    area: 'Outdoor',
    status: 'terisi',
    aktif: true,
  },
  {
    id: 'm-3',
    cabang_id: 'cab-1',
    nama: 'Meja 03',
    area: 'Utama',
    status: 'kosong',
    aktif: false,
  },
]

describe('Layar Pengaturan Meja & Area (T9-04)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
    vi.spyOn(window, 'confirm').mockImplementation(() => true)
  })

  afterEach(() => {
    cleanup()
  })

  it('1. Merender daftar meja dan kartu statistik ringkasan', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} />)

    expect(screen.getByText('Pengaturan Meja & Area')).toBeDefined()
    expect(screen.getByTestId('stat-total-meja').textContent).toBe('3')
    expect(screen.getByTestId('stat-meja-aktif').textContent).toBe('2')
    expect(screen.getByTestId('stat-meja-nonaktif').textContent).toBe('1')

    expect(screen.getByText('Meja 01')).toBeDefined()
    expect(screen.getByText('Meja 02')).toBeDefined()
    expect(screen.getByText('Meja 03')).toBeDefined()
  })

  it('2. Menyaring daftar meja berdasarkan filter tab area', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} />)

    // Awalnya semua meja muncul
    expect(screen.getByText('Meja 01')).toBeDefined()
    expect(screen.getByText('Meja 02')).toBeDefined()

    // Klik filter "📍 Outdoor"
    const filterOutdoor = screen.getByRole('button', { name: /Filter area Outdoor/i })
    fireEvent.click(filterOutdoor)

    // Meja 02 (Outdoor) ada, Meja 01 (Utama) tidak tampil
    expect(screen.getByText('Meja 02')).toBeDefined()
    expect(screen.queryByText('Meja 01')).toBeNull()
  })

  it('3. Menolak tambah meja baru bila nama meja kosong', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} />)

    const tombolTambah = screen.getByRole('button', { name: 'Tambah Meja Baru' })
    fireEvent.click(tombolTambah)

    expect(screen.getByText('Tambah Meja Baru')).toBeDefined()

    // Langsung klik simpan tanpa isi nama
    const tombolSimpan = screen.getByRole('button', { name: 'Simpan data meja' })
    fireEvent.click(tombolSimpan)

    expect(screen.getByText(/Nomor atau nama meja wajib diisi/i)).toBeDefined()
  })

  it('4. Menolak tambah meja baru bila nama kembar di cabang yang sama', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} cabangId="cab-1" />)

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Meja Baru' }))

    const inputNama = screen.getByLabelText(/Nomor atau Nama Meja/i)
    fireEvent.change(inputNama, { target: { value: 'Meja 01' } }) // Sudah ada di DATA_UJI

    fireEvent.click(screen.getByRole('button', { name: 'Simpan data meja' }))

    expect(
      screen.getByText(/Nomor\/nama meja "Meja 01" sudah digunakan di cabang ini/i),
    ).toBeDefined()
  })

  it('5. Berhasil menambah meja baru dan memanggil onSimpanMeja', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: true,
      meja: {
        id: 'm-baru',
        cabang_id: 'cab-1',
        nama: 'Meja 04',
        area: 'Utama',
        status: 'kosong',
        aktif: true,
      },
    })

    render(
      <Meja
        daftarMejaAwal={DATA_UJI}
        daftarAreaAwal={['Utama']}
        cabangId="cab-1"
        onSimpanMeja={mockSimpan}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Meja Baru' }))

    const inputNama = screen.getByLabelText(/Nomor atau Nama Meja/i)
    fireEvent.change(inputNama, { target: { value: 'Meja 04' } })

    fireEvent.click(screen.getByRole('button', { name: 'Simpan data meja' }))

    expect(mockSimpan).toHaveBeenCalledWith({
      id: undefined,
      cabang_id: 'cab-1',
      nama: 'Meja 04',
      area: 'Utama',
      aktif: true,
    })

    await waitFor(() => {
      expect(screen.getByText(/Meja "Meja 04" berhasil ditambahkan/i)).toBeDefined()
    })
  })

  it('6. Mengubah meja (edit nama & area)', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: true,
      meja: {
        id: 'm-1',
        cabang_id: 'cab-1',
        nama: 'Meja 01-Renov',
        area: 'Utama',
        status: 'kosong',
        aktif: true,
      },
    })

    render(<Meja daftarMejaAwal={DATA_UJI} cabangId="cab-1" onSimpanMeja={mockSimpan} />)

    // Klik tombol ubah pada meja 1
    const tombolUbah = screen.getByRole('button', { name: 'Ubah meja Meja 01' })
    fireEvent.click(tombolUbah)

    expect(screen.getByText('Ubah Informasi Meja')).toBeDefined()

    const inputNama = screen.getByLabelText(/Nomor atau Nama Meja/i)
    fireEvent.change(inputNama, { target: { value: 'Meja 01-Renov' } })

    fireEvent.click(screen.getByRole('button', { name: 'Simpan data meja' }))

    expect(mockSimpan).toHaveBeenCalledWith({
      id: 'm-1',
      cabang_id: 'cab-1',
      nama: 'Meja 01-Renov',
      area: 'Utama',
      aktif: true,
    })

    await waitFor(() => {
      expect(screen.getByText(/Meja "Meja 01-Renov" berhasil diperbarui/i)).toBeDefined()
    })
  })

  it('7. Mengaktifkan / menonaktifkan meja via tombol cepat toggle', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })

    render(<Meja daftarMejaAwal={DATA_UJI} onSimpanMeja={mockSimpan} />)

    // Meja 01 awalnya aktif -> klik Nonaktifkan
    const tombolToggle = screen.getByRole('button', { name: 'Ganti status aktif Meja 01' })
    expect(tombolToggle.textContent).toContain('Nonaktifkan')

    fireEvent.click(tombolToggle)

    expect(mockSimpan).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'm-1',
        aktif: false,
      }),
    )

    await waitFor(() => {
      expect(screen.getByText(/Meja "Meja 01" dinonaktifkan/i)).toBeDefined()
    })
  })

  it('8. Mencegah penonaktifan meja yang sedang terisi pesanan aktif', () => {
    const mockSimpan = vi.fn()

    render(<Meja daftarMejaAwal={DATA_UJI} onSimpanMeja={mockSimpan} />)

    // Meja 02 statusnya 'terisi'
    const tombolToggle = screen.getByRole('button', { name: 'Ganti status aktif Meja 02' })
    fireEvent.click(tombolToggle)

    expect(mockSimpan).not.toHaveBeenCalled()
    expect(screen.getByText(/sedang terisi tamu/i)).toBeDefined()
  })

  it('9. Menghapus meja dan memanggil onHapusMeja', async () => {
    const mockHapus = vi.fn().mockResolvedValue({ berhasil: true })

    render(<Meja daftarMejaAwal={DATA_UJI} onHapusMeja={mockHapus} />)

    const tombolHapus = screen.getByRole('button', { name: 'Hapus meja Meja 01' })
    fireEvent.click(tombolHapus)

    expect(window.confirm).toHaveBeenCalled()
    expect(mockHapus).toHaveBeenCalledWith('m-1')

    await waitFor(() => {
      expect(screen.getByText(/Meja "Meja 01" berhasil dihapus/i)).toBeDefined()
    })
  })

  it('10. Membuka modal stand QR meja dan merender QR SVG', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} namaResto="Kedai Oasis" />)

    const tombolQr = screen.getByRole('button', { name: 'Lihat kode QR Meja 01' })
    fireEvent.click(tombolQr)

    expect(screen.getByText('Stand Kode QR — Meja 01')).toBeDefined()
    expect(screen.getByText('MEJA 01')).toBeDefined()
    expect(screen.getByText('Kedai Oasis')).toBeDefined()
    expect(screen.getByRole('img', { name: 'QR Meja Meja 01' })).toBeDefined()
    expect(screen.getByRole('button', { name: 'Unduh Stand Akrilik SVG' })).toBeDefined()
  })

  it('11. Menyalin tautan QR meja ke clipboard', async () => {
    render(<Meja daftarMejaAwal={DATA_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: 'Lihat kode QR Meja 01' }))

    const tombolSalin = screen.getByRole('button', { name: 'Salin tautan meja' })
    fireEvent.click(tombolSalin)

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
      expect.stringContaining('katalog?meja=Meja%2001'),
    )
    await waitFor(() => {
      expect(screen.getByText(/Tautan Tersalin/i)).toBeDefined()
    })
  })

  it('12. Mode hanya-baca menyembunyikan aksi pengelolaan', () => {
    render(<Meja daftarMejaAwal={DATA_UJI} hanyaBaca={true} />)

    // Tombol tambah meja disembunyikan
    expect(screen.queryByRole('button', { name: 'Tambah Meja Baru' })).toBeNull()

    // Tombol ubah dan hapus disembunyikan
    expect(screen.queryByRole('button', { name: 'Ubah meja Meja 01' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Hapus meja Meja 01' })).toBeNull()

    // Tombol QR meja tetap tersedia untuk pratinjau
    expect(screen.getByRole('button', { name: 'Lihat kode QR Meja 01' })).toBeDefined()
  })
})
