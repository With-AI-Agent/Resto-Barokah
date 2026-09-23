// @vitest-environment jsdom
/**
 * Uji Struk.tsx (T5-03) — rincian pajak & service terpisah.
 *
 * Aturan yang dikunci di sini, dan alasannya:
 *  - Struk TIDAK BOLEH menghitung pajak/service sendiri. Angkanya datang dari
 *    peladen (`hitung_total()` menulis kolom `subtotal/total_diskon/pajak/
 *    service/total` di baris pesanan). Kalau layar menghitung ulang, ia akan
 *    berbeda dari uang yang benar-benar tercatat begitu ada diskon atau
 *    pembulatan — dan resto mencetak struk yang tidak cocok dengan kasnya.
 *  - Baris "Pembulatan" BUKAN angka baru: ia SELISIH yang membuat rincian
 *    menjumlah persis ke total, yaitu total − (subtotal − diskon + pajak + service).
 *    Dengan begitu struk tidak pernah "tidak ketemu" walau resto memakai
 *    pembulatan 100/500/1000.
 *  - Pajak/service 0% tetap punya baris bernilai Rp0 (DoD T5-03) supaya pelanggan
 *    bisa melihat bahwa resto memang tidak memungut, bukan menyembunyikan.
 *
 * Padanan buktinya di sisi database: `supabase/tes/pajak_service.sql`.
 */
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'
import { Struk, selisihPembulatan, type DataStruk } from './Struk'

afterEach(() => {
  cleanup()
})

/** Angka yang identik dengan uji SQL: subtotal 54.000, PB1 10%, service 5%. */
const DASAR: DataStruk = {
  nomor: 101,
  tanggal: '2026-09-23T10:15:00.000Z',
  namaResto: 'Kedai Oasis',
  item: [{ nama: 'Nasi Goreng', qty: 2, hargaSatuan: 27000, subtotal: 54000 }],
  subtotal: 54000,
  totalDiskon: 0,
  pajak: 5400,
  service: 2700,
  total: 62100,
}

function baris(label: string): string {
  return screen.getByTestId(`struk-${label}`).textContent ?? ''
}

describe('selisihPembulatan', () => {
  it('tanpa pembulatan hasilnya nol', () => {
    expect(selisihPembulatan(DASAR)).toBe(0)
  })

  it('total dibulatkan ke bawah → selisih negatif (menguntungkan pelanggan)', () => {
    expect(selisihPembulatan({ ...DASAR, total: 62000 })).toBe(-100)
  })

  it('dihitung setelah diskon, bukan dari subtotal kotor', () => {
    // dasar 50.000 + 5.000 + 2.500 = 57.500; total dibulatkan ke 57.500 → 0
    expect(
      selisihPembulatan({
        ...DASAR,
        totalDiskon: 4000,
        pajak: 5000,
        service: 2500,
        total: 57500,
      }),
    ).toBe(0)
  })
})

describe('Struk (T5-03)', () => {
  it('menampilkan subtotal, PB1, service, dan total sebagai baris TERPISAH', () => {
    render(<Struk data={DASAR} />)
    expect(baris('subtotal')).toContain('Rp54.000')
    expect(baris('pajak')).toContain('Rp5.400')
    expect(baris('service')).toContain('Rp2.700')
    expect(baris('total')).toContain('Rp62.100')
  })

  it('angka yang tampil persis angka peladen — struk tidak menghitung ulang', () => {
    // Pajak sengaja TIDAK sama dengan 10% subtotal. Struk wajib menurut peladen;
    // kalau ia menghitung sendiri, uji ini merah.
    render(<Struk data={{ ...DASAR, pajak: 1234, service: 567, total: 55801 }} />)
    expect(baris('pajak')).toContain('Rp1.234')
    expect(baris('service')).toContain('Rp567')
    expect(baris('total')).toContain('Rp55.801')
  })

  it('pajak & service 0% tetap punya barisnya sendiri bernilai Rp0', () => {
    render(<Struk data={{ ...DASAR, pajak: 0, service: 0, total: 54000 }} />)
    expect(baris('pajak')).toContain('Rp0')
    expect(baris('service')).toContain('Rp0')
    expect(baris('total')).toContain('Rp54.000')
  })

  it('diskon tampil sebagai baris pengurang bertanda minus', () => {
    render(
      <Struk data={{ ...DASAR, totalDiskon: 4000, pajak: 5000, service: 2500, total: 57500 }} />,
    )
    expect(baris('diskon')).toContain('4.000')
    expect(baris('diskon')).toContain('−')
  })

  it('tanpa diskon baris diskon tidak dicetak (struk tetap ringkas)', () => {
    render(<Struk data={DASAR} />)
    expect(screen.queryByTestId('struk-diskon')).toBeNull()
  })

  it('pembulatan ke bawah dicetak sebagai baris selisih, bukan disembunyikan', () => {
    render(<Struk data={{ ...DASAR, total: 62000 }} />)
    expect(baris('pembulatan')).toContain('100')
    expect(baris('total')).toContain('Rp62.000')
  })

  it('tanpa selisih pembulatan barisnya tidak dicetak', () => {
    render(<Struk data={DASAR} />)
    expect(screen.queryByTestId('struk-pembulatan')).toBeNull()
  })

  it('rincian yang dicetak SELALU menjumlah persis ke total', () => {
    const kasus: DataStruk[] = [
      DASAR,
      { ...DASAR, totalDiskon: 4000, pajak: 5000, service: 2500, total: 57500 },
      { ...DASAR, total: 62000 },
      { ...DASAR, pajak: 0, service: 0, total: 54000 },
      { ...DASAR, totalDiskon: 54000, pajak: 0, service: 0, total: 0 },
    ]
    for (const data of kasus) {
      const jumlah =
        data.subtotal - data.totalDiskon + data.pajak + data.service + selisihPembulatan(data)
      expect(jumlah).toBe(data.total)
    }
  })

  it('mencetak baris item beserta qty dan harga satuannya', () => {
    render(<Struk data={DASAR} />)
    const item = screen.getByTestId('struk-item-0').textContent ?? ''
    expect(item).toContain('Nasi Goreng')
    expect(item).toContain('2')
    expect(item).toContain('Rp27.000')
    expect(item).toContain('Rp54.000')
  })

  it('menampilkan pembayaran & kembalian bila tagihan sudah dibayar', () => {
    render(
      <Struk
        data={DASAR}
        pembayaran={[{ metode: 'Tunai', jumlah: 62100, diterima: 100000 }]}
        kembalian={37900}
      />,
    )
    expect(baris('bayar-0')).toContain('Tunai')
    expect(baris('bayar-0')).toContain('Rp62.100')
    expect(baris('kembalian')).toContain('Rp37.900')
  })

  it('pembayaran sebagian: sisa tagihan disebut, tidak berpura-pura lunas', () => {
    render(
      <Struk
        data={DASAR}
        pembayaran={[{ metode: 'Tunai', jumlah: 30000, diterima: 30000 }]}
        kembalian={0}
      />,
    )
    expect(baris('sisa')).toContain('Rp32.100')
    expect(screen.queryByTestId('struk-lunas')).toBeNull()
  })

  it('lunas: penanda lunas tampil dan tidak ada baris sisa', () => {
    render(
      <Struk
        data={DASAR}
        pembayaran={[{ metode: 'Tunai', jumlah: 62100, diterima: 62100 }]}
        kembalian={0}
      />,
    )
    expect(screen.getByTestId('struk-lunas')).toBeTruthy()
    expect(screen.queryByTestId('struk-sisa')).toBeNull()
  })

  it('kepala & kaki struk dari pengaturan resto dicetak apa adanya', () => {
    render(<Struk data={{ ...DASAR, header: 'Kedai Oasis Bandung', footer: 'Terima kasih' }} />)
    expect(screen.getByText('Kedai Oasis Bandung')).toBeTruthy()
    expect(screen.getByText('Terima kasih')).toBeTruthy()
  })
})
