-- T-025(a): pembayaran pertama (termasuk sebagian) membekukan isi/nominal.
-- Sebab penolakan wajib BY-201, bukan RLS/status/izin yang kebetulan menolak.
-- Setup dua pesanan belum lunas, sehingga uji tidak ditopang penjaga status lama.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, kunci_idempoten)
values ('b5220000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 2201, 'beku-bayar-1'),
       ('b5220000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 2202, 'beku-bayar-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty)
values ('b5220000-0000-0000-0000-000000000101', 'b5220000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2),
       ('b5220000-0000-0000-0000-000000000102', 'b5220000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2);
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
-- Diskon sebelum bayar tetap diterima; uji juga menyediakan baris untuk UPDATE/DELETE.
insert into public.diskon_transaksi(id, pesanan_id, jenis, nominal, nilai, alasan)
values ('b5220000-0000-0000-0000-000000000201', 'b5220000-0000-0000-0000-000000000001',
        'manual', 1000, 1000, 'sebelum bayar');
insert into public.pembayaran(pesanan_id, metode_id, jumlah, diterima, kunci_idempoten)
select 'b5220000-0000-0000-0000-000000000001', id, 1, 1, 'beku-bayar-pertama'
from public.metode_bayar where penyewa_id='11111111-1111-1111-1111-111111111111' and nama='Tunai';
select uji.sama((select status from public.pesanan where id='b5220000-0000-0000-0000-000000000001'),
               'draf', 'kontrol: baru bayar Rp1, bukan lunas');
select uji.harap_gagal_sebab(
 $$insert into public.pembatalan(pesanan_id, tahap, alasan)
 values ('b5220000-0000-0000-0000-000000000001','sebelum_dapur','void setelah bayar')$$,
 'BY-201', 'T025-void: jalur resmi pun tidak boleh membatalkan sesudah bayar');
select uji.harap_gagal_sebab(
 $$update public.pesanan_item set qty=1 where id='b5220000-0000-0000-0000-000000000101'$$,
 'BY-201', 'T025-item: bahkan pembayaran Rp1 melarang pengurangan item');
reset role;
select uji.klaim(null);
-- Perubahan nonnominal juga dilarang; ini membuktikan penjaga rincian sendiri,
-- bukan cuma penjaga total yang kebetulan akan menolak nominal berubah.
select uji.harap_gagal_sebab(
 $$update public.pesanan_item set catatan='ubah' where id='b5220000-0000-0000-0000-000000000101'$$,
 'BY-201', 'T025-catatan: isi nonnominal juga beku untuk peladen');
-- Uji ID asal lebih awal; AFTER lama hanya menghitung parent tujuan.
select uji.harap_gagal_sebab(
 $$update public.diskon_transaksi set pesanan_id='b5220000-0000-0000-0000-000000000002' where id='b5220000-0000-0000-0000-000000000201'$$,
 'BY-201', 'T025-parent-lama: baris diskon tidak boleh dipindahkan keluar');
-- INSERT hanya punya ID baru; uji ini mendahului penolakan salinan harga lama.
select uji.harap_gagal_sebab(
 $$insert into public.pesanan_item(pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
 values('b5220000-0000-0000-0000-000000000001','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1)$$,
 'BY-201', 'T025-parent-baru: item baru tidak boleh masuk pesanan berbayar');
-- Pemilik tabel/jalur peladen juga tunduk: SECURITY DEFINER tidak menjadi pintu belakang.
-- Setiap percobaan berdiri sendiri & tidak boleh mengubah satu baris pun.
do $uji$
declare cmd text;
begin
 foreach cmd in array array[
  $q$delete from public.pesanan_item where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set qty=3 where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set harga_saat_itu=1 where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set status='batal' where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set catatan='ubah' where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set pesanan_id='b5220000-0000-0000-0000-000000000002' where id='b5220000-0000-0000-0000-000000000101'$q$,
  $q$update public.pesanan_item set pesanan_id='b5220000-0000-0000-0000-000000000001' where id='b5220000-0000-0000-0000-000000000102'$q$,
  $q$insert into public.pesanan_item(pesanan_id,menu_item_id,nama_saat_itu,harga_saat_itu,qty)
     values('b5220000-0000-0000-0000-000000000001','beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1)$q$,
  $q$update public.diskon_transaksi set nilai=100 where id='b5220000-0000-0000-0000-000000000201'$q$,
  $q$delete from public.diskon_transaksi where id='b5220000-0000-0000-0000-000000000201'$q$,
  $q$update public.diskon_transaksi set pesanan_id='b5220000-0000-0000-0000-000000000002' where id='b5220000-0000-0000-0000-000000000201'$q$,
  $q$insert into public.diskon_transaksi(pesanan_id,jenis,nominal,nilai,alasan)
     values('b5220000-0000-0000-0000-000000000001','manual',1,1,'ubah tagihan')$q$,
  $q$insert into public.pembatalan(pesanan_id,pesanan_item_id,tahap,alasan)
     values('b5220000-0000-0000-0000-000000000001','b5220000-0000-0000-0000-000000000101','sebelum_dapur','void item')$q$,
  $q$update public.pesanan set total=1 where id='b5220000-0000-0000-0000-000000000001'$q$,
  $q$update public.pesanan set status='batal' where id='b5220000-0000-0000-0000-000000000001'$q$,
  $q$delete from public.pesanan where id='b5220000-0000-0000-0000-000000000001'$q$
 ] loop
  perform uji.harap_gagal_sebab(cmd, 'BY-201', 'T025-peladen: ' || cmd);
 end loop;
end $uji$;
-- Rehitung setelah konfigurasi pajak berubah juga tidak boleh menulis ulang tagihan.
update public.pengaturan set pajak_pb1_persen=20 where penyewa_id='11111111-1111-1111-1111-111111111111';
-- Jalur peladen harus menyatakan role + klaim secara eksplisit agar tes ini
-- menguji BY-201, bukan berhenti lebih awal pada pagar identitas.
select uji.klaim(null, '{"role":"service_role"}');
set local role service_role;
select uji.harap_gagal_sebab($$select public.hitung_total('b5220000-0000-0000-0000-000000000001')$$,
 'BY-201', 'T025-total: hitung_total tidak melewati pembekuan');
reset role;
select uji.klaim(null);
update public.pengaturan set pajak_pb1_persen=10 where penyewa_id='11111111-1111-1111-1111-111111111111';
select uji.sama((select (subtotal,total_diskon,total) from public.pesanan where id='b5220000-0000-0000-0000-000000000001'),
               (54000,1000,60950), 'nominal asli tetap utuh');
select uji.sama((select count(*) from public.pembatalan where pesanan_id='b5220000-0000-0000-0000-000000000001'),
               0::bigint, 'tidak ada jejak void palsu');
-- Pembayaran berikutnya tetap boleh: split payment tidak dimatikan.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
insert into public.pembayaran(pesanan_id,metode_id,jumlah,diterima,kunci_idempoten)
select 'b5220000-0000-0000-0000-000000000001', id, 60949, 61000, 'beku-bayar-sisa'
from public.metode_bayar where penyewa_id='11111111-1111-1111-1111-111111111111' and nama='Tunai';
select uji.harap_gagal_sebab($$update public.pesanan_item set qty=1 where id='b5220000-0000-0000-0000-000000000101'$$,
 'BY-201', 'T025-full: sesudah seluruh pembayaran juga beku');
reset role;
select uji.klaim(null);
-- Operasional tanpa mengubah isi masih boleh: progress masak saja; penjaga lama
-- tetap memvalidasi izin/transisi. Isi baru/transisi batal TIDAK dikecualikan.
update public.pengaturan set pajak_pb1_persen=20 where penyewa_id='11111111-1111-1111-1111-111111111111';
do $uji$
begin
 update public.pesanan_item set status='dimasak' where id='b5220000-0000-0000-0000-000000000101';
 update public.pesanan_item set status='siap' where id='b5220000-0000-0000-0000-000000000101';
exception when raise_exception then
 if sqlerrm like 'BY-201:%' then
   perform uji.harap(false, 'T025-progres: perubahan tarif tidak boleh memblokir progres masak murni');
 else raise;
 end if;
end $uji$;
select uji.sama((select status from public.pesanan_item where id='b5220000-0000-0000-0000-000000000101'), 'siap', 'progress masak tidak mengubah tagihan');
-- Kontrol positif sebelum bayar: penyuntingan + void resmi tetap sah.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
update public.pesanan_item set qty=1 where id='b5220000-0000-0000-0000-000000000102';
insert into public.pembatalan(pesanan_id,tahap,alasan)
values('b5220000-0000-0000-0000-000000000002','sebelum_dapur','kontrol tanpa pembayaran');
reset role;
select uji.klaim(null);
select uji.sama((select status from public.pesanan where id='b5220000-0000-0000-0000-000000000002'), 'batal', 'kontrol: void sebelum bayar tetap sah');
