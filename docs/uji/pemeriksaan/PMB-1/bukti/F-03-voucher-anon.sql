-- Probe baca-saja terhadap produksi: hanya PGlite lokal; runner selalu ROLLBACK.
-- Jalankan dari akar repo: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-03-voucher-anon.sql
-- Sengaja menegaskan perilaku cacat (probe hijau berarti kelemahan masih ada), BUKAN uji regresi keamanan.
-- Prasyarat runner: fixture tenant Kedai Oasis di alat/sql/data-uji.sql; semua migrasi berlaku diterapkan.

-- Kampanye uji berkuota 10, terisolasi di transaksi runner (tidak pernah dikirim ke produksi).
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000003',
  '11111111-1111-1111-1111-111111111111',
  'Probe F-03 saja', 'PROBEF03', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 10, true
);

-- Tidak ada JWT/akun, dan semua panggilan berikut benar-benar dari role publik.
select uji.klaim(null);
set local role anon;

select uji.harap(
  (public.daftar_voucher(
    '11111111-1111-1111-1111-111111111111',
    'c3000000-0000-0000-0000-000000000003',
    'Pengaku Google', 'orang-asli-a@gmail.com', null, null, true, 'google'
  )->>'kode') = 'SUKSES',
  'F-03: anonim tanpa OAuth dapat mengaku Google lalu mendapat voucher'
);
select uji.harap(
  (public.daftar_voucher(
    '11111111-1111-1111-1111-111111111111',
    'c3000000-0000-0000-0000-000000000003',
    'Pengaku Email', 'orang-asli-b@gmail.com', null, null, true, 'email'
  )->>'kode') = 'SUKSES',
  'F-03: anonim tanpa verifikasi email dapat mengaku alamat kedua lalu mendapat voucher'
);
select uji.harap(
  (select hasil->>'kode' = 'VOUCHER_SUDAH_DIKLAIM'
       and nullif(hasil->'data'->>'kode_voucher', '') is not null
     from (select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000003',
       'Orang Lain', 'orang-asli-a@gmail.com', null, null, true, 'google'
     ) as hasil) as panggil),
  'F-03: pemanggil anonim lain bisa meminta kode voucher pemilik email yang sama'
);

reset role;
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000003') = 2,
  'F-03: dua identitas yang tidak diverifikasi benar-benar mendapat dua voucher tersimpan'
);
select uji.harap(
  (select count(*) from public.pelanggan
    where email in ('orang-asli-a@gmail.com', 'orang-asli-b@gmail.com')
      and terverifikasi_pada is not null) = 2,
  'F-03: database menandai kedua alamat sudah diverifikasi tanpa bukti Auth/email'
);
select uji.harap(
  (select count(*) from auth.users
    where email in ('orang-asli-a@gmail.com', 'orang-asli-b@gmail.com')) = 0,
  'F-03: tidak ada akun Auth untuk kedua email'
);
