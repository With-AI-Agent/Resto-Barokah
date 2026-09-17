// @vitest-environment jsdom
import { beforeAll, describe, expect, it } from 'vitest'
import { TEMA } from '../lib/tema'
// Berkas gaya NYATA (bukan salinan di dalam uji) diimpor apa adanya; Vitest
// dikonfigurasi `css: true` supaya isinya benar-benar dipasang ke dokumen uji.
import './token/tema.css'
import './komponen.css'

/**
 * Uji KASKADE NYATA atas berkas gaya sungguhan.
 *
 * Kenapa ada: dua cacat yang dilaporkan pemilik 2026-09-17 —
 *   (1) tombol Nyaman/Padat "tidak berefek", karena aturannya hanya mengubah kelas
 *       prototipe yang tidak dipakai aplikasi; dan
 *   (2) tema terasa cuma sedikit padahal jumlahnya 10.
 * Uji ini **mengukur angka** pada kedua mode kerapatan dan memastikan kesepuluh tema
 * benar-benar mendefinisikan tampilan yang berbeda. Kalau kelak ada yang mematikan
 * efeknya lagi (seperti kejadian itu), uji ini MERAH.
 */

function pasang(density: string, theme = 'terang') {
  document.documentElement.setAttribute('data-density', density)
  document.documentElement.setAttribute('data-theme', theme)
  document.body.innerHTML = `
    <div class="halaman">
      <div class="card" id="kartu"><div class="card-head"><h3>Contoh</h3></div><p>x</p></div>
      <div class="kisi-2"><div class="card">a</div><div class="card">b</div></div>
      <div class="baris-rapat" id="baris">a</div>
      <table class="table"><tbody><tr><td id="sel">x</td></tr></tbody></table>
    </div>`
}

/** Ganti var(--x) dengan nilai yang benar-benar berlaku di dokumen. */
function selesaikan(nilai: string): string {
  const akar = getComputedStyle(document.documentElement)
  return nilai.replace(
    /var\((--[a-z0-9-]+)\)/gi,
    (_, nama: string) => akar.getPropertyValue(nama).trim() || '0px',
  )
}

function ukuran(selector: string, properti: string): number {
  const el = document.querySelector(selector)
  expect(el, `elemen ${selector} tidak ada`).toBeTruthy()
  const nilai = selesaikan(getComputedStyle(el as Element).getPropertyValue(properti))
  const angka = Number.parseFloat(nilai)
  expect(Number.isNaN(angka), `${selector} ${properti} = "${nilai}" tidak bisa dibaca`).toBe(false)
  return angka
}

describe('kerapatan (Nyaman vs Padat) benar-benar mengubah ukuran', () => {
  const hasil: Record<string, { kartu: number; sel: number; baris: number; huruf: number }> = {}

  beforeAll(() => {
    for (const mode of ['nyaman', 'padat']) {
      pasang(mode)
      hasil[mode] = {
        kartu: ukuran('#kartu', 'padding'),
        sel: ukuran('#sel', 'padding'),
        baris: ukuran('#baris', 'padding'),
        huruf: Number.parseFloat(getComputedStyle(document.body).fontSize),
      }
    }
  })

  it('kartu lebih rapat di mode Padat (angka, bukan klaim)', () => {
    expect(hasil.padat.kartu).toBeLessThan(hasil.nyaman.kartu)
    expect(hasil.padat.kartu).toBeGreaterThanOrEqual(12)
  })

  it('baris tabel lebih rapat di mode Padat', () => {
    expect(hasil.padat.sel).toBeLessThan(hasil.nyaman.sel)
  })

  it('baris contoh lebih rapat di mode Padat', () => {
    expect(hasil.padat.baris).toBeLessThan(hasil.nyaman.baris)
  })

  it('huruf TIDAK dikecilkan (keterbacaan & daerah sentuh dijaga)', () => {
    expect(hasil.padat.huruf).toBe(hasil.nyaman.huruf)
  })

  it('ganti kerapatan tidak mengubah warna (hanya jarak)', () => {
    pasang('nyaman')
    const aksenNyaman = getComputedStyle(document.documentElement)
      .getPropertyValue('--accent')
      .trim()
    pasang('padat')
    const aksenPadat = getComputedStyle(document.documentElement)
      .getPropertyValue('--accent')
      .trim()
    expect(aksenPadat).toBe(aksenNyaman)
  })
})

describe('sepuluh tema benar-benar ada dan berbeda', () => {
  /** jsdom tidak menyubstitusi var() berantai; resolver kecil ini yang menyelesaikannya. */
  function nilaiToken(kode: string, token: string): string {
    document.documentElement.setAttribute('data-theme', kode)
    let nilai = getComputedStyle(document.documentElement).getPropertyValue(token).trim()
    for (let i = 0; i < 4 && nilai.startsWith('var('); i += 1) {
      const m = /^var\((--[a-z0-9-]+)\)$/i.exec(nilai)
      if (!m) break
      nilai = getComputedStyle(document.documentElement).getPropertyValue(m[1]).trim()
    }
    return nilai
  }

  it('jumlah tema 10 (bukan 5)', () => {
    expect(TEMA.length).toBe(10)
  })

  it('kesepuluh tema berbeda satu sama lain (bukan 10 label untuk 5 tampilan)', () => {
    const sidik = TEMA.map((butir) =>
      ['--accent', '--surface', '--text', '--font-display']
        .map((token) => nilaiToken(butir.kode, token))
        .join(' | '),
    )
    for (const [i, s] of sidik.entries()) {
      expect(
        s.replace(/\s/g, '').length,
        `tema ${TEMA[i].kode} tidak punya warna/ huruf`,
      ).toBeGreaterThan(10)
    }
    const kembar = sidik.filter((s, i) => sidik.indexOf(s) !== i)
    expect(kembar, 'ada tema yang tampilannya kembar').toHaveLength(0)
    expect(new Set(sidik).size).toBe(TEMA.length)
  })
})
