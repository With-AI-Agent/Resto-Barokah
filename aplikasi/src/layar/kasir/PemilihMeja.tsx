import { useState } from 'react'
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
  const [tipe, setTipe] = useState<TipePesanan>(tipePesanan)
  const [mejaDipilih, setMejaDipilih] = useState<string>(mejaTerpilihId)
  const [catatan, setCatatan] = useState<string>(catatanPesanan)
  const [modePindahMeja, setModePindahMeja] = useState(false)
  const [sedangPindah, setSedangPindah] = useState(false)
  const [pesanInfo, setPesanInfo] = useState<string | null>(null)

  const tanganiPilihTipe = (t: TipePesanan) => {
    setTipe(t)
    onPilihTipe(t)
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
    <div className="pemilih-meja space-y-4 max-w-2xl mx-auto p-4 bg-white rounded-2xl border border-neutral-200">
      {/* Header & Pilihan Tipe Pesanan */}
      <div>
        <div className="font-bold text-lg text-neutral-800 mb-2">Tipe Pesanan & Meja</div>
        <div className="grid grid-cols-3 gap-2">
          <Tombol
            ragam={tipe === 'dinein' ? 'utama' : 'biasa'}
            onClick={() => tanganiPilihTipe('dinein')}
          >
            🍽️ Makan di Tempat (Dine In)
          </Tombol>

          <Tombol
            ragam={tipe === 'takeaway' ? 'utama' : 'biasa'}
            onClick={() => tanganiPilihTipe('takeaway')}
          >
            🥡 Bawa Pulang (Takeaway)
          </Tombol>

          <Tombol
            ragam={tipe === 'ojol' ? 'utama' : 'biasa'}
            onClick={() => tanganiPilihTipe('ojol')}
          >
            🛵 Ojek Online (GoFood/Grab)
          </Tombol>
        </div>
      </div>

      {pesanInfo && (
        <div
          role="status"
          className="p-3 bg-emerald-50 border border-emerald-200 rounded-lg text-xs text-emerald-800"
        >
          {pesanInfo}
        </div>
      )}

      {/* Grid Meja untuk Makan di Tempat */}
      {tipe === 'dinein' && (
        <div className="space-y-3 pt-2 border-t border-neutral-200">
          <div className="flex items-center justify-between">
            <div className="text-sm font-bold text-neutral-700">
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

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 max-h-56 overflow-y-auto">
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
                  className={`p-3 rounded-xl border text-left transition-all cursor-pointer flex flex-col justify-between select-none ${
                    aktifDipilih
                      ? 'border-emerald-600 bg-emerald-50 shadow-sm ring-2 ring-emerald-500'
                      : 'border-neutral-200 bg-white hover:bg-neutral-50'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-bold text-sm text-neutral-800">{meja.nama}</span>
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
                        ? 'Kosong'
                        : meja.status === 'terisi'
                          ? 'Terisi'
                          : 'Siap'}
                    </Lencana>
                  </div>

                  <div className="text-[11px] text-neutral-500">
                    {meja.area || 'Indoor'}
                    {meja.jumlahTamu ? ` • ${meja.jumlahTamu} Tamu` : ''}
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Catatan Khusus Cepat untuk Seluruh Pesanan */}
      <div className="pt-2 border-t border-neutral-200 space-y-2">
        <label className="block text-xs font-bold text-neutral-700 uppercase tracking-wider">
          Catatan Khusus Pesanan (Cepat)
        </label>
        <div className="flex flex-wrap gap-1.5">
          {CATATAN_CEPAT.map((tag) => (
            <Tombol key={tag} ragam="kecil" onClick={() => tambahCatatanCepat(tag)}>
              + {tag}
            </Tombol>
          ))}
        </div>

        <KolomIsian
          label="Catatan Tambahan untuk Dapur"
          contoh="Mis. Meja 01 mau makanan diantar bersamaan, sambal dipisah"
          nilai={catatan}
          onUbah={(v) => {
            setCatatan(v)
            onSimpanCatatanPesanan?.(v)
          }}
        />
      </div>

      {onTutup && (
        <div className="flex justify-end pt-2 border-t border-neutral-200">
          <Tombol ragam="utama" onClick={onTutup}>
            Selesai & Lanjutkan
          </Tombol>
        </div>
      )}
    </div>
  )
}
