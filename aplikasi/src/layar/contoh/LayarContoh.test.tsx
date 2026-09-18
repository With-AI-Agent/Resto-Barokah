import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import LayarContoh from './LayarContoh'
import { TEMA } from '../../lib/tema'

/**
 * Uji asap layar contoh: membuktikan pohon komponen React (TSX) benar-benar
 * bisa dirender, memakai kelas rancangan v3, dan semua bagiannya terpasang.
 */
describe('LayarContoh', () => {
  const html = renderToStaticMarkup(<LayarContoh />)

  it('menampilkan judul aplikasi', () => {
    expect(html).toContain('<h1>Sajian</h1>')
  })

  it('menampilkan total belanja terformat rupiah', () => {
    expect(html).toContain('Rp27.500')
  })

  it('memakai kelas rancangan (btn, card, chip, table)', () => {
    expect(html).toContain('class="btn btn-primary"')
    expect(html).toContain('class="card"')
    expect(html).toContain('class="chip chip-warn"')
    expect(html).toContain('class="table"')
  })

  it('menampilkan ketiga keadaan halaman', () => {
    expect(html).toContain('keadaan-kosong')
    expect(html).toContain('keadaan-memuat')
    expect(html).toContain('keadaan-gagal')
  })

  it('tombol pemilih menyebut jumlah seluruh tema', () => {
    // Sejak panel pemilih dibuat tertutup-dulu (2026-09-17), daftar tema TIDAK ada di
    // markup sebelum dibuka — jadi di sini hanya yang bisa dibuktikan tanpa interaksi:
    // tombolnya menyebut jumlah tema yang tersedia. Isi daftarnya (semua tema bisa
    // dipilih) dikunci uji interaksi `kerapatan.test.tsx` yang membuka panelnya dulu.
    expect(html).toContain(`Ganti tema (${TEMA.length})`)
    expect(TEMA.length).toBe(10)
  })

  it('menyediakan pilihan kerapatan', () => {
    expect(html).toContain('class="segmen"')
    expect(html).toContain('Nyaman')
    expect(html).toContain('Padat')
  })

  it('menampilkan status pengaturan rahasia', () => {
    expect(html).toContain('VITE_SUPABASE_URL')
    expect(html).toContain('VITE_SUPABASE_ANON_KEY')
  })
})
