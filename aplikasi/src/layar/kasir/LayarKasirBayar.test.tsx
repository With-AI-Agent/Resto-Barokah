// @vitest-environment jsdom
/**
 * Uji sambungan LayarKasir → layar Bayar (sisa T5-01).
 *
 * Yang dibuktikan di sini adalah hal yang DULU SALAH: modal bayar lama di
 * `LayarKasir` mengeras-kodekan tiga metode ('tunai' | 'qris' | 'kartu') di
 * dalam berkas layar, sehingga:
 *  - metode yang dinonaktifkan pemilik di Pengaturan TETAP tampil di kasir;
 *  - metode baru (mis. transfer bank) tidak pernah bisa muncul tanpa koding;
 *  - uang dicatat lewat `onBayarPesanan(pesananId, metodeString, nominal)` —
 *    bukan lewat pintu tunggal RPC `bayar_pesanan` (migrasi 0039).
 *
 * Sesudah disambung: `LayarKasir` tidak punya daftar metode sama sekali. Ia
 * hanya meneruskan metode dari kontainer ke `Bayar.tsx`, dan uangnya lewat
 * `onBayar` yang di produksi dipasang ke `useBayar` (RPC 0039).
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import type { MetodeBayar } from './Bayar'
import { PenyediaBahasa } from '../../bahasa'

afterEach(() => {
  cleanup()
})

/** Metode dari peladen: sengaja BUKAN tunai/qris/kartu, supaya ketahuan bila
 *  layar masih diam-diam memakai daftar bawaannya sendiri. */
const METODE: MetodeBayar[] = [
  { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuhReferensi: false, urutan: 1 },
  { id: 'm-transfer', nama: 'Transfer Bank', jenis: 'non_tunai', butuhReferensi: true, urutan: 2 },
]

function bukaBayar() {
  fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))
  fireEvent.click(screen.getByRole('button', { name: /Bayar Pesanan/i }))
}

describe('LayarKasir ↔ Bayar (T5-01, sambungan)', () => {
  it('modal bayar menampilkan metode dari kontainer, bukan daftar bawaan layar', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir metodeBayar={METODE} />
      </PenyediaBahasa>,
    )
    bukaBayar()

    expect(screen.getByTestId('metode-Tunai')).toBeTruthy()
    expect(screen.getByTestId('metode-Transfer Bank')).toBeTruthy()
    // Metode lama yang dulu dikeras-kodekan tidak boleh muncul lagi.
    expect(screen.queryByText(/QRIS Dinamis/i)).toBeNull()
    expect(screen.queryByText(/Kartu Debit\/Kredit/i)).toBeNull()
  })

  it('tanpa metode aktif: kasir diberi tahu, bukan disuguhi tombol bayar palsu', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir metodeBayar={[]} />
      </PenyediaBahasa>,
    )
    bukaBayar()

    expect(screen.getByText('Belum ada metode bayar aktif')).toBeTruthy()
  })

  it('uang dicatat lewat onBayar (pintu RPC bayar_pesanan), bukan onBayarPesanan lama', async () => {
    const onBayar = vi.fn().mockResolvedValue({
      jumlah: 13800,
      kembalian: 36200,
      totalDibayar: 13800,
      totalPesanan: 13800,
      lunas: true,
      dobel: false,
    })
    render(
      <PenyediaBahasa>
        <LayarKasir metodeBayar={METODE} onBayar={onBayar} />
      </PenyediaBahasa>,
    )
    bukaBayar()

    fireEvent.click(screen.getByText('Rp50.000'))
    fireEvent.click(screen.getByText('Tinjau pembayaran'))
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))

    await waitFor(() => expect(onBayar).toHaveBeenCalled())
    const masukan = onBayar.mock.calls[0][0]
    // Tahu Tempe Rp12.000 + service 5% + PB1 10% = Rp13.800
    expect(masukan).toMatchObject({
      metodeId: 'm-tunai',
      jumlah: 13800,
      diterima: 50000,
      referensi: null,
    })
  })

  it('kembalian yang ditampilkan adalah angka peladen, bukan hitungan layar', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir
          metodeBayar={METODE}
          keadaanBayar="berhasil"
          terakhirBayar={{
            jumlah: 13800,
            // Sengaja berbeda dari (50.000 − 13.800): layar wajib menurut peladen.
            kembalian: 36199,
            totalDibayar: 13800,
            totalPesanan: 13800,
            lunas: true,
            dobel: false,
            sisa: 0,
          }}
        />
      </PenyediaBahasa>,
    )
    bukaBayar()

    expect(screen.getByTestId('kembalian').textContent).toContain('Rp36.199')
  })

  it('pembayaran sebagian: layar menawarkan bayar sisa dan keranjang belum dikosongkan', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir
          metodeBayar={METODE}
          keadaanBayar="berhasil"
          terakhirBayar={{
            jumlah: 5000,
            kembalian: 0,
            totalDibayar: 5000,
            totalPesanan: 13800,
            lunas: false,
            dobel: false,
            sisa: 8800,
          }}
        />
      </PenyediaBahasa>,
    )
    bukaBayar()

    expect(screen.getByText('Bayar sisa Rp8.800')).toBeTruthy()
    // Keranjang masih berisi: uang belum tertutup, pesanan belum boleh hilang.
    expect(screen.queryByText(/Keranjang Masih Kosong/i)).toBeNull()
  })

  it('sesudah lunas dan kasir menekan Selesai: keranjang dikosongkan & modal tertutup', async () => {
    const onSelesaiBayar = vi.fn()
    render(
      <PenyediaBahasa>
        <LayarKasir
          metodeBayar={METODE}
          keadaanBayar="berhasil"
          onSelesaiBayar={onSelesaiBayar}
          terakhirBayar={{
            jumlah: 13800,
            kembalian: 0,
            totalDibayar: 13800,
            totalPesanan: 13800,
            lunas: true,
            dobel: false,
            sisa: 0,
          }}
        />
      </PenyediaBahasa>,
    )
    bukaBayar()

    fireEvent.click(screen.getByText('Selesai'))

    await waitFor(() => {
      expect(screen.getByText(/Keranjang Masih Kosong/i)).toBeTruthy()
    })
    expect(onSelesaiBayar).toHaveBeenCalled()
  })

  it('pesan galat peladen (mis. BY-301) tampil apa adanya di kasir', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir metodeBayar={METODE} pesanBayar="BY-301: pembayaran melebihi total pesanan." />
      </PenyediaBahasa>,
    )
    bukaBayar()

    expect(screen.getByText(/BY-301/)).toBeTruthy()
  })

  it('tombol Batal di layar Bayar menutup modal tanpa mencatat uang', () => {
    const onBayar = vi.fn()
    render(
      <PenyediaBahasa>
        <LayarKasir metodeBayar={METODE} onBayar={onBayar} />
      </PenyediaBahasa>,
    )
    bukaBayar()

    fireEvent.click(screen.getByTestId('batal').querySelector('button') as HTMLButtonElement)
    expect(screen.queryByTestId('metode-Tunai')).toBeNull()
    expect(onBayar).not.toHaveBeenCalled()
  })

  it('berkas layar kasir tidak lagi memuat daftar metode bayar keras-kode', async () => {
    // Penjaga regresi: kalau seseorang menambah kembali 'qris'/'kartu' sebagai
    // pilihan yang ditulis di dalam LayarKasir, uji ini merah.
    //
    // Komentar dibuang lebih dulu — catatan sejarah di kepala berkas memang
    // MENYEBUT metode lama untuk menjelaskan kenapa diganti, dan itu bukan kode.
    const berkas = await import('./LayarKasir?raw')
    const isi = (berkas as { default: string }).default
    const kode = isi.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')

    expect(kode).not.toMatch(/'qris'/)
    expect(kode).not.toMatch(/'kartu'/)
    expect(kode).not.toMatch(/QRIS Dinamis/)
    // Tidak ada pula pecahan uang cepat versi layar kasir: itu milik Bayar.tsx.
    expect(kode).not.toMatch(/PECAHAN_UANG_CEPAT/)
  })
})
