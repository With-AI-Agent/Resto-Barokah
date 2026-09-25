// @vitest-environment jsdom
import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Menu, type MenuItemPublik, type KategoriPublik } from './Menu'

const DUMMY_KATEGORI: KategoriPublik[] = [
  { id: 'kat-1', nama: 'Makanan Utama', urutan: 1 },
  { id: 'kat-2', nama: 'Minuman Segar', urutan: 2 },
  { id: 'kat-3', nama: 'Camilan', urutan: 3 },
]

const DUMMY_MENU: MenuItemPublik[] = [
  {
    id: 'm-01',
    kategori_id: 'kat-1',
    nama: 'Nasi Liwet Komplit Barokah',
    deskripsi: 'Nasi liwet gurih rempah dengan suwiran ayam bakar, tempe orek, dan sambal terasi.',
    harga: 35000,
    foto_path: 'https://contoh.com/liwet.webp',
    unggulan: true,
    jenis: 'makanan',
    habis: false,
    varian: [
      { nama: 'Porsi Standar', tambahan_harga: 0 },
      { nama: 'Porsi Jumbo', tambahan_harga: 8000 },
    ],
    tambahan: [
      { id: 't-1', nama: 'Telur Mata Sapi', harga: 4000 },
      { id: 't-2', nama: 'Ayam Goreng Ekstra', harga: 12000 },
    ],
  },
  {
    id: 'm-02',
    kategori_id: 'kat-2',
    nama: 'Es Kelapa Muda Jeruk',
    deskripsi: 'Air kelapa murni segar dengan perasan jeruk nipis dan serutan kelapa lembut.',
    harga: 16000,
    unggulan: false,
    jenis: 'minuman',
    habis: true,
    varian: [
      { nama: 'Dingin', tambahan_harga: 0 },
      { nama: 'Kurang Gula', tambahan_harga: 0 },
    ],
    tambahan: [{ id: 't-3', nama: 'Biji Selasih', harga: 2000 }],
  },
  {
    id: 'm-03',
    kategori_id: 'kat-3',
    nama: 'Tahu Cabe Garam Krispi',
    deskripsi: 'Tahu sutra dipotong dadu digoreng garing renyah dengan tumisan bawang cabai.',
    harga: 18000,
    unggulan: true,
    jenis: 'makanan',
    habis: false,
  },
]

describe('Komponen Menu Publik (Menu.tsx — T8-03)', () => {
  afterEach(cleanup)

  it('merender daftar kategori dan menghitung jumlah item per kategori', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    // Tab Semua harus memuat 3 item
    expect(screen.getByRole('button', { name: /kategori semua/i }).textContent).toContain(
      'Semua (3)',
    )
    // Kategori Makanan Utama 1 item
    expect(screen.getByRole('button', { name: /kategori makanan utama/i }).textContent).toContain(
      'Makanan Utama (1)',
    )
    // Kategori Minuman Segar 1 item
    expect(screen.getByRole('button', { name: /kategori minuman segar/i }).textContent).toContain(
      'Minuman Segar (1)',
    )
    // Kategori Camilan 1 item
    expect(screen.getByRole('button', { name: /kategori camilan/i }).textContent).toContain(
      'Camilan (1)',
    )
  })

  it('merender foto, nama, deskripsi, dan format rupiah pada item menu', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    expect(screen.getByText('Nasi Liwet Komplit Barokah')).toBeDefined()
    expect(
      screen.getByText(
        'Nasi liwet gurih rempah dengan suwiran ayam bakar, tempe orek, dan sambal terasi.',
      ),
    ).toBeDefined()
    expect(screen.getByTestId('harga-m-01').textContent).toBe('Rp35.000')

    // Item tanpa foto menampilkan placeholder ramah
    const kartuCamilan = screen.getByTestId('kartu-menu-m-03')
    expect(kartuCamilan).toBeDefined()
    expect(kartuCamilan.textContent).toContain('Tahu Cabe Garam Krispi')
    expect(kartuCamilan.textContent).toContain('Rp18.000')
  })

  it('menampilkan penanda HABIS dengan overlay tertutup dan keterangan jelas pada item habis', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    // Item m-02 berstatus habis
    const overlayHabis = screen.getByTestId('overlay-habis-m-02')
    expect(overlayHabis).toBeDefined()
    expect(overlayHabis.textContent).toContain('HABIS')
    expect(overlayHabis.textContent).toContain('Stok Habis di Cabang Ini')

    const kartuMenuHabis = screen.getByTestId('kartu-menu-m-02')
    expect(kartuMenuHabis).toBeDefined()
  })

  it('dapat menyembunyikan dan menampilkan kembali menu habis lewat sakelar filter', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    // Awalnya item habis tampil tertutup
    expect(screen.getByText('Es Kelapa Muda Jeruk')).toBeDefined()

    // Klik tombol sakelar untuk menyembunyikan item habis
    const tombolToggleHabis = screen.getByRole('button', { name: /filter menu habis/i })
    fireEvent.click(tombolToggleHabis)

    // Item habis kini tidak tampil
    expect(screen.queryByText('Es Kelapa Muda Jeruk')).toBeNull()
    expect(screen.getByText('Nasi Liwet Komplit Barokah')).toBeDefined()
    expect(screen.getByText('Tahu Cabe Garam Krispi')).toBeDefined()

    // Klik kembali untuk menampilkan semua menu
    fireEvent.click(tombolToggleHabis)
    expect(screen.getByText('Es Kelapa Muda Jeruk')).toBeDefined()
  })

  it('membuka modal rincian menu dengan varian, tambahan, dan simulasi kalkulasi harga interaktif', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    // Klik tombol Lihat Detail pada Nasi Liwet
    const tombolDetail = screen.getByRole('button', {
      name: /rincian nasi liwet komplit barokah/i,
    })
    fireEvent.click(tombolDetail)

    // Modal rincian terbuka
    expect(screen.getByTestId('konten-modal-rincian')).toBeDefined()
    expect(screen.getByText('Pilihan Varian / Rasa:')).toBeDefined()
    expect(screen.getByText('Tambahan / Topping (Opsional):')).toBeDefined()

    // Harga awal: Rp35.000 (varian default Porsi Standar +Rp 0)
    expect(screen.getByTestId('total-rincian-simulasi').textContent).toBe('Rp35.000')

    // Pilih varian Porsi Jumbo (+Rp 8.000)
    const tombolJumbo = screen.getByRole('button', { name: /pilih varian porsi jumbo/i })
    fireEvent.click(tombolJumbo)
    // 35.000 + 8.000 = Rp43.000
    expect(screen.getByTestId('total-rincian-simulasi').textContent).toBe('Rp43.000')

    // Tambah topping Telur Mata Sapi (+Rp 4.000)
    const tombolTelur = screen.getByRole('button', { name: /pilih tambahan telur mata sapi/i })
    fireEvent.click(tombolTelur)
    // 43.000 + 4.000 = Rp47.000
    expect(screen.getByTestId('total-rincian-simulasi').textContent).toBe('Rp47.000')

    // Tambah topping Ayam Goreng Ekstra (+Rp 12.000)
    const tombolAyam = screen.getByRole('button', { name: /pilih tambahan ayam goreng ekstra/i })
    fireEvent.click(tombolAyam)
    // 47.000 + 12.000 = Rp59.000
    expect(screen.getByTestId('total-rincian-simulasi').textContent).toBe('Rp59.000')

    // Batalkan topping Telur Mata Sapi
    fireEvent.click(tombolTelur)
    // 59.000 - 4.000 = Rp55.000
    expect(screen.getByTestId('total-rincian-simulasi').textContent).toBe('Rp55.000')

    // Tutup modal
    const tombolTutup = screen.getByRole('button', { name: /tutup rincian menu/i })
    fireEvent.click(tombolTutup)
    expect(screen.queryByTestId('konten-modal-rincian')).toBeNull()
  })

  it('melakukan penyaringan berdasarkan tab kategori dan pencarian kata kunci', () => {
    render(<Menu kategori={DUMMY_KATEGORI} menu={DUMMY_MENU} />)

    // Klik kategori Minuman Segar
    const tabMinuman = screen.getByRole('button', { name: /kategori minuman segar/i })
    fireEvent.click(tabMinuman)

    expect(screen.getByText('Es Kelapa Muda Jeruk')).toBeDefined()
    expect(screen.queryByText('Nasi Liwet Komplit Barokah')).toBeNull()
    expect(screen.queryByText('Tahu Cabe Garam Krispi')).toBeNull()

    // Kembali ke semua kategori
    const tabSemua = screen.getByRole('button', { name: /kategori semua/i })
    fireEvent.click(tabSemua)

    expect(screen.getByText('Nasi Liwet Komplit Barokah')).toBeDefined()
    expect(screen.getByText('Es Kelapa Muda Jeruk')).toBeDefined()
    expect(screen.getByText('Tahu Cabe Garam Krispi')).toBeDefined()

    // Cari kata kunci "Tahu"
    const inputCari = screen.getByRole('searchbox', { name: /cari menu/i })
    fireEvent.change(inputCari, { target: { value: 'Tahu' } })

    expect(screen.getByText('Tahu Cabe Garam Krispi')).toBeDefined()
    expect(screen.queryByText('Nasi Liwet Komplit Barokah')).toBeNull()
    expect(screen.queryByText('Es Kelapa Muda Jeruk')).toBeNull()

    // Cari kata kunci yang tidak ada
    fireEvent.change(inputCari, { target: { value: 'Pizza Keju' } })
    expect(screen.getByTestId('menu-kosong')).toBeDefined()
  })
})
