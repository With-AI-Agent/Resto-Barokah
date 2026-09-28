import { useEffect, useState } from 'react'
import type { PenggunaSesi } from '../lib/auth'

export interface CabangInfo {
  id: string
  nama: string
}

export interface StateCabang {
  cabangAktifId: string | null
  cabangIds: string[]
  bisaPindahCabang: boolean
  gantiCabang: (id: string) => boolean
}

export function useCabang(sesi: PenggunaSesi | null): StateCabang {
  const [cabangAktifId, setCabangAktifId] = useState<string | null>(
    () => sesi?.cabangAktifId ?? sesi?.cabangIds?.[0] ?? null,
  )

  useEffect(() => {
    if (sesi?.cabangAktifId) {
      setCabangAktifId(sesi.cabangAktifId)
    } else if (sesi?.cabangIds && sesi.cabangIds.length > 0) {
      setCabangAktifId(sesi.cabangIds[0])
    } else {
      setCabangAktifId(null)
    }
  }, [sesi])

  const cabangIds = sesi?.cabangIds ?? []
  const peran = sesi?.peran

  // Owner pusat atau pengguna dengan lebih dari 1 cabang berhak pindah cabang (ART-1)
  const bisaPindahCabang =
    peran === 'owner_pusat' || peran === 'pemilik_platform' || cabangIds.length > 1

  const gantiCabang = (id: string): boolean => {
    if (!sesi) return false

    // Pemilik atau yang memiliki akses ke cabang tersebut
    if (peran === 'owner_pusat' || peran === 'pemilik_platform' || cabangIds.includes(id)) {
      setCabangAktifId(id)
      sesi.cabangAktifId = id
      return true
    }

    // Admin cabang atau kasir terkunci mutlak ke cabang miliknya
    return false
  }

  return {
    cabangAktifId,
    cabangIds,
    bisaPindahCabang,
    gantiCabang,
  }
}
