import { useCallback, useEffect, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import type { BarisTransaksi } from '../layar/kasir/DaftarTransaksi'

export type KeadaanRiwayat = 'memuat' | 'siap' | 'gagal'

export interface StateRiwayat {
  daftar: BarisTransaksi[]
  keadaan: KeadaanRiwayat
  pesan: string | null
  muat: () => void
}

interface BarisPembayaranPeladen {
  id: string
  waktu: string
  jumlah: number
  kembalian: number | null
  referensi: string | null
  metode_nama_saat_itu: string
  pesanan: {
    nomor: number | null
    subtotal: number
    pajak: number
    service: number
    total_diskon: number
    total: number
    dibuat_pada: string
    cabang_id: string
    pesanan_item: Array<{
      nama_saat_itu: string
      harga_saat_itu: number
      qty: number
      subtotal: number
      catatan: string | null
    }> | null
  } | null
}

const BATAS_BARIS = 30

/**
 * Riwayat transaksi NYATA dari peladen (PMB1-F-021 · kartu B-F-02).
 *
 * Kenapa ada: layar "Riwayat Transaksi" (terjangkau navigasi kasir) dulu diisi
 * SATU baris sintetis dari pembayaran terakhir — nomor selalu 1, tanggal dari
 * jam perangkat, namaResto keras-kode, item kosong, pajak/service/diskon nol,
 * metode selalu Tunai. Itu fitur setengah jalan yang menipu (PRD baris 30).
 *
 * Sumber data: tabel `pembayaran` (RLS `pembayaran_pilih` — hanya penyewa sendiri)
 * dengan rincian pesanan + item tersemat; difilter ke cabang aktif; terbaru dulu,
 * dibatasi 30 baris untuk layar kasir. Gagal jaringan = keadaan `gagal` yang
 * diumumkan jujur + bisa dicoba lagi — bukan daftar kosong diam-diam.
 */
export function useRiwayatTransaksi(cabangId: string | null): StateRiwayat {
  const [daftar, setDaftar] = useState<BarisTransaksi[]>([])
  const [keadaan, setKeadaan] = useState<KeadaanRiwayat>('memuat')
  const [pesan, setPesan] = useState<string | null>(null)

  const muat = useCallback(() => {
    if (!cabangId) {
      setKeadaan('gagal')
      setPesan('Cabang aktif belum diketahui.')
      return
    }
    const klien = klienSupabase()
    if (!klien) {
      setKeadaan('gagal')
      setPesan('Koneksi Supabase belum dikonfigurasi di perangkat ini.')
      return
    }
    setKeadaan('memuat')
    setPesan(null)
    void (async () => {
      try {
        const { data, error } = await klien
          .from('pembayaran')
          .select(
            'id, waktu, jumlah, kembalian, referensi, metode_nama_saat_itu, ' +
              'pesanan(nomor, subtotal, pajak, service, total_diskon, total, dibuat_pada, cabang_id, ' +
              'pesanan_item(nama_saat_itu, harga_saat_itu, qty, subtotal, catatan))',
          )
          .eq('pesanan.cabang_id', cabangId)
          .order('waktu', { ascending: false })
          .limit(BATAS_BARIS)
        if (error) {
          setDaftar([])
          setKeadaan('gagal')
          setPesan(`Riwayat tidak bisa dibaca peladen: ${error.message}`)
          return
        }
        const baris = ((data ?? []) as unknown as BarisPembayaranPeladen[]).map((b) => {
          const p = b.pesanan
          return {
            id: b.id,
            data: {
              // Nomor dari peladen — tanpa nomor pun jujur ditampilkan 0, bukan
              // dikarang 1 seperti versi sintetis yang lama.
              nomor: p?.nomor ?? 0,
              tanggal: p?.dibuat_pada ?? b.waktu,
              item: (p?.pesanan_item ?? []).map((it) => ({
                nama: it.nama_saat_itu,
                qty: it.qty,
                hargaSatuan: it.harga_saat_itu,
                subtotal: it.subtotal,
                catatan: it.catatan ?? undefined,
              })),
              subtotal: p?.subtotal ?? 0,
              totalDiskon: p?.total_diskon ?? 0,
              pajak: p?.pajak ?? 0,
              service: p?.service ?? 0,
              total: p?.total ?? b.jumlah,
            },
            pembayaran: [
              {
                metode: b.metode_nama_saat_itu,
                jumlah: b.jumlah,
                referensi: b.referensi ?? undefined,
              },
            ],
            kembalian: b.kembalian ?? 0,
          }
        })
        setDaftar(baris)
        setKeadaan('siap')
      } catch (err) {
        setDaftar([])
        setKeadaan('gagal')
        setPesan(err instanceof Error ? err.message : String(err))
      }
    })()
  }, [cabangId])

  useEffect(() => {
    muat()
  }, [muat])

  return { daftar, keadaan, pesan, muat }
}
