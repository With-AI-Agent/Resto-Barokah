-- ============================================================================
-- 0035 — SUMBER KEBENARAN MENU HABIS (T4-05)
--
-- Satu sumber kebenaran: `menu_cabang.habis` (sudah dibaca `menu_habis()` 0007).
-- Tambahan lapisan T4-05:
--   1. `menu_habis_riwayat` — jejak SIAPA & KAPAN setiap perubahan penanda,
--      hanya-tambah (3 lapis: pemicu tolak, tanpa kebijakan tulis, hak dicabut);
--   2. pemicu `picu_menu_habis_catat` pada menu_cabang — SETIAP penulis (RPC
--      maupun tulis langsung sesuai kontrak katalog.sql) tercatat otomatis;
--      perubahan ke nilai yang sama TIDAK dicatat (bukan perubahan nyata);
--   3. RPC `tandai_habis(menu, cabang, habis)` — pintu rapi untuk tombol dapur.
--      Menandai & mencabut keduanya butuh izin `ubah_stok` (pencabutan termasuk
--      — kasir/pelayan tidak memilikinya; matriks 0005 beku).
-- Kasir & katalog publik membaca `menu_habis()`/`menu_cabang.habis` yang sama,
-- sehingga penanda langsung berlaku tanpa sumber kedua (realtime menyusul di
-- kabel data aplikasi).
-- ============================================================================

create table if not exists public.menu_habis_riwayat (
  id           bigserial primary key,
  penyewa_id   uuid not null references public.penyewa (id) on delete cascade,
  menu_item_id uuid not null references public.menu_item (id) on delete cascade,
  cabang_id    uuid not null references public.cabang (id) on delete cascade,
  habis        boolean not null,
  pelaku_id    uuid references public.pengguna (id) on delete set null,
  waktu        timestamptz not null default now()
);

comment on table public.menu_habis_riwayat is
  'Jejak hanya-tambah penanda menu habis (T4-05): siapa, kapan, menandai atau mencabut. Tidak boleh diubah/dihapus.';

alter table public.menu_habis_riwayat enable row level security;

drop policy if exists menu_habis_riwayat_pilih on public.menu_habis_riwayat;
create policy menu_habis_riwayat_pilih on public.menu_habis_riwayat
  for select to authenticated using (penyewa_id = (select public.penyewa_saya()));

revoke all on public.menu_habis_riwayat from public, anon, authenticated;
grant select on public.menu_habis_riwayat to authenticated, service_role;

-- Lapis 1: tolak segala ubah/hapus riwayat (pemilik pun ditolak pemicu ini).
create or replace function public.picu_menu_habis_riwayat_jaga()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  raise exception 'Riwayat penanda habis hanya-tambah — tidak boleh diubah atau dihapus.';
end
$$;

drop trigger if exists menu_habis_riwayat_jaga on public.menu_habis_riwayat;
create trigger menu_habis_riwayat_jaga
  before update or delete on public.menu_habis_riwayat
  for each row execute function public.picu_menu_habis_riwayat_jaga();

-- Lapis 2: pencatat otomatis dari SETIAP perubahan menu_cabang.habis.
create or replace function public.picu_menu_habis_catat()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  if (tg_op = 'INSERT' and new.habis)
     or (tg_op = 'UPDATE' and new.habis is distinct from old.habis) then
    select mi.penyewa_id into v_penyewa from public.menu_item mi where mi.id = new.menu_item_id;
    insert into public.menu_habis_riwayat (penyewa_id, menu_item_id, cabang_id, habis, pelaku_id)
    values (v_penyewa, new.menu_item_id, new.cabang_id, new.habis, auth.uid());
  end if;
  return new;
end
$$;

drop trigger if exists menu_habis_catat on public.menu_cabang;
create trigger menu_habis_catat
  after insert or update on public.menu_cabang
  for each row execute function public.picu_menu_habis_catat();

revoke all on function public.picu_menu_habis_riwayat_jaga() from public, anon, authenticated;
revoke all on function public.picu_menu_habis_catat() from public, anon, authenticated;

-- ============================================================================
-- RPC tandai_habis — pintu tombol dapur (TECH_SPEC §5 M5/M9).
-- ============================================================================
create or replace function public.tandai_habis(
  p_menu_item_id uuid,
  p_cabang_id     uuid,
  p_habis         boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  if not public.boleh('ubah_stok') then
    raise exception 'Anda tidak berizin mengubah stok.';
  end if;

  select mi.penyewa_id into v_penyewa
    from public.menu_item mi
    join public.cabang c on c.penyewa_id = mi.penyewa_id
   where mi.id = p_menu_item_id
     and c.id = p_cabang_id
     and mi.penyewa_id = public.penyewa_saya();
  if not found then
    raise exception 'Menu tidak ditemukan di resto ini.';
  end if;

  insert into public.menu_cabang (cabang_id, menu_item_id, habis)
  values (p_cabang_id, p_menu_item_id, p_habis)
  on conflict (cabang_id, menu_item_id)
    do update set habis = excluded.habis
    where menu_cabang.habis is distinct from excluded.habis;

  return jsonb_build_object('habis', p_habis);
end
$$;

comment on function public.tandai_habis(uuid, uuid, boolean) is
  'T4-05: menandai/mencabut menu habis pada satu cabang. Sumber kebenaran menu_cabang.habis; jejak siapa & kapan di menu_habis_riwayat. Menandai maupun mencabut butuh izin ubah_stok.';

revoke all on function public.tandai_habis(uuid, uuid, boolean) from public, anon;
grant execute on function public.tandai_habis(uuid, uuid, boolean) to authenticated, service_role;
