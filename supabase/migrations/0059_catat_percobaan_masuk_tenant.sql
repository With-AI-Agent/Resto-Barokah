-- ============================================================================
-- MIGRASI 0059 — Isolasi Penyewa & Pencabutan Anon pada percobaan_masuk (N F-05)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-05: percobaan_masuk bisa ditulis anon
--     lintas penyewa tanpa batas dan periksa_kunci_masuk terbaca anon.
--   - docs/KEAMANAN.md §1 & §2: deny by default, periksa di database.
-- ============================================================================

-- 1. Cabut hak eksekusi anon dari catat_percobaan_masuk & periksa_kunci_masuk
revoke execute on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) from anon;
revoke execute on function public.periksa_kunci_masuk(uuid, uuid) from anon;

-- 2. Perketat catat_percobaan_masuk dengan validasi penyewa
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
declare
  v_penyewa uuid;
begin
  if p_penyewa_id is null then
    raise exception 'Penyewa ID wajib diisi.';
  end if;

  -- Jika pemanggil adalah pengguna authenticated (bukan service_role),
  -- pastikan penyewa_id cocok dengan tenant pemanggil.
  if current_setting('role', true) = 'authenticated' then
    v_penyewa := public.penyewa_saya();
    if v_penyewa is null or v_penyewa <> p_penyewa_id then
      raise exception 'Akses lintas penyewa ditolak.';
    end if;
  end if;

  -- Pastikan penyewa ada di database
  if not exists (select 1 from public.penyewa where id = p_penyewa_id) then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- Jika pengguna_id diberikan, pastikan pengguna milik penyewa yang sama
  if p_pengguna_id is not null then
    if not exists (select 1 from public.pengguna where id = p_pengguna_id and penyewa_id = p_penyewa_id) then
      raise exception 'Pengguna tidak terdaftar pada penyewa ini.';
    end if;
  end if;

  -- Jika perangkat_id diberikan, pastikan perangkat milik penyewa yang sama
  if p_perangkat_id is not null then
    if not exists (select 1 from public.perangkat where id = p_perangkat_id and penyewa_id = p_penyewa_id) then
      raise exception 'Perangkat tidak terdaftar pada penyewa ini.';
    end if;
  end if;

  insert into public.percobaan_masuk (
    penyewa_id, pengguna_id, perangkat_id, berhasil, sebab, waktu
  ) values (
    p_penyewa_id, p_pengguna_id, p_perangkat_id, p_berhasil, p_sebab, now()
  );
end;
$$;

comment on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) is
  'Mencatat hasil percobaan masuk dengan validasi integritas tenant (N F-05). Hak anon dicabut.';

-- 3. Perketat periksa_kunci_masuk: hanya pemanggil se-resto atau service_role
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
  -- Verifikasi hak akses: bila authenticated, hanya boleh periksa diri sendiri
  -- atau bawahan se-resto (izin kelola_pegawai)
  if current_setting('role', true) = 'authenticated' then
    if p_pengguna_id is not null then
      if p_pengguna_id <> auth.uid() and not (public.sepenyewa(p_pengguna_id) and public.boleh('kelola_pegawai')) then
        raise exception 'Tidak berhak memeriksa status kunci pengguna lain.';
      end if;
    end if;
  end if;

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
    'sisa_percobaan_akun', greatest(5 - v_gagal_akun, 0),
    'sisa_percobaan_perangkat', greatest(12 - v_gagal_perangkat, 0)
  );
end;
$$;

comment on function public.periksa_kunci_masuk(uuid, uuid) is
  'Memeriksa status kunci akun/perangkat dengan pembatasan hak akses se-resto (N F-05). Hak anon dicabut.';
