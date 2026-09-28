/**
 * DataPelanggan.tsx (T5-08) — menawarkan poin/voucher tanpa memaksa pelanggan
 * memberikan datanya.
 *
 * Komponen MURNI: tidak menyimpan apa pun sendiri. Penyimpanan & anonimisasi
 * adalah urusan Fase 8 (T8-15, bersama halaman kebijakan privasi) — di sini
 * datanya hanya dikumpulkan dan diserahkan ke kontainer.
 *
 * ATURAN YANG DIPEGANG (DoD T5-08 + `docs/KEAMANAN.md` §11 UU PDP 27/2022):
 *  - **Benar-benar opsional.** Ada tombol "Lewati" yang selalu hidup, dan
 *    pembayaran TIDAK PERNAH menunggu bagian ini.
 *  - **Persetujuan eksplisit.** Nomor HP hanya boleh dikirim bila kotak
 *    persetujuan dicentang; tombol simpan mati sampai itu terjadi. Persetujuan
 *    ikut dikirim sebagai data (`setuju: true`), bukan diasumsikan.
 *  - **Minimalisasi.** Hanya nomor HP dan nama panggilan (opsional). Tidak ada
 *    NIK, alamat, tanggal lahir, atau apa pun yang tidak dipakai voucher.
 *  - **Penjelasan singkat di layar**, bukan hanya di halaman kebijakan: pelanggan
 *    harus tahu datanya dipakai untuk apa tanpa membuka tautan.
 *
 * Yang sengaja TIDAK dilakukan: nomor tidak divalidasi ketat (mis. wajib diawali
 * 08). Kasir sering mencatat nomor yang didikte cepat; menolak format yang tidak
 * biasa hanya membuat kasir mengarang nomor supaya bisa lanjut — dan data karangan
 * lebih buruk daripada tidak ada data. Yang dijaga cuma "ada isinya dan masuk akal
 * sebagai nomor".
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'

export interface DataPelangganMasukan {
  noHp: string
  nama?: string
  setuju: true
}

export interface DataPelangganProps {
  sedangKirim?: boolean
  pesan?: string | null
  /** Dipanggil hanya bila pelanggan setuju. */
  onSimpan?: (masukan: DataPelangganMasukan) => void
  /** Dipanggil saat pelanggan/kasir memilih melewati — harus selalu tersedia. */
  onLewati?: () => void
}

/**
 * Nomor dianggap masuk akal bila memuat minimal 8 angka. Longgar disengaja
 * (lihat catatan di kepala berkas).
 */
export function nomorMasukAkal(nilai: string): boolean {
  return (nilai.match(/\d/g) ?? []).length >= 8
}

export function DataPelanggan({
  sedangKirim = false,
  pesan = null,
  onSimpan,
  onLewati,
}: DataPelangganProps) {
  const [noHp, setNoHp] = useState('')
  const [nama, setNama] = useState('')
  const [setuju, setSetuju] = useState(false)

  const bolehSimpan = setuju && nomorMasukAkal(noHp) && !sedangKirim

  const tanganiSimpan = () => {
    if (!bolehSimpan) return
    onSimpan?.({ noHp: noHp.trim(), nama: nama.trim() || undefined, setuju: true })
  }

  return (
    <div className="data-pelanggan" data-testid="data-pelanggan">
      <p className="data-pelanggan__jelas" data-testid="pelanggan-penjelasan">
        Boleh dilewati. Nomor HP hanya dipakai untuk mengumpulkan poin dan mengirim voucher kedai
        ini — tidak dijual, tidak dibagikan ke pihak lain, dan bisa dihapus kapan saja atas
        permintaan pelanggan.
      </p>

      <KolomIsian
        label="Nomor HP pelanggan"
        nilai={noHp}
        onUbah={setNoHp}
        contoh="Mis. 0812 3456 7890"
        keterangan="Opsional — kosongkan saja bila pelanggan tidak berminat."
      />

      <KolomIsian
        label="Nama panggilan"
        nilai={nama}
        onUbah={setNama}
        contoh="Mis. Bu Ani"
        keterangan="Opsional, hanya untuk menyapa di struk voucher."
      />

      <label className="data-pelanggan__setuju">
        <input
          type="checkbox"
          checked={setuju}
          onChange={(e) => setSetuju(e.target.checked)}
          data-testid="pelanggan-setuju"
        />
        <span>Pelanggan setuju nomornya disimpan untuk poin &amp; voucher kedai ini.</span>
      </label>

      {pesan && (
        <p className="data-pelanggan__pesan" role="status" data-testid="pelanggan-pesan">
          {pesan}
        </p>
      )}

      <div className="data-pelanggan__aksi">
        {/* Tombol lewati sengaja ditaruh sejajar & selalu hidup: bagian ini tidak
            boleh terasa seperti syarat untuk membayar. */}
        <Tombol ragam="biasa" onClick={onLewati} nama="Lewati data pelanggan">
          Lewati
        </Tombol>
        <Tombol ragam="utama" onClick={tanganiSimpan} nonaktif={!bolehSimpan}>
          {sedangKirim ? 'Menyimpan...' : 'Simpan & lanjut'}
        </Tombol>
      </div>
    </div>
  )
}
