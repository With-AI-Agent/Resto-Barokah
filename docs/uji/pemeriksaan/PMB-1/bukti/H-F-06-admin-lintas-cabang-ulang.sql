-- ============================================================================
-- PROBE HAKIM F-06 (2026-09-29) — reproduksi independen PMB1-F-085
--
-- ATURAN BACA HASIL: berkas ini LULUS = CACATNYA NYATA (konvensi probe PMB).
-- Kalau RPC-nya sudah membatasi admin cabang ke cabangnya sendiri, berkas ini
-- WAJIB menjadi MERAH (uji.sama menuntut berhasil = true; kalau RPC menolak,
-- nilai yang diterima false tidak sama dengan harapan true -> MERAH).
--
-- Kenapa probe ini menggantikan bukti/F-06-admin-lintas-cabang.sql milik
-- pemeriksa: berkas pemeriksa TIDAK menjalankan RPC apa pun — isinya sebuah
-- fungsi pg_temp yang langsung `return ... true` dengan kalimat yang sudah
-- ditulis di dalamnya. Artinya berkas itu LULUS apa pun isi kodenya (bahkan
-- kalau buat_kode_perangkat sudah benar), jadi ia bukan bukti. Probe ini
-- benar-benar memanggil RPC-nya.
--
-- Yang diuji: public.buat_kode_perangkat (definisi berlaku di 0030) hanya
-- memeriksa `penyewa_id = v_penyewa`, tidak pernah memanggil
-- public.cabang_pantau_saya(p_cabang_id), padahal docs/KEAMANAN.md §4/§5
-- membatasi admin cabang ke cabangnya sendiri.
--
-- Data uji: Pak Andi (90000000-...-003, admin_cabang) hanya terdaftar di
-- cabang A1 (a1a1a1a1-...-0001). Ia meminta kode untuk cabang A2
-- (a1a1a1a1-...-0002) — cabang SEBANGSA, bukan cabangnya.
-- ============================================================================

select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

-- 1. Admin cabang A1 meminta kode pendaftaran untuk cabang A2
select uji.sama(
  (public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
    'Tablet Cabang Dua (probe hakim)'
  ) ->> 'berhasil')::boolean,
  true,
  'CACAT NYATA: admin cabang A1 berhasil membuat kode pendaftaran untuk cabang A2'
);

-- 2. Bukti barisnya benar-benar ada di tabel kode_pendaftaran_perangkat
select uji.sama(
  (select count(*)::text
     from public.kode_pendaftaran_perangkat
    where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'
      and nama_perangkat = 'Tablet Cabang Dua (probe hakim)'),
  '1',
  'CACAT NYATA: baris kode pendaftaran untuk cabang A2 benar-benar terbit'
);

-- 3. Pembanding kendali: permintaan ke cabang miliknya sendiri (A1) juga berhasil
--    (membuktikan probe di atas bukan gagal karena RPC-nya rusak total)
select uji.sama(
  (public.buat_kode_perangkat(
    'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
    'Tablet Cabang Pusat (probe hakim)'
  ) ->> 'berhasil')::boolean,
  true,
  'KENDALI: admin cabang A1 memang boleh membuat kode untuk cabangnya sendiri'
);

reset role;
select uji.klaim(null);
