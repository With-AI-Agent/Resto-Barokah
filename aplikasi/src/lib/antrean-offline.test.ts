/**
 * antrean-offline.test.ts — Pengujian unit antrean luring IndexedDB (T10-01 / ART-8).
 */

import { describe, expect, it, beforeEach } from 'vitest'
import {
  apakahAdaDataSensitif,
  bersihkanDataSensitif,
  tambahKeAntrean,
  ambilSemuaAntrean,
  ambilAntreanMenunggu,
  hitungAntreanMenunggu,
  perbaruiStatusItem,
  hapusItemAntrean,
  bersihkanAntreanSukses,
  kosongkanSemuaAntrean,
  prosesAntrean,
  buatKunciIdempoten,
  type ItemAntrean,
} from './antrean-offline'

describe('antrean-offline (T10-01 / ART-8)', () => {
  beforeEach(async () => {
    await kosongkanSemuaAntrean()
  })

  describe('Sanitasi Data Sensitif (DoD: tidak menyimpan data sensitif)', () => {
    it('mendeteksi keberadaan kunci sensitif dengan benar', () => {
      expect(apakahAdaDataSensitif({ nama: 'Budi', meja: '01' })).toBe(false)
      expect(apakahAdaDataSensitif({ nama: 'Budi', pin: '123456' })).toBe(true)
      expect(apakahAdaDataSensitif({ data: { password: 'rahasia-banget' } })).toBe(true)
      expect(apakahAdaDataSensitif([{ id: 1 }, { kredensial: 'abc' }])).toBe(true)
    })

    it('membersihkan PIN, kata sandi, dan kredensial secara rekursif', () => {
      const masukanKotor = {
        pesananId: 'pes-001',
        tipe: 'dinein',
        items: [{ nama: 'Nasi Goreng', harga: 25000 }],
        pin: '123456',
        pin_hash: '$2b$10$abcdef...',
        kata_sandi: 'rahasia123',
        password: 'secretPassword',
        authorization: 'Bearer token-jwt-staf',
        subObjek: {
          pin_lama: '654321',
          kredensial: 'sensitif',
          catatanAman: 'Pedas sedang',
        },
      }

      const hasilBersih = bersihkanDataSensitif(masukanKotor)

      expect(hasilBersih.pesananId).toBe('pes-001')
      expect(hasilBersih.tipe).toBe('dinein')
      expect(hasilBersih.items).toEqual([{ nama: 'Nasi Goreng', harga: 25000 }])
      expect(hasilBersih.subObjek.catatanAman).toBe('Pedas sedang')

      // Pastikan semua properti sensitif lenyap
      expect('pin' in hasilBersih).toBe(false)
      expect('pin_hash' in hasilBersih).toBe(false)
      expect('kata_sandi' in hasilBersih).toBe(false)
      expect('password' in hasilBersih).toBe(false)
      expect('authorization' in hasilBersih).toBe(false)
      expect('pin_lama' in hasilBersih.subObjek).toBe(false)
      expect('kredensial' in hasilBersih.subObjek).toBe(false)
    })

    it('tambahKeAntrean otomatis membersihkan data sensitif', async () => {
      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idemp-001',
        muatan: {
          pesananId: 'pes-002',
          pin: '999888',
          staf: 'Rina',
        },
      })

      expect(item.muatan.pesananId).toBe('pes-002')
      expect(item.muatan.staf).toBe('Rina')
      expect('pin' in item.muatan).toBe(false)
    })
  })

  describe('Kunci Idempoten & Pencegahan Duplikasi (ART-8)', () => {
    it('menghasilkan format kunci idempoten yang valid', () => {
      const kunci = buatKunciIdempoten('pos')
      expect(kunci.startsWith('pos-')).toBe(true)
      expect(kunci.length).toBeGreaterThan(10)
    })

    it('memakai kunci idempoten yang diberikan pemanggil', async () => {
      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-khusus-12345',
        muatan: { total: 50000 },
      })

      expect(item.kunciIdempoten).toBe('kunci-khusus-12345')
    })

    it('menolak menduplikasi item bila kunci idempoten sudah ada (idempotent)', async () => {
      const itemPertama = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-sama-001',
        muatan: { total: 45000 },
      })

      const itemKedua = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-sama-001',
        muatan: { total: 45000 },
      })

      expect(itemKedua.id).toBe(itemPertama.id)
      const semua = await ambilSemuaAntrean()
      expect(semua.length).toBe(1)
    })
  })

  describe('Operasi Antrean & Penghitungan Status (DoD)', () => {
    it('menghitung jumlah menunggu dengan akurat ("menunggu dikirim X")', async () => {
      expect(await hitungAntreanMenunggu()).toBe(0)
      expect(await ambilAntreanMenunggu()).toEqual([])

      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-1',
        muatan: { total: 10000 },
      })
      expect(await hitungAntreanMenunggu()).toBe(1)
      expect((await ambilAntreanMenunggu()).length).toBe(1)

      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-2',
        muatan: { total: 20000 },
      })
      expect(await hitungAntreanMenunggu()).toBe(2)
      expect((await ambilAntreanMenunggu()).length).toBe(2)
    })

    it('memperbarui status item dan pesan galat', async () => {
      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-status-1',
        muatan: { total: 15000 },
      })

      await perbaruiStatusItem(item.id, 'gagal', 'Koneksi terputus')

      const daftar = await ambilSemuaAntrean()
      const terupdate = daftar.find((i) => i.id === item.id)
      expect(terupdate?.status).toBe('gagal')
      expect(terupdate?.pesanGalat).toBe('Koneksi terputus')
      expect(terupdate?.percobaan).toBe(1)
      expect(terupdate?.terakhirDicoba).toBeDefined()
    })

    it('menghapus item dan membersihkan antrean sukses', async () => {
      const item1 = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-del-1',
        muatan: { total: 10000 },
      })
      const item2 = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-del-2',
        muatan: { total: 20000 },
      })

      await perbaruiStatusItem(item1.id, 'sukses')
      const dibersihkan = await bersihkanAntreanSukses()
      expect(dibersihkan).toBe(1)

      const sisa = await ambilSemuaAntrean()
      expect(sisa.length).toBe(1)
      expect(sisa[0].id).toBe(item2.id)

      await hapusItemAntrean(item2.id)
      expect((await ambilSemuaAntrean()).length).toBe(0)
    })
  })

  describe('Pemrosesan Sekuensial (FIFO)', () => {
    it('memproses antrean secara berurutan dan menghapus yang sukses', async () => {
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-fifo-1',
        muatan: { urutan: 1 },
      })
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-fifo-2',
        muatan: { urutan: 2 },
      })

      const urutanDiproses: number[] = []
      const hasil = await prosesAntrean(async (item: ItemAntrean) => {
        urutanDiproses.push(item.muatan.urutan as number)
        return { sukses: true }
      })

      expect(hasil.diproses).toBe(2)
      expect(hasil.berhasil).toBe(2)
      expect(hasil.gagal).toBe(0)
      expect(urutanDiproses).toEqual([1, 2])

      // Semua yang berhasil langsung terhapus dari antrean
      expect(await hitungAntreanMenunggu()).toBe(0)
    })

    it('menghentikan pemrosesan sisa antrean bila terjadi gangguan jaringan', async () => {
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-net-1',
        muatan: { urutan: 1 },
      })
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-net-2',
        muatan: { urutan: 2 },
      })

      let jumlahPanggilan = 0
      const hasil = await prosesAntrean(async () => {
        jumlahPanggilan += 1
        return { sukses: false, pesan: 'Failed to fetch (network error)' }
      })

      expect(jumlahPanggilan).toBe(1)
      expect(hasil.diproses).toBe(1)
      expect(hasil.gagal).toBe(1)
      // Item kedua belum diproses karena jaringan terdeteksi mati
      expect(await hitungAntreanMenunggu()).toBe(2)
    })
  })
})
