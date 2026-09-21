import type { ReactNode } from 'react'

/** Penjelasan saat data belum ada — halaman tidak pernah kosong tanpa keterangan. */
export function KeadaanKosong({
  judul,
  keterangan,
  aksi,
}: {
  judul: string
  keterangan?: string
  aksi?: ReactNode
}) {
  return (
    <div className="keadaan keadaan-kosong" role="status">
      <span className="keadaan-ikon" aria-hidden="true">
        ○
      </span>
      <p className="keadaan-judul">{judul}</p>
      {keterangan ? <p className="small muted">{keterangan}</p> : null}
      {aksi ? <div className="keadaan-aksi">{aksi}</div> : null}
    </div>
  )
}
