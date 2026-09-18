-- ============================================================================
-- UJI: ARAH STOK DITENTUKAN JENIS — juga pada INSERT LANGSUNG (bukan hanya catat_stok)
-- Menutup temuan review putaran13 #2 PR-02 (K-3): perbaikan 0012 menambal RPC
-- `catat_stok`, sedangkan policy INSERT langsung tetap menerima arah bertentangan:
-- jenis='keluar' + jumlah=+7 membuat saldo NAIK sementara buku besar menyebut KELUAR.
-- ============================================================================
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (izin ubah_stok)
set local role authenticated;
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  20, 'kontrol: saldo awal Beras 20'
);

-- INSERT langsung (bukan RPC) dengan arah bertentangan.
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan, pelaku_id)
values ('beef1000-0000-0000-0000-000000000001', 'keluar', 7, 'insert langsung arah salah', '90000000-0000-0000-0000-000000000006');
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  13, 'INSERT langsung (keluar, +7) MENGURANGI saldo: 20 → 13'
);
select uji.sama(
  (select sp.jumlah::int from public.stok_pergerakan sp where sp.alasan = 'insert langsung arah salah'),
  -7, 'baris buku besar menyimpan −7 (jenis dan tanda tidak lagi bertentangan)'
);

-- Kebalikannya: masuk dengan tanda minus tetap menambah.
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan, pelaku_id)
values ('beef1000-0000-0000-0000-000000000001', 'masuk', -3, 'insert langsung masuk minus', '90000000-0000-0000-0000-000000000006');
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  16, 'INSERT langsung (masuk, −3) MENAMBAH saldo: 13 → 16'
);

-- Opname/koreksi tetap dua arah (memang delta), tapi tidak boleh nol.
insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan, pelaku_id)
values ('beef1000-0000-0000-0000-000000000001', 'opname', -6, 'opname kurang 6', '90000000-0000-0000-0000-000000000006');
select uji.sama(
  (select s.jumlah::int from public.stok_bahan s where s.id = 'beef1000-0000-0000-0000-000000000001'),
  10, 'opname boleh mengurangi (10)'
);
select uji.harap_gagal(
  $$insert into public.stok_pergerakan (stok_bahan_id, jenis, jumlah, alasan, pelaku_id)
      values ('beef1000-0000-0000-0000-000000000001','koreksi', 0, 'koreksi nol', '90000000-0000-0000-0000-000000000006')$$,
  'pergerakan koreksi bernilai nol ditolak (tidak ada perubahan yang dicatat)'
);
reset role;
select uji.klaim(null);
