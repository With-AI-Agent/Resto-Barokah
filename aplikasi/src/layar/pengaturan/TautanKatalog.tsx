import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KolomIsian } from '../../komponen/KolomIsian'
import { KomponenQr } from '../../komponen/KomponenQr'
import { buatQrMatriks } from '../../lib/qrcode'

export interface MejaKatalog {
  id: string
  nama: string
  area?: string
}

export interface TautanKatalogProps {
  namaResto?: string
  tagline?: string
  slugResto?: string
  baseUrl?: string
  daftarMeja?: MejaKatalog[]
  onCetak?: () => void
  onKembali?: () => void
}

const DAFTAR_MEJA_DEFAULT: MejaKatalog[] = [
  { id: 'meja-01', nama: 'Meja 01', area: 'Utama / AC' },
  { id: 'meja-02', nama: 'Meja 02', area: 'Utama / AC' },
  { id: 'meja-03', nama: 'Meja 03', area: 'Utama / AC' },
  { id: 'meja-04', nama: 'Meja 04', area: 'Outdoor' },
  { id: 'meja-05', nama: 'Meja 05', area: 'Outdoor' },
  { id: 'meja-vip-1', nama: 'Meja VIP 1', area: 'Lantai 2' },
]

export function TautanKatalog({
  namaResto = 'Resto Barokah',
  tagline = 'Cita Rasa Nusantara & Masakan Tradisional',
  slugResto = 'resto-barokah',
  baseUrl,
  daftarMeja = DAFTAR_MEJA_DEFAULT,
  onCetak,
  onKembali,
}: TautanKatalogProps) {
  const [tabAktif, setTabAktif] = useState<'resto' | 'meja' | 'massal'>('resto')
  const [mejaTerpilihId, setMejaTerpilihId] = useState<string>(daftarMeja[0]?.id || 'meja-01')
  const [mejaKustom, setMejaKustom] = useState<string>('')
  const [tersalin, setTersalin] = useState(false)
  const [perangkatTeruji, setPerangkatTeruji] = useState<{ android: boolean; ios: boolean }>({
    android: false,
    ios: false,
  })

  // URL dasar resolusi cerdas
  const hostDasar =
    baseUrl ||
    (typeof window !== 'undefined' ? window.location.origin : 'https://resto-barokah.dev')

  // Tautan publik umum resto
  const tautanPublikResto = `${hostDasar}/katalog/${slugResto}`

  // Meja yang sedang dipilih
  const mejaTerpilih = daftarMeja.find((m) => m.id === mejaTerpilihId) || {
    id: 'kustom',
    nama: mejaKustom || 'Meja Khusus',
    area: 'Area Meja',
  }

  const namaMejaAktif = mejaKustom.trim() ? mejaKustom.trim() : mejaTerpilih.nama

  // Tautan khusus meja
  const tautanMeja = `${tautanPublikResto}?meja=${encodeURIComponent(namaMejaAktif)}&meja_id=${encodeURIComponent(mejaTerpilih.id)}`

  const tanganiSalinTautan = async (tautan: string) => {
    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(tautan)
      }
      setTersalin(true)
      setTimeout(() => setTersalin(false), 2500)
    } catch {
      setTersalin(true)
      setTimeout(() => setTersalin(false), 2500)
    }
  }

  const tanganiCetak = () => {
    if (onCetak) {
      onCetak()
    } else if (typeof window !== 'undefined' && window.print) {
      window.print()
    }
  }

  const tanganiBagikanWa = (tautan: string) => {
    const teksPesan = encodeURIComponent(
      `Halo! Silakan lihat daftar menu dan harga kami di ${namaResto} lewat tautan ini: ${tautan}`,
    )
    if (typeof window !== 'undefined') {
      window.open(`https://api.whatsapp.com/send?text=${teksPesan}`, '_blank')
    }
  }

  const tanganiUnduhKartuMejaSvg = (namaMejaTarget: string, urlTarget: string) => {
    const matriks = buatQrMatriks(urlTarget)
    const N = matriks.length
    const margin = 2
    const total = N + margin * 2

    let pathD = ''
    for (let r = 0; r < N; r++) {
      for (let c = 0; c < N; c++) {
        if (matriks[r][c]) {
          pathD += `M${c + margin},${r + margin}h1v1h-1z `
        }
      }
    }

    const svgKartu = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 560" width="400" height="560">
  <rect width="100%" height="100%" fill="white" rx="16" stroke="black" stroke-width="2"/>
  <text x="200" y="45" font-family="sans-serif" font-size="20" font-weight="bold" text-anchor="middle" fill="black">${namaResto}</text>
  <text x="200" y="70" font-family="sans-serif" font-size="12" text-anchor="middle" fill="gray">${tagline}</text>
  <line x1="40" y1="90" x2="360" y2="90" stroke="black" stroke-width="1"/>
  
  <rect x="75" y="110" width="250" height="50" rx="8" fill="black"/>
  <text x="200" y="143" font-family="sans-serif" font-size="24" font-weight="900" text-anchor="middle" fill="white">${namaMejaTarget.toUpperCase()}</text>
  
  <g transform="translate(80, 180)">
    <rect width="240" height="240" fill="white"/>
    <svg viewBox="0 0 ${total} ${total}" width="240" height="240">
      <path d="${pathD.trim()}" fill="black"/>
    </svg>
  </g>
  
  <text x="200" y="455" font-family="sans-serif" font-size="14" font-weight="bold" text-anchor="middle" fill="black">Pindai untuk Melihat Menu</text>
  <text x="200" y="478" font-family="sans-serif" font-size="11" text-anchor="middle" fill="gray">Arahkan kamera ponsel Anda ke kode QR di atas</text>
  <text x="200" y="520" font-family="sans-serif" font-size="10" text-anchor="middle" fill="gray">${urlTarget}</text>
</svg>`

    const blob = new Blob([svgKartu], { type: 'image/svg+xml' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `kartu-meja-${namaMejaTarget.toLowerCase().replace(/\s+/g, '-')}.svg`
    link.click()
    URL.revokeObjectURL(link.href)
  }

  return (
    <div
      className="layar-tautan-katalog"
      style={{
        maxWidth: '900px',
        margin: '0 auto',
        padding: 'var(--s-4)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--s-4)',
      }}
      data-testid="layar-tautan-katalog"
    >
      {/* Header Halaman */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: 'var(--s-3)',
          borderBottom: '1px solid var(--border)',
          paddingBottom: 'var(--s-3)',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
            <span style={{ fontSize: '24px' }}>📱</span>
            <h2
              style={{
                fontSize: 'var(--t-5)',
                fontWeight: 800,
                color: 'var(--text)',
                margin: 0,
              }}
            >
              Tautan & Kode QR Katalog Resto
            </h2>
          </div>
          <p
            style={{
              fontSize: 'var(--t-2)',
              color: 'var(--text-muted)',
              marginTop: 'var(--s-1)',
              marginBottom: 0,
            }}
          >
            Bagikan tautan menu ke media sosial atau cetak kode QR meja untuk pelanggan kedai.
          </p>
        </div>

        {onKembali && (
          <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke pengaturan">
            ← Kembali
          </Tombol>
        )}
      </div>

      {/* Navigasi Tab Pengaturan Tautan */}
      <div
        style={{
          display: 'flex',
          gap: 'var(--s-2)',
          borderBottom: '1px solid var(--border)',
          paddingBottom: 'var(--s-2)',
          flexWrap: 'wrap',
        }}
        role="tablist"
        aria-label="Pilihan Jenis Tautan Katalog"
      >
        <Tombol
          ragam={tabAktif === 'resto' ? 'utama' : 'biasa'}
          onClick={() => setTabAktif('resto')}
          nama="Pilih tab Tautan & QR Utama"
        >
          🌐 Tautan & QR Utama (Resto)
        </Tombol>
        <Tombol
          ragam={tabAktif === 'meja' ? 'utama' : 'biasa'}
          onClick={() => setTabAktif('meja')}
          nama="Pilih tab QR Per Meja"
        >
          🍽️ QR Per Meja (Siap Cetak)
        </Tombol>
        <Tombol
          ragam={tabAktif === 'massal' ? 'utama' : 'biasa'}
          onClick={() => setTabAktif('massal')}
          nama="Pilih tab Cetak Massal Semua Meja"
        >
          🖨️ Cetak Massal Semua Meja
        </Tombol>
      </div>

      {/* ======================= TAB 1: TAUTAN & QR UTAMA RESTO ======================= */}
      {tabAktif === 'resto' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}>
          <Kartu judul="Tautan Resmi Menu Digital Pelanggan">
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--s-3)',
                padding: 'var(--s-3)',
              }}
            >
              <p style={{ fontSize: 'var(--t-2)', color: 'var(--text)', margin: 0 }}>
                Tautan ini dapat dipasang di bio Instagram, profil Google Maps, pesan WhatsApp, atau
                dibagikan ke calon pelanggan sebelum berkunjung.
              </p>

              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--s-2)',
                  background: 'var(--surface-2)',
                  padding: 'var(--s-2) var(--s-3)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border)',
                  wordBreak: 'break-all',
                }}
              >
                <span style={{ fontSize: '18px' }}>🔗</span>
                <span
                  style={{
                    fontSize: 'var(--t-2)',
                    fontWeight: 600,
                    color: 'var(--accent)',
                    fontFamily: 'var(--font-mono, monospace)',
                    flex: 1,
                  }}
                  data-testid="tautan-utama-resto"
                >
                  {tautanPublikResto}
                </span>
              </div>

              <div style={{ display: 'flex', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
                <Tombol
                  ragam={tersalin ? 'biasa' : 'utama'}
                  onClick={() => tanganiSalinTautan(tautanPublikResto)}
                  nama="Salin tautan resto"
                >
                  {tersalin ? '✓ Tautan Berhasil Disalin!' : '📋 Salin Tautan'}
                </Tombol>

                <Tombol
                  ragam="biasa"
                  onClick={() => tanganiBagikanWa(tautanPublikResto)}
                  nama="Bagikan ke WhatsApp"
                >
                  💬 Bagikan ke WhatsApp
                </Tombol>

                <Tombol
                  ragam="polos"
                  onClick={() => {
                    if (typeof window !== 'undefined') {
                      window.open(tautanPublikResto, '_blank')
                    }
                  }}
                  nama="Buka pratinjau katalog menu"
                >
                  ↗️ Buka Pratinjau
                </Tombol>
              </div>
            </div>
          </Kartu>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
              gap: 'var(--s-4)',
            }}
          >
            {/* Kartu QR Utama */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
              <KomponenQr
                url={tautanPublikResto}
                judul={`QR Menu ${namaResto}`}
                keterangan="Pindai untuk melihat seluruh menu dan ketersediaan cabang secara langsung."
                bisaSalin={true}
                bisaUnduh={true}
              />
            </div>

            {/* Rekomendasi Penggunaan */}
            <Kartu judul="Petunjuk Pemasangan QR">
              <div
                style={{
                  padding: 'var(--s-3)',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 'var(--s-2)',
                  fontSize: 'var(--t-2)',
                  color: 'var(--text)',
                }}
              >
                <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
                  <span>📍</span>
                  <div>
                    <strong>Papan Kasir & Pintu Masuk:</strong> Cetak QR umum ini dan letakkan di
                    atas meja kasir untuk antrean yang ingin melihat menu lebih awal.
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
                  <span>📢</span>
                  <div>
                    <strong>Media Promosi:</strong> Sisipkan QR pada brosur cetak atau banner kedai
                    agar orang yang lewat dapat langsung melihat menu di ponsel.
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
                  <span>✨</span>
                  <div>
                    <strong>Hemat Biaya Cetak:</strong> Pembaruan harga dan stok habis otomatis
                    tersinkronisasi tanpa perlu mencetak ulang buku menu fisik.
                  </div>
                </div>
              </div>
            </Kartu>
          </div>
        </div>
      )}

      {/* ======================= TAB 2: QR PER NOMOR MEJA ======================= */}
      {tabAktif === 'meja' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}>
          {/* Panel Pemilihan Meja */}
          <Kartu judul="Pilih Meja Resto">
            <div
              style={{
                padding: 'var(--s-3)',
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--s-3)',
              }}
            >
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--s-2)' }}>
                {daftarMeja.map((meja) => {
                  const aktif = mejaTerpilihId === meja.id && !mejaKustom.trim()
                  return (
                    <Tombol
                      key={meja.id}
                      ragam={aktif ? 'utama' : 'biasa'}
                      onClick={() => {
                        setMejaTerpilihId(meja.id)
                        setMejaKustom('')
                      }}
                      nama={`Pilih nomor ${meja.nama}`}
                    >
                      {meja.nama} {meja.area ? `(${meja.area})` : ''}
                    </Tombol>
                  )
                })}
              </div>

              {/* Isian Meja Kustom */}
              <div style={{ maxWidth: '320px' }}>
                <KolomIsian
                  label="Nomor / Nama Meja Kustom (Opsional)"
                  nilai={mejaKustom}
                  onUbah={setMejaKustom}
                  contoh="Contoh: Meja Lesehan 3"
                  keterangan="Gunakan ini bila ingin mencetak nomor meja yang belum ada di daftar."
                />
              </div>
            </div>
          </Kartu>

          {/* Pratinjau Kartu Meja Siap Cetak & Tombol Aksi */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
              gap: 'var(--s-4)',
              alignItems: 'start',
            }}
          >
            {/* Lembar Akrilik Kartu Meja (Visual Preview Stand) */}
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 'var(--s-2)',
              }}
            >
              <div
                id="area-cetak-kartu-meja"
                className="kartu"
                style={{
                  width: '100%',
                  maxWidth: '340px',
                  background: 'var(--surface)',
                  border: '2px solid var(--text)',
                  borderRadius: 'var(--radius-lg)',
                  padding: 'var(--s-4)',
                  textAlign: 'center',
                  boxShadow: 'var(--sh-3)',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: 'var(--s-3)',
                }}
                data-testid="pratinjau-kartu-meja"
              >
                {/* Header Kartu Meja */}
                <div>
                  <h3
                    style={{
                      fontSize: 'var(--t-4)',
                      fontWeight: 800,
                      margin: 0,
                      color: 'var(--text)',
                    }}
                  >
                    {namaResto}
                  </h3>
                  <p
                    style={{
                      fontSize: 'var(--t-1)',
                      color: 'var(--text-muted)',
                      margin: 'var(--s-1) 0 0 0',
                    }}
                  >
                    {tagline}
                  </p>
                </div>

                {/* Kotak Nomor Meja Tebal */}
                <div
                  style={{
                    background: 'var(--text)',
                    color: 'var(--surface)',
                    padding: 'var(--s-2) var(--s-4)',
                    borderRadius: 'var(--radius-md)',
                    width: '80%',
                  }}
                  data-testid="nomor-meja-terpilih"
                >
                  <span
                    style={{
                      fontSize: 'var(--t-4)',
                      fontWeight: 900,
                      letterSpacing: '1px',
                    }}
                  >
                    {namaMejaAktif.toUpperCase()}
                  </span>
                </div>

                {/* Kode QR Tajam */}
                <div
                  style={{
                    background: 'white',
                    padding: 'var(--s-2)',
                    borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--border)',
                  }}
                  data-testid="qr-meja-svg-wadah"
                >
                  {/* Render SVG QR langsung */}
                  {(() => {
                    const matriks = buatQrMatriks(tautanMeja)
                    const N = matriks.length
                    const margin = 2
                    const total = N + margin * 2
                    let pathD = ''
                    for (let r = 0; r < N; r++) {
                      for (let c = 0; c < N; c++) {
                        if (matriks[r][c]) {
                          pathD += `M${c + margin},${r + margin}h1v1h-1z `
                        }
                      }
                    }
                    return (
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox={`0 0 ${total} ${total}`}
                        width={180}
                        height={180}
                        role="img"
                        aria-label={`QR Meja ${namaMejaAktif}`}
                        style={{ display: 'block' }}
                      >
                        <rect width="100%" height="100%" fill="white" />
                        <path d={pathD.trim()} fill="black" />
                      </svg>
                    )
                  })()}
                </div>

                {/* Petunjuk Konsumen */}
                <div>
                  <div
                    style={{
                      fontSize: 'var(--t-2)',
                      fontWeight: 700,
                      color: 'var(--text)',
                    }}
                  >
                    Pindai untuk Melihat Menu
                  </div>
                  <div
                    style={{
                      fontSize: 'var(--t-1)',
                      color: 'var(--text-muted)',
                      marginTop: 'var(--s-1)',
                    }}
                  >
                    Buka kamera HP Anda & arahkan ke kode QR ini
                  </div>
                  <div
                    style={{
                      fontSize: 'var(--t-1)',
                      color: 'var(--text-muted)',
                      marginTop: 'var(--s-1)',
                      fontFamily: 'var(--font-mono, monospace)',
                    }}
                  >
                    {tautanMeja}
                  </div>
                </div>
              </div>

              <span
                style={{
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                  fontStyle: 'italic',
                }}
              >
                Pratinjau tampilan fisik stand akrilik meja (A6)
              </span>
            </div>

            {/* Panel Aksi Cetak & Mitigasi Risiko Uji Pindai */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
              <Kartu judul="Aksi Cetak & Unduh">
                <div
                  style={{
                    padding: 'var(--s-3)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 'var(--s-2)',
                  }}
                >
                  <Tombol
                    ragam="utama"
                    onClick={tanganiCetak}
                    lebar
                    nama="Cetak lembar kartu meja ini"
                  >
                    🖨️ Cetak Kartu Meja Ini
                  </Tombol>

                  <Tombol
                    ragam="biasa"
                    onClick={() => tanganiUnduhKartuMejaSvg(namaMejaAktif, tautanMeja)}
                    lebar
                    nama="Unduh berkas kartu meja SVG"
                  >
                    ⬇️ Unduh Kartu Meja (SVG Siap Cetak)
                  </Tombol>

                  <Tombol
                    ragam="polos"
                    onClick={() => tanganiSalinTautan(tautanMeja)}
                    lebar
                    nama="Salin tautan meja"
                  >
                    {tersalin ? '✓ Tautan Tersalin!' : '📋 Salin Tautan Meja Ini'}
                  </Tombol>
                </div>
              </Kartu>

              {/* Mitigasi Risiko: Panel Uji Pindai 2 Perangkat Sebelum Cetak */}
              <Kartu judul="Mitigasi Risiko: Uji Pindai Sebelum Cetak">
                <div
                  style={{
                    padding: 'var(--s-3)',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 'var(--s-2)',
                    fontSize: 'var(--t-2)',
                  }}
                  data-testid="panel-uji-pindai"
                >
                  <p style={{ margin: 0, color: 'var(--text)' }}>
                    Untuk mencegah <strong>salah cetak QR</strong> pada puluhan meja akrilik,
                    pastikan kode QR terverifikasi terbaca dengan baik:
                  </p>

                  <div
                    style={{
                      background: 'var(--surface-2)',
                      padding: 'var(--s-2)',
                      borderRadius: 'var(--radius-sm)',
                      border: '1px solid var(--border)',
                      fontSize: 'var(--t-1)',
                      fontFamily: 'var(--font-mono, monospace)',
                    }}
                  >
                    <div>
                      <strong>Target Meja:</strong> {namaMejaAktif}
                    </div>
                    <div>
                      <strong>Tautan Terbaca:</strong> {tautanMeja}
                    </div>
                  </div>

                  {/* Simulasi / Uji 2 Perangkat */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-2)' }}>
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <span>Uji Pindai 1 (Android / Chrome):</span>
                      {perangkatTeruji.android ? (
                        <Lencana nada="success">✓ Terverifikasi</Lencana>
                      ) : (
                        <Tombol
                          ragam="kecil"
                          onClick={() => setPerangkatTeruji((p) => ({ ...p, android: true }))}
                          nama="Uji pindai di Android"
                        >
                          Uji Coba Android
                        </Tombol>
                      )}
                    </div>

                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <span>Uji Pindai 2 (Apple iOS / Safari):</span>
                      {perangkatTeruji.ios ? (
                        <Lencana nada="success">✓ Terverifikasi</Lencana>
                      ) : (
                        <Tombol
                          ragam="kecil"
                          onClick={() => setPerangkatTeruji((p) => ({ ...p, ios: true }))}
                          nama="Uji pindai di iPhone"
                        >
                          Uji Coba iPhone
                        </Tombol>
                      )}
                    </div>
                  </div>

                  {perangkatTeruji.android && perangkatTeruji.ios && (
                    <div
                      style={{
                        background: 'var(--surface)',
                        border: '1px solid var(--border)',
                        padding: 'var(--s-2)',
                        borderRadius: 'var(--radius-sm)',
                        color: 'var(--accent)',
                        fontWeight: 600,
                        textAlign: 'center',
                      }}
                      data-testid="status-uji-lolos"
                    >
                      🎉 Kedua perangkat terverifikasi! Kode QR aman untuk dicetak massal.
                    </div>
                  )}
                </div>
              </Kartu>
            </div>
          </div>
        </div>
      )}

      {/* ======================= TAB 3: CETAK MASSAL SEMUA MEJA ======================= */}
      {tabAktif === 'massal' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}>
          <Kartu judul={`Daftar Seluruh Kartu Meja (${daftarMeja.length} Meja)`}>
            <div
              style={{
                padding: 'var(--s-3)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                flexWrap: 'wrap',
                gap: 'var(--s-2)',
                borderBottom: '1px solid var(--border)',
              }}
            >
              <span style={{ fontSize: 'var(--t-2)', color: 'var(--text-muted)' }}>
                Siap untuk dicetak sekaligus pada kertas stiker atau lembar akrilik meja.
              </span>
              <Tombol
                ragam="utama"
                onClick={tanganiCetak}
                nama="Cetak seluruh lembar kartu meja sekarang"
              >
                🖨️ Cetak Semua Kartu Meja Sekaligus
              </Tombol>
            </div>

            {/* Grid Semua Meja */}
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                gap: 'var(--s-3)',
                padding: 'var(--s-3)',
              }}
              data-testid="kisi-cetak-massal"
            >
              {daftarMeja.map((meja) => {
                const urlMejaIni = `${tautanPublikResto}?meja=${encodeURIComponent(meja.nama)}&meja_id=${encodeURIComponent(meja.id)}`
                const matriks = buatQrMatriks(urlMejaIni)
                const N = matriks.length
                const margin = 2
                const total = N + margin * 2
                let pathD = ''
                for (let r = 0; r < N; r++) {
                  for (let c = 0; c < N; c++) {
                    if (matriks[r][c]) {
                      pathD += `M${c + margin},${r + margin}h1v1h-1z `
                    }
                  }
                }

                return (
                  <div
                    key={meja.id}
                    className="kartu"
                    style={{
                      background: 'var(--surface)',
                      border: '1px solid var(--border)',
                      borderRadius: 'var(--radius-md)',
                      padding: 'var(--s-3)',
                      textAlign: 'center',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: 'var(--s-2)',
                    }}
                    data-testid={`kartu-massal-${meja.id}`}
                  >
                    <div
                      style={{
                        fontSize: 'var(--t-2)',
                        fontWeight: 800,
                        color: 'var(--text)',
                      }}
                    >
                      {meja.nama}
                    </div>
                    {meja.area && (
                      <span
                        style={{
                          fontSize: 'var(--t-1)',
                          color: 'var(--text-muted)',
                        }}
                      >
                        {meja.area}
                      </span>
                    )}

                    <div
                      style={{
                        background: 'white',
                        padding: 'var(--s-1)',
                        borderRadius: 'var(--radius-sm)',
                        display: 'inline-block',
                      }}
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        viewBox={`0 0 ${total} ${total}`}
                        width={130}
                        height={130}
                        role="img"
                        aria-label={`QR ${meja.nama}`}
                      >
                        <rect width="100%" height="100%" fill="white" />
                        <path d={pathD.trim()} fill="black" />
                      </svg>
                    </div>

                    <Tombol
                      ragam="kecil"
                      onClick={() => tanganiUnduhKartuMejaSvg(meja.nama, urlMejaIni)}
                      nama={`Unduh SVG kartu ${meja.nama}`}
                    >
                      ⬇️ Unduh SVG
                    </Tombol>
                  </div>
                )
              })}
            </div>
          </Kartu>
        </div>
      )}
    </div>
  )
}
