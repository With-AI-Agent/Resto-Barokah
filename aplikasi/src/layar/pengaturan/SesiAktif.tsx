import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'

export interface DataSesiAktif {
  sessionId: string
  perangkatId: string
  namaPerangkat: string
  jenisPerangkat: string
  statusPerangkat: 'aktif' | 'dicabut' | 'hilang' | string
  penggunaId: string
  namaPengguna: string
  emailPengguna: string
  peran: string
  cabangId?: string
  namaCabang?: string
  mulai: string
  berakhirPada: string
  status: 'aktif' | 'dicabut' | 'selesai' | string
  diperbaruiPada?: string
}

export interface SesiAktifProps {
  daftarSesiAwal?: DataSesiAktif[]
  onMuatSesi?: () => Promise<DataSesiAktif[]>
  onAkhiriSesi?: (
    sessionId: string,
    alasan: string,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  onKeluarSemuaPerangkat?: (
    penggunaId: string,
    alasan: string,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  onTandaiPerangkatHilang?: (
    perangkatId: string,
    alasan: string,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  sesiSayaId?: string
  peranPengguna?: string
}

const CONTOH_SESI_AKTIF: DataSesiAktif[] = [
  {
    sessionId: 'sess-kasir-01',
    perangkatId: 'dev-pos-01',
    namaPerangkat: 'Tablet Kasir Depan (POS #1)',
    jenisPerangkat: 'tablet',
    statusPerangkat: 'aktif',
    penggunaId: 'user-kasir-01',
    namaPengguna: 'Rina (Kasir Shift Pagi)',
    emailPengguna: 'rina.kasir@resto.local',
    peran: 'kasir',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    mulai: new Date(Date.now() - 7200000).toISOString(),
    berakhirPada: new Date(Date.now() + 36000000).toISOString(),
    status: 'aktif',
  },
  {
    sessionId: 'sess-waiter-02',
    perangkatId: 'dev-tab-02',
    namaPerangkat: 'HP Waiter Outdoor #2',
    jenisPerangkat: 'ponsel',
    statusPerangkat: 'aktif',
    penggunaId: 'user-waiter-01',
    namaPengguna: 'Dedi (Pelayan)',
    emailPengguna: 'dedi.waiter@resto.local',
    peran: 'pelayan',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    mulai: new Date(Date.now() - 3600000).toISOString(),
    berakhirPada: new Date(Date.now() + 39600000).toISOString(),
    status: 'aktif',
  },
  {
    sessionId: 'sess-dapur-03',
    perangkatId: 'dev-kds-01',
    namaPerangkat: 'Layar KDS Dapur Utama',
    jenisPerangkat: 'kds',
    statusPerangkat: 'aktif',
    penggunaId: 'user-dapur-01',
    namaPengguna: 'Sari (Kepala Dapur)',
    emailPengguna: 'sari.dapur@resto.local',
    peran: 'dapur',
    cabangId: 'cab-01',
    namaCabang: 'Cabang Utama (Pusat)',
    mulai: new Date(Date.now() - 14400000).toISOString(),
    berakhirPada: new Date(Date.now() + 28800000).toISOString(),
    status: 'aktif',
  },
]

export function SesiAktif({
  daftarSesiAwal = CONTOH_SESI_AKTIF,
  onMuatSesi,
  onAkhiriSesi = async () => ({ berhasil: true, pesan: 'Sesi berhasil diakhiri.' }),
  onKeluarSemuaPerangkat = async () => ({
    berhasil: true,
    pesan: 'Semua sesi staf berhasil dicabut.',
  }),
  onTandaiPerangkatHilang = async () => ({
    berhasil: true,
    pesan: 'Perangkat berhasil ditandai hilang dan seluruh sesi dicabut.',
  }),
  sesiSayaId,
}: SesiAktifProps) {
  const [daftarSesi, setDaftarSesi] = useState<DataSesiAktif[]>(daftarSesiAwal)
  const [pencarian, setPencarian] = useState('')
  const [filterPeran, setFilterPeran] = useState<string>('semua')
  const [hanyaAktif, setHanyaAktif] = useState(true)

  const [targetAkhiriSesi, setTargetAkhiriSesi] = useState<DataSesiAktif | null>(null)
  const [targetKeluarSemua, setTargetKeluarSemua] = useState<DataSesiAktif | null>(null)
  const [targetPerangkatHilang, setTargetPerangkatHilang] = useState<DataSesiAktif | null>(null)

  const [alasan, setAlasan] = useState('')
  const [sedangProses, setSedangProses] = useState(false)
  const [sedangSegarkan, setSedangSegarkan] = useState(false)
  const [pesanNotifikasi, setPesanNotifikasi] = useState<{
    tipe: 'sukses' | 'galat'
    teks: string
  } | null>(null)

  const tanganiSegarkan = async () => {
    if (!onMuatSesi) return
    setSedangSegarkan(true)
    try {
      const data = await onMuatSesi()
      setDaftarSesi(data)
      setPesanNotifikasi({ tipe: 'sukses', teks: 'Daftar sesi berhasil diperbarui.' })
    } catch {
      setPesanNotifikasi({ tipe: 'galat', teks: 'Gagal memuat daftar sesi dari peladen.' })
    } finally {
      setSedangSegarkan(false)
    }
  }

  const bukaModalAkhiriSesi = (sesi: DataSesiAktif) => {
    setTargetAkhiriSesi(sesi)
    setAlasan('Sesi diakhiri oleh pengelola restoran')
  }

  const bukaModalKeluarSemua = (sesi: DataSesiAktif) => {
    setTargetKeluarSemua(sesi)
    setAlasan('Pencabutan seluruh sesi aktif staf')
  }

  const bukaModalPerangkatHilang = (sesi: DataSesiAktif) => {
    setTargetPerangkatHilang(sesi)
    setAlasan('Perangkat dilaporkan hilang atau tertinggal')
  }

  const eksekusiAkhiriSesi = async () => {
    if (!targetAkhiriSesi) return
    setSedangProses(true)
    try {
      const res = await onAkhiriSesi(
        targetAkhiriSesi.sessionId,
        alasan.trim() || 'Sesi diakhiri manual',
      )
      if (res.berhasil) {
        setDaftarSesi((prev) =>
          prev.map((s) =>
            s.sessionId === targetAkhiriSesi.sessionId ? { ...s, status: 'dicabut' } : s,
          ),
        )
        setPesanNotifikasi({
          tipe: 'sukses',
          teks:
            res.pesan ?? `Sesi untuk ${targetAkhiriSesi.namaPengguna} berhasil diputus seketika.`,
        })
        setTargetAkhiriSesi(null)
      } else {
        setPesanNotifikasi({
          tipe: 'galat',
          teks: res.pesan ?? 'Gagal mengakhiri sesi.',
        })
      }
    } catch {
      setPesanNotifikasi({
        tipe: 'galat',
        teks: 'Terjadi gangguan jaringan saat mengakhiri sesi.',
      })
    } finally {
      setSedangProses(false)
    }
  }

  const eksekusiKeluarSemua = async () => {
    if (!targetKeluarSemua) return
    setSedangProses(true)
    try {
      const res = await onKeluarSemuaPerangkat(
        targetKeluarSemua.penggunaId,
        alasan.trim() || 'Pencabutan seluruh perangkat',
      )
      if (res.berhasil) {
        setDaftarSesi((prev) =>
          prev.map((s) =>
            s.penggunaId === targetKeluarSemua.penggunaId ? { ...s, status: 'dicabut' } : s,
          ),
        )
        setPesanNotifikasi({
          tipe: 'sukses',
          teks:
            res.pesan ?? `Seluruh sesi aktif ${targetKeluarSemua.namaPengguna} berhasil diputus.`,
        })
        setTargetKeluarSemua(null)
      } else {
        setPesanNotifikasi({
          tipe: 'galat',
          teks: res.pesan ?? 'Gagal mencabut seluruh sesi pengguna.',
        })
      }
    } catch {
      setPesanNotifikasi({
        tipe: 'galat',
        teks: 'Terjadi gangguan jaringan saat memutus seluruh sesi.',
      })
    } finally {
      setSedangProses(false)
    }
  }

  const eksekusiTandaiHilang = async () => {
    if (!targetPerangkatHilang) return
    setSedangProses(true)
    try {
      const res = await onTandaiPerangkatHilang(
        targetPerangkatHilang.perangkatId,
        alasan.trim() || 'Perangkat dilaporkan hilang',
      )
      if (res.berhasil) {
        setDaftarSesi((prev) =>
          prev.map((s) =>
            s.perangkatId === targetPerangkatHilang.perangkatId
              ? { ...s, status: 'dicabut', statusPerangkat: 'hilang' }
              : s,
          ),
        )
        setPesanNotifikasi({
          tipe: 'sukses',
          teks:
            res.pesan ??
            `Perangkat "${targetPerangkatHilang.namaPerangkat}" ditandai hilang dan seluruh aksesnya diputus seketika.`,
        })
        setTargetPerangkatHilang(null)
      } else {
        setPesanNotifikasi({
          tipe: 'galat',
          teks: res.pesan ?? 'Gagal menandai perangkat hilang.',
        })
      }
    } catch {
      setPesanNotifikasi({
        tipe: 'galat',
        teks: 'Terjadi gangguan jaringan saat menandai perangkat hilang.',
      })
    } finally {
      setSedangProses(false)
    }
  }

  const sesiTersaring = daftarSesi.filter((s) => {
    if (hanyaAktif && s.status !== 'aktif') return false
    if (filterPeran !== 'semua' && s.peran !== filterPeran) return false
    if (pencarian.trim()) {
      const q = pencarian.toLowerCase()
      const cocokNama = s.namaPengguna.toLowerCase().includes(q)
      const cocokEmail = s.emailPengguna.toLowerCase().includes(q)
      const cocokPerangkat = s.namaPerangkat.toLowerCase().includes(q)
      return cocokNama || cocokEmail || cocokPerangkat
    }
    return true
  })

  const jumlahAktif = daftarSesi.filter((s) => s.status === 'aktif').length
  const jumlahPerangkatHilang = daftarSesi.filter((s) => s.statusPerangkat === 'hilang').length

  const formatWaktu = (iso: string) => {
    try {
      return new Date(iso).toLocaleString('id-ID', {
        dateStyle: 'medium',
        timeStyle: 'short',
      })
    } catch {
      return iso
    }
  }

  return (
    <div
      className="layar-sesi-aktif space-y-6 max-w-6xl mx-auto p-4"
      data-testid="layar-sesi-aktif"
    >
      {/* Header Info */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">Sesi Aktif & Keamanan Perangkat</h2>
          <p className="text-sm text-neutral-500">
            Pantau staf yang sedang masuk di tablet kasir atau HP resto. Bila perangkat hilang atau
            dicuri, putuskan sesinya dari sini agar data dan uang restoran tetap aman.
          </p>
        </div>
        <div className="flex items-center gap-2">
          {onMuatSesi && (
            <Tombol
              ragam="biasa"
              onClick={tanganiSegarkan}
              nonaktif={sedangSegarkan}
              nama="Segarkan daftar sesi"
            >
              {sedangSegarkan ? 'Menyegarkan...' : 'Segarkan'}
            </Tombol>
          )}
        </div>
      </div>

      {/* Banner Notifikasi Hasil */}
      {pesanNotifikasi && (
        <div
          role="alert"
          className={`p-3.5 rounded-lg border text-sm flex items-center justify-between ${
            pesanNotifikasi.tipe === 'sukses'
              ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
              : 'bg-red-50 text-red-800 border-red-200'
          }`}
        >
          <span>{pesanNotifikasi.teks}</span>
          <Tombol ragam="kecil" onClick={() => setPesanNotifikasi(null)} nama="Tutup notifikasi">
            Tutup
          </Tombol>
        </div>
      )}

      {/* Ringkasan Status */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="p-4 bg-white rounded-lg border border-neutral-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold text-lg">
            {jumlahAktif}
          </div>
          <div>
            <div className="text-xs text-neutral-500 uppercase tracking-wider font-semibold">
              Sesi Sedang Masuk
            </div>
            <div className="text-sm font-medium text-neutral-800">
              {jumlahAktif > 0 ? 'Perangkat terhubung aktif' : 'Tidak ada sesi aktif'}
            </div>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg border border-neutral-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-lg">
            {daftarSesi.length}
          </div>
          <div>
            <div className="text-xs text-neutral-500 uppercase tracking-wider font-semibold">
              Total Catatan Sesi
            </div>
            <div className="text-sm font-medium text-neutral-800">Riwayat sesi di resto</div>
          </div>
        </div>

        <div className="p-4 bg-white rounded-lg border border-neutral-200 shadow-sm flex items-center gap-3">
          <div
            className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-lg ${
              jumlahPerangkatHilang > 0
                ? 'bg-red-100 text-red-700'
                : 'bg-neutral-100 text-neutral-600'
            }`}
          >
            {jumlahPerangkatHilang}
          </div>
          <div>
            <div className="text-xs text-neutral-500 uppercase tracking-wider font-semibold">
              Perangkat Hilang
            </div>
            <div className="text-sm font-medium text-neutral-800">
              {jumlahPerangkatHilang > 0 ? 'Akses diblokir permanen' : 'Aman (tidak ada hilang)'}
            </div>
          </div>
        </div>
      </div>

      {/* Filter & Kontrol Pencarian */}
      <Kartu judul="Daftar Sesi Staf & Perangkat">
        <div className="flex flex-col sm:flex-row gap-3 mb-4">
          <div className="flex-1">
            <KolomIsian
              label="Cari Sesi"
              contoh="Ketik nama staf, email, atau nama perangkat..."
              nilai={pencarian}
              onUbah={setPencarian}
            />
          </div>
          <div className="flex items-end gap-2">
            <div>
              <label
                htmlFor="filter-peran-select"
                className="block text-xs font-medium text-neutral-600 mb-1"
              >
                Peran:
              </label>
              <select
                id="filter-peran-select"
                aria-label="Filter berdasarkan peran staf"
                className="input text-sm h-11 px-3 py-2 border border-neutral-300 rounded-md bg-white"
                value={filterPeran}
                onChange={(e) => setFilterPeran(e.target.value)}
              >
                <option value="semua">Semua Peran</option>
                <option value="kasir">Kasir</option>
                <option value="pelayan">Pelayan</option>
                <option value="dapur">Dapur</option>
                <option value="admin_cabang">Admin Cabang</option>
                <option value="owner_pusat">Owner Pusat</option>
              </select>
            </div>
            <Tombol
              ragam={hanyaAktif ? 'utama' : 'biasa'}
              onClick={() => setHanyaAktif((v) => !v)}
              nama="Alihkan tampilan hanya sesi aktif"
            >
              {hanyaAktif ? '✓ Hanya Sesi Aktif' : 'Tampilkan Semua Status'}
            </Tombol>
          </div>
        </div>

        {/* Tabel Sesi */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm" data-testid="tabel-sesi-aktif">
            <thead>
              <tr className="border-b border-neutral-200 text-neutral-600">
                <th className="py-2.5">Staf Masuk</th>
                <th className="py-2.5">Perangkat POS</th>
                <th className="py-2.5">Cabang</th>
                <th className="py-2.5">Waktu Mulai</th>
                <th className="py-2.5">Status</th>
                <th className="py-2.5 text-right">Tindakan Keamanan</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-neutral-100">
              {sesiTersaring.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-neutral-400">
                    Tidak ada sesi yang cocok dengan kriteria pencarian.
                  </td>
                </tr>
              ) : (
                sesiTersaring.map((sesi) => {
                  const adalahSesiSaya = sesiSayaId === sesi.sessionId
                  const sesiAktif = sesi.status === 'aktif'
                  const perangkatHilang = sesi.statusPerangkat === 'hilang'

                  return (
                    <tr
                      key={sesi.sessionId}
                      className={`hover:bg-neutral-50/60 ${adalahSesiSaya ? 'bg-amber-50/40' : ''}`}
                      data-testid={`baris-sesi-${sesi.sessionId}`}
                    >
                      <td className="py-3">
                        <div className="font-semibold text-neutral-900 flex items-center gap-1.5">
                          {sesi.namaPengguna}
                          {adalahSesiSaya && (
                            <span className="text-[10px] bg-amber-200 text-amber-900 px-1.5 py-0.5 rounded font-bold">
                              PERANGKAT INI
                            </span>
                          )}
                        </div>
                        <div className="text-xs text-neutral-500">{sesi.emailPengguna}</div>
                        <div className="mt-1">
                          <Lencana nada="netral">{sesi.peran.toUpperCase()}</Lencana>
                        </div>
                      </td>

                      <td className="py-3">
                        <div className="font-medium text-neutral-800">{sesi.namaPerangkat}</div>
                        <div className="text-xs text-neutral-500 capitalize">
                          Jenis: {sesi.jenisPerangkat}
                        </div>
                        {perangkatHilang && (
                          <div className="mt-0.5">
                            <Lencana nada="danger">PERANGKAT HILANG</Lencana>
                          </div>
                        )}
                      </td>

                      <td className="py-3 text-neutral-600">{sesi.namaCabang ?? 'Cabang Utama'}</td>

                      <td className="py-3 text-xs text-neutral-600">
                        <div>{formatWaktu(sesi.mulai)}</div>
                        <div className="text-neutral-400">
                          Batas: {formatWaktu(sesi.berakhirPada)}
                        </div>
                      </td>

                      <td className="py-3">
                        {sesiAktif ? (
                          <span className="inline-flex items-center gap-1.5 text-emerald-700 font-medium text-xs">
                            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                            Aktif
                          </span>
                        ) : sesi.status === 'dicabut' ? (
                          <Lencana nada="danger">Dicabut</Lencana>
                        ) : (
                          <Lencana nada="netral">Selesai</Lencana>
                        )}
                      </td>

                      <td className="py-3 text-right">
                        <div className="flex flex-col sm:flex-row items-end sm:items-center justify-end gap-1.5">
                          {sesiAktif && (
                            <Tombol
                              ragam="bahaya"
                              onClick={() => bukaModalAkhiriSesi(sesi)}
                              nama={`Akhiri sesi ${sesi.namaPengguna}`}
                            >
                              Akhiri Sesi
                            </Tombol>
                          )}

                          {sesiAktif && (
                            <Tombol
                              ragam="biasa"
                              onClick={() => bukaModalKeluarSemua(sesi)}
                              nama={`Keluarkan semua sesi ${sesi.namaPengguna}`}
                            >
                              Keluarkan Semua
                            </Tombol>
                          )}

                          {!perangkatHilang && (
                            <Tombol
                              ragam="polos"
                              onClick={() => bukaModalPerangkatHilang(sesi)}
                              nama={`Tandai ${sesi.namaPerangkat} hilang`}
                            >
                              Tandai Hilang
                            </Tombol>
                          )}
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* Modal Konfirmasi: Akhiri Sesi Tunggal */}
      {targetAkhiriSesi && (
        <Lapis
          buka={true}
          onTutup={() => setTargetAkhiriSesi(null)}
          judul="Konfirmasi Akhiri Sesi Staf"
        >
          <div className="p-4 space-y-4" data-testid="dialog-akhiri-sesi">
            <div className="p-3 bg-amber-50 border border-amber-200 rounded text-sm text-amber-900">
              <p className="font-semibold mb-1">
                Putuskan sesi aktif untuk {targetAkhiriSesi.namaPengguna}?
              </p>
              <p className="text-xs">
                Perangkat &quot;{targetAkhiriSesi.namaPerangkat}&quot; akan langsung keluar
                seketika. Staf terkait harus memasukkan ulang PIN untuk masuk kembali.
              </p>
            </div>

            <KolomIsian
              label="Alasan Pengakhiran (Tercatat di Jejak Audit Resto)"
              nilai={alasan}
              onUbah={setAlasan}
              contoh="Contoh: Pegawai selesai shift / pergantian tugas"
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol
                ragam="biasa"
                onClick={() => setTargetAkhiriSesi(null)}
                nonaktif={sedangProses}
              >
                Batal
              </Tombol>
              <Tombol ragam="bahaya" onClick={eksekusiAkhiriSesi} nonaktif={sedangProses}>
                {sedangProses ? 'Memproses...' : 'Ya, Akhiri Sesi Sekarang'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Konfirmasi: Keluar Semua Perangkat */}
      {targetKeluarSemua && (
        <Lapis
          buka={true}
          onTutup={() => setTargetKeluarSemua(null)}
          judul="Keluarkan Dari Seluruh Perangkat"
        >
          <div className="p-4 space-y-4" data-testid="dialog-keluar-semua">
            <div className="p-3 bg-orange-50 border border-orange-200 rounded text-sm text-orange-950">
              <p className="font-semibold mb-1">
                Keluarkan {targetKeluarSemua.namaPengguna} dari SELURUH perangkat?
              </p>
              <p className="text-xs">
                Semua sesi aktif staf ini di tablet mana pun akan diputus seketika. Sangat
                disarankan bila PIN pegawai sempat diketahui pihak lain atau terjadi indikasi
                penyalahgunaan.
              </p>
            </div>

            <KolomIsian
              label="Alasan Pencabutan Seluruh Sesi (Wajib untuk Audit)"
              nilai={alasan}
              onUbah={setAlasan}
              contoh="Contoh: Reset keamanan / staf cuti mendadak"
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol
                ragam="biasa"
                onClick={() => setTargetKeluarSemua(null)}
                nonaktif={sedangProses}
              >
                Batal
              </Tombol>
              <Tombol ragam="bahaya" onClick={eksekusiKeluarSemua} nonaktif={sedangProses}>
                {sedangProses ? 'Memproses...' : 'Keluarkan Dari Semua Tablet'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Konfirmasi: Tandai Perangkat Hilang */}
      {targetPerangkatHilang && (
        <Lapis
          buka={true}
          onTutup={() => setTargetPerangkatHilang(null)}
          judul="Peringatan Keamanan: Tandai Perangkat Hilang"
        >
          <div className="p-4 space-y-4" data-testid="dialog-perangkat-hilang">
            <div className="p-3.5 bg-red-50 border border-red-300 rounded text-sm text-red-900">
              <p className="font-bold mb-1 text-red-800">
                🚨 BAHAYA KEAMANAN: Perangkat &quot;{targetPerangkatHilang.namaPerangkat}&quot; akan
                DIBLOKIR TOTAL!
              </p>
              <p className="text-xs leading-relaxed">
                Seluruh sesi staf di tablet ini langsung terputus di basis data seketika. Perangkat
                ini tidak akan bisa dipakai lagi untuk mengakses data restoran maupun kasir hingga
                didaftarkan ulang secara resmi oleh Owner.
              </p>
            </div>

            <KolomIsian
              label="Keterangan Hilang / Dicuri (Wajib Dicatat di Buku Jejak Audit)"
              nilai={alasan}
              onUbah={setAlasan}
              contoh="Contoh: Tablet kasir tertinggal di ojek / hilang saat jam tutup"
              wajib
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol
                ragam="biasa"
                onClick={() => setTargetPerangkatHilang(null)}
                nonaktif={sedangProses}
              >
                Batal
              </Tombol>
              <Tombol
                ragam="bahaya"
                onClick={eksekusiTandaiHilang}
                nonaktif={sedangProses || !alasan.trim()}
              >
                {sedangProses ? 'Memblokir...' : 'Tandai Hilang & Blokir Seketika'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
