/**
 * tarif.ts (T-027) — perkiraan pajak & service di keranjang, memakai TARIF RESTO
 * yang tersimpan di `public.pengaturan`, bukan angka keras-kode di layar.
 *
 * KENAPA ADA:
 * Sebelum ini keranjang kasir menghitung pajak 10 % dan service 5 % yang ditulis
 * langsung di kode. Uangnya tidak pernah salah — angka yang SAH selalu datang
 * dari peladen (`hitung_total`) dan itulah yang ditagih serta dicetak di struk.
 * Tetapi kalau kedai memakai tarif lain (mis. pajak 11 %, atau tanpa service),
 * angka di keranjang meleset dari yang akhirnya ditagih: kasir sudah terlanjur
 * menyebut "lima puluh ribu" lalu struk keluar lima puluh satu ribu. Bukan
 * kehilangan uang, tetapi memalukan dan membuat tamu curiga.
 *
 * Lebih penting lagi: tarif pajak BISA BERUBAH karena aturan pemerintah. Kalau
 * angkanya terkunci di kode, setiap perubahan menuntut pembaruan aplikasi. Dengan
 * dibaca dari pengaturan, pemilik kedai bisa menyesuaikannya sendiri tanpa
 * menyentuh kode sama sekali.
 *
 * RUMUSNYA SENGAJA MENIRU PELADEN PERSIS (`hitung_total`, migrasi 0025):
 *   dasar   = maks(subtotal - diskon, 0)
 *   pajak   = bulat(dasar * persen_pajak / 100)
 *   service = bulat(dasar * persen_service / 100)
 *   total   = dasar + pajak + service, lalu DIBULATKAN TURUN ke kelipatan
 *             `pembulatan` bila resto memakainya.
 *
 * Urutannya penting: pajak dihitung dari dasar SESUDAH diskon, bukan sebelumnya.
 * Kalau layar memakai urutan berbeda, selisihnya baru terlihat saat ada diskon —
 * justru saat kasir paling butuh angkanya benar.
 *
 * TETAP SEBUAH PERKIRAAN. Layar tidak pernah menjadi sumber kebenaran uang.
 * Yang ditagih ke tamu selalu hasil hitungan peladen.
 */

export interface TarifResto {
  /** Persen PB1/pajak, mis. 10 atau 11. */
  pajakPersen: number
  /** Persen service charge, mis. 5. Boleh 0 kalau kedai tidak memungutnya. */
  servicePersen: number
  /** Pembulatan total: 'none' | '100' | '500' | '1000' — sama seperti kolom `pengaturan.pembulatan`. */
  pembulatan: 'none' | '100' | '500' | '1000'
}

/**
 * Dipakai HANYA sebagai jaring pengaman saat pengaturan resto belum termuat
 * (misalnya jaringan sedang lambat di detik-detik pertama aplikasi dibuka).
 * Angkanya sama dengan nilai bawaan kolom `pengaturan` di migrasi 0004, supaya
 * layar tidak pernah menampilkan tarif yang tidak pernah ada di mana pun.
 */
export const TARIF_BAWAAN: TarifResto = {
  pajakPersen: 10,
  servicePersen: 5,
  pembulatan: 'none',
}

export interface RincianUang {
  subtotal: number
  totalDiskon: number
  pajak: number
  service: number
  total: number
}

/**
 * Hitung perkiraan keranjang dengan tarif resto.
 *
 * Nilai tarif yang tidak masuk akal (negatif, bukan angka) diperlakukan sebagai
 * 0 alih-alih membuat layar menampilkan `NaN`. Kasir yang melihat "RpNaN" tidak
 * punya cara menebak apa yang salah, sedangkan angka 0 langsung terbaca keliru
 * dan bisa dilaporkan.
 */
export function hitungPerkiraan(
  subtotal: number,
  totalDiskon: number,
  tarif: TarifResto = TARIF_BAWAAN,
): RincianUang {
  const dasar = Math.max(0, subtotal - totalDiskon)

  const pajak = Math.round((dasar * bersihkanPersen(tarif.pajakPersen)) / 100)
  const service = Math.round((dasar * bersihkanPersen(tarif.servicePersen)) / 100)

  const langkah = langkahPembulatan(tarif.pembulatan)
  const kasar = dasar + pajak + service
  // Peladen membulatkan TURUN (pembagian bilangan bulat), jadi layar pun turun.
  // Membulatkan ke atas akan membuat perkiraan lebih besar daripada tagihan
  // sebenarnya — tamu merasa ditagih lebih, dan itu keluhan yang mahal.
  const total = langkah > 0 ? Math.floor(kasar / langkah) * langkah : kasar

  return { subtotal, totalDiskon, pajak, service, total }
}

function bersihkanPersen(nilai: number): number {
  if (!Number.isFinite(nilai) || nilai < 0) return 0
  return nilai
}

function langkahPembulatan(pembulatan: TarifResto['pembulatan']): number {
  if (pembulatan === 'none') return 0
  const angka = Number(pembulatan)
  return Number.isFinite(angka) && angka > 0 ? angka : 0
}
