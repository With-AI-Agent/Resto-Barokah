import { useEffect, useId, useRef, useState, type ReactNode } from 'react'

/**
 * PemilihRingkas — tombol yang membuka panel pilihan, dengan cara menutup
 * seperti yang lazim di aplikasi lain.
 *
 * Kenapa dibuat (laporan pemilik 2026-09-17, ketiga): panel tema memakai
 * `<details>/<summary>` bawaan peramban, yang **tidak** menutup saat Esc
 * ditekan maupun saat mengetuk di luar — pemilik harus mengklik tombolnya lagi.
 * Riset (WAI-ARIA APG pola *disclosure*; panduan Evinced; artikel aksesibilitas
 * 2022–2026) menyebut empat hal wajib yang kini dipenuhi di sini:
 *
 *  1. **Esc menutup DAN mengembalikan fokus ke tombolnya** — tanpa itu pengguna
 *     papan tik "terdampar" dan harus menekan Tab berkali-kali.
 *  2. **Klik/ketuk di luar menutup** (tanpa merebut fokus — fokus tidak
 *     dikembalikan ke tombol pada kasus ini, sesuai anjuran panduan menu aksesibel).
 *  3. **Fokus pindah keluar panel → menutup** (APG: "moving focus out of the
 *     region also closes an open dropdown").
 *  4. **Keadaan diumumkan**: `aria-expanded` di tombol + `aria-controls` ke id
 *     panel; panel diberi `aria-labelledby` ke tombolnya.
 *
 * Aturan yang sama ditulis di `prototipe/js/ui.js` supaya sumber desain dan
 * aplikasi tidak berbeda. Rincian & sumber: `skills/desain-antarmuka/SKILL.md`.
 */
type Props = {
  /** Nama tombol (dipakai juga sebagai aria-label). */
  label: string
  /** Isi tombol; kalau kosong, dipakai `label`. */
  anakTombol?: ReactNode
  /** Kelas tombol; bawaan gaya aplikasi. */
  kelasTombol?: string
  /** Kalimat kecil di kepala panel (opsional). */
  judulPanel?: ReactNode
  /** Kelas wadah panel. */
  kelasPanel?: string
  /** Isi daftar (tombol-tombol pilihan). */
  children: ReactNode
}

export function PemilihRingkas({
  label,
  anakTombol,
  kelasTombol = 'btn btn-sm',
  judulPanel,
  kelasPanel = 'picker-panel',
  children,
}: Props) {
  const [terbuka, setTerbuka] = useState(false)
  const awalan = useId()
  const idTombol = `${awalan}tombol`
  const idPanel = `${awalan}panel`
  const akar = useRef<HTMLDivElement>(null)
  const tombol = useRef<HTMLButtonElement>(null)

  const tutup = (kembalikanFokus: boolean) => {
    setTerbuka(false)
    if (kembalikanFokus) tombol.current?.focus()
  }

  useEffect(() => {
    if (!terbuka) return
    const tekan = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        tutup(true) // Esc: tutup + fokus pulang ke tombol
      }
    }
    const sentuhLuar = (e: PointerEvent) => {
      if (!akar.current?.contains(e.target as Node)) tutup(false) // klik di luar: tutup, fokus tidak dirampas
    }
    document.addEventListener('keydown', tekan)
    document.addEventListener('pointerdown', sentuhLuar)
    return () => {
      document.removeEventListener('keydown', tekan)
      document.removeEventListener('pointerdown', sentuhLuar)
    }
  }, [terbuka])

  return (
    <div
      className="picker"
      ref={akar}
      onBlur={(e) => {
        // Fokus pindah ke luar panel (mis. Tab keluar) → panel menutup.
        if (terbuka && !akar.current?.contains(e.relatedTarget)) tutup(false)
      }}
      onClick={(e) => {
        // Sebuah pilihan diklik dari dalam daftar → panel menutup, fokus pulang.
        if (terbuka && (e.target as HTMLElement).closest('.picker-daftar button')) tutup(true)
      }}
    >
      <button
        type="button"
        id={idTombol}
        ref={tombol}
        className={kelasTombol}
        aria-expanded={terbuka}
        aria-controls={idPanel}
        aria-label={label}
        onClick={() => (terbuka ? tutup(false) : setTerbuka(true))}
      >
        {anakTombol ?? label}
      </button>
      {terbuka ? (
        <div className={kelasPanel} id={idPanel} role="region" aria-labelledby={idTombol}>
          {judulPanel ? <p className="picker-all">{judulPanel}</p> : null}
          <div className="picker-daftar">{children}</div>
        </div>
      ) : null}
    </div>
  )
}
