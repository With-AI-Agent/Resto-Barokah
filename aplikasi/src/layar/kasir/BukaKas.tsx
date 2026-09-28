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
      <div className="buka-kas-wadah">
        <div className="kotak-peringatan">
          <span style={{ fontSize: '24px' }}>⚠️</span>
          <div>
            <h3 style={{ fontWeight: 700, fontSize: 'var(--t-4)', margin: 0 }}>
              Shift Kasir Sudah Aktif
            </h3>
            <p style={{ fontSize: 'var(--t-2)', margin: '4px 0 0' }}>
              Anda masih memiliki sesi shift kasir yang aktif di cabang ini.
            </p>
          </div>
        </div>

        <div className="kotak-rincian-kas">
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Cabang:</span>
            <span style={{ fontWeight: 600 }}>{namaCabang}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Kasir:</span>
            <span style={{ fontWeight: 600 }}>{namaKasir}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>ID Shift:</span>
            <span style={{ fontFamily: 'var(--mono)' }}>{shiftAktif.id}</span>
          </div>
          {shiftAktif.modalAwal !== undefined && (
            <div className="kotak-rincian-kas__baris">
              <span style={{ color: 'var(--text-muted)' }}>Modal Awal:</span>
              <span style={{ fontWeight: 800, color: 'var(--text)' }}>
                {rupiah(shiftAktif.modalAwal)}
              </span>
            </div>
          )}
          {shiftAktif.dibukaPada && (
            <div className="kotak-rincian-kas__baris">
              <span style={{ color: 'var(--text-muted)' }}>Waktu Buka:</span>
              <span style={{ fontSize: 'var(--t-2)' }}>
                {new Date(shiftAktif.dibukaPada).toLocaleString('id-ID')}
              </span>
            </div>
          )}
        </div>

        <div style={{ display: 'flex', gap: 'var(--s-2)', paddingTop: 'var(--s-2)' }}>
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
      <div className="buka-kas-wadah" style={{ textAlign: 'center' }}>
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
            Shift Berhasil Dibuka!
          </h3>
          <p style={{ fontSize: 'var(--t-2)', color: 'var(--text-muted)', marginTop: '4px' }}>
            {pesanHasil || 'Modal awal kasir telah dicatat di sistem.'}
          </p>
        </div>

        <div className="kotak-rincian-kas" style={{ textAlign: 'left' }}>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Cabang:</span>
            <span style={{ fontWeight: 600 }}>{namaCabang}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Kasir:</span>
            <span style={{ fontWeight: 600 }}>{namaKasir}</span>
          </div>
          <div className="kotak-rincian-kas__baris">
            <span style={{ color: 'var(--text-muted)' }}>Modal Awal:</span>
            <span style={{ fontWeight: 800, color: 'var(--accent)' }}>
              {nominalValid ? rupiah(Math.round(nominalBersih)) : '-'}
            </span>
          </div>
        </div>

        <div style={{ paddingTop: 'var(--s-2)' }}>
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
    <div className="buka-kas-wadah">
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
          Buka Shift Kasir
        </h2>
        <p style={{ fontSize: 'var(--t-2)', color: 'var(--text-muted)', marginTop: '4px' }}>
          Catat modal tunai awal di laci kas sebelum memulai transaksi transaksi hari ini.
        </p>
      </div>

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

      {/* Formulir Buka Shift */}
      {!konfirmasi ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
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
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-1)' }}>
            <span
              style={{
                fontSize: 'var(--t-1)',
                fontWeight: 700,
                color: 'var(--text-muted)',
                textTransform: 'uppercase',
              }}
            >
              Pilihan Cepat:
            </span>
            <div className="uang-cepat-grid">
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
            <div
              style={{
                padding: 'var(--s-3)',
                background: 'var(--accent-soft)',
                borderRadius: 'var(--radius)',
                border: '1px solid var(--accent)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
              }}
            >
              <span style={{ fontSize: 'var(--t-2)', fontWeight: 600, color: 'var(--accent)' }}>
                Pratinjau Modal:
              </span>
              <span
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: 'var(--t-5)',
                  fontWeight: 800,
                  color: 'var(--accent)',
                }}
              >
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
          <div style={{ display: 'flex', gap: 'var(--s-2)', paddingTop: 'var(--s-2)' }}>
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
              Konfirmasi Buka Shift
            </h4>
            <p style={{ fontSize: 'var(--t-2)', marginTop: '4px' }}>
              Periksa kembali data modal awal sebelum membuka shift. Modal awal tidak dapat diubah
              secara langsung setelah shift terbuka.
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
              <span style={{ color: 'var(--text-muted)' }}>Modal Awal:</span>
              <span style={{ fontWeight: 800, color: 'var(--text)' }}>
                {rupiah(Math.round(nominalBersih))}
              </span>
            </div>
            {catatanInput.trim() && (
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '4px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Catatan:</span>
                <span style={{ fontStyle: 'italic' }}>{catatanInput.trim()}</span>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', gap: 'var(--s-2)', paddingTop: 'var(--s-2)' }}>
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
