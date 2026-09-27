// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { SesiAktif, type DataSesiAktif } from './SesiAktif'

describe('SesiAktif (T10-06)', () => {
  afterEach(() => {
    cleanup()
  })

  const daftarUji: DataSesiAktif[] = [
    {
      sessionId: 'sess-01',
      perangkatId: 'dev-01',
      namaPerangkat: 'Tablet POS Kasir',
      jenisPerangkat: 'tablet',
      statusPerangkat: 'aktif',
      penggunaId: 'user-01',
      namaPengguna: 'Rina Kasir',
      emailPengguna: 'rina@resto.local',
      peran: 'kasir',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Pusat',
      mulai: new Date().toISOString(),
      berakhirPada: new Date(Date.now() + 36000000).toISOString(),
      status: 'aktif',
    },
    {
      sessionId: 'sess-02',
      perangkatId: 'dev-02',
      namaPerangkat: 'HP Waiter Outdoor',
      jenisPerangkat: 'ponsel',
      statusPerangkat: 'aktif',
      penggunaId: 'user-02',
      namaPengguna: 'Dedi Pelayan',
      emailPengguna: 'dedi@resto.local',
      peran: 'pelayan',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Pusat',
      mulai: new Date(Date.now() - 3600000).toISOString(),
      berakhirPada: new Date(Date.now() + 39600000).toISOString(),
      status: 'aktif',
    },
  ]

  it('merender daftar sesi aktif dengan informasi lengkap pengguna, perangkat, dan peran', () => {
    render(<SesiAktif daftarSesiAwal={daftarUji} />)

    expect(screen.getByText('Sesi Aktif & Keamanan Perangkat')).toBeDefined()
    expect(screen.getByText('Rina Kasir')).toBeDefined()
    expect(screen.getByText('Dedi Pelayan')).toBeDefined()
    expect(screen.getByText('Tablet POS Kasir')).toBeDefined()
    expect(screen.getByText('HP Waiter Outdoor')).toBeDefined()
    expect(screen.getAllByText('Aktif').length).toBeGreaterThanOrEqual(2)
  })

  it('memfilter sesi berdasarkan kata kunci pencarian', () => {
    render(<SesiAktif daftarSesiAwal={daftarUji} />)

    const inputCari = screen.getByPlaceholderText(/Ketik nama staf/i)
    fireEvent.change(inputCari, { target: { value: 'Rina' } })

    expect(screen.getByText('Rina Kasir')).toBeDefined()
    expect(screen.queryByText('Dedi Pelayan')).toBeNull()
  })

  it('memfilter sesi berdasarkan peran staf', () => {
    render(<SesiAktif daftarSesiAwal={daftarUji} />)

    const selectPeran = screen.getByRole('combobox', { name: /Filter berdasarkan peran staf/i })
    fireEvent.change(selectPeran, { target: { value: 'pelayan' } })

    expect(screen.queryByText('Rina Kasir')).toBeNull()
    expect(screen.getByText('Dedi Pelayan')).toBeDefined()
  })

  it('mengakhiri sesi tunggal dengan alasan audit saat tombol Akhiri Sesi diklik', async () => {
    const onAkhiriMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Sesi berhasil diakhiri.',
    })

    render(<SesiAktif daftarSesiAwal={daftarUji} onAkhiriSesi={onAkhiriMock} />)

    const tombolAkhiri = screen.getByRole('button', { name: /Akhiri sesi Rina Kasir/i })
    fireEvent.click(tombolAkhiri)

    // Modal konfirmasi muncul
    expect(screen.getByTestId('dialog-akhiri-sesi')).toBeDefined()
    expect(screen.getByText(/Putuskan sesi aktif untuk Rina Kasir/i)).toBeDefined()

    // Submit konfirmasi
    const tombolSubmit = screen.getByRole('button', { name: /Ya, Akhiri Sesi Sekarang/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onAkhiriMock).toHaveBeenCalledWith('sess-01', expect.any(String))
    })
  })

  it('mengeluarkan pengguna dari seluruh perangkat saat tombol Keluarkan Semua diklik', async () => {
    const onKeluarSemuaMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Semua sesi staf berhasil dicabut.',
    })

    render(<SesiAktif daftarSesiAwal={daftarUji} onKeluarSemuaPerangkat={onKeluarSemuaMock} />)

    const tombolKeluarSemua = screen.getByRole('button', {
      name: /Keluarkan semua sesi Dedi Pelayan/i,
    })
    fireEvent.click(tombolKeluarSemua)

    // Modal dialog muncul
    expect(screen.getByTestId('dialog-keluar-semua')).toBeDefined()
    expect(screen.getByText(/Keluarkan Dedi Pelayan dari SELURUH perangkat/i)).toBeDefined()

    // Eksekusi
    const tombolSubmit = screen.getByRole('button', { name: /Keluarkan Dari Semua Tablet/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onKeluarSemuaMock).toHaveBeenCalledWith('user-02', expect.any(String))
    })
  })

  it('menandai perangkat hilang dan memutuskan seluruh sesinya saat tombol Tandai Hilang diklik', async () => {
    const onTandaiHilangMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Perangkat berhasil ditandai hilang dan seluruh aksesnya diputus seketika.',
    })

    render(<SesiAktif daftarSesiAwal={daftarUji} onTandaiPerangkatHilang={onTandaiHilangMock} />)

    const tombolHilang = screen.getByRole('button', { name: /Tandai Tablet POS Kasir hilang/i })
    fireEvent.click(tombolHilang)

    // Modal bahaya muncul
    expect(screen.getByTestId('dialog-perangkat-hilang')).toBeDefined()
    expect(
      screen.getByText(/BAHAYA KEAMANAN: Perangkat "Tablet POS Kasir" akan DIBLOKIR TOTAL/i),
    ).toBeDefined()

    // Eksekusi
    const tombolSubmit = screen.getByRole('button', { name: /Tandai Hilang & Blokir Seketika/i })
    fireEvent.click(tombolSubmit)

    await waitFor(() => {
      expect(onTandaiHilangMock).toHaveBeenCalledWith('dev-01', expect.any(String))
    })
  })

  it('menyegarkan daftar sesi saat tombol Segarkan diklik', async () => {
    const dataSegar: DataSesiAktif[] = [
      ...daftarUji,
      {
        sessionId: 'sess-03',
        perangkatId: 'dev-03',
        namaPerangkat: 'Layar Dapur KDS',
        jenisPerangkat: 'kds',
        statusPerangkat: 'aktif',
        penggunaId: 'user-03',
        namaPengguna: 'Sari Dapur',
        emailPengguna: 'sari@resto.local',
        peran: 'dapur',
        mulai: new Date().toISOString(),
        berakhirPada: new Date(Date.now() + 36000000).toISOString(),
        status: 'aktif',
      },
    ]

    const onMuatMock = vi.fn().mockResolvedValue(dataSegar)

    render(<SesiAktif daftarSesiAwal={daftarUji} onMuatSesi={onMuatMock} />)

    const tombolSegarkan = screen.getByRole('button', { name: /Segarkan daftar sesi/i })
    fireEvent.click(tombolSegarkan)

    await waitFor(() => {
      expect(onMuatMock).toHaveBeenCalled()
      expect(screen.getByText('Sari Dapur')).toBeDefined()
    })
  })
})
