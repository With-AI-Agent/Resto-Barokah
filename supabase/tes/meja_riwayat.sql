-- PR-15 (review putaran16): hapus meja tidak boleh memutus riwayat pesanan.
-- Cacat lama: penjaga 0014 hanya menolak hapus bila masih ada pesanan AKTIF;
-- meja dengan riwayat pesanan LUNAS/BATAL bisa dihapus dan `on delete set null`
-- mencabut tautannya — laporan kehilangan "meja mana". Sejak 0016 (bagian 7):
-- meja yang punya riwayat pesanan tidak bisa dihapus; jalurnya nonaktifkan.
-- Probe lama: docs/uji/audit/probe-2026-09-19/pr15-meja-terputus.sql (kini GAGAL).

-- Jadikan pesanan fixture lunas (riwayat yang harus dilindungi).
reset role;
update public.pesanan set status = 'lunas' where id = 'eeee0000-0000-0000-0000-000000000010';

-- 1) Admin cabang mencoba menghapus meja ber-riwayat → DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$delete from public.meja where id = 'aaa00000-0000-0000-0000-000000000001'$$,
  'riwayat',
  'PR-15: meja ber-riwayat pesanan lunas tidak bisa dihapus');

-- 2) Tautan riwayat tetap utuh.
reset role;
select uji.sama(
  (select meja_id from public.pesanan where id = 'eeee0000-0000-0000-0000-000000000010'),
  'aaa00000-0000-0000-0000-000000000001'::uuid,
  'PR-15: pesanan lunas tetap tahu "meja mana"');

-- 3) Jalur yang benar tetap terbuka: nonaktifkan meja.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
update public.meja set aktif = false where id = 'aaa00000-0000-0000-0000-000000000001';
select uji.sama(
  (select aktif from public.meja where id = 'aaa00000-0000-0000-0000-000000000001'),
  false, 'PR-15: menonaktifkan meja tetap boleh (data induk tidak dihapus)');

-- 4) Meja TANPA riwayat tetap boleh dihapus (penjaga tidak menutup jalur sah).
insert into public.meja (id, cabang_id, nama, area)
values ('aaa00000-0000-0000-0000-000000000009', 'a1a1a1a1-0000-0000-0000-000000000001',
        'Meja Cadangan', 'Teras');
delete from public.meja where id = 'aaa00000-0000-0000-0000-000000000009';
select uji.sama(
  (select count(*)::int from public.meja where id = 'aaa00000-0000-0000-0000-000000000009'),
  0, 'kontrol: meja tanpa riwayat tetap bisa dihapus');
reset role;
select uji.klaim(null);
