-- ============================================================================
-- 0003 — Fungsi bantu identitas (satu sumber kebenaran untuk semua policy)
--
-- Nama fungsi mengikuti TECH_SPEC §9 ART-1 yang sudah dikunci:
--   penyewa_saya() · cabang_saya() · cabang_ids_saya() · peran_saya()
-- ditambah satu pembantu lagi: sepenyewa() — dipakai policy yang butuh
-- memeriksa pemilik baris lain tanpa menulis subquery langsung (menghindari
-- RLS berputar/berulang).
--
-- Aturan teknis yang WAJIB dipertahankan:
--   * Identitas diambil dari TABEL `pengguna` lewat `auth.uid()` — bukan dari
--     metadata yang bisa diubah klien (ART-1).
--   * Semua fungsi SECURITY DEFINER + `set search_path` dikunci, karena fungsi
--     ini membaca tabel yang RLS-nya aktif (kalau tidak, policy akan berputar).
--   * Hak jalankan hanya untuk peran `authenticated` (bukan `anon`) — anon
--     memang tidak punya identitas.
-- ============================================================================

-- -------------------------------------------------------- penyewa_saya()
create or replace function public.penyewa_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.penyewa_id
    from public.pengguna p
   where p.id = auth.uid()
     and p.aktif
$$;

comment on function public.penyewa_saya() is
  'Penyewa (resto) milik pengguna yang sedang masuk. Null untuk pemilik platform / belum masuk.';

-- ---------------------------------------------------------- peran_saya()
create or replace function public.peran_saya()
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.peran
    from public.pengguna p
   where p.id = auth.uid()
     and p.aktif
$$;

comment on function public.peran_saya() is
  'Peran resmi pengguna yang sedang masuk (pemilik_platform/owner_pusat/admin_cabang/kasir/pelayan/dapur).';

-- --------------------------------------------------------- cabang_saya()
-- Cabang "aktif" pengguna: diambil dari klaim token `cabang_id` yang dibuat
-- peladen saat masuk, TETAPI tetap diverifikasi ke tabel pengguna_cabang —
-- jadi klaim palsu/kedaluwarsa tidak memberi akses.
create or replace function public.cabang_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select pc.cabang_id
    from public.pengguna_cabang pc
    join public.pengguna p on p.id = pc.pengguna_id and p.aktif   -- akun nonaktif kehilangan akses
   where pc.pengguna_id = auth.uid()
     and pc.aktif
     and pc.cabang_id = nullif(auth.jwt() ->> 'cabang_id', '')::uuid
   limit 1
$$;

comment on function public.cabang_saya() is
  'Cabang aktif pengguna (dari klaim token, diverifikasi ulang ke pengguna_cabang). Null bila belum memilih cabang atau tidak berhak.';

-- ----------------------------------------------------- cabang_ids_saya()
create or replace function public.cabang_ids_saya()
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select pc.cabang_id
    from public.pengguna_cabang pc
    join public.cabang c on c.id = pc.cabang_id and c.aktif
    join public.pengguna p on p.id = pc.pengguna_id and p.aktif      -- akun nonaktif kehilangan akses
   where pc.pengguna_id = auth.uid()
     and pc.aktif
$$;

comment on function public.cabang_ids_saya() is
  'Daftar cabang yang boleh diakses pengguna (pegawai merangkap cabang). Kosong bila tidak punya cabang.';

-- ------------------------------------------------------------- sepenyewa()
create or replace function public.sepenyewa(p_pengguna_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.pengguna p
     where p.id = p_pengguna_id
       and p.penyewa_id is not null
       and p.penyewa_id = public.penyewa_saya()
  )
$$;

comment on function public.sepenyewa(uuid) is
  'Benar bila pengguna lain berada di penyewa (resto) yang sama. Dipakai policy baris milik pegawai.';

-- --------------------------------------------------------------- hak akses
revoke all on function public.penyewa_saya() from public;
revoke all on function public.peran_saya() from public;
revoke all on function public.cabang_saya() from public;
revoke all on function public.cabang_ids_saya() from public;
revoke all on function public.sepenyewa(uuid) from public;

grant execute on function public.penyewa_saya() to authenticated, service_role;
grant execute on function public.peran_saya() to authenticated, service_role;
grant execute on function public.cabang_saya() to authenticated, service_role;
grant execute on function public.cabang_ids_saya() to authenticated, service_role;
grant execute on function public.sepenyewa(uuid) to authenticated, service_role;
