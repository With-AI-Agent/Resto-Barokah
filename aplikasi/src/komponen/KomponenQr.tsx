import { useState, useId } from 'react'
import { buatQrMatriks } from '../lib/qrcode'
import { Tombol } from './Tombol'

export interface KomponenQrProps {
  url: string
  ukuran?: number
  judul?: string
  keterangan?: string
  bisaSalin?: boolean
  bisaUnduh?: boolean
  className?: string
}

export function KomponenQr({
  url,
  ukuran = 180,
  judul,
  keterangan,
  bisaSalin = true,
  bisaUnduh = false,
  className = '',
}: KomponenQrProps) {
  const [tersalin, setTersalin] = useState(false)
  const idUnik = useId()

  const matriks = buatQrMatriks(url || 'https://resto-barokah.dev')
  const N = matriks.length
  const margin = 2
  const total = N + margin * 2

  let pathD = ''
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (matriks[r][c]) {
        pathD += `M${c + margin},${r + margin}h1v1h-1z `
      }
    }
  }

  const handleSalin = async () => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(url)
      }
      setTersalin(true)
      setTimeout(() => setTersalin(false), 2500)
    } catch {
      setTersalin(true)
      setTimeout(() => setTersalin(false), 2500)
    }
  }

  const handleUnduhSvg = () => {
    const svgKonten = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${total} ${total}" width="500" height="500">
  <rect width="100%" height="100%" fill="white"/>
  <path d="${pathD.trim()}" fill="black"/>
</svg>`
    const blob = new Blob([svgKonten], { type: 'image/svg+xml' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `qr-katalog-${Date.now()}.svg`
    link.click()
    URL.revokeObjectURL(link.href)
  }

  return (
    <div
      className={`kartu flex-kolom item-pusat teks-pusat ${className}`}
      style={{
        padding: 'var(--s-4)',
        background: 'var(--surface)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--sh-2)',
        maxWidth: '320px',
        margin: '0 auto',
      }}
      data-testid="komponen-qr"
    >
      {judul && (
        <h4
          id={`judul-qr-${idUnik}`}
          style={{
            fontSize: 'var(--t-4)',
            fontWeight: 700,
            marginBottom: 'var(--s-2)',
            color: 'var(--text)',
          }}
        >
          {judul}
        </h4>
      )}

      {/* Tampilan Visual QR Code SVG */}
      <div
        style={{
          background: 'white',
          padding: 'var(--s-3)',
          borderRadius: 'var(--radius-md)',
          boxShadow: 'var(--sh-1)',
          display: 'inline-flex',
          justifyContent: 'center',
          alignItems: 'center',
          margin: '0 auto',
        }}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox={`0 0 ${total} ${total}`}
          width={ukuran}
          height={ukuran}
          role="img"
          aria-labelledby={judul ? `judul-qr-${idUnik}` : undefined}
          aria-label={judul || 'Kode QR Katalog'}
          style={{ display: 'block', maxWidth: '100%', height: 'auto' }}
        >
          <rect width="100%" height="100%" fill="white" />
          <path d={pathD.trim()} fill="black" />
        </svg>
      </div>

      {keterangan && (
        <p
          className="small muted"
          style={{ marginTop: 'var(--s-2)', marginBottom: 'var(--s-2)', fontSize: 'var(--t-2)' }}
        >
          {keterangan}
        </p>
      )}

      <div
        style={{
          marginTop: 'var(--s-3)',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-2)',
        }}
      >
        <div
          style={{
            fontSize: 'var(--t-1)',
            padding: 'var(--s-1) var(--s-2)',
            background: 'var(--surface-2)',
            borderRadius: 'var(--radius-sm)',
            border: '1px solid var(--border)',
            wordBreak: 'break-all',
            color: 'var(--text-muted)',
            fontFamily: 'var(--font-mono, monospace)',
          }}
          data-testid="teks-url-qr"
        >
          {url}
        </div>

        <div style={{ display: 'flex', gap: 'var(--s-2)', justifyContent: 'center' }}>
          {bisaSalin && (
            <Tombol
              ragam={tersalin ? 'biasa' : 'utama'}
              onClick={handleSalin}
              lebar
              nama="Salin tautan katalog"
            >
              {tersalin ? '✓ Tautan Tersalin!' : '📋 Salin Tautan'}
            </Tombol>
          )}

          {bisaUnduh && (
            <Tombol ragam="polos" onClick={handleUnduhSvg} nama="Unduh QR Code SVG">
              ⬇️ Unduh QR
            </Tombol>
          )}
        </div>
      </div>
    </div>
  )
}
