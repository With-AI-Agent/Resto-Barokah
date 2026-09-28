// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { KebijakanPrivasi } from './KebijakanPrivasi'

describe('KebijakanPrivasi (T8-15 / UU PDP)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender judul kebijakan privasi dan nama resto default', () => {
    render(<KebijakanPrivasi />)

    expect(screen.getByRole('heading', { name: /Kebijakan Privasi/i })).toBeDefined()
    expect(screen.getByText(/Pelindungan Data Pribadi Pelanggan Resto Barokah/i)).toBeDefined()
    expect(screen.getByText(/Versi 1.0 \(September 2026\)/i)).toBeDefined()
  })

  it('merender dengan nama resto kustom dan ringkasan komitmen UU PDP', () => {
    render(<KebijakanPrivasi namaResto="Kedai Oasis Bandung" />)

    expect(
      screen.getByText(/Pelindungan Data Pribadi Pelanggan Kedai Oasis Bandung/i),
    ).toBeDefined()
    const ringkasan = screen.getByTestId('ringkasan-privasi')
    expect(ringkasan.textContent).toContain('UU PDP No. 27/2022')
    expect(ringkasan.textContent).toContain('Kedai Oasis Bandung')
  })

  it('menjelaskan prinsip minimalisasi data dan larangan NIK/biometrik', () => {
    render(<KebijakanPrivasi />)

    expect(screen.getAllByText(/Nama Lengkap \(Wajib\)/i).length).toBeGreaterThan(0)
    expect(
      screen.getAllByText(/Alamat Email \(Wajib untuk jalur email\/Google\)/i).length,
    ).toBeGreaterThan(0)
    expect(screen.getAllByText(/Nomor Telepon \/ WhatsApp \(Opsional\)/i).length).toBeGreaterThan(0)
    expect(screen.getByText(/Nomor Induk Kependudukan \(NIK\)/i)).toBeDefined()
  })

  it('menjelaskan hak subjek data termasuk anonimisasi dan waktu tanggap 3x24 jam', () => {
    render(<KebijakanPrivasi />)

    expect(screen.getAllByText(/Hak Akses/i).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Hak Koreksi/i).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Hak Penghapusan \/ Anonimisasi/i).length).toBeGreaterThan(0)
    expect(screen.getByText(/3 × 24 jam/i)).toBeDefined()
    expect(
      screen.getByText(/Catatan nilai nominal transaksi resto tetap tersimpan utuh/i),
    ).toBeDefined()
  })

  it('menampilkan kontak resto jika disediakan', () => {
    render(
      <KebijakanPrivasi
        kontakResto={{
          telepon: '0812-9988-7766',
          email: 'privasi@kedaioasis.test',
        }}
      />,
    )

    expect(screen.getByText('0812-9988-7766')).toBeDefined()
    expect(screen.getByText('privasi@kedaioasis.test')).toBeDefined()
  })

  it('memanggil fungsi onKembali saat tombol kembali diklik', () => {
    const onKembaliMock = vi.fn()
    render(<KebijakanPrivasi onKembali={onKembaliMock} />)

    const tombolKembaliAtas = screen.getByRole('button', { name: /Kembali ke halaman sebelumnya/i })
    fireEvent.click(tombolKembaliAtas)
    expect(onKembaliMock).toHaveBeenCalledTimes(1)

    const tombolKembaliBawah = screen.getByRole('button', {
      name: /Tutup kebijakan privasi dan kembali/i,
    })
    fireEvent.click(tombolKembaliBawah)
    expect(onKembaliMock).toHaveBeenCalledTimes(2)
  })
})
