/**
 * LaporanKas.tsx (T7-07) — Laporan Kas Harian dan per Shift untuk Pemilik / Admin Cabang.
 *
 * Mengacu pada PRD M8 (Kriteria Selesai: Laporan A dikunci untuk G1) & TECH_SPEC §5:
 *  - Memuat omzet (makanan/minuman/lainnya)
 *  - Jumlah transaksi & rincian metode bayar
 *  - Diskon & voucher
 *  - Pembatalan & nilai kerugian
 *  - Kas awal, kas masuk, kas keluar, setoran, uang seharusnya, uang fisik, dan selisih
 *  - Nama kasir & jam shift
 *  - Filter cabang sesuai peran (owner_pusat vs admin_cabang)
 *  - Seluruh angka berasal dari peladen (RPC laporan_harian / laporan_shift)
 */

import React, { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, jamLokal } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export interface RincianMetodeBayar {
  metode_id?: string
  metode_nama: string
  jumlah_transaksi: number
  total_nominal: number
}

export interface BarisPergerakanKas {
  id?: string
  waktu: string
  jenis: 'masuk' | 'keluar' | 'setoran'
  jumlah: number
  alasan: string
  pelaku_nama?: string | null
}

export interface BarisKoreksiModal {
  id?: string
  waktu: string
  modal_awal_lama: number
  modal_awal_baru: number
  selisih: number
  alasan: string
  disetujui_oleh_nama?: string | null
}

export interface BarisPembatalanShift {
  id: string
  nomor_pesanan: number
  item_nama?: string | null
  waktu: string
  tahap: 'sebelum_dapur' | 'sesudah_dapur'
  alasan: string
  nilai_kerugian: number
  bahan_terbuang: boolean
  pelaku_nama?: string | null
  penyetuju_nama?: string | null
}

export interface RingkasanShiftBaris {
  shift_id: string
  cabang_id: string
  nama_cabang: string
  dibuka_oleh: string
  kasir_buka_nama: string | null
  dibuka_pada: string
  ditutup_oleh?: string | null
  kasir_tutup_nama?: string | null
  ditutup_pada?: string | null
  status: 'aktif' | 'ditutup'
  melewati_tengah_malam?: boolean
  modal_awal: number
  kas_masuk: number
  kas_keluar: number
  setoran: number
  penjualan_tunai: number
  penjualan_non_tunai: number
  total_penjualan: number
  uang_seharusnya: number
  uang_fisik: number | null
  selisih: number | null
  alasan_selisih?: string | null
  jumlah_transaksi: number
}

export interface DataLaporanHarian {
  tanggal: string
  cabang_id: string | null
  nama_cabang: string
  jumlah_shift: number
  penjualan: {
    jumlah_transaksi: number
    omzet_total: number
    omzet_makanan: number
    omzet_minuman: number
    omzet_lainnya: number
    total_diskon: number
  }
  kas: {
    total_modal_awal: number
    kas_masuk: number
    kas_keluar: number
    setoran: number
    penjualan_tunai: number
    penjualan_non_tunai: number
    total_penjualan: number
    total_uang_seharusnya: number
    total_uang_fisik: number
    total_selisih: number
  }
  metode_bayar: RincianMetodeBayar[]
  shifts: RingkasanShiftBaris[]
  pembatalan: {
    jumlah: number
    total_nilai_rugi: number
    daftar: BarisPembatalanShift[]
  }
}

export interface DataLaporanShiftDetail {
  shift: {
    id: string
    cabang_id: string
    nama_cabang: string
    kasir_buka_id: string
    kasir_buka_nama: string | null
    kasir_tutup_id?: string | null
    kasir_tutup_nama?: string | null
    dibuka_pada: string
    ditutup_pada?: string | null
    status: 'aktif' | 'ditutup'
    melewati_tengah_malam: boolean
    catatan_buka?: string | null
  }
  kas: {
    modal_awal: number
    total_koreksi_modal: number
    kas_masuk: number
    kas_keluar: number
    setoran: number
    penjualan_tunai: number
    penjualan_non_tunai: number
    total_penjualan: number
    uang_seharusnya: number
    uang_fisik: number | null
    selisih: number | null
    alasan_selisih?: string | null
  }
  penjualan: {
    jumlah_transaksi: number
    omzet_total: number
    omzet_makanan: number
    omzet_minuman: number
    omzet_lainnya: number
    total_subtotal: number
    total_pajak: number
    total_service: number
    total_diskon: number
  }
  metode_bayar: RincianMetodeBayar[]
  pergerakan_kas: BarisPergerakanKas[]
  koreksi_modal: BarisKoreksiModal[]
  pembatalan: {
    jumlah: number
    total_nilai_rugi: number
    daftar: BarisPembatalanShift[]
  }
}

export interface LaporanKasProps {
  dataHarian?: DataLaporanHarian | null
  shiftTerpilihDetail?: DataLaporanShiftDetail | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggal?: string
  sedangMemuat?: boolean
  pesanGagal?: string | null
  onPilihCabang?: (cabangId: string) => void
  onPilihTanggal?: (tanggal: string) => void
  onPilihShift?: (shiftId: string) => void
  onTutupRincianShift?: () => void
  onMuatUlang?: () => void
}

export const LaporanKas: React.FC<LaporanKasProps> = ({
  dataHarian,
  shiftTerpilihDetail,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggal = new Date().toISOString().slice(0, 10),
  sedangMemuat = false,
  pesanGagal = null,
  onPilihCabang,
  onPilihTanggal,
  onPilihShift,
  onTutupRincianShift,
  onMuatUlang,
}) => {
  const { t } = useBahasa()
  const [modalBuka, setModalBuka] = useState(false)

  // Buka modal jika ada rincian shift terpilih
  const handlePilihShift = (shiftId: string) => {
    onPilihShift?.(shiftId)
    setModalBuka(true)
  }

  const handleTutupModal = () => {
    setModalBuka(false)
    onTutupRincianShift?.()
  }

  const formatJam = (isoString?: string | null) => {
    if (!isoString) return '-'
    try {
      return jamLokal(new Date(isoString))
    } catch {
      return isoString
    }
  }

  if (sedangMemuat) {
    return <KeadaanMemuat judul={t('memuat')} />
  }

  if (pesanGagal) {
    return (
      <KeadaanGagal
        judul="Gagal memuat data laporan"
        keterangan={pesanGagal}
        onCoba={onMuatUlang}
      />
    )
  }

  const bisaGantiCabang = peranPengguna === 'owner_pusat'

  return (
    <div
      className="laporan-kas-kontainer"
      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4, 16px)' }}
    >
      {/* 1. Bilah Kendali Atas (Cabang & Tanggal) */}
      <section
        className="card"
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 'var(--s-3, 12px)',
          padding: 'var(--s-3, 12px) var(--s-4, 16px)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 'var(--s-3, 12px)',
            flexWrap: 'wrap',
          }}
        >
          <h2 style={{ fontSize: 'var(--t-5, 1.25rem)', margin: 0, fontWeight: 700 }}>
            {t('laporan.judul')}
          </h2>
          <Lencana nada="info">{dataHarian?.nama_cabang || t('laporan.semua_cabang')}</Lencana>
        </div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 'var(--s-2, 8px)',
            flexWrap: 'wrap',
          }}
        >
          {/* Pemilih Cabang */}
          {daftarCabang.length > 0 && (
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-1, 4px)' }}>
              <label
                htmlFor="pilih-cabang-laporan"
                style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
              >
                📍 {t('cabang')}:
              </label>
              {bisaGantiCabang ? (
                <select
                  id="pilih-cabang-laporan"
                  className="input"
                  value={cabangAktifId || ''}
                  onChange={(e) => onPilihCabang?.(e.target.value)}
                  style={{
                    padding: 'var(--s-1, 4px) var(--s-2, 8px)',
                    height: '38px',
                    fontSize: 'var(--t-3, 0.875rem)',
                  }}
                >
                  <option value="">{t('laporan.semua_cabang')}</option>
                  {daftarCabang.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.nama}
                    </option>
                  ))}
                </select>
              ) : (
                <span style={{ fontWeight: 600, fontSize: 'var(--t-3, 0.875rem)' }}>
                  {daftarCabang.find((c) => c.id === cabangAktifId)?.nama || 'Cabang Saya'}
                </span>
              )}
            </div>
          )}

          {/* Pemilih Tanggal */}
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-1, 4px)' }}>
            <label
              htmlFor="pilih-tanggal-laporan"
              style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
            >
              📅 {t('laporan.filter_tanggal')}:
            </label>
            <input
              id="pilih-tanggal-laporan"
              type="date"
              className="input"
              value={tanggal}
              onChange={(e) => onPilihTanggal?.(e.target.value)}
              style={{
                padding: 'var(--s-1, 4px) var(--s-2, 8px)',
                height: '38px',
                fontSize: 'var(--t-3, 0.875rem)',
              }}
            />
          </div>

          {onMuatUlang && (
            <Tombol ragam="biasa" onClick={onMuatUlang}>
              🔄 {t('ulang')}
            </Tombol>
          )}
        </div>
      </section>

      {!dataHarian ? (
        <KeadaanKosong
          judul={t('kosong')}
          keterangan="Tidak ada data laporan kas untuk tanggal atau cabang ini."
        />
      ) : (
        <>
          {/* 2. Kartu Indikator Utama (KPI Ringkasan) */}
          <section
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
              gap: 'var(--s-3, 12px)',
            }}
          >
            {/* Omzet Total */}
            <Kartu kelas="kpi-kartu">
              <span
                style={{ fontSize: 'var(--t-2, 0.75rem)', color: 'var(--warna-teks-redup, #666)' }}
              >
                {t('laporan.omset_penjualan')}
              </span>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700, margin: '4px 0' }}>
                {rupiah(dataHarian.penjualan.omzet_total)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  display: 'flex',
                  gap: '8px',
                  flexWrap: 'wrap',
                }}
              >
                <span title={t('laporan.omzet_makanan')}>
                  🍲 {rupiah(dataHarian.penjualan.omzet_makanan)}
                </span>
                <span title={t('laporan.omzet_minuman')}>
                  🥤 {rupiah(dataHarian.penjualan.omzet_minuman)}
                </span>
              </div>
            </Kartu>

            {/* Jumlah Transaksi & Diskon */}
            <Kartu kelas="kpi-kartu">
              <span
                style={{ fontSize: 'var(--t-2, 0.75rem)', color: 'var(--warna-teks-redup, #666)' }}
              >
                {t('laporan.transaksi_selesai')}
              </span>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700, margin: '4px 0' }}>
                {dataHarian.penjualan.jumlah_transaksi} Transaksi
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--warna-peringatan, #b45309)',
                }}
              >
                🏷️ {t('laporan.total_diskon')}: {rupiah(dataHarian.penjualan.total_diskon)}
              </div>
            </Kartu>

            {/* Uang Kas Seharusnya vs Fisik */}
            <Kartu kelas="kpi-kartu">
              <span
                style={{ fontSize: 'var(--t-2, 0.75rem)', color: 'var(--warna-teks-redup, #666)' }}
              >
                {t('laporan.uang_seharusnya')}
              </span>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700, margin: '4px 0' }}>
                {rupiah(dataHarian.kas.total_uang_seharusnya)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <span>Fisik: {rupiah(dataHarian.kas.total_uang_fisik)}</span>
                {dataHarian.kas.total_selisih === 0 ? (
                  <Lencana nada="success">Sesuai (Rp0)</Lencana>
                ) : (
                  <Lencana nada={dataHarian.kas.total_selisih < 0 ? 'danger' : 'warn'}>
                    Selisih {rupiah(dataHarian.kas.total_selisih)}
                  </Lencana>
                )}
              </div>
            </Kartu>

            {/* Arus Kas & Pembatalan */}
            <Kartu kelas="kpi-kartu">
              <span
                style={{ fontSize: 'var(--t-2, 0.75rem)', color: 'var(--warna-teks-redup, #666)' }}
              >
                Arus Kas & Pembatalan
              </span>
              <div style={{ fontSize: 'var(--t-3, 0.875rem)', margin: '4px 0' }}>
                <span style={{ color: 'var(--warna-sukses, #15803d)' }}>
                  + {rupiah(dataHarian.kas.kas_masuk)}
                </span>
                {' / '}
                <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                  - {rupiah(dataHarian.kas.kas_keluar + dataHarian.kas.setoran)}
                </span>
              </div>
              <div style={{ fontSize: 'var(--t-2, 0.75rem)' }}>
                {dataHarian.pembatalan.jumlah === 0 ? (
                  <span style={{ color: 'var(--warna-sukses, #15803d)' }}>✅ Tanpa Pembatalan</span>
                ) : (
                  <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                    ⚠️ {dataHarian.pembatalan.jumlah} batal (
                    {rupiah(dataHarian.pembatalan.total_nilai_rugi)} rugi)
                  </span>
                )}
              </div>
            </Kartu>
          </section>

          {/* 3. Baris Dua Kolom: Rincian Metode Bayar & Ringkasan Kas */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
              gap: 'var(--s-3, 12px)',
            }}
          >
            {/* Rincian Metode Bayar */}
            <Kartu judul={t('laporan.rincian_metode')}>
              {dataHarian.metode_bayar.length === 0 ? (
                <p
                  style={{
                    color: 'var(--warna-teks-redup, #666)',
                    fontSize: 'var(--t-3, 0.875rem)',
                  }}
                >
                  Belum ada pembayaran lunas.
                </p>
              ) : (
                <table
                  style={{
                    width: '100%',
                    borderCollapse: 'collapse',
                    fontSize: 'var(--t-3, 0.875rem)',
                  }}
                >
                  <thead>
                    <tr
                      style={{
                        borderBottom: '1px solid var(--warna-garis, #e5e7eb)',
                        textAlign: 'left',
                      }}
                    >
                      <th style={{ padding: '6px 8px' }}>Metode</th>
                      <th style={{ padding: '6px 8px', textAlign: 'center' }}>Transaksi</th>
                      <th style={{ padding: '6px 8px', textAlign: 'right' }}>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dataHarian.metode_bayar.map((mb, idx) => (
                      <tr
                        key={mb.metode_id || idx}
                        style={{ borderBottom: '1px solid var(--warna-garis-redup, #f3f4f6)' }}
                      >
                        <td style={{ padding: '8px' }}>
                          <strong>{mb.metode_nama}</strong>
                        </td>
                        <td style={{ padding: '8px', textAlign: 'center' }}>
                          {mb.jumlah_transaksi}
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right', fontWeight: 600 }}>
                          {rupiah(mb.total_nominal)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </Kartu>

            {/* Rekapitulasi Kas */}
            <Kartu judul={t('laporan.kas_harian')}>
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                  fontSize: 'var(--t-3, 0.875rem)',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>{t('laporan.modal_awal')}:</span>
                  <strong>{rupiah(dataHarian.kas.total_modal_awal)}</strong>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>Penjualan Tunai:</span>
                  <span style={{ color: 'var(--warna-sukses, #15803d)' }}>
                    + {rupiah(dataHarian.kas.penjualan_tunai)}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>Penjualan Non-Tunai:</span>
                  <span>{rupiah(dataHarian.kas.penjualan_non_tunai)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>{t('laporan.kas_masuk')}:</span>
                  <span style={{ color: 'var(--warna-sukses, #15803d)' }}>
                    + {rupiah(dataHarian.kas.kas_masuk)}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>{t('laporan.kas_keluar')}:</span>
                  <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                    - {rupiah(dataHarian.kas.kas_keluar)}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>{t('laporan.setoran')} Bank:</span>
                  <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                    - {rupiah(dataHarian.kas.setoran)}
                  </span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    borderTop: '2px dashed var(--warna-garis, #e5e7eb)',
                    paddingTop: '8px',
                    fontWeight: 700,
                  }}
                >
                  <span>{t('laporan.uang_seharusnya')}:</span>
                  <span>{rupiah(dataHarian.kas.total_uang_seharusnya)}</span>
                </div>
              </div>
            </Kartu>
          </div>

          {/* 4. Daftar Shift Kasir Hari Ini */}
          <Kartu judul={`${t('laporan.kas_shift')} (${dataHarian.shifts.length} Shift)`}>
            {dataHarian.shifts.length === 0 ? (
              <p
                style={{ color: 'var(--warna-teks-redup, #666)', fontSize: 'var(--t-3, 0.875rem)' }}
              >
                Belum ada shift kasir yang tercatat pada tanggal ini.
              </p>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table
                  style={{
                    width: '100%',
                    borderCollapse: 'collapse',
                    fontSize: 'var(--t-3, 0.875rem)',
                  }}
                >
                  <thead>
                    <tr
                      style={{
                        borderBottom: '2px solid var(--warna-garis, #e5e7eb)',
                        textAlign: 'left',
                      }}
                    >
                      <th style={{ padding: '8px' }}>Cabang / Shift</th>
                      <th style={{ padding: '8px' }}>Kasir</th>
                      <th style={{ padding: '8px' }}>Jam</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>Modal Awal</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>Penjualan</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>Seharusnya</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>Fisik</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>Selisih</th>
                      <th style={{ padding: '8px', textAlign: 'center' }}>Status</th>
                      <th style={{ padding: '8px', textAlign: 'center' }}>Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dataHarian.shifts.map((s) => (
                      <tr
                        key={s.shift_id}
                        style={{ borderBottom: '1px solid var(--warna-garis-redup, #f3f4f6)' }}
                      >
                        <td style={{ padding: '10px 8px' }}>
                          <div style={{ fontWeight: 600 }}>{s.nama_cabang}</div>
                          {s.melewati_tengah_malam && (
                            <span
                              title="Shift melewati tengah malam"
                              style={{ fontSize: 'var(--t-2, 0.75rem)' }}
                            >
                              🌙 Lewat tengah malam
                            </span>
                          )}
                        </td>
                        <td style={{ padding: '10px 8px' }}>
                          <div>{s.kasir_buka_nama || 'Kasir'}</div>
                          {s.kasir_tutup_nama && s.kasir_tutup_nama !== s.kasir_buka_nama && (
                            <div
                              style={{
                                fontSize: 'var(--t-2, 0.75rem)',
                                color: 'var(--warna-teks-redup, #666)',
                              }}
                            >
                              Tutup: {s.kasir_tutup_nama}
                            </div>
                          )}
                        </td>
                        <td style={{ padding: '10px 8px' }}>
                          <div>
                            {formatJam(s.dibuka_pada)} -{' '}
                            {s.ditutup_pada ? formatJam(s.ditutup_pada) : 'Sekarang'}
                          </div>
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'right' }}>
                          {rupiah(s.modal_awal)}
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'right' }}>
                          <div>{rupiah(s.total_penjualan)}</div>
                          <div
                            style={{
                              fontSize: 'var(--t-2, 0.75rem)',
                              color: 'var(--warna-teks-redup, #666)',
                            }}
                          >
                            {s.jumlah_transaksi} trx
                          </div>
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'right', fontWeight: 600 }}>
                          {rupiah(s.uang_seharusnya)}
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'right' }}>
                          {s.uang_fisik !== null ? rupiah(s.uang_fisik) : '-'}
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'right' }}>
                          {s.selisih === null ? (
                            '-'
                          ) : s.selisih === 0 ? (
                            <span
                              style={{ color: 'var(--warna-sukses, #15803d)', fontWeight: 600 }}
                            >
                              Rp0
                            </span>
                          ) : (
                            <span
                              style={{
                                color:
                                  s.selisih < 0
                                    ? 'var(--warna-bahaya, #b91c1c)'
                                    : 'var(--warna-peringatan, #b45309)',
                                fontWeight: 600,
                              }}
                            >
                              {rupiah(s.selisih)}
                            </span>
                          )}
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'center' }}>
                          <Lencana nada={s.status === 'ditutup' ? 'netral' : 'success'}>
                            {s.status === 'ditutup' ? 'Ditutup' : 'Aktif'}
                          </Lencana>
                        </td>
                        <td style={{ padding: '10px 8px', textAlign: 'center' }}>
                          <Tombol ragam="kecil" onClick={() => handlePilihShift(s.shift_id)}>
                            Rincian
                          </Tombol>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Kartu>
        </>
      )}

      {/* 5. Modal Lapis: Rincian Shift Terpilih */}
      <Lapis
        buka={modalBuka && !!shiftTerpilihDetail}
        judul={`${t('laporan.rincian_shift')} — ${shiftTerpilihDetail?.shift.nama_cabang || ''}`}
        onTutup={handleTutupModal}
      >
        {shiftTerpilihDetail && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4, 16px)' }}>
            {/* Informasi Kasir & Jam */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: '8px',
                padding: '12px',
                backgroundColor: 'var(--warna-latar-kartu, #f9fafb)',
                borderRadius: '8px',
                fontSize: 'var(--t-3, 0.875rem)',
              }}
            >
              <div>
                <strong>{t('laporan.kasir_buka')}:</strong>{' '}
                {shiftTerpilihDetail.shift.kasir_buka_nama || '-'}
                <div>Buka: {formatJam(shiftTerpilihDetail.shift.dibuka_pada)}</div>
              </div>
              <div>
                <strong>{t('laporan.kasir_tutup')}:</strong>{' '}
                {shiftTerpilihDetail.shift.kasir_tutup_nama || '-'}
                <div>
                  Tutup:{' '}
                  {shiftTerpilihDetail.shift.ditutup_pada
                    ? formatJam(shiftTerpilihDetail.shift.ditutup_pada)
                    : 'Belum Ditutup'}
                </div>
              </div>
              <div>
                <strong>Status:</strong>{' '}
                <Lencana
                  nada={shiftTerpilihDetail.shift.status === 'ditutup' ? 'netral' : 'success'}
                >
                  {shiftTerpilihDetail.shift.status === 'ditutup' ? 'Ditutup' : 'Aktif'}
                </Lencana>
                {shiftTerpilihDetail.shift.melewati_tengah_malam && (
                  <div
                    style={{
                      color: 'var(--warna-peringatan, #b45309)',
                      fontSize: 'var(--t-2, 0.75rem)',
                    }}
                  >
                    🌙 Melewati tengah malam
                  </div>
                )}
              </div>
            </div>

            {/* Rincian Kas Shift */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
                gap: '12px',
              }}
            >
              <div
                style={{
                  border: '1px solid var(--warna-garis, #e5e7eb)',
                  borderRadius: '8px',
                  padding: '12px',
                  fontSize: 'var(--t-3, 0.875rem)',
                }}
              >
                <h4 style={{ margin: '0 0 8px 0', fontSize: 'var(--t-4, 1rem)' }}>
                  Arus Kas Shift
                </h4>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.modal_awal')}:</span>
                  <span>{rupiah(shiftTerpilihDetail.kas.modal_awal)}</span>
                </div>
                {shiftTerpilihDetail.kas.total_koreksi_modal !== 0 && (
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      marginBottom: '4px',
                      color: 'var(--warna-peringatan, #b45309)',
                    }}
                  >
                    <span>Koreksi Modal Awal:</span>
                    <span>{rupiah(shiftTerpilihDetail.kas.total_koreksi_modal)}</span>
                  </div>
                )}
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>Penjualan Tunai:</span>
                  <span style={{ color: 'var(--warna-sukses, #15803d)' }}>
                    + {rupiah(shiftTerpilihDetail.kas.penjualan_tunai)}
                  </span>
                </div>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.kas_masuk')}:</span>
                  <span style={{ color: 'var(--warna-sukses, #15803d)' }}>
                    + {rupiah(shiftTerpilihDetail.kas.kas_masuk)}
                  </span>
                </div>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.kas_keluar')}:</span>
                  <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                    - {rupiah(shiftTerpilihDetail.kas.kas_keluar)}
                  </span>
                </div>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.setoran')}:</span>
                  <span style={{ color: 'var(--warna-bahaya, #b91c1c)' }}>
                    - {rupiah(shiftTerpilihDetail.kas.setoran)}
                  </span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    borderTop: '1px solid var(--warna-garis, #e5e7eb)',
                    paddingTop: '6px',
                    fontWeight: 700,
                  }}
                >
                  <span>{t('laporan.uang_seharusnya')}:</span>
                  <span>{rupiah(shiftTerpilihDetail.kas.uang_seharusnya)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                  <span>{t('laporan.uang_fisik')}:</span>
                  <span>
                    {shiftTerpilihDetail.kas.uang_fisik !== null
                      ? rupiah(shiftTerpilihDetail.kas.uang_fisik)
                      : '-'}
                  </span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginTop: '4px',
                    fontWeight: 600,
                  }}
                >
                  <span>{t('laporan.selisih')}:</span>
                  <span>
                    {shiftTerpilihDetail.kas.selisih === null
                      ? '-'
                      : rupiah(shiftTerpilihDetail.kas.selisih)}
                  </span>
                </div>
                {shiftTerpilihDetail.kas.alasan_selisih && (
                  <div
                    style={{
                      marginTop: '4px',
                      fontSize: 'var(--t-2, 0.75rem)',
                      color: 'var(--warna-teks-redup, #666)',
                    }}
                  >
                    Alasan: {shiftTerpilihDetail.kas.alasan_selisih}
                  </div>
                )}
              </div>

              {/* Rincian Penjualan & Kategori */}
              <div
                style={{
                  border: '1px solid var(--warna-garis, #e5e7eb)',
                  borderRadius: '8px',
                  padding: '12px',
                  fontSize: 'var(--t-3, 0.875rem)',
                }}
              >
                <h4 style={{ margin: '0 0 8px 0', fontSize: 'var(--t-4, 1rem)' }}>
                  Rincian Omzet Penjualan
                </h4>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.omzet_makanan')}:</span>
                  <span>{rupiah(shiftTerpilihDetail.penjualan.omzet_makanan)}</span>
                </div>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>{t('laporan.omzet_minuman')}:</span>
                  <span>{rupiah(shiftTerpilihDetail.penjualan.omzet_minuman)}</span>
                </div>
                {shiftTerpilihDetail.penjualan.omzet_lainnya > 0 && (
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      marginBottom: '4px',
                    }}
                  >
                    <span>{t('laporan.omzet_lainnya')}:</span>
                    <span>{rupiah(shiftTerpilihDetail.penjualan.omzet_lainnya)}</span>
                  </div>
                )}
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>Pajak Resto:</span>
                  <span>{rupiah(shiftTerpilihDetail.penjualan.total_pajak)}</span>
                </div>
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}
                >
                  <span>Biaya Layanan:</span>
                  <span>{rupiah(shiftTerpilihDetail.penjualan.total_service)}</span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: '4px',
                    color: 'var(--warna-peringatan, #b45309)',
                  }}
                >
                  <span>{t('laporan.total_diskon')}:</span>
                  <span>- {rupiah(shiftTerpilihDetail.penjualan.total_diskon)}</span>
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    borderTop: '1px solid var(--warna-garis, #e5e7eb)',
                    paddingTop: '6px',
                    fontWeight: 700,
                  }}
                >
                  <span>{t('laporan.omset_penjualan')}:</span>
                  <span>{rupiah(shiftTerpilihDetail.penjualan.omzet_total)}</span>
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-2, 0.75rem)',
                    marginTop: '4px',
                    color: 'var(--warna-teks-redup, #666)',
                  }}
                >
                  {shiftTerpilihDetail.penjualan.jumlah_transaksi} Transaksi Selesai
                </div>
              </div>
            </div>

            {/* Riwayat Koreksi Modal Awal (bila ada) */}
            {shiftTerpilihDetail.koreksi_modal.length > 0 && (
              <div style={{ fontSize: 'var(--t-3, 0.875rem)' }}>
                <h4 style={{ margin: '0 0 6px 0', fontSize: 'var(--t-4, 1rem)' }}>
                  Riwayat Koreksi Modal Awal
                </h4>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr
                      style={{
                        borderBottom: '1px solid var(--warna-garis, #e5e7eb)',
                        textAlign: 'left',
                      }}
                    >
                      <th style={{ padding: '4px 6px' }}>Waktu</th>
                      <th style={{ padding: '4px 6px' }}>Lama → Baru</th>
                      <th style={{ padding: '4px 6px' }}>Selisih</th>
                      <th style={{ padding: '4px 6px' }}>Alasan</th>
                      <th style={{ padding: '4px 6px' }}>Disetujui</th>
                    </tr>
                  </thead>
                  <tbody>
                    {shiftTerpilihDetail.koreksi_modal.map((km, i) => (
                      <tr
                        key={km.id || i}
                        style={{ borderBottom: '1px solid var(--warna-garis-redup, #f3f4f6)' }}
                      >
                        <td style={{ padding: '6px' }}>{formatJam(km.waktu)}</td>
                        <td style={{ padding: '6px' }}>
                          {rupiah(km.modal_awal_lama)} → {rupiah(km.modal_awal_baru)}
                        </td>
                        <td style={{ padding: '6px', fontWeight: 600 }}>{rupiah(km.selisih)}</td>
                        <td style={{ padding: '6px' }}>{km.alasan}</td>
                        <td style={{ padding: '6px' }}>{km.disetujui_oleh_nama || 'Atasan'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* Riwayat Pembatalan pada Shift Ini (bila ada) */}
            {shiftTerpilihDetail.pembatalan.jumlah > 0 && (
              <div style={{ fontSize: 'var(--t-3, 0.875rem)' }}>
                <h4
                  style={{
                    margin: '0 0 6px 0',
                    fontSize: 'var(--t-4, 1rem)',
                    color: 'var(--warna-bahaya, #b91c1c)',
                  }}
                >
                  Pembatalan Pesanan / Void ({shiftTerpilihDetail.pembatalan.jumlah} Item)
                </h4>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr
                      style={{
                        borderBottom: '1px solid var(--warna-garis, #e5e7eb)',
                        textAlign: 'left',
                      }}
                    >
                      <th style={{ padding: '4px 6px' }}>Pesanan</th>
                      <th style={{ padding: '4px 6px' }}>Item</th>
                      <th style={{ padding: '4px 6px' }}>Tahap</th>
                      <th style={{ padding: '4px 6px' }}>Nilai Kerugian</th>
                      <th style={{ padding: '4px 6px' }}>Alasan</th>
                    </tr>
                  </thead>
                  <tbody>
                    {shiftTerpilihDetail.pembatalan.daftar.map((pb) => (
                      <tr
                        key={pb.id}
                        style={{ borderBottom: '1px solid var(--warna-garis-redup, #f3f4f6)' }}
                      >
                        <td style={{ padding: '6px' }}>#{pb.nomor_pesanan}</td>
                        <td style={{ padding: '6px' }}>{pb.item_nama || 'Seluruh Pesanan'}</td>
                        <td style={{ padding: '6px' }}>
                          <Lencana nada={pb.tahap === 'sesudah_dapur' ? 'danger' : 'netral'}>
                            {pb.tahap === 'sesudah_dapur' ? 'Sesudah Dapur' : 'Sebelum Dapur'}
                          </Lencana>
                        </td>
                        <td
                          style={{
                            padding: '6px',
                            fontWeight: 600,
                            color:
                              pb.nilai_kerugian > 0 ? 'var(--warna-bahaya, #b91c1c)' : 'inherit',
                          }}
                        >
                          {rupiah(pb.nilai_kerugian)}
                        </td>
                        <td style={{ padding: '6px' }}>{pb.alasan}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '12px' }}>
              <Tombol ragam="utama" onClick={handleTutupModal}>
                {t('laporan.tutup_detail')}
              </Tombol>
            </div>
          </div>
        )}
      </Lapis>
    </div>
  )
}
export default LaporanKas
