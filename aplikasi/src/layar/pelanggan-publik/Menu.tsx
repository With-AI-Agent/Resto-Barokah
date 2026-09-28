import { useState, useMemo } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { rupiah } from '../../lib/format'

export interface VarianPublik {
  nama: string
  tambahan_harga: number
}

export interface TambahanPublik {
  id?: string
  nama: string
  harga: number
}

export interface MenuItemPublik {
  id: string
  kategori_id: string
  nama: string
  deskripsi?: string
  harga: number
  foto_path?: string
  urutan?: number
  unggulan?: boolean
  jenis?: 'makanan' | 'minuman' | 'lainnya'
  habis?: boolean
  varian?: VarianPublik[]
  tambahan?: TambahanPublik[]
}

export interface KategoriPublik {
  id: string
  nama: string
  urutan?: number
}

export interface MenuProps {
  kategori: KategoriPublik[]
  menu: MenuItemPublik[]
  kategoriTerpilih?: string
  onPilihKategori?: (kategoriId: string) => void
  kataKunci?: string
  onCari?: (kataKunci: string) => void
  sembunyikanHabisAwal?: boolean
  onPilihItem?: (item: MenuItemPublik) => void
}

/**
 * Placeholder SVG ringan untuk gambar menu yang belum diunggah atau gagal dimuat.
 * Dioptimalkan dengan ukuran file sangat kecil (< 300 byte) tanpa warna mentah.
 */
function PlaceholderFoto({ jenis }: { jenis?: string }) {
  const ikon = jenis === 'minuman' ? '🥤' : jenis === 'lainnya' ? '🍽️' : '🍲'
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        display: 'grid',
        placeItems: 'center',
        background: 'var(--surface-2)',
        color: 'var(--text-muted)',
        fontSize: '32px',
        userSelect: 'none',
      }}
      aria-hidden="true"
    >
      <span>{ikon}</span>
    </div>
  )
}

export function Menu({
  kategori = [],
  menu = [],
  kategoriTerpilih: kategoriProps,
  onPilihKategori,
  kataKunci: kataKunciProps,
  onCari,
  sembunyikanHabisAwal = false,
  onPilihItem,
}: MenuProps) {
  const [kategoriLokal, setKategoriLokal] = useState<string>('semua')
  const [kataKunciLokal, setKataKunciLokal] = useState<string>('')
  const [sembunyikanHabis, setSembunyikanHabis] = useState<boolean>(sembunyikanHabisAwal)
  const [hanyaUnggulan, setHanyaUnggulan] = useState<boolean>(false)

  // State untuk rincian modal item menu
  const [itemRincian, setItemRincian] = useState<MenuItemPublik | null>(null)
  const [varianDipilih, setVarianDipilih] = useState<VarianPublik | null>(null)
  const [tambahanDipilih, setTambahanDipilih] = useState<TambahanPublik[]>([])

  const kategoriAktif = kategoriProps !== undefined ? kategoriProps : kategoriLokal
  const kataKunciAktif = kataKunciProps !== undefined ? kataKunciProps : kataKunciLokal

  const setKategori = (id: string) => {
    if (onPilihKategori) {
      onPilihKategori(id)
    } else {
      setKategoriLokal(id)
    }
  }

  const setKataKunci = (teks: string) => {
    if (onCari) {
      onCari(teks)
    } else {
      setKataKunciLokal(teks)
    }
  }

  // Hitung jumlah item per kategori & unggulan
  const hitunganKategori = useMemo(() => {
    const peta: Record<string, number> = { semua: menu.length }
    for (const kat of kategori) {
      peta[kat.id] = menu.filter((m) => m.kategori_id === kat.id).length
    }
    return peta
  }, [kategori, menu])

  const jumlahUnggulan = useMemo(() => {
    return menu.filter((m) => m.unggulan).length
  }, [menu])

  // Daftar item unggulan untuk sorotan (featured carousel)
  const daftarSorotanUnggulan = useMemo(() => {
    return menu.filter((item) => item.unggulan && (!sembunyikanHabis || !item.habis))
  }, [menu, sembunyikanHabis])

  // Filter daftar menu secara instan di klien (in-memory)
  const menuTersaring = useMemo(() => {
    return menu.filter((item) => {
      // 1. Sembunyikan item habis jika opsi aktif
      if (sembunyikanHabis && item.habis) {
        return false
      }

      // 2. Filter hanya unggulan jika aktif
      if (hanyaUnggulan && !item.unggulan) {
        return false
      }

      // 3. Filter kategori
      if (kategoriAktif !== 'semua' && item.kategori_id !== kategoriAktif) {
        return false
      }

      // 4. Filter kata kunci pencarian (nama & deskripsi)
      if (kataKunciAktif.trim()) {
        const cari = kataKunciAktif.toLowerCase()
        const cocokNama = item.nama.toLowerCase().includes(cari)
        const cocokDeskripsi = item.deskripsi?.toLowerCase().includes(cari) ?? false
        if (!cocokNama && !cocokDeskripsi) {
          return false
        }
      }

      return true
    })
  }, [menu, sembunyikanHabis, hanyaUnggulan, kategoriAktif, kataKunciAktif])

  // Tangani buka modal rincian
  const bukaRincian = (item: MenuItemPublik) => {
    setItemRincian(item)
    setVarianDipilih(item.varian && item.varian.length > 0 ? item.varian[0] : null)
    setTambahanDipilih([])
    if (onPilihItem) {
      onPilihItem(item)
    }
  }

  const tutupRincian = () => {
    setItemRincian(null)
    setVarianDipilih(null)
    setTambahanDipilih([])
  }

  const toggleTambahan = (t: TambahanPublik) => {
    setTambahanDipilih((prev) => {
      const ada = prev.some((x) => x.nama === t.nama)
      if (ada) {
        return prev.filter((x) => x.nama !== t.nama)
      } else {
        return [...prev, t]
      }
    })
  }

  // Hitung total simulasi rincian
  const totalRincian = useMemo(() => {
    if (!itemRincian) return 0
    let total = itemRincian.harga
    if (varianDipilih) {
      total += varianDipilih.tambahan_harga
    }
    for (const t of tambahanDipilih) {
      total += t.harga
    }
    return total
  }, [itemRincian, varianDipilih, tambahanDipilih])

  return (
    <div className="menu-publik-container" data-testid="komponen-menu">
      {/* 1. KONTROL MENU: PENCARIAN, TAB KATEGORI, TOGGLE UNGGULAN & SAKELAR HABIS */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-3)',
          marginBottom: 'var(--s-4)',
        }}
      >
        {/* Bilah Pencarian Langsung dengan Tombol Hapus */}
        <div style={{ position: 'relative', width: '100%', display: 'flex', alignItems: 'center' }}>
          <input
            type="search"
            value={kataKunciAktif}
            onChange={(e) => setKataKunci(e.target.value)}
            placeholder="🔍 Cari menu favorit atau minuman segar..."
            className="input"
            aria-label="Cari menu"
            style={{
              width: '100%',
              paddingLeft: 'var(--s-4)',
              paddingRight: kataKunciAktif ? 'var(--s-8)' : 'var(--s-4)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
              background: 'var(--surface)',
              color: 'var(--text)',
              minHeight: '44px',
            }}
            data-testid="input-cari-menu"
          />
          {kataKunciAktif && (
            <div style={{ position: 'absolute', right: 'var(--s-2)', zIndex: 5 }}>
              <Tombol
                ragam="polos"
                onClick={() => setKataKunci('')}
                nama="Hapus kata kunci pencarian"
              >
                ✕
              </Tombol>
            </div>
          )}
        </div>

        {/* Banner Ringkasan Pencarian (jika aktif) */}
        {kataKunciAktif.trim() && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: 'var(--s-2) var(--s-3)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
              fontSize: 'var(--t-2)',
            }}
            data-testid="ringkasan-pencarian"
          >
            <span>
              Menampilkan <strong>{menuTersaring.length}</strong> menu untuk kata kunci "
              <strong>{kataKunciAktif}</strong>"
            </span>
            <Tombol ragam="polos" onClick={() => setKataKunci('')} nama="Reset pencarian">
              Reset
            </Tombol>
          </div>
        )}

        {/* Pil Kategori & Tombol Saringan */}
        <div
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 'var(--s-2)',
          }}
        >
          {/* Gulir Pil Kategori */}
          <div
            role="tablist"
            aria-label="Kategori menu"
            style={{
              display: 'flex',
              gap: 'var(--s-2)',
              overflowX: 'auto',
              paddingBottom: 'var(--s-1)',
              maxWidth: '100%',
            }}
          >
            <Tombol
              ragam={kategoriAktif === 'semua' && !hanyaUnggulan ? 'utama' : 'biasa'}
              onClick={() => {
                setKategori('semua')
                setHanyaUnggulan(false)
              }}
              nama="Kategori Semua"
            >
              Semua ({hitunganKategori['semua'] || 0})
            </Tombol>

            {/* Tombol Filter Cepat Unggulan */}
            {jumlahUnggulan > 0 && (
              <Tombol
                ragam={hanyaUnggulan ? 'utama' : 'biasa'}
                onClick={() => setHanyaUnggulan(!hanyaUnggulan)}
                nama="Filter hanya menu unggulan"
              >
                ⭐ Unggulan ({jumlahUnggulan})
              </Tombol>
            )}

            {kategori.map((kat) => {
              const aktif = kategoriAktif === kat.id && !hanyaUnggulan
              const jumlah = hitunganKategori[kat.id] || 0
              return (
                <Tombol
                  key={kat.id}
                  ragam={aktif ? 'utama' : 'biasa'}
                  onClick={() => {
                    setKategori(kat.id)
                    setHanyaUnggulan(false)
                  }}
                  nama={`Kategori ${kat.nama}`}
                >
                  {kat.nama} ({jumlah})
                </Tombol>
              )
            })}
          </div>

          {/* Sakelar Sembunyikan Habis */}
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Tombol
              ragam={sembunyikanHabis ? 'utama' : 'polos'}
              onClick={() => setSembunyikanHabis(!sembunyikanHabis)}
              nama="Filter menu habis"
            >
              {sembunyikanHabis ? '✓ Menyembunyikan Habis' : 'Semua Menu (Termasuk Habis)'}
            </Tombol>
          </div>
        </div>
      </div>

      {/* 2. SOROTAN ITEM UNGGULAN (FEATURED ITEMS CAROUSEL) — T8-04 */}
      {!kataKunciAktif.trim() &&
        kategoriAktif === 'semua' &&
        !hanyaUnggulan &&
        daftarSorotanUnggulan.length > 0 && (
          <section
            style={{
              marginBottom: 'var(--s-5)',
              padding: 'var(--s-3)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-lg)',
              border: '1px solid var(--border)',
            }}
            data-testid="sorotan-unggulan"
            aria-label="Sorotan Menu Unggulan"
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 'var(--s-3)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
                <span style={{ fontSize: '20px' }}>⭐</span>
                <div>
                  <h3
                    style={{
                      fontSize: 'var(--t-4)',
                      fontWeight: 800,
                      margin: 0,
                      color: 'var(--text)',
                      lineHeight: 1.2,
                    }}
                  >
                    Rekomendasi Resto
                  </h3>
                  <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                    Paling disukai dan dicari pelanggan
                  </span>
                </div>
              </div>
              <Lencana nada="accent">{daftarSorotanUnggulan.length} Menu Pilihan</Lencana>
            </div>

            <div
              style={{
                display: 'flex',
                gap: 'var(--s-3)',
                overflowX: 'auto',
                paddingBottom: 'var(--s-2)',
              }}
              data-testid="daftar-sorotan-unggulan"
            >
              {daftarSorotanUnggulan.map((item) => (
                <div
                  key={`sorotan-${item.id}`}
                  className="kartu"
                  style={{
                    minWidth: '220px',
                    maxWidth: '240px',
                    flex: '0 0 auto',
                    background: 'var(--surface)',
                    border: '1px solid var(--border)',
                    borderRadius: 'var(--radius-md)',
                    overflow: 'hidden',
                    display: 'flex',
                    flexDirection: 'column',
                    boxShadow: 'var(--sh-1)',
                  }}
                  data-testid={`kartu-sorotan-${item.id}`}
                >
                  <div style={{ height: '110px', width: '100%', position: 'relative' }}>
                    {item.foto_path ? (
                      <img
                        src={item.foto_path}
                        alt={item.nama}
                        loading="lazy"
                        decoding="async"
                        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                      />
                    ) : (
                      <PlaceholderFoto jenis={item.jenis} />
                    )}
                  </div>
                  <div
                    style={{
                      padding: 'var(--s-2)',
                      display: 'flex',
                      flexDirection: 'column',
                      flex: 1,
                    }}
                  >
                    <h4
                      style={{
                        fontSize: 'var(--t-2)',
                        fontWeight: 700,
                        margin: '0 0 var(--s-1) 0',
                        color: 'var(--text)',
                        lineHeight: 1.2,
                      }}
                      data-testid={`judul-sorotan-${item.id}`}
                    >
                      ⭐ {item.nama}
                    </h4>
                    <div
                      style={{
                        marginTop: 'auto',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        paddingTop: 'var(--s-1)',
                      }}
                    >
                      <span
                        style={{
                          fontSize: 'var(--t-2)',
                          fontWeight: 800,
                          color: 'var(--accent)',
                        }}
                      >
                        {rupiah(item.harga)}
                      </span>
                      <Tombol
                        ragam="kecil"
                        onClick={() => bukaRincian(item)}
                        nama={`Pilih rekomendasi ${item.nama}`}
                      >
                        Pilih
                      </Tombol>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

      {/* 3. DAFTAR KISI MENU */}
      {menuTersaring.length === 0 ? (
        <div
          className="kartu"
          style={{
            padding: 'var(--s-6)',
            textAlign: 'center',
            background: 'var(--surface)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-lg)',
            margin: 'var(--s-4) 0',
          }}
          data-testid="menu-kosong"
        >
          <div style={{ fontSize: '40px', marginBottom: 'var(--s-2)' }}>🍽️</div>
          <h3 style={{ fontSize: 'var(--t-4)', fontWeight: 700, margin: '0 0 var(--s-1) 0' }}>
            Tidak Ada Menu yang Sesuai
          </h3>
          <p
            className="muted"
            style={{ color: 'var(--text-muted)', fontSize: 'var(--t-2)', margin: 0 }}
          >
            {kataKunciAktif
              ? `Tidak ditemukan menu dengan kata kunci "${kataKunciAktif}". Coba cari kata kunci lain.`
              : hanyaUnggulan
                ? 'Tidak ada menu unggulan yang sesuai dengan saringan ini.'
                : sembunyikanHabis
                  ? 'Semua menu di kategori ini sedang habis stoknya di cabang ini.'
                  : 'Belum ada menu yang didaftarkan pada kategori ini.'}
          </p>
          {(kataKunciAktif || sembunyikanHabis || kategoriAktif !== 'semua' || hanyaUnggulan) && (
            <div style={{ marginTop: 'var(--s-4)' }}>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setKataKunci('')
                  setKategori('semua')
                  setSembunyikanHabis(false)
                  setHanyaUnggulan(false)
                }}
                nama="Reset filter menu"
              >
                Tampilkan Semua Menu
              </Tombol>
            </div>
          )}
        </div>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
            gap: 'var(--s-4)',
          }}
          data-testid="kisi-menu"
        >
          {menuTersaring.map((item) => {
            const apakahHabis = Boolean(item.habis)
            return (
              <article
                key={item.id}
                className="kartu flex-kolom"
                style={{
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-lg)',
                  overflow: 'hidden',
                  boxShadow: 'var(--sh-1)',
                  position: 'relative',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                  opacity: apakahHabis ? 0.72 : 1,
                  filter: apakahHabis ? 'grayscale(70%)' : 'none',
                }}
                data-testid={`kartu-menu-${item.id}`}
              >
                {/* WADAH FOTO TEROPTIMASI */}
                <div
                  style={{
                    position: 'relative',
                    width: '100%',
                    height: '160px',
                    overflow: 'hidden',
                    background: 'var(--surface-2)',
                  }}
                >
                  {item.foto_path ? (
                    <img
                      src={item.foto_path}
                      alt={item.nama}
                      loading="lazy"
                      decoding="async"
                      style={{
                        width: '100%',
                        height: '100%',
                        objectFit: 'cover',
                        display: 'block',
                      }}
                      onError={(e) => {
                        e.currentTarget.style.display = 'none'
                      }}
                    />
                  ) : (
                    <PlaceholderFoto jenis={item.jenis} />
                  )}

                  {/* Lencana Unggulan */}
                  {item.unggulan && !apakahHabis && (
                    <div
                      style={{
                        position: 'absolute',
                        top: 'var(--s-2)',
                        left: 'var(--s-2)',
                        zIndex: 2,
                      }}
                    >
                      <Lencana nada="accent">⭐ Unggulan</Lencana>
                    </div>
                  )}

                  {/* Overlay Penutup Habis Terjual (DoD T8-03) */}
                  {apakahHabis && (
                    <div
                      style={{
                        position: 'absolute',
                        inset: 0,
                        background: 'var(--surface-2)',
                        display: 'grid',
                        placeItems: 'center',
                        zIndex: 3,
                        padding: 'var(--s-2)',
                        textAlign: 'center',
                      }}
                      data-testid={`overlay-habis-${item.id}`}
                    >
                      <div
                        style={{
                          display: 'flex',
                          flexDirection: 'column',
                          alignItems: 'center',
                          gap: 'var(--s-1)',
                        }}
                      >
                        <span data-testid="indikator-habis">
                          <Lencana nada="danger">HABIS</Lencana>
                        </span>
                        <span
                          style={{
                            fontSize: 'var(--t-1)',
                            fontWeight: 600,
                            color: 'var(--text)',
                          }}
                        >
                          Stok Habis di Cabang Ini
                        </span>
                      </div>
                    </div>
                  )}
                </div>

                {/* KONTEN RINCIAN MENU */}
                <div
                  style={{
                    padding: 'var(--s-3)',
                    display: 'flex',
                    flexDirection: 'column',
                    flex: 1,
                  }}
                >
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      gap: 'var(--s-2)',
                      marginBottom: 'var(--s-1)',
                    }}
                  >
                    <h3
                      style={{
                        fontSize: 'var(--t-3)',
                        fontWeight: 700,
                        margin: 0,
                        color: 'var(--text)',
                        lineHeight: 1.3,
                      }}
                    >
                      {item.nama}
                    </h3>
                  </div>

                  {item.deskripsi && (
                    <p
                      className="muted"
                      style={{
                        fontSize: 'var(--t-2)',
                        color: 'var(--text-muted)',
                        margin: '0 0 var(--s-3) 0',
                        lineHeight: 1.4,
                        display: '-webkit-box',
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                        flex: 1,
                      }}
                    >
                      {item.deskripsi}
                    </p>
                  )}

                  {/* Informasi Varian & Tambahan */}
                  <div
                    style={{
                      display: 'flex',
                      flexWrap: 'wrap',
                      gap: 'var(--s-1)',
                      marginBottom: 'var(--s-3)',
                    }}
                  >
                    {item.varian && item.varian.length > 0 && (
                      <Lencana nada="info">{item.varian.length} Pilihan Rasa/Ukuran</Lencana>
                    )}
                    {item.tambahan && item.tambahan.length > 0 && (
                      <Lencana nada="netral">+{item.tambahan.length} Tambahan</Lencana>
                    )}
                  </div>

                  {/* HARGA & AKSI LIHAT RINCIAN */}
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      marginTop: 'auto',
                      paddingTop: 'var(--s-2)',
                      borderTop: '1px solid var(--border)',
                    }}
                  >
                    <div>
                      <span
                        style={{
                          fontSize: 'var(--t-4)',
                          fontWeight: 800,
                          color: 'var(--accent)',
                        }}
                        data-testid={`harga-${item.id}`}
                      >
                        {rupiah(item.harga)}
                      </span>
                    </div>

                    <Tombol
                      ragam={apakahHabis ? 'biasa' : 'utama'}
                      onClick={() => bukaRincian(item)}
                      nama={`Rincian ${item.nama}`}
                    >
                      {apakahHabis ? 'Rincian' : 'Lihat Detail'}
                    </Tombol>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      {/* 4. MODAL RINCIAN MENU & VARIAN/TAMBAHAN (LAPIS) */}
      <Lapis
        buka={itemRincian !== null}
        judul={itemRincian?.nama || 'Rincian Menu'}
        onTutup={tutupRincian}
        kaki={
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              width: '100%',
              gap: 'var(--s-3)',
            }}
          >
            <div>
              <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                Perkiraan Harga:
              </span>
              <div
                style={{
                  fontSize: 'var(--t-5)',
                  fontWeight: 800,
                  color: 'var(--accent)',
                }}
                data-testid="total-rincian-simulasi"
              >
                {rupiah(totalRincian)}
              </div>
            </div>
            <Tombol ragam="biasa" onClick={tutupRincian} nama="Tutup rincian menu">
              Tutup
            </Tombol>
          </div>
        }
      >
        {itemRincian && (
          <div
            style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}
            data-testid="konten-modal-rincian"
          >
            {/* Foto besar */}
            <div
              style={{
                width: '100%',
                height: '200px',
                borderRadius: 'var(--radius-md)',
                overflow: 'hidden',
                background: 'var(--surface-2)',
              }}
            >
              {itemRincian.foto_path ? (
                <img
                  src={itemRincian.foto_path}
                  alt={itemRincian.nama}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              ) : (
                <PlaceholderFoto jenis={itemRincian.jenis} />
              )}
            </div>

            {/* Status & Kategori */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
              {itemRincian.habis ? (
                <Lencana nada="danger">Stok Habis di Cabang Ini</Lencana>
              ) : (
                <Lencana nada="success">Tersedia</Lencana>
              )}
              {itemRincian.unggulan && <Lencana nada="accent">⭐ Menu Unggulan</Lencana>}
              {itemRincian.jenis && (
                <Lencana nada="netral">
                  {itemRincian.jenis === 'makanan'
                    ? 'Makanan'
                    : itemRincian.jenis === 'minuman'
                      ? 'Minuman'
                      : 'Lainnya'}
                </Lencana>
              )}
            </div>

            {/* Deskripsi */}
            {itemRincian.deskripsi && (
              <p
                style={{
                  fontSize: 'var(--t-3)',
                  color: 'var(--text)',
                  margin: 0,
                  lineHeight: 1.5,
                }}
              >
                {itemRincian.deskripsi}
              </p>
            )}

            {/* Opsi Varian */}
            {itemRincian.varian && itemRincian.varian.length > 0 && (
              <div style={{ marginTop: 'var(--s-2)' }}>
                <h4
                  style={{
                    fontSize: 'var(--t-3)',
                    fontWeight: 700,
                    marginBottom: 'var(--s-2)',
                    color: 'var(--text)',
                  }}
                >
                  Pilihan Varian / Rasa:
                </h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--s-2)' }}>
                  {itemRincian.varian.map((v) => {
                    const dipilih = varianDipilih?.nama === v.nama
                    return (
                      <Tombol
                        key={v.nama}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => setVarianDipilih(v)}
                        nama={`Pilih varian ${v.nama}`}
                      >
                        {v.nama} {v.tambahan_harga > 0 ? `(+${rupiah(v.tambahan_harga)})` : ''}
                      </Tombol>
                    )
                  })}
                </div>
              </div>
            )}

            {/* Opsi Tambahan / Topping */}
            {itemRincian.tambahan && itemRincian.tambahan.length > 0 && (
              <div style={{ marginTop: 'var(--s-2)' }}>
                <h4
                  style={{
                    fontSize: 'var(--t-3)',
                    fontWeight: 700,
                    marginBottom: 'var(--s-2)',
                    color: 'var(--text)',
                  }}
                >
                  Tambahan / Topping (Opsional):
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
                  {itemRincian.tambahan.map((t) => {
                    const dipilih = tambahanDipilih.some((x) => x.nama === t.nama)
                    return (
                      <div
                        key={t.nama}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: 'var(--s-2) var(--s-3)',
                          borderRadius: 'var(--radius-md)',
                          background: dipilih ? 'var(--surface-2)' : 'var(--surface)',
                          border: '1px solid var(--border)',
                        }}
                      >
                        <span style={{ fontSize: 'var(--t-3)', color: 'var(--text)' }}>
                          {t.nama}
                        </span>
                        <div
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 'var(--s-2)',
                          }}
                        >
                          <span
                            style={{
                              fontSize: 'var(--t-2)',
                              fontWeight: 600,
                              color: 'var(--accent)',
                            }}
                          >
                            +{rupiah(t.harga)}
                          </span>
                          <Tombol
                            ragam={dipilih ? 'utama' : 'biasa'}
                            onClick={() => toggleTambahan(t)}
                            nama={`Pilih tambahan ${t.nama}`}
                          >
                            {dipilih ? '✓ Dipilih' : '+ Tambah'}
                          </Tombol>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            )}
          </div>
        )}
      </Lapis>
    </div>
  )
}
