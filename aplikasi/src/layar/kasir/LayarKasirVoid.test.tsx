// @vitest-environment jsdom
/**
 * Uji sambungan LayarKasir → VoidItem (T5-06) + penjaga anti-kambuh.
 *
 * Yang DULU SALAH di `LayarKasir.tsx`: satu-satunya jalan menghapus item adalah
 *
 *     setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== id))
 *
 * dipakai untuk SEMUA keadaan. Untuk keranjang draf itu benar. Untuk item yang
 * sudah tercatat di peladen itu celah: item hilang dari layar tanpa alasan,
 * tanpa pelaku, tanpa jejak — sementara database punya tabel `pembatalan`
 * beserta pagarnya (`picu_pembatalan_sah`, migrasi 0015) yang tidak pernah
 * dipakai siapa pun. Laporan pembatalan harian jadi selalu kosong walau kasir
 * membatalkan puluhan item.
 *
 * Sesudah T5-06: bila kontainer memasang `onBatalkanItem`, penghapusan WAJIB
 * lewat dialog alasan, dan item baru hilang dari layar setelah peladen menerima.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import { PenyediaBahasa } from '../../bahasa'
import isiLayarKasir from './LayarKasir.tsx?raw'

afterEach(cleanup)

/** Komentar dibuang dulu — penjaga `?raw` gampang tertipu teks di dalam komentar. */
const isiTanpaKomentar = isiLayarKasir.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')

function tambahSatuItem() {
  fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))
}

function klikHapus() {
  const tombol = screen.getAllByRole('button', { name: /Hapus item/i })
  fireEvent.click(tombol[tombol.length - 1])
}

describe('LayarKasir — void item butuh alasan (T5-06)', () => {
  it('keranjang draf (tanpa onBatalkanItem): hapus langsung, tidak mengganggu kasir', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )
    tambahSatuItem()
    klikHapus()

    expect(screen.queryByTestId('void-item')).toBeNull()
  })

  it('item tercatat (ada onBatalkanItem): hapus membuka dialog alasan, bukan langsung hilang', () => {
    const onBatalkanItem = vi.fn()
    render(
      <PenyediaBahasa>
        <LayarKasir onBatalkanItem={onBatalkanItem} />
      </PenyediaBahasa>,
    )
    tambahSatuItem()
    klikHapus()

    expect(screen.getByTestId('void-item')).toBeTruthy()
    expect(onBatalkanItem).not.toHaveBeenCalled()
  })

  it('alasan ikut terkirim ke peladen bersama id itemnya', async () => {
    const onBatalkanItem = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <PenyediaBahasa>
        <LayarKasir onBatalkanItem={onBatalkanItem} />
      </PenyediaBahasa>,
    )
    tambahSatuItem()
    klikHapus()
    fireEvent.click(screen.getByRole('button', { name: 'Salah input kasir' }))
    fireEvent.click(screen.getByRole('button', { name: /Batalkan & catat alasan/i }))

    await waitFor(() => expect(onBatalkanItem).toHaveBeenCalledTimes(1))
    expect(onBatalkanItem.mock.calls[0][0].alasan).toBe('Salah input kasir')
    expect(typeof onBatalkanItem.mock.calls[0][0].itemId).toBe('string')
  })

  it('item TETAP di keranjang bila peladen menolak (tidak lenyap diam-diam)', async () => {
    const onBatalkanItem = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Anda tidak berizin membatalkan pesanan sebelum dapur mulai.',
    })
    render(
      <PenyediaBahasa>
        <LayarKasir onBatalkanItem={onBatalkanItem} />
      </PenyediaBahasa>,
    )
    tambahSatuItem()
    klikHapus()
    fireEvent.click(screen.getByRole('button', { name: 'Menu habis' }))
    fireEvent.click(screen.getByRole('button', { name: /Batalkan & catat alasan/i }))

    await waitFor(() =>
      expect(screen.getByTestId('void-pesan').textContent).toContain('tidak berizin'),
    )
    expect(screen.getByTestId('void-item')).toBeTruthy()
  })

  it('peringatan PIN atasan muncul bila pesanan sudah masuk dapur', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir onBatalkanItem={vi.fn()} sudahKeDapur />
      </PenyediaBahasa>,
    )
    tambahSatuItem()
    klikHapus()

    expect(screen.getByTestId('void-peringatan-dapur')).toBeTruthy()
  })
})

describe('LayarKasir — penjaga anti-kambuh void (T5-06)', () => {
  it('penghapusan tanpa syarat tidak boleh jadi satu-satunya jalur lagi', () => {
    // Filter masih ada (jalur draf), tetapi HARUS dijaga percabangan onBatalkanItem.
    expect(isiTanpaKomentar).toMatch(/onBatalkanItem/)
    expect(isiTanpaKomentar).toMatch(/if \(!onBatalkanItem\)/)
  })

  it('item hanya dibuang setelah peladen menjawab berhasil', () => {
    expect(isiTanpaKomentar).toMatch(/hasil\?\.berhasil/)
  })
})
