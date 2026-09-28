-- ============================================================================
-- UJI T5-07 — "bahan terbuang" ditentukan peladen, tidak dititipkan klien (0042)
-- ============================================================================
-- Yang dibuktikan berkas ini:
--   1. Void SESUDAH dapur yang dikirim `bahan_terbuang = false` TETAP tersimpan
--      `true` — kerugian bahan tidak bisa disembunyikan dari laporan. (Ditimpa,
--      bukan ditolak: `false` adalah nilai BAWAAN kolom, jadi pemicu tidak bisa
--      membedakannya dari "klien menyerahkan pengisian ke peladen" — pola yang
--      sama dipakai `nilai_kerugian` sejak 0015.)
--   2. Void SESUDAH dapur dengan penanda benar juga DITERIMA dan tersimpan `true`.
--   3. Void SEBELUM dapur yang dikirim `bahan_terbuang = true` DITOLAK —
--      laporan kerugian tidak boleh dipompa untuk kejadian yang tidak membuang
--      apa pun.
--   4. Void SEBELUM dapur biasa tersimpan `false`.
--   5. Penanda tetap benar untuk pembatalan SATU ITEM (bukan hanya pesanan).
--
-- Pesanan uji dibuat di dalam berkas ini (id khusus `d7…`) supaya tidak
-- mengganggu pesanan contoh milik berkas uji lain.
-- ============================================================================

-- Penyiapan: dua pesanan Cabang A1 — satu belum ke dapur, satu sudah dimasak.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('d7000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 971, current_date, 'dinein', 'draf', 'bahan-terbuang-pra'),
       ('d7000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 972, current_date, 'dinein', 'draf', 'bahan-terbuang-pasca');

insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('d7000000-0000-0000-0000-0000000000a1', 'd7000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('d7000000-0000-0000-0000-0000000000a2', 'd7000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 8000, 1, 8000),
       ('d7000000-0000-0000-0000-0000000000b1', 'd7000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);

-- Pesanan kedua benar-benar sudah masuk dapur (dua tanda diisi, seperti keadaan nyata).
update public.pesanan
   set dikirim_ke_dapur_pada = now(), status = 'dimasak'
 where id = 'd7000000-0000-0000-0000-000000000002';

-- ---------------------------------------------------------------------------
-- 1. SESUDAH dapur + bahan_terbuang = false → DITIMPA jadi true (celah utama).
-- ---------------------------------------------------------------------------
-- Penyetuju (owner) memasukkan PIN-nya sendiri untuk pesanan ini lebih dulu.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'penyiapan: owner memasang PIN-nya sendiri');
reset role;
select uji.klaim(null);

-- Bukti PIN diverifikasi dari kursi KASIR (pemanggil harus sedang masuk —
-- `verifikasi_pin` menolak pemanggil anonim); yang dicocokkan tetap PIN owner.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur',
                         'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789',
                         'd7000000-0000-0000-0000-000000000002')).berhasil,
  true, 'penyiapan: bukti PIN penyetuju sah untuk pesanan yang sudah dimasak');

-- Inilah celah T5-07 yang sesungguhnya: kasir membatalkan pesanan yang MAKANANNYA
-- SUDAH DIMASAK sambil mengirim "tidak ada bahan terbuang". Dulu diterima apa
-- adanya dan kerugiannya lenyap dari laporan selamanya.
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('d7000000-0000-0000-0000-000000000002', 'sesudah_dapur',
        '90000000-0000-0000-0000-000000000002', 'makanan sudah dimasak', false);
reset role;
select uji.klaim(null);

select uji.sama(
  (select pb.bahan_terbuang from public.pembatalan pb
    where pb.pesanan_id = 'd7000000-0000-0000-0000-000000000002' limit 1),
  true, 'T5-07: kiriman "tanpa bahan terbuang" DITIMPA — kerugian tidak bisa disembunyikan'
);
select uji.sama(
  (select pb.nilai_kerugian from public.pembatalan pb
    where pb.pesanan_id = 'd7000000-0000-0000-0000-000000000002' limit 1),
  27000, 'T5-07: nilai kerugian tetap dari salinan harga (27.000)'
);

-- ---------------------------------------------------------------------------
-- 3. SEBELUM dapur + bahan_terbuang = true → DITOLAK (laporan tidak dipompa).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan, bahan_terbuang)
      values ('d7000000-0000-0000-0000-000000000001', 'd7000000-0000-0000-0000-0000000000a1',
              'sebelum_dapur', 'salah input', true)$$,
  'TIDAK boleh ditandai bahan terbuang',
  'T5-07: void sebelum dapur tidak bisa dipompa jadi kerugian bahan'
);

-- ---------------------------------------------------------------------------
-- 4 & 5. SEBELUM dapur (satu item) tanpa penanda → diterima, tersimpan `false`.
-- ---------------------------------------------------------------------------
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('d7000000-0000-0000-0000-000000000001', 'd7000000-0000-0000-0000-0000000000a1',
        'sebelum_dapur', 'salah input kasir');
reset role;
select uji.klaim(null);

select uji.sama(
  (select pb.bahan_terbuang from public.pembatalan pb
    where pb.pesanan_item_id = 'd7000000-0000-0000-0000-0000000000a1' limit 1),
  false, 'T5-07: void sebelum dapur tercatat TANPA bahan terbuang'
);
select uji.sama(
  (select pb.nilai_kerugian from public.pembatalan pb
    where pb.pesanan_item_id = 'd7000000-0000-0000-0000-0000000000a1' limit 1),
  27000, 'T5-07: nilai kerugian satu item dari salinan harga item itu'
);

-- Bersih-bersih: kembalikan keadaan supaya berkas uji lain tidak terpengaruh.
delete from public.pembatalan
 where pesanan_id in ('d7000000-0000-0000-0000-000000000001', 'd7000000-0000-0000-0000-000000000002');
delete from public.pesanan_item
 where pesanan_id in ('d7000000-0000-0000-0000-000000000001', 'd7000000-0000-0000-0000-000000000002');
delete from public.pesanan
 where id in ('d7000000-0000-0000-0000-000000000001', 'd7000000-0000-0000-0000-000000000002');
update public.percobaan_pin set dipakai_pada = now()
 where pesanan_id = 'd7000000-0000-0000-0000-000000000002' and dipakai_pada is null;
