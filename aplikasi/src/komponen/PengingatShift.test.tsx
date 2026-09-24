// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { PengingatShift, type ShiftAktifInfo } from './PengingatShift'
import { PenyediaBahasa } from '../bahasa'

afterEach(() => {
  cleanup()
})

const shiftNormal: ShiftAktifInfo = {
  id: 'shift-1',
  dibukaPada: new Date('2026-09-24T08:00:00Z').toISOString(),
  namaKasir: 'Rina',
  modalAwal: 100000,
}

describe('PengingatShift (T7-05)', () => {
  it('tidak menampilkan apa pun bila shiftAktif kosong (null)', () => {
    const onTutup = vi.fn()
    const { container } = render(
      <PenyediaBahasa>
        <PengingatShift shiftAktif={null} onTutupKas={onTutup} />
      </PenyediaBahasa>,
    )
    expect(container.firstChild).toBeNull()
  })

  it('tidak menampilkan apa pun jika shift masih normal di tengah jam operasional', () => {
    const onTutup = vi.fn()
    // Dibuka jam 08:00, waktu sekarang jam 11:00 di hari yang sama
    const waktuSekarang = new Date('2026-09-24T11:00:00')
    const shiftHariIni: ShiftAktifInfo = {
      ...shiftNormal,
      dibukaPada: new Date('2026-09-24T08:00:00').toISOString(),
    }

    const { container } = render(
      <PenyediaBahasa>
        <PengingatShift
          shiftAktif={shiftHariIni}
          jamTutup="22:00"
          waktuSekarang={waktuSekarang}
          onTutupKas={onTutup}
        />
      </PenyediaBahasa>,
    )
    expect(container.firstChild).toBeNull()
  })

  it('menampilkan peringatan mendekati jam tutup dan dapat diabaikan', () => {
    const onTutup = vi.fn()
    const onAbaikan = vi.fn()
    // Jam 21:45 (15 menit sebelum jam tutup 22:00)
    const waktuSekarang = new Date('2026-09-24T21:45:00')
    const shiftHariIni: ShiftAktifInfo = {
      ...shiftNormal,
      dibukaPada: new Date('2026-09-24T15:00:00').toISOString(),
    }

    render(
      <PenyediaBahasa>
        <PengingatShift
          shiftAktif={shiftHariIni}
          jamTutup="22:00"
          waktuSekarang={waktuSekarang}
          onTutupKas={onTutup}
          onAbaikan={onAbaikan}
        />
      </PenyediaBahasa>,
    )

    const kotak = screen.getByTestId('pengingat-shift')
    expect(kotak).toBeTruthy()
    expect(kotak.getAttribute('data-tingkat')).toBe('mendekati_tutup')

    // Tekan tombol ingatkan nanti
    const btnAbaikan = screen.getByRole('button', { name: /ingatkan nanti/i })
    fireEvent.click(btnAbaikan)
    expect(onAbaikan).toHaveBeenCalledTimes(1)

    // Kotak mendekati tutup disembunyikan setelah diabaikan
    expect(screen.queryByTestId('pengingat-shift')).toBeNull()
  })

  it('menampilkan peringatan mendesak saat melewati jam tutup', () => {
    const onTutup = vi.fn()
    // Jam 22:15 (melewati jam tutup 22:00)
    const waktuSekarang = new Date('2026-09-24T22:15:00')
    const shiftHariIni: ShiftAktifInfo = {
      ...shiftNormal,
      dibukaPada: new Date('2026-09-24T14:00:00').toISOString(),
    }

    render(
      <PenyediaBahasa>
        <PengingatShift
          shiftAktif={shiftHariIni}
          jamTutup="22:00"
          waktuSekarang={waktuSekarang}
          onTutupKas={onTutup}
        />
      </PenyediaBahasa>,
    )

    const kotak = screen.getByTestId('pengingat-shift')
    expect(kotak).toBeTruthy()
    expect(kotak.getAttribute('data-tingkat')).toBe('lewat_jam_tutup')
    expect(screen.getByText(/Jam operasional telah berakhir/i)).toBeTruthy()

    // Klik tombol tutup kas
    const btnTutup = screen.getByRole('button', { name: /tutup kas sekarang/i })
    fireEvent.click(btnTutup)
    expect(onTutup).toHaveBeenCalledTimes(1)
  })

  it('menampilkan peringatan kritis saat shift melewati tengah malam (beda hari kalender)', () => {
    const onTutup = vi.fn()
    // Dibuka kemarin (2026-09-23), waktu sekarang hari ini (2026-09-24)
    const waktuSekarang = new Date('2026-09-24T09:00:00')
    const shiftKemarin: ShiftAktifInfo = {
      ...shiftNormal,
      dibukaPada: new Date('2026-09-23T16:00:00').toISOString(),
    }

    render(
      <PenyediaBahasa>
        <PengingatShift
          shiftAktif={shiftKemarin}
          jamTutup="22:00"
          waktuSekarang={waktuSekarang}
          onTutupKas={onTutup}
        />
      </PenyediaBahasa>,
    )

    const kotak = screen.getByTestId('pengingat-shift')
    expect(kotak).toBeTruthy()
    expect(kotak.getAttribute('data-tingkat')).toBe('melewati_tengah_malam')
    expect(screen.getByText(/melewati tengah malam/i)).toBeTruthy()
  })

  it('menampilkan peringatan durasi shift panjang melebihi 12 jam pada hari yang sama', () => {
    const onTutup = vi.fn()
    // Dibuka jam 06:00, waktu sekarang jam 19:00 (13 jam kemudian)
    const waktuSekarang = new Date('2026-09-24T19:00:00')
    const shiftPanjang: ShiftAktifInfo = {
      ...shiftNormal,
      dibukaPada: new Date('2026-09-24T06:00:00').toISOString(),
    }

    render(
      <PenyediaBahasa>
        <PengingatShift
          shiftAktif={shiftPanjang}
          jamTutup="23:00"
          waktuSekarang={waktuSekarang}
          onTutupKas={onTutup}
        />
      </PenyediaBahasa>,
    )

    const kotak = screen.getByTestId('pengingat-shift')
    expect(kotak).toBeTruthy()
    expect(kotak.getAttribute('data-tingkat')).toBe('durasi_panjang')
    expect(screen.getByText(/lebih dari 12 jam/i)).toBeTruthy()
  })
})
