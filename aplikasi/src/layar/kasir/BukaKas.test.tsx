// @vitest-environment jsdom
/**
 * Uji BukaKas.tsx (T7-01) — layar pembukaan shift kasir & pencatatan modal awal.
 *
 * Yang dibuktikan (DoD T7-01 + PRD M7 + TECH_SPEC §4.3 & §9 ART-6):
 *  - Modal awal wajib diisi dan tidak boleh negatif;
 *  - Tombol uang cepat mengisi nominal dengan benar;
 *  - Pratinjau format Rupiah muncul secara jelas;
 *  - Alur konfirmasi mencegah salah ketik sebelum dikirim;
 *  - Peladen memproses buka shift lewat `onBukaShift` (RPC `buka_shift`);
 *  - Penolakan / galat peladen ditampilkan jelas tanpa meledak;
 *  - Deteksi shift aktif mencegah kasir membuka shift baru jika sudah ada yang terbuka.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { BukaKas } from './BukaKas'

afterEach(() => {
  cleanup()
})

describe('BukaKas (T7-01)', () => {
  it('merender info cabang dan nama kasir', () => {
    render(<BukaKas cabangId="cab-utama" namaCabang="Cabang Utama" namaKasir="Rina Kasir" />)

    expect(screen.getByText(/Buka Shift Kasir/i)).toBeDefined()
    expect(screen.getByText(/Cabang Utama \(cab-utama\)/i)).toBeDefined()
    expect(screen.getByText('Rina Kasir')).toBeDefined()
  })

  it('tombol lanjut nonaktif jika modal awal belum diisi', () => {
    render(<BukaKas />)
    const tombolLanjut = screen.getByRole('button', { name: /Lanjut Buka Shift/i })
    expect((tombolLanjut as HTMLButtonElement).disabled).toBe(true)
  })

  it('tombol uang cepat mengisi modal awal dan menampilkan pratinjau Rupiah', () => {
    render(<BukaKas />)

    // Klik tombol cepat Rp100.000
    fireEvent.click(screen.getByText('Rp100.000'))

    // Pratinjau muncul
    expect(screen.getByText('Pratinjau Modal:')).toBeDefined()
    // Tombol lanjut menjadi aktif
    const tombolLanjut = screen.getByRole('button', { name: /Lanjut Buka Shift/i })
    expect((tombolLanjut as HTMLButtonElement).disabled).toBe(false)
  })

  it('bisa memilih modal awal Rp0', () => {
    render(<BukaKas />)
    fireEvent.click(screen.getByText('Rp0 (Nol)'))

    const tombolLanjut = screen.getByRole('button', { name: /Lanjut Buka Shift/i })
    expect((tombolLanjut as HTMLButtonElement).disabled).toBe(false)
  })

  it('alur konfirmasi bekerja: menampilkan ringkasan dan tombol eksekusi', () => {
    render(<BukaKas />)

    fireEvent.click(screen.getByText('Rp200.000'))
    fireEvent.click(screen.getByRole('button', { name: /Lanjut Buka Shift/i }))

    expect(screen.getByText('Konfirmasi Buka Shift')).toBeDefined()
    expect(screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i })).toBeDefined()

    // Tombol Ubah mengembalikan ke formulir pengisian
    fireEvent.click(screen.getByRole('button', { name: 'Ubah' }))
    expect(screen.getByText('Modal Awal Kasir *')).toBeDefined()
  })

  it('memanggil onBukaShift dengan nominal angka dan catatan yang dimasukkan', async () => {
    const onBukaShiftMock = vi.fn().mockResolvedValue({
      sukses: true,
      shiftId: 'shift-123',
      pesan: 'Shift kasir berhasil dibuka.',
    })

    render(<BukaKas onBukaShift={onBukaShiftMock} />)

    const inputModal = screen.getByLabelText(/Modal Awal Kasir/i)
    fireEvent.change(inputModal, { target: { value: '150000' } })

    const inputCatatan = screen.getByLabelText(/Catatan Pembukaan/i)
    fireEvent.change(inputCatatan, { target: { value: 'Pecahan kembalian lengkap' } })

    fireEvent.click(screen.getByRole('button', { name: /Lanjut Buka Shift/i }))
    fireEvent.click(screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i }))

    await waitFor(() => {
      expect(onBukaShiftMock).toHaveBeenCalledWith({
        modalAwal: 150000,
        catatan: 'Pecahan kembalian lengkap',
      })
    })

    // Layar sukses muncul
    await waitFor(() => {
      expect(screen.getByText(/Shift Berhasil Dibuka!/i)).toBeDefined()
    })
  })

  it('menampilkan galat bila onBukaShift menolak (misal SH-409 shift dobel)', async () => {
    const onBukaShiftMock = vi.fn().mockResolvedValue({
      sukses: false,
      pesan: 'SH-409: Anda masih memiliki shift kasir yang aktif di cabang ini.',
    })

    render(<BukaKas onBukaShift={onBukaShiftMock} />)

    fireEvent.click(screen.getByText('Rp100.000'))
    fireEvent.click(screen.getByRole('button', { name: /Lanjut Buka Shift/i }))
    fireEvent.click(screen.getByRole('button', { name: /Ya, Buka Shift Sekarang/i }))

    await waitFor(() => {
      expect(
        screen.getByText(/SH-409: Anda masih memiliki shift kasir yang aktif di cabang ini/i),
      ).toBeDefined()
    })
  })

  it('menampilkan status shift aktif jika kasir sudah membuka shift sebelumnya', () => {
    const onLanjutMock = vi.fn()
    render(
      <BukaKas
        shiftAktif={{
          id: 'shift-xyz-aktif',
          modalAwal: 150000,
          dibukaPada: '2026-09-24T08:00:00Z',
        }}
        onLanjut={onLanjutMock}
      />,
    )

    expect(screen.getByText(/Shift Kasir Sudah Aktif/i)).toBeDefined()
    expect(screen.getByText('shift-xyz-aktif')).toBeDefined()
    expect(screen.getByText('Rp150.000')).toBeDefined()

    fireEvent.click(screen.getByRole('button', { name: /Lanjut ke Kasir POS/i }))
    expect(onLanjutMock).toHaveBeenCalled()
  })
})
