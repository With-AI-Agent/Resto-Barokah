import type { ReactNode } from 'react'

/**
 * Tombol dasar.
 * Kelas `btn` berasal dari rancangan v3 (`src/gaya/token/tema.css`):
 * tinggi minimal 44 px, cincin fokus otomatis, dan warna dari token tema.
 * Varian kecil (`.btn-sm`) tetap aman disentuh karena rancangan menambah
 * daerah sentuh lewat `::after` (lihat `.btn-sm::after`).
 */

export type RagamTombol = 'utama' | 'biasa' | 'kecil' | 'polos' | 'bahaya'

const KELAS_RAGAM: Record<RagamTombol, string> = {
  utama: 'btn btn-primary',
  biasa: 'btn',
  kecil: 'btn btn-sm',
  polos: 'btn btn-polos',
  bahaya: 'btn btn-danger',
}

export type PropsTombol = {
  children: ReactNode
  ragam?: RagamTombol
  onClick?: () => void
  jenis?: 'button' | 'submit'
  nonaktif?: boolean
  /** Tombol selebar kartu (dipakai di bilah bawah). */
  lebar?: boolean
  /** Nama untuk pembaca layar bila isi tombol hanya ikon. */
  nama?: string
}

export function Tombol({
  children,
  ragam = 'utama',
  onClick,
  jenis = 'button',
  nonaktif = false,
  lebar = false,
  nama,
}: PropsTombol) {
  const kelas = lebar ? `${KELAS_RAGAM[ragam]} btn-lg` : KELAS_RAGAM[ragam]
  return (
    <button type={jenis} className={kelas} onClick={onClick} disabled={nonaktif} aria-label={nama}>
      {children}
    </button>
  )
}
