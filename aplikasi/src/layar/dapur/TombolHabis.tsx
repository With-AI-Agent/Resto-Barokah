/**
 * TombolHabis (T4-05) — tombol "menu habis" dari dapur.
 *
 * Satu sentuhan dari dapur menandai menu habis sehingga kasir & katalog publik
 * berhenti menjualnya (sumber kebenaran di peladen; realtime menyusul di kabel
 * data). Di sini: konfirmasi dua langkah inline (tanpa jendela modal) supaya
 * tidak sengaja tersentuh di layar sentuh dapur, plus keterangan pencabutan
 * memerlukan izin (aturan disimpan di peladen).
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'

export function TombolHabis({ namaMenu, onTandai }: { namaMenu: string; onTandai: () => void }) {
  const [mengonfirmasi, setMengonfirmasi] = useState(false)

  if (!mengonfirmasi) {
    return (
      <Tombol ragam="biasa" onClick={() => setMengonfirmasi(true)}>
        <span data-testid="tombol-habis">Tandai Habis: {namaMenu}</span>
      </Tombol>
    )
  }

  return (
    <span style={{ display: 'inline-flex', gap: 'var(--s-2)', alignItems: 'center' }}>
      <span className="small muted">Tandai {namaMenu} habis di kasir &amp; katalog?</span>
      <Tombol
        ragam="utama"
        onClick={() => {
          setMengonfirmasi(false)
          onTandai()
        }}
      >
        <span data-testid="tombol-habis-ya">Ya, Habis</span>
      </Tombol>
      <Tombol ragam="biasa" onClick={() => setMengonfirmasi(false)}>
        Batal
      </Tombol>
    </span>
  )
}
