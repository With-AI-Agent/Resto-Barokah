/**
 * ScanVoucher.tsx (T8-10) — Pemindaian Barcode/QR Kamera + Masukan Manual sebagai Cadangan.
 *
 * Ref: PRD M10 ("Kasir bisa scan lewat kamera atau mengetik kode manual").
 *
 * Jaminan Teknis (DoD T8-10):
 *  1. Memindai barcode/QR dari kamera perangkat kasir menggunakan API standar peramban.
 *  2. Masukan manual SELALU TERSEDIA langsung di layar sebagai cadangan utama bila kamera
 *     bermasalah, buram, tidak fokus, atau perangkat kasir berupa PC tanpa webcam.
 *  3. Pesan kejelasan bila kamera tidak tersedia atau izin akses ditolak disajikan
 *     dalam bahasa Indonesia yang ramah awam tanpa jargon teknis.
 *  4. Pembersihan sumber daya (MediaStream track) dilakukan secara otomatis saat komponen unmount.
 */
import { useEffect, useRef, useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'

export interface ScanVoucherProps {
  /** Callback saat kode berhasil dipindai dari kamera atau dimasukkan manual */
  onPindai: (kode: string) => void
  /** Callback saat kasir membatalkan atau menutup pemindai */
  onBatal?: () => void
  /** Apakah langsung mengaktifkan kamera saat layar dibuka (default: true) */
  autoMulai?: boolean
}

type StatusKamera = 'memuat' | 'aktif' | 'ditolak' | 'tidak_tersedia' | 'berhenti'

export function ScanVoucher({ onPindai, onBatal, autoMulai = true }: ScanVoucherProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [statusKamera, setStatusKamera] = useState<StatusKamera>('memuat')
  const [pesanGalatKamera, setPesanGalatKamera] = useState<string | null>(null)
  const [kodeManual, setKodeManual] = useState('')
  const [pesanManual, setPesanManual] = useState<string | null>(null)
  const [kodeTerdeteksi, setKodeTerdeteksi] = useState<string | null>(null)

  useEffect(() => {
    let aktif = true
    let streamAktif: MediaStream | null = null
    let rafId: number | null = null

    const inisialisasiKamera = async () => {
      if (!autoMulai) {
        setStatusKamera('berhenti')
        return
      }

      // Periksa ketersediaan API MediaDevices pada peramban
      if (
        typeof navigator === 'undefined' ||
        !navigator.mediaDevices ||
        !navigator.mediaDevices.getUserMedia
      ) {
        if (aktif) {
          setStatusKamera('tidak_tersedia')
          setPesanGalatKamera(
            'Kamera tidak didukung pada peramban atau perangkat kasir ini. Silakan gunakan masukan manual di bawah.',
          )
        }
        return
      }

      setStatusKamera('memuat')
      setPesanGalatKamera(null)

      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment' },
        })

        if (!aktif) {
          stream.getTracks().forEach((track) => track.stop())
          return
        }

        streamAktif = stream
        if (videoRef.current) {
          videoRef.current.srcObject = stream
          await videoRef.current.play().catch(() => {})
        }
        setStatusKamera('aktif')

        // Jika peramban mendukung BarcodeDetector API asli
        interface DetektorBarcode {
          detect: (source: ImageBitmapSource) => Promise<Array<{ rawValue: string }>>
        }
        type JendelaDenganDetektor = typeof window & {
          BarcodeDetector?: new (opsi?: { formats: string[] }) => DetektorBarcode
        }

        const jendela = window as JendelaDenganDetektor
        if (typeof jendela.BarcodeDetector === 'function') {
          const detector = new jendela.BarcodeDetector({
            formats: ['qr_code', 'code_128', 'code_39', 'ean_13'],
          })

          const loopDeteksi = async () => {
            if (!aktif || !videoRef.current) return
            try {
              if (videoRef.current.readyState >= 2) {
                const barcodes = await detector.detect(videoRef.current)
                if (barcodes && barcodes.length > 0 && barcodes[0].rawValue) {
                  const hasil = barcodes[0].rawValue.trim().toUpperCase()
                  setKodeTerdeteksi(hasil)
                  onPindai(hasil)
                  return
                }
              }
            } catch {
              // Abaikan galat frame individual, lanjutkan loop
            }
            rafId = requestAnimationFrame(loopDeteksi)
          }

          rafId = requestAnimationFrame(loopDeteksi)
        }
      } catch (err: unknown) {
        if (!aktif) return
        const galat = err as { name?: string; message?: string }
        if (galat?.name === 'NotAllowedError' || galat?.name === 'PermissionDeniedError') {
          setStatusKamera('ditolak')
          setPesanGalatKamera(
            'Izin akses kamera ditolak oleh peramban. Mohon izinkan akses kamera atau gunakan masukan manual di bawah.',
          )
        } else {
          setStatusKamera('tidak_tersedia')
          setPesanGalatKamera(
            'Kamera tidak dapat diakses atau sedang digunakan oleh aplikasi lain. Silakan gunakan masukan manual di bawah.',
          )
        }
      }
    }

    inisialisasiKamera()

    return () => {
      aktif = false
      if (rafId) cancelAnimationFrame(rafId)
      if (streamAktif) {
        streamAktif.getTracks().forEach((track) => track.stop())
      }
    }
  }, [autoMulai, onPindai])

  const tanganiGunakanManual = () => {
    setPesanManual(null)
    const bersih = kodeManual.trim().toUpperCase()
    if (!bersih) {
      setPesanManual('Ketik kode voucher terlebih dahulu.')
      return
    }
    onPindai(bersih)
  }

  return (
    <div className="scan-voucher" data-testid="scan-voucher">
      {/* Area Kamera / Bidikan */}
      <div className="scan-voucher__kamera-wadah" data-testid="kamera-wadah">
        {statusKamera === 'aktif' && (
          <>
            <video
              ref={videoRef}
              className="scan-voucher__video"
              data-testid="video-kamera"
              playsInline
              muted
            />
            <div className="scan-voucher__bingkai-bidik" data-testid="bingkai-bidik" />
          </>
        )}

        {statusKamera === 'memuat' && (
          <div className="scan-voucher__pesan-kamera">
            <Lencana nada="info">Menyiapkan Kamera...</Lencana>
            <p className="small muted">Sedang menghubungkan ke kamera perangkat...</p>
          </div>
        )}

        {(statusKamera === 'tidak_tersedia' || statusKamera === 'ditolak') && (
          <div className="scan-voucher__pesan-kamera" data-testid="pesan-kamera-tidak-tersedia">
            <Lencana nada="danger">
              {statusKamera === 'ditolak' ? 'Akses Ditolak' : 'Kamera Tidak Tersedia'}
            </Lencana>
            <p className="small" style={{ color: 'var(--text-muted)' }}>
              {pesanGalatKamera}
            </p>
          </div>
        )}

        {statusKamera === 'berhenti' && (
          <div className="scan-voucher__pesan-kamera">
            <Lencana nada="netral">Kamera Nonaktif</Lencana>
          </div>
        )}
      </div>

      {kodeTerdeteksi && (
        <div data-testid="scan-hasil-deteksi" style={{ textAlign: 'center' }}>
          <Lencana nada="success">Kode Terdeteksi: {kodeTerdeteksi}</Lencana>
        </div>
      )}

      {/* Jalur Cadangan Wajib: Masukan Manual (Selalu Tersedia) */}
      <div className="scan-voucher__manual" data-testid="scan-voucher-manual">
        <KolomIsian
          label="Ketik kode voucher manual"
          jenis="text"
          nilai={kodeManual}
          onUbah={(val) => {
            setKodeManual(val)
            setPesanManual(null)
          }}
          contoh="Mis. RB-8M4K-9Q2V atau VC-HEMAT20"
          keterangan="Gunakan jalur ini bila kamera bermasalah, tidak fokus, atau perangkat kasir tanpa webcam."
        />

        {pesanManual && (
          <p className="small" data-testid="scan-pesan-manual" style={{ color: 'var(--danger)' }}>
            {pesanManual}
          </p>
        )}

        <div style={{ display: 'flex', gap: 'var(--s-2)', marginTop: 'var(--s-1)' }}>
          <Tombol
            ragam="utama"
            onClick={tanganiGunakanManual}
            nonaktif={!kodeManual.trim()}
            nama="Gunakan kode manual"
          >
            Gunakan Kode Manual
          </Tombol>
        </div>
      </div>

      {/* Tombol Aksi Bawah */}
      <div className="scan-voucher__aksi">
        <Tombol ragam="biasa" onClick={onBatal} nama="Batal scan">
          Batal
        </Tombol>
      </div>
    </div>
  )
}
