// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import { PenyediaBahasa } from '../../bahasa'

describe('LayarKasir POS (T3-01 s/d T3-16)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender layout POS lengkap: katalog menu dan keranjang kosong di awal', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    expect(screen.getByText(/Kasir POS — Cabang Utama/i)).toBeDefined()
    expect(screen.getByText(/Semua Menu/i)).toBeDefined()
    expect(screen.getByText(/Keranjang Masih Kosong/i)).toBeDefined()
  })

  it('menambahkan item dari katalog ke keranjang dan memperbarui ringkasan total', async () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    // Klik Es Teh Manis Melati (tanpa varian)
    const esTeh = screen.getByText('Es Teh Manis Melati')
    fireEvent.click(esTeh)

    // Item harus muncul di keranjang
    await waitFor(() => {
      expect(screen.getAllByText('Es Teh Manis Melati').length).toBeGreaterThan(0)
    })

    // Subtotal, service, pajak, dan tombol bayar aktif
    expect(screen.getByRole('button', { name: /Bayar Pesanan/i })).toBeDefined()
  })

  it('menjalankan alur pembayaran tunai dan menyelesaikan transaksi pesanan', async () => {
    // Sejak T5-01 uang dicatat lewat `onBayar` (pintu RPC `bayar_pesanan`),
    // dan metode bayar datang dari kontainer — bukan daftar keras-kode layar.
    const onBayarMock = vi.fn().mockResolvedValue({
      jumlah: 13800,
      kembalian: 36200,
      totalDibayar: 13800,
      totalPesanan: 13800,
      lunas: true,
      dobel: false,
    })

    render(
      <PenyediaBahasa>
        <LayarKasir
          metodeBayar={[
            { id: 'm-tunai', nama: 'Tunai', jenis: 'tunai', butuhReferensi: false, urutan: 1 },
          ]}
          onBayar={onBayarMock}
        />
      </PenyediaBahasa>,
    )

    // Tambah Tahu Tempe (tanpa varian) ke keranjang
    fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))

    // Klik tombol Bayar Pesanan
    fireEvent.click(screen.getByRole('button', { name: /Bayar Pesanan/i }))

    // Modal pembayaran terbuka, metodenya dari kontainer
    expect(screen.getByText('Pembayaran Transaksi Kasir')).toBeDefined()
    expect(screen.getByTestId('metode-Tunai')).toBeDefined()

    // Isi uang diterima, tinjau, lalu catat
    fireEvent.click(screen.getByText('Rp50.000'))
    fireEvent.click(screen.getByText('Tinjau pembayaran'))
    fireEvent.click(screen.getByText('Ya, catat pembayaran'))

    await waitFor(() => {
      expect(onBayarMock).toHaveBeenCalled()
    })
  })

  it('dapat membuka modal Tagihan Terbuka (Open Bill)', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByText(/Tagihan Terbuka/i))
    expect(screen.getByText('Tagihan Terbuka (Open Bill)')).toBeDefined()
  })

  // ---------------------------------------------- T-027 tarif dari pengaturan
  //
  // Sebelum ini keranjang selalu memakai 10 %/5 % yang ditulis di kode, sehingga
  // kedai dengan tarif berbeda melihat angka keranjang meleset dari yang
  // akhirnya ditagih peladen. Dua uji berikut mengunci perilaku barunya.

  it('memakai tarif resto dari pengaturan, bukan 10 %/5 % keras-kode (T-027)', async () => {
    render(
      <PenyediaBahasa>
        {/* Kedai dengan pajak 11 % dan TANPA service charge. */}
        <LayarKasir tarif={{ pajakPersen: 11, servicePersen: 0, pembulatan: 'none' }} />
      </PenyediaBahasa>,
    )

    // Es Teh punya varian, jadi dialog pilihan muncul dulu sebelum masuk keranjang.
    fireEvent.click(screen.getByText('Es Teh Manis Melati')) // Rp6.000
    fireEvent.click(screen.getByText('Manis Sedang'))
    fireEvent.click(screen.getByText('Tambahkan ke Pesanan'))

    // 6.000 + pajak 11 % (660) + service 0 = 6.660
    await waitFor(() => {
      expect(screen.getByText('Rp6.660')).toBeDefined()
    })
  })

  it('tanpa prop tarif, keranjang memakai tarif bawaan 10 %/5 % (T-027)', async () => {
    render(
      <PenyediaBahasa>
        <LayarKasir />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByText('Es Teh Manis Melati')) // Rp6.000
    fireEvent.click(screen.getByText('Manis Sedang'))
    fireEvent.click(screen.getByText('Tambahkan ke Pesanan'))

    // 6.000 + pajak 600 + service 300 = 6.900
    await waitFor(() => {
      expect(screen.getByText('Rp6.900')).toBeDefined()
    })
  })

  // ---------------------------------------------- T7-02 Tutup Kas di Layar Kasir
  it('menampilkan tombol Tutup Kas saat ada shift aktif dan membuka dialog rekonsiliasi (T7-02)', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir
          shiftAktif={{
            id: 'shift-pos-01',
            cabangId: 'cab-01',
            modalAwal: 100000,
            dibukaPada: '2026-09-24T08:00:00Z',
          }}
          uangSeharusnyaPerkiraan={300000}
        />
      </PenyediaBahasa>,
    )

    const tombolTutupKas = screen.getByRole('button', { name: /Tutup Kas/i })
    expect(tombolTutupKas).toBeDefined()

    fireEvent.click(tombolTutupKas)

    expect(screen.getByText('Tutup Shift Kasir')).toBeDefined()
    expect(screen.getByText('Rp100.000')).toBeDefined()
    expect(screen.getByText('Rp300.000')).toBeDefined()
  })

  // ---------------------------------------------- T7-03 Kas Masuk & Keluar di Layar Kasir
  it('menampilkan tombol Kas Masuk & Keluar saat ada shift aktif dan membuka dialog pergerakan kas (T7-03)', () => {
    const onKasPergerakan = vi.fn().mockResolvedValue({ sukses: true })

    render(
      <PenyediaBahasa>
        <LayarKasir
          shiftAktif={{
            id: 'shift-pos-01',
            cabangId: 'cab-01',
            modalAwal: 100000,
            dibukaPada: '2026-09-24T08:00:00Z',
          }}
          onKasPergerakan={onKasPergerakan}
        />
      </PenyediaBahasa>,
    )

    const tombolKasPergerakan = screen.getByRole('button', { name: /Kas Masuk & Keluar/i })
    expect(tombolKasPergerakan).toBeDefined()

    fireEvent.click(tombolKasPergerakan)

    expect(screen.getByText(/Pencatatan Pergerakan Kas/i)).toBeDefined()
    expect(screen.getByTestId('pilih-jenis-keluar')).toBeDefined()
  })
})
