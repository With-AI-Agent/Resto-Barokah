-- ============================================================================
-- 0001 — Penyewa (resto) & cabang
-- Isolasi tingkat 1 (resto) & tingkat 2 (cabang) — TECH_SPEC §4.1 & §9 ART-1.
--
-- Catatan penting: RLS DINYALAKAN di sini, tetapi policy-nya sengaja BELUM
-- dibuat. Artinya "deny by default": sebelum policy resmi ada (0004_pola_rls.sql),
-- tidak ada satu pun peran aplikasi yang bisa membaca tabel ini. Urutan ini
-- disengaja karena policy butuh fungsi identitas dari 0003_helper_identitas.sql.
--
-- Aturan yang dipakai sepanjang proyek: berkas migrasi yang sudah pernah
-- dijalankan TIDAK PERNAH diubah — perbaikan selalu berupa migrasi baru.
-- ============================================================================

-- gen_random_uuid(): sejak PostgreSQL 13 sudah bawaan. Di Supabase juga tersedia.
-- Blok ini hanya jaring pengaman kalau lingkungan uji tidak menyediakannya.
do $$
begin
  execute 'create extension if not exists pgcrypto';
exception
  when others then
    raise notice 'pgcrypto tidak tersedia di lingkungan ini; memakai gen_random_uuid bawaan PostgreSQL';
end
$$;

-- ---------------------------------------------------------------- penyewa
create table if not exists public.penyewa (
  id          uuid primary key default gen_random_uuid(),
  nama        text not null check (length(btrim(nama)) between 1 and 120),
  slug        text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,30}$'),
  status      text not null default 'aktif' check (status in ('aktif', 'nonaktif')),
  zona_waktu  text not null default 'Asia/Jakarta',
  mata_uang   text not null default 'IDR' check (mata_uang ~ '^[A-Z]{3}$'),
  dibuat_pada timestamptz not null default now()
);

comment on table public.penyewa is
  'Satu baris = satu resto/kedai (penyewa). Isolasi tingkat 1 (TECH_SPEC §9 ART-1).';

-- ---------------------------------------------------------------- cabang
create table if not exists public.cabang (
  id          uuid primary key default gen_random_uuid(),
  penyewa_id  uuid not null references public.penyewa (id) on delete cascade,
  nama        text not null check (length(btrim(nama)) between 1 and 120),
  alamat      text,
  telepon     text,
  aktif       boolean not null default true,
  dibuat_pada timestamptz not null default now(),
  unique (penyewa_id, nama)
);

comment on table public.cabang is
  'Cabang milik satu penyewa. Isolasi tingkat 2 (TECH_SPEC §9 ART-1).';

create index if not exists cabang_penyewa_idx on public.cabang (penyewa_id);

-- ------------------------------------------------------------ kunci RLS
alter table public.penyewa enable row level security;
alter table public.cabang enable row level security;

-- Service role (Edge Function/peladen) memang perlu menembus RLS.
-- Ini bawaan Supabase; ditulis ulang di sini supaya perilaku lokal = produksi.
grant select, insert, update, delete on public.penyewa to service_role;
grant select, insert, update, delete on public.cabang to service_role;

-- Peran aplikasi: hanya hak baca di tingkat tabel. Yang membatasi baris mana
-- yang boleh dilihat adalah policy di 0004_pola_rls.sql (deny by default).
-- Supabase memberi hak ini secara bawaan; ditulis eksplisit agar sama di uji lokal.
grant select on public.penyewa to anon, authenticated;
grant select on public.cabang to anon, authenticated;
