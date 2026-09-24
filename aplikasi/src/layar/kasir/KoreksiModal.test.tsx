/**
 * @vitest-environment jsdom
 */
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { KoreksiModal } from './KoreksiModal'
import { PenyediaBahasa } from '../../bahasa'

function renderDenganBahasa(ui: React.ReactElement) {
  return render(<PenyediaBahasa>{ui}</PenyediaBahasa>)
}

describe('KoreksiModal Component (T7-06)', () => {
  afterEach(() => {
    cleanup()
  })

  const atasanDummy = [
    { id: 'atasan-001', nama: 'Pak Hendra', peran: 'owner_pusat' },
    { id: 'atasan-002', nama: 'Ibu Ratna', peran: 'admin_cabang' },
  ]

  it('merender nilai modal awal saat ini dan informasi bantuan', () => {
    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={vi.fn()}
      />,
    )

    const modalSaatIniEl = screen.getByTestId('modal-awal-saat-ini')
    expect(modalSaatIniEl.textContent).toContain('100.000')

    const selisihEl = screen.getByTestId('selisih-koreksi')
    expect(selisihEl.textContent).toContain('0')
  })

  it('menonaktifkan tombol simpan jika modal awal baru sama dengan modal saat ini', () => {
    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={vi.fn()}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const inputPin = screen.getByLabelText(/PIN Atasan/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    // Isi modal baru sama dengan modal saat ini (100.000)
    fireEvent.change(inputModalBaru, { target: { value: '100000' } })
    fireEvent.change(inputAlasan, { target: { value: 'Salah hitung' } })
    fireEvent.change(inputPin, { target: { value: '123456' } })

    expect((tombolSimpan as HTMLButtonElement).disabled).toBe(true)
  })

  it('menonaktifkan tombol simpan jika alasan kosong', () => {
    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={vi.fn()}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const inputPin = screen.getByLabelText(/PIN Atasan/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    fireEvent.change(inputAlasan, { target: { value: '   ' } })
    fireEvent.change(inputPin, { target: { value: '123456' } })

    expect((tombolSimpan as HTMLButtonElement).disabled).toBe(true)
  })

  it('menonaktifkan tombol simpan jika PIN atasan belum diisi', () => {
    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={vi.fn()}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    fireEvent.change(inputAlasan, { target: { value: 'Tertinggal pecahan Rp50.000' } })

    expect((tombolSimpan as HTMLButtonElement).disabled).toBe(true)
  })

  it('menghitung selisih positif dan negatif secara dinamis', () => {
    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={vi.fn()}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const selisihEl = screen.getByTestId('selisih-koreksi')

    // Bertambah 50.000
    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    expect(selisihEl.textContent).toContain('+')
    expect(selisihEl.textContent).toContain('50.000')

    // Berkurang 20.000
    fireEvent.change(inputModalBaru, { target: { value: '80000' } })
    expect(selisihEl.textContent).toContain('20.000')
  })

  it('memanggil onSimpanKoreksi dengan argumen yang tepat saat formulir valid', async () => {
    const onSimpan = vi.fn().mockResolvedValue({
      sukses: true,
      pesan: 'Modal awal berhasil dikoreksi.',
    })

    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={onSimpan}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const inputPin = screen.getByLabelText(/PIN Atasan/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    fireEvent.change(inputAlasan, { target: { value: 'Uang receh tertinggal di brankas' } })
    fireEvent.change(inputPin, { target: { value: '738294' } })

    expect((tombolSimpan as HTMLButtonElement).disabled).toBe(false)
    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      expect(onSimpan).toHaveBeenCalledWith({
        shiftId: 'shift-123',
        modalAwalBaru: 150000,
        alasan: 'Uang receh tertinggal di brankas',
        disetujuiOleh: 'atasan-001',
        pinAtasan: '738294',
      })
    })

    const pesanEl = screen.getByTestId('pesan-koreksi')
    expect(pesanEl.textContent).toContain('berhasil')
  })

  it('menampilkan galat bila peladen menolak permohonan koreksi modal', async () => {
    const onSimpan = vi.fn().mockResolvedValue({
      sukses: false,
      pesan: 'PIN atasan tidak valid atau sudah kadaluarsa.',
    })

    renderDenganBahasa(
      <KoreksiModal
        shiftId="shift-123"
        modalAwalSaatIni={100000}
        daftarAtasan={atasanDummy}
        onSimpanKoreksi={onSimpan}
      />,
    )

    const inputModalBaru = screen.getByLabelText(/Modal Awal Baru/i)
    const inputAlasan = screen.getByLabelText(/Alasan Koreksi/i)
    const inputPin = screen.getByLabelText(/PIN Atasan/i)
    const tombolSimpan = screen.getByRole('button', { name: /Simpan Koreksi Modal/i })

    fireEvent.change(inputModalBaru, { target: { value: '150000' } })
    fireEvent.change(inputAlasan, { target: { value: 'Salah hitung' } })
    fireEvent.change(inputPin, { target: { value: '999999' } })

    fireEvent.click(tombolSimpan)

    await waitFor(() => {
      const pesanEl = screen.getByTestId('pesan-koreksi')
      expect(pesanEl.textContent).toContain('PIN atasan tidak valid')
    })
  })
})
