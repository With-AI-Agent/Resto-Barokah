/**
 * useAntrean.ts — Hook pengelola antrean kirim luring (T10-01 / ART-8).
 *
 * Memberikan visibilitas status antrean luring kepada antarmuka kasir/pelayan:
 *  - Indikator status jujur ("menunggu dikirim X") saat koneksi offline / tertunda.
 *  - Sinkronisasi otomatis saat mendeteksi event `online`.
 *  - Pembersihan otomatis data sensitif (PIN, kredensial) sebelum masuk IndexedDB.
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import {
  type ItemAntrean,
  type MasukanTambahAntrean,
  type HasilProsesAntrean,
  type StatistikAntrean,
  ambilSemuaAntrean,
  hitungStatistikAntrean,
  tambahKeAntrean,
  hapusItemAntrean,
  prosesAntrean,
  bersihkanAntreanSukses,
  langgananPerubahanAntrean,
  cobaLagiItem as cobaLagiItemLib,
  cobaLagiSemuaGagal as cobaLagiSemuaGagalLib,
} from '../lib/antrean-offline'
import { klienSupabase } from '../lib/supabase'

export interface GunakanAntreanHasil {
  /** Status koneksi jaringan perangkat (true = terhubung internet). */
  apakahDaring: boolean
  /** Jumlah pesanan/aksi yang tertahan di antrean lokal (menunggu/mengirim/gagal). */
  jumlahMenunggu: number
  /** Jumlah pesanan yang sedang menunggu atau dalam proses pengiriman. */
  jumlahTertunda: number
  /** Jumlah pesanan yang gagal terkirim ke peladen. */
  jumlahGagal: number
  /** Jumlah pesanan yang berhasil terkirim. */
  jumlahTerkirim: number
  /** Rincian statistik seluruh status antrean. */
  statistik: StatistikAntrean
  /** Seluruh item di antrean lokal. */
  daftarAntrean: ItemAntrean[]
  /** Penanda apakah proses sinkronisasi sedang berjalan. */
  sedangSinkronisasi: boolean
  /** Pesan status jelas dalam bahasa manusia: misal "menunggu dikirim 2" (DoD). */
  pesanStatus: string
  /** Menyimpan pesanan/aksi baru ke antrean lokal (dengan sanitasi sensitif). */
  tambahAntrean: (masukan: MasukanTambahAntrean) => Promise<ItemAntrean>
  /** Memproses pengiriman antrean ke peladen. */
  sinkronkanAntrean: (
    penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
  ) => Promise<HasilProsesAntrean>
  /** Mencoba ulang satu item gagal secara manual. */
  cobaLagiItem: (
    id: string,
    penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
  ) => Promise<void>
  /** Mencoba ulang seluruh item yang gagal secara manual. */
  cobaLagiSemuaGagal: (
    penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
  ) => Promise<number>
  /** Menghapus item tertentu dari antrean lokal. */
  hapusAntrean: (id: string) => Promise<void>
  /** Memuat ulang daftar antrean dari IndexedDB. */
  muatUlang: () => Promise<void>
  /** Membersihkan item yang sudah sukses. */
  bersihkanSukses: () => Promise<number>
}

export function useAntrean(): GunakanAntreanHasil {
  const [apakahDaring, setApakahDaring] = useState<boolean>(() => {
    return typeof navigator !== 'undefined' ? navigator.onLine : true
  })
  const [daftarAntrean, setDaftarAntrean] = useState<ItemAntrean[]>([])
  const [statistik, setStatistik] = useState<StatistikAntrean>({
    total: 0,
    menunggu: 0,
    mengirim: 0,
    gagal: 0,
    sukses: 0,
  })
  const [sedangSinkronisasi, setSedangSinkronisasi] = useState<boolean>(false)
  const sedangProsesRef = useRef<boolean>(false)

  // Fungsi sinkronisasi internal default bila tidak disediakan penangan khusus
  const penanganDefault = useCallback(
    async (item: ItemAntrean): Promise<{ sukses: boolean; pesan?: string }> => {
      const klien = klienSupabase()
      if (!klien) {
        return { sukses: false, pesan: 'Sambungan Supabase belum siap.' }
      }

      if (item.jenis === 'simpan_pesanan') {
        try {
          const m = item.muatan as {
            pesananId?: string
            penyewaId?: string
            cabangId?: string
            mejaId?: string | null
            tipe?: string
            shiftId?: string | null
            items?: Array<{
              menuItemId?: string
              id?: string
              nama?: string
              harga?: number
              qty?: number
              catatan?: string | null
            }>
          }

          const idPesanan = m.pesananId || item.id
          const { error: errPesanan } = await klien.from('pesanan').insert({
            id: idPesanan,
            penyewa_id: m.penyewaId,
            cabang_id: m.cabangId,
            meja_id: m.mejaId ?? null,
            tipe: m.tipe ?? 'dinein',
            shift_id: m.shiftId ?? null,
            kunci_idempoten: item.kunciIdempoten,
          })

          if (errPesanan) {
            // Jika kunci idempoten sudah ada di peladen (duplikat), anggap sukses
            if (errPesanan.message.includes('kunci_idempoten') || errPesanan.code === '23505') {
              return { sukses: true }
            }
            return { sukses: false, pesan: errPesanan.message }
          }

          if (m.items && m.items.length > 0) {
            const barisItem = m.items.map((it) => ({
              pesanan_id: idPesanan,
              menu_item_id: it.menuItemId || it.id,
              nama_saat_itu: it.nama,
              harga_saat_itu: it.harga,
              qty: it.qty,
              subtotal: (it.harga || 0) * (it.qty || 1),
              catatan: it.catatan ?? null,
            }))
            const { error: errItems } = await klien.from('pesanan_item').insert(barisItem)
            if (errItems && !errItems.message.includes('kunci_idempoten')) {
              return { sukses: false, pesan: errItems.message }
            }
          }

          // Kunci hitung total
          try {
            await klien.rpc('hitung_total', { p_pesanan_id: idPesanan })
          } catch {
            // Pemicu peladen tetap menjaga total
          }

          return { sukses: true }
        } catch (e) {
          const pesan = e instanceof Error ? e.message : String(e)
          return { sukses: false, pesan }
        }
      }

      if (item.jenis === 'bayar_pesanan') {
        try {
          const m = item.muatan as {
            pesananId: string
            metodeId: string
            jumlah: number
            diterima?: number | null
            referensi?: string | null
          }
          const { data, error } = await klien.rpc('bayar_pesanan', {
            p_pesanan_id: m.pesananId,
            p_metode_id: m.metodeId,
            p_jumlah: m.jumlah,
            p_diterima: m.diterima ?? null,
            p_referensi: m.referensi ?? null,
            p_kunci_idempoten: item.kunciIdempoten,
          })

          if (error) {
            if (error.message.includes('kunci_idempoten') || error.code === '23505') {
              return { sukses: true }
            }
            return { sukses: false, pesan: error.message }
          }
          const res = data as {
            berhasil?: boolean
            dobel?: boolean
            kode?: string
            pesan?: string
          } | null
          if (res && res.berhasil === false) {
            return { sukses: false, pesan: res.pesan || res.kode || 'Gagal memproses pembayaran' }
          }
          return { sukses: true }
        } catch (e) {
          const pesan = e instanceof Error ? e.message : String(e)
          return { sukses: false, pesan }
        }
      }

      if (item.jenis === 'pakai_voucher') {
        try {
          const m = item.muatan as {
            pesananId: string
            kodeVoucher: string
            pinKasir?: string
          }
          const { data, error } = await klien.rpc('pakai_voucher', {
            p_pesanan_id: m.pesananId,
            p_kode: m.kodeVoucher,
            p_pin_kasir: m.pinKasir ?? '',
            p_kunci_idempoten: item.kunciIdempoten,
          })

          if (error) {
            if (error.message.includes('kunci_idempoten') || error.code === '23505') {
              return { sukses: true }
            }
            return { sukses: false, pesan: error.message }
          }
          const res = data as { berhasil?: boolean; kode?: string; pesan?: string } | null
          if (res && !res.berhasil && res.kode !== 'IDEMPOTEN') {
            return { sukses: false, pesan: res.pesan || res.kode || 'Gagal memakai voucher' }
          }
          return { sukses: true }
        } catch (e) {
          const pesan = e instanceof Error ? e.message : String(e)
          return { sukses: false, pesan }
        }
      }

      // Jenis aksi lainnya yang belum didukung ditolak secara fail-closed (F-05)
      return { sukses: false, pesan: `Jenis aksi belum didukung: ${item.jenis}` }
    },
    [],
  )

  const segarkanData = useCallback(async () => {
    try {
      const daftar = await ambilSemuaAntrean()
      const stats = await hitungStatistikAntrean()
      setDaftarAntrean(daftar)
      setStatistik(stats)
    } catch {
      // Abaikan
    }
  }, [])

  const sinkronkanAntrean = useCallback(
    async (
      penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
    ): Promise<HasilProsesAntrean> => {
      if (sedangProsesRef.current) {
        return { diproses: 0, berhasil: 0, gagal: 0 }
      }

      sedangProsesRef.current = true
      setSedangSinkronisasi(true)

      try {
        const penangan = penanganKustom || penanganDefault
        const hasil = await prosesAntrean(penangan)
        await segarkanData()
        return hasil
      } finally {
        sedangProsesRef.current = false
        setSedangSinkronisasi(false)
      }
    },
    [penanganDefault, segarkanData],
  )

  const cobaLagiItem = useCallback(
    async (
      id: string,
      penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
    ): Promise<void> => {
      await cobaLagiItemLib(id)
      await segarkanData()
      if (typeof navigator === 'undefined' || navigator.onLine) {
        void sinkronkanAntrean(penanganKustom)
      }
    },
    [segarkanData, sinkronkanAntrean],
  )

  const cobaLagiSemuaGagal = useCallback(
    async (
      penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
    ): Promise<number> => {
      const total = await cobaLagiSemuaGagalLib()
      await segarkanData()
      if (typeof navigator === 'undefined' || navigator.onLine) {
        void sinkronkanAntrean(penanganKustom)
      }
      return total
    },
    [segarkanData, sinkronkanAntrean],
  )

  // Pantau status online / offline dari peramban
  useEffect(() => {
    void segarkanData()

    const tanganiOnline = () => {
      setApakahDaring(true)
      // Saat jaringan kembali tersambung, otomatis kirim antrean yang tertunda (DoD)
      void sinkronkanAntrean()
    }

    const tanganiOffline = () => {
      setApakahDaring(false)
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('online', tanganiOnline)
      window.addEventListener('offline', tanganiOffline)
    }

    // Langganan pembaruan antrean lokal (reaktif antarkomponen)
    const lepasLangganan = langgananPerubahanAntrean(() => {
      void segarkanData()
    })

    return () => {
      if (typeof window !== 'undefined') {
        window.removeEventListener('online', tanganiOnline)
        window.removeEventListener('offline', tanganiOffline)
      }
      lepasLangganan()
    }
  }, [segarkanData, sinkronkanAntrean])

  const tambahAntrean = useCallback(
    async (masukan: MasukanTambahAntrean): Promise<ItemAntrean> => {
      const item = await tambahKeAntrean(masukan)
      await segarkanData()
      return item
    },
    [segarkanData],
  )

  const hapusAntrean = useCallback(
    async (id: string): Promise<void> => {
      await hapusItemAntrean(id)
      await segarkanData()
    },
    [segarkanData],
  )

  const bersihkanSukses = useCallback(async (): Promise<number> => {
    const dibersihkan = await bersihkanAntreanSukses()
    await segarkanData()
    return dibersihkan
  }, [segarkanData])

  const jumlahTertunda = statistik.menunggu + statistik.mengirim
  const jumlahGagal = statistik.gagal
  const jumlahTerkirim = statistik.sukses
  const jumlahMenunggu = jumlahTertunda + jumlahGagal

  // Penyusunan pesan status jelas dalam bahasa manusia (DoD T10-01 & T10-03)
  let pesanStatus = ''
  if (sedangSinkronisasi) {
    pesanStatus = 'Mengirim antrean ke peladen...'
  } else if (!apakahDaring) {
    if (jumlahMenunggu > 0) {
      pesanStatus = `menunggu dikirim ${jumlahMenunggu}`
    } else {
      pesanStatus = 'Mode luring (offline)'
    }
  } else if (jumlahGagal > 0 && jumlahTertunda > 0) {
    pesanStatus = `menunggu dikirim ${jumlahTertunda}, ${jumlahGagal} gagal`
  } else if (jumlahGagal > 0) {
    pesanStatus = `ada ${jumlahGagal} pesanan gagal dikirim`
  } else if (jumlahTertunda > 0) {
    pesanStatus = `menunggu dikirim ${jumlahTertunda}`
  } else {
    pesanStatus = 'Daring (semua pesanan terkirim)'
  }

  return {
    apakahDaring,
    jumlahMenunggu,
    jumlahTertunda,
    jumlahGagal,
    jumlahTerkirim,
    statistik,
    daftarAntrean,
    sedangSinkronisasi,
    pesanStatus,
    tambahAntrean,
    sinkronkanAntrean,
    cobaLagiItem,
    cobaLagiSemuaGagal,
    hapusAntrean,
    muatUlang: segarkanData,
    bersihkanSukses,
  }
}
