// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, renderHook, waitFor } from '@testing-library/react'
import { useAlamatCabang } from './useAlamatCabang'
import { klienSupabase } from '../lib/supabase'

vi.mock('../lib/supabase', () => ({
  klienSupabase: vi.fn(),
}))

/**
 * Uji PMB1-F-020 — sumber alamat struk:
 * alamat WAJIB dari kolom `cabang.alamat` milik peladen (RLS `cabang_pilih`);
 * kosong/gagal → null (tanpa mengarang alamat). Uji ini WAJIB bisa MERAH:
 * kalau hook mulai mengarang alamat atau berhenti membaca peladen, kasus di
 * bawah pecah.
 */
function mockKlien(jawab: () => Promise<{ data: unknown; error: unknown }>) {
  const maybeSingle = vi.fn(jawab)
  const from = vi.fn().mockReturnValue({
    select: (kolom: string) => {
      expect(kolom).toBe('alamat')
      return {
        eq: (kolomSaring: string) => {
          expect(kolomSaring).toBe('id')
          return { maybeSingle }
        },
      }
    },
  })
  vi.mocked(klienSupabase).mockReturnValue({ from } as never)
  return { from, maybeSingle }
}

describe('useAlamatCabang (PMB1-F-020)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  it('mengambil alamat cabang dari peladen', async () => {
    const { from } = mockKlien(() =>
      Promise.resolve({ data: { alamat: 'Jl. Kenanga 99, Cimahi' }, error: null }),
    )
    const { result } = renderHook(() => useAlamatCabang('cab-01'))

    await waitFor(() => expect(result.current).toBe('Jl. Kenanga 99, Cimahi'))
    expect(from).toHaveBeenCalledWith('cabang')
  })

  it('alamat kosong di peladen → null (tidak dikarang)', async () => {
    const { maybeSingle } = mockKlien(() =>
      Promise.resolve({ data: { alamat: '   ' }, error: null }),
    )
    const { result } = renderHook(() => useAlamatCabang('cab-01'))
    await waitFor(() => expect(maybeSingle).toHaveBeenCalledTimes(1))
    await waitFor(() => expect(result.current).toBeNull())
  })

  it('galat peladen → null, tanpa meledak', async () => {
    const { maybeSingle } = mockKlien(() =>
      Promise.resolve({ data: null, error: { message: 'RLS menolak' } }),
    )
    const { result } = renderHook(() => useAlamatCabang('cab-01'))
    await waitFor(() => expect(maybeSingle).toHaveBeenCalledTimes(1))
    await waitFor(() => expect(result.current).toBeNull())
  })

  it('tanpa klien Supabase → null tanpa memanggil peladen', () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const { result } = renderHook(() => useAlamatCabang('cab-01'))
    expect(result.current).toBeNull()
  })

  it('tanpa cabangId → null tanpa memanggil peladen', () => {
    const { from } = mockKlien(() => Promise.resolve({ data: null, error: null }))
    renderHook(() => useAlamatCabang(null))
    expect(from).not.toHaveBeenCalled()
  })

  it('pindah cabang → membaca ulang dan alamat mengikuti cabang baru', async () => {
    let jawaban: { data: unknown; error: unknown } = {
      data: { alamat: 'Alamat Lama' },
      error: null,
    }
    const { maybeSingle } = mockKlien(() => Promise.resolve(jawaban))
    const { result, rerender } = renderHook(({ id }) => useAlamatCabang(id), {
      initialProps: { id: 'cab-01' },
    })
    await waitFor(() => expect(result.current).toBe('Alamat Lama'))

    jawaban = { data: { alamat: 'Alamat Baru' }, error: null }
    rerender({ id: 'cab-02' })
    await waitFor(() => expect(result.current).toBe('Alamat Baru'))
    expect(maybeSingle.mock.calls.length).toBeGreaterThanOrEqual(2)
  })
})
