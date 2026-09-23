-- ============================================================================
-- UJI: T5-04 — satu diskon per transaksi (bawaan) + tumpuk dengan BATAS
--
-- Aturan yang dikunci (DoD ROADMAP T5-04):
--   1. **Bawaan resto = TIDAK boleh tumpuk.** Diskon KEDUA ditolak, apa pun
--      nilainya — bahkan kalau nilainya kecil dan masih jauh di dalam batas izin
--      kasir. Kalau pagar ini tumpul, kasir bisa memberi potongan besar dengan
--      cara memecahnya jadi banyak baris kecil yang masing-masing "sah".
--   2. **Dengan `tumpuk_diskon = true`, diskon kedua boleh** — tapi TOTALNYA
--      tetap dijaga cap resto (`batas_maks_potongan_persen` /
--      `batas_maks_potongan_nominal`), bukan diperiksa per baris.
--   3. **Cap dihitung KUMULATIF.** Dua baris yang masing-masing di bawah cap,
--      tetapi jumlahnya melewati cap, WAJIB ditolak pada baris kedua.
--   4. **Cap nominal juga ditegakkan**, bukan hanya cap persen.
--   5. **Total diskon tidak boleh melebihi subtotal** (pesanan tidak bisa minus).
--   6. Mematikan kembali `tumpuk_diskon` mengembalikan aturan satu-diskon.
--
-- Mekanismenya ada di `picu_diskon_batas()` (migrasi `0019_pesan_diskon_jujur.sql`,
-- pagar cap kumulatif dari `0014`). Berkas ini yang membuktikannya masih hidup;
-- ketajamannya dibuktikan `alat/uji-mutasi-0019.py`.
--
-- Pesanan uji: eeee…0010 resto A, subtotal 54.000. Kasir (…004) batas 25.000 / 5 %,
-- owner (…002) batas 100.000 / 20 %. Cap bawaan resto sejak 0014 = 50 %.
-- ============================================================================

-- Kontrol: bawaan resto memang TIDAK mengizinkan tumpuk.
select uji.sama(
  (select p.tumpuk_diskon from public.pengaturan p
    where p.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  false, 'kontrol: bawaan resto = satu diskon per transaksi');

-- ---------------------------------------------------------------------------
-- 1. Bawaan: diskon PERTAMA diterima, diskon KEDUA ditolak walau kecil.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;

insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2000, 2000, 'diskon pertama T5-04');
select uji.sama(
  (select count(*)::integer from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1, 'diskon pertama diterima');

-- Nominal sengaja KECIL (1.000 = 1,85 % dari 54.000): jauh di dalam batas izin
-- kasir DAN di dalam cap resto, jadi yang menahan benar-benar aturan "satu diskon".
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 1000, 1000, 'diskon kedua T5-04')$$,
  'Resto ini hanya mengizinkan satu diskon per transaksi',
  'diskon KEDUA ditolak saat tumpuk belum diizinkan (walau nilainya kecil & di dalam batas izin)');

reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 2. Owner menyalakan tumpuk → diskon kedua boleh.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 1000, 1000, 'diskon kedua sah');
select uji.sama(
  (select coalesce(sum(d.nilai), 0)::integer from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  3000, 'dengan tumpuk menyala, dua diskon menumpuk jadi 3.000');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 3. Cap PERSEN ditegakkan pada TOTAL, bukan per baris.
--    Cap diturunkan ke 10 % (= 5.400). Sudah ada 3.000; tambahan 3.000 membuat
--    total 6.000 > 5.400 → WAJIB ditolak, padahal 3.000 sendiri masih di bawah cap.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set batas_maks_potongan_persen = 10
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2500, 2500, 'pecahan menembus cap')$$,
  'melebihi batas maks potongan resto',
  'cap persen dihitung KUMULATIF: baris yang sendirinya kecil (2.500 = 4,6 persen, lolos batas izin kasir) tetap ditolak bila totalnya menembus cap');

-- Tambahan yang membuat total TEPAT di cap (3.000 + 2.400 = 5.400) tetap diterima:
-- pagar tidak boleh memblokir yang sah.
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 2400, 2400, 'pas di cap');
select uji.sama(
  (select coalesce(sum(d.nilai), 0)::integer from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  5400, 'total diskon boleh mencapai cap persis (10 persen dari 54.000 = 5.400)');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 4. Cap NOMINAL juga ditegakkan (bukan hanya cap persen).
--    Cap persen dilonggarkan ke 50 %, cap nominal dipasang 6.000.
--    Sudah 5.400; tambahan 1.000 → 6.400 > 6.000 → ditolak.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set batas_maks_potongan_persen = 50, batas_maks_potongan_nominal = 6000
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 1000, 1000, 'menembus cap nominal')$$,
  'melebihi batas maks potongan resto',
  'cap NOMINAL resto ditegakkan pada total, bukan hanya cap persen');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 5. Total diskon tidak boleh melebihi subtotal (pesanan tidak bisa minus).
--    Satu baris besar akan lebih dulu ditahan pagar BATAS IZIN (owner pun berbatas
--    20 % = 10.800), jadi pagar subtotal tidak akan pernah tersentuh dengan cara itu.
--    Supaya yang teruji benar-benar aturan subtotal, keadaan dibuat selonggar
--    mungkin yang masih sah — tumpuk menyala, cap resto 100 % — lalu owner menambah
--    diskon BERTAHAP dengan nilai yang masing-masing di dalam batas izinnya.
--    Yang akhirnya menahan harus aturan TOTAL DI ATAS SUBTOTAL.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set tumpuk_diskon = true, batas_maks_potongan_persen = 100, batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

do $$
declare
  i       integer;
  v_pesan text;
begin
  -- 10.000 = 18,5 % dari 54.000 → di dalam batas owner (100.000 / 20 %).
  for i in 1..10 loop
    begin
      insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 10000, 10000,
              'gelombang subtotal ' || i);
    exception when others then
      v_pesan := sqlerrm;
      exit;
    end;
  end loop;
  perform uji.harap(
    v_pesan like 'Total diskon%melebihi subtotal%',
    'yang menahan gelombang diskon adalah ATURAN SUBTOTAL, bukan izin per baris (pesan: '
      || coalesce(v_pesan, '(tidak ada yang menahan — penjaga subtotal tumpul!)') || ')'
  );
end $$;

select uji.harap(
  (select coalesce(sum(d.nilai), 0)::integer from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010')
  <= (select p.subtotal from public.pesanan p
       where p.id = 'eeee0000-0000-0000-0000-000000000010'),
  'total diskon tidak pernah melampaui subtotal (pesanan tidak bisa jadi minus)');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 6. Tumpuk dimatikan lagi → aturan satu-diskon berlaku kembali.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set tumpuk_diskon = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, persen, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', null, 500, 500, 'sesudah tumpuk dimatikan')$$,
  'Resto ini hanya mengizinkan satu diskon per transaksi',
  'mematikan tumpuk mengembalikan aturan satu diskon per transaksi');
reset role;
select uji.klaim(null);
