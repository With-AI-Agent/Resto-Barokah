/**
 * StatusAntreanOffline.test.tsx — Pengujian komponen penampil status antrean luring (T10-01).
 */
// @vitest-environment jsdom
import { describe, expect, it, beforeEach, afterEach } from 'vitest'
import { render, screen, act, cleanup } from '@testing-library/react'
import { StatusAntreanOffline } from './StatusAntreanOffline'
import { kosongkanSemuaAntrean, tambahKeAntrean } from '../lib/antrean-offline'

describe('StatusAntreanOffline (T10-01 / ART-8)', () => {
  beforeEach(async () => {
    cleanup()
    await kosongkanSemuaAntrean()
  })

  afterEach(() => {
    cleanup()
  })

  it('tidak menampilkan apa-apa saat daring dan antrean kosong', () => {
    const { container } = render(<StatusAntreanOffline />)
    expect(container.firstChild).toBeNull()
  })

  it('menampilkan status "menunggu dikirim 2" saat ada 2 pesanan tertunda (DoD)', async () => {
    await tambahKeAntrean({
      jenis: 'simpan_pesanan',
      kunciIdempoten: 'kunci-uji-1',
      muatan: { total: 10000 },
    })
    await tambahKeAntrean({
      jenis: 'simpan_pesanan',
      kunciIdempoten: 'kunci-uji-2',
      muatan: { total: 20000 },
    })

    await act(async () => {
      render(<StatusAntreanOffline />)
    })

    const statusEl = screen.getByTestId('teks-status-antrean')
    expect(statusEl).toBeDefined()
    expect(statusEl.textContent).toBe('menunggu dikirim 2')

    // Ada tombol Kirim Sekarang
    const btnKirim = screen.getByRole('button', { name: /kirim sekarang/i })
    expect(btnKirim).toBeDefined()
    expect(btnKirim.textContent).toBe('Kirim Sekarang')
  })

  it('menampilkan status saat dalam mode ringkas (lencana)', async () => {
    await tambahKeAntrean({
      jenis: 'simpan_pesanan',
      kunciIdempoten: 'kunci-uji-ringkas',
      muatan: { total: 15000 },
    })

    await act(async () => {
      render(<StatusAntreanOffline ringkas={true} />)
    })

    const ringkasEl = screen.getByTestId('status-antrean-ringkas')
    expect(ringkasEl).toBeDefined()
    expect(ringkasEl.textContent).toContain('menunggu dikirim 1')
  })

  it('menampilkan peringatan mode luring saat offline', async () => {
    await act(async () => {
      render(<StatusAntreanOffline />)
    })

    act(() => {
      window.dispatchEvent(new Event('offline'))
    })

    expect(screen.getByText('Mode Luring (Offline)')).toBeDefined()
  })
})
