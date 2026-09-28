-- ============================================================================
-- 0020 · Tabel catatan_audit (temuan audit F F-07 / ROADMAP T1-13)
-- ----------------------------------------------------------------------------
-- Menutup temuan audit F F-07: tabel `catatan_audit` sebagai jejak audit
-- peristiwa penting di resto.
--
-- Karakteristik & aturan:
--   * Kolom: id, penyewa_id, pelaku_id, aksi, entitas, entitas_id,
--     nilai_lama, nilai_baru, waktu.
--   * pelaku_id boleh NULL (untuk kejadian yang dipicu sistem/otomatis).
--   * RLS aktif + policy: baca hanya pegawai yang memiliki izin `kelola_pegawai`
--     di penyewa yang sama (`penyewa_id = public.penyewa_saya() and public.boleh('kelola_pegawai')`).
--   * Tanpa grant insert/update/delete untuk klien (anon, authenticated).
--     Hanya jalur peladen/definer/service_role yang dapat menambah data.
--   * TANPA trigger otomatis dulu (pencatatan otomatis menyusul di tugas/fase berikutnya).
-- ============================================================================

create table if not exists public.catatan_audit (
  id          uuid primary key default gen_random_uuid(),
  penyewa_id  uuid not null references public.penyewa (id) on delete cascade,
  pelaku_id   uuid references public.pengguna (id) on delete set null,
  aksi        text not null,
  entitas     text not null,
  entitas_id  uuid,
  nilai_lama  jsonb,
  nilai_baru  jsonb,
  waktu       timestamptz not null default now()
);

comment on table public.catatan_audit is
  'Jejak audit peristiwa penting (F-07/T1-13). Hanya-tambah melalui jalur peladen/definer; dibaca oleh pemegang izin kelola_pegawai.';

create index if not exists catatan_audit_penyewa_waktu_idx
  on public.catatan_audit (penyewa_id, waktu desc);

-- Cabut semua hak dari public, anon, authenticated
revoke all on table public.catatan_audit from public, anon, authenticated;

-- RLS wajib aktif
alter table public.catatan_audit enable row level security;

-- Hak baca untuk authenticated (dibatasi oleh policy RLS)
grant select on table public.catatan_audit to authenticated;
grant select, insert, update, delete on table public.catatan_audit to service_role;

-- Kebijakan RLS: baca hanya bagi yang berizin kelola_pegawai di penyewa yang sama
drop policy if exists catatan_audit_pilih on public.catatan_audit;
create policy catatan_audit_pilih on public.catatan_audit
  for select to authenticated
  using (
    penyewa_id = public.penyewa_saya()
    and public.boleh('kelola_pegawai')
  );
