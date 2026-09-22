/**
 * Penyimpanan antrean cadangan per perangkat (T4-10).
 *
 * Layar dapur/bar harus tetap informatif saat jaringan putus: tiket terakhir yang
 * pernah tampil disimpan di perangkat (localStorage) dan bisa ditampilkan lagi
 * dengan tanda "Tertunda". Ini bukan sumber kebenaran — hanya cadangan tampilan;
 * kebenaran tetap di peladen.
 *
 * Semua operasi TIDAK meledak: penyimpanan penuh / mode privat / JSON rusak cukup
 * menghasilkan nilai kosong, tidak menggagalkan layar.
 */

export type BagianAntrean = 'dapur' | 'bar'

const KUNCI = (bagian: BagianAntrean) => `resto.antrean-terakhir.${bagian}`

export function simpanAntreanTerakhir<T>(bagian: BagianAntrean, tiket: T[]): void {
  try {
    if (typeof localStorage === 'undefined') return
    const muatan = {
      versi: 1 as const,
      bagian,
      tiket,
      disimpanPada: new Date().toISOString(),
    }
    localStorage.setItem(KUNCI(bagian), JSON.stringify(muatan))
  } catch {
    // Penyimpanan penuh / ditolak peramban — cadangan bersifat sukarela.
  }
}

export function muatAntreanTerakhir<T>(bagian: BagianAntrean): T[] | null {
  try {
    if (typeof localStorage === 'undefined') return null
    const mentah = localStorage.getItem(KUNCI(bagian))
    if (!mentah) return null
    const muatan: unknown = JSON.parse(mentah)
    if (
      typeof muatan === 'object' &&
      muatan !== null &&
      (muatan as { versi?: unknown }).versi === 1 &&
      Array.isArray((muatan as { tiket?: unknown }).tiket)
    ) {
      return (muatan as { tiket: T[] }).tiket
    }
    return null
  } catch {
    return null
  }
}

export function hapusAntreanTerakhir(bagian: BagianAntrean): void {
  try {
    if (typeof localStorage === 'undefined') return
    localStorage.removeItem(KUNCI(bagian))
  } catch {
    // abaikan
  }
}
