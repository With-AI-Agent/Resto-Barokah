// @vitest-environment jsdom
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { PenyediaBahasa } from '../bahasa'
import { ambilMenuPeran, Navigasi } from './Navigasi'

describe('Navigasi per Peran (T2-06)', () => {
  it('menghasilkan menu yang tepat untuk masing-masing 6 peran', () => {
    const menuKasir = ambilMenuPeran('kasir')
    expect(menuKasir.map((m) => m.id)).toEqual(['kasir', 'riwayat', 'tutup_kas'])

    const menuDapur = ambilMenuPeran('dapur')
    expect(menuDapur.map((m) => m.id)).toEqual(['dapur', 'stok_habis'])

    const menuPelayan = ambilMenuPeran('pelayan')
    expect(menuPelayan.map((m) => m.id)).toEqual(['pesanan_meja', 'status_pesanan', 'voucher'])

    const menuOwner = ambilMenuPeran('owner_pusat')
    expect(menuOwner.map((m) => m.id)).toEqual([
      'kasir',
      'dapur',
      'laporan',
      'menu_stok',
      'pegawai',
      'pengaturan',
    ])

    const menuPlatform = ambilMenuPeran('pemilik_platform')
    expect(menuPlatform.map((m) => m.id)).toEqual([
      'platform_dasbor',
      'platform_resto',
      'platform_dukungan',
    ])
  })

  it('merender menu dan merespons pemilihan tab layar', () => {
    const onPilihLayarMock = vi.fn()
    render(
      <PenyediaBahasa>
        <Navigasi peran="kasir" layarAktif="kasir" onPilihLayar={onPilihLayarMock} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Kasir POS')).toBeDefined()
    expect(screen.getByText('Riwayat Transaksi')).toBeDefined()
    expect(screen.getByText('Tutup Kas Shift')).toBeDefined()

    fireEvent.click(screen.getByText('Riwayat Transaksi'))
    expect(onPilihLayarMock).toHaveBeenCalledWith('riwayat')
  })

  it('memicu tombol keluar dan bantuan ketika ditekan', () => {
    const onKeluarMock = vi.fn()
    const onBantuanMock = vi.fn()

    render(
      <PenyediaBahasa>
        <Navigasi
          peran="kasir"
          layarAktif="kasir"
          onPilihLayar={vi.fn()}
          onKeluar={onKeluarMock}
          onBukaBantuan={onBantuanMock}
        />
      </PenyediaBahasa>,
    )

    const btnKeluar = screen.getByRole('button', { name: /keluar/i })
    fireEvent.click(btnKeluar)
    expect(onKeluarMock).toHaveBeenCalled()

    const btnBantuan = screen.getByRole('button', { name: /bantuan/i })
    fireEvent.click(btnBantuan)
    expect(onBantuanMock).toHaveBeenCalled()
  })
})
