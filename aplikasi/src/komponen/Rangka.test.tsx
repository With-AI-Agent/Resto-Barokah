// @vitest-environment jsdom
import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { PenyediaBahasa } from '../bahasa'
import type { PenggunaSesi } from '../lib/auth'
import { Rangka } from './Rangka'

describe('Rangka Layout component (T2-06)', () => {
  const mockSesi: PenggunaSesi = {
    id: 'usr-1',
    nama: 'Rina Kasir',
    email: 'rina@resto.test',
    peran: 'kasir',
    penyewaId: 'resto-1',
    cabangIds: ['cab-001'],
    cabangAktifId: 'cab-001',
  }

  it('merender header judul, peran, nama pengguna, dan konten anak', () => {
    render(
      <PenyediaBahasa>
        <Rangka sesi={mockSesi} layarAktif="kasir" onPilihLayar={vi.fn()}>
          <div data-testid="isi-konten">Konten Kasir POS</div>
        </Rangka>
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Resto Barokah')).toBeDefined()
    expect(screen.getByText('Rina Kasir')).toBeDefined()
    expect(screen.getByText('KASIR')).toBeDefined()
    expect(screen.getByTestId('isi-konten')).toBeDefined()
  })
})
