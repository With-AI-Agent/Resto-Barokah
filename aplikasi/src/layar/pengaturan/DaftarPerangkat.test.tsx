// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { DaftarPerangkat, type ItemPerangkat } from './DaftarPerangkat'

describe('DaftarPerangkat (T2-17)', () => {
  afterEach(() => {
    cleanup()
  })

  const daftarContoh: ItemPerangkat[] = [
    {
      id: 'dev-01',
      nama: 'Tablet POS Kasir 1',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Utama (Pusat)',
      peranDiizinkan: ['kasir'],
      aktif: true,
      terakhirAktif: new Date().toISOString(),
      jumlahSesiAktif: 1,
    },
    {
      id: 'dev-02',
      nama: 'Tablet Waiter Outdoor',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Utama (Pusat)',
      peranDiizinkan: ['pelayan'],
      aktif: false,
      terakhirAktif: new Date(Date.now() - 3600000).toISOString(),
      jumlahSesiAktif: 0,
    },
  ]

  it('merender daftar perangkat resmi dan status keaktifannya', () => {
    render(<DaftarPerangkat daftarPerangkat={daftarContoh} onCabutPerangkat={vi.fn()} />)

    expect(screen.getByText('Tablet POS Kasir 1')).toBeDefined()
    expect(screen.getByText('Tablet Waiter Outdoor')).toBeDefined()
    expect(screen.getByText('Aktif Resmi')).toBeDefined()
    expect(screen.getByText('Telah Dicabut')).toBeDefined()
  })

  it('membuka dialog konfirmasi saat tombol Cabut Izin diklik dan memanggil onCabutPerangkat', async () => {
    const onCabutMock = vi.fn().mockResolvedValue({ sukses: true })

    render(<DaftarPerangkat daftarPerangkat={daftarContoh} onCabutPerangkat={onCabutMock} />)

    // Klik tombol Cabut Izin pada Tablet POS Kasir 1
    const tombolCabut = screen.getByRole('button', { name: /Cabut Izin/i })
    fireEvent.click(tombolCabut)

    // Dialog konfirmasi muncul
    expect(screen.getByText(/Konfirmasi Cabut Izin Perangkat/i)).toBeDefined()
    expect(screen.getAllByText(/Tablet POS Kasir 1/i).length).toBeGreaterThanOrEqual(1)

    // Klik konfirmasi eksekusi pencabutan
    const tombolKonfirmasi = screen.getByRole('button', { name: /Ya, Cabut Izin Sekarang/i })
    fireEvent.click(tombolKonfirmasi)

    await waitFor(() => {
      expect(onCabutMock).toHaveBeenCalledWith(
        'dev-01',
        'Perangkat hilang / ditarik dari operasional',
      )
    })
  })
})
