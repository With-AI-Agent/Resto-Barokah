// @vitest-environment jsdom
/**
 * Uji T5-12 — laporan pembatalan.
 *
 * Yang paling dijaga: **kerugian hanya dihitung dari pembatalan sesudah dapur
 * mulai.** Menjumlahkan semua baris akan melaporkan "kerugian" atas pesanan yang
 * belum pernah dimasak — angka yang membuat pemilik cemas tanpa sebab, dan yang
 * lebih buruk, membuat angka kerugian sungguhan jadi tidak dipercaya.
 */
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import {
  DaftarPembatalan,
  labelTahap,
  ringkasPembatalan,
  saringPembatalan,
  type BarisPembatalan,
} from './DaftarPembatalan'

afterEach(cleanup)

const PRA: BarisPembatalan = {
  id: 'b1',
  nomorPesanan: 961,
  waktu: '2026-09-23T10:00:00.000Z',
  tahap: 'sebelum_dapur',
  alasan: 'Tamu berubah pikiran sebelum dimasak',
  nilaiKerugian: 0,
  pelakuNama: 'Rina',
  itemNama: 'Nasi Goreng Spesial',
  itemQty: 2,
}

const PASCA: BarisPembatalan = {
  id: 'b2',
  nomorPesanan: 962,
  waktu: '2026-09-23T12:30:00.000Z',
  tahap: 'sesudah_dapur',
  alasan: 'Ayam gosong, dimasak ulang',
  nilaiKerugian: 32000,
  pelakuNama: 'Rina',
  penyetujuNama: 'Pak Andi',
}

const PASCA2: BarisPembatalan = {
  ...PASCA,
  id: 'b3',
  nomorPesanan: 963,
  nilaiKerugian: 18000,
  penyetujuNama: null,
}

const DAFTAR = [PRA, PASCA, PASCA2]

describe('ringkasPembatalan', () => {
  it('menghitung jumlah kejadian per jenis', () => {
    const r = ringkasPembatalan(DAFTAR)
    expect(r.jumlah).toBe(3)
    expect(r.jumlahSebelum).toBe(1)
    expect(r.jumlahSesudah).toBe(2)
  })

  it('kerugian HANYA dari pembatalan sesudah dapur mulai', () => {
    expect(ringkasPembatalan(DAFTAR).totalKerugian).toBe(50000)
  })

  it('pembatalan pra-dapur bernilai tidak ikut dihitung sebagai kerugian', () => {
    // Kalau suatu saat ada baris pra-dapur yang terlanjur bernilai, ia tetap
    // tidak boleh masuk angka kerugian — jenisnya yang menentukan, bukan nilainya.
    const aneh: BarisPembatalan = { ...PRA, id: 'b9', nilaiKerugian: 99000 }
    expect(ringkasPembatalan([aneh]).totalKerugian).toBe(0)
  })

  it('daftar kosong menghasilkan nol, bukan NaN', () => {
    expect(ringkasPembatalan([])).toEqual({
      jumlah: 0,
      jumlahSebelum: 0,
      jumlahSesudah: 0,
      totalKerugian: 0,
    })
  })
})

describe('saringPembatalan', () => {
  it('"semua" mengembalikan seluruh baris', () => {
    expect(saringPembatalan(DAFTAR, 'semua')).toHaveLength(3)
  })

  it('menyaring per jenis', () => {
    expect(saringPembatalan(DAFTAR, 'sebelum_dapur')).toHaveLength(1)
    expect(saringPembatalan(DAFTAR, 'sesudah_dapur')).toHaveLength(2)
  })
})

describe('labelTahap — bahasa pegawai, bukan nama kolom', () => {
  it('tidak menampilkan nama kolom database', () => {
    expect(labelTahap('sesudah_dapur')).toBe('Sesudah dapur mulai')
    expect(labelTahap('sebelum_dapur')).toBe('Sebelum dapur mulai')
  })
})

describe('DaftarPembatalan', () => {
  it('daftar kosong menenangkan, bukan layar putih', () => {
    render(<DaftarPembatalan daftar={[]} />)
    expect(screen.getByText(/Tidak ada pembatalan/i)).toBeTruthy()
  })

  it('memisahkan jumlah kejadian dari nilai kerugian', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)
    expect(screen.getByTestId('ringkas-jumlah').textContent).toBe('3')
    expect(screen.getByTestId('ringkas-kerugian').textContent).toContain('Rp50.000')
  })

  it('menampilkan siapa, alasan, dan jenis untuk tiap baris (PRD M8)', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)
    expect(screen.getByTestId('pelaku-b1').textContent).toContain('Rina')
    expect(screen.getByTestId('alasan-b1').textContent).toContain('Tamu berubah pikiran')
    expect(screen.getByTestId('tahap-b1').textContent).toBe('Sebelum dapur mulai')
  })

  it('menampilkan penyetuju bila pembatalan butuh persetujuan', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)
    expect(screen.getByTestId('penyetuju-b2').textContent).toContain('Pak Andi')
    expect(screen.queryByTestId('penyetuju-b3')).toBeNull()
  })

  it('nilai kerugian hanya ditulis pada pembatalan sesudah dapur', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)
    expect(screen.getByTestId('kerugian-b2').textContent).toContain('Rp32.000')
    expect(screen.queryByTestId('kerugian-b1')).toBeNull()
  })

  it('pelaku yang akunnya terhapus tidak membuat baris hilang', () => {
    render(<DaftarPembatalan daftar={[{ ...PRA, pelakuNama: null }]} />)
    expect(screen.getByTestId('pelaku-b1').textContent).toContain('pengguna terhapus')
  })

  it('menyaring daftar lewat tab jenis', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)

    fireEvent.click(screen.getByRole('button', { name: /Saring: Sesudah dapur/i }))

    expect(screen.queryByTestId('batal-b1')).toBeNull()
    expect(screen.getByTestId('batal-b2')).toBeTruthy()
  })

  it('menandai jenis pada baris supaya bisa dibedakan sekilas', () => {
    render(<DaftarPembatalan daftar={DAFTAR} />)
    expect(screen.getByTestId('batal-b1').getAttribute('data-tahap')).toBe('sebelum_dapur')
    expect(screen.getByTestId('batal-b2').getAttribute('data-tahap')).toBe('sesudah_dapur')
  })

  it('menampilkan konteks rentang bila diberikan', () => {
    render(<DaftarPembatalan daftar={DAFTAR} keterangan="23 September 2026 — Cabang Utama" />)
    expect(screen.getByText(/23 September 2026 — Cabang Utama/)).toBeTruthy()
  })
})
