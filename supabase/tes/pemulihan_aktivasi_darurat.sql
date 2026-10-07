-- ============================================================================
-- UJI SQL: aktivasi perangkat darurat TANPA sesi (PMB1-F-083 ronde 3 &
--          PMB1-F-234 · K-2) — kunci induk §4b kini tuntas sampai akhir
-- ============================================================================
-- Yang dijaga (migrasi 0105):
--   1. Owner yang kehilangan SELURUH perangkat bisa MENYELESAIKAN pemulihan
--      darurat (mengaktifkan perangkat) TANPA sesi, memakai kunci perangkat
--      yang ia pilih sendiri saat pengajuan (bukti kepemilikan). Sebelumnya
--      hanya ada selesaikan_pemulihan (0028) yang menuntut auth.uid() +
--      kelola_pegawai -> PERANGKAT_TIDAK_SAH selamanya (vonis F-083/F-234).
--   2. Masa tenggang 30 menit tetap ditegakkan: aktivasi sebelum waktunya
--      ditolak.
--   3. Kunci salah / permohonan tak dikenal ditolak dengan pesan seragam
--      (anti-orakel).
--   4. Sesudah aktif: antrean 'selesai', perangkat aktif=true, dan LOGIN
--      owner lewat perangkat itu benar-benar berhasil (ujung-ke-ujung:
--      verifikasi_pin_perangkat mengembalikan true — bukti kunci induk §4b
--      Tingkat 3 bisa dijalankan sampai akhir).
--   5. Permohonan yang sudah selesai tidak bisa diaktifkan ulang.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/pemulihan_aktivasi_darurat.sql
-- ============================================================================

-- Penyiapan: PIN owner dipasang sebagai pemilik tabel (pola tes perangkat lain)
-- supaya langkah 4 bisa membuktikan login ujung-ke-ujung.
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- Penyiapan: owner membuat kode pemulihan darurat (jalur ber-sesi sah).
select uji.klaim('90000000-0000-0000-0000-000000000002'); -- Bu Oasis (owner_pusat)
select uji.sama(
  public.buat_kode_pemulihan('kode-uji-aktivasi-darurat-2026-masih-sangat-panjang'),
  'Kode pemulihan darurat berhasil disimpan. Cetak dan simpan 2 salinan fisik di amplop tersegel.',
  'F-083 r3: owner membuat kode pemulihan darurat'
);
reset role;

-- 1. TANPA SESI: owner mengajukan pemulihan darurat (jalur 0102, sudah ada).
select uji.klaim(null);
set local role anon;
select uji.harap(
  public.pulihkan_perangkat(
    'kode-uji-aktivasi-darurat-2026-masih-sangat-panjang',
    'hp-aktivasi-darurat-f083',
    'kunci-aktivasi-darurat-0123456789',
    'a1a1a1a1-0000-0000-0000-000000000001'
  ) is not null,
  'F-083 r3: pengajuan pemulihan darurat tanpa sesi berhasil'
);
reset role;

-- 2. Masa tenggang ditegakkan: aktivasi SEBELUM 30 menit -> DITOLAK.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-aktivasi-darurat-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: aktivasi sebelum masa tenggang lewat ditolak (tanpa sesi)'
);

-- 2b. Kunci salah sesudah tenggang lewat -> tetap DITOLAK (pesan seragam).
--     (Tenggang dimajukan lewat pemilik tabel: RLS tidak menghalangi pemilik.)
reset role;
update public.pemulihan_perangkat
   set aktif_setelah = now() - interval '1 second'
 where perangkat_id = (select id from public.perangkat where nama = 'hp-aktivasi-darurat-f083');

set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-salah-bukan-milik-owner-1234')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: kunci perangkat salah ditolak dengan pesan seragam'
);

-- 3. Kunci yang benar sesudah tenggang lewat -> AKTIF tanpa sesi.
select uji.sama(
  public.selesaikan_pemulihan_darurat('kunci-aktivasi-darurat-0123456789'),
  true,
  'F-234: aktivasi perangkat darurat tanpa sesi berhasil sesudah tenggang'
);

-- 3b. Antrean selesai + perangkat aktif + jejak audit tercatat.
reset role;
select uji.harap(
  exists (
    select 1 from public.pemulihan_perangkat q
    join public.perangkat p on p.id = q.perangkat_id
     where p.nama = 'hp-aktivasi-darurat-f083'
       and q.status = 'selesai'
       and p.aktif = true
  ),
  'F-234: antrean selesai dan perangkat darurat aktif'
);
select uji.harap(
  exists (
    select 1 from public.catatan_audit
     where aksi = 'selesaikan_pemulihan_darurat'
       and pelaku_id = '90000000-0000-0000-0000-000000000002'
  ),
  'F-234: jejak audit aktivasi tanpa sesi tercatat atas nama pemohon'
);

-- 3c. Permohonan yang sudah selesai tidak bisa diaktifkan ulang.
set local role anon;
select uji.harap_gagal_sebab(
  $$select public.selesaikan_pemulihan_darurat('kunci-aktivasi-darurat-0123456789')$$,
  'Permohonan pemulihan tidak ditemukan',
  'F-234: permohonan selesai tidak bisa diaktifkan ulang'
);

-- 4. UJUNG-KE-UJUNG: owner yang tadinya terkunci PERANGKAT_TIDAK_SAH kini
--    bisa LOGIN lewat perangkat darurat yang baru diaktifkan.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.harap(
  (select public.verifikasi_pin_perangkat(
     'owner.a@contoh.test',
     '481516',
     p.id,
     p.nama,
     'kunci-aktivasi-darurat-0123456789'
   )->>'kode' from public.perangkat p where p.nama = 'hp-aktivasi-darurat-f083') = 'LOGIN_SUKSES',
  'F-234: login owner lewat perangkat darurat berhasil (kunci induk §4b tuntas)'
);
reset role;
