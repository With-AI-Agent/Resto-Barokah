-- ============================================================================
-- UJI SQL: Laporan bulanan "siapa menyetujui apa" (PMB1-F-087 · K-3)
-- ============================================================================
-- Yang dijaga (KEAMANAN §9 butir 4 + §15 butir 3):
--   1. Diskon dengan stempel `disetujui_oleh` masuk rekap per penyetuju.
--   2. Pembatalan dengan stempel `disetujui_oleh` masuk rekap.
--   3. Filter bulan takwim bekerja (kejadian bulan lain tidak ikut).
--   4. Baris TANPA stempel persetujuan tidak dihitung (bukan PIN approval).
--   5. Kasir (tanpa lihat_laporan) DITOLAK.
--   6. Isolasi tenant: resto lain tidak melihat persetujuan resto ini, dan
--      sebaliknya.
-- Catatan jujur: cabang `voucher.pakai_disetujui_oleh` (saklar 0098) ikut
-- teruji strukturnya tetapi saklarnya bawaan MATI, jadi tidak ada baris
-- voucher di sini — cabang itu hidup otomatis begitu Lee menyalakan 0098.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/laporan_persetujuan_pin.sql
-- Migrasi berlaku: 0104_laporan_persetujuan_pin_bulanan.sql
-- ============================================================================

-- Penyiapan (jalur pemilik tabel).
-- Pemilik tenant B untuk uji isolasi dua arah (pengguna.id mengacu auth.users).
insert into auth.users (id, email)
values ('f0870000-0000-0000-0000-0000000000fe', 'owner.b@contoh.test')
on conflict (id) do nothing;
insert into public.pengguna (id, penyewa_id, nama, email, peran)
values ('f0870000-0000-0000-0000-0000000000fe', '22222222-2222-2222-2222-222222222222', 'Bu Warung', 'owner.b@contoh.test', 'owner_pusat')
on conflict (id) do nothing;
insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('f0870000-0000-0000-0000-0000000000fe', 'b1b1b1b1-0000-0000-0000-000000000001')
on conflict do nothing;

-- Pesanan uji tenant A (dua) & tenant B (satu).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, subtotal, pajak, service, total, kunci_idempoten)
values
  ('f0870000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 901, '2026-10-01', 'dinein', 'dikirim', 40000, 4000, 2000, 46000, 'f087-pesanan-a-okt'),
  ('f0870000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 902, '2026-10-02', 'dinein', 'dikirim', 30000, 3000, 1500, 34500, 'f087-pesanan-a-okt-2'),
  ('f0870000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 903, '2026-09-15', 'dinein', 'dikirim', 40000, 4000, 2000, 46000, 'f087-pesanan-a-sep'),
  ('f0870000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 904, '2026-10-05', 'dinein', 'dikirim', 30000, 3000, 1500, 34500, 'f087-pesanan-a-polos'),
  ('f0870000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'a1a1a1a1-0000-0000-0000-000000000001', 905, '2026-10-05', 'dinein', 'dikirim', 30000, 3000, 1500, 34500, 'f087-pesanan-a-void'),
  ('f0870000-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'b1b1b1b1-0000-0000-0000-000000000001', 71,  '2026-10-03', 'dinein', 'dikirim', 20000, 2000, 1000, 23000, 'f087-pesanan-b-okt');

-- Kupon bukti PIN atasan (PR-04): stempel disetujui_oleh wajib disertai baris
-- percobaan_pin penyetuju untuk pesanan itu, segar (< 5 menit), belum terpakai.
insert into public.percobaan_pin (pengguna_id, berhasil, aksi, pesanan_id, waktu)
values
  ('90000000-0000-0000-0000-000000000002', true, 'beri_diskon', 'f0870000-0000-0000-0000-000000000001', now()),
  ('90000000-0000-0000-0000-000000000002', true, 'beri_diskon', 'f0870000-0000-0000-0000-000000000002', now()),
  ('90000000-0000-0000-0000-000000000002', true, 'beri_diskon', 'f0870000-0000-0000-0000-000000000004', now()),
  ('f0870000-0000-0000-0000-0000000000fe', true, 'beri_diskon', 'f0870000-0000-0000-0000-000000000003', now());

-- Pemicu diskon memeriksa identitas SESI (bukan hanya baris), jadi fixture
-- disisipkan dengan klaim pelaku yang sah: kasir A untuk diskon kecil.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- Diskon manual Oktober ×2, disetujui owner (Bu Oasis). Nilai kecil = di bawah
-- batas kasir sekalipun, tapi STEMPELNYA yang masuk laporan.
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, disetujui_oleh, waktu)
values
  ('f0870000-0000-0000-0000-000000000001', 'manual', 1500, 1500, 'uji f087 diskon 1', '90000000-0000-0000-0000-000000000004', '90000000-0000-0000-0000-000000000002', '2026-10-04 10:00:00+07'),
  ('f0870000-0000-0000-0000-000000000002', 'manual', 1000, 1000, 'uji f087 diskon 2', '90000000-0000-0000-0000-000000000004', '90000000-0000-0000-0000-000000000002', '2026-10-05 11:00:00+07');

-- Diskon September — di luar bulan laporan, wajib tersaring.
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, disetujui_oleh, waktu)
values ('f0870000-0000-0000-0000-000000000004', 'manual', 1200, 1200, 'uji f087 bulan lalu', '90000000-0000-0000-0000-000000000004', '90000000-0000-0000-0000-000000000002', '2026-09-15 09:00:00+07');

-- Diskon TANPA stempel persetujuan — tidak boleh masuk laporan.
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, waktu)
values ('f0870000-0000-0000-0000-000000000005', 'manual', 900, 900, 'uji f087 tanpa persetujuan', '90000000-0000-0000-0000-000000000004', '2026-10-05 12:00:00+07');

-- Pembatalan dengan stempel persetujuan.
insert into public.pembatalan (pesanan_id, tahap, pelaku_id, disetujui_oleh, alasan, nilai_kerugian, waktu)
values ('f0870000-0000-0000-0000-000000000006', 'sebelum_dapur', '90000000-0000-0000-0000-000000000004', '90000000-0000-0000-0000-000000000002', 'uji f087 void', 30000, '2026-10-05 13:00:00+07');

-- Diskon tenant B untuk isolasi dua arah (klaim kasir B).
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, pelaku_id, disetujui_oleh, waktu)
values ('f0870000-0000-0000-0000-000000000003', 'manual', 500, 500, 'uji f087 tenant b', '90000000-0000-0000-0000-000000000007', 'f0870000-0000-0000-0000-0000000000fe', '2026-10-05 14:00:00+07');
reset role;
select uji.klaim(null);

-- 1. Owner tenant A melihat rekap Oktober: diskon manual ×2 total 9.000, pembatalan ×1.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select jumlah from public.laporan_persetujuan_pin('2026-10-15'::date) where jenis_persetujuan = 'diskon manual'),
  2::bigint,
  'F-087: dua diskon distempel owner terhitung; yang September & tanpa stempel tidak ikut'
);
select uji.sama(
  (select total_nilai from public.laporan_persetujuan_pin('2026-10-15'::date) where jenis_persetujuan = 'diskon manual'),
  2500::bigint,
  'F-087: total nilai diskon persetujuan = 2.500'
);
select uji.sama(
  (select penyetuju_nama from public.laporan_persetujuan_pin('2026-10-15'::date) where jenis_persetujuan = 'diskon manual'),
  'Bu Oasis',
  'F-087: nama penyetuju tampil (siapa)'
);
select uji.sama(
  (select jumlah from public.laporan_persetujuan_pin('2026-10-15'::date) where jenis_persetujuan like 'pembatalan%'),
  1::bigint,
  'F-087: satu pembatalan distempel terhitung'
);

-- 2. Baris tanpa stempel & baris tenant B tidak bocor ke tenant A.
select uji.sama(
  (select count(*)::bigint from public.laporan_persetujuan_pin('2026-10-15'::date)),
  2::bigint,
  'F-087: tepat 2 baris rekap (diskon + pembatalan) — tanpa stempel & lintas tenant tersaring'
);

-- 3. Kasir ditolak.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$select * from public.laporan_persetujuan_pin()$$,
  'Anda tidak berwenang melihat laporan persetujuan\.',
  'F-087: kasir DITOLAK memanggil laporan_persetujuan_pin');

-- 4. Isolasi dua arah: owner tenant B hanya melihat baris tenant B.
reset role;
select uji.klaim('f0870000-0000-0000-0000-0000000000fe');
set local role authenticated;
select uji.sama(
  (select jumlah from public.laporan_persetujuan_pin('2026-10-15'::date) where jenis_persetujuan = 'diskon manual'),
  1::bigint,
  'F-087: tenant B hanya melihat persetujuannya sendiri'
);

reset role;
select uji.klaim(null);
