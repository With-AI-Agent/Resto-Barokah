/* eslint-disable react-refresh/only-export-components */
/**
 * Kerangka Multi-Bahasa (i18n) Aplikasi Resto Barokah (T1-40)
 * Menjamin seluruh teks UI terpusat dan mudah diterjemahkan tanpa hardcoding.
 */

import { createContext, useContext, useState, useEffect, type ReactNode } from 'react'
import { id, type KamusBahasa } from './id'
import { en } from './en'
import { zh } from './zh'
import { ar } from './ar'

export type KodeBahasa = 'id' | 'en' | 'zh' | 'ar'
export type ArahTeks = 'ltr' | 'rtl'

export interface MetaBahasa {
  kode: KodeBahasa
  nama: string
  namaLokal: string
  arah: ArahTeks
  tersediaG1: boolean
}

export const DAFTAR_BAHASA: readonly MetaBahasa[] = [
  { kode: 'id', nama: 'Indonesia', namaLokal: 'Bahasa Indonesia', arah: 'ltr', tersediaG1: true },
  { kode: 'en', nama: 'Inggris', namaLokal: 'English', arah: 'ltr', tersediaG1: true },
  { kode: 'zh', nama: 'Mandarin', namaLokal: '简体中文', arah: 'ltr', tersediaG1: true },
  { kode: 'ar', nama: 'Arab', namaLokal: 'العربية', arah: 'rtl', tersediaG1: false },
] as const

export const KAMUS_SEMUA_BAHASA: Record<KodeBahasa, KamusBahasa> = {
  id,
  en,
  zh,
  ar,
}

export interface KonteksBahasa {
  bahasa: KodeBahasa
  meta: MetaBahasa
  arah: ArahTeks
  gantiBahasa: (kode: KodeBahasa) => void
  t: (kunciPath: string, nilaiPengganti?: Record<string, string | number>) => string
}

const KonteksI18n = createContext<KonteksBahasa | null>(null)

const KUNCI_PENYIMPANAN_BAHASA = 'resto_barokah_bahasa_pilihan'

export function PenyediaBahasa({
  children,
  bahasaAwal = 'id',
}: {
  children: ReactNode
  bahasaAwal?: KodeBahasa
}) {
  const [bahasa, setBahasa] = useState<KodeBahasa>(() => {
    try {
      const tersimpan = localStorage.getItem(KUNCI_PENYIMPANAN_BAHASA)
      if (tersimpan && ['id', 'en', 'zh', 'ar'].includes(tersimpan)) {
        return tersimpan as KodeBahasa
      }
    } catch {
      // Abaikan bila storage gagal
    }
    return bahasaAwal
  })

  const meta = DAFTAR_BAHASA.find((b) => b.kode === bahasa) ?? DAFTAR_BAHASA[0]
  const arah = meta.arah

  useEffect(() => {
    try {
      localStorage.setItem(KUNCI_PENYIMPANAN_BAHASA, bahasa)
    } catch {
      // Abaikan bila storage gagal
    }
    document.documentElement.lang = bahasa
    document.documentElement.dir = arah
  }, [bahasa, arah])

  const gantiBahasa = (kode: KodeBahasa) => {
    setBahasa(kode)
  }

  const t = (kunciPath: string, nilaiPengganti?: Record<string, string | number>): string => {
    const kamus = KAMUS_SEMUA_BAHASA[bahasa] ?? KAMUS_SEMUA_BAHASA.id
    const bagian = kunciPath.split('.')

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let hasil: any = kamus
    for (const b of bagian) {
      if (hasil && typeof hasil === 'object' && b in hasil) {
        hasil = hasil[b]
      } else {
        // Fallback ke Bahasa Indonesia jika tidak ditemukan
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        let fallback: any = KAMUS_SEMUA_BAHASA.id
        for (const fb of bagian) {
          if (fallback && typeof fallback === 'object' && fb in fallback) {
            fallback = fallback[fb]
          } else {
            return kunciPath
          }
        }
        hasil = fallback
        break
      }
    }

    if (typeof hasil !== 'string') {
      return kunciPath
    }

    if (nilaiPengganti) {
      let str = hasil
      for (const [k, v] of Object.entries(nilaiPengganti)) {
        str = str.replace(new RegExp(`{${k}}`, 'g'), String(v))
      }
      return str
    }

    return hasil
  }

  return (
    <KonteksI18n.Provider value={{ bahasa, meta, arah, gantiBahasa, t }}>
      {children}
    </KonteksI18n.Provider>
  )
}

export function useBahasa(): KonteksBahasa {
  const ctx = useContext(KonteksI18n)
  if (!ctx) {
    // Kembalikan konteks fallback default jika tidak berada dalam provider
    const metaBawaan = DAFTAR_BAHASA[0]
    return {
      bahasa: 'id',
      meta: metaBawaan,
      arah: 'ltr',
      gantiBahasa: () => {},
      t: (kunciPath: string) => {
        const bagian = kunciPath.split('.')
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        let hasil: any = id
        for (const b of bagian) {
          if (hasil && typeof hasil === 'object' && b in hasil) {
            hasil = hasil[b]
          } else {
            return kunciPath
          }
        }
        return typeof hasil === 'string' ? hasil : kunciPath
      },
    }
  }
  return ctx
}
