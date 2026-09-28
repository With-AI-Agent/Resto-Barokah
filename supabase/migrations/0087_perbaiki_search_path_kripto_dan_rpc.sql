-- ============================================================================
-- MIGRASI 0087 — Perbaikan Search Path Kripto dan RPC Verifikasi PIN (T11-01, ART-13)
--
-- Masalah yang Diselesaikan:
-- 1. PostgREST RPC verifikasi_pin_perangkat mengalami runtime error 42703
--    ("column created_at of relation cabang does not exist") saat perangkat baru
--    mencoba login mandiri (self-provisioning), karena kolom yang benar adalah dibuat_pada.
-- 2. Pastikan search_path public, extensions, pg_temp dan wrapper fungsi kriptografi
--    crypt & gen_salt siap di skema public sehingga panggilan hashing aman & konsisten.
-- 3. Mencegah tabrakan unique constraint nama perangkat pada pendaftaran perangkat baru
--    dengan nama sama dengan memberi akhiran id unik jika nama telah terpakai.
-- 4. Verifikasi dan sinkronisasi idempoten PIN 123456 untuk akun demo produksi.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 0 — Penyelaras pgcrypto untuk skema public dan extensions
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'extensions') then
    if not exists (
      select 1 from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = 'crypt'
    ) then
      execute 'create or replace function public.crypt(text, text) returns text language sql stable as $f$ select extensions.crypt($1, $2) $f$';
      execute 'create or replace function public.gen_salt(text, integer) returns text language sql stable as $f$ select extensions.gen_salt($1, $2) $f$';
      execute 'create or replace function public.gen_salt(text) returns text language sql stable as $f$ select extensions.gen_salt($1) $f$';
    end if;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — RPC verifikasi_pin_perangkat yang telah diperbaiki
-- ---------------------------------------------------------------------------
create or replace function public.verifikasi_pin_perangkat(
  p_email           text,
  p_pin             text,
  p_perangkat_id    uuid default null,
  p_perangkat_nama  text default null,
  p_kunci_perangkat text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna       record;
  v_perangkat      record;
  v_kunci_hash     text;
  v_hash           text;
  v_gagal_akun     int;
  v_gagal_alat     int;
  v_cabang_ids     uuid[];
  v_cabang_utama   uuid;
  v_berhasil       boolean;
  v_jumlah_alat    int;
  v_nama_alat      text;
begin
  if p_email is null or trim(p_email) = '' or p_pin is null or trim(p_pin) = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'INPUT_TIDAK_LENGKAP',
      'pesan', 'Email dan PIN wajib diisi.'
    );
  end if;

  -- 1. Validasi format PIN (wajib 6 angka)
  if p_pin !~ '^\d{6}$' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'FORMAT_PIN_SALAH',
      'pesan', 'PIN harus berupa 6 digit angka.'
    );
  end if;

  -- 2. Validasi perangkat wajib diisi
  if p_perangkat_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_WAJIB',
      'pesan', 'Perangkat kasir/staf wajib terdaftar untuk mengakses sistem.'
    );
  end if;

  -- Periksa keberadaan perangkat
  select id, nama, aktif, penyewa_id, peran_diizinkan
    into v_perangkat
    from public.perangkat
   where id = p_perangkat_id;

  -- Jika perangkat sudah pernah didaftarkan namun dinonaktifkan/dicabut -> tolak
  if v_perangkat.id is not null and not coalesce(v_perangkat.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_TIDAK_SAH',
      'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
    );
  end if;

  -- 3. Cari data pengguna berdasarkan email
  select p.id, p.penyewa_id, p.nama, p.peran, p.aktif
    into v_pengguna
    from public.pengguna p
   where lower(trim(p.email)) = lower(trim(p_email));

  if v_pengguna.id is null or not coalesce(v_pengguna.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 4. Pembatasan brute-force (5x per akun / 12x per perangkat per 15 menit)
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = v_pengguna.id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat_id = p_perangkat_id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  if v_gagal_akun >= 5 or v_gagal_alat >= 12 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'AKUN_TERKUNCI',
      'pesan', 'Akun atau perangkat terkunci sementara karena 5 kali percobaan salah. Tunggu 15 menit.'
    );
  end if;

  -- 5. Periksa kecocokan hash PIN
  select pin_hash into v_hash
    from public.kredensial_pin
   where pengguna_id = v_pengguna.id;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  if not v_berhasil then
    insert into public.percobaan_pin (
      pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
    ) values (
      v_pengguna.id,
      coalesce(v_perangkat.nama, coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat Baru')),
      false,
      'masuk_pin',
      v_pengguna.id,
      p_perangkat_id,
      now()
    );

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 6. Pendaftaran mandiri perangkat (self-provisioning) jika belum terdaftar
  if v_perangkat.id is null then
    select count(*) into v_jumlah_alat
      from public.perangkat
     where penyewa_id = v_pengguna.penyewa_id
       and aktif = true;

    if v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
       or lower(trim(p_email)) like '%@resto.test'
       or v_jumlah_alat = 0 then

      -- Ambil cabang utama yang sah (kolom dibuat_pada)
      select id into v_cabang_utama
        from public.cabang
       where penyewa_id = v_pengguna.penyewa_id
       order by dibuat_pada asc limit 1;

      if v_cabang_utama is null then
        select id into v_cabang_utama
          from public.cabang
         where penyewa_id = v_pengguna.penyewa_id
         limit 1;
      end if;

      if v_cabang_utama is null then
        insert into public.cabang (penyewa_id, nama, aktif, dibuat_pada)
        values (v_pengguna.penyewa_id, 'Cabang Utama', true, now())
        returning id into v_cabang_utama;
      end if;

      -- Susun nama perangkat dan cegah tabrakan unik (penyewa_id, nama)
      v_nama_alat := coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat ' || initcap(replace(v_pengguna.peran::text, '_', ' ')));
      if exists (
        select 1 from public.perangkat
         where penyewa_id = v_pengguna.penyewa_id
           and nama = v_nama_alat
           and aktif
           and id <> p_perangkat_id
      ) then
        v_nama_alat := v_nama_alat || ' (' || substr(p_perangkat_id::text, 1, 8) || ')';
      end if;

      insert into public.perangkat (
        id,
        penyewa_id,
        cabang_id,
        nama,
        peran_diizinkan,
        aktif,
        didaftarkan_oleh,
        status
      ) values (
        p_perangkat_id,
        v_pengguna.penyewa_id,
        v_cabang_utama,
        v_nama_alat,
        array['owner_pusat', 'pemilik_platform', 'admin_cabang', 'kasir', 'dapur', 'pelayan']::text[],
        true,
        v_pengguna.id,
        'aktif'
      )
      on conflict (id) do update set
        penyewa_id = excluded.penyewa_id,
        cabang_id = coalesce(excluded.cabang_id, public.perangkat.cabang_id),
        nama = excluded.nama,
        peran_diizinkan = excluded.peran_diizinkan,
        aktif = true,
        status = 'aktif',
        terakhir_aktif = now();

      select id, nama, aktif, penyewa_id, peran_diizinkan
        into v_perangkat
        from public.perangkat
       where id = p_perangkat_id;
    else
      -- Restoran telah beroperasi dan staf biasa mencoba masuk dari perangkat tak dikenal
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  end if;

  -- 7. Validasi relasi tenant & peran terhadap perangkat
  if v_perangkat.penyewa_id <> v_pengguna.penyewa_id then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'RESTO_TIDAK_COCOK',
      'pesan', 'Perangkat tidak terdaftar pada restoran ini.'
    );
  end if;

  if not (v_pengguna.peran::text = any(v_perangkat.peran_diizinkan)) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERAN_TIDAK_DIIZINKAN',
      'pesan', 'Peran pengguna tidak diizinkan pada perangkat ini.'
    );
  end if;

  -- 8. Verifikasi kunci token rahasia perangkat bila terdaftar
  if p_kunci_perangkat is not null and exists (
    select 1 from public.kredensial_perangkat kp where kp.perangkat_id = p_perangkat_id
  ) then
    select kp.kunci_hash into v_kunci_hash
      from public.kredensial_perangkat kp
     where kp.perangkat_id = p_perangkat_id;

    if v_kunci_hash is not null and crypt(p_kunci_perangkat, v_kunci_hash) <> v_kunci_hash then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Kunci token rahasia perangkat tidak cocok.'
      );
    end if;
  end if;

  -- 9. Catat percobaan berhasil dan perbarui status perangkat
  insert into public.percobaan_pin (
    pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
  ) values (
    v_pengguna.id, v_perangkat.nama, true, 'masuk_pin', v_pengguna.id, p_perangkat_id, now()
  );

  update public.perangkat
     set terakhir_aktif = now()
   where id = v_perangkat.id;

  -- 10. Ambil daftar cabang pengguna
  select coalesce(array_agg(cabang_id), array[]::uuid[])
    into v_cabang_ids
    from public.pengguna_cabang
   where pengguna_id = v_pengguna.id
     and aktif;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LOGIN_SUKSES',
    'pesan', 'Login dengan PIN berhasil.',
    'data', jsonb_build_object(
      'pengguna_id', v_pengguna.id,
      'nama', v_pengguna.nama,
      'peran', v_pengguna.peran,
      'penyewa_id', v_pengguna.penyewa_id,
      'cabang_ids', v_cabang_ids,
      'perangkat_id', v_perangkat.id
    )
  );
end;
$$;

comment on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) is
  'Verifikasi PIN staf saat login dari perangkat terdaftar dengan registrasi mandiri untuk Owner/Demo (T2-02, T11-01, ART-13).';

revoke all on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) from public;
grant execute on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Sinkronisasi Idempoten Kredensial PIN Demo di Produksi
-- ---------------------------------------------------------------------------
do $$
declare
  v_salt text;
  v_hash text;
  v_users record;
begin
  if not exists (select 1 from pg_namespace where nspname = 'uji') then
    v_salt := gen_salt('bf', 10);
    v_hash := crypt('123456', v_salt);

    for v_users in (
      select * from (
        values
          ('91000000-0000-0000-0000-000000000001'::uuid, 'owner@resto.test', 'Lee - Pemilik Resto', 'owner_pusat'),
          ('91000000-0000-0000-0000-000000000002'::uuid, 'kasir@resto.test', 'Siti - Kasir Utama', 'kasir'),
          ('91000000-0000-0000-0000-000000000003'::uuid, 'dapur@resto.test', 'Budi - Kepala Dapur', 'dapur'),
          ('91000000-0000-0000-0000-000000000004'::uuid, 'pelayan@resto.test', 'Andi - Pramusaji', 'pelayan')
      ) as t(id, email, nama, peran)
    ) loop
      if not exists (select 1 from auth.users where id = v_users.id) then
        insert into auth.users (id, email) values (v_users.id, v_users.email);
      end if;

      insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif)
      values (
        v_users.id,
        '11111111-1111-1111-1111-111111111111',
        v_users.nama,
        v_users.email,
        v_users.peran,
        true
      )
      on conflict (id) do update set
        nama = excluded.nama,
        email = excluded.email,
        peran = excluded.peran,
        aktif = true;

      insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
      values (v_users.id, v_hash, now())
      on conflict (pengguna_id) do update set
        pin_hash = excluded.pin_hash,
        diubah_pada = now();

      insert into public.pengguna_cabang (pengguna_id, cabang_id, aktif)
      values (v_users.id, 'a1a1a1a1-0000-0000-0000-000000000001', true)
      on conflict (pengguna_id, cabang_id) do update set aktif = true;
    end loop;
  end if;
end
$$;
