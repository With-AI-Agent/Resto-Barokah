/**
 * Uji T6-01 — penyusun ESC/POS.
 *
 * Kenapa uji ini penting: printer termal tidak bisa "hampir benar". Satu byte
 * meleset dan struk keluar sebagai huruf sampah, atau kertas tidak terpotong,
 * atau angka rupiah bergeser kolom. Uji lapangan hanya terjadi sesekali
 * (T6-08), jadi uji byte inilah yang menjaga tata letak di antaranya.
 */
import { describe, expect, it } from 'vitest'
import {
  LEBAR_58MM,
  LEBAR_80MM,
  PenyusunEscPos,
  barisKiriKanan,
  barisTengah,
  bungkusTeks,
  garis,
  keCp437,
  lebarCetak,
  potong,
} from './expos'

/** Bantuan baca: ubah byte jadi teks agar harapan uji mudah dipahami manusia. */
function keTeks(byte: Uint8Array): string {
  return Array.from(byte)
    .map((b) => (b >= 0x20 && b <= 0x7e ? String.fromCharCode(b) : `<${b.toString(16)}>`))
    .join('')
}

describe('keCp437 — teks Indonesia & huruf beraksen', () => {
  it('huruf ASCII biasa dikirim apa adanya', () => {
    expect(keCp437('Nasi Goreng')).toEqual([78, 97, 115, 105, 32, 71, 111, 114, 101, 110, 103])
  })

  it('huruf beraksen diganti huruf polos, BUKAN dibuang (kolom tidak boleh bergeser)', () => {
    // "Crème Brûlée" → "Creme Brulee": 12 huruf masuk, 12 byte keluar.
    const byte = keCp437('Crème Brûlée')
    expect(String.fromCharCode(...byte)).toBe('Creme Brulee')
    expect(byte).toHaveLength(12)
  })

  it('tanda kutip miring dan garis panjang disederhanakan', () => {
    expect(String.fromCharCode(...keCp437('“Ayam” – enak'))).toBe('"Ayam" - enak')
  })

  it('huruf yang benar-benar asing jadi ? supaya panjang tetap terduga', () => {
    const byte = keCp437('滋')
    expect(byte).toEqual([0x3f])
  })

  it('rupiah dengan pemisah ribuan aman', () => {
    expect(String.fromCharCode(...keCp437('Rp27.500'))).toBe('Rp27.500')
  })
})

describe('lebarCetak — panjang yang benar-benar tercetak', () => {
  it('menghitung "…" sebagai tiga titik, bukan satu huruf', () => {
    expect('…'.length).toBe(1) // JavaScript bilang 1
    expect(lebarCetak('…')).toBe(3) // printer mencetak 3
  })
})

describe('barisKiriKanan — angka uang tidak pernah dikorbankan', () => {
  it('nama pendek: angka menempel di tepi kanan', () => {
    const baris = barisKiriKanan('Es Teh', 'Rp5.000', LEBAR_58MM)
    expect(baris).toHaveLength(LEBAR_58MM)
    expect(baris.endsWith('Rp5.000')).toBe(true)
    expect(baris.startsWith('Es Teh')).toBe(true)
  })

  it('nama kepanjangan: NAMA yang dipotong, angka tetap utuh', () => {
    const panjang = 'Nasi Goreng Spesial Kampung Pedas Level Lima'
    const baris = barisKiriKanan(panjang, 'Rp127.500', LEBAR_58MM)
    expect(baris).toHaveLength(LEBAR_58MM)
    expect(baris.endsWith('Rp127.500')).toBe(true)
    // Nama pasti terpotong — itu memang yang dikehendaki.
    expect(baris.includes('Level Lima')).toBe(false)
  })

  it('selalu ada minimal satu spasi antara nama dan angka', () => {
    const baris = barisKiriKanan('A'.repeat(100), 'Rp1.000', LEBAR_58MM)
    expect(baris).toHaveLength(LEBAR_58MM)
    expect(baris.includes(' Rp1.000')).toBe(true)
  })

  it('angka yang lebih lebar dari kertas TETAP UTUH (tidak pernah dipenggal)', () => {
    // Kertas sempit 8 kolom, harga 11 kolom. Lebih baik satu baris berantakan
    // daripada struk mencetak "Rp1.250." dan tamu membaca nilai yang salah.
    const baris = barisKiriKanan('Paket Pesta', 'Rp1.250.000', 8)
    expect(baris).toBe('Rp1.250.000')
    expect(baris.includes('1.250.000')).toBe(true)
  })

  it('kertas 80 mm memakai 48 kolom', () => {
    const baris = barisKiriKanan('Es Teh', 'Rp5.000', LEBAR_80MM)
    expect(baris).toHaveLength(48)
  })
})

describe('barisTengah & garis', () => {
  it('menaruh teks di tengah', () => {
    expect(barisTengah('OASIS', 11)).toBe('   OASIS')
  })

  it('garis selebar kertas', () => {
    expect(garis(LEBAR_58MM)).toHaveLength(32)
    expect(garis(LEBAR_80MM)).toHaveLength(48)
  })
})

describe('potong', () => {
  it('tidak melebihi lebar yang diminta', () => {
    expect(potong('Nasi Goreng Spesial', 11)).toBe('Nasi Goreng')
  })

  it('lebar 0 menghasilkan teks kosong (tidak meledak)', () => {
    expect(potong('apa pun', 0)).toBe('')
  })
})

describe('bungkusTeks — catatan dapur tidak boleh berubah arti', () => {
  it('memecah di sela kata, bukan di tengah kata', () => {
    const baris = bungkusTeks('tanpa sambal pedas sedikit saja', 12)
    for (const b of baris) expect(lebarCetak(b)).toBeLessThanOrEqual(12)
    expect(baris.join(' ')).toBe('tanpa sambal pedas sedikit saja')
  })

  it('kata tunggal yang lebih panjang dari kertas dipenggal paksa', () => {
    const baris = bungkusTeks('AAAAAAAAAAAAAAAAAAAA', 8)
    expect(baris).toEqual(['AAAAAAAA', 'AAAAAAAA', 'AAAA'])
  })

  it('teks kosong menghasilkan daftar kosong', () => {
    expect(bungkusTeks('   ', 10)).toEqual([])
  })
})

describe('PenyusunEscPos — byte perintah', () => {
  it('ESC @ mengawali, ESC t 0 memilih CP437', () => {
    const byte = new PenyusunEscPos().awal().pilihCp437().selesai()
    expect(Array.from(byte)).toEqual([0x1b, 0x40, 0x1b, 0x74, 0x00])
  })

  it('tebal hidup lalu mati', () => {
    const byte = new PenyusunEscPos().tebal(true).tebal(false).selesai()
    expect(Array.from(byte)).toEqual([0x1b, 0x45, 0x01, 0x1b, 0x45, 0x00])
  })

  it('perataan kiri/tengah/kanan memakai ESC a', () => {
    const byte = new PenyusunEscPos().rata('kiri').rata('tengah').rata('kanan').selesai()
    expect(Array.from(byte)).toEqual([0x1b, 0x61, 0x00, 0x1b, 0x61, 0x01, 0x1b, 0x61, 0x02])
  })

  it('huruf besar memakai GS !', () => {
    const byte = new PenyusunEscPos().hurufBesar(true).hurufBesar(false).selesai()
    expect(Array.from(byte)).toEqual([0x1d, 0x21, 0x11, 0x1d, 0x21, 0x00])
  })

  it('potong kertas memberi umpan baris dulu, supaya baris terakhir tidak ikut terpotong', () => {
    const byte = new PenyusunEscPos().potongKertas().selesai()
    expect(Array.from(byte)).toEqual([0x0a, 0x0a, 0x0a, 0x1d, 0x56, 0x00])
  })

  it('buka laci memakai ESC p', () => {
    const byte = new PenyusunEscPos().bukaLaci().selesai()
    expect(Array.from(byte)).toEqual([0x1b, 0x70, 0x00, 0x19, 0xfa])
  })

  it('baris menambahkan pindah baris', () => {
    const byte = new PenyusunEscPos().baris('Hai').selesai()
    expect(keTeks(byte)).toBe('Hai<a>')
  })

  it('kiriKanan memakai lebar kertas penyusunnya', () => {
    const byte = new PenyusunEscPos(LEBAR_58MM).kiriKanan('Es Teh', 'Rp5.000').selesai()
    const teks = String.fromCharCode(...Array.from(byte).slice(0, -1))
    expect(teks).toHaveLength(32)
    expect(teks.endsWith('Rp5.000')).toBe(true)
  })

  it('hasil akhir berupa Uint8Array siap kirim', () => {
    const byte = new PenyusunEscPos().awal().baris('OK').potongKertas().selesai()
    expect(byte).toBeInstanceOf(Uint8Array)
    expect(byte.length).toBeGreaterThan(0)
  })

  it('bawaan penyusun adalah kertas 58 mm', () => {
    expect(new PenyusunEscPos().lebar).toBe(32)
  })

  it('rangkaian lengkap tetap berurutan (awal → isi → potong)', () => {
    const byte = new PenyusunEscPos(LEBAR_58MM)
      .awal()
      .pilihCp437()
      .rata('tengah')
      .tebal(true)
      .baris('KEDAI OASIS')
      .tebal(false)
      .rata('kiri')
      .garis()
      .kiriKanan('Nasi Goreng', 'Rp27.500')
      .potongKertas()
      .selesai()
    const teks = keTeks(byte)
    expect(teks.startsWith('<1b>@<1b>t<0>')).toBe(true)
    expect(teks.includes('KEDAI OASIS')).toBe(true)
    expect(teks.includes('--------')).toBe(true)
    expect(teks.includes('Rp27.500')).toBe(true)
    expect(teks.endsWith('<1d>V<0>')).toBe(true)
  })
})
