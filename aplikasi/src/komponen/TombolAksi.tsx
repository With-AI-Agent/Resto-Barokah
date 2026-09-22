import { useState, type ReactNode, type ButtonHTMLAttributes, type MouseEvent } from 'react'
import { REGISTRI_AKSI, type EntriAksi } from '../lib/aksi'
import type { PeranPengguna } from '../lib/layar'

export interface TombolAksiProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'id'> {
  aksiId: string
  peranPengguna?: PeranPengguna
  daftarIzinPengguna?: string[]
  onEksekusi?: (aksi: EntriAksi) => Promise<void> | void
  variasi?: 'utama' | 'sekunder' | 'bahaya' | 'teks'
  sedangMemuat?: boolean
  anak?: ReactNode
}

export function TombolAksi({
  aksiId,
  peranPengguna,
  daftarIzinPengguna = [],
  onEksekusi,
  variasi = 'utama',
  sedangMemuat = false,
  anak,
  className = '',
  onClick,
  disabled,
  ...sisaProps
}: TombolAksiProps) {
  const [sedangProses, setSedangProses] = useState(false)

  const aksi = REGISTRI_AKSI[aksiId]
  if (!aksi) {
    throw new Error(`Aksi dengan id "${aksiId}" tidak terdaftar di REGISTRI_AKSI.`)
  }

  // Cek hak akses peran
  const peranBoleh = !peranPengguna || aksi.peran.includes(peranPengguna)

  // Cek hak akses izin spesifik
  const izinBoleh = !aksi.izin || daftarIzinPengguna.includes(aksi.izin)

  const punyaAkses = peranBoleh && izinBoleh

  // Jika tidak punya akses dan diatur sembunyikan
  if (!punyaAkses && aksi.sembunyikanBilaTanpaIzin) {
    return null
  }

  const tombolNonaktif = disabled || !punyaAkses || sedangMemuat || sedangProses

  const handleClick = async (e: MouseEvent<HTMLButtonElement>) => {
    if (tombolNonaktif) return

    if (aksi.konfirmasi) {
      const setuju = window.confirm(aksi.konfirmasi)
      if (!setuju) return
    }

    if (onClick) {
      onClick(e)
    }

    if (onEksekusi) {
      try {
        setSedangProses(true)
        await onEksekusi(aksi)
      } finally {
        setSedangProses(false)
      }
    }
  }

  const kelasVariasi = {
    utama: 'tombol-utama',
    sekunder: 'tombol-sekunder',
    bahaya: 'tombol-bahaya',
    teks: 'tombol-teks',
  }[variasi]

  const judulTooltip = !punyaAkses
    ? aksi.alasanNonaktifBilaTanpaIzin || 'Anda tidak memiliki hak akses untuk aksi ini.'
    : undefined

  return (
    <button
      type="button"
      data-aksi-id={aksiId}
      className={`tombol ${kelasVariasi} ${className}`}
      disabled={tombolNonaktif}
      title={judulTooltip}
      onClick={handleClick}
      {...sisaProps}
    >
      {sedangMemuat || sedangProses ? (
        <span className="indikator-memuat">Memproses...</span>
      ) : (
        anak || aksi.label
      )}
    </button>
  )
}
