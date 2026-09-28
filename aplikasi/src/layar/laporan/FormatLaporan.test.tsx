// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { FormatLaporan } from './FormatLaporan'
import type { DataLaporanPenjualan } from './LaporanPenjualan'
import type { DataLaporanHarian } from './LaporanKas'
import type { DataLaporanMenu } from './LaporanMenu'

afterEach(cleanup)

const DATA_PENJUALAN_MOCK: DataLaporanPenjualan = {
  rentang: {
    tanggal_mulai: '2026-09-18',
    tanggal_akhir: '2026-09-24',
    jumlah_hari: 7,
  },
  cabang: {
    id: 'c-01',
    nama: 'Cabang Utama Oasis',
  },
  ringkasan: {
    total_omzet: 2500000,
    total_subtotal: 2400000,
    total_pajak: 200000,
    total_service: 100000,
    total_diskon: 200000,
    total_transaksi: 50,
    rata_rata_transaksi: 50000,
  },
  jenis_menu: {
    omzet_makanan: 1800000,
    omzet_minuman: 600000,
    omzet_lainnya: 100000,
  },
  per_kategori: [
    {
      kategori_id: 'kat-01',
      kategori_nama: 'Makanan Utama',
      qty_terjual: 45,
      total_omzet: 1800000,
      persentase: 72.0,
    },
  ],
  per_metode: [
    {
      metode_id: 'met-01',
      metode_nama: 'Tunai',
      jenis: 'tunai',
      jumlah_transaksi: 30,
      total_nominal: 1500000,
      persentase: 60.0,
    },
    {
      metode_id: 'met-02',
      metode_nama: 'QRIS',
      jenis: 'qris',
      jumlah_transaksi: 20,
      total_nominal: 1000000,
      persentase: 40.0,
    },
  ],
  tren_harian: [],
}

const DATA_HARIAN_MOCK: DataLaporanHarian = {
  tanggal: '2026-09-24',
  cabang_id: 'c-01',
  nama_cabang: 'Cabang Utama Oasis',
  jumlah_shift: 1,
  penjualan: {
    jumlah_transaksi: 50,
    omzet_total: 2500000,
    omzet_makanan: 1800000,
    omzet_minuman: 600000,
    omzet_lainnya: 100000,
    total_diskon: 200000,
  },
  kas: {
    total_modal_awal: 200000,
    kas_masuk: 50000,
    kas_keluar: 20000,
    setoran: 1500000,
    penjualan_tunai: 1500000,
    penjualan_non_tunai: 1000000,
    total_penjualan: 2500000,
    total_uang_seharusnya: 1730000,
    total_uang_fisik: 1730000,
    total_selisih: 0,
  },
  metode_bayar: [
    { metode_nama: 'Tunai', jumlah_transaksi: 30, total_nominal: 1500000 },
    { metode_nama: 'QRIS', jumlah_transaksi: 20, total_nominal: 1000000 },
  ],
  shifts: [],
  pembatalan: {
    jumlah: 2,
    total_nilai_rugi: 45000,
    daftar: [],
  },
}

const DATA_MENU_MOCK: DataLaporanMenu = {
  rentang: {
    tanggal_mulai: '2026-09-18',
    tanggal_akhir: '2026-09-24',
    jumlah_hari: 7,
  },
  cabang: {
    id: 'c-01',
    nama: 'Cabang Utama Oasis',
  },
  ringkasan: {
    total_porsi: 85,
    total_omzet_menu: 2400000,
    total_diskon_manual: 120000,
    total_voucher: 80000,
    total_biaya_promosi: 200000,
  },
  peringkat_menu: [
    {
      menu_item_id: 'm-01',
      nama_menu: 'Nasi Kebuli Spesial',
      kategori_nama: 'Makanan Utama',
      jenis: 'makanan',
      qty_terjual: 50,
      total_omzet: 1500000,
      rata_harga: 30000,
      persentase: 62.5,
    },
    {
      menu_item_id: 'm-02',
      nama_menu: 'Jus Alpukat',
      kategori_nama: 'Minuman',
      jenis: 'minuman',
      qty_terjual: 35,
      total_omzet: 900000,
      rata_harga: 25714,
      persentase: 37.5,
    },
  ],
  diskon_manual: [
    {
      id: 'dm-1',
      pesanan_id: 'p-1',
      nomor_pesanan: 10,
      tanggal: '2026-09-24',
      waktu: '2026-09-24T12:00:00Z',
      persen: 5,
      nominal: 120000,
      nilai: 120000,
      alasan: 'Diskon pembukaan',
      pelaku_id: 'u-1',
      kasir_nama: 'Kasir Ahmad',
      penyetuju_id: 'u-spv',
      penyetuju_nama: 'SPV Budi',
    },
  ],
  voucher_terpakai: [
    {
      id: 'vc-1',
      pesanan_id: 'p-2',
      nomor_pesanan: 11,
      tanggal: '2026-09-24',
      waktu: '2026-09-24T12:30:00Z',
      kode_voucher: 'HEMAT10RB',
      nilai: 80000,
      pelaku_id: 'u-1',
      kasir_nama: 'Kasir Ahmad',
      penyetuju_id: null,
      penyetuju_nama: null,
    },
  ],
}

describe('FormatLaporan', () => {
  it('merender kop surat resto dan judul laporan dengan rapi', () => {
    render(
      <FormatLaporan
        dataPenjualan={DATA_PENJUALAN_MOCK}
        dataHarian={DATA_HARIAN_MOCK}
        tanggal="2026-09-24"
      />,
    )

    expect(screen.getByRole('heading', { level: 1, name: 'RESTO BAROKAH' })).toBeDefined()
    expect(screen.getByText(/Cabang Utama Oasis/)).toBeDefined()
    expect(screen.getAllByText(/24 Sep 2026/).length).toBeGreaterThanOrEqual(1)
  })

  it('merender ringkasan keuangan, penerimaan kas, dan omzet bersih', () => {
    render(
      <FormatLaporan
        dataPenjualan={DATA_PENJUALAN_MOCK}
        dataHarian={DATA_HARIAN_MOCK}
        dataMenu={DATA_MENU_MOCK}
      />,
    )

    // Subtotal & Omzet
    expect(screen.getByText('Rp2.400.000')).toBeDefined()
    expect(screen.getByText('Rp2.500.000')).toBeDefined()
    expect(screen.getByText('50 Transaksi')).toBeDefined()

    // Pajak & Service
    expect(screen.getByText('+ Rp200.000')).toBeDefined()
    expect(screen.getByText('+ Rp100.000')).toBeDefined()
  })

  it('merender rincian metode pembayaran (Tunai & QRIS)', () => {
    render(<FormatLaporan dataPenjualan={DATA_PENJUALAN_MOCK} />)

    expect(screen.getByText('Tunai')).toBeDefined()
    expect(screen.getByText('Rp1.500.000')).toBeDefined()
    expect(screen.getByText('QRIS')).toBeDefined()
    expect(screen.getByText('Rp1.000.000')).toBeDefined()
  })

  it('merender tabel rekonsiliasi kas shift dan setoran brankas', () => {
    render(<FormatLaporan dataHarian={DATA_HARIAN_MOCK} />)

    expect(screen.getByText(/Rekonsiliasi Kas Shift & Brankas/)).toBeDefined()
    expect(screen.getByText('Rp200.000')).toBeDefined() // modal awal
    expect(screen.getByText('Rp50.000')).toBeDefined() // kas masuk
    expect(screen.getByText('Rp20.000')).toBeDefined() // kas keluar
    expect(screen.getAllByText('Rp1.500.000').length).toBeGreaterThanOrEqual(1) // setoran brankas / tunai
    expect(screen.getAllByText('Rp1.730.000').length).toBeGreaterThanOrEqual(1) // uang fisik & seharusnya
    expect(screen.getByText('Rp0 (Tepat)')).toBeDefined() // selisih tepat
  })

  it('merender menu andalan / top 5 menu', () => {
    render(<FormatLaporan dataMenu={DATA_MENU_MOCK} />)

    expect(screen.getByText('Nasi Kebuli Spesial')).toBeDefined()
    expect(screen.getByText('50')).toBeDefined()
    expect(screen.getByText('Jus Alpukat')).toBeDefined()
    expect(screen.getByText('35')).toBeDefined()
  })

  it('merender rincian biaya promosi dan pembatalan pesanan', () => {
    render(<FormatLaporan dataHarian={DATA_HARIAN_MOCK} dataMenu={DATA_MENU_MOCK} />)

    expect(screen.getAllByText('Rp200.000').length).toBeGreaterThanOrEqual(1) // biaya promosi
    expect(screen.getByText(/Diskon Manual \(1 Transaksi\)/)).toBeDefined()
    expect(screen.getByText(/Voucher Terpakai \(1 Voucher\)/)).toBeDefined()
    expect(screen.getByText(/Rugi: Rp45\.000/)).toBeDefined()
  })

  it('merender kolom pengesahan tanda tangan kasir dan pemilik', () => {
    render(<FormatLaporan namaPetugas="Siti Kasir" namaPemilik="Lee (Owner)" />)

    expect(screen.getByText('( Siti Kasir )')).toBeDefined()
    expect(screen.getByText('( Lee (Owner) )')).toBeDefined()
    expect(screen.getByText(/Kasir \/ Penanggung Jawab/)).toBeDefined()
    expect(screen.getByText(/Pemilik \/ Pengelola Resto/)).toBeDefined()
  })

  it('mengunci tampilan cabang bagi admin_cabang tanpa dropdown untuk mencegah kebocoran data', () => {
    const daftarCabang = [
      { id: 'c-01', nama: 'Cabang Oasis Dago' },
      { id: 'c-02', nama: 'Cabang Oasis Riau' },
    ]

    render(
      <FormatLaporan
        daftarCabang={daftarCabang}
        cabangAktifId="c-01"
        peranPengguna="admin_cabang"
      />,
    )

    expect(screen.queryByLabelText(/cabang/i)).toBeNull()
    expect(screen.getAllByText('Cabang Oasis Dago').length).toBeGreaterThanOrEqual(1)
  })

  it('memungkinkan owner_pusat mengganti cabang dan memanggil onPilihCabang', () => {
    const onPilihCabang = vi.fn()
    const daftarCabang = [
      { id: 'c-01', nama: 'Cabang Oasis Dago' },
      { id: 'c-02', nama: 'Cabang Oasis Riau' },
    ]

    render(
      <FormatLaporan
        daftarCabang={daftarCabang}
        cabangAktifId="c-01"
        peranPengguna="owner_pusat"
        onPilihCabang={onPilihCabang}
      />,
    )

    const select = screen.getByLabelText(/cabang/i) as HTMLSelectElement
    expect(select).toBeDefined()
    fireEvent.change(select, { target: { value: 'c-02' } })
    expect(onPilihCabang).toHaveBeenCalledWith('c-02')
  })

  it('memanggil onCetak atau window.print saat tombol cetak diklik', () => {
    const onCetak = vi.fn()
    render(<FormatLaporan onCetak={onCetak} />)

    const tombolCetak = screen.getByRole('button', { name: /cetak/i })
    fireEvent.click(tombolCetak)
    expect(onCetak).toHaveBeenCalledTimes(1)
  })

  it('memanggil onTutup saat tombol kembali diklik', () => {
    const onTutup = vi.fn()
    render(<FormatLaporan onTutup={onTutup} />)

    const tombolKembali = screen.getByRole('button', { name: /kembali ke laporan/i })
    fireEvent.click(tombolKembali)
    expect(onTutup).toHaveBeenCalledTimes(1)
  })
})
