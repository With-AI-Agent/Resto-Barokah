// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { LaporanKas, type DataLaporanHarian, type DataLaporanShiftDetail } from './LaporanKas'

afterEach(cleanup)

const DATA_HARIAN_MOCK: DataLaporanHarian = {
  tanggal: '2026-09-24',
  cabang_id: 'c-01',
  nama_cabang: 'Cabang Utama',
  jumlah_shift: 1,
  penjualan: {
    jumlah_transaksi: 12,
    omzet_total: 450000,
    omzet_makanan: 320000,
    omzet_minuman: 100000,
    omzet_lainnya: 30000,
    total_diskon: 20000,
  },
  kas: {
    total_modal_awal: 100000,
    kas_masuk: 50000,
    kas_keluar: 20000,
    setoran: 50000,
    penjualan_tunai: 250000,
    penjualan_non_tunai: 200000,
    total_penjualan: 450000,
    total_uang_seharusnya: 330000,
    total_uang_fisik: 330000,
    total_selisih: 0,
  },
  metode_bayar: [
    { metode_id: 'm-1', metode_nama: 'Tunai', jumlah_transaksi: 7, total_nominal: 250000 },
    { metode_id: 'm-2', metode_nama: 'QRIS', jumlah_transaksi: 5, total_nominal: 200000 },
  ],
  shifts: [
    {
      shift_id: 'shift-01',
      cabang_id: 'c-01',
      nama_cabang: 'Cabang Utama',
      dibuka_oleh: 'u-1',
      kasir_buka_nama: 'Rina Kasir',
      dibuka_pada: '2026-09-24T08:00:00.000Z',
      ditutup_oleh: 'u-1',
      kasir_tutup_nama: 'Rina Kasir',
      ditutup_pada: '2026-09-24T16:00:00.000Z',
      status: 'ditutup',
      melewati_tengah_malam: false,
      modal_awal: 100000,
      kas_masuk: 50000,
      kas_keluar: 20000,
      setoran: 50000,
      penjualan_tunai: 250000,
      penjualan_non_tunai: 200000,
      total_penjualan: 450000,
      uang_seharusnya: 330000,
      uang_fisik: 330000,
      selisih: 0,
      alasan_selisih: null,
      jumlah_transaksi: 12,
    },
  ],
  pembatalan: {
    jumlah: 1,
    total_nilai_rugi: 15000,
    daftar: [
      {
        id: 'b-01',
        nomor_pesanan: 101,
        item_nama: 'Ayam Goreng Gosong',
        waktu: '2026-09-24T12:00:00.000Z',
        tahap: 'sesudah_dapur',
        alasan: 'Masakan gosong',
        nilai_kerugian: 15000,
        bahan_terbuang: true,
        pelaku_nama: 'Budi Koki',
        penyetuju_nama: 'Rina Kasir',
      },
    ],
  },
}

const DATA_SHIFT_DETAIL_MOCK: DataLaporanShiftDetail = {
  shift: {
    id: 'shift-01',
    cabang_id: 'c-01',
    nama_cabang: 'Cabang Utama',
    kasir_buka_id: 'u-1',
    kasir_buka_nama: 'Rina Kasir',
    kasir_tutup_id: 'u-1',
    kasir_tutup_nama: 'Rina Kasir',
    dibuka_pada: '2026-09-24T08:00:00.000Z',
    ditutup_pada: '2026-09-24T16:00:00.000Z',
    status: 'ditutup',
    melewati_tengah_malam: false,
    catatan_buka: 'Shift pagi lancar',
  },
  kas: {
    modal_awal: 100000,
    total_koreksi_modal: 20000,
    kas_masuk: 50000,
    kas_keluar: 20000,
    setoran: 50000,
    penjualan_tunai: 250000,
    penjualan_non_tunai: 200000,
    total_penjualan: 450000,
    uang_seharusnya: 330000,
    uang_fisik: 330000,
    selisih: 0,
    alasan_selisih: null,
  },
  penjualan: {
    jumlah_transaksi: 12,
    omzet_total: 450000,
    omzet_makanan: 320000,
    omzet_minuman: 100000,
    omzet_lainnya: 30000,
    total_subtotal: 420000,
    total_pajak: 35000,
    total_service: 15000,
    total_diskon: 20000,
  },
  metode_bayar: [
    { metode_nama: 'Tunai', jumlah_transaksi: 7, total_nominal: 250000 },
    { metode_nama: 'QRIS', jumlah_transaksi: 5, total_nominal: 200000 },
  ],
  pergerakan_kas: [
    {
      waktu: '2026-09-24T09:00:00.000Z',
      jenis: 'masuk',
      jumlah: 50000,
      alasan: 'Tukar uang kecil',
      pelaku_nama: 'Rina Kasir',
    },
  ],
  koreksi_modal: [
    {
      waktu: '2026-09-24T08:15:00.000Z',
      modal_awal_lama: 80000,
      modal_awal_baru: 100000,
      selisih: 20000,
      alasan: 'Kekurangan hitung uang kembalian pagi',
      disetujui_oleh_nama: 'Andi Supervisor',
    },
  ],
  pembatalan: {
    jumlah: 1,
    total_nilai_rugi: 15000,
    daftar: [
      {
        id: 'b-01',
        nomor_pesanan: 101,
        item_nama: 'Ayam Goreng Gosong',
        waktu: '2026-09-24T12:00:00.000Z',
        tahap: 'sesudah_dapur',
        alasan: 'Masakan gosong',
        nilai_kerugian: 15000,
        bahan_terbuang: true,
      },
    ],
  },
}

describe('LaporanKas', () => {
  it('merender indikator memuat saat sedangMemuat bernilai true', () => {
    render(<LaporanKas sedangMemuat={true} />)
    expect(screen.getByText(/memuat/i)).toBeDefined()
  })

  it('merender keadaan gagal dengan tombol coba lagi saat ada pesanGagal', () => {
    const onMuatUlang = vi.fn()
    render(<LaporanKas pesanGagal="Gagal menyambung ke database" onMuatUlang={onMuatUlang} />)
    expect(screen.getByText('Gagal memuat data laporan')).toBeDefined()
    expect(screen.getByText('Gagal menyambung ke database')).toBeDefined()
    const tombolCoba = screen.getByRole('button', { name: /coba lagi/i })
    fireEvent.click(tombolCoba)
    expect(onMuatUlang).toHaveBeenCalled()
  })

  it('merender keadaan kosong saat dataHarian kosong / null', () => {
    render(<LaporanKas dataHarian={null} />)
    expect(
      screen.getByText(/tidak ada data laporan kas untuk tanggal atau cabang ini/i),
    ).toBeDefined()
  })

  it('merender ringkasan omzet, kategori, transaksi, dan arus kas dengan tepat', () => {
    render(<LaporanKas dataHarian={DATA_HARIAN_MOCK} />)

    // Judul & Cabang
    expect(screen.getByText(/laporan penjualan & kas/i)).toBeDefined()
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)

    // Omzet total Rp450.000
    expect(screen.getAllByText('Rp450.000').length).toBeGreaterThanOrEqual(1)

    // Omzet makanan & minuman
    expect(screen.getAllByText(/Rp320\.000/).length).toBeGreaterThanOrEqual(1)
    expect(screen.getAllByText(/Rp100\.000/).length).toBeGreaterThanOrEqual(1)

    // Transaksi & diskon
    expect(screen.getByText(/12 Transaksi/)).toBeDefined()
    expect(screen.getAllByText(/Rp20\.000/).length).toBeGreaterThanOrEqual(1)

    // Uang Seharusnya & Fisik
    expect(screen.getAllByText('Rp330.000').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('Sesuai (Rp0)')).toBeDefined()

    // Metode Bayar
    expect(screen.getByText('Tunai')).toBeDefined()
    expect(screen.getByText('QRIS')).toBeDefined()

    // Kasir pada tabel shift
    expect(screen.getByText('Rina Kasir')).toBeDefined()
    expect(screen.getByText('Ditutup')).toBeDefined()
  })

  it('menampilkan selisih negatif dengan lencana peringatan saat fisik tidak cocok', () => {
    const dataAdaSelisih: DataLaporanHarian = {
      ...DATA_HARIAN_MOCK,
      kas: {
        ...DATA_HARIAN_MOCK.kas,
        total_uang_fisik: 325000,
        total_selisih: -5000,
      },
    }
    render(<LaporanKas dataHarian={dataAdaSelisih} />)
    expect(screen.getByText(/selisih -Rp5\.000/i)).toBeDefined()
  })

  it('memungkinkan pemilik (owner_pusat) memilih cabang lain', () => {
    const onPilihCabang = vi.fn()
    const daftarCabang = [
      { id: 'c-01', nama: 'Cabang Utama' },
      { id: 'c-02', nama: 'Cabang Dago' },
    ]
    render(
      <LaporanKas
        dataHarian={DATA_HARIAN_MOCK}
        peranPengguna="owner_pusat"
        daftarCabang={daftarCabang}
        cabangAktifId="c-01"
        onPilihCabang={onPilihCabang}
      />,
    )

    const select = screen.getByLabelText(/cabang/i) as HTMLSelectElement
    expect(select).toBeDefined()
    fireEvent.change(select, { target: { value: 'c-02' } })
    expect(onPilihCabang).toHaveBeenCalledWith('c-02')
  })

  it('mengunci pilihan cabang untuk admin_cabang tanpa dropdown', () => {
    const daftarCabang = [{ id: 'c-01', nama: 'Cabang Utama' }]
    render(
      <LaporanKas
        dataHarian={DATA_HARIAN_MOCK}
        peranPengguna="admin_cabang"
        daftarCabang={daftarCabang}
        cabangAktifId="c-01"
      />,
    )

    expect(screen.queryByLabelText(/cabang/i)).toBeNull()
    expect(screen.getAllByText('Cabang Utama').length).toBeGreaterThanOrEqual(1)
  })

  it('memungkinkan memilih tanggal laporan', () => {
    const onPilihTanggal = vi.fn()
    render(
      <LaporanKas
        dataHarian={DATA_HARIAN_MOCK}
        tanggal="2026-09-24"
        onPilihTanggal={onPilihTanggal}
      />,
    )

    const inputTanggal = screen.getByLabelText(/filter tanggal/i) as HTMLInputElement
    expect(inputTanggal.value).toBe('2026-09-24')
    fireEvent.change(inputTanggal, { target: { value: '2026-09-23' } })
    expect(onPilihTanggal).toHaveBeenCalledWith('2026-09-23')
  })

  it('membuka modal rincian shift ketika tombol rincian ditekan', () => {
    const onPilihShift = vi.fn()
    render(
      <LaporanKas
        dataHarian={DATA_HARIAN_MOCK}
        shiftTerpilihDetail={DATA_SHIFT_DETAIL_MOCK}
        onPilihShift={onPilihShift}
      />,
    )

    const tombolRincian = screen.getByRole('button', { name: 'Rincian' })
    fireEvent.click(tombolRincian)
    expect(onPilihShift).toHaveBeenCalledWith('shift-01')

    // Modal detail shift terbuka
    expect(screen.getByText(/rincian shift — cabang utama/i)).toBeDefined()
    expect(screen.getByText('Arus Kas Shift')).toBeDefined()
    expect(screen.getByText('Rincian Omzet Penjualan')).toBeDefined()

    // Memuat riwayat koreksi modal awal
    expect(screen.getByText('Riwayat Koreksi Modal Awal')).toBeDefined()
    expect(screen.getByText(/kekurangan hitung uang kembalian pagi/i)).toBeDefined()
    expect(screen.getByText('Andi Supervisor')).toBeDefined()

    // Memuat rincian pembatalan pesanan
    expect(screen.getByText(/pembatalan pesanan \/ void/i)).toBeDefined()
    expect(screen.getByText('Ayam Goreng Gosong')).toBeDefined()

    // Menutup modal
    const tombolTutup = screen.getByRole('button', { name: /tutup rincian/i })
    fireEvent.click(tombolTutup)
  })
})
