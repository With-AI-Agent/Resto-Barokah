-- ============================================================================
-- PROBE HAKIM — H-F-06.3 (2026-10-06), verifikasi ulang PMB1-F-083 (migrasi 0102)
-- ============================================================================
-- Perilaku yang DIHARAPKAN hari ini (sesudah perbaikan 0102) → harus LULUS.
--   A. Jalur TANPA SESI benar-benar hidup: anon + kode pemulihan sah → perangkat
--      darurat terdaftar (nonaktif, masa tenggang 30 menit) & baris persetujuan
--      pasangan ditulis (kaitan 0101).
--   B. Kode sekali pakai: percobaan kedua ditolak.
--   C. Kode salah / terlalu pendek ditolak.
--   D. Kedalaman pertahanan: kode yang DIBUAT admin_cabang (bukan owner_pusat)
--      tetap ditolak walaupun hash-nya sah.
--   E. RESIDU (dasar temuan baru hakim): aktivasi perangkat darurat tetap
--      menuntut SESI (`selesaikan_pemulihan` → "Anda harus masuk terlebih
--      dahulu"), padahal skenario bencananya = owner tidak punya sesi; selama
--      nonaktif, login perangkat darurat ditolak PERANGKAT_TIDAK_SAH.
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-06.3-probe-083.sql
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel ---------------------------------------
delete from public.percobaan_masuk where sebab = 'pulihkan_darurat';
delete from public.pemulihan_perangkat;
delete from public.kredensial_pemulihan;
delete from public.perangkat where nama like 'hp-darurat%';

insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('246813', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- --- A. owner membuat kode (jalur ber-sesi sah) ----------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  public.buat_kode_pemulihan('kode-pemulihan-darurat-hakim-06-3-2026'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-083: owner membuat kode pemulihan darurat'
);

-- --- A2. anon memulihkan perangkat TANPA sesi ------------------------------
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-pemulihan-darurat-hakim-06-3-2026',
    'hp-darurat-hakim',
    'kunci-panjang-darurat-hakim-0123456789',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'F-083: pemulihan darurat TANPA sesi berhasil (deadlock dibuka)'
);

-- --- A3. sesudahnya: perangkat nonaktif + persetujuan pasangan ada ---------
reset role;
create temp table probe_083 as
  select p.id          as perangkat_id,
         q.id          as pemulihan_id
    from public.perangkat p
    join public.pemulihan_perangkat q on q.perangkat_id = p.id
   where p.nama = 'hp-darurat-hakim'
   limit 1;
grant select on probe_083 to anon, authenticated;

select uji.sama(
  (select aktif from public.perangkat where nama = 'hp-darurat-hakim'),
  false,
  'F-083: perangkat darurat terdaftar NONAKTIF (masa tenggang 30 menit)'
);
select uji.sama(
  (select status from public.pemulihan_perangkat where id = (select pemulihan_id from probe_083)),
  'menunggu',
  'F-083: antrean pemulihan berstatus menunggu'
);
select uji.sama(
  (select count(*) from public.persetujuan_perangkat
    where perangkat_id = (select perangkat_id from probe_083)
      and pengguna_id = '90000000-0000-0000-0000-000000000002'),
  1::bigint,
  'F-083: baris persetujuan pasangan owner x perangkat darurat ditulis (kaitan 0101)'
);
select uji.sama(
  (select terpakai from public.kredensial_pemulihan
    where penyewa_id = '11111111-1111-1111-1111-111111111111'
    order by dibuat_pada desc limit 1),
  true,
  'F-083: kode pemulihan ditandai terpakai'
);

-- --- B. kode sekali pakai --------------------------------------------------
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-pemulihan-darurat-hakim-06-3-2026', 'hp-darurat-hakim-2',
      'kunci-panjang-darurat-hakim-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'tidak valid atau sudah pernah dipakai',
  'F-083: kode yang sudah terpakai ditolak dari jalur tanpa sesi'
);

-- --- C. kode salah & kode pendek ditolak ----------------------------------
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-salah-hakim-xxxxxxxxxxxxxxxxxxxxxx', 'hp-darurat-penyerang',
      'kunci-panjang-darurat-hakim-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'tidak valid atau sudah pernah dipakai',
  'F-083: kode salah ditolak tanpa sesi'
);
reset role;
insert into public.kredensial_pemulihan (penyewa_id, kode_hash, dibuat_oleh)
values (
  '11111111-1111-1111-1111-111111111111',
  crypt('kode-pendek-sah-xx', gen_salt('bf', 10)),
  '90000000-0000-0000-0000-000000000002'
);
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-pendek-sah-xx', 'hp-darurat-pendek',
      'kunci-panjang-darurat-hakim-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'tidak valid atau sudah pernah dipakai',
  'F-083: kode < 20 karakter ditolak (hash sah pun tidak dipakai)'
);

-- --- D. kode buatan admin (bukan owner) ditolak ---------------------------
reset role;
insert into public.kredensial_pemulihan (penyewa_id, kode_hash, dibuat_oleh)
values (
  '11111111-1111-1111-1111-111111111111',
  crypt('kode-buatan-admin-cabang-0001', gen_salt('bf', 10)),
  '90000000-0000-0000-0000-000000000003'
);
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.pulihkan_perangkat(
      'kode-buatan-admin-cabang-0001', 'hp-darurat-admin',
      'kunci-panjang-darurat-hakim-0123456789',
      'a1a1a1a1-0000-0000-0000-000000000001')$$,
  'Hanya owner_pusat',
  'F-083: kode yang dibuat admin_cabang ditolak (kedalaman pertahanan)'
);

-- --- E. RESIDU: aktivasi tetap butuh sesi ---------------------------------
-- E1. Kursi anon: bahkan tidak diberi izin memanggil fungsinya.
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan((select pemulihan_id from probe_083))$$,
  'permission denied for function selesaikan_pemulihan',
  'F-083 residu: anon tidak punya izin memanggil selesaikan_pemulihan'
);

-- E2. Kursi authenticated TANPA sesi (auth.uid() null) — kedudukan owner yang
--     kehilangan semua perangkat: tetap ditolak.
select uji.klaim(null);
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan((select pemulihan_id from probe_083))$$,
  'Anda harus masuk terlebih dahulu',
  'F-083 residu: tanpa sesi, aktivasi perangkat darurat ditolak (butuh auth.uid())'
);

-- E3. Kontrol: dari kursi owner BER-sesi jalur itu memang ada — tetapi masih
--     tertahan masa tenggang 30 menit (jadi bukan jalan pintas).
select uji.klaim('90000000-0000-0000-0000-000000000002');
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan((select pemulihan_id from probe_083))$$,
  'Masa tenggang 30 menit belum berakhir',
  'F-083: pemegang sesi kelola_pegawai pun harus menunggu masa tenggang 30 menit'
);

-- E4. Selama nonaktif, perangkat darurat tidak bisa dipakai login.
select uji.klaim(null);
set local role anon;
select uji.sama(
  public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '246813',
    (select perangkat_id from probe_083), 'hp-darurat-hakim', null
  )->>'kode',
  'PERANGKAT_TIDAK_SAH',
  'F-083 residu: perangkat darurat yang belum diaktifkan tetap tidak bisa dipakai login'
);
