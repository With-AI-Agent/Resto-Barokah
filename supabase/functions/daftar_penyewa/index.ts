// ============================================================================
// Edge Function: daftar penyewa baru oleh Pemilik Platform (T9-10 — PRD M1 / ART-1)
//
// Alur:
//   1. Menerima permintaan POST pendaftaran resto baru.
//   2. Memeriksa bentuk JSON dan validasi masukan awal (nama, email, PIN 6 digit).
//   3. Memeriksa Authorization header pemanggil (harus token autentikasi valid).
//   4. Meneruskan ke RPC database `public.buat_penyewa(...)` menggunakan token pemanggil
//      sehingga otorisasi peran `pemilik_platform` ditegakkan penuh oleh basis data.
//   5. Menjawab dengan CORS resmi dan format JSON seragam.
// ============================================================================

const RPC = 'buat_penyewa'

const ASAL_DIIZINKAN = [
  'https://resto-barokah.fatrizmubarok.workers.dev',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]

function kepalaCORS(req: Request): Record<string, string> {
  const kepala: Record<string, string> = {
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    Vary: 'Origin',
  }
  const asal = req.headers.get('origin')
  if (asal !== null && ASAL_DIIZINKAN.includes(asal)) {
    kepala['Access-Control-Allow-Origin'] = asal
  }
  return kepala
}

function balasan(isi: unknown, status = 200, kepala: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...kepala,
    },
  })
}

export default async function handler(req: Request): Promise<Response> {
  const kepala = kepalaCORS(req)

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: kepala })
  }

  if (req.method !== 'POST') {
    return balasan({ berhasil: false, pesan: 'Hanya menerima permintaan POST.' }, 405, kepala)
  }

  let isi: unknown
  try {
    isi = await req.json()
  } catch {
    return balasan({ berhasil: false, pesan: 'Format JSON permintaan tidak terbaca.' }, 400, kepala)
  }

  if (isi === null || typeof isi !== 'object' || Array.isArray(isi)) {
    return balasan({ berhasil: false, pesan: 'Format badan permintaan tidak valid.' }, 400, kepala)
  }

  const badan = isi as Record<string, unknown>
  const nama = typeof badan['nama'] === 'string' ? badan['nama'].trim() : ''
  const slug = typeof badan['slug'] === 'string' ? badan['slug'].trim() : null
  const zonaWaktu = typeof badan['zona_waktu'] === 'string' ? badan['zona_waktu'].trim() : 'Asia/Jakarta'
  const mataUang = typeof badan['mata_uang'] === 'string' ? badan['mata_uang'].trim().toUpperCase() : 'IDR'
  const kontakTelepon = typeof badan['kontak_telepon'] === 'string' ? badan['kontak_telepon'].trim() : null
  const kontakEmail = typeof badan['kontak_email'] === 'string' ? badan['kontak_email'].trim() : null
  const cabangNama = typeof badan['cabang_nama'] === 'string' ? badan['cabang_nama'].trim() : 'Cabang Utama'
  const cabangAlamat = typeof badan['cabang_alamat'] === 'string' ? badan['cabang_alamat'].trim() : null
  const cabangTelepon = typeof badan['cabang_telepon'] === 'string' ? badan['cabang_telepon'].trim() : null
  const ownerNama = typeof badan['owner_nama'] === 'string' ? badan['owner_nama'].trim() : ''
  const ownerEmail = typeof badan['owner_email'] === 'string' ? badan['owner_email'].trim().toLowerCase() : ''
  const ownerPin = typeof badan['owner_pin'] === 'string' ? badan['owner_pin'].trim() : ''

  if (!nama) {
    return balasan({ berhasil: false, pesan: 'Nama penyewa/resto wajib diisi (1-120 karakter).' }, 400, kepala)
  }
  if (!ownerNama) {
    return balasan({ berhasil: false, pesan: 'Nama Owner pertama wajib diisi (1-120 karakter).' }, 400, kepala)
  }
  if (!ownerEmail || !ownerEmail.includes('@')) {
    return balasan({ berhasil: false, pesan: 'Format email Owner tidak valid.' }, 400, kepala)
  }
  if (!/^\d{6}$/.test(ownerPin)) {
    return balasan({ berhasil: false, pesan: 'Akun Owner wajib diberikan PIN awal 6 digit angka.' }, 400, kepala)
  }

  const urlSupabase = Deno.env.get('SUPABASE_URL') ?? ''
  const kunciAnon = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  const authHeader = req.headers.get('authorization') ?? ''

  if (!authHeader) {
    return balasan({ berhasil: false, pesan: 'Pengguna belum terautentikasi.' }, 401, kepala)
  }

  try {
    const resPeladen = await fetch(`${urlSupabase}/rest/v1/rpc/${RPC}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: kunciAnon,
        Authorization: authHeader,
      },
      body: JSON.stringify({
        p_nama: nama,
        p_slug: slug,
        p_zona_waktu: zonaWaktu,
        p_mata_uang: mataUang,
        p_kontak_telepon: kontakTelepon,
        p_kontak_email: kontakEmail,
        p_cabang_nama: cabangNama,
        p_cabang_alamat: cabangAlamat,
        p_cabang_telepon: cabangTelepon,
        p_owner_nama: ownerNama,
        p_owner_email: ownerEmail,
        p_owner_pin: ownerPin,
      }),
    })

    const teks = await resPeladen.text()
    let hasil: unknown
    try {
      hasil = JSON.parse(teks)
    } catch {
      hasil = { berhasil: false, pesan: teks || 'Gagal memproses pendaftaran penyewa.' }
    }

    return balasan(hasil, resPeladen.status, kepala)
  } catch {
    return balasan({ berhasil: false, pesan: 'Gagal terhubung ke layanan basis data.' }, 502, kepala)
  }
}
