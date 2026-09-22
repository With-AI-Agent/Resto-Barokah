// @vitest-environment jsdom
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { KunciSekarang } from './KunciSekarang'

describe('KunciSekarang (T2-16)', () => {
  it('merender tombol Kunci Sekarang dan memicu onKunci saat diklik', () => {
    const onKunci = vi.fn()
    render(<KunciSekarang onKunci={onKunci} />)

    const tombol = screen.getByRole('button', { name: /Kunci Sekarang/i })
    expect(tombol).toBeDefined()

    fireEvent.click(tombol)
    expect(onKunci).toHaveBeenCalledTimes(1)
  })

  it('menampilkan peringatan waktu mundur saat dalamPeringatan aktif', () => {
    const onKunci = vi.fn()
    const onBatalkan = vi.fn()

    render(
      <KunciSekarang
        onKunci={onKunci}
        dalamPeringatan={true}
        sisaDetik={45}
        onBatalkanPeringatan={onBatalkan}
      />
    )

    expect(screen.getByRole('alert')).toBeDefined()
    expect(screen.getByText(/45 detik/i)).toBeDefined()

    const tombolBatal = screen.getByRole('button', { name: /Saya Masih di Sini/i })
    fireEvent.click(tombolBatal)
    expect(onBatalkan).toHaveBeenCalledTimes(1)
  })
})
