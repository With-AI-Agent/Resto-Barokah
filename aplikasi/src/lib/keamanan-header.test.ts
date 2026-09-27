import { describe, it, expect } from 'vitest'
import fs from 'node:fs'
import path from 'node:path'

describe('Header Keamanan & Content-Security-Policy (T10-14 / TECH_SPEC §6 & §8 / docs/KEAMANAN.md §16)', () => {
  const jalurHeaders = path.resolve(__dirname, '../../public/_headers')

  it('berkas _headers ada di folder public aplikasi', () => {
    expect(fs.existsSync(jalurHeaders)).toBe(true)
  })

  it('memuat aturan global /* dengan seluruh header keamanan esensial', () => {
    const isi = fs.readFileSync(jalurHeaders, 'utf-8')
    expect(isi).toContain('X-Frame-Options: DENY')
    expect(isi).toContain('X-Content-Type-Options: nosniff')
    expect(isi).toContain('Referrer-Policy: strict-origin-when-cross-origin')
    expect(isi).toContain('Strict-Transport-Security: max-age=31536000; includeSubDomains; preload')
    expect(isi).toContain('Permissions-Policy:')
    expect(isi).toContain('Content-Security-Policy:')
  })

  it('Permissions-Policy mengizinkan kamera untuk scan voucher dan memblokir fitur tak berizin', () => {
    const isi = fs.readFileSync(jalurHeaders, 'utf-8')
    expect(isi).toMatch(/Permissions-Policy:.*camera=\(self\)/)
    expect(isi).toMatch(/microphone=\(\)/)
    expect(isi).toMatch(/geolocation=\(\)/)
  })

  it('Content-Security-Policy membatasi sumber script, style, font, connect, dan anti-clickjacking', () => {
    const isi = fs.readFileSync(jalurHeaders, 'utf-8')
    const barisCsp = isi
      .split('\n')
      .find((b: string) => b.trim().startsWith('Content-Security-Policy:'))
    expect(barisCsp).toBeDefined()

    const csp = barisCsp || ''
    // Anti clickjacking dan sandbox
    expect(csp).toContain("frame-ancestors 'none'")
    expect(csp).toContain("object-src 'none'")
    expect(csp).toContain("base-uri 'self'")

    // Script dan Style
    expect(csp).toContain("default-src 'self'")
    expect(csp).toContain("script-src 'self'")
    expect(csp).not.toContain("script-src 'self' 'unsafe-inline'")
    expect(csp).not.toContain('unsafe-eval')
    expect(csp).not.toContain('script-src *')
    expect(csp).toContain("style-src 'self' 'unsafe-inline'")

    // Font dan Gambar
    expect(csp).toContain("font-src 'self' data:")
    expect(csp).toContain("img-src 'self' data: blob: https:")

    // Anti-XSS & Request Form
    expect(csp).toContain('upgrade-insecure-requests')
    expect(csp).toContain("form-action 'self'")

    // Koneksi resmi
    expect(csp).toContain('connect-src')
    expect(csp).toContain('https://*.supabase.co')
    expect(csp).toContain('wss://*.supabase.co')
    expect(csp).toContain('https://*.workers.dev')
    expect(csp).toContain('https://api.resend.com')
  })

  it('memuat optimasi Cache-Control immutable untuk berkas kompilasi /assets/*', () => {
    const isi = fs.readFileSync(jalurHeaders, 'utf-8')
    expect(isi).toContain('/assets/*')
    expect(isi).toContain('Cache-Control: public, max-age=31536000, immutable')
  })
})
