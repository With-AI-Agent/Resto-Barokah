// @vitest-environment jsdom
/**
 * PROBE HAKIM H-F-02.2 (bukan bagian uji proyek) — disalin sementara ke aplikasi/src/_probe_pesanan_meja.test.tsx
 * untuk dijalankan, lalu dihapus. Memanggil App SUNGGUHAN dari kursi peran pelayan dan menekan tab navigasi
 * "Pesanan Meja" (id pesanan_meja, Navigasi.tsx:57) lalu "Status Pesanan" (kontrol).
 * Harapan sehat: keduanya menampilkan layar pelayan (teks menu bawaan LayarPelayan).
 * Kontrol negatif: pohon a8ff618^ (sebelum perbaikan F-021) harus LULUS kedua kasus.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import App from './App'
import * as supabaseLib from './lib/supabase'
import { simpanSesiLokal } from './lib/auth'

vi.mock('./lib/supabase', async (importOriginal) => {
  const actual = await importOriginal<typeof supabaseLib>()
  return { ...actual, klienSupabase: vi.fn().mockReturnValue(null) }
})

describe('PROBE F-02.2 — tab pelayan', () => {
  beforeEach(() => {
    localStorage.clear()
    sessionStorage.clear()
    simpanSesiLokal({
      id: '90000000-0000-0000-0000-000000000006',
      nama: 'Dewi Pelayan',
      email: 'pelayan@contoh.test',
      peran: 'pelayan',
      penyewaId: '11111111-1111-1111-1111-111111111111',
      cabangIds: ['cab-01'],
      cabangAktifId: 'cab-01',
      perangkatId: 'de000000-0000-0000-0000-000000000003',
    })
  })
  afterEach(() => cleanup())

  it('KONTROL: tab Status Pesanan menampilkan layar pelayan', () => {
    render(<App />)
    fireEvent.click(screen.getByText('Status Pesanan'))
    expect(screen.queryAllByText(/Nasi Goreng Spesial Barokah/).length).toBeGreaterThan(0)
  })

  it('UJI: tab Pesanan Meja menampilkan layar pelayan', () => {
    render(<App />)
    fireEvent.click(screen.getByText('Pesanan Meja'))
    expect(screen.queryAllByText(/Nasi Goreng Spesial Barokah/).length).toBeGreaterThan(0)
  })
})
