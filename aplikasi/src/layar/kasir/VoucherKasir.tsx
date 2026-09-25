/**
 * VoucherKasir.tsx (T8-09) — Cek (baca saja) & Pakai (atomik + PIN) Voucher di Layar Kasir.
 *
 * Ref: PRD M10 (aturan voucher) & M3 (izin pakai voucher); TECH_SPEC §9 ART-5.
 *
 * Aturan & Jaminan Teknis:
 *  1. **Tombol Cek TIDAK mengubah apa pun (BACA SAJA):**
 *     Memanggil RPC `cek_voucher` untuk memeriksa masa berlaku, status, kesesuaian cabang,
 *     dan minimal belanja serta menghitung estimasi potongan harga. Tidak mengubah status voucher.
 *  2. **Pakai WAJIB PIN Kasir / Penanggung Jawab Berizin:**
 *     Pencairan voucher memanggil RPC `pakai_voucher` yang menuntut otorisasi PIN kasir
 *     terverifikasi kriptografis, mencatat jejak audit ke `percobaan_pin` dan `voucher_percobaan`.
 *  3. **Eksekusi Atomik Sekali Pakai (ART-5):**
 *     Mencegah dobel klaim secara konkuren dan menolak pemakaian voucher yang sudah terpakai
 *     atau kadaluwarsa dengan pesan kesalahan yang jelas dan spesifik.
 *  4. **Potongan Dihitung Peladen:**
 *     Persen potongan dibatasi plafon maksimal kampanye, atau nominal sesuai aturan kampanye.
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { rupiah } from '../../lib/format'

export interface DataVoucherCek {
  voucher_id: string
  kode_voucher: string
  status: string
  nama_kampanye: string
  jenis: 'persen' | 'nominal'
  nilai: number
  min_belanja: number
  maks_potongan: number | null
  estimasi_potongan: number
  nama_pelanggan?: string | null
  berlaku_sampai?: string | null
}

export interface HasilCekVoucher {
  berhasil: boolean
  kode?: string
  pesan?: string
  data?: DataVoucherCek
}

export interface HasilPakaiVoucher {
  berhasil: boolean
  kode?: string
  pesan?: string
  data?: {
    voucher_id: string
    kode_voucher: string
    nilai_potongan: number
    nama_kampanye: string
    nama_pelanggan?: string | null
  }
}

export interface VoucherKasirProps {
  /** Subtotal pesanan saat ini sebagai dasar validasi minimal belanja & estimasi potongan */
  subtotal: number
  pesananId?: string
  cabangId?: string
  sedangMemproses?: boolean
  pesan?: string | null
  onCek: (masukan: {
    kode: string
    subtotal: number
    cabangId?: string
  }) => Promise<HasilCekVoucher | null> | void
  onPakai: (masukan: {
    kode: string
    pinKasir: string
    pesananId?: string
  }) => Promise<HasilPakaiVoucher | null> | void
  onBatal?: () => void
  onSelesai?: (hasil: HasilPakaiVoucher['data']) => void
}

export function VoucherKasir({
  subtotal,
  pesananId,
  cabangId,
  sedangMemproses = false,
  pesan = null,
  onCek,
  onPakai,
  onBatal,
  onSelesai,
}: VoucherKasirProps) {
  const [kodeInput, setKodeInput] = useState('')
  const [pinKasir, setPinKasir] = useState('')
  const [sedangCek, setSedangCek] = useState(false)
  const [sedangPakai, setSedangPakai] = useState(false)
  const [hasilCek, setHasilCek] = useState<HasilCekVoucher | null>(null)
  const [pesanLokal, setPesanLokal] = useState<string | null>(null)
  const [statusSuksesPakai, setStatusSuksesPakai] = useState<string | null>(null)

  const kodeBersih = kodeInput.trim().toUpperCase()

  const tanganiCek = async () => {
    setPesanLokal(null)
    setStatusSuksesPakai(null)
    if (!kodeBersih) {
      setPesanLokal('Masukkan kode voucher terlebih dahulu.')
      return
    }

    setSedangCek(true)
    try {
      const res = await onCek({
        kode: kodeBersih,
        subtotal,
        cabangId,
      })
      if (res) {
        setHasilCek(res)
        if (!res.berhasil) {
          setPesanLokal(res.pesan ?? 'Voucher tidak dapat digunakan.')
        }
      }
    } finally {
      setSedangCek(false)
    }
  }

  const tanganiPakai = async () => {
    setPesanLokal(null)
    if (!kodeBersih) {
      setPesanLokal('Kode voucher tidak boleh kosong.')
      return
    }

    if (!pinKasir || pinKasir.trim().length === 0) {
      setPesanLokal('Masukkan PIN Kasir untuk mengotorisasi pemakaian voucher.')
      return
    }

    setSedangPakai(true)
    try {
      const res = await onPakai({
        kode: kodeBersih,
        pinKasir: pinKasir.trim(),
        pesananId,
      })
      // Kosongkan PIN dari memori peramban segera setelah digunakan
      setPinKasir('')

      if (res?.berhasil) {
        setStatusSuksesPakai(
          res.pesan ??
            `Voucher ${res.data?.nama_kampanye ?? ''} berhasil digunakan! Potongan: ${rupiah(res.data?.nilai_potongan ?? 0)}.`,
        )
        onSelesai?.(res.data)
      } else {
        setPesanLokal(res?.pesan ?? 'Pemakaian voucher ditolak oleh sistem.')
      }
    } finally {
      setSedangPakai(false)
    }
  }

  const bolehPakai =
    Boolean(hasilCek?.berhasil) &&
    pinKasir.trim().length > 0 &&
    !sedangMemproses &&
    !sedangPakai &&
    !statusSuksesPakai

  return (
    <div className="voucher-kasir" data-testid="voucher-kasir">
      <p className="voucher-kasir__subtotal" data-testid="voucher-subtotal">
        Subtotal pesanan: <strong>{rupiah(subtotal)}</strong>
      </p>

      {/* Baris Input Kode & Tombol Cek (BACA SAJA) */}
      <div className="voucher-kasir__baris-cek">
        <div style={{ flex: 1 }}>
          <KolomIsian
            label="Kode voucher"
            jenis="text"
            nilai={kodeInput}
            onUbah={(val) => {
              setKodeInput(val)
              setHasilCek(null)
              setPesanLokal(null)
              setStatusSuksesPakai(null)
            }}
            contoh="Mis. RB-8M4K-9Q2V atau HEMAT20"
            wajib
            keterangan="Ketik kode voucher atau pindai barcode pelanggan."
          />
        </div>
        <div style={{ marginBottom: 'var(--s-1)' }}>
          <Tombol
            ragam="biasa"
            onClick={tanganiCek}
            nonaktif={sedangCek || sedangMemproses}
            nama="Cek voucher"
          >
            {sedangCek ? 'Memeriksa...' : '🔍 Cek Voucher'}
          </Tombol>
        </div>
      </div>

      {/* Hasil Cek Baca Saja */}
      {hasilCek && (
        <div
          className={`voucher-kasir__hasil ${
            hasilCek.berhasil ? 'voucher-kasir__hasil--sukses' : 'voucher-kasir__hasil--gagal'
          }`}
          data-testid={hasilCek.berhasil ? 'voucher-hasil-cek-sukses' : 'voucher-hasil-cek-gagal'}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
            <Lencana nada={hasilCek.berhasil ? 'success' : 'danger'}>
              {hasilCek.berhasil ? 'Voucher Sah' : 'Tidak Sah'}
            </Lencana>
            <span style={{ fontWeight: 600 }}>{hasilCek.pesan}</span>
          </div>

          {hasilCek.berhasil && hasilCek.data && (
            <div className="voucher-kasir__rincian">
              <div data-testid="voucher-nama-kampanye">
                <strong>Kampanye:</strong> {hasilCek.data.nama_kampanye}
              </div>
              <div data-testid="voucher-rincian-diskon">
                <strong>Aturan Promo:</strong>{' '}
                {hasilCek.data.jenis === 'persen'
                  ? `Diskon ${hasilCek.data.nilai}%${
                      hasilCek.data.maks_potongan
                        ? ` (maksimal ${rupiah(hasilCek.data.maks_potongan)})`
                        : ''
                    }`
                  : `Potongan ${rupiah(hasilCek.data.nilai)}`}
              </div>
              <div
                data-testid="voucher-estimasi-potongan"
                style={{ color: 'var(--accent)', fontWeight: 600, fontSize: 'var(--t-3)' }}
              >
                Estimasi Potongan: {rupiah(hasilCek.data.estimasi_potongan)}
              </div>
              <div data-testid="voucher-min-belanja" className="muted">
                Syarat belanja minimal: {rupiah(hasilCek.data.min_belanja)}
              </div>
              {hasilCek.data.nama_pelanggan && (
                <div data-testid="voucher-pelanggan" className="muted">
                  Pemilik voucher: {hasilCek.data.nama_pelanggan}
                </div>
              )}
              {hasilCek.data.berlaku_sampai && (
                <div data-testid="voucher-berlaku" className="muted">
                  Berlaku hingga:{' '}
                  {new Date(hasilCek.data.berlaku_sampai).toLocaleDateString('id-ID', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                  })}
                </div>
              )}
            </div>
          )}

          {!hasilCek.berhasil && (
            <p
              className="small"
              data-testid="voucher-pesan-gagal"
              style={{ color: 'var(--danger)' }}
            >
              {hasilCek.pesan}
            </p>
          )}
        </div>
      )}

      {/* Bagian Masukan PIN Kasir (Wajib untuk Pakai Voucher) */}
      {hasilCek?.berhasil && !statusSuksesPakai && (
        <div style={{ marginTop: 'var(--s-1)' }}>
          <KolomIsian
            label="PIN Kasir"
            jenis="password"
            nilai={pinKasir}
            onUbah={setPinKasir}
            contoh="••••"
            wajib
            keterangan="Masukkan PIN Kasir Anda untuk mengonfirmasi pemakaian voucher atomik."
          />
        </div>
      )}

      {/* Status Sukses Pemakaian */}
      {statusSuksesPakai && (
        <div
          className="voucher-kasir__hasil voucher-kasir__hasil--sukses"
          data-testid="voucher-sukses-pakai"
        >
          <Lencana nada="success">Berhasil Digunakan</Lencana>
          <p style={{ fontWeight: 600, color: 'var(--success)' }}>{statusSuksesPakai}</p>
        </div>
      )}

      {/* Pesan Kesalahan / Notifikasi */}
      {(pesanLokal || pesan) && !statusSuksesPakai && (
        <p
          className="voucher-kasir__pesan"
          role="status"
          data-testid="voucher-pesan-pakai"
          style={{ color: 'var(--danger)' }}
        >
          {pesanLokal ?? pesan}
        </p>
      )}

      {/* Tombol Aksi */}
      <div className="voucher-kasir__aksi">
        <Tombol ragam="biasa" onClick={onBatal}>
          {statusSuksesPakai ? 'Tutup' : 'Batal'}
        </Tombol>
        {!statusSuksesPakai && hasilCek?.berhasil && (
          <Tombol ragam="utama" onClick={tanganiPakai} nonaktif={!bolehPakai} nama="Pakai voucher">
            {sedangPakai ? 'Menerapkan...' : '🎟️ Pakai Voucher'}
          </Tombol>
        )}
      </div>
    </div>
  )
}
