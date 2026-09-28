/**
 * DaftarPembatalan.tsx (T5-12) — daftar pembatalan untuk pemilik: siapa, nilai,
 * alasan, dan jenisnya (sebelum atau sesudah dapur mulai).
 *
 * KENAPA ADA: PRD M6 butir 4 berbunyi "tidak ada pembatalan yang tidak
 * terlihat". Angka total saja tidak cukup — "hari ini ada 7 pembatalan" tidak
 * memberi tahu apa pun yang bisa ditindaklanjuti. Yang berguna bagi pemilik
 * adalah melihat POLA: satu pegawai yang membatalkan jauh lebih sering daripada
 * yang lain, atau alasan yang sama berulang setiap hari (yang biasanya berarti
 * ada masalah proses, bukan masalah orang).
 *
 * DUA HAL YANG DIJAGA LAYAR INI:
 *
 *  1. **Membedakan kerugian nyata dari sekadar salah ketik.** Pembatalan
 *     sebelum dapur mulai umumnya tidak merugikan apa-apa — tamu berubah
 *     pikiran, kasir salah pilih meja. Pembatalan SESUDAH dapur mulai berarti
 *     bahan sudah terpakai dan uangnya hangus. Kalau keduanya ditampilkan sama
 *     rata, pemilik akan panik melihat angka besar yang sebetulnya tidak
 *     berbahaya — atau sebaliknya, tenang melihat angka kecil yang ternyata
 *     kerugian betulan.
 *
 *  2. **Tidak menghakimi lewat tata letak.** Nama pegawai ditampilkan apa
 *     adanya, tanpa peringkat "paling sering membatalkan". Daftar semacam itu
 *     mendorong pegawai menutupi kesalahan alih-alih mencatatnya jujur, dan
 *     pencatatan jujur justru satu-satunya alasan tabel ini ada.
 *
 * Komponen ini MURNI TAMPILAN. Ia menerima baris yang sudah dibaca kontainer
 * dari view `laporan_pembatalan`, dan tidak pernah memanggil peladen sendiri.
 * Siapa yang boleh melihat isinya ditegakkan database (izin `lihat_laporan`,
 * migrasi 0043) — bukan oleh layar ini, karena pagar yang hanya ada di layar
 * bisa dilewati siapa pun yang membuka alamatnya langsung.
 */
import { useMemo, useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { rupiah, jamLokal } from '../../lib/format'

export type TahapBatal = 'sebelum_dapur' | 'sesudah_dapur'

export interface BarisPembatalan {
  id: string
  nomorPesanan: number
  waktu: string
  tahap: TahapBatal
  alasan: string
  nilaiKerugian: number
  pelakuNama: string | null
  penyetujuNama?: string | null
  itemNama?: string | null
  itemQty?: number | null
}

export type SaringTahap = 'semua' | TahapBatal

export interface RingkasanPembatalan {
  jumlah: number
  jumlahSebelum: number
  jumlahSesudah: number
  /** Hanya menjumlahkan kerugian NYATA (sesudah dapur), bukan semua baris. */
  totalKerugian: number
}

/**
 * Ringkasan yang jujur.
 *
 * `totalKerugian` sengaja hanya menjumlahkan pembatalan sesudah dapur mulai.
 * Menjumlahkan semuanya akan melaporkan "kerugian" atas pesanan yang bahkan
 * belum pernah dimasak — angka yang membuat pemilik cemas tanpa sebab, dan yang
 * lebih buruk, membuat angka kerugian yang sungguhan jadi tidak dipercaya.
 */
export function ringkasPembatalan(daftar: BarisPembatalan[]): RingkasanPembatalan {
  return daftar.reduce<RingkasanPembatalan>(
    (akum, baris) => {
      const sesudah = baris.tahap === 'sesudah_dapur'
      return {
        jumlah: akum.jumlah + 1,
        jumlahSebelum: akum.jumlahSebelum + (sesudah ? 0 : 1),
        jumlahSesudah: akum.jumlahSesudah + (sesudah ? 1 : 0),
        totalKerugian: akum.totalKerugian + (sesudah ? baris.nilaiKerugian : 0),
      }
    },
    { jumlah: 0, jumlahSebelum: 0, jumlahSesudah: 0, totalKerugian: 0 },
  )
}

export function saringPembatalan(
  daftar: BarisPembatalan[],
  saring: SaringTahap,
): BarisPembatalan[] {
  if (saring === 'semua') return daftar
  return daftar.filter((baris) => baris.tahap === saring)
}

/** Label yang bisa dibaca pegawai, bukan nama kolom database. */
export function labelTahap(tahap: TahapBatal): string {
  return tahap === 'sesudah_dapur' ? 'Sesudah dapur mulai' : 'Sebelum dapur mulai'
}

export interface DaftarPembatalanProps {
  daftar: BarisPembatalan[]
  /** Ditampilkan sebagai judul konteks, mis. "23 September 2026 — Cabang Utama". */
  keterangan?: string
}

export function DaftarPembatalan({ daftar, keterangan }: DaftarPembatalanProps) {
  const [saring, setSaring] = useState<SaringTahap>('semua')

  const ringkasan = useMemo(() => ringkasPembatalan(daftar), [daftar])
  const hasil = useMemo(() => saringPembatalan(daftar, saring), [daftar, saring])

  if (daftar.length === 0) {
    return (
      <KeadaanKosong
        judul="Tidak ada pembatalan"
        keterangan="Belum ada pesanan yang dibatalkan pada rentang ini. Daftar akan terisi sendiri bila terjadi pembatalan."
      />
    )
  }

  return (
    <section className="daftar-pembatalan" aria-label="Laporan pembatalan">
      {keterangan && <p className="daftar-pembatalan__konteks">{keterangan}</p>}

      {/*
        Dua angka dipisah dengan sengaja: jumlah kejadian TIDAK sama dengan
        kerugian. Pembatalan sebelum dapur mulai umumnya tidak merugikan apa pun.
      */}
      <div className="daftar-pembatalan__ringkas">
        <div>
          <span className="daftar-pembatalan__angka" data-testid="ringkas-jumlah">
            {ringkasan.jumlah}
          </span>
          <span className="daftar-pembatalan__label">pembatalan</span>
        </div>
        <div>
          <span className="daftar-pembatalan__angka" data-testid="ringkas-kerugian">
            {rupiah(ringkasan.totalKerugian)}
          </span>
          <span className="daftar-pembatalan__label">kerugian (sesudah dapur mulai)</span>
        </div>
      </div>

      <div className="daftar-pembatalan__saring" role="group" aria-label="Saring menurut jenis">
        {(
          [
            ['semua', `Semua (${ringkasan.jumlah})`],
            ['sebelum_dapur', `Sebelum dapur (${ringkasan.jumlahSebelum})`],
            ['sesudah_dapur', `Sesudah dapur (${ringkasan.jumlahSesudah})`],
          ] as [SaringTahap, string][]
        ).map(([nilai, teks]) => (
          /* Memakai <Tombol>, bukan tombol mentah: kontrak UI (peta-ui Aturan 7)
             menjaga gaya, ukuran sentuh, dan label aksesibel tetap seragam. */
          <span
            key={nilai}
            className={
              saring === nilai
                ? 'daftar-pembatalan__tab daftar-pembatalan__tab--aktif'
                : 'daftar-pembatalan__tab'
            }
          >
            <Tombol
              ragam={saring === nilai ? 'utama' : 'polos'}
              nama={`Saring: ${teks}`}
              onClick={() => setSaring(nilai)}
            >
              {teks}
            </Tombol>
          </span>
        ))}
      </div>

      {hasil.length === 0 ? (
        <KeadaanKosong
          judul="Tidak ada pada jenis ini"
          keterangan="Coba pilih jenis lain di atas."
        />
      ) : (
        <ul className="daftar-pembatalan__hasil">
          {hasil.map((baris) => (
            <li
              key={baris.id}
              className="daftar-pembatalan__baris"
              data-testid={`batal-${baris.id}`}
              data-tahap={baris.tahap}
            >
              <div className="daftar-pembatalan__kepala">
                <strong>#{baris.nomorPesanan}</strong>
                <span className="daftar-pembatalan__jam">{jamLokal(new Date(baris.waktu))}</span>
                <Lencana nada={baris.tahap === 'sesudah_dapur' ? 'danger' : 'netral'}>
                  <span data-testid={`tahap-${baris.id}`}>{labelTahap(baris.tahap)}</span>
                </Lencana>
              </div>

              {baris.itemNama && (
                <p className="daftar-pembatalan__item">
                  {baris.itemQty ? `${baris.itemQty}× ` : ''}
                  {baris.itemNama}
                </p>
              )}

              {/* Alasan ditampilkan utuh: alasan yang dipotong jadi tidak berguna
                  untuk menelusuri masalah yang berulang. */}
              <p className="daftar-pembatalan__alasan" data-testid={`alasan-${baris.id}`}>
                “{baris.alasan}”
              </p>

              <div className="daftar-pembatalan__kaki">
                <span data-testid={`pelaku-${baris.id}`}>
                  oleh {baris.pelakuNama ?? 'pengguna terhapus'}
                </span>
                {baris.penyetujuNama && (
                  <span data-testid={`penyetuju-${baris.id}`}>disetujui {baris.penyetujuNama}</span>
                )}
                {baris.tahap === 'sesudah_dapur' && (
                  <span
                    className="daftar-pembatalan__kerugian"
                    data-testid={`kerugian-${baris.id}`}
                  >
                    kerugian {rupiah(baris.nilaiKerugian)}
                  </span>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  )
}
