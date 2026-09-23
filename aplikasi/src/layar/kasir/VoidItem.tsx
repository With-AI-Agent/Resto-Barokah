/**
 * VoidItem.tsx (T5-06) — membatalkan item/pesanan SEBELUM dapur mulai, dengan
 * alasan yang wajib diisi.
 *
 * Komponen ini MURNI: tidak ada jaringan. Kabel datanya milik kontainer
 * (`onBatalkan` dipasang ke insert baris `pembatalan`).
 *
 * KENAPA ADA (temuan 2026-09-23): pagar databasenya sudah lengkap sejak `0015`
 * (`picu_pembatalan_sah`: tahap dicek dari DUA tanda, alasan wajib, satu target
 * sekali batal, nilai kerugian dari salinan harga, PIN atasan bila dapur sudah
 * mulai). Tetapi LAYAR KASIR tidak pernah memakainya — tombol hapus di keranjang
 * hanya membuang baris dari daftar di layar:
 *
 *     setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== id))
 *
 * Selama item belum dikirim ke peladen itu wajar (masih draf di layar). Yang
 * TIDAK wajar adalah memakai jalan yang sama untuk item yang SUDAH tercatat:
 * item hilang tanpa alasan, tanpa nama pelaku, dan tanpa jejak di laporan —
 * persis celah yang membuat pemilik tidak pernah tahu berapa yang dibatalkan
 * kasir dalam sehari. Berkas ini menutup celah itu di sisi layar.
 *
 * Aturan yang dipegang (DoD T5-06 + PRD M6 + TECH_SPEC §9 ART-4):
 *  - **Alasan wajib.** Tombol batal mati sampai alasan terisi; alasan boleh
 *    dipilih dari daftar cepat atau diketik sendiri.
 *  - **Tidak ada penghapusan data.** Yang terjadi adalah pencatatan pembatalan;
 *    barisnya tetap ada di database dan masuk laporan.
 *  - **Layar tidak memutuskan tahap.** Kalau pesanan ternyata sudah masuk dapur,
 *    peladen yang menolak dan pesannya ditampilkan apa adanya — layar tidak
 *    pernah menyulapnya jadi "berhasil".
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { rupiah } from '../../lib/format'

/** Alasan cepat — mempercepat kasir tanpa memaksa mengetik saat antrean panjang. */
export const ALASAN_CEPAT = [
  'Salah input kasir',
  'Pelanggan batal pesan',
  'Pelanggan ganti menu',
  'Menu habis',
] as const

export interface HasilVoid {
  berhasil: boolean
  pesan?: string | null
}

export interface VoidItemProps {
  /** Nama item yang akan dibatalkan (atau nama pesanan bila membatalkan semua). */
  namaTarget: string
  /** Nilai yang batal ditagih — supaya kasir sadar besarnya sebelum menekan. */
  nilai: number
  /**
   * Apakah pesanan sudah dikirim ke dapur. Dipakai HANYA untuk memberi tahu
   * kasir lebih awal; yang menegakkan tetap peladen (`picu_pembatalan_sah`).
   */
  sudahKeDapur?: boolean
  sedangKirim?: boolean
  pesan?: string | null
  onBatalkan?: (masukan: { alasan: string }) => Promise<HasilVoid | null> | void
  onTutup?: () => void
}

export function VoidItem({
  namaTarget,
  nilai,
  sudahKeDapur = false,
  sedangKirim = false,
  pesan = null,
  onBatalkan,
  onTutup,
}: VoidItemProps) {
  const [alasan, setAlasan] = useState('')
  const [pesanLokal, setPesanLokal] = useState<string | null>(null)

  const alasanTerisi = alasan.trim().length > 0
  const bolehBatal = alasanTerisi && !sedangKirim

  const tanganiBatalkan = async () => {
    setPesanLokal(null)
    const hasil = await onBatalkan?.({ alasan: alasan.trim() })
    if (hasil && !hasil.berhasil) {
      setPesanLokal(hasil.pesan ?? 'Pembatalan ditolak peladen.')
    }
  }

  return (
    <div className="void-item" data-testid="void-item">
      <p className="void-item__target" data-testid="void-target">
        Membatalkan: <strong>{namaTarget}</strong> — {rupiah(nilai)}
      </p>

      {sudahKeDapur && (
        <p data-testid="void-peringatan-dapur">
          <Lencana nada="warn">Dapur sudah mulai</Lencana> Pembatalan sekarang dihitung sebagai
          bahan terbuang dan wajib disetujui atasan lewat PIN.
        </p>
      )}

      <fieldset className="void-item__alasan-cepat">
        <legend className="label">Alasan cepat</legend>
        {ALASAN_CEPAT.map((a) => (
          <Tombol key={a} ragam={alasan === a ? 'utama' : 'biasa'} onClick={() => setAlasan(a)}>
            {a}
          </Tombol>
        ))}
      </fieldset>

      <KolomIsian
        label="Alasan pembatalan"
        nilai={alasan}
        onUbah={setAlasan}
        contoh="Mis. pelanggan berubah pikiran"
        wajib
        keterangan="Wajib diisi. Inilah yang dibaca pemilik di laporan pembatalan."
      />

      {(pesanLokal || pesan) && (
        <p className="void-item__pesan" role="status" data-testid="void-pesan">
          {pesanLokal ?? pesan}
        </p>
      )}

      <div className="void-item__aksi">
        <Tombol ragam="biasa" onClick={onTutup}>
          Jangan batalkan
        </Tombol>
        <Tombol ragam="bahaya" onClick={tanganiBatalkan} nonaktif={!bolehBatal}>
          {sedangKirim ? 'Menyimpan...' : 'Batalkan & catat alasan'}
        </Tombol>
      </div>
    </div>
  )
}
