// @vitest-environment jsdom
/**
 * Uji T5-08 — nomor HP pelanggan opsional, dengan persetujuan.
 *
 * Yang dijaga di sini adalah dua janji yang gampang sekali dilanggar diam-diam
 * saat layar dirapikan: (1) bagian ini TIDAK PERNAH menjadi syarat membayar, dan
 * (2) data pribadi tidak berpindah tanpa persetujuan eksplisit
 * (`docs/KEAMANAN.md` §11, UU PDP 27/2022).
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { DataPelanggan, nomorMasukAkal } from './DataPelanggan'

afterEach(cleanup)

function isiNomor(nilai: string) {
  fireEvent.change(screen.getByLabelText(/Nomor HP pelanggan/i), { target: { value: nilai } })
}

function centangSetuju() {
  fireEvent.click(screen.getByTestId('pelanggan-setuju'))
}

describe('nomorMasukAkal', () => {
  it('menerima nomor wajar termasuk yang berspasi', () => {
    expect(nomorMasukAkal('0812 3456 7890')).toBe(true)
    expect(nomorMasukAkal('081234567')).toBe(true)
  })

  it('menolak isian yang jelas bukan nomor', () => {
    expect(nomorMasukAkal('')).toBe(false)
    expect(nomorMasukAkal('0812')).toBe(false)
    expect(nomorMasukAkal('tidak mau')).toBe(false)
  })
})

describe('DataPelanggan (T5-08)', () => {
  it('nomor TIDAK dikirim tanpa persetujuan, walau nomornya sudah diisi', () => {
    const onSimpan = vi.fn()
    render(<DataPelanggan onSimpan={onSimpan} />)

    isiNomor('0812 3456 7890')
    expect(
      (screen.getByRole('button', { name: /Simpan & lanjut/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
    expect(onSimpan).not.toHaveBeenCalled()
  })

  it('persetujuan saja tidak cukup bila nomornya kosong', () => {
    render(<DataPelanggan />)
    centangSetuju()
    expect(
      (screen.getByRole('button', { name: /Simpan & lanjut/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
  })

  it('nomor + persetujuan → terkirim, dan persetujuannya ikut sebagai data', () => {
    const onSimpan = vi.fn()
    render(<DataPelanggan onSimpan={onSimpan} />)

    isiNomor('0812 3456 7890')
    centangSetuju()
    fireEvent.click(screen.getByRole('button', { name: /Simpan & lanjut/i }))

    expect(onSimpan).toHaveBeenCalledWith({ noHp: '0812 3456 7890', setuju: true })
  })

  it('nama panggilan ikut bila diisi, dan tidak dikirim bila kosong', () => {
    const onSimpan = vi.fn()
    render(<DataPelanggan onSimpan={onSimpan} />)

    isiNomor('0812 3456 7890')
    fireEvent.change(screen.getByLabelText(/Nama panggilan/i), { target: { value: 'Bu Ani' } })
    centangSetuju()
    fireEvent.click(screen.getByRole('button', { name: /Simpan & lanjut/i }))

    expect(onSimpan).toHaveBeenCalledWith({
      noHp: '0812 3456 7890',
      nama: 'Bu Ani',
      setuju: true,
    })
  })

  it('tombol Lewati SELALU hidup — bagian ini tidak boleh menghambat pembayaran', () => {
    const onLewati = vi.fn()
    render(<DataPelanggan onLewati={onLewati} />)

    const lewati = screen.getByRole('button', { name: /Lewati/i }) as HTMLButtonElement
    expect(lewati.disabled).toBe(false)
    fireEvent.click(lewati)
    expect(onLewati).toHaveBeenCalledTimes(1)
  })

  it('melewati tidak mengirim data pelanggan apa pun', () => {
    const onSimpan = vi.fn()
    render(<DataPelanggan onSimpan={onSimpan} onLewati={vi.fn()} />)

    isiNomor('0812 3456 7890')
    fireEvent.click(screen.getByRole('button', { name: /Lewati/i }))
    expect(onSimpan).not.toHaveBeenCalled()
  })

  it('menjelaskan kegunaan data di layar, bukan hanya di halaman kebijakan', () => {
    render(<DataPelanggan />)
    const teks = screen.getByTestId('pelanggan-penjelasan').textContent ?? ''
    expect(teks).toContain('Boleh dilewati')
    expect(teks).toContain('voucher')
    expect(teks).toContain('tidak dijual')
  })
})
