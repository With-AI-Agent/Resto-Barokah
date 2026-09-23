// @vitest-environment jsdom
/**
 * Uji layar pemasangan printer (T6-02).
 *
 * Yang paling dijaga: janji kepada pemilik bahwa printer merek lain tetap bisa
 * dipakai harus TERLIHAT di layar, bukan hanya benar di dalam kode.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { PasangPrinter, halamanUji } from './PasangPrinter'
import { LEBAR_58MM, LEBAR_80MM } from '../../lib/printer/expos'

afterEach(() => cleanup())

describe('PasangPrinter — janji "merek lain tetap jalan" terlihat pengguna', () => {
  it('menyediakan pilihan printer umum, bukan hanya merek terdaftar', () => {
    render(<PasangPrinter />)
    expect(screen.getByRole('option', { name: /umum \(58 mm\)/i })).toBeTruthy()
    expect(screen.getByRole('option', { name: /umum \(80 mm\)/i })).toBeTruthy()
  })

  it('memberi tahu pengguna apa yang harus dipilih bila mereknya tidak ada', () => {
    render(<PasangPrinter />)
    expect(screen.getByText(/merek Anda tidak ada di daftar/i)).toBeTruthy()
  })

  it('kelima printer pemilik tersedia sebagai jalan pintas', () => {
    render(<PasangPrinter />)
    for (const nama of [
      /Goojprt PT-210/i,
      /Kassen BT-P290/i,
      /Blueprint Lite-58/i,
      /Xprinter XP-N160II/i,
      /Epson TM-T82X/i,
    ]) {
      expect(screen.getByRole('option', { name: nama })).toBeTruthy()
    }
  })
})

describe('PasangPrinter — lebar kertas bisa diatur pengguna', () => {
  it('memilih printer 80 mm ikut mengubah lebar kertas', () => {
    render(<PasangPrinter />)
    fireEvent.change(screen.getByLabelText(/merek printer/i), {
      target: { value: 'xprinter-xpn160ii' },
    })
    expect((screen.getByLabelText(/80 mm/i) as HTMLInputElement).checked).toBe(true)
  })

  it('pengguna tetap bisa mengubah lebar sesudah memilih merek', () => {
    render(<PasangPrinter />)
    fireEvent.click(screen.getByLabelText(/80 mm/i))
    expect((screen.getByLabelText(/80 mm/i) as HTMLInputElement).checked).toBe(true)
    fireEvent.click(screen.getByLabelText(/58 mm/i))
    expect((screen.getByLabelText(/58 mm/i) as HTMLInputElement).checked).toBe(true)
  })

  it('pilihan lebar memakai kata yang bisa dipahami tanpa istilah teknis', () => {
    render(<PasangPrinter />)
    expect(screen.getByText(/selebar .?5 cm/i)).toBeTruthy()
    expect(screen.getByText(/selebar .?8 cm/i)).toBeTruthy()
  })

  it('menyimpan profil dan lebar yang dipilih', () => {
    const onSimpan = vi.fn()
    render(<PasangPrinter onSimpan={onSimpan} />)
    fireEvent.change(screen.getByLabelText(/merek printer/i), {
      target: { value: 'goojprt-pt210' },
    })
    fireEvent.click(screen.getByRole('button', { name: /simpan pengaturan printer/i }))
    expect(onSimpan).toHaveBeenCalledWith(
      expect.objectContaining({ profilId: 'goojprt-pt210', lebar: LEBAR_58MM }),
    )
  })

  it('memuat pengaturan yang sudah tersimpan', () => {
    render(<PasangPrinter tersimpan={{ profilId: 'epson-tmt82x', lebar: LEBAR_80MM }} />)
    expect((screen.getByLabelText(/merek printer/i) as HTMLSelectElement).value).toBe(
      'epson-tmt82x',
    )
    expect((screen.getByLabelText(/80 mm/i) as HTMLInputElement).checked).toBe(true)
  })

  it('menampilkan keterangan printer yang dipilih', () => {
    render(<PasangPrinter tersimpan={{ profilId: 'xprinter-xpn160ii', lebar: LEBAR_80MM }} />)
    expect(screen.getByTestId('keterangan-profil').textContent).toMatch(/pisau|laci/i)
  })
})

describe('PasangPrinter — uji cetak', () => {
  it('mengirim halaman contoh sesuai lebar yang dipilih', () => {
    const onUjiCetak = vi.fn()
    render(<PasangPrinter onUjiCetak={onUjiCetak} />)
    fireEvent.click(screen.getByRole('button', { name: /uji cetak/i }))
    expect(onUjiCetak).toHaveBeenCalledTimes(1)
    expect(onUjiCetak.mock.calls[0][0]).toBeInstanceOf(Uint8Array)
  })
})

describe('halamanUji — bukti nyata printer siap', () => {
  function baca(byte: Uint8Array): string {
    const a = Array.from(byte)
    let keluar = ''
    for (let i = 0; i < a.length; i += 1) {
      const b = a[i]
      if (b === 0x1b) {
        const c = a[i + 1]
        if (c === 0x40) i += 1
        else if (c === 0x70) i += 4
        else i += 2
        continue
      }
      if (b === 0x1d) {
        i += 2
        continue
      }
      if (b === 0x0a) {
        keluar += '\n'
        continue
      }
      if (b >= 0x20 && b <= 0x7e) keluar += String.fromCharCode(b)
    }
    return keluar
  }

  it('memuat garis selebar kertas supaya salah lebar langsung kelihatan', () => {
    const teks = baca(halamanUji(LEBAR_58MM))
    expect(teks).toContain('-'.repeat(LEBAR_58MM))
    expect(teks).toContain('UJI CETAK')
  })

  it('menyebutkan lebar yang sedang dipakai', () => {
    expect(baca(halamanUji(LEBAR_80MM))).toContain('48 kolom')
  })

  it('tidak ada baris yang melebihi lebar kertas', () => {
    for (const lebar of [LEBAR_58MM, LEBAR_80MM]) {
      for (const baris of baca(halamanUji(lebar)).split('\n')) {
        expect(baris.length).toBeLessThanOrEqual(lebar)
      }
    }
  })

  it('diakhiri potong kertas', () => {
    expect(Array.from(halamanUji(LEBAR_58MM).slice(-3))).toEqual([0x1d, 0x56, 0x00])
  })
})
