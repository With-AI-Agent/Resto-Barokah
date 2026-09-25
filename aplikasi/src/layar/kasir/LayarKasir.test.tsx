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
          shiftAktif={{
            id: 'shift-pos-01',
            cabangId: 'cab-01',
            modalAwal: 100000,
            dibukaPada: '2026-09-24T08:00:00Z',
          }}
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
            dibukaPada: new Date().toISOString(),
          }}
          uangSeharusnyaPerkiraan={300000}
        />
      </PenyediaBahasa>,
    )

    const tombolTutupKas = screen.getByRole('button', { name: /🔴\s*Tutup Kas/i })
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

  // ---------------------------------------------- T7-04 Wajib Shift di Layar Kasir
  it('menampilkan banner peringatan wajib buka kas jika shift belum dibuka (T7-04)', () => {
    render(
      <PenyediaBahasa>
        <LayarKasir shiftAktif={null} wajibShift={true} />
      </PenyediaBahasa>,
    )

    expect(screen.getByTestId('banner-wajib-shift')).toBeDefined()
    expect(screen.getByText(/Kasir belum membuka shift kas/i)).toBeDefined()
    expect(screen.getByRole('button', { name: /Buka Kas Sekarang/i })).toBeDefined()
  })

  it('mengklik tombol bayar saat belum ada shift membuka modal Buka Kas (T7-04)', async () => {
    render(
      <PenyediaBahasa>
        <LayarKasir shiftAktif={null} wajibShift={true} />
      </PenyediaBahasa>,
    )

    // Tambah item ke keranjang
    fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))

    // Klik tombol bayar pesanan
    const btnBayar = screen.getByRole('button', { name: /Bayar Pesanan/i })
    fireEvent.click(btnBayar)

    // Modal Buka Kas muncul secara otomatis untuk memandu kasir
    expect(screen.getByText('Buka Shift Kasir')).toBeDefined()
    expect(screen.getByLabelText(/Modal Awal Kasir/i)).toBeDefined()
  })

  // ---------------------------------------------- T7-05 Pengingat Shift di Layar Kasir
  it('menampilkan banner pengingat shift saat melewati jam tutup dan membuka modal Tutup Kas (T7-05)', () => {
    const shiftHariIni = {
      id: 'shift-pos-01',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: new Date('2026-09-24T10:00:00').toISOString(),
    }
    // Jam 22:30 (melewati jam tutup 22:00)
    const waktuLewat = new Date('2026-09-24T22:30:00')

    render(
      <PenyediaBahasa>
        <LayarKasir
          shiftAktif={shiftHariIni}
          jamTutup="22:00"
          waktuSekarangPengingat={waktuLewat}
          uangSeharusnyaPerkiraan={150000}
        />
      </PenyediaBahasa>,
    )

    const bannerPengingat = screen.getByTestId('pengingat-shift')
    expect(bannerPengingat).toBeDefined()
    expect(bannerPengingat.getAttribute('data-tingkat')).toBe('lewat_jam_tutup')

    // Klik tombol tutup kas di banner pengingat
    const btnTutup = screen.getByRole('button', { name: /Tutup Kas Sekarang/i })
    fireEvent.click(btnTutup)

    // Dialog Tutup Kas terbuka
    expect(screen.getByText('Tutup Shift Kasir')).toBeDefined()
  })

  it('menampilkan banner pengingat kritis saat shift melewati tengah malam (T7-05)', () => {
    const shiftKemarin = {
      id: 'shift-pos-kemarin',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: new Date('2026-09-23T15:00:00').toISOString(),
    }
    // Hari berikutnya jam 08:00
    const waktuBesok = new Date('2026-09-24T08:00:00')

    render(
      <PenyediaBahasa>
        <LayarKasir
          shiftAktif={shiftKemarin}
          jamTutup="22:00"
          waktuSekarangPengingat={waktuBesok}
        />
      </PenyediaBahasa>,
    )

    const bannerPengingat = screen.getByTestId('pengingat-shift')
    expect(bannerPengingat).toBeDefined()
    expect(bannerPengingat.getAttribute('data-tingkat')).toBe('melewati_tengah_malam')
    expect(screen.getByText(/melewati tengah malam/i)).toBeDefined()
  })

  // ---------------------------------------------- T7-06 Koreksi Modal Awal Shift
  it('menampilkan tombol koreksi modal saat shift aktif dan membuka dialog KoreksiModal (T7-06)', () => {
    const shift = {
      id: 'shift-pos-01',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: new Date().toISOString(),
    }

    render(
      <PenyediaBahasa>
        <LayarKasir shiftAktif={shift} />
      </PenyediaBahasa>,
    )

    const btnKoreksi = screen.getByRole('button', { name: /Koreksi Modal Awal/i })
    expect(btnKoreksi).toBeDefined()

    fireEvent.click(btnKoreksi)

    expect(screen.getByTestId('koreksi-modal')).toBeDefined()
    expect(screen.getByTestId('modal-awal-saat-ini').textContent).toContain('100.000')
  })

  it('memproses koreksi modal awal shift melalui onKoreksiModal (T7-06)', async () => {
    const shift = {
      id: 'shift-pos-01',
      cabangId: 'cab-01',
      modalAwal: 100000,
      dibukaPada: new Date().toISOString(),
    }
    const atasan = [{ id: 'owner-01', nama: 'Pak Hendra', peran: 'owner_pusat' }]
    const onKoreksi = vi.fn().mockResolvedValue({
      sukses: true,
      pesan: 'Modal awal berhasil dikoreksi.',
      data: { modalAwalBaru: 150000 },
    })

    render(
      <PenyediaBahasa>
        <LayarKasir shiftAktif={shift} daftarAtasan={atasan} onKoreksiModal={onKoreksi} />
      </PenyediaBahasa>,
    )

    const btnKoreksi = screen.getByRole('button', { name: /Koreksi Modal Awal/i })
    fireEvent.click(btnKoreksi)

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const inputPin = screen.getByLabelText(/PIN Atasan/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    fireEvent.change(inputAlasan, { target: { value: 'Ketinggalan di brankas' } })
    fireEvent.change(inputPin, { target: { value: '738294' } })

    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(onKoreksi).toHaveBeenCalledWith({
        shiftId: 'shift-pos-01',
        modalAwalBaru: 150000,
        alasan: 'Ketinggalan di brankas',
        disetujuiOleh: 'owner-01',
        pinAtasan: '738294',
      })
    })
  })
})
