// @vitest-environment jsdom
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { bukaLaciTercatat } from './laci'
import { klienSupabase } from './supabase'

vi.mock('./supabase', () => ({
  klienSupabase: vi.fn(),
}))

/**
 * Uji PMB1-F-010: laci HANYA terbuka bila peladen mencatat.
 * MERAH pada repo lama: modul ini (dan RPC catat_buka_laci) belum ada —
 * byte kick bisa dikirim tanpa jejak apa pun (grep "buka_laci" → 0).
 */
describe('bukaLaciTercatat (PMB1-F-010)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('menolak fail-closed bila Supabase belum dikonfigurasi', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const hasil = await bukaLaciTercatat('manual', 'tes')
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('KONFIGURASI_KURANG')
    expect(hasil.byte).toBeUndefined()
  })

  it('memanggil RPC catat_buka_laci dan menerbitkan byte HANYA setelah peladen mencatat', async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: { berhasil: true, kode: 'TERCATAT', pesan: 'Buka laci tercatat di jejak audit.' },
      error: null,
    })
    vi.mocked(klienSupabase).mockReturnValue({ rpc } as never)

    const hasil = await bukaLaciTercatat('manual', 'setoran koin')
    expect(rpc).toHaveBeenCalledWith('catat_buka_laci', {
      p_konteks: 'manual',
      p_alasan: 'setoran koin',
    })
    expect(hasil.berhasil).toBe(true)
    expect(hasil.byte).toBeInstanceOf(Uint8Array)
    // Kick ESC/POS untuk drawer: 7 byte pin pulsa bawaan (0x1B 0x70 …).
    expect(Array.from(hasil.byte as Uint8Array)).toContain(0x1b)
  })

  it('TIDAK menerbitkan byte bila peladen menolak (alasan wajib / peran)', async () => {
    const rpc = vi.fn().mockResolvedValue({
      data: {
        berhasil: false,
        kode: 'ALASAN_WAJIB',
        pesan: 'Buka laci tanpa transaksi wajib menyebut alasan.',
      },
      error: null,
    })
    vi.mocked(klienSupabase).mockReturnValue({ rpc } as never)

    const hasil = await bukaLaciTercatat('manual')
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('ALASAN_WAJIB')
    expect(hasil.byte).toBeUndefined()
  })

  it('TIDAK menerbitkan byte bila jaringan/RPC gagal (fail-closed)', async () => {
    const rpc = vi.fn().mockResolvedValue({ data: null, error: { message: 'jaringan putus' } })
    vi.mocked(klienSupabase).mockReturnValue({ rpc } as never)

    const hasil = await bukaLaciTercatat('cetak_struk_tunai')
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('PELADEN_GAGAL')
    expect(hasil.byte).toBeUndefined()
  })
})
