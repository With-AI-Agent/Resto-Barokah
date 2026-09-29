import type { SupabaseClient } from '@supabase/supabase-js'

export interface HasilPindahMeja {
  sukses: boolean
  pesan?: string
}

/** Pindah meja lewat RPC berjejak; aplikasi tidak menulis meja_id langsung. */
export async function pindahPesananMeja(
  klien: Pick<SupabaseClient, 'rpc'>,
  pesananId: string,
  mejaAsalId: string,
  mejaTujuanId: string,
): Promise<HasilPindahMeja> {
  try {
    const { error } = await klien.rpc('pindah_meja', {
      p_pesanan_id: pesananId,
      p_meja_asal_id: mejaAsalId,
      p_meja_tujuan_id: mejaTujuanId,
    })
    if (error) return { sukses: false, pesan: error.message }
    return { sukses: true }
  } catch (galat) {
    return {
      sukses: false,
      pesan: galat instanceof Error ? galat.message : 'Meja gagal dipindahkan.',
    }
  }
}
