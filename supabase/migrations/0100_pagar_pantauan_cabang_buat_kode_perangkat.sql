-- ============================================================================
-- 0100 — Pagar pantauan cabang pada RPC buat_kode_perangkat (PMB1-F-085)
-- ============================================================================
-- Latar (temuan PMB1-F-085, kartu K-F-06.2, K-2):
--   Definisi 0030 hanya memeriksa (a) izin `kelola_pegawai` dan (b) cabang
--   sasaran berada dalam penyewa yang sama. Akibatnya admin cabang A yang sah
--   dapat menerbitkan kode pendaftaran perangkat untuk cabang B yang BUKAN
--   pantauannya (probe: bukti/F-06-admin-lintas-cabang.sql). KEAMANAN §4b
--   menghendaki admin cabang hanya mengelola perangkat cabangnya sendiri.
--
-- Perbaikan:
--   Setelah cabang sasaran dinyatakan valid, pemanggil WAJIB memantau cabang
--   itu menurut public.cabang_pantau_saya(uuid) — sama persis pagar yang
--   dipakai RLS meja/pesanan/shift (0007/0045/0046). Owner_pusat tetap
--   memantau seluruh cabang penyewanya (definisi helper 0007), jadi alur sah
--   tidak berubah; admin cabang ditolak dengan FORBIDDEN tanpa baris tersimpan.
--
-- Berkas 0030 TIDAK disunting (beban periksa-migrasi-beku); fungsi ditulis
-- ulang utuh di sini (CREATE OR REPLACE, idempoten).
-- Uji: supabase/tes/kode_perangkat_lintas_cabang.sql
-- ============================================================================

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

  -- PMB1-F-085: pemanggil harus MEMANTAU cabang sasaran. Admin cabang hanya
  -- memantau cabangnya sendiri (pengguna_cabang); owner_pusat memantau semua
  -- cabang penyewanya. Tanpa pagar ini admin cabang bisa menerbitkan kode
  -- untuk cabang lain dalam penyewa yang sama.
  if not public.cabang_pantau_saya(v_cabang) then
    return jsonb_build_object('berhasil', false, 'kode', 'FORBIDDEN', 'pesan', 'Cabang tujuan berada di luar pantauan Anda.');
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
  'Membuat kode sekali pakai pendaftaran perangkat baru dengan masa berlaku 15 menit (T1-24). Sejak 0100: cabang sasaran wajib dalam pantauan pemanggil (PMB1-F-085).';

revoke all on function public.buat_kode_perangkat(uuid, text, text, text[]) from public;
grant execute on function public.buat_kode_perangkat(uuid, text, text, text[]) to authenticated, service_role;
