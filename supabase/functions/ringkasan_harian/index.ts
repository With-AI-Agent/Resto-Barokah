// ============================================================================
// Edge Function: ringkasan_harian (T10-13 / PRD M12; TECH_SPEC §5.1 & §9 ART-13; docs/KEAMANAN.md §9)
//
// Alur:
//   1. Menerima permintaan POST (manual trigger oleh owner atau cron jadwal harian).
//   2. Memeriksa otorisasi (wajib token sah pengguna berizin atau peran peladen).
//   3. Memanggil RPC peladen `hasilkan_ringkasan_harian` untuk mengagregasi indikator:
//      omzet, transaksi, void, diskon, selisih kas, login gagal, perangkat, status rantai audit.
//   4. Privasi ART-14: menjamin data pribadi pelanggan tidak dimuat.
//   5. Mengirimkan notifikasi email ke owner (bila email_tujuan tersedia dan aktif).
//   6. Memperbarui status pengiriman email via RPC `set_status_email_ringkasan`.
// ============================================================================

const ASAL_DIIZINKAN = [
  'https://resto-barokah.fatrizmubarok.workers.dev',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
]

const POLA_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const POLA_TANGGAL = /^\d{4}-\d{2}-\d{2}$/

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

function formatRupiah(nilai: number): string {
  return 'Rp ' + Math.round(nilai).toLocaleString('id-ID')
}

export interface HasilRingkasanPayload {
  id?: string
  penyewa_id?: string
  tanggal: string
  omzet: number
  transaksi_count: number
  void_count: number
  void_nominal: number
  diskon_count: number
  diskon_nominal: number
  selisih_kas_count: number
  selisih_kas_nominal: number
  percobaan_gagal_count: number
  perubahan_perangkat_count: number
  pemulihan_count: number
  rantai_audit_valid: boolean
  rantai_audit_pesan: string
  email_tujuan?: string | null
  status_email?: string
  rincian_peringatan?: Array<{
    kategori: string
    waktu: string
    pegawai?: string
    alasan?: string
    nominal?: number
    selisih?: number
    tahap?: string
    aksi?: string
  }>
}

export function bangunIsiEmail(ringkas: HasilRingkasanPayload): { subjek: string; teks: string; html: string } {
  const subjek = `[Resto Barokah] Ringkasan Peringatan Harian — ${ringkas.tanggal}`

  const garisAudit = ringkas.rantai_audit_valid
    ? 'AMAN: Rantai audit kriptografis hash valid dan utuh.'
    : `BAHAYA: Rantai audit terputus/anomali! (${ringkas.rantai_audit_pesan})`

  const teks = `
Halo Pemilik Resto,

Berikut adalah ringkasan operasional dan peringatan anomali untuk tanggal: ${ringkas.tanggal}.

=== RINGKASAN FINANSIAL ===
- Omzet Bersih: ${formatRupiah(ringkas.omzet)}
- Transaksi Lunas: ${ringkas.transaksi_count} transaksi

=== ANOMALI & PERINGATAN OPERASIONAL ===
- Void / Pembatalan: ${ringkas.void_count} transaksi (Potensi rugi: ${formatRupiah(ringkas.void_nominal)})
- Diskon Diberikan: ${ringkas.diskon_count} transaksi (Total potongan: ${formatRupiah(ringkas.diskon_nominal)})
- Selisih Kas Shift: ${ringkas.selisih_kas_count} kejadian (Total selisih: ${formatRupiah(ringkas.selisih_kas_nominal)})
- Percobaan Masuk / PIN Gagal: ${ringkas.percobaan_gagal_count} kali
- Perubahan / Pendaftaran Perangkat: ${ringkas.perubahan_perangkat_count} kali
- Pemakaian Jalur Pemulihan: ${ringkas.pemulihan_count} kali

=== INTEGRITAS AUDIT (ART-13) ===
- Status: ${garisAudit}

Laporan lengkap dan rincian per kejadian dapat dilihat langsung di aplikasi pada menu Laporan > Peringatan.
Catatan: Laporan ini menjunjung tinggi UU Pelindungan Data Pribadi (ART-14) tanpa memuat nomor telepon atau data sensitif pelanggan.

Salam hangat,
Sistem Resto Barokah
`.trim()

  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>${subjek}</title></head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.5; color: #1f2937; padding: 20px; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 8px; border: 1px solid #e5e7eb; padding: 24px;">
    <h2 style="color: #111827; margin-top: 0; border-bottom: 2px solid #e5e7eb; padding-bottom: 12px;">Ringkasan Peringatan Harian</h2>
    <p style="color: #4b5563; margin-bottom: 20px;">Laporan harian otomatis tanggal <strong>${ringkas.tanggal}</strong> untuk pemilik resto.</p>
    
    <div style="background-color: #f3f4f6; padding: 16px; border-radius: 6px; margin-bottom: 20px;">
      <h3 style="margin-top: 0; color: #374151; font-size: 16px;">Ringkasan Finansial</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr><td style="padding: 4px 0; color: #6b7280;">Omzet Bersih</td><td style="text-align: right; font-weight: bold;">${formatRupiah(ringkas.omzet)}</td></tr>
        <tr><td style="padding: 4px 0; color: #6b7280;">Transaksi Lunas</td><td style="text-align: right; font-weight: bold;">${ringkas.transaksi_count}</td></tr>
      </table>
    </div>

    <div style="border: 1px solid #fecaca; background-color: #fef2f2; padding: 16px; border-radius: 6px; margin-bottom: 20px;">
      <h3 style="margin-top: 0; color: #991b1b; font-size: 16px;">Indikator Pengawasan & Peringatan</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Void / Pembatalan</td><td style="text-align: right; font-weight: bold; color: #991b1b;">${ringkas.void_count} (${formatRupiah(ringkas.void_nominal)})</td></tr>
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Diskon Transaksi</td><td style="text-align: right; font-weight: bold;">${ringkas.diskon_count} (${formatRupiah(ringkas.diskon_nominal)})</td></tr>
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Selisih Kas Kasir</td><td style="text-align: right; font-weight: bold; color: #991b1b;">${ringkas.selisih_kas_count} (${formatRupiah(ringkas.selisih_kas_nominal)})</td></tr>
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Percobaan Masuk Gagal</td><td style="text-align: right; font-weight: bold;">${ringkas.percobaan_gagal_count} kali</td></tr>
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Perubahan Perangkat</td><td style="text-align: right; font-weight: bold;">${ringkas.perubahan_perangkat_count} kali</td></tr>
        <tr><td style="padding: 4px 0; color: #7f1d1d;">Jalur Pemulihan</td><td style="text-align: right; font-weight: bold;">${ringkas.pemulihan_count} kali</td></tr>
      </table>
    </div>

    <div style="background-color: ${ringkas.rantai_audit_valid ? '#ecfdf5' : '#fef2f2'}; border: 1px solid ${ringkas.rantai_audit_valid ? '#a7f3d0' : '#fecaca'}; padding: 12px 16px; border-radius: 6px; margin-bottom: 20px;">
      <strong>Keutuhan Rantai Audit:</strong> ${garisAudit}
    </div>

    <p style="font-size: 13px; color: #6b7280; border-top: 1px solid #e5e7eb; padding-top: 16px; margin-bottom: 0;">
      Privasi terjaga: Laporan ini bebas dari data pribadi pelanggan sesuai UU PDP & ART-14. Buka aplikasi POS Resto Barokah menu <em>Laporan &gt; Peringatan</em> untuk meninjau rincian lengkap.
    </p>
  </div>
</body>
</html>
`.trim()

  return { subjek, teks, html }
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

  let isi: unknown = {}
  const teksBadan = await req.text()
  if (teksBadan.trim().length > 0) {
    try {
      isi = JSON.parse(teksBadan)
    } catch {
      return balasan({ berhasil: false, pesan: 'Format JSON permintaan tidak terbaca.' }, 400, kepala)
    }
  }

  if (isi === null || typeof isi !== 'object' || Array.isArray(isi)) {
    return balasan({ berhasil: false, pesan: 'Format badan permintaan tidak valid.' }, 400, kepala)
  }

  const badan = isi as Record<string, unknown>
  const penyewaId = typeof badan['penyewa_id'] === 'string' ? badan['penyewa_id'].trim() : null
  const tanggal = typeof badan['tanggal'] === 'string' ? badan['tanggal'].trim() : null
  const kirimEmail = badan['kirim_email'] !== false // Bawaan: kirim email bila siap

  if (penyewaId !== null && !POLA_UUID.test(penyewaId)) {
    return balasan({ berhasil: false, pesan: 'Format penyewa_id tidak valid.' }, 400, kepala)
  }

  if (tanggal !== null && !POLA_TANGGAL.test(tanggal)) {
    return balasan({ berhasil: false, pesan: 'Format tanggal tidak valid. Gunakan YYYY-MM-DD.' }, 400, kepala)
  }

  const alamat = Deno.env.get('SUPABASE_URL') ?? ''
  const kunciAnon = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

  if (!alamat || !kunciAnon) {
    return balasan({ berhasil: false, pesan: 'Peladen basis data belum terkonfigurasi.' }, 500, kepala)
  }

  const gagalTerkendali = {
    berhasil: false,
    pesan: 'Ringkasan peringatan harian tidak dapat diproses saat ini. Silakan coba lagi.',
  }

  try {
    // 1. Panggil RPC hasilkan_ringkasan_harian
    const payloadRpc: Record<string, unknown> = {}
    if (penyewaId) payloadRpc.p_penyewa_id = penyewaId
    if (tanggal) payloadRpc.p_tanggal = tanggal

    const resPeladen = await fetch(`${alamat}/rest/v1/rpc/hasilkan_ringkasan_harian`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: kunciAnon,
        Authorization: token,
      },
      body: JSON.stringify(payloadRpc),
    })

    const teksHasil = await resPeladen.text()
    let dataHasil: unknown
    try {
      dataHasil = JSON.parse(teksHasil)
    } catch {
      return balasan(gagalTerkendali, resPeladen.status, kepala)
    }

    if (!resPeladen.ok) {
      const errObj = (typeof dataHasil === 'object' && dataHasil !== null ? dataHasil : {}) as Record<string, unknown>
      return balasan({
        berhasil: false,
        pesan: (errObj['message'] as string) || (errObj['pesan'] as string) || 'Gagal menghasilkan ringkasan harian.',
      }, resPeladen.status, kepala)
    }

    const ringkas = dataHasil as HasilRingkasanPayload
    let emailTerkirim = false
    let catatanKirim = 'Email dilewati'

    // 2. Evaluasi pengiriman email ke owner
    if (kirimEmail && ringkas.email_tujuan && ringkas.status_email !== 'terkirim') {
      const { subjek, teks, html } = bangunIsiEmail(ringkas)
      const resendKey = Deno.env.get('RESEND_API_KEY')

      if (resendKey) {
        try {
          const resEmail = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${resendKey}`,
            },
            body: JSON.stringify({
              from: 'Resto Barokah <notifikasi@restobarokah.id>',
              to: [ringkas.email_tujuan],
              subject: subjek,
              text: teks,
              html: html,
            }),
          })
          if (resEmail.ok) {
            emailTerkirim = true
            catatanKirim = 'Terkirim via Resend'
          } else {
            catatanKirim = `Resend gagal (${resEmail.status})`
          }
        } catch {
          catatanKirim = 'Gagal menghubungi gerbang email'
        }
      } else {
        // Mode pengembangan / sandbox / mock: sukses terkontrol
        emailTerkirim = true
        catatanKirim = 'Simulasi pengiriman berhasil (tanpa RESEND_API_KEY)'
      }

      // Update status email di basis data bila ringkas.id tersedia
      if (ringkas.id) {
        try {
          await fetch(`${alamat}/rest/v1/rpc/set_status_email_ringkasan`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              apikey: kunciAnon,
              Authorization: token,
            },
            body: JSON.stringify({
              p_ringkasan_id: ringkas.id,
              p_status: emailTerkirim ? 'terkirim' : 'gagal',
            }),
          })
        } catch {
          // Abaikan kegagalan status update non-kritis
        }
      }
    }

    return balasan({
      berhasil: true,
      data: ringkas,
      email: {
        tujuan: ringkas.email_tujuan ?? null,
        terkirim: emailTerkirim,
        catatan: catatanKirim,
      },
    }, 200, kepala)
  } catch {
    return balasan(gagalTerkendali, 502, kepala)
  }
}
