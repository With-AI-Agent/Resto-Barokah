// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LupaAkses } from './LupaAkses'
import { PenyediaBahasa } from '../../bahasa'

describe('LupaAkses (T2-05)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender kolom email dan tombol pemulihan', () => {
    render(
      <PenyediaBahasa>
        <LupaAkses onMintaTautanPemulihan={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByLabelText(/Alamat Email Terdaftar/i)).toBeDefined()
    expect(screen.getByRole('button', { name: /Kirim Tautan Pemulihan/i })).toBeDefined()
  })

  it('berhasil mengirim tautan dan menampilkan pesan sukses', async () => {
    const onMintaMock = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <PenyediaBahasa>
        <LupaAkses onMintaTautanPemulihan={onMintaMock} />
      </PenyediaBahasa>,
    )

    fireEvent.change(screen.getByLabelText(/Alamat Email Terdaftar/i), {
      target: { value: 'pelanggan@test.com' },
    })

    fireEvent.click(screen.getByRole('button', { name: /Kirim Tautan Pemulihan/i }))

    await waitFor(() => {
      expect(onMintaMock).toHaveBeenCalledWith('pelanggan@test.com')
      expect(screen.getByRole('status')).toBeDefined()
      expect(screen.getByText(/Tautan pemulihan akun telah dikirim/i)).toBeDefined()
    })
  })
})
