// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarPenyewaPlatform, type PenyewaItem } from './Penyewa'

describe('LayarPenyewaPlatform (T9-10 / PRD M1 / ART-1)', () => {
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  const daftarContoh: PenyewaItem[] = [
    {
      id: '11111111-1111-1111-1111-111111111111',
      nama: 'Kedai Oasis',
      slug: 'kedai-oasis',
      status: 'aktif',
      zona_waktu: 'Asia/Jakarta',
      mata_uang: 'IDR',
      kontak_telepon: '081234567890',
      kontak_email: 'halo@kedai-oasis.test',
      dibuat_pada: '2026-09-01T08:00:00Z',
      jumlah_cabang: 2,
      owner_nama: 'Bu Oasis',
      owner_email: 'owner.a@contoh.test',
    },
    {
      id: '22222222-2222-2222-2222-222222222222',
      nama: 'Warung Bandung',
      slug: 'warung-bandung',
      status: 'nonaktif',
      zona_waktu: 'Asia/Jakarta',
      mata_uang: 'IDR',
      kontak_telepon: '082198765432',
      kontak_email: 'admin@warungbandung.test',
      dibuat_pada: '2026-09-10T09:30:00Z',
      jumlah_cabang: 1,
      owner_nama: 'Pak Jajang',
      owner_email: 'owner.b@contoh.test',
    },
  ]

  it('merender daftar resto penyewa dengan ringkasan statistik dan informasi cabang', () => {
    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} />)

    expect(screen.getByText('Kelola Resto Penyewa')).toBeDefined()
    expect(screen.getByText('Pemilik Platform')).toBeDefined()
    expect(screen.getByText('Kedai Oasis')).toBeDefined()
    expect(screen.getByText('Warung Bandung')).toBeDefined()
    expect(screen.getByText('/kedai-oasis')).toBeDefined()
    expect(screen.getByText('/warung-bandung')).toBeDefined()
    expect(screen.getByText('Aktif')).toBeDefined()
    expect(screen.getByText('Nonaktif')).toBeDefined()
    expect(screen.getByText('Total Restoran')).toBeDefined()
    expect(screen.getByText('Total Seluruh Cabang')).toBeDefined()
  })

  it('dapat menyaring resto berdasarkan kata kunci pencarian dan status', () => {
    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} />)

    const inputCari = screen.getByPlaceholderText(/mis\. Oasis atau bandung/i)
    fireEvent.change(inputCari, { target: { value: 'Bandung' } })

    expect(screen.queryByText('Kedai Oasis')).toBeNull()
    expect(screen.getByText('Warung Bandung')).toBeDefined()

    // Reset pencarian & klik filter Aktif
    fireEvent.change(inputCari, { target: { value: '' } })
    const tombolAktif = screen.getByRole('button', { name: /^Aktif \(/i })
    fireEvent.click(tombolAktif)

    expect(screen.getByText('Kedai Oasis')).toBeDefined()
    expect(screen.queryByText('Warung Bandung')).toBeNull()
  })

  it('membuka modal pendaftaran penyewa baru dan memproses pendaftaran sukses', async () => {
    const onSimpanMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Restoran baru berhasil didaftarkan.',
    })

    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} onSimpanPenyewa={onSimpanMock} />)

    // Klik tombol tambah
    fireEvent.click(screen.getByRole('button', { name: /➕ Tambah Penyewa Baru/i }))

    expect(screen.getByText('Daftarkan Restoran / Penyewa Baru')).toBeDefined()

    // Isi formulir
    const inputNamaResto = screen.getByPlaceholderText(/mis\. Resto Sederhana Barokah/i)
    fireEvent.change(inputNamaResto, { target: { value: 'Resto Berkah Abadi' } })

    const inputOwnerNama = screen.getByPlaceholderText(/Budi Santoso/i)
    fireEvent.change(inputOwnerNama, { target: { value: 'Haji Ahmad' } })

    const inputOwnerEmail = screen.getByPlaceholderText(/budi\.owner@resto\.test/i)
    fireEvent.change(inputOwnerEmail, { target: { value: 'ahmad@resto.test' } })

    const inputOwnerPin = screen.getByPlaceholderText(/mis\. 741852/i)
    fireEvent.change(inputOwnerPin, { target: { value: '852963' } })

    // Klik tombol simpan
    fireEvent.click(screen.getByRole('button', { name: /Daftarkan Resto/i }))

    await waitFor(() => {
      expect(onSimpanMock).toHaveBeenCalledWith(
        expect.objectContaining({
          nama: 'Resto Berkah Abadi',
          slug: 'resto-berkah-abadi',
          owner_nama: 'Haji Ahmad',
          owner_email: 'ahmad@resto.test',
          owner_pin: '852963',
        }),
      )
    })

    expect(screen.getByText(/Restoran baru berhasil didaftarkan/i)).toBeDefined()
  })

  it('menolak submit formulir jika validasi masukan tidak lengkap atau PIN tidak 6 digit', async () => {
    const onSimpanMock = vi.fn()

    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} onSimpanPenyewa={onSimpanMock} />)

    fireEvent.click(screen.getByRole('button', { name: /➕ Tambah Penyewa Baru/i }))

    // Langsung klik simpan tanpa isi
    fireEvent.click(screen.getByRole('button', { name: /Daftarkan Resto/i }))
    expect(screen.getByText(/Nama restoran wajib diisi/i)).toBeDefined()
    expect(onSimpanMock).not.toHaveBeenCalled()

    // Isi nama resto tapi tanpa owner
    const inputNamaResto = screen.getByPlaceholderText(/mis\. Resto Sederhana Barokah/i)
    fireEvent.change(inputNamaResto, { target: { value: 'Resto Enak' } })
    fireEvent.click(screen.getByRole('button', { name: /Daftarkan Resto/i }))
    expect(screen.getByText(/Nama Owner pertama wajib diisi/i)).toBeDefined()

    // Isi owner nama tapi email salah
    const inputOwnerNama = screen.getByPlaceholderText(/Budi Santoso/i)
    fireEvent.change(inputOwnerNama, { target: { value: 'Bambang' } })
    const inputOwnerEmail = screen.getByPlaceholderText(/budi\.owner@resto\.test/i)
    fireEvent.change(inputOwnerEmail, { target: { value: 'bambang-tanpa-domain' } })
    fireEvent.click(screen.getByRole('button', { name: /Daftarkan Resto/i }))
    expect(screen.getByText(/Email Owner pertama tidak valid/i)).toBeDefined()

    // Email valid tapi PIN kurang dari 6 digit
    fireEvent.change(inputOwnerEmail, { target: { value: 'bambang@contoh.test' } })
    const inputOwnerPin = screen.getByPlaceholderText(/mis\. 741852/i)
    fireEvent.change(inputOwnerPin, { target: { value: '1234' } })
    fireEvent.click(screen.getByRole('button', { name: /Daftarkan Resto/i }))
    expect(screen.getByText(/PIN Owner wajib 6 digit angka/i)).toBeDefined()
  })

  it('membuka modal penonaktifan penyewa, mewajibkan alasan, dan memproses pembekuan akun', async () => {
    const onSetStatusMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Penyewa berhasil dinonaktifkan.',
    })

    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} onSetStatusPenyewa={onSetStatusMock} />)

    // Klik tombol nonaktifkan untuk Kedai Oasis
    const tombolNonaktif = screen.getByRole('button', { name: /⏸️ Nonaktifkan/i })
    fireEvent.click(tombolNonaktif)

    expect(screen.getByText(/Nonaktifkan Penyewa: Kedai Oasis/i)).toBeDefined()
    expect(screen.getByText(/Keamanan Data Terjamin/i)).toBeDefined()

    // Klik simpan tanpa alasan
    fireEvent.click(screen.getByRole('button', { name: /Konfirmasi Nonaktifkan/i }))
    expect(screen.getByText(/Alasan penonaktifan wajib diisi minimal 5 karakter/i)).toBeDefined()
    expect(onSetStatusMock).not.toHaveBeenCalled()

    // Isi alasan valid
    const inputAlasan = screen.getByPlaceholderText(/mis\. Langganan expired atau permintaan pemilik/i)
    fireEvent.change(inputAlasan, { target: { value: 'Masa uji coba selesai' } })

    fireEvent.click(screen.getByRole('button', { name: /Konfirmasi Nonaktifkan/i }))

    await waitFor(() => {
      expect(onSetStatusMock).toHaveBeenCalledWith(
        '11111111-1111-1111-1111-111111111111',
        'nonaktif',
        'Masa uji coba selesai',
      )
    })
  })

  it('dapat mengaktifkan kembali penyewa yang sebelumnya nonaktif', async () => {
    const onSetStatusMock = vi.fn().mockResolvedValue({
      berhasil: true,
      pesan: 'Penyewa berhasil diaktifkan kembali.',
    })

    render(<LayarPenyewaPlatform daftarAwal={daftarContoh} onSetStatusPenyewa={onSetStatusMock} />)

    // Warung Bandung sedang nonaktif -> ada tombol Aktifkan Kembali
    const tombolAktifkan = screen.getByRole('button', { name: /▶️ Aktifkan Kembali/i })
    fireEvent.click(tombolAktifkan)

    await waitFor(() => {
      expect(onSetStatusMock).toHaveBeenCalledWith('22222222-2222-2222-2222-222222222222', 'aktif')
    })
  })
})
