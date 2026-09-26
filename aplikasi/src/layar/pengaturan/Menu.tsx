/**
 * Menu.tsx — Pengelolaan Menu Lengkap (T9-05 / PRD M2 & M3).
 *
 * Mengizinkan Owner Resto (atau staf berizin atur_pengaturan) untuk:
 *  1. CRUD Kategori menu (nama, urutan, tujuan dapur/bar, status aktif).
 *  2. CRUD Menu item (nama, deskripsi, harga, foto, urutan, unggulan, jenis, aktif).
 *  3. Mengelola Varian menu (rasa, ukuran, level kepedasan dengan tambahan harga).
 *  4. Mengelola Opsi Tambahan / Topping (ekstra keju, telur, sambal dll).
 *  5. Mengubah urutan tampil (sorting order) kategori dan menu via tombol panah.
 *  6. Penanda habis manual di menu per cabang (terintegrasi tandai_habis).
 *  7. Mitigasi fail-closed: menu yang pernah dipesan dicegah dari penghapusan fisik,
 *     tersedia tombol cepat soft-delete (nonaktifkan menu) yang aman bagi pembukuan.
 */

import { useState, useId } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { rupiah } from '../../lib/format'

export interface DataKategori {
  id: string
  nama: string
  urutan: number
  tujuan: 'dapur' | 'bar'
  aktif: boolean
  jumlah_menu?: number
}

export interface DataVarian {
  nama: string
  tambahan_harga: number
  aktif?: boolean
}

export interface DataTambahan {
  id?: string
  nama: string
  harga: number
  aktif?: boolean
}

export interface DataMenuItem {
  id: string
  kategori_id: string
  kategori_nama?: string
  nama: string
  deskripsi?: string
  harga: number
  foto_path?: string
  urutan: number
  unggulan: boolean
  jenis: 'makanan' | 'minuman' | 'lainnya'
  aktif: boolean
  habis?: boolean
  harga_cabang?: number | null
  varian?: DataVarian[]
  tambahan?: DataTambahan[]
}

export interface MenuProps {
  daftarKategoriAwal?: DataKategori[]
  daftarMenuAwal?: DataMenuItem[]
  cabangId?: string
  onSimpanKategori?: (data: {
    id?: string
    nama: string
    urutan?: number
    tujuan: 'dapur' | 'bar'
    aktif: boolean
  }) => Promise<{ berhasil: boolean; id?: string; pesan?: string }>
  onHapusKategori?: (id: string) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanMenu?: (data: {
    id?: string
    kategori_id: string
    nama: string
    deskripsi?: string
    harga: number
    foto_path?: string
    urutan?: number
    unggulan?: boolean
    jenis: 'makanan' | 'minuman' | 'lainnya'
    aktif?: boolean
    varian?: DataVarian[]
    tambahan?: DataTambahan[]
  }) => Promise<{ berhasil: boolean; id?: string; pesan?: string }>
  onHapusMenu?: (id: string) => Promise<{ berhasil: boolean; pesan?: string }>
  onTandaiHabis?: (menuId: string, habis: boolean) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanUrutanKategori?: (
    urutan: Array<{ id: string; urutan: number }>,
  ) => Promise<{ berhasil: boolean }>
  onSimpanUrutanMenu?: (
    urutan: Array<{ id: string; urutan: number }>,
  ) => Promise<{ berhasil: boolean }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

const KATEGORI_BAWAAN: DataKategori[] = [
  { id: 'kat-1', nama: 'Makanan Utama', urutan: 1, tujuan: 'dapur', aktif: true, jumlah_menu: 2 },
  { id: 'kat-2', nama: 'Minuman Segar', urutan: 2, tujuan: 'bar', aktif: true, jumlah_menu: 1 },
]

const MENU_BAWAAN: DataMenuItem[] = [
  {
    id: 'm-1',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan Utama',
    nama: 'Nasi Goreng Spesial',
    deskripsi: 'Nasi goreng bumbu rempah dengan telur mata sapi dan acar',
    harga: 25000,
    foto_path: '',
    urutan: 1,
    unggulan: true,
    jenis: 'makanan',
    aktif: true,
    habis: false,
    varian: [
      { nama: 'Sedang', tambahan_harga: 0, aktif: true },
      { nama: 'Pedas', tambahan_harga: 0, aktif: true },
    ],
    tambahan: [{ id: 't-1', nama: 'Telur Dadar', harga: 4000, aktif: true }],
  },
  {
    id: 'm-2',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan Utama',
    nama: 'Mie Goreng Jawa',
    deskripsi: 'Mie kuning kenyal dengan suwiran ayam kampung dan sayur segar',
    harga: 22000,
    foto_path: '',
    urutan: 2,
    unggulan: false,
    jenis: 'makanan',
    aktif: true,
    habis: false,
    varian: [],
    tambahan: [],
  },
  {
    id: 'm-3',
    kategori_id: 'kat-2',
    kategori_nama: 'Minuman Segar',
    nama: 'Es Teh Manis',
    deskripsi: 'Seduhan teh melati wangi dengan gula asli dan es batu kristal',
    harga: 6000,
    foto_path: '',
    urutan: 1,
    unggulan: false,
    jenis: 'minuman',
    aktif: true,
    habis: false,
    varian: [
      { nama: 'Dingin', tambahan_harga: 0, aktif: true },
      { nama: 'Hangat', tambahan_harga: 0, aktif: true },
    ],
    tambahan: [],
  },
]

export function Menu({
  daftarKategoriAwal = KATEGORI_BAWAAN,
  daftarMenuAwal = MENU_BAWAAN,
  cabangId: _cabangId,
  onSimpanKategori,
  onHapusKategori,
  onSimpanMenu,
  onHapusMenu,
  onTandaiHabis,
  onSimpanUrutanKategori,
  onSimpanUrutanMenu,
  onKembali,
  hanyaBaca = false,
}: MenuProps) {
  const [daftarKategori, setDaftarKategori] = useState<DataKategori[]>(daftarKategoriAwal)
  const [daftarMenu, setDaftarMenu] = useState<DataMenuItem[]>(daftarMenuAwal)

  // Filter Kategori Aktif & Pencarian
  const [filterKategoriId, setFilterKategoriId] = useState<string>('semua')
  const [kataKunciCari, setKataKunciCari] = useState<string>('')

  // Notifikasi / Status
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [memuat, setMemuat] = useState<boolean>(false)

  // Dialog / Modal Form Kategori
  const [modalKategoriBuka, setModalKategoriBuka] = useState<boolean>(false)
  const [editKategoriData, setEditKategoriData] = useState<{
    id?: string
    nama: string
    urutan: number
    tujuan: 'dapur' | 'bar'
    aktif: boolean
  }>({ nama: '', urutan: 1, tujuan: 'dapur', aktif: true })

  // Dialog / Modal Form Menu
  const [modalMenuBuka, setModalMenuBuka] = useState<boolean>(false)
  const [editMenuData, setEditMenuData] = useState<{
    id?: string
    kategori_id: string
    nama: string
    deskripsi: string
    harga: number
    foto_path: string
    urutan: number
    unggulan: boolean
    jenis: 'makanan' | 'minuman' | 'lainnya'
    aktif: boolean
    varian: DataVarian[]
    tambahan: DataTambahan[]
  }>({
    kategori_id: daftarKategori[0]?.id || '',
    nama: '',
    deskripsi: '',
    harga: 0,
    foto_path: '',
    urutan: 1,
    unggulan: false,
    jenis: 'makanan',
    aktif: true,
    varian: [],
    tambahan: [],
  })

  // State input varian & tambahan sementara di form
  const [inputNamaVarian, setInputNamaVarian] = useState<string>('')
  const [inputHargaVarian, setInputHargaVarian] = useState<string>('0')
  const [inputNamaTambahan, setInputNamaTambahan] = useState<string>('')
  const [inputHargaTambahan, setInputHargaTambahan] = useState<string>('0')

  // Modal Konfirmasi Hapus
  const [menuAkanDihapus, setMenuAkanDihapus] = useState<DataMenuItem | null>(null)
  const [kategoriAkanDihapus, setKategoriAkanDihapus] = useState<DataKategori | null>(null)

  const idSelectKategori = useId()
  const idSelectJenis = useId()
  const idSelectTujuan = useId()

  // Statistik Ringkasan
  const totalMenu = daftarMenu.length
  const menuAktif = daftarMenu.filter((m) => m.aktif).length
  const menuHabis = daftarMenu.filter((m) => m.habis).length
  const totalKategori = daftarKategori.length

  // Filter menu yang ditampilkan
  const menuDitampilkan = daftarMenu.filter((m) => {
    const cocokKategori = filterKategoriId === 'semua' || m.kategori_id === filterKategoriId
    const cocokCari =
      kataKunciCari.trim() === '' ||
      m.nama.toLowerCase().includes(kataKunciCari.toLowerCase()) ||
      (m.deskripsi && m.deskripsi.toLowerCase().includes(kataKunciCari.toLowerCase()))
    return cocokKategori && cocokCari
  })

  // Helper proses kompresi foto klien via Canvas
  const prosesBerkasFoto = async (berkas: File): Promise<string> => {
    return new Promise((resolve) => {
      if (!berkas.type.startsWith('image/')) {
        resolve('')
        return
      }
      const reader = new FileReader()
      reader.onload = (e) => {
        const dataUrl = e.target?.result as string
        const img = new Image()
        img.onload = () => {
          try {
            let lebar = img.width
            let tinggi = img.height
            const maksDimensi = 1000
            if (lebar > maksDimensi || tinggi > maksDimensi) {
              const rasio = Math.min(maksDimensi / lebar, maksDimensi / tinggi)
              lebar = Math.round(lebar * rasio)
              tinggi = Math.round(tinggi * rasio)
            }
            const canvas = document.createElement('canvas')
            canvas.width = lebar
            canvas.height = tinggi
            const ctx = canvas.getContext('2d')
            if (!ctx) {
              resolve(dataUrl)
              return
            }
            ctx.drawImage(img, 0, 0, lebar, tinggi)
            resolve(canvas.toDataURL('image/jpeg', 0.85))
          } catch {
            resolve(dataUrl)
          }
        }
        img.src = dataUrl
      }
      reader.readAsDataURL(berkas)
    })
  }

  // --- Handlers Kategori ---
  const bukaModalTambahKategori = () => {
    setEditKategoriData({
      nama: '',
      urutan: daftarKategori.length + 1,
      tujuan: 'dapur',
      aktif: true,
    })
    setModalKategoriBuka(true)
    setPesanGalat(null)
  }

  const bukaModalEditKategori = (kat: DataKategori) => {
    setEditKategoriData({
      id: kat.id,
      nama: kat.nama,
      urutan: kat.urutan,
      tujuan: kat.tujuan,
      aktif: kat.aktif,
    })
    setModalKategoriBuka(true)
    setPesanGalat(null)
  }

  const simpanKategori = async () => {
    if (!editKategoriData.nama.trim()) {
      setPesanGalat('Nama kategori wajib diisi.')
      return
    }

    setMemuat(true)
    setPesanGalat(null)
    try {
      if (onSimpanKategori) {
        const res = await onSimpanKategori({
          id: editKategoriData.id,
          nama: editKategoriData.nama.trim(),
          urutan: editKategoriData.urutan,
          tujuan: editKategoriData.tujuan,
          aktif: editKategoriData.aktif,
        })
        if (!res.berhasil) {
          setPesanGalat(res.pesan || 'Gagal menyimpan kategori menu.')
          setMemuat(false)
          return
        }
      }

      if (editKategoriData.id) {
        setDaftarKategori((lama) =>
          lama.map((k) =>
            k.id === editKategoriData.id
              ? {
                  ...k,
                  nama: editKategoriData.nama.trim(),
                  urutan: editKategoriData.urutan,
                  tujuan: editKategoriData.tujuan,
                  aktif: editKategoriData.aktif,
                }
              : k,
          ),
        )
        setPesanSukses(`Kategori "${editKategoriData.nama.trim()}" berhasil diperbarui.`)
      } else {
        const idBaru = 'kat-' + Date.now()
        setDaftarKategori((lama) => [
          ...lama,
          {
            id: idBaru,
            nama: editKategoriData.nama.trim(),
            urutan: editKategoriData.urutan,
            tujuan: editKategoriData.tujuan,
            aktif: editKategoriData.aktif,
            jumlah_menu: 0,
          },
        ])
        setPesanSukses(`Kategori baru "${editKategoriData.nama.trim()}" berhasil dibuat.`)
      }
      setModalKategoriBuka(false)
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Terjadi galat saat menyimpan kategori.')
    } finally {
      setMemuat(false)
    }
  }

  const eksekusiHapusKategori = async () => {
    if (!kategoriAkanDihapus) return
    const menuDiKategori = daftarMenu.filter((m) => m.kategori_id === kategoriAkanDihapus.id)
    if (menuDiKategori.length > 0) {
      setPesanGalat(
        `Kategori "${kategoriAkanDihapus.nama}" masih memiliki ${menuDiKategori.length} menu. Pindahkan atau hapus menu terlebih dahulu.`,
      )
      setKategoriAkanDihapus(null)
      return
    }

    setMemuat(true)
    try {
      if (onHapusKategori) {
        const res = await onHapusKategori(kategoriAkanDihapus.id)
        if (!res.berhasil) {
          setPesanGalat(res.pesan || 'Gagal menghapus kategori.')
          setMemuat(false)
          return
        }
      }
      setDaftarKategori((lama) => lama.filter((k) => k.id !== kategoriAkanDihapus.id))
      setPesanSukses(`Kategori "${kategoriAkanDihapus.nama}" berhasil dihapus.`)
      if (filterKategoriId === kategoriAkanDihapus.id) {
        setFilterKategoriId('semua')
      }
      setKategoriAkanDihapus(null)
    } catch (err: unknown) {
      setPesanGalat(
        err instanceof Error ? err.message : 'Terjadi kesalahan saat menghapus kategori.',
      )
    } finally {
      setMemuat(false)
    }
  }

  const geserUrutanKategori = async (indeks: number, arah: 'atas' | 'bawah') => {
    if (hanyaBaca) return
    const targetIndeks = arah === 'atas' ? indeks - 1 : indeks + 1
    if (targetIndeks < 0 || targetIndeks >= daftarKategori.length) return

    const salinan = [...daftarKategori]
    const sementara = salinan[indeks]
    salinan[indeks] = salinan[targetIndeks]
    salinan[targetIndeks] = sementara

    const diperbarui = salinan.map((k, i) => ({ ...k, urutan: i + 1 }))
    setDaftarKategori(diperbarui)

    if (onSimpanUrutanKategori) {
      await onSimpanUrutanKategori(diperbarui.map((k) => ({ id: k.id, urutan: k.urutan })))
    }
  }

  // --- Handlers Menu ---
  const bukaModalTambahMenu = () => {
    setEditMenuData({
      kategori_id: filterKategoriId !== 'semua' ? filterKategoriId : daftarKategori[0]?.id || '',
      nama: '',
      deskripsi: '',
      harga: 0,
      foto_path: '',
      urutan: daftarMenu.length + 1,
      unggulan: false,
      jenis: 'makanan',
      aktif: true,
      varian: [],
      tambahan: [],
    })
    setInputNamaVarian('')
    setInputHargaVarian('0')
    setInputNamaTambahan('')
    setInputHargaTambahan('0')
    setModalMenuBuka(true)
    setPesanGalat(null)
  }

  const bukaModalEditMenu = (menu: DataMenuItem) => {
    setEditMenuData({
      id: menu.id,
      kategori_id: menu.kategori_id,
      nama: menu.nama,
      deskripsi: menu.deskripsi || '',
      harga: menu.harga,
      foto_path: menu.foto_path || '',
      urutan: menu.urutan,
      unggulan: menu.unggulan,
      jenis: menu.jenis,
      aktif: menu.aktif,
      varian: menu.varian ? [...menu.varian] : [],
      tambahan: menu.tambahan ? [...menu.tambahan] : [],
    })
    setInputNamaVarian('')
    setInputHargaVarian('0')
    setInputNamaTambahan('')
    setInputHargaTambahan('0')
    setModalMenuBuka(true)
    setPesanGalat(null)
  }

  const tambahVarianKeForm = () => {
    if (!inputNamaVarian.trim()) return
    const selisih = parseInt(inputHargaVarian, 10) || 0
    setEditMenuData((lama) => ({
      ...lama,
      varian: [
        ...lama.varian,
        { nama: inputNamaVarian.trim(), tambahan_harga: selisih, aktif: true },
      ],
    }))
    setInputNamaVarian('')
    setInputHargaVarian('0')
  }

  const hapusVarianDariForm = (indeks: number) => {
    setEditMenuData((lama) => ({
      ...lama,
      varian: lama.varian.filter((_, i) => i !== indeks),
    }))
  }

  const tambahTambahanKeForm = () => {
    if (!inputNamaTambahan.trim()) return
    const hrg = Math.max(0, parseInt(inputHargaTambahan, 10) || 0)
    setEditMenuData((lama) => ({
      ...lama,
      tambahan: [...lama.tambahan, { nama: inputNamaTambahan.trim(), harga: hrg, aktif: true }],
    }))
    setInputNamaTambahan('')
    setInputHargaTambahan('0')
  }

  const hapusTambahanDariForm = (indeks: number) => {
    setEditMenuData((lama) => ({
      ...lama,
      tambahan: lama.tambahan.filter((_, i) => i !== indeks),
    }))
  }

  const simpanMenu = async () => {
    if (!editMenuData.nama.trim()) {
      setPesanGalat('Nama menu wajib diisi.')
      return
    }
    if (editMenuData.harga < 0) {
      setPesanGalat('Harga menu tidak boleh negatif.')
      return
    }
    if (!editMenuData.kategori_id) {
      setPesanGalat('Kategori menu wajib dipilih.')
      return
    }

    setMemuat(true)
    setPesanGalat(null)
    try {
      if (onSimpanMenu) {
        const res = await onSimpanMenu({
          id: editMenuData.id,
          kategori_id: editMenuData.kategori_id,
          nama: editMenuData.nama.trim(),
          deskripsi: editMenuData.deskripsi.trim(),
          harga: editMenuData.harga,
          foto_path: editMenuData.foto_path,
          urutan: editMenuData.urutan,
          unggulan: editMenuData.unggulan,
          jenis: editMenuData.jenis,
          aktif: editMenuData.aktif,
          varian: editMenuData.varian,
          tambahan: editMenuData.tambahan,
        })
        if (!res.berhasil) {
          setPesanGalat(res.pesan || 'Gagal menyimpan menu.')
          setMemuat(false)
          return
        }
      }

      const namaKat =
        daftarKategori.find((k) => k.id === editMenuData.kategori_id)?.nama || 'Kategori'

      if (editMenuData.id) {
        setDaftarMenu((lama) =>
          lama.map((m) =>
            m.id === editMenuData.id
              ? {
                  ...m,
                  kategori_id: editMenuData.kategori_id,
                  kategori_nama: namaKat,
                  nama: editMenuData.nama.trim(),
                  deskripsi: editMenuData.deskripsi.trim(),
                  harga: editMenuData.harga,
                  foto_path: editMenuData.foto_path,
                  urutan: editMenuData.urutan,
                  unggulan: editMenuData.unggulan,
                  jenis: editMenuData.jenis,
                  aktif: editMenuData.aktif,
                  varian: editMenuData.varian,
                  tambahan: editMenuData.tambahan,
                }
              : m,
          ),
        )
        setPesanSukses(`Menu "${editMenuData.nama.trim()}" berhasil diperbarui.`)
      } else {
        const idBaru = 'm-' + Date.now()
        setDaftarMenu((lama) => [
          ...lama,
          {
            id: idBaru,
            kategori_id: editMenuData.kategori_id,
            kategori_nama: namaKat,
            nama: editMenuData.nama.trim(),
            deskripsi: editMenuData.deskripsi.trim(),
            harga: editMenuData.harga,
            foto_path: editMenuData.foto_path,
            urutan: editMenuData.urutan,
            unggulan: editMenuData.unggulan,
            jenis: editMenuData.jenis,
            aktif: editMenuData.aktif,
            habis: false,
            varian: editMenuData.varian,
            tambahan: editMenuData.tambahan,
          },
        ])
        setPesanSukses(`Menu baru "${editMenuData.nama.trim()}" berhasil ditambahkan.`)
      }
      setModalMenuBuka(false)
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Terjadi galat saat menyimpan menu.')
    } finally {
      setMemuat(false)
    }
  }

  const toggleAktifMenu = async (menu: DataMenuItem) => {
    if (hanyaBaca) return
    const statusBaru = !menu.aktif
    setMemuat(true)
    try {
      if (onSimpanMenu) {
        await onSimpanMenu({
          id: menu.id,
          kategori_id: menu.kategori_id,
          nama: menu.nama,
          harga: menu.harga,
          jenis: menu.jenis,
          aktif: statusBaru,
        })
      }
      setDaftarMenu((lama) => lama.map((m) => (m.id === menu.id ? { ...m, aktif: statusBaru } : m)))
      setPesanSukses(
        `Status menu "${menu.nama}" berhasil diubah menjadi ${statusBaru ? 'Aktif' : 'Nonaktif'}.`,
      )
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Gagal mengubah status aktif menu.')
    } finally {
      setMemuat(false)
    }
  }

  const toggleHabisMenu = async (menu: DataMenuItem) => {
    if (hanyaBaca) return
    const habisBaru = !menu.habis
    setMemuat(true)
    try {
      if (onTandaiHabis) {
        await onTandaiHabis(menu.id, habisBaru)
      }
      setDaftarMenu((lama) => lama.map((m) => (m.id === menu.id ? { ...m, habis: habisBaru } : m)))
      setPesanSukses(
        `Ketersediaan menu "${menu.nama}" ditandai ${habisBaru ? 'HABIS' : 'TERSEDIA'}.`,
      )
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Gagal mengubah penanda habis menu.')
    } finally {
      setMemuat(false)
    }
  }

  const eksekusiHapusMenu = async () => {
    if (!menuAkanDihapus) return
    setMemuat(true)
    setPesanGalat(null)
    try {
      if (onHapusMenu) {
        const res = await onHapusMenu(menuAkanDihapus.id)
        if (!res.berhasil) {
          setPesanGalat(
            res.pesan ||
              'Menu ini memiliki riwayat transaksi pesanan dan tidak boleh dihapus secara permanen. Silakan nonaktifkan menu (aktif = false).',
          )
          setMemuat(false)
          return
        }
      }
      setDaftarMenu((lama) => lama.filter((m) => m.id !== menuAkanDihapus.id))
      setPesanSukses(`Menu "${menuAkanDihapus.nama}" berhasil dihapus.`)
      setMenuAkanDihapus(null)
    } catch (err: unknown) {
      setPesanGalat(
        err instanceof Error
          ? err.message
          : 'Menu ini memiliki riwayat transaksi pesanan dan tidak boleh dihapus permanen. Gunakan nonaktifkan menu.',
      )
    } finally {
      setMemuat(false)
    }
  }

  const geserUrutanMenu = async (indeks: number, arah: 'atas' | 'bawah') => {
    if (hanyaBaca) return
    const targetIndeks = arah === 'atas' ? indeks - 1 : indeks + 1
    if (targetIndeks < 0 || targetIndeks >= menuDitampilkan.length) return

    const menuIndeksAsli = daftarMenu.findIndex((m) => m.id === menuDitampilkan[indeks].id)
    const menuTargetAsli = daftarMenu.findIndex((m) => m.id === menuDitampilkan[targetIndeks].id)
    if (menuIndeksAsli === -1 || menuTargetAsli === -1) return

    const salinan = [...daftarMenu]
    const temp = salinan[menuIndeksAsli]
    salinan[menuIndeksAsli] = salinan[menuTargetAsli]
    salinan[menuTargetAsli] = temp

    const diperbarui = salinan.map((m, i) => ({ ...m, urutan: i + 1 }))
    setDaftarMenu(diperbarui)

    if (onSimpanUrutanMenu) {
      await onSimpanUrutanMenu(diperbarui.map((m) => ({ id: m.id, urutan: m.urutan })))
    }
  }

  return (
    <div className="pengaturan-menu" data-testid="pengaturan-menu">
      {/* Header & Navigasi Pengaturan */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          marginBottom: '1.25rem',
        }}
      >
        <div>
          <h2 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 700 }}>
            Pengelolaan Menu & Kategori
          </h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--teks-redup)', fontSize: '0.9rem' }}>
            Atur master kategori, varian rasa/ukuran, topping ekstra, foto menu, dan urutan tampil
            tanpa koding.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu identitas">
              ← Kembali
            </Tombol>
          )}
          {!hanyaBaca && (
            <>
              <Tombol
                ragam="biasa"
                onClick={bukaModalTambahKategori}
                nama="Tambah Kategori Menu Baru"
              >
                + Kategori Baru
              </Tombol>
              <Tombol ragam="utama" onClick={bukaModalTambahMenu} nama="Tambah Menu Baru">
                + Tambah Menu Baru
              </Tombol>
            </>
          )}
        </div>
      </div>

      {/* Banner Pesan Sukses / Galat */}
      {pesanSukses && (
        <div
          role="status"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            backgroundColor: 'var(--sukses-latar, var(--latar-kartu))',
            color: 'var(--sukses, var(--teks))',
            borderRadius: 'var(--radius, 8px)',
            border: '1px solid var(--sukses)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{pesanSukses}</span>
          <Tombol ragam="biasa" onClick={() => setPesanSukses(null)} nama="Tutup pesan sukses">
            ✕
          </Tombol>
        </div>
      )}

      {pesanGalat && (
        <div
          role="alert"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            backgroundColor: 'var(--bahaya-latar, var(--latar-kartu))',
            color: 'var(--bahaya, var(--teks))',
            borderRadius: 'var(--radius, 8px)',
            border: '1px solid var(--bahaya)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{pesanGalat}</span>
          <Tombol ragam="biasa" onClick={() => setPesanGalat(null)} nama="Tutup pesan kesalahan">
            ✕
          </Tombol>
        </div>
      )}

      {/* Kartu Ringkasan Statistik */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: '0.75rem',
          marginBottom: '1.25rem',
        }}
      >
        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>Total Menu</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 700, marginTop: '0.25rem' }}>
            {totalMenu}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>Menu Aktif</div>
          <div
            style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              marginTop: '0.25rem',
              color: 'var(--sukses)',
            }}
          >
            {menuAktif}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>Habis di Cabang</div>
          <div
            style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              marginTop: '0.25rem',
              color: menuHabis > 0 ? 'var(--bahaya)' : 'var(--teks)',
            }}
          >
            {menuHabis}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>Total Kategori</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 700, marginTop: '0.25rem' }}>
            {totalKategori}
          </div>
        </Kartu>
      </div>

      {/* Navigasi Kategori (Tab Filter + Pengaturan Urutan Kategori) */}
      <div
        style={{
          padding: '0.75rem 1rem',
          backgroundColor: 'var(--latar-kartu)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius, 8px)',
          marginBottom: '1rem',
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: '0.5rem',
          }}
        >
          <span style={{ fontSize: '0.85rem', fontWeight: 600, color: 'var(--teks-redup)' }}>
            KATEGORI MENU
          </span>
          <span style={{ fontSize: '0.8rem', color: 'var(--teks-redup)' }}>
            Gunakan tombol panah untuk mengatur urutan
          </span>
        </div>

        <div
          style={{
            display: 'flex',
            gap: '0.5rem',
            overflowX: 'auto',
            paddingBottom: '0.25rem',
            alignItems: 'center',
          }}
        >
          <Tombol
            ragam={filterKategoriId === 'semua' ? 'utama' : 'biasa'}
            onClick={() => setFilterKategoriId('semua')}
            nama="Tampilkan semua kategori menu"
          >
            Semua ({totalMenu})
          </Tombol>

          {daftarKategori.map((kat, idx) => {
            const aktif = filterKategoriId === kat.id
            const jumlahItem = daftarMenu.filter((m) => m.kategori_id === kat.id).length
            return (
              <div
                key={kat.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  backgroundColor: aktif ? 'var(--utama-latar, var(--latar))' : 'var(--latar)',
                  border: `1px solid ${aktif ? 'var(--utama)' : 'var(--border)'}`,
                  borderRadius: 'var(--radius, 6px)',
                  padding: '0.15rem 0.35rem',
                  gap: '0.25rem',
                }}
              >
                <Tombol
                  ragam={aktif ? 'utama' : 'biasa'}
                  onClick={() => setFilterKategoriId(kat.id)}
                  nama={`Pilih kategori ${kat.nama}`}
                >
                  {kat.nama} ({jumlahItem})
                </Tombol>

                <Lencana nada={kat.tujuan === 'bar' ? 'info' : 'netral'}>
                  {kat.tujuan === 'bar' ? 'Bar' : 'Dapur'}
                </Lencana>

                {!hanyaBaca && (
                  <div style={{ display: 'flex', gap: '0.15rem', marginLeft: '0.25rem' }}>
                    <Tombol
                      ragam="biasa"
                      onClick={() => geserUrutanKategori(idx, 'atas')}
                      nonaktif={idx === 0}
                      nama={`Geser kategori ${kat.nama} ke atas`}
                    >
                      ▲
                    </Tombol>
                    <Tombol
                      ragam="biasa"
                      onClick={() => geserUrutanKategori(idx, 'bawah')}
                      nonaktif={idx === daftarKategori.length - 1}
                      nama={`Geser kategori ${kat.nama} ke bawah`}
                    >
                      ▼
                    </Tombol>
                    <Tombol
                      ragam="biasa"
                      onClick={() => bukaModalEditKategori(kat)}
                      nama={`Edit kategori ${kat.nama}`}
                    >
                      ✏️
                    </Tombol>
                    <Tombol
                      ragam="bahaya"
                      onClick={() => setKategoriAkanDihapus(kat)}
                      nama={`Hapus kategori ${kat.nama}`}
                    >
                      🗑️
                    </Tombol>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      </div>

      {/* Bilah Pencarian Menu */}
      <div style={{ marginBottom: '1rem' }}>
        <KolomIsian
          label="Cari Menu"
          nilai={kataKunciCari}
          onUbah={setKataKunciCari}
          contoh="Ketik nama atau deskripsi menu..."
        />
      </div>

      {/* Daftar Menu Items */}
      {menuDitampilkan.length === 0 ? (
        <Kartu>
          <div style={{ padding: '2rem 1rem', textAlign: 'center' }}>
            <div style={{ fontSize: '2.5rem', marginBottom: '0.5rem' }}>🍲</div>
            <h3 style={{ margin: 0, fontWeight: 600 }}>Tidak ada menu ditemukan</h3>
            <p style={{ color: 'var(--teks-redup)', fontSize: '0.9rem', marginTop: '0.25rem' }}>
              {kataKunciCari
                ? 'Tidak ada menu yang sesuai dengan kata kunci pencarian.'
                : 'Belum ada menu di kategori ini. Tambahkan menu baru untuk mulai menjual.'}
            </p>
            {!hanyaBaca && (
              <Tombol ragam="utama" onClick={bukaModalTambahMenu} nama="Tambah Menu Pertama">
                + Tambah Menu Baru
              </Tombol>
            )}
          </div>
        </Kartu>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {menuDitampilkan.map((menu, idx) => {
            const kat = daftarKategori.find((k) => k.id === menu.kategori_id)
            const jumlahVarian = menu.varian ? menu.varian.length : 0
            const jumlahTambahan = menu.tambahan ? menu.tambahan.length : 0

            return (
              <div
                key={menu.id}
                data-testid={`baris-menu-${menu.id}`}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  backgroundColor: 'var(--latar-kartu)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius, 8px)',
                  padding: '0.85rem 1rem',
                  gap: '1rem',
                  flexWrap: 'wrap',
                  opacity: menu.aktif ? 1 : 0.65,
                }}
              >
                {/* Info Menu & Thumbnail */}
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    flex: '1 1 300px',
                  }}
                >
                  <div
                    style={{
                      width: '48px',
                      height: '48px',
                      borderRadius: 'var(--radius, 6px)',
                      backgroundColor: 'var(--latar)',
                      border: '1px solid var(--border)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '1.5rem',
                      overflow: 'hidden',
                      flexShrink: 0,
                    }}
                  >
                    {menu.foto_path ? (
                      <img
                        src={menu.foto_path}
                        alt={menu.nama}
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />
                    ) : menu.jenis === 'minuman' ? (
                      '🥤'
                    ) : (
                      '🍲'
                    )}
                  </div>

                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ fontWeight: 700, fontSize: '1.05rem' }}>{menu.nama}</span>
                      {menu.unggulan && <Lencana nada="accent">⭐ Unggulan</Lencana>}
                      <Lencana nada={menu.aktif ? 'success' : 'netral'}>
                        {menu.aktif ? 'Aktif' : 'Nonaktif'}
                      </Lencana>
                      {menu.habis && <Lencana nada="danger">Habis</Lencana>}
                    </div>

                    <div
                      style={{
                        fontSize: '0.85rem',
                        color: 'var(--teks-redup)',
                        marginTop: '0.2rem',
                        display: 'flex',
                        gap: '0.75rem',
                        flexWrap: 'wrap',
                      }}
                    >
                      <span>📁 {kat?.nama || menu.kategori_nama || 'Kategori'}</span>
                      <span>🎯 {kat?.tujuan === 'bar' ? 'Bar' : 'Dapur'}</span>
                      {jumlahVarian > 0 && <span>🔀 {jumlahVarian} Varian</span>}
                      {jumlahTambahan > 0 && <span>➕ {jumlahTambahan} Topping</span>}
                    </div>

                    {menu.deskripsi && (
                      <div
                        style={{
                          fontSize: '0.8rem',
                          color: 'var(--teks-redup)',
                          marginTop: '0.2rem',
                          maxWidth: '450px',
                        }}
                      >
                        {menu.deskripsi}
                      </div>
                    )}
                  </div>
                </div>

                {/* Harga Pokok & Harga Cabang */}
                <div style={{ textAlign: 'right', minWidth: '120px' }}>
                  <div style={{ fontWeight: 700, fontSize: '1.1rem', color: 'var(--teks)' }}>
                    {rupiah(menu.harga)}
                  </div>
                  {menu.harga_cabang && (
                    <div style={{ fontSize: '0.8rem', color: 'var(--teks-redup)' }}>
                      Cabang: {rupiah(menu.harga_cabang)}
                    </div>
                  )}
                </div>

                {/* Aksi Menu (Urutan, Status Habis, Toggle Aktif, Edit, Hapus) */}
                {!hanyaBaca && (
                  <div
                    style={{
                      display: 'flex',
                      gap: '0.35rem',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                    }}
                  >
                    {/* Tombol Urutan */}
                    <Tombol
                      ragam="biasa"
                      onClick={() => geserUrutanMenu(idx, 'atas')}
                      nonaktif={idx === 0}
                      nama={`Geser menu ${menu.nama} ke atas`}
                    >
                      ▲
                    </Tombol>
                    <Tombol
                      ragam="biasa"
                      onClick={() => geserUrutanMenu(idx, 'bawah')}
                      nonaktif={idx === menuDitampilkan.length - 1}
                      nama={`Geser menu ${menu.nama} ke bawah`}
                    >
                      ▼
                    </Tombol>

                    {/* Penanda Habis Manual */}
                    <Tombol
                      ragam={menu.habis ? 'bahaya' : 'biasa'}
                      onClick={() => toggleHabisMenu(menu)}
                      nama={`Tandai ${menu.habis ? 'tersedia' : 'habis'} menu ${menu.nama}`}
                    >
                      {menu.habis ? '❌ Habis' : '✅ Ada'}
                    </Tombol>

                    {/* Sakelar Aktif/Nonaktif */}
                    <Tombol
                      ragam={menu.aktif ? 'biasa' : 'utama'}
                      onClick={() => toggleAktifMenu(menu)}
                      nama={`Ubah status aktif menu ${menu.nama}`}
                    >
                      {menu.aktif ? 'Nonaktifkan' : 'Aktifkan'}
                    </Tombol>

                    {/* Tombol Edit */}
                    <Tombol
                      ragam="biasa"
                      onClick={() => bukaModalEditMenu(menu)}
                      nama={`Edit menu ${menu.nama}`}
                    >
                      ✏️ Edit
                    </Tombol>

                    {/* Tombol Hapus */}
                    <Tombol
                      ragam="bahaya"
                      onClick={() => setMenuAkanDihapus(menu)}
                      nama={`Hapus menu ${menu.nama}`}
                    >
                      🗑️
                    </Tombol>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {/* Modal Form Kategori (Tambah / Edit) */}
      {modalKategoriBuka && (
        <Lapis
          buka={modalKategoriBuka}
          judul={editKategoriData.id ? 'Edit Kategori Menu' : 'Tambah Kategori Menu Baru'}
          onTutup={() => setModalKategoriBuka(false)}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', minWidth: '320px' }}>
            <KolomIsian
              label="Nama Kategori"
              nilai={editKategoriData.nama}
              onUbah={(val) => setEditKategoriData((lama) => ({ ...lama, nama: val }))}
              contoh="Contoh: Makanan Berat, Minuman Dingin, Snack"
            />

            <div>
              <label
                htmlFor={idSelectTujuan}
                style={{
                  display: 'block',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  marginBottom: '0.35rem',
                }}
              >
                Tujuan Layar Produksi
              </label>
              <select
                id={idSelectTujuan}
                value={editKategoriData.tujuan}
                onChange={(e) =>
                  setEditKategoriData((lama) => ({
                    ...lama,
                    tujuan: e.target.value as 'dapur' | 'bar',
                  }))
                }
                style={{
                  width: '100%',
                  padding: '0.5rem 0.75rem',
                  borderRadius: 'var(--radius, 6px)',
                  border: '1px solid var(--border)',
                  backgroundColor: 'var(--latar)',
                  color: 'var(--teks)',
                  fontSize: '0.95rem',
                }}
              >
                <option value="dapur">Dapur (Makanan / Masak)</option>
                <option value="bar">Bar (Minuman / Racikan)</option>
              </select>
              <div
                style={{ fontSize: '0.75rem', color: 'var(--teks-redup)', marginTop: '0.25rem' }}
              >
                Pesanan pada kategori ini otomatis diarahkan ke layar dapur atau layar bar yang
                sesuai.
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <input
                id="kat-aktif"
                type="checkbox"
                checked={editKategoriData.aktif}
                onChange={(e) =>
                  setEditKategoriData((lama) => ({ ...lama, aktif: e.target.checked }))
                }
              />
              <label htmlFor="kat-aktif" style={{ fontSize: '0.9rem', cursor: 'pointer' }}>
                Kategori Aktif & Ditampilkan di Menu
              </label>
            </div>

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: '0.5rem',
                marginTop: '0.5rem',
              }}
            >
              <Tombol
                ragam="biasa"
                onClick={() => setModalKategoriBuka(false)}
                nama="Batal simpan kategori"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                onClick={simpanKategori}
                nonaktif={memuat}
                nama="Simpan data kategori menu"
              >
                {memuat ? 'Menyimpan...' : 'Simpan Kategori'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Form Menu (Tambah / Edit Lengkap) */}
      {modalMenuBuka && (
        <Lapis
          buka={modalMenuBuka}
          judul={editMenuData.id ? 'Edit Menu Item' : 'Tambah Menu Baru'}
          onTutup={() => setModalMenuBuka(false)}
        >
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '1rem',
              maxWidth: '560px',
              maxHeight: '80vh',
              overflowY: 'auto',
              paddingRight: '0.25rem',
            }}
          >
            {/* Nama Menu */}
            <KolomIsian
              label="Nama Menu"
              nilai={editMenuData.nama}
              onUbah={(val) => setEditMenuData((lama) => ({ ...lama, nama: val }))}
              contoh="Contoh: Nasi Goreng Kambing, Es Kopi Susu"
            />

            {/* Kategori & Jenis */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: '0.75rem',
              }}
            >
              <div>
                <label
                  htmlFor={idSelectKategori}
                  style={{
                    display: 'block',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    marginBottom: '0.35rem',
                  }}
                >
                  Kategori Menu
                </label>
                <select
                  id={idSelectKategori}
                  value={editMenuData.kategori_id}
                  onChange={(e) =>
                    setEditMenuData((lama) => ({ ...lama, kategori_id: e.target.value }))
                  }
                  style={{
                    width: '100%',
                    padding: '0.5rem 0.75rem',
                    borderRadius: 'var(--radius, 6px)',
                    border: '1px solid var(--border)',
                    backgroundColor: 'var(--latar)',
                    color: 'var(--teks)',
                    fontSize: '0.95rem',
                  }}
                >
                  {daftarKategori.map((k) => (
                    <option key={k.id} value={k.id}>
                      {k.nama} ({k.tujuan === 'bar' ? 'Bar' : 'Dapur'})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label
                  htmlFor={idSelectJenis}
                  style={{
                    display: 'block',
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    marginBottom: '0.35rem',
                  }}
                >
                  Jenis Menu
                </label>
                <select
                  id={idSelectJenis}
                  value={editMenuData.jenis}
                  onChange={(e) =>
                    setEditMenuData((lama) => ({
                      ...lama,
                      jenis: e.target.value as 'makanan' | 'minuman' | 'lainnya',
                    }))
                  }
                  style={{
                    width: '100%',
                    padding: '0.5rem 0.75rem',
                    borderRadius: 'var(--radius, 6px)',
                    border: '1px solid var(--border)',
                    backgroundColor: 'var(--latar)',
                    color: 'var(--teks)',
                    fontSize: '0.95rem',
                  }}
                >
                  <option value="makanan">Makanan</option>
                  <option value="minuman">Minuman</option>
                  <option value="lainnya">Lainnya / Camilan</option>
                </select>
              </div>
            </div>

            {/* Harga Pokok */}
            <KolomIsian
              label="Harga Pokok (Rp)"
              jenis="number"
              nilai={editMenuData.harga.toString()}
              onUbah={(val) => {
                const n = parseInt(val, 10)
                setEditMenuData((lama) => ({ ...lama, harga: isNaN(n) ? 0 : n }))
              }}
              contoh="25000"
            />

            {/* Deskripsi */}
            <KolomIsian
              label="Deskripsi Menu (Opsional)"
              nilai={editMenuData.deskripsi}
              onUbah={(val) => setEditMenuData((lama) => ({ ...lama, deskripsi: val }))}
              contoh="Penjelasan singkat menu untuk katalog dan kasir"
            />

            {/* Unggah Foto / Pratinjau Foto */}
            <div>
              <span
                style={{
                  display: 'block',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  marginBottom: '0.35rem',
                }}
              >
                Foto Menu (JPG/PNG/WebP maks 1000px)
              </span>
              <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  aria-label="Pilih foto menu"
                  onChange={async (e) => {
                    const berkas = e.target.files?.[0]
                    if (berkas) {
                      const hasil = await prosesBerkasFoto(berkas)
                      setEditMenuData((lama) => ({ ...lama, foto_path: hasil }))
                    }
                  }}
                  style={{ fontSize: '0.85rem' }}
                />
                {editMenuData.foto_path && (
                  <Tombol
                    ragam="biasa"
                    onClick={() => setEditMenuData((lama) => ({ ...lama, foto_path: '' }))}
                    nama="Hapus foto menu"
                  >
                    Hapus Foto
                  </Tombol>
                )}
              </div>
              {editMenuData.foto_path && (
                <div style={{ marginTop: '0.5rem' }}>
                  <img
                    src={editMenuData.foto_path}
                    alt="Pratinjau foto menu"
                    style={{
                      maxHeight: '120px',
                      borderRadius: 'var(--radius, 6px)',
                      border: '1px solid var(--border)',
                    }}
                  />
                </div>
              )}
            </div>

            {/* Checkbox Unggulan & Aktif */}
            <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <input
                  id="menu-unggulan"
                  type="checkbox"
                  checked={editMenuData.unggulan}
                  onChange={(e) =>
                    setEditMenuData((lama) => ({ ...lama, unggulan: e.target.checked }))
                  }
                />
                <label htmlFor="menu-unggulan" style={{ fontSize: '0.9rem', cursor: 'pointer' }}>
                  ⭐ Menu Unggulan (Tampil di rekomendasi)
                </label>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <input
                  id="menu-aktif"
                  type="checkbox"
                  checked={editMenuData.aktif}
                  onChange={(e) =>
                    setEditMenuData((lama) => ({ ...lama, aktif: e.target.checked }))
                  }
                />
                <label htmlFor="menu-aktif" style={{ fontSize: '0.9rem', cursor: 'pointer' }}>
                  Menu Aktif (Dapat dijual)
                </label>
              </div>
            </div>

            {/* Bagian Varian Menu (Rasa / Ukuran / Level) */}
            <div
              style={{
                borderTop: '1px solid var(--border)',
                paddingTop: '0.75rem',
                marginTop: '0.25rem',
              }}
            >
              <span
                style={{
                  display: 'block',
                  fontSize: '0.9rem',
                  fontWeight: 700,
                  marginBottom: '0.35rem',
                }}
              >
                Varian Menu (Opsi Pilihan Satu Rasa / Ukuran)
              </span>
              <p
                style={{
                  margin: '0 0 0.5rem',
                  fontSize: '0.8rem',
                  color: 'var(--teks-redup)',
                }}
              >
                Contoh: Dingin (+Rp 0), Panas (+Rp 0), Porsi Jumbo (+Rp 5.000).
              </p>

              {/* Daftar Varian yang ada */}
              {editMenuData.varian.length > 0 && (
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.35rem',
                    marginBottom: '0.75rem',
                  }}
                >
                  {editMenuData.varian.map((v, i) => (
                    <div
                      key={i}
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        padding: '0.35rem 0.6rem',
                        backgroundColor: 'var(--latar)',
                        borderRadius: 'var(--radius, 4px)',
                        fontSize: '0.85rem',
                      }}
                    >
                      <span>
                        <strong>{v.nama}</strong> ({v.tambahan_harga >= 0 ? '+' : ''}
                        {rupiah(v.tambahan_harga)})
                      </span>
                      <Tombol
                        ragam="bahaya"
                        onClick={() => hapusVarianDariForm(i)}
                        nama={`Hapus varian ${v.nama}`}
                      >
                        ✕
                      </Tombol>
                    </div>
                  ))}
                </div>
              )}

              {/* Input Tambah Varian */}
              <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}>
                <div style={{ flex: 2 }}>
                  <KolomIsian
                    label="Nama Varian"
                    nilai={inputNamaVarian}
                    onUbah={setInputNamaVarian}
                    contoh="Dingin / Jumbo / Pedas"
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <KolomIsian
                    label="Selisih Harga (Rp)"
                    jenis="number"
                    nilai={inputHargaVarian}
                    onUbah={setInputHargaVarian}
                    contoh="0 atau 5000"
                  />
                </div>
                <Tombol ragam="biasa" onClick={tambahVarianKeForm} nama="Tambah opsi varian">
                  + Tambah
                </Tombol>
              </div>
            </div>

            {/* Bagian Topping / Tambahan Ekstra */}
            <div
              style={{
                borderTop: '1px solid var(--border)',
                paddingTop: '0.75rem',
                marginTop: '0.25rem',
              }}
            >
              <span
                style={{
                  display: 'block',
                  fontSize: '0.9rem',
                  fontWeight: 700,
                  marginBottom: '0.35rem',
                }}
              >
                Opsi Tambahan / Topping (Bisa Pilih Banyak)
              </span>
              <p
                style={{
                  margin: '0 0 0.5rem',
                  fontSize: '0.8rem',
                  color: 'var(--teks-redup)',
                }}
              >
                Contoh: Ekstra Telur Mata Sapi (+Rp 4.000), Ekstra Keju Parut (+Rp 3.000).
              </p>

              {/* Daftar Tambahan */}
              {editMenuData.tambahan.length > 0 && (
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '0.35rem',
                    marginBottom: '0.75rem',
                  }}
                >
                  {editMenuData.tambahan.map((t, i) => (
                    <div
                      key={i}
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        padding: '0.35rem 0.6rem',
                        backgroundColor: 'var(--latar)',
                        borderRadius: 'var(--radius, 4px)',
                        fontSize: '0.85rem',
                      }}
                    >
                      <span>
                        <strong>{t.nama}</strong> (+{rupiah(t.harga)})
                      </span>
                      <Tombol
                        ragam="bahaya"
                        onClick={() => hapusTambahanDariForm(i)}
                        nama={`Hapus tambahan ${t.nama}`}
                      >
                        ✕
                      </Tombol>
                    </div>
                  ))}
                </div>
              )}

              {/* Input Tambah Topping */}
              <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}>
                <div style={{ flex: 2 }}>
                  <KolomIsian
                    label="Nama Topping"
                    nilai={inputNamaTambahan}
                    onUbah={setInputNamaTambahan}
                    contoh="Telur Dadar / Sambal Matah"
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <KolomIsian
                    label="Harga Tambahan (Rp)"
                    jenis="number"
                    nilai={inputHargaTambahan}
                    onUbah={setInputHargaTambahan}
                    contoh="4000"
                  />
                </div>
                <Tombol ragam="biasa" onClick={tambahTambahanKeForm} nama="Tambah opsi topping">
                  + Tambah
                </Tombol>
              </div>
            </div>

            {/* Tombol Simpan & Batal */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: '0.5rem',
                borderTop: '1px solid var(--border)',
                paddingTop: '0.75rem',
              }}
            >
              <Tombol
                ragam="biasa"
                onClick={() => setModalMenuBuka(false)}
                nama="Batal simpan menu"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                onClick={simpanMenu}
                nonaktif={memuat}
                nama="Simpan seluruh data menu"
              >
                {memuat ? 'Menyimpan...' : 'Simpan Menu'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Konfirmasi Hapus Menu */}
      {menuAkanDihapus && (
        <Lapis
          buka={Boolean(menuAkanDihapus)}
          judul="Konfirmasi Hapus Menu"
          onTutup={() => setMenuAkanDihapus(null)}
        >
          <div style={{ maxWidth: '420px' }}>
            <p style={{ marginTop: 0 }}>
              Apakah Anda yakin ingin menghapus menu <strong>"{menuAkanDihapus.nama}"</strong>?
            </p>
            <div
              style={{
                padding: '0.75rem',
                backgroundColor: 'var(--peringatan-latar, var(--latar))',
                borderRadius: 'var(--radius, 6px)',
                fontSize: '0.85rem',
                border: '1px solid var(--border)',
                marginBottom: '1rem',
              }}
            >
              ⚠️ <strong>Pemberitahuan Sistem:</strong> Menu yang pernah dipesan dalam transaksi
              tidak dapat dihapus secara permanen untuk melindungi audit pembukuan. Bila menu
              tersebut pernah dipesan, gunakan opsi <strong>Nonaktifkan</strong>.
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
              <Tombol
                ragam="biasa"
                onClick={() => setMenuAkanDihapus(null)}
                nama="Batal hapus menu"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="bahaya"
                onClick={eksekusiHapusMenu}
                nonaktif={memuat}
                nama="Hapus menu permanen"
              >
                {memuat ? 'Menghapus...' : 'Hapus Menu'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Konfirmasi Hapus Kategori */}
      {kategoriAkanDihapus && (
        <Lapis
          buka={Boolean(kategoriAkanDihapus)}
          judul="Konfirmasi Hapus Kategori"
          onTutup={() => setKategoriAkanDihapus(null)}
        >
          <div style={{ maxWidth: '420px' }}>
            <p style={{ marginTop: 0 }}>
              Apakah Anda yakin ingin menghapus kategori{' '}
              <strong>"{kategoriAkanDihapus.nama}"</strong>?
            </p>
            <p style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>
              Kategori yang masih memiliki item menu tidak dapat dihapus.
            </p>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.5rem' }}>
              <Tombol
                ragam="biasa"
                onClick={() => setKategoriAkanDihapus(null)}
                nama="Batal hapus kategori"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="bahaya"
                onClick={eksekusiHapusKategori}
                nonaktif={memuat}
                nama="Hapus kategori permanen"
              >
                {memuat ? 'Menghapus...' : 'Hapus Kategori'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
