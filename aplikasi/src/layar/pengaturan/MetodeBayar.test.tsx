// @vitest-environment jsdom
import { render, screen, fireEvent, cleanup, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { MetodeBayar, type ItemMetodeBayar } from './MetodeBayar'

const DATA_METODE_UJI: ItemMetodeBayar[] = [
  { id: 'm1', nama: 'Tunai', jenis: 'tunai', butuh_referensi: false, aktif: true, urutan: 1 },
  { id: 'm2', nama: 'QRIS', jenis: 'non_tunai', butuh_referensi: true, aktif: true, urutan: 2 },
  { id: 'm3', nama: 'Transfer Bank', jenis: 'non_tunai', butuh_referensi: true, aktif: false, urutan: 3 },
]

describe('MetodeBayar (Pengaturan Metode Pembayaran & Tip — PRD M2 / T9-07)', () => {
  afterEach(() => {
    cleanup()
    vi.clearAllMocks()
  })

  it('merender daftar metode pembayaran awal dan seksi aturan tip dengan benar', () => {
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} />)

    expect(screen.getByTestId('pengaturan-metode-bayar')).toBeDefined()
    expect(screen.getByText('Metode Pembayaran & Aturan Tip')).toBeDefined()
    expect(screen.getByText('Daftar Metode Pembayaran Aktif')).toBeDefined()
    expect(screen.getByText('Aturan Tip Pelanggan')).toBeDefined()

    // Memeriksa baris tabel
    expect(screen.getAllByText('Tunai').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('QRIS')).toBeDefined()
    expect(screen.getByText('Transfer Bank')).toBeDefined()

    // Memeriksa lencana jenis & status
    expect(screen.getByText('Tidak Butuh')).toBeDefined()
    expect(screen.getAllByText('Wajib Diisi').length).toBe(2)
  })

  it('dapat mengaktifkan dan menonaktifkan metode pembayaran', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onSimpanMetode={mockSimpan} />)

    // Tombol nonaktifkan QRIS
    const tombolNonaktifkan = screen.getByRole('button', { name: /ubah status qris/i })
    fireEvent.click(tombolNonaktifkan)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'm2',
          nama: 'QRIS',
          aktif: false,
        }),
      )
    })
  })

  it('menolak menonaktifkan satu-satunya metode pembayaran yang aktif', async () => {
    const satuMetodeAktif: ItemMetodeBayar[] = [
      { id: 'm1', nama: 'Tunai', jenis: 'tunai', butuh_referensi: false, aktif: true, urutan: 1 },
      { id: 'm2', nama: 'QRIS', jenis: 'non_tunai', butuh_referensi: true, aktif: false, urutan: 2 },
    ]
    const mockSimpan = vi.fn()
    render(<MetodeBayar daftarMetodeAwal={satuMetodeAktif} onSimpanMetode={mockSimpan} />)

    const tombolMatikan = screen.getByRole('button', { name: /ubah status tunai/i })
    fireEvent.click(tombolMatikan)

    expect(screen.getByText(/Minimal harus ada satu metode pembayaran yang aktif/i)).toBeDefined()
    expect(mockSimpan).not.toHaveBeenCalled()
  })

  it('dapat membuka modal dan menambah metode pembayaran baru', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onSimpanMetode={mockSimpan} />)

    // Klik tombol tambah metode
    const tombolTambah = screen.getByRole('button', { name: /tambah metode pembayaran baru/i })
    fireEvent.click(tombolTambah)

    // Modal terbuka
    expect(screen.getByText('Tambah Metode Pembayaran Baru')).toBeDefined()

    // Isi nama metode
    const inputNama = screen.getByPlaceholderText(/Misal: QRIS BCA/i)
    fireEvent.change(inputNama, { target: { value: 'GoPay Dinamis' } })

    // Klik simpan
    const tombolKonfirmasi = screen.getByRole('button', { name: /konfirmasi simpan metode/i })
    fireEvent.click(tombolKonfirmasi)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith(
        expect.objectContaining({
          nama: 'GoPay Dinamis',
          jenis: 'non_tunai',
          butuh_referensi: true,
          aktif: true,
        }),
      )
    })
  })

  it('menolak penambahan metode bayar dengan nama kembar', async () => {
    const mockSimpan = vi.fn()
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onSimpanMetode={mockSimpan} />)

    const tombolTambah = screen.getByRole('button', { name: /tambah metode pembayaran baru/i })
    fireEvent.click(tombolTambah)

    const inputNama = screen.getByPlaceholderText(/Misal: QRIS BCA/i)
    fireEvent.change(inputNama, { target: { value: 'tunai' } }) // kembar dengan huruf kecil

    const tombolKonfirmasi = screen.getByRole('button', { name: /konfirmasi simpan metode/i })
    fireEvent.click(tombolKonfirmasi)

    expect(screen.getByText(/Metode pembayaran dengan nama "tunai" sudah terdaftar/i)).toBeDefined()
    expect(mockSimpan).not.toHaveBeenCalled()
  })

  it('dapat membuka modal edit dan mengubah data metode bayar', async () => {
    const mockSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onSimpanMetode={mockSimpan} />)

    const tombolEdit = screen.getByRole('button', { name: /edit qris/i })
    fireEvent.click(tombolEdit)

    expect(screen.getByText('Edit Metode Pembayaran')).toBeDefined()

    const inputNama = screen.getByDisplayValue('QRIS')
    fireEvent.change(inputNama, { target: { value: 'QRIS All Payment' } })

    const tombolKonfirmasi = screen.getByRole('button', { name: /konfirmasi simpan metode/i })
    fireEvent.click(tombolKonfirmasi)

    await waitFor(() => {
      expect(mockSimpan).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'm2',
          nama: 'QRIS All Payment',
        }),
      )
    })
  })

  it('dapat menggeser urutan metode pembayaran ke atas dan ke bawah', async () => {
    const mockUrutan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onSimpanUrutanMetode={mockUrutan} />)

    // Baris ke-2 (QRIS) digeser naik
    const tombolNaikQris = screen.getByRole('button', { name: /geser naik qris/i })
    fireEvent.click(tombolNaikQris)

    await waitFor(() => {
      expect(mockUrutan).toHaveBeenCalledWith([
        { id: 'm2', urutan: 1 },
        { id: 'm1', urutan: 2 },
        { id: 'm3', urutan: 3 },
      ])
    })
  })

  it('dapat membuka modal konfirmasi dan menghapus metode pembayaran', async () => {
    const mockHapus = vi.fn().mockResolvedValue({ berhasil: true })
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} onHapusMetode={mockHapus} />)

    const tombolHapus = screen.getByRole('button', { name: /hapus transfer bank/i })
    fireEvent.click(tombolHapus)

    expect(screen.getByText('Hapus Metode Pembayaran')).toBeDefined()
    expect(screen.getByText(/Apakah Anda yakin ingin menghapus metode pembayaran/i)).toBeDefined()

    const tombolKonfirmasiHapus = screen.getByRole('button', { name: /konfirmasi hapus metode/i })
    fireEvent.click(tombolKonfirmasiHapus)

    await waitFor(() => {
      expect(mockHapus).toHaveBeenCalledWith('m3')
    })
  })

  it('dapat mengaktifkan fitur tip dan menyimpan pengaturan tip restoran', async () => {
    const mockSimpanTip = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <MetodeBayar
        daftarMetodeAwal={DATA_METODE_UJI}
        aturanTipAwal={{ izinkan_tip: false, cara_hitung_tip: 'sukarela' }}
        onSimpanAturanTip={mockSimpanTip}
      />,
    )

    // Centang izinkan tip
    const cekIzinkan = screen.getByLabelText(/Bolehkan Pelanggan Memberikan Tip/i)
    fireEvent.click(cekIzinkan)

    // Pilih model rekomendasi persen
    const radioPersen = screen.getByLabelText(/Pilihan Persentase/i)
    fireEvent.click(radioPersen)

    // Ubah daftar persen
    const inputPersen = screen.getByDisplayValue('5, 10, 15')
    fireEvent.change(inputPersen, { target: { value: '5, 10, 20' } })

    // Klik simpan aturan tip
    const tombolSimpanTip = screen.getByRole('button', { name: /simpan seluruh konfigurasi aturan tip/i })
    fireEvent.click(tombolSimpanTip)

    await waitFor(() => {
      expect(mockSimpanTip).toHaveBeenCalledWith(
        expect.objectContaining({
          izinkan_tip: true,
          cara_hitung_tip: 'persen',
          pilihan_tip_persen: [5, 10, 20],
        }),
      )
    })
  })

  it('menonaktifkan seluruh tombol aksi dan form pada mode hanyaBaca', () => {
    render(<MetodeBayar daftarMetodeAwal={DATA_METODE_UJI} hanyaBaca={true} />)

    expect(screen.queryByRole('button', { name: /tambah metode pembayaran baru/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /hapus transfer bank/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /edit qris/i })).toBeNull()

    const cekIzinkan = screen.getByLabelText(/Bolehkan Pelanggan Memberikan Tip/i)
    expect((cekIzinkan as HTMLInputElement).disabled).toBe(true)
  })
})
