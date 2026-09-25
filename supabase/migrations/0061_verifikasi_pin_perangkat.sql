-- ============================================================================
-- MIGRASI 0061 — RPC verifikasi_pin_perangkat untuk Autentikasi Staf (N F-01)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-01: RPC verifikasi_pin_perangkat yang
--     dipanggil aplikasi/src/lib/auth.ts:176 belum ada di database.
--   - ROADMAP T2-02 & TECH_SPEC §7: Verifikasi PIN staf dari perangkat terdaftar.
-- ============================================================================

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
  v_pengguna     record;
  v_perangkat    record;
  v_kunci_hash   text;
  v_hash         text;
  v_gagal_akun   int;
  v_gagal_alat   int;
  v_cabang_ids   uuid[];
  v_berhasil     boolean;
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

  -- 2. Validasi perangkat terdaftar (faktor wajib staf: KEAMANAN.md §1.3)
  if p_perangkat_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_WAJIB',
      'pesan', 'Perangkat kasir/staf wajib terdaftar untuk mengakses sistem.'
    );
  end if;

  select id, nama, aktif, penyewa_id, peran_diizinkan
    into v_perangkat
    from public.perangkat
   where id = p_perangkat_id;

  if v_perangkat.id is null or not coalesce(v_perangkat.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_TIDAK_SAH',
      'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
    );
  end if;

  -- Verifikasi kunci token rahasia perangkat bila terdaftar di kredensial_perangkat
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

  -- 3. Cari data pengguna berdasarkan email (anti-oracle: pesan dan kode diseragamkan)
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

  -- Validasi relasi tenant & peran terhadap perangkat
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

  -- Catat percobaan PIN
  insert into public.percobaan_pin (
    pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
  ) values (
    v_pengguna.id, v_perangkat.nama, v_berhasil, 'masuk_pin', v_pengguna.id, p_perangkat_id, now()
  );

  if not v_berhasil then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- Ambil daftar cabang yang diizinkan untuk pengguna
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
  'Verifikasi PIN staf saat login dari perangkat terdaftar (T2-02 / N F-01 & AUD-4).';

revoke all on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) from public;
grant execute on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) to anon, authenticated, service_role;
