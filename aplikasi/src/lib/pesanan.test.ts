import { describe, expect, it, vi } from 'vitest'
import type { SupabaseClient } from '@supabase/supabase-js'
import { kirimPesananKeDapur } from './pesanan'

describe('kirimPesananKeDapur', () => {
  it('mengirimkan hanya ID lewat RPC, tanpa timestamp dari perangkat', async () => {
    const rpc = vi.fn().mockResolvedValue({ error: null })
    const klien = { rpc } as unknown as Pick<SupabaseClient, 'rpc'>

    await expect(kirimPesananKeDapur(klien, 'pesanan-uji')).resolves.toEqual({ sukses: true })
    expect(rpc).toHaveBeenCalledOnce()
    expect(rpc).toHaveBeenCalledWith('kirim_pesanan', { p_pesanan_id: 'pesanan-uji' })
  })

  it('mengembalikan gagal bila peladen menolak RPC', async () => {
    const rpc = vi.fn().mockResolvedValue({ error: { message: 'akses ditolak' } })
    const klien = { rpc } as unknown as Pick<SupabaseClient, 'rpc'>

    await expect(kirimPesananKeDapur(klien, 'pesanan-uji')).resolves.toEqual({
      sukses: false,
      pesan: 'akses ditolak',
    })
  })
})
