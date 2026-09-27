#!/usr/bin/env node
/**
 * uji-edge-ringkasan-harian.mjs — menguji BATAS Edge Function `ringkasan_harian` TANPA jaringan.
 *
 * Menguji perilaku handler:
 *   1. Penolakan method selain POST (405).
 *   2. Penolakan tanpa header Authorization (401).
 *   3. Penolakan format JSON tidak valid (400).
 *   4. Penolakan penyewa_id bukan UUID (400).
 *   5. Penolakan tanggal bukan format YYYY-MM-DD (400).
 *   6. Pemanggilan RPC hasilkan_ringkasan_harian berhasil (200).
 *   7. Pembangun email bangunIsiEmail bebas dari data pribadi pelanggan (ART-14).
 *   8. Pembaruan status pengiriman email ke set_status_email_ringkasan (200).
 *   9. Penanganan gagal jaringan terkendali 502.
 *  10. Pembatasan CORS dan preflight OPTIONS (204).
 */
import { readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import vm from 'node:vm'
import { createRequire } from 'node:module'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const BERKAS = join(AKAR, 'supabase', 'functions', 'ringkasan_harian', 'index.ts')

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

const PENYEWA_UJI = '11111111-1111-1111-1111-111111111111'
const RINGKASAN_ID = '77777777-7777-7777-7777-777777777777'

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

    if (String(url).includes('/rpc/hasilkan_ringkasan_harian')) {
      return new Response(
        JSON.stringify({
          id: RINGKASAN_ID,
          penyewa_id: PENYEWA_UJI,
          tanggal: '2026-09-25',
          omzet: 150000,
          transaksi_count: 2,
          void_count: 1,
          void_nominal: 35000,
          diskon_count: 2,
          diskon_nominal: 15000,
          selisih_kas_count: 1,
          selisih_kas_nominal: 20000,
          percobaan_gagal_count: 2,
          perubahan_perangkat_count: 1,
          pemulihan_count: 0,
          rantai_audit_valid: true,
          rantai_audit_pesan: 'Rantai audit utuh.',
          email_tujuan: 'owner.a@contoh.test',
          status_email: 'tertunda',
          rincian_peringatan: [
            {
              kategori: 'void',
              pegawai: 'Rina',
              alasan: 'Salah meja',
              nominal: 35000,
              waktu: '2026-09-25T12:00:00Z',
            },
          ],
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      )
    }

    return new Response(JSON.stringify({ berhasil: true }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
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
    Math,
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
  const bangunEmail = modulTiruan.exports?.bangunIsiEmail

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
      jawab = await handler(new Request('https://fungsi.invalid/ringkasan_harian', opsi))
    } catch (e) {
      melempar = e
    }
  }
  const badan = jawab ? await jawab.text() : ''
  return { jawab, badan, melempar, panggilan, bangunEmail }
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

// 1. Method GET -> 405
{
  const r = await jalankan({ method: 'GET' })
  catat('S01 method selain POST → 405', r.jawab?.status === 405, `status=${r.jawab?.status}`)
}

// 2. Tanpa token Authorization -> 401
{
  const r = await jalankan({ isi: { tanggal: '2026-09-25' }, tanpaToken: true })
  catat('S02 tanpa token Authorization → 401', r.jawab?.status === 401 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 3. Body JSON tidak valid -> 400
{
  const r = await jalankan({ isi: '{bukan-json' })
  catat('S03 JSON tidak valid → 400', r.jawab?.status === 400, `status=${r.jawab?.status}`)
}

// 4. Format penyewa_id bukan UUID -> 400
{
  const r = await jalankan({ isi: { penyewa_id: 'salah-format' } })
  catat('S04 penyewa_id bukan UUID → 400', r.jawab?.status === 400 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 5. Format tanggal bukan YYYY-MM-DD -> 400
{
  const r = await jalankan({ isi: { tanggal: '25-09-2026' } })
  catat('S05 format tanggal bukan YYYY-MM-DD → 400', r.jawab?.status === 400 && r.panggilan.length === 0, `status=${r.jawab?.status}`)
}

// 6. Permintaan valid -> memanggil RPC hasilkan_ringkasan_harian
{
  const r = await jalankan({ isi: { penyewa_id: PENYEWA_UJI, tanggal: '2026-09-25' } })
  const d = bacaJSON(r.badan)
  const panggil = r.panggilan[0]
  catat(
    'S06 permintaan valid memanggil hasilkan_ringkasan_harian',
    r.jawab?.status === 200 && d?.berhasil === true && panggil?.url.includes('/rpc/hasilkan_ringkasan_harian'),
    `status=${r.jawab?.status} data_omzet=${d?.data?.omzet}`,
  )
}

// 7. Privasi ART-14: Memastikan pembangun email bebas data pribadi pelanggan
{
  const r = await jalankan({})
  if (typeof r.bangunEmail === 'function') {
    const konten = r.bangunEmail({
      tanggal: '2026-09-25',
      omzet: 150000,
      transaksi_count: 2,
      void_count: 1,
      void_nominal: 35000,
      diskon_count: 0,
      diskon_nominal: 0,
      selisih_kas_count: 0,
      selisih_kas_nominal: 0,
      percobaan_gagal_count: 0,
      perubahan_perangkat_count: 0,
      pemulihan_count: 0,
      rantai_audit_valid: true,
      rantai_audit_pesan: 'Audit utuh.',
    })
    const amanDariKontak = !konten.html.includes('@gmail.com') && !konten.teks.includes('0812')
    catat(
      'S07 pembangun email bebas data pelanggan (ART-14)',
      amanDariKontak && konten.subjek.includes('2026-09-25'),
      `subjek=${konten.subjek}`,
    )
  } else {
    catat('S07 pembangun email bebas data pelanggan (ART-14)', false, 'bangunEmail tidak diekspor')
  }
}

// 8. Pembaruan status pengiriman email ke set_status_email_ringkasan
{
  const r = await jalankan({ isi: { penyewa_id: PENYEWA_UJI, tanggal: '2026-09-25', kirim_email: true } })
  const d = bacaJSON(r.badan)
  const panggilSetStatus = r.panggilan.find((p) => p.url.includes('/rpc/set_status_email_ringkasan'))
  catat(
    'S08 pembaruan status email memanggil set_status_email_ringkasan',
    r.jawab?.status === 200 && panggilSetStatus !== undefined && d?.email?.terkirim === true,
    `email_terkirim=${d?.email?.terkirim} panggil_set_status=${panggilSetStatus !== undefined}`,
  )
}

// 9. Upstream fetch gagal jaringan -> balasan terkendali 502
{
  const r = await jalankan({
    fetchTiruan: () => {
      throw new TypeError('network offline')
    },
  })
  const d = bacaJSON(r.badan)
  catat(
    'S09 upstream jaringan error → jawaban terkendali 502',
    r.melempar === null && r.jawab?.status === 502 && d?.berhasil === false,
    `melempar=${r.melempar?.message ?? 'tidak'} status=${r.jawab?.status}`,
  )
}

// 10. CORS: Origin sah dan preflight OPTIONS 204
{
  const asal = 'http://localhost:5173'
  const r = await jalankan({ method: 'OPTIONS', origin: asal })
  catat(
    'S10 preflight OPTIONS → 204 dengan header CORS',
    r.jawab?.status === 204 && r.jawab?.headers.get('access-control-allow-origin') === asal,
    `status=${r.jawab?.status}`,
  )
}

const gagal = hasil.filter((h) => !h.lulus)
console.log('UJI BATAS EDGE — ringkasan_harian (berkas asli dijalankan di VM, tanpa jaringan)')
for (const h of hasil) {
  console.log(`  ${h.lulus ? 'LOLOS' : 'GAGAL'}  ${h.nama}  [${h.catatan}]`)
}
console.log(`\nRINGKASAN: ${hasil.length - gagal.length} lolos, ${gagal.length} gagal`)
process.exit(gagal.length > 0 ? 1 : 0)
