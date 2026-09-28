import type { ReactNode } from 'react'
import { KeadaanKosong } from './KeadaanKosong'

export type KolomTabel<T> = {
  /** Kunci di dalam data baris (dipakai bila `nilai` tidak diisi). */
  kunci: string
  judul: string
  rata?: 'kiri' | 'kanan'
  /** Cara menampilkan sel (mis. uang, jam, lencana). */
  nilai?: (baris: T) => ReactNode
}

/**
 * Tabel daftar (transaksi, menu, pegawai).
 * Di layar sempit tabel bisa digeser ke samping; kalau tidak ada baris,
 * yang tampil bukan tabel kosong melainkan penjelasan (KeadaanKosong).
 */
export function Tabel<T>({
  kolom,
  baris,
  judulKosong = 'Belum ada data',
  keteranganKosong = 'Data akan muncul di sini setelah ada isinya.',
}: {
  kolom: readonly KolomTabel<T>[]
  baris: readonly T[]
  judulKosong?: string
  keteranganKosong?: string
}) {
  if (baris.length === 0) {
    return <KeadaanKosong judul={judulKosong} keterangan={keteranganKosong} />
  }

  return (
    <div className="tabel-bungkus">
      <table className="table">
        <thead>
          <tr>
            {kolom.map((k) => (
              <th key={k.kunci} scope="col" className={k.rata === 'kanan' ? 'right' : undefined}>
                {k.judul}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {baris.map((b, urutan) => (
            <tr key={urutan}>
              {kolom.map((k) => (
                <td key={k.kunci} className={k.rata === 'kanan' ? 'right' : undefined}>
                  {k.nilai ? k.nilai(b) : String((b as Record<string, unknown>)[k.kunci] ?? '')}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
