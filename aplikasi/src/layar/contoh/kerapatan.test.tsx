// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import LayarContoh from './LayarContoh'
import { KERAPATAN, TEMA } from '../../lib/tema'

/**
 * Uji INTERAKSI kontrol tampilan (permintaan pemilik 2026-09-17).
 *
 * Kenapa ada: sebelumnya uji hanya memastikan tombolnya DIRENDER, bukan bahwa
 * tombolnya BEKERJA. Cacatnya terbukti di lapangan: tombol "Padat" tidak
 * mengubah apa pun yang terlihat di layar aplikasi. Uji ini mengunci tiga hal:
 *   1) semua tema tersedia & bisa dipilih;
 *   2) kerapatan benar-benar dipasang ke elemen akar (<html data-density>);
 *   3) pilihan tersimpan dan dipakai lagi saat halaman dibuka ulang.
 * Efek visualnya sendiri dikunci uji statis `alat/periksa-kerapatan.py`
 * (token CSS wajib mengecil dan wajib menyasar kelas yang dipakai aplikasi).
 */

describe('kontrol tema & kerapatan di layar contoh', () => {
  beforeEach(() => {
    document.documentElement.dataset.theme = 'terang'
    document.documentElement.dataset.density = 'nyaman'
    localStorage.clear()
  })

  afterEach(cleanup)

  /** Buka panel tema lalu klik satu tema (panel sekarang hanya berisi daftar saat terbuka). */
  function pilihTema(nama: string) {
    const tombol = screen.getByRole('button', { name: /Pilih tema/ })
    if (tombol.getAttribute('aria-expanded') !== 'true') fireEvent.click(tombol)
    fireEvent.click(screen.getByText(nama))
  }

  it('menyediakan tombol untuk SEMUA tema (10, bukan sebagian)', () => {
    render(<LayarContoh />)
    // daftar baru muncul setelah panel dibuka (dulu selalu ter-render)
    fireEvent.click(screen.getByRole('button', { name: /Pilih tema/ }))
    for (const butir of TEMA) {
      // nama tema bisa muncul lebih dari sekali di halaman (mis. judul kartu),
      // jadi yang dipastikan adalah: tombolnya ADA dan bisa dipilih.
      const tombol = screen.getAllByText(butir.nama).some((el) => el.closest('button') !== null)
      expect(tombol, `tombol tema ${butir.nama} tidak ditemukan`).toBe(true)
    }
    expect((screen.getByText(`Ganti tema (${TEMA.length})`) as HTMLElement).textContent).toContain(
      '10',
    )
  })

  it('mengganti tema benar-benar mengubah elemen akar & tersimpan', () => {
    render(<LayarContoh />)
    pilihTema('Etnik Nusantara')
    expect(document.documentElement.dataset.theme).toBe('etnik')
    expect(localStorage.getItem('sajian.tema')).toBe('etnik')
    // status di kepala halaman ikut berubah (bukti yang bisa dilihat pemilik)
    expect(document.body.textContent).toContain('tema aktif Etnik Nusantara')
  })

  it('panel tema TERTUTUP dulu, dan bisa dibuka lewat tombolnya', () => {
    render(<LayarContoh />)
    const tombol = screen.getByRole('button', { name: /Pilih tema/ })
    expect(tombol.getAttribute('aria-expanded')).toBe('false')
    expect(screen.queryByRole('region', { name: /Pilih tema/ })).toBeNull()

    fireEvent.click(tombol)
    expect(screen.getByRole('region', { name: /Pilih tema/ })).toBeTruthy()
    expect(tombol.getAttribute('aria-expanded')).toBe('true')
  })

  it('tombol Padat benar-benar mengubah kerapatan di elemen akar & tersimpan', () => {
    render(<LayarContoh />)
    const tombolPadat = screen.getByRole('button', { name: KERAPATAN[1].nama })
    fireEvent.click(tombolPadat)
    expect(document.documentElement.dataset.density).toBe('padat')
    expect(localStorage.getItem('sajian.kerapatan')).toBe('padat')
    expect(tombolPadat.getAttribute('aria-pressed')).toBe('true')
    expect(document.body.textContent).toContain('kerapatan Padat')
  })

  it('kembali ke Nyaman juga bekerja (dua arah)', () => {
    render(<LayarContoh />)
    fireEvent.click(screen.getByRole('button', { name: 'Padat' }))
    fireEvent.click(screen.getByRole('button', { name: 'Nyaman' }))
    expect(document.documentElement.dataset.density).toBe('nyaman')
    expect(localStorage.getItem('sajian.kerapatan')).toBe('nyaman')
    expect(document.body.textContent).toContain('kerapatan Nyaman')
  })

  it('pilihan yang tersimpan dipakai lagi saat halaman dibuka ulang', () => {
    localStorage.setItem('sajian.tema', 'gelap')
    localStorage.setItem('sajian.kerapatan', 'padat')
    render(<LayarContoh />)
    expect(document.documentElement.dataset.theme).toBe('gelap')
    expect(document.documentElement.dataset.density).toBe('padat')
  })
})
