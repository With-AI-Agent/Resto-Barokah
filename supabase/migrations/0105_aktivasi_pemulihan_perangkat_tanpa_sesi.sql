-- ============================================================================
-- MIGRASI 0105 — PMB1-F-083 ronde 3 & PMB1-F-234 (K-2): aktivasi perangkat
--                darurat TANPA sesi — kunci induk yang dijanjikan §4b kini
--                benar-benar bisa dijalankan sampai akhir
-- ============================================================================
-- Baseline yang dilanggar (vonis H-F-06.3, kartu H-F-06.3 §1 F-083 + temuan
-- baru F-234): migrasi 0102 memecah separuh deadlock — pengajuan pemulihan
-- (pulihkan_perangkat) bisa tanpa sesi — tetapi AKTIVASI sesudah masa tenggang
-- 30 menit (selesaikan_pemulihan, 0028 bagian 5) masih menuntut auth.uid() +
-- izin kelola_pegawai, dan 0 pemanggil klien. Akibatnya perangkat darurat
-- selamanya nonaktif dan login menolaknya (PERANGKAT_TIDAK_SAH): owner yang
-- kehilangan SELURUH perangkat tetap tidak bisa masuk. Janji KEAMANAN §4b
-- Tingkat 3 ("kunci induk ... pendaftaran perangkat darurat") belum utuh, dan
-- docs/ops/PEMULIHAN_PERANGKAT.md menyuruh menjalankan langkah yang tidak bisa
-- dijalankan orang yang kehilangan seluruh perangkat.
--
-- Rancangan perbaikan:
--   * RPC baru `selesaikan_pemulihan_darurat(p_kunci_perangkat)` — TANPA sesi.
--     Bukti kepemilikan = KUNCI PERANGKAT yang pemohon pilih sendiri saat
--     pengajuan (disimpan bcrypt di kredensial_perangkat oleh 0102). Hanya
--     pihak yang menyelesaikan pengajuan darurat yang tahu kunci itu; kode
--     pemulihan sendiri sudah hangus sekali-pakai pada langkah pengajuan.
--     Sidik jari id antrean (uuid acak 128-bit) TIDAK dipakai sebagai bukti —
--     kunci lebih kuat, dan pemanggil tidak perlu tahu id antrean.
--   * Syarat tetap ketat: antrean berstatus 'menunggu', masa tenggang 30 menit
--     SUDAH lewat, kunci cocok bcrypt. Sesudah aktif: antrean 'selesai',
--     perangkat aktif=true, jejak audit (pelaku = pemohon pemulihan).
--   * Jalur ber-sesi lama `selesaikan_pemulihan` (0028) TIDAK diubah — owner
--     yang masih punya perangkat lain tetap bisa menyelesaikan dari aplikasi.
--
-- Batas jujur (dicatat juga di kartu B-F-06.3):
--   * Kata sandi + TOTP pada kunci induk §4b belum mungkin (klaster cara masuk
--     keputusan Lee B belum dibangun) — perlindungan jalur ini = kode >= 20
--     karakter bcrypt sekali pakai (pengajuan) + kunci perangkat >= 16 karakter
--     bcrypt (aktivasi) + masa tenggang 30 menit + jejak audit.
--   * Pembatas laju lapisan SQL tidak bertahan bersama raise (pola 0102);
--     pembatas laju sesungguhnya milik lapisan tepi (infra).
--   * `batalkan_pemulihan` masih menuntut sesi — celah simetris untuk owner
--     yang kehilangan semua perangkat; TIDAK diperbaiki diam-diam di sini,
--     dicatat sebagai temuan baru di kartu B-F-06.3 (K-4, ranah verifikasi).
--   * Layar darurat di aplikasi belum ada (residu sejak ronde 1).
--
-- Uji: supabase/tes/pemulihan_aktivasi_darurat.sql
-- RUJUKAN: kartu/H-F-06.3.md §1 F-083 & §2 F-234 · kartu/B-F-06.3.md.
-- ============================================================================

create or replace function public.selesaikan_pemulihan_darurat(p_kunci_perangkat text)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_antrean    record;
begin
  if p_kunci_perangkat is null or length(p_kunci_perangkat) < 16 then
    raise exception 'Kunci perangkat darurat tidak valid.';
  end if;

  -- Cari permohonan menunggu yang masa tenggangnya sudah lewat dan kuncinya
  -- cocok dengan kredensial perangkat daruratnya (bukti kepemilikan).
  select q.id, q.penyewa_id, q.perangkat_id, q.pemohon_id
    into v_antrean
    from public.pemulihan_perangkat q
    join public.kredensial_perangkat kp on kp.perangkat_id = q.perangkat_id
   where q.status = 'menunggu'
     and now() >= q.aktif_setelah
     and crypt(p_kunci_perangkat, kp.kunci_hash) = kp.kunci_hash
   order by q.diminta_pada desc
   limit 1;

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
      'jalur', 'tanpa_sesi'
    )
  );

  return true;
end;
$$;

comment on function public.selesaikan_pemulihan_darurat(text) is
  'PMB1-F-083/F-234: mengaktifkan perangkat darurat sesudah masa tenggang 30 menit TANPA sesi — bukti kepemilikan = kunci perangkat yang dipilih pemohon saat pengajuan (bcrypt). Melengkapi jalur pulihkan_perangkat tanpa sesi (0102) sehingga kunci induk KEAMANAN §4b Tingkat 3 bisa dijalankan sampai akhir oleh owner yang kehilangan seluruh perangkat.';

revoke all on function public.selesaikan_pemulihan_darurat(text) from public;
grant execute on function public.selesaikan_pemulihan_darurat(text) to anon, authenticated, service_role;
