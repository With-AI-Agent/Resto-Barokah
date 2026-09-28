import type { ReactNode } from 'react'

export type NadaLencana = 'accent' | 'success' | 'warn' | 'danger' | 'info' | 'netral'

const KELAS_NADA: Record<NadaLencana, string> = {
  accent: 'chip chip-accent',
  success: 'chip chip-success',
  warn: 'chip chip-warn',
  danger: 'chip chip-danger',
  info: 'chip chip-info',
  netral: 'chip',
}

/** Lencana kecil untuk status, topping, atau penanda singkat. */
export function Lencana({
  children,
  nada = 'netral',
}: {
  children: ReactNode
  nada?: NadaLencana
}) {
  return <span className={KELAS_NADA[nada]}>{children}</span>
}
