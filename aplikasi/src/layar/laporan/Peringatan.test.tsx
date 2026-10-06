// @vitest-environment jsdom
/**
 * Uji T10-13 — Layar Ringkasan Peringatan Harian Pemilik (Peringatan.tsx)
 *
 * Menguji kepatuhan kriteria penerimaan:
 *  1. Tampilan indikator keuangan & anomali (omzet, transaksi, void, diskon, selisih kas, login gagal, perangkat).
 *  2. Integritas status rantai audit berantai hash (ART-13).
 *  3. Kepatuhan privasi UU PDP: bebas data pribadi pelanggan (ART-14).
 *  4. Interaksi pengaturan & pengiriman notifikasi email harian ke owner.
 *  5. Penyaringan rincian kejadian per kategori anomali.
 */

import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { Peringatan, type DataRingkasanPeringatan } from './Peringatan'

afterEach(cleanup)

const DATA_RINGKASAN_LENGKAP: DataRingkasanPeringatan = {
  id: 'ringkas-001',
  tanggal: '2026-09-25',
  omzet: 172500,
  transaksi_count: 2,
  void_count: 1,
  void_nominal: 35000,
  diskon_count: 2,
  diskon_nominal: 15000,
  selisih_kas_count: 1,
  selisih_kas_nominal: 20000,
  percobaan_gagal_count: 2,
  perubahan_perangkat_count: 1,
  pemulihan_count: 0,
  rantai_audit_valid: true,
  rantai_audit_pesan: 'Seluruh rantai audit valid dan tidak terputus.',
  email_tujuan: 'owner.a@contoh.test',
  status_email: 'tertunda',
  rincian_peringatan: [
    {
      kategori: 'void',
      waktu: '2026-09-25T08:05:00Z',
      pegawai: 'Bu Oasis',
      nominal: 35000,
      alasan: 'Salah input meja dan makanan batal diproses',
    },
    {
      kategori: 'diskon',
      waktu: '2026-09-25T07:10:00Z',
      pegawai: 'Bu Oasis',
      nominal: 5000,
      alasan: 'Keluarga pemilik',
    },
    {
      kategori: 'selisih_kas',
      waktu: '2026-09-25T10:00:00Z',
      pegawai: 'Rina',
      selisih: -20000,
      alasan: 'Kembalian salah berikan',
    },
    {
      kategori: 'masuk_gagal',
      waktu: '2026-09-25T00:55:00Z',
      pegawai: 'Rina',
      alasan: 'Kata sandi salah 3 kali',
    },
    {
      kategori: 'perangkat',
      waktu: '2026-09-25T02:00:00Z',
      pegawai: 'Bu Oasis',
      aksi: 'daftar_perangkat',
    },
  ],
}

describe('Peringatan Component (T10-13)', () => {
  it('menampilkan keadaan kosong saat data belum ada', () => {
    render(<Peringatan data={null} tanggalTerpilih="2026-09-25" />)
    expect(screen.getByText(/Belum Ada Ringkasan Harian/i)).toBeTruthy()
  })

  it('menampilkan indikator omzet dan transaksi lunas secara tepat', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)
    expect(screen.getByText(/Rp172.500/i)).toBeTruthy()
    expect(screen.getByText(/2 transaksi lunas/i)).toBeTruthy()
  })

  it('menampilkan metrik pengawasan anomali (void, diskon, selisih kas, login gagal)', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)
    expect(screen.getByText(/1 pesanan/i)).toBeTruthy()
    expect(screen.getByText(/Potensi rugi: Rp35.000/i)).toBeTruthy()
    expect(screen.getAllByText(/2 kali/i).length).toBe(2) // Diskon (2 kali) & Login gagal (2 kali)
    expect(screen.getByText(/Total: Rp15.000/i)).toBeTruthy()
    expect(screen.getByText(/1 kejadian/i)).toBeTruthy()
    expect(screen.getByText(/Selisih: Rp20.000/i)).toBeTruthy()
    expect(screen.getByText(/Potensi serangan brute-force/i)).toBeTruthy()
  })

  it('menampilkan lencana rantai audit hijau saat valid (ART-13)', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)
    expect(screen.getByText(/VALID & UTUH/i)).toBeTruthy()
    expect(screen.getByText(/Seluruh rantai audit valid dan tidak terputus/i)).toBeTruthy()
  })

  it('menampilkan lencana rantai audit bahaya saat rantai terputus (ART-13)', () => {
    const dataRusak: DataRingkasanPeringatan = {
      ...DATA_RINGKASAN_LENGKAP,
      rantai_audit_valid: false,
      rantai_audit_pesan: 'Hash baris 10 tidak cocok dengan prev_hash baris 11.',
    }
    render(<Peringatan data={dataRusak} />)
    expect(screen.getByText(/TERPUTUS \/ ANOMALI/i)).toBeTruthy()
    expect(screen.getByText(/Hash baris 10 tidak cocok/i)).toBeTruthy()
  })

  it('menjamin bebas dari data pribadi pelanggan (UU PDP & ART-14)', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)
    // Memastikan teks komitmen privasi tampil
    expect(screen.getByText(/Prinsip Privasi UU PDP & ART-14/i)).toBeTruthy()

    // Memastikan tidak ada format email pribadi umum atau nomor HP di layar
    const containerText = document.body.textContent || ''
    expect(containerText).not.toContain('@gmail.com')
    expect(containerText).not.toContain('0812')
  })

  it('memfilter tabel kejadian berdasarkan kategori yang dipilih', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)

    // Awalnya ada 5 kejadian
    expect(screen.getByText(/Salah input meja/i)).toBeTruthy()
    expect(screen.getByText(/Keluarga pemilik/i)).toBeTruthy()

    // Klik tombol filter "Void"
    const tombolVoid = screen.getByRole('button', { name: /^Void$/i })
    fireEvent.click(tombolVoid)

    // Kejadian void tetap ada, diskon disaring hilang
    expect(screen.getByText(/Salah input meja/i)).toBeTruthy()
    expect(screen.queryByText(/Keluarga pemilik/i)).toBeNull()
  })

  it('memanggil aksi simpan pengaturan notifikasi email', async () => {
    const simpanMock = vi.fn().mockResolvedValue(undefined)
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} onSimpanPengaturanNotifikasi={simpanMock} />)

    const inputEmail = screen.getByPlaceholderText(/email.owner@contoh.test/i)
    fireEvent.change(inputEmail, { target: { value: 'owner.baru@contoh.test' } })

    const tombolSimpan = screen.getByRole('button', { name: /Simpan Email/i })
    fireEvent.click(tombolSimpan)

    expect(simpanMock).toHaveBeenCalledWith(true, 'owner.baru@contoh.test')
  })

  it('memanggil aksi kirim email manual', async () => {
    const kirimMock = vi.fn().mockResolvedValue(undefined)
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} onKirimEmailManual={kirimMock} />)

    const tombolKirim = screen.getByRole('button', { name: /Kirim Sekarang/i })
    fireEvent.click(tombolKirim)

    expect(kirimMock).toHaveBeenCalledWith('ringkas-001')
  })
})

describe('Peringatan — perangkat berkuasa tinggal satu (PMB1-F-072 · KEAMANAN §4)', () => {
  it('menampilkan peringatan keras bila ada peran berkuasa tanpa cadangan cukup', () => {
    render(
      <Peringatan
        data={DATA_RINGKASAN_LENGKAP}
        statusPerangkatBerkuasa={[
          { peran: 'owner_pusat', jumlah_aktif: 2, cadangan_cukup: true },
          { peran: 'admin_cabang', jumlah_aktif: 1, cadangan_cukup: false },
        ]}
      />,
    )

    const banner = screen.getByText(/Perangkat berkuasa hampir habis/i)
    expect(banner).toBeTruthy()
    expect(screen.getByText(/tinggal/i)).toBeTruthy()
    // Peran yang cadangannya cukup TIDAK ikut diperingatkan
    expect(screen.queryByText(/owner pusat.*tinggal/is)).toBeNull()
  })

  it('tidak menampilkan peringatan bila semua peran berkuasa punya cadangan', () => {
    render(
      <Peringatan
        data={DATA_RINGKASAN_LENGKAP}
        statusPerangkatBerkuasa={[
          { peran: 'owner_pusat', jumlah_aktif: 2, cadangan_cukup: true },
          { peran: 'admin_cabang', jumlah_aktif: 3, cadangan_cukup: true },
        ]}
      />,
    )
    expect(screen.queryByText(/Perangkat berkuasa hampir habis/i)).toBeNull()
  })

  it('tidak menampilkan peringatan bila prop belum diisi (jalur data belum terhubung)', () => {
    render(<Peringatan data={DATA_RINGKASAN_LENGKAP} />)
    expect(screen.queryByText(/Perangkat berkuasa hampir habis/i)).toBeNull()
  })
})
