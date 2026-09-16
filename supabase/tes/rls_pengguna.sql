-- ============================================================================
-- UJI: pengguna, pengguna_cabang, izin, pengaturan (T1-02, ART-2)
-- Membuktikan: pegawai cabang 1 tidak bisa melihat data cabang 2, izin hanya
-- terlihat oleh yang berhak, dan pengaturan hanya bisa diubah owner pusat
-- di restonya sendiri.
-- ============================================================================

-- 1. Setiap orang melihat barisnya sendiri, dan hanya itu (kasir biasa).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select count(*) from public.pengguna), 1::bigint, 'kasir hanya melihat dirinya sendiri');
select uji.sama((select p.nama from public.pengguna p), 'Rina', 'baris yang terlihat = dirinya sendiri');
reset role;
select uji.klaim(null);

-- 2. Owner pusat melihat seluruh pegawai restonya (5 orang), tidak melihat resto lain.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama((select count(*) from public.pengguna), 5::bigint, 'owner pusat melihat 5 pegawai restonya');
select uji.harap(
  (select count(*) from public.pengguna where penyewa_id = '22222222-2222-2222-2222-222222222222') = 0,
  'pegawai resto lain tidak terlihat owner pusat'
);
reset role;
select uji.klaim(null);

-- 3. Admin cabang: hanya pegawai yang bertugas di cabangnya (Pusat), bukan cabang lain.
--    Saat masuk, klaim token memuat cabang aktif — itu yang dipakai policy.
select uji.klaim('90000000-0000-0000-0000-000000000003', '{"cabang_id":"a1a1a1a1-0000-0000-0000-000000000001"}'::jsonb);
set local role authenticated;
select uji.sama((select count(*) from public.pengguna), 3::bigint, 'admin cabang melihat dirinya + 2 pegawai cabang Pusat');
select uji.harap(
  not exists (select 1 from public.pengguna where id = '90000000-0000-0000-0000-000000000006'),
  'pegawai yang HANYA bertugas di Cabang Dua tidak terlihat admin Pusat'
);
select uji.harap(
  exists (select 1 from public.pengguna where id = '90000000-0000-0000-0000-000000000005'),
  'pegawai merangkap yang juga bertugas di Pusat tetap terlihat'
);

-- 4. Baris cabang pegawai: admin Pusat hanya melihat baris cabang Pusat.
select uji.sama(
  (select count(*) from public.pengguna_cabang where cabang_id = 'a1a1a1a1-0000-0000-0000-000000000002'),
  0::bigint,
  'admin Pusat TIDAK melihat satu baris pun pegawai Cabang Dua'
);
select uji.sama(
  (select count(*) from public.pengguna_cabang),
  3::bigint,
  'admin Pusat melihat 3 baris cabang Pusat (dirinya + kasir + pelayan)'
);

-- 5. Izin: kasir hanya melihat izinnya sendiri; admin melihat izin pegawai lingkupnya.
select uji.sama((select count(*) from public.izin), 8::bigint, 'admin cabang melihat seluruh izin pegawai restonya');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama((select count(*) from public.izin), 2::bigint, 'kasir hanya melihat izinnya sendiri');
select uji.harap(
  not exists (select 1 from public.izin where kode_izin = 'lihat_laporan'),
  'kasir tidak melihat izin owner pusat'
);
select uji.harap_gagal(
  $$update public.izin set boleh = true where kode_izin = 'lihat_laporan'$$,
  'kasir tidak boleh mengubah izin lewat tabel langsung (harus lewat RPC berizin)'
);
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.izin), 0::bigint, 'kasir resto lain tidak melihat izin Kedai Oasis');
reset role;
select uji.klaim(null);

-- 6. Pengaturan: hanya owner pusat restonya yang boleh mengubah; yang lain tidak.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama((select count(*) from public.pengaturan), 1::bigint, 'owner pusat hanya melihat pengaturan restonya');
update public.pengaturan set service_persen = 7 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.sama(
  (select service_persen::text from public.pengaturan where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '7.00',
  'owner pusat berhasil mengubah pengaturan restonya'
);
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.pengaturan), 1::bigint, 'kasir resto lain hanya melihat pengaturannya sendiri');
update public.pengaturan set pajak_pb1_persen = 99 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select pajak_pb1_persen::text from public.pengaturan where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '10.00',
  'pajak Kedai Oasis TIDAK berubah walau ada perintah ubah dari resto lain'
);
reset role;
select uji.klaim(null);
