/**
 * DaftarTransaksi.tsx (T5-10) — mencari transaksi lama dan mencetak ulang
 * struknya, TANPA membuat transaksi baru dan tanpa mengubah data apa pun.
 *
 * KENAPA ADA: struk hilang, robek, atau tidak jadi tercetak adalah kejadian
 * harian. Tanpa jalan resmi mencetak ulang, kasir akan mencari jalan sendiri —
 * dan jalan sendiri yang paling sering dipakai adalah **membuat pesanan baru
 * lalu membatalkannya**, yang mengotori laporan dan angka pembatalan.
 *
 * ATURAN YANG DIPEGANG (DoD T5-10):
 *  - **Tidak mengubah data.** Komponen ini hanya membaca. Satu-satunya keluaran
 *    ke luar adalah `onCetakUlang`, dan kontainernya pun hanya boleh mencetak +
 *    mencatat jejak — bukan menyentuh baris transaksi.
 *  - **Cetak ulang selalu bertanda.** Struk hasil cetak ulang dirender dengan
 *    `salinan` menyala, sehingga tercetak "SALINAN — CETAK ULANG". Lembar kedua
 *    tidak boleh bisa menyamar sebagai lembar pertama; itu mitigasi yang diminta
 *    ROADMAP (penyalahgunaan cetak ulang).
 *  - **Cari dengan nomor, waktu, atau nominal** — tiga hal yang benar-benar
 *    diingat orang saat struk hilang ("tadi sekitar jam 2", "kira-kira 62 ribu").
 *
 * Pencarian dilakukan di sisi layar atas daftar yang SUDAH diberikan kontainer.
 * Untuk satu shift kasir (puluhan sampai ratusan transaksi) ini jauh lebih
 * responsif daripada bolak-balik ke peladen setiap ketikan; kalau suatu saat
 * datanya jauh lebih besar, penyaringan bisa dipindah ke peladen tanpa mengubah
 * tampilan ini.
 */
import { useMemo, useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Struk, type DataStruk, type PembayaranStruk } from '../../komponen/Struk'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, jamLokal } from '../../lib/format'

export interface BarisTransaksi {
  id: string
  data: DataStruk
  pembayaran?: PembayaranStruk[]
  kembalian?: number
}

/**
 * Apakah satu baris cocok dengan kata kunci?
 *
 * Kata kunci dicocokkan ke TIGA hal sekaligus (nomor, jam, nominal) karena orang
 * yang kehilangan struk biasanya hanya ingat salah satunya. Angka dicocokkan
 * setelah pemisah ribuan dibuang, supaya mengetik "62100" maupun "62.100" sama
 * saja — kasir tidak boleh gagal menemukan transaksi gara-gara titik.
 */
export function cocokTransaksi(baris: BarisTransaksi, kunci: string): boolean {
  const cari = kunci.trim().toLowerCase()
  if (cari === '') return true

  const angkaCari = cari.replace(/[.,\s]/g, '')
  const nomor = String(baris.data.nomor)
  const total = String(baris.data.total)
  const jam = jamLokal(new Date(baris.data.tanggal)).toLowerCase()
  const totalTampil = rupiah(baris.data.total)
    .toLowerCase()
    .replace(/[.,\s]/g, '')

  return (
    nomor.includes(angkaCari) ||
    total.includes(angkaCari) ||
    totalTampil.includes(angkaCari) ||
    jam.includes(cari)
  )
}

export interface DaftarTransaksiProps {
  daftar: BarisTransaksi[]
  /**
   * Dipanggil saat kasir menekan "Cetak ulang". Kontainer bertanggung jawab
   * mencetak dan MENCATAT JEJAKNYA; komponen ini tidak pernah mengubah data.
   */
  onCetakUlang?: (baris: BarisTransaksi) => void
  onTutup?: () => void
}

export function DaftarTransaksi({ daftar, onCetakUlang, onTutup }: DaftarTransaksiProps) {
  const [kunci, setKunci] = useState('')
  const [dipilih, setDipilih] = useState<string | null>(null)

  const hasil = useMemo(() => daftar.filter((b) => cocokTransaksi(b, kunci)), [daftar, kunci])
  const barisDipilih = daftar.find((b) => b.id === dipilih) ?? null

  const tanganiCetakUlang = () => {
    if (!barisDipilih) return
    onCetakUlang?.(barisDipilih)
  }

  return (
    <div className="daftar-transaksi" data-testid="daftar-transaksi">
      <KolomIsian
        label="Cari transaksi"
        nilai={kunci}
        onUbah={setKunci}
        contoh="Nomor, jam, atau nominal — mis. 101 / 17:15 / 62100"
        keterangan="Boleh salah satu saja; titik ribuan tidak perlu diketik."
      />

      {hasil.length === 0 ? (
        <KeadaanKosong
          judul="Transaksi tidak ditemukan"
          keterangan="Coba kata kunci lain: nomor struk, jam kira-kira, atau nominal totalnya."
        />
      ) : (
        <ul className="daftar-transaksi__hasil" data-testid="transaksi-hasil">
          {hasil.map((baris) => (
            <li key={baris.id}>
              <button
                type="button"
                className={
                  baris.id === dipilih
                    ? 'daftar-transaksi__baris daftar-transaksi__baris--pilih'
                    : 'daftar-transaksi__baris'
                }
                onClick={() => setDipilih(baris.id)}
                data-testid={`transaksi-${baris.data.nomor}`}
              >
                <span>No. {baris.data.nomor}</span>
                <span>{jamLokal(new Date(baris.data.tanggal))}</span>
                <span>{rupiah(baris.data.total)}</span>
              </button>
            </li>
          ))}
        </ul>
      )}

      {barisDipilih && (
        <div className="daftar-transaksi__pratinjau" data-testid="transaksi-pratinjau">
          {/* Selalu `salinan` — pratinjau cetak ulang tidak boleh terlihat seperti
              struk asli, bahkan di layar. */}
          <Struk
            data={barisDipilih.data}
            pembayaran={barisDipilih.pembayaran ?? []}
            kembalian={barisDipilih.kembalian ?? 0}
            salinan
          />
        </div>
      )}

      <div className="daftar-transaksi__aksi">
        {onTutup && (
          <Tombol ragam="biasa" onClick={onTutup}>
            Tutup
          </Tombol>
        )}
        <Tombol
          ragam="utama"
          onClick={tanganiCetakUlang}
          nonaktif={!barisDipilih}
          nama="Cetak ulang struk"
        >
          Cetak ulang (SALINAN)
        </Tombol>
      </div>
    </div>
  )
}
