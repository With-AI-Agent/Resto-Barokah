// ============================================================================
// Edge Function: verifikasi PIN pegawai (ART-2 & TECH_SPEC §9)
//
// Tugasnya sengaja TIPIS: menerima permintaan, memeriksa bentuknya, lalu
// meneruskan ke fungsi database `public.verifikasi_pin(...)` memakai token
// pemanggil (bukan kunci penuh). Semua aturan yang menentukan (hash, batas
// percobaan, izin) ada di database — jadi tidak ada dua tempat yang bisa
// berbeda pendapat.
//
// ATURAN YANG TIDAK BOLEH DILANGGAR:
//   1. PIN TIDAK PERNAH ditulis ke log, tidak pernah disimpan, tidak pernah
//      dikembalikan. Berkas ini karena itu TIDAK memakai console.* sama sekali.
//   2. Hanya menerima POST (permintaan dengan data di URL bisa tersimpan di log
//      perantara → PIN bocor).
//   3. Memakai kunci publik + token pemanggil, BUKAN service_role: kalau memakai
//      service_role, seluruh penjagaan RLS di database dilewati.
//   4. Menjawab dengan pesan yang sama seperti database — tidak menambah detail
//      yang bisa membantu menebak.
//
// Penjaga otomatis: `alat/periksa-fungsi-pin.py` menolak kiriman kode bila
// berkas ini kembali memuat console.*, kata service_role, atau tidak lagi
// memakai POST/Authorization. Pemeriksa itu ikut berjalan di CI.
// ============================================================================

const RPC = 'verifikasi_pin'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function balasan(isi: unknown, status = 200): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  if (req.method !== 'POST') return balasan({ pesan: 'Metode harus POST.' }, 405)

  const alamat = Deno.env.get('SUPABASE_URL')
  const kunciPublik = Deno.env.get('SUPABASE_ANON_KEY')
  const token = req.headers.get('Authorization')

  if (!alamat || !kunciPublik) return balasan({ pesan: 'Peladen belum siap.' }, 500)
  if (!token) return balasan({ pesan: 'Anda harus masuk dulu untuk memakai PIN.' }, 401)

  let isi: Record<string, unknown>
  try {
    isi = await req.json()
  } catch {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400)
  }

  const penggunaId = typeof isi['pengguna_id'] === 'string' ? isi['pengguna_id'] : ''
  const pin = typeof isi['pin'] === 'string' ? isi['pin'] : ''
  const aksi = typeof isi['aksi'] === 'string' ? isi['aksi'] : null
  const perangkat = typeof isi['perangkat'] === 'string' ? isi['perangkat'] : 'tidak-diketahui'

  // Sejak T1-23 (migrasi 0011) PIN wajib TEPAT 6 angka — dijaga di sini sebagai
  // saringan awal, dan tetap ditegakkan database (simpan_pin/verifikasi_pin).
  if (!/^[0-9a-f-]{36}$/i.test(penggunaId) || !/^\d{6}$/.test(pin)) {
    return balasan({ pesan: 'PIN harus tepat 6 angka.' }, 400)
  }

  const jawab = await fetch(`${alamat}/rest/v1/rpc/${RPC}`, {
    method: 'POST',
    headers: {
      apikey: kunciPublik,
      Authorization: token,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      p_pengguna_id: penggunaId,
      p_pin: pin,
      p_aksi: aksi,
      p_perangkat: perangkat,
    }),
  })

  if (!jawab.ok) {
    // Sebab teknis tidak dibocorkan ke peramban; pesannya tetap bahasa Indonesia.
    return balasan({ berhasil: false, sisa_percobaan: 0, pesan: 'PIN tidak bisa diperiksa sekarang. Coba lagi.' }, 200)
  }

  const baris = await jawab.json()
  const hasil = Array.isArray(baris) ? baris[0] : baris
  return balasan({
    berhasil: hasil?.berhasil === true,
    sisa_percobaan: Number(hasil?.sisa_percobaan ?? 0),
    pesan: typeof hasil?.pesan === 'string' ? hasil.pesan : 'PIN tidak bisa diperiksa sekarang. Coba lagi.',
  })
})
