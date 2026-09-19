-- ============================================================================
-- UJI: fungsi bantu identitas (T1-03)
-- Memeriksa penyewa_saya(), peran_saya(), cabang_saya(), cabang_ids_saya(),
-- sepenyewa() untuk SEMUA peran — termasuk akun tanpa cabang dan pemilik
-- platform yang berdiri di luar penyewa.
-- ============================================================================

-- 1. Sebelum masuk (anon): identitas kosong dan fungsi tidak boleh dijalankan.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal('select public.penyewa_saya()', 'anon tidak boleh memanggil fungsi identitas');
select uji.harap_gagal('select public.cabang_ids_saya()', 'anon tidak boleh memanggil daftar cabang');
reset role;
select uji.klaim(null);

-- 2. Pemilik platform: berdiri di atas semua penyewa → tidak punya penyewa/cabang.
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;
select uji.sama(public.penyewa_saya(), null::uuid, 'pemilik platform tidak punya penyewa');
select uji.sama(public.peran_saya(), 'pemilik_platform', 'peran pemilik platform');
select uji.sama((select count(*) from public.cabang_ids_saya()), 0::bigint, 'pemilik platform tidak punya cabang');
reset role;
select uji.klaim(null);

-- 3. Owner pusat: punya penyewa, TIDAK punya cabang (memang tidak bertugas di kasir).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.penyewa_saya(), '11111111-1111-1111-1111-111111111111'::uuid, 'penyewa owner pusat');
select uji.sama(public.peran_saya(), 'owner_pusat', 'peran owner pusat');
select uji.sama((select count(*) from public.cabang_ids_saya()), 0::bigint, 'owner pusat tanpa cabang');
select uji.sama(public.cabang_saya(), null::uuid, 'cabang aktif owner pusat kosong');
select uji.harap(public.sepenyewa('90000000-0000-0000-0000-000000000004'), 'sepenyewa() benar untuk pegawai satu resto');
select uji.harap(not public.sepenyewa('90000000-0000-0000-0000-000000000007'), 'sepenyewa() salah untuk pegawai resto lain');
select uji.harap(not public.sepenyewa('90000000-0000-0000-0000-000000000001'), 'sepenyewa() salah untuk pemilik platform');
reset role;
select uji.klaim(null);

-- 4. Admin cabang: satu cabang.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(public.penyewa_saya(), '11111111-1111-1111-1111-111111111111'::uuid, 'penyewa admin cabang');
select uji.sama(public.peran_saya(), 'admin_cabang', 'peran admin cabang');
select uji.sama((select count(*) from public.cabang_ids_saya()), 1::bigint, 'admin cabang punya satu cabang');
select uji.sama(
  (select v from public.cabang_ids_saya() as v),
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  'cabang admin adalah Pusat'
);
reset role;
select uji.klaim(null);

-- 5. Kasir cabang 1 & dapur cabang 2 (satu cabang, berbeda cabang).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.peran_saya(), 'kasir', 'peran kasir');
select uji.sama((select v from public.cabang_ids_saya() as v), 'a1a1a1a1-0000-0000-0000-000000000001'::uuid, 'cabang kasir');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(public.peran_saya(), 'dapur', 'peran dapur');
select uji.sama((select v from public.cabang_ids_saya() as v), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 'cabang dapur');
reset role;
select uji.klaim(null);

-- 6. Pegawai merangkap dua cabang (pelayan).
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama((select count(*) from public.cabang_ids_saya()), 2::bigint, 'pelayan bertugas di dua cabang');
select uji.sama(
  (select min(v::text) from public.cabang_ids_saya() as v),
  'a1a1a1a1-0000-0000-0000-000000000001',
  'cabang pertama pelayan'
);

-- 7. Cabang aktif: SATU SUMBER = tabel `sesi_cabang` (bukan klaim token, lihat 0012).
--    Pelayan memilih cabang lewat RPC; database memverifikasi keanggotaannya.
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.cabang_saya(), null::uuid, 'sebelum memilih, belum ada cabang aktif');

-- Klaim token palsu TIDAK lagi berpengaruh sama sekali (ART-1: jangan percaya klien).
select uji.klaim('90000000-0000-0000-0000-000000000005', '{"cabang_id":"a1a1a1a1-0000-0000-0000-000000000002"}'::jsonb);
select uji.sama(public.cabang_saya(), null::uuid, 'klaim token palsu tidak memberi cabang aktif');

-- Jalur sah: pilih cabang yang benar-benar ia tempati.
select uji.sama(public.pilih_cabang('a1a1a1a1-0000-0000-0000-000000000002'), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 'pilih_cabang mengembalikan cabang yang dipilih');
select uji.sama(public.cabang_saya(), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 'cabang aktif = cabang yang dipilih');

-- Cabang milik resto lain: pemanggil TIDAK bertugas di sana → DITOLAK.
select uji.harap_gagal(
  $$select public.pilih_cabang('b1b1b1b1-0000-0000-0000-000000000001')$$,
  'memilih cabang milik resto lain ditolak (diverifikasi ke keanggotaan)'
);
select uji.sama(public.cabang_saya(), 'a1a1a1a1-0000-0000-0000-000000000002'::uuid, 'cabang aktif tidak berubah setelah percobaan curang');

-- 8. Pegawai tidak aktif tidak mendapat identitas apa pun.
reset role;
select uji.klaim(null);
update public.pengguna set aktif = false where id = '90000000-0000-0000-0000-000000000005';
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.penyewa_saya(), null::uuid, 'pegawai nonaktif tidak punya penyewa');
select uji.sama(public.peran_saya(), null::text, 'pegawai nonaktif tidak punya peran');
select uji.sama((select count(*) from public.cabang_ids_saya()), 0::bigint, 'pegawai nonaktif tidak punya cabang');
reset role;
select uji.klaim(null);
