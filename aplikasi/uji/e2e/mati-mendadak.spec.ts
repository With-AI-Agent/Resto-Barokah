// @vitest-environment jsdom
/**
 * mati-mendadak.spec.ts — Uji Pemulihan Gangguan Listrik & Perangkat Mati Mendadak (T10-09).
 *
 * Menguji ketahanan aplikasi Resto Barokah saat perangkat kasir atau dapur mati mendadak:
 * 1. Draf keranjang kasir yang belum terkirim otomatis tersimpan lokal dan dipulihkan.
 * 2. Kasir dapat melanjutkan pesanan atau mengosongkan draf.
 * 3. Tagihan terbuka (open bill) tidak hilang saat perangkat mati.
 * 4. Shift kas yang masih aktif dikenali dan dilanjutkan, tidak dipaksa buka shift baru.
 * 5. Cadangan antrean KDS dapur tetap menampilkan tiket terakhir saat mati listrik.
 * 6. Aturan rekonsiliasi server-wins: data peladen selalu menang saat tersinkron ulang.
 *
 * Ref: PRD §9 risiko, TECH_SPEC §9 ART-8 & §10, ROADMAP T10-09.
 */
import React from 'react'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { PenyediaBahasa } from '../../src/bahasa'
import { LayarKasir } from '../../src/layar/kasir/LayarKasir'
import {
  simpanDrafKasir,
  muatDrafKasir,
  simpanTagihanTerbukaLokal,
  muatTagihanTerbukaLokal,
  simpanAntreanTerakhir,
  muatAntreanTerakhir,
  rekonsiliasiEntitas,
  rekonsiliasiDaftarPesanan,
} from '../../src/lib/antrean-lokal'
import { apakahShiftMasihBerjalan } from '../../src/lib/pemulihan-sesi'

describe('T10-09: Uji Pemulihan Mati Mendadak (Kasir & Dapur)', () => {
  const CABANG_ID = 'cab-oasis-01'

  beforeEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  afterEach(() => {
    cleanup()
    localStorage.clear()
  })

  // ==========================================================================
  // SKENARIO 1: KERANJANG KASIR TERSIMPAN & DIPULIHKAN SETELAH MATI LISTRIK
  // ==========================================================================
  describe('Skenario 1: Pemulihan Draf Keranjang Kasir', () => {
    it('memulihkan keranjang kasir yang belum dibayar saat aplikasi dibuka kembali', async () => {
      // 1. Kasir sedang menyusun pesanan sebelum listrik padam
      const drafSebelumPadam = {
        daftarItemKeranjang: [
          {
            id: 'item-101',
            menuItem: {
              id: 'menu-bebek',
              nama: 'Bebek Goreng Madu',
              harga: 35000,
              kategoriId: 'kat-utama',
              aktif: true,
            },
            qty: 2,
            subtotal: 70000,
          },
          {
            id: 'item-102',
            menuItem: {
              id: 'menu-esteh',
              nama: 'Es Teh Manis Melati',
              harga: 6000,
              kategoriId: 'kat-minum',
              aktif: true,
            },
            qty: 2,
            subtotal: 12000,
          },
        ],
        tipePesanan: 'dinein',
        mejaAktif: { id: 'meja-07', nama: 'Meja 07 (Gazebo)', status: 'terisi', aktif: true },
        diskonAktif: 0,
        catatanPesananUmum: 'Sambal dipisah',
      }

      // Simulasikan draf tersimpan di localStorage sebelum browser mati
      simpanDrafKasir(CABANG_ID, drafSebelumPadam)

      // 2. Listrik menyala kembali, kasir membuka aplikasi
      render(
        React.createElement(
          PenyediaBahasa,
          null,
          React.createElement(LayarKasir, {
            cabangId: CABANG_ID,
            namaCabang: 'Kedai Oasis',
            shiftAktif: {
              id: 'shift-oasis-01',
              cabangId: CABANG_ID,
              modalAwal: 200000,
              dibukaPada: new Date().toISOString(),
            },
          }),
        ),
      )

      // 3. Verifikasi banner pemulihan tampil jujur
      await waitFor(() => {
        expect(screen.getByTestId('banner-pemulihan-draf')).toBeDefined()
      })
      expect(
        screen.getByText(/Draf transaksi sebelum perangkat terhenti dimuat kembali/i),
      ).toBeDefined()

      // 4. Verifikasi seluruh item dan catatan kembali utuh di layar kasir
      expect(screen.getByText('Bebek Goreng Madu')).toBeDefined()
      expect(screen.getAllByText('Es Teh Manis Melati').length).toBeGreaterThanOrEqual(1)
    })

    it('memungkinkan kasir mengosongkan draf dan memulai pesanan baru', async () => {
      simpanDrafKasir(CABANG_ID, {
        daftarItemKeranjang: [
          {
            id: 'item-batal',
            menuItem: {
              id: 'menu-soto',
              nama: 'Soto Betawi Barokah',
              harga: 30000,
              kategoriId: 'kat-utama',
              aktif: true,
            },
            qty: 1,
            subtotal: 30000,
          },
        ],
        tipePesanan: 'dinein',
      })

      render(
        React.createElement(
          PenyediaBahasa,
          null,
          React.createElement(LayarKasir, { cabangId: CABANG_ID }),
        ),
      )

      await waitFor(() => {
        expect(screen.getByTestId('banner-pemulihan-draf')).toBeDefined()
      })

      // Kasir menekan "Buang Draf"
      const btnBuang = screen.getByTestId('btn-buang-draf-pulih')
      fireEvent.click(btnBuang)

      // Keranjang kembali bersih dan draf dihapus dari storage
      await waitFor(() => {
        expect(screen.queryByTestId('banner-pemulihan-draf')).toBeNull()
      })
      expect(screen.getByText(/Keranjang Masih Kosong/i)).toBeDefined()
      expect(muatDrafKasir(CABANG_ID)).toBeNull()
    })
  })

  // ==========================================================================
  // SKENARIO 2: KELANJUTAN SHIFT AKTIF (TIDAK MEMBUAT SHIFT DOBEL)
  // ==========================================================================
  describe('Skenario 2: Kelanjutan Shift Kasir Aktif', () => {
    it('mengenali shift yang sedang berjalan dan tidak memaksa buka shift baru', () => {
      const waktuSekarang = new Date('2026-09-27T16:00:00Z')
      const shiftAktif = {
        id: 'shift-aktif-01',
        cabangId: CABANG_ID,
        modalAwal: 150000,
        dibukaPada: '2026-09-27T08:00:00Z',
      }

      // Verifikasi helper mengenali shift masih berjalan di hari yang sama
      expect(apakahShiftMasihBerjalan(shiftAktif, '22:00', waktuSekarang)).toBe(true)

      // Render layar kasir dengan shift aktif
      render(
        React.createElement(
          PenyediaBahasa,
          null,
          React.createElement(LayarKasir, {
            cabangId: CABANG_ID,
            wajibShift: true,
            shiftAktif,
          }),
        ),
      )

      // Banner peringatan "belum buka kas" TIDAK boleh muncul karena shift lama dilanjutkan
      expect(screen.queryByTestId('banner-wajib-shift')).toBeNull()
      expect(screen.getByText(/Shift Aktif/i)).toBeDefined()
    })
  })

  // ==========================================================================
  // SKENARIO 3: TAGIHAN TERBUKA (OPEN BILL) TIDAK HILANG
  // ==========================================================================
  describe('Skenario 3: Tagihan Terbuka Lokal', () => {
    it('mempertahankan daftar tagihan terbuka di penyimpanan lokal', () => {
      const tagihanAktif = [
        {
          id: 'ord-meja-2',
          nomor: 201,
          tanggal: '2026-09-27',
          tipe: 'dinein' as const,
          namaMeja: 'Meja 02',
          status: 'dimasak' as const,
          jumlahItem: 3,
          ringkasanItem: '2x Ayam Bakar, 1x Es Teh',
          total: 70000,
          dibuatPada: '14:15',
        },
      ]

      // Simpan cadangan lokal tagihan terbuka
      simpanTagihanTerbukaLokal(CABANG_ID, tagihanAktif)

      // Perangkat mati mendadak lalu dimuat kembali
      const pulih = muatTagihanTerbukaLokal(CABANG_ID)
      expect(pulih).toEqual(tagihanAktif)
    })
  })

  // ==========================================================================
  // SKENARIO 4: CADANGAN ANTREAN DAPUR / BAR TETAP HIDUP
  // ==========================================================================
  describe('Skenario 4: Cadangan Antrean KDS Dapur', () => {
    it('menjaga tiket antrean dapur di penyimpanan lokal saat mati listrik', () => {
      const tiketDapur = [
        {
          id: 'pesanan-01',
          nomor: 105,
          namaMeja: 'Meja 03',
          waktu: '14:20',
          item: [{ id: 'it-1', nama: 'Nasi Goreng Spesial', qty: 2 }],
        },
      ]

      simpanAntreanTerakhir('dapur', tiketDapur)

      // KDS Dapur dimuat ulang setelah listrik pulih
      const tiketPulih = muatAntreanTerakhir<{ id: string; nomor: number }>('dapur')
      expect(tiketPulih).toEqual(tiketDapur)
      expect(tiketPulih?.[0].nomor).toBe(105)
    })
  })

  // ==========================================================================
  // SKENARIO 5: REKONSILIASI SERVER-WINS (SERVER SELALU MENANG)
  // ==========================================================================
  describe('Skenario 5: Rekonsiliasi Server-Wins', () => {
    it('memprioritaskan data peladen ketika ada perbedaan dengan data lokal', () => {
      const dataLokal = {
        id: 'ord-301',
        status: 'dikirim',
        diperbaruiPada: '2026-09-27T14:00:00Z',
      }
      const dataServer = {
        id: 'ord-301',
        status: 'dimasak', // Sudah diperbarui oleh dapur di peladen
        diperbaruiPada: '2026-09-27T14:05:00Z',
      }

      const hasil = rekonsiliasiEntitas(dataLokal, dataServer)

      // Server-Wins: data terpilih wajib data server
      expect(hasil?.dataTerpilih.status).toBe('dimasak')
      expect(hasil?.sumber).toBe('server')
      expect(hasil?.adaKonflik).toBe(true)
    })

    it('menggabungkan pesanan peladen dengan draf lokal baru tanpa kehilangan draf', () => {
      const pesananLokal = [
        { id: 'server-ord-1', status: 'dikirim' },
        { id: 'lokal-draf-baru', status: 'draf' }, // Baru dibuat offline
      ]
      const pesananServer = [
        { id: 'server-ord-1', status: 'siap' },
        { id: 'server-ord-2', status: 'lunas' },
      ]

      const { hasil, konflik, jumlahDipulihkanDariLokal } = rekonsiliasiDaftarPesanan(
        pesananLokal,
        pesananServer,
      )

      // Seluruh pesanan peladen ada di hasil
      expect(hasil.some((p) => p.id === 'server-ord-1' && p.status === 'siap')).toBe(true)
      expect(hasil.some((p) => p.id === 'server-ord-2' && p.status === 'lunas')).toBe(true)

      // Draf lokal baru tidak hilang
      expect(hasil.some((p) => p.id === 'lokal-draf-baru')).toBe(true)
      expect(jumlahDipulihkanDariLokal).toBe(1)
      expect(konflik.length).toBe(1)
    })
  })
})
