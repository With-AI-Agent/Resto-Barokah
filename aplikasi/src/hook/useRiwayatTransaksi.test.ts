// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, renderHook, waitFor } from '@testing-library/react'
import { useRiwayatTransaksi } from './useRiwayatTransaksi'
import { klienSupabase } from '../lib/supabase'

vi.mock('../lib/supabase', () => ({
  klienSupabase: vi.fn(),
}))

/**
 * Uji PMB1-F-021: riwayat transaksi = data peladen sebagaimana adanya.
 * MERAH pada repo lama: hook ini belum ada — layar riwayat menampilkan satu
 * baris sintetis (nomor 1, jam perangkat, item kosong, metode selalu Tunai).
 */
describe('useRiwayatTransaksi (PMB1-F-021)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  afterEach(() => {
    cleanup()
  })

  it('memetakan pembayaran+pesanan peladen menjadi baris riwayat apa adanya', async () => {
    const kirim = vi.fn().mockResolvedValue({
      data: [
        {
          id: 'pb-1',
          waktu: '2026-09-30T09:00:00Z',
          jumlah: 50000,
          kembalian: 2500,
          referensi: null,
          metode_nama_saat_itu: 'Tunai',
          pesanan: {
            nomor: 17,
            subtotal: 54000,
            pajak: 5400,
            service: 2700,
            total_diskon: 5000,
            total: 57100,
            dibuat_pada: '2026-09-30T08:40:00Z',
            cabang_id: 'cab-01',
            pesanan_item: [
              {
                nama_saat_itu: 'Nasi Goreng Spesial',
                harga_saat_itu: 27000,
                qty: 2,
                subtotal: 54000,
                catatan: null,
              },
            ],
          },
        },
      ],
      error: null,
    })
    const eq = vi.fn().mockReturnThis()
    const order = vi.fn().mockReturnThis()
    const limit = vi.fn().mockReturnValue(Promise.resolve({ data: undefined, error: null }))
    const selectPertama = vi.fn().mockReturnValue({
      eq,
      order,
      limit: kirim,
    })
    vi.mocked(klienSupabase).mockReturnValue({
      from: vi.fn().mockReturnValue({ select: selectPertama }),
    } as never)

    const { result } = renderHook(() => useRiwayatTransaksi('cab-01'))
    // .eq lalu .order lalu .limit — pastikan filter cabang aktif dipakai
    expect(eq).toHaveBeenCalledWith('pesanan.cabang_id', 'cab-01')

    await waitFor(() => expect(result.current.keadaan).toBe('siap'))
    expect(result.current.daftar).toHaveLength(1)
    const baris = result.current.daftar[0]
    // Nomor, tanggal, uang — semuanya dari peladen, bukan dikarang.
    expect(baris.data.nomor).toBe(17)
    expect(baris.data.tanggal).toBe('2026-09-30T08:40:00Z')
    expect(baris.data.pajak).toBe(5400)
    expect(baris.data.service).toBe(2700)
    expect(baris.data.totalDiskon).toBe(5000)
    expect(baris.data.total).toBe(57100)
    expect(baris.data.item[0]?.nama).toBe('Nasi Goreng Spesial')
    expect(baris.pembayaran?.[0]?.metode).toBe('Tunai')
    expect(baris.pembayaran?.[0]?.jumlah).toBe(50000)
    expect(baris.kembalian).toBe(2500)
  })

  it('gagal peladen diumumkan jujur (keadaan gagal + pesan), daftar tidak dikarang', async () => {
    const kirim = vi.fn().mockResolvedValue({ data: null, error: { message: 'RLS menolak' } })
    const eq = vi.fn().mockReturnThis()
    const order = vi.fn().mockReturnThis()
    const selectPertama = vi.fn().mockReturnValue({ eq, order, limit: kirim })
    vi.mocked(klienSupabase).mockReturnValue({
      from: vi.fn().mockReturnValue({ select: selectPertama }),
    } as never)

    const { result } = renderHook(() => useRiwayatTransaksi('cab-01'))
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.daftar).toHaveLength(0)
    expect(result.current.pesan).toContain('RLS menolak')
  })

  it('tanpa klien Supabase: gagal jujur, bukan daftar kosong diam-diam', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const { result } = renderHook(() => useRiwayatTransaksi('cab-01'))
    await waitFor(() => expect(result.current.keadaan).toBe('gagal'))
    expect(result.current.pesan).toContain('belum dikonfigurasi')
  })
})
