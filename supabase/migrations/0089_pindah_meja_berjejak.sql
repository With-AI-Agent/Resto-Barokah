-- ============================================================================
-- 0089 — PINDAH MEJA DENGAN RIWAYAT KEKAL (PMB-1 F-131)
--
-- Pengguna hanya mengirim ID pesanan dan meja tujuan. Fungsi memakai RLS
-- pemanggil, mengunci pesanan/meja, dan pemicu menulis jejak asal/tujuan/pelaku.
-- ============================================================================

create table public.pindah_meja_riwayat (
  id              bigint generated always as identity primary key,
  penyewa_id      uuid not null references public.penyewa (id) on delete cascade,
  cabang_id       uuid not null references public.cabang (id) on delete cascade,
  pesanan_id      uuid not null references public.pesanan (id) on delete cascade,
  meja_asal_id    uuid not null references public.meja (id) on delete restrict,
  meja_tujuan_id  uuid not null references public.meja (id) on delete restrict,
  pelaku_id       uuid references public.pengguna (id) on delete set null,
  dibuat_pada     timestamptz not null default now(),
  check (meja_asal_id <> meja_tujuan_id)
);

comment on table public.pindah_meja_riwayat is
  'Jejak append-only perpindahan meja: meja asal, meja tujuan, pesanan, cabang, pelaku, dan waktu peladen.';

alter table public.pindah_meja_riwayat enable row level security;
create policy pindah_meja_riwayat_pilih on public.pindah_meja_riwayat
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
  );
grant select on public.pindah_meja_riwayat to authenticated;
revoke insert, update, delete, truncate on public.pindah_meja_riwayat from public, anon, authenticated;

-- Jejak dibuat hanya oleh pemicu setelah perpindahan meja yang benar-benar terjadi.
create or replace function public.picu_catat_pindah_meja()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.meja_id is not null
     and new.meja_id is not null
     and old.meja_id is distinct from new.meja_id then
    insert into public.pindah_meja_riwayat (
      penyewa_id, cabang_id, pesanan_id, meja_asal_id, meja_tujuan_id, pelaku_id
    ) values (
      new.penyewa_id, new.cabang_id, new.id, old.meja_id, new.meja_id, auth.uid()
    );
  end if;
  return new;
end
$$;

revoke all on function public.picu_catat_pindah_meja() from public, anon, authenticated;
drop trigger if exists pesanan_catat_pindah_meja on public.pesanan;
create trigger pesanan_catat_pindah_meja
  after update of meja_id on public.pesanan
  for each row execute function public.picu_catat_pindah_meja();

create or replace function public.pindah_meja(
  p_pesanan_id uuid,
  p_meja_asal_id uuid,
  p_meja_tujuan_id uuid
)
returns void
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_cabang_id uuid;
  v_meja_asal_id uuid;
  v_status_pesanan text;
  v_cabang_tujuan_id uuid;
  v_status_tujuan text;
begin
  select p.penyewa_id, p.cabang_id, p.meja_id, p.status
    into v_penyewa_id, v_cabang_id, v_meja_asal_id, v_status_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
   for update;

  if not found then
    raise exception 'Pesanan tidak ditemukan atau tidak dapat diakses.';
  end if;
  if v_status_pesanan not in ('draf', 'dikirim', 'dimasak', 'siap') then
    raise exception 'Pesanan yang sudah lunas atau batal tidak dapat dipindah.';
  end if;
  if v_meja_asal_id is null then
    raise exception 'Pesanan ini belum memiliki meja asal.';
  end if;
  if v_meja_asal_id = p_meja_tujuan_id then
    return;
  end if;
  if v_meja_asal_id is distinct from p_meja_asal_id then
    raise exception 'Meja asal pesanan sudah berubah; muat ulang sebelum memindahkan.';
  end if;

  select m.cabang_id, m.status
    into v_cabang_tujuan_id, v_status_tujuan
    from public.meja m
   where m.id = p_meja_tujuan_id
     and m.aktif
   for update;
  if not found or v_cabang_tujuan_id is distinct from v_cabang_id then
    raise exception 'Meja tujuan tidak aktif atau bukan milik cabang pesanan.';
  end if;
  if v_status_tujuan <> 'kosong' then
    raise exception 'Meja tujuan harus kosong.';
  end if;
  if exists (
    select 1 from public.pesanan p
     where p.cabang_id = v_cabang_id
       and p.meja_id = p_meja_tujuan_id
       and p.id <> p_pesanan_id
       and p.status in ('draf', 'dikirim', 'dimasak', 'siap')
  ) then
    raise exception 'Meja tujuan sudah memiliki pesanan aktif.';
  end if;

  update public.pesanan
     set meja_id = p_meja_tujuan_id
   where id = p_pesanan_id;

  update public.meja m
     set status = 'kosong'
   where m.id = v_meja_asal_id
     and not exists (
       select 1 from public.pesanan p
        where p.cabang_id = v_cabang_id
          and p.meja_id = v_meja_asal_id
          and p.status in ('draf', 'dikirim', 'dimasak', 'siap')
     );
  update public.meja m
     set status = 'terisi'
   where m.id = p_meja_tujuan_id;
end
$$;

comment on function public.pindah_meja(uuid, uuid, uuid) is
  'Memindahkan pesanan aktif ke meja kosong di cabang yang sama. Riwayat asal/tujuan/pelaku dibuat pemicu secara atomik.';
revoke all on function public.pindah_meja(uuid, uuid, uuid) from public, anon;
grant execute on function public.pindah_meja(uuid, uuid, uuid) to authenticated;
