import { useEffect, useRef, useState, useCallback } from 'react'
import type { PeranPengguna } from '../lib/auth'

export interface OpsiKunciOtomatis {
  peran?: PeranPengguna
  diLuarJamOperasional?: boolean
  detikTenggangPeringatan?: number
  onKunci?: () => void
  onPeringatan?: (sisaDetik: number) => void
}

/**
 * Batas waktu menganggur sebelum terkunci otomatis (dalam milidetik).
 * Kasir/Pelayan/Dapur: 15 menit
 * Admin Cabang: 30 menit
 * Owner: 60 menit
 */
export const BATAS_MENGANGGUR_MS: Record<PeranPengguna, number> = {
  kasir: 15 * 60 * 1000,
  pelayan: 15 * 60 * 1000,
  dapur: 15 * 60 * 1000,
  admin_cabang: 30 * 60 * 1000,
  owner_pusat: 60 * 60 * 1000,
  pemilik_platform: 30 * 60 * 1000,
  pelanggan: 60 * 60 * 1000,
}

export function batasWaktuInaktifMenit(peran: PeranPengguna): number {
  return (BATAS_MENGANGGUR_MS[peran] ?? 15 * 60 * 1000) / (60 * 1000)
}

export function useKunciOtomatis({
  peran = 'kasir',
  diLuarJamOperasional = false,
  detikTenggangPeringatan = 60,
  onKunci,
  onPeringatan,
}: OpsiKunciOtomatis = {}) {
  const [terkunci, setTerkunci] = useState(false)
  const [dalamPeringatan, setDalamPeringatan] = useState(false)
  const [sisaDetik, setSisaDetik] = useState(0)

  const batasWaktuMs = BATAS_MENGANGGUR_MS[peran] ?? 15 * 60 * 1000
  const waktuAktivitasTerakhir = useRef(Date.now())

  const kunci = useCallback(() => {
    setTerkunci(true)
    setDalamPeringatan(false)
    setSisaDetik(0)
    onKunci?.()
  }, [onKunci])

  const bukaKunci = useCallback(() => {
    setTerkunci(false)
    setDalamPeringatan(false)
    setSisaDetik(0)
    waktuAktivitasTerakhir.current = Date.now()
  }, [])

  const rekamAktivitas = useCallback(() => {
    if (terkunci) return
    waktuAktivitasTerakhir.current = Date.now()
    if (dalamPeringatan) {
      setDalamPeringatan(false)
      setSisaDetik(0)
    }
  }, [terkunci, dalamPeringatan])

  useEffect(() => {
    // Kunci otomatis hanya berjalan jika di luar jam operasional atau sesuai kebijakan keamanan
    // Jika di luar jam operasional, batas waktu default 15 menit
    const batasEfektifMs = diLuarJamOperasional ? Math.min(batasWaktuMs, 15 * 60 * 1000) : batasWaktuMs
    const batasPeringatanMs = batasEfektifMs - detikTenggangPeringatan * 1000

    const interval = setInterval(() => {
      if (terkunci) return

      const sudahLewatMs = Date.now() - waktuAktivitasTerakhir.current

      if (sudahLewatMs >= batasEfektifMs) {
        kunci()
      } else if (sudahLewatMs >= batasPeringatanMs) {
        const sisa = Math.max(1, Math.ceil((batasEfektifMs - sudahLewatMs) / 1000))
        setDalamPeringatan(true)
        setSisaDetik(sisa)
        onPeringatan?.(sisa)
      } else {
        if (dalamPeringatan) {
          setDalamPeringatan(false)
          setSisaDetik(0)
        }
      }
    }, 1000)

    const tanganiAktivitas = () => rekamAktivitas()

    window.addEventListener('pointerdown', tanganiAktivitas)
    window.addEventListener('keydown', tanganiAktivitas)
    window.addEventListener('touchstart', tanganiAktivitas)
    window.addEventListener('scroll', tanganiAktivitas)

    return () => {
      clearInterval(interval)
      window.removeEventListener('pointerdown', tanganiAktivitas)
      window.removeEventListener('keydown', tanganiAktivitas)
      window.removeEventListener('touchstart', tanganiAktivitas)
      window.removeEventListener('scroll', tanganiAktivitas)
    }
  }, [batasWaktuMs, diLuarJamOperasional, detikTenggangPeringatan, kunci, rekamAktivitas, terkunci, dalamPeringatan, onPeringatan])

  return {
    terkunci,
    dalamPeringatan,
    sisaDetik,
    kunci,
    bukaKunci,
    rekamAktivitas,
  }
}
