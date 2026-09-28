// @vitest-environment jsdom
/**
 * Uji T5-11 — tagihan ditinggal & pembayaran sebagian.
 *
 * Umur SELALU disuntik lewat prop `sekarang`. Uji yang bergantung pada jam nyata
 * akan berubah warna sendiri tengah malam atau di mesin CI dengan zona berbeda,
 * dan kegagalan semacam itu memakan waktu berjam-jam untuk didiagnosis.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import {
  BATAS_LAMA_MENIT,
  BATAS_MENDESAK_MENIT,
  DaftarTagihan,
  labelUmur,
  sisaTagihan,
  tingkatUmur,
  umurMenit,
  type BarisTagihan,
} from './DaftarTagihan'

afterEach(cleanup)

const SEKARANG = new Date('2026-09-23T12:00:00.000Z')

/** Tagihan yang dibuat `menit` yang lalu dari SEKARANG. */
function tagihan(nomor: number, menitLalu: number, sudahDibayar = 0): BarisTagihan {
  return {
    id: `t${nomor}`,
    nomor,
    dibuatPada: new Date(SEKARANG.getTime() - menitLalu * 60000).toISOString(),
    total: 100000,
    sudahDibayar,
  }
}

describe('umurMenit', () => {
  it('menghitung selisih dalam menit penuh', () => {
    expect(umurMenit(tagihan(1, 45).dibuatPada, SEKARANG)).toBe(45)
  })

  it('tidak pernah negatif walau jam perangkat meleset ke belakang', () => {
    const nanti = new Date(SEKARANG.getTime() + 10 * 60000).toISOString()
    expect(umurMenit(nanti, SEKARANG)).toBe(0)
  })
})

describe('tingkatUmur', () => {
  it('baru di bawah batas lama', () => {
    expect(tingkatUmur(BATAS_LAMA_MENIT - 1)).toBe('baru')
  })

  it('naik tepat DI batas, bukan sesudahnya', () => {
    expect(tingkatUmur(BATAS_LAMA_MENIT)).toBe('lama')
    expect(tingkatUmur(BATAS_MENDESAK_MENIT)).toBe('mendesak')
  })
})

describe('labelUmur — dibaca manusia, bukan angka mentah', () => {
  it('di bawah sejam ditulis menit', () => {
    expect(labelUmur(45)).toBe('45 menit')
  })

  it('di atas sejam ditulis jam + menit, bukan "125 menit"', () => {
    expect(labelUmur(125)).toBe('2 jam 5 menit')
  })

  it('jam bulat tidak menempelkan "0 menit"', () => {
    expect(labelUmur(120)).toBe('2 jam')
  })
})

describe('sisaTagihan', () => {
  it('total dikurangi yang sudah dibayar', () => {
    expect(sisaTagihan(tagihan(1, 5, 40000))).toBe(60000)
  })

  it('tidak pernah negatif', () => {
    expect(sisaTagihan({ ...tagihan(1, 5), total: 10000, sudahDibayar: 15000 })).toBe(0)
  })
})

describe('DaftarTagihan', () => {
  it('daftar kosong menenangkan, bukan layar putih', () => {
    render(<DaftarTagihan daftar={[]} sekarang={SEKARANG} />)
    expect(screen.getByText(/Tidak ada tagihan yang ditinggal/i)).toBeTruthy()
  })

  it('menandai umur tiap tagihan dengan tingkat yang benar', () => {
    render(
      <DaftarTagihan
        daftar={[tagihan(1, 5), tagihan(2, 45), tagihan(3, 200)]}
        sekarang={SEKARANG}
      />,
    )

    expect(screen.getByTestId('tagihan-1').getAttribute('data-umur')).toBe('baru')
    expect(screen.getByTestId('tagihan-2').getAttribute('data-umur')).toBe('lama')
    expect(screen.getByTestId('tagihan-3').getAttribute('data-umur')).toBe('mendesak')
  })

  it('menulis umur dengan bahasa manusia', () => {
    render(<DaftarTagihan daftar={[tagihan(3, 200)]} sekarang={SEKARANG} />)
    expect(screen.getByTestId('umur-3').textContent).toContain('3 jam 20 menit')
  })

  it('menonjolkan SISA — angka yang harus diucapkan kasir ke tamu', () => {
    render(<DaftarTagihan daftar={[tagihan(4, 10, 40000)]} sekarang={SEKARANG} />)
    expect(screen.getByTestId('sisa-4').textContent).toContain('Rp60.000')
  })

  it('pembayaran sebagian tetap terlihat, supaya tamu tidak merasa uangnya hilang', () => {
    render(<DaftarTagihan daftar={[tagihan(4, 10, 40000)]} sekarang={SEKARANG} />)
    expect(screen.getByTestId('terbayar-4').textContent).toContain('Rp40.000')
  })

  it('tagihan yang belum dibayar sama sekali tidak menulis baris "sudah dibayar"', () => {
    render(<DaftarTagihan daftar={[tagihan(5, 10, 0)]} sekarang={SEKARANG} />)
    expect(screen.queryByTestId('terbayar-5')).toBeNull()
  })

  it('menjelaskan keputusan MVP soal split bill, supaya kasir tidak mencari tombol yang tidak ada', () => {
    render(<DaftarTagihan daftar={[tagihan(1, 5)]} sekarang={SEKARANG} />)
    expect(screen.getByTestId('tagihan-catatan').textContent).toMatch(/bukan tagihan yang dipecah/i)
  })

  it('menyerahkan pelanjutan bayar ke kontainer — layar ini tidak mencatat uang', () => {
    const onLanjutkanBayar = vi.fn()
    render(
      <DaftarTagihan
        daftar={[tagihan(7, 10, 40000)]}
        onLanjutkanBayar={onLanjutkanBayar}
        sekarang={SEKARANG}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: /Lanjutkan pembayaran #7/i }))

    expect(onLanjutkanBayar).toHaveBeenCalledTimes(1)
    expect(onLanjutkanBayar.mock.calls[0][0].nomor).toBe(7)
  })
})
