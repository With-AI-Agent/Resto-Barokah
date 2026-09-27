// @vitest-environment jsdom
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { StatusPemakaian, type DataStatusPemakaian } from './StatusPemakaian'

describe('StatusPemakaian (T11-08 / K6)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('menampilkan seluruh 4 dimensi kuota gratis dan status aman bawaan', () => {
    render(<StatusPemakaian />)

    expect(screen.getByText('Status Batas Gratis & Kapasitas (K6)')).toBeDefined()
    expect(screen.getByText('AMAN (BIAYA RP 0)')).toBeDefined()
    expect(screen.getByText('Basis Data PostgreSQL (Supabase)')).toBeDefined()
    expect(screen.getByText('Penyimpanan Foto Menu (Storage)')).toBeDefined()
    expect(screen.getByText('Lalu Lintas Jaringan / Egress')).toBeDefined()
    expect(screen.getByText('Email Transaksional (Brevo/Resend)')).toBeDefined()
    expect(screen.getByText(/Hari ke-1/)).toBeDefined()
  })

  it('menampilkan peringatan waspada (70%) bila kuota mendekati batas', () => {
    const dataWaspada: DataStatusPemakaian = {
      waktuTerakhirDiperiksa: '2026-09-27T09:00:00Z',
      basisData: {
        judul: 'Basis Data PostgreSQL (Supabase)',
        pemakaian: 375.0, // 75%
        batas: 500.0,
        satuan: 'MB',
        keterangan: 'Menyimpan transaksi',
      },
      penyimpananFoto: {
        judul: 'Penyimpanan Foto Menu (Storage)',
        pemakaian: 1.0,
        batas: 1024.0,
        satuan: 'MB',
        keterangan: 'Foto menu',
      },
      laluLintas: {
        judul: 'Lalu Lintas Jaringan / Egress',
        pemakaian: 100.0,
        batas: 5120.0,
        satuan: 'MB',
        keterangan: 'Lalu lintas',
      },
      email: {
        judul: 'Email Transaksional (Brevo/Resend)',
        pemakaian: 50,
        batas: 3000,
        satuan: 'email',
        keterangan: 'Email',
      },
      denyutHarianHari: 1,
    }

    render(<StatusPemakaian dataAwal={dataWaspada} />)
    expect(screen.getByText('WASPADA (≥ 70%)')).toBeDefined()
    expect(screen.getByText('75%')).toBeDefined()
  })

  it('menampilkan peringatan bahaya (90%) bila kuota kritis', () => {
    const dataBahaya: DataStatusPemakaian = {
      waktuTerakhirDiperiksa: '2026-09-27T09:00:00Z',
      basisData: {
        judul: 'Basis Data PostgreSQL (Supabase)',
        pemakaian: 460.0, // 92%
        batas: 500.0,
        satuan: 'MB',
        keterangan: 'Menyimpan transaksi',
      },
      penyimpananFoto: {
        judul: 'Penyimpanan Foto Menu (Storage)',
        pemakaian: 1.0,
        batas: 1024.0,
        satuan: 'MB',
        keterangan: 'Foto menu',
      },
      laluLintas: {
        judul: 'Lalu Lintas Jaringan / Egress',
        pemakaian: 100.0,
        batas: 5120.0,
        satuan: 'MB',
        keterangan: 'Lalu lintas',
      },
      email: {
        judul: 'Email Transaksional (Brevo/Resend)',
        pemakaian: 50,
        batas: 3000,
        satuan: 'email',
        keterangan: 'Email',
      },
      denyutHarianHari: 1,
    }

    render(<StatusPemakaian dataAwal={dataBahaya} />)
    expect(screen.getByText('PERINGATAN DARURAT (≥ 90%)')).toBeDefined()
    expect(screen.getByText('92%')).toBeDefined()
  })

  it('memanggil fungsi onSegarkan saat tombol Periksa Ulang ditekan', async () => {
    const onSegarkanMock = vi.fn().mockResolvedValue({
      waktuTerakhirDiperiksa: '2026-09-27T10:00:00Z',
      basisData: {
        judul: 'Basis Data PostgreSQL (Supabase)',
        pemakaian: 40.0,
        batas: 500.0,
        satuan: 'MB',
        keterangan: 'Menyimpan transaksi',
      },
      penyimpananFoto: {
        judul: 'Penyimpanan Foto Menu (Storage)',
        pemakaian: 2.0,
        batas: 1024.0,
        satuan: 'MB',
        keterangan: 'Foto menu',
      },
      laluLintas: {
        judul: 'Lalu Lintas Jaringan / Egress',
        pemakaian: 200.0,
        batas: 5120.0,
        satuan: 'MB',
        keterangan: 'Lalu lintas',
      },
      email: {
        judul: 'Email Transaksional (Brevo/Resend)',
        pemakaian: 100,
        batas: 3000,
        satuan: 'email',
        keterangan: 'Email',
      },
      denyutHarianHari: 1,
    })

    render(<StatusPemakaian onSegarkan={onSegarkanMock} />)
    const tombolPeriksa = screen.getByRole('button', { name: /periksa ulang/i })
    fireEvent.click(tombolPeriksa)

    await waitFor(() => {
      expect(onSegarkanMock).toHaveBeenCalledTimes(1)
      expect(screen.getByText('Status pemakaian berhasil diperbarui!')).toBeDefined()
    })
  })
})
