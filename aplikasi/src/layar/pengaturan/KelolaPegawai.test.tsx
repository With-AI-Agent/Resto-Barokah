// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { KelolaPegawai, type PegawaiResto } from './KelolaPegawai'

describe('KelolaPegawai (T9-08 / PRD M3 & M6 / ART-2)', () => {
  afterEach(() => {
    cleanup()
  })

  const daftarContoh: PegawaiResto[] = [
    {
      id: 'usr-01',
      nama: 'Budi Santoso',
      email: 'budi@resto.test',
      peran: 'kasir',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Utama',
      aktif: true,
      dibuatPada: '2026-09-01',
    },
    {
      id: 'usr-02',
      nama: 'Rudi Tabuti',
      email: 'rudi@resto.test',
      peran: 'dapur',
      cabangId: 'cab-01',
      namaCabang: 'Cabang Utama',
      aktif: false,
      dibuatPada: '2026-08-15',
    },
  ]

  it('merender daftar pegawai resto dengan nama, peran, dan status', () => {
    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        onTambahPegawai={vi.fn()}
        onUbahStatusPegawai={vi.fn()}
        onAturUlangPin={vi.fn()}
      />,
    )

    expect(screen.getByText('Budi Santoso')).toBeDefined()
    expect(screen.getByText('budi@resto.test')).toBeDefined()
    expect(screen.getByText('Rudi Tabuti')).toBeDefined()
    expect(screen.getByText('Aktif')).toBeDefined()
    expect(screen.getByText('Nonaktif')).toBeDefined()
  })

  it('membuka modal tambah pegawai dan memproses form pembuatan akun baru', async () => {
    const onTambahMock = vi.fn().mockResolvedValue({ sukses: true, pegawaiId: 'usr-99' })

    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        namaCabangAktif="Cabang Pusat"
        onTambahPegawai={onTambahMock}
        onUbahStatusPegawai={vi.fn()}
        onAturUlangPin={vi.fn()}
      />,
    )

    // Klik tombol tambah
    fireEvent.click(screen.getByRole('button', { name: /\+ Tambah Pegawai Baru/i }))

    // Modal muncul
    expect(screen.getByText('Tambah Akun Pegawai Baru')).toBeDefined()

    // Isi formulir
    fireEvent.change(screen.getByLabelText(/Nama Lengkap/i), { target: { value: 'Dewi Sartika' } })
    fireEvent.change(screen.getByLabelText(/Alamat Email/i), {
      target: { value: 'dewi@barokah.id' },
    })
    fireEvent.change(screen.getByLabelText(/PIN Awal/i), { target: { value: '654321' } })

    // Submit
    fireEvent.click(screen.getByRole('button', { name: /Simpan Pegawai/i }))

    await waitFor(() => {
      expect(onTambahMock).toHaveBeenCalledWith({
        nama: 'Dewi Sartika',
        email: 'dewi@barokah.id',
        peran: 'kasir',
        cabangId: 'cab-01',
        pinAwal: '654321',
      })
      expect(screen.getByText('Dewi Sartika')).toBeDefined()
    })
  })

  it('mengubah status aktif/nonaktif pegawai saat tombol diklik (soft-disable ART-2)', async () => {
    const onUbahStatusMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        onTambahPegawai={vi.fn()}
        onUbahStatusPegawai={onUbahStatusMock}
        onAturUlangPin={vi.fn()}
      />,
    )

    // Klik tombol Nonaktifkan untuk Budi Santoso
    const tombolNonaktif = screen.getByRole('button', { name: /Nonaktifkan/i })
    fireEvent.click(tombolNonaktif)

    await waitFor(() => {
      expect(onUbahStatusMock).toHaveBeenCalledWith('usr-01', false)
    })
  })

  it('dapat membuka modal Hak Akses & Izin dan menyimpan konfigurasi izin', async () => {
    const onSimpanIzinMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        onSimpanIzin={onSimpanIzinMock}
      />,
    )

    // Buka modal hak akses untuk Budi Santoso
    const tombolHakAkses = screen.getAllByRole('button', { name: /Hak Akses/i })[0]
    fireEvent.click(tombolHakAkses)

    expect(screen.getByText(/Hak Akses & Izin: Budi Santoso/i)).toBeDefined()
    expect(screen.getByText(/beri_diskon/i)).toBeDefined()
    expect(screen.getByText(/lihat_laporan/i)).toBeDefined()

    // Klik simpan hak akses
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Hak Akses/i })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(onSimpanIzinMock).toHaveBeenCalled()
    })
  })

  it('dapat membuka modal Reset PIN dan mengirimkan PIN baru 6 angka', async () => {
    const onResetPinMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        onAturUlangPin={onResetPinMock}
      />,
    )

    // Buka modal reset PIN untuk Budi Santoso
    const tombolReset = screen.getAllByRole('button', { name: /Reset PIN/i })[0]
    fireEvent.click(tombolReset)

    expect(screen.getByText(/Reset PIN: Budi Santoso/i)).toBeDefined()

    // Isi PIN baru 6 digit
    const inputPin = screen.getByLabelText(/PIN Baru \(6 Angka\)/i)
    fireEvent.change(inputPin, { target: { value: '987321' } })

    // Klik tombol simpan PIN
    const tombolSimpanPin = screen.getByRole('button', { name: /Simpan PIN Baru/i })
    fireEvent.click(tombolSimpanPin)

    await waitFor(() => {
      expect(onResetPinMock).toHaveBeenCalledWith('usr-01', '987321')
    })
  })

  it('dapat memfilter daftar pegawai berdasarkan teks pencarian', () => {
    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
      />,
    )

    const inputCari = screen.getByPlaceholderText(/Cari nama atau email pegawai/i)
    fireEvent.change(inputCari, { target: { value: 'Rudi' } })

    expect(screen.getByText('Rudi Tabuti')).toBeDefined()
    expect(screen.queryByText('Budi Santoso')).toBeNull()
  })

  it('dapat membuka modal Edit pegawai dan mengubah nama/email/peran', async () => {
    const onUbahPegawaiMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <KelolaPegawai
        daftarPegawai={daftarContoh}
        cabangAktifId="cab-01"
        onUbahPegawai={onUbahPegawaiMock}
      />,
    )

    // Klik edit untuk Budi Santoso
    const tombolEdit = screen.getAllByRole('button', { name: /Edit/i })[0]
    fireEvent.click(tombolEdit)

    expect(screen.getByText(/Edit Profil: Budi Santoso/i)).toBeDefined()

    // Ubah nama
    const inputNama = screen.getByLabelText(/Nama Lengkap/i)
    fireEvent.change(inputNama, { target: { value: 'Budi Santoso SPv' } })

    // Klik simpan
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Pegawai/i })
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(onUbahPegawaiMock).toHaveBeenCalledWith({
        id: 'usr-01',
        nama: 'Budi Santoso SPv',
        email: 'budi@resto.test',
        peran: 'kasir',
        cabangId: 'cab-01',
      })
    })
  })
})
