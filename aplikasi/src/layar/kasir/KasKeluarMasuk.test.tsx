/**
 * @vitest-environment jsdom
 */
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { KasKeluarMasuk } from './KasKeluarMasuk'
import { PenyediaBahasa } from '../../bahasa'

function renderDenganBahasa(ui: React.ReactElement) {
  return render(<PenyediaBahasa>{ui}</PenyediaBahasa>)
}

describe('KasKeluarMasuk (T7-03 — Kas Masuk, Kas Keluar, Setoran, dan Koreksi)', () => {
  afterEach(() => {
    cleanup()
  })

  it('merender judul dan pilihan jenis kas secara default', () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(
      <KasKeluarMasuk
        shiftId="shift-1"
        cabangId="cabang-1"
        namaCabang="Resto Barokah Pusat"
        namaKasir="Rina"
        onSimpan={onSimpan}
      />,
    )

    expect(screen.getByText(/Pencatatan Pergerakan Kas/i)).toBeDefined()
    expect(screen.getByTestId('pilih-jenis-keluar')).toBeDefined()
    expect(screen.getByTestId('pilih-jenis-masuk')).toBeDefined()
    expect(screen.getByTestId('pilih-jenis-setoran')).toBeDefined()
    expect(screen.getByTestId('pilih-jenis-koreksi')).toBeDefined()
  })

  it('dapat beralih jenis pergerakan kas', () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    const btnMasuk = screen.getByTestId('pilih-jenis-masuk')
    fireEvent.click(btnMasuk)
    expect(btnMasuk.className).toContain('opsi-jenis-btn--aktif')

    // Saran alasan untuk kas masuk harus muncul
    expect(screen.getByText('Tambah uang kembalian / receh')).toBeDefined()
  })

  it('tombol nominal cepat menambah jumlah dan reset mengosongkannya', () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    const inputJumlah = screen.getByLabelText(/Jumlah Uang/i) as HTMLInputElement
    expect(inputJumlah.value).toBe('')

    fireEvent.click(screen.getByText('+Rp10.000'))
    expect(inputJumlah.value).toContain('10.000')

    fireEvent.click(screen.getByText('+Rp50.000'))
    expect(inputJumlah.value).toContain('60.000')

    fireEvent.click(screen.getByText('Reset'))
    expect(inputJumlah.value).toBe('')
  })

  it('mengklik saran alasan mengisi input alasan', () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    const saranEsBatu = screen.getByText('Beli es batu kristal')
    fireEvent.click(saranEsBatu)

    const inputAlasan = screen.getByLabelText(/Alasan \/ Keperluan/i) as HTMLInputElement
    expect(inputAlasan.value).toBe('Beli es batu kristal')
  })

  it('menolak pengiriman jika jumlah uang 0', async () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    // Isi alasan tanpa isi jumlah
    fireEvent.click(screen.getByText('Beli es batu kristal'))

    // Tombol submit lumpuh saat jumlah <= 0
    const btnSimpan = screen.getByText('Simpan Catatan Kas').closest('button')!
    expect(btnSimpan.hasAttribute('disabled')).toBe(true)
  })

  it('menolak pengiriman jika alasan kosong', async () => {
    const onSimpan = vi.fn()
    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    // Isi nominal tanpa mengisi alasan
    fireEvent.click(screen.getByText('+Rp10.000'))

    // Tombol submit lumpuh saat alasan kosong
    const btnSimpan = screen.getByText('Simpan Catatan Kas').closest('button')!
    expect(btnSimpan.hasAttribute('disabled')).toBe(true)

    // Form disubmit langsung harus memunculkan pesan galat alasan wajib
    const formEl = btnSimpan.closest('form')!
    fireEvent.submit(formEl)

    const alertEl = await screen.findByRole('alert')
    expect(alertEl.textContent).toContain('tidak boleh kosong')
    expect(onSimpan).not.toHaveBeenCalled()
  })

  it('berhasil menyimpan pergerakan kas keluar dan menampilkan layar sukses', async () => {
    const onSimpan = vi.fn().mockResolvedValue({
      sukses: true,
      data: {
        id: 'kp-123',
        shiftId: 'shift-1',
        cabangId: 'cabang-1',
        jenis: 'keluar',
        jumlah: 25000,
        alasan: 'Beli es batu kristal',
        pelakuId: 'user-1',
        dibuatPada: '2026-09-24T10:00:00Z',
      },
    })

    const onTutup = vi.fn()

    renderDenganBahasa(
      <KasKeluarMasuk
        shiftId="shift-1"
        cabangId="cabang-1"
        namaCabang="Resto Barokah Pusat"
        namaKasir="Rina"
        onSimpan={onSimpan}
        onTutup={onTutup}
      />,
    )

    // Isi nominal
    fireEvent.click(screen.getByText('+Rp20.000'))
    const inputJumlah = screen.getByLabelText(/Jumlah Uang/i)
    fireEvent.change(inputJumlah, { target: { value: '25000' } })

    // Pilih alasan
    fireEvent.click(screen.getByText('Beli es batu kristal'))

    // Kirim
    const btnSimpan = screen.getByText('Simpan Catatan Kas').closest('button')!
    expect(btnSimpan.hasAttribute('disabled')).toBe(false)
    fireEvent.click(btnSimpan)

    await waitFor(() => {
      expect(onSimpan).toHaveBeenCalledWith(
        expect.objectContaining({
          jenis: 'keluar',
          jumlah: 25000,
          alasan: 'Beli es batu kristal',
          shiftId: 'shift-1',
          cabangId: 'cabang-1',
        }),
      )
    })

    // Layar sukses harus tampil
    expect(await screen.findByTestId('layar-kas-pergerakan-sukses')).toBeDefined()
    expect(screen.getByText(/Pergerakan kas berhasil dicatat/i)).toBeDefined()
    expect(screen.getByText(/- Rp25\.000/)).toBeDefined()

    // Tombol selesai
    const btnSelesai = screen.getByText('Selesai').closest('button')!
    fireEvent.click(btnSelesai)
    expect(onTutup).toHaveBeenCalledTimes(1)
  })

  it('menampilkan galat bila onSimpan mengembalikan kesalahan dari server', async () => {
    const onSimpan = vi.fn().mockResolvedValue({
      sukses: false,
      pesan: 'Shift kas sudah ditutup. Uang tidak dapat keluar.',
    })

    renderDenganBahasa(<KasKeluarMasuk shiftId="shift-1" cabangId="cabang-1" onSimpan={onSimpan} />)

    fireEvent.click(screen.getByText('+Rp10.000'))
    fireEvent.click(screen.getByText('Beli es batu kristal'))

    const btnSimpan = screen.getByText('Simpan Catatan Kas').closest('button')!
    fireEvent.click(btnSimpan)

    const alertEl = await screen.findByRole('alert')
    expect(alertEl.textContent).toContain('Shift kas sudah ditutup. Uang tidak dapat keluar.')
  })

  it('tombol batal memicu callback onBatal', () => {
    const onSimpan = vi.fn()
    const onBatal = vi.fn()

    renderDenganBahasa(
      <KasKeluarMasuk
        shiftId="shift-1"
        cabangId="cabang-1"
        onSimpan={onSimpan}
        onBatal={onBatal}
      />,
    )

    const btnBatal = screen.getByText('Batal').closest('button')!
    fireEvent.click(btnBatal)
    expect(onBatal).toHaveBeenCalledTimes(1)
  })
})
