-- ============================================================================
-- UJI: persetujuan void sesudah dapur harus TERBUKTI dengan PIN penyetuju
-- Temuan audit AUD-3 K-2 (A F-03, 2026-09-17): pemicu hanya memeriksa bahwa
-- penyetuju itu BERWENANG (`boleh_untuk`), bukan bahwa ia benar-benar
-- MENYETUJUI. Akibatnya kasir bisa menuliskan nama owner sebagai penyetuju
-- tanpa owner pernah menyentuh perangkat — dan itu tercatat sebagai
-- "disetujui atasan" (jejak persetujuan palsu, kerugian bahan ikut tercatat).
-- Aturan yang dikunci: wajib ada bukti PIN yang benar untuk aksi ini &
-- baru saja (jendela singkat), dicatat di `percobaan_pin`.
-- ============================================================================

-- Persiapan: owner memasang PIN-nya sendiri (PIN pertama boleh tanpa PIN lama).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null, null, 'de000000-0000-0000-0000-000000000001', 'kunci-uji-hp-owner-0123456789'), 'PIN tersimpan.', 'owner memasang PIN-nya sendiri');
reset role;
select uji.klaim(null);

-- 1. Kasir membatalkan setelah dapur mulai dengan penyetuju yang berwenang
--    tetapi TANPA bukti persetujuan → harus DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur',
              '90000000-0000-0000-0000-000000000002', 'void tanpa bukti persetujuan')$$, 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri u', 'pembatalan sesudah dapur DITOLAK bila penyetuju belum memasukkan PIN-nya');

-- 2. PIN yang benar tetapi untuk AKSI LAIN juga bukan bukti.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', null, 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789')).berhasil,
  true, 'kontrol: PIN penyetuju benar (tanpa menyebut aksi)');
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur',
              '90000000-0000-0000-0000-000000000002', 'void dengan PIN tanpa aksi')$$, 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri u', 'pembatalan DITOLAK bila PIN-nya tidak diminta untuk aksi void_sesudah_dapur');

-- 3. Bukti yang benar: penyetuju memasukkan PIN-nya untuk aksi ini → diterima.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', 'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true, 'PIN penyetuju diverifikasi UNTUK aksi & PESANAN void_sesudah_dapur');
insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan, bahan_terbuang)
values ('eeee0000-0000-0000-0000-000000000010', 'sesudah_dapur',
        '90000000-0000-0000-0000-000000000002', 'void dengan bukti PIN', true);
select uji.sama(
  (select count(*) from public.pembatalan where alasan = 'void dengan bukti PIN'),
  1::bigint,
  'pembatalan DITERIMA setelah bukti PIN penyetuju ada'
);
reset role;
select uji.klaim(null);

-- 4. Bukti KEDALUWARSA tidak berlaku: pesanan kedua, bukti dimundurkan waktunya.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000c001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 93, current_date, 'dinein', 'dikirim',
        10000, 0, 0, 10000, 'void-kedaluwarsa');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = '00000000-0000-0000-0000-00000000c001';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', '00000000-0000-0000-0000-00000000c001')).berhasil,
  true, 'kontrol: bukti kedua dibuat untuk pesanan kedua');
reset role;
-- Pemilik tabel memundurkan waktu bukti (meniru persetujuan 1 jam lalu).
update public.percobaan_pin set waktu = now() - interval '1 hour'
 where pengguna_id = '90000000-0000-0000-0000-000000000002' and berhasil and aksi = 'void_sesudah_dapur';

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('00000000-0000-0000-0000-00000000c001', 'sesudah_dapur',
              '90000000-0000-0000-0000-000000000002', 'void dengan bukti lama')$$, 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri u', 'pembatalan DITOLAK bila bukti persetujuannya sudah kedaluwarsa');
reset role;
select uji.klaim(null);

-- 5. KUPON SEKALI PAKAI (temuan review putaran8 PR-04): persetujuan PIN untuk SATU pesanan
--    tidak boleh dipakai membatalkan pesanan lain.
-- Pesanan ini punya DUA item hidup supaya pemeriksaan berikutnya benar-benar menguji
-- kupon sekali pakai: pembatalan item pertama TIDAK menutup pesanannya (sejak AUD-3 F-04
-- & F-05 status item hanya lewat baris pembatalan resmi, dan satu target hanya sekali),
-- jadi percobaan memakai ulang kupon yang sudah habis tidak bisa tertahan oleh aturan
-- idempotensi — hanya bisa tertahan oleh aturan kupon itu sendiri.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000c002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 94, current_date, 'dinein', 'dikirim',
        10000, 0, 0, 10000, 'void-replay');
update public.pesanan set dikirim_ke_dapur_pada = now() - interval '5 minutes'
 where id = '00000000-0000-0000-0000-00000000c002';
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('00000000-0000-0000-0000-00000000c201', '00000000-0000-0000-0000-00000000c002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 5000, 1, 5000),
       ('00000000-0000-0000-0000-00000000c202', '00000000-0000-0000-0000-00000000c002',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 5000, 1, 5000);

reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner menyetujui yang KEDUA
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '738294', 'void_sesudah_dapur', 'de000000-0000-0000-0000-000000000006', 'kunci-uji-hp-atasan-0123456789', '00000000-0000-0000-0000-00000000c002')).berhasil,
  true, 'kontrol: persetujuan untuk pesanan kedua dibuat'
);

reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, disetujui_oleh, alasan)
values ('00000000-0000-0000-0000-00000000c002', '00000000-0000-0000-0000-00000000c201',
        'sesudah_dapur', '90000000-0000-0000-0000-000000000002',
        'pembatalan pertama (item yang disetujui)');
select uji.sama(
  (select p.status from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000c002'),
  'dikirim', 'kontrol: satu item dibatalkan, pesanan masih hidup (item kedua masih ada)'
);
select uji.harap_gagal_sebab($$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('00000000-0000-0000-0000-00000000c001', 'sesudah_dapur',
              '90000000-0000-0000-0000-000000000002', 'mencoba memakai ulang bukti pesanan lain')$$, 'Persetujuan belum terbukti untuk pesanan ini: penyetuju harus memasukkan PIN-nya sendiri u', 'satu persetujuan PIN tidak bisa dipakai untuk pesanan LAIN (kupon sekali pakai)');
-- Item KEDUA (masih hidup) + kupon yang SUDAH HABIS: yang menahan hanya aturan kupon.
select uji.sama(
  (select count(*) from public.pembatalan pb
    where pb.pesanan_item_id = '00000000-0000-0000-0000-00000000c202'),
  0::bigint, 'kontrol: item kedua belum dibatalkan'
);
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, disetujui_oleh, alasan)
      values ('00000000-0000-0000-0000-00000000c002', '00000000-0000-0000-0000-00000000c202',
              'sesudah_dapur', '90000000-0000-0000-0000-000000000002',
              'memakai ulang bukti yang sudah habis')$$,
  'Persetujuan belum terbukti',
  'bukti yang sudah dipakai tidak bisa dipakai lagi untuk pesanan yang sama (kupon sekali pakai)'
);
reset role;
select uji.klaim(null);
