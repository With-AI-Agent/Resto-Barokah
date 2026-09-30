#!/usr/bin/env node
/**
 * ALAT EKSEKUSI PERINGATAN BATAS K6 (PMB1-F-076 · kartu B-F-05)
 *
 * Kenapa ada: janji TECH_SPEC §10 (baris 417) & keputusan K6 (baris 465) — peringatan
 * otomatis 70% & 90% — sampai 2026-09-30 tanpa PEMANGGIL sama sekali: Edge Function
 * `peringatan_batas` hanya bisa dipanggil manual; `alat/pantau_batas.py` bahkan mengklaim
 * "terpasang via Edge Function dan alur kerja CI harian" padahal 0 dari 5 workflow
 * memanggilnya (temuan PMB1-F-076, hakim H-F-05).
 *
 * Apa yang dilakukan alat ini (dipanggil `.github/workflows/denyut-harian.yml`
 * setiap hari 02:00 WIB, setelah denyut, pembersih, dan ringkasan harian):
 *   1. POST ke Edge Function `peringatan_batas` (service role).
 *   2. Membaca status kapasitas (WASPADA 70% / BAHAYA 90%) dan mencatatnya apa adanya.
 *   3. Jujur: jawaban tidak ok / berhasil=false → keluar kode 1 (CI merah), bukan ditelan.
 *
 * Pemakaian:
 *   node alat/eksekusi-peringatan-batas.mjs             # periksa (butuh SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY)
 *   node alat/eksekusi-peringatan-batas.mjs --uji-diri  # uji-diri tanpa jaringan
 *
 * Batas jujur: (1) efektif di produksi hanya setelah workflow `denyut-harian` dijalankan
 * di GitHub oleh Lee dan Edge `peringatan_batas` ter-deploy — kalau belum, pelaporan
 * gagalnya TERLIHAT (tidak ada sukses palsu); (2) Edge `peringatan_batas` saat ini masih
 * memakai angka ESTIMASI pemakaian (lihat komentar Edge) — pemantauan metrik nyata
 * (Management API / pg_database_size) adalah pekerjaan lanjutan yang terpisah.
 */
const args = process.argv.slice(2)

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY

function akhirUrl(u) {
  return String(u || '').replace(/\/+$/, '')
}

/** Satu panggilan POST ke Edge Function peringatan_batas. */
async function periksaBatas(alamat, kunci) {
  const url = `${akhirUrl(alamat)}/functions/v1/peringatan_batas`
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      apikey: kunci,
      Authorization: `Bearer ${kunci}`,
      'Content-Type': 'application/json',
    },
    body: '{}',
  })
  const teks = await res.text()
  let isi = null
  try {
    isi = JSON.parse(teks)
  } catch {
    isi = null
  }
  return { status: res.status, isi, teks }
}

function gagalUji(pesan) {
  console.error(`  [X] ${pesan}`)
  process.exitCode = 1
}

function ok(pesan) {
  console.log(`  OK    ${pesan}`)
}

async function ujiDiri() {
  console.log('UJI DIRI eksekusi-peringatan-batas')

  // Kasus 1: tanpa rahasia → ditolak fail-closed (tidak ada sukses palsu)
  {
    const simpanError = console.error
    console.error = () => {}
    let kode
    try {
      kode = await utama({ tanpaRahasia: true })
    } finally {
      console.error = simpanError
    }
    if (kode !== 1) {
      gagalUji('kasus 1: tanpa rahasia harusnya ditolak (kode 1)')
      return
    }
    ok('kasus 1: tanpa rahasia → ditolak fail-closed')
  }

  // Kasus 2: URL Edge & kepala panggilan sesuai kontrak (apikey + Bearer + POST ke functions/v1)
  const tangkap = []
  const asliFetch = globalThis.fetch
  globalThis.fetch = async (url, opsi) => {
    tangkap.push({ url, opsi })
    return new Response(
      JSON.stringify({
        berhasil: true,
        butuh_peringatan_70: false,
        butuh_peringatan_90: false,
        email_terkirim: false,
        catatan: 'Kondisi kapasitas prima dan aman dalam batas gratis (Rp 0/bulan).',
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  }
  try {
    process.env.SUPABASE_URL = 'https://contoh.supabase.co/'
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'kunci-uji'
    const kode = await utama()
    if (kode !== 0) {
      gagalUji('kasus 2: panggilan yang sah harusnya lulus (kode 0)')
      return
    }
  } finally {
    globalThis.fetch = asliFetch
    delete process.env.SUPABASE_SERVICE_ROLE_KEY
  }
  const panggilan = tangkap[0]
  if (!panggilan || panggilan.url !== 'https://contoh.supabase.co/functions/v1/peringatan_batas') {
    gagalUji(`kasus 2: URL Edge salah — ${panggilan && panggilan.url}`)
    return
  }
  if (
    !panggilan.opsi ||
    panggilan.opsi.method !== 'POST' ||
    panggilan.opsi.headers.apikey !== 'kunci-uji' ||
    panggilan.opsi.headers.Authorization !== 'Bearer kunci-uji'
  ) {
    gagalUji('kasus 2: metode/kepala (apikey, Bearer) tidak sesuai kontrak')
    return
  }
  ok('kasus 2: URL Edge & kepala panggilan (apikey, Bearer, POST) sesuai kontrak')

  // Kasus 3: akhirUrl memangkas garis miring
  if (akhirUrl('https://contoh.supabase.co///') !== 'https://contoh.supabase.co') {
    gagalUji('kasus 3: akhirUrl harus memangkas garis miring')
    return
  }
  ok('kasus 3: akhirUrl memangkas garis miring')

  console.log('UJI DIRI eksekusi-peringatan-batas SELESAI — LOLOS')
}

async function utama({ tanpaRahasia = false } = {}) {
  // Baca env saat dipanggil (bukan saat modul dimuat) supaya uji-diri bisa memasang rahasia palsu.
  const alamat = tanpaRahasia ? '' : (supabaseUrl ?? process.env.SUPABASE_URL)
  const kunci = tanpaRahasia
    ? ''
    : (supabaseKey ?? process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_KEY)
  if (!alamat || !kunci) {
    console.error(
      'PERINGATAN_BATAS DIBATALKAN: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY belum terpasang — ' +
        'periksa kapasitas TIDAK dijalankan (fail-closed, tanpa sukses palsu).',
    )
    return 1
  }
  console.log(`Memeriksa batas kapasitas K6 via Edge peringatan_batas di ${akhirUrl(alamat)} …`)
  const hasil = await periksaBatas(alamat, kunci)
  if (hasil.status !== 200 || !hasil.isi || hasil.isi.berhasil !== true) {
    console.error(
      `  [X] Edge peringatan_batas menjawab tidak ok (HTTP ${hasil.status}). Potongan jawaban:\n${String(hasil.teks).slice(0, 600)}`,
    )
    return 1
  }
  const isi = hasil.isi
  console.log(`  OK    status: ${isi.catatan}`)
  console.log(
    `  OK    waspada 70%: ${isi.butuh_peringatan_70 ? 'YA' : 'tidak'} · bahaya 90%: ${isi.butuh_peringatan_90 ? 'YA' : 'tidak'} · email terkirim: ${isi.email_terkirim ? 'YA' : 'tidak'}`,
  )
  // 90% = darurat → CI merah supaya tidak mengalir tanpa perhatian; 70% cukup dicatat.
  if (isi.butuh_peringatan_90 === true) {
    console.error('  [X] KAPASITAS ≥ 90% (BAHAYA) — segera naik kelas/rapikan penyimpanan.')
    return 1
  }
  console.log('PERINGATAN_BATAS SELESAI — laporan status kapasitas tercatat.')
  return 0
}

if (args.includes('--uji-diri')) {
  ujiDiri().catch((e) => {
    console.error(e)
    process.exit(1)
  })
} else {
  utama()
    .then((kode) => process.exit(kode))
    .catch((e) => {
      console.error(e)
      process.exit(1)
    })
}
