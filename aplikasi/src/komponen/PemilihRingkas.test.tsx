// @vitest-environment jsdom
// Catatan alat: pemeriksa memakai assertion bawaan Vitest (bukan jest-dom),
// mengikuti gaya uji lain di repo ini yang tidak memasang pustaka matcher tambahan.
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { PemilihRingkas } from './PemilihRingkas'

/**
 * Uji perilaku penutupan panel pilihan — kelas cacat "kontrol yang tidak bisa
 * ditutup dengan cara yang lazim" (laporan pemilik 2026-09-17: panel tema hanya
 * bisa ditutup dengan mengklik tombolnya lagi; Esc dan klik-di-luar tidak jalan).
 * Aturannya dari WAI-ARIA APG (disclosure) + panduan menu aksesibel.
 *
 * Catatan alat: berkas ini memakai `fireEvent` (bawaan @testing-library/react)
 * agar tidak menambah pustaka baru — paket `user-event` sengaja tidak dipakai
 * supaya `npm audit` tetap 0 kerentanan.
 */

afterEach(cleanup)

function siapkan(onPilih = vi.fn()) {
  const { container } = render(
    <div>
      <PemilihRingkas label="Pilih tema" anakTombol="Ganti tema (10)" judulPanel="Pilih tema">
        <button type="button" onClick={onPilih}>
          Hangat Kedai
        </button>
        <button type="button">Gelap Dapur</button>
      </PemilihRingkas>
      <button type="button">Tombol lain di luar</button>
    </div>,
  )
  return {
    tombol: screen.getByRole('button', { name: 'Pilih tema' }),
    wadah: container.querySelector('.picker') as HTMLElement,
    onPilih,
  }
}

const panel = () => screen.queryByRole('region', { name: 'Pilih tema' })
const diLuar = () => screen.getByRole('button', { name: 'Tombol lain di luar' })

describe('PemilihRingkas — cara menutup panel', () => {
  it('tertutup sejak awal; keadaan diumumkan lewat aria-expanded + aria-controls', () => {
    const { tombol } = siapkan()
    expect(panel()).toBeNull()
    expect(tombol.getAttribute('aria-expanded')).toBe('false')
    expect((tombol.getAttribute('aria-controls') || '').length).toBeGreaterThan(0)

    fireEvent.click(tombol)
    expect(panel()).not.toBeNull()
    expect(tombol.getAttribute('aria-expanded')).toBe('true')
    expect(panel()?.getAttribute('id')).toBe(tombol.getAttribute('aria-controls'))
    expect(panel()?.getAttribute('aria-labelledby')).toBe(tombol.id)
  })

  it('menutup dengan tombol Esc dan MENGEMBALIKAN fokus ke tombolnya', () => {
    const { tombol } = siapkan()
    fireEvent.click(tombol)
    expect(panel()).not.toBeNull()

    fireEvent.keyDown(document, { key: 'Escape' })
    expect(panel()).toBeNull()
    expect(document.activeElement).toBe(tombol)
  })

  it('menutup saat mengetuk di LUAR panel', () => {
    const { tombol } = siapkan()
    fireEvent.click(tombol)
    expect(panel()).not.toBeNull()

    fireEvent(diLuar(), new Event('pointerdown', { bubbles: true }))
    expect(panel()).toBeNull()
  })

  it('TIDAK menutup saat mengetuk di dalam panel', () => {
    const { tombol } = siapkan()
    fireEvent.click(tombol)
    fireEvent.click(screen.getByText('Pilih tema'))
    expect(panel()).not.toBeNull()
  })

  it('menutup setelah sebuah pilihan dipilih, fokus pulang ke tombol', () => {
    const { tombol, onPilih } = siapkan()
    fireEvent.click(tombol)
    fireEvent.click(screen.getByRole('button', { name: 'Hangat Kedai' }))

    expect(onPilih).toHaveBeenCalledTimes(1)
    expect(panel()).toBeNull()
    expect(document.activeElement).toBe(tombol)
  })

  it('menutup saat fokus pindah keluar panel (APG: fokus keluar = tutup)', () => {
    const { tombol, wadah } = siapkan()
    fireEvent.click(tombol)
    expect(panel()).not.toBeNull()

    fireEvent.focusOut(wadah, { relatedTarget: diLuar() })
    expect(panel()).toBeNull()
  })

  it('TIDAK menutup saat fokus berpindah ANTAR isi panel', () => {
    const { tombol, wadah } = siapkan()
    fireEvent.click(tombol)

    fireEvent.focusOut(wadah, {
      relatedTarget: screen.getByRole('button', { name: 'Gelap Dapur' }),
    })
    expect(panel()).not.toBeNull()
  })

  it('tombol yang sama juga bisa menutup panel (perilaku lama tetap jalan)', () => {
    const { tombol } = siapkan()
    fireEvent.click(tombol)
    fireEvent.click(tombol)
    expect(panel()).toBeNull()
  })
})
