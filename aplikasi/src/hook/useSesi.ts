import { useEffect, useState } from 'react'
import {
  bacaSesiLokal,
  keluar as authKeluar,
  masukDenganPin as authMasukPin,
  simpanSesiLokal,
} from '../lib/auth'
import type { HasilAutentikasi, PenggunaSesi, PeranPengguna } from '../lib/auth'

export interface StateSesi {
  sesi: PenggunaSesi | null
  peran: PeranPengguna | null
  sedangMasuk: boolean
  sedangMemuat: boolean
  masuk: (email: string, pin: string) => Promise<HasilAutentikasi>
  keluar: () => Promise<void>
  perbaruiSesi: (sesiBaru: PenggunaSesi | null) => void
}

export function useSesi(): StateSesi {
  const [sesi, setSesi] = useState<PenggunaSesi | null>(() => bacaSesiLokal())
  const [sedangMemuat, setSedangMemuat] = useState<boolean>(true)

  useEffect(() => {
    const lokal = bacaSesiLokal()
    setSesi(lokal)
    setSedangMemuat(false)
  }, [])

  const masuk = async (email: string, pin: string): Promise<HasilAutentikasi> => {
    setSedangMemuat(true)
    try {
      const hasil = await authMasukPin(email, pin)
      if (hasil.berhasil && hasil.sesi) {
        setSesi(hasil.sesi)
      }
      return hasil
    } finally {
      setSedangMemuat(false)
    }
  }

  const keluar = async (): Promise<void> => {
    setSedangMemuat(true)
    try {
      await authKeluar()
      setSesi(null)
    } finally {
      setSedangMemuat(false)
    }
  }

  const perbaruiSesi = (sesiBaru: PenggunaSesi | null) => {
    simpanSesiLokal(sesiBaru)
    setSesi(sesiBaru)
  }

  return {
    sesi,
    peran: sesi?.peran ?? null,
    sedangMasuk: sesi !== null,
    sedangMemuat,
    masuk,
    keluar,
    perbaruiSesi,
  }
}
