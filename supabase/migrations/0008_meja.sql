-- ============================================================================
-- 0008 — Meja & statusnya (M4)
--
-- Meja adalah keadaan yang dilihat semua orang di cabang itu (pelayan, kasir,
-- dapur). Karena itu:
--   * meja terpisah per cabang, nama meja unik per cabang (boleh sama di cabang
--     lain — "Meja 1" di Pusat dan di Cabang Dua itu wajar);
--   * SEMUA pegawai cabang boleh MELIHAT dan mengubah STATUS (kosong/terisi/siap),
--     karena ini keadaan yang berubah terus saat jam sibuk;
--   * menambah/menghapus meja = owner pusat & admin cabang saja;
--   * owner pusat melihat seluruh cabang restonya.
-- Penguncian supaya dua pelayan tidak membuka meja yang sama dibahas di T3-09.
-- ============================================================================

create table if not exists public.meja (
  id          uuid primary key default gen_random_uuid(),
  cabang_id   uuid not null references public.cabang (id) on delete cascade,
  nama        text not null,
  area        text,
  status      text not null default 'kosong' check (status in ('kosong', 'terisi', 'siap')),
  aktif       boolean not null default true,
  diubah_pada timestamptz not null default now(),
  unique (cabang_id, nama)
);

comment on table public.meja is
  'Meja per cabang dengan status kosong/terisi/siap. Nama meja unik per cabang, bukan unik global.';

alter table public.meja enable row level security;

create index if not exists meja_cabang_idx on public.meja (cabang_id, aktif);

create policy meja_pilih on public.meja
  for select to authenticated
  using (public.cabang_pantau_saya(cabang_id));

-- Status meja = keadaan harian: seluruh pegawai cabang boleh mengubahnya.
create policy meja_ubah_status on public.meja
  for update to authenticated
  using (
    public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

create policy meja_tambah on public.meja
  for insert to authenticated
  with check (
    public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang')
  );

create policy meja_hapus on public.meja
  for delete to authenticated
  using (
    public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang')
  );

grant select, insert, update, delete on public.meja to authenticated;
grant select on public.meja to anon;
grant select, insert, update, delete on public.meja to service_role;
