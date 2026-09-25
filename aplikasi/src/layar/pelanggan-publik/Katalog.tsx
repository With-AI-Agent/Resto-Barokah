import { useState, useMemo } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KomponenQr } from '../../komponen/KomponenQr'
import { Lapis } from '../../komponen/Lapis'
import {
  Menu,
  type MenuItemPublik,
  type KategoriPublik,
  type VarianPublik,
  type TambahanPublik,
} from './Menu'

export type { MenuItemPublik, KategoriPublik, VarianPublik, TambahanPublik }

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

        {/* DAFTAR MENU PUBLIK DENGAN FOTO, VARIAN, TAMBAHAN, & STATUS HABIS (T8-03) */}
        <section aria-label="Daftar Menu Resto">
          <Menu kategori={kategori} menu={menu} onPilihItem={onPilihItem} />
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
