/**
 * MenuCabang.tsx — Harga & Ketersediaan Menu Berbeda Per Cabang (PRD M11 / T9-06)
 *
 * Mengelola harga khusus cabang dan visibilitas/ketersediaan menu per cabang
 * tanpa memecah master katalog pusat:
 *  - Atur harga khusus cabang atau gunakan harga pusat (default).
 *  - Sembunyikan item per cabang (aktif = false).
 *  - Penanda habis manual per cabang (habis = true).
 *  - Tabel perbandingan multi-cabang (mitigasi risiko salah cabang).
 *  - Salin konfigurasi menu antar cabang.
 *  - Reset harga cabang kembali ke harga pusat.
 */

import { useState, useId, useMemo, useCallback } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { Toast } from '../../komponen/Toast'
import { rupiah } from '../../lib/format'

export interface ItemCabang {
  id: string
  nama: string
  alamat?: string
  aktif: boolean
}

export interface PengaturanMenuCabangItem {
  cabang_id: string
  cabang_nama: string
  harga_khusus: number | null // null = ikut harga pusat
  harga_efektif: number
  beda_harga: boolean
  aktif_cabang: boolean // false = disembunyikan di cabang
  habis_cabang: boolean // true = habis di cabang
}

export interface MenuItemPerbandingan {
  id: string
  kategori_id: string
  kategori_nama: string
  nama: string
  harga_pusat: number
  aktif_pusat: boolean
  foto_path?: string
  urutan?: number
  cabang: PengaturanMenuCabangItem[]
}

export interface MenuCabangProps {
  daftarCabangAwal?: ItemCabang[]
  daftarMenuAwal?: MenuItemPerbandingan[]
  cabangTerpilihAwal?: string
  onSimpanMenuCabang?: (data: {
    cabang_id: string
    menu_item_id: string
    harga: number | null
    aktif: boolean
    habis?: boolean
  }) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanBanyakMenuCabang?: (
    cabang_id: string,
    daftar: Array<{
      menu_item_id: string
      harga: number | null
      aktif: boolean
      habis?: boolean
    }>,
  ) => Promise<{ berhasil: boolean; jumlah?: number; pesan?: string }>
  onSalinHargaCabang?: (
    cabang_asal_id: string,
    cabang_tujuan_id: string,
  ) => Promise<{ berhasil: boolean; jumlah?: number; pesan?: string }>
  onResetHargaCabang?: (
    cabang_id: string,
    menu_item_id?: string,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

const CABANG_DEFAULT: ItemCabang[] = [
  { id: 'cab-1', nama: 'Cabang Pusat', alamat: 'Jl. Merdeka No. 1', aktif: true },
  { id: 'cab-2', nama: 'Cabang Dago', alamat: 'Jl. Ir. H. Juanda No. 12', aktif: true },
]

const MENU_DEFAULT: MenuItemPerbandingan[] = [
  {
    id: 'm-1',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan',
    nama: 'Nasi Goreng Spesial',
    harga_pusat: 25000,
    aktif_pusat: true,
    foto_path: '',
    urutan: 1,
    cabang: [
      {
        cabang_id: 'cab-1',
        cabang_nama: 'Cabang Pusat',
        harga_khusus: null,
        harga_efektif: 25000,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      },
      {
        cabang_id: 'cab-2',
        cabang_nama: 'Cabang Dago',
        harga_khusus: 28000,
        harga_efektif: 28000,
        beda_harga: true,
        aktif_cabang: true,
        habis_cabang: false,
      },
    ],
  },
  {
    id: 'm-2',
    kategori_id: 'kat-1',
    kategori_nama: 'Makanan',
    nama: 'Mie Goreng Seafood',
    harga_pusat: 27000,
    aktif_pusat: true,
    foto_path: '',
    urutan: 2,
    cabang: [
      {
        cabang_id: 'cab-1',
        cabang_nama: 'Cabang Pusat',
        harga_khusus: null,
        harga_efektif: 27000,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      },
      {
        cabang_id: 'cab-2',
        cabang_nama: 'Cabang Dago',
        harga_khusus: null,
        harga_efektif: 27000,
        beda_harga: false,
        aktif_cabang: false, // Disembunyikan di Cabang Dago
        habis_cabang: false,
      },
    ],
  },
  {
    id: 'm-3',
    kategori_id: 'kat-2',
    kategori_nama: 'Minuman',
    nama: 'Es Teh Manis',
    harga_pusat: 6000,
    aktif_pusat: true,
    foto_path: '',
    urutan: 1,
    cabang: [
      {
        cabang_id: 'cab-1',
        cabang_nama: 'Cabang Pusat',
        harga_khusus: null,
        harga_efektif: 6000,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      },
      {
        cabang_id: 'cab-2',
        cabang_nama: 'Cabang Dago',
        harga_khusus: 8000,
        harga_efektif: 8000,
        beda_harga: true,
        aktif_cabang: true,
        habis_cabang: true, // Habis di Cabang Dago
      },
    ],
  },
]

export function MenuCabang({
  daftarCabangAwal = CABANG_DEFAULT,
  daftarMenuAwal = MENU_DEFAULT,
  cabangTerpilihAwal,
  onSimpanMenuCabang,
  onSimpanBanyakMenuCabang,
  onSalinHargaCabang,
  onResetHargaCabang,
  onKembali,
  hanyaBaca = false,
}: MenuCabangProps) {
  const idSelectCabang = useId()
  const idSelectSalinAsal = useId()
  const idSelectSalinTujuan = useId()

  const [daftarCabang] = useState<ItemCabang[]>(daftarCabangAwal)
  const [daftarMenu, setDaftarMenu] = useState<MenuItemPerbandingan[]>(daftarMenuAwal)
  const [cabangAktifId, setCabangAktifId] = useState<string>(
    cabangTerpilihAwal || (daftarCabangAwal[0]?.id ?? ''),
  )

  const [modeTampilan, setModeTampilan] = useState<'kelola' | 'perbandingan'>('kelola')
  const [kategoriFilter, setKategoriFilter] = useState<string>('semua')
  const [kataKunciCari, setKataKunciCari] = useState<string>('')

  // State form edit cepat di memory sebelum simpan
  const [perubahanLokal, setPerubahanLokal] = useState<
    Record<
      string,
      {
        harga_khusus: number | null
        aktif_cabang: boolean
        habis_cabang: boolean
      }
    >
  >({})

  // Modal Salin Konfigurasi
  const [modalSalinBuka, setModalSalinBuka] = useState(false)
  const [cabangSalinAsal, setCabangSalinAsal] = useState<string>(cabangAktifId)
  const [cabangSalinTujuan, setCabangSalinTujuan] = useState<string>('')

  // Modal Konfirmasi Reset
  const [modalResetBuka, setModalResetBuka] = useState(false)

  // Feedback UI
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [memuat, setMemuat] = useState(false)

  const cabangTerpilih = useMemo(
    () => daftarCabang.find((c) => c.id === cabangAktifId) || daftarCabang[0],
    [daftarCabang, cabangAktifId],
  )

  // Daftar Kategori Unik
  const daftarKategori = useMemo(() => {
    const map = new Map<string, string>()
    daftarMenu.forEach((m) => {
      if (!map.has(m.kategori_id)) {
        map.set(m.kategori_id, m.kategori_nama)
      }
    })
    return Array.from(map.entries()).map(([id, nama]) => ({ id, nama }))
  }, [daftarMenu])

  // Menu yang disaring
  const menuTersaring = useMemo(() => {
    return daftarMenu.filter((menu) => {
      const cocokKategori = kategoriFilter === 'semua' || menu.kategori_id === kategoriFilter
      const cocokCari =
        kataKunciCari.trim() === '' ||
        menu.nama.toLowerCase().includes(kataKunciCari.toLowerCase()) ||
        menu.kategori_nama.toLowerCase().includes(kataKunciCari.toLowerCase())
      return cocokKategori && cocokCari
    })
  }, [daftarMenu, kategoriFilter, kataKunciCari])

  // Helper untuk membaca nilai item menu pada cabang aktif (dengan penimpaan perubahan lokal)
  const ambilStatusCabangMenu = useCallback(
    (menu: MenuItemPerbandingan) => {
      const dataAsli = menu.cabang.find((c) => c.cabang_id === cabangAktifId) || {
        cabang_id: cabangAktifId,
        cabang_nama: cabangTerpilih?.nama || '',
        harga_khusus: null,
        harga_efektif: menu.harga_pusat,
        beda_harga: false,
        aktif_cabang: true,
        habis_cabang: false,
      }

      const editLokal = perubahanLokal[menu.id]
      if (editLokal) {
        const hargaKhusus = editLokal.harga_khusus
        const hargaEfektif = hargaKhusus !== null ? hargaKhusus : menu.harga_pusat
        return {
          ...dataAsli,
          harga_khusus: hargaKhusus,
          harga_efektif: hargaEfektif,
          beda_harga: hargaKhusus !== null && hargaKhusus !== menu.harga_pusat,
          aktif_cabang: editLokal.aktif_cabang,
          habis_cabang: editLokal.habis_cabang,
        }
      }

      return dataAsli
    },
    [cabangAktifId, cabangTerpilih?.nama, perubahanLokal],
  )

  // Ringkasan Statistik Cabang Terpilih
  const statistikCabang = useMemo(() => {
    const totalMenu = daftarMenu.length
    let bedaHarga = 0
    let disembunyikan = 0
    let habis = 0

    daftarMenu.forEach((m) => {
      const st = ambilStatusCabangMenu(m)
      if (st.beda_harga) bedaHarga++
      if (!st.aktif_cabang) disembunyikan++
      if (st.habis_cabang) habis++
    })

    return { totalMenu, bedaHarga, disembunyikan, habis }
  }, [daftarMenu, ambilStatusCabangMenu])

  // Handlers Perubahan Lokal
  const ubahHargaKhusus = (menuId: string, hargaBaru: number | null) => {
    const menu = daftarMenu.find((m) => m.id === menuId)
    if (!menu) return
    const stSekarang = ambilStatusCabangMenu(menu)
    setPerubahanLokal((lama) => ({
      ...lama,
      [menuId]: {
        harga_khusus: hargaBaru,
        aktif_cabang: stSekarang.aktif_cabang,
        habis_cabang: stSekarang.habis_cabang,
      },
    }))
  }

  const ubahAktifCabang = (menuId: string, aktif: boolean) => {
    const menu = daftarMenu.find((m) => m.id === menuId)
    if (!menu) return
    const stSekarang = ambilStatusCabangMenu(menu)
    setPerubahanLokal((lama) => ({
      ...lama,
      [menuId]: {
        harga_khusus: stSekarang.harga_khusus,
        aktif_cabang: aktif,
        habis_cabang: stSekarang.habis_cabang,
      },
    }))
  }

  const ubahHabisCabang = (menuId: string, habis: boolean) => {
    const menu = daftarMenu.find((m) => m.id === menuId)
    if (!menu) return
    const stSekarang = ambilStatusCabangMenu(menu)
    setPerubahanLokal((lama) => ({
      ...lama,
      [menuId]: {
        harga_khusus: stSekarang.harga_khusus,
        aktif_cabang: stSekarang.aktif_cabang,
        habis_cabang: habis,
      },
    }))
  }

  // Simpan Satu Menu Langsung
  const simpanSatuMenu = async (menuId: string) => {
    if (hanyaBaca) return
    const menu = daftarMenu.find((m) => m.id === menuId)
    if (!menu) return
    const st = ambilStatusCabangMenu(menu)

    setMemuat(true)
    try {
      if (onSimpanMenuCabang) {
        await onSimpanMenuCabang({
          cabang_id: cabangAktifId,
          menu_item_id: menuId,
          harga: st.harga_khusus,
          aktif: st.aktif_cabang,
          habis: st.habis_cabang,
        })
      }

      // Perbarui state master
      setDaftarMenu((lama) =>
        lama.map((m) => {
          if (m.id !== menuId) return m
          const cabangLain = m.cabang.filter((c) => c.cabang_id !== cabangAktifId)
          return {
            ...m,
            cabang: [
              ...cabangLain,
              {
                cabang_id: cabangAktifId,
                cabang_nama: cabangTerpilih?.nama || '',
                harga_khusus: st.harga_khusus,
                harga_efektif: st.harga_efektif,
                beda_harga: st.beda_harga,
                aktif_cabang: st.aktif_cabang,
                habis_cabang: st.habis_cabang,
              },
            ],
          }
        }),
      )

      // Bersihkan perubahan lokal item ini
      setPerubahanLokal((lama) => {
        const salin = { ...lama }
        delete salin[menuId]
        return salin
      })

      setPesanSukses(
        `Pengaturan menu "${menu.nama}" untuk ${cabangTerpilih?.nama} berhasil disimpan.`,
      )
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Gagal menyimpan pengaturan menu cabang.')
    } finally {
      setMemuat(false)
    }
  }

  // Simpan Seluruh Perubahan di Cabang Ini
  const simpanSemuaPerubahanCabang = async () => {
    if (hanyaBaca) return
    const keys = Object.keys(perubahanLokal)
    if (keys.length === 0) {
      setPesanSukses('Tidak ada perubahan yang perlu disimpan.')
      return
    }

    setMemuat(true)
    try {
      const payload = keys.map((menuId) => {
        const item = perubahanLokal[menuId]
        return {
          menu_item_id: menuId,
          harga: item.harga_khusus,
          aktif: item.aktif_cabang,
          habis: item.habis_cabang,
        }
      })

      if (onSimpanBanyakMenuCabang) {
        await onSimpanBanyakMenuCabang(cabangAktifId, payload)
      }

      // Perbarui master state
      setDaftarMenu((lama) =>
        lama.map((m) => {
          const edit = perubahanLokal[m.id]
          if (!edit) return m
          const cabangLain = m.cabang.filter((c) => c.cabang_id !== cabangAktifId)
          const hargaEfektif = edit.harga_khusus !== null ? edit.harga_khusus : m.harga_pusat
          return {
            ...m,
            cabang: [
              ...cabangLain,
              {
                cabang_id: cabangAktifId,
                cabang_nama: cabangTerpilih?.nama || '',
                harga_khusus: edit.harga_khusus,
                harga_efektif: hargaEfektif,
                beda_harga: edit.harga_khusus !== null && edit.harga_khusus !== m.harga_pusat,
                aktif_cabang: edit.aktif_cabang,
                habis_cabang: edit.habis_cabang,
              },
            ],
          }
        }),
      )

      setPerubahanLokal({})
      setPesanSukses(
        `Berhasil menyimpan ${keys.length} perubahan menu untuk ${cabangTerpilih?.nama}.`,
      )
    } catch (err: unknown) {
      setPesanGalat(
        err instanceof Error ? err.message : 'Gagal menyimpan seluruh perubahan menu cabang.',
      )
    } finally {
      setMemuat(false)
    }
  }

  // Salin Konfigurasi Antar Cabang
  const eksekusiSalinCabang = async () => {
    if (hanyaBaca || !cabangSalinAsal || !cabangSalinTujuan) return
    if (cabangSalinAsal === cabangSalinTujuan) {
      setPesanGalat('Cabang asal dan cabang tujuan tidak boleh sama.')
      return
    }

    setMemuat(true)
    try {
      if (onSalinHargaCabang) {
        await onSalinHargaCabang(cabangSalinAsal, cabangSalinTujuan)
      }

      const namaAsal = daftarCabang.find((c) => c.id === cabangSalinAsal)?.nama || 'Cabang Asal'
      const namaTujuan =
        daftarCabang.find((c) => c.id === cabangSalinTujuan)?.nama || 'Cabang Tujuan'

      // Salin konfigurasi di state lokal
      setDaftarMenu((lama) =>
        lama.map((m) => {
          const cfgAsal = m.cabang.find((c) => c.cabang_id === cabangSalinAsal)
          if (!cfgAsal) return m
          const cabangLain = m.cabang.filter((c) => c.cabang_id !== cabangSalinTujuan)
          return {
            ...m,
            cabang: [
              ...cabangLain,
              {
                ...cfgAsal,
                cabang_id: cabangSalinTujuan,
                cabang_nama: namaTujuan,
              },
            ],
          }
        }),
      )

      setModalSalinBuka(false)
      setPesanSukses(`Konfigurasi menu dari ${namaAsal} berhasil disalin ke ${namaTujuan}.`)
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Gagal menyalin konfigurasi cabang.')
    } finally {
      setMemuat(false)
    }
  }

  // Reset Seluruh Menu Cabang ke Pusat
  const eksekusiResetCabang = async () => {
    if (hanyaBaca) return
    setMemuat(true)
    try {
      if (onResetHargaCabang) {
        await onResetHargaCabang(cabangAktifId)
      }

      setDaftarMenu((lama) =>
        lama.map((m) => {
          const cabangLain = m.cabang.filter((c) => c.cabang_id !== cabangAktifId)
          const dataLama = m.cabang.find((c) => c.cabang_id === cabangAktifId)
          return {
            ...m,
            cabang: [
              ...cabangLain,
              {
                cabang_id: cabangAktifId,
                cabang_nama: cabangTerpilih?.nama || '',
                harga_khusus: null,
                harga_efektif: m.harga_pusat,
                beda_harga: false,
                aktif_cabang: dataLama?.aktif_cabang ?? true,
                habis_cabang: dataLama?.habis_cabang ?? false,
              },
            ],
          }
        }),
      )

      // Hapus perubahan lokal harga di cabang ini
      setPerubahanLokal({})
      setModalResetBuka(false)
      setPesanSukses(
        `Seluruh harga menu di ${cabangTerpilih?.nama} berhasil dikembalikan ke harga pusat.`,
      )
    } catch (err: unknown) {
      setPesanGalat(err instanceof Error ? err.message : 'Gagal mengembalikan harga cabang.')
    } finally {
      setMemuat(false)
    }
  }

  const adaPerubahanBelumDisimpan = Object.keys(perubahanLokal).length > 0

  return (
    <div className="pengaturan-menu-cabang" data-testid="pengaturan-menu-cabang">
      {/* Notifikasi Toast */}
      {pesanSukses && <Toast pesan={pesanSukses} nada="sukses" />}
      {pesanGalat && <Toast pesan={pesanGalat} nada="gagal" />}

      {/* Header Halaman */}
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
            Harga & Ketersediaan Menu Per Cabang
          </h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--teks-redup)', fontSize: '0.9rem' }}>
            Atur harga khusus cabang atau sembunyikan item per cabang tanpa memecah master katalog
            pusat (PRD M11).
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu identitas">
              ← Kembali
            </Tombol>
          )}
          {!hanyaBaca && (
            <>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setCabangSalinAsal(cabangAktifId)
                  setCabangSalinTujuan(daftarCabang.find((c) => c.id !== cabangAktifId)?.id || '')
                  setModalSalinBuka(true)
                }}
                nama="Buka modal salin konfigurasi antar cabang"
              >
                📋 Salin Antar Cabang
              </Tombol>
              <Tombol
                ragam="biasa"
                onClick={() => setModalResetBuka(true)}
                nama="Reset seluruh harga cabang ke harga pusat"
              >
                ↺ Reset ke Harga Pusat
              </Tombol>
              {adaPerubahanBelumDisimpan && (
                <Tombol
                  ragam="utama"
                  onClick={simpanSemuaPerubahanCabang}
                  nonaktif={memuat}
                  nama="Simpan seluruh perubahan menu cabang"
                >
                  {memuat
                    ? 'Menyimpan...'
                    : `Simpan Semua Perubahan (${Object.keys(perubahanLokal).length})`}
                </Tombol>
              )}
            </>
          )}
        </div>
      </div>

      {/* Bilah Pilihan Mode Tampilan & Pemilih Cabang */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '1rem',
          backgroundColor: 'var(--latar-kartu)',
          padding: '0.75rem 1rem',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius, 8px)',
          marginBottom: '1.25rem',
        }}
      >
        {/* Pemilih Cabang */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <label htmlFor={idSelectCabang} style={{ fontWeight: 600, fontSize: '0.9rem' }}>
            Pilih Cabang:
          </label>
          <select
            id={idSelectCabang}
            className="input"
            value={cabangAktifId}
            onChange={(e) => {
              setCabangAktifId(e.target.value)
              setPerubahanLokal({})
            }}
            style={{ minWidth: '180px' }}
          >
            {daftarCabang.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nama} {!c.aktif ? '(Nonaktif)' : ''}
              </option>
            ))}
          </select>
        </div>

        {/* Sakelar Mode Tampilan */}
        <div style={{ display: 'flex', gap: '0.35rem' }}>
          <Tombol
            ragam={modeTampilan === 'kelola' ? 'utama' : 'biasa'}
            onClick={() => setModeTampilan('kelola')}
            nama="Buka mode kelola cabang terpilih"
          >
            ⚙️ Kelola Cabang
          </Tombol>
          <Tombol
            ragam={modeTampilan === 'perbandingan' ? 'utama' : 'biasa'}
            onClick={() => setModeTampilan('perbandingan')}
            nama="Buka mode tabel perbandingan multi-cabang"
          >
            📊 Tabel Perbandingan Multi-Cabang
          </Tombol>
        </div>
      </div>

      {/* Kartu Ringkasan Statistik Cabang Terpilih */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: '0.75rem',
          marginBottom: '1.25rem',
        }}
      >
        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>Total Menu Resto</div>
          <div style={{ fontSize: '1.75rem', fontWeight: 700, marginTop: '0.25rem' }}>
            {statistikCabang.totalMenu}
          </div>
        </Kartu>

        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>
            Harga Khusus di {cabangTerpilih?.nama}
          </div>
          <div
            style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              marginTop: '0.25rem',
              color: 'var(--aksen, #0284c7)',
            }}
          >
            {statistikCabang.bedaHarga}
          </div>
        </Kartu>

        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>
            Disembunyikan di {cabangTerpilih?.nama}
          </div>
          <div
            style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              marginTop: '0.25rem',
              color: 'var(--peringatan, #f59e0b)',
            }}
          >
            {statistikCabang.disembunyikan}
          </div>
        </Kartu>

        <Kartu>
          <div style={{ fontSize: '0.85rem', color: 'var(--teks-redup)' }}>
            Habis di {cabangTerpilih?.nama}
          </div>
          <div
            style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              marginTop: '0.25rem',
              color: 'var(--bahaya, #ef4444)',
            }}
          >
            {statistikCabang.habis}
          </div>
        </Kartu>
      </div>

      {/* FILTER & PENCARIAN (untuk Mode Kelola) */}
      <div
        style={{
          display: 'flex',
          gap: '0.75rem',
          flexWrap: 'wrap',
          marginBottom: '1rem',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        {/* Tab Filter Kategori */}
        <div
          style={{ display: 'flex', gap: '0.35rem', overflowX: 'auto', paddingBottom: '0.25rem' }}
        >
          <Tombol
            ragam={kategoriFilter === 'semua' ? 'utama' : 'biasa'}
            onClick={() => setKategoriFilter('semua')}
            nama="Tampilkan semua kategori"
          >
            Semua ({daftarMenu.length})
          </Tombol>
          {daftarKategori.map((kat) => {
            const jml = daftarMenu.filter((m) => m.kategori_id === kat.id).length
            return (
              <Tombol
                key={kat.id}
                ragam={kategoriFilter === kat.id ? 'utama' : 'biasa'}
                onClick={() => setKategoriFilter(kat.id)}
                nama={`Filter kategori ${kat.nama}`}
              >
                {kat.nama} ({jml})
              </Tombol>
            )
          })}
        </div>

        {/* Kotak Pencarian */}
        <div style={{ minWidth: '220px' }}>
          <KolomIsian
            label="Cari Menu"
            nilai={kataKunciCari}
            onUbah={setKataKunciCari}
            contoh="Cari nama menu..."
          />
        </div>
      </div>

      {/* KONTEN UTAMA: MODE KELOLA CABANG */}
      {modeTampilan === 'kelola' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {menuTersaring.length === 0 ? (
            <div
              style={{
                padding: '2.5rem',
                textAlign: 'center',
                backgroundColor: 'var(--latar-kartu)',
                border: '1px dashed var(--border)',
                borderRadius: 'var(--radius, 8px)',
                color: 'var(--teks-redup)',
              }}
            >
              Tidak ada menu yang sesuai dengan filter atau pencarian.
            </div>
          ) : (
            menuTersaring.map((menu) => {
              const st = ambilStatusCabangMenu(menu)
              const adaEdit = Boolean(perubahanLokal[menu.id])
              const selisih = st.harga_khusus !== null ? st.harga_khusus - menu.harga_pusat : 0

              return (
                <div
                  key={menu.id}
                  style={{
                    backgroundColor: 'var(--latar-kartu)',
                    border: adaEdit ? '1px solid var(--aksen, #0284c7)' : '1px solid var(--border)',
                    borderRadius: 'var(--radius, 8px)',
                    padding: '1rem',
                    display: 'flex',
                    flexWrap: 'wrap',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    gap: '1rem',
                    opacity: !st.aktif_cabang ? 0.65 : 1,
                  }}
                >
                  {/* Kolom Informasi Menu */}
                  <div style={{ flex: '1 1 240px', minWidth: '220px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <span style={{ fontWeight: 700, fontSize: '1.05rem' }}>{menu.nama}</span>
                      <Lencana nada="netral">{menu.kategori_nama}</Lencana>
                      {st.beda_harga && <Lencana nada="accent">Harga Khusus</Lencana>}
                      {!st.aktif_cabang && <Lencana nada="warn">Sembunyi di Cabang</Lencana>}
                      {st.habis_cabang && <Lencana nada="danger">Habis</Lencana>}
                    </div>

                    <div
                      style={{
                        fontSize: '0.85rem',
                        color: 'var(--teks-redup)',
                        marginTop: '0.25rem',
                      }}
                    >
                      Harga Pusat: <strong>{rupiah(menu.harga_pusat)}</strong>
                    </div>
                  </div>

                  {/* Kolom Konfigurasi Harga Cabang */}
                  <div
                    style={{
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.35rem',
                      minWidth: '220px',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <label style={{ fontSize: '0.85rem', fontWeight: 600 }}>Harga Cabang:</label>
                      <Tombol
                        ragam={st.harga_khusus === null ? 'utama' : 'biasa'}
                        onClick={() => ubahHargaKhusus(menu.id, null)}
                        nonaktif={hanyaBaca}
                        nama={`Gunakan harga pusat untuk ${menu.nama}`}
                      >
                        Ikut Pusat
                      </Tombol>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <input
                        type="number"
                        className="input"
                        aria-label={`Harga khusus cabang untuk ${menu.nama}`}
                        value={st.harga_khusus !== null ? st.harga_khusus : ''}
                        placeholder={`Pusat: ${menu.harga_pusat}`}
                        disabled={hanyaBaca}
                        onChange={(e) => {
                          const val = e.target.value.trim()
                          if (val === '') {
                            ubahHargaKhusus(menu.id, null)
                          } else {
                            const n = parseInt(val, 10)
                            ubahHargaKhusus(menu.id, isNaN(n) ? null : n)
                          }
                        }}
                        style={{ width: '130px' }}
                      />

                      {/* Label Selisih Harga */}
                      {st.harga_khusus !== null && (
                        <span
                          style={{
                            fontSize: '0.8rem',
                            fontWeight: 600,
                            color:
                              selisih > 0
                                ? 'var(--sukses, #16a34a)'
                                : selisih < 0
                                  ? 'var(--bahaya, #ef4444)'
                                  : 'var(--teks-redup)',
                          }}
                        >
                          {selisih > 0
                            ? `+${rupiah(selisih)}`
                            : selisih < 0
                              ? `-${rupiah(Math.abs(selisih))}`
                              : 'Sama'}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Kolom Sakelar Ketersediaan di Cabang */}
                  <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
                    <Tombol
                      ragam={st.aktif_cabang ? 'biasa' : 'bahaya'}
                      onClick={() => ubahAktifCabang(menu.id, !st.aktif_cabang)}
                      nonaktif={hanyaBaca}
                      nama={`Ubah status tampil menu ${menu.nama} di cabang`}
                    >
                      {st.aktif_cabang ? '👁️ Tampil' : '🚫 Sembunyi'}
                    </Tombol>

                    <Tombol
                      ragam={st.habis_cabang ? 'bahaya' : 'biasa'}
                      onClick={() => ubahHabisCabang(menu.id, !st.habis_cabang)}
                      nonaktif={hanyaBaca}
                      nama={`Tandai status habis menu ${menu.nama} di cabang`}
                    >
                      {st.habis_cabang ? '❌ Habis' : '✅ Ada'}
                    </Tombol>

                    {adaEdit && !hanyaBaca && (
                      <Tombol
                        ragam="utama"
                        onClick={() => simpanSatuMenu(menu.id)}
                        nonaktif={memuat}
                        nama={`Simpan pengaturan cabang untuk ${menu.nama}`}
                      >
                        {memuat ? 'Menyimpan...' : 'Simpan'}
                      </Tombol>
                    )}
                  </div>
                </div>
              )
            })
          )}
        </div>
      )}

      {/* KONTEN UTAMA: MODE TABEL PERBANDINGAN MULTI-CABANG */}
      {modeTampilan === 'perbandingan' && (
        <div
          style={{
            backgroundColor: 'var(--latar-kartu)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius, 8px)',
            overflowX: 'auto',
          }}
        >
          <table
            style={{
              width: '100%',
              borderCollapse: 'collapse',
              fontSize: '0.9rem',
              textAlign: 'left',
            }}
          >
            <thead>
              <tr
                style={{ borderBottom: '2px solid var(--border)', backgroundColor: 'var(--latar)' }}
              >
                <th style={{ padding: '0.75rem 1rem' }}>Menu</th>
                <th style={{ padding: '0.75rem 1rem' }}>Kategori</th>
                <th style={{ padding: '0.75rem 1rem' }}>Harga Pusat</th>
                {daftarCabang.map((cabang) => (
                  <th key={cabang.id} style={{ padding: '0.75rem 1rem' }}>
                    {cabang.nama}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {menuTersaring.map((menu, idx) => (
                <tr
                  key={menu.id}
                  style={{
                    borderBottom: '1px solid var(--border)',
                    backgroundColor:
                      idx % 2 === 0 ? 'transparent' : 'var(--latar-redup, var(--latar))',
                  }}
                >
                  <td style={{ padding: '0.75rem 1rem', fontWeight: 600 }}>{menu.nama}</td>
                  <td style={{ padding: '0.75rem 1rem', color: 'var(--teks-redup)' }}>
                    {menu.kategori_nama}
                  </td>
                  <td style={{ padding: '0.75rem 1rem', fontWeight: 700 }}>
                    {rupiah(menu.harga_pusat)}
                  </td>
                  {daftarCabang.map((cabang) => {
                    const st = menu.cabang.find((c) => c.cabang_id === cabang.id) || {
                      cabang_id: cabang.id,
                      cabang_nama: cabang.nama,
                      harga_khusus: null,
                      harga_efektif: menu.harga_pusat,
                      beda_harga: false,
                      aktif_cabang: true,
                      habis_cabang: false,
                    }

                    return (
                      <td key={cabang.id} style={{ padding: '0.75rem 1rem' }}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
                          <span
                            style={{
                              fontWeight: st.beda_harga ? 700 : 500,
                              color: st.beda_harga ? 'var(--aksen, #0284c7)' : 'var(--teks)',
                            }}
                          >
                            {rupiah(st.harga_efektif)} {st.beda_harga ? '(Khusus)' : '(Pusat)'}
                          </span>
                          <div style={{ display: 'flex', gap: '0.25rem', flexWrap: 'wrap' }}>
                            {!st.aktif_cabang && <Lencana nada="warn">Sembunyi</Lencana>}
                            {st.habis_cabang && <Lencana nada="danger">Habis</Lencana>}
                          </div>
                        </div>
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* MODAL SALIN KONFIGURASI ANTAR CABANG */}
      {modalSalinBuka && (
        <Lapis
          buka={modalSalinBuka}
          judul="Salin Pengaturan Menu Antar Cabang"
          onTutup={() => setModalSalinBuka(false)}
        >
          <div style={{ maxWidth: '420px', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <p style={{ margin: 0, fontSize: '0.9rem', color: 'var(--teks-redup)' }}>
              Seluruh harga khusus cabang, visibilitas (sembunyi), dan penanda habis pada cabang
              asal akan disalin ke cabang tujuan.
            </p>

            <div>
              <label
                htmlFor={idSelectSalinAsal}
                style={{
                  display: 'block',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  marginBottom: '0.35rem',
                }}
              >
                Cabang Asal:
              </label>
              <select
                id={idSelectSalinAsal}
                className="input"
                value={cabangSalinAsal}
                onChange={(e) => setCabangSalinAsal(e.target.value)}
                style={{ width: '100%' }}
              >
                {daftarCabang.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nama}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label
                htmlFor={idSelectSalinTujuan}
                style={{
                  display: 'block',
                  fontSize: '0.85rem',
                  fontWeight: 600,
                  marginBottom: '0.35rem',
                }}
              >
                Cabang Tujuan:
              </label>
              <select
                id={idSelectSalinTujuan}
                className="input"
                value={cabangSalinTujuan}
                onChange={(e) => setCabangSalinTujuan(e.target.value)}
                style={{ width: '100%' }}
              >
                {daftarCabang
                  .filter((c) => c.id !== cabangSalinAsal)
                  .map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.nama}
                    </option>
                  ))}
              </select>
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
                onClick={() => setModalSalinBuka(false)}
                nama="Batal salin konfigurasi cabang"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                onClick={eksekusiSalinCabang}
                nonaktif={memuat || cabangSalinAsal === cabangSalinTujuan}
                nama="Konfirmasi salin konfigurasi cabang"
              >
                {memuat ? 'Menyalin...' : 'Salin Konfigurasi'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* MODAL RESET HARGA CABANG KE PUSAT */}
      {modalResetBuka && (
        <Lapis
          buka={modalResetBuka}
          judul="Reset Harga ke Harga Pusat"
          onTutup={() => setModalResetBuka(false)}
        >
          <div style={{ maxWidth: '420px', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <p style={{ margin: 0, fontSize: '0.9rem' }}>
              Apakah Anda yakin ingin mengembalikan seluruh harga menu di{' '}
              <strong>"{cabangTerpilih?.nama}"</strong> kembali mengikuti harga pusat?
            </p>
            <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--teks-redup)' }}>
              Harga khusus cabang yang pernah diatur akan dihapus sehingga seluruh transaksi di
              cabang ini akan menggunakan harga master resto.
            </p>

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
                onClick={() => setModalResetBuka(false)}
                nama="Batal reset harga cabang"
              >
                Batal
              </Tombol>
              <Tombol
                ragam="bahaya"
                onClick={eksekusiResetCabang}
                nonaktif={memuat}
                nama="Konfirmasi reset harga cabang"
              >
                {memuat ? 'Mereset...' : 'Reset ke Harga Pusat'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
