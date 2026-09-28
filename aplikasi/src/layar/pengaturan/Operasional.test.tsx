// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { Operasional, hitungSimulasiStruk, type DataOperasional } from './Operasional'

describe('Operasional (Pengaturan Operasional & Kasir — T9-03 / PRD M2, M6 / ART-3)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('fungsi hitungSimulasiStruk menghitung finansial sesuai ART-3 dan aturan pembulatan', () => {
    // 1. Tanpa pembulatan: subtotal 42.000, diskon 5.000 -> dasar 37.000
    // Pajak 10% = 3.700, Service 5% = 1.850 -> Total = 37.000 + 3.700 + 1.850 = 42.550
    const simNone = hitungSimulasiStruk(42000, 5000, 10, 5, 'none')
    expect(simNone.dasar).toBe(37000)
    expect(simNone.nominalPajak).toBe(3700)
    expect(simNone.nominalService).toBe(1850)
    expect(simNone.total).toBe(42550)

    // 2. Pembulatan 500: 42.550 dibulatkan ke kelipatan 500 -> 42.500
    const sim500 = hitungSimulasiStruk(42000, 5000, 10, 5, '500')
    expect(sim500.total).toBe(42500)

    // 3. Pembulatan 1000: 42.550 dibulatkan ke kelipatan 1000 -> 42.000
    const sim1000 = hitungSimulasiStruk(42000, 5000, 10, 5, '1000')
    expect(sim1000.total).toBe(42000)

    // 4. Pembulatan 100: 42.550 dibulatkan ke kelipatan 100 -> 42.500
    const sim100 = hitungSimulasiStruk(42000, 5000, 10, 5, '100')
    expect(sim100.total).toBe(42500)
  })

  it('merender judul, kolom isian utama, pilihan alur pesan, dan pratinjau struk', () => {
    render(<Operasional />)

    expect(screen.getByText('Pengaturan Operasional & Kasir')).toBeDefined()
    expect(screen.getByLabelText('Pajak PB1 (%)')).toBeDefined()
    expect(screen.getByLabelText('Service Charge (%)')).toBeDefined()
    expect(screen.getByLabelText('Jam Operasional')).toBeDefined()
    expect(screen.getByLabelText('Pesan Kepala Struk (Header)')).toBeDefined()
    expect(screen.getByLabelText('Pesan Penutup Struk (Footer)')).toBeDefined()

    // 4 pilihan cara pesan
    expect(screen.getByText('Dilayani Kasir')).toBeDefined()
    expect(screen.getByText('Mandiri / Ambil Sendiri')).toBeDefined()
    expect(screen.getByText('Pelayan di Meja')).toBeDefined()
    expect(screen.getByText('Fleksibel / Campuran')).toBeDefined()

    // 4 pilihan pembulatan
    expect(screen.getByText('Tanpa Pembulatan')).toBeDefined()
    expect(screen.getByText('Ke Rp 100')).toBeDefined()
    expect(screen.getByText('Ke Rp 500')).toBeDefined()
    expect(screen.getByText('Ke Rp 1.000')).toBeDefined()

    // Kartu pratinjau struk kasir
    expect(screen.getByText(/pratinjau struk kasir/i)).toBeDefined()
    expect(screen.getByText('TOTAL AKHIR:')).toBeDefined()
  })

  it('memilih tombol cepat persentase PB1 memperbarui nilai input dan kalkulasi', () => {
    render(<Operasional />)

    const tombol11 = screen.getByRole('button', { name: /pilih tarif pb1 11 persen/i })
    fireEvent.click(tombol11)

    const inputPajak = screen.getByLabelText(/pajak pb1/i) as HTMLInputElement
    expect(inputPajak.value).toBe('11')
    expect(screen.getByText(/pajak pb1 \(11%\):/i)).toBeDefined()
  })

  it('memilih tombol cepat persentase Service Charge memperbarui nilai input dan kalkulasi', () => {
    render(<Operasional />)

    const tombol7 = screen.getByRole('button', { name: /pilih service charge 7 persen/i })
    fireEvent.click(tombol7)

    const inputService = screen.getByLabelText('Service Charge (%)') as HTMLInputElement
    expect(inputService.value).toBe('7')
    expect(screen.getByText(/service charge \(7%\):/i)).toBeDefined()
  })

  it('dapat mengubah aturan pembulatan dan tercermin di kartu struk', () => {
    render(<Operasional />)

    const kartu500 = screen.getByText('Ke Rp 500')
    fireEvent.click(kartu500)

    expect(screen.getByText(/kelipatan 500/i)).toBeDefined()
  })

  it('dapat mengubah alur cara pesan dan tercermin di footer struk', () => {
    render(<Operasional />)

    const kartuMandiri = screen.getByText('Mandiri / Ambil Sendiri')
    fireEvent.click(kartuMandiri)

    expect(screen.getByText(/mode layanan: mandiri \/ ambil sendiri/i)).toBeDefined()
  })

  it('menolak nilai pajak tidak sah (< 0 atau > 100) dengan pesan galat', async () => {
    render(<Operasional />)

    const inputPajak = screen.getByLabelText(/pajak pb1/i)
    fireEvent.change(inputPajak, { target: { value: '150' } })

    const tombolSimpan = screen.getByRole('button', { name: /simpan pengaturan operasional/i })
    fireEvent.click(tombolSimpan)

    expect(await screen.findByRole('alert')).toBeDefined()
    expect(screen.getByText(/angka antara 0 sampai 100/i)).toBeDefined()
  })

  it('menolak nilai service charge tidak sah (< 0 atau > 100) dengan pesan galat', async () => {
    render(<Operasional />)

    const inputService = screen.getByLabelText('Service Charge (%)')
    fireEvent.change(inputService, { target: { value: '-5' } })

    const tombolSimpan = screen.getByRole('button', { name: /simpan pengaturan operasional/i })
    fireEvent.click(tombolSimpan)

    expect(await screen.findByRole('alert')).toBeDefined()
    expect(screen.getByText(/angka antara 0 sampai 100/i)).toBeDefined()
  })

  it('memanggil onSimpan dengan data operasional lengkap saat tombol simpan ditekan', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Pengaturan operasional berhasil disimpan.',
    })

    const dataAwal: Partial<DataOperasional> = {
      pajak_pb1_persen: 10,
      service_persen: 5,
      pembulatan: 'none',
      cara_pesan: 'kasir',
      jam_buka: '08:00 - 22:00',
      header_struk: 'Header Asli',
      footer_struk: 'Footer Asli',
      tumpuk_diskon: false,
    }

    render(<Operasional dataAwal={dataAwal} onSimpan={mockSimpan} />)

    // Ubah header struk
    const inputHeader = screen.getByLabelText(/pesan kepala struk/i)
    fireEvent.change(inputHeader, { target: { value: 'KEDAI OASIS BAROKAH' } })

    // Klik simpan
    const tombolSimpan = screen.getByRole('button', { name: /simpan pengaturan operasional/i })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledTimes(1)
    })

    const payload = mockSimpan.mock.calls[0][0] as DataOperasional
    expect(payload.header_struk).toBe('KEDAI OASIS BAROKAH')
    expect(payload.pajak_pb1_persen).toBe(10)
    expect(payload.service_persen).toBe(5)

    expect(await screen.findByRole('status')).toBeDefined()
    expect(screen.getByText(/pengaturan operasional berhasil disimpan/i)).toBeDefined()
  })

  it('menampilkan pesan galat saat onSimpan mengembalikan berhasil: false', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Data pengaturan sudah diubah oleh pengguna lain.',
    })

    render(<Operasional onSimpan={mockSimpan} />)

    const tombolSimpan = screen.getByRole('button', { name: /simpan pengaturan operasional/i })
    fireEvent.click(tombolSimpan)

    expect(await screen.findByRole('alert')).toBeDefined()
    expect(screen.getByText(/data pengaturan sudah diubah oleh pengguna lain/i)).toBeDefined()
  })

  it('tombol reset mengembalikan form ke data awal', () => {
    const dataAwal: Partial<DataOperasional> = {
      pajak_pb1_persen: 10,
      service_persen: 5,
      header_struk: 'Header Bawaan',
    }

    render(<Operasional dataAwal={dataAwal} />)

    const inputHeader = screen.getByLabelText(/pesan kepala struk/i) as HTMLInputElement
    fireEvent.change(inputHeader, { target: { value: 'Teks Baru Sementara' } })
    expect(inputHeader.value).toBe('Teks Baru Sementara')

    const tombolReset = screen.getByRole('button', { name: /reset pengaturan ke semula/i })
    fireEvent.click(tombolReset)

    expect(inputHeader.value).toBe('Header Bawaan')
  })

  it('dalam mode hanyaBaca, tombol simpan tidak ada dan isian nonaktif', () => {
    render(<Operasional hanyaBaca={true} />)

    expect(screen.queryByRole('button', { name: /simpan pengaturan operasional/i })).toBeNull()

    const inputPajak = screen.getByLabelText(/pajak pb1/i) as HTMLInputElement
    expect(inputPajak.disabled).toBe(true)
  })
})
