// @vitest-environment jsdom
/**
 * Uji useBayar — kabel data layar Bayar (T5-01).
 *
 * Yang dibuktikan: metode bayar dimuat dari peladen dengan penyaring `aktif`,
 * pencatatan uang benar-benar lewat RPC `bayar_pesanan` (bukan insert tabel),
 * kunci idempoten STABIL per tagihan + urutan pembayaran (dobel tekan tidak
 * menambah uang), balasan peladen dipetakan tanpa NaN, dan kegagalan jaringan
 * tampil sebagai keadaan `gagal`/pesan — bukan layar kosong yang menipu.
 */
import { act, renderHook, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const rpcMock = vi.fn()
let filterAktif: unknown = null

const METODE_MENTAH = [
  { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuh_referensi: false, urutan: '1' },
  { id: 'm-qris', nama: 'QRIS', jenis: 'non_tunai', butuh_referensi: true, urutan: '2' },
]

function klienPalsu(galat: 'metode' | null = null) {
  const hasil = {
    data: METODE_MENTAH,
    error: galat === 'metode' ? { message: 'metode bayar tidak bisa diambil' } : null,
  }
  // `metode_bayar`: .select().eq('aktif', true).order().order()
  const rantai = {
    select: () => ({
      eq: (kolom: string, nilai: unknown) => {
        filterAktif = { kolom, nilai }
        return {
          order: () => ({
            order: () => Promise.resolve(hasil),
          }),
        }
      },
    }),
  }
  return { from: () => rantai, rpc: rpcMock }
}

vi.mock('../lib/supabase', () => ({ klienSupabase: vi.fn() }))

import { klienSupabase } from '../lib/supabase'
import { angka, kunciIdempoten, petakanBalasan, petakanMetode, useBayar } from './useBayar'

const PESANAN = 'eeee0000-0000-0000-0000-000000000010'

function balasanUji(tambahan: Record<string, unknown> = {}) {
  return {
    berhasil: true,
    kode: 'BY-200',
    pesan: 'Pembayaran sebagian tercatat.',
    pembayaran_id: 'pem-1',
    jumlah: '30000',
    kembalian: '20000',
    total_dibayar: '30000',
    total_pesanan: '62100',
    lunas: false,
    dobel: false,
    ...tambahan,
  }
}

describe('pemetaan angka & metode (numeric/string peladen → number layar)', () => {
  it('angka: string numeric diterima, yang tidak sah jadi 0 (bukan NaN)', () => {
    expect(angka('62100')).toBe(62100)
    expect(angka(1500)).toBe(1500)
    expect(angka('bukan-angka')).toBe(0)
    expect(angka(null)).toBe(0)
    expect(angka(undefined)).toBe(0)
    expect(Number.isNaN(angka('x'))).toBe(false)
  })

  it('petakanMetode: non-tunai wajib referensi, tunai tidak', () => {
    expect(petakanMetode(METODE_MENTAH[0])).toEqual({
      id: 'm-tunai',
      nama: 'Tunai',
      jenis: 'tunai',
      butuhReferensi: false,
      urutan: 1,
    })
    expect(petakanMetode(METODE_MENTAH[1])).toMatchObject({
      jenis: 'non_tunai',
      butuhReferensi: true,
    })
  })

  it('petakanBalasan: angka uang jadi number, tanda lunas/dobel ketat', () => {
    expect(petakanBalasan(balasanUji() as never)).toEqual({
      jumlah: 30000,
      kembalian: 20000,
      totalDibayar: 30000,
      totalPesanan: 62100,
      lunas: false,
      dobel: false,
    })
    expect(petakanBalasan(null)).toEqual({
      jumlah: 0,
      kembalian: 0,
      totalDibayar: 0,
      totalPesanan: 0,
      lunas: false,
      dobel: false,
    })
  })

  it('kunciIdempoten stabil untuk tagihan + urutan yang sama', () => {
    expect(kunciIdempoten(PESANAN, 1)).toBe(`bayar-${PESANAN}-1`)
    expect(kunciIdempoten(PESANAN, 1)).toBe(kunciIdempoten(PESANAN, 1))
    expect(kunciIdempoten(PESANAN, 2)).not.toBe(kunciIdempoten(PESANAN, 1))
  })
})

describe('useBayar', () => {
  beforeEach(() => {
    rpcMock.mockReset()
    filterAktif = null
    vi.mocked(klienSupabase).mockReset()
  })

  it('memuat metode bayar dengan penyaring aktif = true', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    expect(filterAktif).toEqual({ kolom: 'aktif', nilai: true })
    expect(result.current.metode).toHaveLength(2)
    expect(result.current.metode[0].nama).toBe('Tunai')
    unmount()
  })

  it('gagal memuat metode → keadaan gagal + pesan peladen, tidak melempar', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu('metode') as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('metode bayar tidak bisa diambil')
    unmount()
  })

  it('tanpa tagihan terpilih → gagal dengan pesan, tidak ada RPC', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(null))
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('Tidak ada tagihan')
    expect(rpcMock).not.toHaveBeenCalled()
    unmount()
  })

  it('bayar memanggil RPC bayar_pesanan dengan kunci idempoten urutan ke-1', async () => {
    rpcMock.mockResolvedValue({ data: balasanUji(), error: null })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))

    let hasil: unknown = null
    await act(async () => {
      hasil = await result.current.bayar({
        metodeId: 'm-tunai',
        jumlah: 30000,
        diterima: 50000,
      })
    })

    expect(rpcMock).toHaveBeenCalledWith('bayar_pesanan', {
      p_pesanan_id: PESANAN,
      p_metode_id: 'm-tunai',
      p_jumlah: 30000,
      p_diterima: 50000,
      p_referensi: null,
      p_kunci_idempoten: `bayar-${PESANAN}-1`,
    })
    expect(result.current.keadaan).toBe('berhasil')
    expect(result.current.terakhir).toMatchObject({
      jumlah: 30000,
      kembalian: 20000,
      sisa: 32100,
      lunas: false,
    })
    expect(hasil).toMatchObject({ kembalian: 20000 })
    unmount()
  })

  it('pembayaran berikutnya memakai kunci urutan ke-2 (bukan kunci yang sama)', async () => {
    rpcMock.mockResolvedValue({ data: balasanUji(), error: null })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))

    await act(async () => {
      await result.current.bayar({ metodeId: 'm-tunai', jumlah: 30000, diterima: 30000 })
      await result.current.lanjut()
      await result.current.bayar({ metodeId: 'm-qris', jumlah: 32100, referensi: 'QRIS-1' })
    })

    const kunci = rpcMock.mock.calls.map((panggilan) => panggilan[1].p_kunci_idempoten)
    expect(kunci).toEqual([`bayar-${PESANAN}-1`, `bayar-${PESANAN}-2`])
    unmount()
  })

  it('balasan dobel tidak memajukan urutan kunci (uang tidak dicatat dua kali)', async () => {
    rpcMock.mockResolvedValue({ data: balasanUji({ dobel: true }), error: null })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))

    await act(async () => {
      await result.current.bayar({ metodeId: 'm-tunai', jumlah: 30000, diterima: 30000 })
      await result.current.bayar({ metodeId: 'm-tunai', jumlah: 30000, diterima: 30000 })
    })

    const kunci = rpcMock.mock.calls.map((panggilan) => panggilan[1].p_kunci_idempoten)
    expect(kunci).toEqual([`bayar-${PESANAN}-1`, `bayar-${PESANAN}-1`])
    expect(result.current.terakhir?.dobel).toBe(true)
    unmount()
  })

  it('RPC menolak (mis. BY-301) → kembali siap + pesan peladen apa adanya', async () => {
    rpcMock.mockResolvedValue({
      data: null,
      error: { message: 'BY-301: pembayaran 40000 membuat total dibayar 70000 melebihi total.' },
    })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu() as never)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))

    let hasil: unknown = 'belum'
    await act(async () => {
      hasil = await result.current.bayar({ metodeId: 'm-tunai', jumlah: 40000, diterima: 40000 })
    })

    expect(hasil).toBeNull()
    expect(result.current.keadaan).toBe('siap')
    expect(result.current.pesan).toContain('BY-301')
    unmount()
  })

  it('klien Supabase belum dikonfigurasi → gagal, tidak melempar', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const { result, unmount } = renderHook(() => useBayar(PESANAN))
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('belum dikonfigurasi')
    unmount()
  })
})
