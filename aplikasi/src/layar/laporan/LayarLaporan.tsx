/**
 * LayarLaporan.tsx — Dasbor Laporan Keuangan, Kas Shift, dan Pembatalan (T7-07 & T5-12).
 *
 * Menggabungkan:
 *  1. Laporan Kas Harian & per Shift (`LaporanKas`)
 *  2. Laporan Pembatalan Pesanan / Void (`DaftarPembatalan`)
 */

import React, { useState } from 'react'
import { LaporanKas, type DataLaporanHarian, type DataLaporanShiftDetail } from './LaporanKas'
import { DaftarPembatalan, type BarisPembatalan } from './DaftarPembatalan'
import { Tombol } from '../../komponen/Tombol'
import { useBahasa } from '../../bahasa'

export type TabLaporan = 'kas' | 'pembatalan'

export interface LayarLaporanProps {
  dataHarian?: DataLaporanHarian | null
  shiftTerpilihDetail?: DataLaporanShiftDetail | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggal?: string
  sedangMemuat?: boolean
  pesanGagal?: string | null
  daftarPembatalan?: BarisPembatalan[]
  tabAwal?: TabLaporan
  onPilihCabang?: (cabangId: string) => void
  onPilihTanggal?: (tanggal: string) => void
  onPilihShift?: (shiftId: string) => void
  onTutupRincianShift?: () => void
  onMuatUlang?: () => void
}

export const LayarLaporan: React.FC<LayarLaporanProps> = ({
  dataHarian,
  shiftTerpilihDetail,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggal,
  sedangMemuat = false,
  pesanGagal = null,
  daftarPembatalan = [],
  tabAwal = 'kas',
  onPilihCabang,
  onPilihTanggal,
  onPilihShift,
  onTutupRincianShift,
  onMuatUlang,
}) => {
  const { t } = useBahasa()
  const [tabAktif, setTabAktif] = useState<TabLaporan>(tabAwal)

  // Konversi data pembatalan dari laporan harian bila prop daftarPembatalan tidak disediakan eksplisit
  const barisBatal =
    daftarPembatalan.length > 0
      ? daftarPembatalan
      : (dataHarian?.pembatalan.daftar || []).map((pb) => ({
          id: pb.id,
          nomorPesanan: pb.nomor_pesanan,
          waktu: pb.waktu,
          tahap: pb.tahap,
          alasan: pb.alasan,
          nilaiKerugian: pb.nilai_kerugian,
          pelakuNama: pb.pelaku_nama ?? null,
          penyetujuNama: pb.penyetuju_nama ?? null,
          itemNama: pb.item_nama ?? null,
        }))

  return (
    <div
      className="layar-laporan"
      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3, 12px)' }}
    >
      {/* Navigasi Tab */}
      <div
        role="tablist"
        aria-label="Pilihan Laporan"
        style={{
          display: 'flex',
          gap: '8px',
          borderBottom: '1px solid var(--warna-garis, #e5e7eb)',
          paddingBottom: '8px',
        }}
      >
        <Tombol ragam={tabAktif === 'kas' ? 'utama' : 'polos'} onClick={() => setTabAktif('kas')}>
          💰 {t('laporan.kas_harian')} & Shift
        </Tombol>
        <Tombol
          ragam={tabAktif === 'pembatalan' ? 'utama' : 'polos'}
          onClick={() => setTabAktif('pembatalan')}
        >
          ❌ {t('laporan.total_pembatalan')} ({barisBatal.length})
        </Tombol>
      </div>

      {tabAktif === 'kas' ? (
        <LaporanKas
          dataHarian={dataHarian}
          shiftTerpilihDetail={shiftTerpilihDetail}
          daftarCabang={daftarCabang}
          cabangAktifId={cabangAktifId}
          peranPengguna={peranPengguna}
          tanggal={tanggal}
          sedangMemuat={sedangMemuat}
          pesanGagal={pesanGagal}
          onPilihCabang={onPilihCabang}
          onPilihTanggal={onPilihTanggal}
          onPilihShift={onPilihShift}
          onTutupRincianShift={onTutupRincianShift}
          onMuatUlang={onMuatUlang}
        />
      ) : (
        <DaftarPembatalan
          daftar={barisBatal}
          keterangan={dataHarian?.nama_cabang ? `Cabang: ${dataHarian.nama_cabang}` : undefined}
        />
      )}
    </div>
  )
}

export default LayarLaporan
