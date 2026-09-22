const PEMISAH_RIBUAN = '.'
const AWALAN_RUPIAH = 'Rp'

/** Ubah angka rupiah menjadi teks "Rp27.500". */
export function rupiah(nilai: number): string {
  if (!Number.isFinite(nilai)) throw new Error('Nilai rupiah harus angka berhingga')
  const bulat = Math.round(nilai)
  const tanda = bulat < 0 ? '-' : ''
  const angka = String(Math.abs(bulat)).replace(/\B(?=(\d{3})+(?!\d))/g, PEMISAH_RIBUAN)
  return `${tanda}${AWALAN_RUPIAH}${angka}`
}

function duaAngka(n: number): string {
  return n < 10 ? `0${n}` : String(n)
}

/** Jam lokal "14:05". */
export function jamLokal(waktu: Date): string {
  return `${duaAngka(waktu.getHours())}:${duaAngka(waktu.getMinutes())}`
}

/** Tanggal lokal "16 Sep 2026". */
export function tanggalLokal(waktu: Date): string {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
  return `${waktu.getDate()} ${bulan[waktu.getMonth()]} ${waktu.getFullYear()}`
}
