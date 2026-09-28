// @vitest-environment jsdom
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { Identitas, type DataIdentitas } from './Identitas'

describe('Identitas (Pengaturan Identitas & Tampilan Resto — T9-01)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  const dataAwalUji: DataIdentitas = {
    namaResto: 'Kedai Oasis Barokah',
    tagline: 'Cita Rasa Tradisi Hangat & Halal',
    logoUrl: 'https://resto-barokah.com/logo.png',
    bannerUrl: 'https://resto-barokah.com/banner.jpg',
    jamBuka: 'Senin - Minggu: 08.00 - 22.00 WIB',
    versiPengaturan: '2026-09-26T12:00:00Z',
  }

  it('merender judul, kolom nama, tagline, jam buka, dan tombol simpan', () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    expect(screen.getByText('Identitas & Tampilan Restoran')).toBeDefined()
    expect(screen.getByLabelText(/nama restoran/i)).toBeDefined()
    expect(screen.getByLabelText(/slogan \/ tagline/i)).toBeDefined()
    expect(screen.getByLabelText(/jam operasional/i)).toBeDefined()
    expect(screen.getByRole('button', { name: /simpan identitas resto/i })).toBeDefined()
  })

  it('dapat mengubah nama resto, tagline, dan jam buka', () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    const inputNama = screen.getByLabelText(/nama restoran/i) as HTMLInputElement
    fireEvent.change(inputNama, { target: { value: 'Kedai Oasis Baru' } })
    expect(inputNama.value).toBe('Kedai Oasis Baru')

    const inputTagline = screen.getByLabelText(/slogan \/ tagline/i) as HTMLInputElement
    fireEvent.change(inputTagline, { target: { value: 'Rasa Autentik Nusantara' } })
    expect(inputTagline.value).toBe('Rasa Autentik Nusantara')
  })

  it('menolak nama resto kosong saat menekan tombol simpan', async () => {
    const mockSimpan = vi.fn()
    render(<Identitas dataAwal={dataAwalUji} onSimpan={mockSimpan} />)

    const inputNama = screen.getByLabelText(/nama restoran/i)
    fireEvent.change(inputNama, { target: { value: '   ' } })

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/nama restoran wajib diisi/i)).toBeDefined()
    expect(mockSimpan).not.toHaveBeenCalled()
  })

  it('menolak nama resto yang terlalu panjang (> 120 karakter)', async () => {
    const mockSimpan = vi.fn()
    render(<Identitas dataAwal={dataAwalUji} onSimpan={mockSimpan} />)

    const inputNama = screen.getByLabelText(/nama restoran/i)
    fireEvent.change(inputNama, { target: { value: 'A'.repeat(125) } })

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/nama restoran maksimal 120 karakter/i)).toBeDefined()
    expect(mockSimpan).not.toHaveBeenCalled()
  })

  it('menolak unggahan logo dengan format selain JPG/PNG/WebP', async () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    const inputBerkas = screen.getByTestId('input-berkas-logo')
    const berkasSalah = new File(['konten dummy'], 'dokumen.pdf', { type: 'application/pdf' })

    fireEvent.change(inputBerkas, { target: { files: [berkasSalah] } })

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/format berkas logo harus berupa gambar/i)).toBeDefined()
  })

  it('menolak unggahan logo yang melebihi 2 MB', async () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    const inputBerkas = screen.getByTestId('input-berkas-logo')
    const berkasBesar = new File([new ArrayBuffer(2.5 * 1024 * 1024)], 'logo-raksasa.png', {
      type: 'image/png',
    })

    fireEvent.change(inputBerkas, { target: { files: [berkasBesar] } })

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/ukuran logo maksimal 2 mb/i)).toBeDefined()
  })

  it('menolak unggahan banner yang melebihi 3 MB', async () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    const inputBerkas = screen.getByTestId('input-berkas-banner')
    const berkasBesar = new File([new ArrayBuffer(3.5 * 1024 * 1024)], 'banner-raksasa.jpg', {
      type: 'image/jpeg',
    })

    fireEvent.change(inputBerkas, { target: { files: [berkasBesar] } })

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/ukuran banner maksimal 3 mb/i)).toBeDefined()
  })

  it('dapat menghapus logo dan banner yang terpasang', () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    const tombolHapusLogo = screen.getByRole('button', { name: /hapus logo yang terpasang/i })
    fireEvent.click(tombolHapusLogo)

    expect(screen.queryByTestId('img-pratinjau-logo')).toBeNull()

    const tombolHapusBanner = screen.getByRole('button', { name: /hapus banner yang terpasang/i })
    fireEvent.click(tombolHapusBanner)

    expect(screen.queryByTestId('img-pratinjau-banner')).toBeNull()
  })

  it('beralih antara pratinjau katalog dan pratinjau struk', () => {
    render(<Identitas dataAwal={dataAwalUji} />)

    // Awalnya di pratinjau katalog
    expect(screen.getByTestId('wadah-pratinjau-katalog')).toBeDefined()
    expect(screen.getByTestId('teks-nama-pratinjau').textContent).toBe('Kedai Oasis Barokah')

    // Pindah ke pratinjau struk
    const tombolStruk = screen.getByRole('button', { name: /beralih ke pratinjau cetak struk/i })
    fireEvent.click(tombolStruk)

    expect(screen.getByTestId('wadah-pratinjau-struk')).toBeDefined()
    expect(screen.getByTestId('struk-nama-resto').textContent).toContain('KEDAI OASIS BAROKAH')

    // Pindah kembali ke katalog
    const tombolKatalog = screen.getByRole('button', { name: /beralih ke pratinjau katalog/i })
    fireEvent.click(tombolKatalog)

    expect(screen.getByTestId('wadah-pratinjau-katalog')).toBeDefined()
  })

  it('memanggil onSimpan dengan data lengkap dan menampilkan pesan sukses', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Pengaturan identitas berhasil disimpan.',
    })

    render(<Identitas dataAwal={dataAwalUji} onSimpan={mockSimpan} />)

    const inputNama = screen.getByLabelText(/nama restoran/i)
    fireEvent.change(inputNama, { target: { value: 'Kedai Oasis Sukses' } })

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledTimes(1)
      expect(mockSimpan).toHaveBeenCalledWith(
        expect.objectContaining({
          namaResto: 'Kedai Oasis Sukses',
          tagline: 'Cita Rasa Tradisi Hangat & Halal',
        }),
      )
    })

    expect(screen.getByRole('status')).toBeDefined()
    expect(screen.getByText('Pengaturan identitas berhasil disimpan.')).toBeDefined()
  })

  it('menangani kegagalan simpan dari server (mis. konflik versi)', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Data pengaturan sudah diubah oleh pengguna lain. Silakan muat ulang halaman.',
    })

    render(<Identitas dataAwal={dataAwalUji} onSimpan={mockSimpan} />)

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledTimes(1)
    })

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/data pengaturan sudah diubah oleh pengguna lain/i)).toBeDefined()
  })

  it('memanggil onKembali saat tombol kembali diklik', () => {
    const mockKembali = vi.fn()
    render(<Identitas dataAwal={dataAwalUji} onKembali={mockKembali} />)

    const tombolKembali = screen.getByRole('button', { name: /kembali ke menu pengaturan/i })
    fireEvent.click(tombolKembali)

    expect(mockKembali).toHaveBeenCalledTimes(1)
  })

  it('mode hanyaBaca menyembunyikan tombol simpan dan menonaktifkan kolom', () => {
    render(<Identitas dataAwal={dataAwalUji} hanyaBaca />)

    expect(screen.queryByRole('button', { name: /simpan identitas resto/i })).toBeNull()
    const inputNama = screen.getByLabelText(/nama restoran/i) as HTMLInputElement
    expect(inputNama.disabled).toBe(true)
  })
})
