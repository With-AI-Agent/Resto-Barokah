// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { LayarPelangganPublik } from './LayarPelangganPublik'
import { PenyediaBahasa } from '../../bahasa'
import * as supabaseLib from '../../lib/supabase'

describe('Layar Pelanggan Publik (LayarPelangganPublik.tsx — Kontrak UI W-8-02)', () => {
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  it('menampilkan keadaan memuat (loading state) sesuai kontrak', () => {
    render(
      <PenyediaBahasa>
        <LayarPelangganPublik keadaanPaksa="memuat" />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Memuat katalog menu lezat...')).toBeDefined()
  })

  it('menampilkan keadaan gagal (error state) dan tombol coba lagi sesuai kontrak', () => {
    render(
      <PenyediaBahasa>
        <LayarPelangganPublik keadaanPaksa="gagal" />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Gagal memuat katalog menu. Silakan muat ulang.')).toBeDefined()
    expect(screen.getByRole('button', { name: /coba lagi/i })).toBeDefined()
  })

  it('menampilkan keadaan kosong (empty state) saat menu kosong sesuai kontrak', () => {
    render(
      <PenyediaBahasa>
        <LayarPelangganPublik keadaanPaksa="kosong" />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Belum ada menu yang tersedia untuk cabang ini.')).toBeDefined()
  })

  it('merender katalog menu publik lengkap dalam keadaan berhasil', () => {
    render(
      <PenyediaBahasa>
        <LayarPelangganPublik keadaanPaksa="berhasil" />
      </PenyediaBahasa>,
    )

    expect(screen.getByTestId('merek-nama-resto')).toBeDefined()
    expect(screen.getByTestId('banner-resto')).toBeDefined()
    expect(screen.getByTestId('kisi-menu')).toBeDefined()
  })

  it('memanggil RPC katalog_publik dari klien Supabase ketika penyewaId diberikan', async () => {
    const rpcMock = vi.fn().mockResolvedValue({
      data: {
        penyewa: { id: 'penyewa-123', nama: 'Resto Segar', slug: 'resto-segar' },
        cabang: { id: 'cab-456', nama: 'Cabang Segar 1', alamat: 'Jl. Merdeka 1' },
        pengaturan: { nama_resto: 'Resto Segar', tema: 'tropis' },
        kategori: [{ id: 'k-1', nama: 'Minuman' }],
        menu: [{ id: 'm-1', kategori_id: 'k-1', nama: 'Jus Alpukat', harga: 15000 }],
      },
      error: null,
    })

    vi.spyOn(supabaseLib, 'klienSupabase').mockReturnValue({
      rpc: rpcMock,
    } as unknown as ReturnType<typeof supabaseLib.klienSupabase>)

    render(
      <PenyediaBahasa>
        <LayarPelangganPublik penyewaId="penyewa-123" cabangId="cab-456" />
      </PenyediaBahasa>,
    )

    // Memastikan RPC katalog_publik dipanggil dengan parameter yang tepat
    expect(rpcMock).toHaveBeenCalledWith('katalog_publik', {
      p_penyewa_id: 'penyewa-123',
      p_cabang_id: 'cab-456',
    })

    // Konten dari data RPC muncul di layar
    const judulResto = await screen.findAllByText('Resto Segar')
    expect(judulResto.length).toBeGreaterThanOrEqual(1)
    const itemMenu = await screen.findByText('Jus Alpukat')
    expect(itemMenu).toBeDefined()
  })
})
