-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-19 F-04
--                       (state machine item bisa dilewati; pembatalan pra-dapur tanpa jejak)
-- ============================================================================
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL — karena itu ia hidup di
-- `docs/uji/audit/probe-2026-09-20/`, bukan di `supabase/tes` (folder uji wajib hijau).
--
-- Aturan yang dilanggar (kutipan dokumen fondasi):
--   docs/TECH_SPEC.md ART-4 — status item hanya maju `baru → dimasak → siap`; urutan itu
--     bukan hiasan, ia yang membuat dapur & kasir berbicara tentang keadaan yang sama.
--   docs/PRD.md Aturan Bisnis 7 & 11 — setiap pembatalan WAJIB beralasan dan tercatat
--     (baris `pembatalan`), bukan UPDATE status item yang bebas dari perangkat.
-- ============================================================================

-- Persiapan: pesanan baru di cabang Pusat (belum dikirim ke dapur).
select uji.klaim(null);   -- pemilik tabel menyiapkan pesanan
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e7000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 997, current_date, 'dinein', 'draf', 'probe-f04');

-- ---------------------------------------------------------------------------
-- F-04a: item LAHIR langsung `siap` (melompati baru → dimasak)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal, status)
values ('e7000000-0000-0000-0000-000000000101', 'e7000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000, 'siap');
reset role;
select uji.klaim(null);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e7000000-0000-0000-0000-000000000101'),
  'siap',
  'F-04a NYATA: item baru boleh LAHIR berstatus siap (aturan: item baru selalu baru)'
);

-- ---------------------------------------------------------------------------
-- F-04b: status MELOMPAT `baru → siap` lewat UPDATE dari perangkat
-- ---------------------------------------------------------------------------
select uji.klaim(null);
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e7000000-0000-0000-0000-000000000102', 'e7000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
update public.pesanan_item set status = 'siap'
 where id = 'e7000000-0000-0000-0000-000000000102';
reset role;
select uji.klaim(null);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e7000000-0000-0000-0000-000000000102'),
  'siap',
  'F-04b NYATA: status item boleh melompat baru → siap (aturan: harus lewat dimasak)'
);

-- ---------------------------------------------------------------------------
-- F-04c: pembatalan SEBELUM dapur tanpa baris `pembatalan` (tanpa alasan, tanpa jejak)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
update public.pesanan_item set status = 'batal'
 where id = 'e7000000-0000-0000-0000-000000000102';
reset role;
select uji.klaim(null);
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e7000000-0000-0000-0000-000000000102'),
  'batal',
  'F-04c NYATA: item dibatalkan sebelum dapur TANPA alasan & tanpa satu pun baris pembatalan'
);
select uji.sama(
  (select count(*) from public.pembatalan pb where pb.pesanan_id = 'e7000000-0000-0000-0000-000000000001'),
  0::bigint,
  'F-04c NYATA: tidak ada jejak pembatalan, tetapi status item sudah batal'
);
