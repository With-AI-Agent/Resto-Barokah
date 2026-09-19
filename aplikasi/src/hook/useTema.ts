import { useCallback, useEffect, useState } from 'react'
import {
  bacaPilihanTersimpan,
  segarkanWarnaSistem,
  simpanPilihan,
  terapkanKerapatan,
  terapkanTema,
  type Kerapatan,
  type KodeTema,
} from '../lib/tema'

export type PakaiTema = {
  tema: KodeTema
  kerapatan: Kerapatan
  gantiTema: (kode: KodeTema) => void
  gantiKerapatan: (kode: Kerapatan) => void
}

/** Membaca, mengganti, dan menyimpan pilihan tema tanpa memuat ulang halaman. */
export function useTema(): PakaiTema {
  const [tema, setTema] = useState<KodeTema>(() => bacaPilihanTersimpan().tema)
  const [kerapatan, setKerapatan] = useState<Kerapatan>(() => bacaPilihanTersimpan().kerapatan)

  useEffect(() => {
    terapkanTema(tema)
    terapkanKerapatan(kerapatan)
    segarkanWarnaSistem()
    simpanPilihan(tema, kerapatan)
  }, [tema, kerapatan])

  const gantiTema = useCallback((kode: KodeTema) => setTema(kode), [])
  const gantiKerapatan = useCallback((kode: Kerapatan) => setKerapatan(kode), [])

  return { tema, kerapatan, gantiTema, gantiKerapatan }
}
