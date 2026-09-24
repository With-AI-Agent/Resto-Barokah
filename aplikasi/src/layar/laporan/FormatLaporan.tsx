/**
 * FormatLaporan.tsx (T7-10) — Tampilan Laporan Siap Cetak / Simpan PDF + Filter Cabang.
 *
 * Mengacu pada PRD M8 & TECH_SPEC §5:
 *  - Tata letak rapi standar cetak kertas A4 / simpan berkas PDF untuk pembukuan pemilik
 *  - Filter cabang sesuai peran: owner_pusat bisa memilih cabang atau konsolidasi semua cabang;
 *    admin_cabang terkunci pada cabangnya sendiri (mitigasi kebocoran lintas cabang T2-07)
 *  - Memuat judul resmi, periode tanggal, identitas cabang, ringkasan penjualan, metode bayar,
 *    rekonsiliasi kas shift, menu andalan, biaya promosi/pembatalan, serta kolom tanda tangan pemilik.
 */

import React from 'react'
import { Tombol } from '../../komponen/Tombol'
import { rupiah, tanggalLokal, jamLokal } from '../../lib/format'
import { useBahasa } from '../../bahasa'
import type { DataLaporanPenjualan } from './LaporanPenjualan'
import type { DataLaporanHarian } from './LaporanKas'
import type { DataLaporanMenu } from './LaporanMenu'

export interface FormatLaporanProps {
  dataPenjualan?: DataLaporanPenjualan | null
  dataHarian?: DataLaporanHarian | null
  dataMenu?: DataLaporanMenu | null
  daftarCabang?: Array<{ id: string; nama: string }>
  cabangAktifId?: string | null
  peranPengguna?: 'owner_pusat' | 'admin_cabang' | 'kasir'
  tanggal?: string
  tanggalMulai?: string
  tanggalAkhir?: string
  namaPetugas?: string
  namaPemilik?: string
  onPilihCabang?: (cabangId: string) => void
  onTutup?: () => void
  onCetak?: () => void
}

export const FormatLaporan: React.FC<FormatLaporanProps> = ({
  dataPenjualan,
  dataHarian,
  dataMenu,
  daftarCabang = [],
  cabangAktifId = null,
  peranPengguna = 'owner_pusat',
  tanggal,
  tanggalMulai,
  tanggalAkhir,
  namaPetugas = 'Petugas Kasir',
  namaPemilik = 'Lee (Pemilik)',
  onPilihCabang,
  onTutup,
  onCetak,
}) => {
  const { t } = useBahasa()

  const tanganiCetak = () => {
    if (onCetak) {
      onCetak()
    } else {
      window.print()
    }
  }

  const bisaPilihCabang = peranPengguna === 'owner_pusat'
  const namaCabangTerpilih =
    daftarCabang.find((c) => c.id === cabangAktifId)?.nama ||
    dataHarian?.nama_cabang ||
    dataPenjualan?.cabang?.nama ||
    t('laporan.semua_cabang')

  const periodeTeks = tanggal
    ? tanggalLokal(new Date(tanggal))
    : tanggalMulai && tanggalAkhir
      ? `${tanggalMulai} s/d ${tanggalAkhir}`
      : tanggalLokal(new Date())

  const waktuSekarang = `${tanggalLokal(new Date())}, ${jamLokal(new Date())}`

  // Data Keuangan (prioritaskan dataPenjualan, lalu fallback ke dataHarian)
  const omzetTotal = dataPenjualan?.ringkasan.total_omzet ?? dataHarian?.penjualan.omzet_total ?? 0
  const subtotalTotal =
    dataPenjualan?.ringkasan.total_subtotal ?? dataHarian?.penjualan.omzet_total ?? 0
  const pajakTotal = dataPenjualan?.ringkasan.total_pajak ?? 0
  const serviceTotal = dataPenjualan?.ringkasan.total_service ?? 0
  const diskonTotal =
    dataPenjualan?.ringkasan.total_diskon ?? dataHarian?.penjualan.total_diskon ?? 0
  const totalTransaksi =
    dataPenjualan?.ringkasan.total_transaksi ?? dataHarian?.penjualan.jumlah_transaksi ?? 0

  return (
    <div className="format-laporan-bungkus" style={{ padding: 'var(--s-3, 12px) 0' }}>
      {/* Bilah Aksi & Filter (Disembunyikan saat dicetak via @media print) */}
      <div
        className="format-laporan__bilah-aksi"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 'var(--s-3, 12px)',
          maxWidth: '850px',
          margin: '0 auto var(--s-3, 12px) auto',
          padding: 'var(--s-3, 12px)',
          backgroundColor: 'var(--surface-2, #f9fafb)',
          borderRadius: 'var(--radius, 8px)',
          border: '1px solid var(--border, #e5e7eb)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2, 8px)' }}>
          {onTutup && (
            <Tombol ragam="biasa" onClick={onTutup}>
              ← {t('laporan.kembali_ke_laporan')}
            </Tombol>
          )}

          {daftarCabang.length > 0 && (
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 'var(--s-1, 4px)' }}>
              <label
                htmlFor="pilih-cabang-cetak"
                style={{ fontSize: 'var(--t-3, 0.875rem)', fontWeight: 600 }}
              >
                📍 {t('cabang')}:
              </label>
              {bisaPilihCabang ? (
                <select
                  id="pilih-cabang-cetak"
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
                <span
                  style={{
                    fontWeight: 600,
                    fontSize: 'var(--t-3, 0.875rem)',
                    padding: '4px 8px',
                    background: 'var(--surface, #fff)',
                    border: '1px solid var(--border, #ddd)',
                    borderRadius: '4px',
                  }}
                >
                  {namaCabangTerpilih}
                </span>
              )}
            </div>
          )}
        </div>

        <Tombol ragam="utama" onClick={tanganiCetak}>
          🖨️ {t('laporan.cetak_laporan')}
        </Tombol>
      </div>

      {/* Lembar Dokumen Siap Cetak (A4 / PDF Friendly) */}
      <article className="format-laporan" data-testid="lembar-laporan-cetak">
        {/* Kop Surat / Identitas Resto */}
        <header className="format-laporan__header">
          <div>
            <h1
              style={{
                margin: 0,
                fontSize: 'var(--t-6, 1.5rem)',
                fontWeight: 800,
                letterSpacing: '-0.02em',
              }}
            >
              RESTO BAROKAH
            </h1>
            <div
              style={{
                fontSize: 'var(--t-4, 1.125rem)',
                fontWeight: 600,
                marginTop: '4px',
                color: 'var(--warna-teks-redup, #4b5563)',
              }}
            >
              {t('laporan.judul')}
            </div>
          </div>
          <div style={{ textAlign: 'right', fontSize: 'var(--t-2, 0.75rem)' }}>
            <div>
              <strong>{t('cabang')}:</strong> {namaCabangTerpilih}
            </div>
            <div>
              <strong>{t('laporan.rentang_tanggal')}:</strong> {periodeTeks}
            </div>
            <div>
              <strong>{t('laporan.waktu_cetak')}:</strong> {waktuSekarang}
            </div>
          </div>
        </header>

        {/* 1. Ringkasan Rekapitulasi Keuangan */}
        <section style={{ marginBottom: 'var(--s-4, 16px)' }}>
          <h2
            style={{
              fontSize: 'var(--t-4, 1.125rem)',
              margin: '0 0 var(--s-2, 8px) 0',
              borderBottom: '1px solid var(--border, #e5e7eb)',
              paddingBottom: '4px',
            }}
          >
            1. {t('laporan.omset_penjualan')}
          </h2>
          <table className="format-laporan__tabel">
            <tbody>
              <tr>
                <td style={{ width: '40%' }}>{t('laporan.total_subtotal')}</td>
                <td style={{ textAlign: 'right', fontWeight: 600 }}>{rupiah(subtotalTotal)}</td>
              </tr>
              {diskonTotal > 0 && (
                <tr>
                  <td>{t('laporan.diskon_manual')} / Potongan Promo</td>
                  <td style={{ textAlign: 'right', color: 'var(--warna-peringatan, #b45309)' }}>
                    - {rupiah(diskonTotal)}
                  </td>
                </tr>
              )}
              {pajakTotal > 0 && (
                <tr>
                  <td>{t('laporan.total_pajak')}</td>
                  <td style={{ textAlign: 'right' }}>+ {rupiah(pajakTotal)}</td>
                </tr>
              )}
              {serviceTotal > 0 && (
                <tr>
                  <td>{t('laporan.total_service')}</td>
                  <td style={{ textAlign: 'right' }}>+ {rupiah(serviceTotal)}</td>
                </tr>
              )}
              <tr style={{ fontWeight: 700, backgroundColor: 'var(--surface-2, #f9fafb)' }}>
                <td>{t('laporan.omset_penjualan')} (Bersih)</td>
                <td style={{ textAlign: 'right', fontSize: 'var(--t-4, 1.125rem)' }}>
                  {rupiah(omzetTotal)}
                </td>
              </tr>
              <tr>
                <td>{t('laporan.transaksi_selesai')}</td>
                <td style={{ textAlign: 'right' }}>{totalTransaksi} Transaksi</td>
              </tr>
            </tbody>
          </table>
        </section>

        {/* 2. Rincian Metode Pembayaran */}
        {((dataPenjualan?.per_metode && dataPenjualan.per_metode.length > 0) ||
          (dataHarian?.metode_bayar && dataHarian.metode_bayar.length > 0)) && (
          <section style={{ marginBottom: 'var(--s-4, 16px)' }}>
            <h2
              style={{
                fontSize: 'var(--t-4, 1.125rem)',
                margin: '0 0 var(--s-2, 8px) 0',
                borderBottom: '1px solid var(--border, #e5e7eb)',
                paddingBottom: '4px',
              }}
            >
              2. {t('laporan.rincian_metode')}
            </h2>
            <table className="format-laporan__tabel">
              <thead>
                <tr>
                  <th>Metode Bayar</th>
                  <th style={{ textAlign: 'right' }}>{t('laporan.jumlah_transaksi')}</th>
                  <th style={{ textAlign: 'right' }}>Total Penerimaan</th>
                </tr>
              </thead>
              <tbody>
                {dataPenjualan?.per_metode
                  ? dataPenjualan.per_metode.map((m) => (
                      <tr key={m.metode_id || m.metode_nama}>
                        <td>{m.metode_nama}</td>
                        <td style={{ textAlign: 'right' }}>{m.jumlah_transaksi}</td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }}>
                          {rupiah(m.total_nominal)}
                        </td>
                      </tr>
                    ))
                  : (dataHarian?.metode_bayar || []).map((m) => (
                      <tr key={m.metode_nama}>
                        <td>{m.metode_nama}</td>
                        <td style={{ textAlign: 'right' }}>{m.jumlah_transaksi}</td>
                        <td style={{ textAlign: 'right', fontWeight: 600 }}>
                          {rupiah(m.total_nominal)}
                        </td>
                      </tr>
                    ))}
              </tbody>
            </table>
          </section>
        )}

        {/* 3. Rekonsiliasi Kas Shift (bila data harian tersedia) */}
        {dataHarian?.kas && (
          <section style={{ marginBottom: 'var(--s-4, 16px)' }}>
            <h2
              style={{
                fontSize: 'var(--t-4, 1.125rem)',
                margin: '0 0 var(--s-2, 8px) 0',
                borderBottom: '1px solid var(--border, #e5e7eb)',
                paddingBottom: '4px',
              }}
            >
              3. Rekonsiliasi Kas Shift & Brankas
            </h2>
            <table className="format-laporan__tabel">
              <tbody>
                <tr>
                  <td style={{ width: '40%' }}>{t('laporan.modal_awal')}</td>
                  <td style={{ textAlign: 'right' }}>{rupiah(dataHarian.kas.total_modal_awal)}</td>
                </tr>
                <tr>
                  <td>{t('laporan.kas_masuk')}</td>
                  <td style={{ textAlign: 'right' }}>{rupiah(dataHarian.kas.kas_masuk)}</td>
                </tr>
                <tr>
                  <td>{t('laporan.kas_keluar')}</td>
                  <td style={{ textAlign: 'right' }}>{rupiah(dataHarian.kas.kas_keluar)}</td>
                </tr>
                <tr>
                  <td>{t('laporan.setoran')} (ke Brankas)</td>
                  <td style={{ textAlign: 'right' }}>{rupiah(dataHarian.kas.setoran)}</td>
                </tr>
                <tr>
                  <td>Penjualan Tunai Bersih</td>
                  <td style={{ textAlign: 'right' }}>{rupiah(dataHarian.kas.penjualan_tunai)}</td>
                </tr>
                <tr style={{ backgroundColor: 'var(--surface-2, #f9fafb)' }}>
                  <td>{t('laporan.uang_seharusnya')}</td>
                  <td style={{ textAlign: 'right', fontWeight: 600 }}>
                    {rupiah(dataHarian.kas.total_uang_seharusnya)}
                  </td>
                </tr>
                <tr style={{ backgroundColor: 'var(--surface-2, #f9fafb)' }}>
                  <td>{t('laporan.uang_fisik')} (Hasil Hitung)</td>
                  <td style={{ textAlign: 'right', fontWeight: 600 }}>
                    {rupiah(dataHarian.kas.total_uang_fisik)}
                  </td>
                </tr>
                <tr style={{ fontWeight: 700 }}>
                  <td>{t('laporan.selisih')}</td>
                  <td
                    style={{
                      textAlign: 'right',
                      color:
                        dataHarian.kas.total_selisih < 0
                          ? 'var(--warna-bahaya, #b91c1c)'
                          : dataHarian.kas.total_selisih > 0
                            ? 'var(--warna-sukses, #16a34a)'
                            : 'inherit',
                    }}
                  >
                    {dataHarian.kas.total_selisih === 0
                      ? 'Rp0 (Tepat)'
                      : `${dataHarian.kas.total_selisih > 0 ? '+' : ''}${rupiah(dataHarian.kas.total_selisih)}`}
                  </td>
                </tr>
              </tbody>
            </table>
          </section>
        )}

        {/* 4. Menu Terlaris (Top 5 Menu) */}
        {dataMenu?.peringkat_menu && dataMenu.peringkat_menu.length > 0 && (
          <section style={{ marginBottom: 'var(--s-4, 16px)' }}>
            <h2
              style={{
                fontSize: 'var(--t-4, 1.125rem)',
                margin: '0 0 var(--s-2, 8px) 0',
                borderBottom: '1px solid var(--border, #e5e7eb)',
                paddingBottom: '4px',
              }}
            >
              4. {t('laporan.menu_terlaris')} (Top 5)
            </h2>
            <table className="format-laporan__tabel">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Menu</th>
                  <th>Kategori</th>
                  <th style={{ textAlign: 'right' }}>{t('laporan.qty_terjual')}</th>
                  <th style={{ textAlign: 'right' }}>Total Omzet</th>
                </tr>
              </thead>
              <tbody>
                {dataMenu.peringkat_menu.slice(0, 5).map((m, idx) => (
                  <tr key={m.menu_item_id || `${m.nama_menu}-${idx}`}>
                    <td style={{ width: '30px' }}>{idx + 1}</td>
                    <td style={{ fontWeight: 600 }}>{m.nama_menu}</td>
                    <td>{m.kategori_nama}</td>
                    <td style={{ textAlign: 'right' }}>{m.qty_terjual}</td>
                    <td style={{ textAlign: 'right', fontWeight: 600 }}>{rupiah(m.total_omzet)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        )}

        {/* 5. Catatan Pengawasan Pembatalan & Biaya Promosi */}
        {(dataHarian?.pembatalan || dataMenu?.ringkasan) && (
          <section style={{ marginBottom: 'var(--s-4, 16px)' }}>
            <h2
              style={{
                fontSize: 'var(--t-4, 1.125rem)',
                margin: '0 0 var(--s-2, 8px) 0',
                borderBottom: '1px solid var(--border, #e5e7eb)',
                paddingBottom: '4px',
              }}
            >
              5. Pengawasan Pembatalan & Biaya Promosi
            </h2>
            <table className="format-laporan__tabel">
              <tbody>
                {dataMenu?.ringkasan && (
                  <>
                    <tr>
                      <td style={{ width: '50%' }}>Total Biaya Promosi (Diskon + Voucher)</td>
                      <td style={{ textAlign: 'right', fontWeight: 600 }}>
                        {rupiah(dataMenu.ringkasan.total_biaya_promosi)}
                      </td>
                    </tr>
                    <tr>
                      <td>Diskon Manual ({dataMenu.diskon_manual.length} Transaksi)</td>
                      <td style={{ textAlign: 'right' }}>
                        {rupiah(dataMenu.ringkasan.total_diskon_manual)}
                      </td>
                    </tr>
                    <tr>
                      <td>Voucher Terpakai ({dataMenu.voucher_terpakai.length} Voucher)</td>
                      <td style={{ textAlign: 'right' }}>
                        {rupiah(dataMenu.ringkasan.total_voucher)}
                      </td>
                    </tr>
                  </>
                )}
                {dataHarian?.pembatalan && (
                  <tr>
                    <td>
                      Pembatalan Pesanan / Void ({dataHarian.pembatalan.jumlah} Item Dibatalkan)
                    </td>
                    <td
                      style={{
                        textAlign: 'right',
                        fontWeight: 600,
                        color:
                          dataHarian.pembatalan.total_nilai_rugi > 0
                            ? 'var(--warna-bahaya, #b91c1c)'
                            : 'inherit',
                      }}
                    >
                      Rugi: {rupiah(dataHarian.pembatalan.total_nilai_rugi)}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </section>
        )}

        {/* 6. Lembar Pengesahan & Tanda Tangan */}
        <footer className="format-laporan__ttd">
          <div className="format-laporan__kotak-ttd">
            <div>{t('laporan.dibuat_oleh')},</div>
            <div style={{ color: 'var(--warna-teks-redup, #666)', fontSize: '0.8rem' }}>
              Kasir / Penanggung Jawab
            </div>
            <div className="format-laporan__garis-ttd">
              <strong>( {namaPetugas} )</strong>
            </div>
          </div>

          <div className="format-laporan__kotak-ttd">
            <div>{t('laporan.disetujui_oleh')},</div>
            <div style={{ color: 'var(--warna-teks-redup, #666)', fontSize: '0.8rem' }}>
              Pemilik / Pengelola Resto
            </div>
            <div className="format-laporan__garis-ttd">
              <strong>( {namaPemilik} )</strong>
            </div>
          </div>
        </footer>
      </article>
    </div>
  )
}

export default FormatLaporan
