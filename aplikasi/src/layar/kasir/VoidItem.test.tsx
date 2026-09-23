// @vitest-environment jsdom
/**
 * Uji T5-06 — pembatalan sebelum dapur mulai, alasan WAJIB.
 *
 * Yang dijaga di sini adalah hal yang membuat laporan pembatalan ada gunanya:
 * tidak ada jalan membatalkan tanpa alasan, dan penolakan peladen tidak boleh
 * disulap jadi "berhasil" di layar.
 *
 * Pagar sungguhannya di database (`picu_pembatalan_sah`, migrasi 0015 + uji
 * `supabase/tes/void_satu_item.sql`, `pembatalan_sekali.sql`, `nilai_kerugian.sql`).
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { VoidItem } from './VoidItem'

afterEach(cleanup)

describe('VoidItem (T5-06)', () => {
  it('tombol batal MATI sampai alasan terisi (alasan wajib)', () => {
    const onBatalkan = vi.fn()
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} onBatalkan={onBatalkan} />)

    expect(
      (screen.getByRole('button', { name: /Batalkan & catat alasan/i }) as HTMLButtonElement)
        .disabled,
    ).toBe(true)
    expect(onBatalkan).not.toHaveBeenCalled()
  })

  it('alasan yang hanya berisi spasi tetap dianggap kosong', () => {
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} />)

    fireEvent.change(screen.getByLabelText(/Alasan pembatalan/i), { target: { value: '   ' } })
    expect(
      (screen.getByRole('button', { name: /Batalkan & catat alasan/i }) as HTMLButtonElement)
        .disabled,
    ).toBe(true)
  })

  it('alasan cepat mengisi kolom, dan alasannya ikut terkirim', async () => {
    const onBatalkan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} onBatalkan={onBatalkan} />)

    fireEvent.click(screen.getByRole('button', { name: 'Salah input kasir' }))
    fireEvent.click(screen.getByRole('button', { name: /Batalkan & catat alasan/i }))

    await waitFor(() => expect(onBatalkan).toHaveBeenCalledWith({ alasan: 'Salah input kasir' }))
  })

  it('alasan yang diketik sendiri juga diterima', async () => {
    const onBatalkan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} onBatalkan={onBatalkan} />)

    fireEvent.change(screen.getByLabelText(/Alasan pembatalan/i), {
      target: { value: 'pelanggan pindah meja' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Batalkan & catat alasan/i }))

    await waitFor(() =>
      expect(onBatalkan).toHaveBeenCalledWith({ alasan: 'pelanggan pindah meja' }),
    )
  })

  it('penolakan peladen ditampilkan apa adanya, tidak disulap jadi berhasil', async () => {
    const onBatalkan = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Item ini sudah dibatalkan — kiriman ulang tidak dicatat lagi.',
    })
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} onBatalkan={onBatalkan} />)

    fireEvent.change(screen.getByLabelText(/Alasan pembatalan/i), { target: { value: 'salah' } })
    fireEvent.click(screen.getByRole('button', { name: /Batalkan & catat alasan/i }))

    await waitFor(() =>
      expect(screen.getByTestId('void-pesan').textContent).toContain('sudah dibatalkan'),
    )
  })

  it('memberi tahu kasir bila dapur sudah mulai (butuh PIN atasan)', () => {
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} sudahKeDapur />)
    expect(screen.getByTestId('void-peringatan-dapur').textContent).toContain('bahan terbuang')
  })

  it('tidak menakut-nakuti bila dapur belum mulai', () => {
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} />)
    expect(screen.queryByTestId('void-peringatan-dapur')).toBeNull()
  })

  it('menampilkan nilai yang batal ditagih supaya kasir sadar besarnya', () => {
    render(<VoidItem namaTarget="Nasi Goreng" nilai={27000} />)
    expect(screen.getByTestId('void-target').textContent).toContain('Rp27.000')
  })
})
