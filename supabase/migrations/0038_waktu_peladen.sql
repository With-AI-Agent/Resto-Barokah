-- ============================================================================
-- 0038 — WAKTU PELADEN (sisa Fase 4 butir c: kabel data realtime KDS)
--
-- Layar dapur/bar mengurutkan tiket FIFO dan menandai pesanan lama dari UMUR
-- tiket. Umur itu selisih `pesanan.dikirim_ke_dapur_pada` (ditulis peladen)
-- dengan "sekarang". Kalau "sekarang" diambil dari jam tablet dapur, jam yang
-- meleset beberapa menit langsung membuat pesanan sehat terlihat "mendesak"
-- (atau sebaliknya: pesanan basi terlihat biasa). Karena itu papan mengambil
-- waktu dari peladen lewat fungsi ini.
--
-- Sifat fungsi:
--   * `stable` (bukan `immutable`): `now()` = waktu mulai transaksi, jadi dua
--     panggilan dalam satu transaksi memberi nilai sama — cukup untuk layar.
--   * `security invoker` + `search_path` dikunci: fungsi TIDAK membuka satu
--     baris data pun dan tidak boleh menjadi jalan memotong RLS (pelajaran
--     ACL/search_path migrasi 0023 & 0027).
--   * Hanya `authenticated` yang boleh memanggil: waktu peladen bukan data
--     rahasia, tapi tidak ada alasan membuka endpoint publik baru.
-- ============================================================================

create or replace function public.waktu_peladen()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'iso', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'epoch_ms', floor(extract(epoch from now()) * 1000)::bigint
  );
$$;

comment on function public.waktu_peladen() is
  'Waktu peladen (UTC) untuk layar yang membandingkan umur data: papan dapur/bar memakai ini, bukan jam perangkat. Tidak membuka data apa pun (security invoker, tanpa tabel).';

revoke all on function public.waktu_peladen() from public, anon;
grant execute on function public.waktu_peladen() to authenticated;
