-- ============================================================================
-- UJI: nomor pesanan diambil DI BAWAH KUNCI (serialisasi) — mitigasi AUD-3 F-13
-- Temuan AUD-3 2026-09-19 F-13 (K-2, DUGAAN): `max(nomor) + 1` tanpa serialisasi.
-- ============================================================================
-- Batas jujur yang dicatat: uji concurrency yang diminta laporan (dua transaksi bersamaan)
-- BELUM bisa dijalankan di lingkungan uji proyek — PGlite berjalan di satu koneksi. Yang
-- dijaga mesin di sini adalah SIFAT yang bisa diperiksa langsung dari katalog:
--   1. fungsi pengambil nomor VOLATILE (bukan STABLE) — syarat supaya kunci boleh dipakai;
--   2. pemanggilan kunci advisory per (cabang, tanggal) benar-benar ada di badannya;
--   3. nomor tetap berurutan & unik (perilaku sehari-hari tidak berubah);
--   4. isolasi lintas resto (temuan PR-03) masih hidup.
-- Kalau seseorang mengembalikan fungsi ini ke STABLE tanpa kunci, uji ini MERAH — itulah
-- bukti yang bisa diberikan sekarang, tanpa berpura-pura sudah menguji concurrency.
-- ============================================================================

-- 1. Sifat serialisasi: VOLATILE + memakai kunci advisory.
select uji.sama(
  (select p.provolatile from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'nomor_pesanan_berikutnya'),
  'v'::"char",
  'F-13: fungsi pengambil nomor VOLATILE (boleh mengunci) — bukan STABLE lagi'
);
select uji.harap(
  (select pg_get_functiondef(p.oid) like '%pg_advisory_xact_lock%'
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'nomor_pesanan_berikutnya'),
  'F-13: pemanggilan kunci advisory (serialisasi per cabang & tanggal) ADA di badan fungsi'
);

-- 2. Perilaku tidak berubah: nomor naik berurutan untuk cabang & tanggal yang sama.
select uji.klaim(null);
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status, kunci_idempoten)
values ('e9000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 41, public.tanggal_lokal_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid, now()), 'dinein', 'draf', 'kunci-nomor-1');
select uji.sama(
  public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', public.tanggal_lokal_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid, now())),
  42, 'nomor berikutnya = 42 setelah pesanan bernomor 41 (max + 1 tetap benar)'
);

-- 3. Pemicu pesanan benar-benar memakai fungsi itu (nomor diisi sistem, bukan klien).
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- Rina, kasir Cabang A1
set local role authenticated;
insert into public.pesanan (id, penyewa_id, cabang_id, tipe, kunci_idempoten)
values ('e9000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 'dinein', 'kunci-nomor-2');
select uji.sama(
  (select p.nomor from public.pesanan p where p.id = 'e9000000-0000-0000-0000-000000000002'),
  42, 'pesanan baru dari perangkat mendapat nomor dari sistem (42)'
);

-- 4. Isolasi lintas resto (PR-03) masih hidup: kasir resto lain tidak boleh menghitung.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- kasir resto B (penyewa lain)
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', public.tanggal_lokal_cabang('a1a1a1a1-0000-0000-0000-000000000001'::uuid, now()))$$,
  'bukan cabang yang boleh Anda lihat',
  'isolasi lintas resto pada penghitung nomor tetap ditegakkan'
);
reset role;
select uji.klaim(null);
