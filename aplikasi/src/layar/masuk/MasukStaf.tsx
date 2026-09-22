import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Lencana } from '../../komponen/Lencana'
import { formatPesanError } from '../../lib/pesan'
import { useBahasa } from '../../bahasa'
import type { PeranPengguna } from '../../lib/auth'

export interface ProfilStafPerangkat {
  id: string
  nama: string
  email: string
  peran: PeranPengguna
  fotoUrl?: string
}

export interface MasukStafProps {
  daftarStaf?: ProfilStafPerangkat[]
  namaPerangkat?: string
  perangkatTerdaftar?: boolean
  onVerifikasiPin: (email: string, pin: string) => Promise<{ sukses: boolean; kodeGalat?: string; sisaPercobaan?: number }>
  onMintaBantuanAdmin?: () => void
  onMasukSukses?: (staf: ProfilStafPerangkat) => void
}

const DAFTAR_STAF_CONTOH: ProfilStafPerangkat[] = [
  { id: 'usr-01', nama: 'Budi Santoso', email: 'budi@barokah.id', peran: 'kasir' },
  { id: 'usr-02', nama: 'Siti Rahma', email: 'siti@barokah.id', peran: 'kasir' },
  { id: 'usr-03', nama: 'Agus Setiawan', email: 'agus@barokah.id', peran: 'pelayan' },
  { id: 'usr-04', nama: 'Dewi Lestari', email: 'dewi@barokah.id', peran: 'pelayan' },
  { id: 'usr-05', nama: 'Chef Rudi', email: 'rudi@barokah.id', peran: 'dapur' },
]

export function MasukStaf({
  daftarStaf = DAFTAR_STAF_CONTOH,
  namaPerangkat = 'POS Kasir Utama #1',
  perangkatTerdaftar = true,
  onVerifikasiPin,
  onMintaBantuanAdmin,
  onMasukSukses,
}: MasukStafProps) {
  const { t } = useBahasa()
  const [stafTerpilih, setStafTerpilih] = useState<ProfilStafPerangkat | null>(null)
  const [pin, setPin] = useState<string>('')
  const [sedangMemproses, setSedangMemproses] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<{ judul: string; pesan: string; tindakan: string; kode: string } | null>(null)
  const [sisaPercobaan, setSisaPercobaan] = useState<number | null>(null)

  const tekanAngka = (angka: string) => {
    if (pin.length < 6 && !sedangMemproses) {
      const pinBaru = pin + angka
      setPin(pinBaru)
      setPesanGalat(null)
      if (pinBaru.length === 6 && stafTerpilih) {
        prosesMasuk(stafTerpilih, pinBaru)
      }
    }
  }

  const hapusAngka = () => {
    if (!sedangMemproses && pin.length > 0) {
      setPin(pin.slice(0, -1))
      setPesanGalat(null)
    }
  }

  const resetPin = () => {
    setPin('')
    setPesanGalat(null)
  }

  const prosesMasuk = async (staf: ProfilStafPerangkat, pinInput: string) => {
    if (!perangkatTerdaftar) {
      setPesanGalat(
        formatPesanError('PERANGKAT_BELUM_TERDAFTAR')
      )
      return
    }

    setSedangMemproses(true)
    try {
      const hasil = await onVerifikasiPin(staf.email, pinInput)
      if (hasil.sukses) {
        onMasukSukses?.(staf)
      } else {
        const galat = formatPesanError(hasil.kodeGalat ?? 'PIN_SALAH')
        setPesanGalat(galat)
        setPin('')
        if (hasil.sisaPercobaan !== undefined) {
          setSisaPercobaan(hasil.sisaPercobaan)
        }
      }
    } catch {
      setPesanGalat(
        formatPesanError('JARINGAN_TERPUTUS')
      )
      setPin('')
    } finally {
      setSedangMemproses(false)
    }
  }

  return (
    <div className="layar-masuk-staf max-w-4xl mx-auto p-4 flex flex-col md:flex-row gap-6 items-start justify-center min-h-[70vh]">
      {/* Kolom 1: Informasi Perangkat & Pilih Staf */}
      <div className="w-full md:w-1/2 flex flex-col gap-4">
        <Kartu judul={t('app.nama') || 'Resto Barokah'}>
          <div className="flex items-center justify-between border-b pb-3 mb-3 border-neutral-200">
            <div>
              <div className="text-xs text-neutral-500">Perangkat Aktif</div>
              <div className="font-semibold text-neutral-800">{namaPerangkat}</div>
            </div>
            <Lencana nada={perangkatTerdaftar ? 'success' : 'danger'}>
              {perangkatTerdaftar ? 'Terdaftar Resmi' : 'Belum Terdaftar'}
            </Lencana>
          </div>

          {!perangkatTerdaftar && (
            <div
              role="alert"
              className="p-3 bg-red-50 text-red-800 rounded border border-red-200 text-sm mb-4"
            >
              <div className="font-semibold mb-1">Perangkat Belum Terdaftar (PRG-404)</div>
              <div>Perangkat ini belum disetujui oleh Owner / Admin. Hubungi pengelola resto untuk mendaftarkan tablet ini.</div>
            </div>
          )}

          <div className="mb-2 font-medium text-neutral-700">Pilih Nama Pegawai:</div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-72 overflow-y-auto">
            {daftarStaf.map((staf) => {
              const aktif = stafTerpilih?.id === staf.id
              return (
                <button
                  key={staf.id}
                  type="button"
                  onClick={() => {
                    setStafTerpilih(staf)
                    resetPin()
                  }}
                  className={`p-3 rounded-lg border text-left transition-all flex flex-col gap-1 ${
                    aktif
                      ? 'border-emerald-600 bg-emerald-50 text-emerald-900 shadow-sm ring-2 ring-emerald-500'
                      : 'border-neutral-200 bg-white hover:bg-neutral-50 text-neutral-800'
                  }`}
                >
                  <div className="font-semibold text-base">{staf.nama}</div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-neutral-500">{staf.email}</span>
                    <Lencana nada="netral">{staf.peran.toUpperCase()}</Lencana>
                  </div>
                </button>
              )
            })}
          </div>
        </Kartu>

        {onMintaBantuanAdmin && (
          <div className="text-center">
            <button
              type="button"
              onClick={onMintaBantuanAdmin}
              className="text-sm text-neutral-600 hover:text-neutral-900 underline"
            >
              Lupa PIN atau butuh bantuan Admin?
            </button>
          </div>
        )}
      </div>

      {/* Kolom 2: Keypad PIN Masuk */}
      <div className="w-full md:w-1/2">
        <Kartu judul={stafTerpilih ? `PIN Masuk: ${stafTerpilih.nama}` : 'Masukkan PIN 6 Digit'}>
          {stafTerpilih ? (
            <div className="flex flex-col items-center gap-4">
              {/* Indikator PIN Bulat */}
              <div className="flex justify-center gap-3 py-2" aria-label="Indikator PIN">
                {[0, 1, 2, 3, 4, 5].map((index) => {
                  const terisi = index < pin.length
                  return (
                    <div
                      key={index}
                      className={`w-4 h-4 rounded-full border transition-all ${
                        terisi
                          ? 'bg-emerald-600 border-emerald-600 scale-110 shadow-sm'
                          : 'bg-neutral-100 border-neutral-300'
                      }`}
                    />
                  )
                })}
              </div>

              {pesanGalat && (
                <div
                  role="alert"
                  className="w-full p-3 bg-red-50 text-red-800 rounded border border-red-200 text-sm"
                >
                  <div className="font-semibold mb-0.5">{pesanGalat.judul}</div>
                  <div className="text-xs text-red-600 mb-1">{pesanGalat.pesan}</div>
                  <div className="text-xs text-neutral-600 mb-1">{pesanGalat.tindakan}</div>
                  <div className="text-[11px] font-mono text-neutral-500">Kode: {pesanGalat.kode}</div>
                  {sisaPercobaan !== null && sisaPercobaan < 5 && (
                    <div className="text-xs font-semibold mt-1 text-amber-700">
                      Sisa percobaan: {sisaPercobaan}x sebelum terkunci
                    </div>
                  )}
                </div>
              )}

              {/* Keypad Angka 3x4 */}
              <div className="grid grid-cols-3 gap-3 w-full max-w-xs">
                {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((angka) => (
                  <button
                    key={angka}
                    type="button"
                    disabled={sedangMemproses}
                    onClick={() => tekanAngka(angka)}
                    className="h-14 text-xl font-bold bg-neutral-50 hover:bg-neutral-100 active:bg-neutral-200 rounded-lg border border-neutral-200 text-neutral-800 shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  >
                    {angka}
                  </button>
                ))}

                <button
                  type="button"
                  disabled={sedangMemproses || pin.length === 0}
                  onClick={resetPin}
                  className="h-14 text-sm font-semibold bg-neutral-100 hover:bg-neutral-200 rounded-lg border border-neutral-200 text-neutral-700 transition-all focus:outline-none"
                >
                  Reset
                </button>

                <button
                  type="button"
                  disabled={sedangMemproses}
                  onClick={() => tekanAngka('0')}
                  className="h-14 text-xl font-bold bg-neutral-50 hover:bg-neutral-100 active:bg-neutral-200 rounded-lg border border-neutral-200 text-neutral-800 shadow-sm transition-all focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  0
                </button>

                <button
                  type="button"
                  disabled={sedangMemproses || pin.length === 0}
                  onClick={hapusAngka}
                  aria-label="Hapus satu angka"
                  className="h-14 flex items-center justify-center bg-neutral-100 hover:bg-neutral-200 rounded-lg border border-neutral-200 text-neutral-700 transition-all focus:outline-none"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    aria-hidden="true"
                  >
                    <path d="M21 4H8l-7 8 7 8h13a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2z"></path>
                    <line x1="18" y1="9" x2="12" y2="15"></line>
                    <line x1="12" y1="9" x2="18" y2="15"></line>
                  </svg>
                </button>
              </div>

              {sedangMemproses && (
                <div className="text-sm text-neutral-500 animate-pulse">Memverifikasi PIN...</div>
              )}
            </div>
          ) : (
            <div className="text-center py-12 text-neutral-500">
              <svg
                className="w-12 h-12 mx-auto mb-3 text-neutral-400"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="1.5"
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                />
              </svg>
              <div className="font-medium text-neutral-700 mb-1">Silakan pilih nama Anda</div>
              <div className="text-xs text-neutral-500">Pilih dari daftar di sebelah kiri untuk membuka keypad PIN</div>
            </div>
          )}
        </Kartu>
      </div>
    </div>
  )
}
