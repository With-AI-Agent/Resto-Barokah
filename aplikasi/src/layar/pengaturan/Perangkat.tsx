import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { formatPesanError } from '../../lib/pesan'
import type { PeranPengguna } from '../../lib/auth'

export interface KodePendaftaranPerangkat {
  kode: string
  cabangId: string
  peranDiizinkan: PeranPengguna[]
  kedaluwarsaPada: string
}

export interface PegawaiMenungguPersetujuan {
  penggunaId: string
  nama: string
  peran: PeranPengguna
  perangkatId: string
  namaPerangkat: string
}

export interface LayarPerangkatProps {
  cabangId: string
  peranUser: PeranPengguna
  daftarPersetujuan?: PegawaiMenungguPersetujuan[]
  onBuatKode: (
    cabangId: string,
    peran: PeranPengguna[],
  ) => Promise<{ kode: string; kedaluwarsaPada: string }>
  onDaftarkanPerangkat: (
    kode: string,
    namaPerangkat: string,
  ) => Promise<{ sukses: boolean; perangkatId?: string; pesan?: string }>
  onSetujuiPegawai: (
    penggunaId: string,
    perangkatId: string,
  ) => Promise<{ sukses: boolean; pesan?: string }>
}

export function LayarPerangkat({
  cabangId,
  peranUser,
  daftarPersetujuan = [],
  onBuatKode,
  onDaftarkanPerangkat,
  onSetujuiPegawai,
}: LayarPerangkatProps) {
  const [kodeDibuat, setKodeDibuat] = useState<KodePendaftaranPerangkat | null>(null)
  const [peranTerpilih, setPeranTerpilih] = useState<PeranPengguna[]>(['kasir', 'pelayan'])
  const [sedangMembuatKode, setSedangMembuatKode] = useState(false)

  const [inputKode, setInputKode] = useState('')
  const [inputNamaPerangkat, setInputNamaPerangkat] = useState('')
  const [sedangDaftar, setSedangDaftar] = useState(false)
  const [pesanHasilDaftar, setPesanHasilDaftar] = useState<{
    sukses: boolean
    teks: string
  } | null>(null)

  const [daftarTunggu, setDaftarTunggu] = useState<PegawaiMenungguPersetujuan[]>(daftarPersetujuan)

  const berhakBuatKode =
    peranUser === 'owner_pusat' || peranUser === 'admin_cabang' || peranUser === 'pemilik_platform'

  const tanganiBuatKode = async () => {
    setSedangMembuatKode(true)
    try {
      const hasil = await onBuatKode(cabangId, peranTerpilih)
      setKodeDibuat({
        kode: hasil.kode,
        cabangId,
        peranDiizinkan: peranTerpilih,
        kedaluwarsaPada: hasil.kedaluwarsaPada,
      })
    } catch {
      alert('Gagal membuat kode pendaftaran. Pastikan Anda memiliki izin kelola_pegawai.')
    } finally {
      setSedangMembuatKode(false)
    }
  }

  const tanganiDaftarPerangkat = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!inputKode.trim() || !inputNamaPerangkat.trim()) return

    setSedangDaftar(true)
    setPesanHasilDaftar(null)
    try {
      const hasil = await onDaftarkanPerangkat(inputKode.trim(), inputNamaPerangkat.trim())
      if (hasil.sukses) {
        setPesanHasilDaftar({
          sukses: true,
          teks: 'Perangkat berhasil didaftarkan! Tunggu persetujuan owner untuk mengaktifkan staf.',
        })
        setInputKode('')
        setInputNamaPerangkat('')
      } else {
        const galat = formatPesanError(hasil.pesan ?? 'KODE_TIDAK_VALID')
        setPesanHasilDaftar({
          sukses: false,
          teks: `${galat.judul}: ${galat.pesan} (${galat.kode})`,
        })
      }
    } catch {
      setPesanHasilDaftar({
        sukses: false,
        teks: 'Gagal menghubungi peladen saat mendaftarkan perangkat.',
      })
    } finally {
      setSedangDaftar(false)
    }
  }

  const tanganiSetujui = async (penggunaId: string, perangkatId: string) => {
    try {
      const hasil = await onSetujuiPegawai(penggunaId, perangkatId)
      if (hasil.sukses) {
        setDaftarTunggu((prev) =>
          prev.filter((p) => !(p.penggunaId === penggunaId && p.perangkatId === perangkatId)),
        )
      }
    } catch {
      alert('Gagal menyetujui pegawai pada perangkat.')
    }
  }

  return (
    <div className="layar-perangkat space-y-6 max-w-5xl mx-auto p-4">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">
            Pendaftaran & Persetujuan Perangkat
          </h2>
          <p className="text-sm text-neutral-500">
            Kelola tablet kasir, printer, dan persetujuan staf untuk bekerja di perangkat resmi.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Kolom Buat Kode (Hanya Pengelola) */}
        {berhakBuatKode ? (
          <Kartu judul="Buat Kode Pendaftaran Baru">
            <p className="text-sm text-neutral-600 mb-4">
              Kode 6-digit sekali pakai ini berlaku selama <strong>15 menit</strong> untuk
              mendaftarkan tablet baru di resto Anda.
            </p>

            <div className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-neutral-700 mb-1">
                  Peran yang Diizinkan di Perangkat:
                </label>
                <div className="flex flex-wrap gap-2">
                  {(['kasir', 'pelayan', 'dapur'] as PeranPengguna[]).map((peran) => {
                    const dipilih = peranTerpilih.includes(peran)
                    return (
                      <Tombol
                        key={peran}
                        ragam={dipilih ? 'utama' : 'biasa'}
                        onClick={() => {
                          setPeranTerpilih((prev) =>
                            dipilih ? prev.filter((p) => p !== peran) : [...prev, peran],
                          )
                        }}
                      >
                        {peran.toUpperCase()} {dipilih ? '✓' : '+'}
                      </Tombol>
                    )
                  })}
                </div>
              </div>

              <Tombol
                ragam="utama"
                onClick={tanganiBuatKode}
                nonaktif={sedangMembuatKode || peranTerpilih.length === 0}
              >
                {sedangMembuatKode ? 'Membuat Kode...' : 'Buat Kode 6 Digit (15 Menit)'}
              </Tombol>

              {kodeDibuat && (
                <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-lg flex flex-col items-center justify-center gap-2">
                  <div className="text-xs text-emerald-800 font-medium">
                    KODE PENDAFTARAN PERANGKAT:
                  </div>
                  <div className="text-3xl font-mono font-bold tracking-widest text-emerald-950 bg-white px-4 py-2 rounded border border-emerald-300">
                    {kodeDibuat.kode}
                  </div>
                  <div className="text-xs text-emerald-700">
                    Berlaku sampai:{' '}
                    {new Date(kodeDibuat.kedaluwarsaPada).toLocaleTimeString('id-ID')}
                  </div>
                </div>
              )}
            </div>
          </Kartu>
        ) : (
          <Kartu judul="Pemberitahuan Hak Akses">
            <p className="text-sm text-neutral-600">
              Hanya Owner dan Admin Cabang yang dapat menerbitkan kode pendaftaran perangkat baru.
            </p>
          </Kartu>
        )}

        {/* Kolom Daftarkan Tablet Baru (Klien Perangkat) */}
        <Kartu judul="Daftarkan Tablet Ini">
          <form onSubmit={tanganiDaftarPerangkat} className="space-y-4">
            <p className="text-sm text-neutral-600">
              Masukkan nama pengenal (mis. POS Kasir Meja #1) dan kode 6 digit dari Admin untuk
              mendaftarkan perangkat ini.
            </p>

            <KolomIsian
              label="Nama Perangkat"
              contoh="Contoh: Tablet Kasir Depan"
              nilai={inputNamaPerangkat}
              onUbah={setInputNamaPerangkat}
              wajib
            />

            <KolomIsian
              label="Kode 6 Digit Pendaftaran"
              contoh="Contoh: 849201"
              nilai={inputKode}
              onUbah={(v) => setInputKode(v.replace(/\D/g, '').slice(0, 6))}
              wajib
            />

            <Tombol
              ragam="utama"
              jenis="submit"
              nonaktif={sedangDaftar || inputKode.length !== 6 || !inputNamaPerangkat.trim()}
            >
              {sedangDaftar ? 'Mendaftarkan...' : 'Daftarkan Perangkat Sekarang'}
            </Tombol>

            {pesanHasilDaftar && (
              <div
                role="alert"
                className={`p-3 rounded border text-sm ${
                  pesanHasilDaftar.sukses
                    ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                    : 'bg-red-50 text-red-800 border-red-200'
                }`}
              >
                {pesanHasilDaftar.teks}
              </div>
            )}
          </form>
        </Kartu>
      </div>

      {/* Tabel Persetujuan Pegawai (Pegawai x Perangkat) */}
      {berhakBuatKode && (
        <Kartu judul="Persetujuan Akses Pegawai di Perangkat">
          {daftarTunggu.length === 0 ? (
            <div className="text-center py-6 text-sm text-neutral-500">
              Tidak ada permohonan akses pegawai yang menunggu persetujuan.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b border-neutral-200 text-neutral-600">
                    <th className="py-2">Nama Pegawai</th>
                    <th className="py-2">Peran</th>
                    <th className="py-2">Perangkat Dituju</th>
                    <th className="py-2 text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-100">
                  {daftarTunggu.map((item) => (
                    <tr key={`${item.penggunaId}-${item.perangkatId}`}>
                      <td className="py-3 font-medium text-neutral-800">{item.nama}</td>
                      <td className="py-3">
                        <Lencana nada="netral">{item.peran.toUpperCase()}</Lencana>
                      </td>
                      <td className="py-3 text-neutral-600">{item.namaPerangkat}</td>
                      <td className="py-3 text-right">
                        <Tombol
                          ragam="kecil"
                          onClick={() => tanganiSetujui(item.penggunaId, item.perangkatId)}
                        >
                          Setujui Akses
                        </Tombol>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Kartu>
      )}
    </div>
  )
}
