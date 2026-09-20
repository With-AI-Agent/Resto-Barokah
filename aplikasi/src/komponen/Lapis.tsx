import { useEffect, useRef, type ReactNode } from 'react'
import { Tombol } from './Tombol'

const PEMILIK_FOKUS = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'

/**
 * Lapis mengambang (panel di atas halaman) — dipakai untuk konfirmasi,
 * rincian pesanan, dan pilihan pembayaran.
 * Aturan yang sudah dijaga di sini:
 *  - Tombol Esc menutup lapis.
 *  - Klik latar gelap menutup lapis.
 *  - Pembaca layar mengenalinya sebagai dialog (`role="dialog"`, `aria-modal`).
 *  - Halaman di belakang tidak bisa digulir selagi lapis terbuka.
 *  - Fokus keyboard DIKUNCI di dalam lapis (Tab/Shift-Tab berputar di dalamnya)
 *    dan DIPULIHKAN ke elemen semula saat lapis ditutup (temuan F F-15).
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
  const panelRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!buka) return
    const pemegangFokusSebelumnya = document.activeElement as HTMLElement | null
    const tekan = (kejadian: KeyboardEvent) => {
      if (kejadian.key === 'Escape') {
        onTutup()
        return
      }
      if (kejadian.key !== 'Tab') return
      const panel = panelRef.current
      if (!panel) return
      const fokusabel = Array.from(panel.querySelectorAll<HTMLElement>(PEMILIK_FOKUS)).filter(
        (elemen) => !elemen.hasAttribute('disabled'),
      )
      if (fokusabel.length === 0) {
        kejadian.preventDefault()
        panel.focus()
        return
      }
      const pertama = fokusabel[0]
      const terakhir = fokusabel[fokusabel.length - 1]
      const aktif = document.activeElement
      const diLuar = !panel.contains(aktif)
      if (kejadian.shiftKey) {
        if (aktif === pertama || aktif === panel || diLuar) {
          kejadian.preventDefault()
          terakhir.focus()
        }
      } else if (aktif === terakhir || diLuar) {
        kejadian.preventDefault()
        pertama.focus()
      }
    }
    window.addEventListener('keydown', tekan)
    const sebelumnya = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    // Fokus masuk ke lapis: elemen interaktif pertama, atau panelnya bila kosong.
    const panel = panelRef.current
    const awal = panel?.querySelector<HTMLElement>(PEMILIK_FOKUS)
    ;(awal ?? panel)?.focus()
    return () => {
      window.removeEventListener('keydown', tekan)
      document.body.style.overflow = sebelumnya
      // Fokus pulang ke pemegangnya sebelum lapis terbuka.
      pemegangFokusSebelumnya?.focus()
    }
  }, [buka, onTutup])

  if (!buka) return null

  return (
    <div className="lapis-latar" role="presentation" onClick={onTutup}>
      <div
        ref={panelRef}
        tabIndex={-1}
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
