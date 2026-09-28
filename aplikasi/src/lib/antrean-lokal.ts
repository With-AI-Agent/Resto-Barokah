/**
 * Penyimpanan antrean cadangan & pemulihan lokal per perangkat (T4-10, T10-09).
 *
 * Layar dapur, bar, dan kasir harus tetap tahan banting saat gangguan listrik/jaringan:
 * 1. Dapur & Bar: Tiket terakhir disimpan di localStorage dan bisa ditampilkan
 *    dengan tanda cadangan/tertunda saat jaringan putus atau perangkat baru dinyalakan.
 * 2. Kasir (T10-09): Draf pesanan keranjang disimpan otomatis ke penyimpanan lokal
 *    setiap perubahan dan dipulihkan kembali saat kasir membuka aplikasi setelah mati lampu.
 * 3. Tagihan Terbuka (Open Bill): Disimpan lokal agar kasir tetap tahu pesanan meja aktif.
 * 4. Rekonsiliasi Server-Wins: Peladen adalah sumber kebenaran utama; saat tersambung
 *    kembali, data peladen selalu menang (server-wins) untuk mencegah data lokal usang menimpa.
 *
 * Semua operasi TIDAK meledak: penyimpanan penuh / mode privat / JSON rusak cukup
 * menghasilkan nilai kosong / null, tidak menggagalkan layar.
 */

export type BagianAntrean = 'dapur' | 'bar'

const KUNCI_ANTREAN = (bagian: BagianAntrean) => `resto.antrean-terakhir.${bagian}`
const KUNCI_DRAF_KASIR = (cabangId: string) => `resto.kasir.draf.${cabangId}`
const KUNCI_TAGIHAN_TERBUKA = (cabangId: string) => `resto.kasir.tagihan-terbuka.${cabangId}`

// ============================================================================
// 1. ANTREAN DAPUR & BAR (T4-10)
// ============================================================================

export function simpanAntreanTerakhir<T>(bagian: BagianAntrean, tiket: T[]): void {
  try {
    if (typeof localStorage === 'undefined') return
    const muatan = {
      versi: 1 as const,
      bagian,
      tiket,
      disimpanPada: new Date().toISOString(),
    }
    localStorage.setItem(KUNCI_ANTREAN(bagian), JSON.stringify(muatan))
  } catch {
    // Penyimpanan penuh / ditolak peramban — cadangan bersifat sukarela.
  }
}

export function muatAntreanTerakhir<T>(bagian: BagianAntrean): T[] | null {
  try {
    if (typeof localStorage === 'undefined') return null
    const mentah = localStorage.getItem(KUNCI_ANTREAN(bagian))
    if (!mentah) return null
    const muatan: unknown = JSON.parse(mentah)
    if (
      typeof muatan === 'object' &&
      muatan !== null &&
      (muatan as { versi?: unknown }).versi === 1 &&
      Array.isArray((muatan as { tiket?: unknown }).tiket)
    ) {
      return (muatan as { tiket: T[] }).tiket
    }
    return null
  } catch {
    return null
  }
}

export function hapusAntreanTerakhir(bagian: BagianAntrean): void {
  try {
    if (typeof localStorage === 'undefined') return
    localStorage.removeItem(KUNCI_ANTREAN(bagian))
  } catch {
    // abaikan
  }
}

// ============================================================================
// 2. PEMULIHAN DRAF KERANJANG KASIR (T10-09)
// ============================================================================

export interface DrafPesananKasir<T = unknown> {
  versi: 1
  cabangId: string
  daftarItemKeranjang: T[]
  tipePesanan?: string
  mejaAktif?: {
    id: string
    nama: string
    status: string
    aktif: boolean
  } | null
  diskonAktif?: number
  catatanPesananUmum?: string
  disimpanPada: string
}

export function simpanDrafKasir<T>(
  cabangId: string,
  draf: {
    daftarItemKeranjang: T[]
    tipePesanan?: string
    mejaAktif?: { id: string; nama: string; status: string; aktif: boolean } | null
    diskonAktif?: number
    catatanPesananUmum?: string
  },
): void {
  try {
    if (typeof localStorage === 'undefined') return
    // Jika keranjang kosong, hapus draf daripada menyimpan array kosong
    if (!draf.daftarItemKeranjang || draf.daftarItemKeranjang.length === 0) {
      hapusDrafKasir(cabangId)
      return
    }

    const muatan: DrafPesananKasir<T> = {
      versi: 1,
      cabangId,
      daftarItemKeranjang: draf.daftarItemKeranjang,
      tipePesanan: draf.tipePesanan,
      mejaAktif: draf.mejaAktif,
      diskonAktif: draf.diskonAktif,
      catatanPesananUmum: draf.catatanPesananUmum,
      disimpanPada: new Date().toISOString(),
    }
    localStorage.setItem(KUNCI_DRAF_KASIR(cabangId), JSON.stringify(muatan))
  } catch {
    // Abaikan kegagalan kuota storage
  }
}

export function muatDrafKasir<T = unknown>(cabangId: string): DrafPesananKasir<T> | null {
  try {
    if (typeof localStorage === 'undefined') return null
    const mentah = localStorage.getItem(KUNCI_DRAF_KASIR(cabangId))
    if (!mentah) return null
    const muatan: unknown = JSON.parse(mentah)
    if (
      typeof muatan === 'object' &&
      muatan !== null &&
      (muatan as { versi?: unknown }).versi === 1 &&
      (muatan as { cabangId?: unknown }).cabangId === cabangId &&
      Array.isArray((muatan as { daftarItemKeranjang?: unknown }).daftarItemKeranjang) &&
      (muatan as { daftarItemKeranjang: unknown[] }).daftarItemKeranjang.length > 0
    ) {
      return muatan as DrafPesananKasir<T>
    }
    return null
  } catch {
    return null
  }
}

export function hapusDrafKasir(cabangId: string): void {
  try {
    if (typeof localStorage === 'undefined') return
    localStorage.removeItem(KUNCI_DRAF_KASIR(cabangId))
  } catch {
    // abaikan
  }
}

// ============================================================================
// 3. CADANGAN TAGIHAN TERBUKA LOKAL (T10-09)
// ============================================================================

export interface CadanganTagihanTerbuka<T = unknown> {
  versi: 1
  cabangId: string
  tagihan: T[]
  disimpanPada: string
}

export function simpanTagihanTerbukaLokal<T>(cabangId: string, tagihan: T[]): void {
  try {
    if (typeof localStorage === 'undefined') return
    const muatan: CadanganTagihanTerbuka<T> = {
      versi: 1,
      cabangId,
      tagihan,
      disimpanPada: new Date().toISOString(),
    }
    localStorage.setItem(KUNCI_TAGIHAN_TERBUKA(cabangId), JSON.stringify(muatan))
  } catch {
    // abaikan
  }
}

export function muatTagihanTerbukaLokal<T>(cabangId: string): T[] | null {
  try {
    if (typeof localStorage === 'undefined') return null
    const mentah = localStorage.getItem(KUNCI_TAGIHAN_TERBUKA(cabangId))
    if (!mentah) return null
    const muatan: unknown = JSON.parse(mentah)
    if (
      typeof muatan === 'object' &&
      muatan !== null &&
      (muatan as { versi?: unknown }).versi === 1 &&
      (muatan as { cabangId?: unknown }).cabangId === cabangId &&
      Array.isArray((muatan as { tagihan?: unknown }).tagihan)
    ) {
      return (muatan as CadanganTagihanTerbuka<T>).tagihan
    }
    return null
  } catch {
    return null
  }
}

export function hapusTagihanTerbukaLokal(cabangId: string): void {
  try {
    if (typeof localStorage === 'undefined') return
    localStorage.removeItem(KUNCI_TAGIHAN_TERBUKA(cabangId))
  } catch {
    // abaikan
  }
}

// ============================================================================
// 4. ATURAN REKONSILIASI SERVER-WINS (TECH_SPEC §10 & §11 / T10-09)
// ============================================================================

export interface EntitasSinkron {
  id: string
  diperbaruiPada?: string
  status?: string
  [kunci: string]: unknown
}

export interface HasilRekonsiliasi<T extends EntitasSinkron> {
  dataTerpilih: T
  sumber: 'server' | 'lokal'
  adaKonflik: boolean
  alasan: string
}

/**
 * Rekonsiliasi satu entitas lokal vs server berprinsip Server-Wins.
 * Mitigasi T10-09: Data lokal usang dilarang menimpa data server.
 * Jika entitas ada di server, peladen selalu menang.
 * Jika terdapat perbedaan nilai dengan draf lokal, ditandai adaKonflik: true.
 * Jika hanya ada di lokal (mis. transaksi baru belum terkirim), lokal dipertahankan.
 */
export function rekonsiliasiEntitas<T extends EntitasSinkron>(
  lokal: T | null | undefined,
  server: T | null | undefined,
): HasilRekonsiliasi<T> | null {
  if (!lokal && !server) return null

  // Hanya ada di server
  if (!lokal && server) {
    return {
      dataTerpilih: server,
      sumber: 'server',
      adaKonflik: false,
      alasan: 'Data berasal dari peladen.',
    }
  }

  // Hanya ada di lokal (belum tersinkron ke peladen)
  if (lokal && !server) {
    return {
      dataTerpilih: lokal,
      sumber: 'lokal',
      adaKonflik: false,
      alasan: 'Data draf lokal belum tersinkron ke peladen.',
    }
  }

  // Keduanya ada -> Server selalu menang (Server-Wins)
  const lokalStr = JSON.stringify(lokal)
  const serverStr = JSON.stringify(server)
  const adaKonflik = lokalStr !== serverStr

  return {
    dataTerpilih: server!,
    sumber: 'server',
    adaKonflik,
    alasan: adaKonflik
      ? 'Konflik terdeteksi: peladen diprioritaskan (server-wins) untuk mencegah data usang menimpa.'
      : 'Data lokal identik dengan peladen.',
  }
}

/**
 * Merekonsiliasi daftar pesanan/tagihan lokal vs peladen.
 * Semua entitas peladen diprioritaskan. Entitas lokal yang belum terdaftar di
 * peladen (id unik baru) dipertahankan sebagai draf menunggu kirim.
 */
export function rekonsiliasiDaftarPesanan<T extends EntitasSinkron>(
  daftarLokal: T[],
  daftarServer: T[],
): {
  hasil: T[]
  konflik: { id: string; lokal: T; server: T; alasan: string }[]
  jumlahDipulihkanDariLokal: number
} {
  const mapServer = new Map<string, T>()
  for (const s of daftarServer) {
    mapServer.set(s.id, s)
  }

  const hasil: T[] = [...daftarServer]
  const konflik: { id: string; lokal: T; server: T; alasan: string }[] = []
  let jumlahDipulihkanDariLokal = 0

  for (const l of daftarLokal) {
    const s = mapServer.get(l.id)
    if (!s) {
      // Belum ada di server: pertahankan draf lokal
      hasil.push(l)
      jumlahDipulihkanDariLokal++
    } else {
      // Ada di server: cek apakah ada selisih
      const rek = rekonsiliasiEntitas(l, s)
      if (rek?.adaKonflik) {
        konflik.push({
          id: l.id,
          lokal: l,
          server: s,
          alasan: rek.alasan,
        })
      }
    }
  }

  return {
    hasil,
    konflik,
    jumlahDipulihkanDariLokal,
  }
}
