-- ============================================================================
-- PROBE HAKIM H-F-10 — temuan baru hakim (PMB1-F-171): nama argumen RPC
-- `set_status_email_ringkasan` tidak cocok dengan pemanggilnya (Edge Function).
--
-- Pemanggil sungguhan: supabase/functions/ringkasan_harian/index.ts:297
--   body: { p_ringkasan_id: ringkas.id, p_status: ... }   (PostgREST memetakan kunci JSON
--   ke argumen BERNAMA — sama artinya dengan notasi `nama => nilai` di PostgreSQL)
-- Artefak yang diuji (dipanggil sungguhan dari kursi Owner Pusat A):
--   public.set_status_email_ringkasan(p_id uuid, p_status text)
--   supabase/migrations/0085_ringkasan_harian.sql:586-589
--
-- KONTROL NEGATIF (harus DITOLAK): argumen bernama `p_ringkasan_id` (persis yang dikirim Edge Function).
-- KONTROL POSITIF (harus BERHASIL): argumen bernama `p_id` — membuktikan RPC-nya hidup dan
--   probe ini bisa hijau; bila argumen di Edge Function diperbaiki, KONTROL NEGATIF menjadi
--   MERAH (probe ini memang harus diganti dengan uji baru oleh Pembangun).
--
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-10-set-status-email-nama-argumen.sql
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Owner Pusat A

do $$
declare
  v_id uuid;
begin
  perform public.hasilkan_ringkasan_harian('11111111-1111-1111-1111-111111111111'::uuid, '2026-09-25'::date);
  select id into v_id from public.ringkasan_harian
   where penyewa_id = '11111111-1111-1111-1111-111111111111' and tanggal = '2026-09-25';
  perform uji.harap(v_id is not null, 'baris ringkasan_harian ada untuk uji');

  -- KONTROL POSITIF: nama argumen sesuai definisi RPC (p_id)
  perform public.set_status_email_ringkasan(p_id => v_id, p_status => 'terkirim');
  perform uji.harap(
    exists (select 1 from public.ringkasan_harian where id = v_id and status_email = 'terkirim'),
    'KONTROL POSITIF: dipanggil dengan p_id, status email menjadi terkirim');

  -- Kembalikan ke tertunda agar uji utama berarti
  update public.ringkasan_harian set status_email = 'tertunda' where id = v_id;

  -- UJI UTAMA: nama argumen seperti yang dikirim Edge Function (p_ringkasan_id) — HARUS ditolak
  perform uji.harap_gagal_sebab(
    format($q$ select public.set_status_email_ringkasan(p_ringkasan_id => %L::uuid, p_status => 'terkirim') $q$, v_id),
    'does not exist|p_ringkasan_id',
    'RPC tidak mengenal argumen p_ringkasan_id kiriman Edge Function');

  perform uji.harap(
    (select status_email from public.ringkasan_harian where id = v_id) = 'tertunda',
    'status email TIDAK berubah oleh panggilan bernama p_ringkasan_id (tetap tertunda)');
end $$;
