/**
 * pemulihan-sesi.ts — Pemulihan Sesi & Ketahanan Gangguan Listrik (T10-09).
 *
 * Mengatur pemulihan draf transaksi kasir, deteksi shift aktif yang sedang
 * berjalan, dan rekonsiliasi data berprinsip server-wins setelah kejadian
 * listrik padam atau peramban tertutup mendadak.
 *
 * Ref: TECH_SPEC §9 (ART-8) & §10 (Pemulihan Insiden), ROADMAP T10-09.
 */

export {
  simpanDrafKasir,
  muatDrafKasir,
  hapusDrafKasir,
  simpanTagihanTerbukaLokal,
  muatTagihanTerbukaLokal,
  hapusTagihanTerbukaLokal,
  rekonsiliasiEntitas,
  rekonsiliasiDaftarPesanan,
  type DrafPesananKasir,
  type CadanganTagihanTerbuka,
  type EntitasSinkron,
  type HasilRekonsiliasi,
} from './antrean-lokal'

export interface InfoShiftKas {
  id: string
  cabangId: string
  modalAwal: number
  dibukaPada: string
  status?: string
}

/**
 * Mengecek apakah shift kasir masih sah dan perlu dilanjutkan saat pemulihan,
 * ataukah sudah melewati jam operasional kedai.
 *
 * Bila shift masih aktif di hari yang sama dan belum melewati jam tutup,
 * kasir WAJIB melanjutkan shift yang ada daripada membuka shift baru,
 * agar tidak terjadi pembelahan pembukuan kas.
 */
export function apakahShiftMasihBerjalan(
  shift: InfoShiftKas | null | undefined,
  jamTutup = '22:00',
  waktuSekarang: Date = new Date(),
): boolean {
  if (!shift || !shift.id || !shift.dibukaPada) return false

  const tanggalBuka = new Date(shift.dibukaPada)
  if (Number.isNaN(tanggalBuka.getTime())) return false

  // Periksa apakah shift dibuka di tanggal kalender lokal yang sama
  const samaHari =
    tanggalBuka.getFullYear() === waktuSekarang.getFullYear() &&
    tanggalBuka.getMonth() === waktuSekarang.getMonth() &&
    tanggalBuka.getDate() === waktuSekarang.getDate()

  if (!samaHari) {
    // Shift dari hari kemarin yang lupa ditutup
    return false
  }

  // Cek apakah waktu sekarang sudah lewat toleransi jam tutup (+2 jam batas wajar tutup)
  const [jamTutupNum, menitTutupNum] = jamTutup.split(':').map((v) => parseInt(v, 10) || 0)
  const batasToleransi = new Date(waktuSekarang)
  batasToleransi.setHours(jamTutupNum + 2, menitTutupNum, 0, 0)

  if (waktuSekarang.getTime() > batasToleransi.getTime()) {
    return false
  }

  return true
}
