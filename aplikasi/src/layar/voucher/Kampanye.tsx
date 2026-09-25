import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { rupiah, tanggalLokal } from '../../lib/format'
import { Daftar, type KampanyeInfo, type VoucherKlaimHasil } from './Daftar'

export interface KampanyeProps {
  kampanye?: KampanyeInfo & {
    tagline?: string
    banner_url?: string
    nama_pengundang?: string
    kode_referral?: string
    kuota?: number
    sisa_kuota?: number
  }
  onMasukGoogle?: () => Promise<{ sukses?: boolean; berhasil?: boolean; pesan?: string }>
  onKirimEmail?: (email: string) => Promise<{ sukses: boolean; pesan?: string }>
  onKlaimSukses?: (hasil: VoucherKlaimHasil) => void
  onBukaKatalog?: () => void
  onBukaKebijakanPrivasi?: () => void
}

const KAMPANYE_DEFAULT: KampanyeInfo & {
  tagline: string
  banner_url?: string
  nama_pengundang?: string
  kode_referral?: string
  kuota: number
  sisa_kuota: number
} = {
  id: 'kampanye-01',
  nama: 'Promo Sambut Sahabat Baru',
  deskripsi:
    'Nikmati santap lezat masakan nusantara dengan potongan harga istimewa untuk kunjungan pertama Anda di Resto Barokah!',
  jenis: 'nominal',
  nilai: 20000,
  min_belanja: 50000,
  selesai: new Date(Date.now() + 14 * 24 * 3600 * 1000).toISOString(),
  nama_resto: 'Resto Barokah',
  tagline: 'Cita Rasa Nusantara & Masakan Tradisional',
  nama_pengundang: 'Teman Anda',
  kode_referral: 'SAHABAT20',
  kuota: 100,
  sisa_kuota: 48,
}

export function Kampanye({
  kampanye = KAMPANYE_DEFAULT,
  onMasukGoogle,
  onKirimEmail,
  onKlaimSukses,
  onBukaKatalog,
  onBukaKebijakanPrivasi,
}: KampanyeProps) {
  const [modalDaftarBuka, setModalDaftarBuka] = useState(false)
  const [tersalin, setTersalin] = useState(false)
  const [voucherAktif, setVoucherAktif] = useState<VoucherKlaimHasil | null>(null)

  const batasWaktuFormatted = (() => {
    try {
      return tanggalLokal(new Date(kampanye.selesai))
    } catch {
      return kampanye.selesai
    }
  })()

  const tanganiSalinTautan = async () => {
    try {
      const url = typeof window !== 'undefined' ? window.location.href : 'https://resto-barokah.dev'
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

  const tanganiBagikanWa = () => {
    const url = typeof window !== 'undefined' ? window.location.href : 'https://resto-barokah.dev'
    const teksPesan = encodeURIComponent(
      `Yuk mampir ke ${kampanye.nama_resto || 'Resto Barokah'}! Ada voucher diskon ${kampanye.jenis === 'nominal' ? rupiah(kampanye.nilai) : `${kampanye.nilai}%`} untuk kamu. Klaim di sini: ${url}`,
    )
    if (typeof window !== 'undefined') {
      window.open(`https://api.whatsapp.com/send?text=${teksPesan}`, '_blank')
    }
  }

  const tanganiSelesaiDaftar = (hasil: VoucherKlaimHasil) => {
    setVoucherAktif(hasil)
    onKlaimSukses?.(hasil)
  }

  return (
    <div
      className="layar-kampanye"
      style={{
        maxWidth: '720px',
        margin: '0 auto',
        padding: 'var(--s-4)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--s-4)',
      }}
      data-testid="layar-kampanye"
    >
      {/* Banner / Header Hero Kampanye */}
      <div
        className="kartu"
        style={{
          background: 'var(--surface)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-lg)',
          overflow: 'hidden',
          boxShadow: 'var(--sh-2)',
        }}
      >
        {/* Dekorasi Visual Atas */}
        <div
          style={{
            background: 'var(--accent)',
            color: 'var(--surface)',
            padding: 'var(--s-4)',
            textAlign: 'center',
          }}
        >
          <div style={{ fontSize: '36px', marginBottom: 'var(--s-1)' }}>🎁</div>
          <h1
            style={{
              fontSize: 'var(--t-5)',
              fontWeight: 900,
              margin: '0 0 var(--s-1) 0',
              lineHeight: 1.2,
            }}
          >
            {kampanye.nama}
          </h1>
          <p
            style={{
              fontSize: 'var(--t-2)',
              margin: 0,
              opacity: 0.9,
            }}
          >
            {kampanye.nama_resto || 'Resto Barokah'} • {kampanye.tagline}
          </p>
        </div>

        <div
          style={{
            padding: 'var(--s-4)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
          }}
        >
          {kampanye.nama_pengundang && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 'var(--s-2)',
                background: 'var(--surface-2)',
                padding: 'var(--s-2) var(--s-3)',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
              }}
              data-testid="banner-pengundang"
            >
              <span>💌</span>
              <span style={{ fontSize: 'var(--t-2)', color: 'var(--text)' }}>
                Undangan eksklusif dari <strong>{kampanye.nama_pengundang}</strong>
              </span>
            </div>
          )}

          {/* Sorotan Nilai Voucher */}
          <div
            style={{
              textAlign: 'center',
              padding: 'var(--s-3)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '2px dashed var(--accent)',
            }}
          >
            <Lencana nada="accent">Voucher Sambutan</Lencana>
            <div
              style={{
                fontSize: 'var(--t-6, 32px)',
                fontWeight: 900,
                color: 'var(--accent)',
                marginTop: 'var(--s-1)',
              }}
              data-testid="nilai-voucher-promo"
            >
              {kampanye.jenis === 'nominal'
                ? `Potongan ${rupiah(kampanye.nilai)}`
                : `Diskon ${kampanye.nilai}%`}
            </div>
            <div
              style={{
                fontSize: 'var(--t-2)',
                color: 'var(--text-muted)',
                marginTop: 'var(--s-1)',
              }}
            >
              Min. belanja {rupiah(kampanye.min_belanja)} • Berlaku s.d. {batasWaktuFormatted}
            </div>
          </div>

          {kampanye.deskripsi && (
            <p
              style={{
                fontSize: 'var(--t-2)',
                color: 'var(--text)',
                lineHeight: 1.5,
                margin: 0,
                textAlign: 'center',
              }}
            >
              {kampanye.deskripsi}
            </p>
          )}

          {/* Sisa Kuota Promo */}
          {kampanye.kuota && kampanye.sisa_kuota !== undefined && (
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                fontSize: 'var(--t-1)',
                color: 'var(--text-muted)',
                padding: '0 var(--s-1)',
              }}
            >
              <span>Kuota Voucher Tersedia</span>
              <strong style={{ color: 'var(--accent)' }}>
                {kampanye.sisa_kuota} dari {kampanye.kuota} voucher
              </strong>
            </div>
          )}

          {/* Tombol Aksi Utama */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-2)',
              marginTop: 'var(--s-2)',
            }}
          >
            <Tombol
              ragam="utama"
              lebar
              onClick={() => setModalDaftarBuka(true)}
              nama="Daftar dan klaim voucher diskon sekarang"
            >
              🎁 Daftar & Klaim Voucher Diskon
            </Tombol>

            <div style={{ display: 'flex', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
              {onBukaKatalog && (
                <Tombol
                  ragam="biasa"
                  onClick={onBukaKatalog}
                  nama="Lihat daftar menu resto di katalog"
                >
                  📖 Intip Menu Lezat
                </Tombol>
              )}

              <Tombol
                ragam="biasa"
                onClick={tanganiBagikanWa}
                nama="Bagikan promo kampanye via WhatsApp"
              >
                💬 Bagikan ke WhatsApp
              </Tombol>

              <Tombol
                ragam="polos"
                onClick={tanganiSalinTautan}
                nama="Salin tautan kampanye undangan"
              >
                {tersalin ? '✓ Tautan Tersalin!' : '📋 Salin Tautan Promo'}
              </Tombol>
            </div>
          </div>
        </div>
      </div>

      {/* Syarat & Ketentuan Ramah Awam */}
      <Kartu judul="Syarat & Ketentuan Penggunaan Voucher">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-2)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
          }}
        >
          <div>
            1. <strong>Satu Akun Satu Voucher:</strong> Setiap pelanggan berhak mengklaim 1 (satu)
            voucher diskon untuk kampanye ini.
          </div>
          <div>
            2. <strong>Batas Minimum Belanja:</strong> Potongan harga berlaku untuk transaksi dengan
            total pesanan minimal {rupiah(kampanye.min_belanja)}.
          </div>
          <div>
            3. <strong>Mudah Ditukarkan:</strong> Tunjukkan kode voucher atau barcode langsung ke
            kasir saat melakukan pemesanan di resto.
          </div>
          <div>
            4. <strong>Masa Berlaku:</strong> Voucher dapat digunakan sampai dengan{' '}
            {batasWaktuFormatted}.
          </div>
          <div>
            5. <strong>Bantuan di Kedai:</strong> Apabila terkendala dalam pendaftaran mandiri, staf
            kasir kami siap membantu mendaftarkan voucher Anda secara langsung di kedai.
          </div>
        </div>
      </Kartu>

      {/* Modal / Formulir Pendaftaran */}
      {modalDaftarBuka && (
        <Lapis
          buka={modalDaftarBuka}
          onTutup={() => setModalDaftarBuka(false)}
          judul="Pendaftaran Pelanggan & Klaim Voucher"
        >
          <div style={{ padding: 'var(--s-2)' }}>
            <Daftar
              kampanye={kampanye}
              onKlaimSukses={(hasil) => {
                tanganiSelesaiDaftar(hasil)
                // modal tetap dibuka agar pelanggan melihat hasil voucher terbit
              }}
              onMasukGoogle={onMasukGoogle}
              onKirimEmail={onKirimEmail}
              onBatal={() => setModalDaftarBuka(false)}
              onBukaKebijakanPrivasi={onBukaKebijakanPrivasi}
              onLihatMenu={() => {
                setModalDaftarBuka(false)
                onBukaKatalog?.()
              }}
            />
          </div>
        </Lapis>
      )}

      {/* Bagian Voucher Jika Sudah Ada yang Terklaim di Sesi Ini */}
      {voucherAktif && !modalDaftarBuka && (
        <Kartu judul="Voucher Anda yang Siap Dipakai">
          <div
            style={{
              padding: 'var(--s-3)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 'var(--s-2)',
              flexWrap: 'wrap',
            }}
          >
            <div>
              <div
                style={{
                  fontSize: 'var(--t-3)',
                  fontWeight: 900,
                  color: 'var(--accent)',
                  fontFamily: 'var(--font-mono, monospace)',
                }}
              >
                {voucherAktif.kode}
              </div>
              <div style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                Berlaku s.d. {voucherAktif.berlaku_sampai}
              </div>
            </div>
            <Tombol
              ragam="utama"
              onClick={() => setModalDaftarBuka(true)}
              nama="Buka kartu voucher saya"
            >
              Lihat Barcode Voucher
            </Tombol>
          </div>
        </Kartu>
      )}
    </div>
  )
}
