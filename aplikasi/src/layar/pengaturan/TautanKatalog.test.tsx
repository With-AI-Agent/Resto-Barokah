// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { TautanKatalog, type MejaKatalog } from './TautanKatalog'

const CONTOH_MEJA: MejaKatalog[] = [
  { id: 'meja-01', nama: 'Meja 01', area: 'Indoor AC' },
  { id: 'meja-02', nama: 'Meja 02', area: 'Indoor AC' },
  { id: 'meja-03', nama: 'Meja 03', area: 'Outdoor Merokok' },
  { id: 'meja-vip-1', nama: 'VIP 1', area: 'Lantai 2' },
]

describe('Layar Pengaturan Tautan & QR Katalog (T8-05)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    window.print = vi.fn()
    window.open = vi.fn()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
  })

  afterEach(() => {
    cleanup()
  })

  it('merender judul, tab navigasi, dan tautan publik utama resto', () => {
    render(
      <TautanKatalog
        namaResto="Kedai Barokah Rasa"
        slugResto="kedai-barokah-rasa"
        baseUrl="https://kedai-barokah.com"
        daftarMeja={CONTOH_MEJA}
      />,
    )

    // Header & Teks Penjelasan
    expect(screen.getByText('Tautan & Kode QR Katalog Resto')).toBeDefined()
    expect(
      screen.getByText(
        'Bagikan tautan menu ke media sosial atau cetak kode QR meja untuk pelanggan kedai.',
      ),
    ).toBeDefined()

    // Tautan Publik
    const elemenTautan = screen.getByTestId('tautan-utama-resto')
    expect(elemenTautan.textContent).toBe('https://kedai-barokah.com/katalog/kedai-barokah-rasa')

    // QR Code Utama Ter-render
    expect(screen.getByTestId('komponen-qr')).toBeDefined()
    expect(screen.getByText('QR Menu Kedai Barokah Rasa')).toBeDefined()
  })

  it('menyalin tautan resto ke clipboard saat tombol Salin Tautan diklik', async () => {
    render(
      <TautanKatalog
        namaResto="Resto Barokah"
        slugResto="resto-barokah"
        baseUrl="https://resto-barokah.dev"
      />,
    )

    const tombolSalin = screen.getByRole('button', { name: /salin tautan resto/i })
    fireEvent.click(tombolSalin)

    await waitFor(() => {
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
        'https://resto-barokah.dev/katalog/resto-barokah',
      )
      expect(screen.getByText('✓ Tautan Berhasil Disalin!')).toBeDefined()
    })
  })

  it('dapat membagikan tautan ke WhatsApp dan membuka pratinjau katalog', () => {
    render(
      <TautanKatalog
        namaResto="Resto Barokah"
        slugResto="resto-barokah"
        baseUrl="https://resto-barokah.dev"
      />,
    )

    const tombolWa = screen.getByRole('button', { name: /bagikan ke whatsapp/i })
    fireEvent.click(tombolWa)
    expect(window.open).toHaveBeenCalledWith(
      expect.stringContaining('api.whatsapp.com/send?text='),
      '_blank',
    )

    const tombolBuka = screen.getByRole('button', { name: /buka pratinjau katalog menu/i })
    fireEvent.click(tombolBuka)
    expect(window.open).toHaveBeenCalledWith(
      'https://resto-barokah.dev/katalog/resto-barokah',
      '_blank',
    )
  })

  it('dapat berpindah ke tab QR Per Meja dan mengganti meja yang dipilih', () => {
    render(
      <TautanKatalog
        namaResto="Kedai Nusantara"
        slugResto="kedai-nusantara"
        baseUrl="https://kedai.id"
        daftarMeja={CONTOH_MEJA}
      />,
    )

    // Pindah ke tab QR Per Meja
    const tabMeja = screen.getByRole('button', { name: /pilih tab qr per meja/i })
    fireEvent.click(tabMeja)

    // Meja default awal adalah Meja 01
    expect(screen.getByTestId('nomor-meja-terpilih').textContent).toBe('MEJA 01')

    // Pilih Meja 03
    const tombolMeja3 = screen.getByRole('button', { name: /pilih nomor meja 03/i })
    fireEvent.click(tombolMeja3)

    // Pratinjau terbarukan menjadi Meja 03
    expect(screen.getByTestId('nomor-meja-terpilih').textContent).toBe('MEJA 03')
    expect(screen.getByTestId('pratinjau-kartu-meja').textContent).toContain(
      'https://kedai.id/katalog/kedai-nusantara?meja=Meja%2003&meja_id=meja-03',
    )
  })

  it('mendukung pengisian nomor meja kustom secara langsung', () => {
    render(
      <TautanKatalog
        namaResto="Kedai Nusantara"
        slugResto="kedai-nusantara"
        baseUrl="https://kedai.id"
        daftarMeja={CONTOH_MEJA}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: /pilih tab qr per meja/i }))

    // Ketik nomor meja kustom
    const inputMejaKustom = screen.getByPlaceholderText(/Contoh: Meja Lesehan 3/i)
    fireEvent.change(inputMejaKustom, { target: { value: 'Lesehan Bambu 7' } })

    // Pratinjau langsung memperbarui teks meja ke huruf kapital dan URL query
    expect(screen.getByTestId('nomor-meja-terpilih').textContent).toBe('LESEHAN BAMBU 7')
    expect(screen.getByTestId('pratinjau-kartu-meja').textContent).toContain('Lesehan%20Bambu%207')
  })

  it('menjalankan mitigasi risiko salah cetak: panel uji pindai 2 perangkat', () => {
    render(
      <TautanKatalog
        namaResto="Resto Barokah"
        slugResto="resto-barokah"
        daftarMeja={CONTOH_MEJA}
      />,
    )

    fireEvent.click(screen.getByRole('button', { name: /pilih tab qr per meja/i }))

    const panelUji = screen.getByTestId('panel-uji-pindai')
    expect(panelUji).toBeDefined()

    // Status lolos belum muncul
    expect(screen.queryByTestId('status-uji-lolos')).toBeNull()

    // Uji Perangkat 1 (Android)
    const tombolAndroid = screen.getByRole('button', { name: /uji pindai di android/i })
    fireEvent.click(tombolAndroid)
    expect(screen.getByText('✓ Terverifikasi')).toBeDefined()
    expect(screen.queryByTestId('status-uji-lolos')).toBeNull()

    // Uji Perangkat 2 (iPhone)
    const tombolIos = screen.getByRole('button', { name: /uji pindai di iphone/i })
    fireEvent.click(tombolIos)

    // Kedua perangkat terverifikasi dan lencana keamanan muncul
    expect(screen.getByTestId('status-uji-lolos')).toBeDefined()
    expect(screen.getByTestId('status-uji-lolos').textContent).toContain(
      'Kedua perangkat terverifikasi! Kode QR aman untuk dicetak massal.',
    )
  })

  it('memanggil fungsi cetak saat tombol Cetak Kartu Meja diklik', () => {
    const mockCetak = vi.fn()
    render(<TautanKatalog namaResto="Resto Barokah" daftarMeja={CONTOH_MEJA} onCetak={mockCetak} />)

    fireEvent.click(screen.getByRole('button', { name: /pilih tab qr per meja/i }))

    const tombolCetak = screen.getByRole('button', { name: /cetak lembar kartu meja ini/i })
    fireEvent.click(tombolCetak)

    expect(mockCetak).toHaveBeenCalledTimes(1)
  })

  it('merender tab Cetak Massal Semua Meja dengan seluruh kartu meja cabang', () => {
    render(<TautanKatalog namaResto="Resto Barokah" daftarMeja={CONTOH_MEJA} />)

    // Buka tab Cetak Massal
    const tabMassal = screen.getByRole('button', { name: /pilih tab cetak massal semua meja/i })
    fireEvent.click(tabMassal)

    // Kisi cetak massal harus memuat semua meja
    const kisiMassal = screen.getByTestId('kisi-cetak-massal')
    expect(kisiMassal).toBeDefined()

    expect(screen.getByTestId('kartu-massal-meja-01')).toBeDefined()
    expect(screen.getByTestId('kartu-massal-meja-02')).toBeDefined()
    expect(screen.getByTestId('kartu-massal-meja-03')).toBeDefined()
    expect(screen.getByTestId('kartu-massal-meja-vip-1')).toBeDefined()

    // Tombol cetak massal memanggil window.print bila onCetak tidak dipasok
    const tombolCetakSemua = screen.getByRole('button', {
      name: /cetak seluruh lembar kartu meja sekarang/i,
    })
    fireEvent.click(tombolCetakSemua)
    expect(window.print).toHaveBeenCalled()
  })

  it('memanggil onKembali saat tombol kembali diklik', () => {
    const mockKembali = vi.fn()
    render(<TautanKatalog onKembali={mockKembali} />)

    const tombolKembali = screen.getByRole('button', { name: /kembali ke pengaturan/i })
    fireEvent.click(tombolKembali)
    expect(mockKembali).toHaveBeenCalledTimes(1)
  })
})
