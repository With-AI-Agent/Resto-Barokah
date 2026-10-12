import { useEffect, useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { KartuVoucher } from './KartuVoucher'
import { rupiah, tanggalLokal } from '../../lib/format'
import { normalisasiEmail } from '../../lib/emailNormalisasi'
import {
  klaimVoucherDiPeladen,
  ambilKlaimTunda,
  hapusKlaimTunda,
  simpanKlaimTunda,
  type HasilKlaimPeladen,
  type KlaimPeladenArg,
} from '../../lib/voucher'

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
  penyewaId?: string
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
  onKlaimPeladen?: (arg: KlaimPeladenArg) => Promise<HasilKlaimPeladen>
  onBatal?: () => void
  onBukaKebijakanPrivasi?: () => void
  onLihatMenu?: () => void
}

export function Daftar({
  kampanye,
  onKlaimSukses,
  onMasukGoogle,
  onKirimEmail,
  onKlaimPeladen,
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
  // Pesan jujur "menunggu verifikasi" (PMB1-F-032): voucher TIDAK terbit sebelum
  // peladen memverifikasi identitas dan menerbitkan kode dari RPC daftar_voucher.
  const [menungguVerifikasi, setMenungguVerifikasi] = useState<string | null>(null)

  const batasWaktuFormatted = (() => {
    try {
      return tanggalLokal(new Date(kampanye.selesai))
    } catch {
      return kampanye.selesai
    }
  })()

  const buatKlaimTunda = (caraMasuk: 'google' | 'email', emailDipakai: string): void => {
    simpanKlaimTunda({
      penyewaId: kampanye.penyewaId ?? null,
      kampanyeId: kampanye.id,
      nama: nama.trim(),
      email: emailDipakai,
      telepon: telepon.trim() || undefined,
      alamat: alamat.trim() || undefined,
      setujuPrivasi: true,
      caraMasuk,
      disimpanPada: new Date().toISOString(),
    })
  }

  // PMB1-F-032: kode voucher hanya dari peladen. Setelah verifikasi selesai
  // (pengguna kembali dengan sesi hidup), klaim tunda diselesaikan lewat RPC
  // `daftar_voucher` dan kartu voucher menampilkan kode hasil peladen.
  useEffect(() => {
    const tunda = ambilKlaimTunda()
    if (!tunda || tunda.kampanyeId !== kampanye.id) return
    let hidup = true
    void (async () => {
      let hasil: HasilKlaimPeladen
      try {
        hasil = await (onKlaimPeladen ?? klaimVoucherDiPeladen)({
          penyewaId: tunda.penyewaId,
          kampanyeId: tunda.kampanyeId,
          nama: tunda.nama,
          email: tunda.email,
          telepon: tunda.telepon,
          alamat: tunda.alamat,
          setujuPrivasi: true,
          caraMasuk: tunda.caraMasuk,
        })
      } catch {
        return // jaringan gagal: klaim tunda dipertahankan untuk kunjungan berikutnya
      }
      if (!hidup) return
      const kodePeladen = hasil.data?.kode_voucher
      const selesaiTuntas =
        (hasil.berhasil || hasil.kode === 'VOUCHER_SUDAH_DIKLAIM') && Boolean(kodePeladen)
      if (!selesaiTuntas) return // VERIFIKASI_WAJIB dll: tunggu, jangan tampilkan kartu
      hapusKlaimTunda()
      const d = hasil.data ?? {}
      const voucherBaru: VoucherKlaimHasil = {
        kode: kodePeladen ?? '',
        nilai: d.nilai ?? kampanye.nilai,
        jenis: d.jenis ?? kampanye.jenis,
        min_belanja: d.min_belanja ?? kampanye.min_belanja,
        maks_potongan: d.maks_potongan ?? kampanye.maks_potongan,
        berlaku_sampai: d.berlaku_sampai ?? kampanye.selesai,
        nama_pelanggan: d.nama_pelanggan ?? tunda.nama,
        email_pelanggan: tunda.email,
      }
      setVoucherHasil(voucherBaru)
      setMenungguVerifikasi(null)
      onKlaimSukses?.(voucherBaru)
    })()
    return () => {
      hidup = false
    }
    // Sengaja hanya sekali saat layar dibuka: klaim tunda dibaca dari localStorage.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

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
        // PMB1-F-032: proses masuk Google baru DIMULAI (browser akan diarahkan).
        // Kode voucher tidak boleh dibuat di klien — klaim disimpan sebagai tunda
        // dan diterbitkan peladen setelah verifikasi selesai.
        buatKlaimTunda('google', email.trim())
        setPesanSukses(null)
        setMenungguVerifikasi(
          'Anda sedang diarahkan ke Google untuk verifikasi. Setelah verifikasi selesai dan Anda kembali ke halaman ini, voucher diterbitkan otomatis oleh peladen — kode voucher tidak pernah dibuat di perangkat Anda.',
        )
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
        // PMB1-F-032: tautan verifikasi baru DIKIRIM — voucher belum sah.
        // Klaim disimpan sebagai tunda; peladen menerbitkan kode setelah tautan
        // dibuka dan sesi terverifikasi hidup.
        buatKlaimTunda('email', emailBersih)
        setPesanSukses(null)
        setMenungguVerifikasi(
          `Tautan verifikasi telah dikirim ke ${emailBersih}. Buka tautan itu di perangkat ini; setelah verifikasi selesai, voucher diterbitkan otomatis oleh peladen. Kode voucher baru sah setelah verifikasi — bukan sebelumnya.`,
        )
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

            {/* Kartu Fisik Voucher Terbit (T8-08) */}
            <div style={{ width: '100%' }} data-testid="kartu-voucher-terbit">
              <KartuVoucher
                voucher={{
                  kode: voucherHasil.kode,
                  nama_pelanggan: voucherHasil.nama_pelanggan,
                  nama_kampanye: kampanye.nama,
                  nama_resto: kampanye.nama_resto,
                  nilai: voucherHasil.nilai,
                  jenis: voucherHasil.jenis,
                  min_belanja: voucherHasil.min_belanja,
                  maks_potongan: voucherHasil.maks_potongan,
                  berlaku_sampai: voucherHasil.berlaku_sampai,
                  status: 'aktif',
                }}
                onLihatMenu={onLihatMenu}
                onSalin={salinKodeVoucher}
              />
            </div>

            {/* Tombol Aksi Salin Tambahan & Lihat Menu */}
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

          {/* PMB1-F-032: kartu "menunggu verifikasi" — jujur bahwa voucher BELUM terbit */}
          {menungguVerifikasi && (
            <div
              role="status"
              data-testid="menunggu-verifikasi"
              style={{
                padding: 'var(--s-3)',
                background: 'var(--surface-2)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-md)',
                fontSize: 'var(--t-2)',
              }}
            >
              <strong>Menunggu verifikasi…</strong>
              <div style={{ marginTop: 'var(--s-1)' }}>{menungguVerifikasi}</div>
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
