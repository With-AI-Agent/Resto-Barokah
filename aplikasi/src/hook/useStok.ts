/**
 * useStok — kabel data layar Stok (T4-06) & Opname (T4-07).
 *
 * Sama seperti `useTiketDapur`, berkas ini kontainer untuk komponen murni:
 * `Stok.tsx` dan `Opname.tsx` tidak tahu apa-apa tentang jaringan.
 *
 * Aturan yang mengikat:
 *  - **Buku besar adalah satu-satunya sumber riwayat.** Layar tidak pernah
 *    menulis `stok_pergerakan` langsung; penambahan/pengurangan lewat RPC
 *    `set_stok` (delta + alasan wajib) dan opname lewat `opname_stok` (jumlah
 *    fisik — selisih dihitung peladen).
 *  - **Angka dari peladen apa adanya.** `jumlah` bertipe `numeric` di database,
 *    jadi PostgREST mengirimnya sebagai string. Nilai dipetakan ke `number`
 *    tanpa pembulatan diam-diam; yang tidak sah jadi 0 dan ditandai di `pesan`.
 *  - **Realtime + jaring pengaman** seperti papan dapur: langganan
 *    `postgres_changes` pada `stok_bahan`/`stok_pergerakan`, plus penyegaran
 *    berkala bila saluran realtime mati.
 *  - **Tidak pernah meledak** — klien belum dikonfigurasi atau RPC menolak →
 *    keadaan `gagal` + `pesan` bahasa Indonesia.
 */
import { useCallback, useEffect, useRef, useState } from 'react'
import { klienSupabase } from '../lib/supabase'
import type { BarisBahan, BarisPergerakan } from '../layar/dapur/Stok'

/** Baris `stok_bahan` sebagaimana diterima dari PostgREST (numeric → string). */
export interface BarisBahanMentah {
  id: string
  nama: string
  satuan: string
  jumlah: number | string | null
  minimum: number | string | null
  dipantau: boolean | null
}

/** Baris `stok_pergerakan` + nama bahan dan nama pelaku (gabanungan). */
export interface BarisPergerakanMentah {
  id: number | string
  stok_bahan_id: string
  jenis: string
  jumlah: number | string | null
  alasan: string | null
  waktu: string
  stok_bahan: { nama: string | null } | { nama: string | null }[] | null
  pelaku: { nama: string | null } | { nama: string | null }[] | null
}

const JENIS: Record<string, BarisPergerakan['jenis']> = {
  masuk: 'masuk',
  keluar: 'keluar',
  opname: 'opname',
  koreksi: 'koreksi',
}

/** `numeric` datang sebagai string; yang tidak terbaca jadi 0 (bukan NaN ke layar). */
export function angka(nilai: number | string | null | undefined): number {
  if (typeof nilai === 'number') return Number.isFinite(nilai) ? nilai : 0
  if (typeof nilai !== 'string') return 0
  const hasil = Number(nilai)
  return Number.isFinite(hasil) ? hasil : 0
}

function namaDariGabungan(
  nilai: { nama: string | null } | { nama: string | null }[] | null,
): string | null {
  if (Array.isArray(nilai)) return nilai[0]?.nama ?? null
  return nilai?.nama ?? null
}

export function petakanBahan(baris: BarisBahanMentah): BarisBahan {
  return {
    id: baris.id,
    nama: baris.nama,
    satuan: baris.satuan,
    jumlah: angka(baris.jumlah),
    minimum: angka(baris.minimum),
    dipantau: baris.dipantau === true,
  }
}

export function petakanPergerakan(baris: BarisPergerakanMentah): BarisPergerakan {
  return {
    id: String(baris.id),
    bahanId: baris.stok_bahan_id,
    namaBahan: namaDariGabungan(baris.stok_bahan) ?? '(bahan tidak dikenal)',
    jenis: JENIS[baris.jenis] ?? 'koreksi',
    jumlah: angka(baris.jumlah),
    alasan: baris.alasan ?? null,
    oleh: namaDariGabungan(baris.pelaku),
    waktu: baris.waktu,
  }
}

export interface HasilStok {
  bahan: BarisBahan[]
  riwayat: BarisPergerakan[]
  keadaan: 'memuat' | 'gagal' | 'siap'
  pesan: string | null
  muatUlang: () => void
  /** Catat penambahan (+) / pengurangan (−) — delta, alasan wajib. */
  catatStok: (bahanId: string, delta: number, alasan: string) => Promise<void>
  /** Catat jumlah fisik hasil hitung; selisih dihitung peladen. */
  catatOpname: (bahanId: string, jumlahFisik: number, alasan: string) => Promise<void>
}

const PILIHAN_BAHAN = 'id, nama, satuan, jumlah, minimum, dipantau'
const PILIHAN_RIWAYAT =
  'id, stok_bahan_id, jenis, jumlah, alasan, waktu, stok_bahan(nama), pelaku(nama)'

export function useStok({
  batasRiwayat = 50,
  selangCadanganMs = 20_000,
}: {
  /** Berapa baris buku besar terakhir yang ditampilkan. */
  batasRiwayat?: number
  /** Jarak penyegaran berkala bila realtime tidak tersedia (milidetik). */
  selangCadanganMs?: number
} = {}): HasilStok {
  const [bahan, setBahan] = useState<BarisBahan[]>([])
  const [riwayat, setRiwayat] = useState<BarisPergerakan[]>([])
  const [adaGalat, setAdaGalat] = useState(false)
  const [pesan, setPesan] = useState<string | null>(null)
  const [sedangMuat, setSedangMuat] = useState(true)
  const pewaktu = useRef<ReturnType<typeof setInterval> | null>(null)

  const muat = useCallback(async () => {
    const klien = klienSupabase()
    if (!klien) {
      setAdaGalat(true)
      setSedangMuat(false)
      setPesan('Sambungan Supabase belum dikonfigurasi pada perangkat ini.')
      return
    }
    try {
      const [jawabBahan, jawabRiwayat] = await Promise.all([
        klien.from('stok_bahan').select(PILIHAN_BAHAN).order('nama', { ascending: true }),
        klien
          .from('stok_pergerakan')
          .select(PILIHAN_RIWAYAT)
          .order('waktu', { ascending: false })
          .limit(batasRiwayat),
      ])
      if (jawabBahan.error || jawabRiwayat.error) {
        setAdaGalat(true)
        setSedangMuat(false)
        setPesan('Data stok tidak bisa diambil dari peladen.')
        return
      }
      setBahan((jawabBahan.data ?? []).map((b) => petakanBahan(b as BarisBahanMentah)))
      setRiwayat(
        (jawabRiwayat.data ?? []).map((r) => petakanPergerakan(r as BarisPergerakanMentah)),
      )
      setAdaGalat(false)
      setPesan(null)
      setSedangMuat(false)
    } catch {
      setAdaGalat(true)
      setSedangMuat(false)
      setPesan('Jaringan terputus saat mengambil data stok.')
    }
  }, [batasRiwayat])

  useEffect(() => {
    void muat()
    const klien = klienSupabase()
    if (!klien) return
    let berhenti: (() => void) | null = null

    const pasangPenyegarBerkala = () => {
      if (pewaktu.current) return
      pewaktu.current = setInterval(() => {
        void muat()
      }, selangCadanganMs)
    }

    try {
      let saluran = klien.channel('stok-bahan')
      for (const tabel of ['stok_bahan', 'stok_pergerakan'] as const) {
        saluran = saluran.on(
          'postgres_changes',
          { event: '*', schema: 'public', table: tabel },
          () => {
            void muat()
          },
        )
      }
      const langganan = saluran.subscribe((status: string) => {
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') pasangPenyegarBerkala()
      })
      berhenti = () => {
        void klien.removeChannel(langganan)
      }
    } catch {
      pasangPenyegarBerkala()
    }

    return () => {
      if (pewaktu.current) clearInterval(pewaktu.current)
      if (berhenti) berhenti()
    }
  }, [muat, selangCadanganMs])

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

  const catatStok = useCallback(
    async (bahanId: string, delta: number, alasan: string) => {
      await panggil(
        'set_stok',
        { p_stok_bahan_id: bahanId, p_jumlah: delta, p_alasan: alasan },
        'Perubahan stok gagal dicatat.',
      )
    },
    [panggil],
  )

  const catatOpname = useCallback(
    async (bahanId: string, jumlahFisik: number, alasan: string) => {
      await panggil(
        'opname_stok',
        { p_stok_bahan_id: bahanId, p_jumlah_fisik: jumlahFisik, p_alasan: alasan },
        'Hasil opname gagal dicatat.',
      )
    },
    [panggil],
  )

  return {
    bahan,
    riwayat,
    keadaan: sedangMuat ? 'memuat' : adaGalat ? 'gagal' : 'siap',
    pesan,
    muatUlang: () => {
      void muat()
    },
    catatStok,
    catatOpname,
  }
}
