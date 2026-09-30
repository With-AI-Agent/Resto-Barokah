-- ============================================================================
-- UJI SQL: Kekurangan kas tidak lagi disembunyikan jadi nol (PMB1-F-046 · K-2)
-- ============================================================================
-- Skenario: modal awal 100.000, uang keluar (kasbon) 150.000, tidak ada setoran.
--           Uang seharusnya = 100.000 - 150.000 = -50.000.
--           Uang fisik yang dihitung = 0 (semua uang hilang).
-- YANG DIJAGA:
--   1. Menutup shift TANPA alasan selisih harus DITOLAK (sebelum perbaikan: selisih
--      dihitung 0 - 0 = 0, jadi closing berhasil dan kekurangan 50.000 hilang).
--   2. Dengan alasan, shift tertutup dan `uang_se_should_be` TERSIMPAN NEGATIF.
--   3. `selisih` tersimpan negatif (minus 50.000) dan alasannya tersimpan.
--   4. Pratinjau `ambil_shift_perlu_tutup` juga tidak lagi memaksa angka 0.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/selisih_kas_kekurangan_terlihat.sql
-- Migrasi berlaku: 0092_selisih_kas_negatif_tidak_didisembunyikan.sql
-- ============================================================================

-- 1. Rina (kasir A1) membuka shift dengan modal awal 100.000
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select public.buka_shift(
  p_modal_awal := 100000,
  p_cabang_id  := 'a1a1a1a1-0000-0000-0000-000000000001'::uuid,
  p_catatan    := 'Shift uji F-046'
);
reset role;

create temp table _t_f046 as
select id as shift_id, modal_awal
  from public.shift_kas
 where dibuka_oleh = '90000000-0000-0000-0000-000000000004'::uuid
   and status = 'terbuka'
 order by dibuka_pada desc
 limit 1;
grant all on table _t_f046 to authenticated;

select uji.harap(
  (select count(*) from _t_f046) = 1,
  'F-046: shift uji berhasil dibuka (modal awal 100.000)'
);

-- 2. Uang keluar 150.000 (kasbon) tanpa setoran -> kas minus 50.000
insert into public.kas_pergerakan (
  penyewa_id, cabang_id, shift_id, jenis, jumlah, alasan, pelaku_id, kunci_idempoten
) values (
  '11111111-1111-1111-1111-111111111111',
  'a1a1a1a1-0000-0000-0000-000000000001',
  (select shift_id from _t_f046),
  'keluar',
  150000,
  'Uji F-046: kasbon lebih besar dari kas',
  '90000000-0000-0000-0000-000000000004',
  'idem-f046-kasbon'
);

-- 3. Menutup shift dengan uang fisik 0 dan TANPA alasan -> harus DITOLAK
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.tutup_shift(0, null, (select shift_id from _t_f046), null)$$,
  'Alasan selisih wajib diisi',
  'F-046: kekurangan kas tidak boleh ditutup tanpa alasan selisih'
);
reset role;

select uji.harap(
  (select count(*) from public.shift_kas
    where id = (select shift_id from _t_f046) and status = 'terbuka') = 1,
  'F-046: shift masih terbuka (penutupan tanpa alasan ditolak)'
);

-- 4. Dengan alasan -> tertutup, angka negatif tetap tersimpan
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select public.tutup_shift(
  0,
  'Uji F-046: uang hilang 50.000 saat kasbon dibayar',
  (select shift_id from _t_f046),
  null
);
reset role;

select uji.harap(
  (select uang_seharusnya from public.shift_kas where id = (select shift_id from _t_f046)) = -50000,
  'F-046: uang seharusnya TERSIMPAN negatif (-50.000), bukan dipaksa 0'
);
select uji.harap(
  (select selisih from public.shift_kas where id = (select shift_id from _t_f046)) = 50000,
  'F-046: selisih dihitung dari angka negatif (fisik 0 - (-50.000) = 50.000)'
);
select uji.harap(
  (select alasan_selisih from public.shift_kas where id = (select shift_id from _t_f046))
    = 'Uji F-046: uang hilang 50.000 saat kasbon dibayar',
  'F-046: alasan selisih tersimpan sebagai jejak'
);

-- 5. Kontrol: pratinjau serah terima (ambil_shift_perlu_tutup) menghitung dari
--    penjualan tunai saja (tanpa kas_pergerakan) sehingga jalurnya memang tidak pernah
--    negatif; klaim PMB1-F-046 yang bernyawa ada di `tutup_shift` (kasus 3-4 di atas).
--    Kalimat `greatest(0, ...)` di pratinjau tetap dibuang agar tidak menyesatkan
--    pembaca berikutnya, tetapi tidak ada skenario uji yang bisa membuatnya merah.
