// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { KelolaPegawai, type PegawaiResto } from './KelolaPegawai'

describe('KelolaPegawai (T2-03)', () => {
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

  it('mengubah status aktif/nonaktif pegawai saat tombol diklik', async () => {
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
})
