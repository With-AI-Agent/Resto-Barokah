// @vitest-environment jsdom
/**
 * Uji Integrasi Antarmuka App & Penanganan Shift (L F-03)
 *
 * Membuktikan bahwa:
 *  1. `onBukaShift` tidak mengembalikan sukses palsu bila RPC peladen gagal.
 *  2. `onTutupShift` tidak mengembalikan sukses palsu bila RPC peladen gagal.
 *  3. Integrasi RPC peladen dipanggil dengan parameter yang sah.
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import App from './App'
import * as supabaseLib from './lib/supabase'
import { simpanSesiLokal } from './lib/auth'

vi.mock('./lib/supabase', async (importOriginal) => {
  const actual = await importOriginal<typeof supabaseLib>()
  return {
    ...actual,
    klienSupabase: vi.fn(),
  }
})

describe('App - Penanganan Shift Kasir (L F-03)', () => {
  const mockRpc = vi.fn()
  const mockClient = {
    rpc: mockRpc,
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnThis(),
      insert: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({ data: null, error: null }),
    }),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    sessionStorage.clear()
    // Mock sesi kasir aktif
    simpanSesiLokal({
      id: '90000000-0000-0000-0000-000000000004',
      nama: 'Rina Kasir',
      email: 'kasir.a1@contoh.test',
      peran: 'kasir',
      penyewaId: '11111111-1111-1111-1111-111111111111',
      cabangIds: ['cab-01'],
      cabangAktifId: 'cab-01',
      perangkatId: 'de000000-0000-0000-0000-000000000003',
    })
  })

  afterEach(() => {
    cleanup()
  })

  it('menolak pembukaan shift bila RPC peladen gagal dan tidak mengeset sesi terbuka', async () => {
    vi.mocked(supabaseLib.klienSupabase).mockReturnValue(
      mockClient as unknown as ReturnType<typeof supabaseLib.klienSupabase>,
    )
    mockRpc.mockResolvedValueOnce({
      data: null,
      error: { message: 'SH-409: Anda masih memiliki shift kasir yang aktif' },
    })

    render(<App />)

    const tombolBukaKas = screen.getByRole('button', { name: /🟡 Buka Kas/i })
    fireEvent.click(tombolBukaKas)

    const inputModal = screen.getByRole('spinbutton')
    fireEvent.change(inputModal, { target: { value: '100000' } })

    const tombolLanjut = screen.getByRole('button', { name: /Lanjut Buka Shift/i })
    fireEvent.click(tombolLanjut)

    const tombolKonfirmasi = screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i })
    fireEvent.click(tombolKonfirmasi)

    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith(
        'buka_shift',
        expect.objectContaining({
          p_modal_awal: 100000,
        }),
      )
      expect(screen.getByText(/SH-409: Anda masih memiliki shift kasir yang aktif/i)).toBeDefined()
    })
  })

  it('membuka shift dan menyimpan ID shift bila RPC peladen sukses', async () => {
    vi.mocked(supabaseLib.klienSupabase).mockReturnValue(
      mockClient as unknown as ReturnType<typeof supabaseLib.klienSupabase>,
    )
    mockRpc.mockResolvedValueOnce({
      data: {
        berhasil: true,
        kode: 'SH-200',
        shift_id: 'shift-uuid-999',
        cabang_id: 'cab-01',
        modal_awal: 150000,
        dibuka_pada: new Date().toISOString(),
      },
      error: null,
    })

    render(<App />)

    const tombolBukaKas = screen.getByRole('button', { name: /🟡 Buka Kas/i })
    fireEvent.click(tombolBukaKas)

    const inputModal = screen.getByRole('spinbutton')
    fireEvent.change(inputModal, { target: { value: '150000' } })

    const tombolLanjut = screen.getByRole('button', { name: /Lanjut Buka Shift/i })
    fireEvent.click(tombolLanjut)

    const tombolKonfirmasi = screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i })
    fireEvent.click(tombolKonfirmasi)

    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith(
        'buka_shift',
        expect.objectContaining({
          p_modal_awal: 150000,
        }),
      )
      expect(screen.getByText(/Shift Kasir Sudah Aktif/i)).toBeDefined()
    })
  })

  it('menolak penutupan shift bila RPC tutup_shift peladen gagal', async () => {
    vi.mocked(supabaseLib.klienSupabase).mockReturnValue(
      mockClient as unknown as ReturnType<typeof supabaseLib.klienSupabase>,
    )
    // Langkah 1: Buka shift dulu
    mockRpc.mockResolvedValueOnce({
      data: {
        berhasil: true,
        kode: 'SH-200',
        shift_id: 'shift-uuid-888',
        cabang_id: 'cab-01',
        modal_awal: 200000,
        dibuka_pada: new Date().toISOString(),
      },
      error: null,
    })

    render(<App />)

    const tombolBukaKas = screen.getByRole('button', { name: /🟡 Buka Kas/i })
    fireEvent.click(tombolBukaKas)

    const inputModal = screen.getByRole('spinbutton')
    fireEvent.change(inputModal, { target: { value: '200000' } })
    fireEvent.click(screen.getByRole('button', { name: /Lanjut Buka Shift/i }))
    fireEvent.click(screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i }))

    await waitFor(() => {
      expect(screen.getByText(/Shift Kasir Sudah Aktif/i)).toBeDefined()
    })

    // Tutup dialog buka kas
    fireEvent.click(screen.getByLabelText('Tutup'))

    // Langkah 2: Coba tutup shift dengan RPC gagal
    mockRpc.mockResolvedValueOnce({
      data: null,
      error: { message: 'SH-500: Terjadi gangguan jaringan di server' },
    })

    const tombolTutupKas = screen.getByRole('button', { name: /🔴\s*Tutup Kas/i })
    fireEvent.click(tombolTutupKas)

    const inputFisik = screen.getByRole('spinbutton')
    fireEvent.change(inputFisik, { target: { value: '200000' } })

    fireEvent.click(screen.getByRole('button', { name: /Lanjut Tutup Kas/i }))
    fireEvent.click(screen.getByRole('button', { name: /Ya, Tutup Shift Sekarang/i }))

    await waitFor(() => {
      expect(mockRpc).toHaveBeenCalledWith(
        'tutup_shift',
        expect.objectContaining({
          p_uang_fisik: 200000,
          p_shift_id: 'shift-uuid-888',
        }),
      )
      expect(screen.getByText(/SH-500: Terjadi gangguan jaringan di server/i)).toBeDefined()
    })
  })
})
