/**
 * LaporanPenjualan.tsx (T7-08) — Laporan Penjualan Dasar (Kategori, Metode Bayar, Tren Harian).
 *
 * Mengacu pada PRD M8 (Dari mana uang datang) & TECH_SPEC §5:
 *  - Omzet per kategori menu & jenis menu (makanan, minuman, lainnya)
 *  - Rincian metode bayar & kontribusi persentase
 *  - Tren penjualan harian dalam rentang tanggal (maks 90 hari)
 *  - Ringkasan total transaksi, subtotal, diskon, pajak, service, rata-rata transaksi
 *  - Tampilan per cabang & multi-cabang (owner_pusat)
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

export interface KategoriPenjualan {
  kategori_id: string | null
  kategori_nama: string
  qty_terjual: number
  total_omzet: number
  persentase: number
}

export interface MetodePenjualan {
  metode_id: string | null
  metode_nama: string
  jenis: string
  jumlah_transaksi: number
  total_nominal: number
  persentase: number
}

export interface TrenHarianPenjualan {
  tanggal: string
  jumlah_transaksi: number
  omzet_makanan: number
  omzet_minuman: number
  omzet_lainnya: number
  total_diskon: number
  total_omzet: number
}

export interface DataLaporanPenjualan {
  rentang: {
    tanggal_mulai: string
    tanggal_akhir: string
    jumlah_hari: number
  }
  cabang: {
    id: string | null
    nama: string
  }
  ringkasan: {
    total_omzet: number
    total_subtotal: number
    total_pajak: number
    total_service: number
    total_diskon: number
    total_transaksi: number
    rata_rata_transaksi: number
  }
  jenis_menu: {
    omzet_makanan: number
    omzet_minuman: number
    omzet_lainnya: number
  }
  per_kategori: KategoriPenjualan[]
  per_metode: MetodePenjualan[]
  tren_harian: TrenHarianPenjualan[]
}

export interface LaporanPenjualanProps {
  data?: DataLaporanPenjualan | null
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

export const LaporanPenjualan: React.FC<LaporanPenjualanProps> = ({
  data,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggalMulai = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
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

  const formatTgl = (tglStr: string) => {
    try {
      return tanggalLokal(new Date(tglStr))
    } catch {
      return tglStr
    }
  }

  if (sedangMemuat) {
    return <KeadaanMemuat judul={t('memuat')} />
  }

  if (pesanGagal) {
    return (
      <KeadaanGagal
        judul="Gagal memuat laporan penjualan"
        keterangan={pesanGagal}
        onCoba={onMuatUlang}
      />
    )
  }

  const bisaGantiCabang = peranPengguna === 'owner_pusat'

  return (
    <div
      className="laporan-penjualan-kontainer"
      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4, 16px)' }}
    >
      {/* 1. Bilah Filter Cabang & Rentang Tanggal */}
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
            {t('laporan.tab_penjualan')}
          </h2>
          <Lencana nada="info">{data?.cabang?.nama || t('laporan.semua_cabang')}</Lencana>
          {data?.rentang && (
            <span
              style={{
                fontSize: 'var(--t-2, 0.75rem)',
                color: 'var(--text-muted)',
              }}
            >
              ({data.rentang.tanggal_mulai} s/d {data.rentang.tanggal_akhir} ·{' '}
              {data.rentang.jumlah_hari} hari)
            </span>
          )}
        </div>

        <form
          onSubmit={handleTerapkanTanggal}
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
                htmlFor="pilih-cabang-penjualan"
                style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
              >
                📍 {t('cabang')}:
              </label>
              {bisaGantiCabang ? (
                <select
                  id="pilih-cabang-penjualan"
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

          {/* Pemilih Rentang Tanggal */}
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-1, 4px)' }}>
            <label
              htmlFor="tgl-mulai-penjualan"
              style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
            >
              📅 {t('laporan.tanggal_mulai')}:
            </label>
            <input
              id="tgl-mulai-penjualan"
              type="date"
              className="input"
              value={inputMulai}
              onChange={(e) => setInputMulai(e.target.value)}
              style={{
                padding: 'var(--s-1, 4px) var(--s-2, 8px)',
                height: '38px',
                fontSize: 'var(--t-3, 0.875rem)',
              }}
            />
          </div>

          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-1, 4px)' }}>
            <label
              htmlFor="tgl-akhir-penjualan"
              style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
            >
              s/d
            </label>
            <input
              id="tgl-akhir-penjualan"
              type="date"
              className="input"
              value={inputAkhir}
              onChange={(e) => setInputAkhir(e.target.value)}
              style={{
                padding: 'var(--s-1, 4px) var(--s-2, 8px)',
                height: '38px',
                fontSize: 'var(--t-3, 0.875rem)',
              }}
            />
          </div>

          <Tombol ragam="utama" jenis="submit" onClick={() => handleTerapkanTanggal()}>
            {t('laporan.terapkan_filter')}
          </Tombol>

          {onMuatUlang && (
            <Tombol ragam="biasa" jenis="button" onClick={onMuatUlang}>
              🔄 {t('ulang')}
            </Tombol>
          )}
        </form>
      </section>

      {/* Pesan Validasi Rentang Tanggal */}
      {pesanValidasi && (
        <div
          role="alert"
          style={{
            padding: 'var(--s-2, 8px) var(--s-3, 12px)',
            backgroundColor: 'var(--danger-soft)',
            color: 'var(--danger)',
            borderRadius: '6px',
            fontSize: 'var(--t-3, 0.875rem)',
            fontWeight: 500,
          }}
        >
          ⚠️ {pesanValidasi}
        </div>
      )}

      {!data ? (
        <KeadaanKosong judul={t('kosong')} keterangan={t('laporan.tidak_ada_data')} />
      ) : (
        <>
          {/* 2. Kartu KPI Ringkasan Penjualan */}
          <section
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: 'var(--s-3, 12px)',
            }}
          >
            {/* Total Omzet */}
            <Kartu judul={t('laporan.omset_penjualan')}>
              <div
                style={{
                  fontSize: 'var(--t-6, 1.5rem)',
                  fontWeight: 700,
                  color: 'var(--success)',
                }}
              >
                {rupiah(data.ringkasan.total_omzet)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Subtotal: {rupiah(data.ringkasan.total_subtotal)}
              </div>
            </Kartu>

            {/* Transaksi Selesai */}
            <Kartu judul={t('laporan.transaksi_selesai')}>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700 }}>
                {data.ringkasan.total_transaksi}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Pesanan Lunas Selesai
              </div>
            </Kartu>

            {/* Rata-rata per Transaksi */}
            <Kartu judul={t('laporan.rata_rata_transaksi')}>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700 }}>
                {rupiah(data.ringkasan.rata_rata_transaksi)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Rata-rata Nilai Belanja
              </div>
            </Kartu>

            {/* Total Diskon */}
            <Kartu judul={t('laporan.total_diskon')}>
              <div
                style={{
                  fontSize: 'var(--t-6, 1.5rem)',
                  fontWeight: 700,
                  color: 'var(--warn)',
                }}
              >
                {rupiah(data.ringkasan.total_diskon)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                PB1: {rupiah(data.ringkasan.total_pajak)} · Serv:{' '}
                {rupiah(data.ringkasan.total_service)}
              </div>
            </Kartu>
          </section>

          {/* 3. Pembagian Jenis Menu (Makanan, Minuman, Lainnya) */}
          <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
            <h3
              style={{
                margin: '0 0 var(--s-3, 12px) 0',
                fontSize: 'var(--t-4, 1.125rem)',
                fontWeight: 600,
              }}
            >
              🍽️ Pembagian Jenis Menu
            </h3>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                gap: 'var(--s-3, 12px)',
              }}
            >
              <div
                style={{
                  padding: 'var(--s-3, 12px)',
                  borderRadius: '8px',
                  backgroundColor: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                }}
              >
                <div style={{ fontSize: 'var(--t-2, 0.75rem)', fontWeight: 600 }}>
                  🍛 {t('laporan.omzet_makanan')}
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-5, 1.25rem)',
                    fontWeight: 700,
                    marginTop: '4px',
                  }}
                >
                  {rupiah(data.jenis_menu.omzet_makanan)}
                </div>
              </div>

              <div
                style={{
                  padding: 'var(--s-3, 12px)',
                  borderRadius: '8px',
                  backgroundColor: 'var(--surface-2)',
                  border: '1px solid var(--border)',
                }}
              >
                <div style={{ fontSize: 'var(--t-2, 0.75rem)', fontWeight: 600 }}>
                  🥤 {t('laporan.omzet_minuman')}
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-5, 1.25rem)',
                    fontWeight: 700,
                    marginTop: '4px',
                  }}
                >
                  {rupiah(data.jenis_menu.omzet_minuman)}
                </div>
              </div>

              {data.jenis_menu.omzet_lainnya > 0 && (
                <div
                  style={{
                    padding: 'var(--s-3, 12px)',
                    borderRadius: '8px',
                    backgroundColor: 'var(--surface-2)',
                    border: '1px solid var(--border)',
                  }}
                >
                  <div style={{ fontSize: 'var(--t-2, 0.75rem)', fontWeight: 600 }}>
                    📦 {t('laporan.omzet_lainnya')}
                  </div>
                  <div
                    style={{
                      fontSize: 'var(--t-5, 1.25rem)',
                      fontWeight: 700,
                      marginTop: '4px',
                    }}
                  >
                    {rupiah(data.jenis_menu.omzet_lainnya)}
                  </div>
                </div>
              )}
            </div>
          </section>

          {/* 4. Rincian Omzet per Kategori & Metode Bayar (Dua Kolom di Layar Lebar) */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
              gap: 'var(--s-4, 16px)',
            }}
          >
            {/* Omzet per Kategori */}
            <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
              <h3
                style={{
                  margin: '0 0 var(--s-3, 12px) 0',
                  fontSize: 'var(--t-4, 1.125rem)',
                  fontWeight: 600,
                }}
              >
                🏷️ {t('laporan.omzet_kategori')}
              </h3>
              {data.per_kategori.length === 0 ? (
                <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  {t('laporan.tidak_ada_data')}
                </div>
              ) : (
                <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                  <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr
                        style={{
                          borderBottom: '2px solid var(--border)',
                          textAlign: 'left',
                        }}
                      >
                        <th style={{ padding: '8px' }}>Kategori</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.qty_terjual')}
                        </th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.omset_penjualan')}
                        </th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.persentase')}
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.per_kategori.map((kat, idx) => (
                        <tr
                          key={kat.kategori_id || idx}
                          style={{ borderBottom: '1px solid var(--border)' }}
                        >
                          <td style={{ padding: '8px', fontWeight: 600 }}>
                            {kat.kategori_nama || t('laporan.tanpa_kategori')}
                          </td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>{kat.qty_terjual}</td>
                          <td style={{ padding: '8px', textAlign: 'right', fontWeight: 600 }}>
                            {rupiah(kat.total_omzet)}
                          </td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>
                            <Lencana nada="netral">{kat.persentase}%</Lencana>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>

            {/* Rincian Metode Bayar */}
            <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
              <h3
                style={{
                  margin: '0 0 var(--s-3, 12px) 0',
                  fontSize: 'var(--t-4, 1.125rem)',
                  fontWeight: 600,
                }}
              >
                💳 {t('laporan.rincian_metode')}
              </h3>
              {data.per_metode.length === 0 ? (
                <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  {t('laporan.tidak_ada_data')}
                </div>
              ) : (
                <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                  <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr
                        style={{
                          borderBottom: '2px solid var(--border)',
                          textAlign: 'left',
                        }}
                      >
                        <th style={{ padding: '8px' }}>Metode</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.jumlah_transaksi')}
                        </th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>Total Nominal</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.persentase')}
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.per_metode.map((met, idx) => (
                        <tr
                          key={met.metode_id || idx}
                          style={{ borderBottom: '1px solid var(--border)' }}
                        >
                          <td style={{ padding: '8px', fontWeight: 600 }}>
                            {met.metode_nama}{' '}
                            <span
                              style={{
                                fontSize: 'var(--t-2, 0.75rem)',
                                color: 'var(--text-muted)',
                              }}
                            >
                              ({met.jenis})
                            </span>
                          </td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>
                            {met.jumlah_transaksi}
                          </td>
                          <td style={{ padding: '8px', textAlign: 'right', fontWeight: 600 }}>
                            {rupiah(met.total_nominal)}
                          </td>
                          <td style={{ padding: '8px', textAlign: 'right' }}>
                            <Lencana nada="info">{met.persentase}%</Lencana>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>
          </div>

          {/* 5. Tren Penjualan Harian */}
          <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
            <h3
              style={{
                margin: '0 0 var(--s-3, 12px) 0',
                fontSize: 'var(--t-4, 1.125rem)',
                fontWeight: 600,
              }}
            >
              📈 {t('laporan.tren_harian')}
            </h3>
            {data.tren_harian.length === 0 ? (
              <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                {t('laporan.tidak_ada_data')}
              </div>
            ) : (
              <div className="tabel-bungkus" style={{ overflowX: 'auto' }}>
                <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr
                      style={{
                        borderBottom: '2px solid var(--border)',
                        textAlign: 'left',
                      }}
                    >
                      <th style={{ padding: '8px' }}>Tanggal</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.jumlah_transaksi')}
                      </th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.omzet_makanan')}
                      </th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.omzet_minuman')}
                      </th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.total_diskon')}
                      </th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.omset_penjualan')}
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.tren_harian.map((tr) => (
                      <tr key={tr.tanggal} style={{ borderBottom: '1px solid var(--border)' }}>
                        <td style={{ padding: '8px', fontWeight: 600 }}>{formatTgl(tr.tanggal)}</td>
                        <td style={{ padding: '8px', textAlign: 'right' }}>
                          {tr.jumlah_transaksi}
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right' }}>
                          {rupiah(tr.omzet_makanan)}
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right' }}>
                          {rupiah(tr.omzet_minuman)}
                        </td>
                        <td
                          style={{
                            padding: '8px',
                            textAlign: 'right',
                            color: tr.total_diskon > 0 ? 'var(--warn)' : 'inherit',
                          }}
                        >
                          {tr.total_diskon > 0 ? `- ${rupiah(tr.total_diskon)}` : 'Rp 0'}
                        </td>
                        <td
                          style={{
                            padding: '8px',
                            textAlign: 'right',
                            fontWeight: 700,
                            color: tr.total_omzet > 0 ? 'var(--success)' : 'inherit',
                          }}
                        >
                          {rupiah(tr.total_omzet)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        </>
      )}
    </div>
  )
}

export default LaporanPenjualan
