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
      <div className="tutup-kas-wadah" style={{ textAlign: 'center' }}>
        <div
          style={{
            width: '64px',
            height: '64px',
            borderRadius: '50%',
            background: 'var(--success-soft)',
            color: 'var(--success)',
            display: 'grid',
            placeItems: 'center',
            fontSize: '28px',
            margin: '0 auto',
            fontWeight: 'bold',
          }}
        >
          ✓
        </div>
        <div>
          <h3 style={{ fontWeight: 800, fontSize: 'var(--t-5)', color: 'var(--text)', margin: 0 }}>
            Shift Kas Berhasil Ditutup!
          </h3>
          <p style={{ fontSize: 'var(--t-2)', color: 'var(--text-muted)', marginTop: '4px' }}>
            Rekonsiliasi uang fisik dan pencatatan audit telah selesai.
          </p>
        </div>

        <div className="kotak-rincian-kas" style={{ textAlign: 'left' }}>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Cabang:</span>
            <span style={{ fontWeight: 600 }}>{namaCabang}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Petugas Penutup:</span>
            <span style={{ fontWeight: 600 }}>{namaKasir}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Modal Awal:</span>
            <span style={{ fontWeight: 600, color: 'var(--text)' }}>{rupiah(hasil.modalAwal)}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Uang Seharusnya:</span>
            <span style={{ fontWeight: 600, color: 'var(--text)' }}>
              {rupiah(hasil.uangSeharusnya)}
            </span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Uang Fisik Dihitung:</span>
            <span style={{ fontWeight: 800, color: 'var(--text)' }}>{rupiah(hasil.uangFisik)}</span>
          </div>
          <div
            className="kotak-rincian-kas__baris"
            style={{ paddingTop: '4px', borderTop: '1px solid var(--border)' }}
          >
            <span style={{ fontWeight: 700 }}>Selisih Kas:</span>
            <span
              style={{
                fontWeight: 800,
                color: hasil.selisih === 0 ? 'var(--success)' : 'var(--danger)',
              }}
            >
              {hasil.selisih > 0 ? `+${rupiah(hasil.selisih)}` : rupiah(hasil.selisih)}
            </span>
          </div>
          {hasil.alasanSelisih && (
            <div style={{ paddingTop: '4px', fontSize: 'var(--t-2)' }}>
              <span style={{ color: 'var(--text-muted)', display: 'block' }}>Alasan Selisih:</span>
              <span style={{ fontStyle: 'italic', color: 'var(--text)' }}>
                {hasil.alasanSelisih}
              </span>
            </div>
          )}
        </div>

        <div style={{ paddingTop: 'var(--s-2)' }}>
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
    <div className="tutup-kas-wadah">
      {/* Header Info */}
      <div>
        <h2
          style={{
            fontFamily: 'var(--font-display)',
            fontWeight: 800,
            fontSize: 'var(--t-6)',
            margin: 0,
          }}
        >
          Tutup Shift Kasir
        </h2>
        <p style={{ fontSize: 'var(--t-2)', color: 'var(--text-muted)', marginTop: '4px' }}>
          Hitung uang fisik di laci kas dan bandingkan dengan catatan sistem.
        </p>
      </div>

      {/* Ringkasan Shift Aktif */}
      <div className="kotak-rincian-kas">
        <div className="kotak-rincian-kas__baris">
          <span style={{ color: 'var(--text-muted)' }}>Cabang:</span>
          <span style={{ fontWeight: 600 }}>
            {namaCabang} ({cabangId})
          </span>
        </div>
        <div className="kotak-rincian-kas__baris">
          <span style={{ color: 'var(--text-muted)' }}>Kasir:</span>
          <span style={{ fontWeight: 600 }}>{namaKasir}</span>
        </div>
        <div className="kotak-rincian-kas__baris">
          <span style={{ color: 'var(--text-muted)' }}>Modal Awal:</span>
          <span style={{ fontWeight: 600 }}>{rupiah(modalAwal)}</span>
        </div>
        {adaUangSeharusnya && (
          <div
            className="kotak-rincian-kas__baris"
            style={{ paddingTop: '4px', borderTop: '1px solid var(--border)' }}
          >
            <span style={{ fontWeight: 700 }}>Uang Seharusnya (Sistem):</span>
            <span style={{ fontWeight: 800, color: 'var(--text)' }}>
              {rupiah(uangSeharusnyaPerkiraan)}
            </span>
          </div>
        )}
        {dibukaPada && (
          <div
            className="kotak-rincian-kas__baris"
            style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}
          >
            <span>Dibuka Pada:</span>
            <span>{new Date(dibukaPada).toLocaleString('id-ID')}</span>
          </div>
        )}
      </div>

      {/* Pesan Kesalahan */}
      {galatDitampilkan && (
        <div
          style={{
            padding: 'var(--s-3)',
            background: 'var(--danger-soft)',
            border: '1px solid var(--danger)',
            borderRadius: 'var(--radius)',
            fontSize: 'var(--t-2)',
            color: 'var(--danger)',
            display: 'flex',
            gap: 'var(--s-2)',
          }}
        >
          <span>⚠️</span>
          <span>{galatDitampilkan}</span>
        </div>
      )}

      {/* Form Tutup Shift */}
      {!konfirmasi ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
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
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-1)' }}>
            <span
              style={{
                fontSize: 'var(--t-1)',
                fontWeight: 700,
                color: 'var(--text-muted)',
                textTransform: 'uppercase',
              }}
            >
              Bantuan Input:
            </span>
            <div className="uang-cepat-grid">
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
              className="kotak-selisih"
              style={{
                borderColor: selisihPerkiraan === 0 ? 'var(--success)' : 'var(--warn)',
                background: selisihPerkiraan === 0 ? 'var(--success-soft)' : 'var(--warn-soft)',
                display: 'flex',
                flexDirection: 'row',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <div>
                <span
                  style={{
                    fontSize: 'var(--t-2)',
                    fontWeight: 700,
                    display: 'block',
                    color: 'var(--text)',
                  }}
                >
                  {selisihPerkiraan === 0
                    ? 'Hasil Hitung Pas'
                    : selisihPerkiraan > 0
                      ? 'Kas Lebih'
                      : 'Kas Kurang'}
                </span>
                <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                  Fisik {rupiah(Math.round(uangFisikBersih))} vs Seharusnya{' '}
                  {rupiah(uangSeharusnyaPerkiraan)}
                </span>
              </div>
              <span
                data-testid="nilai-selisih"
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--t-5)',
                  fontWeight: 800,
                  color: 'var(--text)',
                }}
              >
                {selisihPerkiraan > 0 ? `+${rupiah(selisihPerkiraan)}` : rupiah(selisihPerkiraan)}
              </span>
            </div>
          )}

          {/* Kolom Alasan Selisih (Wajib jika ada selisih) */}
          {adaSelisih && (
            <div
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--s-2)',
                padding: 'var(--s-3)',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius)',
                border: '1px solid var(--border)',
              }}
            >
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

              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-1)' }}>
                <span
                  style={{ fontSize: 'var(--t-1)', fontWeight: 700, color: 'var(--text-muted)' }}
                >
                  Pilihan Cepat:
                </span>
                <div className="chips-baris">
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
          <div style={{ display: 'flex', gap: 'var(--s-2)', paddingTop: 'var(--s-2)' }}>
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
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
            padding: 'var(--s-4)',
            background: 'var(--warn-soft)',
            borderRadius: 'var(--radius)',
            border: '1px solid var(--warn)',
          }}
        >
          <div>
            <h4
              style={{ fontWeight: 800, fontSize: 'var(--t-4)', color: 'var(--warn)', margin: 0 }}
            >
              Konfirmasi Penutupan Shift
            </h4>
            <p style={{ fontSize: 'var(--t-2)', marginTop: '4px' }}>
              Periksa kembali rekonsiliasi kas di bawah ini. Setelah shift ditutup, data kas menjadi
              beku dan tidak dapat diubah lagi.
            </p>
          </div>

          <div
            style={{
              padding: 'var(--s-3)',
              background: 'var(--surface)',
              borderRadius: 'var(--radius-sm)',
              border: '1px solid var(--border)',
              fontSize: 'var(--t-3)',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--text-muted)' }}>Uang Fisik Dihitung:</span>
              <span style={{ fontWeight: 800, color: 'var(--text)' }}>
                {rupiah(Math.round(uangFisikBersih))}
              </span>
            </div>
            {adaUangSeharusnya && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Uang Seharusnya:</span>
                <span style={{ fontWeight: 600 }}>{rupiah(uangSeharusnyaPerkiraan)}</span>
              </div>
            )}
            {adaUangSeharusnya && (
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  marginTop: '4px',
                  paddingTop: '4px',
                  borderTop: '1px solid var(--border)',
                }}
              >
                <span style={{ fontWeight: 700 }}>Selisih:</span>
                <span
                  style={{
                    fontWeight: 800,
                    color: selisihPerkiraan === 0 ? 'var(--success)' : 'var(--danger)',
                  }}
                >
                  {selisihPerkiraan > 0 ? `+${rupiah(selisihPerkiraan)}` : rupiah(selisihPerkiraan)}
                </span>
              </div>
            )}
            {alasanInput.trim() && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Alasan:</span>
                <span style={{ fontStyle: 'italic' }}>{alasanInput.trim()}</span>
              </div>
            )}
            {catatanInput.trim() && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Catatan:</span>
                <span style={{ fontStyle: 'italic' }}>{catatanInput.trim()}</span>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', gap: 'var(--s-2)', paddingTop: 'var(--s-2)' }}>
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
