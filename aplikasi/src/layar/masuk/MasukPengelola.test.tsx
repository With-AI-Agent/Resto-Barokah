// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { MasukPengelola } from './MasukPengelola'
import { PenyediaBahasa } from '../../bahasa'

describe('MasukPengelola (T2-18 & T2-13)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender form email dan kata sandi pengelola', () => {
    render(
      <PenyediaBahasa>
        <MasukPengelola onMasukKataSandi={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByLabelText(/Alamat Email Pengelola/i)).toBeDefined()
    expect(screen.getByLabelText(/Kata Sandi/i)).toBeDefined()
    expect(screen.getByRole('button', { name: /Masuk sebagai Pengelola/i })).toBeDefined()
  })

  it('masuk langsung bila akun tidak mewajibkan TOTP', async () => {
    const onMasukMock = vi.fn().mockResolvedValue({ sukses: true })
    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <MasukPengelola onMasukKataSandi={onMasukMock} onMasukSukses={onSuksesMock} />
      </PenyediaBahasa>,
    )

    fireEvent.change(screen.getByLabelText(/Alamat Email Pengelola/i), {
      target: { value: 'owner@resto.test' },
    })
    fireEvent.change(screen.getByLabelText(/Kata Sandi/i), {
      target: { value: 'Rahasia123!' },
    })

    fireEvent.click(screen.getByRole('button', { name: /Masuk sebagai Pengelola/i }))

    await waitFor(() => {
      expect(onMasukMock).toHaveBeenCalledWith('owner@resto.test', 'Rahasia123!', undefined)
      expect(onSuksesMock).toHaveBeenCalled()
    })
  })

  it('meminta kode TOTP jika akun memiliki 2FA aktif', async () => {
    const onMasukMock = vi
      .fn()
      .mockResolvedValueOnce({ sukses: false, butuhTotp: true })
      .mockResolvedValueOnce({ sukses: true })

    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <MasukPengelola onMasukKataSandi={onMasukMock} onMasukSukses={onSuksesMock} />
      </PenyediaBahasa>,
    )

    fireEvent.change(screen.getByLabelText(/Alamat Email Pengelola/i), {
      target: { value: 'owner@resto.test' },
    })
    fireEvent.change(screen.getByLabelText(/Kata Sandi/i), {
      target: { value: 'Rahasia123!' },
    })

    fireEvent.click(screen.getByRole('button', { name: /Masuk sebagai Pengelola/i }))

    // Tahap 2: form TOTP muncul
    await waitFor(() => {
      expect(screen.getByText('Verifikasi Dua Langkah (TOTP)')).toBeDefined()
      expect(screen.getByLabelText(/Kode Keamanan 6 Digit/i)).toBeDefined()
    })

    // Masukkan kode TOTP 6 digit: 456789
    fireEvent.change(screen.getByLabelText(/Kode Keamanan 6 Digit/i), {
      target: { value: '456789' },
    })

    fireEvent.click(screen.getByRole('button', { name: /Verifikasi & Masuk/i }))

    await waitFor(() => {
      expect(onMasukMock).toHaveBeenCalledWith('owner@resto.test', 'Rahasia123!', '456789')
      expect(onSuksesMock).toHaveBeenCalled()
    })
  })
})
