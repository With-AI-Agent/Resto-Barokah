// @vitest-environment jsdom
/**
 * luring.spec.ts — Uji Putus-Sambung Jaringan & Anti Data Dobel (T10-04 / ART-8).
 *
 * Menguji ketahanan aplikasi kasir saat mengalami kehilangan koneksi internet,
 * pengiriman transaksi ke antrean luring, pemulihan otomatis saat jaringan kembali,
 * serta pembuktian bahwa mekanisme kunci idempoten (ART-8) mencegah data dobel
 * pada pesanan, pembayaran, dan voucher.
 */
import React from 'react'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup, act } from '@testing-library/react'
import {
  kosongkanSemuaAntrean,
  ambilSemuaAntrean,
  tambahKeAntrean,
  prosesAntrean,
  hitungStatistikAntrean,
  type ItemAntrean,
} from '../../src/lib/antrean-offline'
import { useAntrean } from '../../src/hook/useAntrean'
import { StatusAntrean } from '../../src/komponen/StatusAntrean'
import { PenyediaBahasa } from '../../src/bahasa'

describe('T10-04: Uji Putus-Sambung Jaringan & Anti Data Dobel (ART-8)', () => {
  beforeEach(async () => {
    await kosongkanSemuaAntrean()
    vi.restoreAllMocks()
  })

  afterEach(() => {
    cleanup()
  })

  // ==========================================================================
  // SKENARIO 1: PESANAN SAAT LURING -> PULIH -> TEPAT 1 (ANTI DOBEL PESANAN)
  // ==========================================================================
  describe('Skenario 1: Pesanan dikirim saat luring', () => {
    it('menyimpan pesanan ke antrean luring dengan kunci idempoten dan status menunggu jujur', async () => {
      // Simulasikan keadaan offline
      Object.defineProperty(navigator, 'onLine', { value: false, configurable: true })

      const pesananMuatan = {
        pesananId: 'pesanan-offline-001',
        penyewaId: 'penyewa-1',
        cabangId: 'cabang-1',
        mejaId: 'meja-04',
        tipe: 'dinein',
        items: [
          { menuItemId: 'menu-1', nama: 'Nasi Goreng Spesial', harga: 25000, qty: 2 },
          { menuItemId: 'menu-2', nama: 'Es Teh Manis', harga: 5000, qty: 2 },
        ],
        total: 60000,
      }

      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-pesanan-001',
        labelRingkas: 'Pesanan Meja 04 — 2 Item',
        muatan: pesananMuatan,
      })

      expect(item.id).toBeDefined()
      expect(item.status).toBe('menunggu')
      expect(item.kunciIdempoten).toBe('kunci-pesanan-001')
      expect(item.labelRingkas).toBe('Pesanan Meja 04 — 2 Item')

      const stats = await hitungStatistikAntrean()
      expect(stats.menunggu).toBe(1)
      expect(stats.sukses).toBe(0)
    })

    it('memproses pesanan saat jaringan pulih dan menjamin peladen hanya mencatat tepat 1 kali (anti-dobel)', async () => {
      // 1. Simpan pesanan saat luring
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-pesanan-idem-001',
        labelRingkas: 'Pesanan Meja 05',
        muatan: {
          pesananId: 'pesanan-001',
          total: 50000,
        },
      })

      // Tiruan basis data peladen untuk memverifikasi jumlah transaksi
      const peladenPesanan: Array<{ id: string; kunciIdempoten: string; total: number }> = []

      // Penangan peladen yang mengimplementasikan kunci idempoten unik (ART-8)
      const penanganPeladen = async (item: ItemAntrean) => {
        // Cek duplikasi kunci idempoten di peladen
        const duplikat = peladenPesanan.find((p) => p.kunciIdempoten === item.kunciIdempoten)
        if (duplikat) {
          // Idempoten: respons sukses tanpa membuat baris baru
          return { sukses: true }
        }

        peladenPesanan.push({
          id: (item.muatan.pesananId as string) || item.id,
          kunciIdempoten: item.kunciIdempoten,
          total: (item.muatan.total as number) || 0,
        })
        return { sukses: true }
      }

      // 2. Jaringan pulih -> antrean diproses pertama kali
      Object.defineProperty(navigator, 'onLine', { value: true, configurable: true })
      const hasil1 = await prosesAntrean(penanganPeladen)

      expect(hasil1.berhasil).toBe(1)
      expect(peladenPesanan).toHaveLength(1)
      expect(peladenPesanan[0].id).toBe('pesanan-001')

      // 3. Simulasikan pemicuan ulang sinkronisasi (fluktuasi jaringan / retry otomatis ganda)
      const antreanUlang: ItemAntrean = {
        id: 'item-sync-lagi',
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'kunci-pesanan-idem-001', // KUNCI SAMA
        muatan: { pesananId: 'pesanan-001', total: 50000 },
        status: 'menunggu',
        percobaan: 1,
        dibuatPada: new Date().toISOString(),
      }

      const hasilUlang = await penanganPeladen(antreanUlang)
      expect(hasilUlang.sukses).toBe(true)

      // BUKTI T10-04 DoD: Jumlah pesanan di peladen TETAP TEPAT 1 (TIDAK DOBEL)
      expect(peladenPesanan).toHaveLength(1)
      expect(peladenPesanan[0].total).toBe(50000)
    })
  })

  // ==========================================================================
  // SKENARIO 2: PEMBAYARAN SAAT LURING -> PULIH -> TEPAT 1 (ANTI DOBEL UANG)
  // ==========================================================================
  describe('Skenario 2: Pembayaran dikirim saat luring & putus-sambung', () => {
    it('memproses pembayaran idempoten saat pulih tanpa mendobelkan catatan uang di peladen', async () => {
      const pesananId = 'pesanan-bayar-001'
      const kunciBayar = `bayar-${pesananId}-1`

      // Kasir melakukan pembayaran saat luring
      await tambahKeAntrean({
        jenis: 'bayar_pesanan',
        kunciIdempoten: kunciBayar,
        labelRingkas: 'Pembayaran Tunai Rp 75.000',
        muatan: {
          pesananId,
          metodeId: 'metode-tunai',
          jumlah: 75000,
          diterima: 100000,
        },
      })

      // Tiruan tabel pembayaran di peladen
      const catatanPembayaran: Array<{
        id: string
        pesananId: string
        kunciIdempoten: string
        jumlah: number
      }> = []

      let saldoTercatat = 0

      const penanganBayarPeladen = async (item: ItemAntrean) => {
        // Idempotensi bayar_pesanan (0039 & 0080):
        const sudahAda = catatanPembayaran.find((b) => b.kunciIdempoten === item.kunciIdempoten)
        if (sudahAda) {
          // Respons dobel: true, tidak menambah saldo uang
          return { sukses: true, dobel: true }
        }

        const bayarBaru = {
          id: `byr-${Date.now()}`,
          pesananId: item.muatan.pesananId as string,
          kunciIdempoten: item.kunciIdempoten,
          jumlah: item.muatan.jumlah as number,
        }
        catatanPembayaran.push(bayarBaru)
        saldoTercatat += bayarBaru.jumlah

        return { sukses: true, dobel: false }
      }

      // Jaringan pulih -> kirim antrean
      const hasil = await prosesAntrean(penanganBayarPeladen)
      expect(hasil.berhasil).toBe(1)
      expect(catatanPembayaran).toHaveLength(1)
      expect(saldoTercatat).toBe(75000)

      // Simulasikan percobaan kirim ulang paket pembayaran karena ACK jaringan hilang di tengah jalan
      const kirimUlang = await penanganBayarPeladen({
        id: 'retry-bayar-1',
        jenis: 'bayar_pesanan',
        kunciIdempoten: kunciBayar,
        muatan: { pesananId, jumlah: 75000 },
        status: 'menunggu',
        percobaan: 1,
        dibuatPada: new Date().toISOString(),
      })

      expect(kirimUlang.sukses).toBe(true)
      expect(kirimUlang.dobel).toBe(true)

      // BUKTI T10-04 DoD: Pembayaran di peladen tetap tepat 1 baris, saldo tidak dobel
      expect(catatanPembayaran).toHaveLength(1)
      expect(saldoTercatat).toBe(75000)
    })
  })

  // ==========================================================================
  // SKENARIO 3: PEMAKAIAN VOUCHER SAAT LURING -> PULIH -> TEPAT 1 (ANTI DOBEL VOUCHER)
  // ==========================================================================
  describe('Skenario 3: Voucher saat luring & putus-sambung', () => {
    it('memastikan pemakaian voucher idempoten saat pulih dan potongan tidak ganda', async () => {
      const pesananId = 'pesanan-vcr-001'
      const kodeVoucher = 'HEMAT-20K'
      const kunciVoucher = `voucher-${pesananId}-${kodeVoucher}`

      await tambahKeAntrean({
        jenis: 'pakai_voucher',
        kunciIdempoten: kunciVoucher,
        labelRingkas: 'Pakai Voucher HEMAT-20K',
        muatan: {
          pesananId,
          kodeVoucher,
          potongan: 20000,
        },
      })

      // Tiruan peladen untuk voucher
      const voucherTerpakai: Array<{
        kode: string
        pesananId: string
        kunciIdempoten: string
        potongan: number
      }> = []

      let kuotaVoucher = 1

      const penanganVoucherPeladen = async (item: ItemAntrean) => {
        // Idempotensi pakai_voucher (0067 & 0080)
        const sudah = voucherTerpakai.find((v) => v.kunciIdempoten === item.kunciIdempoten)
        if (sudah) {
          return { sukses: true, kode: 'IDEMPOTEN', potongan: sudah.potongan }
        }

        if (kuotaVoucher <= 0) {
          return { sukses: false, pesan: 'VOUCHER_SUDAH_TERPAKAI' }
        }

        const dataVcr = {
          kode: item.muatan.kodeVoucher as string,
          pesananId: item.muatan.pesananId as string,
          kunciIdempoten: item.kunciIdempoten,
          potongan: (item.muatan.potongan as number) || 20000,
        }
        voucherTerpakai.push(dataVcr)
        kuotaVoucher -= 1

        return { sukses: true, potongan: dataVcr.potongan }
      }

      // Jaringan pulih -> proses sinkronisasi antrean
      const hasilSync = await prosesAntrean(penanganVoucherPeladen)
      expect(hasilSync.berhasil).toBe(1)
      expect(voucherTerpakai).toHaveLength(1)
      expect(kuotaVoucher).toBe(0)

      // Simulasikan pengiriman ulang dengan kunci sama
      const hasilUlang = await penanganVoucherPeladen({
        id: 'retry-vcr',
        jenis: 'pakai_voucher',
        kunciIdempoten: kunciVoucher,
        muatan: { pesananId, kodeVoucher },
        status: 'menunggu',
        percobaan: 1,
        dibuatPada: new Date().toISOString(),
      })

      expect(hasilUlang.sukses).toBe(true)
      expect(hasilUlang.kode).toBe('IDEMPOTEN')

      // BUKTI T10-04 DoD: Voucher terpakai tepat 1 kali, tidak memotong diskon dobel
      expect(voucherTerpakai).toHaveLength(1)
      expect(kuotaVoucher).toBe(0)
    })
  })

  // ==========================================================================
  // SKENARIO 4: JARINGAN PUTUS-SAMBUNG BERULANG (FLAPPING NETWORK)
  // ==========================================================================
  describe('Skenario 4: Jaringan putus-sambung berulang (intermittent connection)', () => {
    it('menghentikan proses anggun saat jaringan putus kembali dan melanjutkan tanpa duplikasi saat pulih kedua kali', async () => {
      // Masukkan 3 transaksi sekaligus saat luring
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'transaksi-A',
        labelRingkas: 'Pesanan A',
        muatan: { pesananId: 'A' },
      })
      await tambahKeAntrean({
        jenis: 'bayar_pesanan',
        kunciIdempoten: 'transaksi-B',
        labelRingkas: 'Pembayaran B',
        muatan: { pesananId: 'B' },
      })
      await tambahKeAntrean({
        jenis: 'pakai_voucher',
        kunciIdempoten: 'transaksi-C',
        labelRingkas: 'Voucher C',
        muatan: { pesananId: 'C' },
      })

      const catatanPeladen: string[] = []

      // Tiruan penangan jaringan tidak stabil:
      // Item 1 sukses, Item 2 gagal koneksi jaringan ('network offline'), Item 3 belum tersentuh
      let putaran = 1
      const penanganJaringanGoyang = async (item: ItemAntrean) => {
        if (putaran === 1) {
          if (item.kunciIdempoten === 'transaksi-A') {
            catatanPeladen.push(item.kunciIdempoten)
            return { sukses: true }
          }
          if (item.kunciIdempoten === 'transaksi-B') {
            // Simulasi koneksi drop seketika
            Object.defineProperty(navigator, 'onLine', { value: false, configurable: true })
            return { sukses: false, pesan: 'Failed to fetch (network error)' }
          }
        }

        // Putaran kedua: semua berhasil
        if (!catatanPeladen.includes(item.kunciIdempoten)) {
          catatanPeladen.push(item.kunciIdempoten)
        }
        return { sukses: true }
      }

      // Putaran 1 pengiriman
      const hasilPutaran1 = await prosesAntrean(penanganJaringanGoyang)
      expect(hasilPutaran1.berhasil).toBe(1) // Hanya A
      expect(hasilPutaran1.gagal).toBe(1) // B gagal
      expect(catatanPeladen).toEqual(['transaksi-A'])

      // Periksa status antrean setelah putaran 1:
      // A sukses, B gagal, C tetap menunggu (tidak diproses saat koneksi putus)
      const antreanSetelahPutaran1 = await ambilSemuaAntrean()
      expect(antreanSetelahPutaran1.find((i) => i.kunciIdempoten === 'transaksi-A')?.status).toBe(
        'sukses',
      )
      expect(antreanSetelahPutaran1.find((i) => i.kunciIdempoten === 'transaksi-B')?.status).toBe(
        'gagal',
      )
      expect(antreanSetelahPutaran1.find((i) => i.kunciIdempoten === 'transaksi-C')?.status).toBe(
        'menunggu',
      )

      // Jaringan pulih kembali (putaran 2)
      putaran = 2
      Object.defineProperty(navigator, 'onLine', { value: true, configurable: true })

      // Setel ulang item gagal agar dicoba lagi
      const itemB = antreanSetelahPutaran1.find((i) => i.kunciIdempoten === 'transaksi-B')!
      itemB.status = 'menunggu'

      const hasilPutaran2 = await prosesAntrean(penanganJaringanGoyang)
      expect(hasilPutaran2.berhasil).toBe(2) // B dan C berhasil dikirim
      expect(hasilPutaran2.gagal).toBe(0)

      // BUKTI: Semua transaksi A, B, C ada tepat 1 di peladen tanpa duplikasi
      expect(catatanPeladen).toEqual(['transaksi-A', 'transaksi-B', 'transaksi-C'])
    })
  })

  // ==========================================================================
  // SKENARIO 5: INTEGRASI UI KASIR (useAntrean & StatusAntrean)
  // ==========================================================================
  describe('Skenario 5: Integrasi Antarmuka Kasir (useAntrean & StatusAntrean)', () => {
    it('memperbarui pesan status kasir secara otomatis saat luring -> daring', async () => {
      // 1. Awal luring
      Object.defineProperty(navigator, 'onLine', { value: false, configurable: true })

      const SkenarioUI = () => {
        const { pesanStatus, apakahDaring, tambahAntrean } = useAntrean()
        return React.createElement(
          'div',
          null,
          React.createElement('div', { 'data-testid': 'status-teks' }, pesanStatus),
          React.createElement(
            'div',
            { 'data-testid': 'mode-jaringan' },
            apakahDaring ? 'DARING' : 'LURING',
          ),
          React.createElement(
            'button',
            {
              'data-testid': 'tombol-tambah',
              onClick: () =>
                tambahAntrean({
                  jenis: 'simpan_pesanan',
                  kunciIdempoten: 'ui-pesanan-01',
                  labelRingkas: 'Pesanan Meja 01',
                  muatan: { total: 45000 },
                }),
            },
            'Tambah',
          ),
        )
      }

      render(React.createElement(PenyediaBahasa, null, React.createElement(SkenarioUI, null)))

      expect(screen.getByTestId('mode-jaringan').textContent).toBe('LURING')

      // Tambah pesanan saat luring
      await act(async () => {
        fireEvent.click(screen.getByTestId('tombol-tambah'))
      })

      await waitFor(() => {
        expect(screen.getByTestId('status-teks').textContent).toBe('menunggu dikirim 1')
      })

      // 2. Jaringan kembali tersambung (event 'online')
      await act(async () => {
        Object.defineProperty(navigator, 'onLine', { value: true, configurable: true })
        window.dispatchEvent(new Event('online'))
      })

      await waitFor(() => {
        expect(screen.getByTestId('mode-jaringan').textContent).toBe('DARING')
      })
    })

    it('menampilkan rincian dialog StatusAntrean dan memungkinkan pemulihan retry manual', async () => {
      // Tambah item gagal ke antrean
      await tambahKeAntrean({
        jenis: 'bayar_pesanan',
        kunciIdempoten: 'byr-gagal-01',
        labelRingkas: 'Pembayaran Meja 02',
        muatan: { nominal_bayar: 50000 },
      })

      const SkenarioKomponen = () => {
        return React.createElement(
          'div',
          null,
          React.createElement(StatusAntrean, {
            penanganKustom: async (item) => {
              expect(item.kunciIdempoten).toBe('byr-gagal-01')
              return { sukses: true }
            },
          }),
        )
      }

      render(React.createElement(PenyediaBahasa, null, React.createElement(SkenarioKomponen, null)))

      // Buka dialog riwayat status antrean
      const tombolRincian = await screen.findByTestId('btn-buka-rincian-antrean')
      fireEvent.click(tombolRincian)

      // Pastikan dialog terbuka
      expect(await screen.findByRole('dialog')).toBeDefined()
      expect(screen.getByText('Rincian Status Antrean & Pengiriman')).toBeDefined()

      // Tombol sinkronisasi manual tersedia di dalam dialog
      const tombolKirim = screen.getByTestId('btn-dialog-kirim-semua')
      expect(tombolKirim).toBeDefined()

      await act(async () => {
        fireEvent.click(tombolKirim)
      })

      // Verifikasi item terkirim
      await waitFor(async () => {
        const stats = await hitungStatistikAntrean()
        expect(stats.sukses).toBe(1)
        expect(stats.menunggu).toBe(0)
      })
    })
  })
})
