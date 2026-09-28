import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { formatPesanError } from '../../lib/pesan'
import { useBahasa } from '../../bahasa'

export interface LupaAksesProps {
  onMintaTautanPemulihan: (email: string) => Promise<{ sukses: boolean; pesan?: string }>
  onKembaliKeMasuk?: () => void
}

export function LupaAkses({ onMintaTautanPemulihan, onKembaliKeMasuk }: LupaAksesProps) {
  const { t } = useBahasa()
  const [email, setEmail] = useState('')
  const [sedangKirim, setSedangKirim] = useState(false)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<{
    judul: string
    pesan: string
    tindakan: string
    kode: string
  } | null>(null)

  const tanganiSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email.trim()) return

    setSedangKirim(true)
    setPesanGalat(null)
    setPesanSukses(null)
    try {
      const hasil = await onMintaTautanPemulihan(email.trim())
      if (hasil.sukses) {
        setPesanSukses(
          `Tautan pemulihan akun telah dikirim ke ${email}. Tautan berlaku selama 15 menit.`,
        )
        setEmail('')
      } else {
        setPesanGalat(formatPesanError(hasil.pesan ?? 'EMAIL_TIDAK_DITEMUKAN'))
      }
    } catch {
      setPesanGalat(formatPesanError('JARINGAN_TERPUTUS'))
    } finally {
      setSedangKirim(false)
    }
  }

  return (
    <div className="layar-lupa-akses max-w-md mx-auto p-4 min-h-[70vh] flex flex-col justify-center">
      <Kartu judul={t('app.nama') || 'Resto Barokah'}>
        <div className="mb-4">
          <h3 className="text-xl font-bold text-neutral-800">Pemulihan Akses Akun</h3>
          <p className="text-xs text-neutral-500 mt-1">
            Masukkan email terdaftar Anda. Kami akan mengirimkan tautan aman sekali pakai untuk
            memulihkan akses voucher dan riwayat pesanan Anda.
          </p>
        </div>

        {pesanGalat && (
          <div
            role="alert"
            className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800 mb-4"
          >
            <div className="font-semibold mb-0.5">{pesanGalat.judul}</div>
            <div className="text-xs text-red-600 mb-1">{pesanGalat.pesan}</div>
            <div className="text-xs text-neutral-600 mb-1">{pesanGalat.tindakan}</div>
            <div className="text-[11px] font-mono text-neutral-500">Kode: {pesanGalat.kode}</div>
          </div>
        )}

        {pesanSukses && (
          <div
            role="status"
            className="p-3 bg-emerald-50 border border-emerald-200 rounded text-sm text-emerald-800 mb-4"
          >
            {pesanSukses}
          </div>
        )}

        <form onSubmit={tanganiSubmit} className="space-y-4">
          <KolomIsian
            label="Alamat Email Terdaftar"
            jenis="email"
            contoh="nama@email.com"
            nilai={email}
            onUbah={setEmail}
            nonaktif={sedangKirim}
            wajib
          />

          <Tombol ragam="utama" jenis="submit" lebar nonaktif={sedangKirim || !email.trim()}>
            {sedangKirim ? 'Mengirim Tautan...' : 'Kirim Tautan Pemulihan'}
          </Tombol>
        </form>

        {onKembaliKeMasuk && (
          <div className="mt-6 pt-4 border-t border-neutral-200 text-center">
            <Tombol ragam="polos" onClick={onKembaliKeMasuk}>
              <span className="text-sm text-emerald-700 font-medium hover:text-emerald-800">
                ← Kembali ke Layar Masuk
              </span>
            </Tombol>
          </div>
        )}
      </Kartu>
    </div>
  )
}
