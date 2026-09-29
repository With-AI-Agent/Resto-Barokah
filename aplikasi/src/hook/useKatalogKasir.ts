import { useEffect, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import type { KategoriData, MenuItemData } from '../layar/kasir/Katalog'

export interface BarisKategori {
  id: string
  nama: string
  urutan: number
}

export interface BarisMenu {
  id: string
  kategori_id: string
  nama: string
  deskripsi: string | null
  harga: number
  foto_path: string | null
  unggulan: boolean
  jenis: MenuItemData['jenis']
  aktif: boolean
  urutan: number
}

export interface BarisMenuCabang {
  menu_item_id: string
  harga: number | null
  aktif: boolean
  habis: boolean
}

export interface BarisVarian {
  menu_item_id: string
  nama: string
  tambahan_harga: number
}

export interface BarisTambahan {
  id: string
  menu_item_id: string | null
  nama: string
  harga: number
}

export interface DataKatalogKasir {
  kategori: BarisKategori[]
  menu: BarisMenu[]
  menuCabang: BarisMenuCabang[]
  varian: BarisVarian[]
  tambahan: BarisTambahan[]
}

export interface HasilKatalogKasir {
  kategori: KategoriData[]
  menu: MenuItemData[]
}

/** Gabungkan katalog tenant dengan harga, status, dan opsi khusus cabang. */
export function petaKatalogKasir(data: DataKatalogKasir): HasilKatalogKasir {
  const konfigurasiCabang = new Map(data.menuCabang.map((baris) => [baris.menu_item_id, baris]))

  const menu = data.menu.flatMap((item) => {
    if (!item.aktif) return []
    const cabang = konfigurasiCabang.get(item.id)
    if (cabang && !cabang.aktif) return []

    const varian = data.varian
      .filter((baris) => baris.menu_item_id === item.id)
      .map((baris) => ({ nama: baris.nama, tambahanHarga: baris.tambahan_harga }))
    const tambahan = data.tambahan
      .filter((baris) => baris.menu_item_id === null || baris.menu_item_id === item.id)
      .map((baris) => ({ id: baris.id, nama: baris.nama, harga: baris.harga }))

    return [
      {
        id: item.id,
        kategoriId: item.kategori_id,
        nama: item.nama,
        deskripsi: item.deskripsi ?? undefined,
        harga: cabang?.harga ?? item.harga,
        fotoPath: item.foto_path ?? undefined,
        unggulan: item.unggulan,
        jenis: item.jenis,
        aktif: item.aktif,
        habis: cabang?.habis ?? false,
        daftarVarian: varian,
        daftarTambahan: tambahan,
      },
    ]
  })

  return {
    kategori: [...data.kategori]
      .sort((a, b) => a.urutan - b.urutan || a.nama.localeCompare(b.nama))
      .map(({ id, nama, urutan }) => ({ id, nama, urutan })),
    menu,
  }
}

/** Memuat semua tabel katalog lewat RLS Supabase dan gagal tertutup bila salah satu gagal. */
export function useKatalogKasir(cabangId: string | null, aktif: boolean) {
  const [hasil, setHasil] = useState<HasilKatalogKasir>({ kategori: [], menu: [] })
  const [sedangMemuat, setSedangMemuat] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)

  useEffect(() => {
    let batal = false

    const muat = async () => {
      if (!aktif) {
        setHasil({ kategori: [], menu: [] })
        setSedangMemuat(false)
        setPesanGalat(null)
        return
      }
      if (!cabangId) {
        setHasil({ kategori: [], menu: [] })
        setSedangMemuat(false)
        setPesanGalat('Pilih cabang aktif untuk memuat katalog.')
        return
      }

      const klien = klienSupabase()
      if (!klien) {
        setHasil({ kategori: [], menu: [] })
        setSedangMemuat(false)
        setPesanGalat('Sambungan ke basis data belum tersedia; katalog tidak dimuat.')
        return
      }

      setHasil({ kategori: [], menu: [] })
      setSedangMemuat(true)
      setPesanGalat(null)
      const [kategori, menu, menuCabang, varian, tambahan] = await Promise.all([
        klien.from('kategori_menu').select('id,nama,urutan').eq('aktif', true).order('urutan'),
        klien
          .from('menu_item')
          .select('id,kategori_id,nama,deskripsi,harga,foto_path,unggulan,jenis,aktif,urutan')
          .eq('aktif', true)
          .order('urutan'),
        klien
          .from('menu_cabang')
          .select('menu_item_id,harga,aktif,habis')
          .eq('cabang_id', cabangId),
        klien.from('menu_varian').select('menu_item_id,nama,tambahan_harga').eq('aktif', true),
        klien.from('menu_tambahan').select('id,menu_item_id,nama,harga').eq('aktif', true),
      ])

      if (batal) return
      const galat =
        kategori.error ?? menu.error ?? menuCabang.error ?? varian.error ?? tambahan.error
      if (galat) {
        setHasil({ kategori: [], menu: [] })
        setPesanGalat(`Katalog gagal dimuat: ${galat.message}`)
        setSedangMemuat(false)
        return
      }

      const dipetakan = petaKatalogKasir({
        kategori: (kategori.data ?? []) as BarisKategori[],
        menu: (menu.data ?? []) as BarisMenu[],
        menuCabang: (menuCabang.data ?? []) as BarisMenuCabang[],
        varian: (varian.data ?? []) as BarisVarian[],
        tambahan: (tambahan.data ?? []) as BarisTambahan[],
      })
      setHasil(dipetakan)
      setSedangMemuat(false)
    }

    void muat().catch((galat: unknown) => {
      if (batal) return
      setHasil({ kategori: [], menu: [] })
      setPesanGalat(galat instanceof Error ? galat.message : 'Katalog gagal dimuat.')
      setSedangMemuat(false)
    })

    return () => {
      batal = true
    }
  }, [cabangId, aktif])

  return { ...hasil, sedangMemuat, pesanGalat }
}
