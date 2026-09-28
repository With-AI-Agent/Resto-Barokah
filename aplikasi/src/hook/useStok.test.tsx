// @vitest-environment jsdom
/**
 * Uji useStok — kabel data layar Stok (T4-06) & Opname (T4-07).
 *
 * Yang dibuktikan: pemetaan `numeric` (PostgREST mengirim string) tidak
 * membocorkan NaN ke layar, riwayat buku besar terbaca apa adanya, dan aksi
 * tulis benar-benar lewat RPC peladen (`set_stok` delta, `opname_stok` jumlah
 * fisik) lalu data dimuat ulang.
 */
import { act, renderHook, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const rpcMock = vi.fn()
const hitung = { bahan: 0, riwayat: 0 }

const BAHAN_MENTAH = [
  {
    id: 'bhn-1',
    nama: 'Beras',
    satuan: 'kg',
    jumlah: '12.500',
    minimum: '5.000',
    dipantau: true,
  },
  {
    id: 'bhn-2',
    nama: 'Gula',
    satuan: 'kg',
    jumlah: null,
    minimum: 'bukan-angka',
    dipantau: null,
  },
]

const RIWAYAT_MENTAH = [
  {
    id: 101,
    stok_bahan_id: 'bhn-1',
    jenis: 'masuk',
    jumlah: '5.000',
    alasan: 'Belanja pagi',
    waktu: '2026-09-23T01:00:00.000Z',
    stok_bahan: { nama: 'Beras' },
    pelaku: { nama: 'Bu Dapur' },
  },
  {
    id: 102,
    stok_bahan_id: 'bhn-9',
    jenis: 'jenis-aneh',
    jumlah: '-1',
    alasan: null,
    waktu: '2026-09-23T02:00:00.000Z',
    stok_bahan: [],
    pelaku: null,
  },
]

function klienPalsu(galat: 'bahan' | 'riwayat' | null = null) {
  const hasilBahan = {
    data: BAHAN_MENTAH,
    error: galat === 'bahan' ? { message: 'gagal' } : null,
  }
  const hasilRiwayat = {
    data: RIWAYAT_MENTAH,
    error: galat === 'riwayat' ? { message: 'gagal' } : null,
  }
  // `stok_bahan`: .select().order()   ·   `stok_pergerakan`: .select().order().limit()
  const rantaiBahan = {
    select: () => ({
      order: () => {
        hitung.bahan += 1
        return Promise.resolve(hasilBahan)
      },
    }),
  }
  const rantaiRiwayat = {
    select: () => ({
      order: () => ({
        limit: () => {
          hitung.riwayat += 1
          return Promise.resolve(hasilRiwayat)
        },
      }),
    }),
  }
  const saluran = {
    on: () => saluran,
    subscribe: () => ({ id: 'saluran-uji' }),
  }
  return {
    from: (tabel: string) => (tabel === 'stok_bahan' ? rantaiBahan : rantaiRiwayat),
    channel: () => saluran,
    removeChannel: vi.fn(),
    rpc: rpcMock,
  }
}

vi.mock('../lib/supabase', () => ({ klienSupabase: vi.fn() }))

import { klienSupabase } from '../lib/supabase'
import { angka, petakanBahan, petakanPergerakan, useStok } from './useStok'

describe('angka — numeric peladen ke number layar', () => {
  it('menerima string numeric, number, dan menolak yang tidak sah jadi 0', () => {
    expect(angka('12.500')).toBe(12.5)
    expect(angka('-3.25')).toBe(-3.25)
    expect(angka(7)).toBe(7)
    expect(angka('bukan-angka')).toBe(0)
    expect(angka(null)).toBe(0)
    expect(angka(undefined)).toBe(0)
    expect(Number.isNaN(angka('x'))).toBe(false)
  })
})

describe('petakanBahan & petakanPergerakan', () => {
  it('saldo & minimum jadi number, dipantau null jadi false', () => {
    expect(petakanBahan(BAHAN_MENTAH[0])).toEqual({
      id: 'bhn-1',
      nama: 'Beras',
      satuan: 'kg',
      jumlah: 12.5,
      minimum: 5,
      dipantau: true,
    })
    expect(petakanBahan(BAHAN_MENTAH[1])).toMatchObject({ jumlah: 0, minimum: 0, dipantau: false })
  })

  it('riwayat: jenis tak dikenal jadi koreksi, nama bahan/pelaku aman saat kosong', () => {
    expect(petakanPergerakan(RIWAYAT_MENTAH[0])).toEqual({
      id: '101',
      bahanId: 'bhn-1',
      namaBahan: 'Beras',
      jenis: 'masuk',
      jumlah: 5,
      alasan: 'Belanja pagi',
      oleh: 'Bu Dapur',
      waktu: '2026-09-23T01:00:00.000Z',
    })
    expect(petakanPergerakan(RIWAYAT_MENTAH[1])).toMatchObject({
      jenis: 'koreksi',
      jumlah: -1,
      alasan: null,
      oleh: null,
      namaBahan: '(bahan tidak dikenal)',
    })
  })
})

describe('useStok — kontainer data stok & opname', () => {
  beforeEach(() => {
    rpcMock.mockReset()
    rpcMock.mockResolvedValue({ data: { ok: true }, error: null })
    hitung.bahan = 0
    hitung.riwayat = 0
  })

  it('memuat saldo bahan dan buku besar sekaligus', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    expect(result.current.bahan).toHaveLength(2)
    expect(result.current.riwayat).toHaveLength(2)
    expect(result.current.bahan[0].jumlah).toBe(12.5)
    unmount()
  })

  it('salah satu sumber gagal → keadaan gagal dengan pesan, tidak melempar', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu('riwayat') as never)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('tidak bisa diambil')
    unmount()
  })

  it('catatStok memanggil set_stok dengan DELTA + alasan lalu memuat ulang', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    const sebelum = hitung.bahan
    await act(async () => {
      await result.current.catatStok('bhn-1', -2.5, 'Dipakai masak')
    })
    expect(rpcMock).toHaveBeenCalledWith('set_stok', {
      p_stok_bahan_id: 'bhn-1',
      p_jumlah: -2.5,
      p_alasan: 'Dipakai masak',
    })
    expect(hitung.bahan).toBe(sebelum + 1)
    unmount()
  })

  it('catatOpname mengirim jumlah FISIK (selisih dihitung peladen)', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    await act(async () => {
      await result.current.catatOpname('bhn-1', 11, 'Opname tutup hari')
    })
    expect(rpcMock).toHaveBeenCalledWith('opname_stok', {
      p_stok_bahan_id: 'bhn-1',
      p_jumlah_fisik: 11,
      p_alasan: 'Opname tutup hari',
    })
    unmount()
  })

  it('RPC menolak → pesan galat tampil, data tidak dikosongkan', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'tidak berizin' } })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    await act(async () => {
      await result.current.catatStok('bhn-1', 1, 'Belanja')
    })
    expect(result.current.pesan).toContain('gagal dicatat')
    expect(result.current.bahan).toHaveLength(2)
    unmount()
  })

  it('klien belum dikonfigurasi → gagal dengan pesan jujur', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const { result, unmount } = renderHook(() => useStok())
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('belum dikonfigurasi')
    unmount()
  })
})
