#!/usr/bin/env node
/**
 * catat-alamat.mjs — mencari ALAMAT PUBLIK halaman lalu MEMERIKSA-nya (bukti, bukan asumsi).
 *
 * Kenapa ada: tugas T0-09 (deploy halaman ke Cloudflare) selesai hanya kalau kita tahu **alamat
 * publiknya** dan alamat itu benar-benar menjawab. Lingkungan agent tidak punya jalan keluar
 * jaringan ke Cloudflare, sedangkan runner GitHub punya — jadi alamat dicari di dalam alur deploy.
 *
 * Masalah nyata yang harus dilewati: catatan (log) job GitHub Actions **tidak bisa dibaca** dari
 * lingkungan agent. Karena itu hasilnya dikeluarkan sebagai **anotasi** (`::notice::` / `::error::`)
 * yang bisa dibaca lewat API GitHub pada commit yang sama — jadi bukti tetap bisa diambil siapa pun
 * tanpa membaca log.
 *
 * Cara kerja:
 *   1. tanya Cloudflare API: subdomain pekerja (workers.dev) milik akun ini
 *   2. susun alamat: https://<nama-pekerja>.<subdomain>.workers.dev
 *   3. buka alamat itu; HTTP 200 = halaman benar-benar hidup (kalau bukan 200 → proses GAGAL)
 *   4. tulis anotasi `ALAMAT-PUBLIK url=… http=… waktu=…` + cetak ke layar
 *
 * Nilai yang dibutuhkan (dari rahasia GitHub, tidak pernah masuk repo):
 *   CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID
 * Opsional: NAMA_WORKER (bawaan `resto-barokah`).
 *
 * Mode `--uji-diri`: server tiruan di localhost + kasus-kasus yang WAJIB ditolak, supaya alat ini
 * dibuktikan bekerja (dijalankan di CI, tanpa jaringan luar).
 */
import { createServer } from 'node:http'

/** Nama pekerja Cloudflare (harus sama dengan `name` di aplikasi/wrangler.toml). */
export const NAMA_WORKER_BAWAAN = 'resto-barokah'

/** Batas tunggu tiap percobaan jaringan (milidetik). */
export const BATAS_TUNGGU_MS = 20000

const POLA_NAMA = /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/

/** Susun alamat publik dari nama pekerja + subdomain. Ditolak sebelum jaringan bila bentuknya aneh. */
export function bangunAlamat(namaPekerja, subdomain) {
  if (!POLA_NAMA.test(namaPekerja)) throw new Error(`nama pekerja tidak sah: ${namaPekerja}`)
  if (!POLA_NAMA.test(subdomain)) throw new Error(`subdomain tidak sah: ${subdomain}`)
  return `https://${namaPekerja}.${subdomain}.workers.dev`
}

/** Tanya Cloudflare: subdomain workers.dev milik akun ini. */
export async function ambilSubdomain({ akun, token, fetchUji = fetch }) {
  const url = `https://api.cloudflare.com/client/v4/accounts/${akun}/workers/subdomain`
  const jawab = await fetchUji(url, {
    headers: { Authorization: `Bearer ${token}` },
    signal: AbortSignal.timeout(BATAS_TUNGGU_MS),
  })
  const teks = await jawab.text()
  if (jawab.status !== 200) {
    throw new Error(
      `Cloudflare menolak permintaan subdomain (HTTP ${jawab.status}): ${teks.slice(0, 160)}`,
    )
  }
  let isi
  try {
    isi = JSON.parse(teks)
  } catch {
    throw new Error(`jawaban Cloudflare bukan JSON: ${teks.slice(0, 120)}`)
  }
  const sub = isi?.result?.subdomain
  if (typeof sub !== 'string' || sub === '') {
    throw new Error(
      'jawaban Cloudflare tidak memuat result.subdomain (pekerja mungkin belum pernah rilis)',
    )
  }
  return sub
}

/** Buka alamat publik; kembalikan status HTTP (0 = gagal menyambung). */
export async function periksaAlamat(alamat, fetchUji = fetch) {
  const mulai = Date.now()
  try {
    const jawab = await fetchUji(alamat, { signal: AbortSignal.timeout(BATAS_TUNGGU_MS) })
    await jawab.text().catch(() => '')
    return { status: jawab.status, ms: Date.now() - mulai }
  } catch (e) {
    return { status: 0, ms: Date.now() - mulai, pesan: String(e?.message ?? e) }
  }
}

/** Baris anotasi GitHub (dibaca lewat API pada commit yang sama — bukan dari log). */
export function anotasiAlamat({ alamat, status, waktu }) {
  const jenis = status === 200 ? 'notice' : 'error'
  return `::${jenis} title=ALAMAT-PUBLIK::url=${alamat} http=${status} waktu=${waktu}`
}

/** Jalankan seluruh pemeriksaan; kembalikan hasilnya (tidak mencetak, tidak keluar proses). */
export async function jalankan({
  akun,
  token,
  namaPekerja = NAMA_WORKER_BAWAAN,
  fetchUji = fetch,
  cetak = console.log,
}) {
  const subdomain = await ambilSubdomain({ akun, token, fetchUji })
  const alamat = bangunAlamat(namaPekerja, subdomain)
  const { status, ms, pesan } = await periksaAlamat(alamat, fetchUji)
  const waktu = new Date().toISOString()
  cetak(`Alamat publik: ${alamat} → HTTP ${status} (${ms} ms)${pesan ? ` — ${pesan}` : ''}`)
  cetak(anotasiAlamat({ alamat, status, waktu }))
  return { alamat, status, ms, waktu, ok: status === 200 }
}

/** Server tiruan: Cloudflare API + halaman pekerja (untuk `--uji-diri`). */
async function serverTiruan({
  subdomain = 'kedai-uji',
  halaman = 200,
  tokenBenar = 'token-uji',
} = {}) {
  const server = createServer((req, res) => {
    const jawab = (status, isi) => {
      res.writeHead(status, { 'content-type': 'application/json' })
      res.end(typeof isi === 'string' ? isi : JSON.stringify(isi))
    }
    if (req.url?.includes('/workers/subdomain')) {
      if (req.headers.authorization !== `Bearer ${tokenBenar}`)
        return jawab(403, { success: false })
      if (subdomain === null) return jawab(200, { result: {} })
      return jawab(200, { result: { subdomain }, success: true })
    }
    return jawab(halaman, halaman === 200 ? { ok: true } : { pesan: 'belum ada' })
  })
  await new Promise((lanjut) => server.listen(0, '127.0.0.1', lanjut))
  const { port } = server.address()
  return {
    basis: `http://127.0.0.1:${port}`,
    tutup: () => new Promise((s) => server.close(s)),
  }
}

async function ujiDiri() {
  const kasus = []
  const diam = () => {}
  // Fetch tiruan: URL Cloudflare diarahkan ke server tiruan; alamat halaman diambil dari Host tiruan.
  const buatFetch = (basis) => async (url, opsi) => {
    const asli = String(url)
    const dialihkan = asli.startsWith('https://api.cloudflare.com')
      ? `${basis}/client/v4/accounts/akun-uji/workers/subdomain`
      : `${basis}/halaman`
    return fetch(dialihkan, opsi)
  }

  const tiruan = await serverTiruan()
  try {
    const hasil = await jalankan({
      akun: 'akun-uji',
      token: 'token-uji',
      fetchUji: buatFetch(tiruan.basis),
      cetak: diam,
    })
    kasus.push([
      'halaman hidup (200) diterima & alamat disusun benar',
      hasil.ok && hasil.alamat === `https://${NAMA_WORKER_BAWAAN}.kedai-uji.workers.dev`,
      hasil.alamat,
    ])
    kasus.push([
      'baris anotasi dibuat untuk dibaca lewat API',
      hasil.ok &&
        /^::notice title=ALAMAT-PUBLIK::url=https:\/\//.test(
          anotasiAlamat({ alamat: hasil.alamat, status: 200, waktu: hasil.waktu }),
        ),
      '',
    ])
    kasus.push([
      'HTTP bukan 200 → ditolak (bukan lolos diam-diam)',
      /^::error /.test(anotasiAlamat({ alamat: hasil.alamat, status: 404, waktu: hasil.waktu })),
      '',
    ])
  } finally {
    await tiruan.tutup()
  }

  const tiruan404 = await serverTiruan({ halaman: 404 })
  try {
    const hasil = await jalankan({
      akun: 'akun-uji',
      token: 'token-uji',
      fetchUji: buatFetch(tiruan404.basis),
      cetak: diam,
    })
    kasus.push(['halaman belum siap (404) → ok=false', hasil.ok === false, `http=${hasil.status}`])
  } finally {
    await tiruan404.tutup()
  }

  const tiruanTanpaSub = await serverTiruan({ subdomain: null })
  try {
    let pesan = ''
    try {
      await jalankan({
        akun: 'akun-uji',
        token: 'token-uji',
        fetchUji: buatFetch(tiruanTanpaSub.basis),
        cetak: diam,
      })
    } catch (e) {
      pesan = String(e?.message ?? e)
    }
    kasus.push([
      'subdomain tidak ada di jawaban → gagal dengan pesan jelas',
      pesan.includes('subdomain'),
      pesan.slice(0, 60),
    ])
  } finally {
    await tiruanTanpaSub.tutup()
  }

  try {
    bangunAlamat('nama salah!', 'sub-uji')
    kasus.push(['nama pekerja tidak sah ditolak sebelum jaringan', false, 'tidak melempar'])
  } catch (e) {
    kasus.push([
      'nama pekerja tidak sah ditolak sebelum jaringan',
      true,
      String(e.message).slice(0, 50),
    ])
  }

  let merah = 0
  console.log('UJI-DIRI ALAT CATAT ALAMAT PUBLIK')
  for (const [nama, lulus, catatan] of kasus) {
    if (!lulus) merah += 1
    console.log(`  ${lulus ? 'OK ' : 'X  '} ${nama}${catatan ? ` — ${catatan}` : ''}`)
  }
  console.log(`\nUJI DIRI: ${kasus.length - merah}/${kasus.length} ${merah ? 'GAGAL' : 'LOLOS'}`)
  return merah === 0
}

async function utama() {
  if (process.argv.includes('--uji-diri')) {
    process.exit((await ujiDiri()) ? 0 : 1)
  }
  const akun = process.env.CLOUDFLARE_ACCOUNT_ID ?? ''
  const token = process.env.CLOUDFLARE_API_TOKEN ?? ''
  const namaPekerja = process.env.NAMA_WORKER ?? NAMA_WORKER_BAWAAN
  if (!akun || !token) {
    console.log(
      'GAGAL — CLOUDFLARE_ACCOUNT_ID / CLOUDFLARE_API_TOKEN belum tersedia di lingkungan ini.',
    )
    process.exit(1)
  }
  try {
    const hasil = await jalankan({ akun, token, namaPekerja })
    if (!hasil.ok) {
      console.log(
        '\nHASIL: GAGAL — alamat publik tidak menjawab 200. Periksa: pekerja sudah terunggah? nama benar? ' +
          'alamat *.workers.dev aktif?',
      )
      process.exit(1)
    }
    console.log(
      '\nHASIL: LULUS — halaman publik menjawab 200 dan alamatnya sudah dicatat sebagai anotasi.',
    )
    process.exit(0)
  } catch (e) {
    console.log(`GAGAL — ${String(e?.message ?? e)}`)
    process.exit(1)
  }
}

if (
  process.argv[1] &&
  import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/').split('/').pop())
) {
  await utama()
}
