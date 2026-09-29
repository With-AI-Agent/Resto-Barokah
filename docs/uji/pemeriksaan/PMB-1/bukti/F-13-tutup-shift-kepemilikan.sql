-- ============================================================================
-- Probe PMB1-F-174 (kartu K-F-13) — kepemilikan shift pada RPC public.tutup_shift()
--
-- Klaim yang diuji (DECISIONS_LOG.md:2452):
--   "Kasir hanya boleh menutup shift milik dirinya sendiri, kecuali atasan dengan
--    hak `kelola_kas` dapat menutup shift kasir lain jika ditentukan secara eksplisit."
--
-- Pertanyaan: benarkah aturan itu ditegakkan peladen?
--
-- Jalankan:
--   node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-13-tutup-shift-kepemilikan.sql
--
-- Cara membaca hasil: asersi berlabel "CELOH" sengaja memakai uji.harap terhadap
-- KENYATAAN (diterima), bukan terhadap klaim — supaya hijau berarti "celah ADA dan
-- terbukti". Bila suatu hari celahnya diperbaiki, asersi CELOH justru akan MERAH,
-- dan itulah kabar baiknya. Kontrol positif & negatif di bawah membuktikan harness
-- benar-benar memanggil RPC yang sebenarnya dan bisa melihat penolakan.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Kontrol positif — Rina (kasir A1, 0004) menutup shift miliknya sendiri.
--    (Sama dengan kasus resmi supabase/tes/tutup_shift.sql; kunci sukses harness.)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Probe F-174: shift milik Rina'
);

select public.tutup_shift(p_uang_fisik := 100000);

reset role;

select uji.harap(
  (select status = 'ditutup' and ditutup_oleh = '90000000-0000-0000-0000-000000000004'::uuid
     from public.shift_kas
    where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
      and dibuka_pada::date = now()::date
    order by dibuka_pada desc limit 1),
  'KONTROL POSITIF: kasir menutup shift miliknya sendiri diterima (sesuai tes resmi)'
);

-- ---------------------------------------------------------------------------
-- 2. CELOH jalur eksplisit p_shift_id — Rina (kasir, TANPA kelola_kas) menutup
--    shift Pak Andi (admin A1, 0003) secara eksplisit. Klaim :2452 menghendaki
--    DITOLAK (Rina bukan pemilik dan bukan atasan ber-kelola_kas); kenyataannya
--    tidak ada satu pun cek pemilik di badan tutup_shift.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 50000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Probe F-174: shift milik Andi untuk dibedah Rina'
);

reset role;

create temp table _f13_shift_andi as
select id, dibuka_oleh
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000003'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;
grant all on table _f13_shift_andi to authenticated;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.tutup_shift(
  p_shift_id   := (select id from _f13_shift_andi),
  p_uang_fisik := 50000
);

reset role;

select uji.harap(
  (select ditutup_oleh = '90000000-0000-0000-0000-000000000004'::uuid
        and dibuka_oleh = '90000000-0000-0000-0000-000000000003'::uuid
     from public.shift_kas where id = (select id from _f13_shift_andi)),
  'CELOH (p_shift_id): kasir menutup shift orang lain DITERIMA tanpa cek pemilik — klaim :2452 seharusnya DITOLAK'
);

-- ---------------------------------------------------------------------------
-- 3. CELOH jalur fallback tanpa p_shift_id — Andi buka shift baru; Rina (yang
--    tidak punya shift sendiri) memanggil tutup_shift TANPA p_shift_id. Fallback
--    "cari shift terbuka di cabang yang dipantau" (0084:424-433) menutup shift
--    Andi. Bahkan tanpa penentuan eksplisit pun orang bisa menutup shift orang lain.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 75000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Probe F-174: shift Andi kedua untuk jalur fallback'
);

reset role;

delete from _f13_shift_andi;
insert into _f13_shift_andi
select id, dibuka_oleh
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000003'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.tutup_shift(p_uang_fisik := 75000);

reset role;

select uji.harap(
  (select ditutup_oleh = '90000000-0000-0000-0000-000000000004'::uuid
        and dibuka_oleh = '90000000-0000-0000-0000-000000000003'::uuid
     from public.shift_kas where id = (select id from _f13_shift_andi)),
  'CELOH (fallback): tanpa p_shift_id, shift terbuka orang lain di cabang pantau ikut tertutup — klaim :2452 seharusnya DITOLAK'
);

-- ---------------------------------------------------------------------------
-- 4. Kontrol negatif — Dedi (pelayan A1, 0005) mencoba menutup shift Andi di
--    cabang yang sama lewat p_shift_id. Kasus ini MEMANG harus ditolak (peran
--    pelayan tidak punya tutup_kas), dan memang ditolak dengan 'tidak berwenang'
--    — membuktikan (a) harness melihat penolakan sungguhan, (b) yang hilang
--    khususnya gerbang KEPEMILIKAN, bukan semua gerbang.
--    (Catatan: kasir beda penyewa seperti Ujang 0007 ditolak lebih dulu oleh
--    gerbang penyewa dengan sebab "Shift kas tidak ditemukan." — itu juga benar,
--    tetapi bukan kontrol yang kita butuhkan di sini.)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 30000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Probe F-174: shift Andi ketiga untuk kontrol negatif'
);

reset role;

delete from _f13_shift_andi;
insert into _f13_shift_andi
select id, dibuka_oleh
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000003'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;

select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.harap_gagal_sebab(
  $$select public.tutup_shift(p_shift_id := (select id from _f13_shift_andi), p_uang_fisik := 30000)$$,
  'tidak berwenang',
  'KONTROL NEGATIF: pelayan DITOLAK menutup shift kas (peran tanpa tutup_kas ditolak; yang tanpa gerbang khusus KEPEMILIKAN)'
);

reset role;

-- Bersih-bersih: Andi menutup shift terakhirnya sendiri (boleh, dia pemiliknya).
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select public.tutup_shift(
  p_shift_id   := (select id from _f13_shift_andi),
  p_uang_fisik := 30000
);

reset role;
select uji.klaim(null);

-- Catatan tambahan (bukti statis, bukan asersi):
-- - `kelola_kas` tidak muncul satu kali pun di seluruh repositori (grep -rn).
-- - Yang dipakai peladen ialah public.boleh('tutup_kas', v_shift.cabang_id)
--   (0046:164; versi hidup 0084:438) — bukan public.punya_hak_di_cabang.
-- - supabase/tes/tutup_shift.sql tidak memuat asersi "kasir hanya menutup shift
--   miliknya sendiri"; skenario "Dua Kasir Satu Shift" justru meng-harap SUKSES
--   ketika admin menutup shift kasir lain (baris 245-296).
