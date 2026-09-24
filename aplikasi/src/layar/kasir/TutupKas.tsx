/**
 * TutupKas — Layar Penutupan Shift Kasir & Rekonsiliasi Kas (T7-02).
 *
 * Mengikuti aturan PRD M7 dan TECH_SPEC §4.3 & §9 ART-6:
 *  - Sistem menghitung uang seharusnya (modal_awal + penerimaan tunai - pengeluaran tunai).
 *  - Kasir memasukkan hasil hitung fisik uang di laci.
 *  - Bila ada selisih (fisik != seharusnya) -> alasan selisih WAJIB diisi.
 *  - Shift ditutup menjadi beku dan mencatat siapa penutup & kapan ditutup.
 *  - Jejak audit kriptografis berantai hash otomatis tersimpan di peladen.
 *
 * Berkas ini komponen UI murni: tidak ada pemanggilan jaringan langsung di dalamnya.
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'

export interface TutupKasHasilData {
  shiftId: string
  cabangId: string
  modalAwal: number
  tunaiMasuk: number
  tunaiKeluar: number
  uangSeharusnya: number
  uangFisik: number
  selisih: number
  alasanSelisih?: string | null
  status: string
  ditutupPada?: string
}

export type HasilTutupKas = {
  sukses: boolean
  pesan?: string
  data?: TutupKasHasilData
}

export interface TutupKasProps {
  shiftId?: string
  cabangId?: string
  namaCabang?: string
  namaKasir?: string
  dibukaPada?: string
  modalAwal?: number
  uangSeharusnyaPerkiraan?: number
  keadaan?: 'siap' | 'mengirim' | 'berhasil' | 'gagal'
  pesanGalat?: string | null
  onTutupShift?: (masukan: {
    uangFisik: number
    alasanSelisih?: string
    catatan?: string
    shiftId?: string
  }) => Promise<{ sukses: boolean; pesan?: string; data?: TutupKasHasilData } | void> | void
  onBatal?: () => void
  onSelesai?: () => void
}

const ALASAN_CEPAT = [
  'Kembalian receh tidak diambil pelanggan',
  'Kekurangan uang receh pecahan kecil',
  'Salah input saat transaksi tunai',
  'Selisih uang fisik laci kas',
]

const TOMBOL_TAMBAH_UANG = [10000, 20000, 50000, 100000]

export function TutupKas({
  shiftId,
  cabangId = 'cab-01',
  namaCabang = 'Cabang Utama',
  namaKasir = 'Kasir Bertugas',
  dibukaPada,
  modalAwal = 0,
  uangSeharusnyaPerkiraan,
  keadaan = 'siap',
  pesanGalat = null,
  onTutupShift,
  onBatal,
  onSelesai,
}: TutupKasProps) {
  const [uangFisikInput, setUangFisikInput] = useState<string>('')
  const [alasanInput, setAlasanInput] = useState<string>('')
  const [catatanInput, setCatatanInput] = useState<string>('')
  const [konfirmasi, setKonfirmasi] = useState<boolean>(false)
  const [galatLokal, setGalatLokal] = useState<string | null>(null)
  const [statusLokal, setStatusLokal] = useState<'siap' | 'mengirim' | 'berhasil' | 'gagal'>(
    keadaan,
  )
  const [ringkasanHasil, setRingkasanHasil] = useState<TutupKasHasilData | null>(null)

  // Nilai nominal uang fisik yang diparsing
  const uangFisikBersih = uangFisikInput.trim() === '' ? NaN : Number(uangFisikInput)
  const nominalValid = !Number.isNaN(uangFisikBersih) && uangFisikBersih >= 0

  // Perhitungan selisih perkiraan (jika uangSeharusnyaPerkiraan tersedia)
  const adaUangSeharusnya = uangSeharusnyaPerkiraan !== undefined
  const selisihPerkiraan =
    adaUangSeharusnya && nominalValid ? Math.round(uangFisikBersih) - uangSeharusnyaPerkiraan : 0
  const adaSelisih = adaUangSeharusnya && selisihPerkiraan !== 0

  const statusAktif = statusLokal === 'mengirim' || keadaan === 'mengirim'
  const galatDitampilkan = galatLokal || pesanGalat

  const tanganiUangPas = () => {
    if (uangSeharusnyaPerkiraan !== undefined) {
      setUangFisikInput(String(uangSeharusnyaPerkiraan))
      setGalatLokal(null)
    }
  }

  const tanganiTambahUang = (nilai: number) => {
    const saatIni = Number.isNaN(uangFisikBersih) ? 0 : Math.round(uangFisikBersih)
    setUangFisikInput(String(saatIni + nilai))
    setGalatLokal(null)
  }

  const tanganiPilihAlasanCepat = (alasan: string) => {
    setAlasanInput(alasan)
    setGalatLokal(null)
  }

  const validasiSebelumKonfirmasi = () => {
    if (!nominalValid) {
      setGalatLokal('Jumlah uang fisik wajib diisi dengan nominal angka (minimal Rp0).')
      return false
    }

    // Jika sistem mengetahui perkiraan uang seharusnya dan ada selisih, alasan wajib diisi
    if (adaSelisih && alasanInput.trim() === '') {
      setGalatLokal(
        'Alasan selisih wajib diisi jika hasil hitung fisik berbeda dari uang seharusnya.',
      )
      return false
    }

    setGalatLokal(null)
    return true
  }

  const tanganiKirimTutupKas = async () => {
    if (!nominalValid) {
      setGalatLokal('Jumlah uang fisik wajib diisi dengan nominal angka.')
      return
    }

    setGalatLokal(null)
    setStatusLokal('mengirim')

    try {
      const payload = {
        uangFisik: Math.round(uangFisikBersih),
        alasanSelisih: alasanInput.trim() || undefined,
        catatan: catatanInput.trim() || undefined,
        shiftId: shiftId || undefined,
      }

      const res = await onTutupShift?.(payload)

      if (res && !res.sukses) {
        setStatusLokal('gagal')
        setGalatLokal(res.pesan || 'Gagal menutup shift kasir.')
      } else {
        setStatusLokal('berhasil')
        if (res && res.data) {
          setRingkasanHasil(res.data)
        }
      }
    } catch (e) {
      setStatusLokal('gagal')
      const pesan = e instanceof Error ? e.message : 'Terjadi kesalahan saat menutup shift.'
      setGalatLokal(pesan)
    }
  }

  // Jika shift berhasil ditutup
  if (statusLokal === 'berhasil' || keadaan === 'berhasil') {
    const hasil = ringkasanHasil || {
      shiftId: shiftId || '-',
      cabangId,
      modalAwal,
      tunaiMasuk: 0,
      tunaiKeluar: 0,
      uangSeharusnya: uangSeharusnyaPerkiraan ?? Math.round(uangFisikBersih || 0),
      uangFisik: Math.round(uangFisikBersih || 0),
      selisih: selisihPerkiraan,
      alasanSelisih: alasanInput.trim() || null,
      status: 'ditutup',
    }

    return (
      <div className="tutup-kas-berhasil p-6 max-w-lg mx-auto bg-white rounded-2xl border border-emerald-200 shadow-sm space-y-5 text-center">
        <div className="w-16 h-16 bg-emerald-100 text-emerald-700 rounded-full flex items-center justify-center text-3xl mx-auto">
          ✓
        </div>
        <div>
          <h3 className="font-bold text-lg text-emerald-900">Shift Kas Berhasil Ditutup!</h3>
          <p className="text-xs text-neutral-500 mt-1">
            Rekonsiliasi uang fisik dan pencatatan audit telah selesai.
          </p>
        </div>

        <div className="p-4 bg-neutral-50 rounded-xl space-y-2 text-sm text-neutral-700 border border-neutral-200 text-left">
          <div className="flex justify-between">
            <span className="text-neutral-500">Cabang:</span>
            <span className="font-semibold">{namaCabang}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Petugas Penutup:</span>
            <span className="font-semibold">{namaKasir}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Modal Awal:</span>
            <span className="font-medium text-neutral-900">{rupiah(hasil.modalAwal)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Uang Seharusnya:</span>
            <span className="font-medium text-neutral-900">{rupiah(hasil.uangSeharusnya)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Uang Fisik Dihitung:</span>
            <span className="font-bold text-neutral-900">{rupiah(hasil.uangFisik)}</span>
          </div>
          <div className="flex justify-between pt-1 border-t border-neutral-200">
            <span className="text-neutral-500 font-semibold">Selisih Kas:</span>
            <span
              className={`font-bold ${
                hasil.selisih === 0
                  ? 'text-emerald-700'
                  : hasil.selisih > 0
                    ? 'text-blue-700'
                    : 'text-red-700'
              }`}
            >
              {hasil.selisih > 0 ? `+${rupiah(hasil.selisih)}` : rupiah(hasil.selisih)}
            </span>
          </div>
          {hasil.alasanSelisih && (
            <div className="pt-1 text-xs">
              <span className="text-neutral-400 block">Alasan Selisih:</span>
              <span className="italic text-neutral-700 font-medium">{hasil.alasanSelisih}</span>
            </div>
          )}
        </div>

        <div className="pt-2">
          {onSelesai && (
            <Tombol ragam="utama" lebar onClick={onSelesai}>
              Selesai & Keluar
            </Tombol>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="tutup-kas-wadah p-6 max-w-lg mx-auto bg-white rounded-2xl border border-neutral-200 shadow-sm space-y-5">
      {/* Header Info */}
      <div>
        <h2 className="font-extrabold text-xl text-neutral-900">Tutup Shift Kasir</h2>
        <p className="text-xs text-neutral-500 mt-1">
          Hitung uang fisik di laci kas dan bandingkan dengan catatan sistem.
        </p>
      </div>

      {/* Ringkasan Shift Aktif */}
      <div className="p-3.5 bg-neutral-50 rounded-xl space-y-2 text-xs text-neutral-600 border border-neutral-200">
        <div className="flex justify-between">
          <span className="text-neutral-400">Cabang:</span>
          <span className="font-medium text-neutral-800">
            {namaCabang} ({cabangId})
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-neutral-400">Kasir:</span>
          <span className="font-medium text-neutral-800">{namaKasir}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-neutral-400">Modal Awal:</span>
          <span className="font-semibold text-neutral-900">{rupiah(modalAwal)}</span>
        </div>
        {adaUangSeharusnya && (
          <div className="flex justify-between pt-1 border-t border-neutral-200">
            <span className="text-neutral-500 font-semibold">Uang Seharusnya (Sistem):</span>
            <span className="font-bold text-neutral-900">{rupiah(uangSeharusnyaPerkiraan)}</span>
          </div>
        )}
        {dibukaPada && (
          <div className="flex justify-between text-[11px] text-neutral-400">
            <span>Dibuka Pada:</span>
            <span>{new Date(dibukaPada).toLocaleString('id-ID')}</span>
          </div>
        )}
      </div>

      {/* Pesan Kesalahan */}
      {galatDitampilkan && (
        <div className="p-3.5 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 flex items-start gap-2">
          <span className="text-base leading-none">⚠️</span>
          <span>{galatDitampilkan}</span>
        </div>
      )}

      {/* Form Tutup Shift */}
      {!konfirmasi ? (
        <div className="space-y-4">
          <KolomIsian
            label="Uang Fisik di Laci Kas"
            nilai={uangFisikInput}
            onUbah={(v) => {
              setUangFisikInput(v)
              setGalatLokal(null)
            }}
            jenis="number"
            wajib
            contoh="0"
            keterangan="Masukkan total uang tunai yang ada di laci saat shift ditutup."
          />

          {/* Tombol Bantuan Hitung / Uang Cepat */}
          <div className="space-y-1.5">
            <span className="text-xs font-semibold text-neutral-500">Bantuan Input:</span>
            <div className="flex flex-wrap gap-2">
              {adaUangSeharusnya && (
                <Tombol ragam="kecil" onClick={tanganiUangPas}>
                  Uang Pas ({rupiah(uangSeharusnyaPerkiraan)})
                </Tombol>
              )}
              {TOMBOL_TAMBAH_UANG.map((nominal) => (
                <Tombol key={nominal} ragam="kecil" onClick={() => tanganiTambahUang(nominal)}>
                  +{rupiah(nominal)}
                </Tombol>
              ))}
              <Tombol
                ragam="kecil"
                onClick={() => {
                  setUangFisikInput('0')
                  setGalatLokal(null)
                }}
              >
                Reset Rp0
              </Tombol>
            </div>
          </div>

          {/* Perbandingan Selisih Real-Time */}
          {nominalValid && adaUangSeharusnya && (
            <div
              data-testid="wadah-selisih"
              className={`p-3.5 rounded-xl border flex items-center justify-between ${
                selisihPerkiraan === 0
                  ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
                  : selisihPerkiraan > 0
                    ? 'bg-blue-50 border-blue-200 text-blue-900'
                    : 'bg-red-50 border-red-200 text-red-900'
              }`}
            >
              <div>
                <span className="text-xs font-medium block">
                  {selisihPerkiraan === 0
                    ? 'Hasil Hitung Pas'
                    : selisihPerkiraan > 0
                      ? 'Kas Lebih'
                      : 'Kas Kurang'}
                </span>
                <span className="text-xs opacity-75">
                  Fisik {rupiah(Math.round(uangFisikBersih))} vs Seharusnya{' '}
                  {rupiah(uangSeharusnyaPerkiraan)}
                </span>
              </div>
              <span data-testid="nilai-selisih" className="text-lg font-extrabold">
                {selisihPerkiraan > 0
                  ? `+${rupiah(selisihPerkiraan)}`
                  : rupiah(selisihPerkiraan)}
              </span>
            </div>
          )}

          {/* Kolom Alasan Selisih (Wajib jika ada selisih) */}
          {adaSelisih && (
            <div className="space-y-2 p-3 bg-neutral-50 rounded-xl border border-neutral-200">
              <KolomIsian
                label="Alasan Selisih Kas (Wajib)"
                nilai={alasanInput}
                onUbah={(v) => {
                  setAlasanInput(v)
                  setGalatLokal(null)
                }}
                wajib
                contoh="Contoh: Kembalian tidak diambil pelanggan Rp500"
                keterangan="Wajib mencatat alasan bila uang fisik tidak sama dengan catatan sistem."
              />

              <div className="space-y-1">
                <span className="text-[11px] font-semibold text-neutral-400">Pilihan Cepat:</span>
                <div className="flex flex-wrap gap-1.5">
                  {ALASAN_CEPAT.map((alasan) => (
                    <Tombol
                      key={alasan}
                      ragam="kecil"
                      onClick={() => tanganiPilihAlasanCepat(alasan)}
                    >
                      {alasan}
                    </Tombol>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Catatan Opsional */}
          <KolomIsian
            label="Catatan Penutupan (Opsional)"
            nilai={catatanInput}
            onUbah={setCatatanInput}
            contoh="Catatan serah terima kas atau kondisi laci"
          />

          {/* Tombol Aksi */}
          <div className="flex gap-3 pt-3">
            <Tombol
              ragam="utama"
              lebar
              nonaktif={!nominalValid || statusAktif}
              onClick={() => {
                if (validasiSebelumKonfirmasi()) {
                  setKonfirmasi(true)
                }
              }}
            >
              Lanjut Tutup Kas
            </Tombol>
            {onBatal && (
              <Tombol ragam="biasa" onClick={onBatal}>
                Batal
              </Tombol>
            )}
          </div>
        </div>
      ) : (
        /* Langkah Konfirmasi */
        <div className="space-y-4 p-4 bg-amber-50 rounded-xl border border-amber-200">
          <div>
            <h4 className="font-bold text-sm text-amber-900">Konfirmasi Penutupan Shift</h4>
            <p className="text-xs text-amber-800 mt-1">
              Periksa kembali rekonsiliasi kas di bawah ini. Setelah shift ditutup, data kas menjadi
              beku dan tidak dapat diubah lagi.
            </p>
          </div>

          <div className="p-3 bg-white rounded-lg border border-amber-200 text-sm space-y-1.5">
            <div className="flex justify-between">
              <span className="text-neutral-500 text-xs">Uang Fisik Dihitung:</span>
              <span className="font-bold text-neutral-900">
                {rupiah(Math.round(uangFisikBersih))}
              </span>
            </div>
            {adaUangSeharusnya && (
              <div className="flex justify-between">
                <span className="text-neutral-500 text-xs">Uang Seharusnya:</span>
                <span className="font-medium text-neutral-800">
                  {rupiah(uangSeharusnyaPerkiraan)}
                </span>
              </div>
            )}
            {adaUangSeharusnya && (
              <div className="flex justify-between pt-1 border-t border-neutral-100">
                <span className="text-neutral-500 text-xs font-semibold">Selisih:</span>
                <span
                  className={`font-bold text-xs ${
                    selisihPerkiraan === 0
                      ? 'text-emerald-700'
                      : selisihPerkiraan > 0
                        ? 'text-blue-700'
                        : 'text-red-700'
                  }`}
                >
                  {selisihPerkiraan > 0 ? `+${rupiah(selisihPerkiraan)}` : rupiah(selisihPerkiraan)}
                </span>
              </div>
            )}
            {alasanInput.trim() && (
              <div className="pt-1 text-xs">
                <span className="text-neutral-400 block">Alasan:</span>
                <span className="italic text-neutral-800 font-medium">{alasanInput.trim()}</span>
              </div>
            )}
          </div>

          <div className="flex gap-2 pt-2">
            <Tombol ragam="utama" lebar nonaktif={statusAktif} onClick={tanganiKirimTutupKas}>
              {statusAktif ? 'Menutup Shift...' : 'Ya, Tutup Shift Sekarang'}
            </Tombol>
            <Tombol ragam="biasa" nonaktif={statusAktif} onClick={() => setKonfirmasi(false)}>
              Ubah
            </Tombol>
          </div>
        </div>
      )}
    </div>
  )
}
