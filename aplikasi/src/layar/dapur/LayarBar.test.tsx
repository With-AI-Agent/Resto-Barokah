/**
 * Uji LayarBar (T4-02): hanya bagian minuman, satu pesanan tampil di dua layar,
 * keadaan dasar tetap ramah.
 */
// @vitest-environment jsdom
import { describe, expect, it, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { LayarBar } from './LayarBar'
import type { TiketPesanan } from './KartuPesanan'

afterEach(() => {
  cleanup()
})

const WAKTU = '2026-09-22T10:30:00.000Z'

const TIKET_CAMPUR: TiketPesanan = {
  id: 'campur',
  nomor: 55,
  tipe: 'dinein',
  meja: '3',
  dikirimPada: '2026-09-22T10:10:00.000Z',
  items: [
    {
      id: 'm1',
      menuItemId: 'menu-m1',
      namaSaatItu: 'Nasi Goreng',
      qty: 1,
      catatan: null,
      status: 'baru',
      tujuan: 'dapur',
    },
    {
      id: 'b1',
      menuItemId: 'menu-b1',
      namaSaatItu: 'Es Teh',
      qty: 2,
      catatan: 'Sedikit gula',
      status: 'baru',
      tujuan: 'bar',
    },
  ],
}

describe('LayarBar (T4-02)', () => {
  it('satu pesanan muncul di dua layar — bar hanya melihat bagiannya', () => {
    render(<LayarBar tiket={[TIKET_CAMPUR]} waktuSekarang={WAKTU} />)
    expect(screen.getByTestId('kartu-campur')).toBeTruthy()
    expect(screen.getByText(/Es Teh/)).toBeTruthy()
    expect(screen.queryByText(/Nasi Goreng/)).toBeNull()
  })

  it('catatan minuman tetap mencolok', () => {
    render(<LayarBar tiket={[TIKET_CAMPUR]} waktuSekarang={WAKTU} />)
    expect(screen.getByTestId('catatan-item-b1').textContent).toContain('Sedikit gula')
  })

  it('keadaan kosong bar ramah', () => {
    render(<LayarBar tiket={[]} waktuSekarang={WAKTU} />)
    expect(screen.getByText('Belum ada pesanan minuman.')).toBeTruthy()
  })

  it('penanda waktu bar sama seperti dapur (ambang bisa diatur)', () => {
    // dikirim 10:10, sekarang 10:20 = 10 menit → waspada pada ambang [5, 15]
    render(<LayarBar tiket={[TIKET_CAMPUR]} waktuSekarang="2026-09-22T10:20:00.000Z" ambangMenit={[5, 15]} />)
    expect(screen.getByTestId('penanda-waktu').getAttribute('data-tingkat')).toBe('waspada')
  })
})
