-- ============================================================================
-- MIGRASI 0058 — Penegakan Keaktifan Sesi & Pencabutan Perangkat (N F-03)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-03: Pencabutan perangkat/sesi tidak
--     diperiksa pada permintaan berikutnya (umur maksimum sesi tidak ditegakkan).
--   - docs/KEAMANAN.md §4: "semua pemeriksaan perangkat/sesi dilakukan di database
--     pada setiap permintaan."
--   - docs/TECH_SPEC.md §9 ART-1 & ART-11/12 (T1-25)
--
-- Solusi:
--   1. Fungsi public.sesi_masih_aktif() memvalidasi apakah session_id dan/atau
--      perangkat_id yang dibawa oleh token pemanggil masih aktif, belum kedaluwarsa,
--      dan perangkatnya tidak dicabut.
--   2. Fungsi identitas inti (penyewa_saya, peran_saya, cabang_saya, cabang_ids_saya)
--      mengintegrasikan public.sesi_masih_aktif() sehingga ketika sesi/perangkat
--      dicabut atau umur maksimum terlewati, identitas otomatis gugur (NULL),
--      menyebabkan seluruh RLS menolak akses seketika.
--   3. RPC akhiri_sesi() ditambahkan untuk melengkapi penutupan sesi tunggal.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Fungsi Pemeriksa Keaktifan Sesi: public.sesi_masih_aktif()
-- ---------------------------------------------------------------------------
create or replace function public.sesi_masih_aktif()
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_role text;
  v_uid  uuid;
  v_jwt  jsonb;
  v_session_id text;
  v_perangkat_id text;
  v_header_perangkat text;
begin
  -- 1. Jalur peladen / service_role bypass
  v_role := current_setting('role', true);
  if v_role = 'service_role' or public.jalur_peladen_terverifikasi() then
    return true;
  end if;

  v_uid := auth.uid();
  if v_uid is null then
    return false;
  end if;

  -- 2. Baca JWT claims
  v_jwt := auth.jwt();
  v_session_id := nullif(v_jwt ->> 'session_id', '');
  v_perangkat_id := nullif(v_jwt ->> 'perangkat_id', '');

  -- 3. Baca header x-perangkat-id bila tersedia
  begin
    v_header_perangkat := nullif(current_setting('request.headers', true)::jsonb ->> 'x-perangkat-id', '');
  exception when others then
    v_header_perangkat := null;
  end;

  -- 4. Pemeriksaan sesi_perangkat bila session_id ada di token
  if v_session_id is not null then
    if not exists (
      select 1
        from public.sesi_perangkat sp
        join public.perangkat p on p.id = sp.perangkat_id
       where sp.session_id = v_session_id
         and sp.pengguna_id = v_uid
         and sp.status = 'aktif'
         and sp.berakhir_pada > now()
         and p.aktif = true
    ) then
      return false;
    end if;
  end if;

  -- 5. Pemeriksaan status perangkat bila perangkat_id ada di token
  if v_perangkat_id is not null then
    if not exists (
      select 1
        from public.perangkat p
       where p.id = v_perangkat_id::uuid
         and p.aktif = true
    ) then
      return false;
    end if;
  end if;

  -- 6. Pemeriksaan status perangkat bila x-perangkat-id ada di header
  if v_header_perangkat is not null then
    if not exists (
      select 1
        from public.perangkat p
       where p.id = v_header_perangkat::uuid
         and p.aktif = true
    ) then
      return false;
    end if;
  end if;

  return true;
end;
$$;

comment on function public.sesi_masih_aktif() is
  'Memeriksa apakah sesi dan perangkat pemanggil masih aktif dan belum kedaluwarsa (T1-25 / N F-03).';

revoke all on function public.sesi_masih_aktif() from public;
grant execute on function public.sesi_masih_aktif() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Integrasikan sesi_masih_aktif ke penyewa_saya() & peran_saya()
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
     and public.sesi_masih_aktif()
$$;

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
     and public.sesi_masih_aktif()
$$;

create or replace function public.cabang_saya()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select sc.cabang_id
    from public.sesi_cabang sc
    join public.pengguna_cabang pc
      on pc.pengguna_id = sc.pengguna_id
     and pc.cabang_id = sc.cabang_id
     and pc.aktif
    join public.pengguna p on p.id = sc.pengguna_id and p.aktif   -- akun nonaktif kehilangan akses
   where sc.pengguna_id = auth.uid()
     and public.sesi_masih_aktif()
   limit 1
$$;

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
    join public.pengguna p on p.id = pc.pengguna_id and p.aktif
   where pc.pengguna_id = auth.uid()
     and pc.aktif
     and public.sesi_masih_aktif()
$$;

-- ---------------------------------------------------------------------------
-- 3. RPC akhiri_sesi(p_session_id)
-- ---------------------------------------------------------------------------
create or replace function public.akhiri_sesi(
  p_session_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sid text := coalesce(p_session_id, nullif(auth.jwt() ->> 'session_id', ''));
  v_uid uuid := auth.uid();
  v_jml int;
begin
  if v_uid is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Autentikasi diperlukan.');
  end if;

  if v_sid is null then
    return jsonb_build_object('berhasil', false, 'kode', 'INVALID_INPUT', 'pesan', 'Session ID tidak ditentukan.');
  end if;

  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where session_id = v_sid
     and (pengguna_id = v_uid or public.boleh('kelola_pegawai'));

  get diagnostics v_jml = row_count;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SESI_DIAKHIRI',
    'pesan', 'Sesi berhasil diakhiri.',
    'data', jsonb_build_object('jumlah', v_jml)
  );
end;
$$;

comment on function public.akhiri_sesi(text) is
  'Mengakhiri sesi tertentu milik sendiri atau bawahan bila berizin kelola_pegawai (T1-25).';

revoke all on function public.akhiri_sesi(text) from public;
grant execute on function public.akhiri_sesi(text) to authenticated, service_role;
