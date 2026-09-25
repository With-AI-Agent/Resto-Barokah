-- ============================================================================
-- 0063_anti_email_palsu.sql
-- Fase 8: T8-07 — Verifikasi email + anti email sekali-pakai + normalisasi Gmail
-- (PRD M10, TECH_SPEC §4.4, §5, §9 ART-5 & ART-10)
--
-- Pagar yang dibangun:
-- 1. Fungsi normalisasi email `public.normalisasi_email`:
--    - Menghilangkan titik (.) dan tag alias (+) pada domain Gmail / Googlemail.
--    - Menyatukan domain googlemail.com menjadi gmail.com.
--    - Menyeragamkan huruf kecil (lowercase) dan membersihkan spasi.
-- 2. Fungsi deteksi domain email sekali-pakai `public.apakah_email_sekali_pakai`:
--    - Menolak domain email sementara/burner (10minutemail, tempmail, mailinator, dll).
-- 3. Tabel `public.pelanggan`:
--    - Menyimpan identitas pelanggan (nama, email, telepon, alamat).
--    - Wajib persetujuan privasi UU PDP (`persetujuan_privasi = true`, T-011).
--    - Pemicu validasi email & anti-disposable otomatis sebelum INSERT/UPDATE.
--    - Indeks unik per resto: (penyewa_id, email_normalisasi).
-- 4. Tabel `public.kampanye_voucher`, `public.voucher`, `public.voucher_percobaan`.
--    - Indeks unik (kampanye_id, pelanggan_id) di tabel voucher:
--      Satu identitas hanya berhak atas satu voucher per kampanye.
-- 5. RPC `public.daftar_voucher`:
--    - Gerbang atomik pendaftaran pelanggan dan klaim voucher.
--    - Menolak email sekali-pakai, menolak tanpa persetujuan privasi,
--      dan menolak klaim berulang untuk identitas yang sama.
-- ============================================================================

-- 1. Fungsi Normalisasi Email
create or replace function public.normalisasi_email(p_email text)
returns text
language plpgsql
immutable
parallel safe
leakproof
as $$
declare
  v_email text;
  v_lokal text;
  v_domain text;
begin
  if p_email is null then
    return null;
  end if;

  v_email := lower(trim(p_email));
  if v_email = '' then
    return null;
  end if;

  -- Format email sederhana tapi ketat
  if v_email !~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$' then
    return null;
  end if;

  v_lokal := split_part(v_email, '@', 1);
  v_domain := split_part(v_email, '@', 2);

  if v_domain in ('gmail.com', 'googlemail.com') then
    v_domain := 'gmail.com';
    -- Buang alias sub-addressing (+tag)
    v_lokal := split_part(v_lokal, '+', 1);
    -- Buang semua tanda titik (.)
    v_lokal := replace(v_lokal, '.', '');
    if v_lokal = '' then
      return null;
    end if;
  end if;

  return v_lokal || '@' || v_domain;
end;
$$;

comment on function public.normalisasi_email(text) is
  'Normalisasi alamat email: huruf kecil, trim, hapus titik dan alias plus pada Gmail (T8-07).';

-- 2. Fungsi Saringan Email Sekali-Pakai (Disposable Email)
create or replace function public.apakah_email_sekali_pakai(p_email text)
returns boolean
language plpgsql
immutable
parallel safe
leakproof
as $$
declare
  v_domain text;
begin
  if p_email is null then
    return false;
  end if;

  v_domain := lower(trim(p_email));
  if position('@' in v_domain) > 0 then
    v_domain := split_part(v_domain, '@', 2);
  end if;

  return v_domain in (
    '10minutemail.com',
    '10minutemail.net',
    '10minutemail.org',
    'burnermail.io',
    'crazymailing.com',
    'dispostable.com',
    'disposablemail.com',
    'emailondeck.com',
    'fakeinbox.com',
    'fakemail.net',
    'fakemailgenerator.com',
    'generator.email',
    'getairmail.com',
    'grr.la',
    'guerrillamail.biz',
    'guerrillamail.com',
    'guerrillamail.de',
    'guerrillamail.net',
    'guerrillamail.org',
    'guerrillamailblock.com',
    'inboxkitten.com',
    'mailcatch.com',
    'maildrop.cc',
    'mailinator.com',
    'mohmal.com',
    'mytemp.email',
    'nada.ltd',
    'sharklasers.com',
    'spam4.me',
    'temp-mail.org',
    'tempail.com',
    'tempmail.com',
    'tempmail.net',
    'throwawaymail.com',
    'trashmail.com',
    'trashmail.net',
    'trashmail.org',
    'yopmail.com',
    'yopmail.net'
  );
end;
$$;

comment on function public.apakah_email_sekali_pakai(text) is
  'Memeriksa apakah domain email terdaftar sebagai penyedia email sekali-pakai / sementara (T8-07).';

-- 3. Tabel Pelanggan
create table if not exists public.pelanggan (
  id uuid primary key default gen_random_uuid(),
  penyewa_id uuid not null references public.penyewa(id) on delete cascade,
  nama text not null check (length(trim(nama)) > 0),
  email text,
  email_normalisasi text,
  telepon text,
  alamat text,
  cara_masuk text not null check (cara_masuk in ('google', 'email', 'kasir')),
  terverifikasi_pada timestamptz,
  didaftarkan_oleh uuid references public.pengguna(id),
  persetujuan_privasi boolean not null default false check (persetujuan_privasi = true),
  persetujuan_privasi_pada timestamptz not null default now(),
  persetujuan_privasi_versi text not null default 'v1.0',
  dibuat_pada timestamptz not null default now(),
  diubah_pada timestamptz not null default now(),
  constraint pelanggan_cara_masuk_valid check (
    (cara_masuk in ('google', 'email') and email is not null and email_normalisasi is not null and length(trim(email)) > 0)
    or
    (cara_masuk = 'kasir' and didaftarkan_oleh is not null)
  )
);

create unique index if not exists pelanggan_penyewa_email_normalisasi_unik
  on public.pelanggan (penyewa_id, email_normalisasi)
  where email_normalisasi is not null;

create index if not exists idx_pelanggan_penyewa_dibuat
  on public.pelanggan (penyewa_id, dibuat_pada desc);

-- Pemicu Validasi Pelanggan
create or replace function public.picu_pelanggan_validasi_email()
returns trigger
language plpgsql
as $$
begin
  -- Wajib persetujuan privasi UU PDP (T-011)
  if coalesce(new.persetujuan_privasi, false) is not true then
    raise exception 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
      using errcode = '22023';
  end if;

  if new.email is not null and length(trim(new.email)) > 0 then
    new.email := trim(new.email);

    if public.apakah_email_sekali_pakai(new.email) then
      raise exception 'Email sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
        using errcode = '22023';
    end if;

    new.email_normalisasi := public.normalisasi_email(new.email);
    if new.email_normalisasi is null then
      raise exception 'Format alamat email tidak sah.'
        using errcode = '22023';
    end if;
  else
    new.email := null;
    new.email_normalisasi := null;
  end if;

  if new.cara_masuk in ('google', 'email') and new.terverifikasi_pada is null then
    new.terverifikasi_pada := now();
  end if;

  new.diubah_pada := now();
  return new;
end;
$$;

revoke all on function public.picu_pelanggan_validasi_email() from anon, authenticated, public;

drop trigger if exists trg_pelanggan_validasi_email on public.pelanggan;
create trigger trg_pelanggan_validasi_email
  before insert or update on public.pelanggan
  for each row execute function public.picu_pelanggan_validasi_email();

-- 4. Tabel Kampanye Voucher
create table if not exists public.kampanye_voucher (
  id uuid primary key default gen_random_uuid(),
  penyewa_id uuid not null references public.penyewa(id) on delete cascade,
  nama text not null check (length(trim(nama)) > 0),
  kode_kampanye text not null check (length(trim(kode_kampanye)) > 0),
  jenis text not null check (jenis in ('persen', 'nominal')),
  nilai numeric not null check (nilai > 0),
  min_belanja numeric not null default 0 check (min_belanja >= 0),
  maks_potongan numeric check (maks_potongan is null or maks_potongan > 0),
  mulai timestamptz not null default now(),
  selesai timestamptz not null,
  kuota integer not null default 100 check (kuota >= 0),
  anggaran_maks numeric not null default 10000000 check (anggaran_maks >= 0),
  cabang_berlaku jsonb not null default '[]'::jsonb,
  aktif boolean not null default true,
  dibuat_pada timestamptz not null default now(),
  constraint kampanye_selesai_sesudah_mulai check (selesai > mulai),
  unique (penyewa_id, kode_kampanye)
);

-- 5. Tabel Voucher (satu voucher per identitas per kampanye)
create table if not exists public.voucher (
  id uuid primary key default gen_random_uuid(),
  penyewa_id uuid not null references public.penyewa(id) on delete cascade,
  kampanye_id uuid not null references public.kampanye_voucher(id) on delete cascade,
  pelanggan_id uuid not null references public.pelanggan(id) on delete cascade,
  kode text not null unique check (length(trim(kode)) >= 6),
  status text not null default 'aktif' check (status in ('aktif', 'terpakai', 'kedaluwarsa', 'dibatalkan')),
  dibuat_pada timestamptz not null default now(),
  terpakai_pada timestamptz,
  terpakai_di_cabang uuid references public.cabang(id),
  terpakai_oleh uuid references public.pengguna(id),
  pesanan_id uuid references public.pesanan(id),
  unique (kampanye_id, pelanggan_id)
);

-- 6. Tabel Percobaan Voucher (log semua cek/scan)
create table if not exists public.voucher_percobaan (
  id uuid primary key default gen_random_uuid(),
  penyewa_id uuid not null references public.penyewa(id) on delete cascade,
  kode_dicoba text not null,
  hasil text not null,
  alasan text,
  kasir_id uuid references public.pengguna(id),
  cabang_id uuid references public.cabang(id),
  perangkat text,
  waktu timestamptz not null default now()
);

-- 7. RPC daftar_voucher (M10 & TECH_SPEC §5)
create or replace function public.daftar_voucher(
  p_penyewa_id uuid,
  p_kampanye_id uuid,
  p_nama text,
  p_email text,
  p_telepon text default null,
  p_alamat text default null,
  p_persetujuan_privasi boolean default true,
  p_cara_masuk text default 'email'
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_kmp record;
  v_email_norm text;
  v_pelanggan_id uuid;
  v_terbit_count integer;
  v_kode_voucher text;
  v_voucher_id uuid;
  v_ada record;
begin
  -- 1. Validasi Persetujuan Privasi (UU PDP & T-011)
  if coalesce(p_persetujuan_privasi, false) is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PRIVASI_WAJIB',
      'pesan', 'Persetujuan pemrosesan data pribadi (UU PDP) wajib diberikan.'
    );
  end if;

  -- 2. Validasi Nama
  if p_nama is null or length(trim(p_nama)) = 0 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'NAMA_WAJIB',
      'pesan', 'Nama lengkap wajib diisi.'
    );
  end if;

  -- 3. Validasi Email (kecuali kasir mendaftarkan)
  if (p_email is null or length(trim(p_email)) = 0) and p_cara_masuk != 'kasir' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'EMAIL_WAJIB',
      'pesan', 'Alamat email wajib diisi.'
    );
  end if;

  if p_email is not null and length(trim(p_email)) > 0 then
    if public.apakah_email_sekali_pakai(p_email) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_SEKALI_PAKAI',
        'pesan', 'Email sementara atau sekali-pakai tidak diizinkan. Mohon gunakan email pribadi aktif.'
      );
    end if;

    v_email_norm := public.normalisasi_email(p_email);
    if v_email_norm is null then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'EMAIL_TIDAK_SAH',
        'pesan', 'Format alamat email tidak sah.'
      );
    end if;
  end if;

  -- 4. Periksa Kampanye
  select * into v_kmp
    from public.kampanye_voucher
   where id = p_kampanye_id
     and penyewa_id = p_penyewa_id;

  if v_kmp.id is null or v_kmp.aktif is not true then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_TIDAK_AKTIF',
      'pesan', 'Kampanye voucher tidak ditemukan atau sudah tidak aktif.'
    );
  end if;

  if now() < v_kmp.mulai or now() > v_kmp.selesai then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KAMPANYE_BERAKHIR',
      'pesan', 'Masa berlaku kampanye voucher telah berakhir.'
    );
  end if;

  select count(1) into v_terbit_count
    from public.voucher
   where kampanye_id = p_kampanye_id;

  if v_terbit_count >= v_kmp.kuota then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KUOTA_HABIS',
      'pesan', 'Mohon maaf, kuota voucher untuk kampanye ini telah habis.'
    );
  end if;

  -- 5. Ambil atau Buat Pelanggan
  if v_email_norm is not null then
    select id into v_pelanggan_id
      from public.pelanggan
     where penyewa_id = p_penyewa_id
       and email_normalisasi = v_email_norm;
  end if;

  if v_pelanggan_id is null then
    insert into public.pelanggan (
      penyewa_id,
      nama,
      email,
      telepon,
      alamat,
      cara_masuk,
      persetujuan_privasi,
      didaftarkan_oleh
    ) values (
      p_penyewa_id,
      trim(p_nama),
      trim(p_email),
      nullif(trim(coalesce(p_telepon, '')), ''),
      nullif(trim(coalesce(p_alamat, '')), ''),
      p_cara_masuk,
      true,
      case when p_cara_masuk = 'kasir' then (select auth.uid()) else null end
    ) returning id into v_pelanggan_id;
  end if;

  -- 6. Pagar Kritis: Satu identitas = satu voucher per kampanye (ART-5)
  select kode, status into v_ada
    from public.voucher
   where kampanye_id = p_kampanye_id
     and pelanggan_id = v_pelanggan_id;

  if v_ada.kode is not null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'VOUCHER_SUDAH_DIKLAIM',
      'pesan', 'Satu identitas hanya berhak mengklaim 1 voucher untuk kampanye ini.',
      'data', jsonb_build_object(
        'kode_voucher', v_ada.kode,
        'status', v_ada.status
      )
    );
  end if;

  -- 7. Terbitkan Kode Acak Tidak Berurutan
  v_kode_voucher := 'BRK-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));

  insert into public.voucher (
    penyewa_id,
    kampanye_id,
    pelanggan_id,
    kode,
    status
  ) values (
    p_penyewa_id,
    p_kampanye_id,
    v_pelanggan_id,
    v_kode_voucher,
    'aktif'
  ) returning id into v_voucher_id;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Voucher berhasil diterbitkan.',
    'data', jsonb_build_object(
      'voucher_id', v_voucher_id,
      'kode_voucher', v_kode_voucher,
      'nama_pelanggan', trim(p_nama),
      'nilai', v_kmp.nilai,
      'jenis', v_kmp.jenis,
      'min_belanja', v_kmp.min_belanja,
      'maks_potongan', v_kmp.maks_potongan,
      'berlaku_sampai', v_kmp.selesai
    )
  );
end;
$$;

comment on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text) is
  'RPC pendaftaran pelanggan & klaim voucher kampanye (M10, TECH_SPEC §5).';

revoke all on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text) from public;
grant execute on function public.daftar_voucher(uuid, uuid, text, text, text, text, boolean, text) to anon, authenticated, service_role;

-- 8. Row Level Security (RLS)
alter table public.pelanggan enable row level security;
alter table public.kampanye_voucher enable row level security;
alter table public.voucher enable row level security;
alter table public.voucher_percobaan enable row level security;

-- Kebijakan RLS Pelanggan
create policy pelanggan_pilih on public.pelanggan
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

create policy pelanggan_tambah on public.pelanggan
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir')
  );

create policy pelanggan_ubah on public.pelanggan
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
  );

-- Kebijakan RLS Kampanye Voucher
create policy kampanye_voucher_pilih on public.kampanye_voucher
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

create policy kampanye_voucher_kelola on public.kampanye_voucher
  for all to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

-- Kebijakan RLS Voucher
create policy voucher_pilih on public.voucher
  for select to authenticated
  using (penyewa_id = (select public.penyewa_saya()));

create policy voucher_ubah on public.voucher
  for update to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang', 'kasir')
  )
  with check (
    penyewa_id = (select public.penyewa_saya())
  );

-- Kebijakan RLS Voucher Percobaan
create policy voucher_percobaan_pilih on public.voucher_percobaan
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) in ('owner_pusat', 'admin_cabang')
  );

create policy voucher_percobaan_tambah on public.voucher_percobaan
  for insert to authenticated
  with check (
    penyewa_id = (select public.penyewa_saya())
    and (select public.peran_saya()) = 'kasir'
  );
