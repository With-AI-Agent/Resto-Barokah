// @vitest-environment jsdom
import { describe, it, expect, afterEach, vi } from 'vitest'
import { screen, fireEvent, cleanup } from '@testing-library/react'
import { renderDenganHarness, useHarness } from './harness'
import { TombolAksi } from '../komponen/TombolAksi'
import { KeadaanKosong } from '../komponen/KeadaanKosong'
import { KeadaanMemuat } from '../komponen/KeadaanMemuat'
import { KeadaanGagal } from '../komponen/KeadaanGagal'

function KomponenUjiKasir() {
  const { peran, daftarIzin, eksekusiRpc, data } = useHarness()

  return (
    <div>
      <h1>Layar Kasir Uji</h1>
      <p data-testid="peran-aktif">{peran}</p>
      <p data-testid="jumlah-menu">{data.menu.length} menu</p>
      <TombolAksi
        aksiId="kasir.tambah_item"
        peranPengguna={peran}
        daftarIzinPengguna={daftarIzin}
        onEksekusi={async (aksi) => {
          if (aksi.rpc) {
            await eksekusiRpc(aksi.rpc, { item: 'm-1', qty: 1 })
          }
        }}
      />
    </div>
  )
}

describe('Harness Pengujian Komponen Antarmuka (T1-34)', () => {
  afterEach(() => {
    cleanup()
  })

  it('menyediakan konteks peran, izin, dan data contoh dengan benar', () => {
    renderDenganHarness(<KomponenUjiKasir />, {
      peran: 'kasir',
      daftarIzin: ['void_sebelum_dapur'],
    })

    expect(screen.getByTestId('peran-aktif').textContent).toBe('kasir')
    expect(screen.getByTestId('jumlah-menu').textContent).toBe('4 menu')
    expect(screen.getByRole('button', { name: /tambah item/i })).toBeDefined()
  })

  it('merekam pemanggilan RPC saat aksi dieksekusi', async () => {
    const hasil = renderDenganHarness(<KomponenUjiKasir />, {
      peran: 'kasir',
      penanganRpc: {
        hitung_total: vi.fn().mockResolvedValue({ total: 25000 }),
      },
    })

    const tombol = screen.getByRole('button', { name: /tambah item/i })
    fireEvent.click(tombol)

    expect(hasil.cekRpcDipanggil('hitung_total')).toBe(true)
    const panggilanTerakhir = hasil.dapatkanPanggilanTerakhir()
    expect(panggilanTerakhir?.nama).toBe('hitung_total')
    expect(panggilanTerakhir?.params).toEqual({ item: 'm-1', qty: 1 })
  })

  it('dapat menguji keadaan kosong, memuat, dan gagal', () => {
    const { rerender } = renderDenganHarness(
      <KeadaanKosong judul="Keranjang Kosong" keterangan="Pilih menu untuk memulai." />,
    )
    expect(screen.getByText('Keranjang Kosong')).toBeDefined()

    rerender(<KeadaanMemuat judul="Memuat Data Katalog..." baris={2} />)
    expect(screen.getByText('Memuat Data Katalog...')).toBeDefined()

    const cobaFn = vi.fn()
    rerender(<KeadaanGagal onCoba={cobaFn} keterangan="Koneksi bermasalah" />)
    expect(screen.getByText('Koneksi bermasalah')).toBeDefined()
    fireEvent.click(screen.getByRole('button', { name: /coba lagi/i }))
    expect(cobaFn).toHaveBeenCalled()
  })
})
