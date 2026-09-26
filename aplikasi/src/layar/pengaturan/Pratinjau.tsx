/* eslint-disable react-refresh/only-export-components */
/**
 * Pratinjau.tsx — Pratinjau Perubahan & Pengaman Riwayat (T9-11 / PRD M2 Kasus Tepi)
 *
 * Fitur Utama:
 *  1. Diff Viewer (Perbandingan Draf vs Aktif):
 *     Menampilkan perbandingan berdampingan sebelum vs sesudah untuk seluruh
 *     parameter restoran (Identitas, Tema/Warna, Tarif PB1, Service Charge,
 *     Pembulatan, Jam Buka, Header & Footer Struk).
 *  2. Live Receipt Simulator (Simulasi Struk Kasir):
 *     Menghitung simulasi struk secara real-time berdasarkan skenario transaksi contoh,
 *     memperagakan format kertas termal (58mm & 80mm), dan menyandingkan Struk Aturan Lama
 *     vs Struk Aturan Baru beserta analisis selisih tagihan pelanggan.
 *  3. Jaminan Kekekalan Riwayat Masa Lalu (Immutable Past Guarantee):
 *     Menjamin secara transparan dan matematis bahwa seluruh transaksi, struk cetak lama,
 *     dan laporan keuangan/kas yang sudah selesai TIDAK AKAN BERUBAH sedikit pun
 *     (diverifikasi oleh uji database fail-closed `riwayat_tidak_berubah.sql`).
 *  4. Tombol Aksi Mandiri & Pengaman Simpan:
 *     Pemisahan aksi "Simpan Semua Pengaturan", "Batal / Reset Draf", dan "Cetak Contoh Simulasi".
 */

import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Toast } from '../../komponen/Toast'
import { Lapis } from '../../komponen/Lapis'
import { rupiah, tanggalLokal } from '../../lib/format'
import type { DataIdentitas } from './Identitas'
import type { DataTema } from './Tampilan'
import type { DataOperasional, PembulatanPilihan } from './Operasional'

export interface SkenarioSimulasi {
  id: string
  judul: string
  keterangan: string
  item: Array<{
    nama: string
    qty: number
    harga: number
  }>
  diskon: number
}

export const SKENARIO_CONTOH: SkenarioSimulasi[] = [
  {
    id: 'makan-siang',
    judul: 'Makan Siang Standar (2 Orang)',
    keterangan: '2x Nasi Goreng Barokah + 2x Es Teh Segar tanpa diskon',
    item: [
      { nama: 'Nasi Goreng Barokah', qty: 2, harga: 25000 },
      { nama: 'Es Teh Segar', qty: 2, harga: 8000 },
    ],
    diskon: 0,
  },
  {
    id: 'kopi-kudapan',
    judul: 'Pesanan Santai (Kopi & Kudapan)',
    keterangan: '1x Kopi Barokah + 1x Pisang Goreng Crispy',
    item: [
      { nama: 'Kopi Barokah', qty: 1, harga: 15000 },
      { nama: 'Pisang Goreng Crispy', qty: 1, harga: 12000 },
    ],
    diskon: 0,
  },
  {
    id: 'jamuan-promo',
    judul: 'Jamuan Keluarga (Diskon Promo)',
    keterangan: '4x Nasi Goreng + 4x Ayam Bakar Madu dengan kupon diskon Rp 30.000',
    item: [
      { nama: 'Nasi Goreng Barokah', qty: 4, harga: 25000 },
      { nama: 'Ayam Bakar Madu', qty: 4, harga: 30000 },
    ],
    diskon: 30000,
  },
]

export interface PratinjauProps {
  dataIdentitasSaatIni?: Partial<DataIdentitas>
  dataIdentitasDraf?: Partial<DataIdentitas>
  dataTemaSaatIni?: Partial<DataTema>
  dataTemaDraf?: Partial<DataTema>
  dataOperasionalSaatIni?: Partial<DataOperasional>
  dataOperasionalDraf?: Partial<DataOperasional>
  onSimpanSemua?: () => Promise<{ berhasil: boolean; pesan?: string }>
  onResetDraf?: () => void
  onKembali?: () => void
  onCetakSimulasi?: () => void
  hanyaBaca?: boolean
}

export function hitungTagihanStruk(
  items: Array<{ nama: string; qty: number; harga: number }>,
  diskonNominal: number,
  pajakPersen: number,
  servicePersen: number,
  pembulatan: PembulatanPilihan,
) {
  const subtotal = items.reduce((acc, it) => acc + it.qty * it.harga, 0)
  const diskon = Math.min(diskonNominal, subtotal)
  const dasar = Math.max(0, subtotal - diskon)
  const pajak = Math.round((dasar * Math.max(0, pajakPersen)) / 100)
  const service = Math.round((dasar * Math.max(0, servicePersen)) / 100)

  let totalKotor = dasar + pajak + service
  const langkah = pembulatan === 'none' ? 0 : parseInt(pembulatan, 10)
  if (langkah > 0) {
    totalKotor = Math.floor(totalKotor / langkah) * langkah
  }
  const total = Math.max(0, totalKotor)
  const selisihBulat = total - (dasar + pajak + service)

  return {
    subtotal,
    diskon,
    dasar,
    pajak,
    service,
    selisihBulat,
    total,
  }
}

export function Pratinjau({
  dataIdentitasSaatIni,
  dataIdentitasDraf,
  dataTemaSaatIni,
  dataTemaDraf,
  dataOperasionalSaatIni,
  dataOperasionalDraf,
  onSimpanSemua,
  onResetDraf,
  onKembali,
  onCetakSimulasi,
  hanyaBaca = false,
}: PratinjauProps) {
  // Nilai aktif saat ini
  const identitasAktif: DataIdentitas = {
    namaResto: dataIdentitasSaatIni?.namaResto || 'Kedai Oasis Barokah',
    tagline: dataIdentitasSaatIni?.tagline || 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal',
    logoUrl: dataIdentitasSaatIni?.logoUrl || '',
    bannerUrl: dataIdentitasSaatIni?.bannerUrl || '',
    jamBuka: dataIdentitasSaatIni?.jamBuka || '08.00 - 22.00 WIB',
    versiPengaturan: dataIdentitasSaatIni?.versiPengaturan || null,
  }

  const temaAktif: DataTema = {
    tema: dataTemaSaatIni?.tema || 'terang',
    kerapatan: dataTemaSaatIni?.kerapatan || 'nyaman',
    warnaMerek: dataTemaSaatIni?.warnaMerek || '',
  }

  const operasionalAktif: DataOperasional = {
    pajak_pb1_persen: dataOperasionalSaatIni?.pajak_pb1_persen ?? 10,
    service_persen: dataOperasionalSaatIni?.service_persen ?? 5,
    pembulatan: dataOperasionalSaatIni?.pembulatan || 'none',
    cara_pesan: dataOperasionalSaatIni?.cara_pesan || 'kasir',
    jam_buka: dataOperasionalSaatIni?.jam_buka || '08.00 - 22.00 WIB',
    header_struk: dataOperasionalSaatIni?.header_struk || 'Selamat Menikmati Hidangan Barokah',
    footer_struk: dataOperasionalSaatIni?.footer_struk || 'Terima kasih atas kunjungan Anda!',
    tumpuk_diskon: dataOperasionalSaatIni?.tumpuk_diskon ?? false,
  }

  // Nilai draf usulan baru
  const identitasBaru: DataIdentitas = {
    namaResto: dataIdentitasDraf?.namaResto ?? identitasAktif.namaResto,
    tagline: dataIdentitasDraf?.tagline ?? identitasAktif.tagline,
    logoUrl: dataIdentitasDraf?.logoUrl ?? identitasAktif.logoUrl,
    bannerUrl: dataIdentitasDraf?.bannerUrl ?? identitasAktif.bannerUrl,
    jamBuka: dataIdentitasDraf?.jamBuka ?? identitasAktif.jamBuka,
    versiPengaturan: dataIdentitasDraf?.versiPengaturan ?? identitasAktif.versiPengaturan,
  }

  const temaBaru: DataTema = {
    tema: dataTemaDraf?.tema ?? temaAktif.tema,
    kerapatan: dataTemaDraf?.kerapatan ?? temaAktif.kerapatan,
    warnaMerek: dataTemaDraf?.warnaMerek ?? temaAktif.warnaMerek,
  }

  const operasionalBaru: DataOperasional = {
    pajak_pb1_persen: dataOperasionalDraf?.pajak_pb1_persen ?? operasionalAktif.pajak_pb1_persen,
    service_persen: dataOperasionalDraf?.service_persen ?? operasionalAktif.service_persen,
    pembulatan: dataOperasionalDraf?.pembulatan ?? operasionalAktif.pembulatan,
    cara_pesan: dataOperasionalDraf?.cara_pesan ?? operasionalAktif.cara_pesan,
    jam_buka: dataOperasionalDraf?.jam_buka ?? operasionalAktif.jam_buka,
    header_struk: dataOperasionalDraf?.header_struk ?? operasionalAktif.header_struk,
    footer_struk: dataOperasionalDraf?.footer_struk ?? operasionalAktif.footer_struk,
    tumpuk_diskon: dataOperasionalDraf?.tumpuk_diskon ?? operasionalAktif.tumpuk_diskon,
  }

  // Status & Keadaan Komponen
  const [skenarioId, setSkenarioId] = useState<string>('makan-siang')
  const [lebarKertas, setLebarKertas] = useState<'58' | '80'>('58')
  const [dialogKonfirmasi, setDialogKonfirmasi] = useState(false)
  const [sedangSimpan, setSedangSimpan] = useState(false)
  const [toast, setToast] = useState<{
    tampil: boolean
    pesan: string
    nada: 'sukses' | 'gagal' | 'info'
  }>({
    tampil: false,
    pesan: '',
    nada: 'info',
  })

  const skenarioTerpilih = SKENARIO_CONTOH.find((s) => s.id === skenarioId) || SKENARIO_CONTOH[0]

  // Perhitungan Simulasi
  const tagihanLama = hitungTagihanStruk(
    skenarioTerpilih.item,
    skenarioTerpilih.diskon,
    operasionalAktif.pajak_pb1_persen,
    operasionalAktif.service_persen,
    operasionalAktif.pembulatan,
  )

  const tagihanBaru = hitungTagihanStruk(
    skenarioTerpilih.item,
    skenarioTerpilih.diskon,
    operasionalBaru.pajak_pb1_persen,
    operasionalBaru.service_persen,
    operasionalBaru.pembulatan,
  )

  const selisihTotal = tagihanBaru.total - tagihanLama.total
  const persentasePerubahan =
    tagihanLama.total > 0 ? ((selisihTotal / tagihanLama.total) * 100).toFixed(1) : '0'

  // Daftar Item Perbedaan (Diff Items)
  const daftarPerbedaan: Array<{
    kategori: string
    properti: string
    lama: string
    baru: string
    berubah: boolean
  }> = [
    {
      kategori: 'Identitas Resto',
      properti: 'Nama Restoran',
      lama: identitasAktif.namaResto,
      baru: identitasBaru.namaResto,
      berubah: identitasAktif.namaResto !== identitasBaru.namaResto,
    },
    {
      kategori: 'Identitas Resto',
      properti: 'Tagline / Slogan',
      lama: identitasAktif.tagline || '(kosong)',
      baru: identitasBaru.tagline || '(kosong)',
      berubah: identitasAktif.tagline !== identitasBaru.tagline,
    },
    {
      kategori: 'Tema & Tampilan',
      properti: 'Tema Warna',
      lama: temaAktif.tema,
      baru: temaBaru.tema,
      berubah: temaAktif.tema !== temaBaru.tema,
    },
    {
      kategori: 'Tema & Tampilan',
      properti: 'Kerapatan Antarmuka',
      lama: temaAktif.kerapatan,
      baru: temaBaru.kerapatan,
      berubah: temaAktif.kerapatan !== temaBaru.kerapatan,
    },
    {
      kategori: 'Operasional & Pajak',
      properti: 'Pajak PB1',
      lama: `${operasionalAktif.pajak_pb1_persen}%`,
      baru: `${operasionalBaru.pajak_pb1_persen}%`,
      berubah: operasionalAktif.pajak_pb1_persen !== operasionalBaru.pajak_pb1_persen,
    },
    {
      kategori: 'Operasional & Pajak',
      properti: 'Service Charge',
      lama: `${operasionalAktif.service_persen}%`,
      baru: `${operasionalBaru.service_persen}%`,
      berubah: operasionalAktif.service_persen !== operasionalBaru.service_persen,
    },
    {
      kategori: 'Operasional & Pajak',
      properti: 'Aturan Pembulatan',
      lama:
        operasionalAktif.pembulatan === 'none'
          ? 'Tanpa Pembulatan'
          : `Ke Rp ${operasionalAktif.pembulatan}`,
      baru:
        operasionalBaru.pembulatan === 'none'
          ? 'Tanpa Pembulatan'
          : `Ke Rp ${operasionalBaru.pembulatan}`,
      berubah: operasionalAktif.pembulatan !== operasionalBaru.pembulatan,
    },
    {
      kategori: 'Operasional & Pajak',
      properti: 'Alur Pemesanan',
      lama: operasionalAktif.cara_pesan,
      baru: operasionalBaru.cara_pesan,
      berubah: operasionalAktif.cara_pesan !== operasionalBaru.cara_pesan,
    },
    {
      kategori: 'Struk Kasir',
      properti: 'Header Struk',
      lama: operasionalAktif.header_struk || '(kosong)',
      baru: operasionalBaru.header_struk || '(kosong)',
      berubah: operasionalAktif.header_struk !== operasionalBaru.header_struk,
    },
    {
      kategori: 'Struk Kasir',
      properti: 'Footer Struk',
      lama: operasionalAktif.footer_struk || '(kosong)',
      baru: operasionalBaru.footer_struk || '(kosong)',
      berubah: operasionalAktif.footer_struk !== operasionalBaru.footer_struk,
    },
  ]

  const totalBerubah = daftarPerbedaan.filter((d) => d.berubah).length

  // Penanganan Eksekusi Simpan
  const tanganiSimpanSemua = async () => {
    if (!onSimpanSemua) return
    setSedangSimpan(true)
    try {
      const res = await onSimpanSemua()
      if (res.berhasil) {
        setToast({
          tampil: true,
          pesan: res.pesan || 'Seluruh pengaturan baru berhasil disimpan.',
          nada: 'sukses',
        })
        setDialogKonfirmasi(false)
      } else {
        setToast({
          tampil: true,
          pesan: res.pesan || 'Gagal menyimpan pengaturan.',
          nada: 'gagal',
        })
      }
    } catch (err: unknown) {
      const errPesan = err instanceof Error ? err.message : String(err)
      setToast({
        tampil: true,
        pesan: `Terjadi kesalahan: ${errPesan}`,
        nada: 'gagal',
      })
    } finally {
      setSedangSimpan(false)
    }
  }

  const tanggalPratinjau = tanggalLokal(new Date())

  return (
    <div
      className="pratinjau-pengaturan"
      data-testid="pratinjau-pengaturan"
      style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}
    >
      {/* Toast Notifikasi */}
      {toast.tampil && (
        <Toast
          pesan={toast.pesan}
          nada={toast.nada}
          aksi={
            <Tombol
              ragam="kecil"
              onClick={() => setToast({ tampil: false, pesan: '', nada: 'info' })}
            >
              Tutup
            </Tombol>
          }
        />
      )}

      {/* Bagian Kepala & Indikator Status */}
      <Kartu>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '1rem',
          }}
        >
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <h2 style={{ margin: 0, fontSize: '1.25rem' }}>
                👁️ Pratinjau Perubahan & Pengaman Riwayat
              </h2>
              {totalBerubah > 0 ? (
                <Lencana nada="accent">{totalBerubah} Pengaturan Diubah</Lencana>
              ) : (
                <Lencana nada="netral">Semua Pengaturan Selaras</Lencana>
              )}
            </div>
            <p className="muted" style={{ margin: '0.35rem 0 0 0', fontSize: '0.9rem' }}>
              Bandingkan perubahan pengaturan sebelum diterapkan. Periksa live simulasi struk untuk
              melihat dampak tagihan pada pelanggan.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
            {onKembali && (
              <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke tab sebelumnya">
                ← Kembali
              </Tombol>
            )}
            {totalBerubah > 0 && onResetDraf && !hanyaBaca && (
              <Tombol
                ragam="bahaya"
                onClick={onResetDraf}
                nama="Reset seluruh draf perubahan kembali ke nilai aktif"
              >
                Reset Draf
              </Tombol>
            )}
            {onSimpanSemua && !hanyaBaca && (
              <Tombol
                ragam="utama"
                nonaktif={totalBerubah === 0 || sedangSimpan}
                onClick={() => setDialogKonfirmasi(true)}
                nama="Terapkan dan simpan semua perubahan pengaturan"
              >
                {sedangSimpan ? 'Menyimpan...' : 'Terapkan & Simpan Pengaturan'}
              </Tombol>
            )}
          </div>
        </div>
      </Kartu>

      {/* Banner Jaminan Kekekalan Riwayat Masa Lalu (PRD M2 Kasus Tepi) */}
      <div
        style={{
          padding: '1rem 1.25rem',
          borderRadius: 'var(--radius)',
          border: '1px solid var(--border)',
          backgroundColor: 'var(--kartu)',
          display: 'flex',
          gap: '1rem',
          alignItems: 'flex-start',
        }}
        data-testid="jaminan-pengaman-riwayat"
      >
        <span style={{ fontSize: '1.75rem', lineHeight: 1 }} aria-hidden="true">
          🛡️
        </span>
        <div style={{ flex: 1 }}>
          <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: 600 }}>
            Jaminan Integritas: Riwayat Transaksi & Laporan Masa Lalu Tidak Berubah
          </h3>
          <p
            className="muted"
            style={{ margin: '0.25rem 0 0.5rem 0', fontSize: '0.875rem', lineHeight: 1.4 }}
          >
            Sistem Resto Barokah menjamin secara mutlak (<em>immutable past</em>): perubahan nama
            resto, tema visual, kenaikan tarif PB1/service charge, maupun perubahan harga menu{' '}
            <strong>tidak akan pernah mengubah struk dan laporan penjualan masa lalu</strong>.
          </p>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
              gap: '0.75rem',
              marginTop: '0.5rem',
              fontSize: '0.825rem',
            }}
          >
            <div
              style={{
                padding: '0.5rem',
                backgroundColor: 'var(--latar)',
                borderRadius: 'var(--radius)',
              }}
            >
              🔒 <strong>Transaksi Lunas Terkunci:</strong> Seluruh pesanan yang telah dibayar
              menyimpan salinan harga saat transaksi (`harga_saat_itu`) dan menolak modifikasi
              apapun dari perangkat.
            </div>
            <div
              style={{
                padding: '0.5rem',
                backgroundColor: 'var(--latar)',
                borderRadius: 'var(--radius)',
              }}
            >
              📊 <strong>Laporan Keuangan Abadi:</strong> Angka omzet, kas shift, dan rincian pajak
              pada hari-hari lampau menghasilkan selisih tepat Rp 0 (identik byte-per-byte).
            </div>
            <div
              style={{
                padding: '0.5rem',
                backgroundColor: 'var(--latar)',
                borderRadius: 'var(--radius)',
              }}
            >
              ✅ <strong>Teruji Otomatis:</strong> Dilindungi pemicu fail-closed basis data dan
              lolos uji integritas berkas <code>riwayat_tidak_berubah.sql</code>.
            </div>
          </div>
        </div>
      </div>

      {/* Bagian Diff Viewer: Perbandingan Nilai Sebelum vs Sesudah */}
      <Kartu judul="Tabel Perbandingan Pengaturan (Diff Viewer)">
        <div style={{ overflowX: 'auto' }}>
          <table
            style={{
              width: '100%',
              borderCollapse: 'collapse',
              fontSize: '0.875rem',
              textAlign: 'left',
            }}
            data-testid="tabel-diff-pengaturan"
          >
            <thead>
              <tr style={{ borderBottom: '2px solid var(--border)', color: 'var(--teks)' }}>
                <th style={{ padding: '0.5rem' }}>Kategori</th>
                <th style={{ padding: '0.5rem' }}>Parameter</th>
                <th style={{ padding: '0.5rem' }}>Saat Ini (Aktif)</th>
                <th style={{ padding: '0.5rem' }}>Draf Usulan (Baru)</th>
                <th style={{ padding: '0.5rem', textAlign: 'center' }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {daftarPerbedaan.map((row, idx) => (
                <tr
                  key={`${row.kategori}-${row.properti}`}
                  data-testid={`diff-row-${idx}`}
                  style={{
                    borderBottom: '1px solid var(--border)',
                    backgroundColor: row.berubah ? 'var(--aksen-latar)' : 'transparent',
                  }}
                >
                  <td style={{ padding: '0.65rem 0.5rem', fontWeight: 500 }}>{row.kategori}</td>
                  <td style={{ padding: '0.65rem 0.5rem' }}>{row.properti}</td>
                  <td style={{ padding: '0.65rem 0.5rem', color: 'var(--muted)' }}>{row.lama}</td>
                  <td
                    style={{
                      padding: '0.65rem 0.5rem',
                      fontWeight: row.berubah ? 600 : 'normal',
                      color: row.berubah ? 'var(--warna-utama)' : 'inherit',
                    }}
                  >
                    {row.baru}
                  </td>
                  <td style={{ padding: '0.65rem 0.5rem', textAlign: 'center' }}>
                    {row.berubah ? (
                      <Lencana nada="accent">Diubah</Lencana>
                    ) : (
                      <Lencana nada="netral">Sama</Lencana>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* Bagian Live Receipt Simulator: Simulasi Struk Berdampingan */}
      <Kartu judul="Live Receipt Simulator (Simulasi Struk Kasir Nyata)">
        {/* Kontrol Skenario & Format Kertas */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '1rem',
            marginBottom: '1rem',
            paddingBottom: '0.75rem',
            borderBottom: '1px solid var(--border)',
          }}
        >
          <div>
            <label
              style={{
                display: 'block',
                fontSize: '0.8rem',
                fontWeight: 600,
                marginBottom: '0.35rem',
              }}
            >
              Pilih Skenario Pesanan Uji:
            </label>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              {SKENARIO_CONTOH.map((s) => (
                <Tombol
                  key={s.id}
                  ragam={skenarioId === s.id ? 'utama' : 'kecil'}
                  onClick={() => setSkenarioId(s.id)}
                  nama={`Pilih skenario ${s.judul}`}
                >
                  {s.judul}
                </Tombol>
              ))}
            </div>
            <p className="muted" style={{ margin: '0.35rem 0 0 0', fontSize: '0.8rem' }}>
              {skenarioTerpilih.keterangan}
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ fontSize: '0.825rem', fontWeight: 600 }}>Format Cetak:</span>
            <Tombol
              ragam={lebarKertas === '58' ? 'utama' : 'kecil'}
              onClick={() => setLebarKertas('58')}
              nama="Gunakan lebar kertas 58 milimeter"
            >
              58 mm (Kompak)
            </Tombol>
            <Tombol
              ragam={lebarKertas === '80' ? 'utama' : 'kecil'}
              onClick={() => setLebarKertas('80')}
              nama="Gunakan lebar kertas 80 milimeter"
            >
              80 mm (Standar)
            </Tombol>
            {onCetakSimulasi && (
              <Tombol ragam="kecil" onClick={onCetakSimulasi} nama="Cetak lembar simulasi ini">
                🖨️ Cetak Uji
              </Tombol>
            )}
          </div>
        </div>

        {/* Ringkasan Dampak Selisih Finansial */}
        <div
          data-testid="ringkasan-selisih-tagihan"
          style={{
            padding: '0.75rem 1rem',
            borderRadius: 'var(--radius)',
            backgroundColor: 'var(--latar)',
            border: '1px solid var(--border)',
            marginBottom: '1.25rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '0.75rem',
          }}
        >
          <div>
            <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>
              Dampak Terhadap Tagihan Pelanggan ({skenarioTerpilih.judul}):
            </span>
            <div
              style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginTop: '0.2rem' }}
            >
              <span style={{ fontSize: '0.85rem' }}>
                Total Lama: <strong>{rupiah(tagihanLama.total)}</strong>
              </span>
              <span>➔</span>
              <span style={{ fontSize: '0.85rem' }}>
                Total Baru: <strong>{rupiah(tagihanBaru.total)}</strong>
              </span>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <span style={{ fontSize: '0.85rem' }}>Selisih:</span>
            {selisihTotal === 0 ? (
              <Lencana nada="netral">Sama Persis (Rp 0)</Lencana>
            ) : selisihTotal > 0 ? (
              <Lencana nada="accent">
                +{rupiah(selisihTotal)} (+{persentasePerubahan}%)
              </Lencana>
            ) : (
              <Lencana nada="accent">
                {rupiah(selisihTotal)} ({persentasePerubahan}%)
              </Lencana>
            )}
          </div>
        </div>

        {/* Tampilan Struk Berdampingan (Side-by-Side Receipts) */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
            gap: '1.5rem',
            justifyItems: 'center',
          }}
        >
          {/* Struk Lama (Aturan Aktif) */}
          <div
            data-testid="struk-lama"
            style={{
              width: lebarKertas === '58' ? '280px' : '360px',
              border: '1px dashed var(--border)',
              borderRadius: 'var(--radius)',
              padding: '1rem',
              backgroundColor: 'var(--kartu)',
              fontFamily: 'monospace',
              fontSize: '0.825rem',
            }}
          >
            <div
              style={{
                textAlign: 'center',
                borderBottom: '1px dashed var(--border)',
                paddingBottom: '0.5rem',
                marginBottom: '0.5rem',
              }}
            >
              <span
                style={{
                  display: 'inline-block',
                  padding: '0.15rem 0.5rem',
                  fontSize: '0.7rem',
                  borderRadius: 'var(--radius)',
                  backgroundColor: 'var(--border)',
                  marginBottom: '0.35rem',
                }}
              >
                STRUK ATURAN AKTIF (LAMA)
              </span>
              {operasionalAktif.header_struk && (
                <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                  {operasionalAktif.header_struk}
                </div>
              )}
              <div style={{ fontWeight: 'bold', fontSize: '1rem', marginTop: '0.2rem' }}>
                {identitasAktif.namaResto}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                {tanggalPratinjau} · No. 0101 · Meja 04
              </div>
            </div>

            {/* Daftar Item */}
            <div style={{ borderBottom: '1px dashed var(--border)', paddingBottom: '0.5rem' }}>
              {skenarioTerpilih.item.map((item, i) => (
                <div
                  key={i}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: '0.25rem',
                  }}
                >
                  <span>
                    {item.nama} x{item.qty}
                  </span>
                  <span>{rupiah(item.qty * item.harga)}</span>
                </div>
              ))}
            </div>

            {/* Rincian Uang */}
            <div
              style={{
                paddingTop: '0.5rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.25rem',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Subtotal:</span>
                <span>{rupiah(tagihanLama.subtotal)}</span>
              </div>
              {tagihanLama.diskon > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>Diskon Promo:</span>
                  <span>−{rupiah(tagihanLama.diskon)}</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>PB1 ({operasionalAktif.pajak_pb1_persen}%):</span>
                <span>{rupiah(tagihanLama.pajak)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Service ({operasionalAktif.service_persen}%):</span>
                <span>{rupiah(tagihanLama.service)}</span>
              </div>
              {tagihanLama.selisihBulat !== 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>Pembulatan:</span>
                  <span>
                    {tagihanLama.selisihBulat < 0 ? '−' : '+'}
                    {rupiah(Math.abs(tagihanLama.selisihBulat))}
                  </span>
                </div>
              )}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontWeight: 'bold',
                  fontSize: '0.95rem',
                  borderTop: '1px solid var(--border)',
                  paddingTop: '0.35rem',
                  marginTop: '0.25rem',
                }}
              >
                <span>TOTAL:</span>
                <span>{rupiah(tagihanLama.total)}</span>
              </div>
            </div>

            {/* Footer Struk */}
            {operasionalAktif.footer_struk && (
              <div
                style={{
                  textAlign: 'center',
                  fontSize: '0.75rem',
                  color: 'var(--muted)',
                  borderTop: '1px dashed var(--border)',
                  paddingTop: '0.5rem',
                  marginTop: '0.5rem',
                }}
              >
                {operasionalAktif.footer_struk}
              </div>
            )}
          </div>

          {/* Struk Baru (Simulasi Aturan Usulan) */}
          <div
            data-testid="struk-baru"
            style={{
              width: lebarKertas === '58' ? '280px' : '360px',
              border: '2px solid var(--warna-utama)',
              borderRadius: 'var(--radius)',
              padding: '1rem',
              backgroundColor: 'var(--kartu)',
              fontFamily: 'monospace',
              fontSize: '0.825rem',
            }}
          >
            <div
              style={{
                textAlign: 'center',
                borderBottom: '1px dashed var(--border)',
                paddingBottom: '0.5rem',
                marginBottom: '0.5rem',
              }}
            >
              <span
                style={{
                  display: 'inline-block',
                  padding: '0.15rem 0.5rem',
                  fontSize: '0.7rem',
                  borderRadius: 'var(--radius)',
                  backgroundColor: 'var(--warna-utama)',
                  color: 'white',
                  fontWeight: 'bold',
                  marginBottom: '0.35rem',
                }}
              >
                SIMULASI ATURAN BARU
              </span>
              {operasionalBaru.header_struk && (
                <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                  {operasionalBaru.header_struk}
                </div>
              )}
              <div
                style={{
                  fontWeight: 'bold',
                  fontSize: '1rem',
                  marginTop: '0.2rem',
                  color: 'var(--warna-utama)',
                }}
              >
                {identitasBaru.namaResto}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>
                {tanggalPratinjau} · No. 0101 · Meja 04
              </div>
            </div>

            {/* Daftar Item */}
            <div style={{ borderBottom: '1px dashed var(--border)', paddingBottom: '0.5rem' }}>
              {skenarioTerpilih.item.map((item, i) => (
                <div
                  key={i}
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginBottom: '0.25rem',
                  }}
                >
                  <span>
                    {item.nama} x{item.qty}
                  </span>
                  <span>{rupiah(item.qty * item.harga)}</span>
                </div>
              ))}
            </div>

            {/* Rincian Uang */}
            <div
              style={{
                paddingTop: '0.5rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.25rem',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Subtotal:</span>
                <span>{rupiah(tagihanBaru.subtotal)}</span>
              </div>
              {tagihanBaru.diskon > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span>Diskon Promo:</span>
                  <span>−{rupiah(tagihanBaru.diskon)}</span>
                </div>
              )}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontWeight:
                    operasionalAktif.pajak_pb1_persen !== operasionalBaru.pajak_pb1_persen
                      ? 'bold'
                      : 'normal',
                }}
              >
                <span>PB1 ({operasionalBaru.pajak_pb1_persen}%):</span>
                <span>{rupiah(tagihanBaru.pajak)}</span>
              </div>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontWeight:
                    operasionalAktif.service_persen !== operasionalBaru.service_persen
                      ? 'bold'
                      : 'normal',
                }}
              >
                <span>Service ({operasionalBaru.service_persen}%):</span>
                <span>{rupiah(tagihanBaru.service)}</span>
              </div>
              {tagihanBaru.selisihBulat !== 0 && (
                <div
                  style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold' }}
                >
                  <span>Pembulatan:</span>
                  <span>
                    {tagihanBaru.selisihBulat < 0 ? '−' : '+'}
                    {rupiah(Math.abs(tagihanBaru.selisihBulat))}
                  </span>
                </div>
              )}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontWeight: 'bold',
                  fontSize: '0.95rem',
                  borderTop: '1px solid var(--border)',
                  paddingTop: '0.35rem',
                  marginTop: '0.25rem',
                  color: 'var(--warna-utama)',
                }}
              >
                <span>TOTAL:</span>
                <span>{rupiah(tagihanBaru.total)}</span>
              </div>
            </div>

            {/* Footer Struk */}
            {operasionalBaru.footer_struk && (
              <div
                style={{
                  textAlign: 'center',
                  fontSize: '0.75rem',
                  color: 'var(--muted)',
                  borderTop: '1px dashed var(--border)',
                  paddingTop: '0.5rem',
                  marginTop: '0.5rem',
                }}
              >
                {operasionalBaru.footer_struk}
              </div>
            )}
          </div>
        </div>
      </Kartu>

      {/* Modal / Dialog Konfirmasi Simpan Definitif */}
      <Lapis
        buka={dialogKonfirmasi}
        judul="Konfirmasi Terapkan Perubahan Pengaturan"
        onTutup={() => setDialogKonfirmasi(false)}
        kaki={
          <div
            style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', width: '100%' }}
          >
            <Tombol
              ragam="biasa"
              onClick={() => setDialogKonfirmasi(false)}
              nonaktif={sedangSimpan}
              nama="Batal simpan dan kembali ke pratinjau"
            >
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={tanganiSimpanSemua}
              nonaktif={sedangSimpan}
              nama="Konfirmasi simpan seluruh pengaturan"
            >
              {sedangSimpan ? 'Menyimpan...' : 'Ya, Terapkan Sekarang'}
            </Tombol>
          </div>
        }
      >
        <div data-testid="dialog-konfirmasi-simpan">
          <p
            className="muted"
            style={{ margin: '0 0 1rem 0', fontSize: '0.875rem', lineHeight: 1.4 }}
          >
            Anda akan menyimpan <strong>{totalBerubah} perubahan pengaturan</strong> ke basis data.
            Perubahan ini akan langsung berlaku pada seluruh transaksi baru berikutnya.
          </p>
          <div
            style={{
              backgroundColor: 'var(--latar)',
              borderRadius: 'var(--radius)',
              padding: '0.75rem',
              fontSize: '0.8rem',
              border: '1px solid var(--border)',
            }}
          >
            🛡️ <strong>Jaminan:</strong> Transaksi lama, struk yang telah dicetak, dan laporan
            keuangan masa lalu tidak akan terpengaruh.
          </div>
        </div>
      </Lapis>
    </div>
  )
}
