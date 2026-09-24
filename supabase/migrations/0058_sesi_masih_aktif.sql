-- ============================================================================
-- Migrasi 0058: Penegakan sesi perangkat aktif (N F-03 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-03: `sesi_perangkat.berakhir_pada`
--     ditulis di `0030_sesi_dan_persetujuan_perangkat.sql:490`, tetapi TIDAK
--     ada satu pun RPC atau policy yang membaca `status='aktif' AND
--     berakhir_pada > now()` saat permintaan berikutnya dilayani. Akibatnya,
--     pencabutan sesi (`keluar_semua_perangkat`) hanya menulis status tanpa
--     efek阻断 ke RPC lain.
--
-- Solusi (minimal dan non-invasif untuk berkas beku 0001–0056):
--   1. Fungsi helper `public.sesi_masih_aktif(p_session_id text) returns boolean`
--      yang menanyakan `sesi_perangkat` lewat SECURITY DEFINER.
--   2. Fungsi helper `public.sesi_saya() returns text` yang mengambil
--      session_id dari konfigurasi `request.jwt.claim.session_id`.
--   3. RPC publik `public.periksa_sesi_aman(p_session_id text)` yang
--      mengembalikan jsonb `{ aktif, berakhir_pada, sisa_detik }`.
--      Ini dipakai oleh aplikasi (auth.ts) untuk memeriksa sesi SEBELUM
--      melakukan operasi kritis (bayar, buka shift, dll.).
--
-- Mengapa tidak pakai trigger di tabel beku:
--   * Trigger `BEFORE INSERT/UPDATE` di `pesanan`/`pembayaran` adalah modifikasi
--     struktur trigger pada tabel beku. Penjaga `periksa-migrasi-beku.py`
--     tidak menolak ini (cuma menolak perubahan kolom), tetapi disiplin "jangan
--     ubah berkas beku" lebih aman jika kita pakai helper + hook aplikasi.
--   * Aplikasi adalah titik masuk 100% permintaan; jika helper dipanggil di
--     `auth.ts` sebelum RPC, maka setiap permintaan terpasang pagar sesi.
--   * Untuk database-only caller (admin tools, migrasi), mereka diharapkan
--     melewati `periksa_sesi_aman()` sendiri.
--
-- Kelas cacat ini = F F-13 (oracle sesi kadaluarsa). Setelah migrasi ini:
--   - Aplikasi wajib memanggil `periksa_sesi_aman()` sebelum RPC sensitif.
--   - Bila sesi sudah dicabut / kedaluwarsa, aplikasi menolak permintaan.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Helper sesi_masih_aktif()
-- ---------------------------------------------------------------------------
create or replace function public.sesi_masih_aktif(p_session_id text)
returns boolean
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text;
  v_berakhir timestamptz;
begin
  if p_session_id is null or btrim(p_session_id) = '' then
    return false;
  end if;

  select status, berakhir_pada
    into v_status, v_berakhir
    from public.sesi_perangkat
   where session_id = p_session_id;

  if v_status is null then
    return false;
  end if;

  if v_status <> 'aktif' then
    return false;
  end if;

  if v_berakhir is null or v_berakhir <= now() then
    return false;
  end if;

  return true;
end;
$$;

comment on function public.sesi_masih_aktif(text) is
  'N F-03: mengembalikan TRUE hanya bila session_id ada, status=aktif, dan berakhir_pada > now(). Helper dipakai aplikasi untuk pagar sesi di setiap permintaan.';

revoke all on function public.sesi_masih_aktif(text) from public;
grant execute on function public.sesi_masih_aktif(text) to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Helper sesi_saya() — ambil session_id dari konfigurasi request
-- ---------------------------------------------------------------------------
create or replace function public.sesi_saya()
returns text
language sql
stable
as $$
  select nullif(current_setting('request.jwt.claim.session_id', true), '');
$$;

comment on function public.sesi_saya() is
  'N F-03: mengembalikan session_id perangkat dari klaim JWT (request.jwt.claim.session_id). Dipakai auth.ts untuk menetapkan pagar sesi per-permintaan.';

grant execute on function public.sesi_saya() to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — RPC publik periksa_sesi_aman()
-- ---------------------------------------------------------------------------
create or replace function public.periksa_sesi_aman(p_session_id text default null)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_session_id text := coalesce(p_session_id, public.sesi_saya());
  v_status text;
  v_berakhir timestamptz;
  v_mulai timestamptz;
  v_pengguna uuid;
  v_perangkat uuid;
  v_aktif boolean;
  v_sisa_detik int;
begin
  if v_session_id is null then
    return jsonb_build_object(
      'aktif', false,
      'kode', 'SESI_TIDAK_ADA',
      'pesan', 'Tidak ada session_id pada permintaan.'
    );
  end if;

  select status, berakhir_pada, mulai, pengguna_id, perangkat_id
    into v_status, v_berakhir, v_mulai, v_pengguna, v_perangkat
    from public.sesi_perangkat
   where session_id = v_session_id;

  if v_status is null then
    return jsonb_build_object(
      'aktif', false,
      'kode', 'SESI_TIDAK_DIKENAL',
      'pesan', 'Session_id tidak ditemukan.'
    );
  end if;

  v_aktif := (v_status = 'aktif' and v_berakhir > now());

  if v_aktif then
    v_sisa_detik := greatest(0, extract(epoch from (v_berakhir - now()))::int);
  else
    v_sisa_detik := 0;
  end if;

  return jsonb_build_object(
    'aktif', v_aktif,
    'kode', case when v_aktif then 'SESI_AKTIF'
                 when v_status <> 'aktif' then 'SESI_DICABUT'
                 else 'SESI_KEDALUWARSA' end,
    'pesan', case when v_aktif then 'Sesi masih berlaku.'
                  when v_status <> 'aktif' then 'Sesi sudah dicabut.'
                  else 'Sesi sudah kedaluwarsa.' end,
    'data', jsonb_build_object(
      'session_id', v_session_id,
      'status', v_status,
      'mulai', v_mulai,
      'berakhir_pada', v_berakhir,
      'sisa_detik', v_sisa_detik,
      'pengguna_id', v_pengguna,
      'perangkat_id', v_perangkat
    )
  );
end;
$$;

comment on function public.periksa_sesi_aman(text) is
  'N F-03: pagar sesi per-permintaan. Aplikasi WAJIB memanggil RPC ini sebelum operasi kritis (bayar, buka/tutup shift, simpan pesanan).';

revoke all on function public.periksa_sesi_aman(text) from public;
grant execute on function public.periksa_sesi_aman(text) to authenticated, anon, service_role;
