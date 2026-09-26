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
import { DaftarPerangkat } from './DaftarPerangkat'
import { PasangPrinter } from './PasangPrinter'
import { TautanKatalog } from './TautanKatalog'
import { Kampanye } from './Kampanye'

export type TabPengaturan =
  | 'identitas'
  | 'tampilan'
  | 'operasional'
  | 'meja'
  | 'perangkat'
  | 'printer'
  | 'tautan'
  | 'kampanye'

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
  hanyaBaca = false,
}: LayarPengaturanProps) {
  const [tabAktif, setTabAktif] = useState<TabPengaturan>(tabAwal)

  const DAFTAR_TAB: Array<{ id: TabPengaturan; label: string; ikon: string }> = [
    { id: 'identitas', label: 'Identitas Resto', ikon: '🏪' },
    { id: 'tampilan', label: 'Tema & Tampilan', ikon: '🎨' },
    { id: 'operasional', label: 'Operasional & Kasir', ikon: '⚙️' },
    { id: 'meja', label: 'Meja & Area', ikon: '🪑' },
    { id: 'perangkat', label: 'Perangkat POS', ikon: '📱' },
    { id: 'printer', label: 'Printer Struk', ikon: '🖨️' },
    { id: 'tautan', label: 'Tautan & QR Meja', ikon: '🔗' },
    { id: 'kampanye', label: 'Kampanye Voucher', ikon: '🎟️' },
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
        {tabAktif === 'perangkat' && <DaftarPerangkat />}
        {tabAktif === 'printer' && <PasangPrinter />}
        {tabAktif === 'tautan' && <TautanKatalog onKembali={() => setTabAktif('identitas')} />}
        {tabAktif === 'kampanye' && <Kampanye onKembali={() => setTabAktif('identitas')} />}
      </div>
    </div>
  )
}
