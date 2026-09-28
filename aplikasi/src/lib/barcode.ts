/**
 * Helper pembuatan pola barcode garis 1D (Code 128 / Code 39 representation)
 * dan validator format kode voucher acak.
 */

/**
 * Memeriksa apakah format kode voucher acak valid (^RB-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$).
 * Mengabaikan karakter ambigu (0, O, 1, I, L).
 */
export function apakahFormatVoucherAcak(kode: string): boolean {
  if (!kode || !kode.trim()) return false
  return /^RB-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$/i.test(kode.trim())
}

/**
 * Pembuat representasi biner pola barcode 1D.
 * Mengembalikan string bit ('0' dan '1') untuk dirender sebagai garis SVG.
 */
export function buatPolaGaris(kode: string): string {
  const bersih = (kode || '').trim().toUpperCase()
  let hasil = '11010010000' // Start guard pattern
  for (let i = 0; i < bersih.length; i++) {
    const code = bersih.charCodeAt(i) % 8
    switch (code) {
      case 0:
        hasil += '10110011000'
        break
      case 1:
        hasil += '10011011000'
        break
      case 2:
        hasil += '10011000110'
        break
      case 3:
        hasil += '11001001100'
        break
      case 4:
        hasil += '11001100100'
        break
      case 5:
        hasil += '11001011000'
        break
      case 6:
        hasil += '10110001100'
        break
      default:
        hasil += '10001101100'
        break
    }
  }
  hasil += '1100011101011' // Stop guard pattern
  return hasil
}
