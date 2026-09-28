-- ============================================================================
-- UJI: OPNAME_STOK (T4-07) — mengisi jumlah NYATA, sistem menampilkan selisih,
-- tercatat siapa & kapan, koreksi tidak menghapus riwayat.
-- ============================================================================

insert into public.stok_bahan (id, penyewa_id, nama, satuan, jumlah, minimum, dipantau)
values ('00000000-0000-0000-0000-00000000e011','11111111-1111-1111-1111-111111111111','Minyak Uji-37','liter',0,1,true);
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan)
values ('00000000-0000-0000-0000-00000000e011', 'masuk', 10, 'Saldo awal');
select uji.klaim(null);

-- 1. Anonim & kasir ditolak.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e011', 7, 'Hitung')$$,
  'permission denied|tidak diizinkan',
  'anon ditolak memanggil opname_stok');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e011', 7, 'Hitung')$$,
  'tidak berizin mengubah stok',
  'kasir tanpa izin ubah_stok ditolak');
reset role;

-- 2. Opname: jumlah fisik 7 dari saldo 10 → selisih −3, saldo jadi 7.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.opname_stok('00000000-0000-0000-0000-00000000e011', 7, 'Hitung fisik gudang')->>'selisih')::numeric),
  (-3)::numeric, 'selisih opname terlihat: fisik 7 vs sistem 10 = −3');
reset role;
select uji.sama(
  (select b.jumlah from public.stok_bahan b where b.id = '00000000-0000-0000-0000-00000000e011'),
  7::numeric, 'saldo bahan = jumlah hasil hitung fisik');

-- 3. Opname dengan selisih nol TIDAK dicatat — penjaga buku besar lama yang MENANG
--    ('Opname/koreksi dengan perubahan nol tidak perlu dicatat.').
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e011', 7, 'Hitung ulang')$$,
  'tidak perlu dicatat',
  'opname tanpa selisih ditolak penjaga buku besar (kontrak lama menang)');
reset role;
select uji.sama(
  (select count(*) from public.stok_pergerakan p
    where p.stok_bahan_id = '00000000-0000-0000-0000-00000000e011'
      and p.jenis = 'opname'
      and p.pelaku_id = '90000000-0000-0000-0000-000000000006'),
  1::bigint, 'perubahan nyata tercatat lengkap: siapa (dapur), kapan, selisihnya');
select uji.sama(
  (select p.alasan from public.stok_pergerakan p
    where p.stok_bahan_id = '00000000-0000-0000-0000-00000000e011'
    order by p.id desc limit 1),
  'Hitung fisik gudang', 'alasan opname ikut tercatat');

-- 4. Penjagaan: fisik negatif ditolak, alasan wajib, bahan resto lain ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e011', -1, 'Aneh')$$,
  'tidak boleh negatif',
  'jumlah fisik negatif tidak masuk akal');
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e011', 7, null)$$,
  'Alasan wajib',
  'opname tanpa alasan ditolak');
select uji.harap_gagal_sebab(
  $$select public.opname_stok('00000000-0000-0000-0000-00000000e002', 1, 'Usik')$$,
  'tidak ditemukan di resto ini',
  'bahan penyewa lain tidak bisa diopname');
reset role;

-- 5. Koreksi tidak menghapus riwayat: pegawai pun tidak bisa menghapus buku besar.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$delete from public.stok_pergerakan where stok_bahan_id = '00000000-0000-0000-0000-00000000e011'$$,
  'permission denied|row-level security|tidak diizinkan',
  'riwayat opname tidak bisa dihapus pegawai');
reset role;
