-- ============================================================================
-- MIGRASI 0031 — Mode Dukungan Pemilik Platform (T1-28, ART-15)
-- ============================================================================
-- Aturan ART-15:
--   * Pemilik platform secara bawaan TIDAK BISA membaca atau melihat data penyewa.
--   * Akses hanya dibuka lewat mode dukungan: beralasan (min 10 karakter),
--     berbatas waktu (bawaan 60 menit, maks 120 menit), dan HANYA-BACA (read-only).
--   * Seluruh pembukaan & penutupan mode dukungan tercatat di catatan_audit resto.
--   * Berakhir otomatis saat waktu habis atau saat keluar_mode_dukungan dipanggil.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Tabel public.mode_dukungan
-- ---------------------------------------------------------------------------
create table if not exists public.mode_dukungan (
  id            uuid primary key default gen_random_uuid(),
  penyewa_id    uuid not null references public.penyewa (id) on delete cascade,
  pelaku_id     uuid not null references public.pengguna (id) on delete cascade,
  alasan        text not null check (length(trim(alasan)) >= 10),
  mulai         timestamptz not null default now(),
  berakhir_pada timestamptz not null,
  aktif         boolean not null default true,
  diakhiri_pada timestamptz
);

comment on table public.mode_dukungan is
  'Sesi mode dukungan darurat pemilik platform ke penyewa tertentu (T1-28, ART-15). Beralasan, berbatas waktu, dan hanya-baca.';

create index if not exists idx_mode_dukungan_pelaku_aktif
  on public.mode_dukungan (pelaku_id, penyewa_id, aktif, berakhir_pada);

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — RLS untuk mode_dukungan
-- ---------------------------------------------------------------------------
alter table public.mode_dukungan enable row level security;

-- Pemilik platform melihat sesinya sendiri; Owner pusat melihat riwayat dukungan untuk restonya
create policy mode_dukungan_pilih on public.mode_dukungan
  for select to authenticated
  using (
    pelaku_id = (select auth.uid())
    or penyewa_id = (select public.penyewa_saya())
  );

revoke insert, update, delete on table public.mode_dukungan from authenticated, anon, public;
grant select on public.mode_dukungan to authenticated;

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — Pembaruan penyewa_saya() untuk Mendukung Mode Dukungan
-- ---------------------------------------------------------------------------
create or replace function public.penyewa_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    p.penyewa_id,
    (
      select md.penyewa_id
        from public.mode_dukungan md
       where md.pelaku_id = p.id
         and md.aktif
         and md.berakhir_pada > now()
       order by md.mulai desc
       limit 1
    )
  )
    from public.pengguna p
   where p.id = auth.uid()
     and p.aktif
$$;

comment on function public.penyewa_saya() is
  'Penyewa milik pengguna, atau penyewa target mode dukungan aktif bila pemanggil adalah pemilik_platform (T1-28).';

revoke all on function public.penyewa_saya() from public;
grant execute on function public.penyewa_saya() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — Fungsi Pemeriksa Status Mode Dukungan
-- ---------------------------------------------------------------------------
create or replace function public.mode_dukungan_aktif(p_penyewa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.mode_dukungan md
      join public.pengguna p on p.id = md.pelaku_id
     where md.penyewa_id = p_penyewa_id
       and md.pelaku_id = auth.uid()
       and p.peran = 'pemilik_platform'
       and p.aktif
       and md.aktif
       and md.berakhir_pada > now()
  )
$$;

comment on function public.mode_dukungan_aktif(uuid) is
  'Memeriksa apakah pemilik_platform yang sedang login memiliki mode dukungan aktif untuk penyewa tertentu (T1-28).';

revoke all on function public.mode_dukungan_aktif(uuid) from public;
grant execute on function public.mode_dukungan_aktif(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 5 — RPC masuk_mode_dukungan & keluar_mode_dukungan
-- ---------------------------------------------------------------------------

create or replace function public.masuk_mode_dukungan(
  p_penyewa_id    uuid,
  p_alasan        text,
  p_durasi_menit  int default 60
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya        uuid := auth.uid();
  v_peran       text := public.peran_saya();
  v_penyewa_ada boolean;
  v_durasi      int;
  v_berakhir    timestamptz;
  v_id          uuid;
begin
  if v_saya is null or v_peran <> 'pemilik_platform' then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Hanya pemilik platform yang berhak masuk mode dukungan.');
  end if;

  if p_alasan is null or length(trim(p_alasan)) < 10 then
    return jsonb_build_object('berhasil', false, 'kode', 'ALASAN_KURANG', 'pesan', 'Alasan mode dukungan wajib diisi minimal 10 karakter.');
  end if;

  select exists(select 1 from public.penyewa where id = p_penyewa_id) into v_penyewa_ada;
  if not v_penyewa_ada then
    return jsonb_build_object('berhasil', false, 'kode', 'PENYEWA_TIDAK_DITEMUKAN', 'pesan', 'Restoran penyewa tidak ditemukan.');
  end if;

  -- Batasi durasi: minimum 15 menit, maksimum 120 menit (bawaan 60 menit)
  v_durasi := coalesce(p_durasi_menit, 60);
  if v_durasi < 15 or v_durasi > 120 then
    return jsonb_build_object('berhasil', false, 'kode', 'DURASI_TIDAK_VALID', 'pesan', 'Durasi mode dukungan harus antara 15 hingga 120 menit.');
  end if;

  v_berakhir := now() + (v_durasi || ' minutes')::interval;

  -- Tutup sesi dukungan aktif sebelumnya dari pelaku yang sama untuk penyewa ini
  update public.mode_dukungan
     set aktif = false,
         diakhiri_pada = now()
   where pelaku_id = v_saya
     and penyewa_id = p_penyewa_id
     and aktif;

  -- Buat sesi mode dukungan baru
  insert into public.mode_dukungan (
    penyewa_id, pelaku_id, alasan, mulai, berakhir_pada, aktif
  ) values (
    p_penyewa_id, v_saya, trim(p_alasan), now(), v_berakhir, true
  ) returning id into v_id;

  -- Catat ke catatan audit restoran yang dituju (ART-15)
  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
  ) values (
    p_penyewa_id, v_saya, 'masuk_mode_dukungan', 'mode_dukungan', v_id,
    jsonb_build_object(
      'alasan', trim(p_alasan),
      'durasi_menit', v_durasi,
      'berakhir_pada', v_berakhir
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'MODE_DUKUNGAN_AKTIF',
    'pesan', format('Mode dukungan aktif selama %s menit. Akses data hanya-baca (read-only).', v_durasi),
    'data', jsonb_build_object(
      'id', v_id,
      'penyewa_id', p_penyewa_id,
      'berakhir_pada', v_berakhir,
      'durasi_menit', v_durasi
    )
  );
end;
$$;

comment on function public.masuk_mode_dukungan(uuid, text, int) is
  'Mengaktifkan mode dukungan darurat berbatas waktu & beralasan untuk pemilik platform (T1-28, ART-15).';

revoke all on function public.masuk_mode_dukungan(uuid, text, int) from public;
grant execute on function public.masuk_mode_dukungan(uuid, text, int) to authenticated, service_role;

create or replace function public.keluar_mode_dukungan(
  p_penyewa_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya   uuid := auth.uid();
  v_peran  text := public.peran_saya();
  v_jumlah int;
  r        record;
begin
  if v_saya is null or v_peran <> 'pemilik_platform' then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Hanya pemilik platform yang berhak keluar mode dukungan.');
  end if;

  for r in
    select id, penyewa_id
      from public.mode_dukungan
     where pelaku_id = v_saya
       and aktif
       and (p_penyewa_id is null or penyewa_id = p_penyewa_id)
  loop
    update public.mode_dukungan
       set aktif = false,
           diakhiri_pada = now()
     where id = r.id;

    -- Catat jejak audit keluar
    insert into public.catatan_audit (
      penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
    ) values (
      r.penyewa_id, v_saya, 'keluar_mode_dukungan', 'mode_dukungan', r.id,
      jsonb_build_object('diakhiri_pada', now())
    );
  end loop;

  get diagnostics v_jumlah = row_count;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'MODE_DUKUNGAN_BERAKHIR',
    'pesan', 'Mode dukungan telah diakhiri. Akses data penyewa kembali tertutup.'
  );
end;
$$;

comment on function public.keluar_mode_dukungan(uuid) is
  'Mengakhiri sesi mode dukungan aktif milik pemilik platform (T1-28, ART-15).';

revoke all on function public.keluar_mode_dukungan(uuid) from public;
grant execute on function public.keluar_mode_dukungan(uuid) to authenticated, service_role;
