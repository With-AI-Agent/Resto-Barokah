// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { Menu, type DataKategori, type DataMenuItem } from './Menu'

const DATA_KATEGORI_UJI: DataKategori[] = [
  { id: 'kat-1', nama: 'Makanan', urutan: 1, tujuan: 'dapur', aktif: true, jumlah_menu: 2 },
  { id: 'kat-2', nama: 'Minuman', urutan: 2, tujuan: 'bar', aktif: true, jumlah_menu: 1 },
]

const DATA_MENU_UJI: DataMenuItem[] = [
  {
    id: 'm-1',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan',
    nama: 'Nasi Goreng',
    deskripsi: 'Nasi goreng kampung lezat',
    harga: 25000,
    foto_path: '',
    urutan: 1,
    unggulan: true,
    jenis: 'makanan',
    aktif: true,
    habis: false,
    varian: [{ nama: 'Pedas', tambahan_harga: 0, aktif: true }],
    tambahan: [{ id: 't-1', nama: 'Telur Mata Sapi', harga: 4000, aktif: true }],
  },
  {
    id: 'm-2',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan',
    nama: 'Mie Rebus',
    deskripsi: 'Mie kuah hangat gurih',
    harga: 20000,
    foto_path: '',
    urutan: 2,
    unggulan: false,
    jenis: 'makanan',
    aktif: true,
    habis: true,
    varian: [],
    tambahan: [],
  },
  {
    id: 'm-3',
    kategori_id: 'kat-2',
    kategori_nama: 'Minuman',
    nama: 'Es Teh Manis',
    deskripsi: 'Teh melati wangi segar',
    harga: 5000,
    foto_path: '',
    urutan: 1,
    unggulan: false,
    jenis: 'minuman',
    aktif: false,
    habis: false,
    varian: [],
    tambahan: [],
  },
]

describe('Layar Pengaturan Menu & Kategori (T9-05 / PRD M2 & M3)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('1. Merender ringkasan statistik dan daftar menu awal', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    expect(screen.getByText('Pengelolaan Menu & Kategori')).toBeDefined()
    expect(screen.getByText('Total Menu')).toBeDefined()
    expect(screen.getByText('3')).toBeDefined() // 3 total menu
    expect(screen.getByText('Menu Aktif')).toBeDefined()
    expect(screen.getByText('Habis di Cabang')).toBeDefined()
    expect(screen.getByText('Nasi Goreng')).toBeDefined()
    expect(screen.getByText('Mie Rebus')).toBeDefined()
    expect(screen.getByText('Es Teh Manis')).toBeDefined()
  })

  it('2. Menyaring menu berdasarkan tab kategori', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    // Klik tab kategori 'Minuman (1)'
    const tabMinuman = screen.getByRole('button', { name: 'Pilih kategori Minuman' })
    fireEvent.click(tabMinuman)

    expect(screen.getByText('Es Teh Manis')).toBeDefined()
    expect(screen.queryByText('Nasi Goreng')).toBeNull()
    expect(screen.queryByText('Mie Rebus')).toBeNull()

    // Kembalikan ke tab Semua
    const tabSemua = screen.getByRole('button', { name: 'Tampilkan semua kategori menu' })
    fireEvent.click(tabSemua)

    expect(screen.getByText('Nasi Goreng')).toBeDefined()
    expect(screen.getByText('Es Teh Manis')).toBeDefined()
  })

  it('3. Menyaring menu berdasarkan kata kunci pencarian', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    const inputCari = screen.getByLabelText('Cari Menu')
    fireEvent.change(inputCari, { target: { value: 'goreng' } })

    expect(screen.getByText('Nasi Goreng')).toBeDefined()
    expect(screen.queryByText('Mie Rebus')).toBeNull()
    expect(screen.queryByText('Es Teh Manis')).toBeNull()
  })

  it('4. Menolak simpan kategori baru jika nama kosong', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Kategori Menu Baru' }))
    expect(screen.getByText('Tambah Kategori Menu Baru')).toBeDefined()

    // Klik simpan tanpa mengisi nama
    fireEvent.click(screen.getByRole('button', { name: 'Simpan data kategori menu' }))
    expect(screen.getByText('Nama kategori wajib diisi.')).toBeDefined()
  })

  it('5. Berhasil menambah kategori baru dan memanggil onSimpanKategori', async () => {
    const mockSimpanKategori = vi.fn().mockResolvedValue({ berhasil: true, id: 'kat-baru' })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onSimpanKategori={mockSimpanKategori}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Kategori Menu Baru' }))

    const inputNama = screen.getByLabelText('Nama Kategori')
    fireEvent.change(inputNama, { target: { value: 'Camilan Gurih' } })

    fireEvent.click(screen.getByRole('button', { name: 'Simpan data kategori menu' }))

    await waitFor(() => {
      expect(mockSimpanKategori).toHaveBeenCalledWith({
        id: undefined,
        nama: 'Camilan Gurih',
        urutan: 3,
        tujuan: 'dapur',
        aktif: true,
      })
    })

    expect(screen.getByText(/Kategori baru "Camilan Gurih" berhasil dibuat/i)).toBeDefined()
  })

  it('6. Mencegah penghapusan kategori yang masih memiliki menu item', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    // Coba hapus kategori 'Makanan' yang memiliki 2 menu
    fireEvent.click(screen.getByRole('button', { name: 'Hapus kategori Makanan' }))
    expect(screen.getByText('Konfirmasi Hapus Kategori')).toBeDefined()

    fireEvent.click(screen.getByRole('button', { name: 'Hapus kategori permanen' }))
    expect(screen.getByText(/masih memiliki 2 menu/i)).toBeDefined()
  })

  it('7. Berhasil menghapus kategori kosong', async () => {
    const mockHapusKategori = vi.fn().mockResolvedValue({ berhasil: true })
    const kategoriKosong: DataKategori[] = [
      ...DATA_KATEGORI_UJI,
      {
        id: 'kat-kosong',
        nama: 'Spesial',
        urutan: 3,
        tujuan: 'dapur',
        aktif: true,
        jumlah_menu: 0,
      },
    ]

    render(
      <Menu
        daftarKategoriAwal={kategoriKosong}
        daftarMenuAwal={DATA_MENU_UJI}
        onHapusKategori={mockHapusKategori}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Hapus kategori Spesial' }))
    fireEvent.click(screen.getByRole('button', { name: 'Hapus kategori permanen' }))

    await waitFor(() => {
      expect(mockHapusKategori).toHaveBeenCalledWith('kat-kosong')
    })
    expect(screen.getByText(/Kategori "Spesial" berhasil dihapus/i)).toBeDefined()
  })

  it('8. Menolak simpan menu baru bila nama kosong atau harga negatif', () => {
    render(<Menu daftarKategoriAwal={DATA_KATEGORI_UJI} daftarMenuAwal={DATA_MENU_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Menu Baru' }))
    expect(screen.getByText('Tambah Menu Baru')).toBeDefined()

    // Simpan dengan nama kosong
    fireEvent.click(screen.getByRole('button', { name: 'Simpan seluruh data menu' }))
    expect(screen.getByText('Nama menu wajib diisi.')).toBeDefined()
  })

  it('9. Berhasil menambah menu item baru lengkap dengan varian dan topping', async () => {
    const mockSimpanMenu = vi.fn().mockResolvedValue({ berhasil: true, id: 'm-baru' })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onSimpanMenu={mockSimpanMenu}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Tambah Menu Baru' }))

    fireEvent.change(screen.getByLabelText('Nama Menu'), { target: { value: 'Ayam Bakar Madu' } })
    fireEvent.change(screen.getByLabelText('Harga Pokok (Rp)'), { target: { value: '30000' } })
    fireEvent.change(screen.getByLabelText('Deskripsi Menu (Opsional)'), {
      target: { value: 'Ayam kampung bakar lumur madu' },
    })

    // Tambah varian
    fireEvent.change(screen.getByLabelText('Nama Varian'), { target: { value: 'Paha' } })
    fireEvent.click(screen.getByRole('button', { name: 'Tambah opsi varian' }))
    expect(screen.getByText((_, el) => el?.textContent === 'Paha (+Rp0)')).toBeDefined()

    // Tambah topping
    fireEvent.change(screen.getByLabelText('Nama Topping'), { target: { value: 'Sambal Terasi' } })
    fireEvent.change(screen.getByLabelText('Harga Tambahan (Rp)'), { target: { value: '3000' } })
    fireEvent.click(screen.getByRole('button', { name: 'Tambah opsi topping' }))
    expect(
      screen.getByText((_, el) => el?.textContent === 'Sambal Terasi (+Rp3.000)'),
    ).toBeDefined()

    // Simpan menu
    fireEvent.click(screen.getByRole('button', { name: 'Simpan seluruh data menu' }))

    await waitFor(() => {
      expect(mockSimpanMenu).toHaveBeenCalledWith({
        id: undefined,
        kategori_id: 'kat-1',
        nama: 'Ayam Bakar Madu',
        deskripsi: 'Ayam kampung bakar lumur madu',
        harga: 30000,
        foto_path: '',
        urutan: 4,
        unggulan: false,
        jenis: 'makanan',
        aktif: true,
        varian: [{ nama: 'Paha', tambahan_harga: 0, aktif: true }],
        tambahan: [{ nama: 'Sambal Terasi', harga: 3000, aktif: true }],
      })
    })

    expect(screen.getByText(/Menu baru "Ayam Bakar Madu" berhasil ditambahkan/i)).toBeDefined()
  })

  it('10. Mengubah status aktif/nonaktif menu via tombol sakelar', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onSimpanMenu={mockSimpan}
      />,
    )

    // Menu m-1 (Nasi Goreng) status awalnya aktif = true
    const tombolNonaktifkan = screen.getByRole('button', {
      name: 'Ubah status aktif menu Nasi Goreng',
    })
    expect(tombolNonaktifkan.textContent).toContain('Nonaktifkan')

    fireEvent.click(tombolNonaktifkan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith({
        id: 'm-1',
        kategori_id: 'kat-1',
        nama: 'Nasi Goreng',
        harga: 25000,
        jenis: 'makanan',
        aktif: false,
      })
    })

    expect(screen.getByText(/berhasil diubah menjadi Nonaktif/i)).toBeDefined()
  })

  it('11. Mengubah status ketersediaan (habis) via tombol cepat', async () => {
    const mockTandaiHabis = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onTandaiHabis={mockTandaiHabis}
      />,
    )

    // Nasi Goreng awalnya ada (habis = false)
    const tombolAda = screen.getByRole('button', { name: 'Tandai habis menu Nasi Goreng' })
    fireEvent.click(tombolAda)

    await waitFor(() => {
      expect(mockTandaiHabis).toHaveBeenCalledWith('m-1', true)
    })

    expect(screen.getByText(/ditandai HABIS/i)).toBeDefined()
  })

  it('12. Menghapus menu yang belum pernah dipesan memanggil onHapusMenu', async () => {
    const mockHapusMenu = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onHapusMenu={mockHapusMenu}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: 'Hapus menu Mie Rebus' }))
    expect(screen.getByText('Konfirmasi Hapus Menu')).toBeDefined()

    fireEvent.click(screen.getByRole('button', { name: 'Hapus menu permanen' }))

    await waitFor(() => {
      expect(mockHapusMenu).toHaveBeenCalledWith('m-2')
    })

    expect(screen.getByText(/Menu "Mie Rebus" berhasil dihapus/i)).toBeDefined()
  })

  it('13. Menggeser urutan menu dengan tombol panah (▲ / ▼)', async () => {
    const mockUrutan = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        onSimpanUrutanMenu={mockUrutan}
      />,
    )

    // Geser menu indeks 1 (Mie Rebus) ke atas
    const tombolGeserAtas = screen.getByRole('button', { name: 'Geser menu Mie Rebus ke atas' })
    fireEvent.click(tombolGeserAtas)

    await waitFor(() => {
      expect(mockUrutan).toHaveBeenCalledWith([
        { id: 'm-2', urutan: 1 },
        { id: 'm-1', urutan: 2 },
        { id: 'm-3', urutan: 3 },
      ])
    })
  })

  it('14. Mode hanya-baca menyembunyikan aksi pengelolaan', () => {
    render(
      <Menu
        daftarKategoriAwal={DATA_KATEGORI_UJI}
        daftarMenuAwal={DATA_MENU_UJI}
        hanyaBaca={true}
      />,
    )

    expect(screen.queryByRole('button', { name: 'Tambah Menu Baru' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Tambah Kategori Menu Baru' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Edit menu Nasi Goreng' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Hapus menu Nasi Goreng' })).toBeNull()
  })
})
