/**
 * Peringatan.tsx — Layar Ringkasan Peringatan Harian untuk Pemilik (T10-13 / PRD M12; TECH_SPEC §5.1 & §9 ART-13; docs/KEAMANAN.md §9).
 *
 * Tujuan:
 *  Memungkinkan pemilik resto memantau hal-hal aneh/mencurigakan dalam 1 layar komprehensif
 *  (omzet, transaksi, void, diskon, selisih kas, percobaan login gagal, perubahan perangkat,
 *  pemakaian jalur pemulihan, dan keutuhan rantai audit kriptografis) tanpa harus memeriksa
 *  satu per satu secara manual.
 *
 * Prinsip:
 *  1. Privasi ART-14: Bebas data pribadi pelanggan (hanya angka, alasan, dan nama pegawai internal).
 *  2. Audit ART-13: Status rantai audit diverifikasi dan diberi tanda peringatan jika putus.
 *  3. Jalur Ganda: Dapat dilihat di aplikasi DAN dikirim via email harian otomatis ke owner.
 */

import React, { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah } from '../../lib/format'

export interface PeringatanItem {
  kategori: 'void' | 'diskon' | 'selisih_kas' | 'masuk_gagal' | 'perangkat' | 'pemulihan' | string
  waktu: string
  pegawai?: string
  alasan?: string
  nominal?: number
  selisih?: number
  tahap?: string
  aksi?: string
  entitas_id?: string
}

export interface DataRingkasanPeringatan {
  id?: string
  tanggal: string
  omzet: number
  transaksi_count: number
  void_count: number
  void_nominal: number
  diskon_count: number
  diskon_nominal: number
  selisih_kas_count: number
  selisih_kas_nominal: number
  percobaan_gagal_count: number
  perubahan_perangkat_count: number
  pemulihan_count: number
  rantai_audit_valid: boolean
  rantai_audit_pesan: string
  email_tujuan?: string | null
  status_email?: 'tertunda' | 'terkirim' | 'gagal' | 'lewati' | string
  rincian_peringatan: PeringatanItem[]
}

/**
 * Status perangkat berkuasa per peran (PMB1-F-072 · KEAMANAN §4 keputusan pemilik:
 * setiap peran berkuasa minimal 2 perangkat terdaftar; tinggal satu = wajib diperingatkan).
 * Dihitung peladen lewat RPC `hitung_perangkat_berkuasa()` (migrasi 0103).
 */
export interface StatusPerangkatBerkuasa {
  peran: 'owner_pusat' | 'admin_cabang' | string
  jumlah_aktif: number
  cadangan_cukup: boolean
}

export interface PeringatanProps {
  data?: DataRingkasanPeringatan | null
  /** PMB1-F-072: bila ada peran berkuasa dengan cadangan_cukup=false, layar menampilkan peringatan keras di atas semua panel. */
  statusPerangkatBerkuasa?: StatusPerangkatBerkuasa[] | null
  daftarRingkasan?: DataRingkasanPeringatan[]
  tanggalTerpilih?: string
  sedangMemuat?: boolean
  pesanGagal?: string | null
  emailOwnerResto?: string
  notifikasiAktif?: boolean
  onPilihTanggal?: (tgl: string) => void
  onHasilkanRingkasan?: (tgl: string) => Promise<void> | void
  onKirimEmailManual?: (ringkasanId: string) => Promise<void> | void
  onSimpanPengaturanNotifikasi?: (aktif: boolean, email: string) => Promise<void> | void
  onMuatUlang?: () => void
}

const LABEL_PERAN_BERKUASA: Record<string, string> = {
  owner_pusat: 'owner pusat',
  admin_cabang: 'admin cabang',
}

export const Peringatan: React.FC<PeringatanProps> = ({
  data,
  statusPerangkatBerkuasa = null,
  daftarRingkasan: _daftarRingkasan = [],
  tanggalTerpilih,
  sedangMemuat = false,
  pesanGagal = null,
  emailOwnerResto = '',
  notifikasiAktif = true,
  onPilihTanggal,
  onHasilkanRingkasan,
  onKirimEmailManual,
  onSimpanPengaturanNotifikasi,
  onMuatUlang,
}) => {
  const hariIni = new Date().toISOString().split('T')[0]
  const tanggalAktif = tanggalTerpilih || data?.tanggal || hariIni

  const [filterKategori, setFilterKategori] = useState<string>('semua')
  const [inputEmail, setInputEmail] = useState<string>(emailOwnerResto || data?.email_tujuan || '')
  const [toggleNotif, setToggleNotif] = useState<boolean>(notifikasiAktif)
  const [pesanAksi, setPesanAksi] = useState<string | null>(null)
  const [sedangKirim, setSedangKirim] = useState<boolean>(false)

  const rincian = data?.rincian_peringatan || []
  const rincianTerfilter =
    filterKategori === 'semua'
      ? rincian
      : rincian.filter((item) => item.kategori === filterKategori)

  const handleSimpanPengaturan = async () => {
    if (!onSimpanPengaturanNotifikasi) return
    try {
      await onSimpanPengaturanNotifikasi(toggleNotif, inputEmail)
      setPesanAksi('Pengaturan notifikasi email berhasil disimpan.')
    } catch {
      setPesanAksi('Gagal menyimpan pengaturan notifikasi email.')
    }
  }

  const handleKirimEmail = async () => {
    if (!data?.id || !onKirimEmailManual) return
    setSedangKirim(true)
    try {
      await onKirimEmailManual(data.id)
      setPesanAksi(
        'Email ringkasan peringatan berhasil dikirim ke ' + (data.email_tujuan || inputEmail),
      )
    } catch {
      setPesanAksi('Gagal mengirim email ringkasan peringatan.')
    } finally {
      setSedangKirim(false)
    }
  }

  return (
    <div
      className="layar-peringatan"
      style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4, 16px)' }}
    >
      {/* Panel Atas: Header & Pemilih Tanggal */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
          padding: '16px',
          backgroundColor: 'var(--latar-kartu)',
          borderRadius: '8px',
          border: '1px solid var(--border)',
        }}
      >
        <div>
          <h2 style={{ margin: 0, fontSize: '18px', fontWeight: 600 }}>
            ⚠️ Ringkasan Peringatan Harian Pemilik
          </h2>
          <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: 'var(--teks-sekunder)' }}>
            Pengawasan anomali operasional & finansial tanpa data pribadi pelanggan (ART-13 &
            ART-14).
          </p>
        </div>

        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
          <label htmlFor="pilih-tanggal-ringkasan" style={{ fontSize: '13px', fontWeight: 500 }}>
            Tanggal:
          </label>
          <input
            id="pilih-tanggal-ringkasan"
            type="date"
            value={tanggalAktif}
            onChange={(e) => onPilihTanggal?.(e.target.value)}
            style={{
              padding: '6px 10px',
              borderRadius: '6px',
              border: '1px solid var(--border)',
              backgroundColor: 'var(--latar)',
              color: 'var(--teks)',
            }}
          />

          {onHasilkanRingkasan && (
            <Tombol
              ragam="utama"
              onClick={() => onHasilkanRingkasan(tanggalAktif)}
              nonaktif={sedangMemuat}
            >
              🔄 Hasilkan Ringkasan
            </Tombol>
          )}

          {onMuatUlang && (
            <Tombol ragam="polos" onClick={onMuatUlang} nonaktif={sedangMemuat}>
              Muat Ulang
            </Tombol>
          )}
        </div>
      </div>

      {/* PMB1-F-072: peringatan perangkat berkuasa tinggal satu (KEAMANAN §4). */}
      {(statusPerangkatBerkuasa || []).filter((s) => !s.cadangan_cukup).length > 0 && (
        <div
          role="alert"
          className="peringatan-perangkat-berkuasa"
          style={{
            padding: '12px 16px',
            backgroundColor: 'var(--latar-bahaya-muda)',
            color: 'var(--teks-bahaya)',
            borderRadius: '6px',
            border: '1px solid var(--border-bahaya)',
            fontSize: '14px',
          }}
        >
          <strong>📵 Perangkat berkuasa hampir habis.</strong>
          <ul style={{ margin: '8px 0 0 0', paddingLeft: '20px' }}>
            {(statusPerangkatBerkuasa || [])
              .filter((s) => !s.cadangan_cukup)
              .map((s) => (
                <li key={s.peran}>
                  Peran <strong>{LABEL_PERAN_BERKUASA[s.peran] ?? s.peran}</strong> tinggal{' '}
                  <strong>{s.jumlah_aktif}</strong> perangkat aktif — keputusan pemilik: minimal 2
                  (satu utama + satu cadangan). Daftarkan perangkat cadangan sebelum perangkat
                  terakhir hilang.
                </li>
              ))}
          </ul>
        </div>
      )}

      {pesanGagal && (
        <div
          role="alert"
          style={{
            padding: '12px 16px',
            backgroundColor: 'var(--latar-bahaya-muda)',
            color: 'var(--teks-bahaya)',
            borderRadius: '6px',
            border: '1px solid var(--border-bahaya)',
            fontSize: '14px',
          }}
        >
          {pesanGagal}
        </div>
      )}

      {pesanAksi && (
        <div
          role="status"
          style={{
            padding: '10px 14px',
            backgroundColor: 'var(--latar-sukses-muda)',
            color: 'var(--teks-sukses)',
            borderRadius: '6px',
            border: '1px solid var(--border-sukses)',
            fontSize: '13px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{pesanAksi}</span>
          <Tombol ragam="polos" onClick={() => setPesanAksi(null)}>
            ✕
          </Tombol>
        </div>
      )}

      {sedangMemuat ? (
        <div style={{ padding: '32px', textAlign: 'center', color: 'var(--teks-sekunder)' }}>
          Memuat ringkasan harian…
        </div>
      ) : !data ? (
        <KeadaanKosong
          judul="Belum Ada Ringkasan Harian"
          keterangan={`Ringkasan untuk tanggal ${tanggalAktif} belum dihasilkan. Klik tombol di atas untuk mengkalkulasi rekap peringatan.`}
        />
      ) : (
        <>
          {/* Kartu Status Integritas Rantai Audit (ART-13) */}
          <div
            style={{
              padding: '14px 18px',
              borderRadius: '8px',
              border: `1px solid ${data.rantai_audit_valid ? 'var(--border-sukses)' : 'var(--border-bahaya)'}`,
              backgroundColor: data.rantai_audit_valid
                ? 'var(--latar-sukses-muda)'
                : 'var(--latar-bahaya-muda)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: '12px',
            }}
          >
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '16px' }}>🛡️</span>
                <strong style={{ fontSize: '14px' }}>
                  Integritas Rantai Audit Kriptografis (ART-13):
                </strong>
                <Lencana nada={data.rantai_audit_valid ? 'success' : 'danger'}>
                  {data.rantai_audit_valid ? 'VALID & UTUH' : 'TERPUTUS / ANOMALI'}
                </Lencana>
              </div>
              <p
                style={{ margin: '4px 0 0 28px', fontSize: '13px', color: 'var(--teks-sekunder)' }}
              >
                {data.rantai_audit_pesan}
              </p>
            </div>
            <span style={{ fontSize: '12px', color: 'var(--teks-sekunder)' }}>
              Hash SHA-256 terverifikasi
            </span>
          </div>

          {/* Grid Indikator Cepat */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
              gap: '12px',
            }}
          >
            {/* Omzet & Transaksi */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: '1px solid var(--border)',
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Omzet Harian
              </div>
              <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--teks)' }}>
                {rupiah(data.omzet)}
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                {data.transaksi_count} transaksi lunas
              </div>
            </div>

            {/* Void & Pembatalan */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: `1px solid ${data.void_count > 0 ? 'var(--border-bahaya)' : 'var(--border)'}`,
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Void / Pembatalan
              </div>
              <div
                style={{
                  fontSize: '20px',
                  fontWeight: 700,
                  color: data.void_count > 0 ? 'var(--teks-bahaya)' : 'var(--teks)',
                }}
              >
                {data.void_count} pesanan
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                Potensi rugi: {rupiah(data.void_nominal)}
              </div>
            </div>

            {/* Diskon */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: '1px solid var(--border)',
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Diskon Transaksi
              </div>
              <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--teks)' }}>
                {data.diskon_count} kali
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                Total: {rupiah(data.diskon_nominal)}
              </div>
            </div>

            {/* Selisih Kas */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: `1px solid ${data.selisih_kas_count > 0 ? 'var(--border-bahaya)' : 'var(--border)'}`,
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Selisih Kas Kasir
              </div>
              <div
                style={{
                  fontSize: '20px',
                  fontWeight: 700,
                  color: data.selisih_kas_count > 0 ? 'var(--teks-bahaya)' : 'var(--teks)',
                }}
              >
                {data.selisih_kas_count} kejadian
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                Selisih: {rupiah(data.selisih_kas_nominal)}
              </div>
            </div>

            {/* Percobaan Gagal */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: `1px solid ${data.percobaan_gagal_count > 0 ? 'var(--border-peringatan)' : 'var(--border)'}`,
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Login / PIN Gagal
              </div>
              <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--teks)' }}>
                {data.percobaan_gagal_count} kali
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                Potensi serangan brute-force
              </div>
            </div>

            {/* Perangkat & Pemulihan */}
            <div
              style={{
                padding: '14px',
                borderRadius: '8px',
                backgroundColor: 'var(--latar-kartu)',
                border: '1px solid var(--border)',
              }}
            >
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginBottom: '4px' }}>
                Perangkat & Pemulihan
              </div>
              <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--teks)' }}>
                {data.perubahan_perangkat_count} perangkat
              </div>
              <div style={{ fontSize: '12px', color: 'var(--teks-sekunder)', marginTop: '4px' }}>
                {data.pemulihan_count} pemakaian jalur darurat
              </div>
            </div>
          </div>

          {/* Panel Notifikasi Email Pemilik */}
          <div
            style={{
              padding: '16px',
              borderRadius: '8px',
              backgroundColor: 'var(--latar-kartu)',
              border: '1px solid var(--border)',
              display: 'flex',
              flexDirection: 'column',
              gap: '12px',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
              }}
            >
              <div>
                <strong style={{ fontSize: '14px' }}>📬 Notifikasi Email Harian ke Owner</strong>
                <p style={{ margin: '4px 0 0 0', fontSize: '12px', color: 'var(--teks-sekunder)' }}>
                  Laporan ringkas otomatis 1×/hari dikirim ke email pemilik tanpa perlu selalu
                  membuka aplikasi.
                </p>
              </div>

              <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                <span style={{ fontSize: '12px' }}>Status Pengiriman:</span>
                <Lencana
                  nada={
                    data.status_email === 'terkirim'
                      ? 'success'
                      : data.status_email === 'gagal'
                        ? 'danger'
                        : 'netral'
                  }
                >
                  {data.status_email === 'terkirim'
                    ? 'TERKIRIM'
                    : data.status_email === 'gagal'
                      ? 'GAGAL'
                      : 'TERTUNDA'}
                </Lencana>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
              <input
                type="email"
                placeholder="email.owner@contoh.test"
                value={inputEmail}
                onChange={(e) => setInputEmail(e.target.value)}
                style={{
                  flex: '1',
                  minWidth: '240px',
                  padding: '8px 12px',
                  borderRadius: '6px',
                  border: '1px solid var(--border)',
                  backgroundColor: 'var(--latar)',
                  color: 'var(--teks)',
                  fontSize: '13px',
                }}
              />

              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  fontSize: '13px',
                  cursor: 'pointer',
                }}
              >
                <input
                  type="checkbox"
                  checked={toggleNotif}
                  onChange={(e) => setToggleNotif(e.target.checked)}
                />
                Kirim Otomatis Harian
              </label>

              {onSimpanPengaturanNotifikasi && (
                <Tombol ragam="polos" onClick={handleSimpanPengaturan}>
                  Simpan Email
                </Tombol>
              )}

              {onKirimEmailManual && data.id && (
                <Tombol ragam="utama" onClick={handleKirimEmail} nonaktif={sedangKirim}>
                  {sedangKirim ? 'Mengirim…' : 'Kirim Sekarang'}
                </Tombol>
              )}
            </div>
          </div>

          {/* Rincian Peringatan Operasional */}
          <div
            style={{
              padding: '16px',
              borderRadius: '8px',
              backgroundColor: 'var(--latar-kartu)',
              border: '1px solid var(--border)',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: '8px',
                marginBottom: '12px',
              }}
            >
              <div>
                <strong style={{ fontSize: '15px' }}>📋 Log Kejadian & Anomali</strong>
                <span
                  style={{ fontSize: '13px', color: 'var(--teks-sekunder)', marginLeft: '8px' }}
                >
                  ({rincianTerfilter.length} kejadian)
                </span>
              </div>

              {/* Filter Kategori */}
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {[
                  'semua',
                  'void',
                  'diskon',
                  'selisih_kas',
                  'masuk_gagal',
                  'perangkat',
                  'pemulihan',
                ].map((kat) => (
                  <Tombol
                    key={kat}
                    ragam={filterKategori === kat ? 'utama' : 'polos'}
                    onClick={() => setFilterKategori(kat)}
                  >
                    {kat === 'semua'
                      ? 'Semua'
                      : kat === 'selisih_kas'
                        ? 'Selisih Kas'
                        : kat === 'masuk_gagal'
                          ? 'Login Gagal'
                          : kat.charAt(0).toUpperCase() + kat.slice(1)}
                  </Tombol>
                ))}
              </div>
            </div>

            {rincianTerfilter.length === 0 ? (
              <div style={{ padding: '24px', textAlign: 'center', color: 'var(--teks-sekunder)' }}>
                Tidak ada kejadian anomali pada filter ini.
              </div>
            ) : (
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                  <thead>
                    <tr
                      style={{
                        borderBottom: '1px solid var(--border)',
                        textAlign: 'left',
                        color: 'var(--teks-sekunder)',
                      }}
                    >
                      <th style={{ padding: '8px 12px' }}>Waktu</th>
                      <th style={{ padding: '8px 12px' }}>Kategori</th>
                      <th style={{ padding: '8px 12px' }}>Pegawai</th>
                      <th style={{ padding: '8px 12px', textAlign: 'right' }}>Nominal / Selisih</th>
                      <th style={{ padding: '8px 12px' }}>Alasan / Keterangan</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rincianTerfilter.map((item, idx) => {
                      const waktuFormat = item.waktu
                        ? item.waktu.replace('T', ' ').replace('Z', '')
                        : '-'
                      return (
                        <tr
                          key={idx}
                          style={{
                            borderBottom: '1px solid var(--border)',
                          }}
                        >
                          <td style={{ padding: '8px 12px', whiteSpace: 'nowrap' }}>
                            {waktuFormat}
                          </td>
                          <td style={{ padding: '8px 12px' }}>
                            <Lencana
                              nada={
                                item.kategori === 'void' || item.kategori === 'selisih_kas'
                                  ? 'danger'
                                  : item.kategori === 'masuk_gagal'
                                    ? 'warn'
                                    : 'netral'
                              }
                            >
                              {item.kategori}
                            </Lencana>
                          </td>
                          <td style={{ padding: '8px 12px', fontWeight: 500 }}>
                            {item.pegawai || 'Sistem'}
                          </td>
                          <td style={{ padding: '8px 12px', textAlign: 'right' }}>
                            {item.nominal !== undefined && item.nominal !== null
                              ? rupiah(item.nominal)
                              : item.selisih !== undefined && item.selisih !== null
                                ? rupiah(item.selisih)
                                : '-'}
                          </td>
                          <td style={{ padding: '8px 12px', color: 'var(--teks-sekunder)' }}>
                            {item.alasan || item.aksi || '-'}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}

            {/* Perlindungan Privasi Pelanggan (ART-14 / UU PDP) */}
            <div
              style={{
                marginTop: '16px',
                padding: '10px 14px',
                borderRadius: '6px',
                backgroundColor: 'var(--latar)',
                border: '1px solid var(--border)',
                fontSize: '12px',
                color: 'var(--teks-sekunder)',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <span>🔒</span>
              <span>
                <strong>Prinsip Privasi UU PDP &amp; ART-14:</strong> Laporan ini dirancang khusus
                untuk pengawasan internal staf resto. Identitas, nomor telepon, dan email pelanggan
                tidak pernah disertakan dalam ringkasan harian.
              </span>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

export default Peringatan
