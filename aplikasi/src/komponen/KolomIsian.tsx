import { useId } from 'react'

/**
 * Kolom isian dengan label, keterangan, dan pesan galat.
 * Tinggi minimal 44 px dan cincin fokus datang dari kelas `input` rancangan v3.
 * Pesan galat disambungkan lewat `aria-describedby` + `aria-invalid` supaya
 * pembaca layar ikut tahu ada masalah.
 */
export function KolomIsian({
  label,
  nilai,
  onUbah,
  jenis = 'text',
  keterangan,
  galat,
  wajib = false,
  nonaktif = false,
  contoh,
}: {
  label: string
  nilai: string
  onUbah: (nilai: string) => void
  jenis?: 'text' | 'email' | 'number' | 'password' | 'tel' | 'date'
  keterangan?: string
  galat?: string
  wajib?: boolean
  nonaktif?: boolean
  contoh?: string
}) {
  const id = useId()
  const idKeterangan = keterangan ? `${id}-keterangan` : undefined
  const idGalat = galat ? `${id}-galat` : undefined
  const dijelaskan = [idKeterangan, idGalat].filter(Boolean).join(' ') || undefined

  return (
    <div className="kolom-isian">
      <label className="label" htmlFor={id}>
        {label}
        {wajib ? ' *' : ''}
      </label>
      <input
        id={id}
        className="input"
        type={jenis}
        value={nilai}
        placeholder={contoh}
        required={wajib}
        disabled={nonaktif}
        aria-invalid={galat ? true : undefined}
        aria-describedby={dijelaskan}
        onChange={(kejadian) => onUbah(kejadian.target.value)}
      />
      {keterangan ? (
        <p className="small muted" id={idKeterangan}>
          {keterangan}
        </p>
      ) : null}
      {galat ? (
        <p className="small galat-isian" id={idGalat}>
          {galat}
        </p>
      ) : null}
    </div>
  )
}
