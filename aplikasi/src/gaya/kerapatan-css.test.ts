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

/** Semua teks aturan gaya yang benar-benar terpasang, termasuk yang di dalam @media. */
function aturanGaya(): string[] {
  const kumpul: string[] = []
  const telusuri = (daftar: CSSRuleList) => {
    for (const aturan of Array.from(daftar)) {
      const teks = aturan.cssText ?? ''
      if (teks) kumpul.push(teks)
      const anak = (aturan as CSSMediaRule).cssRules
      if (anak && anak.length) telusuri(anak)
    }
  }
  for (const lembar of Array.from(document.styleSheets)) {
    try {
      telusuri(lembar.cssRules)
    } catch {
      /* lembar lintas-asal diabaikan */
    }
  }
  return kumpul
}

function pasang(density: string, theme = 'terang') {
  document.documentElement.setAttribute('data-density', density)
  document.documentElement.setAttribute('data-theme', theme)
  document.body.innerHTML = `
    <div class="halaman">
      <div class="card" id="kartu"><div class="card-head"><h3>Contoh</h3></div><p>x</p></div>
      <div class="kisi-2"><div class="card">a</div><div class="card">b</div></div>
      <div class="baris-rapat" id="baris">a</div>
      <table class="table"><tbody><tr><td id="sel">x</td></tr></tbody></table>
      <button class="btn" id="tombol">Simpan</button>
      <input class="input" id="isian" />
      <span class="lencana" id="lencana">Baru</span>
      <div class="picker" data-terbuka="true">
        <button class="btn btn-sm" aria-expanded="true">Ganti tema</button>
        <div class="picker-panel" id="panel-tema">
          <div class="picker-daftar" id="daftar-tema"><button>tema</button></div>
        </div>
      </div>
      <div class="segmen" id="segmen"><button>Nyaman</button></div>
    </div>`
}

/** Ganti var(--x) dengan nilai yang benar-benar berlaku di dokumen. */
function selesaikan(nilai: string): string {
  // Beberapa token kini BERANTAI (mis. --pad-v-blok: var(--s-5)), jadi penyelesaian
  // var() harus diulang sampai tidak ada lagi yang tersisa — kalau hanya sekali,
  // nilainya tetap berupa "var(...)" dan pengukuran gagal dibaca.
  const akar = getComputedStyle(document.documentElement)
  let hasil = nilai
  for (let putaran = 0; putaran < 6 && hasil.includes('var('); putaran += 1) {
    hasil = hasil.replace(
      /var\((--[a-z0-9-]+)\)/gi,
      (_, nama: string) => akar.getPropertyValue(nama).trim() || '0px',
    )
  }
  return hasil
}

/**
 * jsdom tidak mengurai shorthand yang memuat var() menjadi longhand (padding-left bisa
 * kosong). Karena itu sumbu diambil dari nilai shorthand `padding` lalu diurai sendiri;
 * rumusnya sama seperti CSS: 1 nilai = semua sisi, 2 nilai = atas-bawah / kiri-kanan.
 */
function ukuranSumbu(selector: string, sumbu: 'kiri' | 'atas' = 'kiri'): number {
  const el = document.querySelector(selector)
  expect(el, `elemen ${selector} tidak ada`).toBeTruthy()
  const mentah = getComputedStyle(el as Element)
    .getPropertyValue('padding')
    .trim()
  const bagian = selesaikan(mentah).split(/\s+/)
  const nilai = bagian.length >= 2 ? bagian[sumbu === 'kiri' ? 1 : 0] : bagian[0]
  const angka = Number.parseFloat(nilai)
  expect(Number.isNaN(angka), `${selector} padding = "${mentah}" tidak bisa dibaca`).toBe(false)
  return angka
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
  type Angka = {
    kartuAtas: number
    kartuKiri: number
    selAtas: number
    selKiri: number
    baris: number
    huruf: number
    tinggiBaris: number
    lencanaAtas: number
    lencanaKiri: number
    tombolIsi: number
    tombolTinggi: number
    isianIsi: number
    isianTinggi: number
    segmenTinggi: number
    barisTema: number
  }
  const hasil: Record<string, Angka> = {}

  function tinggiMinimal(selector: string): number {
    const nilai = selesaikan(
      getComputedStyle(document.querySelector(selector) as Element).getPropertyValue('min-height'),
    )
    return Number.parseFloat(nilai) || 0
  }

  beforeAll(() => {
    for (const mode of ['nyaman', 'padat']) {
      pasang(mode)
      hasil[mode] = {
        kartuAtas: ukuranSumbu('#kartu', 'atas'),
        kartuKiri: ukuranSumbu('#kartu', 'kiri'),
        selAtas: ukuranSumbu('#sel', 'atas'),
        selKiri: ukuranSumbu('#sel', 'kiri'),
        baris: ukuran('#baris', 'padding'),
        huruf: Number.parseFloat(getComputedStyle(document.body).fontSize),
        tinggiBaris: Number.parseFloat(selesaikan(getComputedStyle(document.body).lineHeight)),
        lencanaAtas: ukuranSumbu('#lencana', 'atas'),
        lencanaKiri: ukuranSumbu('#lencana'),
        tombolIsi: ukuranSumbu('#tombol'),
        tombolTinggi: tinggiMinimal('#tombol'),
        isianIsi: ukuranSumbu('#isian'),
        isianTinggi: tinggiMinimal('#isian'),
        segmenTinggi: tinggiMinimal('#segmen button'),
        barisTema: tinggiMinimal('#daftar-tema button'),
      }
    }
  })

  it('BLOCK HEIGHT mengecil di mode Padat (keluhan pemilik ketiga, 2026-09-17)', () => {
    expect(hasil.padat.kartuAtas, 'tepi atas-bawah kartu harus turun').toBeLessThan(
      hasil.nyaman.kartuAtas,
    )
    expect(hasil.padat.kartuAtas).toBeGreaterThanOrEqual(12)
    expect(hasil.padat.selAtas, 'tepi atas-bawah sel tabel harus turun').toBeLessThan(
      hasil.nyaman.selAtas,
    )
    expect(hasil.padat.lencanaAtas, 'lencana harus lebih tipis').toBeLessThan(
      hasil.nyaman.lencanaAtas,
    )
    expect(hasil.padat.tinggiBaris, 'tinggi baris teks harus turun').toBeLessThan(
      hasil.nyaman.tinggiBaris,
    )
  })

  it('LEBAR (kiri-kanan) TIDAK menyempit — riset: kerapatan mengubah tinggi, bukan lebar', () => {
    // Material 3 "density scale": "it does not affect the horizontal spacing within
    // the component"; Cloudscape sama. Aturan lama proyek ini justru menyempitkan
    // kiri-kanan dan membiarkan tinggi — itu sebabnya blok terasa "ga pas".
    expect(hasil.padat.tombolIsi, 'tepi kiri-kanan tombol harus tetap').toBe(hasil.nyaman.tombolIsi)
    expect(hasil.padat.isianIsi, 'tepi kiri-kanan isian harus tetap').toBe(hasil.nyaman.isianIsi)
    expect(hasil.padat.kartuKiri, 'tepi kiri-kanan kartu harus tetap').toBe(hasil.nyaman.kartuKiri)
    expect(hasil.padat.selKiri, 'tepi kiri-kanan sel tabel harus tetap').toBe(hasil.nyaman.selKiri)
    expect(hasil.padat.lencanaKiri, 'tepi kiri-kanan lencana harus tetap').toBe(
      hasil.nyaman.lencanaKiri,
    )
  })

  it('baris contoh lebih rapat di mode Padat', () => {
    expect(hasil.padat.baris).toBeLessThan(hasil.nyaman.baris)
  })

  it('huruf TIDAK dikecilkan (keterbacaan & daerah sentuh dijaga)', () => {
    expect(hasil.padat.huruf).toBe(hasil.nyaman.huruf)
  })

  it('TINGGI kendali & baris daftar ikut mengecil, dengan lantai sentuh 44 px', () => {
    expect(hasil.padat.tombolTinggi, 'tombol harus lebih pendek di mode Padat').toBeLessThan(
      hasil.nyaman.tombolTinggi,
    )
    expect(hasil.padat.isianTinggi, 'isian harus lebih pendek di mode Padat').toBeLessThan(
      hasil.nyaman.isianTinggi,
    )
    expect(hasil.padat.barisTema, 'baris daftar tema harus lebih pendek').toBeLessThan(
      hasil.nyaman.barisTema,
    )
    // lantai 44 px dijaga di KEDUA mode (daerah sentuh jangan ikut mengecil)
    expect(hasil.padat.tombolTinggi).toBeGreaterThanOrEqual(44)
    expect(hasil.padat.isianTinggi).toBeGreaterThanOrEqual(44)
    expect(hasil.padat.barisTema).toBeGreaterThanOrEqual(44)
  })

  it('daerah SENTUH tetap minimal 44 px walau mode Padat (jangan sampai salah pencet)', () => {
    expect(hasil.padat.tombolTinggi).toBeGreaterThanOrEqual(44)
    expect(hasil.padat.isianTinggi).toBeGreaterThanOrEqual(44)
    expect(hasil.padat.segmenTinggi).toBeGreaterThanOrEqual(36)
  })

  it('daftar tema punya JEJAK PUDAR di ujungnya (isinya tidak terpotong mentah)', () => {
    pasang('nyaman')
    const semua = aturanGaya()
    const aturanDaftar = semua.filter((teks) => teks.includes('.picker-daftar'))
    expect(aturanDaftar.length, 'tidak ada aturan .picker-daftar').toBeGreaterThan(0)
    const maska = aturanDaftar
      .map((teks) => /mask-image:\s*([^;}]+)/.exec(teks)?.[1]?.trim())
      .filter((nilai): nilai is string => Boolean(nilai))
    expect(maska.length, 'daftar tema tidak memakai mask-image (tidak ada pudar)').toBeGreaterThan(
      0,
    )
    expect(maska.join(' '), 'pudar harus gradien, bukan potongan keras').toContain(
      'linear-gradient',
    )
    // pudarnya mengikuti gulir (muncul hanya di sisi yang masih ada isinya)
    const gulir = semua.filter((teks) => teks.includes('animation-timeline'))
    expect(gulir.length, 'pudar tidak mengikuti posisi gulir').toBeGreaterThan(0)
    expect(gulir.join(' ')).toContain('scroll(')
    // dan dipasang pada elemen yang MENGGESER, bukan pada wadah ber-bordir
    const panel = document.querySelector('.picker-panel') as Element
    expect(
      getComputedStyle(document.querySelector('.picker-daftar') as Element).overflow,
    ).toContain('auto')
    expect(panel).toBeTruthy()
  })

  it('panel tema dipaku ke sudut layar dan tingginya dibatasi (dulu terpotong)', () => {
    pasang('nyaman')
    const gaya = getComputedStyle(document.querySelector('#panel-tema') as Element)
    expect(gaya.position, 'panel harus position:fixed supaya tidak melewati tepi layar').toBe(
      'fixed',
    )
    // jsdom tidak bisa menghitung min()/vh, jadi batas tinggi diperiksa dari deklarasi
    // gaya nyata: wajib memakai satuan vh dan angkanya tidak melebihi 80% layar.
    const semua = aturanGaya()
    const kunci = semua.filter((teks) => teks.includes('.picker-panel'))
    const tinggi = kunci
      .map((teks) => /max-height:\s*([^;}]+)/.exec(teks)?.[1]?.trim())
      .filter((nilai): nilai is string => Boolean(nilai))
    expect(tinggi.length, 'aturan .picker-panel tanpa batas tinggi').toBeGreaterThan(0)
    for (const nilai of tinggi) {
      const angka = Number.parseFloat(nilai.replace(/^min\(/, ''))
      expect(angka, `batas tinggi "${nilai}" tidak terukur`).toBeGreaterThan(0)
      expect(nilai, `batas tinggi "${nilai}" tidak dikunci ke tinggi layar`).toContain('vh')
      expect(angka, `batas tinggi "${nilai}" terlalu besar`).toBeLessThanOrEqual(80)
    }
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
