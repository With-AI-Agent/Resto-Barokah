-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-20 H F-07
--                       (kolom non-uang pesanan bisa diubah klien SETELAH lunas/batal)
-- ============================================================================
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL — karena itu ia hidup di
-- `docs/uji/audit/probe-2026-09-21/`, bukan di `supabase/tes` (folder uji wajib hijau).
--
-- Aturan yang dilanggar (kutipan dokumen fondasi):
--   docs/TECH_SPEC.md — pesanan `lunas`/`batal` adalah JEJAK yang sudah menutup buku;
--     pembekuannya baru ditegakkan pada item & nilai uang (0015), padahal kolom jejak
--     lain (catatan, tipe, shift) masih bisa ditulis perangkat — laporan membaca jejak
--     yang tidak pernah terjadi.
--   docs/PRD.md Aturan Bisnis 7 & 11 — kejadian tercatat apa adanya; mengubah jejak
--     pesanan tertutup dari perangkat = menulis ulang sejarah.
-- ============================================================================

-- Persiapan (pemilik tabel): dua pesanan Cabang A1 + item, satu dilunaskan, satu dibatalkan.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e8000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 991, current_date, 'dinein', 'draf', 'probe-hf07-1'),
       ('e8000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 992, current_date, 'dinein', 'draf', 'probe-hf07-2');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e8000000-0000-0000-0000-000000000101', 'e8000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('e8000000-0000-0000-0000-000000000102', 'e8000000-0000-0000-0000-000000000002',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000);
-- Jalur peladen menutup keduanya (sah).
update public.pesanan set status = 'lunas', dibayar_pada = now()
 where id = 'e8000000-0000-0000-0000-000000000001';
update public.pesanan set status = 'batal', dibatalkan_pada = now(), alasan_batal = 'probe resmi'
 where id = 'e8000000-0000-0000-0000-000000000002';

-- ---------------------------------------------------------------------------
-- H F-07a: pesanan LUNAS — kasir menulis ulang jejak non-uang dari perangkat.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
update public.pesanan
   set catatan = 'catatan dikarang sesudah lunas',
       tipe    = 'takeaway',
       shift_id = 'e8000000-0000-0000-0000-0000000000ff'
 where id = 'e8000000-0000-0000-0000-000000000001';
reset role;

select uji.sama(
  (select catatan from public.pesanan where id = 'e8000000-0000-0000-0000-000000000001'),
  'catatan dikarang sesudah lunas',
  'CACAT: catatan pesanan lunas berubah dari perangkat'
);
select uji.sama(
  (select tipe from public.pesanan where id = 'e8000000-0000-0000-0000-000000000001'),
  'takeaway',
  'CACAT: tipe pesanan lunas berubah dari perangkat'
);

-- ---------------------------------------------------------------------------
-- H F-07b: pesanan BATAL — jejak alasan batal dikarang ulang dari perangkat.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
update public.pesanan
   set catatan = 'jejak batal dikarang'
 where id = 'e8000000-0000-0000-0000-000000000002';
reset role;

select uji.sama(
  (select catatan from public.pesanan where id = 'e8000000-0000-0000-0000-000000000002'),
  'jejak batal dikarang',
  'CACAT: catatan pesanan batal berubah dari perangkat'
);
