import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { useBahasa } from '../../bahasa'

export interface LayarMasukPelangganProps {
  onMasukGoogle?: () => Promise<void>
  onKirimTautanEmail?: (email: string) => Promise<{ sukses: boolean; pesan?: string }>
  onBukaKebijakanPrivasi?: () => void
}

export function LayarMasukPelanggan({
  onMasukGoogle,
  onKirimTautanEmail,
  onBukaKebijakanPrivasi,
}: LayarMasukPelangganProps) {
  const { t } = useBahasa()
  const [email, setEmail] = useState('')
  const [setujuPrivasi, setSetujuPrivasi] = useState(false)
  const [sedangKirimEmail, setSedangKirimEmail] = useState(false)
  const [sedangGoogle, setSedangGoogle] = useState(false)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)

  const tanganiGoogle = async () => {
    if (!setujuPrivasi) {
      setPesanGalat('Mohon centang persetujuan kebijakan privasi terlebih dahulu.')
      return
    }
    setSedangGoogle(true)
    setPesanGalat(null)
    try {
      await onMasukGoogle?.()
    } catch {
      setPesanGalat('Gagal memulai masuk dengan Google. Periksa koneksi internet Anda.')
    } finally {
      setSedangGoogle(false)
    }
  }

  const tanganiKirimEmail = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email.trim()) return

    if (!setujuPrivasi) {
      setPesanGalat('Mohon centang persetujuan kebijakan privasi terlebih dahulu.')
      return
    }

    setSedangKirimEmail(true)
    setPesanGalat(null)
    setPesanSukses(null)
    try {
      const hasil = await onKirimTautanEmail?.(email.trim())
      if (hasil?.sukses) {
        setPesanSukses(
          `Tautan masuk telah dikirim ke ${email}. Silakan buka email Anda untuk masuk langsung tanpa sandi.`
        )
        setEmail('')
      } else {
        setPesanGalat(hasil?.pesan || 'Gagal mengirim tautan verifikasi email.')
      }
    } catch {
      setPesanGalat('Terjadi kendala jaringan saat mengirim email.')
    } finally {
      setSedangKirimEmail(false)
    }
  }

  return (
    <div className="layar-masuk-pelanggan max-w-md mx-auto p-4 min-h-[70vh] flex flex-col justify-center">
      <Kartu judul={t('app.nama') || 'Resto Barokah'}>
        <div className="text-center mb-6">
          <h3 className="text-xl font-bold text-neutral-800">Masuk / Daftar Pelanggan</h3>
          <p className="text-xs text-neutral-500 mt-1">
            Dapatkan voucher diskon, promo ulang tahun, dan simpan riwayat pesanan favorit Anda.
          </p>
        </div>

        {pesanGalat && (
          <div role="alert" className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800 mb-4">
            {pesanGalat}
          </div>
        )}

        {pesanSukses && (
          <div role="status" className="p-3 bg-emerald-50 border border-emerald-200 rounded text-sm text-emerald-800 mb-4">
            {pesanSukses}
          </div>
        )}

        <div className="space-y-4">
          {/* Tombol Masuk Google Utama */}
          <Tombol
            ragam="biasa"
            lebar
            onClick={tanganiGoogle}
            nonaktif={sedangGoogle}
          >
            <span className="flex items-center justify-center gap-3">
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.15z"
                />
                <path
                  fill="#34A853"
                  d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.24v3.15C3.26 21.36 7.33 24 12 24z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.24C.45 8.16 0 9.94 0 12s.45 3.84 1.24 5.42l4.04-3.15z"
                />
                <path
                  fill="#EA4335"
                  d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.24 6.58l4.04 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                />
              </svg>
              <span>{sedangGoogle ? 'Menghubungkan...' : 'Lanjut dengan Akun Google'}</span>
            </span>
          </Tombol>

          <div className="flex items-center my-4">
            <div className="flex-grow border-t border-neutral-200"></div>
            <span className="flex-shrink mx-3 text-xs text-neutral-400 uppercase tracking-wider">
              atau gunakan email
            </span>
            <div className="flex-grow border-t border-neutral-200"></div>
          </div>

          {/* Form Magic Link Email */}
          <form onSubmit={tanganiKirimEmail} className="space-y-4">
            <KolomIsian
              label="Alamat Email Anda"
              jenis="email"
              contoh="nama@email.com"
              nilai={email}
              onUbah={setEmail}
              nonaktif={sedangKirimEmail}
              wajib
            />

            <Tombol ragam="biasa" jenis="submit" lebar nonaktif={sedangKirimEmail || !email.trim()}>
              {sedangKirimEmail ? 'Mengirim...' : 'Kirim Tautan Masuk ke Email'}
            </Tombol>
          </form>

          {/* Persetujuan Privasi (Sesuai UU PDP & T1-40) */}
          <div className="pt-3 border-t border-neutral-100 flex items-start gap-2">
            <input
              type="checkbox"
              id="persetujuan-privasi"
              checked={setujuPrivasi}
              onChange={(e) => setSetujuPrivasi(e.target.checked)}
              className="mt-1 h-4 w-4 rounded border-neutral-300 text-emerald-600 focus:ring-emerald-500 cursor-pointer"
            />
            <label htmlFor="persetujuan-privasi" className="text-xs text-neutral-600 cursor-pointer">
              Saya menyetujui data saya (nama & email) digunakan hanya untuk layanan resto sesuai{' '}
              <Tombol
                ragam="polos"
                onClick={onBukaKebijakanPrivasi}
              >
                <span className="text-emerald-700 underline font-medium">Kebijakan Privasi Resto</span>
              </Tombol>
              . Resto Barokah tidak membagikan data ke pihak ketiga.
            </label>
          </div>
        </div>
      </Kartu>
    </div>
  )
}
