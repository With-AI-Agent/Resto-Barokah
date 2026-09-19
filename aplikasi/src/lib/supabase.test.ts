import { afterEach, describe, expect, it, vi } from 'vitest'
import { alamatSupabaseSah, klienSupabase, ujiSambungan } from './supabase'

/** Jawaban tiruan bergaya `fetch` — hanya status yang dipakai kode. */
function jawab(status: number): typeof fetch {
  return (() => Promise.resolve(new Response('{}', { status }))) as unknown as typeof fetch
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

  it('LULUS saat layanan kesehatan menjawab 200', async () => {
    isiEnv()
    const hasil = await ujiSambungan({ fetchUji: jawab(200) })
    expect(hasil.ok).toBe(true)
    expect(hasil.rincian.join(' ')).toContain('/auth/v1/health → HTTP 200')
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
})
