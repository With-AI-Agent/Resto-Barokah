-- ============================================================================
-- UJI HAKIM H-F-06 — reproduksi independen PMB1-F-085
-- Pertanyaan: apakah RPC public.buat_kode_perangkat() benar-benar mengizinkan
-- admin cabang membuat kode pendaftaran perangkat untuk CABANG LAIN?
--
-- Catatan hakim: probe asli milik pemeriksa (bukti/F-06-admin-lintas-cabang.sql)
-- TIDAK membuktikan apa pun — isinya fungsi pg_temp yang selalu mengembalikan
-- `true` dengan teks hardcoded, tanpa pernah memanggil buat_kode_perangkat.
-- Berkas ini memanggil RPC-nya sungguhan dari kursi admin cabang.
--
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06-admin-lintas-cabang.sql
-- ============================================================================

-- Admin Cabang A1 (Pak Andi) hanya terdaftar di cabang A1 (lihat data-uji.sql:
-- pengguna_cabang → 90000000-…-0003 hanya di a1a1a1a1-…-0001).
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

-- Benar-benar meminta kode untuk Cabang A2 (a1a1a1a1-…-0002), BUKAN cabangnya.
select uji.sama(
  (public.buat_kode_perangkat(
     'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
     'Tablet Cabang Dua (dicoba admin A1)'
   ) ->> 'berhasil')::boolean,
  true,
  'Admin Cabang A1 BERHASIL membuat kode pendaftaran untuk Cabang A2 (bypass batas cabang)'
);

reset role;
select uji.klaim(null);

-- Bersihkan kode yang terbit dari percobaan ini supaya tidak mengotori data uji lain.
delete from public.kode_pendaftaran_perangkat
 where dibuat_oleh = '90000000-0000-0000-0000-000000000003'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002';

-- Kontrak tegak: pemilik pusat (semua cabang restonya) memang BOLEH.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (public.buat_kode_perangkat(
     'a1a1a1a1-0000-0000-0000-000000000002'::uuid,
     'Tablet Cabang Dua (oleh owner)'
   ) ->> 'berhasil')::boolean,
  true,
  'Owner pusat BOLEH membuat kode untuk Cabang A2 (wewenang sah, kontrol)'
);

reset role;
select uji.klaim(null);

delete from public.kode_pendaftaran_perangkat
 where dibuat_oleh = '90000000-0000-0000-0000-000000000002'
   and cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002';

-- Kontrol negatif: kasir penyewa lain tidak punya izin kelola_pegawai maka DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;

select uji.sama(
  (public.buat_kode_perangkat(
     'b1b1b1b1-0000-0000-0000-000000000001'::uuid,
     'Tablet B1'
   ) ->> 'berhasil')::boolean,
  false,
  'Kasir B1 TIDAK punya izin kelola_pegawai → ditolak (kontrol, isolasi penyewa)'
);

reset role;
select uji.klaim(null);
