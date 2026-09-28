import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'

export type StatusPesanan = 'draf' | 'dikirim' | 'dimasak' | 'siap' | 'selesai' | 'batal'

export interface ItemRingkasPesanan {
  id: string
  nomorPesanan: string
  nomorMeja: string
  tipePesanan: 'dine-in' | 'takeaway' | 'ojol'
  waktuDibuat: string
  jumlahItem: number
  totalHarga: number
  status: StatusPesanan
  namaPelanggan?: string
}

export interface DaftarPesananProps {
  cabangId?: string
  daftarPesananAwal?: ItemRingkasPesanan[]
  onPilihPesanan?: (pesananId: string) => void
  onCetakUlang?: (pesananId: string) => void
}

const DATA_PESANAN_CONTOH: ItemRingkasPesanan[] = [
  {
    id: 'ord-101',
    nomorPesanan: 'ORD-20260922-001',
    nomorMeja: 'Meja 01',
    tipePesanan: 'dine-in',
    waktuDibuat: '12:30',
    jumlahItem: 3,
    totalHarga: 62000,
    status: 'siap',
    namaPelanggan: 'Budi Santoso',
  },
  {
    id: 'ord-102',
    nomorPesanan: 'ORD-20260922-002',
    nomorMeja: 'Meja 04',
    tipePesanan: 'dine-in',
    waktuDibuat: '12:45',
    jumlahItem: 5,
    totalHarga: 124000,
    status: 'dimasak',
    namaPelanggan: 'Siti Rahma',
  },
  {
    id: 'ord-103',
    nomorPesanan: 'ORD-20260922-003',
    nomorMeja: 'Takeaway',
    tipePesanan: 'takeaway',
    waktuDibuat: '13:00',
    jumlahItem: 2,
    totalHarga: 34000,
    status: 'selesai',
    namaPelanggan: 'Agus',
  },
  {
    id: 'ord-104',
    nomorPesanan: 'ORD-20260922-004',
    nomorMeja: 'GrabFood',
    tipePesanan: 'ojol',
    waktuDibuat: '13:10',
    jumlahItem: 4,
    totalHarga: 98000,
    status: 'dikirim',
    namaPelanggan: 'Driver Grab 442',
  },
]

export function DaftarPesanan({
  daftarPesananAwal = DATA_PESANAN_CONTOH,
  onPilihPesanan,
  onCetakUlang,
}: DaftarPesananProps) {
  const [filterStatus, setFilterStatus] = useState<string>('semua')
  const [filterTipe, setFilterTipe] = useState<string>('semua')
  const [kataKunci, setKataKunci] = useState('')

  const daftarTersaring = daftarPesananAwal.filter((p) => {
    const cocokStatus = filterStatus === 'semua' || p.status === filterStatus
    const cocokTipe = filterTipe === 'semua' || p.tipePesanan === filterTipe
    const cocokCari =
      p.nomorPesanan.toLowerCase().includes(kataKunci.toLowerCase()) ||
      p.nomorMeja.toLowerCase().includes(kataKunci.toLowerCase()) ||
      (p.namaPelanggan && p.namaPelanggan.toLowerCase().includes(kataKunci.toLowerCase()))
    return cocokStatus && cocokTipe && cocokCari
  })

  const getStatusBadge = (status: StatusPesanan) => {
    switch (status) {
      case 'siap':
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
            ✅ Siap Disajikan
          </span>
        )
      case 'dimasak':
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
            🍳 Sedang Dimasak
          </span>
        )
      case 'dikirim':
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-blue-100 text-blue-800">
            🛵 Menuju Meja/Dapur
          </span>
        )
      case 'selesai':
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-neutral-200 text-neutral-700">
            🏁 Selesai & Lunas
          </span>
        )
      case 'batal':
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-red-100 text-red-700">
            ❌ Dibatalkan
          </span>
        )
      default:
        return (
          <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-neutral-100 text-neutral-600">
            📝 Draf
          </span>
        )
    }
  }

  return (
    <div className="daftar-pesanan-hari-ini bg-white p-4 rounded-2xl border border-neutral-200 shadow-sm space-y-4 max-w-5xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-neutral-100 pb-3">
        <div>
          <h2 className="text-lg font-bold text-neutral-800">Riwayat Pesanan Hari Ini</h2>
          <p className="text-xs text-neutral-500">
            Daftar seluruh transaksi dan pesanan aktif cabang hari ini.
          </p>
        </div>
        <div className="text-xs font-semibold px-2.5 py-1 bg-emerald-50 text-emerald-800 rounded-lg border border-emerald-200 w-fit">
          Total: {daftarTersaring.length} Pesanan
        </div>
      </div>

      {/* Baris Filter & Pencarian */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 items-end">
        <KolomIsian
          label="Pencarian Pesanan"
          nilai={kataKunci}
          onUbah={setKataKunci}
          contoh="🔍 Cari nomor pesanan, meja, atau nama..."
        />

        <div className="flex gap-1.5 overflow-x-auto pb-1">
          {['semua', 'dine-in', 'takeaway', 'ojol'].map((tipe) => (
            <Tombol
              key={tipe}
              ragam={filterTipe === tipe ? 'utama' : 'biasa'}
              onClick={() => setFilterTipe(tipe)}
            >
              {tipe.toUpperCase()}
            </Tombol>
          ))}
        </div>

        <div className="flex gap-1.5 overflow-x-auto pb-1">
          {['semua', 'dimasak', 'siap', 'selesai'].map((st) => (
            <Tombol
              key={st}
              ragam={filterStatus === st ? 'utama' : 'biasa'}
              onClick={() => setFilterStatus(st)}
            >
              {st}
            </Tombol>
          ))}
        </div>
      </div>

      {/* Tabel / Daftar Pesanan */}
      {daftarTersaring.length === 0 ? (
        <div className="p-8 text-center bg-neutral-50 rounded-xl text-neutral-400 text-sm">
          Tidak ada pesanan yang sesuai dengan filter atau pencarian.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-neutral-50 text-neutral-500 text-xs uppercase border-b border-neutral-200">
              <tr>
                <th className="p-3">No. Pesanan</th>
                <th className="p-3">Meja / Tipe</th>
                <th className="p-3">Pelanggan</th>
                <th className="p-3">Waktu</th>
                <th className="p-3 text-right">Total</th>
                <th className="p-3 text-center">Status</th>
                <th className="p-3 text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {daftarTersaring.map((p) => (
                <tr key={p.id} className="hover:bg-neutral-50 transition-colors">
                  <td className="p-3 font-bold text-neutral-800">{p.nomorPesanan}</td>
                  <td className="p-3 font-semibold text-neutral-700">
                    {p.nomorMeja}{' '}
                    <span className="text-xs text-neutral-400 font-normal">({p.tipePesanan})</span>
                  </td>
                  <td className="p-3 text-neutral-600">{p.namaPelanggan || '-'}</td>
                  <td className="p-3 text-xs text-neutral-500">{p.waktuDibuat}</td>
                  <td className="p-3 text-right font-extrabold text-neutral-800">
                    {rupiah(p.totalHarga)}
                  </td>
                  <td className="p-3 text-center">{getStatusBadge(p.status)}</td>
                  <td className="p-3 text-center flex items-center justify-center gap-1.5">
                    {onPilihPesanan && (
                      <Tombol ragam="utama" onClick={() => onPilihPesanan(p.id)}>
                        Buka
                      </Tombol>
                    )}
                    {onCetakUlang && (
                      <Tombol ragam="biasa" onClick={() => onCetakUlang(p.id)}>
                        🖨️ Struk
                      </Tombol>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
