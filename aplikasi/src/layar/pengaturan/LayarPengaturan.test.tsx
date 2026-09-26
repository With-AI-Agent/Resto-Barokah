// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { LayarPengaturan } from './LayarPengaturan'

describe('LayarPengaturan (Induk Pengaturan Restoran — PRD M2 / Fase 9)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('merender bilah tab navigasi dan menampilkan tab identitas sebagai default', () => {
    render(<LayarPengaturan />)

    expect(screen.getByRole('tablist')).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan identitas/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan tema/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan perangkat/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan printer/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan tautan/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan kampanye/i })).toBeDefined()

    // Default menampilkan formulir identitas
    expect(screen.getByTestId('layar-identitas')).toBeDefined()
    expect(screen.getByText('Identitas & Tampilan Restoran')).toBeDefined()
  })

  it('dapat berpindah ke tab Tema & Tampilan', () => {
    render(<LayarPengaturan />)

    const tabTema = screen.getByRole('button', { name: /buka tab pengaturan tema/i })
    fireEvent.click(tabTema)

    expect(screen.getByTestId('layar-tampilan')).toBeDefined()
    expect(screen.getByText(/Tema & Warna Merek Restoran/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Perangkat POS', () => {
    render(<LayarPengaturan />)

    const tabPerangkat = screen.getByRole('button', { name: /buka tab pengaturan perangkat/i })
    fireEvent.click(tabPerangkat)

    expect(screen.getByText(/Daftar Perangkat & Sesi Kasir/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Printer Struk', () => {
    render(<LayarPengaturan />)

    const tabPrinter = screen.getByRole('button', { name: /buka tab pengaturan printer/i })
    fireEvent.click(tabPrinter)

    expect(screen.getByRole('button', { name: /simpan pengaturan printer/i })).toBeDefined()
  })

  it('dapat berpindah ke tab Tautan & QR Meja', () => {
    render(<LayarPengaturan />)

    const tabTautan = screen.getByRole('button', { name: /buka tab pengaturan tautan/i })
    fireEvent.click(tabTautan)

    expect(screen.getByText(/Tautan & Kode QR Katalog Resto/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Kampanye Voucher', () => {
    render(<LayarPengaturan />)

    const tabKampanye = screen.getByRole('button', { name: /buka tab pengaturan kampanye/i })
    fireEvent.click(tabKampanye)

    expect(screen.getByTestId('pengaturan-kampanye')).toBeDefined()
  })

  it('meneruskan onSimpanIdentitas ke komponen Identitas', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<LayarPengaturan onSimpanIdentitas={mockSimpan} />)

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    expect(mockSimpan).toHaveBeenCalledTimes(1)
  })
})
