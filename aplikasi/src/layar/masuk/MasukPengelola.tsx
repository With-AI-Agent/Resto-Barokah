import React, { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { formatPesanError } from '../../lib/pesan'
import { useBahasa } from '../../bahasa'

export interface MasukPengelolaProps {
  onMasukKataSandi: (
    email: string,
    kataSandi: string,
    kodeTotp?: string
  ) => Promise<{
    sukses: boolean
    butuhTotp?: boolean
    perluBootstrap?: boolean
    kodeGalat?: string
    pesan?: string
  }>
  onMasukSukses?: () => void
  onBeralihKeStaf?: () => void
  onLupaSandi?: () => void
}

export function MasukPengelola({
  onMasukKataSandi,
  onMasukSukses,
  onBeralihKeStaf,
  onLupaSandi,
}: MasukPengelolaProps) {
  const { t } = useBahasa()
  const [email, setEmail] = useState('')
  const [kataSandi, setKataSandi] = useState('')
  const [kodeTotp, setKodeTotp] = useState('')
  const [tahapTotp, setTahapTotp] = useState(false)
  const [sedangMemproses, setSedangMemproses] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<{ judul: string; pesan: string; tindakan: string; kode: string } | null>(null)

  const tanganiSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email.trim() || !kataSandi.trim()) return

    if (tahapTotp && kodeTotp.length !== 6) {
      setPesanGalat({
        kode: 'SEC-401',
        judul: 'Kode TOTP Tidak Lengkap',
        pesan: 'Masukkan 6 angka kode autentikator dari aplikasi Anda.',
        tindakan: 'Buka aplikasi Google Authenticator atau aplikasi sejenis.',
      })
      return
    }

    setSedangMemproses(true)
    setPesanGalat(null)
    try {
      const hasil = await onMasukKataSandi(email.trim(), kataSandi, tahapTotp ? kodeTotp : undefined)
      if (hasil.sukses) {
        onMasukSukses?.()
      } else if (hasil.butuhTotp) {
        setTahapTotp(true)
      } else {
        const galat = formatPesanError(hasil.kodeGalat ?? 'AUTENTIKASI_GAGAL')
        setPesanGalat(galat)
      }
    } catch {
      setPesanGalat(formatPesanError('JARINGAN_TERPUTUS'))
    } finally {
      setSedangMemproses(false)
    }
  }

  return (
    <div className="layar-masuk-pengelola max-w-md mx-auto p-4 min-h-[70vh] flex flex-col justify-center">
      <Kartu judul={t('app.nama') || 'Resto Barokah'}>
        <div className="mb-4">
          <h3 className="text-xl font-bold text-neutral-800">
            {tahapTotp ? 'Verifikasi Dua Langkah (TOTP)' : 'Masuk Owner / Admin'}
          </h3>
          <p className="text-xs text-neutral-500 mt-1">
            {tahapTotp
              ? 'Masukkan 6 angka kode keamanan dari aplikasi autentikator Anda.'
              : 'Gunakan email dan kata sandi akun pengelola resto Anda.'}
          </p>
        </div>

        {pesanGalat && (
          <div role="alert" className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800 mb-4">
            <div className="font-semibold mb-0.5">{pesanGalat.judul}</div>
            <div className="text-xs text-red-600 mb-1">{pesanGalat.pesan}</div>
            <div className="text-xs text-neutral-600 mb-1">{pesanGalat.tindakan}</div>
            <div className="text-[11px] font-mono text-neutral-500">Kode: {pesanGalat.kode}</div>
          </div>
        )}

        <form onSubmit={tanganiSubmit} className="space-y-4">
          {!tahapTotp ? (
            <>
              <KolomIsian
                label="Alamat Email Pengelola"
                jenis="email"
                contoh="owner@barokah.id"
                nilai={email}
                onUbah={setEmail}
                nonaktif={sedangMemproses}
                wajib
              />

              <KolomIsian
                label="Kata Sandi"
                jenis="password"
                contoh="••••••••"
                nilai={kataSandi}
                onUbah={setKataSandi}
                nonaktif={sedangMemproses}
                wajib
              />
            </>
          ) : (
            <KolomIsian
              label="Kode Keamanan 6 Digit (Aplikasi TOTP)"
              contoh="Contoh: 123456"
              nilai={kodeTotp}
              onUbah={(v) => setKodeTotp(v.replace(/\D/g, '').slice(0, 6))}
              nonaktif={sedangMemproses}
              wajib
            />
          )}

          <Tombol
            ragam="utama"
            jenis="submit"
            lebar
            nonaktif={sedangMemproses || !email || !kataSandi || (tahapTotp && kodeTotp.length !== 6)}
          >
            {sedangMemproses
              ? 'Memverifikasi...'
              : tahapTotp
              ? 'Verifikasi & Masuk'
              : 'Masuk sebagai Pengelola'}
          </Tombol>

          {tahapTotp && (
            <div className="text-center">
              <button
                type="button"
                onClick={() => {
                  setTahapTotp(false)
                  setKodeTotp('')
                  setPesanGalat(null)
                }}
                className="text-xs text-neutral-600 hover:text-neutral-900 underline"
              >
                Kembali ke Form Kata Sandi
              </button>
            </div>
          )}

          {!tahapTotp && onLupaSandi && (
            <div className="text-center">
              <button
                type="button"
                onClick={onLupaSandi}
                className="text-xs text-neutral-500 hover:text-neutral-800 underline"
              >
                Lupa kata sandi pengelola?
              </button>
            </div>
          )}
        </form>

        {onBeralihKeStaf && (
          <div className="mt-6 pt-4 border-t border-neutral-200 text-center">
            <button
              type="button"
              onClick={onBeralihKeStaf}
              className="text-sm text-emerald-700 font-medium hover:text-emerald-800"
            >
              ← Masuk sebagai Pegawai (PIN 6 Digit)
            </button>
          </div>
        )}
      </Kartu>
    </div>
  )
}
