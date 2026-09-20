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
//   5. (H F-09) CORS dibatasi ke daftar asal sah — tidak ada wildcard `*`.
//   6. (I F-02 / H F-04) `pesanan_id` diperiksa bentuknya lalu diteruskan sebagai
//      `p_pesanan_id`; aksi berkupon (void_sesudah_dapur, beri_diskon) MENOLAK permintaan
//      tanpa pesanan_id, supaya kupon tidak pernah lahir tanpa ikatan pesanan.
//
// Penjaga otomatis:
//   * `alat/periksa-fungsi-pin.py` menolak kiriman kode bila berkas ini kembali memuat console
//     dalam bentuk apa pun, kata service_role, PIN di luar tiga jalur sah, atau tidak lagi
//     memakai POST/Authorization.
//   * `node alat/uji-edge-pin.mjs` MENJALANKAN handler ini (berkas asli, tanpa jaringan) dan
//     menuntut batasnya benar: JSON null/array → 400, UUID tidak sah → 400 sebelum menyentuh
//     database, jaringan putus & jawaban bukan JSON → jawaban gagal terkendali (bukan exception).
// Keduanya ikut berjalan di CI.
// ============================================================================

const RPC = 'verifikasi_pin'

// H F-09 (2026-09-20): asal (origin) DIBATAS — wildcard `*` diganti daftar asal sah.
// Peramban dari asal lain tetap boleh MEMANGGIL, tetapi tidak dapat MEMBACA jawaban
// (header CORS tidak dikirim), sehingga tidak ada kemampuan baru untuk situs jahat.
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
  if (asal !== null && ASAL_DIIZINKAN.includes(asal)) kepala['Access-Control-Allow-Origin'] = asal
  return kepala
}

function balasan(isi: unknown, status = 200, kepala: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: { ...kepala, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req: Request) => {
  const kepala = kepalaCORS(req)
  if (req.method === 'OPTIONS') return new Response('ok', { headers: kepala })
  if (req.method !== 'POST') return balasan({ pesan: 'Metode harus POST.' }, 405, kepala)

  const alamat = Deno.env.get('SUPABASE_URL')
  const kunciPublik = Deno.env.get('SUPABASE_ANON_KEY')
  const token = req.headers.get('Authorization')

  if (!alamat || !kunciPublik) return balasan({ pesan: 'Peladen belum siap.' }, 500, kepala)
  if (!token) return balasan({ pesan: 'Anda harus masuk dulu untuk memakai PIN.' }, 401, kepala)

  let isi: unknown
  try {
    isi = await req.json()
  } catch {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400, kepala)
  }

  // BATAS (temuan audit I F-07, 2026-09-19): JSON yang SAH belum tentu berbentuk objek — `null`,
  // array, atau angka semuanya sah. Dulu baris berikutnya langsung membaca properti sehingga
  // meledak dengan TypeError; kasir melihat kegagalan platform, bukan pesan seperti jalur lain.
  if (isi === null || typeof isi !== 'object' || Array.isArray(isi)) {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400, kepala)
  }
  const badan = isi as Record<string, unknown>

  const penggunaId = typeof badan['pengguna_id'] === 'string' ? badan['pengguna_id'] : ''
  const pin = typeof badan['pin'] === 'string' ? badan['pin'] : ''
  const aksi = typeof badan['aksi'] === 'string' ? badan['aksi'] : null
  const perangkat = typeof badan['perangkat'] === 'string' ? badan['perangkat'] : 'tidak-diketahui'

  // Sejak T1-23 (migrasi 0011) PIN wajib TEPAT 6 angka — dijaga di sini sebagai
  // saringan awal, dan tetap ditegakkan database (simpan_pin/verifikasi_pin).
  // F-07: bentuk UUID diperiksa LENGKAP (dulu `^[0-9a-f-]{36}$` meloloskan 36 tanda minus,
  // sehingga permintaan siapa pun bisa diteruskan ke database).
  const POLA_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!POLA_UUID.test(penggunaId) || !/^\d{6}$/.test(pin)) {
    return balasan({ pesan: 'PIN harus tepat 6 angka.' }, 400, kepala)
  }

  // I F-02 / H F-04 (2026-09-20): kupon persetujuan (void sesudah dapur & beri diskon)
  // WAJIB terikat pesanan di database (`pp.pesanan_id = new.pesanan_id`). Kalau Edge tidak
  // meneruskan pesanan, persetujuan lahir buntu dari perangkat kasir. Maka: bentuk pesanan_id
  // diperiksa (UUID lengkap) dan DIWAJIBKAN untuk aksi yang memakai kupon terikat pesanan.
  const AKSI_WAJIB_PESANAN = ['void_sesudah_dapur', 'beri_diskon']
  const pesananId = typeof badan['pesanan_id'] === 'string' ? (badan['pesanan_id'] as string) : null
  if (pesananId !== null && !POLA_UUID.test(pesananId)) {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400, kepala)
  }
  if (aksi !== null && AKSI_WAJIB_PESANAN.includes(aksi) && pesananId === null) {
    return balasan({ pesan: 'Persetujuan ini wajib menyebut pesanan yang disetujui.' }, 400, kepala)
  }

  // F-07: satu bentuk jawaban gagal untuk SEMUA masalah teknis (jaringan putus, peladen jawab
  // bukan JSON, upstream 500). Sebab teknis tidak dibocorkan ke peramban; pesannya tetap bahasa
  // Indonesia, dan kasir tidak pernah menerima kegagalan tak terkendali.
  const gagalDiperiksa = {
    berhasil: false,
    sisa_percobaan: 0,
    pesan: 'PIN tidak bisa diperiksa sekarang. Coba lagi.',
  }

  let jawab: Response
  try {
    jawab = await fetch(`${alamat}/rest/v1/rpc/${RPC}`, {
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
        p_pesanan_id: pesananId,
      }),
    })
  } catch {
    return balasan(gagalDiperiksa, 200, kepala)
  }

  if (!jawab.ok) {
    return balasan(gagalDiperiksa, 200, kepala)
  }

  let baris: unknown
  try {
    baris = await jawab.json()
  } catch {
    return balasan(gagalDiperiksa, 200, kepala)
  }
  const hasil = (Array.isArray(baris) ? baris[0] : baris) as
    { berhasil?: unknown; sisa_percobaan?: unknown; pesan?: unknown } | null | undefined
  return balasan(
    {
      berhasil: hasil?.berhasil === true,
      sisa_percobaan: Number(hasil?.sisa_percobaan ?? 0),
      pesan:
        typeof hasil?.pesan === 'string'
          ? hasil.pesan
          : 'PIN tidak bisa diperiksa sekarang. Coba lagi.',
    },
    200,
    kepala,
  )
})
