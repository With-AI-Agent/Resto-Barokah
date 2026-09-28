#!/usr/bin/env node
/**
 * uji-edge-akhiri-sesi.mjs — menguji BATAS Edge Function `akhiri_sesi` TANPA jaringan.
 *
 * Menguji perilaku handler:
 *   1. Penolakan body null/array/GET.
 *   2. Penolakan tanpa header Authorization (401).
 *   3. Penolakan UUID tidak valid (400).
 *   4. Rute p_session_id ke RPC `akhiri_sesi`.
 *   5. Rute semua: true ke RPC `keluar_semua_perangkat`.
 *   6. Rute hilang: true ke RPC `tandai_perangkat_hilang`.
 *   7. Penanganan gagal jaringan & upstream bukan JSON terkendali (tidak melempar).
 *   8. Pembatasan CORS asal yang diizinkan.
 */
import { readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import vm from 'node:vm'
import { createRequire } from 'node:module'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const BERKAS = join(AKAR, 'supabase', 'functions', 'akhiri_sesi', 'index.ts')

let esbuild
try {
  esbuild = createRequire(join(AKAR, 'alat', 'package.json'))('esbuild')
} catch {
  try {
    esbuild = createRequire(join(AKAR, 'aplikasi', 'package.json'))('esbuild')
  } catch {
    console.log('GAGAL: esbuild tidak ditemukan.')
    process.exit(2)
  }
}

const sumber = readFileSync(BERKAS, 'utf8')
const code = esbuild.transformSync(sumber, {
  loader: 'ts',
  format: 'cjs',
  target: 'es2022',
}).code

const PENGGUNA_UJI = '90000000-0000-0000-0000-000000000004'
const PERANGKAT_UJI = 'de000000-0000-0000-0000-000000000003'
const SESI_UJI = 'sess_kasir_01'

async function jalankan({ method = 'POST', isi, tanpaToken = false, fetchTiruan, origin } = {}) {
  const panggilan = []
  const penangan = []
  const Deno = {
    serve: (fn) => penangan.push(fn),
    env: {
      get: (k) =>
        ({
          SUPABASE_URL: 'https://uji.invalid',
          SUPABASE_ANON_KEY: 'sb_publishable_uji',
        })[k],
    },
  }
  const fetchUji = async (url, opsi) => {
    panggilan.push({ url: String(url), opsi })
    if (fetchTiruan) return fetchTiruan(String(url), opsi)
    return new Response(
      JSON.stringify({
        berhasil: true,
        kode: 'BERHASIL',
        pesan: 'Aksi berhasil diproses.',
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      },
    )
  }

  const modulTiruan = { exports: {} }
  const konteks = vm.createContext({
    Deno,
    fetch: fetchUji,
    console,
    Response,
    Request,
    Array,
    Object,
    JSON,
    String,
    Number,
    RegExp,
    TypeError,
    URL,
    module: modulTiruan,
    exports: modulTiruan.exports,
  })

  let melempar = null
  try {
    vm.runInContext(code, konteks, { filename: BERKAS })
  } catch (e) {
    melempar = e
  }

  const handler = modulTiruan.exports?.default || penangan[0]

  const opsi = { method, headers: {} }
  if (!tanpaToken) opsi.headers.Authorization = 'Bearer token-uji'
  if (origin) opsi.headers.Origin = origin
  if (isi !== undefined) {
    opsi.headers['Content-Type'] = 'application/json'
    opsi.body = typeof isi === 'string' ? isi : JSON.stringify(isi)
  }

  let jawab = null
  if (!melempar && handler) {
    try {
      jawab = await handler(new Request('https://fungsi.invalid/akhiri_sesi', opsi))
    } catch (e) {
      melempar = e
    }
  }
  const badan = jawab ? await jawab.text() : ''
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

// 1. JSON null -> 400
{
  const r = await jalankan({ isi: 'null' })
  catat('S01 body JSON null → 400 terkendali', r.jawab?.status === 400, `status=${r.jawab?.status}`)
}

// 2. JSON array -> 400
{
  const r = await jalankan({ isi: '[]' })
  catat('S02 body array → 400 terkendali', r.jawab?.status === 400, `status=${r.jawab?.status}`)
}

// 3. Tanpa token Authorization -> 401
{
  const r = await jalankan({ isi: { session_id: SESI_UJI }, tanpaToken: true })
  catat('S03 tanpa token Authorization → 401', r.jawab?.status === 401 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 4. Method GET -> 405
{
  const r = await jalankan({ method: 'GET' })
  catat('S04 method selain POST → 405', r.jawab?.status === 405, `status=${r.jawab?.status}`)
}

// 5. Format UUID pengguna salah -> 400
{
  const r = await jalankan({ isi: { pengguna_id: 'bukan-uuid-sah', semua: true } })
  catat('S05 pengguna_id bukan UUID → 400', r.jawab?.status === 400 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 6. Format UUID perangkat salah -> 400
{
  const r = await jalankan({ isi: { perangkat_id: '12345', hilang: true } })
  catat('S06 perangkat_id bukan UUID → 400', r.jawab?.status === 400 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 7. Sesi tunggal -> diteruskan ke RPC akhiri_sesi
{
  const r = await jalankan({ isi: { session_id: SESI_UJI, alasan: 'Manual logout' } })
  const d = bacaJSON(r.badan)
  const panggil = r.panggilan[0]
  const rpcUrl = panggil?.url ?? ''
  const payload = JSON.parse(panggil?.opsi?.body ?? '{}')
  catat(
    'S07 session_id diarahkan ke RPC akhiri_sesi',
    r.jawab?.status === 200 && rpcUrl.includes('/rpc/akhiri_sesi') && payload.p_session_id === SESI_UJI,
    `status=${r.jawab?.status} url=${rpcUrl} p_session_id=${payload.p_session_id}`,
  )
}

// 8. Keluar semua perangkat -> diarahkan ke RPC keluar_semua_perangkat
{
  const r = await jalankan({ isi: { pengguna_id: PENGGUNA_UJI, semua: true, alasan: 'Ganti password' } })
  const panggil = r.panggilan[0]
  const rpcUrl = panggil?.url ?? ''
  const payload = JSON.parse(panggil?.opsi?.body ?? '{}')
  catat(
    'S08 semua=true diarahkan ke RPC keluar_semua_perangkat',
    r.jawab?.status === 200 && rpcUrl.includes('/rpc/keluar_semua_perangkat') && payload.p_pengguna_id === PENGGUNA_UJI,
    `status=${r.jawab?.status} url=${rpcUrl} p_pengguna_id=${payload.p_pengguna_id}`,
  )
}

// 9. Tandai hilang -> diarahkan ke RPC tandai_perangkat_hilang
{
  const r = await jalankan({ isi: { perangkat_id: PERANGKAT_UJI, hilang: true, alasan: 'Tablet dicuri' } })
  const panggil = r.panggilan[0]
  const rpcUrl = panggil?.url ?? ''
  const payload = JSON.parse(panggil?.opsi?.body ?? '{}')
  catat(
    'S09 hilang=true diarahkan ke RPC tandai_perangkat_hilang',
    r.jawab?.status === 200 && rpcUrl.includes('/rpc/tandai_perangkat_hilang') && payload.p_perangkat_id === PERANGKAT_UJI,
    `status=${r.jawab?.status} url=${rpcUrl} p_perangkat_id=${payload.p_perangkat_id}`,
  )
}

// 10. Upstream fetch gagal jaringan -> jawaban gagal terkendali 502
{
  const r = await jalankan({
    isi: { session_id: SESI_UJI },
    fetchTiruan: () => {
      throw new TypeError('network error')
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'S10 upstream jaringan error → jawaban terkendali 502',
    r.melempar === null && r.jawab?.status === 502 && d?.berhasil === false,
    `melempar=${r.melempar?.message ?? 'tidak'} status=${r.jawab?.status}`,
  )
}

// 11. CORS: origin sah mendapat header reflektif
{
  const asal = 'http://localhost:5173'
  const r = await jalankan({
    isi: { session_id: SESI_UJI },
    origin: asal,
  })
  catat(
    'S11 origin sah → CORS memantulkan origin',
    r.jawab?.headers.get('access-control-allow-origin') === asal,
    `acao=${r.jawab?.headers.get('access-control-allow-origin')}`,
  )
}

// 12. Preflight OPTIONS dari origin sah -> 204
{
  const asal = 'http://localhost:5173'
  const r = await jalankan({ method: 'OPTIONS', origin: asal })
  catat(
    'S12 preflight OPTIONS → 204',
    r.jawab?.status === 204 && r.jawab?.headers.get('access-control-allow-origin') === asal,
    `status=${r.jawab?.status}`,
  )
}

const gagal = hasil.filter((h) => !h.lulus)
console.log('UJI BATAS EDGE — akhiri_sesi (berkas asli dijalankan di VM, tanpa jaringan)')
for (const h of hasil) {
  console.log(`  ${h.lulus ? 'LOLOS' : 'GAGAL'}  ${h.nama}  [${h.catatan}]`)
}
console.log(`\nRINGKASAN: ${hasil.length - gagal.length} lolos, ${gagal.length} gagal`)
process.exit(gagal.length > 0 ? 1 : 0)
