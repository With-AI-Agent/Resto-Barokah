/**
 * Cabang.tsx — Pengelolaan Cabang, Printer Struk & Penugasan Staf (T9-09 / PRD M11 / ART-7 & ART-12)
 *
 * Fitur:
 *  1. Daftar cabang resto dengan indikator status, zona waktu, dan konfigurasi printer default.
 *  2. Tambah cabang baru (nama unik se-resto, alamat, telepon, zona waktu resmi, printer bawaan).
 *  3. Ubah profil cabang dan konfigurasi printer thermal (lebar 58mm / 80mm).
 *  4. Nonaktifkan cabang sementara (soft-disable) dengan penjaga fail-closed minimal satu cabang aktif.
 *  5. Atur penugasan multi-cabang pegawai (ART-12 staf merangkap multi-cabang).
 *  6. Statistik cabang (jumlah meja, perangkat POS terdaftar, dan pegawai bertugas).
 */

import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { Toast } from '../../komponen/Toast'

export interface PrinterCabang {
  profil_id: string
  nama: string
  lebar: number // 58 atau 80
}

export interface DataCabang {
  id: string
  nama: string
  alamat: string | null
  telepon: string | null
  zona_waktu: string
  printer_default: PrinterCabang | null
  aktif: boolean
  jumlah_pegawai?: number
  jumlah_meja?: number
  jumlah_perangkat?: number
  dibuat_pada?: string
  diubah_pada?: string
}

export interface PegawaiCabangItem {
  id: string
  nama: string
  peran: string
  email?: string
  ditugaskan: boolean
}

export interface CabangProps {
  daftarCabang?: DataCabang[]
  daftarPegawaiResto?: Array<{ id: string; nama: string; peran: string; email?: string }>
  hanyaBaca?: boolean
  cabangAktifId?: string
  onTambahCabang?: (data: {
    nama: string
    alamat?: string
    telepon?: string
    zonaWaktu: string
    printer?: PrinterCabang
  }) => Promise<{ sukses: boolean; cabangId?: string; pesan?: string }>
  onSimpanCabang?: (data: {
    id: string
    nama: string
    alamat?: string
    telepon?: string
    zonaWaktu: string
    printer?: PrinterCabang
  }) => Promise<{ sukses: boolean; pesan?: string }>
  onUbahStatusCabang?: (
    cabangId: string,
    aktif: boolean,
  ) => Promise<{ sukses: boolean; pesan?: string }>
  onAturAksesCabang?: (data: {
    penggunaId: string
    cabangId: string
    aktif: boolean
  }) => Promise<{ sukses: boolean; pesan?: string }>
  onMuatAksesPegawai?: (
    cabangId: string,
  ) => Promise<Array<{ id: string; nama: string; peran: string; ditugaskan: boolean }>>
}

const CABANG_DEFAULT: DataCabang[] = [
  {
    id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'Cabang Pusat',
    alamat: 'Jl. Riau No. 50, Bandung',
    telepon: '022-7778888',
    zona_waktu: 'Asia/Jakarta',
    printer_default: {
      profil_id: 'epson-t82',
      nama: 'Epson TM-T82 Kasir',
      lebar: 80,
    },
    aktif: true,
    jumlah_pegawai: 4,
    jumlah_meja: 12,
    jumlah_perangkat: 2,
    dibuat_pada: '2026-01-01T00:00:00Z',
  },
  {
    id: 'a1a1a1a1-0000-0000-0000-000000000002',
    nama: 'Cabang Dago',
    alamat: 'Jl. Ir. H. Juanda No. 120, Bandung',
    telepon: '022-2501234',
    zona_waktu: 'Asia/Jakarta',
    printer_default: {
      profil_id: 'umum-58',
      nama: 'Thermal Kasir 58mm',
      lebar: 58,
    },
    aktif: true,
    jumlah_pegawai: 2,
    jumlah_meja: 8,
    jumlah_perangkat: 1,
    dibuat_pada: '2026-02-01T00:00:00Z',
  },
]

const PEGAWAI_DEFAULT: Array<{ id: string; nama: string; peran: string; email?: string }> = [
  { id: '90000000-0000-0000-0000-000000000002', nama: 'Bu Oasis', peran: 'owner_pusat', email: 'owner@sajian.id' },
  { id: '90000000-0000-0000-0000-000000000003', nama: 'Pak Andi', peran: 'admin_cabang', email: 'andi@sajian.id' },
  { id: '90000000-0000-0000-0000-000000000004', nama: 'Rina', peran: 'kasir', email: 'rina@sajian.id' },
  { id: '90000000-0000-0000-0000-000000000005', nama: 'Dedi', peran: 'pelayan', email: 'dedi@sajian.id' },
  { id: '90000000-0000-0000-0000-000000000006', nama: 'Budi', peran: 'dapur', email: 'budi@sajian.id' },
]

export const OPSI_ZONA_WAKTU = [
  { nilai: 'Asia/Jakarta', label: 'WIB (Asia/Jakarta) — Jawa, Sumatra, Kalbar, Kalteng' },
  { nilai: 'Asia/Makassar', label: 'WITA (Asia/Makassar) — Bali, NTB, NTT, Sulsel, Kalsel, Kaltim' },
  { nilai: 'Asia/Jayapura', label: 'WIT (Asia/Jayapura) — Maluku, Papua' },
]

export const OPSI_PROFIL_PRINTER = [
  { id: 'umum-58', nama: 'Printer Thermal Standar 58mm (ESC/POS)', lebar: 58 },
  { id: 'umum-80', nama: 'Printer Thermal Standar 80mm (ESC/POS)', lebar: 80 },
  { id: 'epson-t82', nama: 'Epson TM-T82 / TM-T82X (80mm)', lebar: 80 },
  { id: 'xprinter-58', nama: 'Xprinter XP-58II / Seri 58mm', lebar: 58 },
  { id: 'goojprt-pt210', nama: 'Goojprt PT-210 Mobile Bluetooth (58mm)', lebar: 58 },
]

export function Cabang({
  daftarCabang = CABANG_DEFAULT,
  daftarPegawaiResto = PEGAWAI_DEFAULT,
  hanyaBaca = false,
  cabangAktifId,
  onTambahCabang,
  onSimpanCabang,
  onUbahStatusCabang,
  onAturAksesCabang,
  onMuatAksesPegawai,
}: CabangProps) {
  const [cabangList, setCabangList] = useState<DataCabang[]>(daftarCabang)
  const [kataKunci, setKataKunci] = useState('')
  const [filterStatus, setFilterStatus] = useState<'semua' | 'aktif' | 'nonaktif'>('semua')
  const [memuat, setMemuat] = useState(false)
  const [toast, setToast] = useState<{ pesan: string; nada: 'sukses' | 'gagal' | 'info' } | null>(null)

  // State Modal Tambah
  const [modalTambahBuka, setModalTambahBuka] = useState(false)
  const [namaTambah, setNamaTambah] = useState('')
  const [alamatTambah, setAlamatTambah] = useState('')
  const [teleponTambah, setTeleponTambah] = useState('')
  const [zonaWaktuTambah, setZonaWaktuTambah] = useState('Asia/Jakarta')
  const [profilPrinterTambah, setProfilPrinterTambah] = useState('umum-58')
  const [namaPrinterTambah, setNamaPrinterTambah] = useState('Printer Kasir 58mm')
  const [lebarPrinterTambah, setLebarPrinterTambah] = useState<number>(58)

  // State Modal Ubah
  const [modalUbahBuka, setModalUbahBuka] = useState(false)
  const [cabangDipilih, setCabangDipilih] = useState<DataCabang | null>(null)
  const [namaUbah, setNamaUbah] = useState('')
  const [alamatUbah, setAlamatUbah] = useState('')
  const [teleponUbah, setTeleponUbah] = useState('')
  const [zonaWaktuUbah, setZonaWaktuUbah] = useState('Asia/Jakarta')
  const [profilPrinterUbah, setProfilPrinterUbah] = useState('umum-58')
  const [namaPrinterUbah, setNamaPrinterUbah] = useState('')
  const [lebarPrinterUbah, setLebarPrinterUbah] = useState<number>(58)

  // State Modal Akses Pegawai Multi-Cabang
  const [modalAksesBuka, setModalAksesBuka] = useState(false)
  const [cabangAkses, setCabangAkses] = useState<DataCabang | null>(null)
  const [daftarAksesPegawai, setDaftarAksesPegawai] = useState<PegawaiCabangItem[]>([])
  const [memuatAkses, setMemuatAkses] = useState(false)

  // Filter daftar cabang
  const daftarTersaring = cabangList.filter((c) => {
    const cocokNama =
      c.nama.toLowerCase().includes(kataKunci.toLowerCase()) ||
      (c.alamat && c.alamat.toLowerCase().includes(kataKunci.toLowerCase()))
    const cocokStatus =
      filterStatus === 'semua'
        ? true
        : filterStatus === 'aktif'
          ? c.aktif
          : !c.aktif
    return cocokNama && cocokStatus
  })

  const totalCabang = cabangList.length
  const totalAktif = cabangList.filter((c) => c.aktif).length
  const totalNonaktif = totalCabang - totalAktif

  // Penanganan Tambah Cabang
  const tanganiBukaTambah = () => {
    setNamaTambah('')
    setAlamatTambah('')
    setTeleponTambah('')
    setZonaWaktuTambah('Asia/Jakarta')
    setProfilPrinterTambah('umum-58')
    setNamaPrinterTambah('Printer Kasir 58mm')
    setLebarPrinterTambah(58)
    setModalTambahBuka(true)
  }

  const tanganiSimpanTambah = async () => {
    const namaBersih = namaTambah.trim()
    if (!namaBersih) {
      setToast({ pesan: 'Nama cabang wajib diisi.', nada: 'gagal' })
      return
    }

    // Cek duplikasi nama lokal
    const duplikat = cabangList.some(
      (c) => c.nama.toLowerCase() === namaBersih.toLowerCase(),
    )
    if (duplikat) {
      setToast({ pesan: `Nama cabang "${namaBersih}" sudah terdaftar.`, nada: 'gagal' })
      return
    }

    setMemuat(true)
    try {
      const printerConfig: PrinterCabang = {
        profil_id: profilPrinterTambah,
        nama: namaPrinterTambah.trim() || 'Printer Kasir',
        lebar: lebarPrinterTambah,
      }

      if (onTambahCabang) {
        const hasil = await onTambahCabang({
          nama: namaBersih,
          alamat: alamatTambah.trim() || undefined,
          telepon: teleponTambah.trim() || undefined,
          zonaWaktu: zonaWaktuTambah,
          printer: printerConfig,
        })
        if (!hasil.sukses) {
          setToast({ pesan: hasil.pesan || 'Gagal menambahkan cabang.', nada: 'gagal' })
          return
        }
      }

      const cabangBaru: DataCabang = {
        id: `cabang-${Date.now()}`,
        nama: namaBersih,
        alamat: alamatTambah.trim() || null,
        telepon: teleponTambah.trim() || null,
        zona_waktu: zonaWaktuTambah,
        printer_default: printerConfig,
        aktif: true,
        jumlah_pegawai: 0,
        jumlah_meja: 0,
        jumlah_perangkat: 0,
        dibuat_pada: new Date().toISOString(),
      }

      setCabangList((prev) => [...prev, cabangBaru])
      setModalTambahBuka(false)
      setToast({ pesan: `Cabang "${namaBersih}" berhasil ditambahkan!`, nada: 'sukses' })
    } catch (err: any) {
      setToast({ pesan: err?.message || 'Terjadi kesalahan saat menambah cabang.', nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  // Penanganan Ubah Cabang
  const tanganiBukaUbah = (cabang: DataCabang) => {
    setCabangDipilih(cabang)
    setNamaUbah(cabang.nama)
    setAlamatUbah(cabang.alamat || '')
    setTeleponUbah(cabang.telepon || '')
    setZonaWaktuUbah(cabang.zona_waktu || 'Asia/Jakarta')
    setProfilPrinterUbah(cabang.printer_default?.profil_id || 'umum-58')
    setNamaPrinterUbah(cabang.printer_default?.nama || 'Printer Kasir')
    setLebarPrinterUbah(cabang.printer_default?.lebar || 58)
    setModalUbahBuka(true)
  }

  const tanganiSimpanUbah = async () => {
    if (!cabangDipilih) return
    const namaBersih = namaUbah.trim()
    if (!namaBersih) {
      setToast({ pesan: 'Nama cabang wajib diisi.', nada: 'gagal' })
      return
    }

    // Cek duplikasi jika nama diubah
    const duplikat = cabangList.some(
      (c) => c.id !== cabangDipilih.id && c.nama.toLowerCase() === namaBersih.toLowerCase(),
    )
    if (duplikat) {
      setToast({ pesan: `Nama cabang "${namaBersih}" sudah digunakan cabang lain.`, nada: 'gagal' })
      return
    }

    setMemuat(true)
    try {
      const printerConfig: PrinterCabang = {
        profil_id: profilPrinterUbah,
        nama: namaPrinterUbah.trim() || 'Printer Kasir',
        lebar: lebarPrinterUbah,
      }

      if (onSimpanCabang) {
        const hasil = await onSimpanCabang({
          id: cabangDipilih.id,
          nama: namaBersih,
          alamat: alamatUbah.trim() || undefined,
          telepon: teleponUbah.trim() || undefined,
          zonaWaktu: zonaWaktuUbah,
          printer: printerConfig,
        })
        if (!hasil.sukses) {
          setToast({ pesan: hasil.pesan || 'Gagal memperbarui cabang.', nada: 'gagal' })
          return
        }
      }

      setCabangList((prev) =>
        prev.map((c) =>
          c.id === cabangDipilih.id
            ? {
                ...c,
                nama: namaBersih,
                alamat: alamatUbah.trim() || null,
                telepon: teleponUbah.trim() || null,
                zona_waktu: zonaWaktuUbah,
                printer_default: printerConfig,
                diubah_pada: new Date().toISOString(),
              }
            : c,
        ),
      )

      setModalUbahBuka(false)
      setToast({ pesan: `Profil cabang "${namaBersih}" berhasil diperbarui!`, nada: 'sukses' })
    } catch (err: any) {
      setToast({ pesan: err?.message || 'Gagal menyimpan perubahan cabang.', nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  // Penanganan Toggle Status Cabang (Soft-Disable ART-12)
  const tanganiToggleStatus = async (cabang: DataCabang) => {
    if (hanyaBaca) return

    // Perlindungan fail-closed: jika hendak menonaktifkan cabang aktif terakhir
    if (cabang.aktif && totalAktif <= 1) {
      setToast({
        pesan: 'Minimal harus ada satu cabang yang aktif di restoran.',
        nada: 'gagal',
      })
      return
    }

    const statusBaru = !cabang.aktif
    const pesanAksi = statusBaru ? 'mengaktifkan' : 'menonaktifkan sementara'
    if (!window.confirm(`Yakin ingin ${pesanAksi} cabang "${cabang.nama}"?`)) {
      return
    }

    setMemuat(true)
    try {
      if (onUbahStatusCabang) {
        const hasil = await onUbahStatusCabang(cabang.id, statusBaru)
        if (!hasil.sukses) {
          setToast({ pesan: hasil.pesan || 'Gagal mengubah status cabang.', nada: 'gagal' })
          return
        }
      }

      setCabangList((prev) =>
        prev.map((c) => (c.id === cabang.id ? { ...c, aktif: statusBaru } : c)),
      )
      setToast({
        pesan: `Cabang "${cabang.nama}" berhasil ${statusBaru ? 'diaktifkan' : 'dinonaktifkan'}.`,
        nada: 'sukses',
      })
    } catch (err: any) {
      setToast({ pesan: err?.message || 'Gagal mengubah status cabang.', nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  // Penanganan Buka Modal Akses Multi-Cabang Pegawai
  const tanganiBukaAkses = async (cabang: DataCabang) => {
    setCabangAkses(cabang)
    setMemuatAkses(true)
    setModalAksesBuka(true)

    try {
      if (onMuatAksesPegawai) {
        const data = await onMuatAksesPegawai(cabang.id)
        setDaftarAksesPegawai(data)
      } else {
        // Fallback simulasi
        const mock: PegawaiCabangItem[] = daftarPegawaiResto.map((p) => ({
          id: p.id,
          nama: p.nama,
          peran: p.peran,
          email: p.email,
          ditugaskan: p.peran === 'owner_pusat' || p.peran === 'admin_cabang',
        }))
        setDaftarAksesPegawai(mock)
      }
    } catch (err: any) {
      setToast({ pesan: err?.message || 'Gagal memuat daftar penugasan pegawai.', nada: 'gagal' })
    } finally {
      setMemuatAkses(false)
    }
  }

  // Penanganan Toggle Akses Pegawai
  const tanganiToggleAksesPegawai = async (pegawai: PegawaiCabangItem) => {
    if (!cabangAkses || hanyaBaca) return
    const statusAksesBaru = !pegawai.ditugaskan

    try {
      if (onAturAksesCabang) {
        const hasil = await onAturAksesCabang({
          penggunaId: pegawai.id,
          cabangId: cabangAkses.id,
          aktif: statusAksesBaru,
        })
        if (!hasil.sukses) {
          setToast({ pesan: hasil.pesan || 'Gagal memperbarui penugasan pegawai.', nada: 'gagal' })
          return
        }
      }

      setDaftarAksesPegawai((prev) =>
        prev.map((p) => (p.id === pegawai.id ? { ...p, ditugaskan: statusAksesBaru } : p)),
      )

      // Perbarui juga hitungan pegawai di kartu cabang lokal
      setCabangList((prev) =>
        prev.map((c) => {
          if (c.id === cabangAkses.id) {
            const hitunganLama = c.jumlah_pegawai || 0
            const hitunganBaru = statusAksesBaru ? hitunganLama + 1 : Math.max(0, hitunganLama - 1)
            return { ...c, jumlah_pegawai: hitunganBaru }
          }
          return c
        }),
      )

      setToast({
        pesan: `Penugasan ${pegawai.nama} di "${cabangAkses.nama}" ${
          statusAksesBaru ? 'diberikan' : 'dicabut'
        }.`,
        nada: 'sukses',
      })
    } catch (err: any) {
      setToast({ pesan: err?.message || 'Gagal mengatur penugasan cabang.', nada: 'gagal' })
    }
  }

  return (
    <div className="space-y-6">
      {/* Header & Statistik Cabang */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-teks-utama">
            Kelola Cabang & Printer Struk
          </h2>
          <p className="text-sm text-teks-sekunder mt-1">
            Pusat kendali operasional cabang resto, pengaturan zona waktu, printer default, dan
            penugasan multi-cabang pegawai (PRD M11 / ART-7 & ART-12).
          </p>
        </div>
        {!hanyaBaca && (
          <Tombol
            ragam="utama"
            onClick={tanganiBukaTambah}
            data-aksi="pengaturan.tambah_cabang"
          >
            + Tambah Cabang
          </Tombol>
        )}
      </div>

      {/* Kartu Ringkasan */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Kartu>
          <div className="p-4">
            <span className="text-xs font-semibold text-teks-sekunder uppercase tracking-wider">
              Total Cabang
            </span>
            <div className="text-2xl font-bold text-teks-utama mt-1">{totalCabang}</div>
            <p className="text-xs text-teks-sekunder mt-1">Cabang terdaftar di restoran</p>
          </div>
        </Kartu>
        <Kartu>
          <div className="p-4">
            <span className="text-xs font-semibold text-teks-sekunder uppercase tracking-wider">
              Cabang Beroperasi
            </span>
            <div className="text-2xl font-bold text-berhasil mt-1">{totalAktif}</div>
            <p className="text-xs text-teks-sekunder mt-1">Aktif melayani pesanan kasir</p>
          </div>
        </Kartu>
        <Kartu>
          <div className="p-4">
            <span className="text-xs font-semibold text-teks-sekunder uppercase tracking-wider">
              Cabang Nonaktif
            </span>
            <div className="text-2xl font-bold text-bahaya mt-1">{totalNonaktif}</div>
            <p className="text-xs text-teks-sekunder mt-1">Tutup sementara tanpa hapus data</p>
          </div>
        </Kartu>
      </div>

      {/* Bilah Pencarian & Filter */}
      <Kartu>
        <div className="p-4 flex flex-col sm:flex-row gap-4 items-stretch sm:items-center justify-between">
          <div className="flex-1 max-w-md">
            <KolomIsian
              label="Cari Cabang"
              nilai={kataKunci}
              onUbah={setKataKunci}
              contoh="Ketik nama cabang atau alamat..."
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-teks-sekunder">Status:</span>
            <div className="inline-flex rounded-lg border border-garis p-1 bg-latar-kartu">
              <Tombol
                ragam={filterStatus === 'semua' ? 'biasa' : 'polos'}
                onClick={() => setFilterStatus('semua')}
              >
                Semua ({totalCabang})
              </Tombol>
              <Tombol
                ragam={filterStatus === 'aktif' ? 'biasa' : 'polos'}
                onClick={() => setFilterStatus('aktif')}
              >
                Aktif ({totalAktif})
              </Tombol>
              <Tombol
                ragam={filterStatus === 'nonaktif' ? 'biasa' : 'polos'}
                onClick={() => setFilterStatus('nonaktif')}
              >
                Nonaktif ({totalNonaktif})
              </Tombol>
            </div>
          </div>
        </div>
      </Kartu>

      {/* Daftar Kartu Cabang */}
      {daftarTersaring.length === 0 ? (
        <Kartu>
          <div className="p-8 text-center text-teks-sekunder">
            <p className="text-base font-semibold">Tidak ada cabang yang cocok dengan kriteria.</p>
            <p className="text-xs mt-1">Coba gunakan kata kunci lain atau ubah filter status.</p>
          </div>
        </Kartu>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {daftarTersaring.map((cabang) => {
            const adalahAktifSistem = cabang.id === cabangAktifId
            return (
              <Kartu key={cabang.id}>
                <div className="p-5 flex flex-col justify-between h-full space-y-4">
                  <div>
                    {/* Header Cabang */}
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-lg font-bold text-teks-utama">{cabang.nama}</h3>
                          {adalahAktifSistem && (
                            <Lencana nada="info">Sesi Aktif</Lencana>
                          )}
                        </div>
                        <p className="text-xs text-teks-sekunder mt-0.5">
                          {cabang.alamat || 'Alamat belum diatur'}
                          {cabang.telepon ? ` • Telp: ${cabang.telepon}` : ''}
                        </p>
                      </div>
                      <Lencana nada={cabang.aktif ? 'success' : 'danger'}>
                        {cabang.aktif ? 'Aktif' : 'Nonaktif'}
                      </Lencana>
                    </div>

                    {/* Informasi Teknis Cabang */}
                    <div className="mt-4 pt-3 border-t border-garis grid grid-cols-2 gap-2 text-xs">
                      <div>
                        <span className="text-teks-sekunder block">Zona Waktu:</span>
                        <span className="font-semibold text-teks-utama">
                          {cabang.zona_waktu === 'Asia/Jakarta'
                            ? 'WIB (Jakarta)'
                            : cabang.zona_waktu === 'Asia/Makassar'
                              ? 'WITA (Makassar)'
                              : cabang.zona_waktu === 'Asia/Jayapura'
                                ? 'WIT (Jayapura)'
                                : cabang.zona_waktu}
                        </span>
                      </div>
                      <div>
                        <span className="text-teks-sekunder block">Printer Struk:</span>
                        <span className="font-semibold text-teks-utama">
                          {cabang.printer_default?.nama || 'Thermal Default'} (
                          {cabang.printer_default?.lebar || 58} mm)
                        </span>
                      </div>
                    </div>

                    {/* Statistik Operasional */}
                    <div className="mt-3 bg-latar-kartu rounded p-2.5 border border-garis flex justify-around text-center text-xs">
                      <div>
                        <span className="text-teks-sekunder block">Meja</span>
                        <span className="font-bold text-sm text-teks-utama">
                          {cabang.jumlah_meja ?? 0}
                        </span>
                      </div>
                      <div className="border-r border-garis" />
                      <div>
                        <span className="text-teks-sekunder block">Pegawai</span>
                        <span className="font-bold text-sm text-teks-utama">
                          {cabang.jumlah_pegawai ?? 0}
                        </span>
                      </div>
                      <div className="border-r border-garis" />
                      <div>
                        <span className="text-teks-sekunder block">Perangkat POS</span>
                        <span className="font-bold text-sm text-teks-utama">
                          {cabang.jumlah_perangkat ?? 0}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Tombol Aksi Cabang */}
                  {!hanyaBaca && (
                    <div className="pt-2 flex flex-wrap gap-2 border-t border-garis justify-end">
                      <Tombol
                        ragam="polos"
                        onClick={() => tanganiBukaAkses(cabang)}
                        data-aksi="pengaturan.atur_akses_cabang"
                      >
                        👥 Penugasan Staf
                      </Tombol>
                      <Tombol
                        ragam="biasa"
                        onClick={() => tanganiBukaUbah(cabang)}
                        data-aksi="pengaturan.simpan_cabang"
                      >
                        ✏️ Edit Cabang
                      </Tombol>
                      <Tombol
                        ragam={cabang.aktif ? 'bahaya' : 'utama'}
                        onClick={() => tanganiToggleStatus(cabang)}
                        nonaktif={memuat}
                        data-aksi="pengaturan.ubah_status_cabang"
                      >
                        {cabang.aktif ? 'Nonaktifkan' : 'Aktifkan'}
                      </Tombol>
                    </div>
                  )}
                </div>
              </Kartu>
            )
          })}
        </div>
      )}

      {/* Modal Tambah Cabang */}
      <Lapis
        buka={modalTambahBuka}
        judul="Tambah Cabang Baru"
        onTutup={() => setModalTambahBuka(false)}
        kaki={
          <div className="flex gap-2 justify-end w-full">
            <Tombol
              ragam="polos"
              onClick={() => setModalTambahBuka(false)}
              nonaktif={memuat}
            >
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={tanganiSimpanTambah}
              nonaktif={memuat}
              data-aksi="pengaturan.tambah_cabang"
            >
              {memuat ? 'Menyimpan...' : 'Simpan Cabang Baru'}
            </Tombol>
          </div>
        }
      >
        <div className="space-y-4">
          <p className="text-xs text-teks-sekunder">
            Cabang baru akan langsung memiliki profil isolasi database dan konfigurasi printer
            bawaan (PRD M11 / ART-12).
          </p>

          <KolomIsian
            label="Nama Cabang"
            nilai={namaTambah}
            onUbah={setNamaTambah}
            wajib
            contoh="Contoh: Cabang Dago, Cabang Sukajadi"
          />

          <KolomIsian
            label="Alamat Cabang"
            nilai={alamatTambah}
            onUbah={setAlamatTambah}
            contoh="Jl. Ir. H. Juanda No. 120, Bandung"
          />

          <KolomIsian
            label="Nomor Telepon"
            nilai={teleponTambah}
            onUbah={setTeleponTambah}
            jenis="tel"
            contoh="022-2501234 atau 081234567890"
          />

          {/* Zona Waktu */}
          <div className="space-y-1">
            <label className="text-xs font-semibold text-teks-utama block">
              Zona Waktu Operasional *
            </label>
            <select
              className="w-full text-sm rounded border border-garis bg-latar-kartu text-teks-utama p-2.5"
              value={zonaWaktuTambah}
              onChange={(e) => setZonaWaktuTambah(e.target.value)}
            >
              {OPSI_ZONA_WAKTU.map((z) => (
                <option key={z.nilai} value={z.nilai}>
                  {z.label}
                </option>
              ))}
            </select>
            <p className="text-[11px] text-teks-sekunder">
              Penting untuk stempel waktu transaksi kasir dan cut-off laporan keuangan cabang.
            </p>
          </div>

          {/* Konfigurasi Printer Struk Default */}
          <div className="pt-3 border-t border-garis space-y-3">
            <h4 className="text-xs font-bold text-teks-utama uppercase tracking-wider">
              Konfigurasi Default Printer Struk (ART-7)
            </h4>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-teks-utama block">
                Model Printer Bawaan
              </label>
              <select
                className="w-full text-sm rounded border border-garis bg-latar-kartu text-teks-utama p-2.5"
                value={profilPrinterTambah}
                onChange={(e) => {
                  const val = e.target.value
                  setProfilPrinterTambah(val)
                  const terpilih = OPSI_PROFIL_PRINTER.find((p) => p.id === val)
                  if (terpilih) {
                    setLebarPrinterTambah(terpilih.lebar)
                    setNamaPrinterTambah(terpilih.nama.split('(')[0].trim())
                  }
                }}
              >
                {OPSI_PROFIL_PRINTER.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.nama}
                  </option>
                ))}
              </select>
            </div>

            <KolomIsian
              label="Nama Perangkat Printer"
              nilai={namaPrinterTambah}
              onUbah={setNamaPrinterTambah}
              contoh="Contoh: Printer Kasir Utama"
            />

            <div className="space-y-1">
              <label className="text-xs font-semibold text-teks-utama block">
                Lebar Kertas Struk *
              </label>
              <div className="grid grid-cols-2 gap-3">
                <label
                  className={`flex items-center gap-2 p-3 rounded border cursor-pointer text-sm font-medium ${
                    lebarPrinterTambah === 58
                      ? 'border-primer bg-latar-kartu text-teks-utama'
                      : 'border-garis text-teks-sekunder'
                  }`}
                >
                  <input
                    type="radio"
                    name="lebar_kertas_tambah"
                    checked={lebarPrinterTambah === 58}
                    onChange={() => setLebarPrinterTambah(58)}
                  />
                  <span>58 mm (32 kolom)</span>
                </label>
                <label
                  className={`flex items-center gap-2 p-3 rounded border cursor-pointer text-sm font-medium ${
                    lebarPrinterTambah === 80
                      ? 'border-primer bg-latar-kartu text-teks-utama'
                      : 'border-garis text-teks-sekunder'
                  }`}
                >
                  <input
                    type="radio"
                    name="lebar_kertas_tambah"
                    checked={lebarPrinterTambah === 80}
                    onChange={() => setLebarPrinterTambah(80)}
                  />
                  <span>80 mm (48 kolom)</span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </Lapis>

      {/* Modal Edit Cabang */}
      <Lapis
        buka={modalUbahBuka}
        judul={`Edit Cabang — ${cabangDipilih?.nama || ''}`}
        onTutup={() => setModalUbahBuka(false)}
        kaki={
          <div className="flex gap-2 justify-end w-full">
            <Tombol
              ragam="polos"
              onClick={() => setModalUbahBuka(false)}
              nonaktif={memuat}
            >
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={tanganiSimpanUbah}
              nonaktif={memuat}
              data-aksi="pengaturan.simpan_cabang"
            >
              {memuat ? 'Menyimpan...' : 'Simpan Perubahan'}
            </Tombol>
          </div>
        }
      >
        <div className="space-y-4">
          <KolomIsian
            label="Nama Cabang"
            nilai={namaUbah}
            onUbah={setNamaUbah}
            wajib
            contoh="Nama cabang resmi"
          />

          <KolomIsian
            label="Alamat Cabang"
            nilai={alamatUbah}
            onUbah={setAlamatUbah}
            contoh="Alamat lengkap cabang"
          />

          <KolomIsian
            label="Nomor Telepon"
            nilai={teleponUbah}
            onUbah={setTeleponUbah}
            jenis="tel"
            contoh="Nomor telepon cabang"
          />

          {/* Zona Waktu */}
          <div className="space-y-1">
            <label className="text-xs font-semibold text-teks-utama block">
              Zona Waktu Operasional *
            </label>
            <select
              className="w-full text-sm rounded border border-garis bg-latar-kartu text-teks-utama p-2.5"
              value={zonaWaktuUbah}
              onChange={(e) => setZonaWaktuUbah(e.target.value)}
            >
              {OPSI_ZONA_WAKTU.map((z) => (
                <option key={z.nilai} value={z.nilai}>
                  {z.label}
                </option>
              ))}
            </select>
          </div>

          {/* Konfigurasi Printer Struk Default */}
          <div className="pt-3 border-t border-garis space-y-3">
            <h4 className="text-xs font-bold text-teks-utama uppercase tracking-wider">
              Konfigurasi Default Printer Struk (ART-7)
            </h4>

            <div className="space-y-1">
              <label className="text-xs font-semibold text-teks-utama block">
                Model Printer Bawaan
              </label>
              <select
                className="w-full text-sm rounded border border-garis bg-latar-kartu text-teks-utama p-2.5"
                value={profilPrinterUbah}
                onChange={(e) => {
                  const val = e.target.value
                  setProfilPrinterUbah(val)
                  const terpilih = OPSI_PROFIL_PRINTER.find((p) => p.id === val)
                  if (terpilih) {
                    setLebarPrinterUbah(terpilih.lebar)
                  }
                }}
              >
                {OPSI_PROFIL_PRINTER.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.nama}
                  </option>
                ))}
              </select>
            </div>

            <KolomIsian
              label="Nama Perangkat Printer"
              nilai={namaPrinterUbah}
              onUbah={setNamaPrinterUbah}
              contoh="Nama printer kasir"
            />

            <div className="space-y-1">
              <label className="text-xs font-semibold text-teks-utama block">
                Lebar Kertas Struk *
              </label>
              <div className="grid grid-cols-2 gap-3">
                <label
                  className={`flex items-center gap-2 p-3 rounded border cursor-pointer text-sm font-medium ${
                    lebarPrinterUbah === 58
                      ? 'border-primer bg-latar-kartu text-teks-utama'
                      : 'border-garis text-teks-sekunder'
                  }`}
                >
                  <input
                    type="radio"
                    name="lebar_kertas_ubah"
                    checked={lebarPrinterUbah === 58}
                    onChange={() => setLebarPrinterUbah(58)}
                  />
                  <span>58 mm (32 kolom)</span>
                </label>
                <label
                  className={`flex items-center gap-2 p-3 rounded border cursor-pointer text-sm font-medium ${
                    lebarPrinterUbah === 80
                      ? 'border-primer bg-latar-kartu text-teks-utama'
                      : 'border-garis text-teks-sekunder'
                  }`}
                >
                  <input
                    type="radio"
                    name="lebar_kertas_ubah"
                    checked={lebarPrinterUbah === 80}
                    onChange={() => setLebarPrinterUbah(80)}
                  />
                  <span>80 mm (48 kolom)</span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </Lapis>

      {/* Modal Penugasan Multi-Cabang Pegawai (ART-12) */}
      <Lapis
        buka={modalAksesBuka}
        judul={`Penugasan Staf — ${cabangAkses?.nama || ''}`}
        onTutup={() => setModalAksesBuka(false)}
        kaki={
          <div className="flex justify-end w-full">
            <Tombol ragam="biasa" onClick={() => setModalAksesBuka(false)}>
              Selesai
            </Tombol>
          </div>
        }
      >
        <div className="space-y-4">
          <p className="text-xs text-teks-sekunder">
            Atur staf yang diizinkan bertugas dan melayani kasir/pesanan di cabang ini. Sistem
            mendukung pegawai merangkap di beberapa cabang sekaligus (ART-12).
          </p>

          {memuatAkses ? (
            <div className="p-6 text-center text-xs text-teks-sekunder">
              Memuat data penugasan pegawai...
            </div>
          ) : daftarAksesPegawai.length === 0 ? (
            <div className="p-6 text-center text-xs text-teks-sekunder">
              Belum ada pegawai yang terdaftar di restoran.
            </div>
          ) : (
            <div className="divide-y divide-garis border border-garis rounded-lg overflow-hidden">
              {daftarAksesPegawai.map((pegawai) => {
                const peranLabel =
                  pegawai.peran === 'owner_pusat'
                    ? 'Owner Pusat'
                    : pegawai.peran === 'admin_cabang'
                      ? 'Admin Cabang'
                      : pegawai.peran === 'kasir'
                        ? 'Kasir'
                        : pegawai.peran === 'pelayan'
                          ? 'Pelayan'
                          : pegawai.peran === 'dapur'
                            ? 'Dapur'
                            : pegawai.peran

                return (
                  <div
                    key={pegawai.id}
                    className="p-3 flex items-center justify-between gap-3 hover:bg-latar-kartu"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold text-teks-utama">
                          {pegawai.nama}
                        </span>
                        <Lencana nada="info">{peranLabel}</Lencana>
                      </div>
                      {pegawai.email && (
                        <p className="text-xs text-teks-sekunder mt-0.5">{pegawai.email}</p>
                      )}
                    </div>
                    <div>
                      <Tombol
                        ragam={pegawai.ditugaskan ? 'bahaya' : 'utama'}
                        onClick={() => tanganiToggleAksesPegawai(pegawai)}
                        nonaktif={hanyaBaca}
                        data-aksi="pengaturan.atur_akses_cabang"
                      >
                        {pegawai.ditugaskan ? 'Cabut Akses' : 'Tugaskan'}
                      </Tombol>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </Lapis>

      {/* Toast Notifikasi */}
      {toast && (
        <Toast
          pesan={toast.pesan}
          nada={toast.nada}
          aksi={
            <Tombol ragam="polos" onClick={() => setToast(null)}>
              Tutup
            </Tombol>
          }
        />
      )}
    </div>
  )
}
