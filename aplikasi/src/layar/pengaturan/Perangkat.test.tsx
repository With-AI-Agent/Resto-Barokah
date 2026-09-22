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

  it('memungkinkan owner/admin membuat kode pendaftaran 6 digit (15 menit)', async () => {
    const onBuatKodeMock = vi.fn().mockResolvedValue({
      kode: '654321',
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

    const tombolBuat = screen.getByRole('button', { name: /Buat Kode 6 Digit/i })
    expect(tombolBuat).toBeDefined()

    fireEvent.click(tombolBuat)

    await waitFor(() => {
      expect(onBuatKodeMock).toHaveBeenCalledWith('cab-01', ['kasir', 'pelayan'])
      expect(screen.getByText('654321')).toBeDefined()
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
    const inputKode = screen.getByLabelText(/Kode 6 Digit Pendaftaran/i)

    fireEvent.change(inputNama, { target: { value: 'Tablet Dapur 2' } })
    fireEvent.change(inputKode, { target: { value: '123456' } })

    const tombolSubmit = screen.getByRole('button', { name: /Daftarkan Perangkat Sekarang/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onDaftarMock).toHaveBeenCalledWith('123456', 'Tablet Dapur 2')
      expect(screen.getByText(/Perangkat berhasil didaftarkan/i)).toBeDefined()
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
