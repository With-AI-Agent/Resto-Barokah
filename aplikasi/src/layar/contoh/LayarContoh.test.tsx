import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import LayarContoh from './LayarContoh'
import { TEMA } from '../../lib/tema'

/**
 * Uji asap layar contoh: membuktikan pohon komponen React (TSX) benar-benar
 * bisa dirender, memakai kelas rancangan v3, dan 10 tema terpasang di pemilih.
 */
describe('LayarContoh', () => {
  const html = renderToStaticMarkup(<LayarContoh />)

  it('menampilkan judul aplikasi', () => {
    expect(html).toContain('<h1>Sajian</h1>')
  })

  it('menampilkan total belanja terformat rupiah', () => {
    expect(html).toContain('Rp27.500')
  })

  it('memakai kelas rancangan (btn, card, chip)', () => {
    expect(html).toContain('class="btn btn-primary"')
    expect(html).toContain('class="card"')
    expect(html).toContain('class="chip chip-warn"')
  })

  it('menyediakan tombol untuk seluruh tema', () => {
    const jumlah = html.split('aria-pressed').length - 1
    expect(jumlah).toBeGreaterThanOrEqual(TEMA.length)
    for (const butir of TEMA) {
      expect(html).toContain(`<strong>${butir.nama}</strong>`)
    }
  })

  it('menyediakan pilihan kerapatan', () => {
    expect(html).toContain('class="segmen"')
    expect(html).toContain('Nyaman')
    expect(html).toContain('Padat')
  })
})
