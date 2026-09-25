// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { Daftar, type KampanyeInfo } from './Daftar'

const CONTOH_KAMPANYE: KampanyeInfo = {
  id: 'kmp-01',
  nama: 'Promo Sambut Sahabat Baru',
  deskripsi: 'Potongan harga khusus pelanggan baru Resto Barokah.',
  jenis: 'nominal',
  nilai: 20000,
  min_belanja: 50000,
  selesai: '2026-10-15T23:59:59Z',
  nama_resto: 'Resto Barokah',
}

describe('Komponen Formulir Pendaftaran Voucher (Daftar.tsx — T8-06)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
  })

  afterEach(() => {
    cleanup()
  })

  it('merender kolom isian pendaftaran dan penawaran voucher promo', () => {
    render(<Daftar kampanye={CONTOH_KAMPANYE} />)

    expect(screen.getByText('Klaim Voucher: Promo Sambut Sahabat Baru')).toBeDefined()
    expect(screen.getByText('Potongan Langsung Rp20.000')).toBeDefined()
    expect(screen.getByPlaceholderText(/Contoh: Rian Anggoro/i)).toBeDefined()
    expect(screen.getByPlaceholderText(/nama@email.com/i)).toBeDefined()
    expect(screen.getByPlaceholderText(/081234567890/i)).toBeDefined()
    expect(screen.getByTestId('centang-privasi-voucher')).toBeDefined()

    // Bantuan ramah kasir muncul
    expect(screen.getByTestId('bantuan-kasir-info')).toBeDefined()
    expect(screen.getByTestId('bantuan-kasir-info').textContent).toContain(
      'Tidak memiliki email atau kesulitan verifikasi?',
    )
  })

  it('menolak klaim jika nama belum diisi atau privasi belum disetujui', () => {
    render(<Daftar kampanye={CONTOH_KAMPANYE} />)

    const tombolGoogle = screen.getByRole('button', { name: /klaim voucher cepat dengan google/i })
    fireEvent.click(tombolGoogle)

    // Muncul alert pesan galat nama wajib diisi
    expect(screen.getByRole('alert').textContent).toContain('Nama lengkap wajib diisi.')

    // Isi nama tapi belum centang privasi
    const inputNama = screen.getByPlaceholderText(/Contoh: Rian Anggoro/i)
    fireEvent.change(inputNama, { target: { value: 'Budi Santoso' } })
    fireEvent.click(tombolGoogle)

    expect(screen.getByRole('alert').textContent).toContain(
      'Mohon centang persetujuan kebijakan privasi',
    )
  })

  it('alur verifikasi Jalur 1 (Google OAuth): berhasil klaim dan menampilkan kartu voucher terbit', async () => {
    const mockGoogle = vi.fn().mockResolvedValue({ sukses: true })
    const mockSukses = vi.fn()

    render(
      <Daftar kampanye={CONTOH_KAMPANYE} onMasukGoogle={mockGoogle} onKlaimSukses={mockSukses} />,
    )

    // Isi form
    fireEvent.change(screen.getByPlaceholderText(/Contoh: Rian Anggoro/i), {
      target: { value: 'Budi Santoso' },
    })
    fireEvent.click(screen.getByTestId('centang-privasi-voucher'))

    // Klik klaim dengan Google
    const tombolGoogle = screen.getByRole('button', { name: /klaim voucher cepat dengan google/i })
    fireEvent.click(tombolGoogle)

    await waitFor(() => {
      expect(mockGoogle).toHaveBeenCalledTimes(1)
      expect(mockSukses).toHaveBeenCalledTimes(1)
      expect(screen.getByTestId('klaim-voucher-sukses')).toBeDefined()
      expect(screen.getByTestId('kartu-voucher-terbit')).toBeDefined()
      expect(screen.getByTestId('teks-kode-voucher').textContent).toMatch(/^BRK-[A-Z0-9]{6}$/)
      expect(screen.getByText('Potongan Rp20.000')).toBeDefined()
    })
  })

  it('alur verifikasi Jalur 2 (Email Magic Link): berhasil klaim dan mengirimkan kode', async () => {
    const mockEmail = vi.fn().mockResolvedValue({ sukses: true })
    const mockSukses = vi.fn()

    render(
      <Daftar kampanye={CONTOH_KAMPANYE} onKirimEmail={mockEmail} onKlaimSukses={mockSukses} />,
    )

    // Isi form
    fireEvent.change(screen.getByPlaceholderText(/Contoh: Rian Anggoro/i), {
      target: { value: 'Siti Rahma' },
    })
    fireEvent.change(screen.getByPlaceholderText(/nama@email.com/i), {
      target: { value: 'siti.rahma@contoh.id' },
    })
    fireEvent.click(screen.getByTestId('centang-privasi-voucher'))

    // Klik klaim lewat email
    const tombolEmail = screen.getByRole('button', { name: /klaim voucher lewat email/i })
    fireEvent.click(tombolEmail)

    await waitFor(() => {
      expect(mockEmail).toHaveBeenCalledWith('siti.rahma@contoh.id')
      expect(mockSukses).toHaveBeenCalledTimes(1)
      const kartuSukses = screen.getByTestId('klaim-voucher-sukses')
      expect(kartuSukses).toBeDefined()
      expect(kartuSukses.textContent).toContain('Siti Rahma')
      expect(kartuSukses.textContent).toContain('Terima kasih')
    })
  })

  it('dapat menyalin kode voucher yang berhasil diterbitkan ke clipboard', async () => {
    const mockGoogle = vi.fn().mockResolvedValue({ sukses: true })

    render(<Daftar kampanye={CONTOH_KAMPANYE} onMasukGoogle={mockGoogle} />)

    fireEvent.change(screen.getByPlaceholderText(/Contoh: Rian Anggoro/i), {
      target: { value: 'Ahmad Dahlan' },
    })
    fireEvent.click(screen.getByTestId('centang-privasi-voucher'))
    fireEvent.click(screen.getByRole('button', { name: /klaim voucher cepat dengan google/i }))

    await waitFor(() => {
      expect(screen.getByTestId('klaim-voucher-sukses')).toBeDefined()
    })

    const tombolSalin = screen.getByRole('button', { name: /salin kode voucher pelanggan/i })
    fireEvent.click(tombolSalin)

    await waitFor(() => {
      expect(navigator.clipboard.writeText).toHaveBeenCalled()
      expect(screen.getByText('✓ Kode Tersalin!')).toBeDefined()
    })
  })

  it('menolak klaim jika menggunakan email sekali-pakai (T8-07)', async () => {
    render(<Daftar kampanye={CONTOH_KAMPANYE} />)

    fireEvent.change(screen.getByPlaceholderText(/Contoh: Rian Anggoro/i), {
      target: { value: 'Budi Santoso' },
    })
    fireEvent.change(screen.getByPlaceholderText(/nama@email.com/i), {
      target: { value: 'budi@tempmail.com' },
    })
    fireEvent.click(screen.getByTestId('centang-privasi-voucher'))

    const tombolEmail = screen.getByRole('button', { name: /klaim voucher lewat email/i })
    fireEvent.click(tombolEmail)

    expect(screen.getByRole('alert').textContent).toMatch(
      /Email sementara atau sekali-pakai tidak diizinkan/i,
    )
  })
})
