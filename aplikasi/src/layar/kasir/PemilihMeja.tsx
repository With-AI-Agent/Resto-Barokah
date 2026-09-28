import { useState } from 'react'
import { useBahasa } from '../../bahasa'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KolomIsian } from '../../komponen/KolomIsian'

export interface MejaData {
  id: string
  nama: string
  area?: string
  status: 'kosong' | 'terisi' | 'siap'
  aktif: boolean
  jumlahTamu?: number
}

export type TipePesanan = 'dinein' | 'takeaway' | 'ojol'

export interface PemilihMejaProps {
  daftarMeja?: MejaData[]
  mejaTerpilihId?: string
  tipePesanan?: TipePesanan
  catatanPesanan?: string
  onPilihTipe: (tipe: TipePesanan) => void
  onPilihMeja: (meja: MejaData) => void
  onPindahMeja?: (
    mejaAsalId: string,
    mejaTujuanId: string,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onSimpanCatatanPesanan?: (catatan: string) => void
  onTutup?: () => void
}

const CONTOH_MEJA: MejaData[] = [
  { id: 'meja-01', nama: 'Meja 01', area: 'Indoor AC', status: 'kosong', aktif: true },
  {
    id: 'meja-02',
    nama: 'Meja 02',
    area: 'Indoor AC',
    status: 'terisi',
    aktif: true,
    jumlahTamu: 3,
  },
  { id: 'meja-03', nama: 'Meja 03', area: 'Indoor AC', status: 'siap', aktif: true },
  { id: 'meja-04', nama: 'Meja 04', area: 'Indoor AC', status: 'kosong', aktif: true },
  {
    id: 'meja-05',
    nama: 'Meja 05 (Outdoor)',
    area: 'Outdoor Merokok',
    status: 'kosong',
    aktif: true,
  },
  {
    id: 'meja-06',
    nama: 'Meja 06 (Outdoor)',
    area: 'Outdoor Merokok',
    status: 'terisi',
    aktif: true,
    jumlahTamu: 4,
  },
  { id: 'meja-07', nama: 'Meja VIP 1', area: 'Ruang VIP', status: 'kosong', aktif: true },
  { id: 'meja-08', nama: 'Meja VIP 2', area: 'Ruang VIP', status: 'siap', aktif: true },
]

const CATATAN_CEPAT = [
  'Tanpa Es',
  'Kurang Pedas',
  'Sangat Pedas',
  'Pisah Kuah / Sambal',
  'Jangan Pakai MSG / Mecin',
  'Bungkus Rapi',
  'Sendok Garpu Plastik',
]

export function PemilihMeja({
  daftarMeja = CONTOH_MEJA,
  mejaTerpilihId = 'meja-01',
  tipePesanan = 'dinein',
  catatanPesanan = '',
  onPilihTipe,
  onPilihMeja,
  onPindahMeja,
  onSimpanCatatanPesanan,
  onTutup,
}: PemilihMejaProps) {
  const { t } = useBahasa()
  const [tipe, setTipe] = useState<TipePesanan>(tipePesanan)
  const [mejaDipilih, setMejaDipilih] = useState<string>(mejaTerpilihId)
  const [catatan, setCatatan] = useState<string>(catatanPesanan)
  const [modePindahMeja, setModePindahMeja] = useState(false)
  const [sedangPindah, setSedangPindah] = useState(false)
  const [pesanInfo, setPesanInfo] = useState<string | null>(null)

  const tanganiPilihTipe = (tipeInput: TipePesanan) => {
    setTipe(tipeInput)
    onPilihTipe(tipeInput)
  }

  const tanganiPilihMeja = (meja: MejaData) => {
    if (modePindahMeja) {
      if (meja.id === mejaDipilih) return
      prosesPindahMeja(meja.id)
      return
    }

    setMejaDipilih(meja.id)
    onPilihMeja(meja)
  }

  const prosesPindahMeja = async (mejaTujuanId: string) => {
    if (!onPindahMeja) return
    setSedangPindah(true)
    setPesanInfo(null)
    try {
      const res = await onPindahMeja(mejaDipilih, mejaTujuanId)
      if (res.sukses) {
        setMejaDipilih(mejaTujuanId)
        setModePindahMeja(false)
        setPesanInfo('Pesanan berhasil dipindahkan ke meja baru.')
      } else {
        setPesanInfo(res.pesan || 'Gagal memindahkan meja.')
      }
    } catch {
      setPesanInfo('Terjadi kendala jaringan saat memindahkan meja.')
    } finally {
      setSedangPindah(false)
    }
  }

  const tambahCatatanCepat = (teks: string) => {
    if (catatan.includes(teks)) return
    const baru = catatan ? `${catatan}, ${teks}` : teks
    setCatatan(baru)
    onSimpanCatatanPesanan?.(baru)
  }

  return (
    <div className="pemilih-meja">
      {/* Header & Pilihan Tipe Pesanan */}
      <div>
        <div
          style={{
            fontWeight: 800,
            fontSize: 'var(--t-4)',
            color: 'var(--text)',
            marginBottom: 'var(--s-2)',
          }}
        >
          {t('kasir.pilih_meja_judul')}
        </div>
        <div className="tipe-pesanan-grid">
          <div
            role="button"
            tabIndex={0}
            className={`tipe-pesanan-btn ${tipe === 'dinein' ? 'tipe-pesanan-btn--aktif' : ''}`}
            onClick={() => tanganiPilihTipe('dinein')}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault()
                tanganiPilihTipe('dinein')
              }
            }}
          >
            <span style={{ fontSize: '20px' }}>🍽️</span>
            <span>{t('kasir.tipe_dinein')}</span>
          </div>

          <div
            role="button"
            tabIndex={0}
            className={`tipe-pesanan-btn ${tipe === 'takeaway' ? 'tipe-pesanan-btn--aktif' : ''}`}
            onClick={() => tanganiPilihTipe('takeaway')}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault()
                tanganiPilihTipe('takeaway')
              }
            }}
          >
            <span style={{ fontSize: '20px' }}>🥡</span>
            <span>{t('kasir.tipe_takeaway')}</span>
          </div>

          <div
            role="button"
            tabIndex={0}
            className={`tipe-pesanan-btn ${tipe === 'ojol' ? 'tipe-pesanan-btn--aktif' : ''}`}
            onClick={() => tanganiPilihTipe('ojol')}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault()
                tanganiPilihTipe('ojol')
              }
            }}
          >
            <span style={{ fontSize: '20px' }}>🛵</span>
            <span>{t('kasir.tipe_ojol')}</span>
          </div>
        </div>
      </div>

      {pesanInfo && (
        <div
          role="status"
          style={{
            padding: 'var(--s-3)',
            background: 'var(--accent-soft)',
            border: '1px solid var(--accent)',
            borderRadius: 'var(--radius-sm)',
            fontSize: 'var(--t-2)',
            color: 'var(--accent)',
          }}
        >
          {pesanInfo}
        </div>
      )}

      {/* Grid Meja untuk Makan di Tempat */}
      {tipe === 'dinein' && (
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
            paddingTop: 'var(--s-2)',
            borderTop: '1px solid var(--border)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ fontSize: 'var(--t-3)', fontWeight: 700, color: 'var(--text)' }}>
              {modePindahMeja ? '👉 Pilih Meja Tujuan Pindah:' : 'Pilih Meja Resto:'}
            </div>

            {onPindahMeja && (
              <Tombol
                ragam={modePindahMeja ? 'bahaya' : 'kecil'}
                onClick={() => setModePindahMeja(!modePindahMeja)}
                nonaktif={sedangPindah}
              >
                {modePindahMeja ? 'Batal Pindah' : '⇄ Pindah Meja'}
              </Tombol>
            )}
          </div>

          <div className="meja-grid" style={{ maxHeight: '240px', overflowY: 'auto' }}>
            {daftarMeja.map((meja) => {
              const aktifDipilih = mejaDipilih === meja.id
              return (
                <div
                  key={meja.id}
                  role="button"
                  tabIndex={0}
                  onClick={() => tanganiPilihMeja(meja)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault()
                      tanganiPilihMeja(meja)
                    }
                  }}
                  className={`meja-kartu ${aktifDipilih ? 'meja-kartu--terpilih' : ''}`}
                >
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      gap: 'var(--s-1)',
                    }}
                  >
                    <span className="meja-kartu__nama">{meja.nama}</span>
                    <Lencana
                      nada={
                        meja.status === 'kosong'
                          ? 'success'
                          : meja.status === 'terisi'
                            ? 'danger'
                            : 'warn'
                      }
                    >
                      {meja.status === 'kosong'
                        ? t('kasir.meja_kosong')
                        : meja.status === 'terisi'
                          ? t('kasir.meja_terisi')
                          : t('kasir.meja_siap')}
                    </Lencana>
                  </div>

                  <div className="meja-kartu__lokasi">
                    {meja.area || 'Indoor'}
                    {meja.jumlahTamu ? ` • ${meja.jumlahTamu} ${t('kasir.tamu')}` : ''}
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Catatan Khusus Cepat untuk Seluruh Pesanan */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--s-2)',
          paddingTop: 'var(--s-2)',
          borderTop: '1px solid var(--border)',
        }}
      >
        <label
          style={{
            fontSize: 'var(--t-1)',
            fontWeight: 700,
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            color: 'var(--text-muted)',
          }}
        >
          {t('kasir.catatan_khusus')}
        </label>
        <div className="chips-baris">
          {CATATAN_CEPAT.map((tag) => (
            <Tombol key={tag} ragam="kecil" onClick={() => tambahCatatanCepat(tag)}>
              + {tag}
            </Tombol>
          ))}
        </div>

        <KolomIsian
          label={t('kasir.catatan_dapur')}
          contoh="Mis. Meja 01 mau makanan diantar bersamaan, sambal dipisah"
          nilai={catatan}
          onUbah={(v) => {
            setCatatan(v)
            onSimpanCatatanPesanan?.(v)
          }}
        />
      </div>

      {onTutup && (
        <div
          style={{
            display: 'flex',
            justifyContent: 'flex-end',
            paddingTop: 'var(--s-2)',
            borderTop: '1px solid var(--border)',
          }}
        >
          <Tombol ragam="utama" onClick={onTutup}>
            {t('kasir.selesai_lanjutkan')}
          </Tombol>
        </div>
      )}
    </div>
  )
}
