/**
 * LayarPengaturan.tsx — Induk Pengaturan Restoran (PRD M2 / Fase 9)
 *
 * Menggabungkan seluruh modul pengaturan restoran:
 *  1. Identitas Resto (`Identitas`) — T9-01 / PRD M2
 *  2. Tema & Warna Merek (`Tampilan`) — T9-02 / PRD M2
 *  3. Pengaturan Operasional (`Operasional`) — T9-03 / PRD M2 & M6
 *  4. Pengelolaan Perangkat POS (`DaftarPerangkat`) — T6-04
 *  5. Sambungan & Pengaturan Printer (`PasangPrinter`) — T6-08
 *  6. Tautan Publik & QR Meja (`TautanKatalog`) — T8-03
 *  7. Kampanye Voucher Pelanggan (`Kampanye`) — T8-08
 */

import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Identitas, type DataIdentitas } from './Identitas'
import { Tampilan, type DataTema } from './Tampilan'
import { Operasional, type DataOperasional } from './Operasional'
import { Meja, type ItemMeja } from './Meja'
import { Menu, type DataKategori, type DataMenuItem } from './Menu'
import { MenuCabang, type ItemCabang, type MenuItemPerbandingan } from './MenuCabang'
import { MetodeBayar, type ItemMetodeBayar, type DataAturanTip } from './MetodeBayar'
import { KelolaPegawai, type PegawaiResto } from './KelolaPegawai'
import type { PeranPengguna } from '../../lib/auth'
import { Cabang, type DataCabang, type PrinterCabang } from './Cabang'
import { DaftarPerangkat } from './DaftarPerangkat'
import { PasangPrinter } from './PasangPrinter'
import { TautanKatalog } from './TautanKatalog'
import { Kampanye } from './Kampanye'
import { Pratinjau } from './Pratinjau'

export type TabPengaturan =
  | 'identitas'
  | 'tampilan'
  | 'operasional'
  | 'meja'
  | 'menu'
  | 'menu_cabang'
  | 'metode_bayar'
  | 'pegawai'
  | 'cabang'
  | 'perangkat'
  | 'printer'
  | 'tautan'
  | 'kampanye'
  | 'pratinjau'

export interface LayarPengaturanProps {
  tabAwal?: TabPengaturan
  dataIdentitas?: Partial<DataIdentitas>
  onSimpanIdentitas?: (data: DataIdentitas) => Promise<{ berhasil: boolean; pesan?: string }>
  dataTema?: Partial<DataTema>
  onSimpanTema?: (data: DataTema) => Promise<{ berhasil: boolean; pesan?: string }>
  dataOperasional?: Partial<DataOperasional>
  onSimpanOperasional?: (data: DataOperasional) => Promise<{ berhasil: boolean; pesan?: string }>
  daftarMejaAwal?: ItemMeja[]
  daftarAreaAwal?: string[]
  onSimpanMeja?: (data: {
    id?: string
    cabang_id: string
    nama: string
    area: string
    aktif: boolean
  }) => Promise<{ berhasil: boolean; meja?: ItemMeja; pesan?: string }>
  onHapusMeja?: (mejaId: string) => Promise<{ berhasil: boolean; pesan?: string }>
  daftarKategoriAwal?: DataKategori[]
  daftarMenuAwal?: DataMenuItem[]
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
  }) => Promise<{ berhasil: boolean; id?: string; pesan?: string }>
  onHapusMenu?: (id: string) => Promise<{ berhasil: boolean; pesan?: string }>
  daftarCabangAwal?: ItemCabang[]
  daftarMenuCabangAwal?: MenuItemPerbandingan[]
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
  daftarMetodeBayarAwal?: ItemMetodeBayar[]
  aturanTipAwal?: Partial<DataAturanTip>
  onSimpanMetodeBayar?: (data: {
    id?: string
    nama: string
    jenis: 'tunai' | 'non_tunai'
    butuh_referensi: boolean
    aktif: boolean
    urutan?: number
  }) => Promise<{ berhasil: boolean; pesan?: string }>
  onHapusMetodeBayar?: (id: string) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanUrutanMetodeBayar?: (
    daftar: Array<{ id: string; urutan: number }>,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanAturanTip?: (data: DataAturanTip) => Promise<{ berhasil: boolean; pesan?: string }>
  daftarPegawaiAwal?: PegawaiResto[]
  onTambahPegawai?: (data: {
    nama: string
    email: string
    peran: PeranPengguna
    cabangId: string
    pinAwal: string
  }) => Promise<{ sukses: boolean; pegawaiId?: string; pesan?: string }>
  onUbahPegawai?: (data: {
    id: string
    nama: string
    email: string
    peran: PeranPengguna
    cabangId: string
  }) => Promise<{ sukses: boolean; pesan?: string }>
  onUbahStatusPegawai?: (
    pegawaiId: string,
    aktif: boolean,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onAturUlangPin?: (
    pegawaiId: string,
    pinBaru: string,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onSimpanIzin?: (data: {
    pegawaiId: string
    kodeIzin: string
    boleh: boolean
    batasNominal?: number | null
    batasPersen?: number | null
  }) => Promise<{ sukses: boolean; pesan?: string }>
  daftarKelolaCabangAwal?: DataCabang[]
  onTambahKelolaCabang?: (data: {
    nama: string
    alamat?: string
    telepon?: string
    zonaWaktu: string
    printer?: PrinterCabang
  }) => Promise<{ sukses: boolean; cabangId?: string; pesan?: string }>
  onSimpanKelolaCabang?: (data: {
    id: string
    nama: string
    alamat?: string
    telepon?: string
    zonaWaktu: string
    printer?: PrinterCabang
  }) => Promise<{ sukses: boolean; pesan?: string }>
  onUbahStatusKelolaCabang?: (
    cabangId: string,
    aktif: boolean,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onAturAksesKelolaCabang?: (data: {
    penggunaId: string
    cabangId: string
    aktif: boolean
  }) => Promise<{ sukses: boolean; pesan?: string }>
  dataIdentitasDraf?: Partial<DataIdentitas>
  dataTemaDraf?: Partial<DataTema>
  dataOperasionalDraf?: Partial<DataOperasional>
  onSimpanSemuaPengaturan?: () => Promise<{ berhasil: boolean; pesan?: string }>
  onResetDrafPengaturan?: () => void
  onCetakSimulasiStruk?: () => void
  hanyaBaca?: boolean
}

export function LayarPengaturan({
  tabAwal = 'identitas',
  dataIdentitas,
  onSimpanIdentitas,
  dataTema,
  onSimpanTema,
  dataOperasional,
  onSimpanOperasional,
  daftarMejaAwal,
  daftarAreaAwal,
  onSimpanMeja,
  onHapusMeja,
  daftarKategoriAwal,
  daftarMenuAwal,
  onSimpanKategori,
  onHapusKategori,
  onSimpanMenu,
  onHapusMenu,
  daftarCabangAwal,
  daftarMenuCabangAwal,
  onSimpanMenuCabang,
  onSimpanBanyakMenuCabang,
  onSalinHargaCabang,
  onResetHargaCabang,
  daftarMetodeBayarAwal,
  aturanTipAwal,
  onSimpanMetodeBayar,
  onHapusMetodeBayar,
  onSimpanUrutanMetodeBayar,
  onSimpanAturanTip,
  daftarPegawaiAwal,
  onTambahPegawai,
  onUbahPegawai,
  onUbahStatusPegawai,
  onAturUlangPin,
  onSimpanIzin,
  daftarKelolaCabangAwal,
  onTambahKelolaCabang,
  onSimpanKelolaCabang,
  onUbahStatusKelolaCabang,
  onAturAksesKelolaCabang,
  dataIdentitasDraf,
  dataTemaDraf,
  dataOperasionalDraf,
  onSimpanSemuaPengaturan,
  onResetDrafPengaturan,
  onCetakSimulasiStruk,
  hanyaBaca = false,
}: LayarPengaturanProps) {
  const [tabAktif, setTabAktif] = useState<TabPengaturan>(tabAwal)

  const DAFTAR_TAB: Array<{ id: TabPengaturan; label: string; ikon: string }> = [
    { id: 'identitas', label: 'Identitas Resto', ikon: '🏪' },
    { id: 'tampilan', label: 'Tema & Tampilan', ikon: '🎨' },
    { id: 'operasional', label: 'Operasional & Kasir', ikon: '⚙️' },
    { id: 'meja', label: 'Meja & Area', ikon: '🪑' },
    { id: 'menu', label: 'Kelola Menu', ikon: '🍲' },
    { id: 'menu_cabang', label: 'Menu Per Cabang', ikon: '📋' },
    { id: 'metode_bayar', label: 'Metode Bayar & Tip', ikon: '💳' },
    { id: 'pegawai', label: 'Kelola Pegawai', ikon: '👥' },
    { id: 'cabang', label: 'Kelola Cabang', ikon: '🏢' },
    { id: 'perangkat', label: 'Perangkat POS', ikon: '📱' },
    { id: 'printer', label: 'Printer Struk', ikon: '🖨️' },
    { id: 'tautan', label: 'Tautan & QR Meja', ikon: '🔗' },
    { id: 'kampanye', label: 'Kampanye Voucher', ikon: '🎟️' },
    { id: 'pratinjau', label: 'Pratinjau & Pengaman', ikon: '👁️' },
  ]

  return (
    <div className="layar-pengaturan" data-testid="layar-pengaturan">
      {/* Bilah Tab Navigasi Pengaturan */}
      <div
        role="tablist"
        aria-label="Navigasi Pengaturan Restoran"
        style={{
          display: 'flex',
          gap: '0.5rem',
          flexWrap: 'wrap',
          marginBottom: '1.25rem',
          paddingBottom: '0.75rem',
          borderBottom: '1px solid var(--border)',
        }}
      >
        {DAFTAR_TAB.map((tab) => {
          const aktif = tabAktif === tab.id
          return (
            <Tombol
              key={tab.id}
              ragam={aktif ? 'utama' : 'biasa'}
              onClick={() => setTabAktif(tab.id)}
              nama={`Buka tab pengaturan ${tab.label}`}
            >
              <span>{tab.ikon}</span>
              <span style={{ marginLeft: '0.35rem' }}>{tab.label}</span>
            </Tombol>
          )
        })}
      </div>

      {/* Konten Tab Aktif */}
      <div className="konten-pengaturan">
        {tabAktif === 'identitas' && (
          <Identitas dataAwal={dataIdentitas} onSimpan={onSimpanIdentitas} hanyaBaca={hanyaBaca} />
        )}
        {tabAktif === 'tampilan' && (
          <Tampilan
            dataAwal={dataTema}
            onSimpan={onSimpanTema}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'operasional' && (
          <Operasional
            dataAwal={dataOperasional}
            onSimpan={onSimpanOperasional}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'meja' && (
          <Meja
            daftarMejaAwal={daftarMejaAwal}
            daftarAreaAwal={daftarAreaAwal}
            onSimpanMeja={onSimpanMeja}
            onHapusMeja={onHapusMeja}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'menu' && (
          <Menu
            daftarKategoriAwal={daftarKategoriAwal}
            daftarMenuAwal={daftarMenuAwal}
            onSimpanKategori={onSimpanKategori}
            onHapusKategori={onHapusKategori}
            onSimpanMenu={onSimpanMenu}
            onHapusMenu={onHapusMenu}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'menu_cabang' && (
          <MenuCabang
            daftarCabangAwal={daftarCabangAwal}
            daftarMenuAwal={daftarMenuCabangAwal}
            onSimpanMenuCabang={onSimpanMenuCabang}
            onSimpanBanyakMenuCabang={onSimpanBanyakMenuCabang}
            onSalinHargaCabang={onSalinHargaCabang}
            onResetHargaCabang={onResetHargaCabang}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'metode_bayar' && (
          <MetodeBayar
            daftarMetodeAwal={daftarMetodeBayarAwal}
            aturanTipAwal={aturanTipAwal}
            onSimpanMetode={onSimpanMetodeBayar}
            onHapusMetode={onHapusMetodeBayar}
            onSimpanUrutanMetode={onSimpanUrutanMetodeBayar}
            onSimpanAturanTip={onSimpanAturanTip}
            onKembali={() => setTabAktif('identitas')}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'pegawai' && (
          <KelolaPegawai
            daftarPegawai={daftarPegawaiAwal}
            onTambahPegawai={onTambahPegawai}
            onUbahPegawai={onUbahPegawai}
            onUbahStatusPegawai={onUbahStatusPegawai}
            onAturUlangPin={onAturUlangPin}
            onSimpanIzin={onSimpanIzin}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'cabang' && (
          <Cabang
            daftarCabang={daftarKelolaCabangAwal}
            onTambahCabang={onTambahKelolaCabang}
            onSimpanCabang={onSimpanKelolaCabang}
            onUbahStatusCabang={onUbahStatusKelolaCabang}
            onAturAksesCabang={onAturAksesKelolaCabang}
            hanyaBaca={hanyaBaca}
          />
        )}
        {tabAktif === 'perangkat' && <DaftarPerangkat />}
        {tabAktif === 'printer' && <PasangPrinter />}
        {tabAktif === 'tautan' && <TautanKatalog onKembali={() => setTabAktif('identitas')} />}
        {tabAktif === 'kampanye' && <Kampanye onKembali={() => setTabAktif('identitas')} />}
        {tabAktif === 'pratinjau' && (
          <Pratinjau
            dataIdentitasSaatIni={dataIdentitas}
            dataIdentitasDraf={dataIdentitasDraf}
            dataTemaSaatIni={dataTema}
            dataTemaDraf={dataTemaDraf}
            dataOperasionalSaatIni={dataOperasional}
            dataOperasionalDraf={dataOperasionalDraf}
            onSimpanSemua={onSimpanSemuaPengaturan}
            onResetDraf={onResetDrafPengaturan}
            onKembali={() => setTabAktif('identitas')}
            onCetakSimulasi={onCetakSimulasiStruk}
            hanyaBaca={hanyaBaca}
          />
        )}
      </div>
    </div>
  )
}
