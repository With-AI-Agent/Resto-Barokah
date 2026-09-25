import { useState, useMemo } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KomponenQr } from '../../komponen/KomponenQr'
import { Lapis } from '../../komponen/Lapis'
import { rupiah } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export interface InfoPenyewaPublik {
  id: string
  nama: string
  slug: string
}

export interface InfoCabangPublik {
  id: string
  nama: string
  alamat?: string
  telepon?: string
}

export interface PengaturanRestoPublik {
  nama_resto: string
  tagline?: string
  logo_url?: string
  banner_url?: string
  tema?: string
  jam_buka?: Record<string, string> | { buka?: string; tutup?: string; teks?: string }
  kontak?: { telepon?: string; whatsapp?: string; instagram?: string }
  lokasi?: { alamat?: string; maps_url?: string; kota?: string }
}

export interface KategoriPublik {
  id: string
  nama: string
  urutan?: number
}

export interface MenuItemPublik {
  id: string
  kategori_id: string
  nama: string
  deskripsi?: string
  harga: number
  foto_path?: string
  unggulan?: boolean
  jenis?: 'makanan' | 'minuman' | 'lainnya'
  habis?: boolean
}

export interface KatalogPublikProps {
  penyewa: InfoPenyewaPublik
  cabang: InfoCabangPublik
  pengaturan: PengaturanRestoPublik
  kategori?: KategoriPublik[]
  menu?: MenuItemPublik[]
  urlPublik?: string
  nomorMeja?: string
  onPilihItem?: (item: MenuItemPublik) => void
  onTutup?: () => void
}

export function Katalog({
  penyewa,
  cabang,
  pengaturan,
  kategori = [],
  menu = [],
  urlPublik,
  nomorMeja,
  onPilihItem,
  onTutup,
}: KatalogPublikProps) {
  const { t } = useBahasa()
  const [kategoriTerpilih, setKategoriTerpilih] = useState<string>('semua')
  const [kataKunci, setKataKunci] = useState<string>('')
  const [tampilkanQrModal, setTampilkanQrModal] = useState<boolean>(false)

  // URL lengkap untuk dibagikan (default peramban atau fallback resmi)
  const tautanKatalog = useMemo(() => {
    if (urlPublik) return urlPublik
    if (typeof window !== 'undefined' && window.location) {
      const basis = window.location.origin + window.location.pathname
      const params = new URLSearchParams()
      if (penyewa?.slug) params.set('resto', penyewa.slug)
      if (cabang?.id) params.set('cabang', cabang.id)
      if (nomorMeja) params.set('meja', nomorMeja)
      const q = params.toString()
      return q ? `${basis}?${q}` : basis
    }
    return `https://resto-barokah.fatrizmubarok.workers.dev/menu?resto=${penyewa.slug || 'resto'}`
  }, [urlPublik, penyewa.slug, cabang.id, nomorMeja])

  // Format jam operasional
  const jamBukaTeks = useMemo(() => {
    const jb = pengaturan.jam_buka
    if (!jb) return 'Setiap Hari · 09.00 - 21.00 WIB'
    if (typeof jb === 'string') return jb
    if ('teks' in jb && jb.teks) return jb.teks
    if ('buka' in jb && 'tutup' in jb) return `${jb.buka} - ${jb.tutup} WIB`
    if (typeof jb === 'object') {
      const entries = Object.entries(jb)
      if (entries.length > 0) {
        return `${entries[0][0]}: ${entries[0][1]}`
      }
    }
    return 'Setiap Hari · 09.00 - 21.00 WIB'
  }, [pengaturan.jam_buka])

  // Penyaringan menu berdasarkan pencarian & kategori
  const menuTersaring = useMemo(() => {
    return menu.filter((item) => {
      const cocokKategori = kategoriTerpilih === 'semua' || item.kategori_id === kategoriTerpilih
      const cocokKataKunci =
        kataKunci.trim() === '' ||
        item.nama.toLowerCase().includes(kataKunci.toLowerCase()) ||
        (item.deskripsi && item.deskripsi.toLowerCase().includes(kataKunci.toLowerCase()))
      return cocokKategori && cocokKataKunci
    })
  }, [menu, kategoriTerpilih, kataKunci])

  const namaResto = pengaturan.nama_resto || penyewa.nama || 'Resto Barokah'
  const taglineResto = pengaturan.tagline || 'Cita rasa istimewa untuk keluarga dan sahabat'
  const alamatResto = pengaturan.lokasi?.alamat || cabang.alamat || 'Alamat cabang belum diatur'
  const teleponResto = pengaturan.kontak?.telepon || cabang.telepon || '-'

  return (
    <div
      data-theme={pengaturan.tema || 'terang'}
      className="katalog-publik-wrap"
      style={{
        minHeight: '100vh',
        background: 'var(--bg)',
        color: 'var(--text)',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {/* 1. BILAH ATAS (MEREK RESTO & AKSI BERBAGI) */}
      <header
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 30,
          background: 'var(--surface)',
          borderBottom: '1px solid var(--border)',
          boxShadow: 'var(--sh-1)',
          padding: 'var(--s-3) var(--s-4)',
        }}
      >
        <div
          style={{
            maxWidth: '960px',
            margin: '0 auto',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 'var(--s-3)',
          }}
        >
          {/* Logo & Nama Resto */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)' }}>
            {pengaturan.logo_url ? (
              <img
                src={pengaturan.logo_url}
                alt={`Logo ${namaResto}`}
                style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: 'var(--radius-md)',
                  objectFit: 'cover',
                  border: '1px solid var(--border)',
                }}
              />
            ) : (
              <div
                style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--accent)',
                  color: 'var(--accent-contrast)',
                  display: 'grid',
                  placeItems: 'center',
                  fontWeight: 800,
                  fontSize: '20px',
                }}
                aria-hidden="true"
              >
                🍽️
              </div>
            )}

            <div>
              <h1
                style={{
                  fontSize: 'var(--t-5)',
                  fontWeight: 800,
                  lineHeight: 1.2,
                  margin: 0,
                  color: 'var(--text)',
                }}
                data-testid="merek-nama-resto"
              >
                {namaResto}
              </h1>
              <p
                className="small muted"
                style={{
                  fontSize: 'var(--t-2)',
                  margin: 0,
                  color: 'var(--text-muted)',
                }}
                data-testid="merek-tagline"
              >
                {taglineResto}
              </p>
            </div>
          </div>

          {/* Tombol Aksi Kanan (QR / Bagikan & Tutup bila ada) */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
            {nomorMeja && (
              <span
                className="chip chip-accent"
                style={{ fontWeight: 700 }}
                data-testid="badge-meja"
              >
                Meja {nomorMeja}
              </span>
            )}

            <Tombol
              ragam="biasa"
              onClick={() => setTampilkanQrModal(true)}
              nama="Buka kode QR dan bagikan tautan"
            >
              📱 Bagikan QR
            </Tombol>

            {onTutup && (
              <Tombol ragam="polos" onClick={onTutup} nama="Tutup katalog publik">
                ✕
              </Tombol>
            )}
          </div>
        </div>
      </header>

      {/* 2. AREA KONTEN UTAMA */}
      <main
        style={{
          maxWidth: '960px',
          margin: '0 auto',
          width: '100%',
          flex: '1 0 auto',
          padding: 'var(--s-4)',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-4)',
        }}
      >
        {/* BANNER RESTO */}
        <section
          className="hero"
          style={{
            margin: 0,
            minHeight: '200px',
            borderRadius: 'var(--radius-lg)',
            overflow: 'hidden',
            position: 'relative',
            background: pengaturan.banner_url
              ? `url(${pengaturan.banner_url}) center/cover no-repeat`
              : 'linear-gradient(135deg, var(--accent) 0%, var(--surface-2) 100%)',
            color: 'white',
            boxShadow: 'var(--sh-3)',
          }}
          data-testid="banner-resto"
        >
          {pengaturan.banner_url && (
            <img
              src={pengaturan.banner_url}
              alt={`Banner ${namaResto}`}
              style={{
                position: 'absolute',
                inset: 0,
                width: '100%',
                height: '100%',
                objectFit: 'cover',
              }}
            />
          )}
          <span className="selubung" />
          <div className="isi" style={{ padding: 'var(--s-5)', position: 'relative', zIndex: 2 }}>
            <span
              className="aksen"
              style={{
                color: 'var(--accent)',
                fontWeight: 700,
                fontSize: 'var(--t-3)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
              }}
            >
              {cabang.nama || 'Cabang Utama'}
            </span>
            <h2
              style={{
                fontSize: 'clamp(24px, 4vw, 36px)',
                fontWeight: 800,
                margin: 0,
                lineHeight: 1.15,
                color: 'white',
              }}
            >
              Selamat Datang di {namaResto}
            </h2>

            <div className="bawah" style={{ marginTop: 'var(--s-2)', flexWrap: 'wrap' }}>
              <span
                className="chip chip-kaca"
                style={{ fontSize: 'var(--t-2)' }}
                data-testid="info-jam-buka"
              >
                🕒 {jamBukaTeks}
              </span>
              <span
                className="chip chip-kaca"
                style={{ fontSize: 'var(--t-2)' }}
                data-testid="info-lokasi"
              >
                📍 {alamatResto}
              </span>
            </div>
          </div>
        </section>

        {/* PENCARIAN & SARINGAN */}
        <section
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
            marginTop: 'var(--s-1)',
          }}
        >
          <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
            <input
              type="search"
              className="input"
              value={kataKunci}
              onChange={(e) => setKataKunci(e.target.value)}
              placeholder={t('pelanggan.cari_menu') || 'Cari menu lezat...'}
              aria-label="Cari menu makanan dan minuman"
              style={{
                flex: 1,
                minHeight: '44px',
                borderRadius: 'var(--radius-pil, 9999px)',
                paddingLeft: 'var(--s-4)',
              }}
              data-testid="input-cari-menu"
            />
            {kataKunci && (
              <Tombol ragam="polos" onClick={() => setKataKunci('')} nama="Hapus pencarian">
                ✕
              </Tombol>
            )}
          </div>

          {/* Bar Kategori */}
          {kategori.length > 0 && (
            <nav
              className="bar-kategori"
              aria-label="Pilih Kategori Menu"
              style={{ padding: '0 0 var(--s-2) 0' }}
            >
              <div
                style={{
                  display: 'flex',
                  gap: 'var(--s-2)',
                  overflowX: 'auto',
                  width: '100%',
                  paddingBottom: '4px',
                }}
              >
                <Tombol
                  ragam={kategoriTerpilih === 'semua' ? 'utama' : 'biasa'}
                  onClick={() => setKategoriTerpilih('semua')}
                  nama="Tampilkan semua kategori"
                >
                  🍽️ {t('pelanggan.semua_kategori') || 'Semua'}
                </Tombol>
                {kategori.map((kat) => {
                  const terpilih = kategoriTerpilih === kat.id
                  return (
                    <Tombol
                      key={kat.id}
                      ragam={terpilih ? 'utama' : 'biasa'}
                      onClick={() => setKategoriTerpilih(kat.id)}
                      nama={`Kategori ${kat.nama}`}
                    >
                      {kat.nama}
                    </Tombol>
                  )
                })}
              </div>
            </nav>
          )}
        </section>

        {/* DAFTAR MENU GRID */}
        <section aria-label="Daftar Menu">
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 'var(--s-3)',
            }}
          >
            <h3 style={{ fontSize: 'var(--t-5)', fontWeight: 700, margin: 0 }}>
              Daftar Menu ({menuTersaring.length})
            </h3>
            {kategoriTerpilih !== 'semua' && (
              <span className="small muted">
                Kategori:{' '}
                {kategori.find((k) => k.id === kategoriTerpilih)?.nama || kategoriTerpilih}
              </span>
            )}
          </div>

          {menuTersaring.length === 0 ? (
            <div
              className="kartu"
              style={{
                textAlign: 'center',
                padding: 'var(--s-8) var(--s-4)',
                background: 'var(--surface)',
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-lg)',
              }}
              data-testid="menu-kosong"
            >
              <p style={{ fontSize: '36px', margin: 0 }}>🍃</p>
              <h4 style={{ fontSize: 'var(--t-4)', marginTop: 'var(--s-2)' }}>
                Tidak Ada Menu yang Sesuai
              </h4>
              <p className="small muted">
                {kataKunci
                  ? `Tidak ada menu yang cocok dengan kata kunci "${kataKunci}".`
                  : 'Belum ada menu yang tersedia untuk kategori ini.'}
              </p>
              {kataKunci && (
                <div style={{ marginTop: 'var(--s-3)' }}>
                  <Tombol ragam="biasa" onClick={() => setKataKunci('')}>
                    Reset Pencarian
                  </Tombol>
                </div>
              )}
            </div>
          ) : (
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                gap: 'var(--s-4)',
              }}
              data-testid="kisi-menu"
            >
              {menuTersaring.map((item) => {
                const itemHabis = !!item.habis
                return (
                  <article
                    key={item.id}
                    className="kartu-makan"
                    style={{
                      opacity: itemHabis ? 0.65 : 1,
                      position: 'relative',
                      display: 'flex',
                      flexDirection: 'column',
                    }}
                    data-testid={`kartu-menu-${item.id}`}
                  >
                    <div className="foto" style={{ position: 'relative' }}>
                      {item.foto_path ? (
                        <img
                          src={item.foto_path}
                          alt={item.nama}
                          loading="lazy"
                          style={{
                            width: '100%',
                            height: '100%',
                            objectFit: 'cover',
                          }}
                        />
                      ) : (
                        <div
                          style={{
                            width: '100%',
                            height: '100%',
                            display: 'grid',
                            placeItems: 'center',
                            background: 'var(--surface-2)',
                            color: 'var(--text-muted)',
                            fontSize: '32px',
                          }}
                          aria-hidden="true"
                        >
                          🍲
                        </div>
                      )}

                      {/* Penanda Status: Habis atau Unggulan */}
                      {itemHabis ? (
                        <span
                          className="chip chip-danger"
                          style={{
                            position: 'absolute',
                            top: 'var(--s-2)',
                            right: 'var(--s-2)',
                            fontWeight: 800,
                            boxShadow: 'var(--sh-2)',
                          }}
                          data-testid="indikator-habis"
                        >
                          HABIS
                        </span>
                      ) : item.unggulan ? (
                        <span
                          className="chip chip-accent"
                          style={{
                            position: 'absolute',
                            top: 'var(--s-2)',
                            right: 'var(--s-2)',
                            fontWeight: 700,
                            boxShadow: 'var(--sh-1)',
                          }}
                        >
                          ★ Favorit
                        </span>
                      ) : null}
                    </div>

                    <div
                      className="isi"
                      style={{
                        padding: 'var(--s-3)',
                        flex: '1 0 auto',
                        display: 'flex',
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div>
                        <span className="nm" style={{ display: 'block', fontWeight: 700 }}>
                          {item.nama}
                        </span>
                        {item.deskripsi && (
                          <p
                            className="small muted"
                            style={{
                              fontSize: 'var(--t-2)',
                              marginTop: '2px',
                              marginBottom: 'var(--s-2)',
                              lineHeight: 1.3,
                            }}
                          >
                            {item.deskripsi}
                          </p>
                        )}
                      </div>

                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          marginTop: 'var(--s-2)',
                        }}
                      >
                        <span className="pr num" style={{ fontWeight: 800 }}>
                          {rupiah(item.harga)}
                        </span>

                        {onPilihItem && !itemHabis && (
                          <Tombol
                            ragam="kecil"
                            onClick={() => onPilihItem(item)}
                            nama={`Pilih ${item.nama}`}
                          >
                            Pilih
                          </Tombol>
                        )}
                      </div>
                    </div>
                  </article>
                )
              })}
            </div>
          )}
        </section>

        {/* 3. KARTU INFORMASI KONTAK & LOKASI RESTO */}
        <section
          className="kartu"
          style={{
            padding: 'var(--s-5)',
            background: 'var(--surface)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-lg)',
            marginTop: 'var(--s-4)',
          }}
          data-testid="kartu-info-lengkap"
        >
          <h4 style={{ fontSize: 'var(--t-4)', fontWeight: 700, marginBottom: 'var(--s-3)' }}>
            Informasi Resto & Kontak
          </h4>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
              gap: 'var(--s-4)',
            }}
          >
            <div>
              <p className="small muted" style={{ fontWeight: 600, marginBottom: '2px' }}>
                📍 Lokasi Cabang:
              </p>
              <p style={{ margin: 0, fontWeight: 500 }}>{cabang.nama}</p>
              <p className="small muted" style={{ margin: 0 }}>
                {alamatResto}
              </p>
              {pengaturan.lokasi?.maps_url && (
                <a
                  href={pengaturan.lokasi.maps_url}
                  target="_blank"
                  rel="noreferrer noopener"
                  style={{
                    display: 'inline-block',
                    marginTop: 'var(--s-1)',
                    fontSize: 'var(--t-2)',
                    color: 'var(--accent)',
                    fontWeight: 600,
                  }}
                >
                  Lihat di Google Maps →
                </a>
              )}
            </div>

            <div>
              <p className="small muted" style={{ fontWeight: 600, marginBottom: '2px' }}>
                🕒 Jam Operasional:
              </p>
              <p style={{ margin: 0, fontWeight: 500 }}>{jamBukaTeks}</p>
            </div>

            <div>
              <p className="small muted" style={{ fontWeight: 600, marginBottom: '2px' }}>
                📞 Kontak & Pemesanan:
              </p>
              <p style={{ margin: 0, fontWeight: 500 }} data-testid="info-telepon">
                {teleponResto}
              </p>
              {pengaturan.kontak?.whatsapp && (
                <p className="small muted" style={{ margin: 0 }}>
                  WhatsApp: {pengaturan.kontak.whatsapp}
                </p>
              )}
            </div>
          </div>
        </section>
      </main>

      {/* 4. FOOTER */}
      <footer
        style={{
          borderTop: '1px solid var(--border)',
          background: 'var(--surface)',
          padding: 'var(--s-4)',
          textAlign: 'center',
          marginTop: 'var(--s-6)',
        }}
      >
        <p className="small muted" style={{ margin: 0 }}>
          © {new Date().getFullYear()} <strong>{namaResto}</strong> · Didukung oleh{' '}
          <span style={{ color: 'var(--accent)', fontWeight: 600 }}>Resto Barokah</span>
        </p>
      </footer>

      {/* 5. MODAL DIALOG QR CODE & SALIN TAUTAN */}
      <Lapis
        buka={tampilkanQrModal}
        judul="Bagikan Menu Resto"
        onTutup={() => setTampilkanQrModal(false)}
        kaki={
          <Tombol
            ragam="biasa"
            lebar
            onClick={() => setTampilkanQrModal(false)}
            nama="Selesai melihat QR"
          >
            Selesai
          </Tombol>
        }
      >
        <div data-testid="modal-qr">
          <KomponenQr
            url={tautanKatalog}
            ukuran={200}
            judul={namaResto}
            keterangan={
              nomorMeja
                ? `Menu digital khusus Meja ${nomorMeja}. Pindai langsung dengan kamera ponsel.`
                : 'Pindai kode QR atau salin tautan untuk membuka menu di peramban ponsel.'
            }
            bisaSalin
            bisaUnduh
          />
        </div>
      </Lapis>
    </div>
  )
}
