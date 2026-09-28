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
          `Tautan masuk telah dikirim ke ${email}. Silakan buka email Anda untuk masuk langsung tanpa sandi.`,
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

  const namaApp = t('app.nama') || t('umum.aplikasi') || 'Resto Barokah'

  return (
    <div
      className="layar-masuk-pelanggan"
      style={{
        maxWidth: '440px',
        width: '100%',
        margin: '0 auto',
        padding: '0 var(--s-3)',
      }}
    >
      <Kartu judul={namaApp}>
        <div style={{ textAlign: 'center', marginBottom: 'var(--s-5)' }}>
          <h2
            style={{
              fontSize: 'var(--t-6)',
              fontWeight: 700,
              margin: '0 0 var(--s-2) 0',
              color: 'var(--text)',
            }}
          >
            Masuk / Daftar Pelanggan
          </h2>
          <p
            style={{
              fontSize: 'var(--t-3)',
              color: 'var(--text-muted)',
              margin: 0,
              lineHeight: 1.5,
            }}
          >
            Dapatkan voucher diskon khusus, promo ulang tahun, dan simpan riwayat pesanan favorit Anda.
          </p>
        </div>

        {pesanGalat && (
          <div
            role="alert"
            style={{
              padding: 'var(--s-3)',
              borderRadius: 'var(--radius)',
              background: 'var(--surface-2)',
              border: '1px solid var(--danger)',
              borderLeft: '4px solid var(--danger)',
              color: 'var(--text)',
              fontSize: 'var(--t-3)',
              marginBottom: 'var(--s-4)',
            }}
          >
            {pesanGalat}
          </div>
        )}

        {pesanSukses && (
          <div
            role="status"
            style={{
              padding: 'var(--s-3)',
              borderRadius: 'var(--radius)',
              background: 'var(--surface-2)',
              border: '1px solid var(--success)',
              borderLeft: '4px solid var(--success)',
              color: 'var(--text)',
              fontSize: 'var(--t-3)',
              marginBottom: 'var(--s-4)',
            }}
          >
            {pesanSukses}
          </div>
        )}

        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}>
          {/* Tombol Masuk Google Utama */}
          <Tombol ragam="biasa" lebar onClick={tanganiGoogle} nonaktif={sedangGoogle}>
            <span
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 'var(--s-3)',
                width: '100%',
              }}
            >
              <img
                src="/logo-google.svg"
                alt=""
                style={{ width: '20px', height: '20px', flexShrink: 0 }}
              />
              <span style={{ fontWeight: 600 }}>
                {sedangGoogle ? 'Menghubungkan...' : 'Lanjut dengan Akun Google'}
              </span>
            </span>
          </Tombol>

          {/* Garis Pemisah Antara Google & Email */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              margin: 'var(--s-2) 0',
            }}
          >
            <div style={{ flex: 1, borderTop: '1px solid var(--border)' }} />
            <span
              style={{
                padding: '0 var(--s-3)',
                fontSize: 'var(--t-2)',
                color: 'var(--text-muted)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
              }}
            >
              atau gunakan email
            </span>
            <div style={{ flex: 1, borderTop: '1px solid var(--border)' }} />
          </div>

          {/* Form Magic Link Email */}
          <form
            onSubmit={tanganiKirimEmail}
            style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}
          >
            <KolomIsian
              label="Alamat Email Anda"
              jenis="email"
              contoh="nama@email.com"
              nilai={email}
              onUbah={setEmail}
              nonaktif={sedangKirimEmail}
              wajib
            />

            <Tombol
              ragam="utama"
              jenis="submit"
              lebar
              nonaktif={sedangKirimEmail || !email.trim()}
            >
              {sedangKirimEmail ? 'Mengirim...' : 'Kirim Tautan Masuk ke Email'}
            </Tombol>
          </form>

          {/* Persetujuan Privasi (Sesuai UU PDP & T1-40) */}
          <div
            style={{
              paddingTop: 'var(--s-3)',
              borderTop: '1px solid var(--border)',
              display: 'flex',
              alignItems: 'flex-start',
              gap: 'var(--s-2)',
            }}
          >
            <input
              type="checkbox"
              id="persetujuan-privasi"
              checked={setujuPrivasi}
              onChange={(e) => setSetujuPrivasi(e.target.checked)}
              style={{
                marginTop: '3px',
                width: '18px',
                height: '18px',
                cursor: 'pointer',
                accentColor: 'var(--primary)',
              }}
            />
            <label
              htmlFor="persetujuan-privasi"
              style={{
                fontSize: 'var(--t-2)',
                color: 'var(--text-muted)',
                lineHeight: 1.4,
                cursor: 'pointer',
              }}
            >
              Saya menyetujui data saya (nama & email) digunakan hanya untuk layanan resto sesuai{' '}
              <Tombol ragam="polos" onClick={onBukaKebijakanPrivasi}>
                <span
                  style={{
                    color: 'var(--primary)',
                    textDecoration: 'underline',
                    fontWeight: 600,
                  }}
                >
                  Kebijakan Privasi Resto
                </span>
              </Tombol>
              . Resto Barokah tidak membagikan data ke pihak ketiga.
            </label>
          </div>
        </div>
      </Kartu>
    </div>
  )
}
