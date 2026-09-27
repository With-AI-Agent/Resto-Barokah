/**
 * CabutAkses.tsx — Cabut Akses Cepat Pegawai Berhenti & Serah Terima (T10-12 / PRD M3 & M12 / ART-2)
 *
 * Fitur:
 *  1. Satu tombol pencabutan akses atomik:
 *     - Akun seketika dinonaktifkan (aktif = false).
 *     - Semua sesi aktif perangkat dan cabang diputus.
 *     - PIN dihapus dari sistem sehingga tidak bisa masuk lagi.
 *     - Shift kasir terbuka ditandai untuk ditutup atasan (rekonsiliasi kas fisik di laci).
 *  2. Jaminan Integritas Finansial (ART-2):
 *     - Riwayat transaksi, struk lama, dan laporan tidak hilang (tanpa hard-delete).
 *     - Jejak serah terima kekal tercatat di catatan_audit.
 */

import { useState } from 'react'
import { Lapis } from '../../komponen/Lapis'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import type { PegawaiResto } from './KelolaPegawai'

export interface CabutAksesProps {
  buka: boolean
  pegawai: PegawaiResto | null
  onTutup: () => void
  onKonfirmasi: (data: {
    pegawaiId: string
    alasan: string
    catatanSerahTerima: string
  }) => Promise<{ sukses: boolean; pesan?: string }>
}

export function CabutAkses({ buka, pegawai, onTutup, onKonfirmasi }: CabutAksesProps) {
  const [alasan, setAlasan] = useState('Pegawai berhenti / mengundurkan diri (resign)')
  const [catatanSerahTerima, setCatatanSerahTerima] = useState('')
  const [sedangProses, setSedangProses] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [konfirmasiKetik, setKonfirmasiKetik] = useState('')

  if (!buka || !pegawai) return null

  const tanganiSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (konfirmasiKetik.trim().toUpperCase() !== 'CABUT') {
      setPesanGalat('Ketik kata CABUT untuk mengonfirmasi tindakan penting ini.')
      return
    }

    setSedangProses(true)
    setPesanGalat(null)

    try {
      const hasil = await onKonfirmasi({
        pegawaiId: pegawai.id,
        alasan: alasan.trim(),
        catatanSerahTerima: catatanSerahTerima.trim(),
      })

      if (hasil.sukses) {
        onTutup()
      } else {
        setPesanGalat(hasil.pesan || 'Gagal mencabut akses pegawai.')
      }
    } catch (err: unknown) {
      const pesan =
        err instanceof Error ? err.message : 'Terjadi kendala saat memproses serah terima.'
      setPesanGalat(pesan)
    } finally {
      setSedangProses(false)
    }
  }

  return (
    <Lapis buka={buka} onTutup={onTutup} judul={`Cabut Akses: ${pegawai.nama}`}>
      <form onSubmit={tanganiSubmit} className="p-4 space-y-4">
        {pesanGalat && (
          <div
            role="alert"
            className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800"
          >
            {pesanGalat}
          </div>
        )}

        {/* Kartu Ringkasan Pegawai */}
        <div className="p-3 bg-neutral-50 rounded border border-neutral-200 space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-semibold text-neutral-800">{pegawai.nama}</span>
            <Lencana nada={pegawai.aktif ? 'success' : 'danger'}>
              {pegawai.peran.toUpperCase()}
            </Lencana>
          </div>
          <div className="text-xs text-neutral-600">
            Email: <span className="font-mono">{pegawai.email}</span> · Cabang: {pegawai.namaCabang}
          </div>
        </div>

        {/* Penjelasan Perlindungan Keamanan & Serah Terima */}
        <div className="p-3 bg-amber-50 border border-amber-200 rounded text-xs text-amber-900 space-y-1.5">
          <div className="font-semibold flex items-center gap-1.5">
            <span>Tindakan serah terima & pengamanan sistem:</span>
          </div>
          <ul className="list-disc pl-4 space-y-1">
            <li>
              <strong>Akun seketika dinonaktifkan:</strong> Pegawai tidak lagi memiliki hak akses
              apa pun.
            </li>
            <li>
              <strong>Sesi perangkat diakhiri:</strong> Seluruh login di tablet/ponsel kasir
              seketika dicabut.
            </li>
            <li>
              <strong>Kredensial PIN dihapus:</strong> PIN masuk dihapus permanen dari basis data.
            </li>
            <li>
              <strong>Shift kasir ditandai:</strong> Jika kasir meninggalkan shift terbuka, atasan
              (Admin Cabang / Owner Pusat) wajib menutupnya setelah menghitung kas fisik.
            </li>
            <li>
              <strong>Jaminan Laporan Masa Lalu:</strong> Nama dan seluruh transaksi historis
              pegawai tetap utuh di pembukuan kedai.
            </li>
          </ul>
        </div>

        <KolomIsian
          label="Alasan Berhenti / Pencabutan Akses"
          contoh="Contoh: Mengundurkan diri (resign) per akhir bulan"
          nilai={alasan}
          onUbah={setAlasan}
          wajib
        />

        <div className="kolom-isian">
          <label className="label">Catatan Serah Terima (Kas / Alat / Kunci)</label>
          <textarea
            className="input min-h-[72px]"
            placeholder="Contoh: Kunci laci kas fisik telah diserahkan ke Admin. Laci kas berisi modal awal Rp 100.000."
            value={catatanSerahTerima}
            onChange={(e) => setCatatanSerahTerima(e.target.value)}
          />
        </div>

        <div className="pt-2 border-t border-neutral-200 space-y-2">
          <KolomIsian
            label="Ketik kata 'CABUT' untuk konfirmasi"
            contoh="CABUT"
            nilai={konfirmasiKetik}
            onUbah={setKonfirmasiKetik}
            keterangan="Konfirmasi tambahan untuk mencegah salah klik."
            wajib
          />

          <div className="flex justify-end gap-2 pt-2">
            <Tombol ragam="biasa" onClick={onTutup} nonaktif={sedangProses}>
              Batal
            </Tombol>
            <Tombol
              ragam="bahaya"
              jenis="submit"
              nonaktif={sedangProses || konfirmasiKetik.trim().toUpperCase() !== 'CABUT'}
            >
              {sedangProses ? 'Mencabut Akses...' : 'Cabut Akses Sekarang'}
            </Tombol>
          </div>
        </div>
      </form>
    </Lapis>
  )
}
