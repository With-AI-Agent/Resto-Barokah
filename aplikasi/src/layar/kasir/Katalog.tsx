import { useState, useMemo } from 'react'
import { useBahasa } from '../../bahasa'
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
  daftarKategori,
  daftarMenu = CONTOH_MENU,
  sedangMemuat = false,
  onTambahKeKeranjang,
}: KatalogProps) {
  const { t } = useBahasa()
  const kategoriTersedia = useMemo(() => {
    if (daftarKategori && daftarKategori.length > 0) return daftarKategori
    return [
      { id: 'kat-0', nama: t('kasir.semua_menu') },
      { id: 'kat-1', nama: t('kasir.makanan_utama') },
      { id: 'kat-2', nama: t('kasir.minuman_segar') },
      { id: 'kat-3', nama: t('kasir.cemilan_pendamping') },
    ]
  }, [daftarKategori, t])

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

  const toggleTambahan = (tItem: TambahanItem) => {
    setTambahanTerpilih((prev) =>
      prev.some((item) => item.id === tItem.id)
        ? prev.filter((item) => item.id !== tItem.id)
        : [...prev, tItem],
    )
  }

  return (
    <div className="katalog-wadah">
      {/* Bilah Pencarian & Kategori */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
        <KolomIsian
          label=""
          contoh={`🔍 ${t('kasir.cari_menu')}`}
          nilai={kataKunci}
          onUbah={setKataKunci}
        />

        {/* Tab Kategori Horisontal */}
        <div className="kategori-pills">
          {kategoriTersedia.map((kat) => {
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
        <div style={{ padding: 'var(--s-8) 0', textAlign: 'center', color: 'var(--text-muted)' }}>
          <div>{t('umum.memuat')}</div>
        </div>
      ) : daftarMenuTersaring.length === 0 ? (
        <div
          style={{
            padding: 'var(--s-8) 0',
            textAlign: 'center',
            color: 'var(--text-muted)',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 'var(--s-2)',
          }}
        >
          <div style={{ fontSize: '32px' }}>🍽️</div>
          <div style={{ fontWeight: 700 }}>{t('keadaan.kosong_judul')}</div>
          <div style={{ fontSize: 'var(--t-2)' }}>{t('keadaan.kosong_keterangan')}</div>
        </div>
      ) : (
        <div
          className="kisi-menu-grid"
          style={{ overflowY: 'auto', maxHeight: '65vh', paddingRight: '4px' }}
        >
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
                className={`kartu-menu ${terkunciHabis ? 'kartu-menu--habis' : ''}`}
              >
                {/* Lencana Unggulan atau Habis */}
                <div className="kartu-menu__atas">
                  <span
                    style={{
                      fontSize: 'var(--t-1)',
                      textTransform: 'uppercase',
                      letterSpacing: '0.08em',
                      color: 'var(--text-muted)',
                      fontWeight: 700,
                    }}
                  >
                    {item.jenis}
                  </span>
                  {terkunciHabis ? (
                    <Lencana nada="danger">{t('kasir.habis')}</Lencana>
                  ) : item.unggulan ? (
                    <Lencana nada="accent">⭐ {t('kasir.favorit')}</Lencana>
                  ) : null}
                </div>

                {/* Info Menu */}
                <div>
                  <div className="kartu-menu__nama">{item.nama}</div>
                  {item.deskripsi && <div className="kartu-menu__deskripsi">{item.deskripsi}</div>}
                </div>

                {/* Harga & Tombol Tambah */}
                <div className="kartu-menu__bawah">
                  <div className="kartu-menu__harga">{rupiah(item.harga)}</div>
                  {!terkunciHabis && (
                    <span className="kartu-menu__tombol-tambah" aria-label={`Tambah ${item.nama}`}>
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
          judul={`${t('kasir.opsi_item')}: ${itemDipilih.nama}`}
        >
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-4)',
              padding: 'var(--s-3)',
              maxHeight: '75vh',
              overflowY: 'auto',
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                borderBottom: '1px solid var(--border)',
                paddingBottom: 'var(--s-2)',
              }}
            >
              <span style={{ fontSize: 'var(--t-3)', fontWeight: 600, color: 'var(--text)' }}>
                {t('kasir.harga_dasar')}:
              </span>
              <span style={{ fontWeight: 800, color: 'var(--accent)', fontSize: 'var(--t-4)' }}>
                {rupiah(itemDipilih.harga)}
              </span>
            </div>

            {/* Pilihan Varian (Radio) */}
            {itemDipilih.daftarVarian && itemDipilih.daftarVarian.length > 0 && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
                <label
                  style={{
                    fontSize: 'var(--t-2)',
                    fontWeight: 700,
                    textTransform: 'uppercase',
                    letterSpacing: '0.06em',
                    color: 'var(--text-muted)',
                  }}
                >
                  {t('kasir.varian_ukuran')} *
                </label>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                    gap: 'var(--s-2)',
                  }}
                >
                  {itemDipilih.daftarVarian.map((varian) => {
                    const dipilih = varianTerpilih?.nama === varian.nama
                    return (
                      <Tombol
                        key={varian.nama}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => setVarianTerpilih(varian)}
                      >
                        <span
                          style={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            width: '100%',
                            gap: 'var(--s-2)',
                          }}
                        >
                          <span>{varian.nama}</span>
                          {varian.tambahanHarga > 0 && (
                            <span style={{ fontSize: 'var(--t-2)', opacity: 0.9 }}>
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
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
                <label
                  style={{
                    fontSize: 'var(--t-2)',
                    fontWeight: 700,
                    textTransform: 'uppercase',
                    letterSpacing: '0.06em',
                    color: 'var(--text-muted)',
                  }}
                >
                  {t('kasir.tambahan_topping')}
                </label>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
                    gap: 'var(--s-2)',
                  }}
                >
                  {itemDipilih.daftarTambahan.map((tambahan) => {
                    const dipilih = tambahanTerpilih.some((tItem) => tItem.id === tambahan.id)
                    return (
                      <Tombol
                        key={tambahan.id}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => toggleTambahan(tambahan)}
                      >
                        <span
                          style={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            width: '100%',
                            gap: 'var(--s-2)',
                          }}
                        >
                          <span>
                            {dipilih ? '✓ ' : '+ '}
                            {tambahan.nama}
                          </span>
                          <span style={{ fontSize: 'var(--t-2)', opacity: 0.9 }}>
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
              label={t('kasir.catatan_dapur')}
              contoh="Mis. Kurang pedas, jangan pakai daun bawang, es dipisah"
              nilai={catatanKhusus}
              onUbah={setCatatanKhusus}
            />

            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: 'var(--s-2)',
                paddingTop: 'var(--s-3)',
                borderTop: '1px solid var(--border)',
              }}
            >
              <Tombol ragam="biasa" onClick={() => setItemDipilih(null)}>
                {t('umum.batal')}
              </Tombol>
              <Tombol ragam="utama" onClick={tanganiSimpanOpsi}>
                {t('kasir.tambah_ke_pesanan')}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
