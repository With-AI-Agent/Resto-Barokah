-- ============================================================================
-- 0106 — Penanda penyewa/permohonan pada aktivasi pemulihan darurat
--        (PMB1-F-239 · KEPUTUSAN LEE 2026-10-07)
-- ============================================================================
-- Latar (temuan PMB1-F-239, kartu H-P-1B-00, K-3):
--   Fungsi 0105 `selesaikan_pemulihan_darurat(p_kunci_perangkat)` memilih
--   permohonan lewat pemindaian SELURUH tabel pemulihan_perangkat LINTAS
--   penyewa lalu mengambil satu baris terbaru:
--       order by q.diminta_pada desc limit 1
--   tanpa filter penyewa_id dan tanpa id permohonan. Akibat (terbukti probe
--   H-F-06.5 A10/A11, 1 LULUS · 0 GAGAL):
--     * Permohonan kembar satu penyewa berkunci sama -> satu panggilan selalu
--       mengaktifkan yang TERBARU; permohonan lama tertinggal 'menunggu'
--       tanpa kedaluwarsa, tanpa kabar.
--     * Kunci kembar LINTAS penyewa (satu pemilik dua resto, kunci bawaan
--       vendor, pemilik memilih kunci sama) -> panggilan pemilik A bisa
--       mengaktifkan permohonan milik penyewa B, permohonan A tertinggal.
--   KEPUTUSAN LEE 2026-10-07 (REKAM_PESAN_PEMILIK §31 butir 37): penanda
--   penyewa/permohonan DIPILIH; dibangun Pembangun ronde 4 (berkas ini).
--
-- Perbaikan:
--   Fungsi kini mengunci SATU permohonan lewat PENANDA PERMOHONAN: id (uuid)
--   yang dikembalikan `pulihkan_perangkat` (0102) saat pengajuan. Pemohon sah
--   memang memegang id itu dari jawaban pengajuannya, jadi ia penanda tak
--   terpisahkan dari alur, BUKAN rahasia tambahan. Seluruh syarat bukti
--   (status 'menunggu', masa tenggang lewat, kunci perangkat cocok dengan
--   hash perangkat permohonan ITU) dipasang pada baris yang ditunjuk — tidak
--   ada lagi pemilihan bebas lintas penyewa. Tanda tangan lama satu-argumen
--   (0105) dijatuhkan supaya jalur pemilihan bebas itu benar-benar tertutup.
--
-- Batas jujur (dicatat, bukan disembunyikan):
--   * Id permohonan adalah PENANDA, bukan bukti sahih tersendiri — kunci
--     perangkat tetap wajib cocok dengan bcrypt hash perangkat permohonan
--     yang ditunjuk; id acak 128-bit tidak menebus apa pun tanpa kunci.
--   * Permohonan 'menunggu' yang tidak pernah diselesaikan tetap tinggal
--     sampai dibatalkan/diselesaikan (tidak ada kedaluwarsa otomatis — sama
--     seperti 0105). Bahaya pemilihan implisitnya sudah hilang; pembatalan
--     tetap lewat jalur ber-sesi atau eskalasi Tingkat 4 (KEPUTUSAN LEE
--     2026-10-07, PMB1-F-238 — `batalkan_pemulihan` sengaja TIDAK dibuka
--     tanpa sesi).
--   * Layar darurat di aplikasi belum ada (residu sejak ronde 1); prosedur
--     resmi tetap Tingkat 4 — lihat docs/ops/PEMULIHAN_PERANGKAT.md §3.
--
-- Uji: supabase/tes/pemulihan_aktivasi_darurat.sql (diselaraskan ke tanda
--      tangan baru + kasus penanda F-239: kembar satu penyewa & lintas
--      penyewa).
-- RUJUKAN: kartu/H-P-1B-00.md §F-239 · bukti/H-F-06.5-probe-105.sql.
-- ============================================================================

create or replace function public.selesaikan_pemulihan_darurat(
  p_permohonan_id   uuid,
  p_kunci_perangkat text
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_antrean    record;
begin
  if p_permohonan_id is null or p_kunci_perangkat is null or length(p_kunci_perangkat) < 16 then
    raise exception 'Kunci perangkat darurat tidak valid.';
  end if;

  -- PMB1-F-239: pencarian DIIKAT pada permohonan yang ditunjuk pemegang id
  -- (penanda penyewa/permohonan). Syarat bukti tetap penuh: status menunggu,
  -- masa tenggang lewat, dan kunci cocok dengan kredensial perangkat
  -- permohonan ITU (bukan hasil pemilihan bebas lintas penyewa).
  select q.id, q.penyewa_id, q.perangkat_id, q.pemohon_id
    into v_antrean
    from public.pemulihan_perangkat q
    join public.kredensial_perangkat kp on kp.perangkat_id = q.perangkat_id
   where q.id = p_permohonan_id
     and q.status = 'menunggu'
     and now() >= q.aktif_setelah
     and crypt(p_kunci_perangkat, kp.kunci_hash) = kp.kunci_hash;

  if v_antrean.id is null then
    -- Jangan bocorkan alasan mana yang gagal (anti-orakel): pesan seragam.
    raise exception 'Permohonan pemulihan tidak ditemukan, belum melewati masa tenggang, atau kunci perangkat salah.';
  end if;

  update public.pemulihan_perangkat
     set status = 'selesai',
         diselesaikan_pada = now()
   where id = v_antrean.id;

  update public.perangkat
     set aktif = true
   where id = v_antrean.perangkat_id;

  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_antrean.penyewa_id,
    v_antrean.pemohon_id,
    'selesaikan_pemulihan_darurat',
    'pemulihan_perangkat',
    v_antrean.id,
    jsonb_build_object(
      'perangkat_id', v_antrean.perangkat_id,
      'diaktifkan_pada', now(),
      'jalur', 'tanpa_sesi_penanda_permohonan',
      'temuan', 'PMB1-F-239'
    )
  );

  return true;
end;
$$;

comment on function public.selesaikan_pemulihan_darurat(uuid, text) is
  'Mengaktifkan SATU permohonan pemulihan darurat yang ditunjuk id permohonannya (dikembalikan pulihkan_perangkat saat pengajuan) dengan bukti kunci perangkat pemohon. TANPA sesi; penanda penyewa/permohonan mengikat pencarian (PMB1-F-239, pengganti pemilihan bebas 0105).';

revoke all on function public.selesaikan_pemulihan_darurat(uuid, text) from public;
-- anon tetap diberi execute: pintu darurat TANPA sesi. Perlindungan = id
-- permohonan (penanda) + kunci perangkat bcrypt yang dipilih pemohon.
grant execute on function public.selesaikan_pemulihan_darurat(uuid, text) to anon, authenticated, service_role;

-- PMB1-F-239: jalur lama satu-argumen (0105) memindai SELURUH tabel lintas
-- penyewa dan memilih permohonan terbaru — dijatuhkan supaya pemilihan bebas
-- itu tidak bisa dipanggil lagi dari mana pun.
drop function if exists public.selesaikan_pemulihan_darurat(text);
