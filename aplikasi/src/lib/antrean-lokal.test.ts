/**
 * Uji penyimpanan antrean cadangan per perangkat (T4-10) & Pemulihan Mati Mendadak (T10-09).
 */
// @vitest-environment jsdom
import { describe, expect, it, beforeEach } from 'vitest'
import {
  simpanAntreanTerakhir,
  muatAntreanTerakhir,
  hapusAntreanTerakhir,
  simpanDrafKasir,
  muatDrafKasir,
  hapusDrafKasir,
  simpanTagihanTerbukaLokal,
  muatTagihanTerbukaLokal,
  hapusTagihanTerbukaLokal,
  rekonsiliasiEntitas,
  rekonsiliasiDaftarPesanan,
} from './antrean-lokal'

describe('antrean-lokal (T4-10 & T10-09)', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  // ==========================================================================
  // BAGIAN 1: ANTREAN DAPUR & BAR (T4-10)
  // ==========================================================================
  describe('Antrean Dapur & Bar', () => {
    it('menyimpan lalu memuat kembali tiket antrean', () => {
      const tiket = [
        { id: 't1', nomor: 7 },
        { id: 't2', nomor: 8 },
      ]
      simpanAntreanTerakhir('dapur', tiket)
      expect(muatAntreanTerakhir<{ id: string }>('dapur')).toEqual(tiket)
    })

    it('antrean dapur dan bar disimpan terpisah', () => {
      simpanAntreanTerakhir('dapur', [{ id: 'dapur-1' }])
      simpanAntreanTerakhir('bar', [{ id: 'bar-1' }])
      expect(muatAntreanTerakhir<{ id: string }>('dapur')).toEqual([{ id: 'dapur-1' }])
      expect(muatAntreanTerakhir<{ id: string }>('bar')).toEqual([{ id: 'bar-1' }])
    })

    it('muatan kosong / JSON rusak menghasilkan null, bukan meledak', () => {
      expect(muatAntreanTerakhir('dapur')).toBeNull()
      localStorage.setItem('resto.antrean-terakhir.dapur', 'bukan-json')
      expect(muatAntreanTerakhir('dapur')).toBeNull()
      localStorage.setItem('resto.antrean-terakhir.dapur', JSON.stringify({ versi: 99 }))
      expect(muatAntreanTerakhir('dapur')).toBeNull()
    })

    it('bisa dihapus (mis. setelah daring kembali)', () => {
      simpanAntreanTerakhir('dapur', [{ id: 't1' }])
      hapusAntreanTerakhir('dapur')
      expect(muatAntreanTerakhir('dapur')).toBeNull()
    })
  })

  // ==========================================================================
  // BAGIAN 2: PEMULIHAN DRAF KERANJANG KASIR (T10-09)
  // ==========================================================================
  describe('Draf Keranjang Kasir (T10-09)', () => {
    it('menyimpan dan memuat kembali draf keranjang kasir per cabang', () => {
      const draf = {
        daftarItemKeranjang: [
          { id: 'item-1', nama: 'Nasi Goreng', harga: 25000, qty: 2, subtotal: 50000 },
        ],
        tipePesanan: 'dinein',
        mejaAktif: { id: 'm-01', nama: 'Meja 01', status: 'terisi', aktif: true },
        diskonAktif: 5000,
        catatanPesananUmum: 'Pedas sedang',
      }

      simpanDrafKasir('cab-01', draf)

      const termuat = muatDrafKasir('cab-01')
      expect(termuat).not.toBeNull()
      expect(termuat?.cabangId).toBe('cab-01')
      expect(termuat?.versi).toBe(1)
      expect(termuat?.daftarItemKeranjang).toEqual(draf.daftarItemKeranjang)
      expect(termuat?.mejaAktif?.nama).toBe('Meja 01')
      expect(termuat?.diskonAktif).toBe(5000)
      expect(typeof termuat?.disimpanPada).toBe('string')
    })

    it('draf kasir antar cabang disimpan terpisah', () => {
      simpanDrafKasir('cab-01', {
        daftarItemKeranjang: [
          { id: 'item-cab-1', nama: 'Es Teh', harga: 5000, qty: 1, subtotal: 5000 },
        ],
      })
      simpanDrafKasir('cab-02', {
        daftarItemKeranjang: [
          { id: 'item-cab-2', nama: 'Kopi Susu', harga: 15000, qty: 1, subtotal: 15000 },
        ],
      })

      const drafCab1 = muatDrafKasir<{ id: string; nama: string }>('cab-01')
      const drafCab2 = muatDrafKasir<{ id: string; nama: string }>('cab-02')

      expect(drafCab1?.daftarItemKeranjang[0].nama).toBe('Es Teh')
      expect(drafCab2?.daftarItemKeranjang[0].nama).toBe('Kopi Susu')
    })

    it('menyimpan keranjang kosong otomatis menghapus draf kasir', () => {
      simpanDrafKasir('cab-01', {
        daftarItemKeranjang: [
          { id: 'item-1', nama: 'Ayam Goreng', harga: 20000, qty: 1, subtotal: 20000 },
        ],
      })
      expect(muatDrafKasir('cab-01')).not.toBeNull()

      // Simpan draf dengan array kosong
      simpanDrafKasir('cab-01', { daftarItemKeranjang: [] })
      expect(muatDrafKasir('cab-01')).toBeNull()
    })

    it('hapusDrafKasir menghapus draf dari penyimpanan lokal', () => {
      simpanDrafKasir('cab-01', {
        daftarItemKeranjang: [
          { id: 'item-1', nama: 'Ayam Bakar', harga: 22000, qty: 1, subtotal: 22000 },
        ],
      })
      hapusDrafKasir('cab-01')
      expect(muatDrafKasir('cab-01')).toBeNull()
    })

    it('kebal terhadap muatan draf rusak atau cabangId tidak cocok', () => {
      localStorage.setItem('resto.kasir.draf.cab-01', 'bukan-format-json')
      expect(muatDrafKasir('cab-01')).toBeNull()

      localStorage.setItem(
        'resto.kasir.draf.cab-01',
        JSON.stringify({ versi: 1, cabangId: 'cab-LAIN', daftarItemKeranjang: [{ id: '1' }] }),
      )
      expect(muatDrafKasir('cab-01')).toBeNull()
    })
  })

  // ==========================================================================
  // BAGIAN 3: CADANGAN TAGIHAN TERBUKA LOKAL (T10-09)
  // ==========================================================================
  describe('Cadangan Tagihan Terbuka Lokal (T10-09)', () => {
    it('menyimpan, memuat, dan menghapus tagihan terbuka lokal', () => {
      const tagihan = [
        { id: 'bill-1', nomor: 101, namaMeja: 'Meja 01', total: 60000, status: 'dimasak' },
        { id: 'bill-2', nomor: 102, namaMeja: 'Meja 05', total: 120000, status: 'dikirim' },
      ]

      simpanTagihanTerbukaLokal('cab-01', tagihan)
      const termuat = muatTagihanTerbukaLokal<{ id: string; nomor: number }>('cab-01')

      expect(termuat).toEqual(tagihan)

      hapusTagihanTerbukaLokal('cab-01')
      expect(muatTagihanTerbukaLokal('cab-01')).toBeNull()
    })

    it('mengembalikan null jika isi penyimpanan rusak', () => {
      localStorage.setItem('resto.kasir.tagihan-terbuka.cab-01', '{rusak}')
      expect(muatTagihanTerbukaLokal('cab-01')).toBeNull()
    })
  })

  // ==========================================================================
  // BAGIAN 4: ATURAN REKONSILIASI SERVER-WINS (TECH_SPEC §10 & §11)
  // ==========================================================================
  describe('Rekonsiliasi Server-Wins (TECH_SPEC §10 & §11)', () => {
    it('mengembalikan data server saat ada perbedaan antara lokal dan server (server-wins)', () => {
      const lokal = {
        id: 'ord-01',
        status: 'dikirim',
        total: 50000,
        diperbaruiPada: '2026-09-27T08:00:00Z',
      }
      const server = {
        id: 'ord-01',
        status: 'dimasak', // Dapur sudah mengupdate status di peladen
        total: 50000,
        diperbaruiPada: '2026-09-27T08:05:00Z',
      }

      const hasil = rekonsiliasiEntitas(lokal, server)

      expect(hasil).not.toBeNull()
      expect(hasil?.dataTerpilih).toEqual(server)
      expect(hasil?.sumber).toBe('server')
      expect(hasil?.adaKonflik).toBe(true)
      expect(hasil?.alasan).toContain('server-wins')
    })

    it('mengidentifikasi tidak ada konflik bila data lokal dan server identik', () => {
      const lokal = { id: 'ord-02', status: 'dimasak', total: 35000 }
      const server = { id: 'ord-02', status: 'dimasak', total: 35000 }

      const hasil = rekonsiliasiEntitas(lokal, server)

      expect(hasil?.dataTerpilih).toEqual(server)
      expect(hasil?.adaKonflik).toBe(false)
      expect(hasil?.sumber).toBe('server')
    })

    it('mempertahankan data lokal jika entitas baru belum ada di peladen', () => {
      const drafBaruLokal = { id: 'ord-baru-offline', status: 'draf', total: 40000 }
      const hasil = rekonsiliasiEntitas(drafBaruLokal, null)

      expect(hasil?.dataTerpilih).toEqual(drafBaruLokal)
      expect(hasil?.sumber).toBe('lokal')
      expect(hasil?.adaKonflik).toBe(false)
    })

    it('merekonsiliasi daftar pesanan dengan menggabungkan entitas server dan mempertahankan draf lokal', () => {
      const daftarLokal = [
        { id: 'ord-1', status: 'dikirim', total: 50000 },
        { id: 'ord-baru-lokal', status: 'draf', total: 20000 },
      ]
      const daftarServer = [
        { id: 'ord-1', status: 'siap', total: 50000 }, // Status server lebih maju
        { id: 'ord-2', status: 'dimasak', total: 75000 }, // Pesanan dari kasir lain
      ]

      const { hasil, konflik, jumlahDipulihkanDariLokal } = rekonsiliasiDaftarPesanan(
        daftarLokal,
        daftarServer,
      )

      // Hasil akhir harus memuat 3 pesanan: 2 dari server + 1 draf lokal yang belum ada di server
      expect(hasil).toHaveLength(3)
      expect(jumlahDipulihkanDariLokal).toBe(1)

      // ord-1 harus mengambil versi server ('siap', bukan 'dikirim')
      const ord1 = hasil.find((item) => item.id === 'ord-1')
      expect(ord1?.status).toBe('siap')

      // ord-baru-lokal tetap ada
      const ordLokal = hasil.find((item) => item.id === 'ord-baru-lokal')
      expect(ordLokal?.status).toBe('draf')

      // Konflik tercatat untuk ord-1
      expect(konflik).toHaveLength(1)
      expect(konflik[0].id).toBe('ord-1')
    })
  })
})
