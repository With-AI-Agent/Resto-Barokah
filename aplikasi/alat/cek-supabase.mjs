#!/usr/bin/env node
/**
 * cek-supabase.mjs — uji sambung ke proyek Supabase memakai KUNCI PUBLIK saja.
 *
 * Kenapa ada: tugas T0-08 meminta bukti "koneksi uji berhasil dari aplikasi". Uji ini sengaja
 * dijalankan sebagai alat (bukan bagian aplikasi) supaya bisa dipakai SEBELUM kode aplikasi
 * menyentuh Supabase, dan supaya tidak ada kunci rahasia yang perlu hadir.
 *
 * Yang diuji:
 *   1. VITE_SUPABASE_URL  — alamat proyek (boleh publik)
 *   2. VITE_SUPABASE_ANON_KEY — kunci publik `anon`/publishable (boleh publik; RLS yang menjaga data)
 *   3. Server menjawab dan MENERIMA kunci itu (kalau kunci salah → HTTP 401)
 *   4. TABEL KATALOG terbaca lewat kunci publik (bukti migrasi sudah disebar ke proyek nyata).
 *      Yang dibaca hanya SATU kolom dari maksimal SATU baris katalog yang memang publik di MVP ini
 *      (pelanggan harus bisa melihat menu). Contoh setara `select 1`: bila tabel belum ada, Supabase
 *      menjawab 404 dan alat ini GAGAL dengan pesan \"migrasi belum disebar\" — bukan lolos diam-diam.
 *
 * Sumber nilai (urut): argumen `--url`/`--kunci` → variabel lingkungan → berkas `aplikasi/.env`.
 * CI memakai variabel lingkungan (GitHub Actions), pengembang lokal memakai `aplikasi/.env`.
 *
 * Cara pakai (di folder `aplikasi/`):
 *   1. salin `.env.example` menjadi `.env`, isi dua nilai di atas
 *   2. jalankan:  npm run cek:supabase
 * atau, tanpa berkas .env:
 *   node alat/cek-supabase.mjs --url https://xxx.supabase.co --kunci sb_publishable_xxx
 *
 * Mode `--uji-diri`: menyalakan server tiruan di localhost, lalu membuktikan alat ini
 * MENOLAK pengaturan yang salah (kunci rahasia, alamat asing, kunci ditolak server 401) dan
 * MENERIMA yang benar. Diuji di CI karena tidak butuh jaringan luar.
 *
 * Kunci RAHASIA (service_role, Resend, Cloudflare) TIDAK dipakai di sini dan tidak boleh masuk
 * berkas .env aplikasi (aturan docs/TECH_SPEC.md §6).
 */
import { readFileSync } from 'node:fs'
import { createServer } from 'node:http'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')

/** Batas tunggu tiap percobaan jaringan (milidetik). */
export const BATAS_TUNGGU_MS = 15000

/** Bentuk alamat proyek Supabase yang sah. */
export const POLA_ALAMAT = /^https:\/\/[a-z0-9-]+\.supabase\.co$/i

/** Ciri kunci rahasia yang TIDAK boleh ada di berkas .env aplikasi. */
export const POLA_RAHASIA = /service_role|sb_secret_/i

/** Tabel katalog yang MEMANG publik di MVP (pelanggan melihat menu) — dipakai sebagai bukti skema. */
export const TABEL_KATALOG = 'menu_item'

export function bacaEnv(akar = AKAR) {
  const nilai = {}
  try {
    const isi = readFileSync(resolve(akar, '.env'), 'utf8')
    for (const baris of isi.split('\n')) {
      const m = baris.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/)
      if (m && !baris.trim().startsWith('#')) nilai[m[1]] = m[2].replace(/^["']|["']$/g, '')
    }
  } catch {
    /* berkas .env belum ada — boleh, nanti dilaporkan sebagai kurang */
  }
  return nilai
}

/**
 * Periksa pengaturan sebelum menyentuh jaringan.
 * `izinkanHostUji` hanya dipakai `--uji-diri` (server tiruan di 127.0.0.1).
 */
export function periksaPengaturan({ alamat, kunci, izinkanHostUji = false }) {
  const gagal = []
  if (!alamat) gagal.push('VITE_SUPABASE_URL belum diisi (aplikasi/.env)')
  if (!kunci) gagal.push('VITE_SUPABASE_ANON_KEY belum diisi (aplikasi/.env)')
  if (
    alamat &&
    !POLA_ALAMAT.test(alamat) &&
    !(izinkanHostUji && /^https?:\/\/127\.0\.0\.1:\d+$/.test(alamat))
  ) {
    gagal.push(`alamat tidak berbentuk https://<proyek>.supabase.co — sekarang: ${alamat}`)
  }
  if (kunci && POLA_RAHASIA.test(kunci)) {
    gagal.push('kunci yang diisi tampak KUNCI RAHASIA — jangan pakai service_role di aplikasi')
  }
  return gagal
}

async function panggil(alamat, kunci, jalur, fetchUji) {
  const url = `${alamat}${jalur}`
  const mulai = Date.now()
  try {
    const jawab = await fetchUji(url, {
      headers: { apikey: kunci, Authorization: `Bearer ${kunci}` },
      signal: AbortSignal.timeout(BATAS_TUNGGU_MS),
    })
    const teks = (await jawab.text()).slice(0, 200)
    return { url, status: jawab.status, ms: Date.now() - mulai, teks }
  } catch (e) {
    return { url, status: 0, ms: Date.now() - mulai, teks: String(e?.message ?? e) }
  }
}

/** Jalankan uji sambung; kembalikan hasilnya (tidak mencetak, tidak keluar proses). */
export async function ujiSambung({ alamat, kunci, fetchUji = fetch, cetak = console.log }) {
  cetak(`Menguji ${alamat} dengan kunci publik …\n`)
  const health = await panggil(alamat, kunci, '/auth/v1/health', fetchUji)
  const rest = await panggil(alamat, kunci, '/rest/v1/', fetchUji)
  const katalog = await panggil(alamat, kunci, `/rest/v1/${TABEL_KATALOG}?select=id&limit=1`, fetchUji)

  const healthOk = health.status === 200
  const katalogOk = katalog.status === 200 || katalog.status === 206
  const baris = [
    ['Kesehatan layanan Auth (bukti kunci diterima)', healthOk],
    [
      'Layanan data (PostgREST) menjawab',
      rest.status === 200 || rest.status === 401 || rest.status === 404,
    ],
    [`Tabel katalog (${TABEL_KATALOG}) terbaca — bukti migrasi sudah disebar`, katalogOk],
  ]
  for (const [nama, ok] of baris) cetak(`  ${ok ? 'OK ' : 'X  '} ${nama}`)
  cetak(
    `\n  rincian: /auth/v1/health → HTTP ${health.status} (${health.ms} ms) ${health.status === 200 ? '' : health.teks}`,
  )
  cetak(`           /rest/v1/       → HTTP ${rest.status} (${rest.ms} ms)`)
  cetak(
    `           /rest/v1/${TABEL_KATALOG} → HTTP ${katalog.status} (${katalog.ms} ms) ${katalogOk ? '' : katalog.teks}`,
  )

  if (!healthOk) {
    cetak(
      '\nHASIL: GAGAL — server tidak menerima alamat+kunci ini. Periksa URL & kunci publik di aplikasi/.env.',
    )
    cetak(
      '(Kalau kunci salah, Supabase menjawab 401. Kalau alamat salah, biasanya status 0 / DNS gagal.)',
    )
    return { ok: false, health, rest, katalog }
  }
  if (!katalogOk) {
    cetak('\nHASIL: GAGAL — alamat+kunci benar, tetapi tabel katalog tidak bisa dibaca:')
    if (katalog.status === 404) {
      cetak(
        '  → tabelnya BELUM ADA di proyek ini: 14 berkas migrasi belum disebar (butir T-020).',
      )
    } else if (katalog.status === 401 || katalog.status === 403) {
      cetak(
        '  → kunci publik tidak boleh membaca katalog: periksa hak tingkat tabel & RLS di migrasi 0007.',
      )
    } else {
      cetak('  → penyebab belum dikenali; lihat rincian status di atas.')
    }
    return { ok: false, health, rest, katalog }
  }
  cetak(
    '\nHASIL: LULUS — sambungan Supabase bekerja dengan kunci publik saja (tanpa kunci rahasia)',
  )
  cetak(
    `         dan tabel katalog terbaca (HTTP ${katalog.status}) — migrasi sudah disebar ke proyek nyata.`,
  )
  return { ok: true, health, rest, katalog }
}

/** Server tiruan Supabase untuk `--uji-diri` (menerima hanya kunci yang benar). */
async function serverTiruan(kunciBenar, { katalogAda = true } = {}) {
  const server = createServer((req, res) => {
    const kunci = req.headers.apikey ?? ''
    const jawab = (status, isi) => {
      res.writeHead(status, { 'content-type': 'application/json' })
      res.end(JSON.stringify(isi))
    }
    if (kunci !== kunciBenar) return jawab(401, { message: 'Invalid API key' })
    if (req.url?.startsWith('/auth/v1/health'))
      return jawab(200, { name: 'gotrue', version: 'uji' })
    if (req.url?.startsWith(`/rest/v1/${TABEL_KATALOG}`)) {
      // Dua keadaan nyata: tabel sudah disebar (200 + daftar kosong karena RLS) atau belum ada (404).
      if (!katalogAda)
        return jawab(404, {
          code: 'PGRST205',
          message: `Could not find the table 'public.${TABEL_KATALOG}' in the schema cache`,
        })
      return jawab(200, [])
    }
    if (req.url?.startsWith('/rest/v1/')) return jawab(200, { swagger: '2.0' })
    return jawab(404, { message: 'not found' })
  })
  await new Promise((lanjut) => server.listen(0, '127.0.0.1', lanjut))
  const { port } = server.address()
  return { alamat: `http://127.0.0.1:${port}`, tutup: () => new Promise((s) => server.close(s)) }
}

async function ujiDiri() {
  const kunci = 'sb_publishable_uji'
  const tiruan = await serverTiruan(kunci)
  const tiruanTanpaKatalog = await serverTiruan(kunci, { katalogAda: false })
  const diam = () => {}
  const kasus = []
  const jalankan = async (nama, opsi, harapOk) => {
    const gagal = periksaPengaturan({ ...opsi, izinkanHostUji: true })
    if (gagal.length) {
      // Ditolak sebelum menyentuh jaringan: BENAR justru kalau memang diharapkan gagal.
      kasus.push([nama, !harapOk, `ditolak sebelum jaringan: ${gagal[0]}`])
      return
    }
    const hasil = await ujiSambung({ ...opsi, cetak: diam })
    kasus.push([nama, hasil.ok === harapOk, `ok=${hasil.ok} (harap ${harapOk})`])
  }
  try {
    await jalankan('pengaturan benar diterima', { alamat: tiruan.alamat, kunci }, true)
    await jalankan(
      'kunci salah ditolak server',
      { alamat: tiruan.alamat, kunci: 'sb_publishable_salah' },
      false,
    )
    await jalankan(
      'kunci rahasia service_role ditolak',
      { alamat: tiruan.alamat, kunci: 'service_role_rahasia' },
      false,
    )
    await jalankan('alamat asing ditolak', { alamat: 'https://contoh.example.com', kunci }, false)
    await jalankan('alamat kosong ditolak', { alamat: '', kunci }, false)
    // Bukti terpenting sejak 2026-09-19: kalau tabel katalog BELUM ada di proyek (migrasi belum
    // disebar), alat ini WAJIB gagal — bukan melaporkan LULUS hanya karena jaringan hidup.
    await jalankan(
      'tabel katalog belum disebar ditolak (bukan lolos diam-diam)',
      { alamat: tiruanTanpaKatalog.alamat, kunci },
      false,
    )
  } finally {
    await tiruan.tutup()
    await tiruanTanpaKatalog.tutup()
  }
  let merah = 0
  for (const [nama, lulus, catatan] of kasus) {
    if (!lulus) merah++
    console.log(`  ${lulus ? 'OK ' : 'X  '} ${nama} — ${catatan}`)
  }
  console.log(`\nUJI DIRI: ${kasus.length - merah}/${kasus.length} ${merah ? 'GAGAL' : 'LOLOS'}`)
  return merah === 0
}

function argumen(nama) {
  const i = process.argv.indexOf(nama)
  return i >= 0 ? (process.argv[i + 1] ?? '') : ''
}

async function utama() {
  if (process.argv.includes('--uji-diri')) {
    process.exit((await ujiDiri()) ? 0 : 1)
  }
  const env = bacaEnv()
  // Urutan sumber nilai: argumen → variabel lingkungan (dipakai CI) → berkas aplikasi/.env (lokal).
  const alamat = (argumen('--url') || process.env.VITE_SUPABASE_URL || env.VITE_SUPABASE_URL || '')
    .trim()
    .replace(/\/+$/, '')
  const kunci = (
    argumen('--kunci') ||
    process.env.VITE_SUPABASE_ANON_KEY ||
    env.VITE_SUPABASE_ANON_KEY ||
    ''
  ).trim()

  const gagal = periksaPengaturan({ alamat, kunci })
  if (gagal.length) {
    console.log('GAGAL — pengaturan belum siap:')
    for (const g of gagal) console.log(`  - ${g}`)
    process.exit(1)
  }
  const hasil = await ujiSambung({ alamat, kunci })
  process.exit(hasil.ok ? 0 : 1)
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await utama()
}
