-- ============================================================================
-- Migrasi 0056: Cabang Aktif Otomatis untuk kas_pergerakan (N F-04 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-04: `public.cabang_aktif_saya()` tidak
--     pernah didefinisikan; `kas_pergerakan` (migrasi 0047 baris 199) memanggil
--     fungsi itu pada jalur default (kasir tidak mengirim `p_cabang_id`).
--   - Uji SQL `supabase/tes/kas_pergerakan.sql` selalu mengirim `p_cabang_id`
--     sehingga jalur default tidak pernah tereksekusi → cacat tak tertangkap.
--   - Bantah-balik sesi kerja 2026-09-24 NYATA.
--
-- Masalah yang diselesaikan:
--   1. Fungsi `cabang_aktif_saya()` HARUS ADA sebelum migrasi 0047 bisa
--      terpasang dengan benar. Sebenarnya PostgreSQL menunda validasi hingga
--      fungsi dipanggil (definisi malas), sehingga migrasi 0047 terpasang
--      tanpa error — tetapi `kas_pergerakan` akan gagal pada runtime dengan
--      `function public.cabang_aktif_saya() does not exist`.
--   2. Kasir yang sah di satu cabang tidak perlu mengirim `p_cabang_id`
--      (cabang sudah dapat disimpulkan dari keanggotaan `pengguna_cabang`).
--
-- Aturan kelas (audit F F-13, F-14): setiap fallback `cabang_aktif_saya()`
-- harus SEIZIN `penyewa_saya()` — fallback lintas penyewa adalah oracle.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — public.cabang_aktif_saya(): cabang pertama yang boleh diakses
-- ---------------------------------------------------------------------------
create or replace function public.cabang_aktif_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  -- Cabang pertama dari `cabang_ids_saya()` (sudah difilter ke penyewa aktif
  -- dan akun nonaktif). Kalau tidak ada → NULL.
  select c.id
    from public.cabang c
   where c.id in (select public.cabang_ids_saya())
     and c.penyewa_id = public.penyewa_saya()
   order by c.dibuat_pada asc, c.id asc
   limit 1
$$;

comment on function public.cabang_aktif_saya() is
  'Cabang aktif pengguna saat ini = cabang pertama yang boleh diakses (cabang_ids_saya), deterministik per sesi. NULL bila tidak punya akses. Dipakai kas_pergerakan sebagai fallback bila kasir tidak mengirim p_cabang_id.';

revoke all on function public.cabang_aktif_saya() from public;
grant execute on function public.cabang_aktif_saya() to authenticated, service_role;
