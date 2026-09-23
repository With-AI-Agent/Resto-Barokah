/**
 * DiskonManual.tsx (T5-05) — memberi diskon manual di layar kasir, dengan
 * persetujuan PIN atasan bila nilainya di atas batas kasir.
 *
 * Komponen ini MURNI: tidak ada jaringan. Kabel datanya milik kontainer
 * (`onTerapkan` dipasang ke insert `diskon_transaksi`, `onMintaPersetujuan`
 * dipasang ke RPC `verifikasi_pin`).
 *
 * Aturan yang dipegang (DoD T5-05 + PRD M3 + DECISIONS_LOG [Fase 5/2026-09-23]):
 *  - **Batas datang dari peladen** (`izin_efektif`), bukan dikarang layar. Kalau
 *    batasnya belum diketahui, layar bersikap hati-hati: anggap butuh persetujuan.
 *  - **Layar tidak pernah menjadi penentu.** Pagar sungguhannya ada di database
 *    (`picu_diskon_batas`, migrasi 0041). Yang dilakukan layar hanya memberi tahu
 *    kasir lebih awal supaya tidak mengetik dua kali — kalau layar salah menebak,
 *    peladen tetap menolak.
 *  - **Alasan wajib** (kolom `diskon_transaksi` menuntutnya, dan laporan
 *    pembatalan/diskon tidak ada artinya tanpa alasan).
 *  - **PIN atasan diketik atasan sendiri**, di layar kasir, lalu dipakai untuk
 *    pesanan itu saja dan sekali pakai. Layar tidak menyimpan PIN-nya di state
 *    lebih lama dari yang diperlukan dan mengosongkannya setelah dipakai.
 *  - Diskon yang melebihi batas ATASAN pun tetap ditolak peladen; pesan dari
 *    peladen ditampilkan apa adanya, tidak diterjemahkan ulang jadi "berhasil".
 */
import { useMemo, useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { rupiah } from '../../lib/format'

/** Batas diskon pemakai yang sedang masuk, dari `izin_efektif('beri_diskon')`. */
export interface BatasDiskon {
  /** Apakah pemakai ini boleh memberi diskon sama sekali. */
  boleh: boolean
  /** Batas rupiah; `null` = tanpa batas nominal. */
  batasNominal: number | null
  /** Batas persen; `null` = tanpa batas persen. */
  batasPersen: number | null
}

export interface HasilDiskon {
  berhasil: boolean
  pesan?: string | null
}

export interface DiskonManualProps {
  /** Subtotal pesanan dari peladen — dasar hitung persen efektif. */
  subtotal: number
  /** Batas pemakai yang sedang masuk; `null` = belum diketahui (hati-hati). */
  batas?: BatasDiskon | null
  /** Daftar atasan yang bisa dimintai persetujuan (nama untuk dipilih kasir). */
  daftarAtasan?: { id: string; nama: string }[]
  sedangKirim?: boolean
  pesan?: string | null
  /** Meminta peladen memverifikasi PIN atasan untuk pesanan ini. */
  onMintaPersetujuan?: (masukan: {
    atasanId: string
    pin: string
  }) => Promise<HasilDiskon | null> | void
  /** Mencatat diskonnya. `disetujuiOleh` diisi bila persetujuan dipakai. */
  onTerapkan?: (masukan: {
    nilai: number
    alasan: string
    disetujuiOleh: string | null
  }) => Promise<HasilDiskon | null> | void
  onBatal?: () => void
}

/**
 * Persen efektif dihitung dari UANG, sama seperti peladen (migrasi 0019/0041):
 * nilai diskon dibagi subtotal. Kalau subtotal 0, diskon apa pun dianggap 100 %
 * supaya layar tidak menebak lebih longgar daripada peladen.
 */
export function persenEfektif(nilai: number, subtotal: number): number {
  if (!Number.isFinite(nilai) || nilai <= 0) return 0
  if (!Number.isFinite(subtotal) || subtotal <= 0) return 100
  return Math.round((nilai * 100 * 100) / subtotal) / 100
}

/**
 * Apakah nilai ini melewati batas pemakai? Bila batas belum diketahui (`null`),
 * jawabannya **ya** — lebih baik meminta persetujuan yang ternyata tidak perlu
 * daripada menjanjikan berhasil lalu ditolak peladen di depan pelanggan.
 */
export function melebihiBatas(
  nilai: number,
  subtotal: number,
  batas?: BatasDiskon | null,
): boolean {
  if (nilai <= 0) return false
  if (!batas) return true
  if (!batas.boleh) return true
  if (batas.batasNominal !== null && nilai > batas.batasNominal) return true
  if (batas.batasPersen !== null && persenEfektif(nilai, subtotal) > batas.batasPersen) return true
  return false
}

export function DiskonManual({
  subtotal,
  batas = null,
  daftarAtasan = [],
  sedangKirim = false,
  pesan = null,
  onMintaPersetujuan,
  onTerapkan,
  onBatal,
}: DiskonManualProps) {
  const [nilaiTeks, setNilaiTeks] = useState('')
  const [alasan, setAlasan] = useState('')
  const [atasanId, setAtasanId] = useState('')
  const [pin, setPin] = useState('')
  const [disetujuiOleh, setDisetujuiOleh] = useState<string | null>(null)
  const [pesanLokal, setPesanLokal] = useState<string | null>(null)

  const nilai = useMemo(() => {
    const bersih = Number(nilaiTeks.replace(/[^\d]/g, ''))
    return Number.isFinite(bersih) ? bersih : 0
  }, [nilaiTeks])

  const persen = persenEfektif(nilai, subtotal)
  const perluPersetujuan = melebihiBatas(nilai, subtotal, batas)
  const sudahDisetujui = disetujuiOleh !== null
  const alasanTerisi = alasan.trim().length > 0

  // Tombol terapkan hidup hanya bila semua syarat yang KITA tahu sudah terpenuhi.
  const bolehTerapkan =
    nilai > 0 && alasanTerisi && !sedangKirim && (!perluPersetujuan || sudahDisetujui)

  const tanganiMintaPersetujuan = async () => {
    setPesanLokal(null)
    if (!atasanId || pin.trim().length === 0) {
      setPesanLokal('Pilih atasan dan minta beliau memasukkan PIN-nya.')
      return
    }
    const hasil = await onMintaPersetujuan?.({ atasanId, pin })
    // PIN tidak disimpan lebih lama dari yang diperlukan.
    setPin('')
    if (hasil?.berhasil) {
      setDisetujuiOleh(atasanId)
      setPesanLokal('Persetujuan atasan diterima.')
    } else {
      setDisetujuiOleh(null)
      setPesanLokal(hasil?.pesan ?? 'PIN atasan tidak diterima.')
    }
  }

  const tanganiTerapkan = async () => {
    setPesanLokal(null)
    const hasil = await onTerapkan?.({ nilai, alasan: alasan.trim(), disetujuiOleh })
    if (hasil && !hasil.berhasil) {
      setPesanLokal(hasil.pesan ?? 'Diskon ditolak peladen.')
    }
  }

  return (
    <div className="diskon-manual" data-testid="diskon-manual">
      <p className="diskon-manual__subtotal" data-testid="diskon-subtotal">
        Subtotal pesanan: <strong>{rupiah(subtotal)}</strong>
      </p>

      <KolomIsian
        label="Nilai diskon (rupiah)"
        jenis="text"
        nilai={nilaiTeks}
        onUbah={setNilaiTeks}
        contoh="Mis. 5000"
        wajib
        keterangan="Ketik angka rupiah yang dipotong dari tagihan."
      />

      {nilai > 0 && (
        <p className="diskon-manual__persen" data-testid="diskon-persen">
          Setara {persen}% dari subtotal.
        </p>
      )}

      <KolomIsian
        label="Alasan diskon"
        nilai={alasan}
        onUbah={setAlasan}
        contoh="Mis. pelanggan komplain masakan terlambat"
        wajib
        keterangan="Alasan wajib — inilah yang dibaca pemilik di laporan."
      />

      {perluPersetujuan && nilai > 0 && !sudahDisetujui && (
        <div className="diskon-manual__persetujuan" data-testid="diskon-perlu-persetujuan">
          <Lencana nada="warn">Perlu persetujuan atasan</Lencana>
          <p>
            Diskon ini di atas batas Anda. Minta pemilik atau admin memasukkan PIN-nya di sini —
            beliau tidak perlu keluar-masuk akun.
          </p>

          <label className="label" htmlFor="diskon-atasan">
            Atasan yang menyetujui
          </label>
          <select
            id="diskon-atasan"
            className="input"
            data-testid="diskon-atasan"
            value={atasanId}
            onChange={(e) => setAtasanId(e.target.value)}
          >
            <option value="">— pilih atasan —</option>
            {daftarAtasan.map((a) => (
              <option key={a.id} value={a.id}>
                {a.nama}
              </option>
            ))}
          </select>

          <KolomIsian
            label="PIN atasan"
            jenis="password"
            nilai={pin}
            onUbah={setPin}
            keterangan="Diketik oleh atasan sendiri. Berlaku untuk tagihan ini saja, sekali pakai."
          />

          <Tombol ragam="biasa" onClick={tanganiMintaPersetujuan} nonaktif={sedangKirim}>
            Minta persetujuan
          </Tombol>
        </div>
      )}

      {sudahDisetujui && (
        <p data-testid="diskon-disetujui">
          <Lencana nada="success">Disetujui atasan</Lencana>{' '}
          {daftarAtasan.find((a) => a.id === disetujuiOleh)?.nama ?? 'Atasan'} telah menyetujui
          diskon ini.
        </p>
      )}

      {(pesanLokal || pesan) && (
        <p className="diskon-manual__pesan" role="status" data-testid="diskon-pesan">
          {pesanLokal ?? pesan}
        </p>
      )}

      <div className="diskon-manual__aksi">
        <Tombol ragam="biasa" onClick={onBatal}>
          Batal
        </Tombol>
        <Tombol ragam="utama" onClick={tanganiTerapkan} nonaktif={!bolehTerapkan}>
          {sedangKirim ? 'Menyimpan...' : 'Terapkan diskon'}
        </Tombol>
      </div>
    </div>
  )
}
