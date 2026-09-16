import { useEffect, type ReactNode } from 'react'
import { Tombol } from './Tombol'

/**
 * Lapis mengambang (panel di atas halaman) — dipakai untuk konfirmasi,
 * rincian pesanan, dan pilihan pembayaran.
 * Aturan yang sudah dijaga di sini:
 *  - Tombol Esc menutup lapis.
 *  - Klik latar gelap menutup lapis.
 *  - Pembaca layar mengenalinya sebagai dialog (`role="dialog"`, `aria-modal`).
 *  - Halaman di belakang tidak bisa digulir selagi lapis terbuka.
 */
export function Lapis({
  buka,
  judul,
  onTutup,
  children,
  kaki,
}: {
  buka: boolean
  judul: string
  onTutup: () => void
  children?: ReactNode
  kaki?: ReactNode
}) {
  useEffect(() => {
    if (!buka) return
    const tekan = (kejadian: KeyboardEvent) => {
      if (kejadian.key === 'Escape') onTutup()
    }
    window.addEventListener('keydown', tekan)
    const sebelumnya = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      window.removeEventListener('keydown', tekan)
      document.body.style.overflow = sebelumnya
    }
  }, [buka, onTutup])

  if (!buka) return null

  return (
    <div className="lapis-latar" role="presentation" onClick={onTutup}>
      <div
        className="lapis-panel"
        role="dialog"
        aria-modal="true"
        aria-label={judul}
        onClick={(kejadian) => kejadian.stopPropagation()}
      >
        <div className="lapis-kepala">
          <h2 className="lapis-judul">{judul}</h2>
          <Tombol ragam="polos" onClick={onTutup} nama="Tutup">
            Tutup
          </Tombol>
        </div>
        <div className="lapis-isi">{children}</div>
        {kaki ? <div className="lapis-kaki">{kaki}</div> : null}
      </div>
    </div>
  )
}
