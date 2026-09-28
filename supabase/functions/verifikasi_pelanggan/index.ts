// ============================================================================
// Edge Function: verifikasi pelanggan & anti-email palsu (T8-07 — ART-5 & ART-10)
//
// Alur:
//   1. Menerima data pendaftaran pelanggan (nama, email, nomor HP, persetujuan privasi).
//   2. Memeriksa persetujuan pemrosesan data pribadi (UU PDP Pasal 20 & ART-10).
//   3. Memvalidasi format email dan menolak email sementara / sekali-pakai (disposable email).
//   4. Menormalisasi alamat Gmail (menghapus titik dan tag `+`, menyatukan domain googlemail.com).
//   5. Meneruskan ke RPC database `public.daftar_voucher` untuk menjamin atomisitas,
//      pembatasan 1 voucher per kampanye, kuota, serta anggaran kampanye.
// ============================================================================

const ASAL_DIIZINKAN = [
  'https://resto-barokah.fatrizmubarok.workers.dev',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]

const DOMAIN_SEKALI_PAKAI = new Set([
  '10minutemail.com',
  '10minutemail.net',
  '10minutemail.org',
  'burnermail.io',
  'crazymailing.com',
  'dispostable.com',
  'disposablemail.com',
  'emailondeck.com',
  'fakeinbox.com',
  'fakemail.net',
  'fakemailgenerator.com',
  'generator.email',
  'getairmail.com',
  'grr.la',
  'guerrillamail.biz',
  'guerrillamail.com',
  'guerrillamail.de',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamailblock.com',
  'inboxkitten.com',
  'mailcatch.com',
  'maildrop.cc',
  'mailinator.com',
  'mohmal.com',
  'mytemp.email',
  'nada.ltd',
  'sharklasers.com',
  'spam4.me',
  'temp-mail.org',
  'tempail.com',
  'tempmail.com',
  'tempmail.net',
  'throwawaymail.com',
  'trashmail.com',
  'trashmail.net',
  'trashmail.org',
  'yopmail.com',
  'yopmail.net',
])

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
    headers: { ...kepala, 'Content-Type': 'application/json' },
  })
}

function normalisasiEmail(input: string): {
  sah: boolean
  pesan?: string
  email_asli: string
  email_normalisasi?: string
  adalah_sekali_pakai?: boolean
} {
  const emailMentah = (input ?? '').trim()
  if (!emailMentah) {
    return { sah: false, pesan: 'Alamat email tidak boleh kosong.', email_asli: '' }
  }

  const pola = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/
  if (!pola.test(emailMentah)) {
    return { sah: false, pesan: 'Format alamat email tidak sah.', email_asli: emailMentah }
  }

  const bagian = emailMentah.split('@')
  if (bagian.length !== 2) {
    return { sah: false, pesan: 'Format alamat email tidak sah.', email_asli: emailMentah }
  }

  let [lokal, domain] = bagian
  lokal = lokal.toLowerCase()
  domain = domain.toLowerCase()

  if (DOMAIN_SEKALI_PAKAI.has(domain)) {
    return {
      sah: false,
      adalah_sekali_pakai: true,
      pesan: 'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.',
      email_asli: emailMentah,
    }
  }

  if (domain === 'gmail.com' || domain === 'googlemail.com') {
    domain = 'gmail.com'
    const tanpaTag = lokal.split('+')[0] || ''
    lokal = tanpaTag.replace(/\./g, '')
    if (!lokal) {
      return { sah: false, pesan: 'Bagian nama email Gmail tidak sah.', email_asli: emailMentah }
    }
  }

  return {
    sah: true,
    email_asli: emailMentah,
    email_normalisasi: `${lokal}@${domain}`,
    adalah_sekali_pakai: false,
  }
}

Deno.serve(async (req: Request) => {
  const kepala = kepalaCORS(req)
  if (req.method === 'OPTIONS') return new Response('ok', { headers: kepala })
  if (req.method !== 'POST') return balasan({ pesan: 'Metode harus POST.' }, 405, kepala)

  const alamat = Deno.env.get('SUPABASE_URL')
  const kunciPublik = Deno.env.get('SUPABASE_ANON_KEY')
  const token = req.headers.get('Authorization') || `Bearer ${kunciPublik}`

  if (!alamat || !kunciPublik) return balasan({ pesan: 'Peladen belum siap.' }, 500, kepala)

  let isi: unknown
  try {
    isi = await req.json()
  } catch {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400, kepala)
  }

  if (isi === null || typeof isi !== 'object' || Array.isArray(isi)) {
    return balasan({ pesan: 'Permintaan tidak terbaca.' }, 400, kepala)
  }
  const badan = isi as Record<string, unknown>

  const nama = typeof badan['nama'] === 'string' ? badan['nama'].trim() : ''
  const emailInput = typeof badan['email'] === 'string' ? badan['email'].trim() : ''
  const telepon = typeof badan['telepon'] === 'string' ? badan['telepon'].trim() : null
  const alamatPelanggan = typeof badan['alamat'] === 'string' ? badan['alamat'].trim() : null
  const penyewaId = typeof badan['penyewa_id'] === 'string' ? badan['penyewa_id'].trim() : ''
  const kampanyeId = typeof badan['kampanye_id'] === 'string' ? badan['kampanye_id'].trim() : null
  const persetujuanPrivasi = badan['persetujuan_privasi'] === true
  const caraMasuk = typeof badan['cara_masuk'] === 'string' ? badan['cara_masuk'] : 'email'

  // Validasi Persetujuan Privasi UU PDP (T-011, ART-10)
  if (!persetujuanPrivasi) {
    return balasan(
      {
        berhasil: false,
        kode: 'PRIVASI_WAJIB',
        pesan: 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.',
      },
      400,
      kepala,
    )
  }

  // Validasi Nama Pelanggan
  if (!nama) {
    return balasan(
      {
        berhasil: false,
        kode: 'NAMA_WAJIB',
        pesan: 'Nama lengkap wajib diisi.',
      },
      400,
      kepala,
    )
  }

  // Validasi format UUID untuk penyewaId
  const POLA_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  if (!POLA_UUID.test(penyewaId)) {
    return balasan(
      {
        berhasil: false,
        kode: 'PENYEWA_TIDAK_SAH',
        pesan: 'ID penyewa resto tidak sah.',
      },
      400,
      kepala,
    )
  }

  if (kampanyeId !== null && !POLA_UUID.test(kampanyeId)) {
    return balasan(
      {
        berhasil: false,
        kode: 'KAMPANYE_TIDAK_SAH',
        pesan: 'ID kampanye voucher tidak sah.',
      },
      400,
      kepala,
    )
  }

  // Validasi Email & Normalisasi (kecuali didaftarkan kasir tanpa email)
  let emailNormal: string | null = null
  if (caraMasuk !== 'kasir' || emailInput) {
    const hasilValidasi = normalisasiEmail(emailInput)
    if (!hasilValidasi.sah) {
      return balasan(
        {
          berhasil: false,
          kode: hasilValidasi.adalah_sekali_pakai ? 'EMAIL_SEKALI_PAKAI' : 'EMAIL_TIDAK_SAH',
          pesan: hasilValidasi.pesan || 'Format alamat email tidak sah.',
        },
        400,
        kepala,
      )
    }
    emailNormal = hasilValidasi.email_normalisasi || null
  }

  // Panggil RPC database `daftar_voucher`
  const gagalDiperiksa = {
    berhasil: false,
    kode: 'JARINGAN_GAGAL',
    pesan: 'Layanan pendaftaran voucher tidak dapat dihubungi sekarang. Silakan coba lagi.',
  }

  let jawab: Response
  try {
    jawab = await fetch(`${alamat}/rest/v1/rpc/daftar_voucher`, {
      method: 'POST',
      headers: {
        apikey: kunciPublik,
        Authorization: token,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        p_penyewa_id: penyewaId,
        p_kampanye_id: kampanyeId,
        p_nama: nama,
        p_email: emailInput || null,
        p_telepon: telepon,
        p_alamat: alamatPelanggan,
        p_persetujuan_privasi: persetujuanPrivasi,
        p_cara_masuk: caraMasuk,
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
    | { berhasil?: boolean; kode?: string; pesan?: string; data?: unknown }
    | null
    | undefined

  return balasan(
    {
      berhasil: hasil?.berhasil === true,
      kode: typeof hasil?.kode === 'string' ? hasil.kode : 'SUKSES',
      pesan:
        typeof hasil?.pesan === 'string'
          ? hasil.pesan
          : 'Pendaftaran voucher berhasil diproses.',
      data: hasil?.data ?? { email_normalisasi: emailNormal },
    },
    200,
    kepala,
  )
})
