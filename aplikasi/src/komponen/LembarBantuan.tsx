import { useState, useEffect } from 'react'
import { DAFTAR_BANTUAN, type BantuanLayar } from '../kontrak/bantuan'
import { Tombol } from './Tombol'
import { Lencana } from './Lencana'
import { useBahasa } from '../bahasa'

interface LembarBantuanProps {
  idLayar: string
  tampilkanOtomatisPertamaKali?: boolean
}

const KUNCI_PREF_BANTUAN = 'resto_barokah_bantuan_dilihat_'

export function LembarBantuan({
  idLayar,
  tampilkanOtomatisPertamaKali = false,
}: LembarBantuanProps) {
  const { t } = useBahasa()
  const bantuan: BantuanLayar | undefined = DAFTAR_BANTUAN[idLayar]
  const [buka, setBuka] = useState(false)
  const [janganTampilLagi, setJanganTampilLagi] = useState(false)

  useEffect(() => {
    if (tampilkanOtomatisPertamaKali) {
      try {
        const sudah = localStorage.getItem(`${KUNCI_PREF_BANTUAN}${idLayar}`)
        if (!sudah) {
          setBuka(true)
        }
      } catch {
        // Abaikan bila storage gagal
      }
    }
  }, [idLayar, tampilkanOtomatisPertamaKali])

  const tutup = () => {
    if (janganTampilLagi) {
      try {
        localStorage.setItem(`${KUNCI_PREF_BANTUAN}${idLayar}`, 'true')
      } catch {
        // Abaikan bila storage gagal
      }
    }
    setBuka(false)
  }

  const cetakPanduan = () => {
    window.print()
  }

  if (!bantuan) {
    return null
  }

  return (
    <>
      <button
        type="button"
        className="btn btn-sm btn-bantuan"
        onClick={() => setBuka(true)}
        aria-label={`Bantuan ${bantuan.judul}`}
        title="Bantuan cepat layar ini (?)"
        data-testid={`tombol-bantuan-${idLayar}`}
        style={{
          minWidth: '38px',
          height: '38px',
          borderRadius: '50%',
          display: 'inline-flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontWeight: 'bold',
          cursor: 'pointer',
        }}
      >
        ?
      </button>

      {buka && (
        <div
          className="lapis-latar"
          role="dialog"
          aria-modal="true"
          aria-labelledby={`judul-bantuan-${idLayar}`}
          data-testid={`dialog-bantuan-${idLayar}`}
        >
          <div className="lapis-panel" style={{ maxWidth: '640px' }}>
            <div className="lapis-kepala">
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
                <span
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: 'var(--accent)',
                    color: 'var(--surface)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 'bold',
                  }}
                >
                  ?
                </span>
                <h2 id={`judul-bantuan-${idLayar}`} className="lapis-judul">
                  {bantuan.judul}
                </h2>
              </div>
              <Tombol ragam="polos" onClick={tutup} nama="Tutup Bantuan">
                ✕
              </Tombol>
            </div>

            <div className="lapis-isi">
              <p className="aksen" style={{ margin: '0 0 var(--s-2) 0' }}>
                {bantuan.ringkasan}
              </p>

              <div>
                <strong style={{ fontSize: 'var(--t-5)' }}>Langkah Penggunaan:</strong>
                <ol style={{ paddingInlineStart: 'var(--s-5)', margin: 'var(--s-2) 0' }}>
                  {bantuan.langkah.map((l, idx) => (
                    <li key={idx} style={{ marginBottom: 'var(--s-2)' }}>
                      {l}
                    </li>
                  ))}
                </ol>
              </div>

              <div
                style={{
                  padding: 'var(--s-3)',
                  backgroundColor: 'var(--surface-2)',
                  borderInlineStart: '4px solid var(--accent)',
                  borderRadius: 'var(--radius)',
                  marginTop: 'var(--s-2)',
                }}
              >
                <strong style={{ color: 'var(--text)' }}>Bila Terjadi Kendala / Macet:</strong>
                <p style={{ margin: 'var(--s-1) 0 0 0', fontSize: 'var(--t-4)' }}>
                  {bantuan.kalauMacet}
                </p>
              </div>

              <div style={{ marginTop: 'var(--s-3)' }}>
                <small className="muted">Peran yang memiliki akses ke laman ini:</small>
                <div
                  style={{
                    display: 'flex',
                    flexWrap: 'wrap',
                    gap: 'var(--s-1)',
                    marginTop: 'var(--s-1)',
                  }}
                >
                  {bantuan.peranBoleh.map((peran) => (
                    <Lencana key={peran} nada="netral">
                      {peran}
                    </Lencana>
                  ))}
                </div>
              </div>

              <div
                style={{
                  marginTop: 'var(--s-3)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--s-2)',
                }}
              >
                <input
                  type="checkbox"
                  id={`pref-tampil-${idLayar}`}
                  checked={janganTampilLagi}
                  onChange={(e) => setJanganTampilLagi(e.target.checked)}
                />
                <label
                  htmlFor={`pref-tampil-${idLayar}`}
                  style={{ fontSize: 'var(--t-3)', cursor: 'pointer' }}
                >
                  Jangan tampilkan panduan ini secara otomatis lagi
                </label>
              </div>
            </div>

            <div className="lapis-kaki">
              <Tombol ragam="biasa" onClick={cetakPanduan}>
                Cetak Lembar Panduan
              </Tombol>
              <Tombol onClick={tutup}>{t('umum.tutup')}</Tombol>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
