import { useState, useEffect, useCallback } from 'react'
import {
  Katalog,
  type InfoPenyewaPublik,
  type InfoCabangPublik,
  type PengaturanRestoPublik,
  type KategoriPublik,
  type MenuItemPublik,
} from './Katalog'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { klienSupabase } from '../../lib/supabase'

export interface LayarPelangganPublikProps {
  penyewaId?: string
  cabangId?: string
  nomorMeja?: string
  dataAwal?: {
    penyewa: InfoPenyewaPublik
    cabang: InfoCabangPublik
    pengaturan: PengaturanRestoPublik
    kategori: KategoriPublik[]
    menu: MenuItemPublik[]
  }
  keadaanPaksa?: 'memuat' | 'gagal' | 'kosong' | 'berhasil'
  onTutup?: () => void
}

const CONTOH_PENYEWA: InfoPenyewaPublik = {
  id: '00000000-0000-0000-0000-000000000001',
  nama: 'Resto Barokah',
  slug: 'resto-barokah',
}

const CONTOH_CABANG: InfoCabangPublik = {
  id: 'cab-01',
  nama: 'Cabang Utama Bandung',
  alamat: 'Jl. Riau No. 12, Citarum, Kec. Bandung Wetan, Kota Bandung',
  telepon: '0812-3456-7890',
}

const CONTOH_PENGATURAN: PengaturanRestoPublik = {
  nama_resto: 'Resto Barokah',
  tagline: 'Cita rasa rempah asli nusantara untuk keluarga dan sahabat',
  tema: 'terang',
  jam_buka: { teks: 'Setiap Hari · 09.00 - 21.00 WIB' },
  kontak: { telepon: '0812-3456-7890', whatsapp: '6281234567890' },
  lokasi: {
    alamat: 'Jl. Riau No. 12, Citarum, Kec. Bandung Wetan, Kota Bandung',
    kota: 'Bandung',
  },
}

const CONTOH_KATEGORI: KategoriPublik[] = [
  { id: 'kat-01', nama: 'Makanan Utama', urutan: 1 },
  { id: 'kat-02', nama: 'Minuman Segar', urutan: 2 },
  { id: 'kat-03', nama: 'Camilan Gurih', urutan: 3 },
]

const CONTOH_MENU: MenuItemPublik[] = [
  {
    id: 'm-01',
    kategori_id: 'kat-01',
    nama: 'Nasi Goreng Spesial Barokah',
    deskripsi: 'Nasi goreng racikan rempah khas dengan suwiran ayam, telur mata sapi, dan kerupuk.',
    harga: 28000,
    unggulan: true,
    jenis: 'makanan',
    habis: false,
  },
  {
    id: 'm-02',
    kategori_id: 'kat-01',
    nama: 'Sate Ayam Madura (10 Tusuk)',
    deskripsi: 'Daging ayam pilihan dipanggang arang dengan lumuran bumbu kacang kental gurih.',
    harga: 32000,
    unggulan: true,
    jenis: 'makanan',
    habis: false,
  },
  {
    id: 'm-03',
    kategori_id: 'kat-02',
    nama: 'Es Teh Manis Melati',
    deskripsi: 'Seduhan teh melati wangi dengan gula asli dan es batu kristal higienis.',
    harga: 6000,
    jenis: 'minuman',
    habis: false,
  },
  {
    id: 'm-04',
    kategori_id: 'kat-02',
    nama: 'Kopi Susu Gula Aren',
    deskripsi: 'Espresso biji robusta lokal berpadu susu murni segar dan saus gula aren.',
    harga: 18000,
    unggulan: true,
    jenis: 'minuman',
    habis: false,
  },
  {
    id: 'm-05',
    kategori_id: 'kat-03',
    nama: 'Tahu Tempe Goreng Mendoan',
    deskripsi: 'Tahu dan tempe goreng renyah disajikan hangat dengan sambal kecap rawit pedas.',
    harga: 14000,
    jenis: 'makanan',
    habis: true,
  },
]

export function LayarPelangganPublik({
  penyewaId,
  cabangId,
  nomorMeja,
  dataAwal,
  keadaanPaksa,
  onTutup,
}: LayarPelangganPublikProps) {
  const [keadaan, setKeadaan] = useState<'memuat' | 'gagal' | 'kosong' | 'berhasil'>(
    keadaanPaksa || (dataAwal ? 'berhasil' : 'memuat'),
  )
  const [pesanGalat, setPesanGalat] = useState<string>('')
  const [dataKatalog, setDataKatalog] = useState<{
    penyewa: InfoPenyewaPublik
    cabang: InfoCabangPublik
    pengaturan: PengaturanRestoPublik
    kategori: KategoriPublik[]
    menu: MenuItemPublik[]
  }>(
    dataAwal || {
      penyewa: CONTOH_PENYEWA,
      cabang: CONTOH_CABANG,
      pengaturan: CONTOH_PENGATURAN,
      kategori: CONTOH_KATEGORI,
      menu: CONTOH_MENU,
    },
  )

  const muatDataDariPeladen = useCallback(async () => {
    if (keadaanPaksa) {
      setKeadaan(keadaanPaksa)
      return
    }

    if (dataAwal) {
      setDataKatalog(dataAwal)
      setKeadaan(dataAwal.menu.length === 0 ? 'kosong' : 'berhasil')
      return
    }

    const klien = klienSupabase()
    if (!klien || !penyewaId) {
      // Fallback data simulasi/lokal yang lengkap dan siap dicoba
      setDataKatalog({
        penyewa: CONTOH_PENYEWA,
        cabang: CONTOH_CABANG,
        pengaturan: CONTOH_PENGATURAN,
        kategori: CONTOH_KATEGORI,
        menu: CONTOH_MENU,
      })
      setKeadaan('berhasil')
      return
    }

    try {
      setKeadaan('memuat')
      const { data, error } = await klien.rpc('katalog_publik', {
        p_penyewa_id: penyewaId,
        p_cabang_id: cabangId || null,
      })

      if (error) {
        setPesanGalat(error.message)
        setKeadaan('gagal')
        return
      }

      if (!data) {
        setKeadaan('kosong')
        return
      }

      const hasil = data as {
        penyewa: InfoPenyewaPublik
        cabang: InfoCabangPublik
        pengaturan: PengaturanRestoPublik
        kategori: KategoriPublik[]
        menu: MenuItemPublik[]
      }

      setDataKatalog(hasil)
      if (!hasil.menu || hasil.menu.length === 0) {
        setKeadaan('kosong')
      } else {
        setKeadaan('berhasil')
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Gagal memuat katalog menu. Silakan muat ulang.'
      setPesanGalat(msg)
      setKeadaan('gagal')
    }
  }, [penyewaId, cabangId, dataAwal, keadaanPaksa])

  useEffect(() => {
    void muatDataDariPeladen()
  }, [muatDataDariPeladen])

  // Menangani 7 Keadaan Sesuai Kontrak Layar (layar.ts):
  if (keadaan === 'memuat') {
    return (
      <div style={{ padding: 'var(--s-8) var(--s-4)', maxWidth: '600px', margin: '0 auto' }}>
        <KeadaanMemuat judul="Memuat katalog menu lezat..." baris={4} />
      </div>
    )
  }

  if (keadaan === 'gagal') {
    return (
      <div style={{ padding: 'var(--s-8) var(--s-4)', maxWidth: '600px', margin: '0 auto' }}>
        <KeadaanGagal
          judul="Gagal memuat katalog menu. Silakan muat ulang."
          keterangan={pesanGalat || 'Periksa sambungan internet lalu coba lagi.'}
          onCoba={muatDataDariPeladen}
        />
      </div>
    )
  }

  if (keadaan === 'kosong') {
    return (
      <div style={{ padding: 'var(--s-8) var(--s-4)', maxWidth: '600px', margin: '0 auto' }}>
        <KeadaanKosong
          judul="Belum ada menu yang tersedia untuk cabang ini."
          keterangan="Menu sedang disiapkan oleh staf kedai. Silakan periksa kembali nanti."
        />
      </div>
    )
  }

  return (
    <Katalog
      penyewa={dataKatalog.penyewa}
      cabang={dataKatalog.cabang}
      pengaturan={dataKatalog.pengaturan}
      kategori={dataKatalog.kategori}
      menu={dataKatalog.menu}
      nomorMeja={nomorMeja}
      onTutup={onTutup}
    />
  )
}
