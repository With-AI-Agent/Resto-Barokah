-- ============================================================================
-- Migrasi 0059: catat_percobaan_masuk() divalidasi tenant (N F-05 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-05: `catat_percobaan_masuk` (RPC 7 di
--     `0030_sesi_dan_persetujuan_perangkat.sql:566`) SECURITY DEFINER +
--     `grant execute to anon, authenticated, service_role` tanpa validasi
--     `p_penyewa_id`. Akibatnya, `anon` bisa tulis baris percobaan_masuk
--     untuk `penyewa_id` manapun (lintas tenant). Batas laju "5x akun / 12x
--     perangkat" yang dihitung oleh `periksa_kunci_masuk` jadi tidak valid
--     karena baris lintas tenant bisa mengotori hitungan resto korban.
--
-- Solusi (non-invasif terhadap berkas beku 0030):
--   * `create or replace function` untuk `catat_percobaan_masuk` dengan
--     validasi: untuk pemanggil `anon`/`authenticated`, `p_penyewa_id`
--     WAJIB sama dengan `public.penyewa_saya()`. Untuk `service_role`,
--     `p_penyewa_id` boleh bebas (untuk migrasi/sebar/admin tools).
--   * Kalau `auth.uid()` NULL dan role bukan `service_role` → TOLAK
--     (kasus `anon` yang tidak punya auth).
--
-- Kelas cacat ini = F F-14 (oracle percobaan_masuk lintas tenant). Setelah
-- migrasi ini, percobaan_masuk hanya boleh diisi untuk tenant pemanggil.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Fungsi catat_percobaan_masuk() versi aman-tenant
-- ---------------------------------------------------------------------------
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
  v_uid  uuid := auth.uid();
  v_role text := coalesce(
    current_setting('request.jwt.claim.role', true),
    (select rolname from pg_roles where oid = (select current_user::regrole::oid))
  );
  v_penyewa_saya uuid := public.penyewa_saya();
begin
  -- service_role (untuk migrasi/admin tools) BOLEH menulis lintas tenant.
  if v_role <> 'service_role' then
    -- Untuk anon/authenticated: WAJIB p_penyewa_id tidak NULL.
    if p_penyewa_id is null then
      raise exception using
        errcode = 'insufficient_privilege',
        message = 'catat_percobaan_masuk: p_penyewa_id wajib diisi untuk peran anon/authenticated.';
    end if;

    -- Kalau ada auth.uid(), harus ada penyewa_saya juga.
    if v_uid is not null and v_penyewa_saya is null then
      raise exception using
        errcode = 'insufficient_privilege',
        message = 'catat_percobaan_masuk: auth.uid() ada tapi penyewa_saya() null — pemanggil tidak terikat resto.';
    end if;

    -- Cek lintas-tenant: p_penyewa_id harus sama dengan penyewa_saya().
    if v_penyewa_saya is not null and p_penyewa_id <> v_penyewa_saya then
      raise exception using
        errcode = 'insufficient_privilege',
        message = 'catat_percobaan_masuk: p_penyewa_id tidak sesuai dengan resto pemanggil (lintas-tenant ditolak).';
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
  'N F-05: mencatat percobaan masuk. p_penyewa_id WAJIB cocok dengan penyewa_saya() untuk anon/authenticated; service_role bebas (untuk migrasi/admin).';

revoke all on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) from public;
grant execute on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) to anon, authenticated, service_role;
