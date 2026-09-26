/**
 * StatusAntrean.test.tsx — Pengujian pemulihan kegagalan kirim & status antrean (T10-03).
 *
 * Menguji 3 skenario jaringan sesuai kriteria DoD T10-03 & PRD M4:
 *  1. Skenario 1 — Jaringan Daring (Online):
 *     Indikator selalu terlihat (Terkirim, Tertunda, Gagal + jumlah), status terhubung.
 *  2. Skenario 2 — Jaringan Luring (Offline):
 *     Deteksi offline reaktif, antrean lokal tertunda, auto-retry saat kembali online.
 *  3. Skenario 3 — Fluktuasi Jaringan & Gagal Kirim:
 *     Pesan galat peladen ditampilkan gamblang (tidak ada gagal diam-diam),
 *     tombol coba lagi manual per-item & massal, konfirmasi hapus dari antrean.
 */
// @vitest-environment jsdom
import { describe, expect, it, beforeEach, afterEach, vi } from 'vitest'
import { render, screen, act, cleanup, fireEvent } from '@testing-library/react'
import { StatusAntrean } from './StatusAntrean'
import { kosongkanSemuaAntrean, tambahKeAntrean, perbaruiStatusItem } from '../lib/antrean-offline'

describe('StatusAntrean (T10-03 / DoD Ketahanan & Pemulihan)', () => {
  beforeEach(async () => {
    cleanup()
    await kosongkanSemuaAntrean()
    // Pastikan status online default
    Object.defineProperty(navigator, 'onLine', {
      value: true,
      configurable: true,
    })
  })

  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  describe('Skenario 1: Jaringan Daring (Online)', () => {
    it('menampilkan indikator lengkap (Terkirim, Tertunda, Gagal) meskipun antrean 0', async () => {
      await act(async () => {
        render(<StatusAntrean selaluTampil={true} />)
      })

      // Bilah status terlihat
      expect(screen.getByTestId('bilah-status-antrean')).toBeDefined()
      expect(screen.getByText('Terhubung ke Peladen')).toBeDefined()

      // Tiga indikator hitungan selalu terlihat (DoD 1)
      const terkirim = screen.getByTestId('indikator-terkirim')
      const tertunda = screen.getByTestId('indikator-tertunda')
      const gagal = screen.getByTestId('indikator-gagal')

      expect(terkirim.textContent).toContain('Terkirim: 0')
      expect(tertunda.textContent).toContain('Tertunda: 0')
      expect(gagal.textContent).toContain('Gagal: 0')

      // Pesan status daring
      expect(screen.getByTestId('pesan-status-antrean').textContent).toBe(
        'Daring (semua pesanan terkirim)',
      )
    })

    it('menampilkan jumlah terkirim saat ada pesanan berstatus sukses', async () => {
      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-sukses-1',
        muatan: { total: 45000, meja_id: '01' },
      })
      await perbaruiStatusItem(item.id, 'sukses', null)

      await act(async () => {
        render(<StatusAntrean selaluTampil={true} />)
      })

      const terkirim = screen.getByTestId('indikator-terkirim')
      expect(terkirim.textContent).toContain('Terkirim: 1')

      // Buka rincian antrean dan cek label terkonfirmasi peladen
      const btnRincian = screen.getByTestId('btn-buka-rincian-antrean')
      await act(async () => {
        fireEvent.click(btnRincian)
      })

      expect(screen.getByTestId('wadah-dialog-antrean')).toBeDefined()
      expect(screen.getByText('✓ Terkonfirmasi Peladen')).toBeDefined()

      // Pembersihan riwayat terkirim
      const btnBersihkan = screen.getByTestId('btn-bersihkan-sukses')
      await act(async () => {
        fireEvent.click(btnBersihkan)
      })

      expect(screen.getByTestId('antrean-kosong')).toBeDefined()
    })

    it('dapat ditampilkan dalam mode ringkas satu baris', async () => {
      await act(async () => {
        render(<StatusAntrean ringkas={true} />)
      })

      const ringkasEl = screen.getByTestId('indikator-antrean-ringkas')
      expect(ringkasEl).toBeDefined()
      expect(ringkasEl.textContent).toContain('🟢 Daring')
      expect(ringkasEl.textContent).toContain('✓0 ⏳0 ❌0')
    })
  })

  describe('Skenario 2: Jaringan Luring (Offline)', () => {
    it('mendeteksi status luring dan menampilkan jumlah pesanan tertunda', async () => {
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-luring-1',
        muatan: { total: 35000, meja_id: '03' },
      })
      await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-luring-2',
        muatan: { total: 60000, meja_id: '04' },
      })

      await act(async () => {
        render(<StatusAntrean selaluTampil={true} />)
      })

      // Simulasikan terputusnya jaringan
      act(() => {
        Object.defineProperty(navigator, 'onLine', { value: false, configurable: true })
        window.dispatchEvent(new Event('offline'))
      })

      expect(screen.getByText('Mode Luring (Offline)')).toBeDefined()
      expect(screen.getByTestId('pesan-status-antrean').textContent).toBe('menunggu dikirim 2')

      const tertunda = screen.getByTestId('indikator-tertunda')
      expect(tertunda.textContent).toContain('Tertunda: 2')

      // Saat luring, tombol kirim sekarang tidak boleh dipaksakan
      expect(screen.queryByTestId('btn-kirim-antrean-sekarang')).toBeNull()
    })

    it('otomatis memicu sinkronisasi saat jaringan kembali daring (DoD percobaan ulang otomatis)', async () => {
      await act(async () => {
        render(<StatusAntrean selaluTampil={true} />)
      })

      // Simulasikan jaringan pulih kembali (online event)
      await act(async () => {
        Object.defineProperty(navigator, 'onLine', { value: true, configurable: true })
        window.dispatchEvent(new Event('online'))
      })

      // Indikator kembali ke mode terhubung
      expect(screen.getByText('Terhubung ke Peladen')).toBeDefined()
    })
  })

  describe('Skenario 3: Fluktuasi Jaringan & Gagal Kirim (DoD Tanpa Gagal Diam-Diam)', () => {
    it('menampilkan pesan galat peladen secara gamblang tanpa gagal diam-diam dan berhasil coba lagi', async () => {
      const itemGagal = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-gagal-1',
        muatan: { total: 75000, meja_id: '07' },
      })

      // Simulasikan kegagalan jaringan / peladen saat sinkronisasi
      const pesanGalatJujur = '503 Service Unavailable: Koneksi peladen terputus saat pemrosesan'
      await perbaruiStatusItem(itemGagal.id, 'gagal', pesanGalatJujur)

      await act(async () => {
        render(
          <StatusAntrean selaluTampil={true} penanganKustom={async () => ({ sukses: true })} />,
        )
      })

      // Indikator bilah status menampilkan peringatan bahaya
      const gagalEl = screen.getByTestId('indikator-gagal')
      expect(gagalEl.textContent).toContain('Gagal: 1')
      expect(screen.getByTestId('pesan-status-antrean').textContent).toBe(
        'ada 1 pesanan gagal dikirim',
      )

      // Ada tombol coba lagi cepat di bilah status
      const btnCobaLagiSemua = screen.getByTestId('btn-coba-lagi-semua-gagal')
      expect(btnCobaLagiSemua).toBeDefined()
      expect(btnCobaLagiSemua.textContent).toContain('Coba Lagi Gagal (1)')

      // Buka modal rincian antrean untuk melihat pesan galat jujur
      const btnRincian = screen.getByTestId('btn-buka-rincian-antrean')
      await act(async () => {
        fireEvent.click(btnRincian)
      })

      // Verifikasi DoD 3: Tidak ada pesan "gagal diam-diam"
      const galatKotak = screen.getByTestId(`galat-item-${itemGagal.id}`)
      expect(galatKotak).toBeDefined()
      const teksGalat = screen.getByTestId(`teks-galat-${itemGagal.id}`)
      expect(teksGalat.textContent).toBe(pesanGalatJujur)

      // Ada tombol Coba Lagi per item
      const btnCobaLagiItem = screen.getByTestId(`btn-coba-lagi-${itemGagal.id}`)
      expect(btnCobaLagiItem).toBeDefined()

      // Kasir menekan coba lagi per item (DoD 2: Percobaan ulang manual)
      await act(async () => {
        fireEvent.click(btnCobaLagiItem)
      })

      // Status item direset dan berhasil dikonfirmasi oleh peladen
      expect(screen.getByText('✓ Terkonfirmasi Peladen')).toBeDefined()
      expect(screen.getByTestId('indikator-gagal').textContent).toContain('Gagal: 0')
      expect(screen.getByTestId('indikator-terkirim').textContent).toContain('Terkirim: 1')
    })

    it('mendukung coba kirim ulang semua item gagal secara massal', async () => {
      const it1 = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-multi-1',
        muatan: { total: 20000 },
      })
      const it2 = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-multi-2',
        muatan: { total: 30000 },
      })
      await perbaruiStatusItem(it1.id, 'gagal', 'Galat koneksi HTTP 504')
      await perbaruiStatusItem(it2.id, 'gagal', 'Galat koneksi HTTP 504')

      await act(async () => {
        render(
          <StatusAntrean selaluTampil={true} penanganKustom={async () => ({ sukses: true })} />,
        )
      })

      const btnCobaLagiSemua = screen.getByTestId('btn-coba-lagi-semua-gagal')
      expect(btnCobaLagiSemua.textContent).toContain('Coba Lagi Gagal (2)')

      await act(async () => {
        fireEvent.click(btnCobaLagiSemua)
      })

      // Gagal kembali 0 karena seluruh item berhasil dikirim
      const gagalEl = screen.getByTestId('indikator-gagal')
      expect(gagalEl.textContent).toContain('Gagal: 0')
      const terkirimEl = screen.getByTestId('indikator-terkirim')
      expect(terkirimEl.textContent).toContain('Terkirim: 2')
    })

    it('mendukung pembatalan / penghapusan item dari antrean dengan konfirmasi pengaman', async () => {
      const item = await tambahKeAntrean({
        jenis: 'simpan_pesanan',
        kunciIdempoten: 'idempoten-hapus-1',
        muatan: { total: 80000, meja_id: '09' },
      })
      await perbaruiStatusItem(item.id, 'gagal', 'Pesanan dibatalkan pelanggan sebelum tersambung')

      await act(async () => {
        render(<StatusAntrean selaluTampil={true} />)
      })

      // Buka rincian
      await act(async () => {
        fireEvent.click(screen.getByTestId('btn-buka-rincian-antrean'))
      })

      // Klik tombol Hapus
      const btnHapus = screen.getByTestId(`btn-hapus-${item.id}`)
      await act(async () => {
        fireEvent.click(btnHapus)
      })

      // Muncul konfirmasi pengaman
      expect(screen.getByTestId(`konfirmasi-hapus-${item.id}`)).toBeDefined()
      expect(
        screen.getByText(/Apakah Anda yakin ingin membatalkan\/menghapus pesanan ini/i),
      ).toBeDefined()

      // Kasir mengonfirmasi Ya, Hapus
      const btnYa = screen.getByTestId(`btn-konfirmasi-hapus-ya-${item.id}`)
      await act(async () => {
        fireEvent.click(btnYa)
      })

      // Item terhapus dan antrean kosong
      expect(screen.getByTestId('antrean-kosong')).toBeDefined()
    })
  })
})
