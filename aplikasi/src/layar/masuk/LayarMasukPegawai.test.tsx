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
})
