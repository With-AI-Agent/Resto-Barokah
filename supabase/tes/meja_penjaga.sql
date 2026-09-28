-- ============================================================================
-- UJI: DATA INDUK MEJA TIDAK BISA DIUBAH/DIPERLAKUKAN SEMBARANGAN
-- Menutup temuan audit AUD-3 2026-09-18 F-08 (K-3: policy `meja_ubah_status`
-- memberi UPDATE seluruh baris → kasir bisa mengganti nama & menonaktifkan meja)
-- dan F-09 (K-3: meja yang sedang dipakai bisa DIHAPUS → pesanan.meja_id = NULL).
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

-- 1. Kasir hanya boleh mengubah STATUS.
select uji.harap_gagal_sebab($$update public.meja set nama = 'MEJA DIRETUR' where id = 'aaa00000-0000-0000-0000-000000000001'$$, 'Peran kasir hanya boleh mengubah STATUS meja — nama/area/aktif adalah data induk cabang', 'kasir tidak boleh mengganti NAMA meja (data induk cabang)');
select uji.harap_gagal_sebab($$update public.meja set aktif = false where id = 'aaa00000-0000-0000-0000-000000000001'$$, 'Peran kasir hanya boleh mengubah STATUS meja — nama/area/aktif adalah data induk cabang', 'kasir tidak boleh menonaktifkan meja');
update public.meja set status = 'terisi' where id = 'aaa00000-0000-0000-0000-000000000001';
reset role;
select uji.sama(
  (select m.status from public.meja m where m.id = 'aaa00000-0000-0000-0000-000000000001'),
  'terisi', 'kasir TETAP boleh mengubah status meja (pekerjaannya)'
);
select uji.klaim(null);

-- 2. Admin cabang boleh mengubah nama (data induk) — jalur sah tidak ditutup.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
update public.meja set nama = 'Meja Utama' where id = 'aaa00000-0000-0000-0000-000000000001';
reset role;
select uji.sama(
  (select m.nama from public.meja m where m.id = 'aaa00000-0000-0000-0000-000000000001'),
  'Meja Utama', 'admin cabang boleh mengganti nama meja'
);
select uji.klaim(null);

-- 3. Meja yang dipakai pesanan aktif tidak boleh dihapus.
select uji.sama(
  (select count(*) from public.pesanan p
    where p.meja_id = 'aaa00000-0000-0000-0000-000000000001' and p.status not in ('lunas','batal')),
  1::bigint, 'kontrol: ada 1 pesanan aktif di meja itu'
);
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab($$delete from public.meja where id = 'aaa00000-0000-0000-0000-000000000001'$$, 'Meja ini punya 1 pesanan dalam riwayat \(termasuk yang sudah lunas/batal\) — tidak boleh dih', 'meja yang sedang dipakai pesanan aktif TIDAK boleh dihapus (dulu meja_id jadi NULL)');
reset role;
select uji.sama(
  (select count(*) from public.pesanan p where p.meja_id is null),
  0::bigint, 'tidak ada pesanan yang kehilangan acuan mejanya'
);
select uji.klaim(null);
