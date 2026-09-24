/**
 * BukaKas — Layar Pembukaan Shift Kasir & Perekaman Modal Awal (T7-01).
 *
 * Mengikuti aturan PRD M7 dan TECH_SPEC §4.3 & §9 ART-6:
 *  - Modal awal wajib diisi (tidak boleh kosong / negatif).
 *  - Satu shift terbuka per kasir per cabang (ditegakkan peladen di RPC `buka_shift`).
 *  - Siapa & kapan tercatat resmi di peladen.
 *  - Jejak audit berantai hash otomatis tercatat di `catatan_audit`.
 *
 * Berkas ini komponen UI murni: tidak ada pemanggilan jaringan langsung di dalamnya.
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'

export interface ShiftAktifInfo {
  id: string
  cabangId?: string
  dibukaPada?: string
  modalAwal?: number
}

export interface BukaKasProps {
  cabangId?: string
  namaCabang?: string
  namaKasir?: string
  shiftAktif?: ShiftAktifInfo | null
  keadaan?: 'siap' | 'mengirim' | 'berhasil' | 'gagal'
  pesanGalat?: string | null
  onBukaShift?: (masukan: {
    modalAwal: number
    catatan?: string
  }) => Promise<{ sukses: boolean; shiftId?: string; pesan?: string } | void> | void
  onBatal?: () => void
  onLanjut?: () => void
}

const TOMBOL_UANG_CEPAT = [50000, 100000, 200000, 500000]

export function BukaKas({
  cabangId = 'cab-01',
  namaCabang = 'Cabang Utama',
  namaKasir = 'Kasir Bertugas',
  shiftAktif = null,
  keadaan = 'siap',
  pesanGalat = null,
  onBukaShift,
  onBatal,
  onLanjut,
}: BukaKasProps) {
  const [modalAwalInput, setModalAwalInput] = useState<string>('')
  const [catatanInput, setCatatanInput] = useState<string>('')
  const [konfirmasi, setKonfirmasi] = useState<boolean>(false)
  const [galatLokal, setGalatLokal] = useState<string | null>(null)
  const [statusLokal, setStatusLokal] = useState<'siap' | 'mengirim' | 'berhasil' | 'gagal'>(
    keadaan,
  )
  const [pesanHasil, setPesanHasil] = useState<string | null>(null)

  // Nilai nominal modal awal yang diparsing
  const nominalBersih = modalAwalInput.trim() === '' ? NaN : Number(modalAwalInput)
  const nominalValid = !Number.isNaN(nominalBersih) && nominalBersih >= 0

  const statusAktif = statusLokal === 'mengirim' || keadaan === 'mengirim'
  const galatDitampilkan = galatLokal || pesanGalat

  const tanganiPilihUangCepat = (nilai: number) => {
    setModalAwalInput(String(nilai))
    setGalatLokal(null)
  }

  const tanganiBukaKas = async () => {
    if (!nominalValid) {
      setGalatLokal('Modal awal wajib diisi dengan nominal angka yang sah (minimal Rp0).')
      return
    }

    setGalatLokal(null)
    setStatusLokal('mengirim')

    try {
      const res = await onBukaShift?.({
        modalAwal: Math.round(nominalBersih),
        catatan: catatanInput.trim() || undefined,
      })

      if (res && !res.sukses) {
        setStatusLokal('gagal')
        setGalatLokal(res.pesan || 'Gagal membuka shift kasir.')
      } else {
        setStatusLokal('berhasil')
        setPesanHasil(res?.pesan || 'Shift kasir berhasil dibuka.')
      }
    } catch (e) {
      setStatusLokal('gagal')
      const pesan = e instanceof Error ? e.message : 'Terjadi kesalahan saat membuka shift.'
      setGalatLokal(pesan)
    }
  }

  // Jika kasir sudah memiliki shift aktif di cabang ini
  if (shiftAktif) {
    return (
      <div className="buka-kas-wadah p-6 max-w-lg mx-auto bg-white rounded-2xl border border-neutral-200 shadow-sm space-y-5">
        <div className="flex items-center gap-3 text-amber-700 bg-amber-50 p-4 rounded-xl border border-amber-200">
          <span className="text-2xl">⚠️</span>
          <div>
            <h3 className="font-bold text-base">Shift Kasir Sudah Aktif</h3>
            <p className="text-xs text-amber-800 mt-0.5">
              Anda masih memiliki sesi shift kasir yang aktif di cabang ini.
            </p>
          </div>
        </div>

        <div className="p-4 bg-neutral-50 rounded-xl space-y-2 text-sm text-neutral-700 border border-neutral-200">
          <div className="flex justify-between">
            <span className="text-neutral-500">Cabang:</span>
            <span className="font-semibold">{namaCabang}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Kasir:</span>
            <span className="font-semibold">{namaKasir}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">ID Shift:</span>
            <span className="font-mono text-xs">{shiftAktif.id}</span>
          </div>
          {shiftAktif.modalAwal !== undefined && (
            <div className="flex justify-between">
              <span className="text-neutral-500">Modal Awal:</span>
              <span className="font-bold text-neutral-900">{rupiah(shiftAktif.modalAwal)}</span>
            </div>
          )}
          {shiftAktif.dibukaPada && (
            <div className="flex justify-between">
              <span className="text-neutral-500">Waktu Buka:</span>
              <span className="text-xs">
                {new Date(shiftAktif.dibukaPada).toLocaleString('id-ID')}
              </span>
            </div>
          )}
        </div>

        <div className="flex gap-3 pt-2">
          {onLanjut && (
            <Tombol ragam="utama" lebar onClick={onLanjut}>
              Lanjut ke Kasir POS
            </Tombol>
          )}
          {onBatal && (
            <Tombol ragam="biasa" onClick={onBatal}>
              Tutup
            </Tombol>
          )}
        </div>
      </div>
    )
  }

  // Jika pembukaan shift berhasil
  if (statusLokal === 'berhasil' || keadaan === 'berhasil') {
    return (
      <div className="buka-kas-berhasil p-6 max-w-lg mx-auto bg-white rounded-2xl border border-emerald-200 shadow-sm space-y-5 text-center">
        <div className="w-16 h-16 bg-emerald-100 text-emerald-700 rounded-full flex items-center justify-center text-3xl mx-auto">
          ✓
        </div>
        <div>
          <h3 className="font-bold text-lg text-emerald-900">Shift Berhasil Dibuka!</h3>
          <p className="text-sm text-neutral-600 mt-1">
            {pesanHasil || 'Modal awal kasir telah dicatat di sistem.'}
          </p>
        </div>

        <div className="p-4 bg-neutral-50 rounded-xl space-y-2 text-sm text-neutral-700 border border-neutral-200 text-left">
          <div className="flex justify-between">
            <span className="text-neutral-500">Cabang:</span>
            <span className="font-semibold">{namaCabang}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Kasir:</span>
            <span className="font-semibold">{namaKasir}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-neutral-500">Modal Awal:</span>
            <span className="font-bold text-emerald-800">
              {nominalValid ? rupiah(Math.round(nominalBersih)) : '-'}
            </span>
          </div>
        </div>

        <div className="pt-2">
          {onLanjut && (
            <Tombol ragam="utama" lebar onClick={onLanjut}>
              Mulai Transaksi Kasir
            </Tombol>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="buka-kas-wadah p-6 max-w-lg mx-auto bg-white rounded-2xl border border-neutral-200 shadow-sm space-y-5">
      {/* Header Info */}
      <div>
        <h2 className="font-extrabold text-xl text-neutral-900">Buka Shift Kasir</h2>
        <p className="text-xs text-neutral-500 mt-1">
          Catat modal tunai awal di laci kas sebelum memulai transaksi transaksi hari ini.
        </p>
      </div>

      <div className="p-3 bg-neutral-50 rounded-xl space-y-1.5 text-xs text-neutral-600 border border-neutral-200">
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
      </div>

      {/* Pesan Kesalahan */}
      {galatDitampilkan && (
        <div className="p-3.5 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 flex items-start gap-2">
          <span className="text-base leading-none">⚠️</span>
          <span>{galatDitampilkan}</span>
        </div>
      )}

      {/* Formulir Buka Shift */}
      {!konfirmasi ? (
        <div className="space-y-4">
          <KolomIsian
            label="Modal Awal Kasir"
            nilai={modalAwalInput}
            onUbah={(v) => {
              setModalAwalInput(v)
              setGalatLokal(null)
            }}
            jenis="number"
            wajib
            contoh="0"
            keterangan="Hitung uang fisik di laci kas saat shift dimulai (tidak boleh negatif)."
          />

          {/* Tombol Uang Cepat */}
          <div className="space-y-1.5">
            <span className="text-xs font-semibold text-neutral-500">Pilihan Cepat:</span>
            <div className="flex flex-wrap gap-2">
              <Tombol ragam="kecil" onClick={() => tanganiPilihUangCepat(0)}>
                Rp0 (Nol)
              </Tombol>
              {TOMBOL_UANG_CEPAT.map((nominal) => (
                <Tombol key={nominal} ragam="kecil" onClick={() => tanganiPilihUangCepat(nominal)}>
                  {rupiah(nominal)}
                </Tombol>
              ))}
            </div>
          </div>

          {/* Pratinjau Nilai Format Rupiah */}
          {nominalValid && (
            <div className="p-3 bg-emerald-50 rounded-xl border border-emerald-200 flex items-center justify-between">
              <span className="text-xs text-emerald-800 font-medium">Pratinjau Modal:</span>
              <span className="text-base font-extrabold text-emerald-900">
                {rupiah(Math.round(nominalBersih))}
              </span>
            </div>
          )}

          {/* Catatan Opsional */}
          <KolomIsian
            label="Catatan Pembukaan (Opsional)"
            nilai={catatanInput}
            onUbah={setCatatanInput}
            contoh="Contoh: Pecahan 5rb dan 10rb untuk kembalian"
          />

          {/* Tombol Aksi */}
          <div className="flex gap-3 pt-3">
            <Tombol
              ragam="utama"
              lebar
              nonaktif={!nominalValid || statusAktif}
              onClick={() => {
                if (!nominalValid) {
                  setGalatLokal('Modal awal wajib diisi dengan nominal angka yang sah.')
                  return
                }
                setKonfirmasi(true)
              }}
            >
              Lanjut Buka Shift
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
            <h4 className="font-bold text-sm text-amber-900">Konfirmasi Buka Shift</h4>
            <p className="text-xs text-amber-800 mt-1">
              Periksa kembali data modal awal sebelum membuka shift. Modal awal tidak dapat diubah
              secara langsung setelah shift terbuka.
            </p>
          </div>

          <div className="p-3 bg-white rounded-lg border border-amber-200 text-sm space-y-1">
            <div className="flex justify-between">
              <span className="text-neutral-500 text-xs">Modal Awal:</span>
              <span className="font-bold text-neutral-900">
                {rupiah(Math.round(nominalBersih))}
              </span>
            </div>
            {catatanInput.trim() && (
              <div className="flex justify-between">
                <span className="text-neutral-500 text-xs">Catatan:</span>
                <span className="text-xs italic text-neutral-700">{catatanInput.trim()}</span>
              </div>
            )}
          </div>

          <div className="flex gap-2 pt-2">
            <Tombol ragam="utama" lebar nonaktif={statusAktif} onClick={tanganiBukaKas}>
              {statusAktif ? 'Membuka Shift...' : 'Ya, Buka Shift Sekarang'}
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
