-- ============================================================================
-- 0006 — PIN pegawai: disimpan ter-hash + percobaan dibatasi (ART-2 & keamanan)
--
-- Aturan yang dipegang:
--   * PIN TIDAK PERNAH disimpan sebagai teks biasa. Kolom `pin_hash` bahkan
--     diberi batas (CHECK) yang menolak nilai yang bukan berbentuk hash —
--     jadi kalaupun ada kode yang keliru menyimpan PIN mentah, database yang
--     menolaknya, bukan manusia yang harus ingat.
--   * PIN TIDAK PERNAH dikembalikan fungsi apa pun. `simpan_pin` dan
--     `verifikasi_pin` hanya mengembalikan status, bukan hash.
--   * Setiap percobaan (berhasil maupun gagal) TERCATAT di `percobaan_pin`
--     lengkap dengan perangkat — ini bahan laporan keamanan & dasar pembatasan.
--   * Pembatasan percobaan dihitung dari catatan itu: per AKUN (5 kali / 15
--     menit) dan per PERANGKAT (12 kali / 15 menit, melintasi akun) supaya
--     menebak PIN dari satu HP tidak bisa jalan.
--   * Perbandingan PIN memakai `crypt(...) = pin_hash` (bcrypt di Supabase).
-- ============================================================================

-- pgcrypto menyediakan crypt()/gen_salt() (bcrypt). Di Supabase pasti ada;
-- di lingkungan uji lokal dipakai tiruan berlabel dari alat uji.
do $$
begin
  create extension if not exists pgcrypto;
exception when others then
  raise notice 'pgcrypto tidak tersedia di lingkungan ini — memakai tiruan dari alat uji (hanya untuk uji)';
end
$$;

-- ------------------------------------------------------- kolom PIN di pengguna
alter table public.pengguna add column if not exists pin_hash text;
alter table public.pengguna add column if not exists pin_diubah_pada timestamptz;

do $$
begin
  alter table public.pengguna
    add constraint pengguna_pin_hash_berbentuk_hash
    check (pin_hash is null or pin_hash ~ '^\$[a-z0-9]+\$');
exception when duplicate_object then null;
end
$$;

comment on column public.pengguna.pin_hash is
  'Hash PIN (bcrypt). Tidak pernah berisi PIN mentah — dijaga batas (CHECK) di tingkat tabel.';

-- ------------------------------------------------------------- catatan percobaan
create table if not exists public.percobaan_pin (
  id          bigserial primary key,
  pengguna_id uuid not null references public.pengguna (id) on delete cascade,
  perangkat   text not null default 'tidak-diketahui',
  berhasil    boolean not null,
  waktu       timestamptz not null default now()
);

comment on table public.percobaan_pin is
  'Catatan setiap percobaan PIN (berhasil/gagal) per pegawai & perangkat. Dasar pembatasan anti-tebak dan bahan laporan keamanan.';

create index if not exists percobaan_pin_pengguna_waktu_idx
  on public.percobaan_pin (pengguna_id, waktu desc);
create index if not exists percobaan_pin_perangkat_waktu_idx
  on public.percobaan_pin (perangkat, waktu desc);

alter table public.percobaan_pin enable row level security;

-- Hanya boleh DIBACA: pemilik catatannya sendiri, atau pegawai ber-izin
-- kelola_pegawai di resto yang sama. Tidak ada hak menulis langsung —
-- penulisan hanya lewat fungsi verifikasi (SECURITY DEFINER).
create policy percobaan_pin_pilih on public.percobaan_pin
  for select to authenticated
  using (
    pengguna_id = auth.uid()
    or (public.sepenyewa(pengguna_id) and public.boleh('kelola_pegawai'))
  );

grant select on public.percobaan_pin to authenticated;
grant usage, select on sequence public.percobaan_pin_id_seq to service_role;
grant select, insert, update, delete on public.percobaan_pin to service_role;

-- ============================ izin atas nama pegawai lain (pengganti PIN) ====
-- `izin_efektif` dari 0005 menilai pengguna yang sedang masuk. Untuk menyetujui
-- tindakan pakai PIN, gerbangnya harus bisa menilai PEGAWAI YANG PUNYA PIN itu —
-- jadi logikanya dijadikan satu fungsi umum, dan izin_efektif menjadi pembungkusnya.
create or replace function public.izin_efektif_untuk(
  p_pengguna_id uuid,
  p_aksi        text,
  p_cabang_id   uuid default null
)
returns table (boleh boolean, batas_nominal integer, batas_persen numeric)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran   text;
begin
  select p.penyewa_id, p.peran
    into v_penyewa, v_peran
    from public.pengguna p
   where p.id = p_pengguna_id
     and p.aktif;

  if v_penyewa is null or v_peran is null or v_peran = 'pemilik_platform' then
    return query select false, null::integer, null::numeric;
    return;
  end if;

  if p_cabang_id is not null then
    select pc.peran
      into v_peran
      from public.pengguna_cabang pc
     where pc.pengguna_id = p_pengguna_id
       and pc.cabang_id = p_cabang_id
       and pc.aktif
     limit 1;
    if not found then
      if (select p.peran from public.pengguna p where p.id = p_pengguna_id) = 'owner_pusat' then
        v_peran := 'owner_pusat';
      else
        return query select false, null::integer, null::numeric;
        return;
      end if;
    end if;
  end if;

  return query
    select coalesce(k.boleh, false), k.batas_nominal, k.batas_persen
      from (
        select i.boleh, i.batas_nominal, i.batas_persen, 0 as urutan
          from public.izin i
         where i.pengguna_id = p_pengguna_id
           and i.kode_izin = p_aksi
        union all
        select ip.boleh, ip.batas_nominal, ip.batas_persen, 1 as urutan
          from public.izin_peran ip
         where ip.penyewa_id = v_penyewa
           and ip.peran = v_peran
           and ip.kode_izin = p_aksi
      ) k
     order by k.urutan
     limit 1;

  if not found then
    return query select false, null::integer, null::numeric;
    return;
  end if;
end
$$;

comment on function public.izin_efektif_untuk(uuid, text, uuid) is
  'Izin efektif atas nama pegawai mana pun (dipakai gerbang persetujuan PIN). Menambah parameter ke izin_efektif agar tidak ada dua rumus izin.';

-- izin_efektif (0005) kini memakai fungsi umum yang sama — satu rumus, dua pintu.
create or replace function public.izin_efektif(p_aksi text, p_cabang_id uuid default null)
returns table (boleh boolean, batas_nominal integer, batas_persen numeric)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select * from public.izin_efektif_untuk(auth.uid(), p_aksi, p_cabang_id)
$$;

create or replace function public.boleh_untuk(
  p_pengguna_id uuid,
  p_aksi        text,
  p_cabang_id   uuid default null
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select ie.boleh from public.izin_efektif_untuk(p_pengguna_id, p_aksi, p_cabang_id) ie
$$;

comment on function public.boleh_untuk(uuid, text, uuid) is
  'Apakah pegawai tertentu (bukan yang sedang masuk) berizin melakukan aksi — dipakai saat memeriksa PIN penyetuju.';

revoke all on function public.izin_efektif_untuk(uuid, text, uuid) from public;
revoke all on function public.boleh_untuk(uuid, text, uuid) from public;
grant execute on function public.izin_efektif_untuk(uuid, text, uuid) to authenticated, service_role;
grant execute on function public.boleh_untuk(uuid, text, uuid) to authenticated, service_role;

-- ================================================== SIMPAN / GANTI PIN =======
create or replace function public.simpan_pin(
  p_pin_baru    text,
  p_pin_lama    text default null,
  p_pengguna_id uuid default null,
  p_perangkat   text default 'tidak-diketahui'
)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya    uuid := auth.uid();
  v_target  uuid := coalesce(p_pengguna_id, auth.uid());
  v_hash    text;
  v_periksa record;
begin
  if v_saya is null then
    raise exception 'Anda harus masuk dulu untuk menyimpan PIN.';
  end if;

  if p_pin_baru is null or p_pin_baru !~ '^\d{4,6}$' then
    raise exception 'PIN harus berupa 4 sampai 6 angka.';
  end if;

  if v_target <> v_saya then
    if not public.sepenyewa(v_target) then
      raise exception 'Pegawai itu bukan bagian dari resto Anda.';
    end if;
    if not public.boleh('kelola_pegawai') then
      raise exception 'Anda tidak berizin mengubah PIN pegawai lain.';
    end if;
  end if;

  -- Ganti PIN sendiri WAJIB memakai PIN lama (kecuali belum pernah punya PIN).
  if v_target = v_saya and p_pengguna_id is null then
    select * into v_periksa
      from public.verifikasi_pin(v_target, coalesce(p_pin_lama, ''), null, p_perangkat);
    if (select pin_hash from public.pengguna where id = v_target) is not null
       and not v_periksa.berhasil then
      raise exception 'PIN lama salah. %', v_periksa.pesan;
    end if;
  end if;

  v_hash := crypt(p_pin_baru, gen_salt('bf', 10));

  update public.pengguna
     set pin_hash = v_hash,
         pin_diubah_pada = now()
   where id = v_target;

  return 'PIN tersimpan.';
end
$$;

comment on function public.simpan_pin(text, text, uuid, text) is
  'Menyimpan/mengganti PIN (hash bcrypt). PIN sendiri butuh PIN lama; mengubah PIN pegawai lain butuh izin kelola_pegawai.';

-- `ganti_pin` (M12) = pintu kedua untuk hal yang sama; satu isi, bukan dua.
create or replace function public.ganti_pin(p_pin_lama text, p_pin_baru text, p_perangkat text default 'tidak-diketahui')
returns text
language sql
security definer
set search_path = public, pg_temp
as $$
  select public.simpan_pin(p_pin_baru, p_pin_lama, null, p_perangkat)
$$;

-- ======================================================== VERIFIKASI PIN =====
create or replace function public.verifikasi_pin(
  p_pengguna_id uuid,
  p_pin         text,
  p_aksi        text default null,
  p_perangkat   text default 'tidak-diketahui'
)
returns table (berhasil boolean, sisa_percobaan integer, pesan text)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  BATAS_AKUN       constant integer := 5;    -- 5 kali gagal per akun
  BATAS_PERANGKAT  constant integer := 12;   -- 12 kali gagal per perangkat (melintasi akun)
  JENDELA_MENIT    constant integer := 15;
  v_saya       uuid := auth.uid();
  v_perangkat  text := coalesce(nullif(p_perangkat, ''), 'tidak-diketahui');
  v_hash       text;
  v_penyewa_target uuid;
  v_aktif_target   boolean;
  v_gagal_akun integer;
  v_gagal_alat integer;
  v_berhasil   boolean;
begin
  if v_saya is null then
    return query select false, 0, 'Anda harus masuk dulu untuk memakai PIN.';
    return;
  end if;

  if p_pin is null or p_pin !~ '^\d{4,6}$' then
    return query select false, 0, 'PIN harus berupa 4 sampai 6 angka.';
    return;
  end if;

  -- Sasaran harus pegawai AKTIF di resto pemanggil. Akun nonaktif kehilangan
  -- PIN-nya juga (bukan hanya izinnya).
  select p.penyewa_id, p.aktif, p.pin_hash
    into v_penyewa_target, v_aktif_target, v_hash
    from public.pengguna p
   where p.id = p_pengguna_id;

  if v_penyewa_target is null or v_penyewa_target <> public.penyewa_saya() or not coalesce(v_aktif_target, false) then
    -- Jangan membocorkan apakah pegawai itu ada: jawab seperti PIN salah.
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil)
    values (v_saya, v_perangkat, false);
    return query select false, 0, 'PIN tidak dikenali.';
    return;
  end if;

  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = p_pengguna_id
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat = v_perangkat
     and not pp.berhasil
     and pp.waktu > now() - make_interval(mins => JENDELA_MENIT);

  if v_gagal_akun >= BATAS_AKUN or v_gagal_alat >= BATAS_PERANGKAT then
    insert into public.percobaan_pin (pengguna_id, perangkat, berhasil)
    values (p_pengguna_id, v_perangkat, false);
    return query select false, 0,
      format('PIN terkunci sementara karena terlalu banyak percobaan salah. Coba lagi setelah %s menit.', JENDELA_MENIT);
    return;
  end if;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  insert into public.percobaan_pin (pengguna_id, perangkat, berhasil)
  values (p_pengguna_id, v_perangkat, v_berhasil);

  if not v_berhasil then
    return query select false, greatest(BATAS_AKUN - v_gagal_akun - 1, 0),
      'PIN salah.';
    return;
  end if;

  if p_aksi is not null and not public.boleh_untuk(p_pengguna_id, p_aksi) then
    return query select false, BATAS_AKUN,
      format('PIN benar, tetapi pegawai itu tidak berizin: %s.', p_aksi);
    return;
  end if;

  return query select true, BATAS_AKUN, 'PIN diterima.';
end
$$;

comment on function public.verifikasi_pin(uuid, text, text, text) is
  'Memeriksa PIN pegawai: mencatat percobaan, membatasi 5 gagal/akun & 12 gagal/perangkat per 15 menit, dan (bila diminta) memeriksa izin aksi pegawai itu. Tidak pernah mengembalikan hash.';

revoke all on function public.simpan_pin(text, text, uuid, text) from public;
revoke all on function public.ganti_pin(text, text, text) from public;
revoke all on function public.verifikasi_pin(uuid, text, text, text) from public;
grant execute on function public.simpan_pin(text, text, uuid, text) to authenticated, service_role;
grant execute on function public.ganti_pin(text, text, text) to authenticated, service_role;
grant execute on function public.verifikasi_pin(uuid, text, text, text) to authenticated, service_role;
