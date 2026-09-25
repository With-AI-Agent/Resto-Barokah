/**
 * LayarPengaturan.tsx — Induk Pengaturan Restoran (PRD M2 / Fase 9)
 *
 * Menggabungkan seluruh modul pengaturan restoran:
 *  1. Identitas & Tampilan Resto (`Identitas`) — T9-01 / PRD M2
 *  2. Pengelolaan Perangkat POS (`DaftarPerangkat`) — T6-04
 *  3. Sambungan & Pengaturan Printer (`PasangPrinter`) — T6-08
 *  4. Tautan Publik & QR Meja (`TautanKatalog`) — T8-03
 *  5. Kampanye Voucher Pelanggan (`Kampanye`) — T8-08
 */

import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Identitas, type DataIdentitas } from './Identitas'
import { DaftarPerangkat } from './DaftarPerangkat'
import { PasangPrinter } from './PasangPrinter'
import { TautanKatalog } from './TautanKatalog'
import { Kampanye } from './Kampanye'

export type TabPengaturan = 'identitas' | 'perangkat' | 'printer' | 'tautan' | 'kampanye'

export interface LayarPengaturanProps {
  tabAwal?: TabPengaturan
  dataIdentitas?: Partial<DataIdentitas>
  onSimpanIdentitas?: (data: DataIdentitas) => Promise<{ berhasil: boolean; pesan?: string }>
  hanyaBaca?: boolean
}

export function LayarPengaturan({
  tabAwal = 'identitas',
  dataIdentitas,
  onSimpanIdentitas,
  hanyaBaca = false,
}: LayarPengaturanProps) {
  const [tabAktif, setTabAktif] = useState<TabPengaturan>(tabAwal)

  const DAFTAR_TAB: Array<{ id: TabPengaturan; label: string; ikon: string }> = [
    { id: 'identitas', label: 'Identitas & Tampilan', ikon: '🏪' },
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
        {tabAktif === 'perangkat' && <DaftarPerangkat />}
        {tabAktif === 'printer' && <PasangPrinter />}
        {tabAktif === 'tautan' && <TautanKatalog onKembali={() => setTabAktif('identitas')} />}
        {tabAktif === 'kampanye' && <Kampanye onKembali={() => setTabAktif('identitas')} />}
      </div>
    </div>
  )
}
