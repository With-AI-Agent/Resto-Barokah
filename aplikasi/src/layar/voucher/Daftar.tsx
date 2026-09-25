import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KolomIsian } from '../../komponen/KolomIsian'
import { KomponenQr } from '../../komponen/KomponenQr'
import { rupiah, tanggalLokal } from '../../lib/format'
import { normalisasiEmail } from '../../lib/emailNormalisasi'

export interface KampanyeInfo {
  id: string
  nama: string
  deskripsi?: string
  jenis: 'persen' | 'nominal'
  nilai: number
  min_belanja: number
  maks_potongan?: number
  selesai: string
  nama_resto?: string
}

export interface VoucherKlaimHasil {
  kode: string
  nilai: number
  jenis: 'persen' | 'nominal'
  min_belanja: number
  maks_potongan?: number
  berlaku_sampai: string
  nama_pelanggan: string
  email_pelanggan: string
  telepon_pelanggan?: string
}

export interface DaftarProps {
  kampanye: KampanyeInfo
  onKlaimSukses?: (hasil: VoucherKlaimHasil) => void
  onMasukGoogle?: () => Promise<{ sukses?: boolean; berhasil?: boolean; pesan?: string }>
  onKirimEmail?: (email: string) => Promise<{ sukses: boolean; pesan?: string }>
  onBatal?: () => void
  onBukaKebijakanPrivasi?: () => void
  onLihatMenu?: () => void
}

export function Daftar({
  kampanye,
  onKlaimSukses,
  onMasukGoogle,
  onKirimEmail,
  onBatal,
  onBukaKebijakanPrivasi,
  onLihatMenu,
}: DaftarProps) {
  const [nama, setNama] = useState('')
  const [email, setEmail] = useState('')
  const [telepon, setTelepon] = useState('')
  const [alamat, setAlamat] = useState('')
  const [setujuPrivasi, setSetujuPrivasi] = useState(false)
  const [sedangProses, setSedangProses] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [voucherHasil, setVoucherHasil] = useState<VoucherKlaimHasil | null>(null)
  const [kodeTersalin, setKodeTersalin] = useState(false)

  const batasWaktuFormatted = (() => {
    try {
      return tanggalLokal(new Date(kampanye.selesai))
    } catch {
      return kampanye.selesai
    }
  })()

  const buatKodeVoucherAcak = () => {
    const kar = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    let acak = ''
    for (let i = 0; i < 6; i++) {
      acak += kar.charAt(Math.floor(Math.random() * kar.length))
    }
    return `BRK-${acak}`
  }

  const validasiDasar = () => {
    if (!nama.trim()) {
      setPesanGalat('Nama lengkap wajib diisi.')
      return false
    }
    if (!setujuPrivasi) {
      setPesanGalat('Mohon centang persetujuan kebijakan privasi data pelanggan.')
      return false
    }
    return true
  }

  const tanganiKlaimGoogle = async () => {
    setPesanGalat(null)
    if (!validasiDasar()) return

    setSedangProses(true)
    try {
      const hasil = onMasukGoogle ? await onMasukGoogle() : { sukses: true }
      const sukses = Boolean(hasil.sukses ?? hasil.berhasil)
      if (sukses) {
        const voucherBaru: VoucherKlaimHasil = {
          kode: buatKodeVoucherAcak(),
          nilai: kampanye.nilai,
          jenis: kampanye.jenis,
          min_belanja: kampanye.min_belanja,
          maks_potongan: kampanye.maks_potongan,
          berlaku_sampai: batasWaktuFormatted,
          nama_pelanggan: nama.trim(),
          email_pelanggan: email.trim() || 'google-user@gmail.com',
          telepon_pelanggan: telepon.trim() || undefined,
        }
        setVoucherHasil(voucherBaru)
        onKlaimSukses?.(voucherBaru)
      } else {
        setPesanGalat(hasil.pesan || 'Gagal masuk dengan akun Google. Silakan coba lagi.')
      }
    } catch {
      setPesanGalat('Terjadi kendala jaringan saat menghubungkan ke akun Google.')
    } finally {
      setSedangProses(false)
    }
  }

  const tanganiKlaimEmail = async () => {
    setPesanGalat(null)
    if (!validasiDasar()) return

    const validasi = normalisasiEmail(email)
    if (!validasi.sah) {
      setPesanGalat(
        validasi.pesan || 'Mohon masukkan alamat email yang sah untuk menerima voucher.',
      )
      return
    }

    setSedangProses(true)
    try {
      const emailBersih = validasi.email_normalisasi || email.trim()
      const hasil = onKirimEmail ? await onKirimEmail(emailBersih) : { sukses: true }
      if (hasil.sukses) {
        const voucherBaru: VoucherKlaimHasil = {
          kode: buatKodeVoucherAcak(),
          nilai: kampanye.nilai,
          jenis: kampanye.jenis,
          min_belanja: kampanye.min_belanja,
          maks_potongan: kampanye.maks_potongan,
          berlaku_sampai: batasWaktuFormatted,
          nama_pelanggan: nama.trim(),
          email_pelanggan: emailBersih,
          telepon_pelanggan: telepon.trim() || undefined,
        }
        setVoucherHasil(voucherBaru)
        setPesanSukses(`Tautan verifikasi dan kode voucher telah dikirimkan ke ${emailBersih}.`)
        onKlaimSukses?.(voucherBaru)
      } else {
        setPesanGalat(hasil.pesan || 'Gagal memproses pendaftaran email.')
      }
    } catch {
      setPesanGalat('Terjadi kendala jaringan saat mendaftarkan email.')
    } finally {
      setSedangProses(false)
    }
  }

  const salinKodeVoucher = async (kode: string) => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(kode)
      }
      setKodeTersalin(true)
      setTimeout(() => setKodeTersalin(false), 2500)
    } catch {
      setKodeTersalin(true)
      setTimeout(() => setKodeTersalin(false), 2500)
    }
  }

  // ==================== TAMPILAN JIKA KLAIM SUKSES ====================
  if (voucherHasil) {
    return (
      <div
        className="layar-klaim-sukses"
        style={{
          maxWidth: '460px',
          margin: '0 auto',
          padding: 'var(--s-4)',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-4)',
        }}
        data-testid="klaim-voucher-sukses"
      >
        <Kartu judul="🎉 Selamat! Voucher Berhasil Diklaim">
          <div
            style={{
              padding: 'var(--s-3)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              textAlign: 'center',
              gap: 'var(--s-3)',
            }}
          >
            <p style={{ fontSize: 'var(--t-2)', color: 'var(--text)', margin: 0 }}>
              Terima kasih, <strong>{voucherHasil.nama_pelanggan}</strong>! Simpan atau salin kode
              voucher di bawah ini untuk digunakan saat memesan di resto.
            </p>

            {/* Kartu Fisik Voucher */}
            <div
              className="kartu"
              style={{
                width: '100%',
                background: 'var(--surface-2)',
                border: '2px dashed var(--accent)',
                borderRadius: 'var(--radius-lg)',
                padding: 'var(--s-3)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 'var(--s-2)',
              }}
              data-testid="kartu-voucher-terbit"
            >
              <Lencana nada="accent">Voucher Diskon Resmi</Lencana>

              <div
                style={{
                  fontSize: 'var(--t-5)',
                  fontWeight: 900,
                  color: 'var(--accent)',
                  letterSpacing: '2px',
                  fontFamily: 'var(--font-mono, monospace)',
                  background: 'var(--surface)',
                  padding: 'var(--s-2) var(--s-4)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border)',
                }}
                data-testid="teks-kode-voucher"
              >
                {voucherHasil.kode}
              </div>

              <div
                style={{
                  fontSize: 'var(--t-3)',
                  fontWeight: 800,
                  color: 'var(--text)',
                }}
              >
                {voucherHasil.jenis === 'nominal'
                  ? `Potongan ${rupiah(voucherHasil.nilai)}`
                  : `Diskon ${voucherHasil.nilai}%`}
              </div>

              <div
                style={{
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Min. belanja {rupiah(voucherHasil.min_belanja)} • Berlaku s.d.{' '}
                {voucherHasil.berlaku_sampai}
              </div>

              <div style={{ marginTop: 'var(--s-2)', width: '100%' }}>
                <KomponenQr
                  url={voucherHasil.kode}
                  ukuran={150}
                  judul="Barcode Voucher"
                  keterangan="Tunjukkan ke kasir saat memesan di kasir"
                  bisaSalin={false}
                  bisaUnduh={false}
                />
              </div>
            </div>

            {/* Tombol Aksi Salin & Lihat Menu */}
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--s-2)',
                width: '100%',
              }}
            >
              <Tombol
                ragam={kodeTersalin ? 'biasa' : 'utama'}
                onClick={() => salinKodeVoucher(voucherHasil.kode)}
                lebar
                nama="Salin kode voucher pelanggan"
              >
                {kodeTersalin ? '✓ Kode Tersalin!' : '📋 Salin Kode Voucher'}
              </Tombol>

              {onLihatMenu && (
                <Tombol
                  ragam="biasa"
                  onClick={onLihatMenu}
                  lebar
                  nama="Lihat menu resto di katalog"
                >
                  📖 Intip Menu Lezat (Katalog)
                </Tombol>
              )}
            </div>
          </div>
        </Kartu>
      </div>
    )
  }

  // ==================== TAMPILAN FORMULIR PENDAFTARAN ====================
  return (
    <div
      className="layar-daftar-voucher"
      style={{
        maxWidth: '480px',
        margin: '0 auto',
        padding: 'var(--s-4)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--s-4)',
      }}
      data-testid="form-daftar-voucher"
    >
      <Kartu judul={`Klaim Voucher: ${kampanye.nama}`}>
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
          }}
        >
          {/* Ringkasan Penawaran */}
          <div
            style={{
              background: 'var(--surface-2)',
              padding: 'var(--s-3)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
            }}
          >
            <div
              style={{
                fontSize: 'var(--t-3)',
                fontWeight: 800,
                color: 'var(--accent)',
              }}
            >
              {kampanye.jenis === 'nominal'
                ? `Potongan Langsung ${rupiah(kampanye.nilai)}`
                : `Diskon Spesial ${kampanye.nilai}%`}
            </div>
            <div
              style={{
                fontSize: 'var(--t-1)',
                color: 'var(--text-muted)',
                marginTop: 'var(--s-1)',
              }}
            >
              Min. belanja {rupiah(kampanye.min_belanja)} • Berlaku s.d. {batasWaktuFormatted}
            </div>
          </div>

          {pesanGalat && (
            <div
              role="alert"
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                border: '1px solid var(--bahaya)',
                color: 'var(--bahaya)',
                borderRadius: 'var(--radius-md)',
                fontSize: 'var(--t-2)',
              }}
            >
              {pesanGalat}
            </div>
          )}

          {pesanSukses && (
            <div
              role="status"
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                border: '1px solid var(--sukses)',
                color: 'var(--sukses)',
                borderRadius: 'var(--radius-md)',
                fontSize: 'var(--t-2)',
              }}
            >
              {pesanSukses}
            </div>
          )}

          {/* Kolom Isian Identitas Pelanggan */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
            <KolomIsian
              label="Nama Lengkap Anda"
              nilai={nama}
              onUbah={setNama}
              contoh="Contoh: Rian Anggoro"
              nonaktif={sedangProses}
              wajib
            />

            <KolomIsian
              label="Alamat Email"
              jenis="email"
              nilai={email}
              onUbah={setEmail}
              contoh="nama@email.com"
              keterangan="Kode voucher akan dikirimkan ke email ini."
              nonaktif={sedangProses}
              wajib
            />

            <KolomIsian
              label="Nomor WhatsApp / HP (Opsional)"
              jenis="tel"
              nilai={telepon}
              onUbah={setTelepon}
              contoh="081234567890"
              keterangan="Opsional, untuk info promo spesial kedai."
              nonaktif={sedangProses}
            />

            <KolomIsian
              label="Alamat / Kota Domisili (Opsional)"
              nilai={alamat}
              onUbah={setAlamat}
              contoh="Contoh: Bandung"
              nonaktif={sedangProses}
            />

            {/* Kotak Centang Persetujuan Privasi Sesuai UU PDP */}
            <div
              style={{
                display: 'flex',
                alignItems: 'flex-start',
                gap: 'var(--s-2)',
                paddingTop: 'var(--s-1)',
              }}
            >
              <input
                type="checkbox"
                id="persetujuan-privasi-voucher"
                data-testid="centang-privasi-voucher"
                checked={setujuPrivasi}
                onChange={(e) => setSetujuPrivasi(e.target.checked)}
                disabled={sedangProses}
                style={{
                  marginTop: 'var(--s-1)',
                  cursor: 'pointer',
                  width: '18px',
                  height: '18px',
                }}
              />
              <label
                htmlFor="persetujuan-privasi-voucher"
                style={{
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                  cursor: 'pointer',
                  lineHeight: 1.4,
                }}
              >
                Saya menyetujui data nama dan kontak saya digunakan oleh{' '}
                <strong>{kampanye.nama_resto || 'Resto Barokah'}</strong> untuk penerbitan voucher
                sesuai{' '}
                <Tombol ragam="polos" onClick={onBukaKebijakanPrivasi}>
                  <u>Kebijakan Privasi Resto</u>
                </Tombol>
                . Data Anda aman dan tidak disebarluaskan.
              </label>
            </div>
          </div>

          {/* Pilihan Jalur Verifikasi */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-2)',
              marginTop: 'var(--s-2)',
            }}
          >
            {/* Jalur 1 (Utama): Google */}
            <Tombol
              ragam="utama"
              lebar
              onClick={tanganiKlaimGoogle}
              nonaktif={sedangProses}
              nama="Klaim voucher cepat dengan Google"
            >
              {sedangProses ? 'Memproses Klaim...' : '🚀 Klaim Cepat dengan Google'}
            </Tombol>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                margin: 'var(--s-1) 0',
                gap: 'var(--s-2)',
              }}
            >
              <div style={{ flex: 1, borderTop: '1px solid var(--border)' }} />
              <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                atau gunakan verifikasi email
              </span>
              <div style={{ flex: 1, borderTop: '1px solid var(--border)' }} />
            </div>

            {/* Jalur 2: Email */}
            <Tombol
              ragam="biasa"
              lebar
              onClick={tanganiKlaimEmail}
              nonaktif={sedangProses}
              nama="Klaim voucher lewat email"
            >
              ✉️ Kirim Kode ke Email
            </Tombol>

            {onBatal && (
              <Tombol ragam="polos" lebar onClick={onBatal} nama="Batal mendaftar voucher">
                Batal
              </Tombol>
            )}
          </div>

          {/* Pesan Bantuan: Fallback Didaftarkan Kasir (Mitigasi Risiko) */}
          <div
            style={{
              marginTop: 'var(--s-2)',
              padding: 'var(--s-2)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border)',
              fontSize: 'var(--t-1)',
              color: 'var(--text-muted)',
              textAlign: 'center',
            }}
            data-testid="bantuan-kasir-info"
          >
            💡 <strong>Tidak memiliki email atau kesulitan verifikasi?</strong> Jangan khawatir,
            Anda dapat langsung meminta kasir kami untuk mendaftarkan voucher Anda saat berkunjung
            ke kedai.
          </div>
        </div>
      </Kartu>
    </div>
  )
}
