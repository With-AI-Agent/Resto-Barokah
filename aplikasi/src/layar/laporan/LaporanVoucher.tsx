/**
 * LaporanVoucher.tsx (T8-13) — Laporan Klaim Voucher & Deteksi Anomali.
 *
 * Mengacu pada PRD M10 (Voucher promosi & anti-fraud) & TECH_SPEC §5:
 *  - Rekap klaim & pemakaian per kampanye, cabang, dan tren harian
 *  - Total potongan (rupiah diskon voucher)
 *  - Daftar identitas klaim berulang (pelanggan yang mengklaim beberapa voucher)
 *  - Peringatan dini & deteksi anomali (klaim berlebih >3, brute-force, pemakaian kilat <2m, kuota/anggaran menipis)
 *  - Isolasi multi-tenant & pembatasan peran (owner_pusat & admin_cabang)
 */

import React, { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, tanggalLokal } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export interface RingkasanVoucher {
  total_klaim: number
  total_terpakai: number
  total_potongan: number
  tingkat_konversi_persen: number
  rata_rata_potongan: number
}

export interface KampanyeVoucher {
  kampanye_id: string
  kode_kampanye: string
  nama_kampanye: string
  jenis_diskon: string
  nilai_diskon: number
  anggaran_maks: number | null
  total_klaim: number
  total_terpakai: number
  total_potongan: number
  tingkat_konversi_persen: number
}

export interface CabangVoucher {
  cabang_id: string | null
  nama_cabang: string
  total_klaim: number
  total_terpakai: number
  total_potongan: number
}

export interface TrenHarianVoucher {
  tanggal: string
  total_klaim: number
  total_terpakai: number
  total_potongan: number
}

export interface KlaimBerulang {
  pelanggan_id: string
  nama: string | null
  nomor_hp: string | null
  jumlah_klaim: number
  jumlah_terpakai: number
  total_potongan: number
}

export interface AnomaliVoucher {
  tipe:
    | 'klaim_berulang_berlebih'
    | 'brute_force_gagal'
    | 'pemakaian_kilat'
    | 'kuota_hampir_habis'
    | string
  tingkat: 'peringatan' | 'bahaya'
  pesan: string
  data?: Record<string, unknown>
}

export interface DataLaporanVoucher {
  rentang: {
    tanggal_mulai: string
    tanggal_akhir: string
    jumlah_hari: number
  }
  cabang: {
    id: string | null
    nama: string
  }
  ringkasan: RingkasanVoucher
  per_kampanye: KampanyeVoucher[]
  per_cabang: CabangVoucher[]
  tren_harian: TrenHarianVoucher[]
  klaim_berulang: KlaimBerulang[]
  anomali: AnomaliVoucher[]
}

export interface LaporanVoucherProps {
  data?: DataLaporanVoucher | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggalMulai?: string
  tanggalAkhir?: string
  sedangMemuat?: boolean
  pesanGagal?: string | null
  onPilihCabang?: (cabangId: string) => void
  onPilihRentangTanggal?: (mulai: string, akhir: string) => void
  onMuatUlang?: () => void
}

export const LaporanVoucher: React.FC<LaporanVoucherProps> = ({
  data,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggalMulai = new Date(Date.now() - 29 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
  tanggalAkhir = new Date().toISOString().slice(0, 10),
  sedangMemuat = false,
  pesanGagal = null,
  onPilihCabang,
  onPilihRentangTanggal,
  onMuatUlang,
}) => {
  const { t } = useBahasa()

  const [inputMulai, setInputMulai] = useState(tanggalMulai)
  const [inputAkhir, setInputAkhir] = useState(tanggalAkhir)
  const [pesanValidasi, setPesanValidasi] = useState<string | null>(null)

  const hitungSelisihHari = (mulai: string, akhir: string): number => {
    const tMulai = new Date(mulai).getTime()
    const tAkhir = new Date(akhir).getTime()
    return Math.round((tAkhir - tMulai) / (24 * 60 * 60 * 1000))
  }

  const handleTerapkanTanggal = (e?: React.FormEvent) => {
    e?.preventDefault()
    if (inputAkhir < inputMulai) {
      setPesanValidasi('Tanggal akhir tidak boleh lebih awal dari tanggal mulai.')
      return
    }
    const selisih = hitungSelisihHari(inputMulai, inputAkhir)
    if (selisih > 90) {
      setPesanValidasi(t('laporan.batas_90_hari'))
      return
    }
    setPesanValidasi(null)
    onPilihRentangTanggal?.(inputMulai, inputAkhir)
  }

  if (sedangMemuat) {
    return <KeadaanMemuat judul="Memuat laporan voucher..." />
  }

  if (pesanGagal) {
    return (
      <KeadaanGagal
        judul="Gagal memuat laporan voucher"
        keterangan={pesanGagal}
        onCoba={onMuatUlang}
      />
    )
  }

  if (!data) {
    return (
      <KeadaanKosong
        judul={t('laporan.tidak_ada_voucher')}
        keterangan="Pilih rentang tanggal atau cabang lain untuk melihat aktivitas voucher."
      />
    )
  }

  const { ringkasan, per_kampanye, per_cabang, tren_harian, klaim_berulang, anomali } = data
  const totalAktivitas = (ringkasan.total_klaim ?? 0) + (ringkasan.total_terpakai ?? 0)

  return (
    <div
      className="laporan-voucher"
      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4, 16px)' }}
    >
      {/* Header & Filter */}
      <Kartu>
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3, 12px)',
          }}
        >
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: 'var(--s-2, 8px)',
            }}
          >
            <div>
              <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 600 }}>
                🎟️ {t('laporan.laporan_voucher_judul')}
              </h2>
              <span style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                {data.cabang.nama} • {tanggalLokal(new Date(data.rentang.tanggal_mulai))} s.d.{' '}
                {tanggalLokal(new Date(data.rentang.tanggal_akhir))} ({data.rentang.jumlah_hari}{' '}
                hari)
              </span>
            </div>

            {onMuatUlang && (
              <Tombol ragam="polos" onClick={onMuatUlang}>
                🔄 {t('laporan.muat_ulang')}
              </Tombol>
            )}
          </div>

          {/* Form Filter Rentang Tanggal & Cabang */}
          <form
            onSubmit={handleTerapkanTanggal}
            style={{
              display: 'flex',
              gap: 'var(--s-3, 12px)',
              flexWrap: 'wrap',
              alignItems: 'flex-end',
            }}
          >
            {peranPengguna === 'owner_pusat' && daftarCabang.length > 0 && onPilihCabang && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                <label
                  htmlFor="pilih-cabang-voucher"
                  style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}
                >
                  Cabang
                </label>
                <select
                  id="pilih-cabang-voucher"
                  value={cabangAktifId || ''}
                  onChange={(e) => onPilihCabang(e.target.value)}
                  style={{
                    padding: '6px 10px',
                    borderRadius: 'var(--r-md, 8px)',
                    border: '1px solid var(--border)',
                    backgroundColor: 'var(--surface)',
                    color: 'var(--text)',
                    fontSize: '0.875rem',
                  }}
                >
                  <option value="">{t('laporan.semua_cabang')}</option>
                  {daftarCabang.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.nama}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <label
                htmlFor="tgl-mulai-voucher"
                style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}
              >
                {t('laporan.tanggal_mulai')}
              </label>
              <input
                id="tgl-mulai-voucher"
                type="date"
                value={inputMulai}
                onChange={(e) => setInputMulai(e.target.value)}
                style={{
                  padding: '6px 10px',
                  borderRadius: 'var(--r-md, 8px)',
                  border: '1px solid var(--border)',
                  backgroundColor: 'var(--surface)',
                  color: 'var(--text)',
                  fontSize: '0.875rem',
                }}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
              <label
                htmlFor="tgl-akhir-voucher"
                style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)' }}
              >
                {t('laporan.tanggal_akhir')}
              </label>
              <input
                id="tgl-akhir-voucher"
                type="date"
                value={inputAkhir}
                onChange={(e) => setInputAkhir(e.target.value)}
                style={{
                  padding: '6px 10px',
                  borderRadius: 'var(--r-md, 8px)',
                  border: '1px solid var(--border)',
                  backgroundColor: 'var(--surface)',
                  color: 'var(--text)',
                  fontSize: '0.875rem',
                }}
              />
            </div>

            <Tombol ragam="utama" jenis="submit">
              {t('laporan.terapkan_filter')}
            </Tombol>
          </form>

          {pesanValidasi && (
            <div
              style={{
                fontSize: '0.875rem',
                color: 'var(--danger)',
                marginTop: '4px',
              }}
            >
              ⚠️ {pesanValidasi}
            </div>
          )}
        </div>
      </Kartu>

      {/* Bagian Peringatan Dini & Deteksi Anomali */}
      <Kartu>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2, 8px)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
              🛡️ {t('laporan.deteksi_anomali')}
            </h3>
            {anomali.length > 0 ? (
              <Lencana nada="danger">{anomali.length} Perlu Perhatian</Lencana>
            ) : (
              <Lencana nada="success">Status Bersih</Lencana>
            )}
          </div>

          {anomali.length === 0 ? (
            <div
              data-testid="status-anomali-aman"
              style={{
                fontSize: '0.875rem',
                color: 'var(--success)',
                padding: '8px 12px',
                backgroundColor: 'var(--success-soft)',
                borderRadius: 'var(--r-md, 8px)',
              }}
            >
              ✅ {t('laporan.tidak_ada_anomali')}
            </div>
          ) : (
            <div
              data-testid="daftar-anomali"
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
                marginTop: '4px',
              }}
            >
              {anomali.map((anm, idx) => (
                <div
                  key={idx}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '10px 14px',
                    borderRadius: 'var(--r-md, 8px)',
                    backgroundColor:
                      anm.tingkat === 'bahaya' ? 'var(--danger-soft)' : 'var(--warn-soft)',
                    borderLeft: `4px solid ${
                      anm.tingkat === 'bahaya' ? 'var(--danger)' : 'var(--warn)'
                    }`,
                  }}
                >
                  <span style={{ fontSize: '1.25rem', lineHeight: 1 }}>
                    {anm.tingkat === 'bahaya' ? '🚨' : '⚠️'}
                  </span>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span
                        style={{
                          fontWeight: 600,
                          fontSize: '0.875rem',
                          color: anm.tingkat === 'bahaya' ? 'var(--danger)' : 'var(--warn)',
                        }}
                      >
                        {anm.tipe === 'klaim_berulang_berlebih' && 'Klaim Berulang Melebihi Batas'}
                        {anm.tipe === 'brute_force_gagal' &&
                          'Percobaan Brute Force / Gagal Beruntun'}
                        {anm.tipe === 'pemakaian_kilat' && 'Pemakaian Kilat (< 2 Menit)'}
                        {anm.tipe === 'kuota_hampir_habis' && 'Serapan Anggaran / Kuota >= 80%'}
                        {![
                          'klaim_berulang_berlebih',
                          'brute_force_gagal',
                          'pemakaian_kilat',
                          'kuota_hampir_habis',
                        ].includes(anm.tipe) && anm.tipe}
                      </span>
                      <Lencana nada={anm.tingkat === 'bahaya' ? 'danger' : 'warn'}>
                        {anm.tingkat.toUpperCase()}
                      </Lencana>
                    </div>
                    <span style={{ fontSize: '0.875rem', color: 'var(--text)' }}>{anm.pesan}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </Kartu>

      {/* Kartu Ringkasan Metrik (5 Metrik Utama) */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 'var(--s-3, 12px)',
        }}
      >
        <Kartu>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {t('laporan.total_klaim')}
            </span>
            <span style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--text)' }}>
              {ringkasan.total_klaim}
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              Voucher diterbitkan
            </span>
          </div>
        </Kartu>

        <Kartu>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {t('laporan.total_terpakai')}
            </span>
            <span style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--text)' }}>
              {ringkasan.total_terpakai}
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              Berhasil ditebus
            </span>
          </div>
        </Kartu>

        <Kartu>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {t('laporan.tingkat_konversi')}
            </span>
            <span style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--accent)' }}>
              {ringkasan.tingkat_konversi_persen}%
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              Klaim vs Pemakaian
            </span>
          </div>
        </Kartu>

        <Kartu>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              {t('laporan.total_potongan')}
            </span>
            <span style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--danger)' }}>
              {rupiah(ringkasan.total_potongan)}
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              Biaya diskon resto
            </span>
          </div>
        </Kartu>

        <Kartu>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontWeight: 600 }}>
              Rata-rata Potongan
            </span>
            <span style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--text)' }}>
              {rupiah(ringkasan.rata_rata_potongan)}
            </span>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
              per voucher terpakai
            </span>
          </div>
        </Kartu>
      </div>

      {totalAktivitas === 0 ? (
        <Kartu>
          <div
            style={{
              padding: '24px',
              textAlign: 'center',
              color: 'var(--text-muted)',
              fontSize: '0.875rem',
            }}
          >
            {t('laporan.tidak_ada_voucher')}
          </div>
        </Kartu>
      ) : (
        <>
          {/* Rincian per Kampanye */}
          <Kartu>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3, 12px)' }}>
              <div
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
              >
                <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
                  📢 {t('laporan.per_kampanye')}
                </h3>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  {per_kampanye.length} Kampanye Aktif
                </span>
              </div>

              <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--border)' }}>
                      <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                        Kode & Nama Kampanye
                      </th>
                      <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                        Jenis Diskon
                      </th>
                      <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                        Klaim
                      </th>
                      <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                        Terpakai
                      </th>
                      <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                        Konversi
                      </th>
                      <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                        Total Potongan
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {per_kampanye.map((kmp) => (
                      <tr key={kmp.kampanye_id} style={{ borderBottom: '1px solid var(--border)' }}>
                        <td style={{ padding: '8px' }}>
                          <div style={{ display: 'flex', flexDirection: 'column' }}>
                            <span style={{ fontWeight: 600, color: 'var(--text)' }}>
                              {kmp.kode_kampanye}
                            </span>
                            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                              {kmp.nama_kampanye}
                            </span>
                          </div>
                        </td>
                        <td style={{ padding: '8px' }}>
                          <Lencana nada="info">
                            {kmp.jenis_diskon === 'persen'
                              ? `${kmp.nilai_diskon}%`
                              : rupiah(kmp.nilai_diskon)}
                          </Lencana>
                        </td>
                        <td style={{ textAlign: 'right', padding: '8px' }}>{kmp.total_klaim}</td>
                        <td style={{ textAlign: 'right', padding: '8px' }}>{kmp.total_terpakai}</td>
                        <td style={{ textAlign: 'right', padding: '8px' }}>
                          {kmp.tingkat_konversi_persen}%
                        </td>
                        <td
                          style={{
                            textAlign: 'right',
                            padding: '8px',
                            fontWeight: 600,
                            color: 'var(--danger)',
                          }}
                        >
                          {rupiah(kmp.total_potongan)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </Kartu>

          {/* Rincian per Cabang (bila ada multi-cabang) */}
          {per_cabang.length > 0 && (
            <Kartu>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3, 12px)' }}>
                <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
                  🏢 {t('laporan.per_cabang')}
                </h3>

                <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                  <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--border)' }}>
                        <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                          Nama Cabang
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Total Klaim
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Total Terpakai
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Total Potongan
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {per_cabang.map((cb, idx) => (
                        <tr
                          key={cb.cabang_id ?? idx}
                          style={{ borderBottom: '1px solid var(--border)' }}
                        >
                          <td style={{ padding: '8px', fontWeight: 600 }}>{cb.nama_cabang}</td>
                          <td style={{ textAlign: 'right', padding: '8px' }}>{cb.total_klaim}</td>
                          <td style={{ textAlign: 'right', padding: '8px' }}>
                            {cb.total_terpakai}
                          </td>
                          <td
                            style={{
                              textAlign: 'right',
                              padding: '8px',
                              fontWeight: 600,
                              color: 'var(--danger)',
                            }}
                          >
                            {rupiah(cb.total_potongan)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </Kartu>
          )}

          {/* Tren Harian */}
          {tren_harian.length > 0 && (
            <Kartu>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3, 12px)' }}>
                <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
                  📈 {t('laporan.tren_voucher_harian')}
                </h3>

                <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                  <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--border)' }}>
                        <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                          Tanggal
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Klaim
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Terpakai
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Potongan
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {tren_harian.map((tr) => (
                        <tr key={tr.tanggal} style={{ borderBottom: '1px solid var(--border)' }}>
                          <td style={{ padding: '8px' }}>{tanggalLokal(new Date(tr.tanggal))}</td>
                          <td style={{ textAlign: 'right', padding: '8px' }}>{tr.total_klaim}</td>
                          <td style={{ textAlign: 'right', padding: '8px' }}>
                            {tr.total_terpakai}
                          </td>
                          <td
                            style={{
                              textAlign: 'right',
                              padding: '8px',
                              fontWeight: 600,
                              color: 'var(--danger)',
                            }}
                          >
                            {rupiah(tr.total_potongan)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </Kartu>
          )}

          {/* Identitas Klaim Berulang (PRD M10 / T8-13 DoD 3) */}
          <Kartu>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3, 12px)' }}>
              <div
                style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
              >
                <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
                  👥 {t('laporan.klaim_berulang')}
                </h3>
                <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  Minimal 2 klaim pada periode ini
                </span>
              </div>

              {klaim_berulang.length === 0 ? (
                <div
                  style={{
                    padding: '12px',
                    color: 'var(--text-muted)',
                    fontSize: '0.875rem',
                    textAlign: 'center',
                  }}
                >
                  Tidak ada identitas pelanggan dengan klaim berulang (≥ 2 kali).
                </div>
              ) : (
                <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                  <table
                    className="table"
                    data-testid="tabel-klaim-berulang"
                    style={{ width: '100%', borderCollapse: 'collapse' }}
                  >
                    <thead>
                      <tr style={{ borderBottom: '1px solid var(--border)' }}>
                        <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                          Nama Pelanggan
                        </th>
                        <th scope="col" style={{ textAlign: 'left', padding: '8px' }}>
                          Nomor HP
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Total Klaim
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Terpakai
                        </th>
                        <th scope="col" style={{ textAlign: 'right', padding: '8px' }}>
                          Total Potongan
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {klaim_berulang.map((kb) => (
                        <tr
                          key={kb.pelanggan_id}
                          style={{ borderBottom: '1px solid var(--border)' }}
                        >
                          <td style={{ padding: '8px', fontWeight: 600 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <span>{kb.nama || 'Tanpa Nama'}</span>
                              {kb.jumlah_klaim > 3 && (
                                <Lencana nada="warn">Frekuensi Tinggi</Lencana>
                              )}
                            </div>
                          </td>
                          <td style={{ padding: '8px', color: 'var(--text-muted)' }}>
                            {kb.nomor_hp || '-'}
                          </td>
                          <td style={{ textAlign: 'right', padding: '8px', fontWeight: 600 }}>
                            {kb.jumlah_klaim}
                          </td>
                          <td style={{ textAlign: 'right', padding: '8px' }}>
                            {kb.jumlah_terpakai}
                          </td>
                          <td
                            style={{
                              textAlign: 'right',
                              padding: '8px',
                              fontWeight: 600,
                              color: 'var(--danger)',
                            }}
                          >
                            {rupiah(kb.total_potongan)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </Kartu>
        </>
      )}
    </div>
  )
}

export default LaporanVoucher
