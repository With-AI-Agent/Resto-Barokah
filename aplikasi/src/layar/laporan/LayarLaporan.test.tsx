// @vitest-environment jsdom
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LayarLaporan } from './LayarLaporan'
import type { DataLaporanHarian } from './LaporanKas'
import type { DataLaporanPenjualan } from './LaporanPenjualan'
import type { DataLaporanMenu } from './LaporanMenu'

afterEach(cleanup)

const DATA_MENU_MOCK: DataLaporanMenu = {
  rentang: {
    tanggal_mulai: '2026-09-18',
    tanggal_akhir: '2026-09-24',
    jumlah_hari: 7,
  },
  cabang: {
    id: 'c-01',
    nama: 'Cabang Utama',
  },
  ringkasan: {
    total_porsi: 50,
    total_omzet_menu: 1500000,
    total_diskon_manual: 50000,
    total_voucher: 25000,
    total_biaya_promosi: 75000,
  },
  peringkat_menu: [
    {
      menu_item_id: 'm-01',
      nama_menu: 'Ayam Goreng Sambal Bawang',
      kategori_nama: 'Makanan Utama',
      jenis: 'makanan',
      qty_terjual: 50,
      total_omzet: 1500000,
      rata_harga: 30000,
      persentase: 100,
    },
  ],
  diskon_manual: [],
  voucher_terpakai: [],
}

const DATA_PENJUALAN_MOCK: DataLaporanPenjualan = {
  rentang: {
    tanggal_mulai: '2026-09-18',
    tanggal_akhir: '2026-09-24',
    jumlah_hari: 7,
  },
  cabang: {
    id: 'c-01',
    nama: 'Cabang Utama',
  },
  ringkasan: {
    total_omzet: 500000,
    total_subtotal: 480000,
    total_pajak: 40000,
    total_service: 20000,
    total_diskon: 40000,
    total_transaksi: 15,
    rata_rata_transaksi: 33333,
  },
  jenis_menu: {
    omzet_makanan: 350000,
    omzet_minuman: 130000,
    omzet_lainnya: 0,
  },
  per_kategori: [
    {
      kategori_id: 'kat-01',
      kategori_nama: 'Makanan Utama',
      qty_terjual: 20,
      total_omzet: 350000,
      persentase: 72.9,
    },
  ],
  per_metode: [
    {
      metode_id: 'met-01',
      metode_nama: 'QRIS',
      jenis: 'qris',
      jumlah_transaksi: 15,
      total_nominal: 500000,
      persentase: 100,
    },
  ],
  tren_harian: [
    {
      tanggal: '2026-09-24',
      jumlah_transaksi: 15,
      omzet_makanan: 350000,
      omzet_minuman: 130000,
      omzet_lainnya: 0,
      total_diskon: 40000,
      total_omzet: 500000,
    },
  ],
}

const DATA_HARIAN_MOCK: DataLaporanHarian = {
  tanggal: '2026-09-24',
  cabang_id: 'c-01',
  nama_cabang: 'Cabang Utama',
  jumlah_shift: 1,
  penjualan: {
    jumlah_transaksi: 5,
    omzet_total: 200000,
    omzet_makanan: 150000,
    omzet_minuman: 50000,
    omzet_lainnya: 0,
    total_diskon: 0,
  },
  kas: {
    total_modal_awal: 100000,
    kas_masuk: 0,
    kas_keluar: 0,
    setoran: 0,
    penjualan_tunai: 200000,
    penjualan_non_tunai: 0,
    total_penjualan: 200000,
    total_uang_seharusnya: 300000,
    total_uang_fisik: 300000,
    total_selisih: 0,
  },
  metode_bayar: [{ metode_nama: 'Tunai', jumlah_transaksi: 5, total_nominal: 200000 }],
  shifts: [],
  pembatalan: {
    jumlah: 1,
    total_nilai_rugi: 25000,
    daftar: [
      {
        id: 'pb-01',
        nomor_pesanan: 202,
        item_nama: 'Bebek Bakar',
        waktu: '2026-09-24T13:00:00.000Z',
        tahap: 'sesudah_dapur',
        alasan: 'Pelanggan membatalkan setelah dimasak',
        nilai_kerugian: 25000,
        bahan_terbuang: true,
      },
    ],
  },
}

describe('LayarLaporan', () => {
  it('menampilkan tab Penjualan secara bawaan', () => {
    render(<LayarLaporan dataPenjualan={DATA_PENJUALAN_MOCK} />)
    expect(screen.getByRole('heading', { level: 2, name: /penjualan/i })).toBeDefined()
    expect(screen.getAllByText('Rp500.000').length).toBeGreaterThanOrEqual(1)
  })

  it('dapat berpindah ke tab Kas dan menampilkan laporan kas harian', () => {
    render(<LayarLaporan dataPenjualan={DATA_PENJUALAN_MOCK} dataHarian={DATA_HARIAN_MOCK} />)

    const tombolTabKas = screen.getByRole('button', { name: /kas & shift/i })
    fireEvent.click(tombolTabKas)

    expect(screen.getByText(/laporan penjualan & kas/i)).toBeDefined()
    expect(screen.getAllByText('Rp200.000').length).toBeGreaterThanOrEqual(1)
  })

  it('dapat berpindah ke tab Pembatalan dan menampilkan rincian pembatalan', () => {
    render(<LayarLaporan dataPenjualan={DATA_PENJUALAN_MOCK} dataHarian={DATA_HARIAN_MOCK} />)

    const tombolTabBatal = screen.getByRole('button', { name: /pembatalan/i })
    fireEvent.click(tombolTabBatal)

    // Menampilkan daftar pembatalan
    expect(screen.getByText('Bebek Bakar')).toBeDefined()
    expect(screen.getByText(/pelanggan membatalkan setelah dimasak/i)).toBeDefined()
    expect(screen.getByText('Rp25.000')).toBeDefined()
  })

  it('dapat berpindah ke tab Menu & Promo dan menampilkan peringkat menu terlaris', () => {
    render(<LayarLaporan dataPenjualan={DATA_PENJUALAN_MOCK} dataMenu={DATA_MENU_MOCK} />)

    const tombolTabMenu = screen.getByRole('button', { name: /menu & promo/i })
    fireEvent.click(tombolTabMenu)

    expect(screen.getByText('Ayam Goreng Sambal Bawang')).toBeDefined()
    expect(screen.getByText('50 Porsi')).toBeDefined()
    expect(screen.getAllByText('Rp1.500.000').length).toBeGreaterThanOrEqual(1)
  })
})
