/**
 * PROBE HAKIM H-F-02.2 (bukan uji proyek) — disalin sementara ke aplikasi/src/_probe_laci_kertas.test.ts.
 * Klaim Pembangun (B-F-02, F-010): "laci hanya terbuka bila tercatat".
 * Probe: jalur kertas yang SUDAH ADA (susunStruk + opsi.bukaLaci, struk.ts:142) menerbitkan byte ESC p (buka laci)
 * TANPA memanggil peladen sama sekali (klien Supabase dibuat meledak bila disentuh).
 * Kontrol: tanpa opsi.bukaLaci, byte ESC p tidak ada.
 */
import { describe, it, expect, vi } from 'vitest'
import { susunStruk } from './lib/printer/struk'

vi.mock('./lib/supabase', () => ({
  klienSupabase: () => {
    throw new Error('PELADEN DISENTUH — seharusnya tercatat dulu')
  },
}))

const data = {
  nomor: 1, tanggal: '2026-09-30T08:00:00Z', namaResto: 'R', item: [], subtotal: 10000,
  totalDiskon: 0, pajak: 1000, service: 0, total: 11000,
}
const adaEscP = (b: Uint8Array) => b.some((v, i) => v === 0x1b && b[i + 1] === 0x70)

describe('PROBE F-02.2 — jalur kertas membuka laci tanpa jejak', () => {
  it('KONTROL: tanpa opsi.bukaLaci tidak ada ESC p', () => {
    expect(adaEscP(susunStruk(data as never, {}))).toBe(false)
  })
  it('UJI: opsi.bukaLaci=true -> byte buka laci terbit tanpa menyentuh peladen', () => {
    const bytes = susunStruk(data as never, { bukaLaci: true })
    expect(adaEscP(bytes)).toBe(true) // terbukti: laci terbuka TANPA tercatat
  })
})
