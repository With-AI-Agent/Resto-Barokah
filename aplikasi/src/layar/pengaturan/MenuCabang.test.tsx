// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { MenuCabang, type ItemCabang, type MenuItemPerbandingan } from './MenuCabang'

const DATA_CABANG_UJI: ItemCabang[] = [
  { id: 'cab-1', nama: 'Cabang Pusat', alamat: 'Jl. Merdeka 1', aktif: true },
  { id: 'cab-2', nama: 'Cabang Dago', alamat: 'Jl. Dago 10', aktif: true },
]

const DATA_MENU_UJI: MenuItemPerbandingan[] = [
  {
    id: 'm-1',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan',
    nama: 'Nasi Goreng Spesial',
    harga_pusat: 25000,
    aktif_pusat: true,
    foto_path: '',
    urutan: 1,
    cabang: [
      {
        cabang_id: 'cab-1',
        cabang_nama: 'Cabang Pusat',
        harga_khusus: null,
        harga_efektif: 25000,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      },
      {
        cabang_id: 'cab-2',
        cabang_nama: 'Cabang Dago',
        harga_khusus: 28000,
        harga_efektif: 28000,
        beda_harga: true,
        aktif_cabang: true,
        habis_cabang: false,
      },
    ],
  },
  {
    id: 'm-2',
    kategori_id: 'kat-2',
    kategori_nama: 'Minuman',
    nama: 'Es Teh Manis',
    harga_pusat: 6000,
    aktif_pusat: true,
    foto_path: '',
    urutan: 2,
    cabang: [
      {
        cabang_id: 'cab-1',
        cabang_nama: 'Cabang Pusat',
        harga_khusus: null,
        harga_efektif: 6000,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      },
      {
        cabang_id: 'cab-2',
        cabang_nama: 'Cabang Dago',
        harga_khusus: null,
        harga_efektif: 6000,
        beda_harga: false,
        aktif_cabang: false, // Disembunyikan di Dago
        habis_cabang: false,
      },
    ],
  },
]

describe('Layar Pengaturan Menu Cabang (T9-06 / PRD M11)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('1. Merender halaman, kartu ringkasan statistik, dan daftar menu cabang', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
      />,
    )

    expect(screen.getByText('Harga & Ketersediaan Menu Per Cabang')).toBeDefined()
    expect(screen.getByText('Total Menu Resto')).toBeDefined()
    expect(screen.getByText('2')).toBeDefined() // 2 total menu
    expect(screen.getByText('Nasi Goreng Spesial')).toBeDefined()
    expect(screen.getByText('Es Teh Manis')).toBeDefined()
  })

  it('2. Mengganti cabang aktif melalui pemilih cabang', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
      />,
    )

    const selectCabang = screen.getByLabelText('Pilih Cabang:')
    fireEvent.change(selectCabang, { target: { value: 'cab-2' } })

    // Di Cabang Dago, Nasi Goreng memiliki badge 'Harga Khusus' dan Es Teh memiliki badge 'Sembunyi di Cabang'
    expect(screen.getByText('Harga Khusus')).toBeDefined()
    expect(screen.getByText('Sembunyi di Cabang')).toBeDefined()
  })

  it('3. Menyaring menu berdasarkan kata kunci pencarian', () => {
    render(<MenuCabang daftarCabangAwal={DATA_CABANG_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    const inputCari = screen.getByLabelText('Cari Menu')
    fireEvent.change(inputCari, { target: { value: 'teh' } })

    expect(screen.getByText('Es Teh Manis')).toBeDefined()
    expect(screen.queryByText('Nasi Goreng Spesial')).toBeNull()
  })

  it('4. Mengubah harga khusus cabang dan memunculkan badge selisih harga', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
      />,
    )

    const inputHarga = screen.getByLabelText('Harga khusus cabang untuk Nasi Goreng Spesial')
    fireEvent.change(inputHarga, { target: { value: '30000' } })

    // Selisih 30.000 - 25.000 = +Rp5.000
    expect(screen.getByText('+Rp5.000')).toBeDefined()
  })

  it('5. Mengembalikan harga ke harga pusat via tombol "Ikut Pusat"', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-2" // Di Dago harga khusus 28000
      />,
    )

    const tombolIkutPusat = screen.getByRole('button', {
      name: 'Gunakan harga pusat untuk Nasi Goreng Spesial',
    })
    fireEvent.click(tombolIkutPusat)

    const inputHarga = screen.getByLabelText(
      'Harga khusus cabang untuk Nasi Goreng Spesial',
    ) as HTMLInputElement
    expect(inputHarga.value).toBe('')
  })

  it('6. Mengubah status tampil/sembunyi di cabang via tombol sakelar', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
      />,
    )

    const tombolTampil = screen.getByRole('button', {
      name: 'Ubah status tampil menu Nasi Goreng Spesial di cabang',
    })
    expect(tombolTampil.textContent).toContain('Tampil')

    fireEvent.click(tombolTampil)
    expect(tombolTampil.textContent).toContain('Sembunyi')
  })

  it('7. Mengubah status habis di cabang via tombol sakelar', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
      />,
    )

    const tombolHabis = screen.getByRole('button', {
      name: 'Tandai status habis menu Nasi Goreng Spesial di cabang',
    })
    expect(tombolHabis.textContent).toContain('Ada')

    fireEvent.click(tombolHabis)
    expect(tombolHabis.textContent).toContain('Habis')
  })

  it('8. Menyimpan pengaturan satu menu cabang memanggil onSimpanMenuCabang', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
        onSimpanMenuCabang={mockSimpan}
      />,
    )

    const inputHarga = screen.getByLabelText('Harga khusus cabang untuk Nasi Goreng Spesial')
    fireEvent.change(inputHarga, { target: { value: '29000' } })

    const tombolSimpan = screen.getByRole('button', {
      name: 'Simpan pengaturan cabang untuk Nasi Goreng Spesial',
    })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith({
        cabang_id: 'cab-1',
        menu_item_id: 'm-1',
        harga: 29000,
        aktif: true,
        habis: false,
      })
    })

    expect(screen.getByText(/berhasil disimpan/i)).toBeDefined()
  })

  it('9. Menyimpan seluruh perubahan cabang memanggil onSimpanBanyakMenuCabang', async () => {
    const mockSimpanBanyak = vi.fn().mockResolvedValue({ berhasil: true, jumlah: 1 })
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
        onSimpanBanyakMenuCabang={mockSimpanBanyak}
      />,
    )

    // Ubah harga menu m-1
    const inputHarga = screen.getByLabelText('Harga khusus cabang untuk Nasi Goreng Spesial')
    fireEvent.change(inputHarga, { target: { value: '31000' } })

    // Klik tombol simpan semua
    const tombolSimpanSemua = screen.getByRole('button', {
      name: 'Simpan seluruh perubahan menu cabang',
    })
    fireEvent.click(tombolSimpanSemua)

    await waitFor(() => {
      expect(mockSimpanBanyak).toHaveBeenCalledWith('cab-1', [
        {
          menu_item_id: 'm-1',
          harga: 31000,
          aktif: true,
          habis: false,
        },
      ])
    })

    expect(screen.getByText(/Berhasil menyimpan 1 perubahan menu/i)).toBeDefined()
  })

  it('10. Berpindah ke mode Tabel Perbandingan Multi-Cabang', () => {
    render(<MenuCabang daftarCabangAwal={DATA_CABANG_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    const tombolModeTabel = screen.getByRole('button', {
      name: 'Buka mode tabel perbandingan multi-cabang',
    })
    fireEvent.click(tombolModeTabel)

    // Tabel menampilkan kolom untuk setiap cabang
    expect(screen.getByText('Harga Pusat')).toBeDefined()
    expect(screen.getAllByText('Cabang Pusat').length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('Cabang Dago').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('Rp28.000 (Khusus)')).toBeDefined()
  })

  it('11. Menjalankan alur salin konfigurasi antar cabang via modal', async () => {
    const mockSalin = vi.fn().mockResolvedValue({ berhasil: true, jumlah: 2 })
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-1"
        onSalinHargaCabang={mockSalin}
      />,
    )

    fireEvent.click(
      screen.getByRole('button', { name: 'Buka modal salin konfigurasi antar cabang' }),
    )
    expect(screen.getByText('Salin Pengaturan Menu Antar Cabang')).toBeDefined()

    fireEvent.change(screen.getByLabelText('Cabang Asal:'), { target: { value: 'cab-1' } })
    fireEvent.change(screen.getByLabelText('Cabang Tujuan:'), { target: { value: 'cab-2' } })

    fireEvent.click(screen.getByRole('button', { name: 'Konfirmasi salin konfigurasi cabang' }))

    await waitFor(() => {
      expect(mockSalin).toHaveBeenCalledWith('cab-1', 'cab-2')
    })

    expect(screen.getByText(/berhasil disalin/i)).toBeDefined()
  })

  it('12. Menjalankan alur reset seluruh harga cabang ke harga pusat', async () => {
    const mockReset = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        cabangTerpilihAwal="cab-2"
        onResetHargaCabang={mockReset}
      />,
    )

    fireEvent.click(
      screen.getByRole('button', { name: 'Reset seluruh harga cabang ke harga pusat' }),
    )
    expect(screen.getByText('Reset Harga ke Harga Pusat')).toBeDefined()

    fireEvent.click(screen.getByRole('button', { name: 'Konfirmasi reset harga cabang' }))

    await waitFor(() => {
      expect(mockReset).toHaveBeenCalledWith('cab-2')
    })

    expect(screen.getByText(/berhasil dikembalikan ke harga pusat/i)).toBeDefined()
  })

  it('13. Mode hanya-baca menyembunyikan tombol aksi dan menonaktifkan input', () => {
    render(
      <MenuCabang
        daftarCabangAwal={DATA_CABANG_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        hanyaBaca={true}
      />,
    )

    expect(
      screen.queryByRole('button', { name: 'Buka modal salin konfigurasi antar cabang' }),
    ).toBeNull()
    expect(
      screen.queryByRole('button', { name: 'Reset seluruh harga cabang ke harga pusat' }),
    ).toBeNull()

    const inputHarga = screen.getByLabelText(
      'Harga khusus cabang untuk Nasi Goreng Spesial',
    ) as HTMLInputElement
    expect(inputHarga.disabled).toBe(true)
  })
})
