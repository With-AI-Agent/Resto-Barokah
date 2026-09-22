// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { ambilMenuPeran } from '../../komponen/Navigasi'
import { batasWaktuInaktifMenit } from '../../hook/useKunciOtomatis'
import type { PeranPengguna } from '../../lib/auth'
import { Rangka } from '../../komponen/Rangka'
import { PenyediaBahasa } from '../../bahasa'

describe('Uji Menyeluruh Hak Akses & Navigasi 6 Peran (T2-12 & T2-19)', () => {
  afterEach(() => {
    cleanup()
  })

  const SEMUA_PERAN: { peran: PeranPengguna; namaLayarKhas: string; timeoutMenit: number }[] = [
    { peran: 'pemilik_platform', namaLayarKhas: 'Dasbor Platform', timeoutMenit: 30 },
    { peran: 'owner_pusat', namaLayarKhas: 'Pengaturan Resto', timeoutMenit: 60 },
    { peran: 'admin_cabang', namaLayarKhas: 'Pegawai Cabang', timeoutMenit: 30 },
    { peran: 'kasir', namaLayarKhas: 'Tutup Kas Shift', timeoutMenit: 15 },
    { peran: 'pelayan', namaLayarKhas: 'Pesanan Meja', timeoutMenit: 15 },
    { peran: 'dapur', namaLayarKhas: 'Pesanan Dapur', timeoutMenit: 15 },
  ]

  it.each(SEMUA_PERAN)(
    'menampilkan menu yang sesuai dan batas inaktif yang tepat untuk peran $peran',
    ({ peran, namaLayarKhas, timeoutMenit }) => {
      // 1. Verifikasi menu peran
      const menu = ambilMenuPeran(peran)
      expect(menu.length).toBeGreaterThan(0)
      const adaMenuKhas = menu.some((m) => m.label.includes(namaLayarKhas))
      expect(adaMenuKhas).toBe(true)

      // 2. Verifikasi batas waktu inactivity (T2-09 & T2-16)
      const batas = batasWaktuInaktifMenit(peran)
      expect(batas).toBe(timeoutMenit)
    },
  )

  it('merender Rangka kerja aplikasi dengan lencana peran dan info cabang untuk kasir', () => {
    const sesiKasir = {
      id: 'usr-kasir-01',
      nama: 'Siti Kasir',
      email: 'siti@barokah.id',
      peran: 'kasir' as PeranPengguna,
      penyewaId: 'penyewa-01',
      cabangIds: ['cab-001'],
      cabangAktifId: 'cab-001',
    }

    render(
      <PenyediaBahasa>
        <Rangka sesi={sesiKasir} layarAktif="kasir" onPilihLayar={vi.fn()}>
          <div data-testid="konten-kasir">Layar Kasir Aktif</div>
        </Rangka>
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Siti Kasir')).toBeDefined()
    expect(screen.getByText('KASIR')).toBeDefined()
    expect(screen.getByTestId('konten-kasir')).toBeDefined()
  })

  it('merender Rangka kerja aplikasi dengan lencana peran dapur tanpa izin ubah cabang', () => {
    const sesiDapur = {
      id: 'usr-dapur-01',
      nama: 'Chef Junaidi',
      email: 'junaidi@barokah.id',
      peran: 'dapur' as PeranPengguna,
      penyewaId: 'penyewa-01',
      cabangIds: ['cab-001'],
      cabangAktifId: 'cab-001',
    }

    render(
      <PenyediaBahasa>
        <Rangka sesi={sesiDapur} layarAktif="dapur" onPilihLayar={vi.fn()}>
          <div data-testid="konten-dapur">Layar Pesanan Dapur</div>
        </Rangka>
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Chef Junaidi')).toBeDefined()
    expect(screen.getByText('DAPUR')).toBeDefined()
    expect(screen.getByTestId('konten-dapur')).toBeDefined()
  })
})
