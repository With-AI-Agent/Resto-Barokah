import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import { type MenuItemData } from '../kasir/Katalog'
import { type ItemKeranjang } from '../kasir/Keranjang'

const MENU_PELAYAN_BAWAAN: MenuItemData[] = [
  {
    id: 'm-01',
    nama: 'Nasi Goreng Spesial Barokah',
    kategoriId: 'kat-01',
    harga: 28000,
    jenis: 'makanan',
    aktif: true,
    habis: false,
  },
  {
    id: 'm-02',
    nama: 'Ayam Bakar Madu Pedas',
    kategoriId: 'kat-01',
    harga: 32000,
    jenis: 'makanan',
    aktif: true,
    habis: false,
  },
  {
    id: 'm-03',
    nama: 'Es Teh Manis Melati',
    kategoriId: 'kat-02',
    harga: 6000,
    jenis: 'minuman',
    aktif: true,
    habis: false,
  },
  {
    id: 'm-04',
    nama: 'Jus Alpukat Kocok',
    kategoriId: 'kat-02',
    harga: 16000,
    jenis: 'minuman',
    aktif: true,
    habis: true,
  },
]

export interface LayarPelayanProps {
  nomorMejaAwal?: string
  namaPelayan?: string
  onKirimPesanan?: (data: {
    meja: string
    items: ItemKeranjang[]
    catatanUmum: string
  }) => Promise<boolean>
}

export function LayarPelayan({
  nomorMejaAwal = 'Meja 03',
  namaPelayan = 'Pelayan Rian',
  onKirimPesanan,
}: LayarPelayanProps) {
  const [nomorMeja, setNomorMeja] = useState(nomorMejaAwal)
  const [kataKunci, setKataKunci] = useState('')
  const [keranjang, setKeranjang] = useState<ItemKeranjang[]>([])
  const [catatanUmum, setCatatanUmum] = useState('')
  const [sedangKirim, setSedangKirim] = useState(false)
  const [pesanStatus, setPesanStatus] = useState<string | null>(null)

  const menuTersaring = MENU_PELAYAN_BAWAAN.filter((item) =>
    item.nama.toLowerCase().includes(kataKunci.toLowerCase()),
  )

  const tambahItem = (item: MenuItemData) => {
    if (item.habis) return
    setKeranjang((sebelum) => {
      const idx = sebelum.findIndex((i) => i.menuItem.id === item.id)
      if (idx >= 0) {
        const salinan = [...sebelum]
        const itemLama = salinan[idx]
        const qtyBaru = itemLama.qty + 1
        salinan[idx] = {
          ...itemLama,
          qty: qtyBaru,
          subtotal: itemLama.menuItem.harga * qtyBaru,
        }
        return salinan
      }
      return [
        ...sebelum,
        {
          id: `k-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
          menuItem: item,
          qty: 1,
          subtotal: item.harga,
        },
      ]
    })
  }

  const ubahKuantitas = (id: string, delta: number) => {
    setKeranjang((sebelum) =>
      sebelum
        .map((item) => {
          if (item.id === id) {
            const baru = item.qty + delta
            return baru > 0 ? { ...item, qty: baru, subtotal: item.menuItem.harga * baru } : null
          }
          return item
        })
        .filter((i): i is ItemKeranjang => i !== null),
    )
  }

  const totalHarga = keranjang.reduce((acc, item) => acc + item.subtotal, 0)
  const totalItem = keranjang.reduce((acc, item) => acc + item.qty, 0)

  const kirimKeDapur = async () => {
    if (keranjang.length === 0) return
    setSedangKirim(true)
    setPesanStatus(null)
    try {
      if (onKirimPesanan) {
        await onKirimPesanan({ meja: nomorMeja, items: keranjang, catatanUmum })
      }
      setPesanStatus('✅ Pesanan berhasil dikirim ke dapur!')
      setKeranjang([])
      setCatatanUmum('')
    } catch {
      setPesanStatus('❌ Gagal mengirim pesanan. Silakan coba lagi.')
    } finally {
      setSedangKirim(false)
    }
  }

  return (
    <div className="layar-pelayan-hp max-w-md mx-auto p-3 bg-neutral-50 min-h-screen flex flex-col justify-between">
      {/* Header Pelayan */}
      <div className="bg-white p-3 rounded-2xl border border-neutral-200 mb-3 flex items-center justify-between shadow-sm">
        <div>
          <div className="text-xs font-semibold text-emerald-700">Pelayan Mobile POS</div>
          <div className="text-sm font-bold text-neutral-800">{namaPelayan}</div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-neutral-500">Meja:</span>
          <input
            type="text"
            className="w-20 px-2 py-1 text-sm font-bold border border-neutral-300 rounded-lg text-center bg-emerald-50 text-emerald-800"
            value={nomorMeja}
            onChange={(e) => setNomorMeja(e.target.value)}
          />
        </div>
      </div>

      {pesanStatus && (
        <div className="p-2.5 mb-3 rounded-xl bg-emerald-100 text-emerald-800 text-xs font-semibold text-center">
          {pesanStatus}
        </div>
      )}

      {/* Pencarian & Daftar Menu */}
      <div className="flex-1 overflow-y-auto space-y-2">
        <KolomIsian
          label="Cari Menu"
          nilai={kataKunci}
          onUbah={setKataKunci}
          contoh="🔍 Cari menu meja..."
        />

        <div className="space-y-2 pt-1">
          {menuTersaring.map((item) => (
            <div
              key={item.id}
              role="button"
              tabIndex={item.habis ? -1 : 0}
              className={`p-3 rounded-xl border flex items-center justify-between bg-white ${
                !item.habis
                  ? 'border-neutral-200 active:scale-[0.99] cursor-pointer'
                  : 'border-neutral-200 opacity-60'
              }`}
              onClick={() => tambahItem(item)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault()
                  tambahItem(item)
                }
              }}
            >
              <div className="flex-1 pr-2">
                <div className="font-bold text-sm text-neutral-800">{item.nama}</div>
                <div className="text-xs font-semibold text-emerald-700">{rupiah(item.harga)}</div>
                {item.habis && (
                  <span className="inline-block mt-1 text-[10px] bg-red-100 text-red-700 px-1.5 py-0.5 rounded font-bold">
                    Stok Habis
                  </span>
                )}
              </div>
              {!item.habis && (
                <Tombol
                  ragam="utama"
                  onClick={() => {
                    tambahItem(item)
                  }}
                >
                  + Tambah
                </Tombol>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Bagian Ringkasan & Keranjang Bawah */}
      {keranjang.length > 0 && (
        <div className="bg-white p-3 rounded-2xl border border-neutral-200 mt-3 space-y-3 shadow-sm">
          <div className="font-bold text-xs uppercase tracking-wider text-neutral-500">
            Pesanan ({totalItem} item)
          </div>

          <div className="max-h-36 overflow-y-auto space-y-1.5 divide-y divide-neutral-100 text-xs">
            {keranjang.map((item) => (
              <div key={item.id} className="pt-1.5 flex items-center justify-between">
                <div className="flex-1 pr-2">
                  <span className="font-semibold text-neutral-800">{item.menuItem.nama}</span>
                  <div className="text-[11px] text-neutral-400">{rupiah(item.subtotal)}</div>
                </div>
                <div className="flex items-center gap-1.5">
                  <Tombol ragam="biasa" onClick={() => ubahKuantitas(item.id, -1)}>
                    -
                  </Tombol>
                  <span className="font-bold text-sm min-w-4 text-center">{item.qty}</span>
                  <Tombol ragam="biasa" onClick={() => ubahKuantitas(item.id, 1)}>
                    +
                  </Tombol>
                </div>
              </div>
            ))}
          </div>

          <KolomIsian
            label="Catatan Khusus"
            nilai={catatanUmum}
            onUbah={setCatatanUmum}
            contoh="Catatan pesanan meja (opsional)..."
          />

          <div className="flex items-center justify-between pt-1 border-t border-neutral-100">
            <div>
              <div className="text-[10px] text-neutral-400">Estimasi Total</div>
              <div className="text-base font-extrabold text-neutral-800">{rupiah(totalHarga)}</div>
            </div>
            <Tombol ragam="utama" nonaktif={sedangKirim} onClick={kirimKeDapur}>
              {sedangKirim ? 'Mengirim...' : '🚀 Kirim ke Dapur'}
            </Tombol>
          </div>
        </div>
      )}
    </div>
  )
}
