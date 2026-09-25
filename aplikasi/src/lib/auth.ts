/**
 * Otentikasi dan Manajemen Sesi Klien (T2-01, T2-02, TECH_SPEC §1 & §7).
 *
 * Mengatur sesi pengguna, penyimpanan aman, login PIN pegawai dengan perangkat terdaftar,
 * dan pemutusan sesi secara seketika.
 */
import { klienSupabase } from './supabase'

export type PeranPengguna =
  'pemilik_platform' | 'owner_pusat' | 'admin_cabang' | 'kasir' | 'pelayan' | 'dapur' | 'pelanggan'

export interface PenggunaSesi {
  id: string
  nama: string
  email: string
  peran: PeranPengguna
  penyewaId: string | null
  cabangIds: string[]
  cabangAktifId: string | null
  perangkatId?: string | null
  modeDukunganAktif?: boolean
}

export interface HasilAutentikasi {
  berhasil: boolean
  kode?: string
  pesan: string
  sesi?: PenggunaSesi | null
}

const KUNCI_SESI = 'resto_sesi_aktif'
const KUNCI_PERANGKAT_ID = 'resto_perangkat_id'
const KUNCI_PERANGKAT_NAMA = 'resto_perangkat_nama'

/**
 * Mendapatkan identitas unik perangkat lokal.
 */
export function ambilPerangkatLokal(): { id: string; nama: string } {
  let id = ''
  let nama = 'Perangkat Browser'
  try {
    id = localStorage.getItem(KUNCI_PERANGKAT_ID) || ''
    nama = localStorage.getItem(KUNCI_PERANGKAT_NAMA) || nama
    if (!id) {
      id =
        typeof crypto !== 'undefined' && crypto.randomUUID
          ? crypto.randomUUID()
          : 'dev-device-' + Date.now()
      localStorage.setItem(KUNCI_PERANGKAT_ID, id)
      localStorage.setItem(KUNCI_PERANGKAT_NAMA, nama)
    }
  } catch {
    id = 'memory-device-id'
  }
  return { id, nama }
}

/**
 * Menyimpan identitas perangkat lokal.
 */
export function simpanPerangkatLokal(id: string, nama: string): void {
  try {
    localStorage.setItem(KUNCI_PERANGKAT_ID, id)
    localStorage.setItem(KUNCI_PERANGKAT_NAMA, nama)
  } catch {
    // Abaikan jika penyimpanan dinonaktifkan
  }
}

/**
 * Membaca sesi pengguna dari penyimpanan lokal sementara.
 */
export function bacaSesiLokal(): PenggunaSesi | null {
  try {
    const raw = sessionStorage.getItem(KUNCI_SESI)
    if (!raw) return null
    return JSON.parse(raw) as PenggunaSesi
  } catch {
    return null
  }
}

/**
 * Menyimpan sesi pengguna ke penyimpanan lokal sesi.
 */
export function simpanSesiLokal(sesi: PenggunaSesi | null): void {
  try {
    if (!sesi) {
      sessionStorage.removeItem(KUNCI_SESI)
    } else {
      sessionStorage.setItem(KUNCI_SESI, JSON.stringify(sesi))
    }
  } catch {
    // Abaikan kegagalan sessionStorage
  }
}

/**
 * Menghapus seluruh data sesi lokal.
 */
export function hapusSesiLokal(): void {
  try {
    sessionStorage.removeItem(KUNCI_SESI)
  } catch {
    // Abaikan
  }
}

/**
 * Masuk akun pegawai menggunakan kombinasi email + PIN 6-angka (T2-02).
 */
export async function masukDenganPin(
  email: string,
  pin: string,
  opsiPerangkat?: { id?: string; nama?: string },
): Promise<HasilAutentikasi> {
  const emailBersih = email.trim().toLowerCase()
  const pinBersih = pin.trim()

  if (!emailBersih || !emailBersih.includes('@')) {
    return {
      berhasil: false,
      kode: 'EMAIL_TIDAK_VALID',
      pesan: 'Mohon masukkan alamat email pegawai yang valid.',
    }
  }

  if (pinBersih.length !== 6 || !/^\d{6}$/.test(pinBersih)) {
    return {
      berhasil: false,
      kode: 'PIN_TIDAK_VALID',
      pesan: 'PIN harus berupa 6 digit angka.',
    }
  }

  const perangkat = ambilPerangkatLokal()
  const perangkatId = opsiPerangkat?.id || perangkat.id
  const perangkatNama = opsiPerangkat?.nama || perangkat.nama

  const supabase = klienSupabase()
  if (!supabase) {
    // Mode simulasi lokal jika lingkungan Supabase belum tersambung
    const peranBawaan: PeranPengguna = emailBersih.includes('kasir')
      ? 'kasir'
      : emailBersih.includes('dapur')
        ? 'dapur'
        : emailBersih.includes('pelayan')
          ? 'pelayan'
          : emailBersih.includes('admin')
            ? 'admin_cabang'
            : emailBersih.includes('platform')
              ? 'pemilik_platform'
              : 'owner_pusat'

    const sesiSimulasi: PenggunaSesi = {
      id: 'usr-simulasi-001',
      nama: emailBersih.split('@')[0].toUpperCase(),
      email: emailBersih,
      peran: peranBawaan,
      penyewaId: '11111111-1111-1111-1111-111111111111',
      cabangIds: ['cab-001'],
      cabangAktifId: 'cab-001',
      perangkatId,
    }
    simpanSesiLokal(sesiSimulasi)
    return {
      berhasil: true,
      kode: 'LOGIN_SUKSES',
      pesan: 'Berhasil masuk ke aplikasi (Mode Offline/Simulasi).',
      sesi: sesiSimulasi,
    }
  }

  try {
    // Panggil RPC verifikasi PIN terpadu dengan perangkat (T1-26 & ART-11)
    const { data, error } = await supabase.rpc('verifikasi_pin_perangkat', {
      p_email: emailBersih,
      p_pin: pinBersih,
      p_perangkat_id: perangkatId,
      p_perangkat_nama: perangkatNama,
    })

    if (error) {
      return {
        berhasil: false,
        kode: error.code || 'ERR_RPC',
        pesan: error.message || 'Gagal memverifikasi PIN.',
      }
    }

    if (!data || !data.berhasil) {
      return {
        berhasil: false,
        kode: data?.kode || 'PIN_SALAH',
        pesan: data?.pesan || 'PIN atau email tidak cocok.',
      }
    }

    const sesi: PenggunaSesi = {
      id: data.data.pengguna_id,
      nama: data.data.nama,
      email: emailBersih,
      peran: data.data.peran,
      penyewaId: data.data.penyewa_id,
      cabangIds: data.data.cabang_ids || [],
      cabangAktifId: data.data.cabang_ids?.[0] || null,
      perangkatId,
    }

    simpanSesiLokal(sesi)
    return {
      berhasil: true,
      kode: 'LOGIN_SUKSES',
      pesan: 'Berhasil masuk ke sistem.',
      sesi,
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    return {
      berhasil: false,
      kode: 'NET_ERROR',
      pesan: `Gagal menghubungkan ke server: ${msg}`,
    }
  }
}

/**
 * Masuk pelanggan menggunakan Google OAuth (T2-04).
 */
export async function masukDenganGoogle(): Promise<{ berhasil: boolean; pesan?: string }> {
  const supabase = klienSupabase()
  if (!supabase) {
    return { berhasil: false, pesan: 'Layanan Supabase belum dikonfigurasi.' }
  }
  try {
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: typeof window !== 'undefined' ? window.location.origin : undefined,
      },
    })
    if (error) {
      return { berhasil: false, pesan: error.message }
    }
    return { berhasil: true }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    return { berhasil: false, pesan: `Gagal menghubungkan ke Google: ${msg}` }
  }
}

/**
 * Kirim tautan masuk via email (magic link) untuk pelanggan (T2-04).
 */
export async function kirimTautanMasukEmail(
  email: string,
): Promise<{ sukses: boolean; pesan?: string }> {
  const supabase = klienSupabase()
  if (!supabase) {
    return { sukses: false, pesan: 'Layanan Supabase belum dikonfigurasi.' }
  }
  try {
    const { error } = await supabase.auth.signInWithOtp({
      email: email.trim().toLowerCase(),
      options: {
        emailRedirectTo: typeof window !== 'undefined' ? window.location.origin : undefined,
      },
    })
    if (error) {
      return { sukses: false, pesan: error.message }
    }
    return { sukses: true }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    return { sukses: false, pesan: `Gagal mengirim email: ${msg}` }
  }
}

/**
 * Keluar dari sistem dan mencabut sesi lokal.
 */
export async function keluar(): Promise<void> {
  hapusSesiLokal()
  const supabase = klienSupabase()
  if (supabase) {
    try {
      await supabase.auth.signOut()
    } catch {
      // Abaikan error jaringan saat logout
    }
  }
}
