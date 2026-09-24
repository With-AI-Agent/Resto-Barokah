/**
 * LayarLaporan.tsx — Dasbor Laporan Keuangan, Penjualan, Kas Shift, dan Pembatalan (T7-08, T7-07 & T5-12).
 *
 * Menggabungkan:
 *  1. Laporan Penjualan Dasar (`LaporanPenjualan`) — PRD M8 / T7-08
 *  2. Laporan Kas Harian & per Shift (`LaporanKas`) — PRD M8 / T7-07
 *  3. Laporan Pembatalan Pesanan / Void (`DaftarPembatalan`) — T5-12
 */

import React, { useState } from 'react'
import { LaporanPenjualan, type DataLaporanPenjualan } from './LaporanPenjualan'
import { LaporanMenu, type DataLaporanMenu } from './LaporanMenu'
import { LaporanKas, type DataLaporanHarian, type DataLaporanShiftDetail } from './LaporanKas'
import { DaftarPembatalan, type BarisPembatalan } from './DaftarPembatalan'
import { FormatLaporan } from './FormatLaporan'
import { Tombol } from '../../komponen/Tombol'
import { useBahasa } from '../../bahasa'

export type TabLaporan = 'penjualan' | 'menu' | 'kas' | 'pembatalan' | 'cetak'

export interface LayarLaporanProps {
  dataPenjualan?: DataLaporanPenjualan | null
  dataMenu?: DataLaporanMenu | null
  dataHarian?: DataLaporanHarian | null
  shiftTerpilihDetail?: DataLaporanShiftDetail | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggal?: string
  tanggalMulai?: string
  tanggalAkhir?: string
  urutBerdasarkanMenu?: 'nilai' | 'jumlah'
  sedangMemuat?: boolean
  pesanGagal?: string | null
  daftarPembatalan?: BarisPembatalan[]
  tabAwal?: TabLaporan
  onPilihCabang?: (cabangId: string) => void
  onPilihTanggal?: (tanggal: string) => void
  onPilihRentangTanggal?: (mulai: string, akhir: string) => void
  onGantiUrutanMenu?: (urutan: 'nilai' | 'jumlah') => void
  onPilihShift?: (shiftId: string) => void
  onTutupRincianShift?: () => void
  onMuatUlang?: () => void
}

export const LayarLaporan: React.FC<LayarLaporanProps> = ({
  dataPenjualan,
  dataMenu,
  dataHarian,
  shiftTerpilihDetail,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggal,
  tanggalMulai,
  tanggalAkhir,
  urutBerdasarkanMenu = 'nilai',
  sedangMemuat = false,
  pesanGagal = null,
  daftarPembatalan = [],
  tabAwal = 'penjualan',
  onPilihCabang,
  onPilihTanggal,
  onPilihRentangTanggal,
  onGantiUrutanMenu,
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
          borderBottom: '1px solid var(--border)',
          paddingBottom: '8px',
          flexWrap: 'wrap',
        }}
      >
        <Tombol
          ragam={tabAktif === 'penjualan' ? 'utama' : 'polos'}
          onClick={() => setTabAktif('penjualan')}
        >
          📊 {t('laporan.tab_penjualan')}
        </Tombol>
        <Tombol ragam={tabAktif === 'menu' ? 'utama' : 'polos'} onClick={() => setTabAktif('menu')}>
          🍛 {t('laporan.tab_menu')}
        </Tombol>
        <Tombol ragam={tabAktif === 'kas' ? 'utama' : 'polos'} onClick={() => setTabAktif('kas')}>
          💰 {t('laporan.tab_kas')}
        </Tombol>
        <Tombol
          ragam={tabAktif === 'pembatalan' ? 'utama' : 'polos'}
          onClick={() => setTabAktif('pembatalan')}
        >
          ❌ {t('laporan.total_pembatalan')} ({barisBatal.length})
        </Tombol>
        <Tombol
          ragam={tabAktif === 'cetak' ? 'utama' : 'polos'}
          onClick={() => setTabAktif('cetak')}
        >
          🖨️ {t('laporan.format_cetak')}
        </Tombol>
      </div>

      {tabAktif === 'penjualan' && (
        <LaporanPenjualan
          data={dataPenjualan}
          daftarCabang={daftarCabang}
          cabangAktifId={cabangAktifId}
          peranPengguna={peranPengguna}
          tanggalMulai={tanggalMulai}
          tanggalAkhir={tanggalAkhir}
          sedangMemuat={sedangMemuat}
          pesanGagal={pesanGagal}
          onPilihCabang={onPilihCabang}
          onPilihRentangTanggal={onPilihRentangTanggal}
          onMuatUlang={onMuatUlang}
        />
      )}

      {tabAktif === 'menu' && (
        <LaporanMenu
          data={dataMenu}
          daftarCabang={daftarCabang}
          cabangAktifId={cabangAktifId}
          peranPengguna={peranPengguna}
          tanggalMulai={tanggalMulai}
          tanggalAkhir={tanggalAkhir}
          urutBerdasarkan={urutBerdasarkanMenu}
          sedangMemuat={sedangMemuat}
          pesanGagal={pesanGagal}
          onPilihCabang={onPilihCabang}
          onPilihRentangTanggal={onPilihRentangTanggal}
          onGantiUrutan={onGantiUrutanMenu}
          onMuatUlang={onMuatUlang}
        />
      )}

      {tabAktif === 'kas' && (
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
      )}

      {tabAktif === 'pembatalan' && (
        <DaftarPembatalan
          daftar={barisBatal}
          keterangan={
            dataHarian?.nama_cabang
              ? `Cabang: ${dataHarian.nama_cabang}`
              : dataPenjualan?.cabang?.nama
                ? `Cabang: ${dataPenjualan.cabang.nama}`
                : undefined
          }
        />
      )}

      {tabAktif === 'cetak' && (
        <FormatLaporan
          dataPenjualan={dataPenjualan}
          dataHarian={dataHarian}
          dataMenu={dataMenu}
          daftarCabang={daftarCabang}
          cabangAktifId={cabangAktifId}
          peranPengguna={peranPengguna}
          tanggal={tanggal}
          tanggalMulai={tanggalMulai}
          tanggalAkhir={tanggalAkhir}
          onPilihCabang={onPilihCabang}
          onTutup={() => setTabAktif('penjualan')}
        />
      )}
    </div>
  )
}

export default LayarLaporan
