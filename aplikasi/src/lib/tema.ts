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

/** Simpanan lokal (boleh tidak ada: mode penyamaran/menolak izin).
 *  Penjagaan di sini hanya untuk PENGAMBILAN objeknya; pemanggilan
 *  `getItem`/`setItem` dijaga terpisah di `bacaKunci`/`tulisKunci` karena
 *  keduanya bisa melempar sendiri (I F-06). */
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

/**
 * Baca satu kunci dari simpanan. **Tidak pernah meledak** (temuan audit I F-06):
 * `localStorage.getItem` sendiri bisa MELEMPAR `SecurityError` saat peramban
 * menolak penyimpanan — dan dulu `try/catch` hanya mengelilingi pengambilan
 * objeknya, bukan pemanggilan metodenya. Kegagalan baca = kembali ke bawaan.
 */
function bacaKunci(simpan: Storage | null, kunci: string): string {
  try {
    return simpan?.getItem(kunci) ?? ''
  } catch {
    return ''
  }
}

/**
 * Tulis satu kunci ke simpanan. **Tidak pernah meledak** (temuan audit I F-06):
 * `setItem` melempar `QuotaExceededError` saat penyimpanan penuh. Dulu lemparan
 * itu menembus effect React saat mengganti tema — bukan sekadar gagal menyimpan.
 * Mengembalikan `true` hanya kalau nilainya benar-benar tersimpan.
 */
function tulisKunci(simpan: Storage | null, kunci: string, nilai: string): boolean {
  if (!simpan) return false
  try {
    simpan.setItem(kunci, nilai)
    return true
  } catch {
    return false
  }
}

export function bacaPilihanTersimpan(): { tema: KodeTema; kerapatan: Kerapatan } {
  const simpan = penyimpanan()
  const temaTersimpan = bacaKunci(simpan, KUNCI_TEMA)
  const kerapatanTersimpan = bacaKunci(simpan, KUNCI_KERAPATAN)
  return {
    tema: adalahKodeTema(temaTersimpan) ? temaTersimpan : TEMA_BAWAAN,
    kerapatan: adalahKerapatan(kerapatanTersimpan) ? kerapatanTersimpan : KERAPATAN_BAWAAN,
  }
}

/**
 * Simpan pilihan tema & kerapatan.
 * Mengembalikan `false` kalau tidak bisa disimpan (tidak ada simpanan, izin ditolak,
 * atau penyimpanan penuh) — pilihan tetap berlaku di layar, hanya tidak diingat
 * kunjungan berikutnya. Pemanggil BOLEH mengabaikan nilai ini; yang penting ia tidak
 * pernah meledak.
 */
export function simpanPilihan(tema: KodeTema, kerapatan: Kerapatan): boolean {
  const simpan = penyimpanan()
  if (!simpan) return false
  // Dua kunci ditulis terpisah: kalau yang pertama berhasil dan yang kedua penuh,
  // lebih jujur mengembalikan false daripada mengaku semuanya tersimpan.
  const temaTersimpan = tulisKunci(simpan, KUNCI_TEMA, tema)
  const kerapatanTersimpan = tulisKunci(simpan, KUNCI_KERAPATAN, kerapatan)
  return temaTersimpan && kerapatanTersimpan
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
