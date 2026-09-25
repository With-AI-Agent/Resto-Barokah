// @vitest-environment jsdom
import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { Katalog } from './Katalog'
import { PenyediaBahasa } from '../../bahasa'

const DUMMY_PENYEWA = {
  id: 'penyewa-01',
  nama: 'Resto Barokah Pusat',
  slug: 'resto-barokah',
}

const DUMMY_CABANG = {
  id: 'cabang-01',
  nama: 'Cabang Dago Heritage',
  alamat: 'Jl. Ir. H. Juanda No. 88, Bandung',
  telepon: '0812-9988-7766',
}

const DUMMY_PENGATURAN = {
  nama_resto: 'Kedai Barokah Nusantara',
  tagline: 'Sensasi Rasa Otentik Warisan Leluhur',
  tema: 'hangat',
  jam_buka: { teks: 'Senin - Minggu · 08.00 - 22.00 WIB' },
  kontak: { telepon: '0812-9988-7766', whatsapp: '6281299887766' },
  lokasi: { alamat: 'Jl. Ir. H. Juanda No. 88, Bandung', kota: 'Bandung' },
}

const DUMMY_KATEGORI = [
  { id: 'kat-1', nama: 'Makanan', urutan: 1 },
  { id: 'kat-2', nama: 'Minuman', urutan: 2 },
]

const DUMMY_MENU = [
  {
    id: 'm-1',
    kategori_id: 'kat-1',
    nama: 'Nasi Liwet Komplit',
    deskripsi: 'Nasi liwet gurih dengan ayam suwir, tempe orek, dan sambal terasi.',
    harga: 35000,
    unggulan: true,
    habis: false,
  },
  {
    id: 'm-2',
    kategori_id: 'kat-2',
    nama: 'Es Kelapa Muda',
    deskripsi: 'Air kelapa murni dingin dengan serutan daging kelapa muda.',
    harga: 15000,
    unggulan: false,
    habis: true,
  },
]

describe('Halaman Katalog Publik Per Resto (Katalog.tsx — T8-02)', () => {
  afterEach(cleanup)

  it('merender merek resto, tagline, banner, jam buka, dan kontak dari pengaturan', () => {
    const { container } = render(
      <PenyediaBahasa>
        <Katalog
          penyewa={DUMMY_PENYEWA}
          cabang={DUMMY_CABANG}
          pengaturan={DUMMY_PENGATURAN}
          kategori={DUMMY_KATEGORI}
          menu={DUMMY_MENU}
        />
      </PenyediaBahasa>,
    )

    // Memeriksa penerapan tema visual resto
    const root = container.querySelector('.katalog-publik-wrap')
    expect(root?.getAttribute('data-theme')).toBe('hangat')

    // Memeriksa nama resto & tagline
    expect(screen.getByTestId('merek-nama-resto').textContent).toContain('Kedai Barokah Nusantara')
    expect(screen.getByTestId('merek-tagline').textContent).toContain(
      'Sensasi Rasa Otentik Warisan Leluhur',
    )

    // Memeriksa jam buka & lokasi
    expect(screen.getByTestId('info-jam-buka').textContent).toContain(
      'Senin - Minggu · 08.00 - 22.00 WIB',
    )
    expect(screen.getByTestId('info-lokasi').textContent).toContain(
      'Jl. Ir. H. Juanda No. 88, Bandung',
    )
    expect(screen.getByTestId('info-telepon').textContent).toContain('0812-9988-7766')

    // Banner tampil
    expect(screen.getByTestId('banner-resto')).toBeDefined()
  })

  it('dapat membuka dan menutup dialog QR & tautan katalog untuk dibagikan', () => {
    render(
      <PenyediaBahasa>
        <Katalog
          penyewa={DUMMY_PENYEWA}
          cabang={DUMMY_CABANG}
          pengaturan={DUMMY_PENGATURAN}
          kategori={DUMMY_KATEGORI}
          menu={DUMMY_MENU}
          nomorMeja="08"
        />
      </PenyediaBahasa>,
    )

    // Menampilkan lencana nomor meja
    expect(screen.getByTestId('badge-meja').textContent).toContain('Meja 08')

    // Awalnya modal tertutup
    expect(screen.queryByTestId('modal-qr')).toBeNull()

    // Buka modal QR
    const tombolBagikan = screen.getByRole('button', {
      name: /buka kode qr dan bagikan tautan/i,
    })
    fireEvent.click(tombolBagikan)

    // Modal terbuka dengan komponen QR
    expect(screen.getByTestId('modal-qr')).toBeDefined()
    expect(screen.getByTestId('komponen-qr')).toBeDefined()

    // Tutup modal QR
    const tombolSelesai = screen.getByRole('button', { name: /selesai/i })
    fireEvent.click(tombolSelesai)
    expect(screen.queryByTestId('modal-qr')).toBeNull()
  })

  it('melakukan pencarian menu secara langsung (real-time filtering)', () => {
    render(
      <PenyediaBahasa>
        <Katalog
          penyewa={DUMMY_PENYEWA}
          cabang={DUMMY_CABANG}
          pengaturan={DUMMY_PENGATURAN}
          kategori={DUMMY_KATEGORI}
          menu={DUMMY_MENU}
        />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Nasi Liwet Komplit')).toBeDefined()
    expect(screen.getByText('Es Kelapa Muda')).toBeDefined()

    // Ketik pencarian "Liwet"
    const inputCari = screen.getByTestId('input-cari-menu')
    fireEvent.change(inputCari, { target: { value: 'Liwet' } })

    expect(screen.getByText('Nasi Liwet Komplit')).toBeDefined()
    expect(screen.queryByText('Es Kelapa Muda')).toBeNull()

    // Cari menu yang tidak ada
    fireEvent.change(inputCari, { target: { value: 'Steak Wagyu' } })
    expect(screen.getByTestId('menu-kosong')).toBeDefined()
    expect(screen.getByText(/Tidak Ada Menu yang Sesuai/i)).toBeDefined()
  })

  it('menampilkan penanda HABIS dengan jelas pada item menu yang stoknya habis', () => {
    render(
      <PenyediaBahasa>
        <Katalog
          penyewa={DUMMY_PENYEWA}
          cabang={DUMMY_CABANG}
          pengaturan={DUMMY_PENGATURAN}
          kategori={DUMMY_KATEGORI}
          menu={DUMMY_MENU}
        />
      </PenyediaBahasa>,
    )

    const lencanaHabis = screen.getByTestId('indikator-habis')
    expect(lencanaHabis).toBeDefined()
    expect(lencanaHabis.textContent).toBe('HABIS')
  })
})
