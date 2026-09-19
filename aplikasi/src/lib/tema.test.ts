import { beforeEach, describe, expect, it } from 'vitest'
import {
  KERAPATAN,
  TEMA,
  bacaPilihanTersimpan,
  pasangTemaAwal,
  simpanPilihan,
  terapkanKerapatan,
  terapkanTema,
} from './tema'

type AkarPalsu = { dataset: Record<string, string> }

function akarPalsu(): AkarPalsu {
  return { dataset: {} }
}

function simpananPalsu(): void {
  const isi = new Map<string, string>()
  Object.defineProperty(globalThis, 'localStorage', {
    configurable: true,
    value: {
      getItem: (k: string) => isi.get(k) ?? null,
      setItem: (k: string, v: string) => void isi.set(k, v),
      removeItem: (k: string) => void isi.delete(k),
      clear: () => isi.clear(),
      key: (i: number) => [...isi.keys()][i] ?? null,
      get length() {
        return isi.size
      },
    },
  })
}

beforeEach(() => {
  simpananPalsu()
})

describe('daftar tema', () => {
  it('tepat 10 tema dengan kode unik', () => {
    expect(TEMA).toHaveLength(10)
    expect(new Set(TEMA.map((t) => t.kode)).size).toBe(10)
  })

  it('tepat 2 kerapatan', () => {
    expect(KERAPATAN.map((k) => k.kode)).toEqual(['nyaman', 'padat'])
  })
})

describe('menerapkan tema', () => {
  it('menulis data-theme ke elemen akar', () => {
    const akar = akarPalsu()
    expect(terapkanTema('gelap', akar as unknown as HTMLElement)).toBe(true)
    expect(akar.dataset.theme).toBe('gelap')
  })

  it('menulis data-density ke elemen akar', () => {
    const akar = akarPalsu()
    expect(terapkanKerapatan('padat', akar as unknown as HTMLElement)).toBe(true)
    expect(akar.dataset.density).toBe('padat')
  })

  it('tidak meledak walau tidak ada DOM', () => {
    expect(terapkanTema('terang', null)).toBe(false)
  })
})

describe('menyimpan pilihan', () => {
  it('mengembalikan bawaan saat belum ada simpanan', () => {
    expect(bacaPilihanTersimpan()).toEqual({ tema: 'terang', kerapatan: 'nyaman' })
  })

  it('membaca kembali pilihan yang sah', () => {
    simpanPilihan('etnik', 'padat')
    expect(bacaPilihanTersimpan()).toEqual({ tema: 'etnik', kerapatan: 'padat' })
  })

  it('mengabaikan isi simpanan yang tidak dikenal', () => {
    localStorage.setItem('sajian.tema', 'tema-hantu')
    localStorage.setItem('sajian.kerapatan', 'super-padat')
    expect(bacaPilihanTersimpan()).toEqual({ tema: 'terang', kerapatan: 'nyaman' })
  })

  it('pasangTemaAwal memasang pilihan tersimpan ke akar', () => {
    simpanPilihan('tropis', 'padat')
    const akar = akarPalsu()
    const pilihan = pasangTemaAwal(akar as unknown as HTMLElement)
    expect(pilihan).toEqual({ tema: 'tropis', kerapatan: 'padat' })
    expect(akar.dataset).toEqual({ theme: 'tropis', density: 'padat' })
  })
})
