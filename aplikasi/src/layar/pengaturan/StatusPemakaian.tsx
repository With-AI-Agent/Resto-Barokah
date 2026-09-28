/**
 * StatusPemakaian.tsx — Pemantauan Batas Gratis & Kuota Layanan (T11-08 / TECH_SPEC §10 & §13 K6)
 *
 * Mengizinkan Pemilik (Owner/Lee) untuk:
 *  1. Memantau konsumsi 5 dimensi kapasitas layanan (Basis Data, Foto, Lalu Lintas, Email, Denyut).
 *  2. Mengetahui persentase kapasitas berbanding batas kuota gratis 100% (Rp 0/bulan).
 *  3. Mendeteksi peringatan dini otomatis di ambang 70% (Waspada) dan 90% (Bahaya).
 *  4. Melihat catatan waktu terakhir diperiksa dan melakukan pengecekan ulang manual.
 */

import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana, type NadaLencana } from '../../komponen/Lencana'

export interface ItemKapasitas {
  judul: string
  pemakaian: number
  batas: number
  satuan: string
  keterangan: string
}

export interface DataStatusPemakaian {
  waktuTerakhirDiperiksa: string
  basisData: ItemKapasitas
  penyimpananFoto: ItemKapasitas
  laluLintas: ItemKapasitas
  email: ItemKapasitas
  denyutHarianHari: number
}

export interface StatusPemakaianProps {
  dataAwal?: DataStatusPemakaian
  onSegarkan?: () => Promise<DataStatusPemakaian>
  onKembali?: () => void
}

const DATA_BAWAAN: DataStatusPemakaian = {
  waktuTerakhirDiperiksa: '2026-09-27T08:00:00Z',
  basisData: {
    judul: 'Basis Data PostgreSQL (Supabase)',
    pemakaian: 35.0,
    batas: 500.0,
    satuan: 'MB',
    keterangan: 'Menyimpan transaksi pesanan, katalog menu, akun pegawai, dan rantai audit.',
  },
  penyimpananFoto: {
    judul: 'Penyimpanan Foto Menu (Storage)',
    pemakaian: 1.2,
    batas: 1024.0,
    satuan: 'MB',
    keterangan: 'Foto menu terkompresi WebP (< 100 KB/foto).',
  },
  laluLintas: {
    judul: 'Lalu Lintas Jaringan / Egress',
    pemakaian: 450.0,
    batas: 5120.0,
    satuan: 'MB',
    keterangan: 'Beban lalu lintas data bulanan API Supabase & Cloudflare.',
  },
  email: {
    judul: 'Email Transaksional (Brevo/Resend)',
    pemakaian: 90,
    batas: 3000,
    satuan: 'email',
    keterangan: 'Email ringkasan harian, verifikasi akun, dan kode pendaftaran perangkat.',
  },
  denyutHarianHari: 1,
}

function hitungRasio(
  pemakaian: number,
  batas: number,
): {
  persen: number
  status: 'aman' | 'waspada' | 'bahaya'
  nada: NadaLencana
} {
  if (batas <= 0) return { persen: 0, status: 'aman', nada: 'success' }
  const persen = Math.round((pemakaian / batas) * 1000) / 10
  if (persen >= 90) return { persen, status: 'bahaya', nada: 'danger' }
  if (persen >= 70) return { persen, status: 'waspada', nada: 'warn' }
  return { persen, status: 'aman', nada: 'success' }
}

export function StatusPemakaian({ dataAwal, onSegarkan, onKembali }: StatusPemakaianProps) {
  const [data, setData] = useState<DataStatusPemakaian>(dataAwal || DATA_BAWAAN)
  const [memuat, setMemuat] = useState(false)
  const [pesan, setPesan] = useState<string | null>(null)

  const handleSegarkan = async () => {
    if (!onSegarkan) return
    setMemuat(true)
    setPesan(null)
    try {
      const dataBaru = await onSegarkan()
      setData(dataBaru)
      setPesan('Status pemakaian berhasil diperbarui!')
    } catch {
      setPesan('Gagal memeriksa status kapasitas. Menggunakan data lokal.')
    } finally {
      setMemuat(false)
    }
  }

  const items = [data.basisData, data.penyimpananFoto, data.laluLintas, data.email]

  const adaWaspada = items.some((i) => hitungRasio(i.pemakaian, i.batas).status === 'waspada')
  const adaBahaya = items.some((i) => hitungRasio(i.pemakaian, i.batas).status === 'bahaya')

  return (
    <div
      className="status-pemakaian"
      style={{ padding: '1rem', maxWidth: '900px', margin: '0 auto' }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '1.5rem',
          flexWrap: 'wrap',
          gap: '1rem',
        }}
      >
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', margin: 0 }}>
            Status Batas Gratis & Kapasitas (K6)
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--teks-redup)', margin: '0.25rem 0 0 0' }}>
            Komitmen biaya Rp 0/bulan — Bayar setelah ada pemasukan (TECH_SPEC §10 & §13).
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali}>
              Kembali
            </Tombol>
          )}
          <Tombol ragam="utama" onClick={handleSegarkan} nonaktif={memuat}>
            {memuat ? 'Memeriksa...' : 'Periksa Ulang'}
          </Tombol>
        </div>
      </div>

      {pesan && (
        <div
          style={{
            padding: '0.75rem',
            background: 'var(--kartu-lembut)',
            border: '1px solid var(--border)',
            borderRadius: '8px',
            marginBottom: '1rem',
            fontSize: '0.875rem',
          }}
        >
          {pesan}
        </div>
      )}

      {/* Ringkasan Keseluruhan */}
      <Kartu kelas="mb-4">
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '1rem',
          }}
        >
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontWeight: 600 }}>Status Biaya Saat Ini:</span>
              <Lencana nada={adaBahaya ? 'danger' : adaWaspada ? 'warn' : 'success'}>
                {adaBahaya
                  ? 'PERINGATAN DARURAT (≥ 90%)'
                  : adaWaspada
                    ? 'WASPADA (≥ 70%)'
                    : 'AMAN (BIAYA RP 0)'}
              </Lencana>
            </div>
            <p style={{ fontSize: '0.75rem', color: 'var(--teks-redup)', marginTop: '0.25rem' }}>
              Terakhir diperiksa: {new Date(data.waktuTerakhirDiperiksa).toLocaleString('id-ID')}
            </p>
          </div>
          <div style={{ textAlign: 'right' }}>
            <span style={{ fontSize: '0.75rem', color: 'var(--teks-redup)' }}>
              Denyut Anti-Tidur:
            </span>
            <p style={{ fontSize: '0.875rem', fontWeight: 500, margin: 0, color: 'var(--sukses)' }}>
              Hari ke-{data.denyutHarianHari} (Batas 7 hari) 🟢
            </p>
          </div>
        </div>
      </Kartu>

      {/* Daftar 4 Metrik */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}
      >
        {items.map((item, idx) => {
          const { persen, nada, status } = hitungRasio(item.pemakaian, item.batas)
          const warnaBar =
            status === 'bahaya'
              ? 'var(--bahaya, #ef4444)'
              : status === 'waspada'
                ? 'var(--peringatan, #f59e0b)'
                : 'var(--sukses, #10b981)'

          return (
            <Kartu key={idx}>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  marginBottom: '0.75rem',
                }}
              >
                <h3 style={{ fontSize: '0.875rem', fontWeight: 600, margin: 0 }}>{item.judul}</h3>
                <Lencana nada={nada}>{persen}%</Lencana>
              </div>

              {/* Progress Bar */}
              <div
                style={{
                  width: '100%',
                  background: 'var(--border)',
                  height: '10px',
                  borderRadius: '9999px',
                  overflow: 'hidden',
                  marginBottom: '0.5rem',
                }}
              >
                <div
                  style={{
                    height: '10px',
                    borderRadius: '9999px',
                    transition: 'all 0.3s',
                    background: warnaBar,
                    width: `${Math.min(persen, 100)}%`,
                  }}
                />
              </div>

              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontSize: '0.75rem',
                  color: 'var(--teks-redup)',
                  marginBottom: '0.25rem',
                }}
              >
                <span>
                  Pemakaian: {item.pemakaian} {item.satuan}
                </span>
                <span>
                  Batas: {item.batas} {item.satuan}
                </span>
              </div>

              <p
                style={{
                  fontSize: '0.75rem',
                  color: 'var(--teks-redup)',
                  fontStyle: 'italic',
                  margin: 0,
                }}
              >
                {item.keterangan}
              </p>
            </Kartu>
          )
        })}
      </div>

      {/* Panduan Pemilik K6 */}
      <Kartu kelas="panduan-k6">
        <h4 style={{ fontWeight: 'bold', margin: '0 0 0.5rem 0', fontSize: '0.875rem' }}>
          Pedoman Ambang Peringatan Pemilik (Lee):
        </h4>
        <ul
          style={{
            paddingLeft: '1.25rem',
            margin: 0,
            fontSize: '0.75rem',
            lineHeight: '1.5',
            color: 'var(--teks-redup)',
          }}
        >
          <li>
            <strong>Ambang 70% (Waspada):</strong> Sistem mengirim email dini ke pemilik. Belum ada
            biaya, tetapi kedai dianjurkan merapikan foto/arsip log.
          </li>
          <li>
            <strong>Ambang 90% (Bahaya):</strong> Email darurat dikirim. Pertimbangkan peningkatan
            ke paket Supabase Pro ($25/bln) yang dapat disubsidi dari pemasukan langganan SaaS
            resto.
          </li>
          <li>
            <strong>Denyut Harian:</strong> Berjalan otomatis setiap pukul 02:00 WIB via alur kerja
            CI agar proyek tidak pernah tertidur tanpa aktivitas.
          </li>
        </ul>
      </Kartu>
    </div>
  )
}
