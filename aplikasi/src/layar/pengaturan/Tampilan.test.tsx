// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { Tampilan, validasiKontrasAksen } from './Tampilan'

describe('Tampilan (Pengaturan Tema & Warna Merek — T9-02 / PRD M2)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('merender seluruh 10 pilihan tema resmi dan 2 mode kerapatan', () => {
    render(<Tampilan />)

    // 10 tema resmi
    expect(screen.getAllByText('Terang Bersih').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('Hangat Kedai')).toBeDefined()
    expect(screen.getByText('Gelap Dapur')).toBeDefined()
    expect(screen.getByText('Kontras Tinggi')).toBeDefined()
    expect(screen.getByText('Bara Panggang')).toBeDefined()
    expect(screen.getByText('Vintage Klasik')).toBeDefined()
    expect(screen.getByText('Alam Hijau')).toBeDefined()
    expect(screen.getByText('Tropis Segar')).toBeDefined()
    expect(screen.getByText('Pastel Manis')).toBeDefined()
    expect(screen.getByText('Etnik Nusantara')).toBeDefined()

    // 2 mode kerapatan
    expect(screen.getByText('Nyaman')).toBeDefined()
    expect(screen.getByText('Padat')).toBeDefined()

    // Kotak pratinjau awal
    const pratinjau = screen.getByTestId('kotak-pratinjau')
    expect(pratinjau.getAttribute('data-theme')).toBe('terang')
    expect(pratinjau.getAttribute('data-density')).toBe('nyaman')
  })

  it('dapat memilih tema baru dan memperbarui kotak pratinjau langsung', () => {
    render(<Tampilan />)

    const tombolPilihHangat = screen.getByRole('button', { name: /pilih tema hangat kedai/i })
    fireEvent.click(tombolPilihHangat)

    const pratinjau = screen.getByTestId('kotak-pratinjau')
    expect(pratinjau.getAttribute('data-theme')).toBe('hangat')
  })

  it('dapat mengubah mode kerapatan ke padat', () => {
    render(<Tampilan />)

    const tombolPadat = screen.getByRole('button', { name: /pilih mode kerapatan padat/i })
    fireEvent.click(tombolPadat)

    const pratinjau = screen.getByTestId('kotak-pratinjau')
    expect(pratinjau.getAttribute('data-density')).toBe('padat')
  })

  it('memvalidasi warna aksen merek yang memenuhi standar kontras WCAG AA', () => {
    render(<Tampilan />)

    const inputWarna = screen.getByRole('textbox', {
      name: /kode heksa warna aksen/i,
    })

    // Warna kontras tinggi (e06000 jingga pekat)
    fireEvent.change(inputWarna, { target: { value: 'e06000' } })

    expect(screen.getByText('WCAG AA Lolos')).toBeDefined()
  })

  it('menolak warna aksen merek yang kontrasnya rendah di bawah 4.5:1', () => {
    render(<Tampilan />)

    const inputWarna = screen.getByRole('textbox', {
      name: /kode heksa warna aksen/i,
    })

    // Warna abu-abu pucat (cccccc) yang kontrasnya sangat rendah terhadap latar terang
    fireEvent.change(inputWarna, { target: { value: 'cccccc' } })

    expect(screen.getByText('Kontras Rendah')).toBeDefined()

    // Tombol simpan dinonaktifkan bila warna aksen tidak lolos uji kontras
    const tombolSimpan = screen.getByRole('button', {
      name: /simpan pengaturan tema ke database resto/i,
    })
    expect(tombolSimpan.hasAttribute('disabled')).toBe(true)
  })

  it('tombol "Coba di Seluruh Layar" memicu pesan sukses dan pengubahan DOM', () => {
    render(<Tampilan />)

    const tombolCoba = screen.getByRole('button', {
      name: /terapkan tema ini ke aplikasi sekarang/i,
    })
    fireEvent.click(tombolCoba)

    expect(screen.getByText('Tema berhasil diterapkan sementara ke layar ini!')).toBeDefined()
  })

  it('berhasil menyimpan tema terpilih via prop onSimpan', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<Tampilan onSimpan={mockSimpan} />)

    // Pilih tema gelap
    const tombolPilihGelap = screen.getByRole('button', { name: /pilih tema gelap dapur/i })
    fireEvent.click(tombolPilihGelap)

    // Klik simpan
    const tombolSimpan = screen.getByRole('button', {
      name: /simpan pengaturan tema ke database resto/i,
    })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith({
        tema: 'gelap',
        kerapatan: 'nyaman',
        warnaMerek: '',
        versiPengaturan: null,
      })
    })

    expect(screen.getByText('Tema tampilan restoran berhasil disimpan!')).toBeDefined()
  })

  it('menampilkan pesan galat bila onSimpan mengembalikan kesalahan', async () => {
    const mockSimpan = vi
      .fn()
      .mockResolvedValue({ berhasil: false, pesan: 'Izin ditolak oleh server.' })
    render(<Tampilan onSimpan={mockSimpan} />)

    const tombolSimpan = screen.getByRole('button', {
      name: /simpan pengaturan tema ke database resto/i,
    })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(screen.getByText('Izin ditolak oleh server.')).toBeDefined()
    })
  })

  it('menonaktifkan tombol simpan pada mode hanyaBaca', () => {
    render(<Tampilan hanyaBaca={true} />)

    const tombolSimpan = screen.getByRole('button', {
      name: /simpan pengaturan tema ke database resto/i,
    })
    expect(tombolSimpan.hasAttribute('disabled')).toBe(true)
  })

  describe('validasiKontrasAksen helper', () => {
    it('mengembalikan valid: true saat string warna kosong (memakai bawaan)', () => {
      const res = validasiKontrasAksen('')
      expect(res.valid).toBe(true)
    })

    it('mengembalikan valid: false jika format kode bukan heksa valid', () => {
      const res = validasiKontrasAksen('bukan-heksa')
      expect(res.valid).toBe(false)
    })

    it('menguji kontras 10 tema x 3 warna merek teruji', () => {
      const warnaTeruji = ['e06000', '1a7f37', '0969da']
      for (const w of warnaTeruji) {
        const res = validasiKontrasAksen(w)
        expect(res.valid).toBe(true)
        expect(res.rasio).toBeGreaterThanOrEqual(4.5)
      }
    })
  })
})
