import { describe, expect, it, vi } from 'vitest'
import type { SupabaseClient } from '@supabase/supabase-js'
import { pindahPesananMeja } from './meja'

describe('pindahPesananMeja', () => {
  it('mengirim pesanan, meja asal, dan meja tujuan lewat RPC berjejak', async () => {
    const rpc = vi.fn().mockResolvedValue({ error: null })
    const klien = { rpc } as unknown as Pick<SupabaseClient, 'rpc'>

    await expect(
      pindahPesananMeja(klien, 'pesanan-uji', 'meja-asal', 'meja-tujuan'),
    ).resolves.toEqual({ sukses: true })
    expect(rpc).toHaveBeenCalledWith('pindah_meja', {
      p_pesanan_id: 'pesanan-uji',
      p_meja_asal_id: 'meja-asal',
      p_meja_tujuan_id: 'meja-tujuan',
    })
  })

  it('mengembalikan gagal bila server menolak perpindahan', async () => {
    const rpc = vi.fn().mockResolvedValue({ error: { message: 'Meja tujuan harus kosong.' } })
    const klien = { rpc } as unknown as Pick<SupabaseClient, 'rpc'>

    await expect(
      pindahPesananMeja(klien, 'pesanan-uji', 'meja-asal', 'meja-tujuan'),
    ).resolves.toEqual({ sukses: false, pesan: 'Meja tujuan harus kosong.' })
  })
})
