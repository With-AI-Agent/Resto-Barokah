/**
 * Generator QR Code ringan murni TypeScript (tanpa pustaka luar/dependensi pihak ketiga).
 * Mendukung teks/URL umum hingga Versi 10 (kapasitas ~216 byte dengan koreksi kesalahan tingkat M).
 * Menghasilkan matriks biner modul (true = gelap, false = terang) dan SVG tajam.
 */

// Inisialisasi tabel logaritma dan eksponensial untuk aritmatika medan Galois GF(256)
const EXP = new Uint8Array(512)
const LOG = new Uint8Array(256)

let x = 1
for (let i = 0; i < 255; i++) {
  EXP[i] = x
  EXP[i + 255] = x
  LOG[x] = i
  x <<= 1
  if (x & 256) x ^= 0x11d
}

function perkalianGf(a: number, b: number): number {
  if (a === 0 || b === 0) return 0
  return EXP[(LOG[a] + LOG[b]) % 255]
}

function buatPolinomialGenerator(jumlahEc: number): number[] {
  let g = [1]
  for (let i = 0; i < jumlahEc; i++) {
    const berikut = new Array<number>(g.length + 1).fill(0)
    const alfa = EXP[i]
    for (let j = 0; j < g.length; j++) {
      berikut[j] ^= g[j]
      berikut[j + 1] ^= perkalianGf(g[j], alfa)
    }
    g = berikut
  }
  return g
}

function hitungCodewordsEc(data: number[], jumlahEc: number): number[] {
  const gen = buatPolinomialGenerator(jumlahEc)
  const pesan = new Array<number>(data.length + jumlahEc).fill(0)
  for (let i = 0; i < data.length; i++) pesan[i] = data[i]

  for (let i = 0; i < data.length; i++) {
    const sukuUtama = pesan[i]
    if (sukuUtama !== 0) {
      for (let j = 0; j < gen.length; j++) {
        pesan[i + j] ^= perkalianGf(gen[j], sukuUtama)
      }
    }
  }
  return pesan.slice(data.length)
}

interface BlokSpek {
  count: number
  data: number
}

interface VersiSpek {
  v: number
  size: number
  totalCW: number
  dataCW: number
  ecCW: number
  blocks: BlokSpek[]
  align?: number[]
}

const TABEL_M: VersiSpek[] = [
  { v: 1, size: 21, totalCW: 26, dataCW: 16, ecCW: 10, blocks: [{ count: 1, data: 16 }] },
  {
    v: 2,
    size: 25,
    totalCW: 44,
    dataCW: 28,
    ecCW: 16,
    blocks: [{ count: 1, data: 28 }],
    align: [6, 18],
  },
  {
    v: 3,
    size: 29,
    totalCW: 70,
    dataCW: 44,
    ecCW: 26,
    blocks: [{ count: 1, data: 44 }],
    align: [6, 22],
  },
  {
    v: 4,
    size: 33,
    totalCW: 100,
    dataCW: 64,
    ecCW: 18,
    blocks: [{ count: 2, data: 32 }],
    align: [6, 26],
  },
  {
    v: 5,
    size: 37,
    totalCW: 134,
    dataCW: 86,
    ecCW: 24,
    blocks: [{ count: 2, data: 43 }],
    align: [6, 30],
  },
  {
    v: 6,
    size: 41,
    totalCW: 172,
    dataCW: 108,
    ecCW: 16,
    blocks: [{ count: 4, data: 27 }],
    align: [6, 34],
  },
  {
    v: 7,
    size: 45,
    totalCW: 196,
    dataCW: 124,
    ecCW: 18,
    blocks: [{ count: 4, data: 31 }],
    align: [6, 22, 38],
  },
  {
    v: 8,
    size: 49,
    totalCW: 242,
    dataCW: 154,
    ecCW: 22,
    blocks: [
      { count: 2, data: 38 },
      { count: 2, data: 39 },
    ],
    align: [6, 24, 42],
  },
  {
    v: 9,
    size: 53,
    totalCW: 292,
    dataCW: 182,
    ecCW: 22,
    blocks: [
      { count: 3, data: 36 },
      { count: 2, data: 37 },
    ],
    align: [6, 26, 46],
  },
  {
    v: 10,
    size: 57,
    totalCW: 346,
    dataCW: 216,
    ecCW: 26,
    blocks: [
      { count: 4, data: 43 },
      { count: 1, data: 44 },
    ],
    align: [6, 28, 50],
  },
]

function enkodeData(teks: string, spek: VersiSpek): number[] {
  const byteData = new TextEncoder().encode(teks)
  const batasHeader = spek.v < 10 ? 2 : 3
  if (byteData.length > spek.dataCW - batasHeader) {
    throw new Error(`Data (${byteData.length} byte) melampaui kapasitas versi ${spek.v}`)
  }

  const bitArray: number[] = []
  function tambahBit(nilai: number, panjang: number) {
    for (let i = panjang - 1; i >= 0; i--) {
      bitArray.push((nilai >> i) & 1)
    }
  }

  // Mode Byte: 0100 (4 bit)
  tambahBit(4, 4)

  // Indikator jumlah karakter: 8 bit untuk v1-9, 16 bit untuk v10+
  const bitHitungan = spek.v < 10 ? 8 : 16
  tambahBit(byteData.length, bitHitungan)

  // Byte data
  for (const b of byteData) {
    tambahBit(b, 8)
  }

  // Terminator: hingga 4 bit 0
  const kapasitasBit = spek.dataCW * 8
  const panjangTerminator = Math.min(4, kapasitasBit - bitArray.length)
  tambahBit(0, panjangTerminator)

  // Padding hingga batas byte kelipatan 8
  while (bitArray.length % 8 !== 0) {
    bitArray.push(0)
  }

  // Bentuk codeword awal
  const codewordAwal: number[] = []
  for (let i = 0; i < bitArray.length; i += 8) {
    let nilai = 0
    for (let j = 0; j < 8; j++) {
      nilai = (nilai << 1) | bitArray[i + j]
    }
    codewordAwal.push(nilai)
  }

  // Codeword pelengkap (pad bytes 0xEC dan 0x11 bergantian)
  let selangSeling = false
  while (codewordAwal.length < spek.dataCW) {
    codewordAwal.push(selangSeling ? 0x11 : 0xec)
    selangSeling = !selangSeling
  }

  // Pecah ke dalam blok-blok
  const blokDaftar: { data: number[]; ec: number[] }[] = []
  let offset = 0
  for (const b of spek.blocks) {
    for (let i = 0; i < b.count; i++) {
      const dataBlok = codewordAwal.slice(offset, offset + b.data)
      offset += b.data
      const ecBlok = hitungCodewordsEc(dataBlok, spek.ecCW)
      blokDaftar.push({ data: dataBlok, ec: ecBlok })
    }
  }

  // Penjalinan (interleaving) data
  const hasilCodewords: number[] = []
  const maxLenData = Math.max(...blokDaftar.map((b) => b.data.length))
  for (let i = 0; i < maxLenData; i++) {
    for (const b of blokDaftar) {
      if (i < b.data.length) hasilCodewords.push(b.data[i])
    }
  }

  // Penjalinan (interleaving) error correction
  for (let i = 0; i < spek.ecCW; i++) {
    for (const b of blokDaftar) {
      hasilCodewords.push(b.ec[i])
    }
  }

  return hasilCodewords
}

/**
 * Buat matriks 2D boolean untuk QR Code (true = modul gelap, false = modul terang).
 */
export function buatQrMatriks(teks: string): boolean[][] {
  const byteData = new TextEncoder().encode(teks)
  const spek = TABEL_M.find((t) => byteData.length <= t.dataCW - (t.v < 10 ? 2 : 3))
  if (!spek) {
    throw new Error(
      `Teks terlalu panjang untuk kapasitas QR Code maksimal (${byteData.length} byte).`,
    )
  }

  const codewords = enkodeData(teks, spek)
  const N = spek.size
  const matriks: (boolean | null)[][] = Array.from({ length: N }, () => new Array(N).fill(null))
  const dilindungi: boolean[][] = Array.from({ length: N }, () => new Array(N).fill(false))

  // Pasang Finder Pattern 7x7 beserta pemisah 1 modul
  function pasangFinder(barisAwal: number, kolomAwal: number) {
    for (let r = -1; r <= 7; r++) {
      for (let c = -1; c <= 7; c++) {
        const nr = barisAwal + r
        const nc = kolomAwal + c
        if (nr >= 0 && nr < N && nc >= 0 && nc < N) {
          dilindungi[nr][nc] = true
          if (r >= 0 && r <= 6 && c >= 0 && c <= 6) {
            matriks[nr][nc] =
              r === 0 || r === 6 || c === 0 || c === 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4)
          } else {
            matriks[nr][nc] = false
          }
        }
      }
    }
  }

  pasangFinder(0, 0)
  pasangFinder(0, N - 7)
  pasangFinder(N - 7, 0)

  // Pola pewaktu (timing pattern) baris 6 dan kolom 6
  for (let i = 8; i < N - 8; i++) {
    if (!dilindungi[6][i]) {
      dilindungi[6][i] = true
      matriks[6][i] = i % 2 === 0
    }
    if (!dilindungi[i][6]) {
      dilindungi[i][6] = true
      matriks[i][6] = i % 2 === 0
    }
  }

  // Pola penyejajaran (alignment pattern) untuk versi 2 ke atas
  if (spek.align) {
    const kordinat = spek.align
    for (const r of kordinat) {
      for (const c of kordinat) {
        if (dilindungi[r][c]) continue
        for (let dr = -2; dr <= 2; dr++) {
          for (let dc = -2; dc <= 2; dc++) {
            dilindungi[r + dr][c + dc] = true
            matriks[r + dr][c + dc] =
              Math.abs(dr) === 2 || Math.abs(dc) === 2 || (dr === 0 && dc === 0)
          }
        }
      }
    }
  }

  // Modul gelap tetap pada (4 * v + 9, 8)
  const modulGelapR = 4 * spek.v + 9
  dilindungi[modulGelapR][8] = true
  matriks[modulGelapR][8] = true

  // Lindungi area informasi format (format information)
  for (let i = 0; i <= 8; i++) {
    if (!dilindungi[8][i]) dilindungi[8][i] = true
    if (!dilindungi[i][8]) dilindungi[i][8] = true
  }
  for (let i = N - 8; i < N; i++) {
    if (!dilindungi[8][i]) dilindungi[8][i] = true
    if (!dilindungi[i][8]) dilindungi[i][8] = true
  }

  // Ubah codeword menjadi deretan bit
  const semuaBit: number[] = []
  for (const cw of codewords) {
    for (let b = 7; b >= 0; b--) {
      semuaBit.push((cw >> b) & 1)
    }
  }

  // Isi data bit secara zig-zag
  let bitIdx = 0
  let keAtas = true
  for (let col = N - 1; col > 0; col -= 2) {
    if (col === 6) col-- // lewati kolom pewaktu
    const deretanBaris = keAtas
      ? Array.from({ length: N }, (_, i) => N - 1 - i)
      : Array.from({ length: N }, (_, i) => i)

    for (const r of deretanBaris) {
      for (const c of [col, col - 1]) {
        if (!dilindungi[r][c]) {
          const bit = bitIdx < semuaBit.length ? semuaBit[bitIdx++] : 0
          matriks[r][c] = bit === 1
        }
      }
    }
    keAtas = !keAtas
  }

  // Terapkan pola masker (Mask 0: (r + c) % 2 === 0)
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (!dilindungi[r][c]) {
        if ((r + c) % 2 === 0) {
          matriks[r][c] = !matriks[r][c]
        }
      }
    }
  }

  // Hitung dan tempatkan bit informasi format (Level M = 00, Mask 0 = 000)
  const fmt = (0 << 3) | 0
  const gPol = 0x537
  let rem = fmt << 10
  for (let i = 4; i >= 0; i--) {
    if ((rem >> (i + 10)) & 1) rem ^= gPol << i
  }
  const fmtBits = ((fmt << 10) | rem) ^ 0x5412

  const fmtArr: number[] = []
  for (let i = 14; i >= 0; i--) fmtArr.push((fmtBits >> i) & 1)

  const koordinatKiriAtas = [
    [8, 0],
    [8, 1],
    [8, 2],
    [8, 3],
    [8, 4],
    [8, 5],
    [8, 7],
    [8, 8],
    [7, 8],
    [5, 8],
    [4, 8],
    [3, 8],
    [2, 8],
    [1, 8],
    [0, 8],
  ]
  for (let i = 0; i < 15; i++) {
    matriks[koordinatKiriAtas[i][0]][koordinatKiriAtas[i][1]] = fmtArr[i] === 1
  }

  // Pecah penempatan pada pojok kanan-atas dan kiri-bawah
  for (let i = 0; i <= 6; i++) {
    matriks[N - 1 - i][8] = fmtArr[i] === 1
  }
  for (let i = 7; i < 15; i++) {
    matriks[8][N - 15 + i] = fmtArr[i] === 1
  }

  return matriks.map((baris) => baris.map((sel) => !!sel))
}

export interface OpsiQrSvg {
  ukuran?: number
  margin?: number
  warnaGelap?: string
  warnaTerang?: string
  judul?: string
}

/**
 * Buat string SVG siap render dari teks/URL.
 */
export function buatQrSvg(teks: string, opsi: OpsiQrSvg = {}): string {
  const matriks = buatQrMatriks(teks)
  const N = matriks.length
  const margin = opsi.margin ?? 2
  const ukuran = opsi.ukuran ?? 200
  const warnaGelap = opsi.warnaGelap ?? 'black'
  const warnaTerang = opsi.warnaTerang ?? 'white'
  const total = N + margin * 2

  let pathD = ''
  for (let r = 0; r < N; r++) {
    for (let c = 0; c < N; c++) {
      if (matriks[r][c]) {
        pathD += `M${c + margin},${r + margin}h1v1h-1z `
      }
    }
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${total} ${total}" width="${ukuran}" height="${ukuran}" role="img" aria-label="${opsi.judul || 'Kode QR'}">
  <rect width="100%" height="100%" fill="${warnaTerang}"/>
  <path d="${pathD.trim()}" fill="${warnaGelap}"/>
</svg>`
}
