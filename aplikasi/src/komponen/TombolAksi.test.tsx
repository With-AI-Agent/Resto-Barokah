// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { TombolAksi } from './TombolAksi'

describe('Komponen TombolAksi', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender tombol sesuai label di registri', () => {
    render(<TombolAksi aksiId="kasir.tambah_item" />)
    const tombol = screen.getByRole('button', { name: /tambah item/i }) as HTMLButtonElement
    expect(tombol).toBeDefined()
    expect(tombol.getAttribute('data-aksi-id')).toBe('kasir.tambah_item')
  })

  it('menolak aksi_id yang tidak terdaftar di registri (melempar error)', () => {
    expect(() => {
      render(<TombolAksi aksiId="aksi.tidak_ada" />)
    }).toThrow(/tidak terdaftar di REGISTRI_AKSI/i)
  })

  it('menyembunyikan tombol bila peran tidak berhak dan sembunyikanBilaTanpaIzin = true', () => {
    const { container } = render(<TombolAksi aksiId="kasir.tambah_item" peranPengguna="pelayan" />)
    expect(container.firstChild).toBeNull()
  })

  it('menonaktifkan tombol dengan alasan bila sembunyikanBilaTanpaIzin = false', () => {
    render(
      <TombolAksi
        aksiId="kasir.batal_item"
        peranPengguna="kasir"
        daftarIzinPengguna={[]} // tanpa izin void_sebelum_dapur
      />,
    )
    const tombol = screen.getByRole('button', { name: /batalkan item/i }) as HTMLButtonElement
    expect(tombol.disabled).toBe(true)
    expect(tombol.getAttribute('title')).toBe('Memerlukan izin void pembatalan.')
  })

  it('mengaktifkan tombol bila izin dimiliki', () => {
    render(
      <TombolAksi
        aksiId="kasir.batal_item"
        peranPengguna="kasir"
        daftarIzinPengguna={['void_sebelum_dapur']}
      />,
    )
    const tombol = screen.getByRole('button', { name: /batalkan item/i }) as HTMLButtonElement
    expect(tombol.disabled).toBe(false)
  })

  it('meminta konfirmasi sebelum memicu onEksekusi bila aksi memiliki konfirmasi', () => {
    const confirmSpy = vi.spyOn(window, 'confirm').mockImplementation(() => false)
    const onEksekusi = vi.fn()

    render(
      <TombolAksi
        aksiId="kasir.batal_item"
        peranPengguna="kasir"
        daftarIzinPengguna={['void_sebelum_dapur']}
        onEksekusi={onEksekusi}
      />,
    )

    const tombol = screen.getByRole('button', { name: /batalkan item/i }) as HTMLButtonElement
    fireEvent.click(tombol)

    expect(confirmSpy).toHaveBeenCalledWith('Batalkan item pesanan ini?')
    expect(onEksekusi).not.toHaveBeenCalled()

    // Sekarang simulasikan pengguna klik OK
    confirmSpy.mockImplementation(() => true)
    fireEvent.click(tombol)
    expect(onEksekusi).toHaveBeenCalled()

    confirmSpy.mockRestore()
  })

  it('menampilkan status memuat saat sedang proses', () => {
    render(<TombolAksi aksiId="kasir.tambah_item" sedangMemuat={true} />)
    const teksMemuat = screen.getByText(/memproses.../i)
    expect(teksMemuat).toBeDefined()
    const tombol = screen.getByRole('button') as HTMLButtonElement
    expect(tombol.disabled).toBe(true)
  })
})
