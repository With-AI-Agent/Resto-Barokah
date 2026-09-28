// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { DiskonManual, melebihiBatas, persenEfektif } from './DiskonManual'

/**
 * Uji T5-05 — diskon manual butuh izin, dan PIN atasan bila di atas batas.
 *
 * Yang dijaga di sini adalah hal-hal yang MERUGIKAN UANG bila longgar:
 * tombol terapkan tidak boleh hidup sebelum syaratnya lengkap, alasan wajib,
 * dan persetujuan atasan tidak boleh "nempel" setelah PIN ditolak.
 *
 * Pagar sungguhannya tetap di database (migrasi 0041 + uji
 * `supabase/tes/diskon_pin_atasan.sql`); layar hanya lapis pertama.
 */

const BATAS_KASIR = { boleh: true, batasNominal: 25000, batasPersen: 5 }
const ATASAN = [{ id: 'owner-1', nama: 'Bu Sri (Pemilik)' }]

describe('persenEfektif', () => {
  it('menghitung persen dari UANG, sama seperti peladen', () => {
    expect(persenEfektif(5400, 54000)).toBe(10)
    expect(persenEfektif(2000, 54000)).toBe(3.7)
  })

  it('menganggap 100% bila subtotal nol — tidak menebak lebih longgar dari peladen', () => {
    expect(persenEfektif(5000, 0)).toBe(100)
  })

  it('nilai nol atau negatif bukan diskon', () => {
    expect(persenEfektif(0, 54000)).toBe(0)
    expect(persenEfektif(-100, 54000)).toBe(0)
  })
})

describe('melebihiBatas', () => {
  it('di bawah kedua batas → tidak perlu atasan', () => {
    expect(melebihiBatas(2000, 54000, BATAS_KASIR)).toBe(false)
  })

  it('melewati batas PERSEN walau rupiahnya kecil → perlu atasan', () => {
    // 5.000 dari subtotal 54.000 = 9,26 % → di atas batas 5 %.
    expect(melebihiBatas(5000, 54000, BATAS_KASIR)).toBe(true)
  })

  it('melewati batas NOMINAL walau persennya kecil → perlu atasan', () => {
    // 30.000 dari 10.000.000 = 0,3 % (lolos persen) tetapi di atas 25.000.
    expect(melebihiBatas(30000, 10000000, BATAS_KASIR)).toBe(true)
  })

  it('batas belum diketahui → dianggap perlu atasan (hati-hati, bukan optimis)', () => {
    expect(melebihiBatas(1000, 54000, null)).toBe(true)
  })

  it('pemakai tanpa izin diskon selalu perlu atasan', () => {
    expect(
      melebihiBatas(1000, 54000, { boleh: false, batasNominal: null, batasPersen: null }),
    ).toBe(true)
  })

  it('batas null berarti tanpa batas — owner tidak diganggu permintaan persetujuan', () => {
    expect(
      melebihiBatas(999999, 54000, { boleh: true, batasNominal: null, batasPersen: null }),
    ).toBe(false)
  })
})

afterEach(cleanup)

describe('DiskonManual', () => {
  it('tidak bisa menerapkan diskon tanpa alasan (DoD: pelaku, nilai, alasan)', async () => {
    const onTerapkan = vi.fn()
    render(<DiskonManual subtotal={54000} batas={BATAS_KASIR} onTerapkan={onTerapkan} />)

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '2000' } })
    expect(
      (screen.getByRole('button', { name: /Terapkan diskon/i }) as HTMLButtonElement).disabled,
    ).toBe(true)

    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), {
      target: { value: 'pelanggan langganan' },
    })
    await waitFor(() =>
      expect(
        (screen.getByRole('button', { name: /Terapkan diskon/i }) as HTMLButtonElement).disabled,
      ).toBe(false),
    )
  })

  it('diskon kecil tidak meminta PIN atasan (alur cepat tidak dirusak)', async () => {
    const onTerapkan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<DiskonManual subtotal={54000} batas={BATAS_KASIR} onTerapkan={onTerapkan} />)

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '2000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'langganan' } })
    expect(screen.queryByTestId('diskon-perlu-persetujuan')).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))
    expect(onTerapkan).toHaveBeenCalledWith({
      nilai: 2000,
      alasan: 'langganan',
      disetujuiOleh: null,
    })
  })

  it('diskon di atas batas: tombol terapkan MATI sampai atasan menyetujui', async () => {
    const onTerapkan = vi.fn()
    render(
      <DiskonManual
        subtotal={54000}
        batas={BATAS_KASIR}
        daftarAtasan={ATASAN}
        onTerapkan={onTerapkan}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '9000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'komplain' } })

    await waitFor(() => expect(screen.getByTestId('diskon-perlu-persetujuan')).toBeTruthy())
    expect(
      (screen.getByRole('button', { name: /Terapkan diskon/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
    expect(onTerapkan).not.toHaveBeenCalled()
  })

  it('setelah PIN atasan diterima, diskon besar boleh diterapkan dengan jejak penyetuju', async () => {
    const onMintaPersetujuan = vi.fn().mockResolvedValue({ berhasil: true })
    const onTerapkan = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <DiskonManual
        subtotal={54000}
        batas={BATAS_KASIR}
        daftarAtasan={ATASAN}
        onMintaPersetujuan={onMintaPersetujuan}
        onTerapkan={onTerapkan}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '9000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), {
      target: { value: 'komplain masakan terlambat' },
    })
    fireEvent.change(screen.getByTestId('diskon-atasan'), { target: { value: 'owner-1' } })
    fireEvent.change(screen.getByLabelText(/PIN atasan/i), { target: { value: '551937' } })
    fireEvent.click(screen.getByRole('button', { name: /Minta persetujuan/i }))

    expect(onMintaPersetujuan).toHaveBeenCalledWith({ atasanId: 'owner-1', pin: '551937' })
    await waitFor(() => expect(screen.getByTestId('diskon-disetujui')).toBeTruthy())

    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))
    expect(onTerapkan).toHaveBeenCalledWith({
      nilai: 9000,
      alasan: 'komplain masakan terlambat',
      disetujuiOleh: 'owner-1',
    })
  })

  it('PIN atasan SALAH tidak membuka tombol terapkan dan pesannya jujur', async () => {
    const onMintaPersetujuan = vi
      .fn()
      .mockResolvedValue({ berhasil: false, pesan: 'PIN salah. Sisa percobaan: 4.' })
    const onTerapkan = vi.fn()
    render(
      <DiskonManual
        subtotal={54000}
        batas={BATAS_KASIR}
        daftarAtasan={ATASAN}
        onMintaPersetujuan={onMintaPersetujuan}
        onTerapkan={onTerapkan}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '9000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'komplain' } })
    fireEvent.change(screen.getByTestId('diskon-atasan'), { target: { value: 'owner-1' } })
    fireEvent.change(screen.getByLabelText(/PIN atasan/i), { target: { value: '000000' } })
    fireEvent.click(screen.getByRole('button', { name: /Minta persetujuan/i }))

    await waitFor(() =>
      expect(screen.getByTestId('diskon-pesan').textContent).toContain('PIN salah'),
    )
    expect(screen.queryByTestId('diskon-disetujui')).toBeNull()
    expect(
      (screen.getByRole('button', { name: /Terapkan diskon/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
    expect(onTerapkan).not.toHaveBeenCalled()
  })

  it('PIN dikosongkan setelah dipakai (tidak tertinggal di layar)', async () => {
    render(
      <DiskonManual
        subtotal={54000}
        batas={BATAS_KASIR}
        daftarAtasan={ATASAN}
        onMintaPersetujuan={vi.fn().mockResolvedValue({ berhasil: false, pesan: 'PIN salah.' })}
      />,
    )

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '9000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'komplain' } })
    fireEvent.change(screen.getByTestId('diskon-atasan'), { target: { value: 'owner-1' } })
    const kolomPin = screen.getByLabelText(/PIN atasan/i) as HTMLInputElement
    fireEvent.change(kolomPin, { target: { value: '000000' } })
    fireEvent.click(screen.getByRole('button', { name: /Minta persetujuan/i }))

    await waitFor(() =>
      expect((screen.getByLabelText(/PIN atasan/i) as HTMLInputElement).value).toBe(''),
    )
  })

  it('penolakan peladen ditampilkan apa adanya, tidak disulap jadi berhasil', async () => {
    const onTerapkan = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Total potongan (30000) melebihi batas maks potongan resto (50 persen dari subtotal).',
    })
    render(<DiskonManual subtotal={54000} batas={BATAS_KASIR} onTerapkan={onTerapkan} />)

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '2000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'langganan' } })
    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))

    await waitFor(() =>
      expect(screen.getByTestId('diskon-pesan').textContent).toContain(
        'melebihi batas maks potongan',
      ),
    )
  })

  it('menampilkan persen efektif supaya kasir tahu diskonnya sebesar apa', async () => {
    render(<DiskonManual subtotal={54000} batas={BATAS_KASIR} />)

    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '5400' } })
    expect(screen.getByTestId('diskon-persen').textContent).toContain('10%')
  })
})
