-- ============================================================================
-- UJI: status item hanya maju satu langkah, dan pembatalan selalu berjejak
-- Temuan AUD-3 2026-09-19 F-04 (K-2), dibuktikan nyata lewat probe sesi kerja:
-- docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql
-- ============================================================================
-- Aturan terkunci: TECH_SPEC ART-4 (baru → dimasak → siap) dan PRD Aturan Bisnis 7 & 11
-- (pembatalan wajib beralasan & tercatat). Sebelum perbaikan, perangkat bisa: melahirkan
-- item berstatus `siap`, melompat `baru → siap`, memundurkan status, dan membatalkan item
-- hanya dengan mengubah statusnya — tanpa alasan, tanpa baris `pembatalan`, tanpa nilai
-- kerugian.
-- ============================================================================

-- Persiapan: satu pesanan draf (belum ke dapur) di cabang Pusat.
select uji.klaim(null);
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e8000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 998, current_date, 'dinein', 'draf', 'uji-status-item');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e8000000-0000-0000-0000-000000000101', 'e8000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 27000),
       ('e8000000-0000-0000-0000-000000000102', 'e8000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000002', 'Es Teh', 5000, 1, 5000);

-- 1. Perangkat tidak boleh MELAHIRKAN item yang sudah lanjut.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, status)
      values ('e8000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 'siap')$$,
  'selalu mulai dari status baru',
  'F-04a: item tidak boleh lahir berstatus siap'
);
select uji.harap_gagal_sebab(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, status)
      values ('e8000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 'dimasak')$$,
  'selalu mulai dari status baru',
  'F-04a: item tidak boleh lahir berstatus dimasak'
);
select uji.harap_gagal_sebab(
  $$insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, status)
      values ('e8000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 1, 'batal')$$,
  'selalu mulai dari status baru',
  'F-04a: item tidak boleh lahir langsung batal'
);

-- 2. Melompati langkah & memundurkan status → DITOLAK.
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'siap' where id = 'e8000000-0000-0000-0000-000000000101'$$,
  'hanya maju satu langkah',
  'F-04b: baru → siap (melompat) ditolak'
);
-- Jalur sah tetap terbuka: baru → dimasak → siap.
select uji.klaim('90000000-0000-0000-0000-000000000006');   -- dapur (Cabang Dua) — bukan cabangnya
set local role authenticated;
-- RLS menyaring baris cabang lain: perintahnya jalan tanpa error tetapi TIDAK mengubah apa pun
-- (bentuk yang sama dipakai uji `supabase/tes/pesanan.sql`).
update public.pesanan_item set status = 'dimasak' where id = 'e8000000-0000-0000-0000-000000000101';
select uji.sama(
  (select count(*) from public.pesanan_item pi where pi.id = 'e8000000-0000-0000-0000-000000000101'),
  0::bigint, 'dapur cabang lain bahkan tidak melihat item cabang Pusat (tersaring RLS)'
);
reset role;
select uji.klaim(null);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir cabang Pusat
set local role authenticated;
update public.pesanan_item set status = 'dimasak' where id = 'e8000000-0000-0000-0000-000000000101';
update public.pesanan_item set status = 'siap' where id = 'e8000000-0000-0000-0000-000000000101';
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e8000000-0000-0000-0000-000000000101'),
  'siap'::text, 'jalur sah baru → dimasak → siap tetap terbuka (satu langkah sekali)'
);
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'dimasak' where id = 'e8000000-0000-0000-0000-000000000101'$$,
  'hanya maju satu langkah',
  'F-04b: memundurkan status siap → dimasak ditolak'
);

-- 3. Membatalkan item dengan mengubah status → DITOLAK (harus lewat baris pembatalan).
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'batal' where id = 'e8000000-0000-0000-0000-000000000102'$$,
  'baris pembatalan resmi',
  'F-04c: status item tidak bisa diubah menjadi batal dari perangkat'
);
select uji.sama(
  (select count(*) from public.pembatalan pb where pb.pesanan_id = 'e8000000-0000-0000-0000-000000000001'),
  0::bigint, 'tidak ada jejak pembatalan untuk percobaan itu (gagal sebelum tercatat)'
);
-- 4. Jalur SAH: baris pembatalan resmi (beralasan) menandai item batal + menyimpan kerugian.
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan)
values ('e8000000-0000-0000-0000-000000000001', 'e8000000-0000-0000-0000-000000000102',
        'sebelum_dapur', 'pelanggan membatalkan Es Teh');
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e8000000-0000-0000-0000-000000000102'),
  'batal', 'pembatalan resmi menandai item batal'
);
select uji.sama(
  (select pb.nilai_kerugian from public.pembatalan pb
    where pb.pesanan_item_id = 'e8000000-0000-0000-0000-000000000102'),
  5000, 'nilai kerugian dihitung peladen dari salinan harga (5.000)'
);
-- 5. Item yang sudah batal tidak bisa "dihidupkan kembali" oleh perangkat.
select uji.harap_gagal_sebab(
  $$update public.pesanan_item set status = 'baru' where id = 'e8000000-0000-0000-0000-000000000102'$$,
  'hanya maju satu langkah',
  'F-04: item yang sudah batal tidak bisa dipulihkan dari perangkat (batal bukan status biasa)'
);
reset role;
select uji.klaim(null);
-- 6. Jalur PELADEN (peran pemilik tabel) tetap bebas memperbaiki keadaan.
update public.pesanan_item set status = 'siap'
 where id = 'e8000000-0000-0000-0000-000000000102';
select uji.sama(
  (select pi.status from public.pesanan_item pi where pi.id = 'e8000000-0000-0000-0000-000000000102'),
  'siap', 'kontrol: peran peladen tetap bisa memperbaiki keadaan data'
);
