-- PR-08 (review putaran16): saldo awal stok wajib punya asal-usul di buku besar.
-- Cacat lama: `insert into stok_bahan (..., jumlah 500)` menciptakan saldo dari
-- ketiadaan — nol baris di stok_pergerakan, padahal buku besar itu satu-satunya
-- sumber asal-usul angka stok (penjaga lama hanya menolak UPDATE di luar buku
-- besar). Sejak 0016: INSERT dengan jumlah bukan-nol DITOLAK; saldo awal dicatat
-- sebagai baris buku besar yang otomatis menjumlah ke saldo (0007 pemicu 2).
-- Probe lama: docs/uji/audit/probe-2026-09-19/pr08-saldo-tanpa-buku.sql (kini GAGAL).

select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin cabang (boleh tambah bahan)
set local role authenticated;

-- 1) Saldo langsung dari ketiadaan DITOLAK.
select uji.harap_gagal_sebab(
  $$insert into public.stok_bahan (id, penyewa_id, nama, satuan, jumlah)
      values ('00000000-0000-0000-0000-00000000f001','11111111-1111-1111-1111-111111111111',
              'Bahan Siluman','kg', 500)$$,
  'Saldo awal tidak boleh ditulis langsung',
  'PR-08: saldo tidak bisa lagi muncul dari ketiadaan');

-- 2) Jalur sah: bahan lahir dengan saldo 0, saldo awal lewat buku besar.
insert into public.stok_bahan (id, penyewa_id, nama, satuan)
values ('00000000-0000-0000-0000-00000000f001','11111111-1111-1111-1111-111111111111',
        'Bahan Terpantau','kg');
insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah, alasan)
values ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-00000000f001',
        'opname', 500, 'saldo awal pembukaan');
select uji.sama(
  (select jumlah from public.stok_bahan where id='00000000-0000-0000-0000-00000000f001'),
  500::numeric, 'PR-08: saldo 500 kg TERBENTUK dari baris buku besar');
select uji.sama(
  (select coalesce(sum(jumlah),0) from public.stok_pergerakan
    where stok_bahan_id='00000000-0000-0000-0000-00000000f001'),
  500::numeric, 'PR-08: asal-usulnya ada di buku besar (bukan dari ketiadaan)');

-- 3) Penjaga lama tetap hidup: UPDATE jumlah langsung tetap ditolak.
select uji.harap_gagal_sebab(
  $$update public.stok_bahan set jumlah = 999
      where id='00000000-0000-0000-0000-00000000f001'$$,
  'hanya boleh berubah lewat catatan pergerakan',
  'PR-08: tulis langsung ke saldo tetap ditolak (penjaga 0007 tidak regress)');
reset role;
select uji.klaim(null);
