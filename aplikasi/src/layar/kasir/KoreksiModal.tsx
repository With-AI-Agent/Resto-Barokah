/**
 * KoreksiModal — Modal Perbaikan Modal Awal Shift Kasir dengan Izin Atasan (T7-06).
 *
 * Mengikuti PRD M7 (kasus tepi), TECH_SPEC §4.3 & §9 ART-6:
 *  - Mengoreksi salah isi modal awal kasir tanpa menghapus data (append-only audit).
 *  - Wajib persetujuan atasan (Owner / Admin Cabang) dengan verifikasi PIN.
 *  - Wajib alasan koreksi (non-kosong).
 *  - Modal awal baru tidak boleh sama dengan modal saat ini, dan tidak boleh negatif.
 *  - Komponen murni antarmuka: bebas tombol liar (peta-ui.py Aturan 7).
 */
import { useState, useId } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export interface AtasanPenyetuju {
  id: string
  nama: string
  peran?: string
}

export interface KoreksiModalInput {
  shiftId: string
  modalAwalBaru: number
  alasan: string
  disetujuiOleh: string
  pinAtasan: string
  kunciIdempoten?: string
}

export interface HasilKoreksiModal {
  sukses: boolean
  pesan?: string
  data?: {
    id: string
    shiftId: string
    modalAwalSebelumnya: number
    modalAwalBaru: number
    selisih: number
    alasan: string
    diajukanOleh: string
    disetujuiOleh: string
    dibuatPada: string
  }
}

export interface KoreksiModalProps {
  shiftId: string
  modalAwalSaatIni: number
  daftarAtasan?: AtasanPenyetuju[]
  sedangKirim?: boolean
  pesanGalat?: string | null
  onSimpanKoreksi: (masukan: KoreksiModalInput) => Promise<HasilKoreksiModal>
  onTutup?: () => void
  onBatal?: () => void
}

export function KoreksiModal({
  shiftId,
  modalAwalSaatIni,
  daftarAtasan = [],
  sedangKirim: sedangKirimProp = false,
  pesanGalat = null,
  onSimpanKoreksi,
  onTutup,
  onBatal,
}: KoreksiModalProps) {
  const { t } = useBahasa()
  const atasanSelectId = useId()

  const [modalBaruTeks, setModalBaruTeks] = useState('')
  const [alasan, setAlasan] = useState('')
  const [atasanId, setAtasanId] = useState(daftarAtasan[0]?.id || '')
  const [pinAtasan, setPinAtasan] = useState('')
  const [memproses, setMemproses] = useState(false)
  const [pesan, setPesan] = useState<{ teks: string; tipe: 'sukses' | 'galat' } | null>(
    pesanGalat ? { teks: pesanGalat, tipe: 'galat' } : null,
  )

  const modalBaruNominal =
    modalBaruTeks.trim() === '' ? 0 : Number(modalBaruTeks.replace(/\D/g, ''))
  const selisih = modalBaruNominal - modalAwalSaatIni
  const modalBerubah = modalBaruTeks.trim() !== '' && modalBaruNominal !== modalAwalSaatIni
  const alasanValid = alasan.trim().length > 0
  const pinValid = pinAtasan.trim().length >= 4
  const atasanValid = atasanId.trim().length > 0
  const sedangProses = sedangKirimProp || memproses

  const bolehSimpan =
    modalBerubah && modalBaruNominal >= 0 && alasanValid && atasanValid && pinValid && !sedangProses

  const tanganiKoreksi = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    if (!bolehSimpan) return

    setMemproses(true)
    setPesan(null)

    try {
      const res = await onSimpanKoreksi({
        shiftId,
        modalAwalBaru: modalBaruNominal,
        alasan: alasan.trim(),
        disetujuiOleh: atasanId,
        pinAtasan: pinAtasan.trim(),
      })

      if (res.sukses) {
        setPesan({
          teks: res.pesan || t('kasir.sukses_koreksi_modal'),
          tipe: 'sukses',
        })
        setPinAtasan('')
        if (onTutup) {
          setTimeout(onTutup, 900)
        }
      } else {
        setPesan({
          teks: res.pesan || 'Koreksi modal awal gagal diproses.',
          tipe: 'galat',
        })
      }
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
      setPesan({ teks: errorMsg, tipe: 'galat' })
    } finally {
      setMemproses(false)
    }
  }

  return (
    <div className="koreksi-modal" data-testid="koreksi-modal">
      <div className="koreksi-modal__petunjuk">
        <p>{t('kasir.koreksi_modal_petunjuk')}</p>
      </div>

      <div
        className="koreksi-modal__ringkasan"
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: '0.75rem',
          marginBottom: '1rem',
          padding: '0.75rem',
          background: '#f8fafc',
          borderRadius: '0.5rem',
        }}
      >
        <div>
          <span style={{ fontSize: '0.85rem', color: '#64748b' }}>
            {t('kasir.modal_awal_saat_ini')}
          </span>
          <div style={{ fontWeight: 600, fontSize: '1.1rem' }} data-testid="modal-awal-saat-ini">
            {rupiah(modalAwalSaatIni)}
          </div>
        </div>
        <div>
          <span style={{ fontSize: '0.85rem', color: '#64748b' }}>
            {t('kasir.selisih_koreksi')}
          </span>
          <div
            style={{
              fontWeight: 600,
              fontSize: '1.1rem',
              color: selisih > 0 ? '#16a34a' : selisih < 0 ? '#dc2626' : '#64748b',
            }}
            data-testid="selisih-koreksi"
          >
            {selisih > 0 ? `+${rupiah(selisih)}` : rupiah(selisih)}
          </div>
        </div>
      </div>

      <form onSubmit={tanganiKoreksi} className="koreksi-modal__form">
        <div style={{ marginBottom: '0.75rem' }}>
          <KolomIsian
            label={t('kasir.modal_awal_baru')}
            nilai={modalBaruTeks}
            onUbah={setModalBaruTeks}
            contoh="Contoh: 150000"
            wajib
            data-testid="input-modal-baru"
          />
        </div>

        <div style={{ marginBottom: '0.75rem' }}>
          <KolomIsian
            label={t('kasir.alasan_koreksi_modal')}
            nilai={alasan}
            onUbah={setAlasan}
            contoh={t('kasir.alasan_koreksi_placeholder')}
            wajib
            data-testid="input-alasan-koreksi"
          />
        </div>

        <div style={{ marginBottom: '0.75rem' }}>
          <label
            htmlFor={atasanSelectId}
            style={{
              display: 'block',
              fontSize: '0.875rem',
              fontWeight: 500,
              marginBottom: '0.25rem',
            }}
          >
            {t('kasir.penyetuju_atasan')} *
          </label>
          <select
            id={atasanSelectId}
            value={atasanId}
            onChange={(e) => setAtasanId(e.target.value)}
            disabled={sedangProses}
            style={{
              width: '100%',
              padding: '0.5rem',
              borderRadius: '0.375rem',
              border: '1px solid #cbd5e1',
            }}
            data-testid="select-atasan"
          >
            {daftarAtasan.length === 0 ? (
              <option value="">-- {t('kasir.pilih_atasan')} --</option>
            ) : (
              daftarAtasan.map((atasan) => (
                <option key={atasan.id} value={atasan.id}>
                  {atasan.nama} {atasan.peran ? `(${atasan.peran})` : ''}
                </option>
              ))
            )}
          </select>
        </div>

        <div style={{ marginBottom: '1rem' }}>
          <KolomIsian
            label={t('kasir.pin_atasan')}
            jenis="password"
            nilai={pinAtasan}
            onUbah={setPinAtasan}
            contoh="6 digit PIN"
            keterangan={t('kasir.pin_atasan_petunjuk')}
            wajib
            data-testid="input-pin-atasan"
          />
        </div>

        {pesan && (
          <div
            style={{
              padding: '0.75rem',
              borderRadius: '0.375rem',
              marginBottom: '1rem',
              background: pesan.tipe === 'sukses' ? '#dcfce7' : '#fee2e2',
              color: pesan.tipe === 'sukses' ? '#166534' : '#991b1b',
              fontSize: '0.875rem',
            }}
            data-testid="pesan-koreksi"
          >
            {pesan.teks}
          </div>
        )}

        <div
          style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end', marginTop: '1rem' }}
        >
          <Tombol
            ragam="biasa"
            onClick={onBatal || onTutup}
            nonaktif={sedangProses}
            data-testid="tombol-batal-koreksi"
          >
            Batal
          </Tombol>
          <Tombol
            ragam="utama"
            onClick={tanganiKoreksi}
            nonaktif={!bolehSimpan}
            data-testid="tombol-simpan-koreksi"
          >
            {sedangProses ? 'Menyimpan...' : t('kasir.simpan_koreksi_modal')}
          </Tombol>
        </div>
      </form>
    </div>
  )
}
