/**
 * Tema & kerapatan tampilan.
 * 10 tema + 2 kerapatan berasal dari rancangan v3 (prototipe/css/tokens.css)
 * yang sudah disetujui pemilik. Di sini hanya cara memilih dan menyimpannya.
 * Tidak ada warna mentah di berkas ini — warnanya dari token CSS.
 */

export type KodeTema =
  | 'terang'
  | 'hangat'
  | 'gelap'
  | 'kontras'
  | 'bara'
  | 'vintage'
  | 'alam'
  | 'tropis'
  | 'pastel'
  | 'etnik'

export type Kerapatan = 'nyaman' | 'padat'

export type ButirTema = {
  kode: KodeTema
  nama: string
  keterangan: string
}

export const TEMA: readonly ButirTema[] = [
  { kode: 'terang', nama: 'Terang Bersih', keterangan: 'Aksen hijau daun, kartu putih bersih.' },
  { kode: 'hangat', nama: 'Hangat Kedai', keterangan: 'Kertas krem, huruf serif hangat.' },
  { kode: 'gelap', nama: 'Gelap Dapur', keterangan: 'Latar arang, aksen kuning, cahaya lembut.' },
  { kode: 'kontras', nama: 'Kontras Tinggi', keterangan: 'Hitam-putih murni, garis tebal.' },
  { kode: 'bara', nama: 'Bara Panggang', keterangan: 'Huruf kapital raksasa, arang dan emas.' },
  { kode: 'vintage', nama: 'Vintage Klasik', keterangan: 'Kertas tua berbintik, marun.' },
  { kode: 'alam', nama: 'Alam Hijau', keterangan: 'Latar embun, pola daun samar.' },
  { kode: 'tropis', nama: 'Tropis Segar', keterangan: 'Biru laut, pola gelombang.' },
  { kode: 'pastel', nama: 'Pastel Manis', keterangan: 'Merah muda, bayangan ganda.' },
  { kode: 'etnik', nama: 'Etnik Nusantara', keterangan: 'Terakota, pola batik samar.' },
]

export const KERAPATAN: readonly { kode: Kerapatan; nama: string }[] = [
  { kode: 'nyaman', nama: 'Nyaman' },
  { kode: 'padat', nama: 'Padat' },
]

export const TEMA_BAWAAN: KodeTema = 'terang'
export const KERAPATAN_BAWAAN: Kerapatan = 'nyaman'

const KUNCI_TEMA = 'sajian.tema'
const KUNCI_KERAPATAN = 'sajian.kerapatan'

export function adalahKodeTema(nilai: string): nilai is KodeTema {
  return TEMA.some((butir) => butir.kode === nilai)
}

export function adalahKerapatan(nilai: string): nilai is Kerapatan {
  return KERAPATAN.some((butir) => butir.kode === nilai)
}

function akarDokumen(): HTMLElement | null {
  if (typeof document === 'undefined') return null
  return document.documentElement
}

/** Simpanan lokal (boleh tidak ada: mode penyamaran/menolak izin). */
function penyimpanan(): Storage | null {
  try {
    if (typeof localStorage === 'undefined') return null
    return localStorage
  } catch {
    return null
  }
}

/** Pasang tema ke elemen akar. Mengembalikan false kalau tidak ada DOM. */
export function terapkanTema(kode: KodeTema, akar: HTMLElement | null = akarDokumen()): boolean {
  if (!akar) return false
  akar.dataset.theme = kode
  return true
}

/** Pasang kerapatan tampilan (nyaman/padat) ke elemen akar. */
export function terapkanKerapatan(
  kode: Kerapatan,
  akar: HTMLElement | null = akarDokumen(),
): boolean {
  if (!akar) return false
  akar.dataset.density = kode
  return true
}

export function bacaPilihanTersimpan(): { tema: KodeTema; kerapatan: Kerapatan } {
  const simpan = penyimpanan()
  const temaTersimpan = simpan?.getItem(KUNCI_TEMA) ?? ''
  const kerapatanTersimpan = simpan?.getItem(KUNCI_KERAPATAN) ?? ''
  return {
    tema: adalahKodeTema(temaTersimpan) ? temaTersimpan : TEMA_BAWAAN,
    kerapatan: adalahKerapatan(kerapatanTersimpan) ? kerapatanTersimpan : KERAPATAN_BAWAAN,
  }
}

export function simpanPilihan(tema: KodeTema, kerapatan: Kerapatan): void {
  const simpan = penyimpanan()
  if (!simpan) return
  simpan.setItem(KUNCI_TEMA, tema)
  simpan.setItem(KUNCI_KERAPATAN, kerapatan)
}

/**
 * Warna bilah peramban di HP diambil dari token tema, bukan ditulis mentah di
 * index.html — supaya ikut berubah saat tema diganti.
 */
export function segarkanWarnaSistem(akar: HTMLElement | null = akarDokumen()): boolean {
  if (typeof document === 'undefined' || !akar) return false
  const meta = document.querySelector('meta[name="theme-color"]')
  if (!meta) return false
  const warna = getComputedStyle(akar).getPropertyValue('--accent').trim()
  if (!warna) return false
  meta.setAttribute('content', warna)
  return true
}

/** Dipanggil sekali sebelum aplikasi dirender. */
export function pasangTemaAwal(akar: HTMLElement | null = akarDokumen()): {
  tema: KodeTema
  kerapatan: Kerapatan
} {
  const pilihan = bacaPilihanTersimpan()
  terapkanTema(pilihan.tema, akar)
  terapkanKerapatan(pilihan.kerapatan, akar)
  segarkanWarnaSistem(akar)
  return pilihan
}
