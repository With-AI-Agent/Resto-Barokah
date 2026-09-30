// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  ambilKlaimTunda,
  hapusKlaimTunda,
  klaimVoucherDiPeladen,
  simpanKlaimTunda,
  type KlaimTunda,
} from './voucher'
import { klienSupabase } from './supabase'

vi.mock('./supabase', () => ({
  klienSupabase: vi.fn(),
}))

/**
 * Uji PMB1-F-031/F-032 — kontrak `lib/voucher.ts`:
 * kode voucher HANYA dari peladen (RPC `daftar_voucher`), fail-closed, dan
 * klaim tunda tersimpan/dibersihkan dengan benar. Uji ini WAJIB bisa MERAH:
 * kalau modul mulai sukses palsu (mis. menerbitkan hasil tanpa RPC) atau
 * tidak lagi fail-closed, kasus di bawah pecah.
 */
const KLAIM_CONTOH: KlaimTunda = {
  penyewaId: 'pny-01',
  kampanyeId: 'kmp-01',
  nama: 'Budi Santoso',
  email: 'budi@contoh.id',
  setujuPrivasi: true,
  caraMasuk: 'google',
  disimpanPada: '2026-09-30T01:00:00.000Z',
}

function mockKlien(tambahan: Record<string, unknown> = {}) {
  const klien = { rpc: vi.fn(), auth: { getSession: vi.fn() }, ...tambahan }
  vi.mocked(klienSupabase).mockReturnValue(klien as never)
  return klien
}

describe('klaimVoucherDiPeladen — kegagalan fail-closed', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('tanpa klien Supabase → KONFIGURASI_KURANG, tanpa data voucher', async () => {
    vi.mocked(klienSupabase).mockReturnValue(null)
    const hasil = await klaimVoucherDiPeladen({
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('KONFIGURASI_KURANG')
    expect(hasil.data).toBeUndefined()
  })

  it('tanpa penyewa → PENYEWA_KURANG (tidak menebak penyewa)', async () => {
    mockKlien()
    const hasil = await klaimVoucherDiPeladen({
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('PENYEWA_KURANG')
  })

  it('jalur google/email tanpa email & tanpa sesi → EMAIL_WAJIB', async () => {
    const klien = mockKlien()
    klien.auth.getSession.mockResolvedValue({ data: { session: null } })
    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: '',
      setujuPrivasi: true,
      caraMasuk: 'google',
    })
    expect(klien.auth.getSession).toHaveBeenCalledTimes(1)
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('EMAIL_WAJIB')
  })

  it('gagal RPC → PELADEN_GAGAL dengan pesan galat', async () => {
    const klien = mockKlien()
    klien.rpc.mockResolvedValue({ data: null, error: { message: 'verifikasi wajib' } })
    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('PELADEN_GAGAL')
    expect(hasil.pesan).toContain('verifikasi wajib')
  })

  it('RPC meledak (jaringan) → JARINGAN_GAGAL, tanpa sukses palsu', async () => {
    const klien = mockKlien()
    klien.rpc.mockRejectedValue(new Error('jaringan putus'))
    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('JARINGAN_GAGAL')
  })
})

describe('klaimVoucherDiPeladen — jalur sukses (kode HANYA dari peladen)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('memanggil RPC daftar_voucher dengan argumen tepat dan meneruskan jawaban apa adanya', async () => {
    const klien = mockKlien()
    const jawabanPeladen = {
      berhasil: true,
      kode: 'SUKSES',
      pesan: 'Voucher berhasil diterbitkan.',
      data: { kode_voucher: 'BRK-ABC123', nilai: 20000 },
    }
    klien.rpc.mockResolvedValue({ data: jawabanPeladen, error: null })

    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi Santoso',
      email: 'budi@contoh.id',
      telepon: '0812',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })

    expect(klien.rpc).toHaveBeenCalledWith('daftar_voucher', {
      p_penyewa_id: 'pny-01',
      p_kampanye_id: 'kmp-01',
      p_nama: 'Budi Santoso',
      p_email: 'budi@contoh.id',
      p_telepon: '0812',
      p_alamat: null,
      p_persetujuan_privasi: true,
      p_cara_masuk: 'email',
    })
    expect(hasil).toEqual(jawabanPeladen)
    expect(hasil.data?.kode_voucher).toBe('BRK-ABC123')
  })

  it('email kosong pada jalur google diisi dari sesi peladen (bukan dikarang)', async () => {
    const klien = mockKlien()
    klien.auth.getSession.mockResolvedValue({
      data: { session: { user: { email: 'Budi@Contoh.ID' } } },
    })
    klien.rpc.mockResolvedValue({ data: { berhasil: true, kode: 'SUKSES' }, error: null })

    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: '',
      setujuPrivasi: true,
      caraMasuk: 'google',
    })

    expect(hasil.berhasil).toBe(true)
    expect(klien.rpc).toHaveBeenCalledWith(
      'daftar_voucher',
      expect.objectContaining({ p_email: 'Budi@Contoh.ID' }),
    )
  })

  it('jawaban peladen yang gagal diteruskan apa adanya (tidak disulap sukses)', async () => {
    const klien = mockKlien()
    klien.rpc.mockResolvedValue({
      data: { berhasil: false, kode: 'VOUCHER_SUDAH_DIKLAIM', pesan: 'sudah' },
      error: null,
    })
    const hasil = await klaimVoucherDiPeladen({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
    })
    expect(hasil.berhasil).toBe(false)
    expect(hasil.kode).toBe('VOUCHER_SUDAH_DIKLAIM')
  })
})

describe('klaim tunda di localStorage (PMB1-F-032)', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  it('simpan → ambil → hapus: roundtrip utuh', () => {
    simpanKlaimTunda(KLAIM_CONTOH)
    expect(ambilKlaimTunda()).toEqual(KLAIM_CONTOH)
    hapusKlaimTunda()
    expect(ambilKlaimTunda()).toBeNull()
  })

  it('isi rusak/bukan JSON → null (tidak meledak)', () => {
    localStorage.setItem('klaim_voucher_tunda', '{{{bukan json')
    expect(ambilKlaimTunda()).toBeNull()
    localStorage.setItem('klaim_voucher_tunda', JSON.stringify({ aneh: true }))
    expect(ambilKlaimTunda()).toBeNull()
  })
})
