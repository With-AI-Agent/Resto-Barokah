// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { KomponenQr } from './KomponenQr'

describe('Komponen QR Code (KomponenQr.tsx)', () => {
  afterEach(cleanup)

  it('merender judul, keterangan, dan svg qr', () => {
    render(
      <KomponenQr
        url="https://resto-barokah.dev/menu"
        judul="Pindai Menu Kami"
        keterangan="Arahkan kamera HP Anda ke kode di atas."
      />,
    )

    expect(screen.getByText('Pindai Menu Kami')).toBeDefined()
    expect(screen.getByText('Arahkan kamera HP Anda ke kode di atas.')).toBeDefined()
    expect(screen.getByTestId('teks-url-qr').textContent).toBe('https://resto-barokah.dev/menu')
    expect(screen.getByRole('img')).toBeDefined()
  })

  it('menangani tombol salin tautan dengan benar', async () => {
    const tulisTeksMock = vi.fn().mockResolvedValue(undefined)
    Object.assign(navigator, {
      clipboard: {
        writeText: tulisTeksMock,
      },
    })

    render(<KomponenQr url="https://resto-barokah.dev/menu" bisaSalin />)

    const tombolSalin = screen.getByRole('button', { name: /salin tautan katalog/i })
    expect(tombolSalin).toBeDefined()
    fireEvent.click(tombolSalin)

    expect(tulisTeksMock).toHaveBeenCalledWith('https://resto-barokah.dev/menu')
    const teksTersalin = await screen.findByText(/Tautan Tersalin!/i)
    expect(teksTersalin).toBeDefined()
  })
})
