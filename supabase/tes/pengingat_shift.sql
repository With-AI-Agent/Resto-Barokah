-- ===========================================================================
-- Uji SQL: Pengingat Shift Belum Ditutup (T7-05 — PRD M7 Kasus Tepi)
--
-- Cakupan:
-- 1. Penanda shift melewati tengah malam (false saat normal, true saat lewat hari).
-- 2. Rekaman catatan_audit aksi 'shift_melewati_tengah_malam' bagi laporan owner.
-- 3. Pemicu trg_shift_kas_tengah_malam pada UPDATE shift_kas.
-- 4. View public.laporan_shift_menggantung untuk pemantauan shift terbuka.
-- 5. Isolasi multi-tenant pada view laporan_shift_menggantung (security_invoker).
-- 6. Konfigurasi jam_tutup pada public.pengaturan.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Persiapan data uji
-- ---------------------------------------------------------------------------
create temp table _t_shift_049 (
  shift_id uuid,
  shift_kemarin_id uuid
);
grant all on _t_shift_049 to authenticated;

-- Kasir Rina (Resto 1, Cabang 1)
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Buka shift kasir normal hari ini
select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_catatan    := 'Shift pagi hari ini'
);

insert into _t_shift_049 (shift_id)
select id
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'
   and status = 'terbuka'
 limit 1;

reset role;

-- ---------------------------------------------------------------------------
-- 2. Kasus Normal: Tutup shift di hari yang sama -> melewati_tengah_malam = false
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.tutup_shift(
  p_shift_id       := (select shift_id from _t_shift_049),
  p_uang_fisik     := 100000,
  p_alasan_selisih := null,
  p_catatan        := 'Tutup shift tepat waktu hari yang sama'
);

reset role;

select uji.harap(
  (select melewati_tengah_malam from public.shift_kas where id = (select shift_id from _t_shift_049)) = false,
  'Shift ditutup di hari yang sama: melewati_tengah_malam = false'
);

select uji.harap(
  (select count(*) from public.catatan_audit where entitas_id = (select shift_id from _t_shift_049) and aksi = 'shift_melewati_tengah_malam') = 0,
  'Shift normal: tidak ada rekaman audit shift_melewati_tengah_malam'
);

-- ---------------------------------------------------------------------------
-- 3. Kasus Menggantung Lewat Hari: Shift dibuka kemarin belum ditutup
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.buka_shift(
  p_modal_awal := 150000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001',
  p_catatan    := 'Shift yang lupa ditutup semalam'
);

update _t_shift_049
   set shift_kemarin_id = (
     select id from public.shift_kas
      where dibuka_oleh = '90000000-0000-0000-0000-000000000004'
        and status = 'terbuka'
      limit 1
   );

reset role;

-- Simulasikan shift dibuka kemarin (2 hari lalu / kemarin pagi)
-- Nonaktifkan trigger penjaga sementara untuk simulasi data masa lalu
alter table public.shift_kas disable trigger trg_shift_kas_jaga;
update public.shift_kas
   set dibuka_pada = now() - interval '26 hours',
       melewati_tengah_malam = false
 where id = (select shift_kemarin_id from _t_shift_049);
alter table public.shift_kas enable trigger trg_shift_kas_jaga;

-- Pemicu picu_shift_kas_melewati_tengah_malam otomatis menandai saat UPDATE biasa
update public.shift_kas
   set catatan = 'Pembaruan catatan operasional shift'
 where id = (select shift_kemarin_id from _t_shift_049);

select uji.harap(
  (select melewati_tengah_malam from public.shift_kas where id = (select shift_kemarin_id from _t_shift_049)) = true,
  'Pemicu picu_shift_kas_melewati_tengah_malam otomatis menandai melewati_tengah_malam = true saat shift diperbarui'
);

-- ---------------------------------------------------------------------------
-- 4. View public.laporan_shift_menggantung mendeteksi shift menggantung
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (select count(*) from public.laporan_shift_menggantung where shift_id = (select shift_kemarin_id from _t_shift_049)) = 1,
  'View laporan_shift_menggantung mendeteksi shift terbuka'
);

select uji.harap(
  (select tingkat_peringatan from public.laporan_shift_menggantung where shift_id = (select shift_kemarin_id from _t_shift_049)) = 'melewati_tengah_malam',
  'Tingkat peringatan view mendeteksi melewati_tengah_malam'
);

select uji.harap(
  (select melewati_tengah_malam from public.laporan_shift_menggantung where shift_id = (select shift_kemarin_id from _t_shift_049)) = true,
  'Kolom melewati_tengah_malam pada view bernilai true'
);

reset role;

-- ---------------------------------------------------------------------------
-- 5. Isolasi Multi-Tenant pada View laporan_shift_menggantung
-- ---------------------------------------------------------------------------
-- Login sebagai staf resto 2 (Budi, Warung Bandung)
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;

select uji.harap(
  (select count(*) from public.laporan_shift_menggantung where shift_id = (select shift_kemarin_id from _t_shift_049)) = 0,
  'Isolasi multi-tenant: Resto 2 tidak bisa melihat shift menggantung Resto 1'
);

reset role;

-- ---------------------------------------------------------------------------
-- 6. Tutup shift yang melewati tengah malam -> penanda & catatan audit kekal
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.tutup_shift(
  p_shift_id       := (select shift_kemarin_id from _t_shift_049),
  p_uang_fisik     := 150000,
  p_alasan_selisih := null,
  p_catatan        := 'Ditutup esok harinya setelah diingatkan sistem'
);

reset role;

select uji.harap(
  (select melewati_tengah_malam from public.shift_kas where id = (select shift_kemarin_id from _t_shift_049)) = true,
  'Shift ditutup esok hari: melewati_tengah_malam = true'
);

select uji.harap(
  (select count(*) from public.catatan_audit where entitas_id = (select shift_kemarin_id from _t_shift_049) and aksi = 'shift_melewati_tengah_malam') = 1,
  'Catatan audit aksi shift_melewati_tengah_malam otomatis tercatat untuk laporan owner'
);

-- Sesudah ditutup, shift tidak lagi muncul di laporan_shift_menggantung
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (select count(*) from public.laporan_shift_menggantung where shift_id = (select shift_kemarin_id from _t_shift_049)) = 0,
  'Shift yang telah ditutup tidak lagi berada di laporan_shift_menggantung'
);

reset role;

-- ---------------------------------------------------------------------------
-- 7. Konfigurasi jam_tutup pada public.pengaturan
-- ---------------------------------------------------------------------------
select uji.harap(
  (select jam_tutup from public.pengaturan where penyewa_id = '11111111-1111-1111-1111-111111111111') = '22:00',
  'Konfigurasi bawaan jam_tutup adalah 22:00'
);

drop table _t_shift_049;
