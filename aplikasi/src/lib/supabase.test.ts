import { afterEach, describe, expect, it, vi } from 'vitest'
import { alamatSupabaseSah, klienSupabase, ujiSambungan } from './supabase'

/**
 * Jawaban tiruan bergaya `fetch` — hanya status yang dipakai kode.
 *
 * Sejak temuan F F-14 / I F-05, uji WAJIB bisa memberi status BERBEDA per jalur:
 * dulu `jawab(200)` mengirim 200 ke dua jalur sekaligus, sehingga kombinasi
 * "Auth sehat tetapi jalur data gagal" tidak pernah teruji sama sekali.
 */
function jawab(status: number): typeof fetch {
  return jawabJalur({ sehat: status, data: status })
}

/** Status berbeda untuk jalur kesehatan Auth (`/auth/v1/health`) dan data (`/rest/v1/`). */
function jawabJalur(opsi: { sehat: number; data: number }): typeof fetch {
  return ((url: string) =>
    Promise.resolve(
      new Response('{}', { status: url.includes('/auth/v1/health') ? opsi.sehat : opsi.data }),
    )) as unknown as typeof fetch
}

function gagalJaringan(pesan: string): typeof fetch {
  return (() => Promise.reject(new Error(pesan))) as unknown as typeof fetch
}

function isiEnv(): void {
  vi.stubEnv('VITE_SUPABASE_URL', 'https://contoh-proyek.supabase.co')
  vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'sb_publishable_contoh')
}

afterEach(() => {
  vi.unstubAllEnvs()
})

describe('alamatSupabaseSah', () => {
  it('menerima alamat proyek Supabase (dengan atau tanpa garis miring di ujung)', () => {
    expect(alamatSupabaseSah('https://abcdefghijklm.supabase.co')).toBe(true)
    expect(alamatSupabaseSah('https://abcdefghijklm.supabase.co/')).toBe(true)
    expect(alamatSupabaseSah('  https://abc-123.supabase.co  ')).toBe(true)
  })

  it('menolak alamat lain supaya kunci tidak dikirim ke server asing', () => {
    expect(alamatSupabaseSah('')).toBe(false)
    expect(alamatSupabaseSah('http://abcdefghijklm.supabase.co')).toBe(false)
    expect(alamatSupabaseSah('https://contoh.example.com')).toBe(false)
    expect(alamatSupabaseSah('https://supabase.co.evil.example')).toBe(false)
    expect(alamatSupabaseSah('bukan-alamat')).toBe(false)
  })
})

describe('klienSupabase', () => {
  it('mengembalikan null (tidak meledak) saat pengaturan belum diisi', () => {
    expect(klienSupabase()).toBeNull()
  })

  it('mengembalikan null saat alamatnya bukan proyek Supabase', () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://contoh.example.com')
    vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'sb_publishable_contoh')
    expect(klienSupabase()).toBeNull()
  })

  it('membuat klien dari dua nilai publik saja saat pengaturan lengkap', () => {
    isiEnv()
    const klien = klienSupabase()
    expect(klien).not.toBeNull()
    // `supabaseUrl` dilindungi TypeScript; dibaca lewat cast hanya untuk bukti alamat yang dipakai.
    const dipakai = (klien as unknown as { supabaseUrl: string }).supabaseUrl
    expect(dipakai).toBe('https://contoh-proyek.supabase.co')
    // Dipanggil dua kali tetap klien yang sama (tidak membuat koneksi baru tiap kali).
    expect(klienSupabase()).toBe(klien)
  })
})

describe('ujiSambungan', () => {
  it('memberi tahu pengaturan mana yang belum diisi (tanpa jaringan)', async () => {
    const hasil = await ujiSambungan({ fetchUji: gagalJaringan('tidak boleh dipanggil') })
    expect(hasil.ok).toBe(false)
    expect(hasil.pesan).toContain('VITE_SUPABASE_URL')
    expect(hasil.rincian).toEqual([])
  })

  it('menolak alamat yang tidak sah sebelum memanggil jaringan', async () => {
    vi.stubEnv('VITE_SUPABASE_URL', 'https://contoh.example.com')
    vi.stubEnv('VITE_SUPABASE_ANON_KEY', 'sb_publishable_contoh')
    const hasil = await ujiSambungan({ fetchUji: gagalJaringan('tidak boleh dipanggil') })
    expect(hasil.ok).toBe(false)
    expect(hasil.pesan).toContain('supabase.co')
  })

  it('LULUS hanya saat layanan masuk DAN layanan data dua-duanya menjawab 200', async () => {
    isiEnv()
    const hasil = await ujiSambungan({ fetchUji: jawab(200) })
    expect(hasil.ok).toBe(true)
    expect(hasil.jalur).toEqual({ auth: true, data: true })
    expect(hasil.pesan).toContain('layanan data')
    expect(hasil.rincian.join(' ')).toContain('/auth/v1/health → HTTP 200')
    expect(hasil.rincian.join(' ')).toContain('/rest/v1/ → HTTP 200')
  })

  // Inti temuan F F-14 / I F-05: layanan masuk sehat BUKAN bukti sambungan siap pakai.
  for (const [sebutan, statusData] of [
    ['kunci publik ditolak (401)', 401],
    ['kunci publik ditolak (403)', 403],
    ['layanan data rusak (500)', 500],
    ['layanan data tidak ditemukan (404)', 404],
    ['layanan data dijeda (503)', 503],
  ] as const) {
    it(`GAGAL saat layanan masuk sehat tetapi jalur data ${sebutan}`, async () => {
      isiEnv()
      const hasil = await ujiSambungan({ fetchUji: jawabJalur({ sehat: 200, data: statusData }) })
      expect(hasil.ok).toBe(false)
      expect(hasil.jalur).toEqual({ auth: true, data: false })
      expect(hasil.pesan).toContain(`HTTP ${statusData}`)
      expect(hasil.pesan).toContain('layanan data')
      expect(hasil.pesan).not.toContain('berhasil memakai kunci publik')
    })
  }

  it('GAGAL saat layanan masuk sehat tetapi jalur data tidak bisa dihubungi', async () => {
    isiEnv()
    const hasil = await ujiSambungan({
      fetchUji: ((url: string) =>
        url.includes('/auth/v1/health')
          ? Promise.resolve(new Response('{}', { status: 200 }))
          : Promise.reject(new Error('getaddrinfo ENOTFOUND'))) as unknown as typeof fetch,
    })
    expect(hasil.ok).toBe(false)
    expect(hasil.pesan).toContain('HTTP 0')
    expect(hasil.rincian.join(' ')).toContain('ENOTFOUND')
  })

  it('GAGAL saat layanan masuk sehat tetapi jalur data menjawab 200 hanya untuk sebagian (206)', async () => {
    // 206 memang "terbaca", tetapi akar PostgREST tidak mengirimnya; yang penting di sini
    // hanya bahwa status SELAIN 200 tidak dianggap siap tanpa alasan.
    isiEnv()
    const hasil = await ujiSambungan({ fetchUji: jawabJalur({ sehat: 200, data: 206 }) })
    expect(hasil.ok).toBe(false)
    expect(hasil.jalur.data).toBe(false)
  })

  it('GAGAL dengan pesan kunci saat Supabase menolak kunci publik (401)', async () => {
    isiEnv()
    const hasil = await ujiSambungan({ fetchUji: jawab(401) })
    expect(hasil.ok).toBe(false)
    expect(hasil.pesan).toContain('VITE_SUPABASE_ANON_KEY')
  })

  it('GAGAL dengan pesan jaringan saat sambungan putus', async () => {
    isiEnv()
    const hasil = await ujiSambungan({ fetchUji: gagalJaringan('getaddrinfo ENOTFOUND') })
    expect(hasil.ok).toBe(false)
    expect(hasil.pesan).toContain('tidak menjawab')
    expect(hasil.rincian.join(' ')).toContain('ENOTFOUND')
  })

  it('selalu mengisi `jalur` supaya pemanggil tahu bagian mana yang gagal', async () => {
    const kosong = await ujiSambungan({ fetchUji: gagalJaringan('tidak boleh dipanggil') })
    expect(kosong.jalur).toEqual({ auth: false, data: false })
  })
})
