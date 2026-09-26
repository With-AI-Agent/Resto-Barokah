/**
 * StatusAntreanOffline.tsx — Komponen penampil status antrean kirim luring (T10-01).
 *
 * Menyajikan status visual yang jelas dan jujur bagi kasir/staf:
 *  - Menampilkan teks "menunggu dikirim X" sesuai DoD T10-01 dan prinsip ART-8.
 *  - Tombol aksi kirim manual saat kembali daring.
 */

import { type ReactElement } from 'react'
import { useAntrean } from '../hook/useAntrean'
import { Lencana } from './Lencana'
import { Tombol } from './Tombol'

export interface StatusAntreanOfflineProps {
  className?: string
  /** Mode ringkas hanya menampilkan lencana badge */
  ringkas?: boolean
}

export function StatusAntreanOffline({
  className = '',
  ringkas = false,
}: StatusAntreanOfflineProps): ReactElement | null {
  const { apakahDaring, jumlahMenunggu, sedangSinkronisasi, pesanStatus, sinkronkanAntrean } =
    useAntrean()

  // Jika online dan tidak ada antrean yang menunggu, sembunyikan atau tampilkan status tenang
  if (apakahDaring && jumlahMenunggu === 0 && !sedangSinkronisasi) {
    return null
  }

  if (ringkas) {
    return (
      <span
        role="status"
        aria-live="polite"
        data-testid="status-antrean-ringkas"
        className={className}
      >
        <Lencana nada={!apakahDaring ? 'warn' : jumlahMenunggu > 0 ? 'accent' : 'success'}>
          {!apakahDaring ? '📡 Luring' : '🔄'} · {pesanStatus}
        </Lencana>
      </span>
    )
  }

  return (
    <aside
      role="status"
      aria-live="polite"
      data-testid="status-antrean-banner"
      className={`kotak-peringatan ${className}`}
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: 'var(--s-2)',
        padding: 'var(--s-2) var(--s-3)',
        borderRadius: 'var(--radius)',
        border: '1px solid var(--border)',
        backgroundColor: 'var(--bg-kartu)',
        color: 'var(--text)',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
        <span style={{ fontSize: '1.25rem' }}>{!apakahDaring ? '📡' : '🔄'}</span>
        <div>
          <div style={{ fontWeight: 600 }}>
            {!apakahDaring ? 'Mode Luring (Offline)' : 'Sinkronisasi Tertunda'}
          </div>
          <div style={{ fontSize: '0.875rem', opacity: 0.9 }} data-testid="teks-status-antrean">
            {pesanStatus}
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
        {apakahDaring && jumlahMenunggu > 0 && (
          <Tombol
            jenis="button"
            ragam="kecil"
            onClick={() => void sinkronkanAntrean()}
            nonaktif={sedangSinkronisasi}
            data-testid="btn-sinkron-antrean"
          >
            {sedangSinkronisasi ? 'Mengirim...' : 'Kirim Sekarang'}
          </Tombol>
        )}
      </div>
    </aside>
  )
}
