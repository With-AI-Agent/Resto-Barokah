import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { rupiah } from '../../lib/format'

export interface ItemTagihanTerbuka {
  id: string
  nomor: number
  tanggal: string
  tipe: 'dinein' | 'takeaway' | 'ojol'
  namaMeja?: string
  status: 'draf' | 'dikirim' | 'dimasak' | 'siap' | 'lunas' | 'batal'
  jumlahItem: number
  ringkasanItem: string
  total: number
  dibuatPada: string
}

export interface TagihanTerbukaProps {
  daftarTagihan?: ItemTagihanTerbuka[]
  onPilihTagihan: (tagihan: ItemTagihanTerbuka) => void
  onBuatPesananBaru: () => void
  onSegarkan?: () => void
}

const CONTOH_TAGIHAN: ItemTagihanTerbuka[] = [
  {
    id: 'ord-01',
    nomor: 101,
    tanggal: '2026-09-22',
    tipe: 'dinein',
    namaMeja: 'Meja 02',
    status: 'dimasak',
    jumlahItem: 3,
    ringkasanItem: '2x Nasi Goreng Spesial, 1x Es Teh',
    total: 62000,
    dibuatPada: '12:30',
  },
  {
    id: 'ord-02',
    nomor: 102,
    tanggal: '2026-09-22',
    tipe: 'dinein',
    namaMeja: 'Meja 06 (Outdoor)',
    status: 'dikirim',
    jumlahItem: 4,
    ringkasanItem: '2x Ayam Bakar Madu, 2x Kopi Susu',
    total: 100000,
    dibuatPada: '12:45',
  },
  {
    id: 'ord-03',
    nomor: 103,
    tanggal: '2026-09-22',
    tipe: 'takeaway',
    status: 'siap',
    jumlahItem: 2,
    ringkasanItem: '2x Tahu Tempe Lengkuas',
    total: 24000,
    dibuatPada: '13:05',
  },
]

export function TagihanTerbuka({
  daftarTagihan = CONTOH_TAGIHAN,
  onPilihTagihan,
  onBuatPesananBaru,
  onSegarkan,
}: TagihanTerbukaProps) {
  const [filterTipe, setFilterTipe] = useState<string>('semua')

  const daftarTersaring = daftarTagihan.filter((item) => {
    if (filterTipe === 'semua') return true
    return item.tipe === filterTipe
  })

  return (
    <div className="tagihan-terbuka space-y-4 max-w-4xl mx-auto p-4 bg-white rounded-2xl border border-neutral-200">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h3 className="font-bold text-lg text-neutral-800">Tagihan Terbuka (Open Bill)</h3>
          <p className="text-xs text-neutral-500">
            Daftar transaksi aktif yang sedang berjalan atau menunggu pembayaran.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {onSegarkan && (
            <Tombol ragam="biasa" onClick={onSegarkan}>
              🔄 Segarkan
            </Tombol>
          )}
          <Tombol ragam="utama" onClick={onBuatPesananBaru}>
            + Buat Pesanan Baru
          </Tombol>
        </div>
      </div>

      {/* Filter Tipe */}
      <div className="flex gap-2 border-b border-neutral-100 pb-2">
        {['semua', 'dinein', 'takeaway', 'ojol'].map((t) => (
          <Tombol
            key={t}
            ragam={filterTipe === t ? 'utama' : 'biasa'}
            onClick={() => setFilterTipe(t)}
          >
            {t === 'semua'
              ? 'Semua Transaksi'
              : t === 'dinein'
                ? '🍽️ Dine In'
                : t === 'takeaway'
                  ? '🥡 Takeaway'
                  : '🛵 Ojol'}
          </Tombol>
        ))}
      </div>

      {/* Daftar Tagihan Terbuka */}
      {daftarTersaring.length === 0 ? (
        <div className="text-center py-12 text-neutral-400">
          <div className="text-3xl mb-1">📋</div>
          <div className="text-sm font-medium">Tidak ada tagihan terbuka</div>
          <div className="text-xs">
            Klik tombol &quot;+ Buat Pesanan Baru&quot; untuk memulai transaksi.
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {daftarTersaring.map((tagihan) => (
            <div
              key={tagihan.id}
              role="button"
              tabIndex={0}
              onClick={() => onPilihTagihan(tagihan)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault()
                  onPilihTagihan(tagihan)
                }
              }}
              className="p-3.5 rounded-xl border border-neutral-200 hover:border-emerald-500 hover:bg-neutral-50/70 transition-all cursor-pointer flex flex-col justify-between"
            >
              <div className="flex items-start justify-between gap-2 mb-2">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-extrabold text-base text-neutral-900">
                      #{tagihan.nomor}
                    </span>
                    <span className="font-semibold text-sm text-neutral-700">
                      {tagihan.tipe === 'dinein'
                        ? tagihan.namaMeja
                        : tagihan.tipe === 'takeaway'
                          ? 'Bawa Pulang'
                          : 'Ojol'}
                    </span>
                  </div>
                  <div className="text-xs text-neutral-400 mt-0.5">
                    Waktu: {tagihan.dibuatPada} • {tagihan.jumlahItem} Item
                  </div>
                </div>

                <Lencana
                  nada={
                    tagihan.status === 'dimasak'
                      ? 'warn'
                      : tagihan.status === 'siap'
                        ? 'success'
                        : 'info'
                  }
                >
                  {tagihan.status === 'dimasak'
                    ? '🍳 Dimasak'
                    : tagihan.status === 'siap'
                      ? '✅ Siap Saji'
                      : '📤 Dikirim'}
                </Lencana>
              </div>

              <div className="text-xs text-neutral-600 line-clamp-1 mb-2 italic">
                {tagihan.ringkasanItem}
              </div>

              <div className="flex items-center justify-between pt-2 border-t border-neutral-100">
                <span className="text-xs text-neutral-500 font-medium">Total:</span>
                <span className="font-extrabold text-sm text-emerald-700">
                  {rupiah(tagihan.total)}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
