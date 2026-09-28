-- ============================================================================
-- UJI SQL: Akhiri Sesi & Penanganan Perangkat Hilang (T10-06 / PRD M12)
--
-- Memverifikasi:
--   1. public.daftar_sesi() menghormati RLS & otorisasi:
--      - Staf kasir hanya melihat sesinya sendiri.
--      - Owner pusat melihat seluruh sesi aktif pegawainya.
--      - Tidak ada kebocoran sesi antar penyewa.
--   2. public.akhiri_sesi(session_id, alasan):
--      - Staf biasa dilarang mengakhiri sesi staf lain.
--      - Owner bisa mengakhiri sesi siapa pun di restonya.
--      - Jejak audit tercatat dengan rapi.
--      - Sesi yang dicabut seketika ditolak oleh sesi_masih_aktif().
--   3. public.keluar_semua_perangkat(pengguna_id, alasan):
--      - Memutus seluruh sesi aktif pengguna target.
--      - Jejak audit tercatat di public.catatan_audit.
--   4. public.tandai_perangkat_hilang(perangkat_id, alasan):
--      - Staf tanpa kelola_pegawai ditolak (FORBIDDEN).
--      - Owner menandai hilang: status perangkat = 'hilang', aktif = false.
--      - Seluruh sesi aktif pada perangkat tersebut seketika dicabut.
--      - Jejak audit tercatat di catatan_audit.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Penyiapan Sesi Uji
-- ---------------------------------------------------------------------------
reset role;

-- Kasir A1 mengikat sesi pada hp-kasir
select uji.klaim('90000000-0000-0000-0000-000000000004');
select public.ikat_sesi_perangkat(
  'sess_kasir_01',
  'de000000-0000-0000-0000-000000000003',
  'kunci-uji-hp-kasir-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

-- Pelayan A mengikat sesi pada hp-pelayan
select uji.klaim('90000000-0000-0000-0000-000000000005');
select public.ikat_sesi_perangkat(
  'sess_pelayan_01',
  'de000000-0000-0000-0000-000000000004',
  'kunci-uji-hp-pelayan-0123456789',
  '90000000-0000-0000-0000-000000000005'
);

-- Kasir B1 mengikat sesi pada hp-b1 (Penyewa B)
select uji.klaim('90000000-0000-0000-0000-000000000007');
select public.ikat_sesi_perangkat(
  'sess_kasir_b1_01',
  'de000000-0000-0000-0000-000000000008',
  'kunci-uji-hp-b1-0123456789',
  '90000000-0000-0000-0000-000000000007'
);

-- ---------------------------------------------------------------------------
-- 2. Uji public.daftar_sesi()
-- ---------------------------------------------------------------------------
-- Kasir A1 hanya bisa melihat sesinya sendiri
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select count(*)::int from public.daftar_sesi()),
  1,
  'Kasir A1 hanya melihat 1 sesi miliknya sendiri'
);

select uji.sama(
  (select session_id from public.daftar_sesi() limit 1),
  'sess_kasir_01',
  'Session ID yang terlihat oleh kasir A1 adalah sess_kasir_01'
);

-- Owner A melihat seluruh sesi aktif di Resto A (tidak termasuk Resto B)
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select count(*)::int from public.daftar_sesi() where status = 'aktif'),
  2,
  'Owner A melihat 2 sesi aktif (kasir A1 & pelayan A)'
);

select uji.sama(
  (select count(*)::int from public.daftar_sesi() where session_id = 'sess_kasir_b1_01'),
  0,
  'Sesi penyewa B tidak pernah terlihat oleh Owner A (isolasi penyewa)'
);

-- ---------------------------------------------------------------------------
-- 3. Uji public.akhiri_sesi()
-- ---------------------------------------------------------------------------
-- Kasir A1 mencoba mengakhiri sesi Pelayan A -> FORBIDDEN
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.akhiri_sesi('sess_pelayan_01', 'Usil cabut sesi teman')->>'berhasil')::boolean),
  false,
  'Kasir A1 ditolak saat mencoba mengakhiri sesi orang lain'
);

select uji.sama(
  (select public.akhiri_sesi('sess_pelayan_01', 'Usil cabut sesi teman')->>'kode'),
  'FORBIDDEN',
  'Kode balasan FORBIDDEN saat kasir mencoba cabut sesi orang lain'
);

-- Owner A mengakhiri sesi Pelayan A
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select (public.akhiri_sesi('sess_pelayan_01', 'Shift pelayan telah berakhir')->>'berhasil')::boolean),
  true,
  'Owner A berhasil mengakhiri sesi Pelayan A'
);

-- Pastikan status sesi berubah menjadi 'dicabut'
select uji.sama(
  (select status from public.sesi_perangkat where session_id = 'sess_pelayan_01'),
  'dicabut',
  'Status sesi Pelayan A di database menjadi dicabut'
);

-- Jejak audit tercatat
select uji.sama(
  (select count(*)::int from public.catatan_audit where aksi = 'akhiri_sesi' and entitas_id = '90000000-0000-0000-0000-000000000005'),
  1,
  'Catatan audit untuk akhiri_sesi pelayan tercatat'
);

-- Pelayan A langsung kehilangan akses
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000005', '{"session_id": "sess_pelayan_01"}'::jsonb);
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'sesi_masih_aktif() menghasilkan false untuk sesi yang dicabut'
);

-- ---------------------------------------------------------------------------
-- 4. Uji public.keluar_semua_perangkat()
-- ---------------------------------------------------------------------------
reset role;
-- Kasir A1 mengikat 2 sesi
select uji.klaim('90000000-0000-0000-0000-000000000004');
select public.ikat_sesi_perangkat(
  'sess_kasir_02a',
  'de000000-0000-0000-0000-000000000003',
  'kunci-uji-hp-kasir-0123456789',
  '90000000-0000-0000-0000-000000000004'
);
select public.ikat_sesi_perangkat(
  'sess_kasir_02b',
  'de000000-0000-0000-0000-000000000007',
  'kunci-uji-hp-cadangan-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

-- Owner memutus seluruh sesi kasir A1
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select (public.keluar_semua_perangkat('90000000-0000-0000-0000-000000000004', 'Karyawan dilaporkan keluar shift')->>'berhasil')::boolean),
  true,
  'Owner A berhasil keluar_semua_perangkat untuk Kasir A1'
);

select uji.sama(
  (select count(*)::int from public.sesi_perangkat where pengguna_id = '90000000-0000-0000-0000-000000000004' and status = 'aktif'),
  0,
  'Seluruh sesi Kasir A1 sekarang tidak ada yang aktif'
);

select uji.sama(
  (select count(*)::int from public.catatan_audit where aksi = 'keluar_semua_perangkat' and entitas_id = '90000000-0000-0000-0000-000000000004'),
  1,
  'Catatan audit untuk keluar_semua_perangkat tercatat'
);

-- ---------------------------------------------------------------------------
-- 5. Uji public.tandai_perangkat_hilang()
-- ---------------------------------------------------------------------------
-- Ikat sesi kasir di hp-atasan
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004');
select public.ikat_sesi_perangkat(
  'sess_kasir_hilang_01',
  'de000000-0000-0000-0000-000000000006',
  'kunci-uji-hp-atasan-0123456789',
  '90000000-0000-0000-0000-000000000004'
);

-- Kasir A1 mencoba menandai perangkat hilang -> FORBIDDEN
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  (select (public.tandai_perangkat_hilang('de000000-0000-0000-0000-000000000006', 'Tablet hilang')->>'berhasil')::boolean),
  false,
  'Kasir A1 ditolak menandai perangkat hilang (FORBIDDEN)'
);

-- Owner menandai hp-atasan hilang
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select (public.tandai_perangkat_hilang('de000000-0000-0000-0000-000000000006', 'Tablet kasir hilang di meja 5')->>'berhasil')::boolean),
  true,
  'Owner menandai perangkat hilang berhasil'
);

-- Periksa status perangkat
select uji.sama(
  (select status from public.perangkat where id = 'de000000-0000-0000-0000-000000000006'),
  'hilang',
  'Status perangkat di database berubah menjadi hilang'
);

select uji.sama(
  (select aktif from public.perangkat where id = 'de000000-0000-0000-0000-000000000006'),
  false,
  'Perangkat hilang ditandai aktif = false'
);

-- Periksa sesi pada perangkat hilang langsung dicabut
select uji.sama(
  (select status from public.sesi_perangkat where session_id = 'sess_kasir_hilang_01'),
  'dicabut',
  'Sesi kasir pada perangkat hilang seketika dicabut'
);

-- Periksa jejak audit tercatat
select uji.sama(
  (select count(*)::int from public.catatan_audit where aksi = 'tandai_perangkat_hilang' and entitas_id = 'de000000-0000-0000-0000-000000000006'),
  1,
  'Catatan audit untuk tandai_perangkat_hilang tercatat'
);

-- Verifikasi pemanggil dari perangkat hilang seketika diblokir oleh sesi_masih_aktif
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000004', '{"session_id": "sess_kasir_hilang_01", "perangkat_id": "de000000-0000-0000-0000-000000000006"}'::jsonb);
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'sesi_masih_aktif() menolak permintaan dari perangkat yang ditandai hilang'
);

select uji.sama(
  public.penyewa_saya(),
  null,
  'penyewa_saya() menjadi null untuk perangkat yang ditandai hilang'
);

-- RLS menolak akses pesanan seketika
select uji.sama(
  (select count(*)::int from public.pesanan),
  0,
  'RLS menolak akses data seketika bagi perangkat hilang'
);
