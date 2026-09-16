-- ============================================================================
-- UJI: meja & status meja (T1-08)
-- Membuktikan: meja terpisah per cabang, nama meja boleh sama di cabang berbeda
-- tetapi tidak boleh ganda di cabang yang sama, status hanya boleh dari daftar
-- resmi, dan dua cabang tidak saling melihat meja.
-- ============================================================================

-- 1. Sebelum masuk: tidak ada meja yang terlihat.
select uji.klaim(null);
set local role anon;
select uji.sama((select count(*) from public.meja), 0::bigint, 'anon tidak melihat meja');
reset role;
select uji.klaim(null);

-- 2. Kasir Pusat hanya melihat meja cabangnya.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select count(*) from public.meja), 2::bigint, 'kasir Pusat melihat 2 meja cabangnya');
select uji.sama(
  (select count(*) from public.meja m where m.cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'),
  0::bigint,
  'meja Cabang Dua tidak terlihat oleh kasir Pusat'
);
select uji.sama(
  (select count(*) from public.meja m where m.cabang_id = 'b1b1b1b1-0000-0000-0000-000000000001'),
  0::bigint,
  'meja resto lain tidak terlihat'
);

-- 3. Status meja bisa diubah pegawai cabang (kasir/pelayan) — dan hanya nilai resmi.
update public.meja set status = 'siap' where id = 'aaa00000-0000-0000-0000-000000000001';
select uji.sama(
  (select m.status from public.meja m where m.id = 'aaa00000-0000-0000-0000-000000000001'),
  'siap',
  'kasir boleh mengubah status meja menjadi siap'
);
select uji.harap_gagal(
  $$update public.meja set status = 'entah' where id = 'aaa00000-0000-0000-0000-000000000001'$$,
  'status meja di luar daftar resmi ditolak'
);

-- 4. Tetapi kasir TIDAK boleh menambah atau menghapus meja.
select uji.harap_gagal(
  $$insert into public.meja (cabang_id, nama) values ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja Kasir')$$,
  'kasir tidak boleh menambah meja'
);
delete from public.meja where id = 'aaa00000-0000-0000-0000-000000000002';
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.meja where id = 'aaa00000-0000-0000-0000-000000000002'),
  1::bigint,
  'kasir tidak bisa menghapus meja (barisnya tetap ada)'
);

-- 5. Admin cabang boleh menambah meja di cabangnya, dan nama meja boleh sama
--    di cabang lain — tetapi TIDAK boleh ganda di cabang yang sama.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
insert into public.meja (cabang_id, nama, area) values ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 3', 'Belakang');
select uji.sama((select count(*) from public.meja), 3::bigint, 'admin Pusat berhasil menambah meja');
select uji.harap_gagal(
  $$insert into public.meja (cabang_id, nama) values ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 3')$$,
  'nama meja tidak boleh ganda di cabang yang sama'
);
select uji.harap_gagal(
  $$insert into public.meja (cabang_id, nama) values ('a1a1a1a1-0000-0000-0000-000000000002', 'Meja Admin')$$,
  'admin cabang tidak boleh menambah meja di cabang lain'
);
reset role;
select uji.klaim(null);

-- 6. Owner pusat melihat meja seluruh cabang restonya.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama((select count(*) from public.meja), 4::bigint, 'owner pusat melihat meja di semua cabang restonya (3 Pusat + 1 Cabang Dua)');
select uji.sama(
  (select count(*) from public.meja m where m.cabang_id = 'b1b1b1b1-0000-0000-0000-000000000001'),
  0::bigint,
  'meja resto lain tetap tidak terlihat owner pusat'
);

-- Nama meja yang SAMA boleh dipakai di cabang berbeda — bukti aturan "unik per cabang".
insert into public.meja (cabang_id, nama) values ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 5');
insert into public.meja (cabang_id, nama) values ('a1a1a1a1-0000-0000-0000-000000000002', 'Meja 5');
reset role;
select uji.klaim(null);
select uji.sama(
  (select count(*) from public.meja where nama = 'Meja 5'),
  2::bigint,
  'nama meja yang sama boleh ada di dua cabang berbeda'
);
select uji.klaim(null);

-- 7. Resto lain (cabang tunggal) hanya melihat mejanya sendiri.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.meja), 1::bigint, 'kasir resto B melihat 1 meja miliknya');
-- RLS menyaring (bukan error): buktinya = status meja itu TIDAK berubah.
update public.meja set status = 'terisi' where id = 'aaa00000-0000-0000-0000-000000000001';
reset role;
select uji.klaim(null);
select uji.sama(
  (select m.status from public.meja m where m.id = 'aaa00000-0000-0000-0000-000000000001'),
  'siap',
  'status meja resto lain tidak berubah (tetap siap)'
);
