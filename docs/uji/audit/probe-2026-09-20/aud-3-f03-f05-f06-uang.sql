-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-19 (laporan __01a0bbd2)
--                       putaran KEDUA: F-03, F-05, F-06 (tiga temuan K-2)
-- ============================================================================
-- Tujuan: membuktikan SENDIRI (bukan mempercayai laporan) apakah tiga temuan K-2
-- pada jalur uang & jejak benar-benar ada di kode sekarang.
--
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL — karena itu ia hidup di
-- `docs/uji/audit/probe-2026-09-20/`, bukan di `supabase/tes` (folder uji wajib hijau).
--
-- Aturan yang dilanggar (kutipan dokumen fondasi):
--   docs/TECH_SPEC.md §5 & §10 — hanya metode bayar AKTIF dari pengaturan yang boleh dipilih;
--     pilihan metode adalah pengaturan pemilik, bukan kesempatan kasir.
--   docs/PRD.md Aturan Bisnis 7 & 11 — pembatalan berjejak satu kali (idempoten) dan tagihan
--     yang sudah dibayar tidak ditulis ulang; stempel kejadian berasal dari jalur peladen.
--   docs/TECH_SPEC.md §7 — jejak pelaku/stempel kejadian tidak boleh dikarang perangkat.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- F-03: metode bayar yang sudah DINONAKTIFKAN masih bisa dipakai kasir
-- ---------------------------------------------------------------------------
-- Pemilik (bukan pegawai) menonaktifkan QRIS di restonya.
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner
set local role authenticated;
update public.metode_bayar set aktif = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'QRIS';
reset role;
select uji.klaim(null);
select uji.sama(
  (select mb.aktif from public.metode_bayar mb
    where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS'),
  false, 'probe F-03: QRIS sudah dinonaktifkan pemilik'
);

-- Kasir mencoba membayar memakai metode yang sudah dinonaktifkan itu.
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
insert into public.pembayaran (pesanan_id, metode_id, jumlah, referensi, kunci_idempoten)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 1000, 'REF-NONAKTIF', 'probe-f03'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'QRIS';
reset role;
select uji.klaim(null);

select uji.sama(
  (select count(*) from public.pembayaran pb where pb.kunci_idempoten = 'probe-f03'),
  1::bigint,
  'F-03 NYATA: pembayaran dengan metode NONAKTIF diterima (aturan: metode nonaktif tidak boleh dipakai)'
);

-- ---------------------------------------------------------------------------
-- F-05: baris pembatalan tidak idempoten — kiriman ulang menggandakan dampak
-- ---------------------------------------------------------------------------
-- Pesanan uji SENDIRI yang BELUM dikirim ke dapur (tahap sebelum_dapur — tidak butuh PIN).
-- Justru inilah kejadian nyata: kasir menekan "batal" dua kali dengan cepat, atau perangkat
-- mengirim ulang antrean offline.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e4000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 982, current_date, 'dinein', 'draf', 'probe-f05');
insert into public.pesanan_item (id, pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e4000000-0000-0000-0000-000000000101', 'e4000000-0000-0000-0000-000000000001',
        'beef0000-0000-0000-0000-000000000001', 'Nasi Goreng', 27000, 2, 54000);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat (izin void_sebelum_dapur)
set local role authenticated;

-- Kiriman pertama (aksi sah).
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan, bahan_terbuang)
values ('e4000000-0000-0000-0000-000000000001', 'e4000000-0000-0000-0000-000000000101',
        'sebelum_dapur', 'probe F-05 pembatalan sah', false);

-- Kiriman ULANG baris yang sama persis (klik ganda / antrean offline).
insert into public.pembatalan (pesanan_id, pesanan_item_id, tahap, alasan, bahan_terbuang)
values ('e4000000-0000-0000-0000-000000000001', 'e4000000-0000-0000-0000-000000000101',
        'sebelum_dapur', 'probe F-05 pembatalan sah', false);
reset role;
select uji.klaim(null);

select uji.sama(
  (select count(*) from public.pembatalan pb
    where pb.pesanan_id = 'e4000000-0000-0000-0000-000000000001'),
  2::bigint,
  'F-05 NYATA: pembatalan yang sama diterima DUA KALI (aturan: satu aksi = satu jejak / idempoten)'
);
select uji.sama(
  (select coalesce(sum(pb.nilai_kerugian), 0) from public.pembatalan pb
    where pb.pesanan_id = 'e4000000-0000-0000-0000-000000000001'),
  108000::bigint,
  'F-05 NYATA: kerugian tercatat DUA KALI (2 x 54.000) untuk satu aksi pembatalan'
);

-- ---------------------------------------------------------------------------
-- F-06: metadata lifecycle pesanan bisa dikarang lewat UPDATE biasa
-- ---------------------------------------------------------------------------
-- Kasir menstempel "sudah dibayar" pada pesanan yang masih draf, tanpa pembayaran.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e3000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 981, current_date, 'dinein', 'draf', 'probe-f06');

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
update public.pesanan
   set dibayar_pada = now(), alasan_batal = 'dibatalkan tanpa jejak pembatalan'
 where id = 'e3000000-0000-0000-0000-000000000001';
reset role;
select uji.klaim(null);

select uji.sama(
  (select (p.status, p.dibayar_pada is not null, p.alasan_batal is not null)
     from public.pesanan p where p.id = 'e3000000-0000-0000-0000-000000000001'),
  ('draf'::text, true, true),
  'F-06 NYATA: kasir mengarang stempel bayar & alasan batal pada pesanan DRAF (aturan: stempel berasal dari jalur peladen)'
);
