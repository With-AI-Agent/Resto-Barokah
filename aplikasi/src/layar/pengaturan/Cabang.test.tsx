// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { Cabang, type DataCabang } from './Cabang'

describe('Cabang (T9-09 / PRD M11 / ART-7 & ART-12)', () => {
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  const daftarContoh: DataCabang[] = [
    {
      id: 'cab-01',
      nama: 'Cabang Pusat',
      alamat: 'Jl. Riau No. 50, Bandung',
      telepon: '022-7778888',
      zona_waktu: 'Asia/Jakarta',
      printer_default: {
        profil_id: 'epson-t82',
        nama: 'Epson T82 Kasir',
        lebar: 80,
      },
      aktif: true,
      jumlah_pegawai: 4,
      jumlah_meja: 12,
      jumlah_perangkat: 2,
    },
    {
      id: 'cab-02',
      nama: 'Cabang Dago',
      alamat: 'Jl. Ir. H. Juanda No. 120, Bandung',
      telepon: '022-2501234',
      zona_waktu: 'Asia/Jakarta',
      printer_default: {
        profil_id: 'umum-58',
        nama: 'Thermal 58mm',
        lebar: 58,
      },
      aktif: false,
      jumlah_pegawai: 1,
      jumlah_meja: 6,
      jumlah_perangkat: 1,
    },
  ]

  it('merender daftar cabang dengan informasi zona waktu, printer default, dan statistik', () => {
    render(<Cabang daftarCabang={daftarContoh} cabangAktifId="cab-01" />)

    expect(screen.getByText('Cabang Pusat')).toBeDefined()
    expect(screen.getByText('Jl. Riau No. 50, Bandung • Telp: 022-7778888')).toBeDefined()
    expect(screen.getByText('Cabang Dago')).toBeDefined()
    expect(screen.getByText('Aktif')).toBeDefined()
    expect(screen.getByText('Nonaktif')).toBeDefined()
    expect(screen.getByText('Sesi Aktif')).toBeDefined()
    expect(screen.getByText(/Epson T82 Kasir/)).toBeDefined()
    expect(screen.getByText(/Thermal 58mm/)).toBeDefined()
  })

  it('dapat menyaring cabang berdasarkan kata kunci pencarian dan tombol filter status', () => {
    render(<Cabang daftarCabang={daftarContoh} />)

    const inputCari = screen.getByPlaceholderText(/Ketik nama cabang atau alamat/i)
    fireEvent.change(inputCari, { target: { value: 'Dago' } })

    expect(screen.queryByText('Cabang Pusat')).toBeNull()
    expect(screen.getByText('Cabang Dago')).toBeDefined()

    // Reset cari dan filter status Aktif
    fireEvent.change(inputCari, { target: { value: '' } })
    const tombolAktif = screen.getByRole('button', { name: /^Aktif \(/i })
    fireEvent.click(tombolAktif)

    expect(screen.getByText('Cabang Pusat')).toBeDefined()
    expect(screen.queryByText('Cabang Dago')).toBeNull()
  })

  it('membuka modal tambah cabang dan memproses pembuatan cabang baru', async () => {
    const onTambahMock = vi.fn().mockResolvedValue({ sukses: true, cabangId: 'cab-99' })

    render(<Cabang daftarCabang={daftarContoh} onTambahCabang={onTambahMock} />)

    // Klik tombol tambah cabang
    fireEvent.click(screen.getByRole('button', { name: /\+ Tambah Cabang/i }))

    expect(screen.getByText('Tambah Cabang Baru')).toBeDefined()

    // Isi nama cabang
    const inputNama = screen.getByPlaceholderText(/Contoh: Cabang Dago, Cabang Sukajadi/i)
    fireEvent.change(inputNama, { target: { value: 'Cabang Sukajadi' } })

    // Klik simpan
    fireEvent.click(screen.getByRole('button', { name: /Simpan Cabang Baru/i }))

    await waitFor(() => {
      expect(onTambahMock).toHaveBeenCalledWith(
        expect.objectContaining({
          nama: 'Cabang Sukajadi',
          zonaWaktu: 'Asia/Jakarta',
        }),
      )
    })

    expect(screen.getByText(/berhasil ditambahkan/i)).toBeDefined()
  })

  it('menolak penambahan cabang jika nama kosong atau nama duplikat', async () => {
    const onTambahMock = vi.fn()

    render(<Cabang daftarCabang={daftarContoh} onTambahCabang={onTambahMock} />)

    fireEvent.click(screen.getByRole('button', { name: /\+ Tambah Cabang/i }))

    // Kosong -> klik simpan
    fireEvent.click(screen.getByRole('button', { name: /Simpan Cabang Baru/i }))
    expect(screen.getByText('Nama cabang wajib diisi.')).toBeDefined()
    expect(onTambahMock).not.toHaveBeenCalled()

    // Duplikat -> ketik nama yang sudah ada
    const inputNama = screen.getByPlaceholderText(/Contoh: Cabang Dago, Cabang Sukajadi/i)
    fireEvent.change(inputNama, { target: { value: 'Cabang Pusat' } })
    fireEvent.click(screen.getByRole('button', { name: /Simpan Cabang Baru/i }))

    expect(screen.getByText(/sudah terdaftar/i)).toBeDefined()
    expect(onTambahMock).not.toHaveBeenCalled()
  })

  it('membuka modal edit cabang dan menyimpan perubahan profil cabang & printer', async () => {
    const onSimpanMock = vi.fn().mockResolvedValue({ sukses: true })

    render(<Cabang daftarCabang={daftarContoh} onSimpanCabang={onSimpanMock} />)

    const tombolEdit = screen.getAllByRole('button', { name: /Edit Cabang/i })
    fireEvent.click(tombolEdit[0])

    expect(screen.getByText(/Edit Cabang — Cabang Pusat/i)).toBeDefined()

    const inputNama = screen.getByPlaceholderText(/Nama cabang resmi/i)
    fireEvent.change(inputNama, { target: { value: 'Cabang Pusat Baru' } })

    fireEvent.click(screen.getByRole('button', { name: /Simpan Perubahan/i }))

    await waitFor(() => {
      expect(onSimpanMock).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'cab-01',
          nama: 'Cabang Pusat Baru',
        }),
      )
    })

    expect(screen.getByText(/berhasil diperbarui/i)).toBeDefined()
  })

  it('mencegah penonaktifan satu-satunya cabang aktif (fail-closed ART-12)', async () => {
    const onUbahStatusMock = vi.fn()
    window.confirm = vi.fn().mockReturnValue(true)

    // Data hanya punya 1 cabang aktif
    const daftarSatuAktif: DataCabang[] = [
      {
        id: 'cab-01',
        nama: 'Cabang Tunggal',
        alamat: null,
        telepon: null,
        zona_waktu: 'Asia/Jakarta',
        printer_default: null,
        aktif: true,
      },
      {
        id: 'cab-02',
        nama: 'Cabang Tutup',
        alamat: null,
        telepon: null,
        zona_waktu: 'Asia/Jakarta',
        printer_default: null,
        aktif: false,
      },
    ]

    render(<Cabang daftarCabang={daftarSatuAktif} onUbahStatusCabang={onUbahStatusMock} />)

    const tombolNonaktifkan = screen.getByRole('button', { name: /^Nonaktifkan/i })
    fireEvent.click(tombolNonaktifkan)

    expect(screen.getByText('Minimal harus ada satu cabang yang aktif di restoran.')).toBeDefined()
    expect(onUbahStatusMock).not.toHaveBeenCalled()
  })

  it('mengubah status keaktifan cabang dengan dialog konfirmasi jika masih ada cabang aktif lain', async () => {
    const onUbahStatusMock = vi.fn().mockResolvedValue({ sukses: true })
    window.confirm = vi.fn().mockReturnValue(true)

    // Data punya 2 cabang aktif
    const daftarDuaAktif: DataCabang[] = [
      {
        id: 'cab-01',
        nama: 'Cabang Pusat',
        alamat: null,
        telepon: null,
        zona_waktu: 'Asia/Jakarta',
        printer_default: null,
        aktif: true,
      },
      {
        id: 'cab-02',
        nama: 'Cabang Dago',
        alamat: null,
        telepon: null,
        zona_waktu: 'Asia/Jakarta',
        printer_default: null,
        aktif: true,
      },
    ]

    render(<Cabang daftarCabang={daftarDuaAktif} onUbahStatusCabang={onUbahStatusMock} />)

    const tombolNonaktifkan = screen.getAllByRole('button', { name: /^Nonaktifkan/i })
    fireEvent.click(tombolNonaktifkan[1]) // nonaktifkan Cabang Dago

    expect(window.confirm).toHaveBeenCalled()
    await waitFor(() => {
      expect(onUbahStatusMock).toHaveBeenCalledWith('cab-02', false)
    })
  })

  it('membuka modal penugasan staf multi-cabang dan mengatur akses pegawai', async () => {
    const onAturAksesMock = vi.fn().mockResolvedValue({ sukses: true })

    render(<Cabang daftarCabang={daftarContoh} onAturAksesCabang={onAturAksesMock} />)

    const tombolAkses = screen.getAllByRole('button', { name: /Penugasan Staf/i })
    fireEvent.click(tombolAkses[0])

    expect(screen.getByText(/Penugasan Staf — Cabang Pusat/i)).toBeDefined()
    expect(screen.getByText('Rina')).toBeDefined()

    // Klik tombol tugaskan untuk Rina
    const tombolTugaskan = screen.getAllByRole('button', { name: /Tugaskan|Cabut Akses/i })
    fireEvent.click(tombolTugaskan[0])

    await waitFor(() => {
      expect(onAturAksesMock).toHaveBeenCalled()
    })
  })
})
