import React, { useState } from 'react'
import { Tombol } from './Tombol'
import { useBahasa } from '../bahasa'

export interface ShiftAktifInfo {
  id: string
  cabangId?: string
  dibukaPada?: string | Date
  namaKasir?: string
  modalAwal?: number
}

export interface PengingatShiftProps {
  shiftAktif: ShiftAktifInfo | null
  jamTutup?: string // e.g. "22:00"
  waktuSekarang?: Date // for deterministic testing
  onTutupKas: () => void
  onAbaikan?: () => void
}

export type TingkatPengingatShift =
  'melewati_tengah_malam' | 'lewat_jam_tutup' | 'durasi_panjang' | 'mendekati_tutup' | null

export const PengingatShift: React.FC<PengingatShiftProps> = ({
  shiftAktif,
  jamTutup = '22:00',
  waktuSekarang,
  onTutupKas,
  onAbaikan,
}) => {
  const { t } = useBahasa()
  const [diabaikan, setDiabaikan] = useState(false)

  if (!shiftAktif) {
    return null
  }

  const sekarang = waktuSekarang || new Date()
  const dibuka = shiftAktif.dibukaPada ? new Date(shiftAktif.dibukaPada) : sekarang

  // 1. Cek apakah melewati tengah malam (beda hari kalender)
  const bedaHari =
    sekarang.getFullYear() !== dibuka.getFullYear() ||
    sekarang.getMonth() !== dibuka.getMonth() ||
    sekarang.getDate() !== dibuka.getDate()

  // 2. Cek durasi shift (dalam jam)
  const selisihJam = (sekarang.getTime() - dibuka.getTime()) / (1000 * 60 * 60)
  const durasiPanjang = selisihJam >= 12

  // 3. Cek jam operasional toko / jam tutup
  const [jamTutupJam, jamTutupMenit] = jamTutup.split(':').map(Number)
  const menitTutup = jamTutupJam * 60 + (jamTutupMenit || 0)
  const menitSekarang = sekarang.getHours() * 60 + sekarang.getMinutes()

  const lewatJamTutup = menitSekarang >= menitTutup
  const mendekatiTutup = menitSekarang >= menitTutup - 30 && menitSekarang < menitTutup

  // Tentukan tingkat pengingat
  let tingkat: TingkatPengingatShift = null
  if (bedaHari) {
    tingkat = 'melewati_tengah_malam'
  } else if (lewatJamTutup) {
    tingkat = 'lewat_jam_tutup'
  } else if (durasiPanjang) {
    tingkat = 'durasi_panjang'
  } else if (mendekatiTutup) {
    tingkat = 'mendekati_tutup'
  }

  // Jika kondisi aman atau jika hanya peringatan mendekati tutup yang diabaikan
  if (!tingkat) {
    return null
  }

  // Peringatan kritis (beda hari / lewat jam tutup) tidak boleh disembunyikan sepenuhnya
  if (diabaikan && tingkat === 'mendekati_tutup') {
    return null
  }

  const tanganiAbaikan = () => {
    setDiabaikan(true)
    if (onAbaikan) {
      onAbaikan()
    }
  }

  const pesanPengingat = () => {
    switch (tingkat) {
      case 'melewati_tengah_malam':
        return t('kasir.pengingat_shift_lewat_tengah_malam')
      case 'lewat_jam_tutup':
        return `${t('kasir.pengingat_shift_lewat_jam_tutup')} (${jamTutup})`
      case 'durasi_panjang':
        return `${t('kasir.pengingat_shift_durasi_panjang')} (${Math.floor(selisihJam)} jam)`
      case 'mendekati_tutup':
        return `${t('kasir.pengingat_shift_mendekati_tutup')} (${jamTutup})`
      default:
        return ''
    }
  }

  const warnaLatar =
    tingkat === 'melewati_tengah_malam'
      ? 'var(--warna-merah-latar, #ffebee)'
      : 'var(--warna-kuning-latar, #fff8e1)'
  const warnaTeks =
    tingkat === 'melewati_tengah_malam'
      ? 'var(--warna-merah-teks, #b71c1c)'
      : 'var(--warna-kuning-teks, #f57f17)'
  const warnaBorder =
    tingkat === 'melewati_tengah_malam'
      ? 'var(--warna-merah-tepi, #ef9a9a)'
      : 'var(--warna-kuning-tepi, #ffe082)'
  const ikon =
    tingkat === 'melewati_tengah_malam' ? '🚨' : tingkat === 'lewat_jam_tutup' ? '⏰' : '⏳'

  return (
    <div
      role="alert"
      data-testid="pengingat-shift"
      data-tingkat={tingkat}
      className="kotak-peringatan kotak-pengingat-shift"
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: '0.75rem',
        padding: '0.75rem 1rem',
        marginBottom: '1rem',
        borderRadius: '8px',
        backgroundColor: warnaLatar,
        border: `1px solid ${warnaBorder}`,
        color: warnaTeks,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', flex: '1 1 300px' }}>
        <span style={{ fontSize: '1.25rem' }} aria-hidden="true">
          {ikon}
        </span>
        <div style={{ fontSize: '0.9rem', lineHeight: '1.4' }}>
          <strong>
            {tingkat === 'melewati_tengah_malam'
              ? 'PERINGATAN SHIFT GANTUNG: '
              : 'PENGINGAT KASIR: '}
          </strong>
          <span>{pesanPengingat()}</span>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
        <Tombol ragam="utama" onClick={onTutupKas}>
          {t('kasir.tombol_tutup_kas_sekarang')}
        </Tombol>
        {tingkat === 'mendekati_tutup' && (
          <Tombol ragam="biasa" onClick={tanganiAbaikan}>
            {t('kasir.tombol_ingatkan_nanti')}
          </Tombol>
        )}
      </div>
    </div>
  )
}
