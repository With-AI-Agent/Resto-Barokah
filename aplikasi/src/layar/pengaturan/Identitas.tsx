/* eslint-disable react-refresh/only-export-components */
/**
 * Identitas.tsx — Pengaturan Identitas & Tampilan Restoran (T9-01 / PRD M2)
 *
 * Mengizinkan Owner Resto (atau staf dengan izin atur_pengaturan) untuk:
 *  1. Mengubah nama restoran dan tagline/slogan.
 *  2. Mengunggah logo resto (auto-resize/kompresi maks 400x400 px, batas 2 MB).
 *  3. Mengunggah banner hero resto (auto-resize maks 1200x600 px, batas 3 MB).
 *  4. Menetapkan jam operasional resto.
 *  5. Melihat pratinjau langsung tampilan katalog publik dan struk kasir.
 *  6. Menyimpan pengaturan dengan optimistic concurrency locking.
 */

import { useState, useRef, useId, type ChangeEvent } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'

export interface DataIdentitas {
  namaResto: string
  tagline: string
  logoUrl: string
  bannerUrl: string
  jamBuka: string
  versiPengaturan?: string | null
}

export interface IdentitasProps {
  dataAwal?: Partial<DataIdentitas>
  onSimpan?: (data: DataIdentitas) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

const DATA_BAWAAN: DataIdentitas = {
  namaResto: 'Kedai Oasis Barokah',
  tagline: 'Sensasi Kuliner Warisan Tradisi yang Hangat & Halal',
  logoUrl: '',
  bannerUrl: '',
  jamBuka: 'Setiap Hari: 08.00 - 22.00 WIB',
  versiPengaturan: null,
}

const TIPE_GAMBAR_VALID = ['image/jpeg', 'image/png', 'image/webp']
const BATAS_UKURAN_LOGO = 2 * 1024 * 1024 // 2 MB
const BATAS_UKURAN_BANNER = 3 * 1024 * 1024 // 3 MB

/**
 * Membaca berkas gambar dan memperkecil dimensinya via Canvas bila memungkinkan.
 * Aman untuk JSDOM (fallback membaca langsung bila getContext('2d') menghasilkan null).
 */
export async function bacaGambarDanPerkecil(
  berkas: File,
  lebarMaks: number,
  tinggiMaks: number,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const pembaca = new FileReader()
    pembaca.onerror = () => reject(new Error('Gagal membaca berkas gambar.'))
    pembaca.onload = () => {
      const dataUrl = pembaca.result as string
      // Coba perkecil dengan Image dan Canvas jika didukung lingkungan peramban
      try {
        const img = new Image()
        img.onerror = () => resolve(dataUrl)
        img.onload = () => {
          try {
            let lebar = img.width
            let tinggi = img.height

            if (lebar > lebarMaks || tinggi > tinggiMaks) {
              const rasio = Math.min(lebarMaks / lebar, tinggiMaks / tinggi)
              lebar = Math.round(lebar * rasio)
              tinggi = Math.round(tinggi * rasio)
            }

            const canvas = document.createElement('canvas')
            canvas.width = lebar
            canvas.height = tinggi
            const ctx = canvas.getContext('2d')
            if (!ctx) {
              resolve(dataUrl)
              return
            }

            ctx.drawImage(img, 0, 0, lebar, tinggi)
            const jenisOutput = berkas.type === 'image/png' ? 'image/png' : 'image/jpeg'
            const hasilKompresi = canvas.toDataURL(jenisOutput, 0.85)
            resolve(hasilKompresi)
          } catch {
            resolve(dataUrl)
          }
        }
        img.src = dataUrl
      } catch {
        resolve(dataUrl)
      }
    }
    pembaca.readAsDataURL(berkas)
  })
}

export function Identitas({ dataAwal, onSimpan, onKembali, hanyaBaca = false }: IdentitasProps) {
  const [namaResto, setNamaResto] = useState(dataAwal?.namaResto ?? DATA_BAWAAN.namaResto)
  const [tagline, setTagline] = useState(dataAwal?.tagline ?? DATA_BAWAAN.tagline)
  const [logoUrl, setLogoUrl] = useState(dataAwal?.logoUrl ?? DATA_BAWAAN.logoUrl)
  const [bannerUrl, setBannerUrl] = useState(dataAwal?.bannerUrl ?? DATA_BAWAAN.bannerUrl)
  const [jamBuka, setJamBuka] = useState(dataAwal?.jamBuka ?? DATA_BAWAAN.jamBuka)
  const [versiPengaturan, setVersiPengaturan] = useState<string | null>(
    dataAwal?.versiPengaturan ?? null,
  )

  const [tabPratinjau, setTabPratinjau] = useState<'katalog' | 'struk'>('katalog')
  const [sedangMemuat, setSedangMemuat] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)

  const refInputLogo = useRef<HTMLInputElement>(null)
  const refInputBanner = useRef<HTMLInputElement>(null)
  const idNotifikasi = useId()

  const tanganiPilihLogo = async (e: ChangeEvent<HTMLInputElement>) => {
    const berkas = e.target.files?.[0]
    if (!berkas) return
    setPesanGalat(null)

    if (!TIPE_GAMBAR_VALID.includes(berkas.type)) {
      setPesanGalat('Format berkas logo harus berupa gambar JPG, PNG, atau WebP.')
      return
    }

    if (berkas.size > BATAS_UKURAN_LOGO) {
      setPesanGalat('Ukuran logo maksimal 2 MB.')
      return
    }

    try {
      const dataGambar = await bacaGambarDanPerkecil(berkas, 400, 400)
      setLogoUrl(dataGambar)
      setPesanSukses('Logo berhasil dipilih dan diperkecil.')
    } catch {
      setPesanGalat('Gagal memproses gambar logo.')
    }
  }

  const tanganiPilihBanner = async (e: ChangeEvent<HTMLInputElement>) => {
    const berkas = e.target.files?.[0]
    if (!berkas) return
    setPesanGalat(null)

    if (!TIPE_GAMBAR_VALID.includes(berkas.type)) {
      setPesanGalat('Format berkas banner harus berupa gambar JPG, PNG, atau WebP.')
      return
    }

    if (berkas.size > BATAS_UKURAN_BANNER) {
      setPesanGalat('Ukuran banner maksimal 3 MB.')
      return
    }

    try {
      const dataGambar = await bacaGambarDanPerkecil(berkas, 1200, 600)
      setBannerUrl(dataGambar)
      setPesanSukses('Banner berhasil dipilih dan diperkecil.')
    } catch {
      setPesanGalat('Gagal memproses gambar banner.')
    }
  }

  const tanganiSimpan = async () => {
    setPesanGalat(null)
    setPesanSukses(null)

    const namaBersih = namaResto.trim()
    if (!namaBersih) {
      setPesanGalat('Nama restoran wajib diisi (minimal 1 karakter).')
      return
    }

    if (namaBersih.length > 120) {
      setPesanGalat('Nama restoran maksimal 120 karakter.')
      return
    }

    setSedangMemuat(true)
    try {
      if (onSimpan) {
        const hasil = await onSimpan({
          namaResto: namaBersih,
          tagline: tagline.trim(),
          logoUrl,
          bannerUrl,
          jamBuka: jamBuka.trim(),
          versiPengaturan,
        })

        if (!hasil.berhasil) {
          setPesanGalat(hasil.pesan || 'Gagal menyimpan pengaturan identitas.')
        } else {
          setPesanSukses(hasil.pesan || 'Identitas restoran berhasil disimpan!')
          if (hasil.pesan && hasil.pesan.includes('versi:')) {
            setVersiPengaturan(new Date().toISOString())
          }
        }
      } else {
        // Simulasi jika tidak ada onSimpan eksternal
        setPesanSukses('Identitas restoran berhasil diperbarui!')
        setVersiPengaturan(new Date().toISOString())
      }
    } catch (galat: unknown) {
      const pesan = galat instanceof Error ? galat.message : 'Terjadi kesalahan sistem.'
      setPesanGalat(pesan)
    } finally {
      setSedangMemuat(false)
    }
  }

  return (
    <div className="layar-identitas" data-testid="layar-identitas">
      {/* Kepala Halaman */}
      <div
        className="baris-judul"
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '1.25rem',
        }}
      >
        <div>
          <h2 style={{ margin: 0, fontSize: '1.5rem', fontWeight: 700 }}>
            Identitas & Tampilan Restoran
          </h2>
          <p className="teks-lemah" style={{ margin: '0.25rem 0 0 0', color: 'var(--muted)' }}>
            Kelola nama resto, logo, banner, dan tagline yang tampil di katalog publik dan cetakan
            kasir.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu pengaturan">
              Kembali
            </Tombol>
          )}
          {!hanyaBaca && (
            <Tombol
              ragam="utama"
              onClick={tanganiSimpan}
              nonaktif={sedangMemuat}
              nama="Simpan identitas resto"
            >
              {sedangMemuat ? 'Menyimpan...' : 'Simpan Perubahan'}
            </Tombol>
          )}
        </div>
      </div>

      {/* Pesan Galat & Sukses */}
      {pesanGalat && (
        <div
          role="alert"
          id={`${idNotifikasi}-galat`}
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius-md)',
            backgroundColor: 'var(--surface-2)',
            borderLeft: '4px solid var(--danger)',
            color: 'var(--text)',
            fontSize: '0.95rem',
          }}
        >
          <strong>Perhatian: </strong>
          {pesanGalat}
        </div>
      )}

      {pesanSukses && (
        <div
          role="status"
          id={`${idNotifikasi}-sukses`}
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius-md)',
            backgroundColor: 'var(--surface-2)',
            borderLeft: '4px solid var(--success)',
            color: 'var(--text)',
            fontSize: '0.95rem',
          }}
        >
          <strong>Berhasil: </strong>
          {pesanSukses}
        </div>
      )}

      {/* Grid Formulir dan Pratinjau */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '1.5rem',
          alignItems: 'start',
        }}
      >
        {/* Kolom 1: Formulir Identitas */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <Kartu judul="Informasi Merek Resto">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <KolomIsian
                label="Nama Restoran"
                nilai={namaResto}
                onUbah={setNamaResto}
                wajib
                nonaktif={hanyaBaca || sedangMemuat}
                keterangan="Nama resmi yang tampil di banner, struk belanja, dan tab peramban."
                contoh="Contoh: Kedai Oasis Barokah"
              />

              <KolomIsian
                label="Slogan / Tagline"
                nilai={tagline}
                onUbah={setTagline}
                nonaktif={hanyaBaca || sedangMemuat}
                keterangan="Kalimat pemikat singkat di bawah nama restoran pada katalog publik."
                contoh="Contoh: Kuliner Tradisi Hangat & Halal"
              />

              <KolomIsian
                label="Jam Operasional"
                nilai={jamBuka}
                onUbah={setJamBuka}
                nonaktif={hanyaBaca || sedangMemuat}
                keterangan="Jadwal buka kedai yang dibaca pelanggan di beranda katalog."
                contoh="Contoh: Setiap Hari: 08.00 - 22.00 WIB"
              />
            </div>
          </Kartu>

          <Kartu judul="Logo Restoran">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <p
                className="teks-lemah"
                style={{ margin: 0, fontSize: '0.875rem', color: 'var(--muted)' }}
              >
                Logo berformat JPG, PNG, atau WebP (maksimal 2 MB). Diperkecil otomatis ke 400x400
                px.
              </p>

              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div
                  style={{
                    width: '72px',
                    height: '72px',
                    borderRadius: 'var(--radius-md)',
                    border: '1px dashed var(--border)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    overflow: 'hidden',
                    backgroundColor: 'var(--surface-2)',
                  }}
                >
                  {logoUrl ? (
                    <img
                      src={logoUrl}
                      alt="Pratinjau Logo"
                      style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                      data-testid="img-pratinjau-logo"
                    />
                  ) : (
                    <span style={{ fontSize: '1.75rem', color: 'var(--muted)' }}>🏪</span>
                  )}
                </div>

                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  <input
                    ref={refInputLogo}
                    type="file"
                    accept="image/png,image/jpeg,image/webp"
                    style={{ display: 'none' }}
                    onChange={tanganiPilihLogo}
                    data-testid="input-berkas-logo"
                    disabled={hanyaBaca || sedangMemuat}
                  />
                  <Tombol
                    ragam="biasa"
                    onClick={() => refInputLogo.current?.click()}
                    nonaktif={hanyaBaca || sedangMemuat}
                    nama="Pilih berkas gambar logo"
                  >
                    Unggah Logo
                  </Tombol>
                  {logoUrl && (
                    <Tombol
                      ragam="bahaya"
                      onClick={() => setLogoUrl('')}
                      nonaktif={hanyaBaca || sedangMemuat}
                      nama="Hapus logo yang terpasang"
                    >
                      Hapus
                    </Tombol>
                  )}
                </div>
              </div>
            </div>
          </Kartu>

          <Kartu judul="Banner Halaman Depan">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <p
                className="teks-lemah"
                style={{ margin: 0, fontSize: '0.875rem', color: 'var(--muted)' }}
              >
                Banner utama katalog pelanggan (rasio 2:1, maksimal 3 MB, diperkecil otomatis ke
                1200x600 px).
              </p>

              <div
                style={{
                  width: '100%',
                  height: '140px',
                  borderRadius: 'var(--radius-md)',
                  border: '1px dashed var(--border)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  overflow: 'hidden',
                  backgroundColor: 'var(--surface-2)',
                  position: 'relative',
                }}
              >
                {bannerUrl ? (
                  <img
                    src={bannerUrl}
                    alt="Pratinjau Banner"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    data-testid="img-pratinjau-banner"
                  />
                ) : (
                  <div style={{ textAlign: 'center', color: 'var(--muted)' }}>
                    <div style={{ fontSize: '2rem' }}>🖼️</div>
                    <div style={{ fontSize: '0.875rem' }}>Belum ada gambar banner</div>
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <input
                  ref={refInputBanner}
                  type="file"
                  accept="image/png,image/jpeg,image/webp"
                  style={{ display: 'none' }}
                  onChange={tanganiPilihBanner}
                  data-testid="input-berkas-banner"
                  disabled={hanyaBaca || sedangMemuat}
                />
                <Tombol
                  ragam="biasa"
                  onClick={() => refInputBanner.current?.click()}
                  nonaktif={hanyaBaca || sedangMemuat}
                  nama="Pilih berkas gambar banner"
                >
                  Unggah Banner
                </Tombol>
                {bannerUrl && (
                  <Tombol
                    ragam="bahaya"
                    onClick={() => setBannerUrl('')}
                    nonaktif={hanyaBaca || sedangMemuat}
                    nama="Hapus banner yang terpasang"
                  >
                    Hapus
                  </Tombol>
                )}
              </div>
            </div>
          </Kartu>
        </div>

        {/* Kolom 2: Pratinjau Langsung */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <Kartu judul="Pratinjau Langsung (Live Preview)">
            <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
              <Tombol
                ragam={tabPratinjau === 'katalog' ? 'utama' : 'biasa'}
                onClick={() => setTabPratinjau('katalog')}
                nama="Beralih ke pratinjau katalog"
              >
                Tampilan Katalog
              </Tombol>
              <Tombol
                ragam={tabPratinjau === 'struk' ? 'utama' : 'biasa'}
                onClick={() => setTabPratinjau('struk')}
                nama="Beralih ke pratinjau cetak struk"
              >
                Tampilan Struk
              </Tombol>
            </div>

            {tabPratinjau === 'katalog' ? (
              <div
                data-testid="wadah-pratinjau-katalog"
                style={{
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-lg, 12px)',
                  overflow: 'hidden',
                  backgroundColor: 'var(--surface)',
                }}
              >
                {/* Banner Katalog */}
                <div
                  style={{
                    height: '120px',
                    backgroundColor: 'var(--surface-2)',
                    backgroundImage: bannerUrl ? `url(${bannerUrl})` : 'none',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    position: 'relative',
                  }}
                >
                  <div style={{ position: 'absolute', bottom: '8px', right: '8px' }}>
                    <Lencana nada="success">Katalog Publik</Lencana>
                  </div>
                </div>

                {/* Info Resto */}
                <div style={{ padding: '1rem' }}>
                  <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                    <div
                      style={{
                        width: '52px',
                        height: '52px',
                        borderRadius: '50%',
                        overflow: 'hidden',
                        backgroundColor: 'var(--surface-2)',
                        border: '2px solid var(--surface)',
                        boxShadow: 'var(--bayangan-1)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                      }}
                    >
                      {logoUrl ? (
                        <img
                          src={logoUrl}
                          alt="Logo Preview"
                          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                        />
                      ) : (
                        <span>🏪</span>
                      )}
                    </div>
                    <div>
                      <h3
                        style={{ margin: 0, fontSize: '1.15rem', fontWeight: 700 }}
                        data-testid="teks-nama-pratinjau"
                      >
                        {namaResto || 'Nama Resto'}
                      </h3>
                      <p
                        className="teks-lemah"
                        style={{ margin: 0, fontSize: '0.875rem', color: 'var(--muted)' }}
                        data-testid="teks-tagline-pratinjau"
                      >
                        {tagline || 'Slogan restoran'}
                      </p>
                    </div>
                  </div>

                  <div
                    style={{
                      marginTop: '0.75rem',
                      padding: '0.5rem 0.75rem',
                      borderRadius: 'var(--radius-md, 6px)',
                      backgroundColor: 'var(--surface-2)',
                      fontSize: '0.8rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                    }}
                  >
                    <span>🕒</span>
                    <span data-testid="teks-jam-pratinjau">
                      {jamBuka || 'Jam operasional belum diatur'}
                    </span>
                  </div>
                </div>
              </div>
            ) : (
              <div
                data-testid="wadah-pratinjau-struk"
                style={{
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md, 8px)',
                  padding: '1.25rem',
                  backgroundColor: 'var(--surface)',
                  fontFamily: 'monospace',
                  fontSize: '0.85rem',
                  maxWidth: '280px',
                  margin: '0 auto',
                  boxShadow: 'var(--bayangan-1)',
                }}
              >
                <div style={{ textAlign: 'center', marginBottom: '0.75rem' }}>
                  {logoUrl && (
                    <div style={{ width: '36px', height: '36px', margin: '0 auto 4px auto' }}>
                      <img
                        src={logoUrl}
                        alt="Logo Struk"
                        style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                      />
                    </div>
                  )}
                  <div
                    style={{ fontWeight: 'bold', fontSize: '1rem' }}
                    data-testid="struk-nama-resto"
                  >
                    {namaResto.toUpperCase() || 'RESTO BAROKAH'}
                  </div>
                  <div
                    style={{ fontSize: '0.75rem', color: 'var(--muted)' }}
                    data-testid="struk-tagline"
                  >
                    {tagline}
                  </div>
                  <div style={{ fontSize: '0.75rem', margin: '4px 0' }}>
                    --------------------------------
                  </div>
                  <div style={{ fontSize: '0.75rem', textAlign: 'left' }}>
                    <div>Nomor: POS-2609-001</div>
                    <div>Kasir: Rina (POS 1)</div>
                    <div>Waktu: 26/09/2026 12:30</div>
                  </div>
                  <div style={{ fontSize: '0.75rem', margin: '4px 0' }}>
                    --------------------------------
                  </div>
                  <div style={{ fontSize: '0.75rem', textAlign: 'left' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>1x Nasi Goreng Oasis</span>
                      <span>25.000</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                      <span>1x Es Teh Manis</span>
                      <span>8.000</span>
                    </div>
                  </div>
                  <div style={{ fontSize: '0.75rem', margin: '4px 0' }}>
                    --------------------------------
                  </div>
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      fontWeight: 'bold',
                      fontSize: '0.85rem',
                    }}
                  >
                    <span>TOTAL</span>
                    <span>Rp 33.000</span>
                  </div>
                  <div
                    style={{ fontSize: '0.75rem', margin: '8px 0 4px 0', color: 'var(--muted)' }}
                  >
                    Terima kasih atas kunjungan Anda!
                  </div>
                </div>
              </div>
            )}
          </Kartu>
        </div>
      </div>
    </div>
  )
}
