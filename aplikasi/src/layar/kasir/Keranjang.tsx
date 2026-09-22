import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import type { MenuItemData, VarianItem, TambahanItem } from './Katalog'

export interface ItemKeranjang {
  id: string
  menuItem: MenuItemData
  varian?: VarianItem
  tambahan?: TambahanItem[]
  catatan?: string
  qty: number
  subtotal: number
}

export interface RingkasanUang {
  subtotal: number
  totalDiskon: number
  pajak: number
  service: number
  total: number
}

export interface KeranjangProps {
  daftarItem?: ItemKeranjang[]
  ringkasan?: RingkasanUang
  namaMeja?: string
  tipePesanan?: 'dinein' | 'takeaway' | 'ojol'
  sedangMemproses?: boolean
  onTambahQty: (id: string) => void
  onKurangQty: (id: string) => void
  onHapusItem: (id: string) => void
  onUbahCatatan: (id: string, catatan: string) => void
  onKirimKeDapur?: () => void
  onProsesBayar?: () => void
  onBukaPemilihMeja?: () => void
  onBukaVoucher?: () => void
}

const RINGKASAN_DEFAULT: RingkasanUang = {
  subtotal: 0,
  totalDiskon: 0,
  pajak: 0,
  service: 0,
  total: 0,
}

export function Keranjang({
  daftarItem = [],
  ringkasan = RINGKASAN_DEFAULT,
  namaMeja = 'Meja 01',
  tipePesanan = 'dinein',
  sedangMemproses = false,
  onTambahQty,
  onKurangQty,
  onHapusItem,
  onUbahCatatan,
  onKirimKeDapur,
  onProsesBayar,
  onBukaPemilihMeja,
  onBukaVoucher,
}: KeranjangProps) {
  const [itemCatatanEdit, setItemCatatanEdit] = useState<ItemKeranjang | null>(null)
  const [inputCatatan, setInputCatatan] = useState<string>('')

  const bukaEditCatatan = (item: ItemKeranjang) => {
    setItemCatatanEdit(item)
    setInputCatatan(item.catatan || '')
  }

  const simpanCatatan = () => {
    if (itemCatatanEdit) {
      onUbahCatatan(itemCatatanEdit.id, inputCatatan.trim())
      setItemCatatanEdit(null)
    }
  }

  const kosong = daftarItem.length === 0

  return (
    <div className="keranjang-kasir flex flex-col h-full bg-white rounded-2xl border border-neutral-200 shadow-sm overflow-hidden">
      {/* Header Info Meja & Tipe Pesanan */}
      <div className="p-3.5 bg-neutral-50/80 border-b border-neutral-200 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="font-bold text-base text-neutral-800">
            {tipePesanan === 'dinein'
              ? `🍽️ ${namaMeja}`
              : tipePesanan === 'takeaway'
                ? '🥡 Bawa Pulang'
                : '🛵 Ojek Online'}
          </div>
          <Lencana nada="info">
            {tipePesanan === 'dinein'
              ? 'Dine In'
              : tipePesanan === 'takeaway'
                ? 'Takeaway'
                : 'Ojol'}
          </Lencana>
        </div>

        {onBukaPemilihMeja && (
          <Tombol ragam="kecil" onClick={onBukaPemilihMeja}>
            Ubah Meja / Tipe
          </Tombol>
        )}
      </div>

      {/* Daftar Item Pesanan */}
      <div className="flex-1 overflow-y-auto p-3 space-y-2.5 max-h-[48vh] min-h-[180px]">
        {kosong ? (
          <div className="flex flex-col items-center justify-center h-full py-12 text-neutral-400">
            <div className="text-3xl mb-1">🛒</div>
            <div className="text-sm font-medium">Keranjang Masih Kosong</div>
            <div className="text-xs text-neutral-400">
              Pilih menu dari katalog di sebelah kiri untuk memesan.
            </div>
          </div>
        ) : (
          daftarItem.map((item) => (
            <div
              key={item.id}
              className="item-keranjang p-2.5 rounded-xl border border-neutral-100 bg-neutral-50/50 hover:bg-neutral-50 transition-colors flex flex-col gap-1.5"
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1">
                  <div className="font-bold text-sm text-neutral-800">{item.menuItem.nama}</div>
                  {item.varian && (
                    <div className="text-xs text-neutral-500 font-medium">
                      Varian: {item.varian.nama}
                    </div>
                  )}
                  {item.tambahan && item.tambahan.length > 0 && (
                    <div className="text-xs text-neutral-500">
                      + {item.tambahan.map((t) => t.nama).join(', ')}
                    </div>
                  )}
                  {item.catatan && (
                    <div className="text-xs text-amber-800 bg-amber-50 px-2 py-0.5 rounded border border-amber-200 mt-1 inline-block">
                      📝 {item.catatan}
                    </div>
                  )}
                </div>

                {/* Subtotal Item */}
                <div className="text-right">
                  <div className="font-extrabold text-sm text-neutral-900">
                    {rupiah(item.subtotal)}
                  </div>
                </div>
              </div>

              {/* Kontrol Kuantitas & Catatan */}
              <div className="flex items-center justify-between pt-1 border-t border-neutral-200/60 text-xs">
                <Tombol ragam="polos" onClick={() => bukaEditCatatan(item)}>
                  <span className="text-neutral-500 hover:text-neutral-800 underline">
                    {item.catatan ? 'Ubah Catatan' : '+ Tambah Catatan'}
                  </span>
                </Tombol>

                <div className="flex items-center gap-1.5">
                  <Tombol ragam="kecil" onClick={() => onKurangQty(item.id)} nama="Kurangi jumlah">
                    -
                  </Tombol>
                  <span className="font-bold text-sm min-w-[20px] text-center">{item.qty}</span>
                  <Tombol ragam="kecil" onClick={() => onTambahQty(item.id)} nama="Tambah jumlah">
                    +
                  </Tombol>
                  <Tombol ragam="bahaya" onClick={() => onHapusItem(item.id)} nama="Hapus item">
                    ✕
                  </Tombol>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Rangkuman Keuangan & Pajak (Dihitung Server/Peladen) */}
      <div className="p-3.5 bg-neutral-50 border-t border-neutral-200 space-y-2">
        <div className="space-y-1 text-xs text-neutral-600">
          <div className="flex justify-between">
            <span>Subtotal Menu</span>
            <span className="font-semibold text-neutral-800">{rupiah(ringkasan.subtotal)}</span>
          </div>

          {ringkasan.totalDiskon > 0 && (
            <div className="flex justify-between text-emerald-700">
              <span>Diskon / Voucher Promo</span>
              <span className="font-semibold">-{rupiah(ringkasan.totalDiskon)}</span>
            </div>
          )}

          {ringkasan.service > 0 && (
            <div className="flex justify-between">
              <span>Biaya Layanan (Service)</span>
              <span className="font-semibold">{rupiah(ringkasan.service)}</span>
            </div>
          )}

          {ringkasan.pajak > 0 && (
            <div className="flex justify-between">
              <span>PB1 / Pajak Resto</span>
              <span className="font-semibold">{rupiah(ringkasan.pajak)}</span>
            </div>
          )}

          <div className="flex justify-between pt-2 border-t border-neutral-200 text-sm font-extrabold text-neutral-900">
            <span>Total Tagihan</span>
            <span className="text-lg text-emerald-700">{rupiah(ringkasan.total)}</span>
          </div>
        </div>

        {/* Tombol Voucher Diskon */}
        {onBukaVoucher && !kosong && (
          <Tombol ragam="biasa" lebar onClick={onBukaVoucher}>
            🎟️ Tambah Voucher / Diskon
          </Tombol>
        )}

        {/* Tombol Aksi Utama */}
        <div className="grid grid-cols-2 gap-2 pt-1">
          {onKirimKeDapur && (
            <Tombol ragam="biasa" onClick={onKirimKeDapur} nonaktif={kosong || sedangMemproses}>
              🍳 Kirim ke Dapur
            </Tombol>
          )}

          {onProsesBayar && (
            <Tombol ragam="utama" onClick={onProsesBayar} nonaktif={kosong || sedangMemproses}>
              💳 Bayar Pesanan
            </Tombol>
          )}
        </div>
      </div>

      {/* Modal Edit Catatan Khusus */}
      {itemCatatanEdit && (
        <Lapis
          buka={true}
          onTutup={() => setItemCatatanEdit(null)}
          judul={`Catatan: ${itemCatatanEdit.menuItem.nama}`}
        >
          <div className="p-4 space-y-4">
            <KolomIsian
              label="Catatan Khusus untuk Dapur / Bar"
              contoh="Contoh: Es dipisah, sambal banyakin, jangan pakai MSG"
              nilai={inputCatatan}
              onUbah={setInputCatatan}
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setItemCatatanEdit(null)}>
                Batal
              </Tombol>
              <Tombol ragam="utama" onClick={simpanCatatan}>
                Simpan Catatan
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
