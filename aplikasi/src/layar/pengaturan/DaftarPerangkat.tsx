import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'
import type { PeranPengguna } from '../../lib/auth'

export interface ItemPerangkat {
  id: string
  nama: string
  cabangId: string
  namaCabang: string
  peranDiizinkan: PeranPengguna[]
  aktif: boolean
  terakhirAktif: string
  jumlahSesiAktif: number
}

export interface DaftarPerangkatProps {
  daftarPerangkat?: ItemPerangkat[]
  onCabutPerangkat?: (perangkatId: string, alasan: string) => Promise<{ sukses: boolean; pesan?: string }>
  onSegarkan?: () => void
}

const CONTOH_PERANGKAT: ItemPerangkat[] = [
  {
    id: 'dev-01',
    nama: 'Tablet POS Kasir 1',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    peranDiizinkan: ['kasir'],
    aktif: true,
    terakhirAktif: new Date().toISOString(),
    jumlahSesiAktif: 1,
  },
  {
    id: 'dev-02',
    nama: 'Tablet Waiter Outdoor',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    peranDiizinkan: ['pelayan'],
    aktif: true,
    terakhirAktif: new Date(Date.now() - 3600000).toISOString(),
    jumlahSesiAktif: 0,
  },
  {
    id: 'dev-03',
    nama: 'Layar Dapur Display (KDS)',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    peranDiizinkan: ['dapur'],
    aktif: false,
    terakhirAktif: new Date(Date.now() - 86400000).toISOString(),
    jumlahSesiAktif: 0,
  },
]

export function DaftarPerangkat({
  daftarPerangkat = CONTOH_PERANGKAT,
  onCabutPerangkat = async () => ({ sukses: true }),
  onSegarkan,
}: DaftarPerangkatProps) {
  const [daftar, setDaftar] = useState<ItemPerangkat[]>(daftarPerangkat)
  const [perangkatTarget, setPerangkatTarget] = useState<ItemPerangkat | null>(null)
  const [alasanCabut, setAlasanCabut] = useState('')
  const [sedangMencabut, setSedangMencabut] = useState(false)

  const konfirmasiCabut = (perangkat: ItemPerangkat) => {
    setPerangkatTarget(perangkat)
    setAlasanCabut('Perangkat hilang / ditarik dari operasional')
  }

  const eksekusiCabut = async () => {
    if (!perangkatTarget || !alasanCabut.trim()) return

    setSedangMencabut(true)
    try {
      const hasil = await onCabutPerangkat(perangkatTarget.id, alasanCabut.trim())
      if (hasil.sukses) {
        setDaftar((prev) =>
          prev.map((p) => (p.id === perangkatTarget.id ? { ...p, aktif: false, jumlahSesiAktif: 0 } : p))
        )
        setPerangkatTarget(null)
        onSegarkan?.()
      } else {
        alert(hasil.pesan || 'Gagal mencabut izin perangkat.')
      }
    } catch {
      alert('Terjadi kesalahan jaringan saat mencabut perangkat.')
    } finally {
      setSedangMencabut(false)
    }
  }

  return (
    <div className="layar-daftar-perangkat space-y-6 max-w-5xl mx-auto p-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">Daftar Perangkat & Sesi Kasir</h2>
          <p className="text-sm text-neutral-500">
            Pantau tablet POS aktif dan cabut izin seketika bila ada perangkat yang hilang atau dicuri.
          </p>
        </div>
      </div>

      <Kartu judul={`Daftar Perangkat Terdaftar (${daftar.length})`}>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-neutral-200 text-neutral-600">
                <th className="py-2.5">Nama Perangkat</th>
                <th className="py-2.5">Cabang</th>
                <th className="py-2.5">Peran Diizinkan</th>
                <th className="py-2.5">Status</th>
                <th className="py-2.5">Sesi Aktif</th>
                <th className="py-2.5 text-right">Aksi Keamanan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {daftar.map((perangkat) => (
                <tr key={perangkat.id} className="hover:bg-neutral-50/50">
                  <td className="py-3.5 font-semibold text-neutral-800">
                    <div>{perangkat.nama}</div>
                    <div className="text-[11px] font-mono text-neutral-400">ID: {perangkat.id}</div>
                  </td>
                  <td className="py-3.5 text-neutral-600">{perangkat.namaCabang}</td>
                  <td className="py-3.5">
                    <div className="flex flex-wrap gap-1">
                      {perangkat.peranDiizinkan.map((r) => (
                        <Lencana key={r} nada="netral">
                          {r.toUpperCase()}
                        </Lencana>
                      ))}
                    </div>
                  </td>
                  <td className="py-3.5">
                    <Lencana nada={perangkat.aktif ? 'success' : 'danger'}>
                      {perangkat.aktif ? 'Aktif Resmi' : 'Dicabut / Nonaktif'}
                    </Lencana>
                  </td>
                  <td className="py-3.5">
                    {perangkat.jumlahSesiAktif > 0 ? (
                      <span className="inline-flex items-center gap-1.5 text-emerald-700 font-medium text-xs">
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                        {perangkat.jumlahSesiAktif} staf masuk
                      </span>
                    ) : (
                      <span className="text-neutral-400 text-xs">Kosong</span>
                    )}
                  </td>
                  <td className="py-3.5 text-right">
                    {perangkat.aktif ? (
                      <Tombol
                        ragam="bahaya"
                        onClick={() => konfirmasiCabut(perangkat)}
                        nama="Cabut Izin"
                      >
                        Cabut Izin
                      </Tombol>
                    ) : (
                      <span className="text-xs text-neutral-400 italic">Telah Dicabut</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* Dialog Konfirmasi Cabut Perangkat */}
      {perangkatTarget && (
        <Lapis buka={true} onTutup={() => setPerangkatTarget(null)} judul="Konfirmasi Cabut Izin Perangkat">
          <div className="p-4 space-y-4">
            <div className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800">
              <p className="font-semibold mb-1">
                Peringatan Keamanan: Perangkat &quot;{perangkatTarget.nama}&quot; akan langsung diputuskan!
              </p>
              <p className="text-xs">
                Seluruh staf yang sedang masuk di perangkat ini akan dikeluarkan seketika, dan perangkat tidak dapat
                digunakan lagi sampai didaftarkan ulang dengan kode baru.
              </p>
            </div>

            <KolomIsian
              label="Alasan Pencabutan (Wajib untuk catatan audit resto)"
              nilai={alasanCabut}
              onUbah={setAlasanCabut}
              contoh="Contoh: Tablet hilang saat jam tutup resto"
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setPerangkatTarget(null)} nonaktif={sedangMencabut}>
                Batal
              </Tombol>
              <Tombol
                ragam="bahaya"
                onClick={eksekusiCabut}
                nonaktif={sedangMencabut || !alasanCabut.trim()}
              >
                {sedangMencabut ? 'Mencabut...' : 'Ya, Cabut Izin Sekarang'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
