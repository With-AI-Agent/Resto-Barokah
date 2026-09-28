// @vitest-environment jsdom
/**
 * Uji StrukDigital.tsx (T5-09) — cadangan saat printer bermasalah.
 *
 * Dua hal yang dijaga ketat di sini:
 *
 *  1. **Isi digital identik dengan struk cetak** (DoD T5-09 + mitigasi ART-7).
 *     Caranya bukan membandingkan dua gambar, melainkan memastikan komponen ini
 *     memakai `<Struk>` yang sama dan tidak pernah menghitung uang sendiri — ada
 *     uji penjaga berbasis `?raw` untuk itu. Kalau suatu hari struk digital
 *     digambar ulang secara terpisah, cepat atau lambat angkanya akan berbeda
 *     dari kertas, dan itu baru ketahuan saat pelanggan protes.
 *
 *  2. **Tombol yang tidak didukung peramban disembunyikan**, bukan ditampilkan
 *     lalu gagal saat ditekan. Kasir yang sedang diburu antrean tidak boleh
 *     menebak tombol mana yang benar-benar bekerja.
 */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { StrukDigital, ringkasanTeks, bisaBagikan, bisaSalin } from './StrukDigital'
import type { DataStruk } from './Struk'
import isiStrukDigital from './StrukDigital.tsx?raw'

/** Angka yang sama dengan Struk.test.tsx: subtotal 54.000, PB1 10%, service 5%. */
const DASAR: DataStruk = {
  nomor: 101,
  tanggal: '2026-09-23T10:15:00.000Z',
  namaResto: 'Kedai Oasis',
  item: [{ nama: 'Nasi Goreng', qty: 2, hargaSatuan: 27000, subtotal: 54000 }],
  subtotal: 54000,
  totalDiskon: 0,
  pajak: 5400,
  service: 2700,
  total: 62100,
}

const LUNAS = [{ metode: 'Tunai', jumlah: 62100, diterima: 70000 }]

/** Komentar dibuang dulu — penjaga `?raw` gampang tertipu teks di komentar. */
const isiTanpaKomentar = isiStrukDigital
  .replace(/\/\*[\s\S]*?\*\//g, '')
  .replace(/^\s*\/\/.*$/gm, '')

const navigatorAsli = { ...globalThis.navigator }

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
})

beforeEach(() => {
  // Bawaan jsdom: tidak ada share maupun clipboard. Setiap uji memasang sendiri
  // kemampuan yang ingin diperiksa, supaya tidak saling bocor.
  Object.defineProperty(globalThis.navigator, 'share', { value: undefined, configurable: true })
  Object.defineProperty(globalThis.navigator, 'clipboard', {
    value: undefined,
    configurable: true,
  })
  void navigatorAsli
})

function pasangShare(impl: () => Promise<void>) {
  Object.defineProperty(globalThis.navigator, 'share', { value: impl, configurable: true })
}

function pasangClipboard(impl: () => Promise<void>) {
  Object.defineProperty(globalThis.navigator, 'clipboard', {
    value: { writeText: impl },
    configurable: true,
  })
}

describe('ringkasanTeks (T5-09)', () => {
  it('memuat nomor, total, dan status lunas — cukup dibaca sekilas di chat', () => {
    const teks = ringkasanTeks(DASAR, true)
    expect(teks).toContain('No. 101')
    expect(teks).toContain('Rp62.100')
    expect(teks).toContain('LUNAS')
  })

  it('tidak berbohong soal lunas bila memang belum dibayar', () => {
    const teks = ringkasanTeks(DASAR, false)
    expect(teks).toContain('Belum lunas')
    expect(teks).not.toContain('LUNAS —')
  })

  it('memakai total dari peladen apa adanya, tidak menghitung ulang', () => {
    // Total sengaja TIDAK sama dengan subtotal+pajak+service (ada pembulatan).
    const teks = ringkasanTeks({ ...DASAR, total: 62000 }, true)
    expect(teks).toContain('Rp62.000')
  })
})

describe('StrukDigital — isi sama dengan struk cetak', () => {
  it('menampilkan struk yang sama, bukan gambar ulang', () => {
    render(<StrukDigital data={DASAR} pembayaran={LUNAS} />)
    expect(screen.getByTestId('struk')).toBeTruthy()
    expect(screen.getByTestId('struk-total').textContent).toContain('Rp62.100')
  })

  it('PENJAGA: berkas ini tidak boleh menghitung uang sendiri', () => {
    // Tidak ada aritmetika atas medan uang selain menjumlah pembayaran yang
    // sudah jadi. Bila suatu saat ada `data.subtotal + ...`, uji ini berteriak.
    expect(isiTanpaKomentar).not.toMatch(/data\.subtotal\s*[-+*/]/)
    expect(isiTanpaKomentar).not.toMatch(/data\.pajak\s*[-+*/]/)
    expect(isiTanpaKomentar).not.toMatch(/data\.service\s*[-+*/]/)
  })

  it('PENJAGA: tetap memakai komponen Struk bersama (satu tampilan semua jalur)', () => {
    expect(isiTanpaKomentar).toMatch(/<Struk\s/)
  })

  it('menjelaskan alasan kenapa pelanggan tidak menerima kertas', () => {
    render(<StrukDigital data={DASAR} alasan="Printer tidak merespons" />)
    expect(screen.getByTestId('struk-digital-alasan').textContent).toContain(
      'Printer tidak merespons',
    )
  })
})

describe('StrukDigital — jalan penyerahan', () => {
  it('tombol Bagikan disembunyikan bila peramban tidak mendukung', () => {
    render(<StrukDigital data={DASAR} />)
    expect(bisaBagikan()).toBe(false)
    expect(screen.queryByRole('button', { name: /Bagikan struk/i })).toBeNull()
  })

  it('tombol Salin disembunyikan bila peramban tidak mendukung', () => {
    render(<StrukDigital data={DASAR} />)
    expect(bisaSalin()).toBe(false)
    expect(screen.queryByRole('button', { name: /Salin ringkasan struk/i })).toBeNull()
  })

  it('Simpan PDF SELALU tersedia — ini jalan yang paling pasti ada', () => {
    render(<StrukDigital data={DASAR} />)
    expect(screen.getByRole('button', { name: /Simpan struk sebagai PDF/i })).toBeTruthy()
  })

  it('Simpan PDF memanggil dialog cetak peramban', () => {
    const print = vi.fn()
    Object.defineProperty(window, 'print', { value: print, configurable: true })
    render(<StrukDigital data={DASAR} />)

    fireEvent.click(screen.getByRole('button', { name: /Simpan struk sebagai PDF/i }))
    expect(print).toHaveBeenCalledTimes(1)
  })

  it('Bagikan mengirim ringkasan yang benar bila didukung', async () => {
    const share = vi.fn().mockResolvedValue(undefined)
    pasangShare(share)
    render(<StrukDigital data={DASAR} pembayaran={LUNAS} />)

    fireEvent.click(screen.getByRole('button', { name: /Bagikan struk/i }))
    await waitFor(() => expect(share).toHaveBeenCalledTimes(1))
    expect(share.mock.calls[0][0].text).toContain('Rp62.100')
    expect(share.mock.calls[0][0].text).toContain('LUNAS')
  })

  it('berbagi yang dibatalkan TIDAK dianggap kegagalan menakutkan', async () => {
    pasangShare(() => Promise.reject(new Error('AbortError')))
    render(<StrukDigital data={DASAR} pembayaran={LUNAS} />)

    fireEvent.click(screen.getByRole('button', { name: /Bagikan struk/i }))
    await waitFor(() =>
      expect(screen.getByTestId('struk-digital-kabar').textContent).toContain('masih bisa'),
    )
  })

  it('Salin teks menaruh ringkasan ke papan klip dan memberi tahu kasir', async () => {
    const tulis = vi.fn().mockResolvedValue(undefined)
    pasangClipboard(tulis)
    render(<StrukDigital data={DASAR} pembayaran={LUNAS} />)

    fireEvent.click(screen.getByRole('button', { name: /Salin ringkasan struk/i }))
    await waitFor(() => expect(tulis).toHaveBeenCalledTimes(1))
    expect(tulis.mock.calls[0][0]).toContain('No. 101')
    expect(screen.getByTestId('struk-digital-kabar').textContent).toContain('disalin')
  })

  it('gagal menyalin diberitahukan apa adanya, bukan diam-diam', async () => {
    pasangClipboard(() => Promise.reject(new Error('ditolak')))
    render(<StrukDigital data={DASAR} pembayaran={LUNAS} />)

    fireEvent.click(screen.getByRole('button', { name: /Salin ringkasan struk/i }))
    await waitFor(() =>
      expect(screen.getByTestId('struk-digital-kabar').textContent).toContain('Gagal menyalin'),
    )
  })
})
