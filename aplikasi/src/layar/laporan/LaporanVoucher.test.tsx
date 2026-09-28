// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LaporanVoucher, type DataLaporanVoucher } from './LaporanVoucher'

afterEach(cleanup)

const DATA_VOUCHER_MOCK: DataLaporanVoucher = {
  rentang: {
    tanggal_mulai: '2026-09-01',
    tanggal_akhir: '2026-09-25',
    jumlah_hari: 25,
  },
  cabang: {
    id: 'cabang-01',
    nama: 'Cabang Utama',
  },
  ringkasan: {
    total_klaim: 12,
    total_terpakai: 8,
    total_potongan: 160000,
    tingkat_konversi_persen: 66.7,
    rata_rata_potongan: 20000,
  },
  per_kampanye: [
    {
      kampanye_id: 'kmp-01',
      kode_kampanye: 'BERKAH50',
      nama_kampanye: 'Diskon Berkah 50%',
      jenis_diskon: 'persen',
      nilai_diskon: 50,
      anggaran_maks: 500000,
      total_klaim: 10,
      total_terpakai: 6,
      total_potongan: 120000,
      tingkat_konversi_persen: 60.0,
    },
    {
      kampanye_id: 'kmp-02',
      kode_kampanye: 'HEMAT20K',
      nama_kampanye: 'Potongan Langsung 20Rb',
      jenis_diskon: 'nominal',
      nilai_diskon: 20000,
      anggaran_maks: 200000,
      total_klaim: 2,
      total_terpakai: 2,
      total_potongan: 40000,
      tingkat_konversi_persen: 100.0,
    },
  ],
  per_cabang: [
    {
      cabang_id: 'cabang-01',
      nama_cabang: 'Cabang Utama',
      total_klaim: 12,
      total_terpakai: 8,
      total_potongan: 160000,
    },
  ],
  tren_harian: [
    {
      tanggal: '2026-09-24',
      total_klaim: 5,
      total_terpakai: 3,
      total_potongan: 60000,
    },
    {
      tanggal: '2026-09-25',
      total_klaim: 7,
      total_terpakai: 5,
      total_potongan: 100000,
    },
  ],
  klaim_berulang: [
    {
      pelanggan_id: 'pel-01',
      nama: 'Budi Santoso',
      nomor_hp: '081234567890',
      jumlah_klaim: 4,
      jumlah_terpakai: 3,
      total_potongan: 60000,
    },
    {
      pelanggan_id: 'pel-02',
      nama: 'Siti Aminah',
      nomor_hp: '089876543210',
      jumlah_klaim: 2,
      jumlah_terpakai: 1,
      total_potongan: 20000,
    },
  ],
  anomali: [
    {
      tipe: 'klaim_berulang_berlebih',
      tingkat: 'bahaya',
      pesan: 'Pelanggan Budi Santoso melakukan 4 klaim voucher (ambang batas: 3)',
      data: { pelanggan_id: 'pel-01', jumlah_klaim: 4 },
    },
    {
      tipe: 'pemakaian_kilat',
      tingkat: 'peringatan',
      pesan: 'Voucher BERKAH50 dipakai dalam 35 detik sejak diterbitkan (< 2 menit)',
      data: { selisih_detik: 35 },
    },
  ],
}

describe('LaporanVoucher', () => {
  it('merender indikator memuat saat sedangMemuat bernilai true', () => {
    render(<LaporanVoucher sedangMemuat={true} />)
    expect(screen.getByText(/memuat/i)).toBeDefined()
  })

  it('merender keadaan gagal dengan tombol coba lagi saat ada pesanGagal', () => {
    const onMuatUlang = vi.fn()
    render(<LaporanVoucher pesanGagal="Koneksi database terputus" onMuatUlang={onMuatUlang} />)
    expect(screen.getByText('Gagal memuat laporan voucher')).toBeDefined()
    expect(screen.getByText('Koneksi database terputus')).toBeDefined()
    const tombolCoba = screen.getByRole('button', { name: /coba lagi/i })
    fireEvent.click(tombolCoba)
    expect(onMuatUlang).toHaveBeenCalled()
  })

  it('merender keadaan kosong saat data null', () => {
    render(<LaporanVoucher data={null} />)
    expect(screen.getByText(/tidak ada aktivitas voucher pada periode ini/i)).toBeDefined()
  })

  it('merender kartu KPI ringkasan voucher (klaim, terpakai, konversi, potongan, rata-rata)', () => {
    render(<LaporanVoucher data={DATA_VOUCHER_MOCK} />)

    // Header & Cabang
    expect(
      screen.getByRole('heading', { level: 2, name: /laporan voucher & promosi/i }),
    ).toBeDefined()
    expect(screen.getAllByText(/Cabang Utama/).length).toBeGreaterThanOrEqual(1)

    // Ringkasan KPI
    expect(screen.getAllByText('12').length).toBeGreaterThanOrEqual(1) // Total klaim
    expect(screen.getAllByText('8').length).toBeGreaterThanOrEqual(1) // Total terpakai
    expect(screen.getByText('66.7%')).toBeDefined() // Konversi
    expect(screen.getAllByText('Rp160.000').length).toBeGreaterThanOrEqual(1) // Total potongan
    expect(screen.getAllByText('Rp20.000').length).toBeGreaterThanOrEqual(1) // Rata-rata potongan
  })

  it('merender bagian peringatan dini anomali saat ada anomali (bahaya & peringatan)', () => {
    render(<LaporanVoucher data={DATA_VOUCHER_MOCK} />)

    expect(screen.getByTestId('daftar-anomali')).toBeDefined()
    expect(screen.getByText(/Klaim Berulang Melebihi Batas/)).toBeDefined()
    expect(screen.getByText(/Pelanggan Budi Santoso melakukan 4 klaim voucher/)).toBeDefined()
    expect(screen.getByText(/Pemakaian Kilat/)).toBeDefined()
    expect(screen.getByText(/Voucher BERKAH50 dipakai dalam 35 detik/)).toBeDefined()
  })

  it('merender status bersih saat tidak ada anomali yang terdeteksi', () => {
    const dataAman: DataLaporanVoucher = {
      ...DATA_VOUCHER_MOCK,
      anomali: [],
    }
    render(<LaporanVoucher data={dataAman} />)

    expect(screen.getByTestId('status-anomali-aman')).toBeDefined()
    expect(screen.getByText(/Aman: Tidak terdeteksi anomali voucher/)).toBeDefined()
    expect(screen.getByText('Status Bersih')).toBeDefined()
  })

  it('merender rincian per kampanye, per cabang, dan tren harian', () => {
    render(<LaporanVoucher data={DATA_VOUCHER_MOCK} />)

    // Kampanye
    expect(screen.getByText('BERKAH50')).toBeDefined()
    expect(screen.getByText('Diskon Berkah 50%')).toBeDefined()
    expect(screen.getByText('HEMAT20K')).toBeDefined()
    expect(screen.getByText('Potongan Langsung 20Rb')).toBeDefined()

    // Cabang
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)

    // Tren harian
    expect(screen.getAllByText('Rp60.000').length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText('Rp100.000').length).toBeGreaterThanOrEqual(1)
  })

  it('merender daftar identitas klaim berulang dan memberi lencana Frekuensi Tinggi bila > 3', () => {
    render(<LaporanVoucher data={DATA_VOUCHER_MOCK} />)

    expect(screen.getByTestId('tabel-klaim-berulang')).toBeDefined()
    expect(screen.getByText('Budi Santoso')).toBeDefined()
    expect(screen.getByText('081234567890')).toBeDefined()
    expect(screen.getByText('Frekuensi Tinggi')).toBeDefined() // Karena klaim = 4 > 3

    expect(screen.getByText('Siti Aminah')).toBeDefined()
    expect(screen.getByText('089876543210')).toBeDefined()
    // Siti Aminah klaim 2 <= 3 maka tidak dapat penanda Frekuensi Tinggi
    expect(screen.queryAllByText('Frekuensi Tinggi').length).toBe(1)
  })

  it('memungkinkan pemilik (owner_pusat) memilih cabang', () => {
    const onPilihCabang = vi.fn()
    const daftarCabang = [
      { id: 'cabang-01', nama: 'Cabang Utama' },
      { id: 'cabang-02', nama: 'Cabang Dago' },
    ]

    render(
      <LaporanVoucher
        data={DATA_VOUCHER_MOCK}
        daftarCabang={daftarCabang}
        cabangAktifId="cabang-01"
        peranPengguna="owner_pusat"
        onPilihCabang={onPilihCabang}
      />,
    )

    const select = screen.getByLabelText(/cabang/i) as HTMLSelectElement
    expect(select).toBeDefined()
    fireEvent.change(select, { target: { value: 'cabang-02' } })
    expect(onPilihCabang).toHaveBeenCalledWith('cabang-02')
  })

  it('mengunci tampilan cabang bagi admin_cabang tanpa dropdown pemilihan', () => {
    const daftarCabang = [{ id: 'cabang-01', nama: 'Cabang Utama' }]
    render(
      <LaporanVoucher
        data={DATA_VOUCHER_MOCK}
        daftarCabang={daftarCabang}
        cabangAktifId="cabang-01"
        peranPengguna="admin_cabang"
      />,
    )

    expect(screen.queryByLabelText(/cabang/i)).toBeNull()
  })

  it('menolak rentang tanggal jika tanggal akhir lebih awal dari tanggal mulai', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanVoucher
        data={DATA_VOUCHER_MOCK}
        tanggalMulai="2026-09-20"
        tanggalAkhir="2026-09-25"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/tanggal akhir/i) as HTMLInputElement

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
      <LaporanVoucher
        data={DATA_VOUCHER_MOCK}
        tanggalMulai="2026-01-01"
        tanggalAkhir="2026-01-07"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/tanggal akhir/i) as HTMLInputElement

    fireEvent.change(inputMulai, { target: { value: '2026-01-01' } })
    fireEvent.change(inputAkhir, { target: { value: '2026-06-01' } }) // 151 hari

    const tombolTerapkan = screen.getByRole('button', { name: /terapkan/i })
    fireEvent.click(tombolTerapkan)

    expect(onPilihRentangTanggal).not.toHaveBeenCalled()
    expect(screen.getByText(/rentang tanggal maksimal 90 hari/i)).toBeDefined()
  })

  it('meneruskan rentang tanggal valid ke callback onPilihRentangTanggal', () => {
    const onPilihRentangTanggal = vi.fn()
    render(
      <LaporanVoucher
        data={DATA_VOUCHER_MOCK}
        tanggalMulai="2026-09-01"
        tanggalAkhir="2026-09-25"
        onPilihRentangTanggal={onPilihRentangTanggal}
      />,
    )

    const inputMulai = screen.getByLabelText(/tanggal mulai/i) as HTMLInputElement
    const inputAkhir = screen.getByLabelText(/tanggal akhir/i) as HTMLInputElement

    fireEvent.change(inputMulai, { target: { value: '2026-09-05' } })
    fireEvent.change(inputAkhir, { target: { value: '2026-09-20' } })

    const tombolTerapkan = screen.getByRole('button', { name: /terapkan/i })
    fireEvent.click(tombolTerapkan)

    expect(onPilihRentangTanggal).toHaveBeenCalledWith('2026-09-05', '2026-09-20')
  })
})
