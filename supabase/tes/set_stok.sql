-- ============================================================================
-- UJI: SET_STOK (T4-06) — penyesuaian stok sederhana per bahan (delta), lewat
-- pintu tunggal catat_stok (0007). "Pencatatan sederhana, bukan resep otomatis."
-- ============================================================================

-- Data uji: bahan dibuat dengan saldo 0 (aturan buku besar), saldo awal lewat
-- pergerakan; satu bahan penyewa lain sebagai calon korban sentuh-silang.
insert into public.stok_bahan (id, penyewa_id, nama, satuan, jumlah, minimum, dipantau)
values ('00000000-0000-0000-0000-00000000e001','11111111-1111-1111-1111-111111111111','Beras Uji-36','kg',0,2,true),
       ('00000000-0000-0000-0000-00000000e002','22222222-2222-2222-2222-222222222222','Gula Uji-36','kg',0,0,false);
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan)
values ('00000000-0000-0000-0000-00000000e001', 'masuk', 10, 'Saldo awal');
select uji.klaim(null);

-- 1. Anonim & tanpa izin ditolak.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.set_stok('00000000-0000-0000-0000-00000000e001', 5, 'Belanja')$$,
  'permission denied|tidak diizinkan',
  'anon ditolak memanggil set_stok');
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.set_stok('00000000-0000-0000-0000-00000000e001', 5, 'Belanja')$$,
  'tidak berizin mengubah stok',
  'kasir tanpa izin ubah_stok ditolak (pesan kanonik catat_stok)');
reset role;

-- 2. Dapur mencatat penambahan (+5): saldo 10 → 15, riwayat jenis masuk.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_stok('00000000-0000-0000-0000-00000000e001', 5, 'Belanja pagi')->>'jumlah_baru')::numeric),
  15::numeric, 'set_stok +5 menghasilkan saldo baru 15');
reset role;
select uji.sama(
  (select b.jumlah from public.stok_bahan b where b.id = '00000000-0000-0000-0000-00000000e001'),
  15::numeric, 'saldo bahan ikut bertambah lewat buku besar');
select uji.sama(
  (select count(*) from public.stok_pergerakan p
    where p.stok_bahan_id = '00000000-0000-0000-0000-00000000e001'
      and p.jenis = 'masuk' and p.jumlah = 5 and p.alasan = 'Belanja pagi'
      and p.pelaku_id = '90000000-0000-0000-0000-000000000006'),
  1::bigint, 'riwayat mencatat siapa, kapan, berapa, dan alasannya');

-- 3. Pengurangan (−3): saldo 15 → 12, jenis keluar.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_stok('00000000-0000-0000-0000-00000000e001', -3, 'Pemakaian dapur')->>'jumlah_baru')::numeric),
  12::numeric, 'set_stok −3 menghasilkan saldo baru 12');
reset role;
select uji.sama(
  (select p.jenis from public.stok_pergerakan p
    where p.stok_bahan_id = '00000000-0000-0000-0000-00000000e001' and p.jumlah = -3),
  'keluar', 'delta negatif tercatat sebagai keluar');

-- 4. Penjagaan: nol ditolak, alasan wajib, bahan resto lain ditolak.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.set_stok('00000000-0000-0000-0000-00000000e001', 0, 'Sia-sia')$$,
  'tidak boleh nol',
  'perubahan nol ditolak — bukan pergerakan');
select uji.harap_gagal_sebab(
  $$select public.set_stok('00000000-0000-0000-0000-00000000e001', 1, '   ')$$,
  'Alasan wajib',
  'alasan kosong/whitespace ditolak');
select uji.harap_gagal_sebab(
  $$select public.set_stok('00000000-0000-0000-0000-00000000e002', 1, 'Usik')$$,
  'tidak ditemukan di resto ini',
  'bahan penyewa lain tidak bisa disentuh');
reset role;

-- 5. Buku besar hanya-tambah: pegawai pun tidak bisa menulis ulang riwayat.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.stok_pergerakan set jumlah = 999 where stok_bahan_id = '00000000-0000-0000-0000-00000000e001'$$,
  'permission denied|row-level security|tidak diizinkan',
  'pergerakan stok tidak bisa ditulis ulang pegawai');
reset role;
