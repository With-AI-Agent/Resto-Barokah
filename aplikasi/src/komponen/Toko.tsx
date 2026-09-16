import type { ReactNode } from 'react'

/**
 * Komponen dasar aplikasi.
 * Kelas CSS-nya sengaja memakai nama kelas rancangan v3 (btn, card, chip) yang
 * sudah ada di src/gaya/token/tema.css — jadi tampilannya sama dengan prototipe
 * yang sudah disetujui pemilik. Komponen lengkap menyusul di T0-04.
 */

export type RagamTombol = 'utama' | 'biasa' | 'kecil' | 'polos' | 'bahaya'

const KELAS_TOMBOL: Record<RagamTombol, string> = {
  utama: 'btn btn-primary',
  biasa: 'btn',
  kecil: 'btn btn-sm',
  polos: 'btn btn-polos',
  bahaya: 'btn btn-danger',
}

type PropsTombol = {
  children: ReactNode
  ragam?: RagamTombol
  onClick?: () => void
  jenis?: 'button' | 'submit'
  nonaktif?: boolean
}

export function Tombol({
  children,
  ragam = 'utama',
  onClick,
  jenis = 'button',
  nonaktif = false,
}: PropsTombol) {
  return (
    <button type={jenis} className={KELAS_TOMBOL[ragam]} onClick={onClick} disabled={nonaktif}>
      {children}
    </button>
  )
}

export function Kartu({ children, kelas }: { children: ReactNode; kelas?: string }) {
  return <section className={kelas ? `card ${kelas}` : 'card'}>{children}</section>
}

export type NadaLencana = 'accent' | 'success' | 'warn' | 'danger' | 'info'

export function Lencana({
  children,
  nada = 'accent',
}: {
  children: ReactNode
  nada?: NadaLencana
}) {
  return <span className={`chip chip-${nada}`}>{children}</span>
}
