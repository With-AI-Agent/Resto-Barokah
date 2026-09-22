// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarMasukPelanggan } from './LayarMasukPelanggan'
import { PenyediaBahasa } from '../../bahasa'

describe('LayarMasukPelanggan (T2-04)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender tombol Google, kolom email, dan kotak centang privasi', () => {
    render(
      <PenyediaBahasa>
        <LayarMasukPelanggan />
      </PenyediaBahasa>
    )

    expect(screen.getByText(/Lanjut dengan Akun Google/i)).toBeDefined()
    expect(screen.getByLabelText(/Alamat Email Anda/i)).toBeDefined()
    expect(screen.getByText(/Saya menyetujui data saya/i)).toBeDefined()
  })

  it('meminta persetujuan privasi jika belum dicentang saat klik Google', async () => {
    const onGoogleMock = vi.fn()

    render(
      <PenyediaBahasa>
        <LayarMasukPelanggan onMasukGoogle={onGoogleMock} />
      </PenyediaBahasa>
    )

    fireEvent.click(screen.getByText(/Lanjut dengan Akun Google/i))

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeDefined()
      expect(screen.getByText(/centang persetujuan kebijakan privasi/i)).toBeDefined()
      expect(onGoogleMock).not.toHaveBeenCalled()
    })
  })

  it('mengirim tautan email ketika privasi disetujui dan formulir dikirim', async () => {
    const onKirimEmailMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <PenyediaBahasa>
        <LayarMasukPelanggan onKirimTautanEmail={onKirimEmailMock} />
      </PenyediaBahasa>
    )

    // Centang privasi
    fireEvent.click(screen.getByRole('checkbox'))

    // Isi email
    fireEvent.change(screen.getByLabelText(/Alamat Email Anda/i), {
      target: { value: 'pelanggan@gmail.com' },
    })

    // Submit
    fireEvent.click(screen.getByRole('button', { name: /Kirim Tautan Masuk ke Email/i }))

    await waitFor(() => {
      expect(onKirimEmailMock).toHaveBeenCalledWith('pelanggan@gmail.com')
      expect(screen.getByRole('status')).toBeDefined()
      expect(screen.getByText(/Tautan masuk telah dikirim/i)).toBeDefined()
    })
  })
})
