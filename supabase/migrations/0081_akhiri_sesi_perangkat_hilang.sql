-- ============================================================================
-- MIGRASI 0081 — Akhiri Sesi dari Perangkat Lain & Penanganan Perangkat Hilang (T10-06)
--
-- Referensi:
--   - TECH_SPEC §5.1: rpc/daftar_sesi, rpc/keluar_semua_perangkat, rpc/akhiri_sesi
--   - PRD M12: Kasus tepi perangkat hilang/dicuri -> owner menekan "Cabut perangkat"
--     atau menandai "hilang" -> akses mati seketika, sesi aktif berakhir, jejak audit tercatat.
--   - docs/KEAMANAN.md §4 & §7: Pencabutan tidak menunggu token kedaluwarsa.
--   - Area: Role & Permission (ART-2), Audit Trail (ART-6/ART-7).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. RPC public.daftar_sesi()
-- ---------------------------------------------------------------------------
-- Mengembalikan daftar sesi (aktif & riwayat) dalam naungan penyewa pemanggil.
-- Owner / admin berizin kelola_pegawai melihat seluruh sesi staf di cabangnya/restonya.
-- Staf biasa (kasir, pelayan, dapur) hanya melihat riwayat sesi miliknya sendiri.
create or replace function public.daftar_sesi()
returns table (
  session_id text,
  perangkat_id uuid,
  nama_perangkat text,
  jenis_perangkat text,
  status_perangkat text,
  pengguna_id uuid,
  nama_pengguna text,
  email_pengguna text,
  peran text,
  cabang_id uuid,
  nama_cabang text,
  mulai timestamptz,
  berakhir_pada timestamptz,
  status text,
  diperbarui_pada timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_saya    uuid := auth.uid();
  v_boleh   boolean := public.boleh('kelola_pegawai');
begin
  if v_penyewa is null or v_saya is null then
    return;
  end if;

  return query
  select
    sp.session_id,
    sp.perangkat_id,
    p.nama as nama_perangkat,
    p.jenis as jenis_perangkat,
    p.status as status_perangkat,
    sp.pengguna_id,
    u.nama as nama_pengguna,
    u.email as email_pengguna,
    u.peran,
    sp.cabang_id,
    c.nama as nama_cabang,
    sp.mulai,
    sp.berakhir_pada,
    sp.status,
    sp.diperbarui_pada
  from public.sesi_perangkat sp
  join public.perangkat p on p.id = sp.perangkat_id
  join public.pengguna u on u.id = sp.pengguna_id
  left join public.cabang c on c.id = sp.cabang_id
  where sp.penyewa_id = v_penyewa
    and (v_boleh or sp.pengguna_id = v_saya)
  order by (sp.status = 'aktif') desc, sp.mulai desc;
end;
$$;

comment on function public.daftar_sesi() is
  'Mengembalikan daftar sesi aktif dan riwayat sesi pengguna/perangkat dengan filter otorisasi (T10-06 / TECH_SPEC §5.1).';

revoke all on function public.daftar_sesi() from public;
grant execute on function public.daftar_sesi() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Peningkatan RPC public.keluar_semua_perangkat(p_pengguna_id, p_alasan)
-- ---------------------------------------------------------------------------
-- Mengakhiri seluruh sesi aktif pengguna tertentu (atau diri sendiri bila NULL).
-- Mencatat baris audit ke public.catatan_audit.
drop function if exists public.keluar_semua_perangkat(uuid);

create or replace function public.keluar_semua_perangkat(
  p_pengguna_id uuid default null,
  p_alasan text default null
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

  -- Catat audit jejak pemutusan sesi
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    v_saya,
    'keluar_semua_perangkat',
    'sesi_perangkat',
    v_target,
    jsonb_build_object('target_pengguna_id', v_target),
    jsonb_build_object(
      'jumlah_sesi_dicabut', v_jumlah,
      'alasan', coalesce(p_alasan, 'Pencabutan seluruh sesi aktif perangkat')
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SESI_DICABUT',
    'pesan', format('%s sesi aktif berhasil diakhiri.', v_jumlah),
    'data', jsonb_build_object('jumlah', v_jumlah, 'pengguna_id', v_target)
  );
end;
$$;

comment on function public.keluar_semua_perangkat(uuid, text) is
  'Mencabut seluruh sesi aktif pengguna dan mencatat jejak audit (T10-06 / TECH_SPEC §5.1).';

revoke all on function public.keluar_semua_perangkat(uuid, text) from public;
grant execute on function public.keluar_semua_perangkat(uuid, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Peningkatan RPC public.akhiri_sesi(p_session_id, p_alasan)
-- ---------------------------------------------------------------------------
-- Mengakhiri satu sesi aktif tertentu dan mencatat jejak audit.
drop function if exists public.akhiri_sesi(text);

create or replace function public.akhiri_sesi(
  p_session_id text default null,
  p_alasan text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sid text := coalesce(p_session_id, nullif(auth.jwt() ->> 'session_id', ''));
  v_penyewa uuid := public.penyewa_saya();
  v_uid uuid := auth.uid();
  v_sesi record;
  v_jml int;
begin
  if v_uid is null or v_penyewa is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Autentikasi diperlukan.');
  end if;

  if v_sid is null then
    return jsonb_build_object('berhasil', false, 'kode', 'INVALID_INPUT', 'pesan', 'Session ID tidak ditentukan.');
  end if;

  -- Cari sesi
  select * into v_sesi
    from public.sesi_perangkat
   where session_id = v_sid
     and penyewa_id = v_penyewa;

  if v_sesi.session_id is null then
    return jsonb_build_object('berhasil', false, 'kode', 'NOT_FOUND', 'pesan', 'Sesi tidak ditemukan.');
  end if;

  -- Otorisasi: pemilik sesi sendiri atau staf pemegang izin kelola_pegawai
  if v_sesi.pengguna_id <> v_uid and not public.boleh('kelola_pegawai') then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Anda tidak memiliki hak mengakhiri sesi ini.');
  end if;

  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where session_id = v_sid
     and penyewa_id = v_penyewa
     and status = 'aktif';

  get diagnostics v_jml = row_count;

  -- Catat jejak audit
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    v_uid,
    'akhiri_sesi',
    'sesi_perangkat',
    v_sesi.pengguna_id,
    jsonb_build_object('session_id', v_sid, 'perangkat_id', v_sesi.perangkat_id, 'status', v_sesi.status),
    jsonb_build_object('session_id', v_sid, 'status', 'dicabut', 'alasan', coalesce(p_alasan, 'Sesi diakhiri secara manual'))
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SESI_DIAKHIRI',
    'pesan', 'Sesi berhasil diakhiri.',
    'data', jsonb_build_object('session_id', v_sid, 'jumlah', v_jml)
  );
end;
$$;

comment on function public.akhiri_sesi(text, text) is
  'Mengakhiri satu sesi tertentu (sendiri atau bawahan) dan mencatat jejak audit (T10-06 / N F-03).';

revoke all on function public.akhiri_sesi(text, text) from public;
grant execute on function public.akhiri_sesi(text, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. RPC public.tandai_perangkat_hilang(p_perangkat_id, p_alasan)
-- ---------------------------------------------------------------------------
-- Menandai perangkat sebagai 'hilang' (bukan sekadar dicabut), menonaktifkannya,
-- memutuskan seluruh sesi aktif yang berjalan padanya seketika, dan mencatat audit.
create or replace function public.tandai_perangkat_hilang(
  p_perangkat_id uuid,
  p_alasan text default 'Perangkat dilaporkan hilang atau dicuri'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid := public.penyewa_saya();
  v_saya    uuid := auth.uid();
  v_p       record;
  v_jml_sesi int;
begin
  if v_penyewa is null or v_saya is null then
    return jsonb_build_object('berhasil', false, 'kode', 'UNAUTHORIZED', 'pesan', 'Autentikasi diperlukan.');
  end if;

  if not public.boleh('kelola_pegawai') then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Hanya pengelola berwenang yang dapat menandai perangkat hilang.');
  end if;

  select * into v_p
    from public.perangkat
   where id = p_perangkat_id
     and penyewa_id = v_penyewa;

  if v_p.id is null then
    return jsonb_build_object('berhasil', false, 'kode', 'NOT_FOUND', 'pesan', 'Perangkat tidak ditemukan.');
  end if;

  -- Tandai status 'hilang' dan nonaktifkan perangkat
  update public.perangkat
     set aktif = false,
         status = 'hilang',
         dicabut_oleh = v_saya,
         dicabut_pada = now(),
         catatan = coalesce(catatan || ' | ', '') || coalesce(p_alasan, 'Perangkat hilang')
   where id = p_perangkat_id;

  -- Cabut seketika seluruh sesi yang masih aktif pada perangkat ini (T1-25 / T10-06)
  update public.sesi_perangkat
     set status = 'dicabut',
         diperbarui_pada = now()
   where perangkat_id = p_perangkat_id
     and status = 'aktif';

  get diagnostics v_jml_sesi = row_count;

  -- Catat audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    v_saya,
    'tandai_perangkat_hilang',
    'perangkat',
    p_perangkat_id,
    jsonb_build_object('status', v_p.status, 'aktif', v_p.aktif),
    jsonb_build_object(
      'status', 'hilang',
      'aktif', false,
      'sesi_dicabut', v_jml_sesi,
      'alasan', p_alasan
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'PERANGKAT_HILANG_DICABUT',
    'pesan', format('Perangkat berhasil ditandai hilang dan %s sesi aktif seketika dicabut.', v_jml_sesi),
    'data', jsonb_build_object(
      'perangkat_id', p_perangkat_id,
      'sesi_dicabut', v_jml_sesi
    )
  );
end;
$$;

comment on function public.tandai_perangkat_hilang(uuid, text) is
  'Menandai status perangkat sebagai hilang, mencabut seluruh sesi seketika, dan mencatat jejak audit (T10-06 / PRD M12).';

revoke all on function public.tandai_perangkat_hilang(uuid, text) from public;
grant execute on function public.tandai_perangkat_hilang(uuid, text) to authenticated, service_role;
