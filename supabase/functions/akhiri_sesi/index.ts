// ============================================================================
// Edge Function: akhiri sesi & penanganan perangkat hilang (T10-06 / PRD M12)
//
// Alur:
//   1. Menerima permintaan POST pengakhiran sesi aktif atau pelaporan perangkat hilang.
//   2. Memeriksa bentuk JSON dan validasi masukan (UUID, session_id).
//   3. Memeriksa header Authorization (wajib token autentikasi sah).
//   4. Meneruskan ke RPC basis data yang sesuai:
//      - hilang: true / perangkat_id -> tandai_perangkat_hilang
//      - semua: true / pengguna_id -> keluar_semua_perangkat
//      - tunggal (session_id) -> akhiri_sesi
//   5. Seluruh keputusan otorisasi dan pencatatan audit ditegakkan di basis data.
// ============================================================================

const ASAL_DIIZINKAN = [
  'https://resto-barokah.fatrizmubarok.workers.dev',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]

const POLA_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

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

  const token = req.headers.get('Authorization')
  if (!token) {
    return balasan({ berhasil: false, pesan: 'Autentikasi diperlukan.' }, 401, kepala)
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
  const sessionId = typeof badan['session_id'] === 'string' ? badan['session_id'].trim() : null
  const penggunaId = typeof badan['pengguna_id'] === 'string' ? badan['pengguna_id'].trim() : null
  const perangkatId = typeof badan['perangkat_id'] === 'string' ? badan['perangkat_id'].trim() : null
  const alasan = typeof badan['alasan'] === 'string' ? badan['alasan'].trim() : null
  const semua = badan['semua'] === true
  const hilang = badan['hilang'] === true

  // Validasi format UUID jika disediakan
  if (penggunaId !== null && !POLA_UUID.test(penggunaId)) {
    return balasan({ berhasil: false, pesan: 'Format pengguna_id tidak valid.' }, 400, kepala)
  }
  if (perangkatId !== null && !POLA_UUID.test(perangkatId)) {
    return balasan({ berhasil: false, pesan: 'Format perangkat_id tidak valid.' }, 400, kepala)
  }

  let rpcTujuan = 'akhiri_sesi'
  let payloadRpc: Record<string, unknown> = {}

  if (hilang || (perangkatId !== null && sessionId === null && penggunaId === null)) {
    if (!perangkatId) {
      return balasan(
        { berhasil: false, pesan: 'perangkat_id wajib disertakan untuk menandai perangkat hilang.' },
        400,
        kepala,
      )
    }
    rpcTujuan = 'tandai_perangkat_hilang'
    payloadRpc = {
      p_perangkat_id: perangkatId,
      p_alasan: alasan ?? 'Perangkat dilaporkan hilang atau dicuri',
    }
  } else if (semua || (penggunaId !== null && sessionId === null)) {
    rpcTujuan = 'keluar_semua_perangkat'
    payloadRpc = {
      p_pengguna_id: penggunaId,
      p_alasan: alasan ?? 'Pencabutan seluruh sesi aktif perangkat',
    }
  } else {
    rpcTujuan = 'akhiri_sesi'
    payloadRpc = {
      p_session_id: sessionId,
      p_alasan: alasan ?? 'Sesi diakhiri secara manual',
    }
  }

  const alamat = Deno.env.get('SUPABASE_URL') ?? ''
  const kunciAnon = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

  if (!alamat || !kunciAnon) {
    return balasan({ berhasil: false, pesan: 'Peladen basis data belum terkonfigurasi.' }, 500, kepala)
  }

  const gagalTerkendali = {
    berhasil: false,
    pesan: 'Permintaan pengakhiran sesi tidak dapat diproses saat ini. Silakan coba lagi.',
  }

  try {
    const resPeladen = await fetch(`${alamat}/rest/v1/rpc/${rpcTujuan}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: kunciAnon,
        Authorization: token,
      },
      body: JSON.stringify(payloadRpc),
    })

    const teks = await resPeladen.text()
    let hasil: unknown
    try {
      hasil = JSON.parse(teks)
    } catch {
      return balasan(gagalTerkendali, resPeladen.status, kepala)
    }

    const hasilObj = (Array.isArray(hasil) ? hasil[0] : hasil) as Record<string, unknown>
    return balasan(hasilObj, resPeladen.status, kepala)
  } catch {
    return balasan(gagalTerkendali, 502, kepala)
  }
}
