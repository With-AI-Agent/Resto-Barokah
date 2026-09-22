/**
 * Uji LayarDapur (T4-01 + T4-10): FIFO dari waktu kirim peladen, pemisahan
 * bagian, keadaan kosong/muat/gagal, cadangan "Tertunda", dan mode layar besar.
 */
// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { LayarDapur, urutFifo, saringBagian } from './LayarDapur'
import type { TiketPesanan } from './KartuPesanan'

afterEach(() => {
  cleanup()
})

function tiket(
  id: string,
  nomor: number,
  dikirimPada: string,
  items: TiketPesanan['items'],
): TiketPesanan {
  return { id, nomor, tipe: 'dinein', meja: String(nomor), dikirimPada, items }
}

const ITEM_DAPUR = (id: string) => ({
  id,
  menuItemId: `menu-${id}`,
  namaSaatItu: 'Nasi Goreng',
  qty: 1,
  catatan: null,
  status: 'baru' as const,
  tujuan: 'dapur' as const,
})

const ITEM_BAR = (id: string) => ({
  id,
  menuItemId: `menu-${id}`,
  namaSaatItu: 'Jus Jeruk',
  qty: 1,
  catatan: null,
  status: 'baru' as const,
  tujuan: 'bar' as const,
})

const WAKTU = '2026-09-22T10:30:00.000Z'

describe('LayarDapur (T4-01)', () => {
  it('mengurutkan tiket FIFO: tertua di atas, dari waktu kirim peladen', () => {
    const data = [
      tiket('baru', 2, '2026-09-22T10:20:00.000Z', [ITEM_DAPUR('i2')]),
      tiket('tua', 1, '2026-09-22T10:05:00.000Z', [ITEM_DAPUR('i1')]),
    ]
    render(<LayarDapur tiket={data} waktuSekarang={WAKTU} />)
    const papan = screen.getByTestId('papan-antrean')
    const urut = [...papan.children].map((n) => n.getAttribute('data-testid'))
    expect(urut).toEqual(['kartu-tua', 'kartu-baru'])
  })

  it('hanya menampilkan bagian dapur — tiket khusus bar tidak ikut', () => {
    const data = [
      tiket('campur', 3, '2026-09-22T10:10:00.000Z', [ITEM_DAPUR('i3'), ITEM_BAR('i4')]),
      tiket('minum-saja', 4, '2026-09-22T10:11:00.000Z', [ITEM_BAR('i5')]),
    ]
    render(<LayarDapur tiket={data} waktuSekarang={WAKTU} />)
    expect(screen.getByTestId('kartu-campur')).toBeTruthy()
    expect(screen.queryByTestId('kartu-minum-saja')).toBeNull()
  })

  it('tombol status mengalir ke pemanggil (mulai masak)', () => {
    const onMulai = vi.fn()
    render(
      <LayarDapur
        tiket={[tiket('t1', 1, '2026-09-22T10:00:00.000Z', [ITEM_DAPUR('i1')])]}
        waktuSekarang={WAKTU}
        onMulaiMasak={onMulai}
      />,
    )
    fireEvent.click(screen.getByTestId('mulai-i1'))
    expect(onMulai).toHaveBeenCalledWith('i1')
  })

  it('penanda habis per menu dari kartu tiket memanggil onTandaiHabis', () => {
    const onHabis = vi.fn()
    render(
      <LayarDapur
        tiket={[tiket('t1', 1, '2026-09-22T10:00:00.000Z', [ITEM_DAPUR('i1')])]}
        waktuSekarang={WAKTU}
        onTandaiHabis={onHabis}
      />,
    )
    fireEvent.click(screen.getByTestId('tombol-habis'))
    fireEvent.click(screen.getByTestId('tombol-habis-ya'))
    expect(onHabis).toHaveBeenCalledWith('menu-i1', 'Nasi Goreng')
  })
})

describe('LayarDapur (T4-10 — keadaan & ketahanan)', () => {
  it('keadaan kosong ramah', () => {
    render(<LayarDapur tiket={[]} waktuSekarang={WAKTU} />)
    expect(screen.getByText('Tidak ada antrean pesanan yang perlu dimasak.')).toBeTruthy()
  })

  it('keadaan memuat tampil, bukan layar putih', () => {
    render(<LayarDapur tiket={[]} waktuSekarang={WAKTU} keadaan="memuat" />)
    expect(screen.getByRole('status')).toBeTruthy()
  })

  it('keadaan gagal punya tombol coba lagi', () => {
    const onCoba = vi.fn()
    render(<LayarDapur tiket={[]} waktuSekarang={WAKTU} keadaan="gagal" onCoba={onCoba} />)
    fireEvent.click(screen.getByText('Coba lagi'))
    expect(onCoba).toHaveBeenCalled()
  })

  it('saat "sebagian/tertunda": antrean cadangan tampil dengan tanda Tertunda', () => {
    const cadangan = [tiket('lokal', 9, '2026-09-22T09:00:00.000Z', [ITEM_DAPUR('i9')])]
    render(
      <LayarDapur tiket={[]} waktuSekarang={WAKTU} keadaan="sebagian" antreanCadangan={cadangan} />,
    )
    expect(screen.getByTestId('kartu-lokal')).toBeTruthy()
    expect(screen.getByText(/Tertunda/)).toBeTruthy()
    expect(screen.getByTestId('layar-dapur').getAttribute('data-tertunda')).toBe('ya')
  })

  it('gagal dengan cadangan: pesanan terakhir tetap terlihat', () => {
    const cadangan = [tiket('lokal', 9, '2026-09-22T09:00:00.000Z', [ITEM_DAPUR('i9')])]
    render(
      <LayarDapur tiket={[]} waktuSekarang={WAKTU} keadaan="gagal" antreanCadangan={cadangan} />,
    )
    expect(screen.getByTestId('kartu-lokal')).toBeTruthy()
  })

  it('mode TV membesarkan tata letak (ditandai pada wadah)', () => {
    render(<LayarDapur tiket={[]} waktuSekarang={WAKTU} modeTv />)
    expect(screen.getByTestId('layar-dapur').getAttribute('data-mode-tv')).toBe('ya')
  })
})

describe('pembantu LayarDapur', () => {
  it('urutFifo tidak mengubah argumen aslinya', () => {
    const data = [
      tiket('b', 2, '2026-09-22T10:20:00.000Z', [ITEM_DAPUR('i2')]),
      tiket('a', 1, '2026-09-22T10:05:00.000Z', [ITEM_DAPUR('i1')]),
    ]
    const hasil = urutFifo(data)
    expect(hasil.map((t) => t.id)).toEqual(['a', 'b'])
    expect(data.map((t) => t.id)).toEqual(['b', 'a'])
  })

  it('saringBagian mengabaikan item batal saat menilai tiket', () => {
    const data = [
      tiket('x', 1, '2026-09-22T10:00:00.000Z', [{ ...ITEM_DAPUR('i1'), status: 'batal' }]),
    ]
    expect(saringBagian(data, 'dapur')).toHaveLength(0)
  })
})
