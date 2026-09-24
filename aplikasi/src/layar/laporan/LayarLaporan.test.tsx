// @vitest-environment jsdom
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LayarLaporan } from './LayarLaporan'
import type { DataLaporanHarian } from './LaporanKas'

afterEach(cleanup)

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
  it('menampilkan tab Kas Harian secara bawaan', () => {
    render(<LayarLaporan dataHarian={DATA_HARIAN_MOCK} />)
    expect(screen.getByText(/laporan penjualan & kas/i)).toBeDefined()
    expect(screen.getAllByText('Rp200.000').length).toBeGreaterThanOrEqual(1)
  })

  it('dapat berpindah ke tab Pembatalan dan menampilkan rincian pembatalan', () => {
    render(<LayarLaporan dataHarian={DATA_HARIAN_MOCK} />)

    const tombolTabBatal = screen.getByRole('button', { name: /pembatalan/i })
    fireEvent.click(tombolTabBatal)

    // Menampilkan daftar pembatalan
    expect(screen.getByText('Bebek Bakar')).toBeDefined()
    expect(screen.getByText(/pelanggan membatalkan setelah dimasak/i)).toBeDefined()
    expect(screen.getByText('Rp25.000')).toBeDefined()
  })
})
