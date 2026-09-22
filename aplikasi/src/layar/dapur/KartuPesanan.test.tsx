/**
 * Uji KartuPesanan (T4-03 + T4-08).
 * T4-03: lencana tipe pesanan + catatan khusus mencolok + nomor meja jelas.
 * T4-08: penanda waktu berubah setelah ambang (bisa diatur) berdasarkan WAKTU PELADEN.
 */
// @vitest-environment jsdom
import { describe, expect, it, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { KartuPesanan, umurMenit, tingkatWaktu, type TiketPesanan } from './KartuPesanan'

afterEach(() => {
  cleanup()
})

const WAKTU_AWAL = '2026-09-22T10:00:00.000Z'

function tiketContoh(overrides: Partial<TiketPesanan> = {}): TiketPesanan {
  return {
    id: 'tiket-1',
    nomor: 101,
    tipe: 'dinein',
    meja: '5',
    dikirimPada: WAKTU_AWAL,
    items: [
      {
        id: 'item-1',
        menuItemId: 'menu-1',
        namaSaatItu: 'Nasi Goreng',
        qty: 2,
        catatan: 'Tanpa pedas, alergi kacang',
        status: 'baru',
        tujuan: 'dapur',
      },
      {
        id: 'item-2',
        menuItemId: 'menu-2',
        namaSaatItu: 'Jus Jeruk',
        qty: 1,
        catatan: null,
        status: 'dimasak',
        tujuan: 'bar',
      },
    ],
    ...overrides,
  }
}

function waktuSetelah(menit: number): string {
  return new Date(new Date(WAKTU_AWAL).getTime() + menit * 60_000).toISOString()
}

describe('KartuPesanan (T4-03)', () => {
  it('menampilkan nomor pesanan, lencana tipe, dan nomor meja dengan jelas', () => {
    render(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(1)} />)
    expect(screen.getByText('No. 101')).toBeTruthy()
    expect(screen.getByText('Dine-in')).toBeTruthy()
    expect(screen.getByTestId('meja-kartu').textContent).toContain('Meja 5')
  })

  it('menampilkan tipe bawa pulang & ojol dengan labelnya (tanpa nomor meja)', () => {
    const { rerender } = render(
      <KartuPesanan
        tiket={tiketContoh({ tipe: 'bawa_pulang', meja: null })}
        waktuSekarang={waktuSetelah(1)}
      />,
    )
    expect(screen.getByText('Bawa Pulang')).toBeTruthy()
    expect(screen.queryByTestId('meja-kartu')).toBeNull()
    rerender(
      <KartuPesanan
        tiket={tiketContoh({ tipe: 'ojol', meja: null })}
        waktuSekarang={waktuSetelah(1)}
      />,
    )
    expect(screen.getByText('Ojol')).toBeTruthy()
  })

  it('catatan khusus tampil besar & mencolok pada itemnya', () => {
    render(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(1)} />)
    const catatan = screen.getByTestId('catatan-item-item-1')
    expect(catatan.textContent).toContain('Tanpa pedas, alergi kacang')
  })

  it('hanya menampilkan bagian yang diminta (dapur tidak melihat item bar)', () => {
    render(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(1)} bagian="dapur" />)
    expect(screen.getByTestId('baris-item-item-1')).toBeTruthy()
    expect(screen.queryByTestId('baris-item-item-2')).toBeNull()
    cleanup()
    render(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(1)} bagian="bar" />)
    expect(screen.getByTestId('baris-item-item-2')).toBeTruthy()
    expect(screen.queryByTestId('baris-item-item-1')).toBeNull()
  })

  it('tombol sesuai status item: baru → Mulai Masak, dimasak → Siap Saji', () => {
    const onMulai = vi.fn()
    const onSiap = vi.fn()
    render(
      <KartuPesanan
        tiket={tiketContoh()}
        waktuSekarang={waktuSetelah(1)}
        onMulaiMasak={onMulai}
        onSelesaiMasak={onSiap}
      />,
    )
    fireEvent.click(screen.getByTestId('mulai-item-1'))
    expect(onMulai).toHaveBeenCalledWith('item-1')
    expect(screen.queryByTestId('siap-item-1')).toBeNull()
  })
})

describe('KartuPesanan (T4-08 — penanda waktu)', () => {
  it('umur dihitung dari waktu peladen yang disuntik, bukan jam perangkat', () => {
    expect(umurMenit(WAKTU_AWAL, waktuSetelah(0))).toBe(0)
    expect(umurMenit(WAKTU_AWAL, waktuSetelah(12))).toBe(12)
    // Waktu mundur / tanggal rusak tidak memblokir layar (dibulatkan nol).
    expect(umurMenit(waktuSetelah(10), WAKTU_AWAL)).toBe(0)
    expect(umurMenit('bukan-tanggal', waktuSetelah(5))).toBe(0)
  })

  it('penanda berubah setelah ambang bawaan 10 & 20 menit', () => {
    expect(tingkatWaktu(5)).toBe('biasa')
    expect(tingkatWaktu(10)).toBe('waspada')
    expect(tingkatWaktu(19)).toBe('waspada')
    expect(tingkatWaktu(20)).toBe('mendesak')
  })

  it('ambang bisa diatur dari luar (mis. 5 & 15 menit)', () => {
    expect(tingkatWaktu(7, [5, 15])).toBe('waspada')
    expect(tingkatWaktu(15, [5, 15])).toBe('mendesak')
  })

  it('warna lencana waktu mengikuti tingkat pada layar', () => {
    const { rerender } = render(
      <KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(3)} />,
    )
    expect(screen.getByTestId('penanda-waktu').getAttribute('data-tingkat')).toBe('biasa')
    rerender(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(12)} />)
    expect(screen.getByTestId('penanda-waktu').getAttribute('data-tingkat')).toBe('waspada')
    rerender(<KartuPesanan tiket={tiketContoh()} waktuSekarang={waktuSetelah(25)} />)
    expect(screen.getByTestId('penanda-waktu').getAttribute('data-tingkat')).toBe('mendesak')
  })
})
