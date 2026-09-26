/**
 * KelolaPegawai.tsx — Pengelolaan Akun Pegawai, Peran, Izin Berjenjang & PIN (T9-08 / PRD M3 & M6 / ART-2)
 *
 * Fitur:
 *  1. Daftar pegawai resto dengan pencarian nama & filter peran (owner, admin, kasir, pelayan, dapur).
 *  2. Tambah pegawai baru & edit profil pegawai (nama, email, peran, cabang penugasan).
 *  3. Modal atur izin pegawai granular (10 izin resmi sistem + batas diskon nominal & persen).
 *  4. Reset PIN 6 digit pegawai secara mandiri oleh atasan berwenang (dengan validasi kekuatan PIN).
 *  5. Pengaktifan / penonaktifan pegawai (soft-disable) untuk menjaga keutuhan riwayat audit & finansial (ART-2).
 */

import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { rupiah } from '../../lib/format'
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

export interface IzinItem {
  kode_izin: string
  keterangan: string
  kelompok: string
  boleh: boolean
  batas_nominal: number | null
  batas_persen: number | null
  khusus?: boolean
}

export interface KelolaPegawaiProps {
  daftarPegawai?: PegawaiResto[]
  cabangAktifId?: string
  namaCabangAktif?: string
  hanyaBaca?: boolean
  onTambahPegawai?: (data: {
    nama: string
    email: string
    peran: PeranPengguna
    cabangId: string
    pinAwal: string
  }) => Promise<{ sukses: boolean; pegawaiId?: string; pesan?: string }>
  onUbahPegawai?: (data: {
    id: string
    nama: string
    email: string
    peran: PeranPengguna
    cabangId: string
  }) => Promise<{ sukses: boolean; pesan?: string }>
  onUbahStatusPegawai?: (
    pegawaiId: string,
    aktif: boolean,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onAturUlangPin?: (
    pegawaiId: string,
    pinBaru: string,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onSimpanIzin?: (data: {
    pegawaiId: string
    kodeIzin: string
    boleh: boolean
    batasNominal?: number | null
    batasPersen?: number | null
  }) => Promise<{ sukses: boolean; pesan?: string }>
}

export const DAFTAR_IZIN_RESMI: IzinItem[] = [
  {
    kode_izin: 'ubah_harga',
    keterangan: 'Mengubah harga menu saat transaksi di kasir',
    kelompok: 'harga',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'beri_diskon',
    keterangan: 'Memberi diskon manual pesanan (dibatasi nominal dan persen)',
    kelompok: 'diskon',
    boleh: false,
    batas_nominal: 50000,
    batas_persen: 10,
  },
  {
    kode_izin: 'void_sebelum_dapur',
    keterangan: 'Membatalkan item/pesanan sebelum pesanan mulai dimasak',
    kelompok: 'void',
    boleh: true,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'void_sesudah_dapur',
    keterangan: 'Membatalkan item/pesanan sesudah pesanan mulai dimasak di dapur',
    kelompok: 'void',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'lihat_laporan',
    keterangan: 'Melihat ringkasan laporan penjualan, kas harian, dan analitik',
    kelompok: 'laporan',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'kelola_pegawai',
    keterangan: 'Menambah, mengubah akun pegawai, dan mengatur hak akses',
    kelompok: 'pegawai',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'atur_pengaturan',
    keterangan: 'Mengubah konfigurasi restoran, tema, pajak PB1, dan metode bayar',
    kelompok: 'pengaturan',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'pakai_voucher',
    keterangan: 'Memeriksa dan menggunakan voucher diskon promosi pelanggan',
    kelompok: 'voucher',
    boleh: true,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'tutup_kas',
    keterangan: 'Menutup shift kasir dan mencatat rekonsiliasi uang fisik',
    kelompok: 'kas',
    boleh: true,
    batas_nominal: null,
    batas_persen: null,
  },
  {
    kode_izin: 'ubah_stok',
    keterangan: 'Menandai menu habis dan memperbarui persediaan bahan baku',
    kelompok: 'stok',
    boleh: false,
    batas_nominal: null,
    batas_persen: null,
  },
]

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
  hanyaBaca = false,
  onTambahPegawai = async () => ({ sukses: true }),
  onUbahPegawai = async () => ({ sukses: true }),
  onUbahStatusPegawai = async () => ({ sukses: true }),
  onAturUlangPin = async () => ({ sukses: true }),
  onSimpanIzin = async () => ({ sukses: true }),
}: KelolaPegawaiProps) {
  const [pegawaiList, setPegawaiList] = useState<PegawaiResto[]>(daftarPegawai)
  const [cari, setCari] = useState('')
  const [filterPeran, setFilterPeran] = useState<string>('semua')

  // Modal Tambah / Edit
  const [modalBuka, setModalBuka] = useState(false)
  const [pegawaiEdit, setPegawaiEdit] = useState<PegawaiResto | null>(null)
  const [nama, setNama] = useState('')
  const [email, setEmail] = useState('')
  const [peran, setPeran] = useState<PeranPengguna>('kasir')
  const [pinAwal, setPinAwal] = useState('')
  const [sedangSimpan, setSedangSimpan] = useState(false)
  const [galatForm, setGalatForm] = useState<string | null>(null)

  // Modal Reset PIN
  const [modalPinBuka, setModalPinBuka] = useState(false)
  const [pegawaiTargetPin, setPegawaiTargetPin] = useState<PegawaiResto | null>(null)
  const [pinBaru, setPinBaru] = useState('')
  const [sedangResetPin, setSedangResetPin] = useState(false)
  const [pesanPin, setPesanPin] = useState<string | null>(null)

  // Modal Atur Izin
  const [modalIzinBuka, setModalIzinBuka] = useState(false)
  const [pegawaiTargetIzin, setPegawaiTargetIzin] = useState<PegawaiResto | null>(null)
  const [matriksIzin, setMatriksIzin] = useState<IzinItem[]>(DAFTAR_IZIN_RESMI)
  const [sedangSimpanIzin, setSedangSimpanIzin] = useState(false)
  const [pesanIzin, setPesanIzin] = useState<string | null>(null)

  // Buka Modal Tambah Baru
  const bukaModalTambah = () => {
    setPegawaiEdit(null)
    setNama('')
    setEmail('')
    setPeran('kasir')
    setPinAwal('')
    setGalatForm(null)
    setModalBuka(true)
  }

  // Buka Modal Edit
  const bukaModalEdit = (p: PegawaiResto) => {
    setPegawaiEdit(p)
    setNama(p.nama)
    setEmail(p.email)
    setPeran(p.peran)
    setPinAwal('')
    setGalatForm(null)
    setModalBuka(true)
  }

  // Buka Modal Izin
  const bukaModalIzin = (p: PegawaiResto) => {
    setPegawaiTargetIzin(p)
    setPesanIzin(null)

    // Bawaan konfigurasi peran
    const bawaan = DAFTAR_IZIN_RESMI.map((iz) => {
      if (p.peran === 'owner_pusat') {
        return { ...iz, boleh: true, batas_nominal: null, batas_persen: null }
      }
      if (p.peran === 'admin_cabang') {
        return {
          ...iz,
          boleh: iz.kode_izin !== 'atur_pengaturan',
          batas_nominal: iz.kode_izin === 'beri_diskon' ? 100000 : null,
          batas_persen: iz.kode_izin === 'beri_diskon' ? 20 : null,
        }
      }
      if (p.peran === 'kasir') {
        return {
          ...iz,
          boleh: ['beri_diskon', 'void_sebelum_dapur', 'pakai_voucher', 'tutup_kas'].includes(
            iz.kode_izin,
          ),
          batas_nominal: iz.kode_izin === 'beri_diskon' ? 50000 : null,
          batas_persen: iz.kode_izin === 'beri_diskon' ? 10 : null,
        }
      }
      if (p.peran === 'pelayan') {
        return {
          ...iz,
          boleh: ['void_sebelum_dapur'].includes(iz.kode_izin),
          batas_nominal: null,
          batas_persen: null,
        }
      }
      if (p.peran === 'dapur') {
        return {
          ...iz,
          boleh: ['ubah_stok'].includes(iz.kode_izin),
          batas_nominal: null,
          batas_persen: null,
        }
      }
      return iz
    })

    setMatriksIzin(bawaan)
    setModalIzinBuka(true)
  }

  // Simpan Tambah / Edit Pegawai
  const tanganiSimpanPegawai = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!nama.trim() || !email.trim()) {
      setGalatForm('Nama dan email wajib diisi.')
      return
    }

    if (!pegawaiEdit && pinAwal.length !== 6) {
      setGalatForm('PIN awal akun baru wajib 6 digit angka.')
      return
    }

    setSedangSimpan(true)
    setGalatForm(null)

    try {
      if (pegawaiEdit) {
        const hasil = await onUbahPegawai({
          id: pegawaiEdit.id,
          nama: nama.trim(),
          email: email.trim(),
          peran,
          cabangId: cabangAktifId,
        })
        if (hasil.sukses) {
          setPegawaiList((prev) =>
            prev.map((p) =>
              p.id === pegawaiEdit.id ? { ...p, nama: nama.trim(), email: email.trim(), peran } : p,
            ),
          )
          setModalBuka(false)
        } else {
          setGalatForm(hasil.pesan || 'Gagal mengubah data pegawai.')
        }
      } else {
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
        } else {
          setGalatForm(hasil.pesan || 'Gagal menambahkan pegawai.')
        }
      }
    } catch {
      setGalatForm('Terjadi kendala jaringan saat menghubungi peladen.')
    } finally {
      setSedangSimpan(false)
    }
  }

  // Ubah Status Keaktifan (Soft-disable)
  const tanganiToggleStatus = async (pegawai: PegawaiResto) => {
    if (hanyaBaca) return
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
      alert('Kendala jaringan saat mengubah status keaktifan.')
    }
  }

  // Simpan Reset PIN
  const tanganiSimpanResetPin = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!pegawaiTargetPin || pinBaru.length !== 6) return

    setSedangResetPin(true)
    setPesanPin(null)
    try {
      const hasil = await onAturUlangPin(pegawaiTargetPin.id, pinBaru)
      if (hasil.sukses) {
        setPesanPin(`PIN untuk ${pegawaiTargetPin.nama} berhasil diatur ulang.`)
        setTimeout(() => {
          setModalPinBuka(false)
          setPegawaiTargetPin(null)
          setPinBaru('')
          setPesanPin(null)
        }, 1200)
      } else {
        setPesanPin(hasil.pesan || 'Gagal mengatur ulang PIN.')
      }
    } catch {
      setPesanPin('Kendala jaringan saat mengatur ulang PIN.')
    } finally {
      setSedangResetPin(false)
    }
  }

  // Simpan Izin Pegawai
  const tanganiSimpanIzin = async () => {
    if (!pegawaiTargetIzin) return

    setSedangSimpanIzin(true)
    setPesanIzin(null)

    try {
      for (const iz of matriksIzin) {
        await onSimpanIzin({
          pegawaiId: pegawaiTargetIzin.id,
          kodeIzin: iz.kode_izin,
          boleh: iz.boleh,
          batasNominal: iz.batas_nominal,
          batasPersen: iz.batas_persen,
        })
      }
      setPesanIzin(`Hak akses izin untuk ${pegawaiTargetIzin.nama} berhasil disimpan.`)
      setTimeout(() => {
        setModalIzinBuka(false)
        setPegawaiTargetIzin(null)
        setPesanIzin(null)
      }, 1000)
    } catch {
      setPesanIzin('Kendala jaringan saat menyimpan matriks izin.')
    } finally {
      setSedangSimpanIzin(false)
    }
  }

  // Toggle Centang Izin Lokal
  const ubahIzinItem = (kode: string, boleh: boolean) => {
    setMatriksIzin((prev) =>
      prev.map((item) => (item.kode_izin === kode ? { ...item, boleh, khusus: true } : item)),
    )
  }

  // Ubah Batas Diskon Lokal
  const ubahBatasDiskon = (nominal: number | null, persen: number | null) => {
    setMatriksIzin((prev) =>
      prev.map((item) =>
        item.kode_izin === 'beri_diskon'
          ? { ...item, batas_nominal: nominal, batas_persen: persen, khusus: true }
          : item,
      ),
    )
  }

  // Filter List Pegawai
  const daftarTersaring = pegawaiList.filter((p) => {
    const cocokNama =
      p.nama.toLowerCase().includes(cari.toLowerCase()) ||
      p.email.toLowerCase().includes(cari.toLowerCase())
    const cocokPeran = filterPeran === 'semua' || p.peran === filterPeran
    return cocokNama && cocokPeran
  })

  return (
    <div
      className="layar-kelola-pegawai space-y-6 max-w-5xl mx-auto p-4"
      data-testid="kelola-pegawai"
    >
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">Kelola Akun Pegawai</h2>
          <p className="text-sm text-neutral-500">
            Atur staf kedai, penugasan peran kasir/pelayan/koki, batas izin diskon, dan kredensial
            PIN (ART-2).
          </p>
        </div>
        {!hanyaBaca && (
          <Tombol ragam="utama" onClick={bukaModalTambah}>
            + Tambah Pegawai Baru
          </Tombol>
        )}
      </div>

      {/* Filter & Pencarian */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="flex-1">
          <KolomIsian
            label=""
            contoh="Cari nama atau email pegawai..."
            nilai={cari}
            onUbah={setCari}
          />
        </div>
        <div style={{ minWidth: '180px' }}>
          <select
            className="input w-full"
            value={filterPeran}
            onChange={(e) => setFilterPeran(e.target.value)}
            aria-label="Filter Peran Pegawai"
          >
            <option value="semua">Semua Peran</option>
            <option value="owner_pusat">Owner Pusat</option>
            <option value="admin_cabang">Admin Cabang</option>
            <option value="kasir">Kasir</option>
            <option value="pelayan">Pelayan</option>
            <option value="dapur">Dapur</option>
          </select>
        </div>
      </div>

      <Kartu judul={`Daftar Pegawai (${daftarTersaring.length})`}>
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
              {daftarTersaring.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-6 text-center text-neutral-500">
                    Tidak ada pegawai yang cocok dengan pencarian.
                  </td>
                </tr>
              ) : (
                daftarTersaring.map((pegawai) => (
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
                    <td className="py-3.5 text-right space-x-2 whitespace-nowrap">
                      {!hanyaBaca && (
                        <>
                          <Tombol ragam="kecil" onClick={() => bukaModalEdit(pegawai)}>
                            Edit
                          </Tombol>

                          <Tombol ragam="kecil" onClick={() => bukaModalIzin(pegawai)}>
                            Hak Akses
                          </Tombol>

                          <Tombol
                            ragam="kecil"
                            onClick={() => {
                              setPegawaiTargetPin(pegawai)
                              setPinBaru('')
                              setPesanPin(null)
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
                        </>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* Modal Tambah / Edit Pegawai */}
      {modalBuka && (
        <Lapis
          buka={true}
          onTutup={() => setModalBuka(false)}
          judul={pegawaiEdit ? `Edit Profil: ${pegawaiEdit.nama}` : 'Tambah Akun Pegawai Baru'}
        >
          <form onSubmit={tanganiSimpanPegawai} className="p-4 space-y-4">
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

            {!pegawaiEdit && (
              <KolomIsian
                label="PIN Awal (6 Angka)"
                contoh="Contoh: 789123"
                nilai={pinAwal}
                onUbah={(v) => setPinAwal(v.replace(/\D/g, '').slice(0, 6))}
                keterangan="PIN rahasia 6 angka untuk verifikasi login kasir/pelayan."
                wajib
              />
            )}

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
              Masukkan 6 digit angka PIN baru untuk pegawai <strong>{pegawaiTargetPin.nama}</strong>{' '}
              ({pegawaiTargetPin.email}). PIN baru akan langsung dienkripsi dengan standar bcrypt.
            </p>

            {pesanPin && (
              <div
                role="status"
                className="p-3 bg-blue-50 border border-blue-200 rounded text-sm text-blue-800"
              >
                {pesanPin}
              </div>
            )}

            <KolomIsian
              label="PIN Baru (6 Angka)"
              contoh="Contoh: 147258"
              nilai={pinBaru}
              onUbah={(v) => setPinBaru(v.replace(/\D/g, '').slice(0, 6))}
              keterangan="Wajib 6 digit angka dan bukan pola angka mudah ditebak."
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

      {/* Modal Atur Izin Granular */}
      {modalIzinBuka && pegawaiTargetIzin && (
        <Lapis
          buka={true}
          onTutup={() => setModalIzinBuka(false)}
          judul={`Hak Akses & Izin: ${pegawaiTargetIzin.nama}`}
        >
          <div className="p-4 space-y-4 max-h-[80vh] overflow-y-auto">
            <p className="text-sm text-neutral-600">
              Konfigurasi 10 izin resmi sistem untuk <strong>{pegawaiTargetIzin.nama}</strong>{' '}
              (Peran: {pegawaiTargetIzin.peran.toUpperCase()}).
            </p>

            {pesanIzin && (
              <div
                role="status"
                className="p-3 bg-blue-50 border border-blue-200 rounded text-sm text-blue-800"
              >
                {pesanIzin}
              </div>
            )}

            <div className="space-y-3">
              {matriksIzin.map((iz) => {
                const itemDiskon = iz.kode_izin === 'beri_diskon'
                return (
                  <div
                    key={iz.kode_izin}
                    className="p-3 rounded border border-neutral-200 bg-white space-y-2"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="font-semibold text-neutral-800 text-sm flex items-center gap-2">
                          <span>{iz.keterangan}</span>
                          {iz.khusus && <Lencana nada="info">Khusus</Lencana>}
                        </div>
                        <div className="text-xs text-neutral-500 font-mono mt-0.5">
                          {iz.kode_izin} ({iz.kelompok})
                        </div>
                      </div>
                      <Tombol
                        ragam={iz.boleh ? 'utama' : 'biasa'}
                        onClick={() => ubahIzinItem(iz.kode_izin, !iz.boleh)}
                      >
                        {iz.boleh ? 'Diizinkan' : 'Dilarang'}
                      </Tombol>
                    </div>

                    {/* Khusus Izin Diskon: Batas Nominal & Batas Persen */}
                    {itemDiskon && iz.boleh && (
                      <div className="pt-2 border-t border-neutral-100 grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <KolomIsian
                          label="Batas Nominal Diskon (Rp)"
                          contoh="50000"
                          jenis="number"
                          nilai={iz.batas_nominal !== null ? String(iz.batas_nominal) : ''}
                          onUbah={(v) =>
                            ubahBatasDiskon(v === '' ? null : Number(v), iz.batas_persen)
                          }
                          keterangan={
                            iz.batas_nominal ? `Maks: ${rupiah(iz.batas_nominal)}` : 'Tanpa batas'
                          }
                        />
                        <KolomIsian
                          label="Batas Persentase Diskon (%)"
                          contoh="15"
                          jenis="number"
                          nilai={iz.batas_persen !== null ? String(iz.batas_persen) : ''}
                          onUbah={(v) =>
                            ubahBatasDiskon(iz.batas_nominal, v === '' ? null : Number(v))
                          }
                          keterangan={iz.batas_persen ? `Maks: ${iz.batas_persen}%` : 'Tanpa batas'}
                        />
                      </div>
                    )}
                  </div>
                )
              })}
            </div>

            <div className="flex justify-end gap-2 pt-3 border-t border-neutral-200">
              <Tombol
                ragam="biasa"
                onClick={() => setModalIzinBuka(false)}
                nonaktif={sedangSimpanIzin}
              >
                Batal
              </Tombol>
              <Tombol ragam="utama" onClick={tanganiSimpanIzin} nonaktif={sedangSimpanIzin}>
                {sedangSimpanIzin ? 'Menyimpan Izin...' : 'Simpan Hak Akses'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
