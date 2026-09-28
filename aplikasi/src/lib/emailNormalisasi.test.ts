import { describe, it, expect } from 'vitest'
import {
  normalisasiEmail,
  apakahEmailSekaliPakai,
  bersihkanGmail,
  DOMAIN_SEKALI_PAKAI,
} from './emailNormalisasi'

describe('emailNormalisasi (T8-07 — ART-5 & ART-10)', () => {
  it('Kasus 1: Email asli valid diproses dan dinormalisasi huruf kecil', () => {
    const hasil = normalisasiEmail('Pelanggan.Oasis@kedai-oasis.id')
    expect(hasil.sah).toBe(true)
    expect(hasil.email_normalisasi).toBe('pelanggan.oasis@kedai-oasis.id')
    expect(hasil.email_asli).toBe('Pelanggan.Oasis@kedai-oasis.id')
    expect(hasil.domain).toBe('kedai-oasis.id')
    expect(hasil.adalah_sekali_pakai).toBe(false)
  })

  it('Kasus 2: Email sekali-pakai / sementara (disposable) ditolak tegas', () => {
    const daftarContoh = [
      'budi@10minutemail.com',
      'ani@tempmail.com',
      'user@mailinator.com',
      'diskon@guerrillamail.com',
      'test@trashmail.com',
      'akun@yopmail.com',
    ]

    for (const email of daftarContoh) {
      const hasil = normalisasiEmail(email)
      expect(hasil.sah).toBe(false)
      expect(hasil.adalah_sekali_pakai).toBe(true)
      expect(hasil.pesan).toMatch(/Email sementara atau sekali-pakai tidak diizinkan/i)
      expect(apakahEmailSekaliPakai(email)).toBe(true)
    }
  })

  it('Kasus 3: Gmail bertitik dinormalisasi (titik diabaikan)', () => {
    const hasil = normalisasiEmail('b.u.d.i.santoso@gmail.com')
    expect(hasil.sah).toBe(true)
    expect(hasil.email_normalisasi).toBe('budisantoso@gmail.com')
    expect(hasil.domain).toBe('gmail.com')
  })

  it('Kasus 4: Gmail dengan tag plus dinormalisasi (sub-addressing diabaikan)', () => {
    const hasil = normalisasiEmail('budisantoso+promo123@gmail.com')
    expect(hasil.sah).toBe(true)
    expect(hasil.email_normalisasi).toBe('budisantoso@gmail.com')
    expect(hasil.domain).toBe('gmail.com')
  })

  it('Kasus 4b: Kombinasi titik, tanda plus, dan domain googlemail.com', () => {
    const hasil = normalisasiEmail('B.u.d.i.Santoso+diskon.kedai@googlemail.com')
    expect(hasil.sah).toBe(true)
    expect(hasil.email_normalisasi).toBe('budisantoso@gmail.com')
    expect(hasil.domain).toBe('gmail.com')
  })

  it('Kasus 5: Email kosong atau spasi ditolak dengan pesan yang jelas', () => {
    const kosong1 = normalisasiEmail('')
    expect(kosong1.sah).toBe(false)
    expect(kosong1.pesan).toMatch(/tidak boleh kosong/i)

    const kosong2 = normalisasiEmail('   ')
    expect(kosong2.sah).toBe(false)
    expect(kosong2.pesan).toMatch(/tidak boleh kosong/i)
  })

  it('Kasus 6: Format email salah / tidak valid ditolak', () => {
    const daftarSalah = [
      'budi',
      'budi@',
      '@gmail.com',
      'budi@@gmail.com',
      'budi@gmail',
      'budi santoso@gmail.com',
      'budi@.com',
    ]

    for (const email of daftarSalah) {
      const hasil = normalisasiEmail(email)
      expect(hasil.sah).toBe(false)
      expect(hasil.pesan).toMatch(/Format alamat email tidak sah/i)
    }
  })

  it('Fungsi pembantu: bersihkanGmail bekerja mandiri dengan benar', () => {
    expect(bersihkanGmail('b.u.d.i')).toBe('budi')
    expect(bersihkanGmail('budi+promo')).toBe('budi')
    expect(bersihkanGmail('b.u.d.i+voucher+kedai')).toBe('budi')
    expect(bersihkanGmail('')).toBe('')
  })

  it('Daftar domain sekali-pakai memiliki cakupan domain populer', () => {
    expect(DOMAIN_SEKALI_PAKAI.has('10minutemail.com')).toBe(true)
    expect(DOMAIN_SEKALI_PAKAI.has('mailinator.com')).toBe(true)
    expect(DOMAIN_SEKALI_PAKAI.has('tempmail.com')).toBe(true)
    expect(DOMAIN_SEKALI_PAKAI.has('gmail.com')).toBe(false)
    expect(DOMAIN_SEKALI_PAKAI.has('yahoo.com')).toBe(false)
  })
})
