-- ============================================================================
-- PROBE SESI KERJA — bantah-balik temuan AUD-3 2026-09-19 (laporan __01a0bbd2)
-- ============================================================================
-- Tujuan: membuktikan SENDIRI (bukan mempercayai laporan) apakah dua temuan K-1 pada
-- jalur uang benar-benar ada di kode sekarang.
--
-- CARA BACA: berkas ini meng-ASERSI KEADAAN YANG SALAH. Kalau semua asersi LULUS,
-- cacatnya NYATA. Sesudah diperbaiki, berkas ini WAJIB GAGAL — karena itu ia hidup di
-- `docs/uji/audit/probe-2026-09-20/`, bukan di `supabase/tes` (folder uji wajib hijau).
--
-- Aturan yang dilanggar (kutipan dokumen fondasi):
--   docs/TECH_SPEC.md:329-330 — "subtotal → diskon → pajak PB1 → service → pembulatan →
--     total … pajak & service dihitung dari SUBTOTAL SETELAH DISKON".
--   docs/TECH_SPEC.md:152     — kolom `pengaturan.pembulatan` (none/100/500/1000).
--   docs/TECH_SPEC.md:17      — hitungan uang dilakukan di peladen, bukan dikira-kira.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- F-01a: pajak & service dihitung dari subtotal SEBELUM diskon
-- ---------------------------------------------------------------------------
-- Pesanan 1 di cabang A2: Nasi Goreng Rp25.000 × 4 = Rp100.000.
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e1000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000002', 961, current_date, 'dinein', 'draf', 'probe-f01');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e1000000-0000-0000-0000-000000000001', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 25000, 4, 100000);

select uji.sama((select p.subtotal from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000001'),
                100000, 'probe F-01: subtotal dasar 100.000');

select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner (beri_diskon tanpa batas)
set local role authenticated;
insert into public.diskon_transaksi (pesanan_id, jenis, persen, nilai, alasan)
values ('e1000000-0000-0000-0000-000000000001', 'manual', 20, 20000, 'probe F-01');
reset role;
select uji.klaim(null);

select uji.sama(
  (select p.pajak from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000001'),
  10000,
  'F-01a NYATA: PB1 10% dari 100.000 (SEBELUM diskon); aturan menuntut 10% dari 80.000 = 8.000'
);
select uji.sama(
  (select p.service from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000001'),
  5000,
  'F-01a NYATA: service 5% dari 100.000 (SEBELUM diskon); aturan menuntut 5% dari 80.000 = 4.000'
);
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000001'),
  95000,
  'F-01a NYATA: total 100.000 + 10.000 + 5.000 − 20.000 = 95.000; seharusnya 80.000 + 8.000 + 4.000 = 92.000'
);

-- ---------------------------------------------------------------------------
-- F-01b: pengaturan `pembulatan` tidak pernah dibaca
-- ---------------------------------------------------------------------------
-- Pesanan 2 di cabang A1: Nasi Goreng Rp27.000 × 1 → total 31.050 (tidak bulat).
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e1000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 962, current_date, 'dinein', 'draf', 'probe-f01b');
insert into public.pesanan_item (pesanan_id, menu_item_id, nama_saat_itu, harga_saat_itu, qty, subtotal)
values ('e1000000-0000-0000-0000-000000000002', 'beef0000-0000-0000-0000-000000000001',
        'Nasi Goreng', 27000, 1, 27000);

update public.pengaturan set pembulatan = '500'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
update public.pesanan set catatan = 'picu hitung ulang'
 where id = 'e1000000-0000-0000-0000-000000000002';

select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000002'),
  31050, 'probe F-01b: total sebelum dibulatkan = 31.050 (27.000 + 2.700 + 1.350)'
);
select uji.sama(
  (select p.total % 500 from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000002'),
  50,
  'F-01b NYATA: sisa bagi 500 = 50 (seharusnya 0) → pengaturan pembulatan 500 diabaikan mesin'
);
update public.pengaturan set pembulatan = 'none'::text
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- ---------------------------------------------------------------------------
-- F-02: RPC `hitung_total` bisa menulis ulang angka pesanan yang sudah LUNAS
-- ---------------------------------------------------------------------------
update public.pesanan set status = 'lunas', dibayar_pada = now()
 where id = 'e1000000-0000-0000-0000-000000000002';
select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000002'),
  31050, 'probe F-02: angka lunas saat tercatat = 31.050'
);

-- Tarif PB1 naik (kejadian sah: pemilik mengubah pengaturan), lalu KASIR memanggil RPC.
update public.pengaturan set pajak_pb1_persen = 20
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir cabang A1
set local role authenticated;
select uji.sama(
  public.hitung_total('e1000000-0000-0000-0000-000000000002') > 0,
  true,
  'F-02 NYATA: kasir BISA memanggil hitung_total untuk pesanan yang SUDAH LUNAS (tidak ditolak)'
);
reset role;
select uji.klaim(null);

select uji.sama(
  (select p.total from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000002'),
  33750,
  'F-02 NYATA: total pesanan LUNAS berubah 31.050 → 33.750 sesudah RPC dipanggil kasir'
);
select uji.sama(
  (select p.pajak from public.pesanan p where p.id = 'e1000000-0000-0000-0000-000000000002'),
  5400,
  'F-02 NYATA: kolom pajak pesanan lunas ditulis ulang 2.700 → 5.400 (tarif baru menimpa struk lama)'
);

update public.pengaturan set pajak_pb1_persen = 10
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
