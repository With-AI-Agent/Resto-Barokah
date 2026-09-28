import React from 'react'
import { useBahasa } from '../bahasa'

export interface PemilihCabangProps {
  cabangAktifId: string | null
  daftarCabang: Array<{ id: string; nama: string }>
  bisaPindahCabang: boolean
  onGantiCabang: (id: string) => void
}

export const PemilihCabang: React.FC<PemilihCabangProps> = ({
  cabangAktifId,
  daftarCabang,
  bisaPindahCabang,
  onGantiCabang,
}) => {
  const { t } = useBahasa()

  if (daftarCabang.length === 0) return null

  const cabangAktif = daftarCabang.find((c) => c.id === cabangAktifId) || daftarCabang[0]

  if (!bisaPindahCabang) {
    return (
      <div
        className="lencana lencana-netral"
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 'var(--s-1)',
          padding: 'var(--s-1) var(--s-2)',
          fontSize: 'var(--t-3)',
        }}
      >
        <span>📍</span>
        <span>{cabangAktif?.nama || 'Cabang Resto'}</span>
      </div>
    )
  }

  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-2)' }}>
      <label htmlFor="pilih-cabang" style={{ fontSize: 'var(--t-3)', fontWeight: 600 }}>
        📍 {t('cabang')}:
      </label>
      <select
        id="pilih-cabang"
        className="input"
        value={cabangAktifId || ''}
        onChange={(e) => onGantiCabang(e.target.value)}
        style={{
          padding: 'var(--s-1) var(--s-3)',
          height: 'var(--tinggi-kendali, 44px)',
          minHeight: 'var(--tinggi-kendali, 44px)',
          fontSize: 'var(--t-3)',
          cursor: 'pointer',
        }}
      >
        {daftarCabang.map((c) => (
          <option key={c.id} value={c.id}>
            {c.nama}
          </option>
        ))}
      </select>
    </div>
  )
}
