-- ============================================================================
-- UJI: WAKTU PELADEN (0038) — papan dapur/bar menghitung umur tiket dari jam
-- PELADEN, bukan jam perangkat. Yang dibuktikan: fungsi tidak bisa dipanggil
-- anonim, jawabannya benar-benar waktu UTC yang sah, dan fungsinya TIDAK
-- security definer (tidak boleh jadi jalan memotong RLS).
-- ============================================================================

-- 1. Anonim ditolak (endpoint baru tidak boleh terbuka untuk umum).
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.waktu_peladen()$$,
  'permission denied|tidak diizinkan',
  'anon ditolak memanggil waktu_peladen');
reset role;

-- 2. Pegawai apa pun (sudah masuk) boleh memanggil: fungsi ini bukan data.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (select right(public.waktu_peladen()->>'iso', 1)),
  'Z', 'waktu peladen dikirim sebagai UTC berakhiran Z');
select uji.harap(
  (select length(public.waktu_peladen()->>'iso') = 24),
  'bentuk ISO milidetik (YYYY-MM-DDTHH:MM:SS.mmmZ) panjangnya tetap 24');

-- 3. Nilainya benar-benar "sekarang" menurut peladen (bukan angka mati).
select uji.harap(
  (select (public.waktu_peladen()->>'iso')::timestamptz
          between now() - interval '10 seconds' and now() + interval '10 seconds'),
  'iso yang dikembalikan cocok dengan now() peladen (dalam 10 detik)');
select uji.harap(
  (select (public.waktu_peladen()->>'epoch_ms')::bigint
          between floor(extract(epoch from now()) * 1000)::bigint - 10000
              and floor(extract(epoch from now()) * 1000)::bigint + 10000),
  'epoch_ms cocok dengan now() peladen (dalam 10 detik)');
reset role;

-- 4. Bukan security definer + search_path terkunci: fungsi yang cuma melaporkan
--    jam tidak boleh punya hak istimewa (pelajaran ACL/search_path 0023 & 0027).
select uji.sama(
  (select p.prosecdef from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'waktu_peladen'),
  false, 'waktu_peladen BUKAN security definer (security invoker)');
select uji.harap(
  (select coalesce(p.proconfig::text like '%search_path=public, pg_temp%', false)
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'waktu_peladen'),
  'search_path dikunci ke public, pg_temp');
