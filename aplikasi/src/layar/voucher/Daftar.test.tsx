// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { Daftar, type KampanyeInfo } from './Daftar'
import { simpanKlaimTunda, ambilKlaimTunda, hapusKlaimTunda } from '../../lib/voucher'
import type { HasilKlaimPeladen } from '../../lib/voucher'

const CONTOH_KAMPANYE: KampanyeInfo = {
  id: 'kmp-01',
  nama: 'Promo Sambut Sahabat Baru',
  deskripsi: 'Potongan harga khusus pelanggan baru Resto Barokah.',
  jenis: 'nominal',
  nilai: 20000,
  min_belanja: 50000,
  selesai: '2026-10-15T23:59:59Z',
  nama_resto: 'Resto Barokah',
  penyewaId: 'pny-01',
}

const SUKSES_PELADEN: HasilKlaimPeladen = {
  berhasil: true,
  kode: 'SUKSES',
  pesan: 'Voucher berhasil diterbitkan.',
  data: {
    voucher_id: 'vch-01',
    kode_voucher: 'BRK-ABC123',
    nama_pelanggan: 'Budi Santoso',
    nilai: 20000,
    jenis: 'nominal',
    min_belanja: 50000,
    maks_potongan: null,
    berlaku_sampai: '2026-10-15T23:59:59Z',
  },
}

describe('Komponen Formulir Pendaftaran Voucher (Daftar.tsx — T8-06, kontrak peladen PMB1-F-032)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    hapusKlaimTunda()
    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    })
  })

  afterEach(() => {
    cleanup()
    hapusKlaimTunda()
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

  it('Jalur 1 (Google): sukses masuk TIDAK menerbitkan kartu voucher — kode hanya dari peladen (PMB1-F-032)', async () => {
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
    })

    // Kode voucher TIDAK boleh dibuat di klien: kartu sukses TIDAK muncul,
    // klaim disimpan sebagai tunda, dan pesan jujur meminta menunggu verifikasi.
    expect(screen.queryByTestId('klaim-voucher-sukses')).toBeNull()
    expect(screen.queryByTestId('kartu-voucher-terbit')).toBeNull()
    expect(screen.getByTestId('menunggu-verifikasi').textContent).toContain('Google')
    expect(mockSukses).not.toHaveBeenCalled()

    const tunda = ambilKlaimTunda()
    expect(tunda).not.toBeNull()
    expect(tunda?.kampanyeId).toBe('kmp-01')
    expect(tunda?.caraMasuk).toBe('google')
    expect(tunda?.nama).toBe('Budi Santoso')
  })

  it('Jalur 2 (Email): sukses kirim tautan TIDAK menerbitkan voucher — menunggu verifikasi dulu (PMB1-F-032)', async () => {
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
    })

    // Kartu voucher tidak boleh muncul sebelum peladen menerbitkan kode.
    expect(screen.queryByTestId('klaim-voucher-sukses')).toBeNull()
    expect(mockSukses).not.toHaveBeenCalled()
    const tunggu = screen.getByTestId('menunggu-verifikasi')
    expect(tunggu.textContent).toContain('siti.rahma@contoh.id')
    expect(tunggu.textContent).toContain('verifikasi')

    const tunda = ambilKlaimTunda()
    expect(tunda?.caraMasuk).toBe('email')
    expect(tunda?.email).toBe('siti.rahma@contoh.id')
  })

  it('klaim tunda diselesaikan lewat peladen: kartu voucher memakai kode PELADEN, klaim tunda dibersihkan (PMB1-F-032)', async () => {
    simpanKlaimTunda({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi Santoso',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'google',
      disimpanPada: new Date().toISOString(),
    })
    const mockKlaimPeladen = vi.fn().mockResolvedValue(SUKSES_PELADEN)
    const mockSukses = vi.fn()

    render(
      <Daftar
        kampanye={CONTOH_KAMPANYE}
        onKlaimPeladen={mockKlaimPeladen}
        onKlaimSukses={mockSukses}
      />,
    )

    await waitFor(() => {
      expect(screen.getByTestId('klaim-voucher-sukses')).toBeDefined()
      expect(screen.getByTestId('kartu-voucher-terbit')).toBeDefined()
      // Kode persis hasil peladen — bukan kode acak buatan klien
      expect(screen.getByTestId('teks-kode-voucher').textContent).toBe('BRK-ABC123')
    })

    expect(mockKlaimPeladen).toHaveBeenCalledTimes(1)
    expect(mockKlaimPeladen.mock.calls[0][0]).toMatchObject({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi Santoso',
      email: 'budi@contoh.id',
      caraMasuk: 'google',
    })
    expect(mockSukses).toHaveBeenCalledTimes(1)
    expect(ambilKlaimTunda()).toBeNull()
  })

  it('voucher yang sudah diklaim sebelumnya: kode dari peladen tetap ditampilkan, klaim tunda dibersihkan', async () => {
    simpanKlaimTunda({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi Santoso',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
      disimpanPada: new Date().toISOString(),
    })
    const mockKlaimPeladen = vi.fn().mockResolvedValue({
      berhasil: false,
      kode: 'VOUCHER_SUDAH_DIKLAIM',
      pesan: 'Satu identitas hanya berhak mengklaim 1 voucher untuk kampanye ini.',
      data: { kode_voucher: 'BRK-LAMA01', status: 'aktif' },
    })

    render(<Daftar kampanye={CONTOH_KAMPANYE} onKlaimPeladen={mockKlaimPeladen} />)

    await waitFor(() => {
      expect(screen.getByTestId('teks-kode-voucher').textContent).toBe('BRK-LAMA01')
    })
    expect(ambilKlaimTunda()).toBeNull()
  })

  it('belum terverifikasi (VERIFIKASI_WAJIB): tidak ada kartu voucher dan klaim tunda dipertahankan', async () => {
    simpanKlaimTunda({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Budi Santoso',
      email: 'budi@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'email',
      disimpanPada: new Date().toISOString(),
    })
    const mockKlaimPeladen = vi.fn().mockResolvedValue({
      berhasil: false,
      kode: 'VERIFIKASI_WAJIB',
      pesan: 'Verifikasi identitas (Google atau email) wajib selesai sebelum mengambil voucher.',
    })

    render(<Daftar kampanye={CONTOH_KAMPANYE} onKlaimPeladen={mockKlaimPeladen} />)

    await waitFor(() => {
      expect(mockKlaimPeladen).toHaveBeenCalledTimes(1)
    })
    expect(screen.queryByTestId('klaim-voucher-sukses')).toBeNull()
    expect(ambilKlaimTunda()).not.toBeNull()
  })

  it('dapat menyalin kode voucher hasil peladen ke clipboard', async () => {
    simpanKlaimTunda({
      penyewaId: 'pny-01',
      kampanyeId: 'kmp-01',
      nama: 'Ahmad Dahlan',
      email: 'ahmad@contoh.id',
      setujuPrivasi: true,
      caraMasuk: 'google',
      disimpanPada: new Date().toISOString(),
    })
    const mockKlaimPeladen = vi.fn().mockResolvedValue({
      ...SUKSES_PELADEN,
      data: { ...SUKSES_PELADEN.data, nama_pelanggan: 'Ahmad Dahlan' },
    })

    render(<Daftar kampanye={CONTOH_KAMPANYE} onKlaimPeladen={mockKlaimPeladen} />)

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
