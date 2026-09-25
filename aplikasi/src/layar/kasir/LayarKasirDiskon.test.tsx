// @vitest-environment jsdom
/**
 * Uji sambungan LayarKasir → DiskonManual (T5-05) + penjaga anti-kambuh.
 *
 * Yang DULU SALAH di `LayarKasir.tsx`: ada "voucher" keras-kode. Mengetik
 * `BAROKAH10K` langsung memotong Rp10.000 dari tagihan —
 *  - tanpa pagar izin (kasir dengan batas Rp25.000/5 % tidak diperiksa),
 *  - tanpa alasan (padahal kolomnya wajib di database),
 *  - tanpa jejak siapa yang memberi dan siapa yang menyetujui,
 *  - dan tanpa voucher apa pun di database — kodenya hidup di dalam berkas layar,
 *    jadi siapa pun yang pernah melihat kodenya bisa memakainya berkali-kali.
 *
 * Sesudah T5-05: diskon hanya masuk lewat `onTerapkanDiskon` (tabel
 * `diskon_transaksi`, dijaga pemicu `picu_diskon_batas` migrasi 0041), dan
 * layar tidak pernah memotong tagihan atas kemauannya sendiri.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { LayarKasir } from './LayarKasir'
import { PenyediaBahasa } from '../../bahasa'
import isiLayarKasir from './LayarKasir.tsx?raw'

afterEach(() => {
  cleanup()
})

const BATAS_KASIR = { boleh: true, batasNominal: 25000, batasPersen: 5 }
const ATASAN = [{ id: 'owner-1', nama: 'Bu Sri (Pemilik)' }]

/** Komentar dibuang dulu: penjaga berbasis `?raw` gampang tertipu oleh teks di
 *  dalam komentar penjelasan (jebakan yang sudah pernah memakan korban di T5-01). */
const isiTanpaKomentar = isiLayarKasir.replace(/\/\*[\s\S]*?\*\//g, '').replace(/^\s*\/\/.*$/gm, '')

function bukaDiskon() {
  fireEvent.click(screen.getByText('Tahu Tempe Goreng Lengkuas'))
  fireEvent.click(screen.getByRole('button', { name: /Tambah Voucher \/ Diskon/i }))
}

describe('LayarKasir — penjaga anti voucher keras-kode (T5-05)', () => {
  it('tidak ada lagi kode voucher yang ditanam di dalam berkas layar', () => {
    expect(isiTanpaKomentar).not.toMatch(/BAROKAH10K/)
    expect(isiTanpaKomentar).not.toMatch(/kodeVoucherInput/)
  })

  it('layar tidak memotong tagihan atas kemauannya sendiri (tanpa angka diskon ditanam)', () => {
    // Dulu: `setDiskonAktif(10000)`. Nilai diskon sekarang selalu datang dari
    // masukan kasir yang sudah lolos pagar peladen, bukan angka di dalam kode.
    expect(isiTanpaKomentar).not.toMatch(/setDiskonAktif\(\s*\d{3,}\s*\)/)
  })
})

describe('LayarKasir ↔ DiskonManual (T5-05, sambungan)', () => {
  it('diskon di atas batas kasir tidak bisa diterapkan tanpa persetujuan atasan', async () => {
    const onTerapkanDiskon = vi.fn()
    render(
      <PenyediaBahasa>
        <LayarKasir
          batasDiskon={BATAS_KASIR}
          daftarAtasan={ATASAN}
          onTerapkanDiskon={onTerapkanDiskon}
        />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '20000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'komplain' } })

    await waitFor(() => expect(screen.getByTestId('diskon-perlu-persetujuan')).toBeTruthy())
    expect(
      (screen.getByRole('button', { name: /Terapkan diskon/i }) as HTMLButtonElement).disabled,
    ).toBe(true)
    expect(onTerapkanDiskon).not.toHaveBeenCalled()
  })

  it('diskon yang DITOLAK peladen tidak boleh mengurangi tagihan di layar', async () => {
    // Inilah bahaya khas "optimistic update" pada uang: layar terlanjur
    // menampilkan potongan, kasir menagih lebih murah, padahal peladen menolak.
    const onTerapkanDiskon = vi.fn().mockResolvedValue({
      berhasil: false,
      pesan: 'Total potongan melebihi batas maks potongan resto.',
    })
    render(
      <PenyediaBahasa>
        <LayarKasir
          batasDiskon={BATAS_KASIR}
          daftarAtasan={ATASAN}
          onTerapkanDiskon={onTerapkanDiskon}
        />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    // 500 rupiah: di bawah batas kasir (25.000 / 5 %) untuk satu porsi, jadi yang
    // diuji di sini benar-benar penanganan PENOLAKAN peladen — bukan pagar layar.
    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '500' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'langganan' } })
    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))

    await waitFor(() => expect(onTerapkanDiskon).toHaveBeenCalled())
    // Modal tetap terbuka dengan pesan penolakan, dan tidak ada baris potongan.
    await waitFor(() =>
      expect(screen.getByTestId('diskon-pesan').textContent).toContain('melebihi batas maks'),
    )
    expect(screen.queryByText(/Diskon \/ Voucher Promo/i)).toBeNull()
  })

  it('diskon yang DITERIMA peladen baru mengurangi tagihan', async () => {
    const onTerapkanDiskon = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <PenyediaBahasa>
        <LayarKasir
          batasDiskon={BATAS_KASIR}
          daftarAtasan={ATASAN}
          onTerapkanDiskon={onTerapkanDiskon}
        />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '500' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'langganan' } })
    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))

    await waitFor(() =>
      expect(onTerapkanDiskon).toHaveBeenCalledWith({
        nilai: 500,
        alasan: 'langganan',
        disetujuiOleh: null,
      }),
    )
    await waitFor(() => expect(screen.getByText(/Diskon \/ Voucher Promo/i)).toBeTruthy())
  })

  it('persetujuan PIN atasan diteruskan ke kontainer, bukan diperiksa di layar', async () => {
    const onMintaPersetujuanDiskon = vi.fn().mockResolvedValue({ berhasil: true })
    const onTerapkanDiskon = vi.fn().mockResolvedValue({ berhasil: true })
    render(
      <PenyediaBahasa>
        <LayarKasir
          batasDiskon={BATAS_KASIR}
          daftarAtasan={ATASAN}
          onMintaPersetujuanDiskon={onMintaPersetujuanDiskon}
          onTerapkanDiskon={onTerapkanDiskon}
        />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    fireEvent.change(screen.getByLabelText(/Nilai diskon/i), { target: { value: '20000' } })
    fireEvent.change(screen.getByLabelText(/Alasan diskon/i), { target: { value: 'komplain' } })
    await waitFor(() => expect(screen.getByTestId('diskon-atasan')).toBeTruthy())
    fireEvent.change(screen.getByTestId('diskon-atasan'), { target: { value: 'owner-1' } })
    fireEvent.change(screen.getByLabelText(/PIN atasan/i), { target: { value: '551937' } })
    fireEvent.click(screen.getByRole('button', { name: /Minta persetujuan/i }))

    // PIN tidak pernah dicocokkan di layar — hanya diteruskan ke peladen.
    await waitFor(() =>
      expect(onMintaPersetujuanDiskon).toHaveBeenCalledWith({
        atasanId: 'owner-1',
        pin: '551937',
      }),
    )
    expect(isiTanpaKomentar).not.toMatch(/'\d{6}'/)

    fireEvent.click(screen.getByRole('button', { name: /Terapkan diskon/i }))
    await waitFor(() =>
      expect(onTerapkanDiskon).toHaveBeenCalledWith({
        nilai: 20000,
        alasan: 'komplain',
        disetujuiOleh: 'owner-1',
      }),
    )
  })
})

describe('LayarKasir ↔ VoucherKasir (T8-09, alur cek & pakai voucher)', () => {
  it('dapat beralih ke tab voucher promo dan memeriksa kode voucher', async () => {
    const onCekVoucher = vi.fn().mockResolvedValue({
      berhasil: true,
      kode: 'SUKSES',
      pesan: 'Voucher sah.',
      data: {
        voucher_id: 'vcr-1',
        kode_voucher: 'VC-HEMAT20',
        status: 'aktif',
        nama_kampanye: 'Promo Diskon 20%',
        jenis: 'persen',
        nilai: 20,
        min_belanja: 50000,
        maks_potongan: 20000,
        estimasi_potongan: 10000,
      },
    })

    render(
      <PenyediaBahasa>
        <LayarKasir onCekVoucher={onCekVoucher} />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    fireEvent.click(screen.getByRole('button', { name: /Tab Voucher Promo/i }))
    expect(screen.getByTestId('voucher-kasir')).toBeTruthy()

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))

    await waitFor(() => {
      expect(onCekVoucher).toHaveBeenCalledWith(
        expect.objectContaining({
          kode: 'VC-HEMAT20',
        }),
      )
      expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy()
      expect(screen.getByText('Promo Diskon 20%')).toBeTruthy()
    })
  })

  it('voucher yang berhasil dipakai memotong tagihan di layar kasir', async () => {
    const onCekVoucher = vi.fn().mockResolvedValue({
      berhasil: true,
      kode: 'SUKSES',
      pesan: 'Voucher sah.',
      data: {
        voucher_id: 'vcr-1',
        kode_voucher: 'VC-HEMAT20',
        status: 'aktif',
        nama_kampanye: 'Promo Diskon 20%',
        jenis: 'persen',
        nilai: 20,
        min_belanja: 10000,
        maks_potongan: null,
        estimasi_potongan: 5000,
      },
    })
    const onPakaiVoucher = vi.fn().mockResolvedValue({
      berhasil: true,
      kode: 'SUKSES',
      pesan: 'Voucher berhasil digunakan.',
      data: {
        voucher_id: 'vcr-1',
        kode_voucher: 'VC-HEMAT20',
        nilai_potongan: 5000,
        nama_kampanye: 'Promo Diskon 20%',
      },
    })

    render(
      <PenyediaBahasa>
        <LayarKasir onCekVoucher={onCekVoucher} onPakaiVoucher={onPakaiVoucher} />
      </PenyediaBahasa>,
    )

    bukaDiskon()
    fireEvent.click(screen.getByRole('button', { name: /Tab Voucher Promo/i }))

    fireEvent.change(screen.getByLabelText(/Kode voucher/i), {
      target: { value: 'VC-HEMAT20' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Cek voucher/i }))
    await waitFor(() => expect(screen.getByTestId('voucher-hasil-cek-sukses')).toBeTruthy())

    fireEvent.change(screen.getByLabelText(/PIN Kasir/i), {
      target: { value: '1234' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Pakai voucher/i }))

    await waitFor(() => {
      expect(onPakaiVoucher).toHaveBeenCalledWith({
        kode: 'VC-HEMAT20',
        pinKasir: '1234',
        pesananId: 'ord-current',
      })
    })

    // Potongan diskon tampil di ringkasan pesanan
    await waitFor(() => {
      expect(screen.getByText(/Diskon \/ Voucher Promo/i)).toBeTruthy()
    })
  })
})
