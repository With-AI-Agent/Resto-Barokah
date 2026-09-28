/**
 * DaftarTagihan.tsx (T5-11) — tagihan yang ditinggal & pembayaran sebagian.
 *
 * KENAPA ADA: di kedai betulan, meja yang belum membayar itu kenyataan
 * sehari-hari — tamu keluar sebentar, rombongan patungan, atau memang pergi
 * tanpa bayar. Kalau layar kasir tidak pernah menampilkannya, tagihan itu hanya
 * hidup di ingatan kasir, dan yang lupa akan menjadi selisih kas di akhir shift
 * yang tidak bisa dijelaskan siapa pun.
 *
 * DUA HAL YANG DIJAGA (DoD T5-11):
 *
 *  1. **Penanda umur.** Tagihan berumur 10 menit dan tagihan berumur 3 jam itu
 *     dua masalah yang sangat berbeda, tetapi kalau hanya ditulis jamnya, kasir
 *     harus menghitung sendiri di kepala saat sedang sibuk. Jadi umurnya
 *     dihitung layar dan diberi tingkat: `baru` → `lama` → `mendesak`.
 *
 *  2. **Bahasa yang jujur soal "split bill".** Keputusan MVP: pembayaran
 *     sebagian dicatat sebagai beberapa pembayaran terpisah pada SATU tagihan —
 *     bukan tagihan yang dipecah. Kalau layar diam saja soal ini, kasir akan
 *     mengira ada fitur split bill dan mencari-cari tombolnya. Karena itu
 *     kalimat penjelasnya ditulis langsung di layar, bukan disembunyikan di
 *     dokumen.
 *
 * Komponen ini MURNI TAMPILAN: ia menerima daftar dari kontainer dan tidak
 * pernah memanggil peladen sendiri. Melanjutkan pembayaran diserahkan kembali
 * lewat `onLanjutkanBayar`, supaya semua uang tetap lewat satu pintu
 * (`bayar_pesanan`).
 */
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, jamLokal } from '../../lib/format'

export interface BarisTagihan {
  id: string
  nomor: number
  /** Kapan pesanan dibuat — dasar penghitungan umur. */
  dibuatPada: string
  total: number
  /** Jumlah uang yang SUDAH masuk (boleh 0). */
  sudahDibayar: number
}

/** Batas umur dalam menit. Angkanya sengaja bulat supaya mudah dijelaskan ke pegawai. */
export const BATAS_LAMA_MENIT = 30
export const BATAS_MENDESAK_MENIT = 120

export type TingkatUmur = 'baru' | 'lama' | 'mendesak'

/** Umur tagihan dalam menit penuh (tidak pernah negatif kalau jam perangkat meleset). */
export function umurMenit(dibuatPada: string, sekarang: Date = new Date()): number {
  const selisih = sekarang.getTime() - new Date(dibuatPada).getTime()
  return Math.max(0, Math.floor(selisih / 60000))
}

export function tingkatUmur(menit: number): TingkatUmur {
  if (menit >= BATAS_MENDESAK_MENIT) return 'mendesak'
  if (menit >= BATAS_LAMA_MENIT) return 'lama'
  return 'baru'
}

/**
 * Umur dibaca sebagai "45 menit" / "2 jam 5 menit", bukan "125 menit".
 * Kasir sedang berdiri di depan tamu; ia tidak sedang membaca laporan.
 */
export function labelUmur(menit: number): string {
  if (menit < 60) return `${menit} menit`
  const jam = Math.floor(menit / 60)
  const sisa = menit % 60
  return sisa === 0 ? `${jam} jam` : `${jam} jam ${sisa} menit`
}

/** Sisa yang masih harus dibayar; tidak pernah negatif. */
export function sisaTagihan(baris: BarisTagihan): number {
  return Math.max(0, baris.total - baris.sudahDibayar)
}

export interface DaftarTagihanProps {
  daftar: BarisTagihan[]
  /** Diserahkan ke kontainer; komponen ini tidak pernah mencatat uang sendiri. */
  onLanjutkanBayar?: (baris: BarisTagihan) => void
  /** Bisa disuntik saat pengujian supaya umur tidak bergantung jam nyata. */
  sekarang?: Date
}

const NADA_LENCANA: Record<TingkatUmur, 'netral' | 'warn' | 'danger'> = {
  baru: 'netral',
  lama: 'warn',
  mendesak: 'danger',
}

export function DaftarTagihan({ daftar, onLanjutkanBayar, sekarang }: DaftarTagihanProps) {
  const acuan = sekarang ?? new Date()

  if (daftar.length === 0) {
    return (
      <KeadaanKosong
        judul="Tidak ada tagihan yang ditinggal"
        keterangan="Semua pesanan sudah lunas. Daftar ini akan terisi sendiri kalau ada meja yang belum membayar."
      />
    )
  }

  return (
    <section className="daftar-tagihan" aria-label="Tagihan belum lunas">
      {/*
        Kalimat ini bukan hiasan: ia mencegah kasir mencari tombol "split bill"
        yang memang belum ada di MVP.
      */}
      <p className="daftar-tagihan__catatan" data-testid="tagihan-catatan">
        Pembayaran sebagian dicatat sebagai beberapa pembayaran pada satu tagihan yang sama, bukan
        tagihan yang dipecah. Pemecahan tagihan resmi menyusul di tahap berikutnya.
      </p>

      <ul className="daftar-tagihan__hasil">
        {daftar.map((baris) => {
          const menit = umurMenit(baris.dibuatPada, acuan)
          const tingkat = tingkatUmur(menit)
          const sisa = sisaTagihan(baris)

          return (
            <li
              key={baris.id}
              className={`daftar-tagihan__baris daftar-tagihan__baris--${tingkat}`}
              data-testid={`tagihan-${baris.nomor}`}
              data-umur={tingkat}
            >
              <div className="daftar-tagihan__kiri">
                <strong>#{baris.nomor}</strong>
                <span className="daftar-tagihan__jam">{jamLokal(new Date(baris.dibuatPada))}</span>
                <Lencana nada={NADA_LENCANA[tingkat]}>
                  <span data-testid={`umur-${baris.nomor}`}>menggantung {labelUmur(menit)}</span>
                </Lencana>
              </div>

              <div className="daftar-tagihan__kanan">
                {/*
                  Yang ditonjolkan adalah SISA, bukan total: itulah angka yang
                  harus diucapkan kasir ke tamu. Sudah dibayar berapa tetap
                  ditulis supaya tidak ada yang merasa uangnya hilang.
                */}
                <span className="daftar-tagihan__sisa" data-testid={`sisa-${baris.nomor}`}>
                  sisa {rupiah(sisa)}
                </span>
                {baris.sudahDibayar > 0 && (
                  <span
                    className="daftar-tagihan__terbayar"
                    data-testid={`terbayar-${baris.nomor}`}
                  >
                    sudah dibayar {rupiah(baris.sudahDibayar)} dari {rupiah(baris.total)}
                  </span>
                )}
                <Tombol
                  ragam="utama"
                  nama={`Lanjutkan pembayaran #${baris.nomor}`}
                  onClick={() => onLanjutkanBayar?.(baris)}
                >
                  Lanjutkan bayar
                </Tombol>
              </div>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
