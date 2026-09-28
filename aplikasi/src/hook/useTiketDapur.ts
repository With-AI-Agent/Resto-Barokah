/**
 * useTiketDapur — kabel data untuk layar dapur/bar (sisa Fase 4 butir c).
 *
 * Sampai batch sebelumnya `LayarDapur`/`LayarBar` adalah komponen murni yang
 * menunggu kontainer: `App.tsx` menyuntik `tiket={[]}`. Berkas ini kontainernya.
 *
 * Aturan yang mengikat (sama seperti komponen yang dilayaninya):
 *  - **Waktu peladen, bukan jam perangkat.** Umur tiket dihitung dari
 *    `dikirimPada` (kolom `dikirim_ke_dapur_pada`) dibandingkan `waktuSekarang`.
 *    `waktuSekarang` diambil dari RPC `public.waktu_peladen()` (migrasi 0038),
 *    bukan `new Date()` perangkat — jam dapur yang meleset tidak boleh membuat
 *    pesanan sehat terlihat "mendesak". Selama RPC belum menjawab, nilai awal
 *    tetap jam perangkat dan layar tidak pernah berhenti bekerja.
 *  - **Sumber kebenaran tetap peladen.** Cadangan di perangkat
 *    (`lib/antrean-lokal`) hanya dipakai supaya layar tetap informatif saat
 *    jaringan putus, dan selalu diberi tanda "Tertunda" oleh layar.
 *  - **Realtime + jaring pengaman.** Langganan `postgres_changes` dipakai bila
 *    tersedia; kalau saluran realtime gagal (proyek tanpa realtime, jaringan
 *    putus), hook memasang penyegaran berkala supaya papan tidak membeku.
 *  - **Tidak pernah meledak.** Klien Supabase belum dikonfigurasi, jawaban
 *    bukan JSON, atau RPC menolak → hook mengembalikan keadaan `gagal` +
 *    `pesan` bahasa Indonesia, bukan exception.
 */
import { useCallback, useEffect, useRef, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import {
  muatAntreanTerakhir,
  simpanAntreanTerakhir,
  type BagianAntrean,
} from '../lib/antrean-lokal'
import type {
  ItemKartuPesanan,
  StatusItemMasak,
  TiketPesanan,
  TipePesananKartu,
} from '../layar/dapur/KartuPesanan'
import type { KeadaanPapan } from '../layar/dapur/LayarDapur'

/** Baris gabungan `pesanan` + `pesanan_item` + `meja` sebagaimana diterima dari PostgREST. */
export interface BarisPesananDapur {
  id: string
  nomor: number | null
  tipe: string
  dibuat_pada: string
  dikirim_ke_dapur_pada: string | null
  meja: { nama: string | null } | { nama: string | null }[] | null
  pesanan_item:
    | {
        id: string
        menu_item_id: string
        nama_saat_itu: string
        qty: number
        catatan: string | null
        status: string
        tujuan: string | null
      }[]
    | null
}

const TIPE: Record<string, TipePesananKartu> = {
  dinein: 'dinein',
  takeaway: 'bawa_pulang',
  bawa_pulang: 'bawa_pulang',
  ojol: 'ojol',
}

const STATUS: Record<string, StatusItemMasak> = {
  baru: 'baru',
  dimasak: 'dimasak',
  siap: 'siap',
  batal: 'batal',
}

/** Nama meja dari bentuk jawaban PostgREST (objek, array, atau null). */
export function namaMeja(baris: BarisPesananDapur): string | null {
  const meja = baris.meja
  if (Array.isArray(meja)) return meja[0]?.nama ?? null
  return meja?.nama ?? null
}

/** Satu baris peladen → satu tiket layar. Nilai tak dikenal dipetakan aman, tidak melempar. */
export function petakanTiket(baris: BarisPesananDapur): TiketPesanan {
  const items: ItemKartuPesanan[] = (baris.pesanan_item ?? []).map((i) => ({
    id: i.id,
    menuItemId: i.menu_item_id,
    namaSaatItu: i.nama_saat_itu,
    qty: i.qty,
    catatan: i.catatan ?? null,
    status: STATUS[i.status] ?? 'baru',
    // Kolom `tujuan` NOT NULL sejak migrasi 0033; `?? 'dapur'` menjaga baris lama.
    tujuan: i.tujuan === 'bar' ? 'bar' : 'dapur',
  }))
  return {
    id: baris.id,
    nomor: baris.nomor ?? 0,
    tipe: TIPE[baris.tipe] ?? 'dinein',
    meja: namaMeja(baris),
    // FIFO butuh waktu KIRIM. Pesanan yang belum tercatat waktu kirimnya tetap
    // diurutkan (pakai waktu dibuat) supaya tidak hilang dari papan.
    dikirimPada: baris.dikirim_ke_dapur_pada ?? baris.dibuat_pada,
    items,
  }
}

/**
 * Keadaan papan dari hasil muat + cadangan perangkat.
 * `sebagian` = jaringan putus TAPI masih ada antrean tersimpan (layar memasang
 * tanda "Tertunda"); `gagal` = tidak ada yang bisa ditampilkan.
 */
export function keadaanPapanDari(adaGalat: boolean, adaCadangan: boolean): KeadaanPapan {
  if (!adaGalat) return 'siap'
  return adaCadangan ? 'sebagian' : 'gagal'
}

/** Apakah teks berbentuk UUID (dipakai untuk menyaring langganan realtime)? */
export function uuidSah(nilai: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(nilai.trim())
}

export interface HasilTiketDapur {
  tiket: TiketPesanan[]
  /** ISO waktu peladen (kepala `Date`), atau jam perangkat bila kepala tak terbaca. */
  waktuSekarang: string
  keadaan: KeadaanPapan
  /** Antrean cadangan dari perangkat — hanya berarti saat `keadaan` bukan `siap`. */
  antreanCadangan: TiketPesanan[]
  /** Kalimat siap tampil bila ada masalah; `null` bila sehat. */
  pesan: string | null
  muatUlang: () => void
  mulaiMasak: (itemId: string) => Promise<void>
  selesaiMasak: (itemId: string) => Promise<void>
  tandaiHabis: (menuItemId: string) => Promise<void>
}

const PILIHAN =
  'id, nomor, tipe, dibuat_pada, dikirim_ke_dapur_pada, meja(nama), ' +
  'pesanan_item(id, menu_item_id, nama_saat_itu, qty, catatan, status, tujuan)'

/** Status pesanan yang masih harus terlihat di papan dapur. */
const STATUS_PESANAN_AKTIF = ['dikirim', 'dimasak', 'siap']

export function useTiketDapur({
  cabangId,
  bagian,
  selangCadanganMs = 15_000,
}: {
  cabangId: string
  bagian: BagianAntrean
  /** Jarak penyegaran berkala saat realtime tidak tersedia (milidetik). */
  selangCadanganMs?: number
}): HasilTiketDapur {
  const [tiket, setTiket] = useState<TiketPesanan[]>([])
  const [cadangan, setCadangan] = useState<TiketPesanan[]>(
    () => muatAntreanTerakhir<TiketPesanan>(bagian) ?? [],
  )
  const [waktuSekarang, setWaktuSekarang] = useState<string>(() => new Date().toISOString())
  const [adaGalat, setAdaGalat] = useState(false)
  const [pesan, setPesan] = useState<string | null>(null)
  const [sedangMuat, setSedangMuat] = useState(true)
  const penyegar = useRef<(() => void) | null>(null)

  const muat = useCallback(async () => {
    const klien = klienSupabase()
    if (!klien) {
      setAdaGalat(true)
      setSedangMuat(false)
      setPesan('Sambungan Supabase belum dikonfigurasi pada perangkat ini.')
      return
    }
    try {
      const jawaban = await klien
        .from('pesanan')
        .select(PILIHAN)
        .eq('cabang_id', cabangId)
        .in('status', STATUS_PESANAN_AKTIF)
        .order('dikirim_ke_dapur_pada', { ascending: true, nullsFirst: false })
      if (jawaban.error) {
        setAdaGalat(true)
        setSedangMuat(false)
        setPesan('Antrean tidak bisa diambil dari peladen. Menampilkan antrean tersimpan bila ada.')
        return
      }
      const baris = (jawaban.data ?? []) as unknown as BarisPesananDapur[]
      const hasil = baris.map(petakanTiket)
      setTiket(hasil)
      setAdaGalat(false)
      setPesan(null)
      setSedangMuat(false)
      if (hasil.length > 0) {
        simpanAntreanTerakhir(bagian, hasil)
        setCadangan(hasil)
      }
      // Waktu peladen diambil SETELAH antrean tampil: kalau panggilan ini gagal,
      // papan tetap hidup dengan jam perangkat (lebih baik tampil daripada mati).
      const jam = await klien.rpc('waktu_peladen')
      const iso = (jam.data as { iso?: unknown } | null)?.iso
      if (typeof iso === 'string' && !Number.isNaN(new Date(iso).getTime())) {
        setWaktuSekarang(iso)
      }
    } catch {
      setAdaGalat(true)
      setSedangMuat(false)
      setPesan('Jaringan terputus saat mengambil antrean.')
    }
  }, [bagian, cabangId])

  useEffect(() => {
    penyegar.current = () => {
      void muat()
    }
    void muat()
    const klien = klienSupabase()
    if (!klien) return
    let berhenti: (() => void) | null = null
    let pewaktu: ReturnType<typeof setInterval> | null = null

    const pasangPenyegarBerkala = () => {
      if (pewaktu) return
      pewaktu = setInterval(() => {
        void muat()
      }, selangCadanganMs)
    }

    try {
      const namaSaluran = `kds-${bagian}-${cabangId}`
      let saluran = klien.channel(namaSaluran)
      const saringan = uuidSah(cabangId) ? { filter: `cabang_id=eq.${cabangId}` } : {}
      for (const tabel of ['pesanan', 'pesanan_item'] as const) {
        saluran = saluran.on(
          'postgres_changes',
          { event: '*', schema: 'public', table: tabel, ...saringan },
          () => {
            void muat()
          },
        )
      }
      const langganan = saluran.subscribe((status: string) => {
        // Realtime tidak tersedia/gagal → jangan biarkan papan membeku.
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') pasangPenyegarBerkala()
      })
      berhenti = () => {
        void klien.removeChannel(langganan)
      }
    } catch {
      pasangPenyegarBerkala()
    }

    return () => {
      if (pewaktu) clearInterval(pewaktu)
      if (berhenti) berhenti()
    }
  }, [bagian, cabangId, muat, selangCadanganMs])

  /** Aksi tulis lewat RPC peladen (bukan tambal-sulam di klien). */
  const panggil = useCallback(
    async (rpc: string, argumen: Record<string, unknown>, galat: string) => {
      const klien = klienSupabase()
      if (!klien) {
        setPesan('Sambungan Supabase belum dikonfigurasi pada perangkat ini.')
        return
      }
      const jawaban = await klien.rpc(rpc, argumen)
      if (jawaban.error) {
        setPesan(galat)
        return
      }
      setPesan(null)
      await muat()
    },
    [muat],
  )

  const mulaiMasak = useCallback(
    async (itemId: string) => {
      await panggil(
        'set_status_item',
        { p_item_id: itemId, p_status: 'dimasak' },
        'Status item gagal diperbarui.',
      )
    },
    [panggil],
  )

  const selesaiMasak = useCallback(
    async (itemId: string) => {
      await panggil(
        'set_status_item',
        { p_item_id: itemId, p_status: 'siap' },
        'Status item gagal diperbarui.',
      )
    },
    [panggil],
  )

  const tandaiHabis = useCallback(
    async (menuItemId: string) => {
      await panggil(
        'tandai_habis',
        { p_menu_item_id: menuItemId, p_cabang_id: cabangId, p_habis: true },
        'Menu gagal ditandai habis.',
      )
    },
    [cabangId, panggil],
  )

  return {
    tiket,
    waktuSekarang,
    keadaan: sedangMuat ? 'memuat' : keadaanPapanDari(adaGalat, cadangan.length > 0),
    antreanCadangan: cadangan,
    pesan,
    muatUlang: () => {
      void muat()
    },
    mulaiMasak,
    selesaiMasak,
    tandaiHabis,
  }
}
