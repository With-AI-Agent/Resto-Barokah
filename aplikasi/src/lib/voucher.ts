/**
 * KLAIM VOUCHER LEWAT PELADEN (PMB1-F-032).
 *
 * Kenapa ada: temuan PMB1-F-032 — layar klaim voucher dulu MEMBUAT kode voucher
 * di klien (`buatKodeVoucherAcak` dengan Math.random) dan menampilkan kartu
 * "voucher terbit" segera setelah proses masuk Google/email DIMULAI, tanpa
 * pernah memanggil RPC `daftar_voucher`. Padahal janji PRD M10 baris 164:
 * barcode muncul SETELAH verifikasi Google/email, dan satu-satunya penerbit
 * kode yang sah adalah peladen (RPC `daftar_voucher` — diperkuat PMB1-F-031:
 * hanya sesi terverifikasi dari peladen yang boleh menerbitkan).
 *
 * Apa yang dilakukan modul ini:
 *   1. `klaimVoucherDiPeladen` — satu-satunya jalan menerbitkan voucher dari
 *      UI: memanggil RPC `daftar_voucher` dan mengembalikan jawaban peladen
 *      apa adanya (berhasil/gagal, kode galat, data voucher). Gagal tertutup
 *      (fail-closed) bila Supabase/penyewa belum dikonfigurasi — tanpa sukses
 *      palsu.
 *   2. `simpanKlaimTunda` / `ambilKlaimTunda` / `hapusKlaimTunda` — klaim yang
 *      menunggu verifikasi disimpan di localStorage; setelah verifikasi selesai
 *      (sesi hidup) layar menyelesaikan klaim lewat RPC dan BARU menampilkan
 *      kode dari peladen.
 *
 * Batas jujur: kode voucher TIDAK pernah dihitung di klien. Bila peladen
 * menolak (mis. VERIFIKASI_WAJIB), UI tidak boleh menampilkan kartu voucher.
 */
import { klienSupabase } from './supabase'

/** Argumen klaim yang diteruskan ke RPC `daftar_voucher`. */
export interface KlaimPeladenArg {
  penyewaId?: string | null
  kampanyeId: string
  nama: string
  email: string
  telepon?: string
  alamat?: string
  setujuPrivasi: boolean
  caraMasuk: 'google' | 'email' | 'kasir'
}

/** Bentuk `data` pada jawaban RPC `daftar_voucher` (jsonb). */
export interface DataVoucherPeladen {
  voucher_id?: string
  kode_voucher?: string
  nama_pelanggan?: string
  nilai?: number
  jenis?: 'persen' | 'nominal'
  min_belanja?: number
  maks_potongan?: number | null
  berlaku_sampai?: string
  status?: string
}

/** Jawaban RPC `daftar_voucher` apa adanya. */
export interface HasilKlaimPeladen {
  berhasil: boolean
  kode?: string
  pesan?: string
  data?: DataVoucherPeladen
}

/** Klaim yang menunggu verifikasi selesai (disimpan di localStorage). */
export interface KlaimTunda extends KlaimPeladenArg {
  disimpanPada: string
}

const KUNCI_KLAIM_TUNDA = 'klaim_voucher_tunda'

/**
 * Terbitkan voucher HANYA lewat RPC peladen `daftar_voucher`.
 * Tidak ada pembuatan kode di sini — kode selalu hasil peladen.
 */
export async function klaimVoucherDiPeladen(arg: KlaimPeladenArg): Promise<HasilKlaimPeladen> {
  const supabase = klienSupabase()
  if (!supabase) {
    return {
      berhasil: false,
      kode: 'KONFIGURASI_KURANG',
      pesan: 'Layanan Supabase belum dikonfigurasi; voucher tidak bisa diterbitkan.',
    }
  }
  if (!arg.penyewaId) {
    return {
      berhasil: false,
      kode: 'PENYEWA_KURANG',
      pesan: 'Data kampanye belum menyertakan penyewa; klaim tidak bisa diproses.',
    }
  }

  // Jalur google/email wajib membawa alamat yang sama dengan sesi terverifikasi.
  // Bila formulir tidak mengisi email (mis. masuk Google tanpa mengetik email),
  // pakai alamat pada sesi peladen — bukan mengarang alamat di klien.
  let email = (arg.email ?? '').trim()
  if (arg.caraMasuk !== 'kasir' && email === '') {
    try {
      const { data } = await supabase.auth.getSession()
      const emailSesi = data?.session?.user?.email ?? ''
      if (emailSesi) email = emailSesi.trim()
    } catch {
      // sesi tidak bisa dibaca → biarkan kosong; peladen akan menolak jujur.
    }
  }
  if (arg.caraMasuk !== 'kasir' && email === '') {
    return {
      berhasil: false,
      kode: 'EMAIL_WAJIB',
      pesan: 'Alamat email wajib diisi.',
    }
  }

  try {
    const { data, error } = await supabase.rpc('daftar_voucher', {
      p_penyewa_id: arg.penyewaId,
      p_kampanye_id: arg.kampanyeId,
      p_nama: arg.nama,
      p_email: email,
      p_telepon: arg.telepon ?? null,
      p_alamat: arg.alamat ?? null,
      p_persetujuan_privasi: arg.setujuPrivasi === true,
      p_cara_masuk: arg.caraMasuk,
    })
    if (error) {
      return { berhasil: false, kode: 'PELADEN_GAGAL', pesan: error.message }
    }
    if (!data || typeof data !== 'object') {
      return { berhasil: false, kode: 'PELADEN_TIDAK_JELAS', pesan: 'Peladen tidak menjawab.' }
    }
    return data as HasilKlaimPeladen
  } catch (err) {
    const pesan = err instanceof Error ? err.message : String(err)
    return { berhasil: false, kode: 'JARINGAN_GAGAL', pesan }
  }
}

/** Simpan klaim yang menunggu verifikasi (dipanggil saat alur Google/email dimulai). */
export function simpanKlaimTunda(klaim: KlaimTunda): void {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(KUNCI_KLAIM_TUNDA, JSON.stringify(klaim))
}

/** Baca klaim tunda; null bila tidak ada atau rusak. */
export function ambilKlaimTunda(): KlaimTunda | null {
  if (typeof localStorage === 'undefined') return null
  try {
    const mentah = localStorage.getItem(KUNCI_KLAIM_TUNDA)
    if (!mentah) return null
    const isi = JSON.parse(mentah) as KlaimTunda
    if (!isi || typeof isi.kampanyeId !== 'string' || typeof isi.caraMasuk !== 'string') {
      return null
    }
    return isi
  } catch {
    return null
  }
}

/** Bersihkan klaim tunda (dipanggil setelah peladen menerbitkan/menolak tuntas). */
export function hapusKlaimTunda(): void {
  if (typeof localStorage === 'undefined') return
  localStorage.removeItem(KUNCI_KLAIM_TUNDA)
}
