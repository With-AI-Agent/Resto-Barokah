// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LaporanMenu, type DataLaporanMenu } from './LaporanMenu'

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
    total_porsi: 120,
    total_omzet_menu: 3600000,
    total_diskon_manual: 150000,
    total_voucher: 100000,
    total_biaya_promosi: 250000,
  },
  peringkat_menu: [
    {
      menu_item_id: 'm-01',
      nama_menu: 'Nasi Goreng Spesial Barokah',
      kategori_nama: 'Makanan Berat',
      jenis: 'makanan',
      qty_terjual: 80,
      total_omzet: 2400000,
      rata_harga: 30000,
      persentase: 66.7,
    },
    {
      menu_item_id: 'm-02',
      nama_menu: 'Es Teh Manis',
      kategori_nama: 'Minuman Segar',
      jenis: 'minuman',
      qty_terjual: 40,
      total_omzet: 1200000,
      rata_harga: 30000,
      persentase: 33.3,
    },
  ],
  diskon_manual: [
    {
      id: 'dm-01',
      pesanan_id: 'p-01',
      nomor_pesanan: 101,
      tanggal: '2026-09-24',
      waktu: '2026-09-24T12:30:00+07:00',
      persen: 5,
      nominal: 150000,
      nilai: 150000,
      alasan: 'Promo pembukaan toko',
      pelaku_id: 'usr-01',
      kasir_nama: 'Rina Kasir',
      penyetuju_id: 'usr-spv',
      penyetuju_nama: 'Pak Budi SPV',
    },
  ],
  voucher_terpakai: [
    {
      id: 'vc-01',
      pesanan_id: 'p-02',
      nomor_pesanan: 102,
      tanggal: '2026-09-24',
      waktu: '2026-09-24T13:00:00+07:00',
      kode_voucher: 'HEMAT10RB',
      nilai: 100000,
      pelaku_id: 'usr-01',
      kasir_nama: 'Rina Kasir',
      penyetuju_id: null,
      penyetuju_nama: null,
    },
  ],
}

describe('LaporanMenu', () => {
  it('merender indikator memuat saat sedangMemuat bernilai true', () => {
    render(<LaporanMenu sedangMemuat={true} />)
    expect(screen.getByText(/memuat/i)).toBeDefined()
  })

  it('merender keadaan gagal dengan tombol coba lagi saat ada pesanGagal', () => {
    const onMuatUlang = vi.fn()
    render(<LaporanMenu pesanGagal="Gagal mengambil data menu" onMuatUlang={onMuatUlang} />)
    expect(screen.getByText('Gagal memuat laporan menu')).toBeDefined()
    expect(screen.getByText('Gagal mengambil data menu')).toBeDefined()
    const tombolCoba = screen.getByRole('button', { name: /coba lagi/i })
    fireEvent.click(tombolCoba)
    expect(onMuatUlang).toHaveBeenCalled()
  })

  it('merender keadaan kosong saat data null', () => {
    render(<LaporanMenu data={null} />)
    expect(screen.getByText(/tidak ada data menu dan promosi pada periode ini/i)).toBeDefined()
  })

  it('merender kartu KPI ringkasan menu dan biaya promosi', () => {
    render(<LaporanMenu data={DATA_MENU_MOCK} />)

    // Header & Cabang
    expect(screen.getByRole('heading', { level: 2, name: /menu & promo/i })).toBeDefined()
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText(/2026-09-18 s\/d 2026-09-24/)).toBeDefined()

    // KPI Total Porsi & Omzet Menu
    expect(screen.getByText('120 Porsi')).toBeDefined()
    expect(screen.getByText('Rp3.600.000')).toBeDefined()

    // KPI Total Diskon Manual & Total Biaya Promosi
    expect(screen.getByText('Rp150.000')).toBeDefined()
    expect(screen.getByText('Rp250.000')).toBeDefined()
  })

  it('merender tabel peringkat menu dengan nama historis nama_saat_itu', () => {
    render(<LaporanMenu data={DATA_MENU_MOCK} />)

    // Peringkat 1: Nasi Goreng Spesial Barokah
    expect(screen.getByText('Nasi Goreng Spesial Barokah')).toBeDefined()
    expect(screen.getByText('Makanan Berat')).toBeDefined()
    expect(screen.getByText('80')).toBeDefined()
    expect(screen.getByText('Rp2.400.000')).toBeDefined()
    expect(screen.getByText('66.7%')).toBeDefined()

    // Peringkat 2: Es Teh Manis
    expect(screen.getByText('Es Teh Manis')).toBeDefined()
    expect(screen.getByText('Minuman Segar')).toBeDefined()
    expect(screen.getByText('40')).toBeDefined()
    expect(screen.getByText('Rp1.200.000')).toBeDefined()
    expect(screen.getByText('33.3%')).toBeDefined()
  })

  it('memanggil onGantiUrutan ketika tombol urut omzet atau porsi diklik', () => {
    const onGantiUrutan = vi.fn()
    render(
      <LaporanMenu data={DATA_MENU_MOCK} urutBerdasarkan="nilai" onGantiUrutan={onGantiUrutan} />,
    )

    const tombolUrutJumlah = screen.getByRole('button', { name: /urutkan porsi/i })
    fireEvent.click(tombolUrutJumlah)
    expect(onGantiUrutan).toHaveBeenCalledWith('jumlah')

    const tombolUrutNilai = screen.getByRole('button', { name: /urutkan omzet/i })
    fireEvent.click(tombolUrutNilai)
    expect(onGantiUrutan).toHaveBeenCalledWith('nilai')
  })

  it('merender rincian diskon manual dan voucher terpakai', () => {
    render(<LaporanMenu data={DATA_MENU_MOCK} />)

    // Diskon Manual
    expect(screen.getByText((content) => content.includes('#' + '101'))).toBeDefined()
    expect(screen.getByText('Promo pembukaan toko')).toBeDefined()
    expect(screen.getByText('- Rp150.000')).toBeDefined()
    expect(screen.getAllByText('Rina Kasir').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText(/Acc: Pak Budi SPV/)).toBeDefined()

    // Voucher Terpakai
    expect(screen.getByText((content) => content.includes('#' + '102'))).toBeDefined()
    expect(screen.getByText('HEMAT10RB')).toBeDefined()
    expect(screen.getByText('- Rp100.000')).toBeDefined()
  })

  it('memungkinkan pemilik (owner_pusat) memilih cabang atau semua cabang', () => {
    const onPilihCabang = vi.fn()
    const daftarCabang = [
      { id: 'c-01', nama: 'Cabang Utama' },
      { id: 'c-02', nama: 'Cabang Dago' },
    ]

    render(
      <LaporanMenu
        data={DATA_MENU_MOCK}
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
      <LaporanMenu
        data={DATA_MENU_MOCK}
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
      <LaporanMenu
        data={DATA_MENU_MOCK}
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

  it('menolak rentang tanggal jika melebihi 90 hari', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanMenu
        data={DATA_MENU_MOCK}
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
      <LaporanMenu
        data={DATA_MENU_MOCK}
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
