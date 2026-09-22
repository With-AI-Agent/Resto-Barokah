-- ============================================================================
-- MIGRASI 0030 — Sesi Perangkat, Kode Pendaftaran, & Percobaan Masuk
-- (T1-24, T1-25, T1-26, ART-11 & ART-12)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Kolom Tambahan pada Tabel public.perangkat
-- ---------------------------------------------------------------------------
alter table public.perangkat
  add column if not exists jenis text not null default 'pos'
    check (jenis in ('pos', 'tablet_kasir', 'tablet_pelayan', 'display_dapur', 'perangkat_admin', 'hp_owner')),
  add column if not exists peran_diizinkan text[] not null
    default array['kasir', 'pelayan', 'dapur', 'admin_cabang', 'owner_pusat']::text[],
  add column if not exists status text not null default 'aktif'
    check (status in ('aktif', 'dicabut', 'hilang')),
  add column if not exists terakhir_aktif timestamptz not null default now(),
  add column if not exists dicabut_oleh uuid references public.pengguna (id) on delete set null,
  add column if not exists dicabut_pada timestamptz,
  add column if not exists catatan text;

-- Indeks status perangkat per penyewa
create index if not exists idx_perangkat_penyewa_status
  on public.perangkat (penyewa_id, status);

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Tabel kode_pendaftaran_perangkat (T1-24)
-- ---------------------------------------------------------------------------
create table if not exists public.kode_pendaftaran_perangkat (
  id               uuid primary key default gen_random_uuid(),
  penyewa_id       uuid not null references public.penyewa (id) on delete cascade,
  cabang_id        uuid not null references public.cabang (id) on delete restrict,
  kode             text not null,
  nama_perangkat   text not null,
  jenis            text not null default 'pos'
    check (jenis in ('pos', 'tablet_kasir', 'tablet_pelayan', 'display_dapur', 'perangkat_admin', 'hp_owner')),
  peran_diizinkan  text[] not null default array['kasir', 'pelayan', 'dapur']::text[],
  kedaluwarsa_pada timestamptz not null default (now() + interval '15 minutes'),
  dibuat_oleh      uuid not null references public.pengguna (id) on delete cascade,
  dibuat_pada      timestamptz not null default now(),
  dipakai_pada     timestamptz,
  perangkat_id     uuid references public.perangkat (id) on delete set null
);

comment on table public.kode_pendaftaran_perangkat is
  'Kode sekali pakai pendaftaran perangkat baru (T1-24). Masa berlaku 15 menit.';

create unique index if not exists uq_kode_pendaftaran_aktif
  on public.kode_pendaftaran_perangkat (kode)
  where (dipakai_pada is null);

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — Tabel persetujuan_perangkat (T1-24)
-- ---------------------------------------------------------------------------
create table if not exists public.persetujuan_perangkat (
  id             uuid primary key default gen_random_uuid(),
  penyewa_id     uuid not null references public.penyewa (id) on delete cascade,
  perangkat_id   uuid not null references public.perangkat (id) on delete cascade,
  pengguna_id    uuid not null references public.pengguna (id) on delete cascade,
  disetujui_oleh uuid not null references public.pengguna (id) on delete cascade,
  waktu          timestamptz not null default now()
);

comment on table public.persetujuan_perangkat is
  'Persetujuan pemilik/admin saat pegawai pertama kali memakai perangkat tertentu (T1-24).';

create unique index if not exists uq_persetujuan_perangkat_pegawai
  on public.persetujuan_perangkat (perangkat_id, pengguna_id);

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — Tabel sesi_perangkat (T1-25)
-- ---------------------------------------------------------------------------
create table if not exists public.sesi_perangkat (
  session_id     text primary key,
  penyewa_id     uuid not null references public.penyewa (id) on delete cascade,
  perangkat_id   uuid not null references public.perangkat (id) on delete cascade,
  pengguna_id    uuid not null references public.pengguna (id) on delete cascade,
  cabang_id      uuid not null references public.cabang (id) on delete restrict,
  mulai          timestamptz not null default now(),
  berakhir_pada  timestamptz not null,
  status         text not null default 'aktif' check (status in ('aktif', 'selesai', 'dicabut')),
  disetujui_oleh uuid references public.pengguna (id) on delete set null,
  diperbarui_pada timestamptz not null default now()
);

comment on table public.sesi_perangkat is
  'Sesi login pada perangkat terdaftar dengan umur maksimum dan pencabutan seketika (T1-25).';

create index if not exists idx_sesi_perangkat_status
  on public.sesi_perangkat (perangkat_id, status);

create index if not exists idx_sesi_pengguna_status
  on public.sesi_perangkat (pengguna_id, status);

-- ---------------------------------------------------------------------------
-- BAGIAN 5 — Tabel percobaan_masuk (T1-26)
-- ---------------------------------------------------------------------------
create table if not exists public.percobaan_masuk (
  id           uuid primary key default gen_random_uuid(),
  penyewa_id   uuid references public.penyewa (id) on delete cascade,
  pengguna_id  uuid references public.pengguna (id) on delete cascade,
  perangkat_id uuid references public.perangkat (id) on delete cascade,
  berhasil     boolean not null,
  sebab        text,
  waktu        timestamptz not null default now()
);

comment on table public.percobaan_masuk is
  'Semua percobaan autentikasi staf dan perangkat (T1-26). Dasar pembatas 5x akun & 12x perangkat per 15 menit.';

create index if not exists idx_percobaan_masuk_pengguna
  on public.percobaan_masuk (pengguna_id, waktu desc);

create index if not exists idx_percobaan_masuk_perangkat
  on public.percobaan_masuk (perangkat_id, waktu desc);

-- ---------------------------------------------------------------------------
-- BAGIAN 6 — RLS & Kebijakan Akses untuk Tabel Baru
-- ---------------------------------------------------------------------------
alter table public.kode_pendaftaran_perangkat enable row level security;
alter table public.persetujuan_perangkat enable row level security;
alter table public.sesi_perangkat enable row level security;
alter table public.percobaan_masuk enable row level security;

-- kode_pendaftaran_perangkat: hanya pemegang izin kelola_pegawai se-resto
create policy kode_pendaftaran_pilih on public.kode_pendaftaran_perangkat
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('kelola_pegawai'))
  );

-- persetujuan_perangkat: baca se-resto untuk staf yang bertugas di resto itu
create policy persetujuan_perangkat_pilih on public.persetujuan_perangkat
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

-- sesi_perangkat: pengguna melihat sesinya sendiri, pemegang kelola_pegawai melihat se-resto
create policy sesi_perangkat_pilih on public.sesi_perangkat
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (
      pengguna_id = (select auth.uid())
      or (select public.boleh('kelola_pegawai'))
    )
  );

-- percobaan_masuk: hanya pemegang izin kelola_pegawai / admin
create policy percobaan_masuk_pilih on public.percobaan_masuk
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('kelola_pegawai'))
  );

-- Klien tidak boleh INSERT/UPDATE/DELETE langsung ke tabel-tabel ini (wajib via RPC)
revoke insert, update, delete on table public.kode_pendaftaran_perangkat from authenticated, anon, public;
revoke insert, update, delete on table public.persetujuan_perangkat from authenticated, anon, public;
revoke insert, update, delete on table public.sesi_perangkat from authenticated, anon, public;
revoke insert, update, delete on table public.percobaan_masuk from authenticated, anon, public;

grant select on public.kode_pendaftaran_perangkat to authenticated;
grant select on public.persetujuan_perangkat to authenticated;
grant select on public.sesi_perangkat to authenticated;
grant select on public.percobaan_masuk to authenticated;

-- ---------------------------------------------------------------------------
-- BAGIAN 7 — RPC Fungsi Pendaftaran & Pengelolaan Perangkat (T1-24)
-- ---------------------------------------------------------------------------

-- RPC 1: buat_kode_perangkat
create or replace function public.buat_kode_perangkat(
  p_cabang_id       uuid,
  p_nama_perangkat  text,
  p_jenis           text default 'pos',
  p_peran_diizinkan text[] default array['kasir', 'pelayan', 'dapur']::text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_saya    uuid := auth.uid();
  v_kode    text;
  v_id      uuid;
  v_cabang  uuid;
begin
  if v_penyewa is null or v_saya is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Sesi autentikasi tidak sah.');
  end if;

  if not public.boleh('kelola_pegawai') then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Anda tidak memiliki hak kelola pegawai/perangkat.');
  end if;

  -- Pastikan cabang valid milik penyewa ini
  select id into v_cabang
    from public.cabang
   where id = p_cabang_id
     and penyewa_id = v_penyewa
     and aktif;

  if v_cabang is null then
    return jsonb_build_object('berhasil', false, 'kode', 'CABANG_TIDAK_VALID', 'pesan', 'Cabang tujuan tidak ditemukan atau nonaktif.');
  end if;

  -- Buat 8 karakter acak (angka & huruf kapital)
  v_kode := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  insert into public.kode_pendaftaran_perangkat (
    penyewa_id, cabang_id, kode, nama_perangkat, jenis, peran_diizinkan, dibuat_oleh
  ) values (
    v_penyewa, v_cabang, v_kode, trim(p_nama_perangkat), p_jenis, p_peran_diizinkan, v_saya
  ) returning id into v_id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'KODE_DIBUAT',
    'pesan', 'Kode pendaftaran perangkat berhasil dibuat. Berlaku selama 15 menit.',
    'data', jsonb_build_object(
      'id', v_id,
      'kode', v_kode,
      'kedaluwarsa_pada', now() + interval '15 minutes'
    )
  );
end;
$$;

comment on function public.buat_kode_perangkat(uuid, text, text, text[]) is
  'Membuat kode sekali pakai pendaftaran perangkat baru dengan masa berlaku 15 menit (T1-24).';

revoke all on function public.buat_kode_perangkat(uuid, text, text, text[]) from public;
grant execute on function public.buat_kode_perangkat(uuid, text, text, text[]) to authenticated, service_role;

-- RPC 2: daftarkan_perangkat_dengan_kode
create or replace function public.daftarkan_perangkat_dengan_kode(
  p_kode        text,
  p_kunci_mentah text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_rec          record;
  v_perangkat_id uuid;
  v_kunci_hash   text;
begin
  if p_kode is null or trim(p_kode) = '' or p_kunci_mentah is null or length(p_kunci_mentah) < 16 then
    return jsonb_build_object('berhasil', false, 'kode', 'INVALID_INPUT', 'pesan', 'Kode pendaftaran atau kunci rahasia perangkat tidak valid.');
  end if;

  -- Kunci baris kode pendaftaran untuk mencegah balapan (race condition)
  select * into v_rec
    from public.kode_pendaftaran_perangkat
   where kode = upper(trim(p_kode))
     and dipakai_pada is null
     and kedaluwarsa_pada > now()
   for update;

  if v_rec.id is null then
    return jsonb_build_object('berhasil', false, 'kode', 'KODE_KEDALUWARSA', 'pesan', 'Kode pendaftaran salah, sudah dipakai, atau telah kedaluwarsa.');
  end if;

  -- Buat baris perangkat baru
  insert into public.perangkat (
    penyewa_id, cabang_id, nama, jenis, peran_diizinkan, aktif, didaftarkan_oleh, status
  ) values (
    v_rec.penyewa_id, v_rec.cabang_id, v_rec.nama_perangkat, v_rec.jenis, v_rec.peran_diizinkan, true, v_rec.dibuat_oleh, 'aktif'
  ) returning id into v_perangkat_id;

  -- Simpan hash bcrypt kunci perangkat di kredensial_perangkat
  v_kunci_hash := crypt(p_kunci_mentah, gen_salt('bf', 10));

  insert into public.kredensial_perangkat (perangkat_id, kunci_hash, diubah_pada)
  values (v_perangkat_id, v_kunci_hash, now());

  -- Tandai kode pendaftaran sudah terpakai
  update public.kode_pendaftaran_perangkat
     set dipakai_pada = now(),
         perangkat_id = v_perangkat_id
   where id = v_rec.id;

  -- Catat audit
  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
  ) values (
    v_rec.penyewa_id, v_rec.dibuat_oleh, 'daftarkan_perangkat', 'perangkat', v_perangkat_id,
    jsonb_build_object('nama', v_rec.nama_perangkat, 'jenis', v_rec.jenis, 'cabang_id', v_rec.cabang_id)
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'PERANGKAT_TERDAFTAR',
    'pesan', 'Perangkat berhasil didaftarkan.',
    'data', jsonb_build_object(
      'perangkat_id', v_perangkat_id,
      'penyewa_id', v_rec.penyewa_id,
      'cabang_id', v_rec.cabang_id,
      'nama', v_rec.nama_perangkat
    )
  );
end;
$$;

comment on function public.daftarkan_perangkat_dengan_kode(text, text) is
  'Mendaftarkan perangkat baru menggunakan kode pendaftaran sekali pakai (T1-24).';

revoke all on function public.daftarkan_perangkat_dengan_kode(text, text) from public;
grant execute on function public.daftarkan_perangkat_dengan_kode(text, text) to anon, authenticated, service_role;

-- RPC 3: setujui_perangkat_pegawai
create or replace function public.setujui_perangkat_pegawai(
  p_perangkat_id uuid,
  p_pengguna_id  uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid := public.penyewa_saya();
  v_saya       uuid := auth.uid();
  v_p_penyewa  uuid;
  v_u_penyewa  uuid;
begin
  if v_penyewa is null or v_saya is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Sesi autentikasi tidak sah.');
  end if;

  if not public.boleh('kelola_pegawai') then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Anda tidak memiliki hak menyetujui perangkat pegawai.');
  end if;

  select penyewa_id into v_p_penyewa from public.perangkat where id = p_perangkat_id and aktif;
  select penyewa_id into v_u_penyewa from public.pengguna where id = p_pengguna_id and aktif;

  if v_p_penyewa <> v_penyewa or v_u_penyewa <> v_penyewa then
    return jsonb_build_object('berhasil', false, 'kode', 'NOT_FOUND', 'pesan', 'Perangkat atau pegawai tidak ditemukan dalam restoran ini.');
  end if;

  insert into public.persetujuan_perangkat (penyewa_id, perangkat_id, pengguna_id, disetujui_oleh)
  values (v_penyewa, p_perangkat_id, p_pengguna_id, v_saya)
  on conflict (perangkat_id, pengguna_id) do update
     set disetujui_oleh = v_saya, waktu = now();

  return jsonb_build_object('berhasil', true, 'kode', 'DISETUJUI', 'pesan', 'Penggunaan perangkat oleh pegawai berhasil disetujui.');
end;
$$;

comment on function public.setujui_perangkat_pegawai(uuid, uuid) is
  'Menyetujui pegawai memakai perangkat tertentu untuk pertama kali (T1-24).';

revoke all on function public.setujui_perangkat_pegawai(uuid, uuid) from public;
grant execute on function public.setujui_perangkat_pegawai(uuid, uuid) to authenticated, service_role;

-- RPC 4: cabut_perangkat (menggantikan definisi 0018 untuk menambahkan pencabutan sesi & audit)
drop function if exists public.cabut_perangkat(uuid);

create or replace function public.cabut_perangkat(
  p_perangkat_id uuid,
  p_alasan       text default 'Dicabut oleh pengelola'
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_saya    uuid := auth.uid();
  v_p       record;
begin
  if v_penyewa is null or v_saya is null then
    return false;
  end if;

  if not public.boleh('kelola_pegawai') then
    return false;
  end if;

  select * into v_p from public.perangkat where id = p_perangkat_id and penyewa_id = v_penyewa;
  if v_p.id is null then
    return false;
  end if;

  -- Nonaktifkan perangkat
  update public.perangkat
     set aktif = false,
         status = 'dicabut',
         dicabut_oleh = v_saya,
         dicabut_pada = now(),
         catatan = coalesce(catatan || ' | ', '') || coalesce(p_alasan, 'Dicabut')
   where id = p_perangkat_id;

  -- Cabut seketika seluruh sesi yang masih aktif pada perangkat ini (T1-25)
  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where perangkat_id = p_perangkat_id
     and status = 'aktif';

  -- Catat audit
  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru
  ) values (
    v_penyewa, v_saya, 'cabut_perangkat', 'perangkat', p_perangkat_id,
    jsonb_build_object('status', v_p.status, 'aktif', v_p.aktif),
    jsonb_build_object('status', 'dicabut', 'aktif', false, 'alasan', p_alasan)
  );

  return true;
end;
$$;

comment on function public.cabut_perangkat(uuid, text) is
  'Mencabut perangkat terdaftar dan memutus seluruh sesi aktif seketika (T1-24 & T1-25).';

revoke all on function public.cabut_perangkat(uuid, text) from public;
grant execute on function public.cabut_perangkat(uuid, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 8 — RPC Sesi Perangkat (T1-25)
-- ---------------------------------------------------------------------------

-- RPC 5: ikat_sesi_perangkat
create or replace function public.ikat_sesi_perangkat(
  p_session_id      text,
  p_perangkat_id    uuid,
  p_perangkat_kunci text,
  p_pengguna_id     uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_perangkat     record;
  v_pengguna      record;
  v_umur_interval interval;
  v_berakhir      timestamptz;
begin
  if p_session_id is null or trim(p_session_id) = '' or p_perangkat_id is null or p_pengguna_id is null then
    return jsonb_build_object('berhasil', false, 'kode', 'INVALID_INPUT', 'pesan', 'Parameter sesi tidak lengkap.');
  end if;

  -- 1. Verifikasi keabsahan perangkat via perangkat_sah
  if public.perangkat_sah(p_perangkat_id, p_perangkat_kunci) is null then
    return jsonb_build_object('berhasil', false, 'kode', 'PERANGKAT_TIDAK_SAH', 'pesan', 'Perangkat tidak dikenali atau tidak sah.');
  end if;

  select * into v_perangkat from public.perangkat where id = p_perangkat_id and aktif;
  select * into v_pengguna from public.pengguna where id = p_pengguna_id and aktif;

  if v_pengguna.id is null or v_pengguna.penyewa_id <> v_perangkat.penyewa_id then
    return jsonb_build_object('berhasil', false, 'kode', 'PENGGUNA_TIDAK_VALID', 'pesan', 'Pengguna tidak ditemukan atau nonaktif.');
  end if;

  -- 2. Periksa apakah peran diizinkan pada perangkat ini (T1-24)
  if not (v_pengguna.peran::text = any(v_perangkat.peran_diizinkan)) then
    return jsonb_build_object('berhasil', false, 'kode', 'PERAN_TIDAK_DIIZINKAN', 'pesan', 'Peran pengguna tidak diizinkan pada perangkat ini.');
  end if;

  -- 3. Tentukan batas umur sesi berdasarkan peran (T1-25 / KEAMANAN §7)
  --    Staf: 12 jam; Admin/Owner: 30 hari; Pemilik Platform: 8 jam
  if v_pengguna.peran in ('kasir', 'pelayan', 'dapur') then
    v_umur_interval := interval '12 hours';
  elsif v_pengguna.peran in ('admin_cabang', 'owner_pusat') then
    v_umur_interval := interval '30 days';
  elsif v_pengguna.peran = 'pemilik_platform' then
    v_umur_interval := interval '8 hours';
  else
    v_umur_interval := interval '12 hours';
  end if;

  v_berakhir := now() + v_umur_interval;

  -- 4. Simpan atau perbarui sesi
  insert into public.sesi_perangkat (
    session_id, penyewa_id, perangkat_id, pengguna_id, cabang_id, mulai, berakhir_pada, status, diperbarui_pada
  ) values (
    p_session_id, v_perangkat.penyewa_id, p_perangkat_id, p_pengguna_id, v_perangkat.cabang_id, now(), v_berakhir, 'aktif', now()
  )
  on conflict (session_id) do update
     set berakhir_pada = v_berakhir,
         status = 'aktif',
         diperbarui_pada = now();

  -- Perbarui terakhir_aktif perangkat
  update public.perangkat set terakhir_aktif = now() where id = p_perangkat_id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SESI_TERIKAT',
    'pesan', 'Sesi perangkat berhasil diikat.',
    'data', jsonb_build_object(
      'session_id', p_session_id,
      'berakhir_pada', v_berakhir,
      'peran', v_pengguna.peran
    )
  );
end;
$$;

comment on function public.ikat_sesi_perangkat(text, uuid, text, uuid) is
  'Mengikat session token dengan perangkat terdaftar dan menetapkan batas umur sesi (T1-25).';

revoke all on function public.ikat_sesi_perangkat(text, uuid, text, uuid) from public;
grant execute on function public.ikat_sesi_perangkat(text, uuid, text, uuid) to authenticated, anon, service_role;

-- RPC 6: keluar_semua_perangkat
create or replace function public.keluar_semua_perangkat(
  p_pengguna_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_saya    uuid := auth.uid();
  v_target  uuid;
  v_jumlah  int;
begin
  if v_penyewa is null or v_saya is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Sesi autentikasi tidak sah.');
  end if;

  v_target := coalesce(p_pengguna_id, v_saya);

  -- Jika menyasar akun lain, wajib punya izin kelola_pegawai
  if v_target <> v_saya and not public.boleh('kelola_pegawai') then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Anda tidak memiliki hak mengakhiri sesi pengguna lain.');
  end if;

  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where penyewa_id = v_penyewa
     and pengguna_id = v_target
     and status = 'aktif';

  get diagnostics v_jumlah = row_count;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SESI_DICABUT',
    'pesan', format('%s sesi aktif berhasil diakhiri.', v_jumlah),
    'data', jsonb_build_object('jumlah', v_jumlah)
  );
end;
$$;

comment on function public.keluar_semua_perangkat(uuid) is
  'Mencabut seluruh sesi aktif milik pengguna di semua perangkat (T1-25).';

revoke all on function public.keluar_semua_perangkat(uuid) from public;
grant execute on function public.keluar_semua_perangkat(uuid) to authenticated, service_role;

-- RPC 7: catat_percobaan_masuk
create or replace function public.catat_percobaan_masuk(
  p_penyewa_id   uuid,
  p_pengguna_id  uuid default null,
  p_perangkat_id uuid default null,
  p_berhasil     boolean default false,
  p_sebab        text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.percobaan_masuk (
    penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu
  ) values (
    p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now()
  );
end;
$$;

comment on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) is
  'Mencatat hasil percobaan masuk staf atau perangkat secara aman (T1-26).';

revoke all on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) from public;
grant execute on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 9 — Pembatas Percobaan Masuk & Brute-Force (T1-26)
-- ---------------------------------------------------------------------------

-- Fungsi verifikasi status pembatasan masuk (5x akun / 12x perangkat per 15 menit)
create or replace function public.periksa_kunci_masuk(
  p_pengguna_id  uuid,
  p_perangkat_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_gagal_akun      int := 0;
  v_gagal_perangkat int := 0;
  v_ambang_waktu    timestamptz := now() - interval '15 minutes';
begin
  if p_pengguna_id is not null then
    select count(*) into v_gagal_akun
      from public.percobaan_masuk
     where pengguna_id = p_pengguna_id
       and berhasil = false
       and waktu > v_ambang_waktu;
  end if;

  if p_perangkat_id is not null then
    select count(*) into v_gagal_perangkat
      from public.percobaan_masuk
     where perangkat_id = p_perangkat_id
       and berhasil = false
       and waktu > v_ambang_waktu;
  end if;

  if v_gagal_akun >= 5 then
    return jsonb_build_object(
      'terkunci', true,
      'alasan', 'Akun terkunci sementara karena 5 kali percobaan salah. Tunggu 15 menit.',
      'sisa_percobaan_akun', 0
    );
  end if;

  if v_gagal_perangkat >= 12 then
    return jsonb_build_object(
      'terkunci', true,
      'alasan', 'Perangkat terkunci sementara karena 12 kali percobaan salah. Tunggu 15 menit.',
      'sisa_percobaan_perangkat', 0
    );
  end if;

  return jsonb_build_object(
    'terkunci', false,
    'sisa_percobaan_akun', 5 - v_gagal_akun,
    'sisa_percobaan_perangkat', 12 - v_gagal_perangkat
  );
end;
$$;

comment on function public.periksa_kunci_masuk(uuid, uuid) is
  'Memeriksa apakah akun atau perangkat terkunci akibat percobaan masuk gagal (T1-26).';

revoke all on function public.periksa_kunci_masuk(uuid, uuid) from public;
grant execute on function public.periksa_kunci_masuk(uuid, uuid) to anon, authenticated, service_role;
