// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LaporanPenjualan, type DataLaporanPenjualan } from './LaporanPenjualan'

afterEach(cleanup)

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
    total_omzet: 1250000,
    total_subtotal: 1200000,
    total_pajak: 100000,
    total_service: 50000,
    total_diskon: 100000,
    total_transaksi: 45,
    rata_rata_transaksi: 27778,
  },
  jenis_menu: {
    omzet_makanan: 850000,
    omzet_minuman: 300000,
    omzet_lainnya: 50000,
  },
  per_kategori: [
    {
      kategori_id: 'kat-01',
      kategori_nama: 'Makanan Berat',
      qty_terjual: 35,
      total_omzet: 850000,
      persentase: 70.8,
    },
    {
      kategori_id: 'kat-02',
      kategori_nama: 'Minuman Segar',
      qty_terjual: 25,
      total_omzet: 300000,
      persentase: 25.0,
    },
    {
      kategori_id: null,
      kategori_nama: 'Camilan',
      qty_terjual: 10,
      total_omzet: 50000,
      persentase: 4.2,
    },
  ],
  per_metode: [
    {
      metode_id: 'met-01',
      metode_nama: 'Tunai',
      jenis: 'tunai',
      jumlah_transaksi: 25,
      total_nominal: 700000,
      persentase: 56.0,
    },
    {
      metode_id: 'met-02',
      metode_nama: 'QRIS',
      jenis: 'qris',
      jumlah_transaksi: 20,
      total_nominal: 550000,
      persentase: 44.0,
    },
  ],
  tren_harian: [
    {
      tanggal: '2026-09-23',
      jumlah_transaksi: 20,
      omzet_makanan: 400000,
      omzet_minuman: 150000,
      omzet_lainnya: 20000,
      total_diskon: 40000,
      total_omzet: 570000,
    },
    {
      tanggal: '2026-09-24',
      jumlah_transaksi: 25,
      omzet_makanan: 450000,
      omzet_minuman: 150000,
      omzet_lainnya: 30000,
      total_diskon: 60000,
      total_omzet: 680000,
    },
  ],
}

describe('LaporanPenjualan', () => {
  it('merender indikator memuat saat sedangMemuat bernilai true', () => {
    render(<LaporanPenjualan sedangMemuat={true} />)
    expect(screen.getByText(/memuat/i)).toBeDefined()
  })

  it('merender keadaan gagal dengan tombol coba lagi saat ada pesanGagal', () => {
    const onMuatUlang = vi.fn()
    render(<LaporanPenjualan pesanGagal="Koneksi database terputus" onMuatUlang={onMuatUlang} />)
    expect(screen.getByText('Gagal memuat laporan penjualan')).toBeDefined()
    expect(screen.getByText('Koneksi database terputus')).toBeDefined()
    const tombolCoba = screen.getByRole('button', { name: /coba lagi/i })
    fireEvent.click(tombolCoba)
    expect(onMuatUlang).toHaveBeenCalled()
  })

  it('merender keadaan kosong saat data null', () => {
    render(<LaporanPenjualan data={null} />)
    expect(screen.getByText(/tidak ada data penjualan pada periode ini/i)).toBeDefined()
  })

  it('merender kartu KPI ringkasan penjualan, jenis menu, kategori, metode, dan tren harian', () => {
    render(<LaporanPenjualan data={DATA_PENJUALAN_MOCK} />)

    // Header & Cabang
    expect(screen.getByRole('heading', { level: 2, name: /penjualan/i })).toBeDefined()
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText(/2026-09-18 s\/d 2026-09-24/)).toBeDefined()

    // Total Omzet Rp1.250.000 & Subtotal Rp1.200.000
    expect(screen.getAllByText('Rp1.250.000').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText(/Subtotal: Rp1\.200\.000/)).toBeDefined()

    // Transaksi selesai & Rata-rata belanja
    expect(screen.getByText('45')).toBeDefined()
    expect(screen.getByText('Rp27.778')).toBeDefined()

    // Diskon & PB1/Service
    expect(screen.getAllByText(/Rp100\.000/).length).toBeGreaterThanOrEqual(1)

    // Breakdown Jenis Menu
    expect(screen.getAllByText(/Rp850\.000/).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText(/Rp300\.000/).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText(/Rp50\.000/).length).toBeGreaterThanOrEqual(1)

    // Tabel Omzet Kategori
    expect(screen.getByText('Makanan Berat')).toBeDefined()
    expect(screen.getByText('35')).toBeDefined()
    expect(screen.getByText('70.8%')).toBeDefined()
    expect(screen.getByText('Minuman Segar')).toBeDefined()
    expect(screen.getByText('25%')).toBeDefined()

    // Tabel Metode Bayar
    expect(screen.getByText(/Tunai/)).toBeDefined()
    expect(screen.getByText('Rp700.000')).toBeDefined()
    expect(screen.getByText('56%')).toBeDefined()
    expect(screen.getByText(/QRIS/)).toBeDefined()
    expect(screen.getByText('Rp550.000')).toBeDefined()
    expect(screen.getByText('44%')).toBeDefined()

    // Tabel Tren Harian
    expect(screen.getByText('Rp570.000')).toBeDefined()
    expect(screen.getByText('Rp680.000')).toBeDefined()
  })

  it('memungkinkan pemilik (owner_pusat) memilih cabang atau semua cabang', () => {
    const onPilihCabang = vi.fn()
    const daftarCabang = [
      { id: 'c-01', nama: 'Cabang Utama' },
      { id: 'c-02', nama: 'Cabang Dago' },
    ]

    render(
      <LaporanPenjualan
        data={DATA_PENJUALAN_MOCK}
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

  it('mengunci tampilan cabang bagi admin_cabang tanpa elemen dropdown', () => {
    const daftarCabang = [{ id: 'c-01', nama: 'Cabang Utama' }]
    render(
      <LaporanPenjualan
        data={DATA_PENJUALAN_MOCK}
        daftarCabang={daftarCabang}
        cabangAktifId="c-01"
        peranPengguna="admin_cabang"
      />,
    )

    expect(screen.queryByLabelText(/cabang/i)).toBeNull()
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)
  })

  it('menolak rentang tanggal jika tanggal akhir lebih awal dari tanggal mulai', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanPenjualan
        data={DATA_PENJUALAN_MOCK}
        tanggalMulai="2026-09-20"
        tanggalAkhir="2026-09-24"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/s\/d/i) as HTMLInputElement

    fireEvent.change(inputMulai, { target: { value: '2026-09-25' } })
    fireEvent.change(inputAkhir, { target: { value: '2026-09-20' } })

    const tombolTerapkan = screen.getByRole('button', { name: /terapkan/i })
    fireEvent.click(tombolTerapkan)

    expect(onPilihRentangTanggal).not.toHaveBeenCalled()
    expect(
      screen.getByText(/tanggal akhir tidak boleh lebih awal dari tanggal mulai/i),
    ).toBeDefined()
  })

  it('menolak rentang tanggal jika melebihi 90 hari untuk mitigasi beban kueri berat', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanPenjualan
        data={DATA_PENJUALAN_MOCK}
        tanggalMulai="2026-01-01"
        tanggalAkhir="2026-01-07"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/s\/d/i) as HTMLInputElement

    fireEvent.change(inputMulai, { target: { value: '2026-01-01' } })
    fireEvent.change(inputAkhir, { target: { value: '2026-06-01' } }) // 151 hari

    const tombolTerapkan = screen.getByRole('button', { name: /terapkan/i })
    fireEvent.click(tombolTerapkan)

    expect(onPilihRentangTanggal).not.toHaveBeenCalled()
    expect(screen.getByText(/rentang tanggal maksimal 90 hari/i)).toBeDefined()
  })

  it('meneruskan rentang tanggal yang valid ke callback onPilihRentangTanggal', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanPenjualan
        data={DATA_PENJUALAN_MOCK}
        tanggalMulai="2026-09-18"
        tanggalAkhir="2026-09-24"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/s\/d/i) as HTMLInputElement

    fireEvent.change(inputMulai, { target: { value: '2026-09-10' } })
    fireEvent.change(inputAkhir, { target: { value: '2026-09-20' } })

    const tombolTerapkan = screen.getByRole('button', { name: /terapkan/i })
    fireEvent.click(tombolTerapkan)

    expect(onPilihRentangTanggal).toHaveBeenCalledWith('2026-09-10', '2026-09-20')
  })
})
