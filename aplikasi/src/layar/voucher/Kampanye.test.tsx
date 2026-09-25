// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { Kampanye } from './Kampanye'

describe('Komponen Layar Kampanye Undangan & Voucher (Kampanye.tsx — T8-06)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    window.open = vi.fn()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
  })

  afterEach(() => {
    cleanup()
  })

  it('merender judul promo, nama resto, nilai potongan, dan syarat belanja', () => {
    render(<Kampanye />)

    expect(screen.getByText('Promo Sambut Sahabat Baru')).toBeDefined()
    expect(screen.getByTestId('nilai-voucher-promo').textContent).toContain('Potongan Rp20.000')
    expect(screen.getByText(/Min. belanja Rp50.000/i)).toBeDefined()
    expect(screen.getByText(/48 dari 100 voucher/i)).toBeDefined()
    expect(screen.getByText('Syarat & Ketentuan Penggunaan Voucher')).toBeDefined()
  })

  it('menampilkan banner pengundang eksklusif jika ada parameter nama_pengundang', () => {
    render(
      <Kampanye
        kampanye={{
          id: 'k-spesial',
          nama: 'Traktiran Sahabat Barokah',
          jenis: 'nominal',
          nilai: 25000,
          min_belanja: 60000,
          selesai: '2026-11-01T00:00:00Z',
          nama_pengundang: 'Dimas Wicaksono',
        }}
      />,
    )

    const bannerPengundang = screen.getByTestId('banner-pengundang')
    expect(bannerPengundang).toBeDefined()
    expect(bannerPengundang.textContent).toContain('Dimas Wicaksono')
  })

  it('membuka modal pendaftaran saat tombol Daftar & Klaim diklik', () => {
    render(<Kampanye />)

    const tombolKlaim = screen.getByRole('button', {
      name: /daftar dan klaim voucher diskon sekarang/i,
    })
    fireEvent.click(tombolKlaim)

    expect(screen.getByTestId('form-daftar-voucher')).toBeDefined()
    expect(screen.getByText(/Klaim Voucher: Promo Sambut Sahabat Baru/i)).toBeDefined()
  })

  it('memanggil onBukaKatalog saat tombol Intip Menu Lezat diklik', () => {
    const mockKatalog = vi.fn()
    render(<Kampanye onBukaKatalog={mockKatalog} />)

    const tombolMenu = screen.getByRole('button', {
      name: /lihat daftar menu resto di katalog/i,
    })
    fireEvent.click(tombolMenu)

    expect(mockKatalog).toHaveBeenCalledTimes(1)
  })

  it('mendukung pembagian tautan kampanye ke WhatsApp dan salin ke clipboard', async () => {
    render(<Kampanye />)

    const tombolWa = screen.getByRole('button', { name: /bagikan promo kampanye via whatsapp/i })
    fireEvent.click(tombolWa)
    expect(window.open).toHaveBeenCalledWith(
      expect.stringContaining('api.whatsapp.com/send?text='),
      '_blank',
    )

    const tombolSalin = screen.getByRole('button', { name: /salin tautan kampanye undangan/i })
    fireEvent.click(tombolSalin)

    await waitFor(() => {
      expect(navigator.clipboard.writeText).toHaveBeenCalled()
      expect(screen.getByText('✓ Tautan Tersalin!')).toBeDefined()
    })
  })
})
