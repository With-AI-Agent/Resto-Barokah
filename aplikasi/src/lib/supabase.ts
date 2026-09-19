/**
 * Klien Supabase (tugas ROADMAP T0-08).
 *
 * Aturan yang mengikat berkas ini:
 *  - Hanya DUA nilai publik yang boleh masuk ke sini — `VITE_SUPABASE_URL` dan
 *    `VITE_SUPABASE_ANON_KEY` (`docs/TECH_SPEC.md` §6). Kunci rahasia
 *    (`service_role`, Resend, Cloudflare) TIDAK PERNAH ada di aplikasi ini.
 *  - Fungsi di sini **tidak meledak** saat nilai belum diisi: `klienSupabase()`
 *    mengembalikan `null`, dan layar yang membutuhkannya menampilkan
 *    `pesanEnvKurang()` lewat komponen KeadaanGagal. Ini yang membuat aplikasi
 *    tetap bisa dibuka sebelum T0-00 selesai (dan saat pengembangan lokal).
 *  - `ujiSambungan()` sengaja memakai dua jalur **tanpa data** (kesehatan Auth
 *    dan akar PostgREST). Jadi uji sambung bisa LULUS walaupun tabel aslinya
 *    belum ada — atau belum boleh dibaca kunci publik (RLS). Yang dibuktikan
 *    hanyalah: alamat benar, kunci publik diterima, jaringan sampai.
 */
import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import { alamatSupabase, envLengkap, kunciAnonSupabase, pesanEnvKurang } from './env'

/** Batas tunggu tiap percobaan jaringan (milidetik). */
export const BATAS_TUNGGU_MS = 10_000

/** Jalur kesehatan Supabase Auth — publik, tidak membuka satu baris data pun. */
const JALUR_SEHAT = '/auth/v1/health'

/** Akar PostgREST — menjawab 200 kalau kunci publik diterima. */
const JALUR_DATA = '/rest/v1/'

/** Apakah nilai alamat berbentuk alamat proyek Supabase yang sah? */
export function alamatSupabaseSah(nilai: string): boolean {
  return /^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(nilai.trim().replace(/\/+$/, ''))
}

let klienTersimpan: SupabaseClient | null = null

/**
 * Klien Supabase, atau `null` kalau pengaturan belum lengkap/sah.
 * Hasil yang berhasil disimpan supaya tidak membuat koneksi baru tiap dipanggil.
 */
export function klienSupabase(): SupabaseClient | null {
  if (klienTersimpan) return klienTersimpan
  if (!envLengkap()) return null
  const alamat = alamatSupabase().trim().replace(/\/+$/, '')
  if (!alamatSupabaseSah(alamat)) return null
  klienTersimpan = createClient(alamat, kunciAnonSupabase(), {
    auth: { persistSession: true, autoRefreshToken: true },
  })
  return klienTersimpan
}

export type HasilSambungan = {
  ok: boolean
  /** Kalimat bahasa Indonesia siap tampil ke pemilik/pegawai. */
  pesan: string
  /** Rincian teknis per percobaan (untuk layar diagnosa & catatan bukti). */
  rincian: string[]
}

async function panggil(
  ambil: typeof fetch,
  alamat: string,
  kunci: string,
  jalur: string,
): Promise<{ status: number; rincian: string }> {
  const mulai = Date.now()
  try {
    const jawab = await ambil(`${alamat}${jalur}`, {
      headers: { apikey: kunci, Authorization: `Bearer ${kunci}` },
      signal: AbortSignal.timeout(BATAS_TUNGGU_MS),
    })
    return {
      status: jawab.status,
      rincian: `${jalur} → HTTP ${jawab.status} (${Date.now() - mulai} ms)`,
    }
  } catch (e) {
    const sebab = e instanceof Error ? e.message : String(e)
    return { status: 0, rincian: `${jalur} → gagal (${Date.now() - mulai} ms): ${sebab}` }
  }
}

/**
 * Uji sambung memakai kunci publik saja.
 *
 * `opsi.fetchUji` dipakai uji otomatis supaya tidak ada jaringan sungguhan saat
 * `npm test` (dan supaya jawaban 401/putus jaringan bisa diuji).
 */
export async function ujiSambungan(
  opsi: { fetchUji?: typeof fetch } = {},
): Promise<HasilSambungan> {
  if (!envLengkap()) {
    return { ok: false, pesan: pesanEnvKurang(), rincian: [] }
  }
  const alamat = alamatSupabase().trim().replace(/\/+$/, '')
  if (!alamatSupabaseSah(alamat)) {
    return {
      ok: false,
      pesan: `Alamat Supabase tidak berbentuk https://<proyek>.supabase.co — sekarang: ${alamat}`,
      rincian: [],
    }
  }
  const ambil = opsi.fetchUji ?? fetch
  const kunci = kunciAnonSupabase()
  const sehat = await panggil(ambil, alamat, kunci, JALUR_SEHAT)
  const data = await panggil(ambil, alamat, kunci, JALUR_DATA)
  const rincian = [sehat.rincian, data.rincian]

  if (sehat.status === 200) {
    return {
      ok: true,
      pesan: 'Sambungan ke Supabase berhasil memakai kunci publik saja.',
      rincian,
    }
  }
  if (sehat.status === 401 || sehat.status === 403) {
    return {
      ok: false,
      pesan: 'Supabase menolak kunci publik ini. Periksa VITE_SUPABASE_ANON_KEY di berkas .env.',
      rincian,
    }
  }
  return {
    ok: false,
    pesan:
      'Supabase tidak menjawab. Periksa alamat VITE_SUPABASE_URL, sambungan internet, atau apakah proyeknya dijeda.',
    rincian,
  }
}
