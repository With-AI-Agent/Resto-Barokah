-- ============================================================================
-- UJI: isolasi penyewa & cabang pada tabel penyewa/cabang (T1-01, ART-1)
-- Membuktikan: pengunjung belum masuk tidak melihat apa pun, dan akun penyewa A
-- tidak bisa melihat — apalagi mengubah — data penyewa B.
-- ============================================================================

-- 1. Sebelum masuk (anon): NOL baris, bukan error dan bukan bocor.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.penyewa), 0::bigint, 'anon tidak melihat satu baris penyewa pun');
select uji.sama((select count(*) from public.cabang), 0::bigint, 'anon tidak melihat satu baris cabang pun');
reset role;
select uji.klaim(null);

-- 2. Tanpa token (belum masuk) tetapi memakai peran authenticated.
select uji.klaim(null);
set local role authenticated;
select uji.sama((select count(*) from public.penyewa), 0::bigint, 'tanpa identitas: penyewa tidak terlihat');
select uji.sama((select count(*) from public.cabang), 0::bigint, 'tanpa identitas: cabang tidak terlihat');
reset role;
select uji.klaim(null);

-- 3. Kasir Kedai Oasis hanya melihat Kedai Oasis.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select count(*) from public.penyewa), 1::bigint, 'kasir A melihat tepat satu penyewa');
select uji.sama((select p.nama from public.penyewa p), 'Kedai Oasis', 'penyewa yang terlihat = Kedai Oasis');
select uji.sama((select count(*) from public.cabang), 2::bigint, 'kasir A melihat dua cabang (Pusat & Cabang Dua)');
select uji.harap(
  (select count(*) from public.cabang where penyewa_id = '22222222-2222-2222-2222-222222222222') = 0,
  'cabang Warung Bandung TIDAK terlihat oleh kasir Kedai Oasis'
);
reset role;
select uji.klaim(null);

-- 4. Kasir Warung Bandung hanya melihat Warung Bandung.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select p.nama from public.penyewa p), 'Warung Bandung', 'penyewa yang terlihat = Warung Bandung');
select uji.sama((select count(*) from public.cabang), 1::bigint, 'kasir B melihat satu cabang');
select uji.harap(
  (select count(*) from public.cabang where penyewa_id = '11111111-1111-1111-1111-111111111111') = 0,
  'cabang Kedai Oasis TIDAK terlihat oleh kasir Warung Bandung'
);
reset role;
select uji.klaim(null);

-- 5. Menulis cabang: hanya owner pusat, dan hanya di restonya sendiri.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.cabang (penyewa_id, nama) values ('11111111-1111-1111-1111-111111111111', 'Cabang Kasir')$$, 'row-level security policy for table "cabang"', 'kasir tidak boleh menambah cabang');
select uji.harap_gagal_sebab($$update public.penyewa set nama = 'Diubah Kasir' where id = '11111111-1111-1111-1111-111111111111'$$, 'permission denied for table penyewa', 'kasir tidak boleh mengubah penyewa');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.cabang (penyewa_id, nama) values ('22222222-2222-2222-2222-222222222222', 'Cabang Sisipan')$$, 'row-level security policy for table "cabang"', 'owner pusat tidak boleh menambah cabang ke resto lain');
reset role;
select uji.klaim(null);

-- 6. Owner pusat boleh menambah cabang di restonya (dan hasilnya tidak terlihat resto lain).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
insert into public.cabang (penyewa_id, nama) values ('11111111-1111-1111-1111-111111111111', 'Cabang Tiga');
select uji.sama((select count(*) from public.cabang), 3::bigint, 'owner pusat melihat cabang barunya');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.cabang), 1::bigint, 'resto lain tetap tidak melihat cabang baru itu');

-- Penting: RLS MENYARING, bukan melempar error. Jadi buktinya bukan "gagal",
-- melainkan "tidak ada satu baris pun yang berubah".
update public.cabang set nama = 'Dibajak' where id = 'a1a1a1a1-0000-0000-0000-000000000001';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select c.nama from public.cabang c where c.id = 'a1a1a1a1-0000-0000-0000-000000000001'),
  'Pusat',
  'nama cabang tetap Pusat walau ada perintah ubah dari resto lain'
);
reset role;
select uji.klaim(null);
