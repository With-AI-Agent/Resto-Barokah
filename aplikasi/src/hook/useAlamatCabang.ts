import { useEffect, useState } from 'react'
import { klienSupabase } from '../lib/supabase'

/**
 * Alamat cabang aktif (PMB1-F-020 · PRD M6 baris 131).
 *
 * Struk WAJIB memuat alamat resto — sumbernya kolom `cabang.alamat` (0070
 * mengumpulkan id/nama/alamat/telepon untuk katalog). Hook ini membaca satu
 * baris itu; bila peladen tidak terjangkau atau kolom kosong, hasilnya null
 * dan pemanggil jujur tidak menampilkan alamat (bukan mengarang alamat).
 * Bacaan sekali per cabang — alamat tidak berubah tiap detik.
 */
export function useAlamatCabang(cabangId: string | null): string | null {
  const [alamat, setAlamat] = useState<string | null>(null)

  useEffect(() => {
    let hidup = true
    setAlamat(null)
    if (!cabangId) return
    const klien = klienSupabase()
    if (!klien) return
    void (async () => {
      try {
        const { data, error } = await klien
          .from('cabang')
          .select('alamat')
          .eq('id', cabangId)
          .maybeSingle()
        if (!hidup) return
        if (!error && data && typeof data.alamat === 'string' && data.alamat.trim() !== '') {
          setAlamat(data.alamat.trim())
        }
      } catch {
        if (hidup) setAlamat(null)
      }
    })()
    return () => {
      hidup = false
    }
  }, [cabangId])

  return alamat
}
