import { useEffect, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import type { MejaData } from '../layar/kasir/PemilihMeja'

interface BarisMejaKasir {
  id: string
  nama: string
  area: string | null
  status: MejaData['status']
  aktif: boolean
}

export function useMejaKasir(cabangId: string | null, aktif: boolean) {
  const [daftarMeja, setDaftarMeja] = useState<MejaData[]>([])
  const [sedangMemuat, setSedangMemuat] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)

  useEffect(() => {
    let batal = false

    const muat = async () => {
      if (!aktif) {
        setDaftarMeja([])
        setSedangMemuat(false)
        setPesanGalat(null)
        return
      }
      if (!cabangId) {
        setDaftarMeja([])
        setSedangMemuat(false)
        setPesanGalat('Pilih cabang aktif untuk memuat meja.')
        return
      }

      const klien = klienSupabase()
      if (!klien) {
        setDaftarMeja([])
        setSedangMemuat(false)
        setPesanGalat('Sambungan ke basis data belum tersedia; meja tidak dimuat.')
        return
      }

      setDaftarMeja([])
      setSedangMemuat(true)
      setPesanGalat(null)
      try {
        const { data, error } = await klien
          .from('meja')
          .select('id,nama,area,status,aktif')
          .eq('cabang_id', cabangId)
          .eq('aktif', true)
          .order('nama')
        if (batal) return
        if (error) {
          setPesanGalat(`Meja gagal dimuat: ${error.message}`)
          setDaftarMeja([])
        } else {
          setDaftarMeja(
            ((data ?? []) as BarisMejaKasir[]).map((meja) => ({
              id: meja.id,
              nama: meja.nama,
              area: meja.area ?? undefined,
              status: meja.status,
              aktif: meja.aktif,
            })),
          )
        }
      } catch (galat) {
        if (batal) return
        setDaftarMeja([])
        setPesanGalat(galat instanceof Error ? galat.message : 'Meja gagal dimuat.')
      } finally {
        if (!batal) setSedangMemuat(false)
      }
    }

    void muat()
    return () => {
      batal = true
    }
  }, [cabangId, aktif])

  return { daftarMeja, sedangMemuat, pesanGalat }
}
