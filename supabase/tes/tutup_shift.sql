-- ===========================================================================
-- Uji SQL: Tutup Shift Kasir (T7-02 — PRD M7 / TECH_SPEC §9 ART-6)
--
-- Kasus wajib sesuai ROADMAP DoD:
-- 1. Pas (uang fisik = uang seharusnya)
-- 2. Lebih (uang fisik > uang seharusnya, alasan wajib)
-- 3. Kurang (uang fisik < uang seharusnya, alasan wajib)
-- 4. Tanpa alasan saat selisih -> DITOLAK
-- 5. Dua kasir satu shift (dibuka kasir A, ditutup kasir B)
-- Kasus keamanan tambahan:
-- 6. Shift sudah ditutup tidak bisa ditutup lagi
-- 7. Pelayan / Dapur dilarang menutup shift
-- 8. Uang fisik negatif dilarang
-- 9. Jejak audit kriptografis tercatat
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Persiapan: Buka shift oleh Rina (kasir A1) dengan modal awal 100.000
-- ---------------------------------------------------------------------------
-- Rina (kasir A1): 90000000-0000-0000-0000-000000000004
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Shift pagi Rina'
);

reset role;

-- Ambil ID shift Rina
create temp table if not exists _t_shift as
select id as shift_id, modal_awal, cabang_id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

grant all on table _t_shift to authenticated;

select uji.harap(
  (select count(*) from _t_shift) = 1,
  'Shift kasir Rina berhasil dibuka untuk pengujian'
);

-- Catat pesanan dan pembayaran tunai 50.000 di shift ini
insert into public.pesanan (
  id, penyewa_id, cabang_id, nomor, status, subtotal, total, kunci_idempoten, shift_id
) values (
  'e1e1e1e1-0000-0000-0000-000000000001'::uuid,
  '11111111-1111-1111-1111-111111111111'::uuid,
  'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  70201,
  'lunas',
  50000,
  50000,
  'idem-t702-pesanan-01',
  (select shift_id from _t_shift)
);

insert into public.pembayaran (
  pesanan_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, diterima, kembalian,
  kasir_id, shift_id, kunci_idempoten
) values (
  'e1e1e1e1-0000-0000-0000-000000000001'::uuid,
  'Tunai',
  'tunai',
  50000,
  50000,
  0,
  '90000000-0000-0000-0000-000000000004'::uuid,
  (select shift_id from _t_shift),
  'idem-t702-bayar-01'
);

-- Total uang seharusnya: modal_awal (100.000) + tunai (50.000) = 150.000

-- ---------------------------------------------------------------------------
-- 2. Kasus 4: Tanpa Alasan saat ada selisih -> DITOLAK
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Uang fisik 160.000 (selisih +10.000) tapi alasan null
select uji.harap_gagal_sebab(
  $$select public.tutup_shift(160000, null)$$,
  'Alasan selisih wajib diisi jika uang fisik berbeda dari uang seharusnya',
  'Tutup shift dengan selisih tanpa alasan (null) wajib ditolak'
);

-- Uang fisik 140.000 (selisih -10.000) tapi alasan spasi kosong
select uji.harap_gagal_sebab(
  $$select public.tutup_shift(140000, '   ')$$,
  'Alasan selisih wajib diisi jika uang fisik berbeda dari uang seharusnya',
  'Tutup shift dengan selisih alasan spasi kosong wajib ditolak'
);

-- Uang fisik negatif -> DITOLAK
select uji.harap_gagal_sebab(
  $$select public.tutup_shift(-1000)$$,
  'Jumlah uang fisik wajib diisi dan tidak boleh negatif',
  'Uang fisik negatif wajib ditolak'
);

-- ---------------------------------------------------------------------------
-- 3. Kasus 1: Pas (uang fisik = uang seharusnya = 150.000)
-- ---------------------------------------------------------------------------
select public.tutup_shift(
  p_uang_fisik     := 150000,
  p_alasan_selisih := null,
  p_catatan        := 'Tutup shift pas sesuai'
);

reset role;

select uji.harap(
  (select status from public.shift_kas where id = (select shift_id from _t_shift)) = 'ditutup',
  'Status shift menjadi ditutup'
);

select uji.harap(
  (select uang_seharusnya from public.shift_kas where id = (select shift_id from _t_shift)) = 150000,
  'Uang seharusnya dihitung tepat 150.000'
);

select uji.harap(
  (select uang_fisik from public.shift_kas where id = (select shift_id from _t_shift)) = 150000,
  'Uang fisik tercatat 150.000'
);

select uji.harap(
  (select selisih from public.shift_kas where id = (select shift_id from _t_shift)) = 0,
  'Selisih adalah 0'
);

select uji.harap(
  (select ditutup_oleh from public.shift_kas where id = (select shift_id from _t_shift)) = '90000000-0000-0000-0000-000000000004'::uuid,
  'Penutup shift adalah Rina (kasir A1)'
);

-- ---------------------------------------------------------------------------
-- 4. Kasus 6: Shift yang sudah ditutup tidak bisa ditutup lagi
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.tutup_shift(150000, null, (select shift_id from _t_shift))$$,
  'Shift kas ini sudah ditutup sebelumnya',
  'Shift yang sudah ditutup tidak dapat ditutup ulang'
);

reset role;

-- ---------------------------------------------------------------------------
-- 5. Kasus 2: Lebih (uang fisik > uang seharusnya, alasan wajib)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 200000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Shift siang Rina'
);

reset role;

delete from _t_shift;
insert into _t_shift
select id, modal_awal, cabang_id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Tutup shift dengan uang fisik 215.000 (selisih +15.000) dan alasan sah
select public.tutup_shift(
  p_uang_fisik     := 215000,
  p_alasan_selisih := 'Pelanggan meja 3 tidak mau kembalian Rp15.000'
);

reset role;

select uji.harap(
  (select selisih from public.shift_kas where id = (select shift_id from _t_shift)) = 15000,
  'Kasus Lebih: selisih tercatat +15.000'
);

select uji.harap(
  (select alasan_selisih from public.shift_kas where id = (select shift_id from _t_shift)) = 'Pelanggan meja 3 tidak mau kembalian Rp15.000',
  'Kasus Lebih: alasan selisih tersimpan dengan baik'
);

-- ---------------------------------------------------------------------------
-- 6. Kasus 3: Kurang (uang fisik < uang seharusnya, alasan wajib)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 300000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid
);

reset role;

delete from _t_shift;
insert into _t_shift
select id, modal_awal, cabang_id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Tutup shift dengan uang fisik 295.000 (selisih -5.000) dan alasan sah
select public.tutup_shift(
  p_uang_fisik     := 295000,
  p_alasan_selisih := 'Kekurangan receh pecahan 5000 saat jam sibuk'
);

reset role;

select uji.harap(
  (select selisih from public.shift_kas where id = (select shift_id from _t_shift)) = -5000,
  'Kasus Kurang: selisih tercatat -5.000'
);

select uji.harap(
  (select alasan_selisih from public.shift_kas where id = (select shift_id from _t_shift)) = 'Kekurangan receh pecahan 5000 saat jam sibuk',
  'Kasus Kurang: alasan selisih tersimpan dengan baik'
);

-- ---------------------------------------------------------------------------
-- 7. Kasus 5: Dua Kasir Satu Shift
--    Rina (kasir) membuka shift, Pak Andi (admin cabang 1) menutup shift
-- ---------------------------------------------------------------------------
-- Rina membuka shift
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 500000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Dibuka Rina pagi'
);

reset role;

delete from _t_shift;
insert into _t_shift
select id, modal_awal, cabang_id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

-- Pak Andi (admin cabang A1: 90000000-0000-0000-0000-000000000003)
-- menutup shift yang dibuka oleh Rina
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select public.tutup_shift(
  p_shift_id       := (select shift_id from _t_shift),
  p_uang_fisik     := 500000,
  p_alasan_selisih := null,
  p_catatan        := 'Pak Andi serah terima shift siang'
);

reset role;

select uji.harap(
  (select status from public.shift_kas where id = (select shift_id from _t_shift)) = 'ditutup',
  'Kasus Dua Kasir: shift berhasil ditutup oleh kasir/admin kedua'
);

select uji.harap(
  (select dibuka_oleh from public.shift_kas where id = (select shift_id from _t_shift)) = '90000000-0000-0000-0000-000000000004'::uuid,
  'Kasus Dua Kasir: dibuka_oleh tetap Rina'
);

select uji.harap(
  (select ditutup_oleh from public.shift_kas where id = (select shift_id from _t_shift)) = '90000000-0000-0000-0000-000000000003'::uuid,
  'Kasus Dua Kasir: ditutup_oleh tercatat Pak Andi'
);

-- ---------------------------------------------------------------------------
-- 8. Kasus Keamanan: Peran yang tidak berwenang dilarang menutup shift
-- ---------------------------------------------------------------------------
-- Buka shift baru oleh Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid
);

reset role;

delete from _t_shift;
insert into _t_shift
select id, modal_awal, cabang_id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

-- Dedi (pelayan: 90000000-0000-0000-0000-000000000005)
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.tutup_shift(100000, null, (select shift_id from _t_shift))$$,
  'tidak berwenang',
  'Pelayan dilarang menutup shift kas'
);

reset role;

-- Sari (dapur: 90000000-0000-0000-0000-000000000006)
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.tutup_shift(100000, null, (select shift_id from _t_shift))$$,
  'tidak berwenang',
  'Dapur dilarang menutup shift kas'
);

reset role;

-- ---------------------------------------------------------------------------
-- 9. Jejak Audit Kriptografis
-- ---------------------------------------------------------------------------
-- Tutup shift oleh Rina
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.tutup_shift(
  p_uang_fisik     := 100000,
  p_alasan_selisih := null
);

reset role;

select uji.harap(
  (select count(*) > 0
     from public.catatan_audit
    where entitas = 'shift_kas'
      and entitas_id = (select shift_id from _t_shift)
      and aksi = 'tutup_shift'),
  'Jejak audit kriptografis tutup_shift berhasil tercatat'
);

-- ---------------------------------------------------------------------------
-- 10. Kasus saat tidak ada shift terbuka -> DITOLAK
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.tutup_shift(100000, null)$$,
  'Tidak ada shift kas terbuka yang dapat ditutup',
  'Tutup shift saat tidak ada shift terbuka wajib ditolak'
);

reset role;

