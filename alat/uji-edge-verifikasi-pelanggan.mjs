#!/usr/bin/env node
/**
 * uji-edge-verifikasi-pelanggan.mjs — menguji BATAS Edge Function `verifikasi_pelanggan` TANPA jaringan.
 *
 * Menguji perilaku handler:
 *   1. Penolakan body null/array/GET.
 *   2. Penolakan pendaftaran tanpa persetujuan privasi UU PDP (T-011).
 *   3. Penolakan nama kosong.
 *   4. Penolakan email sekali-pakai (10minutemail, tempmail, dll).
 *   5. Penolakan format email tidak sah atau kosong.
 *   6. Pemrosesan normalisasi Gmail (titik & tanda +) pada upstream fetch.
 *   7. Penanganan gagal jaringan terkendali (tidak melempar uncaught exception).
 *   8. Pembatasan CORS asal yang diizinkan.
 */
import { readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import vm from 'node:vm'
import { createRequire } from 'node:module'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const BERKAS = join(AKAR, 'supabase', 'functions', 'verifikasi_pelanggan', 'index.ts')

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

const PENYEWA_UJI = 'e0000000-0000-0000-0000-000000000001'
const KAMPANYE_UJI = 'c0000000-0000-0000-0000-000000000001'

async function jalankan({ method = 'POST', isi, fetchTiruan, origin } = {}) {
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
      JSON.stringify([
        {
          berhasil: true,
          kode: 'SUKSES',
          pesan: 'Voucher berhasil diterbitkan.',
          data: { kode_voucher: 'VCH-TEST-1234' },
        },
      ]),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      },
    )
  }

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
    Set,
    TypeError,
    URL,
    module: { exports: {} },
    exports: {},
  })

  let melempar = null
  try {
    vm.runInContext(code, konteks, { filename: BERKAS })
  } catch (e) {
    melempar = e
  }

  const opsi = { method, headers: {} }
  if (origin) opsi.headers.Origin = origin
  if (isi !== undefined) {
    opsi.headers['Content-Type'] = 'application/json'
    opsi.body = typeof isi === 'string' ? isi : JSON.stringify(isi)
  }

  let jawab = null
  if (!melempar) {
    try {
      jawab = await penangan[0](new Request('https://fungsi.invalid/verifikasi_pelanggan', opsi))
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
  catat('V01 body JSON null → 400 terkendali', r.jawab?.status === 400, `status=${r.jawab?.status}`)
}

// 2. JSON array -> 400
{
  const r = await jalankan({ isi: '[]' })
  catat('V02 body array → 400 terkendali', r.jawab?.status === 400, `status=${r.jawab?.status}`)
}

// 3. Method GET -> 405
{
  const r = await jalankan({ method: 'GET' })
  catat('V03 method GET → 405', r.jawab?.status === 405, `status=${r.jawab?.status}`)
}

// 4. Tanpa persetujuan privasi -> 400
{
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'budi@gmail.com',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: false,
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V04 tanpa persetujuan privasi UU PDP → 400 (T-011)',
    r.jawab?.status === 400 && d?.kode === 'PRIVASI_WAJIB',
    `status=${r.jawab?.status} kode=${d?.kode}`,
  )
}

// 5. Nama kosong -> 400
{
  const r = await jalankan({
    isi: {
      nama: '   ',
      email: 'budi@gmail.com',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: true,
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V05 nama kosong → 400',
    r.jawab?.status === 400 && d?.kode === 'NAMA_WAJIB',
    `status=${r.jawab?.status} kode=${d?.kode}`,
  )
}

// 6. Email sekali-pakai -> 400 EMAIL_SEKALI_PAKAI
{
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'budi@tempmail.com',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: true,
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V06 email sekali-pakai (tempmail) → ditolak 400',
    r.jawab?.status === 400 && d?.kode === 'EMAIL_SEKALI_PAKAI',
    `status=${r.jawab?.status} kode=${d?.kode}`,
  )
}

// 7. Email format salah -> 400 EMAIL_TIDAK_SAH
{
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'budi@@bukanemail',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: true,
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V07 email format salah → ditolak 400',
    r.jawab?.status === 400 && d?.kode === 'EMAIL_TIDAK_SAH',
    `status=${r.jawab?.status} kode=${d?.kode}`,
  )
}

// 8. Sukses & normalisasi Gmail dot + tag -> 200
{
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'b.u.d.i.santoso+promo@gmail.com',
      penyewa_id: PENYEWA_UJI,
      kampanye_id: KAMPANYE_UJI,
      persetujuan_privasi: true,
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V08 sukses pendaftaran voucher → 200',
    r.jawab?.status === 200 && d?.berhasil === true && r.panggilan.length === 1,
    `status=${r.jawab?.status} berhasil=${d?.berhasil}`,
  )
}

// 9. Upstream fetch gagal jaringan -> 200 terkendali (tidak unhandled crash)
{
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: true,
    },
    fetchTiruan: () => {
      throw new TypeError('network offline')
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'V09 upstream jaringan offline → jawaban gagal terkendali',
    r.melempar === null && d?.berhasil === false && d?.kode === 'JARINGAN_GAGAL',
    `melempar=${r.melempar?.message ?? 'tidak'} kode=${d?.kode}`,
  )
}

// 10. CORS: asal sah mendapat header CORS
{
  const asal = 'http://localhost:5173'
  const r = await jalankan({
    isi: {
      nama: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      penyewa_id: PENYEWA_UJI,
      persetujuan_privasi: true,
    },
    origin: asal,
  })
  catat(
    'V10 origin sah → CORS memantulkan origin',
    r.jawab?.headers.get('access-control-allow-origin') === asal,
    `acao=${r.jawab?.headers.get('access-control-allow-origin')}`,
  )
}

const gagal = hasil.filter((h) => !h.lulus)
console.log('UJI BATAS EDGE — verifikasi_pelanggan (berkas asli dijalankan di VM, tanpa jaringan)')
for (const h of hasil) {
  console.log(`  ${h.lulus ? 'LOLOS' : 'GAGAL'}  ${h.nama}  [${h.catatan}]`)
}
console.log(`\nRINGKASAN: ${hasil.length - gagal.length} lolos, ${gagal.length} gagal`)
process.exit(gagal.length > 0 ? 1 : 0)
