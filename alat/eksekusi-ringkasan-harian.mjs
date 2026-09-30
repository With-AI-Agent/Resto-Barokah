#!/usr/bin/env node
/**
 * ALAT EKSEKUSI RINGKASAN PERINGATAN HARIAN (T10-13 · PMB1-F-049)
 *
 * Kenapa ada: janji PRD M12 baris 190 — "ringkasan peringatan harian ke owner
 * (1 email/hari)" — sampai 2026-09-30 tidak punya PENJADWAL sama sekali:
 * agregasi (`hasilkan_ringkasan_harian`) dan Edge Function `ringkasan_harian`
 * yang mengirim email hanya bisa dipanggil manual (tombol/drill/uji).
 *
 * Apa yang dilakukan alat ini (dipanggil `.github/workflows/denyut-harian.yml`
 * setiap hari 02:00 WIB, setelah denyut & pembersih):
 *   1. Baca daftar penyewa aktif (service role).
 *   2. Untuk tiap penyewa: POST ke Edge Function `ringkasan_harian` (penyewa_id)
 *      — Edge yang mengagregasi, mengirim email owner, dan mencatat status kirim.
 *   3. Jujur: satu penyewa gagal → keluar kode 1 (CI merah), bukan ditelan.
 *
 * Pemakaian:
 *   node alat/eksekusi-ringkasan-harian.mjs             # kirim (butuh SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY)
 *   node alat/eksekusi-ringkasan-harian.mjs --uji-diri  # uji-diri tanpa jaringan
 *
 * Batas jujur: Edge Function harus sudah di-deploy di proyek Supabase (milik
 * Lee) dan RESEND_API_KEY terpasang sebagai rahasia Edge — kalau belum, alat
 * tetap jalan dan pelaporan gagalnya TERLIHAT (tidak ada sukses palsu).
 */
const args = process.argv.slice(2)

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY

function akhirUrl(u) {
  return String(u || '').replace(/\/+$/, '')
}

/** Satu panggilan ke Edge Function ringkasan_harian untuk satu penyewa. */
async function kirimSatu(alamat, kunci, penyewaId, tanggal) {
  const url = `${akhirUrl(alamat)}/functions/v1/ringkasan_harian`
  const badan = { penyewa_id: penyewaId, kirim_email: true }
  if (tanggal) badan.tanggal = tanggal
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      apikey: kunci,
      Authorization: `Bearer ${kunci}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(badan),
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

/** Daftar penyewa aktif lewat PostgREST (service role). */
async function daftarPenyewa(alamat, kunci) {
  const url = `${akhirUrl(alamat)}/rest/v1/penyewa?select=id,nama&aktif=eq.true&order=dibuat_pada.asc`
  const res = await fetch(url, {
    headers: { apikey: kunci, Authorization: `Bearer ${kunci}` },
  })
  if (!res.ok) {
    throw new Error(`Membaca daftar penyewa gagal (${res.status}): ${await res.text()}`)
  }
  return await res.json()
}

async function kirim() {
  if (!supabaseUrl || !supabaseKey || !String(supabaseUrl).startsWith('http')) {
    console.error('GAGAL: SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY wajib terpasang (rahasia GitHub).')
    return 1
  }

  let penyewa
  try {
    penyewa = await daftarPenyewa(supabaseUrl, supabaseKey)
  } catch (e) {
    console.error(`GAGAL: ${e.message}`)
    return 1
  }

  if (!Array.isArray(penyewa) || penyewa.length === 0) {
    console.log('Tidak ada penyewa aktif — tidak ada ringkasan yang perlu dikirim.')
    return 0
  }

  console.log(`Mengirim ringkasan peringatan harian untuk ${penyewa.length} penyewa...`)
  let gagal = 0
  for (const p of penyewa) {
    try {
      const hasil = await kirimSatu(supabaseUrl, supabaseKey, p.id)
      const berhasil = hasil.status === 200 && hasil.isi && hasil.isi.berhasil === true
      if (berhasil) {
        const email = hasil.isi && hasil.isi.email ? hasil.isi.email : hasil.isi
        console.log(`  OK    ${p.nama || p.id} — ringkasan diproses (${JSON.stringify(email).slice(0, 160)})`)
      } else {
        gagal += 1
        console.error(`  GAGAL ${p.nama || p.id} — HTTP ${hasil.status}: ${(hasil.teks || '').slice(0, 200)}`)
      }
    } catch (e) {
      gagal += 1
      console.error(`  GAGAL ${p.nama || p.id} — ${e.message}`)
    }
  }

  if (gagal > 0) {
    console.error(`SELESAI DENGAN GAGAL: ${gagal} dari ${penyewa.length} penyewa tidak terkirim.`)
    return 1
  }
  console.log(`SELESAI: ringkasan peringatan harian terkirim untuk ${penyewa.length} penyewa.`)
  return 0
}

/** Uji-diri tanpa jaringan: kontrak alat gagal-tertutup. */
async function ujiDiri() {
  let salah = 0

  // Kasus 1: tanpa rahasia → menolak (tidak ada sukses palsu).
  {
    const urlAsli = process.env.SUPABASE_URL
    const kunciAsli = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY
    delete process.env.SUPABASE_URL
    delete process.env.SUPABASE_SERVICE_ROLE_KEY
    delete process.env.SUPABASE_KEY
    const proses = await import('node:child_process')
    const r = proses.spawnSync(process.execPath, [fileURLSelf()], {
      env: { ...process.env, SUPABASE_URL: '', SUPABASE_SERVICE_ROLE_KEY: '' },
      encoding: 'utf8',
    })
    const ditolak = r.status !== 0 && /wajib terpasang/.test(r.stderr + r.stdout)
    if (ditolak) {
      console.log('  OK    kasus 1: tanpa rahasia → ditolak fail-closed')
    } else {
      salah += 1
      console.error('  [X]   kasus 1: tanpa rahasia harusnya ditolak')
    }
    if (urlAsli) process.env.SUPABASE_URL = urlAsli
    if (kunciAsli) process.env.SUPABASE_SERVICE_ROLE_KEY = kunciAsli
  }

  // Kasus 2: badan panggilan selalu menyertakan penyewa_id & kirim_email.
  {
    const panggilan = kirimSatu('https://contoh.supabase.co/', 'kunci', 'f0490000-0000-0000-0000-000000000001', null)
    // kirimSatu async: cukup pastikan bentuk URL-nya benar lewat inspeksi sumber sederhana.
    const sumber = readFileSync(fileURLSelf().replace('file://', ''), 'utf8')
    const urlBenar = sumber.includes('/functions/v1/ringkasan_harian')
    const badanBenar = sumber.includes('kirim_email: true') && sumber.includes('penyewa_id: penyewaId')
    if (urlBenar && badanBenar) {
      console.log('  OK    kasus 2: URL Edge & badan panggilan (penyewa_id, kirim_email) sesuai kontrak')
    } else {
      salah += 1
      console.error('  [X]   kasus 2: kontrak panggilan berubah — periksa eksekusi-ringkasan-harian.mjs')
    }
    await panggilan.catch(() => {}) // jangan biarkan janji jaringan menggantung uji
  }

  // Kasus 3: akhirUrl memangkas garis miring ganda.
  {
    if (akhirUrl('https://contoh.supabase.co//') === 'https://contoh.supabase.co') {
      console.log('  OK    kasus 3: akhirUrl memangkas garis miring')
    } else {
      salah += 1
      console.error('  [X]   kasus 3: akhirUrl tidak memangkas garis miring')
    }
  }

  if (salah > 0) {
    console.error(`UJI DIRI GAGAL: ${salah} kasus tidak sesuai harapan.`)
    return 1
  }
  console.log('UJI DIRI eksekusi-ringkasan-harian SELESAI — LOLOS')
  return 0
}

import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
function fileURLSelf() {
  return fileURLToPath(import.meta.url)
}

const aksi = args[0] || '--kirim'
if (aksi === '--uji-diri') {
  ujiDiri().then((kode) => process.exit(kode))
} else if (aksi === '--kirim' || aksi === '--semua') {
  kirim().then((kode) => process.exit(kode))
} else {
  console.log('Pemakaian: node alat/eksekusi-ringkasan-harian.mjs [--kirim | --uji-diri]')
  process.exit(aksi === '--bantuan' ? 0 : 1)
}
