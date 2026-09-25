import { describe, it, expect } from 'vitest'
import { buatQrMatriks, buatQrSvg } from './qrcode'

describe('Generator QR Code Ringan (qrcode.ts)', () => {
  it('berhasil menghasilkan matriks QR versi 1 untuk teks pendek', () => {
    const matriks = buatQrMatriks('HELLO')
    expect(matriks.length).toBe(21)
    expect(matriks[0].length).toBe(21)
    // Tiga finder pattern pada pojok-pojok wajib bernilai true di (0,0), (0, 20), (20, 0)
    expect(matriks[0][0]).toBe(true)
    expect(matriks[0][20]).toBe(true)
    expect(matriks[20][0]).toBe(true)
  })

  it('berhasil menghasilkan matriks QR untuk URL panjang katalog publik', () => {
    const url = 'https://resto-barokah.fatrizmubarok.workers.dev/menu?resto=kedai-oasis'
    const matriks = buatQrMatriks(url)
    expect(matriks.length).toBeGreaterThanOrEqual(33)
    expect(matriks[0][0]).toBe(true)
  })

  it('menghasilkan string SVG yang valid dengan path dan ukuran yang sesuai', () => {
    const svg = buatQrSvg('https://example.com/menu', { ukuran: 250, margin: 4 })
    expect(svg).toContain('<svg')
    expect(svg).toContain('width="250"')
    expect(svg).toContain('height="250"')
    expect(svg).toContain('<rect')
    expect(svg).toContain('<path')
    expect(svg).toContain('</svg>')
  })

  it('melempar pesan galat jika teks melebihi kapasitas maksimum', () => {
    const teksSangatPanjang = 'A'.repeat(500)
    expect(() => buatQrMatriks(teksSangatPanjang)).toThrow(/terlalu panjang/)
  })
})
