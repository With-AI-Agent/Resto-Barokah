// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarPerangkat } from './Perangkat'

describe('LayarPerangkat (T2-15)', () => {
  afterEach(() => {
    cleanup()
  })

  const daftarTungguContoh = [
    {
      penggunaId: 'pgw-01',
      nama: 'Budi Santoso',
      peran: 'kasir' as const,
      perangkatId: 'dev-01',
      namaPerangkat: 'Tablet Kasir Depan',
    },
  ]

  it('memungkinkan owner/admin membuat kode pendaftaran 8 karakter (15 menit)', async () => {
    const onBuatKodeMock = vi.fn().mockResolvedValue({
      kode: 'AB12CD34',
      kedaluwarsaPada: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    })

    render(
      <LayarPerangkat
        cabangId="cab-01"
        peranUser="owner_pusat"
        onBuatKode={onBuatKodeMock}
        onDaftarkanPerangkat={vi.fn()}
        onSetujuiPegawai={vi.fn()}
      />,
    )

    const tombolBuat = screen.getByRole('button', { name: /Buat Kode Pendaftaran/i })
    expect(tombolBuat).toBeDefined()

    fireEvent.click(tombolBuat)

    await waitFor(() => {
      expect(onBuatKodeMock).toHaveBeenCalledWith('cab-01', ['kasir', 'pelayan'])
      expect(screen.getByText('AB12CD34')).toBeDefined()
    })
  })

  it('memproses pendaftaran perangkat baru dengan kode dan nama perangkat', async () => {
    const onDaftarMock = vi.fn().mockResolvedValue({ sukses: true, perangkatId: 'dev-99' })

    render(
      <LayarPerangkat
        cabangId="cab-01"
        peranUser="kasir"
        onBuatKode={vi.fn()}
        onDaftarkanPerangkat={onDaftarMock}
        onSetujuiPegawai={vi.fn()}
      />,
    )

    const inputNama = screen.getByLabelText(/Nama Perangkat/i)
    const inputKode = screen.getByLabelText(/Kode Pendaftaran/i)

    fireEvent.change(inputNama, { target: { value: 'Tablet Dapur 2' } })
    fireEvent.change(inputKode, { target: { value: 'AB12CD34' } })

    const tombolSubmit = screen.getByRole('button', { name: /Daftarkan Perangkat Sekarang/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onDaftarMock).toHaveBeenCalledWith('AB12CD34', 'Tablet Dapur 2')
      expect(screen.getByText(/Perangkat berhasil didaftarkan/i)).toBeDefined()
    })
  })

  it('menerima kode 8 karakter huruf-angka kapital sesuai format backend (PMB1-F-086)', async () => {
    const onDaftarMock = vi.fn().mockResolvedValue({ sukses: true, perangkatId: 'dev-98' })

    render(
      <LayarPerangkat
        cabangId="cab-01"
        peranUser="kasir"
        onBuatKode={vi.fn()}
        onDaftarkanPerangkat={onDaftarMock}
        onSetujuiPegawai={vi.fn()}
      />,
    )

    const inputNama = screen.getByLabelText(/Nama Perangkat/i)
    const inputKode = screen.getByLabelText(/Kode Pendaftaran/i) as HTMLInputElement

    fireEvent.change(inputNama, { target: { value: 'Tablet Bar' } })
    // Backend (migrasi 0030) menerbitkan 8 karakter [A-Z2-9]; pengguna
    // mengetik huruf kecil — antarmuka harus mengkapitalkannya, bukan
    // membuangnya (filter lama hanya meloloskan digit sehingga huruf hilang).
    fireEvent.change(inputKode, { target: { value: 'a1b2c3d4' } })

    expect(inputKode.value).toBe('A1B2C3D4')

    const tombolSubmit = screen.getByRole('button', { name: /Daftarkan Perangkat Sekarang/i })
    expect(tombolSubmit.hasAttribute('disabled')).toBe(false)
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onDaftarMock).toHaveBeenCalledWith('A1B2C3D4', 'Tablet Bar')
    })
  })

  it('menyetujui permohonan akses pegawai di perangkat', async () => {
    const onSetujuiMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <LayarPerangkat
        cabangId="cab-01"
        peranUser="owner_pusat"
        daftarPersetujuan={daftarTungguContoh}
        onBuatKode={vi.fn()}
        onDaftarkanPerangkat={vi.fn()}
        onSetujuiPegawai={onSetujuiMock}
      />,
    )

    expect(screen.getByText('Budi Santoso')).toBeDefined()
    expect(screen.getByText('Tablet Kasir Depan')).toBeDefined()

    const tombolSetujui = screen.getByRole('button', { name: /Setujui Akses/i })
    fireEvent.click(tombolSetujui)

    await waitFor(() => {
      expect(onSetujuiMock).toHaveBeenCalledWith('pgw-01', 'dev-01')
    })
  })
})
