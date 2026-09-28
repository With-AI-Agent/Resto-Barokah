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

/** Simpanan yang MENOLAK: `getItem`/`setItem` melempar (izin ditolak / penyimpanan penuh). */
function simpananMenolak(opsi: { baca?: boolean; tulis?: boolean } = {}): void {
  const melempar = (nama: string) => () => {
    throw new DOMException(`ditolak: ${nama}`, 'SecurityError')
  }
  Object.defineProperty(globalThis, 'localStorage', {
    configurable: true,
    value: {
      getItem: opsi.baca === false ? () => null : melempar('getItem'),
      setItem: opsi.tulis === false ? () => undefined : melempar('setItem'),
      removeItem: () => undefined,
      clear: () => undefined,
      key: () => null,
      get length() {
        return 0
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

describe('simpanan yang menolak (temuan audit I F-06)', () => {
  it('bacaPilihanTersimpan tidak meledak saat getItem melempar — kembali ke bawaan', () => {
    simpananMenolak()
    expect(() => bacaPilihanTersimpan()).not.toThrow()
    expect(bacaPilihanTersimpan()).toEqual({ tema: 'terang', kerapatan: 'nyaman' })
  })

  it('simpanPilihan tidak meledak saat setItem melempar — dan jujur bilang gagal', () => {
    simpananMenolak()
    expect(() => simpanPilihan('etnik', 'padat')).not.toThrow()
    expect(simpanPilihan('etnik', 'padat')).toBe(false)
  })

  it('simpanPilihan melaporkan true saat benar-benar tersimpan', () => {
    expect(simpanPilihan('etnik', 'padat')).toBe(true)
    expect(bacaPilihanTersimpan()).toEqual({ tema: 'etnik', kerapatan: 'padat' })
  })

  it('pasangTemaAwal tetap memasang tema walau simpanan menolak dibaca', () => {
    simpananMenolak({ tulis: false })
    const akar = akarPalsu()
    const pilihan = pasangTemaAwal(akar as unknown as HTMLElement)
    expect(pilihan).toEqual({ tema: 'terang', kerapatan: 'nyaman' })
    expect(akar.dataset).toEqual({ theme: 'terang', density: 'nyaman' })
  })
})
