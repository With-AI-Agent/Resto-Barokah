import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import type { PeranPengguna } from '../../lib/auth'

export interface PegawaiResto {
  id: string
  nama: string
  email: string
  peran: PeranPengguna
  cabangId: string
  namaCabang: string
  aktif: boolean
  dibuatPada: string
}

export interface KelolaPegawaiProps {
  daftarPegawai?: PegawaiResto[]
  cabangAktifId?: string
  namaCabangAktif?: string
  onTambahPegawai?: (data: {
    nama: string
    email: string
    peran: PeranPengguna
    cabangId: string
    pinAwal: string
  }) => Promise<{ sukses: boolean; pegawaiId?: string; pesan?: string }>
  onUbahStatusPegawai?: (
    pegawaiId: string,
    aktif: boolean,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onAturUlangPin?: (
    pegawaiId: string,
    pinBaru: string,
  ) => Promise<{ sukses: boolean; pesan?: string }>
}

const CONTOH_PEGAWAI: PegawaiResto[] = [
  {
    id: 'usr-01',
    nama: 'Budi Santoso',
    email: 'budi@resto.test',
    peran: 'kasir',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama',
    aktif: true,
    dibuatPada: '2026-09-01',
  },
  {
    id: 'usr-02',
    nama: 'Siti Rahma',
    email: 'siti@resto.test',
    peran: 'pelayan',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama',
    aktif: true,
    dibuatPada: '2026-09-05',
  },
  {
    id: 'usr-03',
    nama: 'Rudi Tabuti',
    email: 'rudi@resto.test',
    peran: 'dapur',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama',
    aktif: false,
    dibuatPada: '2026-08-15',
  },
]

export function KelolaPegawai({
  daftarPegawai = CONTOH_PEGAWAI,
  cabangAktifId = 'cab-01',
  namaCabangAktif = 'Cabang Utama',
  onTambahPegawai = async () => ({ sukses: true }),
  onUbahStatusPegawai = async () => ({ sukses: true }),
  onAturUlangPin = async () => ({ sukses: true }),
}: KelolaPegawaiProps) {
  const [pegawaiList, setPegawaiList] = useState<PegawaiResto[]>(daftarPegawai)
  const [modalBuka, setModalBuka] = useState(false)
  const [modalPinBuka, setModalPinBuka] = useState(false)
  const [pegawaiTargetPin, setPegawaiTargetPin] = useState<PegawaiResto | null>(null)

  // Form Tambah Pegawai
  const [nama, setNama] = useState('')
  const [email, setEmail] = useState('')
  const [peran, setPeran] = useState<PeranPengguna>('kasir')
  const [pinAwal, setPinAwal] = useState('')
  const [sedangSimpan, setSedangSimpan] = useState(false)
  const [galatForm, setGalatForm] = useState<string | null>(null)

  // Form Reset PIN
  const [pinBaru, setPinBaru] = useState('')
  const [sedangResetPin, setSedangResetPin] = useState(false)

  const tanganiTambah = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!nama.trim() || !email.trim() || pinAwal.length !== 6) {
      setGalatForm('Semua kolom wajib diisi dan PIN harus 6 angka.')
      return
    }

    setSedangSimpan(true)
    setGalatForm(null)
    try {
      const hasil = await onTambahPegawai({
        nama: nama.trim(),
        email: email.trim(),
        peran,
        cabangId: cabangAktifId,
        pinAwal,
      })

      if (hasil.sukses) {
        const pegawaiBaru: PegawaiResto = {
          id: hasil.pegawaiId || `usr-${Date.now()}`,
          nama: nama.trim(),
          email: email.trim(),
          peran,
          cabangId: cabangAktifId,
          namaCabang: namaCabangAktif,
          aktif: true,
          dibuatPada: new Date().toISOString().split('T')[0],
        }
        setPegawaiList((prev) => [pegawaiBaru, ...prev])
        setModalBuka(false)
        setNama('')
        setEmail('')
        setPinAwal('')
      } else {
        setGalatForm(hasil.pesan || 'Gagal menambahkan pegawai.')
      }
    } catch {
      setGalatForm('Terjadi kendala jaringan saat menghubungi peladen.')
    } finally {
      setSedangSimpan(false)
    }
  }

  const tanganiToggleStatus = async (pegawai: PegawaiResto) => {
    const statusBaru = !pegawai.aktif
    try {
      const hasil = await onUbahStatusPegawai(pegawai.id, statusBaru)
      if (hasil.sukses) {
        setPegawaiList((prev) =>
          prev.map((p) => (p.id === pegawai.id ? { ...p, aktif: statusBaru } : p)),
        )
      } else {
        alert(hasil.pesan || 'Gagal mengubah status keaktifan pegawai.')
      }
    } catch {
      alert('Kendala jaringan saat mengubah status pegawai.')
    }
  }

  const tanganiSimpanResetPin = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!pegawaiTargetPin || pinBaru.length !== 6) return

    setSedangResetPin(true)
    try {
      const hasil = await onAturUlangPin(pegawaiTargetPin.id, pinBaru)
      if (hasil.sukses) {
        setModalPinBuka(false)
        setPegawaiTargetPin(null)
        setPinBaru('')
        alert(`PIN untuk ${pegawaiTargetPin.nama} berhasil diatur ulang.`)
      } else {
        alert(hasil.pesan || 'Gagal mengatur ulang PIN.')
      }
    } catch {
      alert('Kendala jaringan saat mengatur ulang PIN.')
    } finally {
      setSedangResetPin(false)
    }
  }

  return (
    <div className="layar-kelola-pegawai space-y-6 max-w-5xl mx-auto p-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">Kelola Akun Pegawai</h2>
          <p className="text-sm text-neutral-500">
            Tambah staf baru, atur PIN kasir/pelayan/dapur, dan nonaktifkan akun tanpa menghapus
            riwayat audit.
          </p>
        </div>
        <Tombol ragam="utama" onClick={() => setModalBuka(true)}>
          + Tambah Pegawai Baru
        </Tombol>
      </div>

      <Kartu judul={`Daftar Pegawai (${pegawaiList.length})`}>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="border-b border-neutral-200 text-neutral-600">
                <th className="py-2.5">Nama & Email</th>
                <th className="py-2.5">Peran</th>
                <th className="py-2.5">Cabang</th>
                <th className="py-2.5">Status</th>
                <th className="py-2.5 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {pegawaiList.map((pegawai) => (
                <tr key={pegawai.id} className="hover:bg-neutral-50/50">
                  <td className="py-3.5 font-medium text-neutral-800">
                    <div>{pegawai.nama}</div>
                    <div className="text-xs text-neutral-500">{pegawai.email}</div>
                  </td>
                  <td className="py-3.5">
                    <Lencana nada="netral">{pegawai.peran.toUpperCase()}</Lencana>
                  </td>
                  <td className="py-3.5 text-neutral-600">{pegawai.namaCabang}</td>
                  <td className="py-3.5">
                    <Lencana nada={pegawai.aktif ? 'success' : 'danger'}>
                      {pegawai.aktif ? 'Aktif' : 'Nonaktif'}
                    </Lencana>
                  </td>
                  <td className="py-3.5 text-right space-x-2">
                    <Tombol
                      ragam="kecil"
                      onClick={() => {
                        setPegawaiTargetPin(pegawai)
                        setPinBaru('')
                        setModalPinBuka(true)
                      }}
                    >
                      Reset PIN
                    </Tombol>

                    <Tombol
                      ragam={pegawai.aktif ? 'bahaya' : 'utama'}
                      onClick={() => tanganiToggleStatus(pegawai)}
                    >
                      {pegawai.aktif ? 'Nonaktifkan' : 'Aktifkan'}
                    </Tombol>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* Modal Tambah Pegawai */}
      {modalBuka && (
        <Lapis buka={true} onTutup={() => setModalBuka(false)} judul="Tambah Akun Pegawai Baru">
          <form onSubmit={tanganiTambah} className="p-4 space-y-4">
            {galatForm && (
              <div
                role="alert"
                className="p-3 bg-red-50 border border-red-200 rounded text-sm text-red-800"
              >
                {galatForm}
              </div>
            )}

            <KolomIsian
              label="Nama Lengkap"
              contoh="Contoh: Ahmad Fauzi"
              nilai={nama}
              onUbah={setNama}
              wajib
            />

            <KolomIsian
              label="Alamat Email"
              contoh="Contoh: ahmad@barokah.id"
              jenis="email"
              nilai={email}
              onUbah={setEmail}
              wajib
            />

            <div className="kolom-isian">
              <label className="label">Peran Pegawai *</label>
              <select
                className="input"
                value={peran}
                onChange={(e) => setPeran(e.target.value as PeranPengguna)}
              >
                <option value="kasir">Kasir</option>
                <option value="pelayan">Pelayan (Waiter)</option>
                <option value="dapur">Dapur (Kitchen Display)</option>
                <option value="admin_cabang">Admin Cabang</option>
              </select>
            </div>

            <KolomIsian
              label="PIN Awal (6 Angka)"
              contoh="Contoh: 789123"
              nilai={pinAwal}
              onUbah={(v) => setPinAwal(v.replace(/\D/g, '').slice(0, 6))}
              keterangan="PIN dapat diubah oleh pegawai setelah pertama kali masuk."
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setModalBuka(false)} nonaktif={sedangSimpan}>
                Batal
              </Tombol>
              <Tombol ragam="utama" jenis="submit" nonaktif={sedangSimpan}>
                {sedangSimpan ? 'Menyimpan...' : 'Simpan Pegawai'}
              </Tombol>
            </div>
          </form>
        </Lapis>
      )}

      {/* Modal Reset PIN */}
      {modalPinBuka && pegawaiTargetPin && (
        <Lapis
          buka={true}
          onTutup={() => setModalPinBuka(false)}
          judul={`Reset PIN: ${pegawaiTargetPin.nama}`}
        >
          <form onSubmit={tanganiSimpanResetPin} className="p-4 space-y-4">
            <p className="text-sm text-neutral-600">
              Masukkan 6 digit angka PIN baru untuk <strong>{pegawaiTargetPin.nama}</strong> (
              {pegawaiTargetPin.email}).
            </p>

            <KolomIsian
              label="PIN Baru (6 Angka)"
              contoh="Contoh: 147258"
              nilai={pinBaru}
              onUbah={(v) => setPinBaru(v.replace(/\D/g, '').slice(0, 6))}
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol
                ragam="biasa"
                onClick={() => setModalPinBuka(false)}
                nonaktif={sedangResetPin}
              >
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                jenis="submit"
                nonaktif={sedangResetPin || pinBaru.length !== 6}
              >
                {sedangResetPin ? 'Menyimpan PIN...' : 'Simpan PIN Baru'}
              </Tombol>
            </div>
          </form>
        </Lapis>
      )}
    </div>
  )
}
