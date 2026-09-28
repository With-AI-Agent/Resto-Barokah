// @vitest-environment jsdom
/**
 * Uji Unit Layar Pengaturan: Kampanye (T8-11).
 *
 * Target DoD:
 *   1. Pengaturan persen / nominal, minimum belanja, batas potongan, masa berlaku, kuota, anggaran.
 *   2. Pratinjau aturan dalam bahasa manusia dan simulasi contoh belanja.
 *   3. Validasi ketat mencegah aturan mustahil (persen > 100, nominal <= 0, tanggal selesai <= mulai, kuota <= 0).
 *   4. Pembuatan kampanye baru dan pembaruan kampanye yang sudah ada.
 *   5. Pengubahan status aktif / nonaktif kampanye.
 */
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { Kampanye, formatPratinjauAturan, type DataKampanyeAdmin } from './Kampanye'

afterEach(() => {
  cleanup()
})

const KAMPANYE_UJI: DataKampanyeAdmin[] = [
  {
    id: 'kmp-101',
    nama: 'Promo Gajian 25%',
    kode_kampanye: 'GAJIAN25',
    jenis: 'persen',
    nilai: 25,
    min_belanja: 50000,
    maks_potongan: 25000,
    mulai: '2026-09-01T00:00:00Z',
    selesai: '2026-10-31T23:59:59Z',
    kuota: 100,
    anggaran_maks: 2500000,
    cabang_berlaku: [],
    aktif: true,
    jumlah_terbit: 20,
    jumlah_terpakai: 5,
    sisa_kuota: 80,
    status_waktu: 'berjalan',
  },
  {
    id: 'kmp-102',
    nama: 'Voucher Minum Rp10rb',
    kode_kampanye: 'MINUM10K',
    jenis: 'nominal',
    nilai: 10000,
    min_belanja: 30000,
    maks_potongan: null,
    mulai: '2026-08-01T00:00:00Z',
    selesai: '2026-08-31T23:59:59Z',
    kuota: 50,
    anggaran_maks: 500000,
    cabang_berlaku: ['cabang-01'],
    aktif: false,
    jumlah_terbit: 50,
    jumlah_terpakai: 40,
    sisa_kuota: 0,
    status_waktu: 'berakhir',
  },
]

describe('formatPratinjauAturan (T8-11)', () => {
  it('menghasilkan kalimat bahasa manusia untuk promo persen dengan plafon', () => {
    const hasil = formatPratinjauAturan({
      jenis: 'persen',
      nilai: 20,
      min_belanja: 50000,
      maks_potongan: 15000,
      selesai: '2026-12-31T23:59:59Z',
      kuota: 100,
      semuaCabang: true,
    })

    expect(hasil.kalimat).toContain('Diskon 20% (maksimal Rp15.000)')
    expect(hasil.kalimat).toContain('dengan belanja minimal Rp50.000')
    expect(hasil.kalimat).toContain('di semua cabang')
    expect(hasil.kalimat).toContain('Kuota: 100 voucher')
    expect(hasil.simulasi).toContain('Contoh: Pelanggan belanja')
  })

  it('menghasilkan kalimat bahasa manusia untuk promo nominal di cabang spesifik', () => {
    const hasil = formatPratinjauAturan({
      jenis: 'nominal',
      nilai: 20000,
      min_belanja: 60000,
      maks_potongan: null,
      selesai: '2026-11-30T23:59:59Z',
      kuota: 50,
      semuaCabang: false,
      jumlahCabang: 2,
    })

    expect(hasil.kalimat).toContain('Potongan langsung Rp20.000')
    expect(hasil.kalimat).toContain('dengan belanja minimal Rp60.000')
    expect(hasil.kalimat).toContain('di 2 cabang terpilih')
    expect(hasil.kalimat).toContain('Kuota: 50 voucher')
  })
})

describe('Komponen Kampanye Pengaturan Admin (T8-11)', () => {
  it('merender daftar kampanye dan statistik kuota serta serapan', () => {
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} />)

    expect(screen.getByText('Promo Gajian 25%')).toBeTruthy()
    expect(screen.getByText('Kode: GAJIAN25')).toBeTruthy()
    expect(screen.getByText('Voucher Minum Rp10rb')).toBeTruthy()
    expect(screen.getByText('Kode: MINUM10K')).toBeTruthy()

    // Lencana status aktif & nonaktif
    expect(screen.getByText('Aktif')).toBeTruthy()
    expect(screen.getByText('Nonaktif')).toBeTruthy()
  })

  it('menyaring daftar berdasarkan status aktif dan nonaktif saat tombol filter diklik', () => {
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} />)

    // Klik filter aktif
    fireEvent.click(screen.getByRole('button', { name: /Filter aktif/i }))
    expect(screen.getByText('Promo Gajian 25%')).toBeTruthy()
    expect(screen.queryByText('Voucher Minum Rp10rb')).toBeNull()

    // Klik filter nonaktif
    fireEvent.click(screen.getByRole('button', { name: /Filter nonaktif/i }))
    expect(screen.queryByText('Promo Gajian 25%')).toBeNull()
    expect(screen.getByText('Voucher Minum Rp10rb')).toBeTruthy()
  })

  it('menolak pembuatan kampanye jika nama kosong atau kode kurang dari 3 karakter', async () => {
    const onSimpan = vi.fn()
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} onSimpan={onSimpan} />)

    fireEvent.click(screen.getByRole('button', { name: /Buat kampanye baru/i }))
    expect(screen.getByTestId('form-kampanye')).toBeTruthy()

    // Klik simpan langsung (nama dan kode masih kosong)
    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))
    expect(screen.getByTestId('form-pesan-galat').textContent).toContain(
      'Nama kampanye tidak boleh kosong',
    )
    expect(onSimpan).not.toHaveBeenCalled()

    // Isi nama, biarkan kode kosong
    fireEvent.change(screen.getByLabelText(/Nama Kampanye/i), { target: { value: 'Promo Baru' } })
    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))
    expect(screen.getByTestId('form-pesan-galat').textContent).toContain(
      'Kode kampanye minimal 3 karakter',
    )
  })

  it('menolak aturan mustahil jika diskon persen melebihi 100%', async () => {
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: /Buat kampanye baru/i }))

    fireEvent.change(screen.getByLabelText(/Nama Kampanye/i), {
      target: { value: 'Promo Raksasa' },
    })
    fireEvent.change(screen.getByLabelText(/Kode Promo Pelanggan/i), {
      target: { value: 'RAKSASA150' },
    })
    fireEvent.change(screen.getByLabelText(/Besar Diskon \(%\)/i), { target: { value: '150' } })

    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))
    expect(screen.getByTestId('form-pesan-galat').textContent).toContain(
      'Diskon persen harus antara 1% sampai 100%',
    )
  })

  it('menolak aturan jika tanggal selesai promo sebelum tanggal mulai', async () => {
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: /Buat kampanye baru/i }))

    fireEvent.change(screen.getByLabelText(/Nama Kampanye/i), { target: { value: 'Promo Mundur' } })
    fireEvent.change(screen.getByLabelText(/Kode Promo Pelanggan/i), {
      target: { value: 'MUNDUR' },
    })
    fireEvent.change(screen.getByLabelText(/Tanggal Mulai/i), { target: { value: '2026-10-10' } })
    fireEvent.change(screen.getByLabelText(/Tanggal Selesai/i), { target: { value: '2026-10-05' } })

    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))
    expect(screen.getByTestId('form-pesan-galat').textContent).toContain(
      'Tanggal selesai promo harus sesudah tanggal mulai',
    )
  })

  it('menolak aturan jika anggaran lebih kecil dari nilai voucher nominal', async () => {
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} />)

    fireEvent.click(screen.getByRole('button', { name: /Buat kampanye baru/i }))

    fireEvent.change(screen.getByLabelText(/Nama Kampanye/i), {
      target: { value: 'Promo Kurang Anggaran' },
    })
    fireEvent.change(screen.getByLabelText(/Kode Promo Pelanggan/i), {
      target: { value: 'KURANG' },
    })
    fireEvent.click(screen.getByRole('button', { name: /Pilih jenis nominal/i }))

    fireEvent.change(screen.getByLabelText(/Besar Potongan \(Rp\)/i), {
      target: { value: '50000' },
    })
    fireEvent.change(screen.getByLabelText(/Anggaran Maksimal \(Rp\)/i), {
      target: { value: '20000' },
    })

    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))
    expect(screen.getByTestId('form-pesan-galat').textContent).toContain(
      'Anggaran kampanye tidak boleh lebih kecil dari nilai voucher',
    )
  })

  it('berhasil menyimpan kampanye baru yang valid dan menutup modal', async () => {
    const onSimpan = vi.fn().mockResolvedValue({ berhasil: true })
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} onSimpan={onSimpan} />)

    fireEvent.click(screen.getByRole('button', { name: /Buat kampanye baru/i }))

    fireEvent.change(screen.getByLabelText(/Nama Kampanye/i), {
      target: { value: 'Promo Ceria 30%' },
    })
    fireEvent.change(screen.getByLabelText(/Kode Promo Pelanggan/i), {
      target: { value: 'CERIA30' },
    })
    fireEvent.change(screen.getByLabelText(/Besar Diskon \(%\)/i), { target: { value: '30' } })
    fireEvent.change(screen.getByLabelText(/Syarat Minimal Belanja/i), {
      target: { value: '60000' },
    })
    fireEvent.change(screen.getByLabelText(/Batas Maksimal Potongan/i), {
      target: { value: '20000' },
    })
    fireEvent.change(screen.getByLabelText(/Tanggal Mulai/i), { target: { value: '2026-10-01' } })
    fireEvent.change(screen.getByLabelText(/Tanggal Selesai/i), { target: { value: '2026-10-31' } })
    fireEvent.change(screen.getByLabelText(/Kuota Voucher/i), { target: { value: '150' } })
    fireEvent.change(screen.getByLabelText(/Anggaran Maksimal/i), { target: { value: '3000000' } })

    // Kotak pratinjau aturan otomatis merefleksikan isian
    const kotakPratinjau = screen.getByTestId('pratinjau-aturan-form')
    expect(kotakPratinjau.textContent).toContain('Diskon 30% (maksimal Rp20.000)')
    expect(kotakPratinjau.textContent).toContain('dengan belanja minimal Rp60.000')

    // Klik simpan
    fireEvent.click(screen.getByRole('button', { name: /Simpan aturan kampanye/i }))

    await waitFor(() => {
      expect(onSimpan).toHaveBeenCalled()
      expect(screen.queryByTestId('form-kampanye')).toBeNull()
      expect(screen.getByTestId('notif-sukses')).toBeTruthy()
      expect(screen.getByText('Promo Ceria 30%')).toBeTruthy()
    })
  })

  it('mengubah status aktif kampanye saat tombol nonaktifkan/aktifkan diklik', async () => {
    const onUbahStatus = vi.fn().mockResolvedValue({ berhasil: true })
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} onUbahStatus={onUbahStatus} />)

    // Klik tombol nonaktifkan GAJIAN25
    const tombolToggle = screen.getByRole('button', { name: /Ubah status GAJIAN25/i })
    expect(tombolToggle.textContent).toContain('Nonaktifkan')

    fireEvent.click(tombolToggle)

    await waitFor(() => {
      expect(onUbahStatus).toHaveBeenCalledWith('kmp-101', false)
      expect(screen.getByTestId('notif-sukses').textContent).toContain('dinonaktifkan')
    })
  })

  it('tombol kembali memicu onKembali saat diklik', () => {
    const onKembali = vi.fn()
    render(<Kampanye daftarKampanyeAwal={KAMPANYE_UJI} onKembali={onKembali} />)

    fireEvent.click(screen.getByRole('button', { name: /Kembali ke menu pengaturan/i }))
    expect(onKembali).toHaveBeenCalled()
  })
})
