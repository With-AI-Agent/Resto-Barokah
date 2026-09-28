-- ============================================================================
-- MIGRASI 0028 — Tangga Pemulihan Perangkat Darurat & Kunci Induk (T1-36)
-- ============================================================================
-- Menutup tugas ROADMAP T1-36 (ART-11, TECH_SPEC §9 ART-11 & §5.1, docs/KEAMANAN.md §4b):
--   * Kehilangan seluruh perangkat owner/admin tidak menghentikan operasional resto.
--   * Kode pemulihan darurat sekali pakai (hanya hash bcrypt tersimpan di DB).
--   * Pendaftaran perangkat darurat dengan masa tenggang wajib 30 menit.
--   * Pembatalan pemulihan dapat dilakukan sebelum masa tenggang berakhir.
--   * Seluruh aktivitas tercatat di tabel catatan_audit.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Tabel Kredensial Pemulihan & Antrean Pemulihan
-- ---------------------------------------------------------------------------
create table if not exists public.kredensial_pemulihan (
  id                      uuid primary key default gen_random_uuid(),
  penyewa_id              uuid not null references public.penyewa (id) on delete cascade,
  kode_hash               text not null check (kode_hash ~ '^\$[a-z0-9]+\$'),
  dibuat_pada             timestamptz not null default now(),
  dibuat_oleh             uuid references public.pengguna (id) on delete set null,
  terpakai                boolean not null default false,
  terpakai_pada           timestamptz,
  terpakai_oleh_perangkat uuid references public.perangkat (id) on delete set null
);

comment on table public.kredensial_pemulihan is
  'Hash bcrypt kode pemulihan darurat (T1-36). Hanya jalur peladen/definer yang menyentuh, tanpa grant klien.';

create table if not exists public.pemulihan_perangkat (
  id               uuid primary key default gen_random_uuid(),
  penyewa_id       uuid not null references public.penyewa (id) on delete cascade,
  perangkat_id     uuid not null references public.perangkat (id) on delete cascade,
  pemohon_id       uuid not null references public.pengguna (id) on delete restrict,
  diminta_pada     timestamptz not null default now(),
  aktif_setelah    timestamptz not null default (now() + interval '30 minutes'),
  status           text not null default 'menunggu' check (status in ('menunggu', 'selesai', 'dibatalkan')),
  dibatalkan_oleh  uuid references public.pengguna (id) on delete set null,
  dibatalkan_pada  timestamptz,
  alasan_batal     text,
  diselesaikan_pada timestamptz
);

comment on table public.pemulihan_perangkat is
  'Antrean pemulihan darurat perangkat dengan masa tenggang 30 menit (T1-36).';

-- RLS untuk kedua tabel
revoke all on table public.kredensial_pemulihan from public, anon, authenticated;
revoke all on table public.pemulihan_perangkat from public, anon, authenticated;

alter table public.kredensial_pemulihan enable row level security;
alter table public.pemulihan_perangkat enable row level security;

-- Policy kredensial_pemulihan: tolak semua untuk klien
drop policy if exists kredensial_pemulihan_tolak_semua on public.kredensial_pemulihan;
create policy kredensial_pemulihan_tolak_semua on public.kredensial_pemulihan
  for select to authenticated, anon using (false);

-- Policy pemulihan_perangkat: baca hanya pengelola (InitPlan subquery)
grant select on table public.pemulihan_perangkat to authenticated;
grant select, insert, update, delete on table public.pemulihan_perangkat to service_role;
grant select, insert, update, delete on table public.kredensial_pemulihan to service_role;

drop policy if exists pemulihan_perangkat_pilih on public.pemulihan_perangkat;
create policy pemulihan_perangkat_pilih on public.pemulihan_perangkat
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('kelola_pegawai'))
  );

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — RPC buat_kode_pemulihan (hanya owner_pusat)
-- ---------------------------------------------------------------------------
create or replace function public.buat_kode_pemulihan(p_kode text)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya      uuid := auth.uid();
  v_penyewa   uuid := public.penyewa_saya();
  v_peran     text := public.peran_saya();
  v_hash      text;
  v_id        uuid;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;
  if v_penyewa is null or v_peran <> 'owner_pusat' then
    raise exception 'Hanya owner_pusat yang berhak membuat atau memperbarui kode pemulihan darurat.';
  end if;
  if p_kode is null or length(trim(p_kode)) < 20 then
    raise exception 'Kode pemulihan darurat harus memiliki panjang minimal 20 karakter.';
  end if;

  -- Nonaktifkan / batalkan kode pemulihan sebelumnya yang belum terpakai
  update public.kredensial_pemulihan
     set terpakai = true,
         terpakai_pada = now()
   where penyewa_id = v_penyewa
     and not terpakai;

  v_hash := crypt(trim(p_kode), gen_salt('bf', 10));

  insert into public.kredensial_pemulihan (penyewa_id, kode_hash, dibuat_oleh)
  values (v_penyewa, v_hash, v_saya)
  returning id into v_id;

  -- Catat audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    v_saya,
    'buat_kode_pemulihan',
    'kredensial_pemulihan',
    v_id,
    jsonb_build_object('dibuat_pada', now())
  );

  return 'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.';
end;
$$;

comment on function public.buat_kode_pemulihan(text) is
  'Membuat kode pemulihan darurat baru (hanya owner_pusat). Kode lama yang belum terpakai otomatis dibatalkan. Hash bcrypt disimpan aman.';

revoke all on function public.buat_kode_pemulihan(text) from public;
grant execute on function public.buat_kode_pemulihan(text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — RPC pulihkan_perangkat (pendaftaran perangkat darurat)
-- ---------------------------------------------------------------------------
create or replace function public.pulihkan_perangkat(
  p_kode_pemulihan text,
  p_nama           text,
  p_kunci          text,
  p_cabang_id      uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya          uuid := auth.uid();
  v_penyewa       uuid := public.penyewa_saya();
  v_peran         text := public.peran_saya();
  v_kredensial_id uuid;
  v_perangkat_id  uuid;
  v_pemulihan_id  uuid;
  r_kred          record;
  v_cocok         boolean := false;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;
  if v_penyewa is null or v_peran <> 'owner_pusat' then
    raise exception 'Hanya owner_pusat yang berhak mengajukan pemulihan perangkat darurat.';
  end if;
  if p_kode_pemulihan is null or length(trim(p_kode_pemulihan)) < 20 then
    raise exception 'Kode pemulihan darurat tidak valid.';
  end if;
  if p_nama is null or length(trim(p_nama)) = 0 then
    raise exception 'Nama perangkat darurat wajib diisi.';
  end if;
  if p_kunci is null or length(p_kunci) < 16 then
    raise exception 'Kunci perangkat darurat minimal 16 karakter.';
  end if;
  if p_cabang_id is null or not public.cabang_pantau_saya(p_cabang_id) then
    raise exception 'Cabang tidak valid atau bukan cabang yang Anda kelola.';
  end if;

  -- Cari kode pemulihan aktif yang cocok
  for r_kred in
    select id, kode_hash
      from public.kredensial_pemulihan
     where penyewa_id = v_penyewa
       and not terpakai
     order by dibuat_pada desc
  loop
    if crypt(trim(p_kode_pemulihan), r_kred.kode_hash) = r_kred.kode_hash then
      v_cocok := true;
      v_kredensial_id := r_kred.id;
      exit;
    end if;
  end loop;

  if not v_cocok then
    -- Catat kegagalan audit
    insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, nilai_baru)
    values (
      v_penyewa,
      v_saya,
      'gagal_pulihkan_perangkat',
      'pemulihan_perangkat',
      jsonb_build_object('alasan', 'Kode pemulihan salah atau telah terpakai')
    );
    raise exception 'Kode pemulihan darurat tidak valid atau sudah pernah dipakai.';
  end if;

  -- Daftarkan perangkat dengan status nonaktif (aktif = false selama masa tenggang)
  insert into public.perangkat (penyewa_id, cabang_id, nama, aktif, didaftarkan_oleh)
  values (v_penyewa, p_cabang_id, trim(p_nama), false, v_saya)
  returning id into v_perangkat_id;

  -- Simpan hash kunci perangkat
  insert into public.kredensial_perangkat (perangkat_id, kunci_hash)
  values (v_perangkat_id, crypt(p_kunci, gen_salt('bf', 10)));

  -- Masukkan ke antrean pemulihan dengan masa tenggang 30 menit
  insert into public.pemulihan_perangkat (
    penyewa_id,
    perangkat_id,
    pemohon_id,
    diminta_pada,
    aktif_setelah,
    status
  )
  values (
    v_penyewa,
    v_perangkat_id,
    v_saya,
    now(),
    now() + interval '30 minutes',
    'menunggu'
  )
  returning id into v_pemulihan_id;

  -- Tandai kode pemulihan sebagai terpakai
  update public.kredensial_pemulihan
     set terpakai = true,
         terpakai_pada = now(),
         terpakai_oleh_perangkat = v_perangkat_id
   where id = v_kredensial_id;

  -- Catat audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    v_saya,
    'pulihkan_perangkat_diajukan',
    'pemulihan_perangkat',
    v_pemulihan_id,
    jsonb_build_object(
      'perangkat_id', v_perangkat_id,
      'nama_perangkat', trim(p_nama),
      'aktif_setelah', now() + interval '30 minutes'
    )
  );

  return v_pemulihan_id;
end;
$$;

comment on function public.pulihkan_perangkat(text, text, text, uuid) is
  'Mendaftarkan perangkat darurat dengan masa tenggang 30 menit. Kode pemulihan diverifikasi dan ditandai terpakai (sekali pakai).';

revoke all on function public.pulihkan_perangkat(text, text, text, uuid) from public;
grant execute on function public.pulihkan_perangkat(text, text, text, uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — RPC batalkan_pemulihan (sebelum 30 menit)
-- ---------------------------------------------------------------------------
create or replace function public.batalkan_pemulihan(
  p_pemulihan_id uuid,
  p_alasan       text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya       uuid := auth.uid();
  v_penyewa    uuid := public.penyewa_saya();
  v_perangkat  uuid;
  v_status     text;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;
  if v_penyewa is null or not public.boleh('kelola_pegawai') then
    raise exception 'Hanya pemegang izin kelola_pegawai yang boleh membatalkan pemulihan perangkat.';
  end if;

  select perangkat_id, status
    into v_perangkat, v_status
    from public.pemulihan_perangkat
   where id = p_pemulihan_id
     and penyewa_id = v_penyewa;

  if v_status is null then
    raise exception 'Permohonan pemulihan tidak ditemukan.';
  end if;
  if v_status <> 'menunggu' then
    raise exception 'Permohonan pemulihan sudah tidak dalam status menunggu.';
  end if;

  update public.pemulihan_perangkat
     set status = 'dibatalkan',
         dibatalkan_oleh = v_saya,
         dibatalkan_pada = now(),
         alasan_batal = coalesce(trim(p_alasan), 'Dibatalkan oleh pengelola.')
   where id = p_pemulihan_id;

  -- Pastikan perangkat tetap tidak aktif
  update public.perangkat
     set aktif = false
   where id = v_perangkat;

  -- Catat audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    v_saya,
    'batalkan_pemulihan',
    'pemulihan_perangkat',
    p_pemulihan_id,
    jsonb_build_object(
      'perangkat_id', v_perangkat,
      'alasan_batal', coalesce(trim(p_alasan), 'Dibatalkan oleh pengelola.')
    )
  );

  return true;
end;
$$;

comment on function public.batalkan_pemulihan(uuid, text) is
  'Membatalkan permohonan pemulihan perangkat darurat dalam masa tenggang.';

revoke all on function public.batalkan_pemulihan(uuid, text) from public;
grant execute on function public.batalkan_pemulihan(uuid, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 5 — RPC selesaikan_pemulihan (setelah masa tenggang 30 menit)
-- ---------------------------------------------------------------------------
create or replace function public.selesaikan_pemulihan(p_pemulihan_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya          uuid := auth.uid();
  v_penyewa       uuid := public.penyewa_saya();
  v_perangkat_id  uuid;
  v_aktif_setelah timestamptz;
  v_status        text;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;
  if v_penyewa is null or not public.boleh('kelola_pegawai') then
    raise exception 'Hanya pemegang izin kelola_pegawai yang boleh menyelesaikan aktivasi pemulihan perangkat.';
  end if;

  select perangkat_id, aktif_setelah, status
    into v_perangkat_id, v_aktif_setelah, v_status
    from public.pemulihan_perangkat
   where id = p_pemulihan_id
     and penyewa_id = v_penyewa;

  if v_status is null then
    raise exception 'Permohonan pemulihan tidak ditemukan.';
  end if;
  if v_status <> 'menunggu' then
    raise exception 'Permohonan pemulihan sudah tidak dalam status menunggu.';
  end if;
  if now() < v_aktif_setelah then
    raise exception 'Masa tenggang 30 menit belum berakhir. Perangkat darurat baru dapat diaktifkan setelah %.', v_aktif_setelah;
  end if;

  update public.pemulihan_perangkat
     set status = 'selesai',
         diselesaikan_pada = now()
   where id = p_pemulihan_id;

  update public.perangkat
     set aktif = true
   where id = v_perangkat_id;

  -- Catat audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    v_saya,
    'selesaikan_pemulihan',
    'pemulihan_perangkat',
    p_pemulihan_id,
    jsonb_build_object(
      'perangkat_id', v_perangkat_id,
      'diaktifkan_pada', now()
    )
  );

  return true;
end;
$$;

comment on function public.selesaikan_pemulihan(uuid) is
  'Mengaktifkan perangkat darurat setelah masa tenggang 30 menit berlalu.';

revoke all on function public.selesaikan_pemulihan(uuid) from public;
grant execute on function public.selesaikan_pemulihan(uuid) to authenticated, service_role;
