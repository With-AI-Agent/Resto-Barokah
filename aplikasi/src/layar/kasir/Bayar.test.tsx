// @vitest-environment jsdom
/**
 * Uji Bayar.tsx (T5-01) — layar pembayaran kasir.
 *
 * Yang dibuktikan (DoD T5-01 + mitigasi risikonya):
 *  - metode bayar tampil dari data yang diberi kontainer (tidak ada daftar
 *    bawaan di layar — yang nonaktif memang tidak dikirim);
 *  - tombol uang cepat (Uang pas/50rb/100rb) mengisi uang diterima;
 *  - kembalian tampil besar, dan uang yang kurang membuat tinjau terkunci;
 *  - konfirmasi nilai dulu, baru dieksekusi (salah tekan nominal bisa dibatalkan);
 *  - non-tunai wajib nomor referensi;
 *  - pembayaran sebagian sah → layar menawarkan "Bayar sisa";
 *  - keadaan memuat/gagal/tanpa metode punya penjelasan, bukan layar kosong.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { Bayar } from './Bayar'
import type { MetodeBayar, Tagihan } from './Bayar'

afterEach(() => {
  cleanup()
})

const METODE: MetodeBayar[] = [
  { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuhReferensi: false, urutan: 1 },
  { id: 'm-qris', nama: 'QRIS', jenis: 'non_tunai', butuhReferensi: true, urutan: 2 },
]

const TAGIHAN: Tagihan = { id: 'pes-1', nomor: 101, total: 62100, sudahDibayar: 0 }

function klikTinjau() {
  fireEvent.click(screen.getByText('Tinjau pembayaran'))
}

describe('Bayar (T5-01)', () => {
  it('menampilkan total tagihan dan jumlah yang harus dibayar', () => {
    render(<Bayar tagihan={TAGIHAN} metode={METODE} />)
    // Rp62.100 muncul dua kali: baris total tagihan dan baris yang harus dibayar
    // (belum ada pembayaran) — keduanya memang wajib benar.
    expect(screen.getAllByText('Rp62.100').length).toBe(2)
    expect(screen.getByTestId('sisa-tagihan').textContent).toContain('Rp62.100')
  })

  it('metode yang diberi kontainer tampil apa adanya (tanpa daftar bawaan layar)', () => {
    render(<Bayar tagihan={TAGIHAN} metode={METODE} />)
    expect(screen.getByTestId('metode-Tunai')).toBeTruthy()
    expect(screen.getByTestId('metode-QRIS')).toBeTruthy()
    // Layar tidak pernah mengarang metode sendiri: hanya dua itu yang ada.
    expect(screen.queryByText('Kartu')).toBeNull()
  })

  it('tunai: tombol uang cepat mengisi uang diterima dan kembalian tampil besar', () => {
    render(<Bayar tagihan={TAGIHAN} metode={METODE} />)
    fireEvent.click(screen.getByText('Rp100.000'))
    expect(screen.getByTestId('kembalian').textContent).toContain('Rp37.900')
    fireEvent.click(screen.getByText('Uang pas'))
    expect(screen.getByTestId('kembalian').textContent).toContain('Rp0')
  })

  it('uang diterima kurang → tinjau terkunci dan selisihnya disebut', () => {
    render(<Bayar tagihan={TAGIHAN} metode={METODE} />)
    fireEvent.click(screen.getByText('Rp50.000'))
    expect(screen.getByText(/kurang Rp12\.100/)).toBeTruthy()
    const tinjau = screen.getByTestId('tinjau').querySelector('button') as HTMLButtonElement
    expect(tinjau.disabled).toBe(true)
  })

  it('konfirmasi dulu baru dicatat; "Periksa lagi" membatalkan tanpa memanggil apa pun', async () => {
    const onBayar = vi.fn().mockResolvedValue({
      jumlah: 62100,
      kembalian: 37900,
      totalDibayar: 62100,
      totalPesanan: 62100,
      lunas: true,
      dobel: false,
    })
    render(<Bayar tagihan={TAGIHAN} metode={METODE} onBayar={onBayar} />)
    fireEvent.click(screen.getByText('Rp100.000'))

    klikTinjau()
    expect(screen.getByText('Periksa dulu sebelum dicatat')).toBeTruthy()
    expect(onBayar).not.toHaveBeenCalled()

    fireEvent.click(screen.getByText('Periksa lagi'))
    expect(onBayar).not.toHaveBeenCalled()

    klikTinjau()
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))
    expect(onBayar).toHaveBeenCalledWith({
      metodeId: 'm-tunai',
      jumlah: 62100,
      diterima: 100000,
      referensi: null,
    })
  })

  it('non-tunai: tanpa referensi tinjau terkunci, dengan referensi terkirim', () => {
    const onBayar = vi.fn().mockResolvedValue(null)
    render(<Bayar tagihan={TAGIHAN} metode={METODE} onBayar={onBayar} />)
    fireEvent.click(screen.getByTestId('metode-QRIS').querySelector('button') as HTMLButtonElement)

    const tinjau = screen.getByTestId('tinjau').querySelector('button') as HTMLButtonElement
    expect(tinjau.disabled).toBe(true)

    fireEvent.change(screen.getByLabelText(/referensi/i), { target: { value: 'QRIS-8899' } })
    expect(tinjau.disabled).toBe(false)

    klikTinjau()
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))
    expect(onBayar).toHaveBeenCalledWith({
      metodeId: 'm-qris',
      jumlah: 62100,
      diterima: null,
      referensi: 'QRIS-8899',
    })
  })

  it('tagihan yang sudah dibayar sebagian → yang ditagih hanya sisanya', () => {
    render(<Bayar tagihan={{ ...TAGIHAN, sudahDibayar: 30000 }} metode={METODE} />)
    expect(screen.getByTestId('sisa-tagihan').textContent).toContain('Rp32.100')
    fireEvent.click(screen.getByText('Uang pas'))
    expect(screen.getByTestId('kembalian').textContent).toContain('Rp0')
  })

  it('sesudah pembayaran sebagian: layar menawarkan bayar sisa, belum menyebut lunas', () => {
    render(
      <Bayar
        tagihan={TAGIHAN}
        metode={METODE}
        keadaan="berhasil"
        terakhir={{
          jumlah: 30000,
          kembalian: 0,
          totalDibayar: 30000,
          totalPesanan: 62100,
          lunas: false,
          dobel: false,
          sisa: 32100,
        }}
      />,
    )
    expect(screen.getByText('Bayar sisa Rp32.100')).toBeTruthy()
    expect(screen.getByText(/Sisa tagihan Rp32\.100/)).toBeTruthy()
    expect(screen.queryByText(/lunas/i)).toBeNull()
  })

  it('sesudah lunas: kembalian besar tampil dan tidak ada tawaran bayar sisa', () => {
    render(
      <Bayar
        tagihan={TAGIHAN}
        metode={METODE}
        keadaan="berhasil"
        terakhir={{
          jumlah: 62100,
          kembalian: 37900,
          totalDibayar: 62100,
          totalPesanan: 62100,
          lunas: true,
          dobel: false,
          sisa: 0,
        }}
      />,
    )
    expect(screen.getByTestId('kembalian').textContent).toContain('Rp37.900')
    expect(screen.getByText(/Tagihan No\. 101 lunas/)).toBeTruthy()
    expect(screen.queryByText(/Bayar sisa/)).toBeNull()
  })

  it('ulangan kunci idempoten diberi tanda, tidak berpura-pura uang baru masuk', () => {
    render(
      <Bayar
        tagihan={TAGIHAN}
        metode={METODE}
        keadaan="berhasil"
        terakhir={{
          jumlah: 30000,
          kembalian: 0,
          totalDibayar: 30000,
          totalPesanan: 62100,
          lunas: false,
          dobel: true,
          sisa: 32100,
        }}
      />,
    )
    expect(screen.getByText(/tidak dicatat dua kali/)).toBeTruthy()
  })

  it('keadaan memuat, gagal, dan tanpa metode punya penjelasan', () => {
    const { unmount } = render(<Bayar tagihan={TAGIHAN} metode={METODE} keadaan="memuat" />)
    expect(screen.getByText('Memuat metode pembayaran...')).toBeTruthy()
    unmount()

    const gagal = render(
      <Bayar tagihan={TAGIHAN} metode={METODE} keadaan="gagal" pesan="jaringan putus" />,
    )
    expect(screen.getByText('Gagal memuat metode pembayaran')).toBeTruthy()
    expect(screen.getByText('jaringan putus')).toBeTruthy()
    gagal.unmount()

    render(<Bayar tagihan={TAGIHAN} metode={[]} />)
    expect(screen.getByText('Belum ada metode bayar aktif')).toBeTruthy()
  })

  it('pesan galat dari peladen tampil apa adanya (termasuk kode BY-301)', () => {
    render(
      <Bayar
        tagihan={TAGIHAN}
        metode={METODE}
        pesan="BY-301: pembayaran 40000 membuat total dibayar melebihi total pesanan."
      />,
    )
    expect(screen.getByText(/BY-301/)).toBeTruthy()
  })

  it('tombol batal mudah dijangkau dan memanggil onBatal', () => {
    const onBatal = vi.fn()
    render(<Bayar tagihan={TAGIHAN} metode={METODE} onBatal={onBatal} />)
    fireEvent.click(screen.getByTestId('batal').querySelector('button') as HTMLButtonElement)
    expect(onBatal).toHaveBeenCalled()
  })
})
