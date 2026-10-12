-- ============================================================================
-- PROBE HAKIM H-F-08 — reproduksi independen PMB1-F-109 (K-2, potongan F-08)
-- Pertanyaan: apakah pemilik_platform yang sedang menjalankan mode dukungan
-- benar-benar HANYA-BACA seperti janji DoD T1-28 (docs/ROADMAP.md:454), atau
-- ia bisa MENGUBAH data resto sasaran lewat RPC SECURITY DEFINER?
--
-- Kenapa probe ini kuat (pelajaran PMB1-F-092):
--   * ia MEMANGGIL RPC yang diuji (public.simpan_urutan_metode_bayar) dari
--     kursi pemilik_platform yang sebenarnya (uji.klaim + set local role);
--   * ia punya DUA kontrol negatif: sebelum masuk mode dan sesudah keluar mode
--     tulis itu TIDAK boleh mengena;
--   * ia membaca nilai kolom sesudahnya untuk membuktikan perubahan nyata.
--
-- Jalankan:
--   node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-mode-dukungan-tulis.sql
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 0. Kursi pemilik_platform (90000000-…-0001; penyewa_id = null di data uji,
--    jadi TANPA mode dukungan ia tidak punya penyewa sama sekali).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000001'); -- Pemilik Platform
set local role authenticated;

-- KONTROL NEGATIF 1 — sebelum mode: RPC harus MENOLAK karena penyewa_saya() null.
select uji.harap_gagal_sebab(
  $perintah$
  select public.simpan_urutan_metode_bayar(
    jsonb_build_array(jsonb_build_object(
      'id', (select id from public.metode_bayar
              where penyewa_id = '11111111-1111-1111-1111-111111111111'
              order by nama limit 1),
      'urutan', 98)))
  $perintah$,
  'Penyewa tidak ditemukan',
  'kontrol negatif: tanpa mode dukungan pemilik_platform tidak bisa menulis apa pun (Penyewa tidak ditemukan)'
);

-- ---------------------------------------------------------------------------
-- 1. Masuk mode dukungan untuk Kedai Oasis (11111111-…-0001), 30 menit.
-- ---------------------------------------------------------------------------
select uji.sama(
  (public.masuk_mode_dukungan(
     '11111111-1111-1111-1111-111111111111',
     'Reproduksi hakim F-08: uji hanya-baca mode dukungan', 30
   ) ->> 'berhasil')::boolean,
  true,
  'pemilik_platform berhasil masuk mode dukungan untuk Kedai Oasis'
);

-- ---------------------------------------------------------------------------
-- 2. INTI TEMUAN: tulis ke data resto sasaran saat mode dukungan aktif.
--    Janji DoD T1-28 = "hanya-baca; dengan mode → tulis ditolak".
--    Kenyataan yang diuji: RPC mengubah baris milik Kedai Oasis → jumlah = 1.
-- ---------------------------------------------------------------------------
select uji.sama(
  (public.simpan_urutan_metode_bayar(
     jsonb_build_array(jsonb_build_object(
       'id', (select id from public.metode_bayar
               where penyewa_id = '11111111-1111-1111-1111-111111111111'
               order by nama limit 1),
       'urutan', 99)))
   ->> 'jumlah')::int,
  1,
  'MODE DUKUNGAN AKTIF: pemilik_platform BERHASIL mengubah urutan metode bayar resto sasaran (janji hanya-baca T1-28 dilanggar)'
);

-- bukti perubahan benar-benar tersimpan di kolom (bukan hanya klaim RPC)
select uji.sama(
  (select urutan from public.metode_bayar
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
    order by nama limit 1),
  99,
  'nilai urutan metode bayar Kedai Oasis benar-benar tersimpan menjadi 99'
);

-- ---------------------------------------------------------------------------
-- 3. KONTROL NEGATIF 2 — keluar mode, ulangi aksi yang sama: harus ditolak lagi.
-- ---------------------------------------------------------------------------
select uji.sama(
  (public.keluar_mode_dukungan('11111111-1111-1111-1111-111111111111') ->> 'berhasil')::boolean,
  true,
  'pemilik_platform keluar dari mode dukungan'
);

select uji.harap_gagal_sebab(
  $perintah$
  select public.simpan_urutan_metode_bayar(
    jsonb_build_array(jsonb_build_object(
      'id', (select id from public.metode_bayar
              where penyewa_id = '11111111-1111-1111-1111-111111111111'
              order by nama limit 1),
      'urutan', 97)))
  $perintah$,
  'Penyewa tidak ditemukan',
  'kontrol negatif: sesudah keluar mode dukungan tulis kembali ditolak (Penyewa tidak ditemukan)'
);

-- ---------------------------------------------------------------------------
-- 4. Bereskan bekas uji supaya data uji lain tidak terpengaruh.
-- ---------------------------------------------------------------------------
reset role;

update public.metode_bayar
   set urutan = 1
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and nama = (select nama from public.metode_bayar
                where penyewa_id = '11111111-1111-1111-1111-111111111111'
                order by nama limit 1);

update public.metode_bayar
   set urutan = 2
 where penyewa_id = '11111111-1111-1111-1111-111111111111'
   and urutan = 99;

select uji.sama(
  (select count(*)::int from public.metode_bayar
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
      and urutan = 99),
  0,
  'pembersihan: tidak ada lagi baris uji ber-urutan 99'
);

select uji.klaim(null);

rollback;
