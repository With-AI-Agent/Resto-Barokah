/**
 * struk.ts (T6-04) — susun struk pelanggan menjadi byte ESC/POS.
 *
 * Aturan pengikat berkas ini, lanjutan langsung dari keputusan T5-03 & T5-09
 * (lihat `docs/DECISIONS_LOG.md` [Cetak/2026-09-23]):
 *
 *  1. **Tidak menghitung uang.** Semua angka datang dari peladen lewat
 *     `DataStruk`. Satu-satunya "hitungan" di sini adalah `selisihPembulatan`,
 *     dan itu pun **diimpor dari `Struk.tsx`** — bukan disalin. Kalau rumusnya
 *     disalin, suatu hari kertas dan layar akan menyebut angka berbeda, dan
 *     tidak ada yang tahu mana yang benar. Itu persis cacat yang dihindari
 *     T5-09 saat struk digital dibuat membungkus `<Struk>` yang sama.
 *
 *  2. **Isi kertas = isi layar.** Urutan dan pilihan barisnya sengaja mengikuti
 *     `Struk.tsx`: pajak & service selalu tampil (termasuk saat 0 %), diskon
 *     hanya bila ada, pembulatan hanya bila bukan nol.
 *
 *  3. **Header & footer dari pengaturan**, bukan keras-kode (DoD T6-04 & PRD
 *     M2) — resto bisa mengganti nama/alamat/ucapan tanpa menunggu rilis.
 *
 *  4. **Tanggal diformat dari ISO peladen**, bukan `new Date()` perangkat.
 *     Jam kasir yang meleset tidak boleh mengubah tanggal pada bukti bayar.
 */
import { rupiah, tanggalLokal } from '../format'
import { selisihPembulatan, type DataStruk, type PembayaranStruk } from '../../komponen/Struk'
import { LEBAR_58MM, PenyusunEscPos, bungkusTeks } from './expos'

export interface OpsiStruk {
  /** Lebar kertas dalam karakter: 32 (58 mm) atau 48 (80 mm). */
  lebar?: number
  /** Daftar pembayaran yang sudah tercatat peladen. */
  pembayaran?: PembayaranStruk[]
  /** Kembalian SAH dari peladen, bukan hitungan layar. */
  kembalian?: number
  /** Tandai sebagai cetak ulang (T5-10). */
  salinan?: boolean
  /** Nama kasir yang melayani — DoD T6-04. */
  namaKasir?: string
  /**
   * Buka laci kas. Diserahkan pemanggil karena hanya pembayaran TUNAI yang
   * pantas membuka laci; kartu/QRIS tidak.
   */
  bukaLaci?: boolean
}

/**
 * Susun struk lengkap menjadi byte siap kirim ke printer.
 *
 * Hasilnya sengaja `Uint8Array` polos supaya bisa dikirim lewat Bluetooth
 * (T6-02) maupun USB (T6-03) tanpa berkas ini tahu jalur mana yang dipakai.
 */
export function susunStruk(data: DataStruk, opsi: OpsiStruk = {}): Uint8Array {
  const lebar = opsi.lebar ?? LEBAR_58MM
  const p = new PenyusunEscPos(lebar)

  p.awal().pilihCp437()

  // --- Kepala: tanda salinan lebih dulu, supaya terbaca sebelum apa pun.
  p.rata('tengah')
  if (opsi.salinan) {
    p.tebal(true).baris('SALINAN - CETAK ULANG').tebal(false)
  }
  if (data.header) {
    for (const baris of bungkusTeks(data.header, lebar)) p.baris(baris)
  }
  if (data.namaResto) {
    p.tebal(true).baris(data.namaResto).tebal(false)
  }
  p.rata('kiri').garis()

  // --- Identitas transaksi.
  p.baris(`No. ${data.nomor}`)
  p.baris(tanggalLokal(new Date(data.tanggal)))
  if (data.namaMeja) p.baris(data.namaMeja)
  if (opsi.namaKasir) p.baris(`Kasir: ${opsi.namaKasir}`)
  p.garis()

  // --- Item: nama di baris sendiri bila panjang, rincian qty × harga di bawah.
  for (const item of data.item) {
    // Nama dibungkus, tidak dicetak mentah: nama menu panjang ("Nasi Goreng
    // Spesial Kampung Pedas Level Lima") melebihi 32 kolom kertas 58 mm, dan
    // printer akan melipatnya sendiri di tempat sembarang — kadang memotong
    // angka di baris berikutnya. Ini ketahuan dari uji, bukan dari membaca ulang.
    for (const barisNama of bungkusTeks(item.nama, lebar)) p.baris(barisNama)
    p.kiriKanan(`  ${item.qty} x ${rupiah(item.hargaSatuan)}`, rupiah(item.subtotal))
    if (item.catatan) {
      for (const baris of bungkusTeks(item.catatan, lebar - 2)) p.baris(`  ${baris}`)
    }
  }
  p.garis()

  // --- Rincian uang. Urutannya mengikuti Struk.tsx persis.
  p.kiriKanan('Subtotal', rupiah(data.subtotal))
  if (data.totalDiskon > 0) p.kiriKanan('Diskon', `-${rupiah(data.totalDiskon)}`)
  p.kiriKanan('PB1 (pajak)', rupiah(data.pajak))
  p.kiriKanan('Service', rupiah(data.service))

  const pembulatan = selisihPembulatan(data)
  if (pembulatan !== 0) {
    const tanda = pembulatan < 0 ? '-' : '+'
    p.kiriKanan('Pembulatan', `${tanda}${rupiah(Math.abs(pembulatan))}`)
  }

  p.tebal(true).kiriKanan('TOTAL', rupiah(data.total)).tebal(false)

  // --- Pembayaran.
  const pembayaran = opsi.pembayaran ?? []
  if (pembayaran.length > 0) {
    p.garis()
    for (const bayar of pembayaran) {
      const label = bayar.referensi ? `${bayar.metode} (${bayar.referensi})` : bayar.metode
      p.kiriKanan(label, rupiah(bayar.jumlah))
    }
    p.kiriKanan('Kembalian', rupiah(opsi.kembalian ?? 0))

    const dibayar = pembayaran.reduce((jumlah, bayar) => jumlah + bayar.jumlah, 0)
    const sisa = Math.max(0, data.total - dibayar)
    if (sisa === 0) {
      p.rata('tengah').tebal(true).baris('LUNAS').tebal(false).rata('kiri')
    } else {
      // Sisa tagihan WAJIB tercetak: struk yang diam soal sisa membuat tamu
      // mengira sudah lunas, dan selisihnya baru ketahuan saat tutup kas.
      p.kiriKanan('Sisa tagihan', rupiah(sisa))
    }
  }

  // --- Kaki.
  if (data.footer) {
    p.garis().rata('tengah')
    for (const baris of bungkusTeks(data.footer, lebar)) p.baris(baris)
    p.rata('kiri')
  }

  if (opsi.bukaLaci) p.bukaLaci()
  p.potongKertas()

  return p.selesai()
}
