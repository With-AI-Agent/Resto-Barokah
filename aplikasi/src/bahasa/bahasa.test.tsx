// @vitest-environment jsdom
import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { PenyediaBahasa, useBahasa, DAFTAR_BAHASA } from './index'
import { rupiah } from '../lib/format'

function KomponenUjiBahasa() {
  const { bahasa, meta, arah, gantiBahasa, t } = useBahasa()

  return (
    <div>
      <p data-testid="bahasa-aktif">{bahasa}</p>
      <p data-testid="nama-bahasa">{meta.nama}</p>
      <p data-testid="arah-teks">{arah}</p>
      <p data-testid="teks-masuk">{t('masuk.judul')}</p>
      <p data-testid="teks-kasir">{t('kasir.judul')}</p>
      <p data-testid="uang-format">{rupiah(50000)}</p>
      <button onClick={() => gantiBahasa('en')}>Ganti English</button>
      <button onClick={() => gantiBahasa('zh')}>Ganti Mandarin</button>
      <button onClick={() => gantiBahasa('ar')}>Ganti Arab</button>
    </div>
  )
}

describe('Kerangka Multi-Bahasa i18n (T1-40)', () => {
  afterEach(() => {
    cleanup()
  })

  it('menyediakan terjemahan bahasa Indonesia sebagai bawaan', () => {
    render(
      <PenyediaBahasa>
        <KomponenUjiBahasa />
      </PenyediaBahasa>,
    )

    expect(screen.getByTestId('bahasa-aktif').textContent).toBe('id')
    expect(screen.getByTestId('nama-bahasa').textContent).toBe('Indonesia')
    expect(screen.getByTestId('arah-teks').textContent).toBe('ltr')
    expect(screen.getByTestId('teks-masuk').textContent).toBe('Masuk Bertugas')
    expect(screen.getByTestId('teks-kasir').textContent).toBe('Kasir & Transaksi')
    expect(screen.getByTestId('uang-format').textContent).toBe('Rp50.000')
  })

  it('dapat berganti bahasa ke Inggris, Mandarin, dan Arab secara instan', () => {
    render(
      <PenyediaBahasa>
        <KomponenUjiBahasa />
      </PenyediaBahasa>,
    )

    // Ganti ke English
    fireEvent.click(screen.getByRole('button', { name: /ganti english/i }))
    expect(screen.getByTestId('bahasa-aktif').textContent).toBe('en')
    expect(screen.getByTestId('teks-masuk').textContent).toBe('Staff Duty Login')
    expect(screen.getByTestId('teks-kasir').textContent).toBe('Cashier & POS')
    expect(document.documentElement.lang).toBe('en')
    expect(document.documentElement.dir).toBe('ltr')

    // Ganti ke Mandarin
    fireEvent.click(screen.getByRole('button', { name: /ganti mandarin/i }))
    expect(screen.getByTestId('bahasa-aktif').textContent).toBe('zh')
    expect(screen.getByTestId('teks-masuk').textContent).toBe('员工上班登录')
    expect(screen.getByTestId('teks-kasir').textContent).toBe('收银与点单')
    expect(document.documentElement.lang).toBe('zh')

    // Ganti ke Arab (RTL)
    fireEvent.click(screen.getByRole('button', { name: /ganti arab/i }))
    expect(screen.getByTestId('bahasa-aktif').textContent).toBe('ar')
    expect(screen.getByTestId('arah-teks').textContent).toBe('rtl')
    expect(document.documentElement.dir).toBe('rtl')

    // Format uang tetap Indonesia di semua bahasa
    expect(screen.getByTestId('uang-format').textContent).toBe('Rp50.000')
  })

  it('memiliki daftar meta 4 bahasa terkonfigurasi', () => {
    expect(DAFTAR_BAHASA.length).toBe(4)
    const kode = DAFTAR_BAHASA.map((b) => b.kode)
    expect(kode).toEqual(['id', 'en', 'zh', 'ar'])
  })
})
