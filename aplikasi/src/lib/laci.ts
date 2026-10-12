/**
 * laci.ts — SATU PINTU sah membuka laci kas (PMB1-F-010 · kartu B-F-02).
 *
 * Kenapa ada: PRD M3 baris 99 menjanjikan jejak audit untuk "buka laci tanpa
 * transaksi", tetapi sebelumnya satu-satunya jalan membuka laci adalah byte
 * ESC/POS (`expos.bukaLaci()`) yang dikirim TANPA jejak apa pun — kontrol
 * anti-fraud dijanjikan tiga dokumen fondasi tanpa wujud (temuan PMB1-F-010).
 *
 * Aturan yang ditegakkan berkas ini: **laci hanya terbuka bila tercatat.**
 *   1. Panggil RPC peladen `catat_buka_laci` (migrasi 0094) — peladen yang
 *      menulis baris `catatan_audit` (aksi `buka_laci`), pelaku dari sesi,
 *      bukan dikarang klien. Buka manual tanpa alasan ditolak peladen.
 *   2. HANYA setelah peladen menjawab `berhasil` byte kick dikembalikan ke
 *      pemanggil untuk dikirim ke printer. RPC gagal → meledak (fail-closed):
 *      tidak ada laci yang terbuka diam-diam tanpa jejak.
 *
 * Konteks: `manual` (tanpa transaksi — wajib beralasan) atau
 * `cetak_struk_tunai` (laci ikut terbuka saat struk tunai dicetak).
 */
import { klienSupabase } from './supabase'
import { PenyusunEscPos, LEBAR_58MM } from './printer/expos'

export type KonteksLaci = 'manual' | 'cetak_struk_tunai'

export interface HasilBukaLaci {
  berhasil: boolean
  kode?: string
  pesan?: string
  /** Byte ESC/POS kick laci — hanya ada bila peladen mencatat. */
  byte?: Uint8Array
}

export async function bukaLaciTercatat(
  konteks: KonteksLaci = 'manual',
  alasan?: string,
): Promise<HasilBukaLaci> {
  const supabase = klienSupabase()
  if (!supabase) {
    return {
      berhasil: false,
      kode: 'KONFIGURASI_KURANG',
      pesan: 'Layanan Supabase belum dikonfigurasi; laci tidak dibuka tanpa jejak.',
    }
  }

  const { data, error } = await supabase.rpc('catat_buka_laci', {
    p_konteks: konteks,
    p_alasan: alasan ?? null,
  })
  if (error) {
    return { berhasil: false, kode: 'PELADEN_GAGAL', pesan: error.message }
  }
  const jawab = (data ?? {}) as { berhasil?: boolean; kode?: string; pesan?: string }
  if (jawab.berhasil !== true) {
    return {
      berhasil: false,
      kode: jawab.kode ?? 'DITOLAK',
      pesan: jawab.pesan ?? 'Buka laci ditolak peladen.',
    }
  }

  // Peladen sudah mencatat — baru byte kick disiapkan.
  const byte = new PenyusunEscPos(LEBAR_58MM).awal().bukaLaci().potongKertas().selesai()
  return { berhasil: true, kode: 'TERCATAT', pesan: jawab.pesan, byte }
}
