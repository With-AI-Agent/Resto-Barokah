-- ============================================================================
-- UJI: JEJAK STATUS ITEM DAPUR — anti-dobel, riwayat kekal, sinkron pesanan (T4-04, ART-4)
-- Peta transisi (baru → dimasak → siap, tanpa lompat/mundur) sudah dijaga mesin 0015
-- (kontrak: supabase/tes/status_item_transisi.sql). Yang dibuktikan di sini adalah
-- TAMBAHAN T4-04: (1) setiap transisi tercatat hanya-tambah (siapa, kapan, dari → ke);
-- (2) dua perangkat menandai item yang sama menghasilkan SATU perubahan tercatat dan
-- ulangan ber-kunci sama tidak mengubah apa pun; (3) riwayat tidak bisa diubah/dihapus;
-- (4) status pesanan maju mengikuti item — tidak sebelumnya; (5) permukaan RPC terkunci.
-- ============================================================================

-- Data uji dibuat sebagai PELADEN: pesanan Cabang Dua (tempat dapur bertugas)
-- dengan 2 item + 1 pesanan Pusat (untuk uji permukaan RPC), semua 'dikirim'.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f042','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000002', 77, current_date, 'dinein', 'dikirim', 'status-item-uji'),
       ('00000000-0000-0000-0000-00000000f043','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 78, current_date, 'dinein', 'dikirim', 'status-item-uji-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000f142','00000000-0000-0000-0000-00000000f042',
        'beef0000-0000-0000-0000-000000000001','Nasi Goreng',27000,1,27000),
       ('00000000-0000-0000-0000-00000000f143','00000000-0000-0000-0000-00000000f042',
        'beef0000-0000-0000-0000-000000000002','Es Teh',5000,2,10000),
       ('00000000-0000-0000-0000-00000000f144','00000000-0000-0000-0000-00000000f043',
        'beef0000-0000-0000-0000-000000000001','Nasi Goreng',25000,1,25000);
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '2 minutes'
 where id in ('00000000-0000-0000-0000-00000000f042', '00000000-0000-0000-0000-00000000f043');
select uji.klaim(null);

-- 1. Permukaan RPC terkunci: anonim tidak boleh memanggil set_status_item.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.set_status_item('00000000-0000-0000-0000-00000000f142', 'dimasak')$$,
  'permission denied|tidak diizinkan',
  'anon ditolak memanggil set_status_item');
reset role;
select uji.klaim(null);

-- 2. Dapur memajukan item pertama: baru → dimasak. Tercatat SATU riwayat;
--    pesanan otomatis 'dikirim' → 'dimasak'.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f142', 'dimasak', 'kunci-t404-1')->>'diubah')::text),
  'true', 'set_status_item baru → dimasak mengubah keadaan (diubah = true)');
reset role;
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f142'),
  'dimasak', 'item pertama kini dimasak');
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f042'),
  'dimasak', 'pesanan ikut maju ke dimasak saat item pertama mulai masak');
select uji.sama(
  (select count(*) from public.pesanan_item_status_riwayat r
    where r.pesanan_item_id = '00000000-0000-0000-0000-00000000f142'),
  1::bigint, 'tepat satu baris riwayat perubahan status tercatat');
select uji.sama(
  (select r.dari || '->' || r.ke from public.pesanan_item_status_riwayat r
    where r.pesanan_item_id = '00000000-0000-0000-0000-00000000f142'),
  'baru->dimasak', 'riwayat merekam dari → ke');

-- 3. ANTI-DOBEL: perangkat lain menandai item yang SAMA ke status yang sama →
--    diubah=false, riwayat tetap 1. Ulangan ber-kunci sama yang terlambat datang
--    (bahkan membawa status berikutnya) diabaikan — kunci = identitas permintaan.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f142', 'dimasak', 'kunci-t404-lain')->>'diubah')::text),
  'false', 'tanda dobel dari perangkat lain = diubah false (idempoten)');
-- Tanda dobel lewat update mentah (tanpa RPC) pun tidak menambah riwayat.
update public.pesanan_item set status = 'dimasak' where id = '00000000-0000-0000-0000-00000000f142';
select uji.sama(
  (select (public.set_status_item('00000000-0000-0000-0000-00000000f142', 'siap', 'kunci-t404-1')->>'diubah')::text),
  'false', 'ulangan kunci lama diabaikan (tidak melompatkan status)');
reset role;
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = '00000000-0000-0000-0000-00000000f142'),
  'dimasak', 'ulangan kunci tidak mengubah status item');
select uji.sama(
  (select count(*) from public.pesanan_item_status_riwayat r
    where r.pesanan_item_id = '00000000-0000-0000-0000-00000000f142'),
  1::bigint, 'dobel/ulangan tidak menambah riwayat — tetap satu perubahan tercatat');

-- 4. Nilai tujuan di luar mesin masak ditolak RPC.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.set_status_item('00000000-0000-0000-0000-00000000f142', 'baru')$$,
  'hanya menerima status dimasak atau siap',
  'status tujuan di luar dimasak/siap ditolak');
reset role;
select uji.klaim(null);

-- 5. Selesai satu per satu: pesanan baru 'siap' ketika SEMUA item siap.
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select public.set_status_item('00000000-0000-0000-0000-00000000f142', 'siap', 'kunci-t404-2');
select public.set_status_item('00000000-0000-0000-0000-00000000f143', 'dimasak', 'kunci-t404-3');
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f042'),
  'dimasak', 'pesanan belum siap — masih ada item yang dimasak');
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select public.set_status_item('00000000-0000-0000-0000-00000000f143', 'siap', 'kunci-t404-4');
reset role;
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f042'),
  'siap', 'pesanan menjadi siap ketika seluruh item siap');
select uji.sama(
  (select count(*) from public.pesanan_item_status_riwayat),
  4::bigint, 'total riwayat = 4 transisi sah (dobel/ulangan tidak dihitung)');

-- 6. Riwayat hanya-tambah: ubah & hapus DITOLAK (kecurangan/penyembunyian jejak
--    tidak mungkin lewat pintu ini).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$update public.pesanan_item_status_riwayat set ke = 'baru' where pesanan_item_id = '00000000-0000-0000-0000-00000000f142'$$,
  'permission denied|tidak diizinkan',
  'riwayat status tidak bisa diubah');
select uji.harap_gagal_sebab(
  $$delete from public.pesanan_item_status_riwayat where pesanan_item_id = '00000000-0000-0000-0000-00000000f142'$$,
  'permission denied|tidak diizinkan',
  'riwayat status tidak bisa dihapus');
reset role;
select uji.klaim(null);

-- 7. Item yang tidak terlihat / milik resto lain ditolak rapi ("tidak ditemukan").
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.set_status_item('00000000-0000-0000-0000-000000000000', 'dimasak')$$,
  'tidak ditemukan',
  'item yang tidak terlihat/milik resto lain ditolak');
reset role;
select uji.klaim(null);
