// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { PenyediaBahasa } from '../../bahasa'
import { LayarMasukPegawai } from './LayarMasukPegawai'

describe('LayarMasukPegawai (T2-02)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender judul, kolom email, dan keypad PIN 6 digit', () => {
    render(
      <PenyediaBahasa>
        <LayarMasukPegawai onMasuk={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Masuk Pegawai')).toBeDefined()
    expect(screen.getByPlaceholderText('nama@resto.test')).toBeDefined()
    expect(screen.getByText('Masuk Sekarang')).toBeDefined()
  })

  it('mengizinkan pengetikan email dan input PIN lewat keypad', async () => {
    const onMasukMock = vi.fn().mockResolvedValue({ berhasil: true, pesan: 'Sukses' })
    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <LayarMasukPegawai onMasuk={onMasukMock} onMasukSukses={onSuksesMock} />
      </PenyediaBahasa>,
    )

    const inputEmail = screen.getByPlaceholderText('nama@resto.test')
    fireEvent.change(inputEmail, { target: { value: 'kasir@resto.test' } })

    // Tekan keypad PIN: 1, 2, 3, 4, 5, 6
    fireEvent.click(screen.getByRole('button', { name: '1' }))
    fireEvent.click(screen.getByRole('button', { name: '2' }))
    fireEvent.click(screen.getByRole('button', { name: '3' }))
    fireEvent.click(screen.getByRole('button', { name: '4' }))
    fireEvent.click(screen.getByRole('button', { name: '5' }))
    fireEvent.click(screen.getByRole('button', { name: '6' }))

    const tombolSubmit = screen.getByText('Masuk Sekarang')
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onMasukMock).toHaveBeenCalledWith('kasir@resto.test', '123456')
      expect(onSuksesMock).toHaveBeenCalled()
    })
  })

  it('menampilkan pesan ramah berkode ketika PIN salah', async () => {
    const onMasukMock = vi.fn().mockResolvedValue({
      berhasil: false,
      kode: 'PIN_SALAH',
      pesan: 'PIN salah',
    })

    render(
      <PenyediaBahasa>
        <LayarMasukPegawai onMasuk={onMasukMock} />
      </PenyediaBahasa>,
    )

    const inputEmail = screen.getByPlaceholderText('nama@resto.test')
    fireEvent.change(inputEmail, { target: { value: 'kasir@resto.test' } })

    for (let i = 0; i < 6; i++) {
      fireEvent.click(screen.getByRole('button', { name: '1' }))
    }

    fireEvent.click(screen.getByText('Masuk Sekarang'))

    await waitFor(() => {
      expect(screen.getByText(/\[PIN-401\]/)).toBeDefined()
    })
  })

  it('mengizinkan pengetikan PIN via keyboard fisik dan konfirmasi via Enter', async () => {
    const onMasukMock = vi.fn().mockResolvedValue({ berhasil: true, pesan: 'Sukses' })
    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <LayarMasukPegawai onMasuk={onMasukMock} onMasukSukses={onSuksesMock} />
      </PenyediaBahasa>,
    )

    const inputEmail = screen.getByPlaceholderText('nama@resto.test')
    fireEvent.change(inputEmail, { target: { value: 'kasir@resto.test' } })

    // Lepaskan fokus dari input email
    fireEvent.blur(inputEmail)

    // Ketik PIN 6 angka via keyboard fisik: 6, 5, 4, 3, 2, 1
    ;['6', '5', '4', '3', '2', '1'].forEach((char) => {
      fireEvent.keyDown(window, { key: char })
    })

    // Tekan Enter untuk konfirmasi masuk
    fireEvent.keyDown(window, { key: 'Enter' })

    await waitFor(() => {
      expect(onMasukMock).toHaveBeenCalledWith('kasir@resto.test', '654321')
      expect(onSuksesMock).toHaveBeenCalled()
    })
  })

  it('menangani Backspace, Escape, dan Spasi pada keyboard fisik', async () => {
    const onMasukMock = vi.fn().mockResolvedValue({ berhasil: true, pesan: 'Sukses' })
    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <LayarMasukPegawai onMasuk={onMasukMock} onMasukSukses={onSuksesMock} />
      </PenyediaBahasa>,
    )

    const inputEmail = screen.getByPlaceholderText('nama@resto.test')
    fireEvent.change(inputEmail, { target: { value: 'admin@resto.test' } })
    fireEvent.blur(inputEmail)

    // 1. Ketik 3 angka, lalu tekan Escape untuk mereset
    fireEvent.keyDown(window, { key: '9' })
    fireEvent.keyDown(window, { key: '8' })
    fireEvent.keyDown(window, { key: '7' })
    fireEvent.keyDown(window, { key: 'Escape' })

    // 2. Ketik lagi 2 angka, tekan Backspace (hapus digit terakhir), lalu lanjutkan hingga 6 digit
    fireEvent.keyDown(window, { key: '1' })
    fireEvent.keyDown(window, { key: '2' })
    fireEvent.keyDown(window, { key: 'Backspace' }) // hapus 2, sisa '1'

    ;['2', '3', '4', '5', '6'].forEach((char) => {
      fireEvent.keyDown(window, { key: char })
    })

    // 3. Tekan Spasi untuk konfirmasi masuk
    fireEvent.keyDown(window, { key: ' ' })

    await waitFor(() => {
      expect(onMasukMock).toHaveBeenCalledWith('admin@resto.test', '123456')
      expect(onSuksesMock).toHaveBeenCalled()
    })
  })
})
