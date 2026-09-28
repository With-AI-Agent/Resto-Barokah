// @vitest-environment jsdom
/**
 * Uji useTiketDapur — kabel data layar dapur/bar (sisa Fase 4 butir c).
 *
 * Yang dibuktikan di sini bukan "komponen bisa digambar" (itu tugas
 * LayarDapur.test.tsx), melainkan tanggung jawab kontainer:
 *  - pemetaan baris peladen → tiket layar (tipe `takeaway` → `bawa_pulang`,
 *    tujuan tak dikenal → `dapur`, waktu kirim kosong → waktu dibuat),
 *  - waktu yang dipakai adalah WAKTU PELADEN (kepala `Date`), bukan jam perangkat,
 *  - jaringan putus + ada cadangan → keadaan `sebagian` (layar memasang "Tertunda"),
 *  - aksi tulis lewat RPC peladen, lalu antrean dimuat ulang.
 */
import { act, renderHook, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { TiketPesanan } from '../layar/dapur/KartuPesanan'

const rpcMock = vi.fn()
const muatUlangHitung = { query: 0 }

/** Waktu peladen palsu yang dikembalikan RPC `waktu_peladen` (migrasi 0038). */
const WAKTU_PELADEN = '2026-09-23T02:06:30.000Z'

interface PilihanMock {
  data?: unknown[] | null
  error?: { message: string } | null
}

function klienPalsu(pilihan: PilihanMock = {}) {
  const hasil = {
    data: pilihan.data ?? [],
    error: pilihan.error ?? null,
  }
  const pembangun = {
    select: () => pembangun,
    eq: () => pembangun,
    in: () => pembangun,
    order: () => {
      muatUlangHitung.query += 1
      return Promise.resolve(hasil)
    },
  }
  const saluran = {
    on: () => saluran,
    subscribe: () => ({ id: 'saluran-uji' }),
  }
  return {
    from: () => pembangun,
    channel: () => saluran,
    removeChannel: vi.fn(),
    rpc: rpcMock,
  }
}

vi.mock('../lib/supabase', () => ({ klienSupabase: vi.fn() }))

import { klienSupabase } from '../lib/supabase'
import {
  keadaanPapanDari,
  namaMeja,
  petakanTiket,
  useTiketDapur,
  uuidSah,
  type BarisPesananDapur,
} from './useTiketDapur'

const BARIS: BarisPesananDapur = {
  id: 'psn-1',
  nomor: 12,
  tipe: 'takeaway',
  dibuat_pada: '2026-09-23T02:00:00.000Z',
  dikirim_ke_dapur_pada: '2026-09-23T02:05:00.000Z',
  meja: { nama: 'M-04' },
  pesanan_item: [
    {
      id: 'itm-1',
      menu_item_id: 'mn-1',
      nama_saat_itu: 'Nasi Goreng',
      qty: 2,
      catatan: 'tanpa sambal',
      status: 'dimasak',
      tujuan: 'dapur',
    },
    {
      id: 'itm-2',
      menu_item_id: 'mn-2',
      nama_saat_itu: 'Es Teh',
      qty: 1,
      catatan: null,
      status: 'aneh-tak-dikenal',
      tujuan: null,
    },
  ],
}

describe('petakanTiket — baris peladen ke tiket layar', () => {
  it('menerjemahkan tipe pesanan peladen ke label layar', () => {
    expect(petakanTiket(BARIS).tipe).toBe('bawa_pulang')
    expect(petakanTiket({ ...BARIS, tipe: 'dinein' }).tipe).toBe('dinein')
    expect(petakanTiket({ ...BARIS, tipe: 'ojol' }).tipe).toBe('ojol')
    expect(petakanTiket({ ...BARIS, tipe: 'tak-dikenal' }).tipe).toBe('dinein')
  })

  it('memakai waktu kirim peladen untuk FIFO, jatuh ke waktu dibuat bila kosong', () => {
    expect(petakanTiket(BARIS).dikirimPada).toBe('2026-09-23T02:05:00.000Z')
    expect(petakanTiket({ ...BARIS, dikirim_ke_dapur_pada: null }).dikirimPada).toBe(
      '2026-09-23T02:00:00.000Z',
    )
  })

  it('tidak membuang item bernilai tak dikenal: status jadi baru, tujuan jadi dapur', () => {
    const tiket = petakanTiket(BARIS)
    expect(tiket.items[0]).toMatchObject({ status: 'dimasak', tujuan: 'dapur', qty: 2 })
    expect(tiket.items[1]).toMatchObject({
      namaSaatItu: 'Es Teh',
      status: 'baru',
      tujuan: 'dapur',
      catatan: null,
    })
  })

  it('membaca nama meja dari bentuk objek maupun array jawaban PostgREST', () => {
    expect(namaMeja(BARIS)).toBe('M-04')
    expect(namaMeja({ ...BARIS, meja: [{ nama: 'M-07' }] })).toBe('M-07')
    expect(namaMeja({ ...BARIS, meja: [] })).toBeNull()
    expect(namaMeja({ ...BARIS, meja: null })).toBeNull()
  })

  it('menyaring UUID hanya untuk bentuk yang sah (saringan langganan realtime)', () => {
    expect(uuidSah('7b6f1a2e-6c1d-4c1a-9a3b-1f0d5e6a7b8c')).toBe(true)
    expect(uuidSah('cab-01')).toBe(false)
  })
})

describe('keadaanPapanDari — mesin keadaan papan', () => {
  it('sehat = siap; galat tanpa cadangan = gagal; galat dengan cadangan = sebagian', () => {
    expect(keadaanPapanDari(false, false)).toBe('siap')
    expect(keadaanPapanDari(false, true)).toBe('siap')
    expect(keadaanPapanDari(true, false)).toBe('gagal')
    expect(keadaanPapanDari(true, true)).toBe('sebagian')
  })
})

describe('useTiketDapur — kontainer data papan dapur', () => {
  beforeEach(() => {
    localStorage.clear()
    rpcMock.mockReset()
    rpcMock.mockImplementation((nama: string) =>
      Promise.resolve(
        nama === 'waktu_peladen'
          ? { data: { iso: WAKTU_PELADEN, epoch_ms: 1_790_000_000_000 }, error: null }
          : { data: { ok: true }, error: null },
      ),
    )
    muatUlangHitung.query = 0
  })

  it('memuat antrean dari peladen lalu melaporkan keadaan siap', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    expect(result.current.tiket).toHaveLength(1)
    expect(result.current.tiket[0].nomor).toBe(12)
    expect(result.current.pesan).toBeNull()
    unmount()
  })

  it('memakai waktu peladen dari RPC waktu_peladen, bukan jam perangkat', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    expect(result.current.waktuSekarang).toBe(WAKTU_PELADEN)
    unmount()
  })

  it('menyimpan antrean terakhir ke perangkat sebagai cadangan tampilan', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    const tersimpan = JSON.parse(localStorage.getItem('resto.antrean-terakhir.dapur') ?? '{}')
    expect(tersimpan.versi).toBe(1)
    expect(tersimpan.tiket).toHaveLength(1)
    unmount()
  })

  it('jaringan putus + ada cadangan → keadaan sebagian dengan antrean tersimpan', async () => {
    const cadangan: TiketPesanan[] = [petakanTiket(BARIS)]
    localStorage.setItem(
      'resto.antrean-terakhir.dapur',
      JSON.stringify({ versi: 1, bagian: 'dapur', tiket: cadangan, disimpanPada: 'x' }),
    )
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ error: { message: 'network' } }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('sebagian'))
    expect(result.current.antreanCadangan).toHaveLength(1)
    expect(result.current.pesan).toContain('antrean tersimpan')
    unmount()
  })

  it('jaringan putus tanpa cadangan → keadaan gagal (layar menampilkan KeadaanGagal)', async () => {
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ error: { message: 'network' } }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'bar' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.antreanCadangan).toHaveLength(0)
    unmount()
  })

  it('klien belum dikonfigurasi → gagal dengan pesan jujur, tidak melempar', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('belum dikonfigurasi')
    unmount()
  })

  it('mulaiMasak memanggil RPC set_status_item lalu memuat ulang antrean', async () => {
    rpcMock.mockResolvedValue({ data: { ok: true }, error: null })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    const sebelum = muatUlangHitung.query
    await act(async () => {
      await result.current.mulaiMasak('itm-1')
    })
    expect(rpcMock).toHaveBeenCalledWith('set_status_item', {
      p_item_id: 'itm-1',
      p_status: 'dimasak',
    })
    expect(muatUlangHitung.query).toBe(sebelum + 1)
    unmount()
  })

  it('tandaiHabis mengirim cabang + menu ke RPC tandai_habis', async () => {
    rpcMock.mockResolvedValue({ data: { ok: true }, error: null })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    await act(async () => {
      await result.current.tandaiHabis('mn-1')
    })
    expect(rpcMock).toHaveBeenCalledWith('tandai_habis', {
      p_menu_item_id: 'mn-1',
      p_cabang_id: 'cab-01',
      p_habis: true,
    })
    unmount()
  })

  it('RPC menolak → pesan galat tampil, antrean tidak dikosongkan', async () => {
    rpcMock.mockResolvedValue({ data: null, error: { message: 'izin ditolak' } })
    vi.mocked(klienSupabase).mockReturnValue(klienPalsu({ data: [BARIS] }) as never)
    const { result, unmount } = renderHook(() =>
      useTiketDapur({ cabangId: 'cab-01', bagian: 'dapur' }),
    )
    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    await act(async () => {
      await result.current.selesaiMasak('itm-1')
    })
    expect(result.current.pesan).toContain('gagal diperbarui')
    expect(result.current.tiket).toHaveLength(1)
    unmount()
  })
})
