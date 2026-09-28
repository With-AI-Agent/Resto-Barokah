-- ============================================================================
-- UJI: Jejak Audit Wajib & Integritas Status Pembayaran (M F-01)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_7ccbb132 M F-01: Pembayaran langsung tidak memiliki
--     jejak audit di catatan_audit.
--   - Migrasi 0060_pembayaran_audit.sql
-- ============================================================================

-- Persiapan: Kasir Rina (9000...0004), cabang Pusat
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 1. Uji Pembayaran Langsung (Direct INSERT) WAJIB menghasilkan catatan_audit (M F-01)
insert into public.pembayaran (
  pesanan_id, metode_id, jumlah, diterima, kunci_idempoten
)
select 'eeee0000-0000-0000-0000-000000000010', mb.id, 5000, 10000, 'uji-mf01-langsung-01'
  from public.metode_bayar mb
 where mb.penyewa_id = '11111111-1111-1111-1111-111111111111' and mb.nama = 'Tunai';

-- Beralih ke Owner untuk memeriksa catatan_audit (karena catatan_audit hanya dapat dibaca pemegang kelola_pegawai)
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

-- Buktikan baris catatan_audit bertambah untuk pembayaran ini
select uji.sama(
  (select count(*)::int from public.catatan_audit where entitas = 'pembayaran' and aksi = 'pembayaran_langsung'),
  1,
  'Pembayaran langsung (direct insert) meninggalkan jejak audit di catatan_audit (M F-01 tertutup)'
);

-- 2. Uji Pembayaran via RPC bayar_pesanan menghasilkan catatan_audit aksi 'bayar_pesanan'
-- dan TIDAK membuat baris dobel
drop table if exists temp_audit_rpc_sebelum;
create temporary table temp_audit_rpc_sebelum as
select count(*)::int as jml from public.catatan_audit where entitas = 'pembayaran';

-- Kasir membayar lewat RPC
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select public.bayar_pesanan(
  'eeee0000-0000-0000-0000-000000000010',
  (select id from public.metode_bayar where penyewa_id = '11111111-1111-1111-1111-111111111111' and nama = 'Tunai' limit 1),
  1000,
  5000,
  null,
  'uji-mf01-rpc-01'
);

-- Owner memeriksa catatan_audit
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  (select count(*)::int from public.catatan_audit where entitas = 'pembayaran') - (select jml from temp_audit_rpc_sebelum),
  1,
  'bayar_pesanan menghasilkan tepat 1 baris catatan_audit (tanpa duplikasi)'
);

select uji.sama(
  (select count(*)::int from public.catatan_audit where entitas = 'pembayaran' and aksi = 'bayar_pesanan'),
  1,
  'bayar_pesanan mencatat jejak dengan aksi bayar_pesanan'
);
