import { useState, useMemo } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'

export interface VarianItem {
  nama: string
  tambahanHarga: number
}

export interface TambahanItem {
  id: string
  nama: string
  harga: number
}

export interface MenuItemData {
  id: string
  kategoriId: string
  nama: string
  deskripsi?: string
  harga: number
  fotoPath?: string
  unggulan?: boolean
  jenis: 'makanan' | 'minuman' | 'lainnya'
  aktif: boolean
  habis?: boolean
  daftarVarian?: VarianItem[]
  daftarTambahan?: TambahanItem[]
}

export interface KategoriData {
  id: string
  nama: string
  urutan?: number
}

export interface KatalogProps {
  daftarKategori?: KategoriData[]
  daftarMenu?: MenuItemData[]
  sedangMemuat?: boolean
  onTambahKeKeranjang: (
    item: MenuItemData,
    varian?: VarianItem,
    tambahan?: TambahanItem[],
    catatan?: string,
  ) => void
}

const CONTOH_KATEGORI: KategoriData[] = [
  { id: 'kat-0', nama: 'Semua Menu' },
  { id: 'kat-1', nama: 'Makanan Utama' },
  { id: 'kat-2', nama: 'Minuman Segar' },
  { id: 'kat-3', nama: 'Cemilan & Pendamping' },
]

const CONTOH_MENU: MenuItemData[] = [
  {
    id: 'menu-01',
    kategoriId: 'kat-1',
    nama: 'Nasi Goreng Spesial Barokah',
    deskripsi: 'Nasi goreng racikan rempah khas dengan suwiran ayam dan telur mata sapi.',
    harga: 28000,
    unggulan: true,
    jenis: 'makanan',
    aktif: true,
    habis: false,
    daftarVarian: [
      { nama: 'Porsi Sedang', tambahanHarga: 0 },
      { nama: 'Porsi Jumbo', tambahanHarga: 7000 },
    ],
    daftarTambahan: [
      { id: 'tbh-1', nama: 'Tambah Telur Dadar', harga: 5000 },
      { id: 'tbh-2', nama: 'Ekstra Kerupuk Kaleng', harga: 2000 },
    ],
  },
  {
    id: 'menu-02',
    kategoriId: 'kat-1',
    nama: 'Ayam Bakar Madu Pedas',
    deskripsi: 'Ayam bakar empuk bumbu madu gurih manis dengan sambal korek.',
    harga: 32000,
    unggulan: true,
    jenis: 'makanan',
    aktif: true,
    habis: false,
    daftarVarian: [
      { nama: 'Paha', tambahanHarga: 0 },
      { nama: 'Dada', tambahanHarga: 2000 },
    ],
  },
  {
    id: 'menu-03',
    kategoriId: 'kat-2',
    nama: 'Es Teh Manis Melati',
    deskripsi: 'Teh melati seduh segar dingin.',
    harga: 6000,
    jenis: 'minuman',
    aktif: true,
    habis: false,
    daftarVarian: [
      { nama: 'Manis Sedang', tambahanHarga: 0 },
      { nama: 'Kurang Gula', tambahanHarga: 0 },
      { nama: 'Tawar Dingin', tambahanHarga: 0 },
    ],
  },
  {
    id: 'menu-04',
    kategoriId: 'kat-2',
    nama: 'Kopi Susu Gula Aren Barokah',
    deskripsi: 'Espresso robusta dengan susu murni dan sirup aren organik.',
    harga: 18000,
    unggulan: true,
    jenis: 'minuman',
    aktif: true,
    habis: true, // Menu habis contoh T3-07
  },
  {
    id: 'menu-05',
    kategoriId: 'kat-3',
    nama: 'Tahu Tempe Goreng Lengkuas',
    deskripsi: 'Tahu dan tempe goreng renyah dengan taburan bumbu lengkuas sangrai.',
    harga: 12000,
    jenis: 'makanan',
    aktif: true,
    habis: false,
  },
]

export function Katalog({
  daftarKategori = CONTOH_KATEGORI,
  daftarMenu = CONTOH_MENU,
  sedangMemuat = false,
  onTambahKeKeranjang,
}: KatalogProps) {
  const [kategoriTerpilih, setKategoriTerpilih] = useState<string>('kat-0')
  const [kataKunci, setKataKunci] = useState<string>('')

  // State Dialog Opsi (Varian / Tambahan)
  const [itemDipilih, setItemDipilih] = useState<MenuItemData | null>(null)
  const [varianTerpilih, setVarianTerpilih] = useState<VarianItem | undefined>(undefined)
  const [tambahanTerpilih, setTambahanTerpilih] = useState<TambahanItem[]>([])
  const [catatanKhusus, setCatatanKhusus] = useState<string>('')

  const daftarMenuTersaring = useMemo(() => {
    return daftarMenu.filter((item) => {
      if (!item.aktif) return false

      const cocokKategori = kategoriTerpilih === 'kat-0' || item.kategoriId === kategoriTerpilih

      const q = kataKunci.toLowerCase().trim()
      const cocokKataKunci =
        !q ||
        item.nama.toLowerCase().includes(q) ||
        (item.deskripsi && item.deskripsi.toLowerCase().includes(q))

      return cocokKategori && cocokKataKunci
    })
  }, [daftarMenu, kategoriTerpilih, kataKunci])

  const tanganiKlikItem = (item: MenuItemData) => {
    if (item.habis) return // Terkunci jika habis (T3-07)

    const punyaVarian = item.daftarVarian && item.daftarVarian.length > 0
    const punyaTambahan = item.daftarTambahan && item.daftarTambahan.length > 0

    if (punyaVarian || punyaTambahan) {
      setItemDipilih(item)
      setVarianTerpilih(item.daftarVarian ? item.daftarVarian[0] : undefined)
      setTambahanTerpilih([])
      setCatatanKhusus('')
    } else {
      onTambahKeKeranjang(item)
    }
  }

  const tanganiSimpanOpsi = () => {
    if (!itemDipilih) return
    onTambahKeKeranjang(
      itemDipilih,
      varianTerpilih,
      tambahanTerpilih.length > 0 ? tambahanTerpilih : undefined,
      catatanKhusus.trim() || undefined,
    )
    setItemDipilih(null)
  }

  const toggleTambahan = (t: TambahanItem) => {
    setTambahanTerpilih((prev) =>
      prev.some((item) => item.id === t.id)
        ? prev.filter((item) => item.id !== t.id)
        : [...prev, t],
    )
  }

  return (
    <div className="katalog-kasir flex flex-col h-full space-y-3">
      {/* Bilah Pencarian & Kategori */}
      <div className="space-y-2">
        <KolomIsian
          label=""
          contoh="🔍 Cari nama makanan atau minuman..."
          nilai={kataKunci}
          onUbah={setKataKunci}
        />

        {/* Tab Kategori Horisontal */}
        <div className="flex gap-2 overflow-x-auto pb-1 no-scrollbar">
          {daftarKategori.map((kat) => {
            const aktif = kategoriTerpilih === kat.id
            return (
              <Tombol
                key={kat.id}
                ragam={aktif ? 'utama' : 'biasa'}
                onClick={() => setKategoriTerpilih(kat.id)}
              >
                <span>{kat.nama}</span>
              </Tombol>
            )
          })}
        </div>
      </div>

      {/* Grid Katalog Menu */}
      {sedangMemuat ? (
        <div className="flex-1 flex items-center justify-center py-12 text-neutral-500">
          <div className="text-sm animate-pulse">Memuat katalog menu resto...</div>
        </div>
      ) : daftarMenuTersaring.length === 0 ? (
        <div className="flex-1 flex flex-col items-center justify-center py-12 text-neutral-400">
          <div className="text-3xl mb-2">🍽️</div>
          <div className="text-sm font-medium">Menu tidak ditemukan</div>
          <div className="text-xs">Coba kata kunci lain atau pilih kategori Semua Menu.</div>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-3 overflow-y-auto max-h-[65vh] pr-1">
          {daftarMenuTersaring.map((item) => {
            const terkunciHabis = item.habis
            return (
              <div
                key={item.id}
                role="button"
                tabIndex={terkunciHabis ? -1 : 0}
                onClick={() => tanganiKlikItem(item)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    tanganiKlikItem(item)
                  }
                }}
                className={`kartu-menu relative p-3.5 rounded-xl border flex flex-col justify-between transition-all select-none text-left ${
                  terkunciHabis
                    ? 'bg-neutral-100 border-neutral-200 text-neutral-400 opacity-70 cursor-not-allowed'
                    : 'bg-white hover:bg-neutral-50 active:scale-[0.98] border-neutral-200 hover:border-emerald-500 hover:shadow-sm cursor-pointer'
                }`}
              >
                {/* Lencana Unggulan atau Habis */}
                <div className="flex items-center justify-between gap-1 mb-1.5">
                  <span className="text-[11px] uppercase tracking-wider text-neutral-400 font-semibold">
                    {item.jenis}
                  </span>
                  {terkunciHabis ? (
                    <Lencana nada="danger">Habis</Lencana>
                  ) : item.unggulan ? (
                    <Lencana nada="accent">⭐ Favorit</Lencana>
                  ) : null}
                </div>

                {/* Info Menu */}
                <div className="flex-1 mb-2">
                  <div
                    className={`font-bold text-sm line-clamp-2 ${
                      terkunciHabis ? 'text-neutral-500' : 'text-neutral-800'
                    }`}
                  >
                    {item.nama}
                  </div>
                  {item.deskripsi && (
                    <div className="text-xs text-neutral-400 line-clamp-1 mt-0.5">
                      {item.deskripsi}
                    </div>
                  )}
                </div>

                {/* Harga & Tombol Tambah */}
                <div className="flex items-center justify-between mt-auto pt-2 border-t border-neutral-100">
                  <div
                    className={`font-extrabold text-sm ${
                      terkunciHabis ? 'text-neutral-400' : 'text-emerald-700'
                    }`}
                  >
                    {rupiah(item.harga)}
                  </div>
                  {!terkunciHabis && (
                    <span className="w-7 h-7 rounded-full bg-emerald-50 text-emerald-700 flex items-center justify-center font-bold text-base hover:bg-emerald-600 hover:text-white transition-colors">
                      +
                    </span>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Dialog Pilihan Varian & Tambahan */}
      {itemDipilih && (
        <Lapis
          buka={true}
          onTutup={() => setItemDipilih(null)}
          judul={`Pilih Opsi: ${itemDipilih.nama}`}
        >
          <div className="p-4 space-y-4 max-h-[75vh] overflow-y-auto">
            <div className="flex justify-between items-center pb-2 border-b border-neutral-200">
              <span className="text-sm font-semibold text-neutral-700">Harga Dasar:</span>
              <span className="font-bold text-emerald-700">{rupiah(itemDipilih.harga)}</span>
            </div>

            {/* Pilihan Varian (Radio) */}
            {itemDipilih.daftarVarian && itemDipilih.daftarVarian.length > 0 && (
              <div>
                <label className="block text-xs font-bold text-neutral-700 mb-2 uppercase tracking-wider">
                  Pilihan Varian / Ukuran *
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {itemDipilih.daftarVarian.map((varian) => {
                    const dipilih = varianTerpilih?.nama === varian.nama
                    return (
                      <Tombol
                        key={varian.nama}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => setVarianTerpilih(varian)}
                      >
                        <span className="flex justify-between items-center w-full">
                          <span>{varian.nama}</span>
                          {varian.tambahanHarga > 0 && (
                            <span className="text-xs opacity-90 font-mono">
                              +{rupiah(varian.tambahanHarga)}
                            </span>
                          )}
                        </span>
                      </Tombol>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Pilihan Tambahan / Toppings (Checkbox) */}
            {itemDipilih.daftarTambahan && itemDipilih.daftarTambahan.length > 0 && (
              <div>
                <label className="block text-xs font-bold text-neutral-700 mb-2 uppercase tracking-wider">
                  Tambahan / Topping (Opsional)
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {itemDipilih.daftarTambahan.map((tambahan) => {
                    const dipilih = tambahanTerpilih.some((t) => t.id === tambahan.id)
                    return (
                      <Tombol
                        key={tambahan.id}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => toggleTambahan(tambahan)}
                      >
                        <span className="flex justify-between items-center w-full">
                          <span>
                            {dipilih ? '✓ ' : '+ '}
                            {tambahan.nama}
                          </span>
                          <span className="text-xs opacity-90 font-mono">
                            +{rupiah(tambahan.harga)}
                          </span>
                        </span>
                      </Tombol>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Catatan Khusus Item */}
            <KolomIsian
              label="Catatan Khusus untuk Dapur"
              contoh="Mis. Kurang pedas, jangan pakai daun bawang, es dipisah"
              nilai={catatanKhusus}
              onUbah={setCatatanKhusus}
            />

            <div className="flex justify-end gap-2 pt-3 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setItemDipilih(null)}>
                Batal
              </Tombol>
              <Tombol ragam="utama" onClick={tanganiSimpanOpsi}>
                Tambahkan ke Pesanan
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
