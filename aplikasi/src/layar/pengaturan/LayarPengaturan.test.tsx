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
    expect(screen.getByRole('button', { name: /buka tab pengaturan operasional/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan meja/i })).toBeDefined()
    expect(screen.getByRole('button', { name: /buka tab pengaturan kelola menu/i })).toBeDefined()
    expect(
      screen.getByRole('button', { name: /buka tab pengaturan menu per cabang/i }),
    ).toBeDefined()
    expect(
      screen.getByRole('button', { name: /buka tab pengaturan metode bayar & tip/i }),
    ).toBeDefined()
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

  it('dapat berpindah ke tab Operasional & Kasir', () => {
    render(<LayarPengaturan />)

    const tabOperasional = screen.getByRole('button', { name: /buka tab pengaturan operasional/i })
    fireEvent.click(tabOperasional)

    expect(screen.getByTestId('pengaturan-operasional')).toBeDefined()
    expect(screen.getByText(/Pengaturan Operasional & Kasir/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Meja & Area (T9-04)', () => {
    render(<LayarPengaturan />)

    const tabMeja = screen.getByRole('button', { name: /buka tab pengaturan meja/i })
    fireEvent.click(tabMeja)

    expect(screen.getByTestId('pengaturan-meja')).toBeDefined()
    expect(screen.getByText(/Pengaturan Meja & Area/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Kelola Menu (T9-05)', () => {
    render(<LayarPengaturan />)

    const tabMenu = screen.getByRole('button', { name: /buka tab pengaturan kelola menu/i })
    fireEvent.click(tabMenu)

    expect(screen.getByTestId('pengaturan-menu')).toBeDefined()
    expect(screen.getByText(/Pengelolaan Menu & Kategori/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Menu Per Cabang (T9-06)', () => {
    render(<LayarPengaturan />)

    const tabMenuCabang = screen.getByRole('button', {
      name: /buka tab pengaturan menu per cabang/i,
    })
    fireEvent.click(tabMenuCabang)

    expect(screen.getByTestId('pengaturan-menu-cabang')).toBeDefined()
    expect(screen.getByText(/Harga & Ketersediaan Menu Per Cabang/i)).toBeDefined()
  })

  it('dapat berpindah ke tab Metode Bayar & Tip (T9-07)', () => {
    render(<LayarPengaturan />)

    const tabMetode = screen.getByRole('button', {
      name: /buka tab pengaturan metode bayar & tip/i,
    })
    fireEvent.click(tabMetode)

    expect(screen.getByTestId('pengaturan-metode-bayar')).toBeDefined()
    expect(screen.getByText(/Metode Pembayaran & Aturan Tip/i)).toBeDefined()
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

  it('dapat berpindah ke tab Kelola Pegawai', () => {
    render(<LayarPengaturan />)

    const tabPegawai = screen.getByRole('button', { name: /buka tab pengaturan kelola pegawai/i })
    fireEvent.click(tabPegawai)

    expect(screen.getByTestId('kelola-pegawai')).toBeDefined()
  })

  it('meneruskan onSimpanIdentitas ke komponen Identitas', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<LayarPengaturan onSimpanIdentitas={mockSimpan} />)

    const tombolSimpan = screen.getByRole('button', { name: /simpan identitas resto/i })
    fireEvent.click(tombolSimpan)

    expect(mockSimpan).toHaveBeenCalledTimes(1)
  })
})
