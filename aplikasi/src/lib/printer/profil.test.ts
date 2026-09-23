/**
 * Uji profil printer — terutama JAMINAN MEREK LAIN TETAP JALAN.
 *
 * Pertanyaan pemilik (2026-09-23): "kalau ada yang pakai printer lain selain
 * yang disebutkan, bisa tetap berjalan tidak?" Jawabannya harus "ya", dan
 * berkas uji inilah yang menjaganya. Kalau suatu hari ada yang mengubah kode
 * sehingga hanya merek terdaftar yang diterima, uji di bawah MERAH.
 */
import { describe, expect, it } from 'vitest'
import {
  PROFIL_DIKENAL,
  PROFIL_UMUM,
  PROFIL_UMUM_80,
  POTONGAN_BLE,
  SEMUA_PROFIL,
  UUID_LAYANAN_UMUM,
  profilDariId,
  tebakProfil,
} from './profil'
import { LEBAR_58MM, LEBAR_80MM } from './expos'
import { susunStruk } from './struk'
import type { DataStruk } from '../../komponen/Struk'

describe('JAMINAN: printer di luar daftar tetap bisa dipakai', () => {
  it('merek yang tidak dikenal TIDAK ditolak, tetapi dapat profil umum', () => {
    const asing = tebakProfil('Printer Antah Berantah XYZ-999')
    expect(asing).toBeTruthy()
    expect(asing.id).toBe('umum-58')
    expect(asing.lebar).toBe(LEBAR_58MM)
  })

  it('nama perangkat kosong atau tidak diketahui tetap dapat profil yang bisa dipakai', () => {
    for (const nama of [null, undefined, '', '   ', 'BT-Printer']) {
      const profil = tebakProfil(nama)
      expect(profil.lebar).toBeGreaterThan(0)
      expect(profil.sambung.length).toBeGreaterThan(0)
    }
  })

  it('kode profil yang tidak dikenal jatuh ke profil umum, bukan meledak', () => {
    expect(profilDariId('merek-yang-tidak-ada').id).toBe('umum-58')
    expect(profilDariId(null).id).toBe('umum-58')
  })

  it('struk tetap tersusun penuh memakai profil printer asing', () => {
    const data: DataStruk = {
      nomor: 7,
      tanggal: '2026-09-23T04:00:00.000Z',
      namaResto: 'Kedai Oasis',
      item: [{ nama: 'Nasi Goreng', qty: 1, hargaSatuan: 27500, subtotal: 27500 }],
      subtotal: 27500,
      totalDiskon: 0,
      pajak: 2750,
      service: 0,
      total: 30250,
    }
    const profil = tebakProfil('Merek Asing Sekali')
    const byte = susunStruk(data, { lebar: profil.lebar })
    // Diawali ESC @ dan diakhiri potong kertas — sama seperti printer dikenal.
    expect(Array.from(byte.slice(0, 2))).toEqual([0x1b, 0x40])
    expect(Array.from(byte.slice(-3))).toEqual([0x1d, 0x56, 0x00])
    expect(byte.length).toBeGreaterThan(50)
  })

  it('profil umum memilih anggapan yang AMAN bila salah (58 mm, tanpa pisau/laci)', () => {
    // Struk 58 mm yang dicetak di printer 80 mm hanya menyisakan ruang kosong;
    // sebaliknya, struk 80 mm di printer 58 mm KEHILANGAN angka di kanan.
    expect(PROFIL_UMUM.lebar).toBe(LEBAR_58MM)
    expect(PROFIL_UMUM.pemotong).toBe(false)
    expect(PROFIL_UMUM.laci).toBe(false)
  })

  it('profil umum mendukung kedua cara sambung', () => {
    expect(PROFIL_UMUM.sambung).toContain('bluetooth')
    expect(PROFIL_UMUM.sambung).toContain('usb')
  })

  it('tersedia juga profil umum 80 mm bila kertasnya lebar', () => {
    expect(PROFIL_UMUM_80.lebar).toBe(LEBAR_80MM)
  })
})

describe('Lima printer yang dipastikan pemilik (2026-09-23)', () => {
  it('semuanya ada di daftar', () => {
    expect(PROFIL_DIKENAL).toHaveLength(5)
  })

  it.each([
    ['Goojprt PT-210', 'goojprt-pt210', LEBAR_58MM],
    ['MyPrinter BT-P290', 'kassen-btp290', LEBAR_58MM],
    ['Blueprint Lite-58', 'blueprint-lite58', LEBAR_58MM],
    ['XPrinter XP-N160II', 'xprinter-xpn160ii', LEBAR_80MM],
    ['EPSON TM-T82X', 'epson-tmt82x', LEBAR_80MM],
  ])('nama perangkat "%s" dikenali sebagai %s dengan lebar benar', (nama, id, lebar) => {
    const profil = tebakProfil(nama)
    expect(profil.id).toBe(id)
    expect(profil.lebar).toBe(lebar)
  })

  it('pencocokan nama tidak peka huruf besar/kecil', () => {
    expect(tebakProfil('goojprt pt-210').id).toBe('goojprt-pt210')
    expect(tebakProfil('GOOJPRT PT-210').id).toBe('goojprt-pt210')
  })

  it('printer 80 mm ditandai punya pisau & laci, printer saku 58 mm tidak', () => {
    expect(profilDariId('xprinter-xpn160ii').pemotong).toBe(true)
    expect(profilDariId('epson-tmt82x').laci).toBe(true)
    expect(profilDariId('goojprt-pt210').pemotong).toBe(false)
  })

  it('setiap profil punya id unik dan lebar yang sah', () => {
    const id = SEMUA_PROFIL.map((p) => p.id)
    expect(new Set(id).size).toBe(id.length)
    for (const p of SEMUA_PROFIL) {
      expect([LEBAR_58MM, LEBAR_80MM]).toContain(p.lebar)
      expect(p.nama.length).toBeGreaterThan(0)
    }
  })
})

describe('Sambungan Bluetooth: daftar alamat layanan', () => {
  it('memuat beberapa alamat, bukan hanya satu (tiap pabrik berbeda)', () => {
    expect(UUID_LAYANAN_UMUM.length).toBeGreaterThanOrEqual(4)
  })

  it('memuat alamat 18f0 yang dipakai banyak printer saku', () => {
    expect(UUID_LAYANAN_UMUM.some((u) => u.startsWith('000018f0'))).toBe(true)
  })

  it('semua alamat ditulis huruf kecil (Web Bluetooth menuntut itu)', () => {
    for (const u of UUID_LAYANAN_UMUM) expect(u).toBe(u.toLowerCase())
  })

  it('kiriman BLE dipotong 20 byte — banyak printer murah hanya menerima sebanyak itu', () => {
    expect(POTONGAN_BLE).toBe(20)
  })
})
