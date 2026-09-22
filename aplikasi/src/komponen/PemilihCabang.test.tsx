// @vitest-environment jsdom
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { PenyediaBahasa } from '../bahasa'
import { PemilihCabang } from './PemilihCabang'

describe('PemilihCabang component (T2-07)', () => {
  const cabangDummy = [
    { id: 'cab-1', nama: 'Cabang Pusat Oasis' },
    { id: 'cab-2', nama: 'Cabang Sudirman' },
  ]

  it('merender lencana tetap jika tidak bisa pindah cabang', () => {
    render(
      <PenyediaBahasa>
        <PemilihCabang
          cabangAktifId="cab-1"
          daftarCabang={cabangDummy}
          bisaPindahCabang={false}
          onGantiCabang={vi.fn()}
        />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Cabang Pusat Oasis')).toBeDefined()
    expect(screen.queryByRole('combobox')).toBeNull()
  })

  it('merender dropdown select saat pengguna berhak pindah cabang', () => {
    const onGantiMock = vi.fn()
    render(
      <PenyediaBahasa>
        <PemilihCabang
          cabangAktifId="cab-1"
          daftarCabang={cabangDummy}
          bisaPindahCabang={true}
          onGantiCabang={onGantiMock}
        />
      </PenyediaBahasa>,
    )

    const select = screen.getByRole('combobox')
    expect(select).toBeDefined()
    fireEvent.change(select, { target: { value: 'cab-2' } })
    expect(onGantiMock).toHaveBeenCalledWith('cab-2')
  })
})
