// @vitest-environment jsdom
import { act, cleanup, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { useTema } from './useTema'

/**
 * Uji pemilih tema (T0-10).
 * Yang dijaga: tema & kerapatan benar-benar menempel ke elemen akar (tanpa muat
 * ulang halaman), tersimpan untuk kunjungan berikutnya, dan sisa simpanan yang
 * tidak dikenal tidak membuat aplikasi salah tampil.
 */

function PemilihTema() {
  const { tema, kerapatan, gantiTema, gantiKerapatan } = useTema()
  return (
    <div>
      <span data-testid="tema">{tema}</span>
      <span data-testid="kerapatan">{kerapatan}</span>
      <button type="button" onClick={() => gantiTema('vintage')}>
        ke vintage
      </button>
      <button type="button" onClick={() => gantiKerapatan('padat')}>
        ke padat
      </button>
    </div>
  )
}

beforeEach(() => {
  localStorage.clear()
  document.documentElement.removeAttribute('data-theme')
  document.documentElement.removeAttribute('data-density')
})

afterEach(() => {
  cleanup()
  localStorage.clear()
})

describe('useTema', () => {
  it('memasang tema bawaan ke elemen akar', () => {
    render(<PemilihTema />)
    expect(screen.getByTestId('tema').textContent).toBe('terang')
    expect(document.documentElement.dataset.theme).toBe('terang')
    expect(document.documentElement.dataset.density).toBe('nyaman')
  })

  it('mengganti tema tanpa memuat ulang halaman', () => {
    render(<PemilihTema />)
    act(() => {
      screen.getByText('ke vintage').click()
    })
    expect(screen.getByTestId('tema').textContent).toBe('vintage')
    expect(document.documentElement.dataset.theme).toBe('vintage')
    expect(localStorage.getItem('sajian.tema')).toBe('vintage')
  })

  it('mengganti kerapatan dan menyimpannya', () => {
    render(<PemilihTema />)
    act(() => {
      screen.getByText('ke padat').click()
    })
    expect(document.documentElement.dataset.density).toBe('padat')
    expect(localStorage.getItem('sajian.kerapatan')).toBe('padat')
  })

  it('membaca kembali pilihan yang tersimpan', () => {
    localStorage.setItem('sajian.tema', 'etnik')
    localStorage.setItem('sajian.kerapatan', 'padat')
    render(<PemilihTema />)
    expect(screen.getByTestId('tema').textContent).toBe('etnik')
    expect(document.documentElement.dataset.theme).toBe('etnik')
  })

  it('mengabaikan simpanan yang tidak dikenal (tidak membuat aplikasi rusak)', () => {
    localStorage.setItem('sajian.tema', 'tema-hantu')
    render(<PemilihTema />)
    expect(screen.getByTestId('tema').textContent).toBe('terang')
    expect(document.documentElement.dataset.theme).toBe('terang')
  })
})
