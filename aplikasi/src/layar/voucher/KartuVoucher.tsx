import { useState } from 'react'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KomponenQr } from '../../komponen/KomponenQr'
import { rupiah } from '../../lib/format'
import { buatPolaGaris } from '../../lib/barcode'

export interface VoucherDetail {
  kode: string
  nama_pelanggan?: string
  nama_kampanye?: string
  nama_resto?: string
  nilai: number
  jenis: 'persen' | 'nominal'
  min_belanja: number
  maks_potongan?: number
  berlaku_sampai: string
  status?: 'aktif' | 'terpakai' | 'kedaluwarsa' | 'dibatalkan'
  pola_barcode?: string
}

export interface KartuVoucherProps {
  voucher: VoucherDetail
  onSalin?: (kode: string) => void
  onCetak?: () => void
  onTutup?: () => void
  onLihatMenu?: () => void
  className?: string
}

/**
 * Komponen Kartu Tiket Voucher Resmi
 * Menampilkan:
 *   1. Kode voucher teks monospaced besar & bebas karakter ambigu.
 *   2. Barcode visual 1D (garis SVG presisi).
 *   3. Barcode 2D (QR Code matriks).
 *   4. Informasi nilai diskon & syarat minimal belanja.
 *   5. Masa berlaku ramah awam & badge status.
 *   6. Tombol salin, cetak, dan kembali.
 */
export function KartuVoucher({
  voucher,
  onSalin,
  onCetak,
  onTutup,
  onLihatMenu,
  className = '',
}: KartuVoucherProps) {
  const [tersalin, setTersalin] = useState(false)
  const status = voucher.status || 'aktif'

  const bitPola = voucher.pola_barcode || buatPolaGaris(voucher.kode)

  const tanganiSalin = async () => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(voucher.kode)
      }
      setTersalin(true)
      onSalin?.(voucher.kode)
      setTimeout(() => setTersalin(false), 2500)
    } catch {
      setTersalin(true)
      onSalin?.(voucher.kode)
      setTimeout(() => setTersalin(false), 2500)
    }
  }

  const tanganiCetak = () => {
    if (onCetak) {
      onCetak()
    } else if (typeof window !== 'undefined' && window.print) {
      window.print()
    }
  }

  const lencanaStatus = () => {
    switch (status) {
      case 'aktif':
        return <Lencana nada="success">Siap Digunakan</Lencana>
      case 'terpakai':
        return <Lencana nada="warn">Sudah Terpakai</Lencana>
      case 'kedaluwarsa':
        return <Lencana nada="danger">Kedaluwarsa</Lencana>
      case 'dibatalkan':
        return <Lencana nada="netral">Dibatalkan</Lencana>
      default:
        return <Lencana nada="netral">{status}</Lencana>
    }
  }

  return (
    <div
      className={`kartu-voucher-wadah ${className}`}
      style={{
        maxWidth: '440px',
        margin: '0 auto',
        padding: 'var(--s-3)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--s-3)',
      }}
      data-testid="kartu-voucher-lengkap"
    >
      {/* Tiket Fisik Voucher */}
      <div
        className="kartu"
        style={{
          background: 'var(--surface)',
          border: '2px solid var(--accent)',
          borderRadius: 'var(--radius-lg)',
          boxShadow: 'var(--sh-2)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
        }}
        data-testid="tiket-voucher"
      >
        {/* Kepala Tiket */}
        <div
          style={{
            background: 'var(--surface-2)',
            padding: 'var(--s-3)',
            borderBottom: '1px dashed var(--border)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div>
            <div
              style={{
                fontSize: 'var(--t-1)',
                color: 'var(--text-muted)',
                fontWeight: 600,
                textTransform: 'uppercase',
                letterSpacing: '1px',
              }}
            >
              {voucher.nama_resto || 'Resto Barokah'}
            </div>
            <h3
              style={{
                margin: 0,
                fontSize: 'var(--t-3)',
                fontWeight: 800,
                color: 'var(--text)',
              }}
            >
              {voucher.nama_kampanye || 'Voucher Spesial'}
            </h3>
          </div>
          <div>{lencanaStatus()}</div>
        </div>

        {/* Badan Tiket: Nilai Diskon */}
        <div
          style={{
            padding: 'var(--s-4)',
            textAlign: 'center',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 'var(--s-2)',
            background: 'var(--surface)',
          }}
        >
          {voucher.nama_pelanggan && (
            <div
              style={{
                fontSize: 'var(--t-2)',
                color: 'var(--text-muted)',
              }}
            >
              Diberikan untuk: <strong>{voucher.nama_pelanggan}</strong>
            </div>
          )}

          <div
            style={{
              fontSize: 'var(--t-6)',
              fontWeight: 900,
              color: 'var(--accent)',
              lineHeight: 1.1,
              marginTop: 'var(--s-1)',
            }}
            data-testid="nilai-diskon-voucher"
          >
            {voucher.jenis === 'nominal'
              ? `Potongan ${rupiah(voucher.nilai)}`
              : `Diskon ${voucher.nilai}%`}
          </div>

          <div
            style={{
              fontSize: 'var(--t-2)',
              color: 'var(--text-muted)',
              display: 'flex',
              flexWrap: 'wrap',
              justifyContent: 'center',
              gap: 'var(--s-2)',
            }}
          >
            <span>Min. Belanja: {rupiah(voucher.min_belanja)}</span>
            {voucher.maks_potongan ? (
              <span>• Maks. Potongan: {rupiah(voucher.maks_potongan)}</span>
            ) : null}
          </div>

          {/* Kotak Kode Voucher Teks Monospace */}
          <div
            style={{
              marginTop: 'var(--s-3)',
              width: '100%',
              background: 'var(--surface-2)',
              border: '2px dashed var(--accent)',
              borderRadius: 'var(--radius-md)',
              padding: 'var(--s-3)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 'var(--s-1)',
            }}
          >
            <span
              style={{
                fontSize: 'var(--t-1)',
                fontWeight: 700,
                color: 'var(--text-muted)',
                letterSpacing: '1px',
              }}
            >
              KODE VOUCHER RESMI
            </span>
            <div
              style={{
                fontSize: 'var(--t-5)',
                fontWeight: 900,
                fontFamily: 'var(--font-mono, monospace)',
                color: 'var(--accent)',
                letterSpacing: '3px',
              }}
              data-testid="kode-voucher-teks"
            >
              <span data-testid="teks-kode-voucher">{voucher.kode}</span>
            </div>
          </div>

          {/* Visual Barcode 1D (Garis) */}
          <div
            style={{
              marginTop: 'var(--s-2)',
              width: '100%',
              padding: 'var(--s-2)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
            }}
            data-testid="wadah-barcode-1d"
          >
            <div style={{ width: '100%', maxWidth: '280px', height: '46px' }}>
              <svg
                viewBox={`0 0 ${bitPola.length} 40`}
                width="100%"
                height="100%"
                preserveAspectRatio="none"
                role="img"
                aria-label={`Barcode 1D untuk kode ${voucher.kode}`}
              >
                <rect width="100%" height="100%" fill="var(--surface-2)" />
                {bitPola
                  .split('')
                  .map((bit, idx) =>
                    bit === '1' ? (
                      <rect key={idx} x={idx} y="0" width="1" height="40" fill="var(--text)" />
                    ) : null,
                  )}
              </svg>
            </div>
            <span
              style={{
                fontSize: 'var(--t-1)',
                color: 'var(--text-muted)',
                fontFamily: 'var(--font-mono, monospace)',
                marginTop: 'var(--s-1)',
              }}
            >
              {voucher.kode}
            </span>
          </div>

          {/* Barcode 2D QR Code */}
          <div
            style={{
              marginTop: 'var(--s-2)',
              width: '100%',
              display: 'flex',
              justifyContent: 'center',
            }}
          >
            <KomponenQr
              url={voucher.kode}
              ukuran={130}
              keterangan="Pindai barcode atau QR di kasir untuk klaim"
              bisaSalin={false}
              bisaUnduh={false}
            />
          </div>

          {/* Informasi Masa Berlaku */}
          <div
            style={{
              marginTop: 'var(--s-2)',
              fontSize: 'var(--t-2)',
              color: status === 'kedaluwarsa' ? 'var(--bahaya)' : 'var(--text-muted)',
              fontWeight: 600,
            }}
            data-testid="masa-berlaku-voucher"
          >
            🗓️ Masa Berlaku: s.d. {voucher.berlaku_sampai}
          </div>
        </div>

        {/* Catatan Kaki Tiket */}
        <div
          style={{
            background: 'var(--surface-2)',
            padding: 'var(--s-2) var(--s-3)',
            borderTop: '1px dashed var(--border)',
            fontSize: 'var(--t-1)',
            color: 'var(--text-muted)',
            textAlign: 'center',
          }}
        >
          ⚠️ Berlaku 1 kali per pelanggan. Tunjukkan tiket ini kepada kasir saat pembayaran.
        </div>
      </div>

      {/* Tombol Aksi Pengguna */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-2)',
        }}
      >
        <Tombol
          ragam={tersalin ? 'biasa' : 'utama'}
          lebar
          onClick={tanganiSalin}
          nama="Salin kode voucher"
        >
          {tersalin ? '✓ Kode Tersalin ke Papan Klip!' : '📋 Salin Kode Voucher'}
        </Tombol>

        <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
          <Tombol ragam="biasa" lebar onClick={tanganiCetak} nama="Cetak atau simpan tiket voucher">
            🖨️ Cetak / Simpan Tiket
          </Tombol>

          {onLihatMenu && (
            <Tombol ragam="biasa" lebar onClick={onLihatMenu} nama="Lihat menu katalog resto">
              📖 Intip Menu
            </Tombol>
          )}
        </div>

        {onTutup && (
          <Tombol ragam="polos" lebar onClick={onTutup} nama="Tutup kartu voucher">
            Kembali
          </Tombol>
        )}
      </div>
    </div>
  )
}
