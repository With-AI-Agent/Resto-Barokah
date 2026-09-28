-- ============================================================================
-- 0032 — RIWAYAT STATUS ITEM DAPUR: anti-dobel, kekal, sinkron status pesanan
-- (T4-04, PRD M5; TECH_SPEC §9 ART-4 — State Machine & Alur Pesanan)
--
-- Keputusan tercatat di docs/DECISIONS_LOG.md [State Machine/2026-09-22].
-- Peta transisi (baru → dimasak → siap, tanpa lompat/mundur) SUDAH dijaga
-- picu_item_jaga (0015 — aturan terkunci ART-4), dan jalur sah itu TERBUKA untuk
-- peran yang boleh menyentuh baris pesanan termasuk kasir (kontrak uji
-- supabase/tes/status_item_transisi.sql). Berkas ini TIDAK mengubah peran mana
-- pun — yang ditambahkan adalah JEJAK dan ANTI-DOBEL yang sebelumnya tiada:
--
--   * Setiap transisi status item HANYA-TAMBAH direkam ke
--     pesanan_item_status_riwayat (siapa, kapan, dari → ke). Hak UPDATE/DELETE
--     dicabut + tanpa policy ubah/hapus = kekal.
--   * ANTI-DOBEL: pemicu pencatat hanya berbunyi bila status BENAR-BENAR berubah
--     (lihat WHEN-nya). Dua perangkat menandai item sama → SATU perubahan tercatat.
--   * RPC set_status_item = pembungkus rapi: kunci baris (FOR UPDATE), kembalikan
--     diubah=false untuk tanda dobel/ulangan (kunci idempoten), teruskan sisanya
--     ke mesin transisi 0015.
--   * Status pesanan maju mengikuti item: item pertama masak → pesanan 'dimasak';
--     seluruh item (non-batal) siap → pesanan 'siap'. Tidak sebelumnya.
-- ============================================================================

-- ------------------------------------------------------------- tabel riwayat
create table if not exists public.pesanan_item_status_riwayat (
  id                uuid primary key default gen_random_uuid(),
  pesanan_item_id   uuid not null references public.pesanan_item (id) on delete cascade,
  pesanan_id        uuid not null references public.pesanan (id) on delete cascade,
  dari              text not null,
  ke                text not null check (ke in ('dimasak', 'siap')),
  oleh_pengguna_id  uuid,
  kunci_idempoten   text,
  dibuat_pada       timestamptz not null default now()
);

comment on table public.pesanan_item_status_riwayat is
  'Jejak hanya-tambah perubahan status masak item (T4-04): siapa, kapan, dari → ke. Dua perangkat menandai item sama hanya menghasilkan satu baris.';

create unique index if not exists pesanan_item_status_riwayat_kunci_idx
  on public.pesanan_item_status_riwayat (kunci_idempoten) where kunci_idempoten is not null;
create index if not exists pesanan_item_status_riwayat_item_idx
  on public.pesanan_item_status_riwayat (pesanan_item_id);

alter table public.pesanan_item_status_riwayat enable row level security;

drop policy if exists riwayat_status_baca on public.pesanan_item_status_riwayat;
create policy riwayat_status_baca on public.pesanan_item_status_riwayat
  for select to authenticated
  using (public.pesanan_sepenyewa(pesanan_id));

drop policy if exists riwayat_status_tulis on public.pesanan_item_status_riwayat;
create policy riwayat_status_tulis on public.pesanan_item_status_riwayat
  for insert to authenticated
  with check (public.pesanan_sepenyewa(pesanan_id));
-- Sengaja TIDAK ada policy UPDATE/DELETE: di bawah RLS, tanpa policy = mustahil.

revoke all on table public.pesanan_item_status_riwayat from public, anon;
revoke update, delete on table public.pesanan_item_status_riwayat from authenticated;
grant select, insert on table public.pesanan_item_status_riwayat to authenticated;

-- ------------------------------- pencatat riwayat + pemajuan status pesanan
-- SECURITY DEFINER dengan search_path terkunci: pemicu ini perlu menulis riwayat
-- dan memajukan baris pesanan saat konteksnya peran 'dapur' — yang sengaja TIDAK
-- punya hak UPDATE umum di tabel pesanan (kebijakan pesanan_ubah 0009 tidak
-- memuat dapur; 0001–0014 beku). Fungsi pemicu tidak bisa dipanggil lewat SELECT,
-- dan yang ditulisnya hanya dua keadaan yang sudah SAH menurut mesin transisi 0015
-- dalam pernyataan yang sama. Peta transisi & pembatalan tetap milik 0015
-- (pemicu item_jaga, invoker — mata terbuka); pemicu ini hanya mencatat & menyinkronkan.
create or replace function public.picu_item_status_catat()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kunci text;
begin
  -- ANTI-DOBEL (lapis RPC): ulangan kiriman jaringan tidak dicatat dua kali.
  -- Pemicu ini hanya berbunyi saat status BENAR-BENAR berubah (lihat WHEN trigger).
  v_kunci := nullif(current_setting('resto.kunci_status_item', true), '');
  insert into public.pesanan_item_status_riwayat
    (pesanan_item_id, pesanan_id, dari, ke, oleh_pengguna_id, kunci_idempoten)
  values
    (new.id, new.pesanan_id, old.status, new.status, auth.uid(), v_kunci);

  -- Status pesanan mengikuti item: jangan sampai dapur dibilang 'siap' terlalu dini
  -- dan jangan sampai pesanan tertinggal 'dikirim' saat pengerjaan sudah berjalan.
  if new.status = 'dimasak' then
    update public.pesanan
       set status = 'dimasak'
     where id = new.pesanan_id and status = 'dikirim';
  elsif new.status = 'siap' then
    update public.pesanan
       set status = 'siap'
     where id = new.pesanan_id
       and status = 'dimasak'
       and not exists (select 1 from public.pesanan_item pi
                        where pi.pesanan_id = new.pesanan_id
                          and pi.status not in ('siap', 'batal'));
  end if;
  return new;
end
$$;

drop trigger if exists item_status_catat on public.pesanan_item;
create trigger item_status_catat
  after update of status on public.pesanan_item
  for each row
  when (old.status is distinct from new.status and new.status in ('dimasak', 'siap'))
  execute function public.picu_item_status_catat();

comment on function public.picu_item_status_catat() is
  'Pemicu pencatat riwayat status item + sinkron status pesanan (T4-04). Hanya berbunyi pada transisi nyata (WHEN status berubah) = anti-dobel dua perangkat.';

revoke all on function public.picu_item_status_catat() from public, anon, authenticated;

-- ------------------------------------------------- RPC pembungkus (idempoten)
create or replace function public.set_status_item(
  p_item_id uuid,
  p_status text,
  p_kunci_idempoten text default null
)
returns jsonb
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_status_lama text;
begin
  if p_status not in ('dimasak', 'siap') then
    raise exception 'set_status_item hanya menerima status dimasak atau siap (diterima: %).',
      coalesce(p_status, '(null)');
  end if;

  -- Ulangan kiriman jaringan (kunci sama) sudah pernah diproses → tidak diulang.
  if p_kunci_idempoten is not null
     and exists (select 1 from public.pesanan_item_status_riwayat k
                  where k.kunci_idempoten = p_kunci_idempoten) then
    return jsonb_build_object('berhasil', true, 'diubah', false,
                              'alasan', 'kunci idempoten sudah pernah diproses');
  end if;

  -- Kunci baris dulu: dua perangkat berebut antrian, bukan adu cepat.
  select pi.status into v_status_lama
    from public.pesanan_item pi
   where pi.id = p_item_id
   for update;
  if not found then
    raise exception 'Item pesanan % tidak ditemukan atau bukan milik resto Anda.', p_item_id;
  end if;

  if v_status_lama = p_status then
    return jsonb_build_object('berhasil', true, 'diubah', false,
                              'alasan', 'status sudah ' || p_status);
  end if;

  -- Peta transisi dijaga mesin 0015; pemicu pencatat menulis riwayat + sinkron.
  perform set_config('resto.kunci_status_item', coalesce(p_kunci_idempoten, ''), true);
  update public.pesanan_item set status = p_status where id = p_item_id;
  return jsonb_build_object('berhasil', true, 'diubah', true, 'status', p_status);
end
$$;

comment on function public.set_status_item(uuid, text, text) is
  'RPC T4-04: memajukan status masak satu item (baru → dimasak → siap) dengan kunci idempoten. Peta transisi dijaga picu_item_jaga (0015); riwayat hanya-tambah + sinkron pesanan ditulis pemicu picu_item_status_catat.';

revoke all on function public.set_status_item(uuid, text, text) from public, anon;
grant execute on function public.set_status_item(uuid, text, text) to authenticated;
