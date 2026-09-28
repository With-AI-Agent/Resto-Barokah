/**
 * LaporanMenu.tsx (T7-09) — Laporan Menu Terlaris & Diskon / Voucher Terpakai.
 *
 * Mengacu pada PRD M8 & M10 (Menu andalan & biaya promosi):
 *  - Peringkat menu terlaris berdasarkan omzet (nilai) atau porsi (jumlah)
 *  - Menggunakan nama_saat_itu agar laporan historis kebal terhadap perubahan nama/harga menu
 *  - Rincian diskon manual terpakai (alasan, nilai, kasir pemberi, atasan penyetuju)
 *  - Rincian voucher/promo terpakai (kode voucher, nilai, kasir pemakai)
 *  - Ringkasan total porsi terjual, total omzet menu, dan total biaya promosi
 */

import React, { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, tanggalLokal, jamLokal } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export interface ItemMenuTerlaris {
  menu_item_id: string | null
  nama_menu: string
  kategori_nama: string
  jenis: string
  qty_terjual: number
  total_omzet: number
  rata_harga: number
  persentase: number
}

export interface ItemDiskonManual {
  id: string
  pesanan_id: string
  nomor_pesanan: number
  tanggal: string
  waktu: string
  persen: number | null
  nominal: number | null
  nilai: number
  alasan: string
  pelaku_id: string | null
  kasir_nama: string | null
  penyetuju_id: string | null
  penyetuju_nama: string | null
}

export interface ItemVoucherTerpakai {
  id: string
  pesanan_id: string
  nomor_pesanan: number
  tanggal: string
  waktu: string
  kode_voucher: string
  nilai: number
  pelaku_id: string | null
  kasir_nama: string | null
  penyetuju_id: string | null
  penyetuju_nama: string | null
}

export interface DataLaporanMenu {
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
    total_porsi: number
    total_omzet_menu: number
    total_diskon_manual: number
    total_voucher: number
    total_biaya_promosi: number
  }
  peringkat_menu: ItemMenuTerlaris[]
  diskon_manual: ItemDiskonManual[]
  voucher_terpakai: ItemVoucherTerpakai[]
}

export interface LaporanMenuProps {
  data?: DataLaporanMenu | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggalMulai?: string
  tanggalAkhir?: string
  urutBerdasarkan?: 'nilai' | 'jumlah'
  sedangMemuat?: boolean
  pesanGagal?: string | null
  onPilihCabang?: (cabangId: string) => void
  onPilihRentangTanggal?: (mulai: string, akhir: string) => void
  onGantiUrutan?: (urutan: 'nilai' | 'jumlah') => void
  onMuatUlang?: () => void
}

export const LaporanMenu: React.FC<LaporanMenuProps> = ({
  data,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggalMulai = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
  tanggalAkhir = new Date().toISOString().slice(0, 10),
  urutBerdasarkan = 'nilai',
  sedangMemuat = false,
  pesanGagal = null,
  onPilihCabang,
  onPilihRentangTanggal,
  onGantiUrutan,
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

  const formatWaktu = (isoString: string) => {
    try {
      const d = new Date(isoString)
      return `${tanggalLokal(d)}, ${jamLokal(d)}`
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
        judul="Gagal memuat laporan menu"
        keterangan={pesanGagal}
        onCoba={onMuatUlang}
      />
    )
  }

  const bisaGantiCabang = peranPengguna === 'owner_pusat'

  return (
    <div
      className="laporan-menu-kontainer"
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
            {t('laporan.tab_menu')}
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
                htmlFor="pilih-cabang-menu"
                style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
              >
                📍 {t('cabang')}:
              </label>
              {bisaGantiCabang ? (
                <select
                  id="pilih-cabang-menu"
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
              htmlFor="tgl-mulai-menu"
              style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
            >
              📅 {t('laporan.tanggal_mulai')}:
            </label>
            <input
              id="tgl-mulai-menu"
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
              htmlFor="tgl-akhir-menu"
              style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
            >
              s/d
            </label>
            <input
              id="tgl-akhir-menu"
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

      {/* Pesan Validasi */}
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
        <KeadaanKosong
          judul={t('kosong')}
          keterangan="Tidak ada data menu dan promosi pada periode ini."
        />
      ) : (
        <>
          {/* 2. Kartu KPI Ringkasan Menu & Promosi */}
          <section
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
              gap: 'var(--s-3, 12px)',
            }}
          >
            {/* Total Porsi Menu Terjual */}
            <Kartu judul={t('laporan.qty_terjual')}>
              <div
                style={{
                  fontSize: 'var(--t-6, 1.5rem)',
                  fontWeight: 700,
                  color: 'var(--success)',
                }}
              >
                {data.ringkasan.total_porsi} Porsi
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Total Item Menu Terpesan
              </div>
            </Kartu>

            {/* Total Omzet Menu */}
            <Kartu judul={t('laporan.omset_penjualan')}>
              <div style={{ fontSize: 'var(--t-6, 1.5rem)', fontWeight: 700 }}>
                {rupiah(data.ringkasan.total_omzet_menu)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Omzet Kotor dari Menu
              </div>
            </Kartu>

            {/* Total Diskon Manual */}
            <Kartu judul={t('laporan.diskon_manual')}>
              <div
                style={{
                  fontSize: 'var(--t-6, 1.5rem)',
                  fontWeight: 700,
                  color: 'var(--warn)',
                }}
              >
                {rupiah(data.ringkasan.total_diskon_manual)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                {data.diskon_manual.length} Transaksi Berdiskon
              </div>
            </Kartu>

            {/* Total Biaya Promosi */}
            <Kartu judul={t('laporan.biaya_promosi')}>
              <div
                style={{
                  fontSize: 'var(--t-6, 1.5rem)',
                  fontWeight: 700,
                  color: 'var(--danger)',
                }}
              >
                {rupiah(data.ringkasan.total_biaya_promosi)}
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2, 0.75rem)',
                  color: 'var(--text-muted)',
                  marginTop: '4px',
                }}
              >
                Diskon Manual + Voucher
              </div>
            </Kartu>
          </section>

          {/* 3. Peringkat Menu Terlaris */}
          <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '8px',
                marginBottom: 'var(--s-3, 12px)',
              }}
            >
              <h3
                style={{
                  margin: 0,
                  fontSize: 'var(--t-4, 1.125rem)',
                  fontWeight: 600,
                }}
              >
                🏆 {t('laporan.menu_terlaris')}
              </h3>

              <div style={{ display: 'flex', gap: '8px' }}>
                <Tombol
                  ragam={urutBerdasarkan === 'nilai' ? 'utama' : 'polos'}
                  jenis="button"
                  onClick={() => onGantiUrutan?.('nilai')}
                >
                  💰 {t('laporan.urut_nilai')}
                </Tombol>
                <Tombol
                  ragam={urutBerdasarkan === 'jumlah' ? 'utama' : 'polos'}
                  jenis="button"
                  onClick={() => onGantiUrutan?.('jumlah')}
                >
                  📦 {t('laporan.urut_jumlah')}
                </Tombol>
              </div>
            </div>

            {data.peringkat_menu.length === 0 ? (
              <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                Belum ada data menu terjual pada rentang tanggal ini.
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
                      <th style={{ padding: '8px', width: '50px' }}>#</th>
                      <th style={{ padding: '8px' }}>Menu</th>
                      <th style={{ padding: '8px' }}>Kategori</th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.qty_terjual')}
                      </th>
                      <th style={{ padding: '8px', textAlign: 'right' }}>
                        {t('laporan.rata_harga')}
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
                    {data.peringkat_menu.map((menu, idx) => (
                      <tr
                        key={menu.menu_item_id || `${menu.nama_menu}-${idx}`}
                        style={{ borderBottom: '1px solid var(--border)' }}
                      >
                        <td
                          style={{
                            padding: '8px',
                            fontWeight: 700,
                            color: 'var(--text-muted)',
                          }}
                        >
                          {idx + 1}
                        </td>
                        <td style={{ padding: '8px', fontWeight: 600 }}>{menu.nama_menu}</td>
                        <td style={{ padding: '8px' }}>
                          <Lencana nada="netral">{menu.kategori_nama}</Lencana>
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right', fontWeight: 600 }}>
                          {menu.qty_terjual}
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right' }}>
                          {rupiah(menu.rata_harga)}
                        </td>
                        <td
                          style={{
                            padding: '8px',
                            textAlign: 'right',
                            fontWeight: 700,
                            color: 'var(--success)',
                          }}
                        >
                          {rupiah(menu.total_omzet)}
                        </td>
                        <td style={{ padding: '8px', textAlign: 'right' }}>
                          <Lencana nada="info">{menu.persentase}%</Lencana>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>

          {/* 4. Rincian Diskon Manual & Voucher Terpakai */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
              gap: 'var(--s-4, 16px)',
            }}
          >
            {/* Daftar Diskon Manual */}
            <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
              <h3
                style={{
                  margin: '0 0 var(--s-3, 12px) 0',
                  fontSize: 'var(--t-4, 1.125rem)',
                  fontWeight: 600,
                }}
              >
                🏷️ {t('laporan.diskon_manual')} ({data.diskon_manual.length})
              </h3>

              {data.diskon_manual.length === 0 ? (
                <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  Tidak ada pemberian diskon manual pada periode ini.
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
                        <th style={{ padding: '8px' }}>Pesanan</th>
                        <th style={{ padding: '8px' }}>Alasan</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.potongan')}
                        </th>
                        <th style={{ padding: '8px' }}>{t('laporan.kasir_pemberi')}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.diskon_manual.map((dm) => (
                        <tr key={dm.id} style={{ borderBottom: '1px solid var(--border)' }}>
                          <td style={{ padding: '8px', fontWeight: 600 }}>
                            #{dm.nomor_pesanan}
                            <div
                              style={{
                                fontSize: 'var(--t-2, 0.75rem)',
                                color: 'var(--text-muted)',
                              }}
                            >
                              {formatWaktu(dm.waktu)}
                            </div>
                          </td>
                          <td style={{ padding: '8px' }}>{dm.alasan}</td>
                          <td
                            style={{
                              padding: '8px',
                              textAlign: 'right',
                              fontWeight: 700,
                              color: 'var(--warn)',
                            }}
                          >
                            - {rupiah(dm.nilai)}
                          </td>
                          <td style={{ padding: '8px', fontSize: 'var(--t-2, 0.75rem)' }}>
                            <div>{dm.kasir_nama || 'Kasir'}</div>
                            {dm.penyetuju_nama && (
                              <div style={{ color: 'var(--text-muted)' }}>
                                Acc: {dm.penyetuju_nama}
                              </div>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>

            {/* Daftar Voucher Terpakai */}
            <section className="card" style={{ padding: 'var(--s-4, 16px)' }}>
              <h3
                style={{
                  margin: '0 0 var(--s-3, 12px) 0',
                  fontSize: 'var(--t-4, 1.125rem)',
                  fontWeight: 600,
                }}
              >
                🎟️ {t('laporan.voucher_terpakai')} ({data.voucher_terpakai.length})
              </h3>

              {data.voucher_terpakai.length === 0 ? (
                <div style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  Tidak ada penukaran voucher atau promo pada periode ini.
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
                        <th style={{ padding: '8px' }}>Pesanan</th>
                        <th style={{ padding: '8px' }}>Kode / Promo</th>
                        <th style={{ padding: '8px', textAlign: 'right' }}>
                          {t('laporan.potongan')}
                        </th>
                        <th style={{ padding: '8px' }}>{t('laporan.kasir_pemberi')}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.voucher_terpakai.map((vc) => (
                        <tr key={vc.id} style={{ borderBottom: '1px solid var(--border)' }}>
                          <td style={{ padding: '8px', fontWeight: 600 }}>
                            #{vc.nomor_pesanan}
                            <div
                              style={{
                                fontSize: 'var(--t-2, 0.75rem)',
                                color: 'var(--text-muted)',
                              }}
                            >
                              {formatWaktu(vc.waktu)}
                            </div>
                          </td>
                          <td style={{ padding: '8px' }}>
                            <Lencana nada="info">{vc.kode_voucher}</Lencana>
                          </td>
                          <td
                            style={{
                              padding: '8px',
                              textAlign: 'right',
                              fontWeight: 700,
                              color: 'var(--warn)',
                            }}
                          >
                            - {rupiah(vc.nilai)}
                          </td>
                          <td style={{ padding: '8px', fontSize: 'var(--t-2, 0.75rem)' }}>
                            {vc.kasir_nama || 'Kasir'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </section>
          </div>
        </>
      )}
    </div>
  )
}

export default LaporanMenu
