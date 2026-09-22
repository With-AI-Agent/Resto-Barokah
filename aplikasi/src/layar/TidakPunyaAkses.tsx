import React, { useState } from 'react'
import { useBahasa } from '../bahasa'
import { Kartu } from '../komponen/Kartu'
import { Tombol } from '../komponen/Tombol'
import { formatPesanError } from '../lib/pesan'

export interface TidakPunyaAksesProps {
  kodeError?: string
  pesanKustom?: string
  onKembali?: () => void
}

export const TidakPunyaAkses: React.FC<TidakPunyaAksesProps> = ({
  kodeError = 'AKSES_TERLARANG',
  pesanKustom,
  onKembali,
}) => {
  const { t } = useBahasa()
  const [bantuanBuka, setBantuanBuka] = useState(false)
  const pesan = formatPesanError(kodeError)

  return (
    <div
      style={{
        minHeight: '70vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 'var(--s-4)',
      }}
    >
      <div style={{ maxWidth: '480px', width: '100%' }}>
        <Kartu judul={`[${pesan.kode}] ${pesan.judul}`}>
          <p className="small muted" style={{ marginTop: 0, marginBottom: 'var(--s-3)' }}>
            {pesanKustom || pesan.pesan}
          </p>
          <div
            style={{
              padding: 'var(--s-3)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius)',
              borderLeft: '4px solid var(--peringatan)',
              marginBottom: 'var(--s-4)',
            }}
          >
            <div style={{ fontSize: 'var(--t-3)', fontWeight: 600, color: 'var(--teks-utama)' }}>
              Langkah Selanjutnya:
            </div>
            <div
              style={{
                fontSize: 'var(--t-3)',
                color: 'var(--teks-redup)',
                marginTop: 'var(--s-1)',
              }}
            >
              👉 {pesan.tindakan}
            </div>
          </div>

          {bantuanBuka && (
            <div
              style={{
                padding: 'var(--s-3)',
                background: 'var(--latar-utama)',
                borderRadius: 'var(--sudut-sedang)',
                marginBottom: 'var(--s-4)',
                border: '1px solid var(--b-netral)',
              }}
            >
              <div
                style={{ fontWeight: 'bold', fontSize: 'var(--t-4)', marginBottom: 'var(--s-2)' }}
              >
                Bantuan Hak Akses
              </div>
              <ul
                style={{
                  margin: 0,
                  paddingLeft: 'var(--s-4)',
                  fontSize: 'var(--t-3)',
                  color: 'var(--teks-utama)',
                }}
              >
                <li>
                  Setiap akun memiliki peran khusus (kasir, dapur, pelayan, admin cabang, owner).
                </li>
                <li>
                  Jika ditugaskan ke bagian baru, minta Owner untuk menyesuaikan peran akun Anda.
                </li>
                <li>Kembali ke halaman utama untuk melihat menu yang tersedia untuk peran Anda.</li>
              </ul>
            </div>
          )}

          <div style={{ display: 'flex', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
            {onKembali && (
              <Tombol ragam="utama" onClick={onKembali}>
                {t('kembali')} ke Halaman Utama
              </Tombol>
            )}
            <Tombol ragam="biasa" onClick={() => setBantuanBuka(!bantuanBuka)}>
              {bantuanBuka ? 'Tutup Bantuan' : t('bantuan')}
            </Tombol>
          </div>
        </Kartu>
      </div>
    </div>
  )
}
