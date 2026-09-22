// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { MasukStaf } from './MasukStaf'
import { PenyediaBahasa } from '../../bahasa'

describe('MasukStaf (T2-14)', () => {
  afterEach(() => {
    cleanup()
  })

  const stafDummy = [
    { id: 'usr-01', nama: 'Budi Santoso', email: 'budi@barokah.id', peran: 'kasir' as const },
    { id: 'usr-02', nama: 'Siti Rahma', email: 'siti@barokah.id', peran: 'pelayan' as const },
  ]

  it('merender daftar staf dan menampilkan instruksi pilih nama', () => {
    render(
      <PenyediaBahasa>
        <MasukStaf daftarStaf={stafDummy} onVerifikasiPin={vi.fn()} />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Budi Santoso')).toBeDefined()
    expect(screen.getByText('Siti Rahma')).toBeDefined()
    expect(screen.getByText(/Silakan pilih nama Anda/i)).toBeDefined()
  })

  it('membuka keypad PIN setelah nama pegawai dipilih dan memproses PIN 6 digit', async () => {
    const onVerifikasiMock = vi.fn().mockResolvedValue({ sukses: true })
    const onSuksesMock = vi.fn()

    render(
      <PenyediaBahasa>
        <MasukStaf
          daftarStaf={stafDummy}
          onVerifikasiPin={onVerifikasiMock}
          onMasukSukses={onSuksesMock}
        />
      </PenyediaBahasa>,
    )

    // Klik nama staf Budi
    fireEvent.click(screen.getByRole('button', { name: /Budi Santoso/i }))

    // Keypad muncul
    expect(screen.getByText('PIN Masuk: Budi Santoso')).toBeDefined()

    // Masukkan PIN 6 digit: 123456
    ;['1', '2', '3', '4', '5', '6'].forEach((digit) => {
      fireEvent.click(screen.getByRole('button', { name: digit }))
    })

    await waitFor(() => {
      expect(onVerifikasiMock).toHaveBeenCalledWith('budi@barokah.id', '123456')
      expect(onSuksesMock).toHaveBeenCalledWith(stafDummy[0])
    })
  })

  it('menampilkan pesan galat dan sisa percobaan jika PIN salah', async () => {
    const onVerifikasiMock = vi.fn().mockResolvedValue({
      sukses: false,
      kodeGalat: 'PIN_SALAH',
      sisaPercobaan: 3,
    })

    render(
      <PenyediaBahasa>
        <MasukStaf daftarStaf={stafDummy} onVerifikasiPin={onVerifikasiMock} />
      </PenyediaBahasa>,
    )

    fireEvent.click(screen.getByRole('button', { name: /Budi Santoso/i }))

    // Masukkan PIN 6 digit: 999999
    for (let i = 0; i < 6; i++) {
      fireEvent.click(screen.getByRole('button', { name: '9' }))
    }

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeDefined()
      expect(screen.getByText(/Sisa percobaan: 3x/i)).toBeDefined()
    })
  })

  it('menolak masuk jika perangkat tidak terdaftar', async () => {
    const onVerifikasiMock = vi.fn()

    render(
      <PenyediaBahasa>
        <MasukStaf
          daftarStaf={stafDummy}
          perangkatTerdaftar={false}
          onVerifikasiPin={onVerifikasiMock}
        />
      </PenyediaBahasa>,
    )

    expect(screen.getByText('Belum Terdaftar')).toBeDefined()
    expect(screen.getByText(/Perangkat Belum Terdaftar/i)).toBeDefined()

    fireEvent.click(screen.getByRole('button', { name: /Budi Santoso/i }))
    for (let i = 0; i < 6; i++) {
      fireEvent.click(screen.getByRole('button', { name: '1' }))
    }

    await waitFor(() => {
      expect(screen.getByText(/Perangkat ini belum disetujui/i)).toBeDefined()
      expect(onVerifikasiMock).not.toHaveBeenCalled()
    })
  })
})
