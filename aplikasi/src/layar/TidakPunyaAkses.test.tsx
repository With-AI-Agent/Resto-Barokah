// @vitest-environment jsdom
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { PenyediaBahasa } from '../bahasa'
import { TidakPunyaAkses } from './TidakPunyaAkses'

describe('TidakPunyaAkses component (T2-08)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender judul, kode ramah, dan instruksi tindakan', () => {
    render(
      <PenyediaBahasa>
        <TidakPunyaAkses kodeError="FORBIDDEN" />
      </PenyediaBahasa>,
    )

    expect(screen.getByText(/\[AK-403\] Akses Tidak Diizinkan/)).toBeDefined()
    expect(screen.getByText(/Owner atau Admin Cabang/)).toBeDefined()
  })

  it('memicu tombol onKembali saat diklik', () => {
    const onKembaliMock = vi.fn()
    render(
      <PenyediaBahasa>
        <TidakPunyaAkses onKembali={onKembaliMock} />
      </PenyediaBahasa>,
    )

    const btn = screen.getByRole('button', { name: /ke Halaman Utama/i })
    fireEvent.click(btn)
    expect(onKembaliMock).toHaveBeenCalled()
  })

  it('membuka lembar bantuan saat tombol bantuan diklik', () => {
    render(
      <PenyediaBahasa>
        <TidakPunyaAkses />
      </PenyediaBahasa>,
    )

    const btnBantuan = screen.getByRole('button', { name: /^bantuan$/i })
    fireEvent.click(btnBantuan)
    expect(screen.getByText('Bantuan Hak Akses')).toBeDefined()
  })
})
