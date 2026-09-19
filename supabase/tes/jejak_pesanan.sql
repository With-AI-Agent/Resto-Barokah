-- ============================================================================
-- UJI: JEJAK PESANAN TIDAK BOLEH DIKARANG DARI PERANGKAT
-- Menutup temuan audit AUD-3 2026-09-18 F-04 & review #2 PR-03 (K-2): kasir bisa
-- menulis kasir_id = UUID owner, tanggal mundur 30 hari, dan nomor pilihan sendiri.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;

-- 1. kasir_id diisi sistem.
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, tipe, kasir_id, kunci_idempoten)
      values ('11111111-1111-1111-1111-111111111111','a1a1a1a1-0000-0000-0000-000000000001','dinein',
              '90000000-0000-0000-0000-000000000002','jejak-karang-kasir')$$,
  'kasir tidak boleh menyebut orang lain sebagai kasir pesanan'
);

-- 2. Tanggal tidak boleh mundur.
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, tipe, tanggal, kunci_idempoten)
      values ('11111111-1111-1111-1111-111111111111','a1a1a1a1-0000-0000-0000-000000000001','dinein',
              current_date - 30, 'jejak-tanggal-mundur')$$,
  'tanggal pesanan baru tidak boleh mundur (dulu bisa masuk ke hari yang sudah ditutup)'
);

-- 3. Nomor dibuat sistem: angka kiriman klien diabaikan.
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, nomor, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f003','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001','dinein', 99999, 'jejak-nomor');
-- Walaupun klien mengirim kasir_id orang lain, NILAI TERSIMPAN tetap pengguna yang masuk
-- (dua lapis: ditolak, atau ditimpa peladen — nilai akhirnya tidak boleh pernah salah).
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, kasir_id, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f005','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001','dinein','90000000-0000-0000-0000-000000000004','jejak-nilai');
select uji.sama(
  (select p.kasir_id from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f005'),
  '90000000-0000-0000-0000-000000000004'::uuid,
  'kasir_id yang tersimpan = pengguna yang masuk (bukan UUID orang lain)'
);
select uji.sama(
  (select p.nomor from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f003') = 99999,
  false, 'nomor pilihan klien (99.999) TIDAK dipakai — peladen memberi nomor urut'
);
select uji.sama(
  (select p.kasir_id from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f003'),
  '90000000-0000-0000-0000-000000000004'::uuid, 'kasir_id terisi otomatis dari pengguna yang masuk'
);

-- 4. Pelayan yang disebut harus pegawai cabang itu.
select uji.harap_gagal(
  $$insert into public.pesanan (penyewa_id, cabang_id, tipe, pelayan_id, kunci_idempoten)
      values ('11111111-1111-1111-1111-111111111111','a1a1a1a1-0000-0000-0000-000000000001','dinein',
              '90000000-0000-0000-0000-000000000002','jejak-pelayan-luar')$$,
  'owner (bukan pegawai cabang itu) tidak boleh dicatat sebagai pelayan pesanan ini'
);
select uji.sama(
  (select count(*) from public.pesanan p where p.kunci_idempoten = 'jejak-pelayan-luar'),
  0::bigint, 'pesanan berpelayan luar tidak tersimpan'
);
-- Pelayan yang memang bertugas di cabang itu boleh disebut.
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, pelayan_id, kunci_idempoten)
values ('00000000-0000-0000-0000-00000000f004','11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001','dinein','90000000-0000-0000-0000-000000000005','jejak-pelayan-sah');
select uji.sama(
  (select p.pelayan_id from public.pesanan p where p.id = '00000000-0000-0000-0000-00000000f004'),
  '90000000-0000-0000-0000-000000000005'::uuid, 'pelayan cabang itu boleh disebut (jalur sah tetap terbuka)'
);

-- 5. Jejak tidak bisa dipindah setelah baris lahir.
select uji.harap_gagal(
  $$update public.pesanan set kasir_id = '90000000-0000-0000-0000-000000000002'
      where id = '00000000-0000-0000-0000-00000000f003'$$,
  'kasir pesanan tidak boleh dipindah setelah tercatat'
);
select uji.harap_gagal(
  $$update public.pesanan set tanggal = current_date - 1
      where id = '00000000-0000-0000-0000-00000000f003'$$,
  'tanggal pesanan tidak boleh diubah setelah tercatat'
);
reset role;
select uji.klaim(null);
