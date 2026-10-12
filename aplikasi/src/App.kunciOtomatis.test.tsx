// @vitest-environment jsdom
/**
 * PMB1-F-084 (K-2, kartu K-F-06.2) — kunci otomatis tidak pernah dipasang.
 *
 * Hook `useKunciOtomatis` dan komponen `KunciSekarang` sudah ada dan lulus uji
 * isolasi, tetapi tidak pernah dipasang di wadah aplikasi (`App.tsx`), sehingga
 * janji KEAMANAN §7 "penguncian otomatis saat tidak ada aktivitas"
 * (kasir/pelayan/dapur 15 menit, admin cabang 30, owner 60) tidak pernah aktif
 * di aplikasi nyata.
 *
 * Uji ini memakai timer palsu: sesi kasir lokal diset, `App` dirender, waktu
 * dimajukan melewati batas 15 menit, dan aplikasi harus kembali ke layar masuk
 * (sesi terkunci/berakhir). Bukti mutasi: bila pemanggilan `useKunciOtomatis`
 * di `App.tsx` dihapus, uji ini MERAH.
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, cleanup, act } from '@testing-library/react'
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

describe('PMB1-F-084 — kunci otomatis terpasang di wadah aplikasi (KEAMANAN §7)', () => {
  const mockClient = {
    rpc: vi.fn().mockResolvedValue({ data: null, error: null }),
    auth: { signOut: vi.fn().mockResolvedValue({ error: null }) },
    from: vi.fn().mockReturnValue({
      select: vi.fn().mockReturnThis(),
      insert: vi.fn().mockReturnThis(),
      update: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({ data: null, error: null }),
      then: undefined,
    }),
  }

  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    sessionStorage.clear()
    vi.mocked(supabaseLib.klienSupabase).mockReturnValue(
      mockClient as unknown as ReturnType<typeof supabaseLib.klienSupabase>,
    )
    // Sesi kasir aktif (batas inaktif kasir = 15 menit, KEAMANAN §7).
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
    vi.useRealTimers()
  })

  it('mengunci sesi kasir sesudah 15 menit menganggur (kembali ke layar masuk)', async () => {
    vi.useFakeTimers()
    render(<App />)

    // Sedang masuk: layar masuk pegawai tidak tampak.
    expect(screen.queryByText('Masuk Pegawai')).toBeNull()

    // Majukan waktu melewati batas 15 menit kasir (+2 detik pelonggar tick).
    // act asinkron agar janjian `keluar()` (pencabutan sesi peladen) ter-flush.
    await act(async () => {
      vi.advanceTimersByTime(15 * 60 * 1000 + 2000)
    })

    // Sesi terkunci otomatis: aplikasi kembali ke layar masuk pegawai.
    expect(screen.getByText('Masuk Pegawai')).toBeTruthy()
  })

  it('tidak mengunci sebelum batas 15 menit terlewati', async () => {
    vi.useFakeTimers()
    render(<App />)

    await act(async () => {
      vi.advanceTimersByTime(14 * 60 * 1000)
    })

    // Masih dalam sesi: layar masuk belum muncul.
    expect(screen.queryByText('Masuk Pegawai')).toBeNull()
  })
})
