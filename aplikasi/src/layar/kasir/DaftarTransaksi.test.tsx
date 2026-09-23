// @vitest-environment jsdom
/**
 * Uji T5-10 — cari transaksi & cetak ulang struk.
 *
 * Dua hal yang dijaga paling ketat:
 *
 *  1. **Cetak ulang selalu bertanda SALINAN.** Kalau lembar kedua bisa terlihat
 *     identik dengan lembar pertama, ia bisa dipakai menagih dua kali atau
 *     diajukan sebagai dua bukti pengeluaran berbeda. Karena itu pratinjaunya pun
 *     sudah bertanda, bukan hanya hasil cetaknya.
 *  2. **Tidak ada perubahan data.** Komponen ini hanya membaca; satu-satunya
 *     keluarannya adalah `onCetakUlang`. Ada uji penjaga `?raw` yang melarang
 *     berkas ini memanggil RPC atau menulis apa pun.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { DaftarTransaksi, cocokTransaksi, type BarisTransaksi } from './DaftarTransaksi'
import isiDaftar from './DaftarTransaksi.tsx?raw'

afterEach(cleanup)

const isiTanpaKomentar = isiDaftar.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')

const T1: BarisTransaksi = {
  id: 't1',
  data: {
    nomor: 101,
    tanggal: '2026-09-23T10:15:00.000Z',
    namaResto: 'Kedai Oasis',
    item: [{ nama: 'Nasi Goreng', qty: 2, hargaSatuan: 27000, subtotal: 54000 }],
    subtotal: 54000,
    totalDiskon: 0,
    pajak: 5400,
    service: 2700,
    total: 62100,
  },
  pembayaran: [{ metode: 'Tunai', jumlah: 62100, diterima: 70000 }],
}

const T2: BarisTransaksi = {
  id: 't2',
  data: {
    nomor: 102,
    tanggal: '2026-09-23T11:30:00.000Z',
    namaResto: 'Kedai Oasis',
    item: [{ nama: 'Es Teh', qty: 1, hargaSatuan: 8000, subtotal: 8000 }],
    subtotal: 8000,
    totalDiskon: 0,
    pajak: 800,
    service: 400,
    total: 9200,
  },
}

const DAFTAR = [T1, T2]

describe('cocokTransaksi (T5-10)', () => {
  it('kata kunci kosong menampilkan semua', () => {
    expect(cocokTransaksi(T1, '')).toBe(true)
    expect(cocokTransaksi(T1, '   ')).toBe(true)
  })

  it('cocok lewat nomor struk', () => {
    expect(cocokTransaksi(T1, '101')).toBe(true)
    expect(cocokTransaksi(T2, '101')).toBe(false)
  })

  it('cocok lewat nominal, dengan atau tanpa titik ribuan', () => {
    expect(cocokTransaksi(T1, '62100')).toBe(true)
    expect(cocokTransaksi(T1, '62.100')).toBe(true)
    expect(cocokTransaksi(T2, '62100')).toBe(false)
  })

  it('cocok lewat sebagian nominal — orang jarang ingat angka persis', () => {
    expect(cocokTransaksi(T1, '621')).toBe(true)
  })
})

describe('DaftarTransaksi — pencarian', () => {
  it('menampilkan semua transaksi sebelum dicari', () => {
    render(<DaftarTransaksi daftar={DAFTAR} />)
    expect(screen.getByTestId('transaksi-101')).toBeTruthy()
    expect(screen.getByTestId('transaksi-102')).toBeTruthy()
  })

  it('menyaring sesuai kata kunci', () => {
    render(<DaftarTransaksi daftar={DAFTAR} />)
    fireEvent.change(screen.getByLabelText(/Cari transaksi/i), { target: { value: '102' } })

    expect(screen.queryByTestId('transaksi-101')).toBeNull()
    expect(screen.getByTestId('transaksi-102')).toBeTruthy()
  })

  it('memberi jalan keluar saat tidak ada yang cocok, bukan layar kosong', () => {
    render(<DaftarTransaksi daftar={DAFTAR} />)
    fireEvent.change(screen.getByLabelText(/Cari transaksi/i), { target: { value: '999999' } })

    expect(screen.getByText(/Transaksi tidak ditemukan/i)).toBeTruthy()
    expect(screen.getByText(/Coba kata kunci lain/i)).toBeTruthy()
  })
})

describe('DaftarTransaksi — cetak ulang', () => {
  it('tombol cetak ulang MATI sampai ada transaksi dipilih', () => {
    render(<DaftarTransaksi daftar={DAFTAR} onCetakUlang={vi.fn()} />)
    expect(
      (screen.getByRole('button', { name: /Cetak ulang struk/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
  })

  it('pratinjau struk SUDAH bertanda SALINAN, bukan hanya hasil cetaknya', () => {
    render(<DaftarTransaksi daftar={DAFTAR} />)
    fireEvent.click(screen.getByTestId('transaksi-101'))

    expect(screen.getByTestId('struk-salinan').textContent).toContain('SALINAN')
  })

  it('angka struk salinan sama persis dengan aslinya (cetak ulang, bukan hitung ulang)', () => {
    render(<DaftarTransaksi daftar={DAFTAR} />)
    fireEvent.click(screen.getByTestId('transaksi-101'))

    expect(screen.getByTestId('struk-total').textContent).toContain('Rp62.100')
  })

  it('mengirim baris yang dipilih ke kontainer saat dicetak ulang', () => {
    const onCetakUlang = vi.fn()
    render(<DaftarTransaksi daftar={DAFTAR} onCetakUlang={onCetakUlang} />)

    fireEvent.click(screen.getByTestId('transaksi-102'))
    fireEvent.click(screen.getByRole('button', { name: /Cetak ulang struk/i }))

    expect(onCetakUlang).toHaveBeenCalledTimes(1)
    expect(onCetakUlang.mock.calls[0][0].id).toBe('t2')
  })

  it('PENJAGA: berkas ini tidak boleh menulis apa pun (tanpa RPC, tanpa fetch)', () => {
    expect(isiTanpaKomentar).not.toMatch(/\.rpc\(/)
    expect(isiTanpaKomentar).not.toMatch(/fetch\(/)
    expect(isiTanpaKomentar).not.toMatch(/\.insert\(|\.update\(|\.delete\(/)
  })

  it('PENJAGA: pratinjau cetak ulang wajib memakai penanda salinan', () => {
    expect(isiTanpaKomentar).toMatch(/salinan\s*\/>|salinan$/m)
  })
})
