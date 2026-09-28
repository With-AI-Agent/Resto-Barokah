import type { ReactNode } from 'react'

/**
 * Kartu wadah isi (kelas `card` dari rancangan v3).
 * Kalau `judul` diisi, judulnya memakai `.card-head` supaya sejajar dengan
 * rancangan; `aksi` di kanan judul dipakai untuk tombol kecil (mis. "Lihat semua").
 */
export function Kartu({
  children,
  judul,
  aksi,
  kelas,
}: {
  children: ReactNode
  judul?: ReactNode
  aksi?: ReactNode
  kelas?: string
}) {
  const kelasKartu = kelas ? `card ${kelas}` : 'card'
  return (
    <section className={kelasKartu}>
      {judul ? (
        <div className="card-head">
          {typeof judul === 'string' ? <h3>{judul}</h3> : judul}
          {aksi}
        </div>
      ) : null}
      {children}
    </section>
  )
}
