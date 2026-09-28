/**
 * useBayar — kabel data layar Bayar (T5-01).
 *
 * Sama seperti `useTiketDapur` dan `useStok`: berkas ini kontainer, sedangkan
 * `Bayar.tsx` komponen murni yang tidak tahu apa-apa tentang jaringan.
 *
 * Aturan yang mengikat:
 *  - **Uang hanya lewat RPC `bayar_pesanan` (migrasi 0039).** Layar tidak pernah
 *    menulis tabel `pembayaran` langsung dan tidak pernah menghitung kembalian
 *    untuk disimpan — angka yang ditampilkan sebagai "perkiraan" hanya bantuan
 *    mata, angka SAH datang dari balasan peladen.
 *  - **Metode bayar dari peladen, hanya yang aktif.** Metode nonaktif tidak boleh
 *    tampil (DoD T5-01); penyaringannya di kueri, bukan disembunyikan di CSS.
 *  - **Kunci idempoten dibuat di klien, SATU per tagihan.** RPC 0039 idempoten per
 *    `(pesanan_id, kunci_idempoten)`: tombol yang terkirim dua kali saat jaringan
 *    goyah tidak mencatat uang dua kali. Karena itu kuncinya STABIL per tagihan +
 *    urutan pembayaran, bukan acak per klik.
 *  - **Tidak pernah meledak** — klien belum dikonfigurasi atau RPC menolak →
 *    keadaan `gagal` + `pesan` bahasa Indonesia (pesan dari peladen apa adanya,
 *    termasuk kode BY-301 bila total terlampaui).
 */
import { useCallback, useEffect, useRef, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import type { BarisTagihan, MetodeBayar } from '../layar/kasir/Bayar'

/** Baris `metode_bayar` sebagaimana diterima dari PostgREST. */
export interface BarisMetodeMentah {
  id: string
  nama: string
  jenis: string | null
  butuh_referensi: boolean | null
  urutan: number | string | null
}

/** Balasan RPC `bayar_pesanan` (migrasi 0039) — angka uang dari peladen. */
export interface BalasanBayarMentah {
  berhasil?: boolean | null
  kode?: string | null
  pesan?: string | null
  pembayaran_id?: string | null
  jumlah?: number | string | null
  kembalian?: number | string | null
  total_dibayar?: number | string | null
  total_pesanan?: number | string | null
  lunas?: boolean | null
  dobel?: boolean | null
}

export type KeadaanBayar = 'memuat' | 'gagal' | 'siap' | 'mengirim' | 'berhasil'

/** `numeric`/`bigint` bisa datang sebagai string; yang tidak terbaca jadi 0. */
export function angka(nilai: number | string | null | undefined): number {
  if (typeof nilai === 'number') return Number.isFinite(nilai) ? nilai : 0
  if (typeof nilai !== 'string') return 0
  const hasil = Number(nilai)
  return Number.isFinite(hasil) ? hasil : 0
}

export function petakanMetode(baris: BarisMetodeMentah): MetodeBayar {
  const jenis = baris.jenis === 'non_tunai' ? 'non_tunai' : 'tunai'
  return {
    id: baris.id,
    nama: baris.nama,
    jenis,
    // Metode non-tunai tanpa penanda eksplisit tetap wajib referensi: lebih baik
    // meminta nomor daripada menyimpan uang tanpa jejak rujukan.
    butuhReferensi: jenis === 'non_tunai' ? baris.butuh_referensi !== false : false,
    urutan: angka(baris.urutan),
  }
}

export function petakanBalasan(baris: BalasanBayarMentah | null): {
  jumlah: number
  kembalian: number
  totalDibayar: number
  totalPesanan: number
  lunas: boolean
  dobel: boolean
} {
  return {
    jumlah: angka(baris?.jumlah),
    kembalian: angka(baris?.kembalian),
    totalDibayar: angka(baris?.total_dibayar),
    totalPesanan: angka(baris?.total_pesanan),
    lunas: baris?.lunas === true,
    dobel: baris?.dobel === true,
  }
}

/**
 * Kunci idempoten yang STABIL: satu tagihan + urutan pembayaran ke-n.
 * Dipakai ulang saat kasir menekan tombol dua kali untuk pembayaran yang sama.
 */
export function kunciIdempoten(pesananId: string, urutanBayar: number): string {
  return `bayar-${pesananId}-${urutanBayar}`
}

export function useBayar(pesananId: string | null) {
  const [keadaan, setKeadaan] = useState<KeadaanBayar>('memuat')
  const [metode, setMetode] = useState<MetodeBayar[]>([])
  const [pesan, setPesan] = useState<string | null>(null)
  const [terakhir, setTerakhir] = useState<BarisTagihan | null>(null)
  // Berapa kali pembayaran berhasil dicatat untuk tagihan ini — penentu urutan
  // di kunci idempoten. Disimpan di ref supaya tidak memicu render ulang.
  const urutanBayar = useRef(0)

  const muat = useCallback(async () => {
    if (!pesananId) {
      setKeadaan('gagal')
      setPesan('Tidak ada tagihan yang dipilih.')
      return
    }
    setKeadaan('memuat')
    setPesan(null)
    const klien = klienSupabase()
    if (!klien) {
      setKeadaan('gagal')
      setPesan('Koneksi Supabase belum dikonfigurasi di perangkat ini.')
      return
    }
    try {
      // Hanya metode AKTIF, urut `urutan` lalu nama (DoD T5-01: metode nonaktif
      // tidak tampil sama sekali).
      const hasil = await klien
        .from('metode_bayar')
        .select('id, nama, jenis, butuh_referensi, urutan')
        .eq('aktif', true)
        .order('urutan', { ascending: true })
        .order('nama', { ascending: true })
      if (hasil.error) {
        setKeadaan('gagal')
        setPesan(hasil.error.message)
        return
      }
      const baris = (hasil.data ?? []) as unknown as BarisMetodeMentah[]
      setMetode(baris.map(petakanMetode))
      setKeadaan('siap')
    } catch (e) {
      setKeadaan('gagal')
      setPesan(e instanceof Error ? e.message : 'Gagal memuat metode bayar.')
    }
  }, [pesananId])

  useEffect(() => {
    void muat()
  }, [muat])

  /**
   * Catat satu pembayaran. Mengembalikan balasan peladen apa adanya supaya layar
   * bisa menampilkan kembalian SAH dan tahu apakah tagihan sudah lunas.
   */
  const bayar = useCallback(
    async (masukan: {
      metodeId: string
      jumlah: number
      diterima?: number | null
      referensi?: string | null
    }) => {
      if (!pesananId) {
        setPesan('Tidak ada tagihan yang dipilih.')
        return null
      }
      const klien = klienSupabase()
      if (!klien) {
        setKeadaan('gagal')
        setPesan('Koneksi Supabase belum dikonfigurasi di perangkat ini.')
        return null
      }
      setKeadaan('mengirim')
      setPesan(null)
      try {
        const jawaban = await klien.rpc('bayar_pesanan', {
          p_pesanan_id: pesananId,
          p_metode_id: masukan.metodeId,
          p_jumlah: masukan.jumlah,
          p_diterima: masukan.diterima ?? null,
          p_referensi: masukan.referensi ?? null,
          p_kunci_idempoten: kunciIdempoten(pesananId, urutanBayar.current + 1),
        })
        if (jawaban.error) {
          setKeadaan('siap')
          setPesan(jawaban.error.message)
          return null
        }
        const balasan = petakanBalasan(jawaban.data as BalasanBayarMentah | null)
        // Ulangan kunci yang sama TIDAK menambah uang, jadi urutan hanya maju
        // untuk pembayaran yang benar-benar baru.
        if (!balasan.dobel) urutanBayar.current += 1
        setTerakhir({
          ...balasan,
          sisa: Math.max(0, balasan.totalPesanan - balasan.totalDibayar),
        })
        setKeadaan('berhasil')
        return balasan
      } catch (e) {
        setKeadaan('siap')
        setPesan(e instanceof Error ? e.message : 'Gagal mencatat pembayaran.')
        return null
      }
    },
    [pesananId],
  )

  /** Selesai melihat struk: kembali siap untuk pembayaran berikutnya (split bill). */
  const lanjut = useCallback(() => {
    setTerakhir(null)
    setKeadaan('siap')
  }, [])

  return { keadaan, metode, pesan, terakhir, bayar, muat, lanjut }
}
