import type { SupabaseClient } from '@supabase/supabase-js'

export interface HasilKirimPesanan {
  sukses: boolean
  pesan?: string
}

/** Kirim pesanan lewat RPC; klien hanya mengirim ID, waktu ditetapkan PostgreSQL. */
export async function kirimPesananKeDapur(
  klien: Pick<SupabaseClient, 'rpc'>,
  pesananId: string,
): Promise<HasilKirimPesanan> {
  try {
    const { error } = await klien.rpc('kirim_pesanan', { p_pesanan_id: pesananId })
    if (error) return { sukses: false, pesan: error.message }
    return { sukses: true }
  } catch (galat) {
    return {
      sukses: false,
      pesan: galat instanceof Error ? galat.message : 'Pesanan gagal dikirim ke dapur.',
    }
  }
}
