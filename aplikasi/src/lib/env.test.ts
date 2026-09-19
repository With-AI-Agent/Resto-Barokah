import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  NAMA_KLIEN,
  alamatSupabase,
  envLengkap,
  kunciAnonSupabase,
  pesanEnvKurang,
  statusEnv,
} from './env'

/**
 * Uji pembacaan pengaturan (T0-10).
 * Yang dijaga di sini: aplikasi tidak boleh meledak saat pengaturan belum diisi
 * (keadaan sebelum pemilik menyelesaikan T0-00), dan pesan bahasa Indonesia
 * benar-benar menyebut nama variabel yang kurang.
 */

function pasang(nilai: Partial<Record<string, string>>) {
  for (const nama of NAMA_KLIEN) {
    vi.stubEnv(nama, nilai[nama] ?? '')
  }
}

afterEach(() => {
  vi.unstubAllEnvs()
})

describe('statusEnv', () => {
  it('melaporkan kedua nilai belum diisi saat kosong', () => {
    pasang({})
    expect(statusEnv()).toEqual([
      { nama: 'VITE_SUPABASE_URL', terisi: false },
      { nama: 'VITE_SUPABASE_ANON_KEY', terisi: false },
    ])
    expect(envLengkap()).toBe(false)
  })

  it('melaporkan terisi setelah nilai diisi', () => {
    pasang({
      VITE_SUPABASE_URL: 'https://contoh.supabase.co',
      VITE_SUPABASE_ANON_KEY: 'kunci-anon',
    })
    expect(envLengkap()).toBe(true)
    expect(alamatSupabase()).toBe('https://contoh.supabase.co')
    expect(kunciAnonSupabase()).toBe('kunci-anon')
  })

  it('spasi berlebih dianggap kosong/tidak dihitung', () => {
    pasang({ VITE_SUPABASE_URL: '   ', VITE_SUPABASE_ANON_KEY: '  kunci  ' })
    const status = statusEnv()
    expect(status[0].terisi).toBe(false)
    expect(status[1].terisi).toBe(true)
    expect(kunciAnonSupabase()).toBe('kunci')
  })
})

describe('pesanEnvKurang', () => {
  it('menyebut nama variabel yang belum diisi', () => {
    pasang({ VITE_SUPABASE_URL: 'https://contoh.supabase.co' })
    const pesan = pesanEnvKurang()
    expect(pesan).toContain('VITE_SUPABASE_ANON_KEY')
    expect(pesan).toContain('.env.example')
    expect(pesan).not.toContain('VITE_SUPABASE_URL,')
  })

  it('kosong bila pengaturan sudah lengkap', () => {
    pasang({ VITE_SUPABASE_URL: 'https://contoh.supabase.co', VITE_SUPABASE_ANON_KEY: 'kunci' })
    expect(pesanEnvKurang()).toBe('')
  })
})
