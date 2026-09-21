/**
 * Pengaturan alamat layanan & kunci.
 *
 * Aturan `docs/TECH_SPEC.md` §6: HANYA dua nilai berawalan `VITE_` yang boleh
 * dibaca aplikasi (keduanya memang untuk publik dan dibatasi RLS):
 *   - VITE_SUPABASE_URL       alamat proyek Supabase
 *   - VITE_SUPABASE_ANON_KEY  kunci publik (anon)
 * Kunci rahasia (service_role, Resend/Brevo, Google, Cloudflare, denyut)
 * TIDAK PERNAH masuk ke aplikasi — hanya hidup di panel rahasia Cloudflare/Supabase.
 *
 * Catatan: fungsi di sini sengaja TIDAK meledak saat nilai belum diisi, supaya
 * aplikasi tetap bisa dibuka (dan halaman contoh tetap jalan) sebelum pemilik
 * menyelesaikan T0-00. Layar yang benar-benar butuh Supabase harus memanggil
 * `pesanEnvKurang()` dan menampilkan KeadaanGagal, bukan layar putih.
 */

export const NAMA_KLIEN = ['VITE_SUPABASE_URL', 'VITE_SUPABASE_ANON_KEY'] as const
export type NamaKlien = (typeof NAMA_KLIEN)[number]

function semuaNilai(): Record<string, string | undefined> {
  return import.meta.env as unknown as Record<string, string | undefined>
}

function baca(nama: NamaKlien): string {
  return (semuaNilai()[nama] ?? '').trim()
}

export function alamatSupabase(): string {
  return baca('VITE_SUPABASE_URL')
}

export function kunciAnonSupabase(): string {
  return baca('VITE_SUPABASE_ANON_KEY')
}

/** Daftar nilai yang boleh dibaca aplikasi + apakah sudah diisi. */
export function statusEnv(): { nama: NamaKlien; terisi: boolean }[] {
  return NAMA_KLIEN.map((nama) => ({ nama, terisi: baca(nama).length > 0 }))
}

export function envLengkap(): boolean {
  return statusEnv().every((butir) => butir.terisi)
}

/** Pesan bahasa Indonesia siap tampil kalau pengaturan belum lengkap. */
export function pesanEnvKurang(): string {
  const kurang = statusEnv()
    .filter((butir) => !butir.terisi)
    .map((butir) => butir.nama)
  if (kurang.length === 0) return ''
  return `Pengaturan aplikasi belum lengkap: ${kurang.join(', ')}. Salin aplikasi/.env.example menjadi aplikasi/.env lalu isi nilainya.`
}
