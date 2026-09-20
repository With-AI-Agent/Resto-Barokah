#!/usr/bin/env node
/**
 * uji-edge-pin.mjs — menguji BATAS (boundary) Edge Function `verifikasi_pin` TANPA jaringan.
 *
 * Kenapa ada (temuan audit I F-07, K-3, 2026-09-19): handler aslinya gagal di luar kontrak —
 * permintaan JSON `null` melempar TypeError (bukan 400), galat jaringan pada `fetch` melempar
 * Error, dan jawaban upstream yang bukan JSON melempar SyntaxError. Semuanya membuat kasir
 * melihat kegagalan tak terkendali, bukan pesan seperti jalur lainnya. Sebelum berkas ini ada,
 * tidak ada satu pun pengujian yang MENJALANKAN handler itu: perubahan pada berkas Edge hanya
 * dijaga pemeriksa TEKS (`alat/periksa-fungsi-pin.py`), bukan perilaku.
 *
 * Cara kerja (jujur, bukan tiruan yang menipu):
 *   1. Berkas ASLI `supabase/functions/verifikasi_pin/index.ts` diubah bentuknya (TS → JS) memakai
 *      `esbuild` — bukan ditulis ulang tangan, jadi yang diuji benar-benar kode yang dikirim.
 *   2. Hasilnya dijalankan di `node:vm` dengan `Deno.serve`/`Deno.env` tiruan dan `fetch` yang
 *      dikendalikan. `Response`/`Request` memakai milik Node (undici) — sama seperti Deno.
 *   3. Setiap kasus memeriksa status + isi jawaban; satu kasus khusus memastikan **PIN tidak pernah
 *      muncul** di jawaban mana pun (lapisan kedua selain pemeriksa teks).
 *
 * Jalankan:  node alat/uji-edge-pin.mjs
 * Keluar 2 bila alat bantunya (esbuild) belum dipasang: jalankan `npm ci --prefix alat`.
 */
import { readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import vm from 'node:vm'
import { createRequire } from 'node:module'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const BERKAS = join(AKAR, 'supabase', 'functions', 'verifikasi_pin', 'index.ts')

let esbuild
try {
  esbuild = createRequire(join(AKAR, 'alat', 'package.json'))('esbuild')
} catch {
  try {
    esbuild = createRequire(join(AKAR, 'aplikasi', 'package.json'))('esbuild')
  } catch {
    console.log('GAGAL: esbuild tidak ditemukan — tidak bisa mengubah TS → JS dengan jujur.')
    console.log('       Jalankan dulu: npm ci --prefix alat   (±3 detik)')
    process.exit(2)
  }
}

const sumber = readFileSync(BERKAS, 'utf8')
const { code } = esbuild.transformSync(sumber, { loader: 'ts', format: 'cjs', target: 'es2022' })

const PIN_UJI = '654321'
const UUID_UJI = 'e2000000-0000-4000-8000-000000000003'
const semuaJawaban = []

/** Jalankan handler dengan `fetch` yang dikendalikan; kembalikan jawaban + catatan panggilan. */
async function jalankan({ method = 'POST', isi, tanpaToken = false, fetchTiruan } = {}) {
  const panggilan = []
  const penangan = []
  const Deno = {
    serve: (fn) => penangan.push(fn),
    env: { get: (k) => ({ SUPABASE_URL: 'https://uji.invalid', SUPABASE_ANON_KEY: 'sb_publishable_uji' })[k] },
  }
  const fetchUji = async (url, opsi) => {
    panggilan.push({ url: String(url), opsi })
    if (fetchTiruan) return fetchTiruan(String(url), opsi)
    return new Response(JSON.stringify([{ berhasil: true, sisa_percobaan: 5, pesan: 'ok' }]), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    })
  }
  const konteks = vm.createContext({
    Deno, fetch: fetchUji, Response, Request, Array, Object, JSON, String, Number, RegExp,
    TypeError, URL, module: { exports: {} }, exports: {},
  })

  let melempar = null
  try {
    vm.runInContext(code, konteks, { filename: BERKAS })
  } catch (e) {
    melempar = e
  }

  const opsi = { method, headers: {} }
  if (!tanpaToken) opsi.headers.Authorization = 'Bearer token-uji'
  if (isi !== undefined) {
    opsi.headers['Content-Type'] = 'application/json'
    opsi.body = typeof isi === 'string' ? isi : JSON.stringify(isi)
  }
  let jawab = null
  if (!melempar) {
    try {
      jawab = await penangan[0](new Request('https://fungsi.invalid/verifikasi_pin', opsi))
    } catch (e) {
      melempar = e
    }
  }
  const badan = jawab ? await jawab.text() : ''
  semuaJawaban.push(badan)
  return { jawab, badan, melempar, panggilan }
}

const hasil = []
const catat = (nama, lulus, catatan) => hasil.push({ nama, lulus, catatan })

function bacaJSON(badan) {
  try {
    return JSON.parse(badan)
  } catch {
    return null
  }
}

// E01 — JSON `null` harus dijawab 400 terkendali (dulu: TypeError → 500 platform).
{
  const r = await jalankan({ isi: 'null' })
  catat('E01 body JSON null → 400 terkendali (bukan TypeError)',
    r.melempar === null && r.jawab?.status === 400,
    `status=${r.jawab?.status} melempar=${r.melempar?.message ?? 'tidak'} body=${r.badan.slice(0, 70)}`)
}
// E02 — badan berisi array (bukan objek) → 400.
{
  const r = await jalankan({ isi: '[]' })
  catat('E02 body array → 400 terkendali',
    r.melempar === null && r.jawab?.status === 400, `status=${r.jawab?.status} melempar=${r.melempar?.message ?? 'tidak'}`)
}
// E03 — tanpa token → 401 sebelum fetch.
{
  const r = await jalankan({ isi: { pengguna_id: UUID_UJI, pin: PIN_UJI }, tanpaToken: true })
  catat('E03 tanpa Authorization → 401 tanpa memanggil upstream',
    r.jawab?.status === 401 && r.panggilan.length === 0, `status=${r.jawab?.status} fetch=${r.panggilan.length}`)
}
// E04 — metode GET → 405.
{
  const r = await jalankan({ method: 'GET' })
  catat('E04 metode selain POST → 405', r.jawab?.status === 405, `status=${r.jawab?.status}`)
}
// E05 — UUID "36 tanda minus" harus DITOLAK sebelum fetch (dulu lolos karena regex longgar).
{
  const r = await jalankan({ isi: { pengguna_id: '-'.repeat(36), pin: PIN_UJI } })
  catat('E05 UUID 36 tanda minus → 400 SEBELUM fetch',
    r.jawab?.status === 400 && r.panggilan.length === 0, `status=${r.jawab?.status} fetch=${r.panggilan.length}`)
}
// E06 — PIN bukan 6 angka → 400, dan nilainya tidak diulang di jawaban.
{
  const r = await jalankan({ isi: { pengguna_id: UUID_UJI, pin: 'PIN-RAHASIA' } })
  catat('E06 PIN salah bentuk → 400 tanpa mengulang nilainya',
    r.jawab?.status === 400 && !r.badan.includes('PIN-RAHASIA'), `status=${r.jawab?.status} bocor=${r.badan.includes('PIN-RAHASIA')}`)
}
// E07 — jaringan putus (fetch menolak) → jawaban gagal terkendali, TIDAK melempar.
{
  const r = await jalankan({
    isi: { pengguna_id: UUID_UJI, pin: PIN_UJI },
    fetchTiruan: () => { throw new TypeError('network error') },
  })
  const d = bacaJSON(r.badan)
  catat('E07 fetch menolak (jaringan putus) → jawaban gagal terkendali',
    r.melempar === null && d?.berhasil === false, `melempar=${r.melempar?.message ?? 'tidak'} body=${r.badan.slice(0, 80)}`)
}
// E08 — upstream menjawab bukan JSON → jawaban gagal terkendali, TIDAK melempar.
{
  const r = await jalankan({
    isi: { pengguna_id: UUID_UJI, pin: PIN_UJI },
    fetchTiruan: () => new Response('<html>gateway error</html>', { status: 200, headers: { 'Content-Type': 'text/html' } }),
  })
  const d = bacaJSON(r.badan)
  catat('E08 upstream bukan JSON → jawaban gagal terkendali',
    r.melempar === null && d?.berhasil === false, `melempar=${r.melempar?.message ?? 'tidak'} body=${r.badan.slice(0, 80)}`)
}
// E09 — upstream 500 → jawaban gagal terkendali (jalur lama, dijaga agar tidak mundur).
{
  const r = await jalankan({
    isi: { pengguna_id: UUID_UJI, pin: PIN_UJI },
    fetchTiruan: () => new Response('boom', { status: 500 }),
  })
  const d = bacaJSON(r.badan)
  catat('E09 upstream 500 → jawaban gagal terkendali', r.melempar === null && d?.berhasil === false, `body=${r.badan.slice(0, 70)}`)
}
// E10 — jalur sukses: 4 kunci diteruskan ke RPC (termasuk p_pin), jawaban bersih dari PIN.
{
  const r = await jalankan({ isi: { pengguna_id: UUID_UJI, pin: PIN_UJI, aksi: 'void', perangkat: 'kasir-1' } })
  const kirim = r.panggilan[0]?.opsi?.body ?? ''
  const punyaKunci = ['p_pengguna_id', 'p_pin', 'p_aksi', 'p_perangkat'].every((k) => kirim.includes(k))
  const d = bacaJSON(r.badan)
  catat('E10 jalur sukses: 4 argumen ke RPC + PIN tidak ada di jawaban/URL',
    d?.berhasil === true && punyaKunci, `berhasil=${d?.berhasil} kunci=${punyaKunci}`)
}
// E11 — penjaga menyeluruh: TIDAK ADA jawaban mana pun yang memuat PIN.
{
  const bocor = semuaJawaban.filter((b) => b.includes(PIN_UJI) || b.includes('PIN-RAHASIA'))
  catat('E11 tak ada jawaban mana pun yang memuat PIN',
    bocor.length === 0, bocor.length === 0 ? `${semuaJawaban.length} jawaban bersih` : `${bocor.length} jawaban bocor`)
}

const gagal = hasil.filter((h) => !h.lulus)
console.log('UJI BATAS EDGE — verifikasi_pin (berkas asli dijalankan di VM, tanpa jaringan)')
for (const h of hasil) {
  console.log(`  ${h.lulus ? 'LOLOS' : 'GAGAL'}  ${h.nama}  [${h.catatan}]`)
}
console.log(`\nRINGKASAN: ${hasil.length - gagal.length} lolos, ${gagal.length} gagal`)
process.exit(gagal.length > 0 ? 1 : 0)
