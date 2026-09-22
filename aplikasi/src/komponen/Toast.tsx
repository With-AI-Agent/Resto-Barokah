import type { ReactNode } from 'react'

export type NadaToast = 'sukses' | 'gagal' | 'info'

const KELAS_TOAST: Record<NadaToast, string> = {
  sukses: 'toast toast-sukses',
  gagal: 'toast toast-gagal',
  info: 'toast toast-info',
}

/**
 * Pemberitahuan singkat yang muncul di atas layar.
 * `role="status"` + `aria-live="polite"` supaya pembaca layar membacakannya
 * tanpa merebut fokus pegawai yang sedang bekerja.
 */
export function Toast({
  pesan,
  nada = 'info',
  aksi,
}: {
  pesan: string
  nada?: NadaToast
  aksi?: ReactNode
}) {
  return (
    <div className={KELAS_TOAST[nada]} role="status" aria-live="polite">
      <span>{pesan}</span>
      {aksi}
    </div>
  )
}
